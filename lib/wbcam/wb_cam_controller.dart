import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as im;
import 'wb_cam_util.dart' as wbcamu;
import 'wb_face.dart';

typedef EachLensCallback(CameraDescription cameraDescription, IconData icon);

abstract class WbCamController {
  CameraController? controller;

  void showCameraException(CameraException e);
  void showError(String error);
  void onLensChanged(CameraDescription cameraDescription);
  bool onUpdateState({VoidCallback fn});
  void onVideoRecordingOK(String videoFile);
  void onTakePictureOK(Uint8List pngImageData);
  bool isFaceDetectModel();
  bool isMounted();
  void onImageStream(int rotation, bool mirrorH, bool mirrorV, CameraImage img);
  int getLimitedSeconds();
  CameraLensDirection getDefaultLensDirection();
  WbCamModel getCamMode();

  bool isNullController() => controller == null;

  void destroyTimer() {
    _currentSecond = 0;
    _timer?.cancel();
  }

  void destroyController() {
    controller?.dispose();
  }

  bool isControllerInitialized() =>
      !isNullController() && controller!.value.isInitialized;

  bool isRecordingVideo() =>
      !isNullController() && controller!.value.isRecordingVideo;
  double aspectRatio() => controller!.value.aspectRatio;
  //camera 5.6 以上支持
  bool canPause() =>
      controller!.value.isRecordingVideo &&
      !controller!.value.isRecordingPaused;
  bool canResume() =>
      controller!.value.isRecordingVideo && controller!.value.isRecordingPaused;

  //bool canPause()=>false;
  //bool canResume()=>false;

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  List<CameraDescription>? _cameras;

  void camerasAysncInit() async {
    try {
      _cameras = await availableCameras();
    } on CameraException catch (e) {
      showCameraException(e);
    }

    //初始化人脸检测库
    if (isFaceDetectModel()) await wbcamu.initFaceDetectData();

    if (_cameras != null) {
      for (CameraDescription cameraDescription in _cameras!) {
        if (cameraDescription.lensDirection == getDefaultLensDirection()) {
          selectLens(cameraDescription);
          break;
        }
      }
    }
  }

  void eachLens(EachLensCallback cb) {
    if (_cameras != null) {
      for (CameraDescription cameraDescription in _cameras!) {
        IconData icon;
        switch (cameraDescription.lensDirection) {
          case CameraLensDirection.back:
            icon = Icons.camera_rear;
            break;
          case CameraLensDirection.front:
            icon = Icons.camera_front;
            break;
          case CameraLensDirection.external:
            icon = Icons.camera;
            break;
        }

        cb(cameraDescription, icon);
      }
    }
  }

  Timer? _timer;

  //当model为 FACE_COMPARE,FACE_RECOGNIZER,FACE_CAPTURE,FACE_PHOTO_CAPTURE,VIDEO_RECORDING,VIDEO_AUDIO_RECORDING 时
  //动作开始时间（秒）
  int _currentSecond = 0;

  bool isTimerWorking() {
    return _currentSecond > 0 && _currentSecond <= getLimitedSeconds();
  }

  void startCounter(VoidCallback onLimitedSeconds, {bool resetCounter = true}) {
    if (resetCounter) _currentSecond = 0;

    _timer?.cancel();

    _timer = new Timer.periodic(
      Duration(seconds: 1),
      (Timer timer) {
        onUpdateState(fn: () {
          if (_currentSecond >= getLimitedSeconds()) {
            timer.cancel();
            _currentSecond = 0;
            if (onLimitedSeconds != null) onLimitedSeconds();
          } else {
            _currentSecond++;
          }
        });
      },
    );
  }

  void stopCounter({bool resetCurrentSecond = true}) {
    _timer?.cancel();
    if (resetCurrentSecond) _currentSecond = 0;
  }

  double counterProgress() {
    return _currentSecond / getLimitedSeconds() * 100.0;
  }

  int currentSecond() {
    return _currentSecond;
  }

  void selectLens(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller?.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      //camera 5.6 以上支持
      enableAudio: getCamMode() == WbCamModel.VIDEO_AUDIO_RECORDING,
    );

