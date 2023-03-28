import 'package:flutter/material.dart';

import '../../flutter_form_builder/form_builder.dart';
import '../index.dart';

class WbPageWidget extends StatefulWidget {
  /// 页面配置信息
  final WbFormPageCfg pageCfg;

  /// 页面数据
  final Map<String, dynamic>? pageData;

  /// 页面提交地址
  final String? submitUri;

  /// 是否只读
  final bool readOnly;

  /// 是否页面充填
  final bool refill;

  /// 提交前校验函数
  final String Function(BuildContext context)? beforeSubmit;

  /// 提交函数
  final Function(BuildContext context, Map<String, dynamic> submitResult)?
      afterSubmit;

  /// 表单项变化事件
  final Function(BuildContext context, String key, Object? value,
      Map<String, dynamic> doc)? itemChange;
  const WbPageWidget(this.pageCfg, this.pageData,
      {super.key,
      this.submitUri,
      this.readOnly = false,
      this.refill = false,
      this.beforeSubmit,
      this.afterSubmit,
      this.itemChange});

  @override
  WbPageWidgetState createState() => WbPageWidgetState();
}

class WbPageWidgetState extends State<WbPageWidget>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (ObjectUtil.isNotEmpty(widget.pageData)) {
      setState(() {
        widget.pageCfg.doc.addAll(widget.pageData!);
      });
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.pageCfg.children.forEach((WbFormCfg iformCfg) {
        if (null != iformCfg.fbKey?.currentState &&
            iformCfg.fbKey?.currentState?.validate() == true) {
          iformCfg.isValidated = true;
        }
        if (widget.readOnly || widget.refill) {
          iformCfg.isValidated = true;
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget getRow(int i, WbFormCfg formCfg) {
    return GestureDetector(
        child: Container(
            child: ListTile(
                title: Row(children: [
                  Expanded(
                      child: Text(formCfg.title,
                          style: TextStyle(color: Colors.black))),
                  formCfg.isValidated
                      ? Icon(Icons.check_circle_outline, color: Colors.green)
                      : Container()
                ]),
                trailing: Icon(Icons.chevron_right, color: Colors.black))),
        onTap: () {
          onRowTap(formCfg);
        });
  }

  onRowTap(WbFormCfg formCfg) {
    NavigatorUtil.pushPage(context, renderSubPage(formCfg)).then((subDoc) {
      if (formCfg.fbKey?.currentState?.validate() == true) {
        setState(() {
          formCfg.isValidated = true;
          widget.pageCfg.doc = formCfg.fbKey!.currentState!.value;
        });
      } else {
        setState(() {
          formCfg.isValidated = false;
        });
      }
    });
  }

  /// 点击标题 调整渲染下级界面
  Widget renderSubPage(WbFormCfg formCfg) {
    /// 获取表单当前存在page.doc中的值
    Map<String, dynamic> formValues = Map.from(widget.pageData ?? Map())
      ..addAll(formCfg.defaultValues)
      ..addAll(widget.pageCfg
          .getDocValues(formCfg.children.map((it) => it.id).toList()));

    return Scaffold(
        appBar: AppBar(title: Text(formCfg.title)),
        body: Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: WbFormWidget(
                widget.pageCfg, formCfg, formValues, widget.itemChange)));
  }

  canSubmit() {
    if (widget.readOnly) return false;

    bool canSubmit = true;
    for (WbFormCfg formCfg in widget.pageCfg.children) {
      if (!formCfg.isValidated) {
        canSubmit = false;
      }
    }
    return canSubmit;
  }

  onSubmit() {
    print(widget.pageCfg.doc);
    if (!canSubmit()) {
      Notify.error("请确保各项都验证通过后再保存。", context: context);
      return;
    }
    if (ObjectUtil.isEmpty(widget.submitUri)) {
      Notify.error("缺少页面提交地址。", context: context);
      return;
    }
    if (ObjectUtil.isNotEmpty(widget.beforeSubmit) &&
        widget.beforeSubmit is Function) {
      String before = widget.beforeSubmit!(context);
      if (ObjectUtil.isNotEmpty(before)) {
        Notify.error(before, context: context);
        return;
      }
    }
    doSubmit();
  }

  doSubmit() async {
    if (ObjectUtil.isNotEmpty(widget.afterSubmit) &&
        widget.afterSubmit is Function) {
      widget.afterSubmit!(context, {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    widget.pageCfg.children.retainWhere((cfg) => cfg.title != 'hidden');
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.pageCfg.title),
            centerTitle: true,
            actions: [
              widget.readOnly
                  ? Container()
                  : Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                          width: 64.0,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    canSubmit() ? Colors.green : Colors.grey,
                              ),
                              child:
                                  Text("保存", style: TextStyle(fontSize: 12.0)),
                              onPressed: () {
                                onSubmit();
                              })))
            ]),
        body: Container(
            height: 1000,
            child: ListView.builder(
                itemCount: widget.pageCfg.childrenSize,
                itemBuilder: (BuildContext context, int index) {
                  return getRow(index, widget.pageCfg.children[index]);
                })));
  }
}

