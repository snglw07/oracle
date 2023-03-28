import 'dart:io';

import 'package:flutter/foundation.dart';
//import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

///媒体工具，负责申请权限，选照片，拍照，录音，播放语音
class MediaUtil {
  //FlutterSound flutterSound = new FlutterSound();

  factory MediaUtil() => _getInstance();
  static MediaUtil get instance => _getInstance();
  static MediaUtil? _instance;
  MediaUtil._internal() {
    // 初始化
  }
  static MediaUtil _getInstance() {
    return _instance ??= MediaUtil._internal();
  }

  /// 检测相关权限是否已经打开(根据已有状态值)
  bool checkPermissionsByStatus(Iterable<PermissionStatus> lists) {
    bool result = true;

    for (PermissionStatus permissionStatus in lists) {
      if (permissionStatus != PermissionStatus.granted) {
        result = false;
        break;
      }
    }

    return result;
  }

  //请求权限：相册，相机，麦克风
  Future requestPermissions(Iterable<Permission> ps) async {
    bool result = true;

    for (Permission permissionGroup in ps) {
      PermissionStatus checkPermissionStatus = await permissionGroup.status;

      if (checkPermissionStatus != PermissionStatus.granted) {
        result = false;
        break;
      }
    }

    if (!result) {
      var map = await ps.toList().request();

      result = checkPermissionsByStatus(map.values);

      if (!result) {
        // openAppSettings();
        return false;
      }
    }

    return result;
  }

  //photo控件 不会手动调用拍照方法
  //拍照，成功则返回照片的本地路径，注：Android 必须要加 file:// 头
  Future<String?> takePhoto() async {
    var imagePicker = ImagePicker();
    var imgfile = await imagePicker.pickImage(source: ImageSource.camera);
    if (imgfile == null) {
      return null;
    }
    String imgPath = imgfile.path;
    if (TargetPlatform.android == defaultTargetPlatform) {
      imgPath = "file://" + imgfile.path;
    }
    return imgPath;
  }

  //从相册选照片，成功则返回照片的本地路径，注：Android 必须要加 file:// 头
  Future<String?> pickImage() async {
    var imagePicker = ImagePicker();
    var imgfile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (imgfile == null) {
      return null;
    }
    String imgPath = imgfile.path;
    if (TargetPlatform.android == defaultTargetPlatform) {
      imgPath = "file://" + imgfile.path;
    }
    return imgPath;
  }

  //开始录音
  /* void startRecordAudio() async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path +
        "/" +
        DateTime.now().millisecondsSinceEpoch.toString() +
        ".aac";
    await AudioRecorder.start(
        path: tempPath, audioOutputFormat: AudioOutputFormat.AAC);
  } */

  //录音结束，通过 finished 返回本地路径和语音时长，注：Android 必须要加 file:// 头
  /* void stopRecordAudio(Function(String path, int duration) finished) async {
    Recording recording = await AudioRecorder.stop();
    String path = recording.path;

    if (path == null) {
      if (finished != null) {
        finished(null, 0);
      }
    }

    if (TargetPlatform.android == defaultTargetPlatform) {
      path = "file://" + path;
    }
    if (finished != null) {
      finished(path, recording.duration.inSeconds);
    }
  } */

  // //播放语音
  // void startPlayAudio(String path) {
  //   if (flutterSound.isPlaying) {
  //     stopPlayAudio();
  //   }
  //   flutterSound.startPlayer(path);
  // }

  // //停止播放语音
  // void stopPlayAudio() {
  //   flutterSound.stopPlayer();
  // }
}
