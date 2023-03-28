import 'package:flutter/material.dart';

import '../../flutter_form_builder/form_builder.dart';
import '../../form_builder_validators/form_builder_validators.dart';
import '../index.dart';

class WbMultipleOptionPickerBuilder implements WbItemBuilder {
  Widget buildBottomSheet(BuildContext context, WbItemCfg itemCfg,
      FormFieldState field, List dataList, WbItemDataCallBack cb) {
    String hintText = "请选择${itemCfg.title ?? ''}";
    List hintTextList = [];
    var value = field.value;
    if (ObjectUtil.isNotEmpty(value) && value is List) {
      for (var itemInValue in value) {
        var itemInDataSource = dataList.firstWhere(
            (kv) => (kv[itemCfg.dataSource?.valueField] == itemInValue),
            orElse: () => null);
        if (itemInDataSource != null) {
          hintTextList.add(itemInDataSource[itemCfg.dataSource?.textField]);
        }
      }
      if (ObjectUtil.isNotEmpty(hintTextList)) {
        hintText = hintTextList.join("、");
      }
    }

    Widget buildSheetHeader() {
      return Container(
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: Colors.grey[300]?.withOpacity(0.4) ?? Colors.green,
                      width: 2.0))),
          height: 60.0,
          child: Row(children: <Widget>[
            Expanded(flex: 1, child: Container()),
            Expanded(
                flex: 3,
                child: Container(
                    alignment: Alignment.center,
                    child: Text('请选择${itemCfg.title}',
                        style: const TextStyle(fontSize: 16)))),
            Expanded(
                flex: 1,
                child: MaterialButton(
                    child: const Text('确认',
                        style: TextStyle(
                            //color: Theme.of(context).accentColor
                            )),
                    onPressed: () {
                      Navigator.of(context).pop(null);
                    }))
          ]));
    }

    onTapBtn() {
      showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            if (dataList.isEmpty) {
              return Container(
                  alignment: Alignment.center,
                  height: 100,
                  child: const Text("无可选项"));
            }

            return StatefulBuilder(builder: (context1, state) {
              Widget buildListItem(data) {
                return ListTile(
                    contentPadding: const EdgeInsets.only(left: 12, right: 24),
                    trailing: (field.value is List &&
                            field.value
                                .contains(data[itemCfg.dataSource?.valueField]))
                        ? const Icon(Icons.check_box, color: Colors.green)
                        : const Icon(Icons.check_box_outline_blank),
                    title: Text(data[itemCfg.dataSource?.textField],
                        textAlign: TextAlign.center),
                    onTap: () {
                      cb(data);
                      state(() {});
                    });
              }

              return Column(children: <Widget>[
                buildSheetHeader(),
                Expanded(
                    flex: 1,
                    child: ListView(
                        children: dataList.map((var data) {
                      return Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color:
                                          Colors.grey[300]?.withOpacity(0.4) ??
                                              Colors.green,
                                      width: 2.0))),
                          child: buildListItem(data));
                    }).toList()))
              ]);
            });
          });
    }

    return InkWell(
        child: Container(
            padding: const EdgeInsets.only(top: 5, bottom: 5),
            child: ObjectUtil.isEmpty(field.value)
                ? Text(hintText,
                    style: const TextStyle(fontSize: 14, color: Colors.grey))
                : Text(hintText, style: const TextStyle(fontSize: 18))),
        onTap: () {
          onTapBtn();
        });
  }

  FutureBuilder makeBuilder(
      WbItemCfg itemCfg, FormFieldState<dynamic> field, WbItemDataCallBack cb) {
    return FutureBuilder<List>(
      future: itemCfg.dataSource?.getDataSource(),
      builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
        if (!snapshot.hasData) return const Text("无数据");

        return buildBottomSheet(
            field.context, itemCfg, field, snapshot.data!, cb);
      },
    );
  }

  @override
  Widget? build(BuildContext context, WbFormCfg formCfg, WbItemCfg itemCfg,
      {GlobalKey<FormBuilderState>? fbKey,
      Object? fbValue,
      Function(String key, Object? value)? updateFunc}) {
    List<FormFieldValidator> validators = [];
    if (!itemCfg.allowBlank) {
      var errorText = "${itemCfg.title}不能为空";
      validators.add(FormBuilderValidators.required(errorText: errorText));
    }

    /// 更新关联表单项的可用禁用状态 一般是选择项中其他项被选择的时候，其他项的录入表单项会允许输入

    /// 值选择之后的回调函数 处理互斥 关联表单项更新

    return null;

    /*return FormBuilderCustomField(
        attribute: itemCfg.id,
        validators: validators,
        formField: FormField(
            enabled: true,
            builder: (FormFieldState<dynamic> field) {
              return InputDecorator(
                  decoration: InputDecoration(
                      labelText: '${itemCfg.title}${itemCfg.labelRequired}',
                      hintText: itemCfg.hintText,
                      hintStyle: TextStyle(fontSize: 14, color: Colors.black),
                      contentPadding: EdgeInsets.only(top: 5.0, bottom: 0),
                      errorText: field.errorText,
                      suffixIcon: field.value != null && itemCfg.allowBlank
                          ? IconButton(
                              icon: Icon(Icons.close, size: 20),
                              onPressed: () {
                                field.didChange(null);
                              })
                          : Container(width: 0, height: 0)),
                  child: makeBuilder(itemCfg, field, (data) {
                    valueSelectCb(itemCfg, field, data);
                  }));
            }));*/
  }
}
