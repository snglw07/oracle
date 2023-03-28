import 'package:cool_ui/cool_ui.dart';
import 'package:flutter/material.dart';

import '../../flutter_form_builder/form_builder.dart';
import '../index.dart';

class WbMainFormWidget extends StatefulWidget {
  final WbFormPageCfg pageCfg;
  WbMainFormWidget(this.pageCfg);
  @override
  WbMainFormWidgetState createState() => WbMainFormWidgetState(pageCfg);
}

class WbMainFormWidgetState extends State<WbMainFormWidget>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final GlobalKey<FormBuilderState> mainfbKey = GlobalKey<FormBuilderState>();
  final WbFormPageCfg? pageCfg;
  TabController? _tabController;

  WbMainFormWidgetState(this.pageCfg);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    pageCfg?.children.retainWhere((WbFormCfg form) => form.title != 'hidden');
    _tabController =
        TabController(length: pageCfg?.children.length ?? 0, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    var tabs = pageCfg?.children
            .map((WbFormCfg form) => Tab(text: form.title))
            .toList() ??
        [];
    return Scaffold(
        appBar: AppBar(
            title: Text(pageCfg?.title ?? ""),
            bottom: TabBar(controller: _tabController, tabs: tabs)),
        body: TabBarView(
            controller: _tabController,
            children: pageCfg?.children.map((WbFormCfg form) {
                  return SafeArea(
                      top: false,
                      bottom: false,
                      child: Builder(builder: (BuildContext context) {
                        return Center(child: WbFormWidget(form, mainfbKey));
                      }));
                }).toList() ??
                []));
  }
}

class WbFormWidget extends StatefulWidget {
  static Map<WbItemType, WbItemBuilder> _itemBuilders = {};

  final WbFormCfg formCfg;
  final GlobalKey<FormBuilderState> mainfbKey;

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
      GlobalKey<FormBuilderState> fbKey,
      {Function(String key, Object? value)? updateFunc}) {
    if (!_itemBuilders.containsKey(itemCfg.type)) return null;
    var builder = _itemBuilders[itemCfg.type];

    return builder?.build(context, formCfg, itemCfg,
        fbKey: fbKey, updateFunc: updateFunc);
  }

  WbFormWidget(this.formCfg, this.mainfbKey) {
    _initDefaultItemBuilder();
  }

  @override
  WbFormWidgetState createState() => WbFormWidgetState(mainfbKey);
}

class WbFormWidgetState extends State<WbFormWidget>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<FormBuilderState> mainfbKey;
  final GlobalKey<FormBuilderState> _subFbKey = GlobalKey<FormBuilderState>();

  WbFormWidgetState(this.mainfbKey);

  @override
  bool get wantKeepAlive => true;
  void onTest() {
    showWeuiSuccessToast(context: context);
  }

  Widget buildBottomButtons(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: MaterialButton(
            //color: Theme.of(context).accentColor,
            child: Text(
              "Submit",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              _subFbKey.currentState?.save();

              if (_subFbKey.currentState?.validate() == true) {
                print(_subFbKey.currentState?.value);
              } else {
                print(_subFbKey.currentState?.value);
                print("validation failed");
              }
            },
          ),
        ),
        SizedBox(
          width: 20,
        ),
        Expanded(
          child: MaterialButton(
            //color: Theme.of(context).accentColor,
            child: Text(
              "Test",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              onTest();
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FormBuilder(
        // context,
        key: _subFbKey,
        //autovalidate: true,
        initialValue: widget.formCfg.defaultValues,
        child: ListView.builder(
            itemCount: widget.formCfg.childrenSize + 1,
            itemBuilder: (BuildContext context, int position) {
              if (position == widget.formCfg.childrenSize) {
                return buildBottomButtons(context);
              } else {
                var itemCfg = widget.formCfg.children[position];
                return widget.buildItem(context, itemCfg, _subFbKey,
                    updateFunc: (String key, Object? value) async =>
                        this.setState(() {}));
              }
            })); //返回当前页面
  }
}
