package oracle

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"regexp"
	"strconv"
	"strings"

	"github.com/thoas/go-funk"
	"gorm.io/gorm"
	"gorm.io/gorm/callbacks"
	"gorm.io/gorm/clause"
	"gorm.io/gorm/logger"
	"gorm.io/gorm/migrator"
	"gorm.io/gorm/schema"
	"gorm.io/gorm/utils"
)

type Config struct {
	DriverName        string
	DSN               string
	Conn              gorm.ConnPool //*sql.DB
	DefaultStringSize uint
	DBVer             string
}

type Dialector struct {
	*Config
}

func Open(dsn string) gorm.Dialector {
	return &Dialector{Config: &Config{DSN: dsn}}
}

func New(config Config) gorm.Dialector {
	return &Dialector{Config: &config}
}

func (d Dialector) DummyTableName() string {
	return "DUAL"
}

func (d Dialector) Name() string {
	return "oracle"
}

func (d Dialector) Initialize(db *gorm.DB) (err error) {
	db.NamingStrategy = Namer{db.NamingStrategy.(schema.NamingStrategy)}
	d.DefaultStringSize = 1024

	// register callbacks
	//callbacks.RegisterDefaultCallbacks(db, &callbacks.Config{WithReturning: true})
	callbacks.RegisterDefaultCallbacks(db, &callbacks.Config{
		CreateClauses: []string{"INSERT", "VALUES", "ON CONFLICT", "RETURNING"},
		UpdateClauses: []string{"UPDATE", "SET", "WHERE", "RETURNING"},
		DeleteClauses: []string{"DELETE", "FROM", "WHERE", "RETURNING"},
	})

	d.DriverName = "oracle"

	if d.Conn != nil {
		db.ConnPool = d.Conn
	} else {
		db.ConnPool, err = sql.Open(d.DriverName, d.DSN)
		if err != nil {
			return
		}
	}
	err = db.ConnPool.QueryRowContext(context.Background(), "select version from product_component_version where rownum = 1").Scan(&d.DBVer)
	if err != nil {
		return err
	}
	//log.Println("DBver:" + d.DBVer)

	if err = db.Callback().Create().Replace("gorm:create", Create); err != nil {
		return
	}

	for k, v := range d.ClauseBuilders() {
		db.ClauseBuilders[k] = v
	}
	return
}

func (d Dialector) ClauseBuilders() map[string]clause.ClauseBuilder {
	dbver, _ := strconv.Atoi(strings.Split(d.DBVer, ".")[0])
	if dbver > 0 && dbver < 12 {
		return map[string]clause.ClauseBuilder{
			"LIMIT": d.RewriteLimit11,
		}

	} else {
		return map[string]clause.ClauseBuilder{
			"LIMIT": d.RewriteLimit,
		}
	}

}

func (d Dialector) RewriteLimit(c clause.Clause, builder clause.Builder) {
	if limit, ok := c.Expression.(clause.Limit); ok {
		if stmt, ok := builder.(*gorm.Statement); ok {
			if _, ok := stmt.Clauses["ORDER BY"]; !ok {
				s := stmt.Schema
				builder.WriteString("ORDER BY ")
				if s != nil && s.PrioritizedPrimaryField != nil {
					builder.WriteQuoted(s.PrioritizedPrimaryField.DBName)
					builder.WriteByte(' ')
				} else {
					builder.WriteString("(SELECT NULL FROM ")
					builder.WriteString(d.DummyTableName())
					builder.WriteString(")")
				}
			}
		}

		if offset := limit.Offset; offset > 0 {
			builder.WriteString(" OFFSET ")
			builder.WriteString(strconv.Itoa(offset))
			builder.WriteString(" ROWS")
		}
		if limit := limit.Limit; *limit > 0 {
			builder.WriteString(" FETCH NEXT ")
			builder.WriteString(strconv.Itoa(*limit))
			builder.WriteString(" ROWS ONLY")
		}
	}
}

// RewriteLimit11 Oracle11 Limit
func (d Dialector) RewriteLimit11(c clause.Clause, builder clause.Builder) {
	if limit, ok := c.Expression.(clause.Limit); ok {
		if stmt, ok := builder.(*gorm.Statement); ok {
			limitsql := strings.Builder{}
			if limit := limit.Limit; *limit > 0 {
				if _, ok := stmt.Clauses["WHERE"]; !ok {
					limitsql.WriteString(" WHERE ")
				} else {
					limitsql.WriteString(" AND ")
				}
				limitsql.WriteString("ROWNUM <= ")
				limitsql.WriteString(strconv.Itoa(*limit))
			}
			if _, ok := stmt.Clauses["ORDER BY"]; !ok {
				_, _ = builder.WriteString(limitsql.String())
			} else {
				//  "ORDER BY" before  insert
				sqltmp := strings.Builder{}
				sqlold := stmt.SQL.String()
				orderindx := strings.Index(sqlold, "ORDER BY") - 1
				sqltmp.WriteString(sqlold[:orderindx])
				sqltmp.WriteString(limitsql.String())
				sqltmp.WriteString(sqlold[orderindx:])
				log.Println(sqltmp.String())
				stmt.SQL = sqltmp
			}
		}
	}
}

