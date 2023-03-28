import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:wbyq/form/index.dart';

import '../../flutter_form_builder/form_builder.dart';
import '../../form_builder_validators/form_builder_validators.dart';

typedef WbItemDataCallBack = void Function(dynamic data);

class WbOptionPickerBuilderOptions extends StatefulWidget {
  final BuildContext context;
  final WbItemCfg itemCfg;
  final FormFieldState field;
  final List? dataList;
  final WbItemDataCallBack cb;

  const WbOptionPickerBuilderOptions(
      this.context, this.itemCfg, this.field, this.dataList, this.cb,
      {Key? key})
      : super(key: key);

  @override
  State<WbOptionPickerBuilderOptions> createState() =>
      WbOptionPickerBuilderOptionsState();
}

class WbOptionPickerBuilderOptionsState
    extends State<WbOptionPickerBuilderOptions> {
  String searchKey = '';
  bool showSearch = false;
  @override
  void initState() {
    super.initState();
    showSearch = ObjectUtil.isNotEmpty(widget.dataList) &&
        ((widget.dataList?.length) ?? 0) > 10;
  }

  Widget buildListItem(data) {
    return ListTile(
        contentPadding: EdgeInsets.only(left: 24, right: 24),
        title: Text(data[widget.itemCfg.dataSource?.textField] ?? "",
            textAlign: TextAlign.center),
        onTap: () {
          Navigator.of(context).pop(data);
        });
  }

  searchKeyWordChange(String value) {
    searchKey = value;
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
          Expanded(
              flex: 1,
              child: Container(
                  alignment: Alignment.centerLeft,
                  child: MaterialButton(
                      child: Text('取消',
                          style: TextStyle(
                              //color: Theme.of(context).accentColor
                              )),
                      onPressed: () {
                        Navigator.of(context).pop(widget.field.value);
                      }))),
          Expanded(
              flex: 3,
              child: Container(
                  alignment: Alignment.center,
                  child: showSearch
                      ? TextField(
                          onChanged: (String val) {
                            searchKeyWordChange(val);
                          },
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '输入以过滤${widget.itemCfg.title}',
                              hintStyle: TextStyle(fontSize: 16)))
                      : Text('请选择${widget.itemCfg.title}',
                          style: TextStyle(fontSize: 16)))),
          Expanded(flex: 1, child: Text(""))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    List filterData = [];
    for (var data in List.from(widget.dataList ?? [])) {
      if ("" != searchKey) {
        String text = data[widget.itemCfg.dataSource?.textField];
        String textPy = PinyinHelper.getShortPinyin(text).toUpperCase();

        if (text.indexOf(searchKey) >= 0 ||
            textPy.indexOf(searchKey.toUpperCase()) >= 0) {
          filterData.add(data);
        }
      } else {
        filterData.add(data);
      }
    }

    return Column(children: <Widget>[
      buildSheetHeader(),
      Expanded(
          flex: 1,
          child: Container(
              child: ListView(
                  children: filterData.map((var data) {
            return Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: Colors.grey[300]?.withOpacity(0.4) ??
                                Colors.green,
                            width: 2.0))),
                child: buildListItem(data));
          }).toList())))
    ]);
  }
}

class WbOptionPickerBuilder implements WbItemBuilder {
  FutureBuilder makeBuilder(
      WbItemCfg itemCfg, FormFieldState<dynamic> field, WbItemDataCallBack cb) {
    return FutureBuilder<List>(
        future: itemCfg.dataSource?.getDataSource(),
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          if (!snapshot.hasData) return const Text("无数据");
          String hintText = "请选择${itemCfg.title ?? ''}";
          var item = snapshot.data?.firstWhere(
              (kv) => (kv[itemCfg.dataSource?.valueField] == field.value),
              orElse: () => null);
          if (item != null) hintText = item[itemCfg.dataSource?.textField];
          if (hintText == ("请选择${itemCfg.title ?? ''}") &&
              ObjectUtil.isNotEmpty(field.value) &&
              field.value is String) hintText = field.value;

          return InkWell(
              child: Container(
                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                  child: ObjectUtil.isEmpty(field.value)
                      ? Text(hintText,
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey))
                      : Text(hintText, style: const TextStyle(fontSize: 18))),
              onTap: () {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return WbOptionPickerBuilderOptions(
                          field.context, itemCfg, field, snapshot.data, cb);
                    }).then((data) {
                  if (data is Map) {
                    cb(data);
                  }
                });
              });
        });
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
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                    contentPadding: EdgeInsets.only(top: 5, bottom: 0),
                    errorText: field.errorText,
                    suffixIcon: field.value != null && itemCfg.allowBlank
                        ? IconButton(
                            icon: Icon(Icons.close, size: 20),
                            onPressed: () {
                              field.didChange(null);
                            })
                        : Container(width: 0, height: 0),
                  ),
                  child: makeBuilder(itemCfg, field, (data) {
                    if (null != data)
                      field.didChange(data[itemCfg.dataSource.valueField]);
                    else
                      field.didChange(null);

                    updateFunc(
                        itemCfg.id,
                        null != data
                            ? data[itemCfg.dataSource.valueField]
                            : null);

                    if (FormUtils.canUpdateTextRefKv(itemCfg, fbKey)) {
                      updateRefItems(field);
                    }
                  }));
            }));*/
  }
}
