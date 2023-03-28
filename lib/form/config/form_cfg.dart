import 'package:flutter/widgets.dart';

import '../../flutter_form_builder/form_builder.dart';
import '../index.dart';

class WbFormPageCfg {
  String _title = '';
  final Map<String, dynamic> _doc = {};
  Map<String, dynamic> _orgForm = {};
  final List<WbFormCfg> _children = [];
  List<WbFormCfg> get children => _children;
  String get title => _title;
  int get childrenSize => _children.length;
  Map<String, dynamic> get orgForm => _orgForm;

  Map<String, Object?> getDocValues(List<String> keys) {
    Map<String, Object?> result = Map();
    for (var key in keys) {
      if (_doc.containsKey(key)) result[key] = _doc[key];
    }
    return result;
  }

  Map<String, dynamic> get doc => _doc;
  set doc(Map<String, dynamic> map) {
    if (ObjectUtil.isNotEmpty(map)) _doc.addAll(map);
  }

  WbFormPageCfg(Map<String, dynamic> cfg, {title = "表单页面"}) {
    _title = title;
    cfg.forEach((String k, dynamic v) {
      if ('orgDoc' == k) {
        _orgForm = v;
      } else {
        WbFormCfg itemCfg = WbFormCfg({'children': v, 'title': k});
        _children.add(itemCfg);
      }
    });
  }
}

class WbFormCfg {
  List<WbItemCfg> _children = [];
  String title = '';
  bool isExpanded = false;
  bool isValidated = false;
  GlobalKey<FormBuilderState>? fbKey;

  List<WbItemCfg> get children => _children;
  int get childrenSize => _children.length;

  WbFormCfg(Map<String, dynamic> cfg) {
    List<Map<String, dynamic>> list = cfg['children'] ?? [];
    title = cfg['title'];
    for (Map<String, dynamic> map in list) {
      if (map["ui"] == 'multiobject') {
        map.forEach((k, v) {
          if (!(v is String)) {
            v['id'] = k;
            WbItemCfg itemCfg = WbItemCfg.fromMap(v);
            _children.add(itemCfg);
          }
        });
      } else {
        WbItemCfg itemCfg = WbItemCfg.fromMap(map);
        _children.add(itemCfg);
      }
    }
    fbKey = GlobalKey<FormBuilderState>();
  }

  Map<String, dynamic> get defaultValues {
    Map<String, dynamic> result = {};

    children.map((itemCfg) {
      if (itemCfg.defaultValue != null) {
        result[itemCfg.id] = itemCfg.defaultValue;
      }
      return null;
    });

    return result;
  }
}
