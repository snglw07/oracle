import 'package:city_pickers/city_pickers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wbyq/common/component_index.dart' as ob;
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/res/styles.dart';
import 'package:wbyq/ui/widgets/show_bottom_multi_sheet.dart';
import 'package:wbyq/utils/navigator_util.dart';

class ITextFieldItem extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final String? inputText;
  final ValueChanged<String>? onChange;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool requiredValue;
  final bool enabled;
  final int flex1;
  final int flex2;
  final int flex3;
  final Widget? appendWidget;
  const ITextFieldItem(
      {Key? key,
      this.labelText = '',
      this.hintText,
      this.onChange,
      this.keyboardType,
      this.inputText,
      this.maxLength,
      this.requiredValue = false,
      this.enabled = true,
      this.appendWidget,
      this.flex1 = 1,
      this.flex2 = 2,
      this.flex3 = 0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: Decorations.bottom2,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Expanded(
              flex: flex1,
              child: Row(children: <Widget>[
                requiredValue
                    ? Text("*",
                        style: TextStyle(fontSize: 16, color: Colors.red))
                    : Container(),
                Text(labelText,
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis)
              ])),
          Expanded(
              flex: flex2,
              child: TextField(
                  keyboardType: keyboardType,
                  readOnly: !enabled,
                  maxLength: maxLength ?? null,
                  controller: TextEditingController.fromValue(
                      TextEditingValue(text: inputText ?? "")),
                  decoration: InputDecoration(
                      hintText:
                          ob.ObjectUtil.isEmpty(hintText) ? '请输入' : hintText,
                      hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                      border: InputBorder.none),
                  onChanged: (value) {
                    if (onChange != null) onChange!(value);
                  })),
          Expanded(flex: flex3, child: this.appendWidget ?? Text(""))
        ]));
  }
}

class ShowBottomSheet extends StatelessWidget {
  final Widget? hintText;
  final List? dataList; //填充数据
  final ValueChanged<dynamic> callBack;
  final bool enabled;
  const ShowBottomSheet({
    Key? key,
    this.hintText,
    this.dataList,
    required this.callBack,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        child: hintText,
        onTap: !enabled
            ? null
            : () {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      if (dataList?.length == 0)
                        return Container(
                            alignment: Alignment.center,
                            height: 100,
                            child: Text("无可选项"));

                      return Column(children: <Widget>[
                        Container(
                            decoration: Decorations.bottom2,
                            height: 60.0,
                            child: Row(children: <Widget>[
                              Expanded(flex: 1, child: Text('')),
                              Expanded(
                                  flex: 3,
                                  child: Container(
                                      alignment: Alignment.center,
                                      child: Text('请选择',
                                          style: TextStyle(fontSize: 16)))),
                              Expanded(
                                  flex: 1,
                                  child: Container(
                                      alignment: Alignment.centerRight,
                                      child: MaterialButton(
                                          child: Text('取消',
                                              style: TextStyle(
                                                  color: Colors.green)),
                                          onPressed: () {
                                            Navigator.of(context).pop({
                                              'description': '',
                                              'value': ''
                                            });
                                          })))
                            ])),
                        Expanded(
                            flex: 1,
                            child: Container(
                                child: ListView(
                                    children: dataList?.map((var data) {
                                          return Container(
                                              decoration: Decorations.bottom2,
                                              padding: EdgeInsets.only(
                                                  left: 24, right: 24),
                                              child: ListTile(
                                                  title: Text(
                                                      (data["description"] ??
                                                              data["text"]) ??
                                                          data["label"],
                                                      textAlign:
                                                          TextAlign.center),
                                                  onTap: () {
                                                    Navigator.of(context)
                                                        .pop(data);
                                                  }));
                                        }).toList() ??
                                        [])))
                      ]);
                    }).then((data) {
                  callBack(data);
                });
              });
  }
}

