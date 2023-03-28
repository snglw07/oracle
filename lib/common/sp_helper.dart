import 'package:flustars/flustars.dart';
import 'package:wbyq/common/common.dart';
import 'package:wbyq/models/models.dart';

class SpHelper {
  // T 用于区分存储类型
  static void putObject<T>(String key, dynamic value) {
    switch (T) {
      case int:
        SpUtil.putInt(key, value);
        break;
      case double:
        SpUtil.putDouble(key, value);
        break;
      case bool:
        SpUtil.putBool(key, value);
        break;
      case String:
        SpUtil.putString(key, value);
        break;
      case List:
        SpUtil.putStringList(key, value);
        break;
      default:
        SpUtil.putObject(key, value);
        break;
    }
  }

  static LanguageModel? getLanguageModel() {
    var map = SpUtil.getObject(Constant.keyLanguage);

    var lmap = Map<String, dynamic>();

    map?.forEach((key, value) => lmap[key?.toString() ?? ""] = value);

    return map == null ? null : LanguageModel.fromJson(lmap);
  }

  static String getThemeColor() {
    return SpUtil.getString(Constant.KEY_THEME_COLOR, defValue: 'blue') ??
        "blue"; //修改默认主题为蓝色
  }
}
