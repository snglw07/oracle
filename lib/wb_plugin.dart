import 'dart:async';
import 'dart:ui';
import 'dart:convert' show json;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

enum WbMessageType {
  //未知消息
  UNKNOWN,
  //收到通知栏消息
  NOTIFIY_ARRIVED,
  //点击通知栏消息
  NOTIFIY_CLICK,
  //收到透传消息
  PASS_THROUGH,
}

class WbMessage {
  WbMessageType? type;
  String? _type;

  String? messageId;

  String? sendUserLoginId;

  String? sendCompanyPartyId;

  String? sendUserName;

  String? sendDate;

  String? topic;
  //String alias;
  //bool isPassThrough;
  //String category;

  String? payload;

  String? content;

  //int messageType;

  //int notifyId;
  //int notifyType;

  String? title;
  //String userAccount;

  String? subTag;

  String? tag;

  Map<String, String?> extra = {};

  WbMessage(Map map) {
    _type = map['type'] ?? 'UNKNOWN';

    if (_type == 'NOTIFIY_ARRIVED')
      type = WbMessageType.NOTIFIY_ARRIVED;
    else if (_type == 'NOTIFIY_CLICK')
      type = WbMessageType.NOTIFIY_CLICK;
    else if (_type == 'PASS_THROUGH')
      type = WbMessageType.PASS_THROUGH;
    else
      type = WbMessageType.UNKNOWN;

    messageId = map['messageId'];
    content = map['description'];
    payload = map['content'];

    topic = map['topic'];
    //alias=map['alias'];
    //isPassThrough=map['passThrough']==1;
    //category=map['category'];

    //messageType=map['messageType'];
    //notifyId=map['notifyId'];
    //notifyType=map['notifyType'];

    title = map['title'];
    //userAccount=map['userAccount'];

    if (map.containsKey("extra")) {
      Map ex = map['extra'];
      ex.forEach((key, value) => extra[key.toString()] = value?.toString());
    }

    sendUserLoginId = extra['createdUserLoginId'];
    sendCompanyPartyId = extra['createCompanyPartyId'];
    sendUserName = extra['sendUserName'];
    sendDate = extra['sendDate'];
    subTag = extra['subTag'];
    tag = extra['tag'];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};

    map['type'] = _type;
    map['messageId'] = messageId;
    map['sendUserLoginId'] = sendUserLoginId;
    map['sendCompanyPartyId'] = sendCompanyPartyId;

    map['sendUserName'] = sendUserName;
    map['sendDate'] = sendDate;
    map['topic'] = topic;
    map['payload'] = payload;
    map['content'] = content;
    map['title'] = title;
    map['tag'] = tag;
    map['subTag'] = subTag;
    map['extra'] = extra;

    return map;
  }

  String toString() {
    return json.encode(toMap());
  }
}

enum WbConversationType { DISCUSSION, GROUP, CHATROOM }

class WbPlugin {
  static const MethodChannel _channel = const MethodChannel('wb_plugin');

  static void Function(WbMessage message)? onPushMessage;

  static void Function(String method, Map map)? onRongCallkitMessage;

  static Future<bool?> configure(
      {String? miPushAppId, String? miPushAppKey, String? rongAppKey}) {
    _channel.setMethodCallHandler((MethodCall call) {
      print(
          "-----------------------------[method call:${call.method}]---------------------");

      if (call.method == 'onMessage') {
        var message = call.arguments;
        var messageId = message['messageId'];

        _channel.invokeMethod("onMessageCB", {"messageId": messageId});

        var method = message['method'];
        if (method == 'onMessage') {
          if (onPushMessage != null) onPushMessage!(WbMessage(message));
        }
      } else if (call.method == 'onRongCallkitMessage') {
        var method = call.arguments['method'];
        if (onRongCallkitMessage != null)
          onRongCallkitMessage!(method, call.arguments);
      }

      return Future.value();
    });

    return _channel.invokeMethod<bool>("configure", {
      "miPushAppId": miPushAppId,
      "miPushAppKey": miPushAppKey,
      "rongAppKey": rongAppKey
    });
  }

