package oracle

import (
	"database/sql"
	"fmt"
	"strings"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
	"gorm.io/gorm/migrator"
	"gorm.io/gorm/schema"
)

type Migrator struct {
	migrator.Migrator
}

// GetTypeAliases return database type aliases
func (m Migrator) GetTypeAliases(databaseTypeName string) []string {
	//dbName := strings.ToLower(databaseTypeName)
	//已经转换为小写了

	if strings.Contains(databaseTypeName, "char") {
		return []string{"varchar2", "nvarchar2", "nchar", "char"}
	} else if databaseTypeName == "ocicloblocator" {
		return []string{"clob"}
	}
	return nil
}

func (m Migrator) CurrentDatabase() (name string) {
	m.DB.Raw(
		fmt.Sprintf(`SELECT ORA_DATABASE_NAME as "Current Database" FROM %s`, m.Dialector.(Dialector).DummyTableName()),
	).Row().Scan(&name)
	return
}

func (m Migrator) CreateTable(values ...interface{}) error {
	for _, value := range values {
		m.TryQuotifyReservedWords(value)
		m.TryRemoveOnUpdate(value)
	}
	err := m.Migrator.CreateTable(values...)

	for _, value := range m.ReorderModels(values, false) {
		if err := m.RunWithValue(value, func(stmt *gorm.Statement) (errr error) {
			for _, dbName := range stmt.Schema.DBNames {
				field := stmt.Schema.FieldsByDBName[dbName]
				if !field.IgnoreMigration {
					defer m.AddColumnComment(field)
				}
			}

			return errr
		}); err != nil {
			return err
		}
	}

	return err
}

func (m Migrator) DropTable(values ...interface{}) error {
	values = m.ReorderModels(values, false)
	for i := len(values) - 1; i >= 0; i-- {
		value := values[i]
		tx := m.DB.Session(&gorm.Session{})
		if m.HasTable(value) {
			if err := m.RunWithValue(value, func(stmt *gorm.Statement) error {
				return tx.Exec("DROP TABLE ? CASCADE CONSTRAINTS", clause.Table{Name: stmt.Table}).Error
			}); err != nil {
				return err
			}
		}
	}
	return nil
}

func (m Migrator) HasTable(value interface{}) bool {
	var count int64

	_ = m.RunWithValue(value, func(stmt *gorm.Statement) error {
		if stmt.Schema != nil && strings.Contains(stmt.Schema.Table, ".") {
			ownertable := strings.Split(stmt.Schema.Table, ".")
			return m.DB.Raw("SELECT COUNT(*) FROM ALL_TABLES WHERE OWNER = ?  and  TABLE_NAME = ?", ownertable[0], ownertable[1]).Row().Scan(&count)
		} else {
			return m.DB.Raw("SELECT COUNT(*) FROM USER_TABLES WHERE TABLE_NAME = ?", stmt.Table).Row().Scan(&count)
		}
	})

	return count > 0
}

// ColumnTypes return columnTypes []gorm.ColumnType and execErr error
func (m Migrator) ColumnTypes(value interface{}) ([]gorm.ColumnType, error) {
	columnTypes := make([]gorm.ColumnType, 0)
	execErr := m.RunWithValue(value, func(stmt *gorm.Statement) (err error) {
		rows, err := m.DB.Session(&gorm.Session{}).Table(stmt.Schema.Table).Where("ROWNUM = 1").Rows()
		if err != nil {
			return err
		}

		defer func() {
			err = rows.Close()
		}()

		var rawColumnTypes []*sql.ColumnType
		rawColumnTypes, err = rows.ColumnTypes()
		if err != nil {
			return err
		}

		for _, c := range rawColumnTypes {
			columnTypes = append(columnTypes, migrator.ColumnType{SQLColumnType: c})
		}

		return
	})

	return columnTypes, execErr
}

func (m Migrator) RenameTable(oldName, newName interface{}) (err error) {
	resolveTable := func(name interface{}) (result string, err error) {
		if v, ok := name.(string); ok {
			result = v
		} else {
			stmt := &gorm.Statement{DB: m.DB}
			if err = stmt.Parse(name); err == nil {
				result = stmt.Table
			}
		}
		return
	}

	var oldTable, newTable string

	if oldTable, err = resolveTable(oldName); err != nil {
		return
	}

	if newTable, err = resolveTable(newName); err != nil {
		return
	}

	if !m.HasTable(oldTable) {
		return
	}

	return m.DB.Exec("RENAME TABLE ? TO ?",
		clause.Table{Name: oldTable},
		clause.Table{Name: newTable},
	).Error
}

func (m Migrator) AddColumn(value interface{}, field string) error {
	return m.RunWithValue(value, func(stmt *gorm.Statement) error {
		if field := stmt.Schema.LookUpField(field); field != nil {
			err := m.DB.Exec(
				"ALTER TABLE ? ADD ? ?",
				clause.Table{Name: stmt.Table}, clause.Column{Name: field.DBName}, m.DB.Migrator().FullDataTypeOf(field),
			).Error

			if err != nil {
				err = m.AddColumnComment(field)
			}

			return err
		}
		return fmt.Errorf("failed to look up field with name: %s", field)
	})
}

//add column comment
func (m Migrator) AddColumnComment(field *schema.Field) error {

	if field.Comment == "" || field.Comment == "''" {
		return nil
	}

	commentSql := fmt.Sprintf("COMMENT ON COLUMN %s.%s is '%s' ", field.Schema.Table, field.DBName, strings.ReplaceAll(field.Comment, "'", ""))

	err := m.DB.Exec(commentSql).Error

	return err
}

