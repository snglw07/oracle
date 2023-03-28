import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

enum NFCStatus {
  none,
  reading,
  read,
  stopped,
  error,
}

class NfcData {
  final String? id;
  final Map<dynamic, dynamic>? content;
  final String? error;
  final String? statusMapper;

  NFCStatus? status;

  NfcData({
    this.id,
    required this.content,
    this.error,
    this.statusMapper,
  });

  factory NfcData.fromMap(Map<dynamic, dynamic> data) {
    NfcData result = NfcData(
      id: data['nfcId'] as String?,
      content:
          data['nfcContent'] as Map<dynamic, dynamic>? ?? <dynamic, dynamic>{},
      error: data['nfcError'] as String?,
      statusMapper: data['nfcStatus'] as String?,
    );
    switch (result.statusMapper) {
      case 'none':
        result.status = NFCStatus.none;
        break;
      case 'reading':
        result.status = NFCStatus.reading;
        break;
      case 'read':
        result.status = NFCStatus.read;
        break;
      case 'stopped':
        result.status = NFCStatus.stopped;
        break;
      case 'error':
        result.status = NFCStatus.error;
        break;
      default:
        result.status = NFCStatus.none;
    }
    return result;
  }
}

class IdCloudPlugin {
  static const MethodChannel _channel =
      MethodChannel('id_cloud_plugin'); //com.jqsoft.idcloudmb.IdCloudPlugin
  static const stream = EventChannel(
      'id_cloud_plugin/nfcReader'); //com.jqsoft.idcloudmb.IdCloudPlugin/nfcReader

  static Future<String?> Function(String uid)? onRequestAccessToken;

  static Future<NfcData> read({String? instruction}) async {
    var data = await _callRead(instruction: instruction);
    final NfcData result = NfcData.fromMap(data);
    return result;
  }

  static Stream<NfcData> onTagDiscovered({String? instruction}) {
    if (Platform.isIOS) {
      _callRead(instruction: instruction);
    }
    return stream.receiveBroadcastStream().map((rawNfcData) {
      return NfcData.fromMap(rawNfcData);
    });
  }

  static Future<Map<dynamic, dynamic>> _callRead({instruction = String}) async {
    return await _channel.invokeMethod(
        'NfcRead', <dynamic, dynamic>{"instruction": instruction});
  }

  static Future<bool> init(
      {required String netAddress,
      required String uid,
      List<String>? subscribers,
      List<String>? notifiers}) async {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'getAccessToken') {
        return onRequestAccessToken!(uid);
      }

      return Future<String?>.value();
    });

    if (Platform.isAndroid) {
      var r = await _channel.invokeMethod<bool>('NfcInit', <dynamic, dynamic>{
        'netAddress': netAddress,
        'uid': uid,
        'subscribers': subscribers,
        'notifiers': notifiers
      });

      return r == true;
    } else {
      return true;
    }
  }

  static Future<NFCAvailability> checkNFCAvailability() async {
    var availability =
        "NFCAvailability.${await _channel.invokeMethod<String>("NfcAvailable")}";
    return NFCAvailability.values.firstWhere(
      (item) => item.toString() == availability,
      orElse: () => NFCAvailability.notSupported,
    );
  }
}

enum NFCAvailability { available, disabled, notSupported }
