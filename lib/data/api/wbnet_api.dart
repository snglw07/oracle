import 'dart:io';

import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/net/dio_util.dart';

class WbNetApi {
  ///获取当前登录操作员信息
  static Future<Map<String, dynamic>> getMyLoginInfo() {
    return DioUtil()
        .request<Map<String, dynamic>>(Method.get, '/w/control/myinfo')
        .then((BaseResp<Map<String, dynamic>> result) {
      var map = <String, dynamic>{};

      if (result.data?.containsKey("data") == true) {
        map.addAll(result.data!["data"] as dynamic);
      } else {
        map["error"] = "网络错误";
      }

      return map;
    }).catchError((e) {
      var map = <String, dynamic>{};
      map["error"] = "网络错误";

      return map;
    });
  }

  static Future<Map<String, dynamic>?> loginForAccessToken(
    String username, {
    String? password,
    String? checkcode,
    String? logintype,
    String? other,
    String? sign,
    String? deviceType,
  }) {
    return DioUtil().request<Map<String, dynamic>>(
        Method.post, '/w/control/checklogin',
        data: {
          "j_username": username,
          "j_password": password,
          "j_checkcode": checkcode,
          "j_logintype": logintype,
          "j_other": other,
          //"j_sign": sign,
          "j_deviceType": deviceType
        }).then((BaseResp<Map<String, dynamic>> result) {
      var map = result.data;

      return map;
    }).catchError((e) {
      var map = <String, dynamic>{};
      map["error"] = "网络错误";

      return map;
    });
  }

  ///获取 一个token
  static Future<String> token({String seqName = "SEQ_GEN", String isDB = "N"}) {
    return DioUtil()
        .request<Map<String, dynamic>>(
            Method.get, 'w/control/base.token/$seqName/$isDB')
        .then((BaseResp<Map<String, dynamic>> result) {
      Map<String, dynamic>? res = result.data;
      return res?['token']?.toString() ?? '';
    });
  }

  ///获取 默认获取2个token
  static Future<List<String>> tokens(
      {String seqName = "SEQ_GEN", int tokenNum = 2, String isDB = "N"}) {
    return DioUtil()
        .request<Map<String, dynamic>>(
            Method.get, 'w/control/base.token.list/$seqName/$tokenNum/$isDB')
        .then((BaseResp<Map<String, dynamic>> result) {
      Map<String, dynamic>? res = result.data;
      return List<String>.from((res?['tokens'] as dynamic) ?? []);
    });
  }

  ///获取当前登录操作员联系人信息
  static Future<Map<String, dynamic>?> queryContact(String type,
      {bool? isForce}) async {
    String appId = await WbUtils.getAppId();
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.get, 'w/control/exec/appd.query.signedmember.grv', data: {
      'type': type,
      'appId': appId
    }).timeout(const Duration(seconds: 60));