  static Future<dynamic> get(String key) {
    return _channel.invokeMethod('get', {'key': key});
  }

  static Future<bool?> set(String key, dynamic value) {
    return _channel.invokeMethod('set', {'key': key, 'value': value});
  }

  static void checkAppUpdate(dynamic cfg) {
    _channel.invokeMethod("checkAppUpdate", cfg);
  }

  static void setAccessToken(String serverAddress, String accessToken) async {
    try {
      _channel.invokeMethod("setAccessToken",
          {"serverAddress": serverAddress, "accessToken": accessToken});
    } catch (e) {
      print(e);
    }
  }

  static void fetchMissingMessage() async {
    var list = await _channel.invokeMethod("fetchMissingMessage");

    list.forEach((message) {
      if (onPushMessage != null) onPushMessage!(WbMessage(message));
    });
  }

  static Future setPushAlias(String alias) {
    return _channel.invokeMethod("setPushAlias", {"alias": alias});
  }

  static Future loginCallkit(
      String token, String userLoginId, String lastName, String headImgUrl) {
    return _channel.invokeMethod("loginCallkit", {
      "token": token,
      "userLoginId": userLoginId,
      "lastName": lastName,
      "headImgUrl": headImgUrl
    });
  }

  static Future<bool> registerHeadlessCallback(
      {Function(dynamic args)? pushCB,
      Function(dynamic args)? callkitCB,
      Function(dynamic args)? heartHitCB,
      int heartHitPeriodSeconds = 5}) async {
    var completer = new Completer<bool>();

    var registrationCBHandler =
        PluginUtilities.getCallbackHandle(_headlessCallbackDispatcher)!
            .toRawHandle();
    var pushCBHandler = pushCB == null
        ? null
        : PluginUtilities.getCallbackHandle(pushCB)!.toRawHandle();
    var callkitCBHandler = callkitCB == null
        ? null
        : PluginUtilities.getCallbackHandle(callkitCB)!.toRawHandle();
    var heartHitCBHandler = heartHitCB == null
        ? null
        : PluginUtilities.getCallbackHandle(heartHitCB)!.toRawHandle();

    _channel.invokeMethod('registerHeadlessCallback', {
      "registrationCB": registrationCBHandler,
      "pushCB": pushCBHandler,
      "callkitCB": callkitCBHandler,
      "heartHitCB": heartHitCBHandler,
      "heartHitPeriodSeconds": heartHitPeriodSeconds
    }).then((dynamic success) {
      completer.complete(true);
    }).catchError((error) {
      String message = error.toString();
      print('[registerHeadlessCallback] ‼️ $message');
      completer.complete(false);
    });
    return completer.future;
  }
}

/// Headless Callback Dispatcher
///
void _headlessCallbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  const MethodChannel _headlessChannel =
      MethodChannel("wb_plugin/headless", JSONMethodCodec());

  _headlessChannel.setMethodCallHandler((MethodCall call) async {
    final args = call.arguments;

    // Run the headless-task.
    try {
      var callbackId = args['callbackId'];
      final Function? callback = PluginUtilities.getCallbackFromHandle(
          CallbackHandle.fromRawHandle(callbackId));
      if (callback == null) {
        print(
            '[BackgroundFetch _headlessCallbackDispatcher] ERROR: Failed to get callback from handle: $args');
        return;
      }
      callback(args);
    } catch (e, stacktrace) {
      print('[BackgroundFetch _headlessCallbackDispather] ‼️ Callback error: ' +
          e.toString());
      print(stacktrace);
    }
  });
  // Signal to native side that the client dispatcher is ready to receive events.
  _headlessChannel.invokeMethod('initialized');
}