func (m Migrator) DropColumn(value interface{}, name string) error {
	if !m.HasColumn(value, name) {
		return nil
	}

	return m.RunWithValue(value, func(stmt *gorm.Statement) error {
		if field := stmt.Schema.LookUpField(name); field != nil {
			name = field.DBName
		}

		return m.DB.Exec(
			"ALTER TABLE ? DROP ?",
			clause.Table{Name: stmt.Table},
			clause.Column{Name: name},
		).Error
	})
}

func (m Migrator) AlterColumn(value interface{}, field string) error {
	if !m.HasColumn(value, field) {
		return nil
	}

	return m.RunWithValue(value, func(stmt *gorm.Statement) error {
		if field := stmt.Schema.LookUpField(field); field != nil {
			return m.DB.Exec(
				"ALTER TABLE ? MODIFY ? ?",
				clause.Table{Name: stmt.Table},
				clause.Column{Name: field.DBName},
				m.FullDataTypeOf(field),
			).Error
		}
		return fmt.Errorf("failed to look up field with name: %s", field)
	})
}

func (m Migrator) HasColumn(value interface{}, field string) bool {
	var count int64
	return m.RunWithValue(value, func(stmt *gorm.Statement) error {
		return m.DB.Raw("SELECT COUNT(*) FROM USER_TAB_COLUMNS WHERE TABLE_NAME = ? AND COLUMN_NAME = ?", stmt.Table, field).Row().Scan(&count)
	}) == nil && count > 0
}

func (m Migrator) CreateConstraint(value interface{}, name string) error {
	m.TryRemoveOnUpdate(value)
	return m.Migrator.CreateConstraint(value, name)
}

func (m Migrator) DropConstraint(value interface{}, name string) error {
	return m.RunWithValue(value, func(stmt *gorm.Statement) error {
		for _, chk := range stmt.Schema.ParseCheckConstraints() {
			if chk.Name == name {
				return m.DB.Exec(
					"ALTER TABLE ? DROP CHECK ?",
					clause.Table{Name: stmt.Table}, clause.Column{Name: name},
				).Error
			}
		}

		return m.DB.Exec(
			"ALTER TABLE ? DROP CONSTRAINT ?",
			clause.Table{Name: stmt.Table}, clause.Column{Name: name},
		).Error
	})
}

func (m Migrator) HasConstraint(value interface{}, name string) bool {
	var count int64
	return m.RunWithValue(value, func(stmt *gorm.Statement) error {
		return m.DB.Raw(
			"SELECT COUNT(*) FROM USER_CONSTRAINTS WHERE TABLE_NAME = ? AND CONSTRAINT_NAME = ?", stmt.Table, name,
		).Row().Scan(&count)
	}) == nil && count > 0
}

func (m Migrator) DropIndex(value interface{}, name string) error {
	return m.RunWithValue(value, func(stmt *gorm.Statement) error {
		if idx := stmt.Schema.LookIndex(name); idx != nil {
			name = idx.Name
		}

		return m.DB.Exec("DROP INDEX ?", clause.Column{Name: name}, clause.Table{Name: stmt.Table}).Error
	})
}

func (m Migrator) HasIndex(value interface{}, name string) bool {
	var count int64
	m.RunWithValue(value, func(stmt *gorm.Statement) error {
		if idx := stmt.Schema.LookIndex(name); idx != nil {
			name = idx.Name
		}

		return m.DB.Raw(
			"SELECT COUNT(*) FROM USER_INDEXES WHERE TABLE_NAME = ? AND INDEX_NAME = ?",
			m.Migrator.DB.NamingStrategy.TableName(stmt.Table),
			m.Migrator.DB.NamingStrategy.IndexName(stmt.Table, name),
		).Row().Scan(&count)
	})

	return count > 0
}

// https://docs.oracle.com/database/121/SPATL/alter-index-rename.htm
func (m Migrator) RenameIndex(value interface{}, oldName, newName string) error {
	panic("TODO")
	return m.RunWithValue(value, func(stmt *gorm.Statement) error {
		return m.DB.Exec(
			"ALTER INDEX ?.? RENAME TO ?", // wat
			clause.Table{Name: stmt.Table}, clause.Column{Name: oldName}, clause.Column{Name: newName},
		).Error
	})
}

func (m Migrator) TryRemoveOnUpdate(values ...interface{}) error {
	for _, value := range values {
		if err := m.RunWithValue(value, func(stmt *gorm.Statement) error {
			for _, rel := range stmt.Schema.Relationships.Relations {
				constraint := rel.ParseConstraint()
				if constraint != nil {
					rel.Field.TagSettings["CONSTRAINT"] = strings.ReplaceAll(rel.Field.TagSettings["CONSTRAINT"], fmt.Sprintf("ON UPDATE %s", constraint.OnUpdate), "")
				}
			}
			return nil
		}); err != nil {
			return err
		}
	}
	return nil
}

func (m Migrator) TryQuotifyReservedWords(values ...interface{}) error {
	for _, value := range values {
		if err := m.RunWithValue(value, func(stmt *gorm.Statement) error {
			for idx, v := range stmt.Schema.DBNames {
				if IsReservedWord(v) {
					stmt.Schema.DBNames[idx] = fmt.Sprintf(`"%s"`, v)
				}
			}

			for _, v := range stmt.Schema.Fields {
				if IsReservedWord(v.DBName) {
					v.DBName = fmt.Sprintf(`"%s"`, v.DBName)
				}
			}
			return nil
		}); err != nil {
			return err
		}
	}
	return nil
}
