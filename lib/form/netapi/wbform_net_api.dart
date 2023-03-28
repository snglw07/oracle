import 'package:wbyq/application.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/net/dio_util.dart';
import 'package:wbyq/utils/wb_utils.dart';

import '../index.dart';

class WbFormApi {
  // 地理位置信息初始化
  bool geodataInited = false;

  /// 本地缓存版本号
  ///
  /// var apkCfg = json.decode(map['apkCfg']);
  /// WbFormApi.appCacheVersion = apkCfg['appCacheVersion'] ?? '100';
  static String appCacheVersion = "";

  // 系统枚举
  static Future<Map<String, dynamic>> systemEnum(String url,
      {Duration cachedDuration = const Duration(days: 1),
      isForce = false}) async {
    String? userLoginId = Application.userLoginModel.userLoginId;
    return await cachedRequest('enum.$userLoginId.$url', () async {
      return DioUtil()
          .request<Map<String, dynamic>>(Method.get, 'w/control/$url');
    }, isForce: isForce, duration: cachedDuration);
  }

  // 系统地理位置信息枚举
  static Future<Map<String, dynamic>> geoGeoMain({isForce = false}) async {
    return await cachedRequest('enum.enums.gwgeolistmap', () async {
      return await DioUtil().request<Map<String, dynamic>>(
          Method.get, 'w/control/gwgeolistmap?geoType=3');
    }, isForce: isForce, duration: const Duration(days: 7));
  }

  // 系统地理位置信息枚举
  static Future<Map<String, dynamic>> geoEnum({isForce = false}) async {
    return await cachedRequest('enum.enums.geodata', () async {
      return await DioUtil().request<Map<String, dynamic>>(
          Method.get, 'w/control/rexec/appd.enums.geodata');
    }, isForce: isForce, duration: const Duration(days: 1));
  }

  // 获取表单渲染页面配置
  static Future<Map<String, dynamic>> formCfg(String formId,
      {Duration cachedDuration = const Duration(days: 1),
      isForce = false}) async {
    Map<String, dynamic> result = await cachedRequest('formcfg.$formId', () {
      return DioUtil().request<Map<String, dynamic>>(
          Method.get, 'w/control/appd.form.cfg?formId=$formId');
    }, isForce: isForce, duration: cachedDuration);

    return result;
  }

  // 缓存固定内容请求
  static Future<Map<String, dynamic>> cachedRequest(
      String key, Future<BaseResp<Map<String, dynamic>>> Function() cacheFn,
      {Duration duration = const Duration(days: 1),
      bool isForce = false}) async {
    assert(key != null && ObjectUtil.isNotEmpty(key), '缓存键不能为空');
    // 获取appid 拼接为缓存键
    String appId = await WbUtils.getAppId();
    String cachedKey = "$appId.${appCacheVersion ?? 100}.$key";
    // 获取sp 的缓存对象 默认最后获取时间
    Map<String, dynamic>? cachedMap;

    SpUtil.getObject(cachedKey)?.forEach((key, value) {
      cachedMap ??= <String, dynamic>{};

      cachedMap![key?.toString() ?? ""] = value;
    });
    Map<String, dynamic> result = {};
    DateTime lastFetchTime = DateTime.now();
    // 若为强制刷新 或者缓存不存在
    if (isForce || ObjectUtil.isEmpty(cachedMap)) {
      result['lastFetchTime'] = lastFetchTime.millisecondsSinceEpoch;
      BaseResp<Map<String, dynamic>> fnRes = await cacheFn();
      result['fnRes'] = fnRes.data;
    } else {
      // 若缓存存在 判断时间
      lastFetchTime = DateTime.fromMillisecondsSinceEpoch(
          cachedMap!['lastFetchTime'] as int);
      if (DateTime.now().subtract(duration).isAfter(lastFetchTime)) {
        BaseResp<Map<String, dynamic>> fnRes = await cacheFn();
        result['fnRes'] = fnRes.data;
        result['lastFetchTime'] = DateTime.now().millisecondsSinceEpoch;
      } else {
        result = cachedMap!;
      }
    }
    Map<String, dynamic> fnRes = result['fnRes'] as Map<String, dynamic>;
    if (!fnRes.containsKey("error")) SpHelper.putObject(cachedKey, result);
    return fnRes;
  }
}
