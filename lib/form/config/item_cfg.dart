import 'package:wbyq/application.dart';

import '../index.dart';

class WbItemCfg {
  final WbItemType type;
  final WbItemVType vtype;
  final String id;
  final String? title;
  final int dataMinLength; //字符串长度
  final int dataMaxLength; //字符串长度
  final int minLength; //字列表长度
  final int maxLength; //列表长度
  final num? minValue; //数字最小值
  final num? maxValue; //数字最大值
  final int? decimalPrecision; //小数精度
  final bool allowBlank;
  final String? hintText;
  final String? labelRequired;
  final Object? defaultValue;
  final WbDataSource? dataSource;
  final String? textRef; // geo选择框 文本关联输入框
  bool disabled; // ui 禁用只是展示

  WbItemCfg({
    required this.type,
    required this.vtype,
    required this.id,
    this.title,
    this.dataMinLength = 0,
    this.minLength = 0,
    this.dataMaxLength = 0,
    this.maxLength = 0,
    this.minValue,
    this.maxValue,
    this.decimalPrecision,
    this.allowBlank = true,
    this.hintText,
    this.labelRequired,
    this.defaultValue,
    this.dataSource,
    this.textRef,
    this.disabled = false,
  });

  static WbItemCfg fromMap(Map<String, dynamic> itemCfg) {
    var defaultValue;
    WbItemType type;
    switch (itemCfg["ui"]) {
      case "text":
        type = WbItemType.text;
        break;
      case "date":
        type = WbItemType.date;
        if (itemCfg['appDefault'] == 'now') defaultValue = DateTime.now();
        break;
      case "datetime":
        type = WbItemType.datetime;
        if (itemCfg['appDefault'] == 'now') defaultValue = DateTime.now();
        break;
      case "optionpicker":
        type = WbItemType.optionpicker;
        if (itemCfg['appDefault'] == 'lastName')
          defaultValue = Application.userLoginModel.lastName;
        if (itemCfg['appDefault'] == 'userLoginId')
          defaultValue = Application.userLoginModel.userLoginId;
        break;
      case "multioptionpicker":
        type = WbItemType.multioptionpicker;
        break;
      case "multiobject":
        type = WbItemType.multiobject;
        break;
      case "radiogroup":
        type = WbItemType.radiogroup;
        break;
      case "checkboxgroup":
        type = WbItemType.checkboxgroup;
        break;
      case "geopicker":
        type = WbItemType.geopicker;
        break;
      default:
        type = WbItemType.unknow;
        break;
    }

    WbItemVType vtype;
    switch (itemCfg["vtype"]) {
      case "email":
        vtype = WbItemVType.email;
        break;
      case "url":
        vtype = WbItemVType.url;
        break;
      case "date":
        vtype = WbItemVType.date;
        break;
      case "datetime":
        vtype = WbItemVType.datetime;
        break;
      case "digits":
        vtype = WbItemVType.digits;
        break;
      case "num":
      case "number":
        vtype = WbItemVType.number;
        break;
      case "phone":
      case "mphone":
        vtype = WbItemVType.mphone;
        break;
      case "tphone":
        vtype = WbItemVType.tphone;
        break;
      case "postal":
        vtype = WbItemVType.postal;
        break;
      case "sfz":
        vtype = WbItemVType.sfz;
        break;
      default:
        vtype = WbItemVType.unknow;
        break;
    }

    WbDataSource? dataSource;
    if (itemCfg.containsKey("dataSource")) {
      Map<String, dynamic> datatemp = {};
      for (String k in itemCfg["dataSource"].keys) {
        datatemp[ReCase(k).camelCase] = itemCfg["dataSource"][k];
      }
      dataSource = WbDataSource(Map<String, dynamic>.from(datatemp));
    }

    var title = itemCfg["title"] ?? itemCfg["name"] ?? '';
    var hintText = itemCfg["hintText"] ?? '请输入$title';

    int dataMinLength = int.tryParse(itemCfg["dataMinLength"] ?? '0') ?? 0;
    int minLength = int.tryParse(itemCfg["minLength"] ?? '0') ?? 0;

    bool allowBlank = 'false' == itemCfg["allowBlank"] ? false : true;
    if (allowBlank && (dataMinLength > 0 || minLength > 0)) allowBlank = false;

    var labelRequired = allowBlank ? '' : '*';

    return WbItemCfg(
      type: type,
      vtype: vtype,
      id: itemCfg["id"] ?? '',
      title: title,
      dataMinLength: dataMinLength,
      dataMaxLength: int.tryParse(itemCfg["dataMaxLength"] ?? '0') ?? 0,
      minLength: minLength,
      maxLength: int.tryParse(itemCfg["maxLength"] ?? '0') ?? 0,
      allowBlank: allowBlank,
      hintText: hintText,
      labelRequired: labelRequired,
      defaultValue: defaultValue ?? itemCfg['default'],
      dataSource: dataSource,
      textRef: itemCfg['textRef'] ?? itemCfg['text-ref'] ?? '',
      minValue: num.tryParse(itemCfg['minValue'] ?? '0'),
      maxValue: num.tryParse(itemCfg['maxValue'] ?? '9999999999'),
      decimalPrecision:
          num.tryParse(itemCfg['decimalPrecision'] ?? '0')?.toInt(),
      disabled: ("true" == itemCfg['disabled']) ? true : false,
    );
  }
}