class IInputDropdown extends StatelessWidget {
  const IInputDropdown({
    Key? key,
    this.child,
    this.labelText,
    required this.valueText,
    this.valueStyle,
    required this.onPressed,
  }) : super(key: key);

  final String? labelText;
  final String valueText;
  final TextStyle? valueStyle;
  final VoidCallback onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onPressed,
        child: InputDecorator(
            decoration:
                InputDecoration(labelText: labelText, border: InputBorder.none),
            baseStyle: valueStyle,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(valueText, style: valueStyle),
                  Icon(Icons.arrow_drop_down,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade700
                          : Colors.white70)
                ])));
  }
}

class IDatePicker extends StatelessWidget {
  const IDatePicker({
    Key? key,
    this.labelText,
    required this.selectedDate,
    required this.selectDate,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  final String? labelText;
  final DateTime selectedDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> selectDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime(2015, 8),
      lastDate: lastDate ?? DateTime(2101),
    );
    if (picked != null && picked != selectedDate) selectDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
      Expanded(
          flex: 1,
          child: IInputDropdown(
              valueText: DateFormat("yyyy-MM-dd").format(selectedDate),
              valueStyle: TextStyle(fontSize: 14),
              onPressed: () {
                _selectDate(context);
              }))
    ]);
  }
}

class ITimePicker extends StatelessWidget {
  const ITimePicker({
    Key? key,
    this.labelText,
    required this.selectedTime,
    required this.selectTime,
  }) : super(key: key);

  final String? labelText;
  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> selectTime;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: selectedTime);
    if (picked != null) selectTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
      Expanded(
          flex: 1,
          child: IInputDropdown(
              valueText: null != selectedTime
                  ? "${selectedTime!.hour}时${selectedTime!.minute}分"
                  : '',
              valueStyle: TextStyle(fontSize: 14),
              onPressed: () {
                _selectTime(context);
              }))
    ]);
  }
}

