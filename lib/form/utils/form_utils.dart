import 'package:flutter/widgets.dart';

import '../../flutter_form_builder/form_builder.dart';
import '../index.dart';

class FormUtils {
  static Map<String, dynamic>? formatFormCfg(Map<String, dynamic>? map) {
    if (null == map || !map.containsKey('doc')) return null;
    Map<String, Map<String, dynamic>> doc =
        Map<String, Map<String, dynamic>>.from(
            map['doc'] as Map<String, Map<String, dynamic>>);

    Map<String, dynamic> result = {};
    for (String key in doc.keys) {
      Map<String, dynamic>? value = doc[key];
      value = FormUtils.keysCamelcase(value);
      value["id"] = key;
      if (value.containsKey("page")) {
        if (!result.containsKey(value['page'])) {
          result[value['page'].toString()] = [value];
        } else {
          List temp = result[value['page']] as List;
          temp.add(value);
          result[value['page'].toString()] = temp;
        }
      } else {
        result['hidden'] = [value];
      }
    }
    //原始doc 文档 会用到字段的
    result['orgDoc'] = doc;
    return result;
  }

  static Map<String, dynamic> keysCamelcase(Map<String, Object?>? map) {
    if (!ObjectUtil.isNotEmpty(map)) return map!;
    Map<String, dynamic> temp = {};
    for (String k in map!.keys) {
      temp[ReCase(k).camelCase] = map[k];
    }

    if (map.containsKey('dataSource')) {
      Map<String, dynamic> dataSource =
          Map<String, dynamic>.from(map['dataSource'] as Map<String, dynamic>);
      var datatemp = {};
      for (String k in dataSource.keys) {
        datatemp[ReCase(k).camelCase] = dataSource[k];
      }
      temp['dataSource'] = datatemp;
    }
    return temp;
  }

  /// 是否存在引用对象
  static bool canUpdateTextRef(
      WbItemCfg itemCfg, GlobalKey<FormBuilderState> fbKey) {
    bool canUpdate = ObjectUtil.isNotEmpty(itemCfg.textRef) &&
        fbKey.currentState?.fields.containsKey(itemCfg.textRef) == true;
    return canUpdate;
  }

  /// 多个引用对象 以竖线分割
  static bool canUpdateMultipleTextRef(
      WbItemCfg itemCfg, GlobalKey<FormBuilderState>? fbKey) {
    bool canUpdate = ObjectUtil.isNotEmpty(itemCfg.textRef);
    if (!canUpdate) return canUpdate;
    List<String>? refs = itemCfg.textRef?.split("|");
    refs?.map((ref) =>
        canUpdate = fbKey?.currentState?.fields.containsKey(ref) == true);
    return canUpdate;
  }

  /// 是否存在引用对象 要有kv的值
  ///
  /// 主要是第一个key 要存在 才能更新
  static bool canUpdateTextRefKv(
      WbItemCfg itemCfg, GlobalKey<FormBuilderState>? fbKey) {
    bool canUpdate = ObjectUtil.isNotEmpty(itemCfg.textRef);
    if (!canUpdate) return canUpdate;
    List<String>? refs = itemCfg.textRef?.split("|");
    canUpdate = fbKey?.currentState?.fields.containsKey(refs?[0]) == true;
    return canUpdate;
  }

  static Map<String, String> iDCard18Parse(String idcard) {
    Map<String, String> result = Map<String, String>();
    if (!RegexUtil.isIDCard18Exact(idcard)) {
      result['error'] = "输入值不是有效的身份证号。";
      return result;
    }

    String geoTag = idcard.substring(0, 6);
    result['geoTag'] = geoTag;

    String birthdate = idcard.substring(6, 14);
    result['birthdate'] = birthdate;
    DateTime? datetime = DateTime.tryParse(birthdate);
    result['birthdateFormated'] =
        DateUtil.formatDate(datetime, format: DateFormats.y_mo_d);

    String sex = "MALE";
    int? sexTag = int.tryParse(idcard.substring(16, 17)) ?? 0;
    if (sexTag % 2 == 0) sex = "FEMALE";

    result['sex'] = sex;
    return result;
  }

  /// 转换表单字段的类型 主要是解决ui绑定时 类型不一致的展示问题
  static Map<String, dynamic> convertFieldType(
      Map<String, dynamic> orgForm, Map<String, dynamic> doc) {
    for (String key in doc.keys) {
      Map<String, dynamic>? itemCfg = orgForm[key] as Map<String, dynamic>;

      /// 存在配置项 且配置项 ui字段 不为空
      if (ObjectUtil.isNotEmpty(itemCfg) && itemCfg.containsKey('ui')) {
        if ('date' == itemCfg['ui'])
          doc[key] = DateTime.parse(doc[key]?.toString() ?? "");
      }
    }
    return doc;
  }
}

