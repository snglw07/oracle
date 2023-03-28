import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:wbyq/common/common.dart';
import 'package:wbyq/application.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/utils/util_index.dart';

/**
 * @Author: thl
 * @GitHub: https://github.com/Sky24n
 * @JianShu: https://www.jianshu.com/u/cbf2ad25d33a
 * @Email: 863764940@qq.com
 * @Description: Dio Util.
 * @Date: 2018/12/19
 */

/// <BaseResp<T> 返回 status code msg data.
class BaseResp<T> {
  String? status;
  int? code;
  String? msg;
  T? data;

  BaseResp(this.status, this.code, this.msg, this.data);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer('{');
    sb.write("\"status\":\"$status\"");
    sb.write(",\"code\":$code");
    sb.write(",\"msg\":\"$msg\"");
    sb.write(",\"data\":\"$data\"");
    sb.write('}');
    return sb.toString();
  }
}

/// <BaseRespR<T> 返回 status code msg data Response.
class BaseRespR<T> {
  String status;
  int code;
  String msg;
  T? data;
  Response? response;

  BaseRespR(this.status, this.code, this.msg, this.data, this.response);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer('{');
    sb.write("\"status\":\"$status\"");
    sb.write(",\"code\":$code");
    sb.write(",\"msg\":\"$msg\"");
    sb.write(",\"data\":\"$data\"");
    sb.write('}');
    return sb.toString();
  }
}

/// 请求方法.
class Method {
  static final String get = "GET";
  static final String post = "POST";
  static final String put = "PUT";
  static final String head = "HEAD";
  static final String delete = "DELETE";
  static final String patch = "PATCH";
  static final String upload = "UPLOAD";
}

///Http配置.
class HttpConfig {
  /// constructor.
  HttpConfig({
    this.status,
    this.code,
    this.msg,
    this.data,
    this.options,
    this.pem,
    this.pKCSPath,
    this.pKCSPwd,
  });

  /// BaseResp [String status]字段 key, 默认：status.
  String? status;

  /// BaseResp [int code]字段 key, 默认：errorCode.
  String? code;

  /// BaseResp [String msg]字段 key, 默认：errorMsg.
  String? msg;

  /// BaseResp [T data]字段 key, 默认：data.
  String? data;

  /// Options.
  Options? options;

  /// 详细使用请查看dio官网 https://github.com/flutterchina/dio/blob/flutter/README-ZH.md#Https证书校验.
  /// PEM证书内容.
  String? pem;

  /// 详细使用请查看dio官网 https://github.com/flutterchina/dio/blob/flutter/README-ZH.md#Https证书校验.
  /// PKCS12 证书路径.
  String? pKCSPath;

  /// 详细使用请查看dio官网 https://github.com/flutterchina/dio/blob/flutter/README-ZH.md#Https证书校验.
  /// PKCS12 证书密码.
  String? pKCSPwd;
}

/// 单例 DioUtil.
/// debug模式下可以打印请求日志. DioUtil.openDebug().
/// dio详细使用请查看dio官网(https://github.com/flutterchina/dio).
class DioUtil {
  static final DioUtil _singleton = DioUtil._init();
  static Dio? _dio;

  /// BaseResp [String status]字段 key, 默认：status.
  String _statusKey = "status";

  /// BaseResp [int code]字段 key, 默认：errorCode.
  String _codeKey = "errorCode";

  /// BaseResp [String msg]字段 key, 默认：errorMsg.
  String _msgKey = "errorMsg";

  /// BaseResp [T data]字段 key, 默认：data.
  String _dataKey = "data";

  /// Options.
  BaseOptions _options = getDefOptions();

  /// PEM证书内容.
  String? _pem;

  /// PKCS12 证书路径.
  String? _pKCSPath;

  /// PKCS12 证书密码.
  String? _pKCSPwd;

  /// 是否是debug模式.
  static bool _isDebug = false;

  static DioUtil getInstance() {
    return _singleton;
  }