func (d Dialector) DefaultValueOf(*schema.Field) clause.Expression {
	return clause.Expr{SQL: "VALUES (DEFAULT)"}
}

func (d Dialector) Migrator(db *gorm.DB) gorm.Migrator {
	return Migrator{
		Migrator: migrator.Migrator{
			Config: migrator.Config{
				DB:                          db,
				Dialector:                   d,
				CreateIndexAfterCreateTable: true,
			},
		},
	}
}

func (d Dialector) BindVarTo(writer clause.Writer, stmt *gorm.Statement, v interface{}) {
	writer.WriteString(":")
	writer.WriteString(strconv.Itoa(len(stmt.Vars)))
}

func (d Dialector) QuoteTo(writer clause.Writer, str string) {
	writer.WriteString(str)
}

var numericPlaceholder = regexp.MustCompile(`:(\d+)`)

func (d Dialector) Explain(sql string, vars ...interface{}) string {
	return logger.ExplainSQL(sql, numericPlaceholder, `'`, funk.Map(vars, func(v interface{}) interface{} {
		switch v := v.(type) {
		case bool:
			if v {
				return 1
			}
			return 0
		default:
			return v
		}
	}).([]interface{})...)
}

func (d Dialector) DataTypeOf(field *schema.Field) string {
	if _, found := field.TagSettings["RESTRICT"]; found {
		delete(field.TagSettings, "RESTRICT")
	}

	var sqlType string

	switch field.DataType {
	case schema.Int, schema.Uint:
		size := field.Precision
		if size == 0 {
			size = 20
		}

		sqlType = fmt.Sprintf("NUMBER(%d,0)", size)
		if val, ok := field.TagSettings["AUTOINCREMENT"]; ok && utils.CheckTruth(val) {
			sqlType += " GENERATED BY DEFAULT AS IDENTITY"
		}
	case schema.Float:
		size := field.Precision
		scale := field.Scale

		if size > 0 && scale > 0 {
			sqlType = fmt.Sprintf("NUMBER(%d,%d)", size, scale)
		} else {
			sqlType = "FLOAT"
		}
	case schema.Bool:
		sqlType = "INTEGER"
	case schema.String, "VARCHAR2":
		size := field.Size
		defaultSize := d.DefaultStringSize

		if size == 0 {
			if defaultSize > 0 {
				size = int(defaultSize)
			} else {
				hasIndex := field.TagSettings["INDEX"] != "" || field.TagSettings["UNIQUE"] != ""
				// TEXT, GEOMETRY or JSON column can't have a default value
				if field.PrimaryKey || field.HasDefaultValue || hasIndex {
					size = 191 // utf8mb4
				}
			}
		}

		if size >= 2000 {
			sqlType = "CLOB"
		} else {
			sqlType = fmt.Sprintf("VARCHAR2(%d)", size)
		}

	case schema.Time:
		sqlType = "DATE" //sqlType = "TIMESTAMP WITH TIME ZONE"
		if field.NotNull || field.PrimaryKey {
			sqlType += " NOT NULL"
		}
	case schema.Bytes:
		sqlType = "BLOB"
	default:
		sqlType = string(field.DataType)

		if strings.EqualFold(sqlType, "text") {
			sqlType = "CLOB"
		}

		if sqlType == "" {
			panic(fmt.Sprintf("invalid sql type %s (%s) for oracle", field.FieldType.Name(), field.FieldType.String()))
		}

		notNull, _ := field.TagSettings["NOT NULL"]
		unique, _ := field.TagSettings["UNIQUE"]
		additionalType := fmt.Sprintf("%s %s", notNull, unique)
		if value, ok := field.TagSettings["DEFAULT"]; ok {
			additionalType = fmt.Sprintf("%s %s %s%s", "DEFAULT", value, additionalType, func() string {
				if value, ok := field.TagSettings["COMMENT"]; ok {
					return " COMMENT " + value
				}
				return ""
			}())
		}
		sqlType = fmt.Sprintf("%v %v", sqlType, additionalType)
	}

	return sqlType
}

func (d Dialector) SavePoint(tx *gorm.DB, name string) error {
	tx.Exec("SAVEPOINT " + name)
	return tx.Error
}

func (d Dialector) RollbackTo(tx *gorm.DB, name string) error {
	tx.Exec("ROLLBACK TO SAVEPOINT " + name)
	return tx.Error
}