    return result.data;
  }

  ///获取登录用户附加信息
  static Future<Map<String, dynamic>?> queryUserLoginExInfo(
      {String? userLoginId}) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.get, 'w/control/exec/appd.query.userlogin.exinfo.grv',
            data: {'userLoginId': userLoginId ?? ''});

    return result.data;
  }

  ///获取登录用户附加信息
  static Future<String> queryUserLoginNameById(String userLoginId) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.get, 'w/control/rexec/appd.query.userlogin.lastname.sql',
            data: {'userLoginId': userLoginId});

    return result.data?['lastName'] as String;
  }

  ///更新用户附加信息
  static Future<Map<String, dynamic>?> updateMyInfo(
      Map<String, dynamic> data) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/appd.update.userlogin.exinfo',
            data: data);

    return result.data;
  }

  ///发送手机登录验证码
  static Future<Map<String, dynamic>?> sendSmsDynLoginCode(String phoneNumber) {
    return DioUtil()
        .request<Map<String, dynamic>>(
            Method.get, 'w/control/sendsmsdynlogincode/$phoneNumber')
        .then((BaseResp<Map<String, dynamic>> result) {
      return result.data;
    }).catchError((e) {
      var map = <String, dynamic>{};
      map["error"] = "网络错误";

      return map;
    });
  }

  static Map<String, dynamic> enumMap = {};

  static Future<Map<String, dynamic>?> getEnums(String enumTypeId) async {
    if (ObjectUtil.isEmpty(enumMap[enumTypeId])) {
      BaseResp<Map<String, dynamic>> result = await DioUtil()
          .request<Map<String, dynamic>>(
              Method.get, 'w/control/exec/appd.getenums',
              data: {"enumTypeId": enumTypeId});
      enumMap[enumTypeId] = result.data as dynamic;
    }
    return Future.value(enumMap[enumTypeId] as dynamic);
  }

  static Future<Map<String, dynamic>?> sendSmsCode(String phoneNumber) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.get, 'w/control/base.bindphone.getsmscode',
            data: {'phoneNumber': phoneNumber});

    return result.data;
  }

  /// 生成微信二维码
  /// type     C-机构码 U-登陆用户码 S-已关注用户码
  ///
  /// recordId company_party_id,user_login_id,wx_subscribe_user主键值
  static Future<Map<String, dynamic>?> generateQrCode(
      String recordId, String type) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.get, 'w/control/base.wechat.qrcode.generate',
            data: {'recordId': recordId, 'qrCodeType': type});

    return result.data;
  }

  ///获取当前app 配置信息
  static Future<Map<String, dynamic>?> getAppClientCfg(String appId) async {
    var platform = 'UNKNOW';
    if (Platform.isAndroid) {
      platform = 'ANDROID';
    } else if (Platform.isIOS) {
      platform = 'IOS';
    }

    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.get, 'w/control/get.clientcfg/$platform/$appId');

    return result.data;
  }

  static Future<Map<String, dynamic>?> postFile(
      File file, String fileName) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .upload<Map<String, dynamic>>(Method.post, 'w/control/appd.resupload',
            file: file, fileName: fileName);

    return result.data;
  }

  static Future<Map<String, dynamic>?> appHeartbeat(
      String appId, String onlineStatus) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(Method.get,
            'w/control/appd.heartbeat/$appId?onlineStatus=$onlineStatus');
    return result.data;
  }

  //查询文档
  static Future<Map<String, dynamic>?> fetchAppdMd(
      {String token = 'appd_nc'}) async {
    String appId = await WbUtils.getAppId();
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.get, 'w/control/appd.mds?appId=$appId&token=$token');

    return result.data;
  }

  //系统参数
  static Future<Map<String, dynamic>?> systemParams() async {
    String appId = await WbUtils.getAppId();
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.get, 'w/control/appd.paramsmap?appId=$appId&prefix=appd');

    return result.data;
  }

  ///exec查询
  static Future<Map<String, dynamic>?> exec(String execId,
      {Map<String, dynamic>? params}) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(Method.post, 'w/control/exec/$execId',
            data: params ?? {});

    return result.data;
  }

  /// api查询
  /// uri control/ 后面的地址
  /// params 参数
  static Future<Map<String, dynamic>?> api(String uri,
      {Map<String, dynamic>? params}) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(Method.post, 'w/control/$uri',
            data: params ?? {});
    return result.data;
  }

  static Map<String, dynamic> homeMap = {};
  static Future<Map<String, dynamic>?> getHomePageSource(
      {bool clearCache = false}) async {
    if (clearCache || ObjectUtil.isEmpty(homeMap)) {
      BaseResp<Map<String, dynamic>> result = await DioUtil()
          .request<Map<String, dynamic>>(
              Method.get, 'w/control/rexec/wbyq.home.page.source');
      homeMap = result.data ?? <String, dynamic>{};
    }

    return Future.value(homeMap);
  }

  static Future<Map<String, dynamic>?> getPatientList(String userLoginId,
      {String? param, String? faceV}) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.get, 'w/control/exec/wbyb.patient.list',
            data: {"userLoginId": userLoginId, "param": param, "faceV": faceV});

    return result.data;
  }

  static Future<Map<String, dynamic>?> storeSchedule(
      Map<String, dynamic?> data) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/wbyq.carschedule.store',
            data: data);

    return result.data;
  }

  static Future<Map<String, dynamic>?> querySchedule(
      {String? departDate}) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/exec/wbyq.carschedule.query',
            data: {"departDate": departDate ?? ''});

    return result.data;
  }

  static Future<Map<String, dynamic>?> queryUpload({String? recordId}) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/exec/wbyq.psupload.query',
            data: {"recordId": recordId ?? ''});

    return result.data;
  }

  static Future<Map<String, dynamic>?> storeUpload(
      Map<String, dynamic> data) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/wbyq.jtjfk.store',
            data: data);

    return result.data;
  }

  static Future<Map<String, dynamic>?> storeJzUpload(
      Map<String, dynamic> data) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(Method.post, 'w/control/wbyq.jzdj.store',
            data: data);

    return result.data;
  }

  static Future<Map<String, dynamic>?> queryMyUploadRecord(
      Map<String, dynamic> data) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/exec/wbyq.yqfk.upload.query',
            data: data);

    return result.data;
  }

  static Future<Map<String, dynamic>?> queryPersonRiskLevel(
      Map<String, dynamic> data) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/exec/wbyq.yqfk.person.risk.query',
            data: data);

    return result.data;
  }

  static Future<Map<String, dynamic>?> queryMyJzUploadRecord(
      Map<String, dynamic> data) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/exec/wbyq.yqfk.jzupload.query',
            data: data);

    return result.data;
  }

  static Future<Map<String, dynamic>?> getStudentList(
      Map<String, dynamic> data) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/exec/xx.app.student.list.sql',
            data: data);

    return result.data;
  }

  static Future<Map<String, dynamic>?> queryStudentInfo(
      String studentId) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/exec/school.student.leave.detail.sql',
            data: {'studentId': studentId});

    return result.data;
  }

  static Future<Map<String, dynamic>?> storeStudentEx(
      Map<String, dynamic> data, String url) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(Method.post, 'w/control/$url',
            data: data);

    return result.data;
  }

  static Future<Map<String, dynamic>?> studentExRecordQuery(
      String studentId, String exType) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/exec/student.exrecord.sql',
            data: {"studentId": studentId, "exType": exType});

    return result.data;
  }

  static Future<Map<String, dynamic>?> studentNormalStore(
      Map<String, dynamic> data) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/student.screening.store',
            data: data);

    return result.data;
  }

  static Future<Map<String, dynamic>?> teacherClassRelation(
      String userLoginId) async {
    BaseResp<Map<String, dynamic>> result = await DioUtil()
        .request<Map<String, dynamic>>(
            Method.post, 'w/control/exec/xx.app.teacher.relation.grv',
            data: {"userLoginId": userLoginId});

    return result.data;
  }
}