  factory DioUtil() {
    return _singleton;
  }

  DioUtil._init() {
    _dio = new Dio(_options);
  }

  /// 打开debug模式.
  static void openDebug() {
    _isDebug = true;
  }

  /// set Config.
  void setConfig(BaseOptions options) {
    //_statusKey = config.status ?? _statusKey;
    //_codeKey = config.code ?? _codeKey;
    _msgKey = "error"; //config.msg ?? _msgKey;
    //_dataKey = config.data ?? _dataKey;
    _mergeOption(options);
    //_pem = config.pem ?? _pem;
    if (_dio != null) {
      _dio?.options = _options;
      if (_pem != null) {
        _dio?.httpClientAdapter = IOHttpClientAdapter()
          ..onHttpClientCreate = (HttpClient client) {
            client.badCertificateCallback =
                (X509Certificate cert, String host, int port) {
              if (cert.pem == _pem) {
                // 证书一致，则放行
                return true;
              }
              return false;
            };
            return client;
          };
      }
      if (_pKCSPath != null) {
        _dio?.httpClientAdapter = IOHttpClientAdapter()
          ..onHttpClientCreate = (HttpClient client) {
            SecurityContext sc = new SecurityContext();
            //file为证书路径
            sc.setTrustedCertificates(_pKCSPath!, password: _pKCSPwd);
            HttpClient httpClient = new HttpClient(context: sc);
            return httpClient;
          };
      }
    }
  }

  /// Make http request with options.
  /// [method] The request method.
  /// [path] The url path.
  /// [data] The request data
  /// [options] The request options.
  /// <BaseResp<T> 返回 status code msg data .
  Future<BaseResp<T>> request<T>(String method, String path,
      {data, Options? options, CancelToken? cancelToken}) async {
    //登录用户增加心跳检测 4分钟间隔
    String? userLoginId = Application.userLoginModel.userLoginId;
    if (ObjectUtil.isNotEmpty(userLoginId))
      addHeartbeatDetect(path, userLoginId);

    var response = await _dio?.request(path,
        data: data,
        options: _checkOptions(method, options),
        cancelToken: cancelToken);
    if (response != null) _printHttpLog(response);
    return handleResponse(response);
  }

  //登录用户增加心跳检测 4分钟间隔
  addHeartbeatDetect(String path, String? userLoginId) async {
    String now = DateTime.now().toString();
    String spLastTimeKey = "heartbeats:$userLoginId:lastOnlineReqTime";
    // 非心跳检测请求 对比请求时间差别
    if (path.indexOf("w/control/appd.heartbeat") < 0) {
      String appId = await WbUtils.getAppId();
      String spKey = "$appId.$userLoginId.onlineStatus";
      String onlineStatus =
          SpUtil.getString(spKey, defValue: 'online') ?? "online";
      String? lastReqTime = SpUtil.getString(spLastTimeKey);
      if (ObjectUtil.isEmpty(lastReqTime)) {
        lastReqTime = now;
        SpUtil.putString(spLastTimeKey, now);
      }
      if ((DateTime.now()
          .subtract(Duration(minutes: 4))
          .isAfter(DateTime.parse(lastReqTime!))))
        WbNetApi.appHeartbeat(appId, onlineStatus);
    } else {
      // 心跳检测请求 修改最后心跳检测时间
      SpUtil.putString(spLastTimeKey, now);
    }
  }