class WbFormWidget extends StatefulWidget {
  @override
  WbFormWidgetState createState() => WbFormWidgetState();

  static Map<WbItemType, WbItemBuilder> _itemBuilders = {};
  final WbFormPageCfg pageCfg;
  final WbFormCfg formCfg;
  final Map<String, dynamic> formValues;
  final Function(BuildContext context, String key, Object? value,
      Map<String, dynamic> doc)? itemChange;

  static void register(WbItemType type, WbItemBuilder builder) {
    _initDefaultItemBuilder();
    _itemBuilders[type] = builder;
  }

  static void _initDefaultItemBuilder() {
    if (_itemBuilders.length > 0) return;

    _itemBuilders[WbItemType.text] = WbTextInputBuilder();
    _itemBuilders[WbItemType.date] = WbDatePickerBuilder();
    _itemBuilders[WbItemType.geopicker] = WbGeoPickerBuilder();
    _itemBuilders[WbItemType.optionpicker] = WbOptionPickerBuilder();
    _itemBuilders[WbItemType.multioptionpicker] =
        WbMultipleOptionPickerBuilder();
  }

  Widget? buildItem(BuildContext context, WbItemCfg itemCfg,
      GlobalKey<FormBuilderState>? fbKey, Object value,
      {Function(String key, Object? value)? updateFunc}) {
    if (!_itemBuilders.containsKey(itemCfg.type)) return null;
    var builder = _itemBuilders[itemCfg.type];

    return builder?.build(context, formCfg, itemCfg,
        fbKey: fbKey, fbValue: value, updateFunc: updateFunc);
  }

  WbFormWidget(this.pageCfg, this.formCfg, this.formValues, this.itemChange) {
    _initDefaultItemBuilder();
  }
}

class WbFormWidgetState extends State<WbFormWidget>
    with AutomaticKeepAliveClientMixin {
  GlobalKey<FormBuilderState>? _subFbKey;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _subFbKey = widget.formCfg.fbKey;
  }

  @override
  void dispose() {
    //CoolKeyboard.dispose();
    super.dispose();
  }

  Widget buildBottomButtons(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(top: 12, bottom: 100),
        child: Row(children: <Widget>[
          Expanded(
              child: MaterialButton(
                  //color: Theme.of(context).accentColor,
                  child: Text("确定", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    _subFbKey?.currentState?.save();
                    if (_subFbKey?.currentState?.validate() == true) {
                      Map<String, Object?> map = Map();
                      map['isValidated'] = true;
                      map['doc'] = _subFbKey?.currentState?.value;
                      Navigator.pop(context, map);
                    } else {
                      Notify.error("请确认无误后点击确定。", context: context);
                    }
                  }))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FormBuilder(
        key: _subFbKey,
        //autovalidate: true,
        initialValue: ObjectUtil.isNotEmpty(widget.formValues)
            ? widget.formValues
            : widget.formCfg.defaultValues,
        child: ListView.builder(
            itemCount: widget.formCfg.childrenSize + 1,
            itemBuilder: (BuildContext context, int position) {
              if (position == widget.formCfg.childrenSize) {
                return buildBottomButtons(context);
              } else {
                var itemCfg = widget.formCfg.children[position];
                return widget.buildItem(
                    context,
                    itemCfg,
                    _subFbKey,
                    widget.pageCfg.doc[itemCfg.id] ??
                        widget.formValues[itemCfg.id],
                    updateFunc: (String key, Object? value) async {
                  print("key---" + key + " value---->" + value.toString());
                  if (ObjectUtil.isNotEmpty(widget.itemChange))
                    widget.itemChange!(context, key, value, widget.pageCfg.doc);

                  this.setState(() => {widget.pageCfg.doc});
                });
              }
            }));
  }
}
