package oracle_test

import (
	"fmt"
	"testing"

	carbon "github.com/golang-module/carbon/v2"
	go_ora "github.com/sijms/go-ora/v2"
	"github.com/snglw07/oracle"
	"gorm.io/gorm"
	"gorm.io/gorm/schema"
)

//@Description 支付订单
type AaYlPayOrder struct {
	CreatedAt carbon.DateTime  `gorm:"<-:create;comment:'创建时间'" json:"createdAt" swaggerignore:"true"` //创建时间
	UpdatedAt *carbon.DateTime `gorm:"comment:'更新时间'" json:"updatedAt" swaggerignore:"true"`           //更新时间

	CreatedIp string `gorm:"<-:create;size:40;comment:'订单创建IP';" json:"createdIp" form:"createdIp" swaggerignore:"true"` //订单创建IP

	NotifyIp string `gorm:"<-:update;size:40;comment:'订单状态更新IP';" json:"notifyIp" form:"notifyIp" swaggerignore:"true"` //订单状态更新IP

	Id string `gorm:"primaryKey;size:32;comment:'商户订单号';" json:"id" form:"id" swaggerignore:"true"` //商户订单号

	OrgId string `gorm:"size:32;comment:'所属机构Id';" json:"orgId" form:"orgId"` //所属机构Id

	BizType string `gorm:"size:32;index:idx_biz_type_pk;comment:'业务类型';" json:"bizType" form:"bizType"` //业务类型

	BizPkId string `gorm:"size:32;index:idx_biz_type_pk;comment:'业务主键';" json:"bizPkId" form:"bizPkId"` //业务主键

	Description string `gorm:"size:200;comment:'订单描述';" json:"description" form:"description"` //订单描述

	BizData string `gorm:"type:text;comment:'业务数据';" json:"bizData" form:"bizData"` //业务数据

	Amount int `gorm:"precision:10;comment:'订单金额';" json:"amount" form:"amount" example:"1"` //金额单位为分

	Status string `gorm:"size:20;comment:'订单状态';" json:"status" form:"status" swaggerignore:"true"` //订单状态

	ReturnUrl string `gorm:"-" json:"returnUrl" form:"returnUrl"` //响应跳转url

	RefundTag int `gorm:"precision:1;default:0;comment:'退费标志';" json:"refundTag" form:"refundTag" swaggerignore:"true"` //退费标志

	Openid string `gorm:"size:32;index:idx_pay_order_openid11;comment:'微信openid';" json:"openid" form:"openid"` //微信openid

	Dt carbon.DateTime `json:"dt"` //创建时间

}

func Test0(t *testing.T) {
	//cnnStr := fmt.Sprintf(`user="%s" password="%s" connectString="%s:%d/%s"`, "c##wbgw", "bltsoft", "192.168.8.188", 1521, "ORCL")

	cnnStr := go_ora.BuildUrl("127.0.0.1", 1521, "ORCL", "c##wbgw", "bltsoft", nil)

	dialector := oracle.Open(cnnStr)

	ormdb, err := gorm.Open(dialector, &gorm.Config{
		DisableForeignKeyConstraintWhenMigrating: true,
		NamingStrategy: schema.NamingStrategy{
			//TablePrefix:   "t_", // table name prefix, table for `User` would be `t_users`
			SingularTable: true,  // use singular table name, table for `User` would be `user` with this option enabled
			NoLowerCase:   false, // skip the snake_casing of names
			//NameReplacer:  strings.NewReplacer("CID", "Cid"), // use name replacer to change struct/field name before convert it to db name
		},
		QueryFields: true,
	})

	fmt.Println(ormdb, err)

	err = ormdb.AutoMigrate(&AaYlPayOrder{})

	fmt.Println(err)

	var entity = AaYlPayOrder{Id: "113", BizData: "clob内容112"}

	tx := ormdb.Save(&entity)

	fmt.Println(tx)
}