  /// Make http request with options.
  /// [method] The request method.
  /// [path] The url path.
  /// [data] The request data
  /// [options] The request options.
  /// <BaseRespR<T> 返回 status code msg data  Response.
  Future<BaseRespR<T>> requestR<T>(String method, String path,
      {data, Options? options, CancelToken? cancelToken}) async {
    var response = await _dio?.request(path,
        data: data,
        options: _checkOptions(method, options),
        cancelToken: cancelToken);
    if (response != null) _printHttpLog(response);
    String _status;
    int _code;
    String _msg;
    T? _data;
    if (response?.statusCode == HttpStatus.ok ||
        response?.statusCode == HttpStatus.created) {
      try {
        if (response?.data is Map) {
          _status = (response?.data[_statusKey] is int)
              ? response?.data[_statusKey].toString()
              : response?.data[_statusKey];
          _code = (response?.data[_codeKey] is String)
              ? int.tryParse(response?.data[_codeKey])
              : response?.data[_codeKey];
          _msg = response?.data[_msgKey];
          try {
            _data = response?.data[_dataKey];
          } catch (e) {
            _data = null;
          }
        } else {
          Map<String, dynamic> _dataMap = _decodeData(response);
          _status = (_dataMap[_statusKey] is int)
              ? _dataMap[_statusKey].toString()
              : _dataMap[_statusKey];
          _code = (_dataMap[_codeKey] is String)
              ? int.tryParse(_dataMap[_codeKey])
              : _dataMap[_codeKey];
          _msg = _dataMap[_msgKey];
          try {
            _data = _dataMap[_dataKey];
          } catch (e) {
            _data = null;
          }
        }
        return new BaseRespR(_status, _code, _msg, _data, response);
      } catch (e) {
        return new Future.error(new DioError(
          response: response,
          message: "data parsing exception...",
          type: DioErrorType.badResponse,
          requestOptions: response?.requestOptions ?? RequestOptions(),
        ));
      }
    }
    return new Future.error(new DioError(
      response: response,
      message: "statusCode: $response.statusCode, service error",
      type: DioErrorType.badResponse,
      requestOptions: response?.requestOptions ?? RequestOptions(),
    ));
  }

