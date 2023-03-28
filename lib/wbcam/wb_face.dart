import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum WbCamModel {
  FACE_COMPARE,
  FACE_RECOGNIZER,
  FACE_CAPTURE,
  FACE_PHOTO_CAPTURE,
  TAKE_PHOTO,
  VIDEO_RECORDING,
  VIDEO_AUDIO_RECORDING
}

class WbFace {
  static const MethodChannel _channel = const MethodChannel('wb_face');

  static Future<bool> ensureFaceModelInitialized(String modelPath) async {
    return await _channel.invokeMethod('ensureFaceModelInitialized', {
      "modelPath": modelPath,
    });
  }

  static Future<Map> startFaceProcess({
    required WbCamModel model,
    required String tag,
    required int limitedSeconds,
    double threshold = 0,
    Uint8List? originalPic,
  }) async {
    String faceModel;
    switch (model) {
      case WbCamModel.FACE_COMPARE:
        faceModel = "FACE_COMPARE";
        break;
      case WbCamModel.FACE_RECOGNIZER:
        faceModel = "FACE_RECOGNIZER";
        break;
      case WbCamModel.FACE_CAPTURE:
        faceModel = "FACE_CAPTURE";
        break;
      case WbCamModel.FACE_PHOTO_CAPTURE:
        faceModel = "FACE_PHOTO_CAPTURE";
        break;
      default:
        faceModel = "";
        break;
    }

    return await _channel.invokeMethod('startFaceProcess', {
      "model": faceModel,
      "tag": tag,
      "limitedSeconds": limitedSeconds,
      "threshold": threshold,
      "originalPic": originalPic,
    });
  }

  static Future<Map> tryGetFaceProcessResult(
      {required String tag, bool pngfmt = true}) async {
    return await _channel.invokeMethod(
        'tryGetFaceProcessResult', {"tag": tag, "pngfmt": pngfmt});
  }

  static Future stopFaceProcess() async {
    return await _channel.invokeMethod('stopFaceProcess');
  }

  static Future<Uint8List> extractFeature(Uint8List imgDataBuf) async {
    return await _channel.invokeMethod('extractFeature', {
      "imgDataBuf": imgDataBuf,
    });
  }

  //android 前置摄像头 rotation: -90 ,mirrorH:false, mirrorV:true
  //android 后置摄像头 rotation: 90, mirrorH:false, mirrorV:false
  static Future<Map> detectMaxFaceOnImage(
      {required String tag,
      required List<Uint8List> bytesList,
      int imageHeight = 1280,
      int imageWidth = 720,
      List<int>? bytesPerRowList, // Android only
      List<int>? bytesPerPixelList, // Android only
      int rotation = 90, // Android only
      bool mirrorH = false, // Android only
      bool mirrorV = false, //Android only
      bool storeTmpDetectImage = false,
      bool storeTmpHeadImage = false}) async {
    return await _channel.invokeMethod(
      'detectMaxFaceOnImage',
      {
        "tag": tag,
        "bytesList": bytesList,
        "imageHeight": imageHeight,
        "imageWidth": imageWidth,
        "bytesPerRowList": bytesPerRowList,
        "bytesPerPixelList": bytesPerPixelList,
        "rotation": rotation,
        "mirrorH": mirrorH,
        "mirrorV": mirrorV,
        "storeTmpDetectImage": storeTmpDetectImage,
        "storeTmpHeadImage": storeTmpHeadImage
      },
    );
  }
}