class IFormItem {
  /// 选择枚举内容
  static selectExecType(
      BuildContext context, String rowLabel, String value, String execId,
      {bool requiredValue = false,
      required ValueChanged<Map> cb,
      bool enabled = true,
      int flex1 = 1,
      int flex2 = 2}) {
    return Container(
        height: 48,
        decoration: Decorations.bottom2,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Expanded(
              flex: flex1,
              child: Row(children: <Widget>[
                requiredValue
                    ? const Text("*",
                        style: TextStyle(fontSize: 16, color: Colors.red))
                    : Container(),
                Text(rowLabel,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis)
              ])),
          Expanded(
              flex: flex2,
              child: Container(
                  padding: const EdgeInsets.only(left: 10),
                  child: FutureBuilder(
                      future: WbNetApi.exec(execId),
                      builder: (BuildContext context,
                          AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                        if (!snapshot.hasData) {
                          return const Text("请选择",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14));
                        }

                        List list = (snapshot.data!["exec"] ?? []) as List;
                        var textLabel = '';
                        if (ob.ObjectUtil.isNotEmpty(value)) {
                          var item = list.firstWhere((it) {
                            return (it['value'] ?? it['key']) == value;
                          }, orElse: () => null);
                          if (ob.ObjectUtil.isNotEmpty(item)) {
                            textLabel = (item['description'] ?? item['text']);
                          }
                        }

                        return ShowBottomSheet(
                            hintText: Text(
                                ob.ObjectUtil.isNotEmpty(textLabel)
                                    ? textLabel
                                    : '请选择',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: ob.ObjectUtil.isNotEmpty(value)
                                        ? Colors.black
                                        : Colors.grey),
                                textAlign: TextAlign.start),
                            dataList: list,
                            callBack: (var result) {
                              cb(result);
                            },
                            enabled: enabled);
                      }))),
          const SizedBox(width: 24, child: Icon(Icons.arrow_drop_down))
        ]));
  }

  /// 选择枚举内容
  static selectEnumType(
      BuildContext context, String rowLabel, String value, String enumId,
      {bool requiredValue = false,
      required ValueChanged<Map> cb,
      bool enabled = true,
      int flex1 = 1,
      int flex2 = 2}) {
    return Container(
        height: 48,
        decoration: Decorations.bottom2,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Expanded(
              flex: flex1,
              child: Row(children: <Widget>[
                requiredValue
                    ? const Text("*",
                        style: TextStyle(fontSize: 16, color: Colors.red))
                    : Container(),
                Text(rowLabel,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis)
              ])),
          Expanded(
              flex: flex2,
              child: Container(
                  padding: const EdgeInsets.only(left: 10),
                  child: FutureBuilder(
                      future: WbNetApi.getEnums(enumId),
                      builder: (BuildContext context,
                          AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                        if (!snapshot.hasData) {
                          return const Text("请选择",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14));
                        }

                        List list = (snapshot.data!["exec"] ?? []) as List;
                        var textLabel = '';
                        if (ob.ObjectUtil.isNotEmpty(value)) {
                          var item = list.firstWhere(
                            (it) {
                              return (it['value'] ?? it['key']) == value;
                            },
                            orElse: () => null,
                          );
                          if (ob.ObjectUtil.isNotEmpty(item)) {
                            textLabel = item['description'] ?? item['label'];
                          }
                        }

                        return ShowBottomSheet(
                            hintText: Text(
                                ob.ObjectUtil.isNotEmpty(textLabel)
                                    ? textLabel
                                    : '请选择',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: ob.ObjectUtil.isNotEmpty(value)
                                        ? Colors.black
                                        : Colors.grey),
                                textAlign: TextAlign.start),
                            dataList: list,
                            callBack: (var result) {
                              if (result != null) {
                                cb(result);
                              }
                            },
                            enabled: enabled);
                      }))),
          const SizedBox(width: 24, child: Icon(Icons.arrow_drop_down))
        ]));
  }

  /// 选择自定义内容
  static selectType(BuildContext context, String rowLabel, String value,
      List<Map<String, dynamic>> enums,
      {bool requiredValue = false,
      required ValueChanged<Map> cb,
      bool enabled = true,
      int flex1 = 1,
      int flex2 = 2}) {
    var textLabel = '';
    if (ob.ObjectUtil.isNotEmpty(value)) {
      var item = enums.firstWhere(
        (it) {
          return (it['value'] ?? it['key']) == value;
        },
        orElse: () => <String, dynamic>{},
      );
      if (ob.ObjectUtil.isNotEmpty(item)) {
        textLabel = item['description'] ?? item['label'] ?? "" as dynamic;
      }
    }
    return Container(
        height: 48,
        decoration: Decorations.bottom2,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Expanded(
              flex: flex1,
              child: Row(children: <Widget>[
                requiredValue
                    ? Text("*",
                        style: TextStyle(fontSize: 16, color: Colors.red))
                    : Container(),
                Text(rowLabel,
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis)
              ])),
          Expanded(
              flex: flex2,
              child: Container(
                  padding: EdgeInsets.only(left: 10),
                  child: ShowBottomSheet(
                      hintText: Text(
                          ob.ObjectUtil.isNotEmpty(textLabel)
                              ? textLabel
                              : "请选择",
                          style: TextStyle(
                              fontSize: 16,
                              color: ob.ObjectUtil.isNotEmpty(value)
                                  ? Colors.black
                                  : Colors.grey),
                          textAlign: TextAlign.start),
                      dataList: enums,
                      callBack: (var result) {
                        cb(result);
                      },
                      enabled: enabled))),
          Container(width: 24, child: Icon(Icons.arrow_drop_down))
        ]));
  }

  /// 选择城市
  static selectCity(BuildContext context, String rowLabel, String textLabel,
      String locationCode,
      {bool requiredValue = false, required ValueChanged<Map> cb}) {
    return Container(
        height: 48,
        decoration: Decorations.bottom2,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Expanded(
              flex: 1,
              child: Row(children: <Widget>[
                requiredValue
                    ? Text("*",
                        style: TextStyle(fontSize: 16, color: Colors.red))
                    : Container(),
                Text(rowLabel,
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis)
              ])),
          Expanded(
              flex: 2,
              child: Container(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                    Expanded(
                        flex: 1,
                        child: IInputDropdown(
                            valueText: ob.ObjectUtil.isNotEmpty(textLabel)
                                ? textLabel
                                : "请选择",
                            valueStyle: TextStyle(
                                fontSize: 16,
                                color: ob.ObjectUtil.isNotEmpty(textLabel)
                                    ? Colors.black
                                    : Colors.grey),
                            onPressed: () async {
                              Result? result = await CityPickers.showCityPicker(
                                  context: context,
                                  locationCode: locationCode ?? '500000');
                              cb({"result": result});
                            }))
                  ]))),
        ]));
  }

  /// 选择日期
  static selectDate(
      BuildContext context, String rowLabel, DateTime selectedDate,
      {bool requiredValue = false,
      DateTime? firstDate,
      DateTime? lastDate,
      required ValueChanged<DateTime> cb}) {
    return Container(
        decoration: Decorations.bottom2,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Expanded(
              flex: 1,
              child: Row(children: <Widget>[
                requiredValue
                    ? Text("*",
                        style: TextStyle(fontSize: 16, color: Colors.red))
                    : Container(),
                Text(rowLabel,
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis)
              ])),
          Expanded(
              flex: 2,
              child: IDatePicker(
                  selectedDate: selectedDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  selectDate: (DateTime date) {
                    cb(date);
                  }))
        ]));
  }

  ///选择时间
  static selectTime(
      BuildContext context, String rowLabel, TimeOfDay selectedTime,
      {bool requiredValue = false, required ValueChanged<TimeOfDay> cb}) {
    return Container(
        decoration: Decorations.bottom2,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Expanded(
              flex: 1,
              child: Row(children: <Widget>[
                requiredValue
                    ? Text("*",
                        style: TextStyle(fontSize: 16, color: Colors.red))
                    : Container(),
                Text(rowLabel,
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis)
              ])),
          Expanded(
              flex: 2,
              child: ITimePicker(
                  selectedTime: selectedTime,
                  selectTime: (TimeOfDay date) {
                    cb(date);
                  }))
        ]));
  }

  //下拉多选
  static selectCheckBox(BuildContext context, String rowLabel, String value,
      List<Map<String, dynamic>> enums,
      {bool requiredValue = false,
      required ValueChanged<Map> cb,
      int flex1 = 1,
      int flex2 = 2}) {
    var textLabel = '';
    if (ob.ObjectUtil.isNotEmpty(value)) {
      textLabel = value;
    }
    Widget hintText = Text(
      ob.ObjectUtil.isNotEmpty(textLabel) ? textLabel : "请选择",
      style: TextStyle(
          color:
              ob.ObjectUtil.isNotEmpty(textLabel) ? Colors.black : Colors.grey),
    );
    return Container(
        height: 48,
        decoration: Decorations.bottom2,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Expanded(
              flex: flex1,
              child: Row(children: <Widget>[
                requiredValue
                    ? const Text("*",
                        style: TextStyle(fontSize: 16, color: Colors.red))
                    : Container(),
                Text(rowLabel,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis)
              ])),
          Expanded(
              flex: flex2,
              child: InkWell(
                child: hintText,
                onTap: () {
                  NavigatorUtil.pushPage(
                          context,
                          ShowBottomMultiSheet("选择症状",
                              dataList: enums,
                              selected: ob.ObjectUtil.isEmpty(value)
                                  ? []
                                  : value.split(',')))
                      .then((res) {
                    if (res != null) cb(res!);
                  });
                },
              )),
          const SizedBox(width: 24, child: Icon(Icons.list))
        ]));
  }
}