  /// Download the file and save it in local. The default http method is "GET",you can custom it by [Options.method].
  /// [urlPath]: The file url.
  /// [savePath]: The path to save the downloading file later.
  /// [onProgress]: The callback to listen downloading progress.please refer to [OnDownloadProgress].
  Future<Response>? download(
    String urlPath,
    savePath, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
    data,
    Options? options,
  }) {
    return _dio?.download(urlPath, savePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
        data: data,
        options: options);
  }

  /// decode response data.
  Map<String, dynamic> _decodeData(Response? response) {
    if (response == null ||
        response.data == null ||
        response.data.toString().isEmpty) {
      return new Map();
    }
    return json.decode(response.data.toString());
  }

  /// check Options.
  Options _checkOptions(method, options) {
    options ??= Options();

    options.method = method;
    return options;
  }

  /// merge Option.
  void _mergeOption(BaseOptions opt) {
    _options.method = opt.method ?? _options.method;
    _options.headers = (new Map.from(_options.headers))..addAll(opt.headers);

    _options.baseUrl = opt.baseUrl ?? _options.baseUrl;
    _options.connectTimeout = opt.connectTimeout ?? _options.connectTimeout;
    _options.receiveTimeout = opt.receiveTimeout ?? _options.receiveTimeout;
    _options.responseType = opt.responseType ?? _options.responseType;
    //_options.data = opt.data ?? _options.data;
    _options.extra = (new Map.from(_options.extra))..addAll(opt.extra);
    _options.contentType = opt.contentType ?? _options.contentType;
    _options.validateStatus = opt.validateStatus ?? _options.validateStatus;
    _options.followRedirects = opt.followRedirects ?? _options.followRedirects;
  }

  /// print Http Log.
  void _printHttpLog(Response response) {
    if (!_isDebug) {
      return;
    }
    try {
      print("----------------Http Log----------------" +
          "\n[statusCode]:   " +
          response.statusCode.toString() +
          "\n[request   ]:   " +
          _getOptionsStr(response.requestOptions));
      _printDataStr("reqdata ", response.requestOptions.data);
      _printDataStr("response", response.data);
    } catch (ex) {
      print("Http Log" + " error......");
    }
  }

  /// get Options Str.
  String _getOptionsStr(RequestOptions request) {
    return "method: " +
        request.method +
        "  baseUrl: " +
        request.baseUrl +
        "  path: " +
        request.path;
  }

  /// print Data Str.
  void _printDataStr(String tag, Object value) {
    String da = value.toString();
    while (da.isNotEmpty) {
      if (da.length > 512) {
        print("[$tag  ]:   " + da.substring(0, 512));
        da = da.substring(512, da.length);
      } else {
        print("[$tag  ]:   " + da);
        da = "";
      }
    }
  }

  /// get dio.
  Dio getDio() {
    return _dio!;
  }

  /// create new dio.
  static Dio createNewDio([BaseOptions? options]) {
    options = options ?? getDefOptions();
    Dio dio = new Dio(options);
    return dio;
  }

  /// get Def Options.
  static BaseOptions getDefOptions() {
    BaseOptions options = new BaseOptions();
    options.contentType = "application/x-www-form-urlencoded";
    options.connectTimeout = Duration(seconds: 5);
    options.receiveTimeout = Duration(seconds: 10);

    options.headers = (new Map.from(options.headers))
      ..addAll({
        //"_ACCESS_TOKEN":"",
        "X-Requested-With": "Dio",
      });

    return options;
  }

  static Map<String, String> getDefHeaders() {
    var map = Map<String, String>.from(_dio!.options.headers);

    return map;
  }

  static String getAbsoluteUrl(String url) {
    return _dio!.options.baseUrl + '/' + url;
  }

  Future<BaseResp<T>> upload<T>(String method, String path,
      {Map<String, dynamic>? data,
      File? file,
      String? fileName,
      Options? options,
      CancelToken? cancelToken}) async {
    FormData formData = new FormData();

    if (data != null) formData = FormData.fromMap(data);

    formData.files.add(MapEntry(
      'files',
      await MultipartFile.fromFile(
        file?.path ?? "",
        filename: fileName ?? "" + '.png',
      ),
    ));

    var response = await _dio?.request(path,
        data: formData,
        options: _checkOptions(method, options),
        cancelToken: cancelToken);
    if (response != null) _printHttpLog(response);
    return handleResponse(response);
  }

  Future<BaseResp<T>> handleResponse<T>(Response? response) {
    String? _status;
    int? _code;
    String? _msg;
    T? _data;

    if (response?.statusCode == HttpStatus.ok ||
        response?.statusCode == HttpStatus.created) {
      try {
        if (response?.data is Map) {
          _status = (response?.data[_statusKey] is int)
              ? response?.data[_statusKey].toString()
              : response?.data[_statusKey];
          _code = (response?.data[_codeKey] is String)
              ? int.tryParse(response?.data[_codeKey])
              : response?.data[_codeKey];
          _msg = response?.data[_msgKey];

          if (_msg == null)
            _code = Constant.STATUS_SUCCESS;
          else
            _code = Constant.STATUS_FAIL;

          _data = response?.data; //response.data[_dataKey];
        } else {
          Map<String, dynamic> _dataMap = _decodeData(response);
          _status = (_dataMap[_statusKey] is int)
              ? _dataMap[_statusKey].toString()
              : _dataMap[_statusKey];
          _code = (_dataMap[_codeKey] is String)
              ? int.tryParse(_dataMap[_codeKey])
              : _dataMap[_codeKey];
          _msg = _dataMap[_msgKey];
          _data = _dataMap[_dataKey];
        }
        return new Future.sync(() => BaseResp(_status, _code, _msg, _data));
      } catch (e) {
        return new Future.error(new DioError(
            response: response,
            message: "data parsing exception...",
            type: DioErrorType.badResponse,
            requestOptions: response?.requestOptions ?? RequestOptions()));
      }
    }
    return new Future.error(new DioError(
        response: response,
        message: "statusCode: $response.statusCode, service error",
        type: DioErrorType.badResponse,
        requestOptions: response?.requestOptions ?? RequestOptions()));
  }
}