class ReCase {
  final RegExp _upperAlphaRegex = new RegExp(r'[A-Z]');
  final RegExp _symbolRegex = new RegExp(r'[ ./_\-]');
  String? originalText;
  List<String>? _words;

  ReCase(String text) {
    this.originalText = text;
    this._words = _groupIntoWords(text);
  }

  List<String> _groupIntoWords(String text) {
    StringBuffer sb = new StringBuffer();
    List<String> words = [];
    bool isAllCaps = !text.contains(RegExp('[a-z]'));

    for (int i = 0; i < text.length; i++) {
      String char = new String.fromCharCode(text.codeUnitAt(i));
      String? nextChar = (i + 1 == text.length
          ? null
          : new String.fromCharCode(text.codeUnitAt(i + 1)));

      if (_symbolRegex.hasMatch(char)) {
        continue;
      }
      sb.write(char);
      bool isEndOfWord = nextChar == null ||
          (_upperAlphaRegex.hasMatch(nextChar) && !isAllCaps) ||
          _symbolRegex.hasMatch(nextChar);

      if (isEndOfWord) {
        words.add(sb.toString());
        sb.clear();
      }
    }

    return words;
  }

  String get camelCase => _getCamelCase();

  String get constantCase => _getConstantCase();

  String get sentenceCase => _getSentenceCase();

  String get snakeCase => _getSnakeCase();

  String get dotCase => _getSnakeCase(separator: '.');

  String get paramCase => _getSnakeCase(separator: '-');

  String get pathCase => _getSnakeCase(separator: '/');

  String get pascalCase => _getPascalCase();

  String get headerCase => _getPascalCase(separator: '-');

  String get titleCase => _getPascalCase(separator: ' ');

  String _getCamelCase({String separator = ''}) {
    List<String> words = this._words?.map(_upperCaseFirstLetter).toList() ?? [];
    words[0] = words[0].toLowerCase();
    return words.join(separator);
  }

  String _getConstantCase({String separator = '_'}) {
    List<String> words =
        this._words?.map((word) => word.toUpperCase()).toList() ?? [];
    return words.join(separator);
  }

  String _getPascalCase({String separator = ''}) {
    List<String> words = this._words?.map(_upperCaseFirstLetter).toList() ?? [];
    return words.join(separator);
  }

  String _getSentenceCase({String separator = ' '}) {
    List<String> words =
        this._words?.map((word) => word.toLowerCase()).toList() ?? [];
    words[0] = _upperCaseFirstLetter(words[0]);
    return words.join(separator);
  }

  String _getSnakeCase({String separator = '_'}) {
    List<String> words =
        this._words?.map((word) => word.toLowerCase()).toList() ?? [];
    return words.join(separator);
  }

  String _upperCaseFirstLetter(String word) {
    return '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}';
  }
}

class FormDateUtils {
  /// 根据时间 返回季度
  static int quarterNumber({DateTime? date}) {
    double quarter;
    if (ObjectUtil.isEmpty(date)) {
      quarter = (DateTime.now().month - 1) / 3 + 1;
    } else {
      quarter = (date!.month - 1) / 3 + 1;
    }
    return quarter.toInt();
  }

  /// 返回季度开始日期
  static DateTime firstDayOfQuarter() {
    DateTime firstDayOfQuarter;
    int quarter = FormDateUtils.quarterNumber();
    firstDayOfQuarter = DateTime(DateTime.now().year, (quarter - 1) * 3 + 1);
    return firstDayOfQuarter;
  }

  /// 返回下季度开始日期
  static DateTime firstDayOfNextQuarter() {
    DateTime firstDayOfNextQuarter;
    int quarter = FormDateUtils.quarterNumber();
    if (quarter == 4) {
      firstDayOfNextQuarter = DateTime(
        DateTime.now().year + 1,
      );
    } else {
      firstDayOfNextQuarter = DateTime(DateTime.now().year, quarter * 3 + 1);
    }
    return firstDayOfNextQuarter;
  }

  /// 返回本季度结束日期
  static DateTime lastDayOfQuarter() {
    return FormDateUtils.firstDayOfNextQuarter().add(Duration(days: -1));
  }
}