    // If the controller is updated then update the UI.
    controller?.addListener(() {
      onUpdateState();
      if (controller!.value.hasError) {
        //showError('摄像头错误： ${controller.value.errorDescription}');
      }
    });

    try {
      await controller?.initialize();
    } on CameraException catch (e) {
      showCameraException(e);
    }

    if (isMounted() && controller!.value.isInitialized) {
      onUpdateState();

      if (isFaceDetectModel()) {
        int rotation = 0;
        var mirrorH = false, mirrorV = false;
        if (Platform.isAndroid) {
          //android 前置摄像头 rotation: -90 ,mirrorH:false, mirrorV:true
          //android 后置摄像头 rotation: 90, mirrorH:false, mirrorV:false
          if (cameraDescription.lensDirection == CameraLensDirection.front) {
            rotation = -90;
            mirrorH = false;
            mirrorV = true;
          } else if (cameraDescription.lensDirection ==
              CameraLensDirection.back) {
            rotation = 90;
            mirrorH = false;
            mirrorV = false;
          }
        }

        //人脸相关操作需要启动视频流
        await controller!.startImageStream((CameraImage img) {
          if (isMounted() && isFaceDetectModel())
            onImageStream(rotation, mirrorH, mirrorV, img);
        });
      }

      onLensChanged(cameraDescription);
    }
  }

  CameraPreview makeCameraPreview() {
    return CameraPreview(controller!);
  }

  Future<void> startVideoRecording() async {
    if (!controller!.value.isInitialized) {
      showError('错误：请先选择一个摄像头.');
      return null;
    }

    // final Directory extDir = await getApplicationDocumentsDirectory();
    // final String dirPath = '${extDir.path}/video';
    // await Directory(dirPath).create(recursive: true);
    // final String filePath = '$dirPath/${timestamp()}.mp4';

    if (controller!.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      await controller!.startVideoRecording();
    } on CameraException catch (e) {
      showCameraException(e);
      return null;
    }

    startCounter(onStopButtonPressed);
  }

  Future<String?> stopVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      return null;
    }

    String videoCapturedFile;

    try {
      var xfile = await controller!.stopVideoRecording();
      videoCapturedFile = xfile.path;
    } on CameraException catch (e) {
      showCameraException(e);
      return null;
    }
    stopCounter();

    return videoCapturedFile;
  }

  Future<void> pauseVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      return null;
    }

    try {
      //camera 5.6 以上支持
      await controller!.pauseVideoRecording();
    } on CameraException catch (e) {
      showCameraException(e);
      rethrow;
    }
    stopCounter(resetCurrentSecond: false);
  }

  Future<void> resumeVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      return null;
    }

    try {
      //camera 5.6 以上支持
      await controller!.resumeVideoRecording();
    } on CameraException catch (e) {
      showCameraException(e);
      rethrow;
    }

    startCounter(onStopButtonPressed, resetCounter: false);
  }

  Future<String?> takePicture() async {
    if (!controller!.value.isInitialized) {
      showError('错误：请选择摄像头.');
      return null;
    }
    //final Directory extDir = await getApplicationDocumentsDirectory();
    //final String dirPath = '${extDir.path}/photo';
    //await Directory(dirPath).create(recursive: true);
    //String filePath = '$dirPath/${timestamp()}.jpg';
    String filePath;

    if (controller!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      var xfilePath = await controller!.takePicture();
      filePath = xfilePath.path;
    } on CameraException catch (e) {
      showCameraException(e);
      return null;
    }

    return filePath;
  }

  void onTakePictureButtonPressed() {
    takePicture().then((String? filePath) {
      if (filePath == null) return;

      var image = im.decodeImage(File(filePath).readAsBytesSync());

      File(filePath).delete();
      if (image != null) {
        image = im.bakeOrientation(image);
        var fullImageData = im.encodePng(image);

        onTakePictureOK(fullImageData as dynamic);
      }
    });
  }

  void onStartVideoRecordButtonPressed() {
    startVideoRecording();
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((String? filePath) {
      if (filePath != null) onVideoRecordingOK(filePath);
    });
  }

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      onUpdateState();
    });
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      onUpdateState();
    });
  }
}
