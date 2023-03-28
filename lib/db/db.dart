import 'dart:convert' show json;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:wbyq/common/component_index.dart';

class DB {
  static late Database database;

  static Future<void> initAsync() async {
    String databasesPath = await getDatabasesPath();
    String url = path.join(databasesPath, 'wbyq.db');

    try {
      database = await openDatabase(url);
    } catch (e) {
      print("Error $e");
    }

    /// content 通知栏提示消息体 文本
    /// payload json 属性值
    /// extra json 属性值
    ///
    database.execute('''
            CREATE TABLE IF NOT EXISTS all_msg(
              messageId text primary key,
              sendUserLoginId text,
              sendCompanyPartyId text,
              sendUserName text,
              sendDate  text,
              tag text,
              subTag text,
              title text,
              content text,
              payload text,
              extra text,
              acceptDate text,
              acceptUserLoginId text
            )
            ''');
  }

  static void test() async {
    await DB.execute(
        'CREATE TABLE IF NOT EXISTS test (pk int primary key,f1 text,f2 text)');

    var a = await DB.tableExists('test');
    var b = await DB.tableNotExists('test');

    var c = await DB.fieldExists('test', 'Pk');
    var d = await DB.fieldExists('test1', 'Pk');

    await DB.execute("replace into test(pk,f1,f2) values(100,'a1','a1111111')");
    await DB.execute("replace into test(pk,f1,f2) values(101,'a2','重温222')");

    var e = await DB.getValue<List>('select * from test');
    var f = await DB.getValue<Map>('select * from test where pk=?', [100]);

    var g = await DB.getValue<num>('select pk from test where pk=?', [100]);
    var h = await DB.getValue<int>('select pk from test where pk=?', [100]);
    var l = await DB.getValue<dynamic>('select f1 from test where pk=?', [100]);
    var m = await DB.getValue<String>('select f2 from test where pk=?', [100]);

    print('$a,$b,$c,$d,$e,$f,$g,$h,$l,$m');
  }

  static Future<List<String>> getAllTables([bool? upperCase]) async {
    if (database == null) {
      return Future.value([]);
    }

    var tables = await getValue<List>(
        "SELECT upper(name) name FROM sqlite_master WHERE type = 'table'");
    var targetList = <String>[];

    tables?.forEach((item) {
      targetList.add(upperCase == true
          ? item['name'].toString().toUpperCase()
          : item['name']);
    });

    return targetList;
  }

  static Future<List<String>> getAllFieldNames(String tableName,
      [bool? upperCase]) async {
    var fields = await getValue<List>("PRAGMA table_info('$tableName')");

    var fieldNames = <String>[];

    fields?.forEach((item) {
      fieldNames.add(upperCase == true
          ? item['name'].toString().toUpperCase()
          : item['name']);
    });

    return fieldNames;
  }

  ///检查表是否存在
  static Future<bool> tableExists(String tableName) async {
    var c = await getValue<num>(
        "SELECT count(*) c FROM sqlite_master WHERE type = 'table' and upper(name)=upper('$tableName')");

    return (c ?? 0) > 0;
  }

  ///检查表是否不存在
  static Future<bool> tableNotExists(String tableName) async {
    bool b = await tableExists(tableName);

    return !b;
  }

  static Future<bool> fieldExists(String tableName, String fieldName) async {
    var list = await getAllFieldNames(tableName, true);

    var cfn = fieldName.toUpperCase();

    return list.any((fn) => cfn == fn);
  }

  ///返回 单值查询 返回值应该是 String int double map list
  static Future<T?> getValue<T>(String sql, [List<dynamic>? arguments]) async {
    var list = await database.rawQuery(sql, arguments);

    if (ObjectUtil.isEmptyList(list)) return null;

    if (isTypeOf<T, Map>())
      return list[0] as T;
    else if (isTypeOf<T, List>()) return list as T;

    return list[0].values.elementAt(0) as T;
  }

  static Future execute(String sql, [List<dynamic>? arguments]) {
    return database.execute(sql, arguments);
  }

  ///map中至少应该包含 tableName表的主键
  static Future<void> merge(String tableName, Map<String, dynamic> map) async {
    var fieldNames = await getAllFieldNames(tableName);

    var validFieldNames = map.keys.where((key) => fieldNames.contains(key));

    if (validFieldNames == null || validFieldNames.length == 0)
      return Future.value();

    var validFieldValues = [];

    String vs = '';
    for (var fieldName in validFieldNames) {
      vs += vs.length == 0 ? '?' : ',?';

      var value = map[fieldName] == '' ? null : map[fieldName];

      if (value is Map || value is List) value = json.encode(value);

      validFieldValues.add(value);
    }

    String sql =
        'replace into $tableName(${validFieldNames.join(",")}) values($vs) ';

    return database.execute(sql, validFieldValues);
  }
}
