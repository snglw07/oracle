import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:wbyq/form/index.dart';
import 'package:intl/intl.dart' as intl;

import '../../flutter_form_builder/fields/form_builder_date_time_picker.dart';
import '../../flutter_form_builder/fields/form_builder_text_field.dart';

class HeaderDate extends StatefulWidget {
  final String labelText;
  final String attribute;
  final DateTime? initialValue;
  final Function(DateTime date) onChanged;
  final String name;
  const HeaderDate(
      {required this.name,
      required this.labelText,
      required this.attribute,
      required this.onChanged,
      this.initialValue,
      Key? key})
      : super(key: key);

  @override
  HeaderDateState createState() => HeaderDateState();
}

class HeaderDateState extends State<HeaderDate> {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(top: 10),
        child: FormBuilderDateTimePicker(
            name: widget.name,
            //readOnly: true,
            initialValue: widget.initialValue ?? DateTime.now(),
            initialDate: DateTime.now(),
            firstDate: DateTime(1910, 1),
            lastDate: DateTime(2050, 12),
            initialDatePickerMode: DatePickerMode.day,
            textCapitalization: TextCapitalization.none,
            inputType: InputType.date,
            format: intl.DateFormat("yyyy-MM-dd"),
            decoration:
                InputDecoration(labelText: '${widget.labelText ?? "请选择日期"}'),
            //attribute: widget.attribute,
            onChanged: (DateTime? date) {
              widget.onChanged(date ?? DateTime.now());
            }));
  }
}

class HeaderSelect extends StatefulWidget {
  final String labelText;
  final String attribute;
  final String? initialValue;

  /// 为空时候默认值
  final String nullValue;
  final List<Map<String, String>> dataSource;
  final Function(String value) onChanged;
  const HeaderSelect({
    required this.labelText,
    required this.attribute,
    required this.dataSource,
    required this.onChanged,
    this.initialValue = '',
    this.nullValue = '',
    Key? key,
  }) : super(key: key);

  @override
  HeaderSelectState createState() => HeaderSelectState();
}

class HeaderSelectState extends State<HeaderSelect> {
  @override
  Widget build(BuildContext context) {
    String? hintText = "请选择${widget.labelText}";
    if (ObjectUtil.isNotEmpty(widget.initialValue)) {
      hintText = widget.dataSource.firstWhere((Map<String, String> m) {
        return m['key'] == (widget.initialValue ?? widget.nullValue);
      })['value'];
    }

    return Container(
      padding: const EdgeInsets.only(top: 10),
      /*child: FormBuilderCustomField(
            attribute: widget.attribute,
            formField: FormField(
                initialValue: widget.initialValue,
                builder: (FormFieldState<dynamic> field) {
                  return InputDecorator(
                      decoration: InputDecoration(
                          labelText: widget.labelText,
                          hintText: hintText,
                          hintStyle:
                              TextStyle(fontSize: 14, color: Colors.grey),
                          contentPadding: EdgeInsets.only(top: 5, bottom: 0),
                          suffixIcon: IconButton(
                              icon: Icon(Icons.close, size: 20),
                              onPressed: () {
                                widget.onChanged(widget.nullValue ?? '');
                              })),
                      child: InkWell(
                          child: Container(
                              padding: EdgeInsets.only(top: 5, bottom: 5),
                              child: Text(hintText ?? "")),
                          onTap: () {
                            showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  if (widget.dataSource.length == 0)
                                    return Container(
                                        alignment: Alignment.center,
                                        height: 100,
                                        child: Text("无可选项"));

                                  return Column(children: <Widget>[
                                    Container(
                                        decoration: BoxDecoration(
                                            border: Border(
                                                bottom: BorderSide(
                                                    color: Colors.grey[300]
                                                        .withOpacity(0.4),
                                                    width: 2.0))),
                                        height: 50.0,
                                        child: Row(children: <Widget>[
                                          Expanded(flex: 1, child: Container()),
                                          Expanded(
                                              flex: 3,
                                              child: Container(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                      '请选择${widget.labelText}',
                                                      style: TextStyle(
                                                          fontSize: 16)))),
                                          Expanded(
                                              flex: 1,
                                              child: Container(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: MaterialButton(
                                                      child: Text('取消',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .green)),
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(null);
                                                      })))
                                        ])),
                                    Expanded(
                                        flex: 1,
                                        child: Container(
                                            child: ListView(
                                                children: widget.dataSource.map(
                                                    (Map<String, String> data) {
                                          return Container(
                                              decoration: BoxDecoration(
                                                  border: Border(
                                                      bottom: BorderSide(
                                                          color: Colors
                                                              .grey[300]
                                                              .withOpacity(0.4),
                                                          width: 2.0))),
                                              child: ListTile(
                                                  title: Text(data["value"],
                                                      style: TextStyle(
                                                          fontSize: 15),
                                                      textAlign:
                                                          TextAlign.center),
                                                  onTap: () {
                                                    Navigator.of(context)
                                                        .pop(data);
                                                  }));
                                        }).toList())))
                                  ]);
                                }).then((data) {
                              if (null != data)
                                widget.onChanged(data['key']);
                              else
                                widget.onChanged(widget.nullValue ?? '');
                            });
                          }));
                }))*/
    );
  }
}

class HeaderText extends StatefulWidget {
  final String name;
  final String labelText;
  final String hintText;
  final String attribute;
  final String initialValue;
  final Function(dynamic val) onChanged;
  const HeaderText(
      {required this.name,
      required this.labelText,
      required this.attribute,
      required this.onChanged,
      this.hintText = "",
      this.initialValue = "",
      Key? key})
      : super(key: key);

  @override
  HeaderTextState createState() => HeaderTextState();
}

class HeaderTextState extends State<HeaderText> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: FormBuilderTextField(
            name: widget.name,
            //attribute: widget.attribute,
            initialValue: widget.initialValue,
            style: TextStyle(fontSize: 16, height: 1),
            decoration: InputDecoration(
                labelText: '${widget.labelText}', hintText: widget.hintText),
            onChanged: (val) {
              widget.onChanged(val);
            }));
  }
}
