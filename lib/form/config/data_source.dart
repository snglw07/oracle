import '../index.dart';

class WbDataSource {
  String? _url;
  String? _textField;
  String? _valueField;
  List? _dataList; //<Map<String,dynamic>>

  String? get textField => _textField;
  String? get valueField => _valueField;

  WbDataSource(Map<String, dynamic> cfg) {
    _url = cfg["url"];
    _textField = cfg["textField"];
    _valueField = cfg["valueField"];
    if (ObjectUtil.isNotEmpty(cfg["ds"])) {
      _dataList = cfg["ds"];
    } else {
      getDataSource().then((json) {
        _dataList = json;
      });
    }
  }

  Future<List> getDataSource({Map<String, dynamic>? params}) async {
    if (_dataList != null) return _dataList!;
    _dataList = [];
    Map<String, dynamic> map = await WbFormApi.systemEnum(_url ?? "");
    if (ObjectUtil.isNotEmpty(map) && map.containsKey("data")) {
      List<Map<String, dynamic>> list =
          map['data'] as List<Map<String, dynamic>>;

      for (var it in list) {
        Map<String, dynamic> imap = Map<String, dynamic>.of(it);
        Map m = {'id': imap['enumId'], ...imap};
        _dataList?.add(m);
      }
    }
    return _dataList ?? [];
  }
}
