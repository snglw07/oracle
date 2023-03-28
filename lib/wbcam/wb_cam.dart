import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'circle_wave_progress.dart';
import 'wb_draw_objects.dart';
import 'wb_face.dart';
import 'wb_cam_alert.dart';
import 'wb_cam_controller.dart';
import 'wb_cam_result.dart';
import 'wb_cam_util.dart' as wbcamu;

typedef LensDirectionChangedCallback = void Function(
    CameraLensDirection cameraLensDirection);

class WbCam extends StatefulWidget {
  final WbCamModel model;
  //当model为 FACE_COMPARE,FACE_RECOGNIZER,FACE_CAPTURE,FACE_PHOTO_CAPTURE,VIDEO_RECORDING,VIDEO_AUDIO_RECORDING 时 最大时长
  final int limitedSeconds;

  //1:1 1:N 阈值
  final double threshold;

  //1:1 对比的头像文件字节码
  final Uint8List? originalHead;
  //1:1 对比的头像所有者姓名
  final String headUserName;

  //默认镜头 前置/后置
  final CameraLensDirection defaultLensDirection;

  //镜头改变时的回调
  final LensDirectionChangedCallback? lensDirectionChangedCallback;

  //返回的图像为jpg格式,false:为png格式
  final bool returnJpgImage;

  WbCam({
    this.model = WbCamModel.FACE_COMPARE,
    this.limitedSeconds = 60,
    this.threshold = 0.8,
    this.originalHead,
    this.headUserName = "",
    this.defaultLensDirection = CameraLensDirection.front,
    this.lensDirectionChangedCallback,
    this.returnJpgImage = true,
  });

  @override
  _WbCamState createState() {
    WidgetsFlutterBinding.ensureInitialized();

    return _WbCamState();
  }
}

class _WbCamState extends State<WbCam>
    with WidgetsBindingObserver, WbCamController {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _keyCameraPreview = GlobalKey();
  CameraDescription? _currentCameraDescription;

  //当model为VIDEO_RECORDING,VIDEO_AUDO_RECORDING 反回的图像或视频文件（视频为mp4）
  String? _videoCapturedFile;

  //预览图像大小
  Size _imageSize = Size(480, 640);

  //当前人脸位置
  Rect _faceRect = Rect.fromLTRB(0, 0, 0, 0);

  //人脸检测框提示
  String _detectTip = "";

  int _lastRefreshTime = 0;

  //人脸操作TAG
  String _tag = "";

  //当前采集到的人脸像
  Widget? _faceImg;

  //当前采集到的图像
  Widget? _fullImg;

  //当前采集到的人脸像
  Uint8List? _faceImageData;

  //当前采集到的图像
  Uint8List? _fullImageData;

  //1:1 1:N
  double _score = 0;

  //1:1 对比原始头像Provider
  ImageProvider? _originalHeadProvider;

  //当操作失败时的提示信息
  String? _tip;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    if (widget.originalHead != null)
      _originalHeadProvider = wbcamu.toImageProvider(widget.originalHead!);

    camerasAysncInit();
  }

  @override
  void dispose() {
    destroyTimer();
    destroyController();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (!isControllerInitialized()) return;

    if (state == AppLifecycleState.inactive) {
      destroyController();
    } else if (state == AppLifecycleState.resumed) {
      if (!isNullController()) {
        selectLens(controller!.description);
      }
    }
  }

  bool isFaceDetectModel() {
    return widget.model == WbCamModel.FACE_COMPARE ||
        widget.model == WbCamModel.FACE_RECOGNIZER ||
        widget.model == WbCamModel.FACE_CAPTURE ||
        widget.model == WbCamModel.FACE_PHOTO_CAPTURE;
  }

  bool _isFaceDetecting() {
    return isFaceDetectModel() && isTimerWorking();
  }

  //////////////////////controller begin//////////
  @override
  void showCameraException(CameraException e) {
    showError('错误: ${e.code}\n${e.description}');
  }

  @override
  void showError(String message) {
    print(message);
    if (_scaffoldKey.currentState?.context != null)
      ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
  }

  @override
  void onLensChanged(CameraDescription cameraDescription) {
    if (widget.lensDirectionChangedCallback != null)
      widget.lensDirectionChangedCallback!(cameraDescription.lensDirection);

    _currentCameraDescription = cameraDescription;

    if (widget.model == WbCamModel.FACE_COMPARE ||
        widget.model == WbCamModel.FACE_RECOGNIZER) {
      _onFaceAction();
    }
  }

  @override
  bool onUpdateState({VoidCallback? fn}) {
    if (mounted) {
      setState(() {
        if (fn != null) fn();
      });
    }

    return mounted;
  }

  @override
  void onVideoRecordingOK(String videoFile) {
    if (mounted) {
      setState(() {
        _videoCapturedFile = videoFile;
      });
    }
  }

  @override
  void onTakePictureOK(Uint8List pngImageData) {
    if (mounted) {
      setState(() {
        _fullImageData = pngImageData;
        if (_fullImageData != null) _fullImg = Image.memory(_fullImageData!);
      });
    }
  }

  @override
  bool isMounted() {
    return mounted;
  }

  @override
  void onImageStream(
      int rotation, bool mirrorH, bool mirrorV, CameraImage img) {
    if (_isFaceDetecting()) {
      WbFace.tryGetFaceProcessResult(
        tag: _tag,
      ).then((Map map) {
        if (map['result'] == true && map['head'] != null) {
          stopCounter();
          WbFace.stopFaceProcess();

          _faceImageData = map['head'];
          _fullImageData = map.containsKey('image') ? map['image'] : null;

          if (widget.model == WbCamModel.FACE_COMPARE ||
              widget.model == WbCamModel.FACE_RECOGNIZER) {
            var score = map['score'] as num;
            _score = score.toDouble();
          }

          setState(() {
            _faceImg = Image.memory(
              _faceImageData!,
              width: 180.0,
            );
          });
        }
      });
    }

    var nowTime = DateTime.now().millisecondsSinceEpoch;
    var diffMilliseconds = nowTime - _lastRefreshTime;
    if (diffMilliseconds < 100) return;

    _lastRefreshTime = nowTime;

    if (Platform.isAndroid)
      _imageSize = Size(img.height.toDouble(), img.width.toDouble());
    else
      _imageSize = Size(img.width.toDouble(), img.height.toDouble());

    WbFace.detectMaxFaceOnImage(
            tag: _tag,
            bytesList: img.planes.map((plane) {
              return plane.bytes;
            }).toList(),
            bytesPerRowList: img.planes.map((plane) {
              return plane.bytesPerRow;
            }).toList(),
            bytesPerPixelList: img.planes.map((plane) {
              return plane.bytesPerPixel ?? 0;
            }).toList(),
            imageHeight: img.height,
            imageWidth: img.width,
            rotation: rotation,
            mirrorH: mirrorH,
            mirrorV: mirrorV)
        .then((face) {
      if (mounted) {
        if (face != null) {
          var x = face['x'] as num;
          var y = face['y'] as num;
          var width = face['width'] as num;
          var height = face['height'] as num;
          var confidence = ((face['confidence'] as num) * 100).toInt();

          _detectTip =
              " $confidence"; //"s:${face['confidence']},x:${face['x']},y:${face['y']},width:${face['width']},height:${face['height']}";

          _faceRect = Rect.fromLTWH(
              x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble());
        } else {
          _detectTip = "";
          _faceRect = Rect.fromLTWH(0, 0, 0, 0);
        }

        setState(() {});
      }
    });
  }

  @override
  int getLimitedSeconds() {
    return widget.limitedSeconds;
  }

  @override
  CameraLensDirection getDefaultLensDirection() {
    return widget.defaultLensDirection;
  }

  @override
  WbCamModel getCamMode() {
    return widget.model;
  }
  /////////////////////////controller end//////////

  void _onFaceAction() {
    if (!isTimerWorking()) {
      _tag = timestamp();

      WbFace.startFaceProcess(
        model: widget.model,
        tag: _tag,
        limitedSeconds: widget.limitedSeconds,
        originalPic: widget.originalHead,
        threshold: widget.threshold,
      );

      startCounter(() {
        WbFace.stopFaceProcess();
        if (widget.model == WbCamModel.FACE_CAPTURE ||
            widget.model == WbCamModel.FACE_PHOTO_CAPTURE)
          _tip = "采集人脸像失败";
        else if (widget.model == WbCamModel.FACE_COMPARE)
          _tip = "人脸验证失败";
        else if (widget.model == WbCamModel.FACE_RECOGNIZER) _tip = "人脸识别失败";
      });
    }
  }

  Widget _faceDetectWidget() {
    if (!isFaceDetectModel()) return Container();

    return Positioned.fill(
        child: new CustomPaint(
      painter: new DrawObjects(
          _keyCameraPreview, _imageSize, _faceRect, _detectTip, 0),
    ));
  }

  Widget _cameraLensSwitch() {
    List<SpeedDialChild> childButtons = [];

    eachLens((CameraDescription cameraDescription, IconData icon) {
      if (icon == null) return;

      var isSelf = _currentCameraDescription == cameraDescription;
      var isRecording = isRecordingVideo();

      childButtons.add(
        SpeedDialChild(
            child: Icon(icon),
            backgroundColor: isSelf || isRecording ? Colors.grey : null,
            onTap: (isSelf || isRecording)
                ? () => {}
                : () {
                    selectLens(cameraDescription);
                  }),
      );
    });

    childButtons.add(
      SpeedDialChild(
          child: Icon(Icons.arrow_back),
          label: '返回上级',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: () => Navigator.pop(context)),
    );

    return SpeedDial(
      childMargin: EdgeInsets.fromLTRB(0, 0, 20, 40),
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      // this is ignored if animatedIcon is non null
      // child: Icon(Icons.add),
      visible: true,
      // If true user is forced to close dial manually
      // by tapping main button and overlay is not rendered.
      closeManually: false,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      //onOpen: () => print('OPENING DIAL'),
      //onClose: () => print('DIAL CLOSED'),
      tooltip: '摄像头切换',
      heroTag: 'speed-dial-hero-tag',
      //backgroundColor: Colors.white,
      //foregroundColor: Colors.black,
      elevation: 8.0,
      shape: CircleBorder(),
      children: childButtons,
    );
  }

  Widget _confirmWidget() {
    if (_videoCapturedFile == null &&
        _faceImg == null &&
        _fullImg == null &&
        _tip == null) return Container();

    return WbCamAlert(
      model: widget.model,
      onOK: () {
        Navigator.of(context).pop(WbCamResult(
          isOK: true,
          tip: _tip ?? "",
          score: _score,
          faceImageData: widget.returnJpgImage
              ? wbcamu.toJpgImageData(_faceImageData)
              : _faceImageData,
          fullImageData: widget.returnJpgImage
              ? wbcamu.toJpgImageData(_fullImageData)
              : _fullImageData,
          videoFileName: _videoCapturedFile,
        ));
      },
      onTry: () {
        if (widget.model == WbCamModel.VIDEO_AUDIO_RECORDING ||
            widget.model == WbCamModel.VIDEO_RECORDING)
          File(_videoCapturedFile!).delete();

        setState(() {
          _faceImageData = null;
          _fullImageData = null;
          _faceImg = null;
          _fullImg = null;
          _tip = null;
          _score = 0;
          _videoCapturedFile = null;
        });

        if (widget.model == WbCamModel.FACE_COMPARE ||
            widget.model == WbCamModel.FACE_RECOGNIZER) _onFaceAction();
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
      score: (_score * 100).round() / 100,
      faceImg: _faceImg,
      fullImg: _fullImg,
      tip: _tip,
    );
  }

  Widget _faceCompareOriginalPic() {
    if (_originalHeadProvider == null ||
        widget.model != WbCamModel.FACE_COMPARE) return Container();

    return Align(
      alignment: Alignment.topCenter,
      child: Column(children: [
        Container(
          width: 160.0,
          height: 160.0,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.white30, width: 6),
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.fill,
                image:
                    _originalHeadProvider!, //AssetImage('assets/model/wsl1.jpg'),
              )),
        ),
        Text(
          widget.headUserName ?? "",
          style: TextStyle(
            color: Colors.blue,
            fontSize: 25.0,
            fontWeight: FontWeight.w900,
          ),
        )
      ]),
    );
  }

  Widget _cameraPreviewWidget() {
    if (!isControllerInitialized()) {
      return Text(
        '加载中....',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    List<Widget> actionButtons = [];
    if (widget.model == WbCamModel.FACE_CAPTURE ||
        widget.model == WbCamModel.FACE_PHOTO_CAPTURE) {
      actionButtons.add(
        FloatingActionButton(
          onPressed: _onFaceAction,
          child: Icon(Icons.camera),
          tooltip: '人脸像采集',
          heroTag: null,
        ),
      );
    } else if (widget.model == WbCamModel.TAKE_PHOTO) {
      actionButtons.add(
        FloatingActionButton(
          onPressed: onTakePictureButtonPressed,
          child: Icon(Icons.camera),
          heroTag: null,
        ),
      );
    } else if ((widget.model == WbCamModel.VIDEO_RECORDING ||
            widget.model == WbCamModel.VIDEO_AUDIO_RECORDING) &&
        isControllerInitialized()) {
      //开始录像
      actionButtons.add(
        FloatingActionButton(
          onPressed:
              isRecordingVideo() ? () => {} : onStartVideoRecordButtonPressed,
          child: Icon(Icons.play_arrow),
          backgroundColor: isRecordingVideo() ? Colors.grey : null,
          heroTag: null,
          mini: false,
        ),
      );

      //暂停录像
      if (!canResume()) {
        actionButtons.add(Container(
          height: 1,
          padding: EdgeInsets.only(right: 9.0),
        ));
        actionButtons.add(
          FloatingActionButton(
            onPressed: !canPause() ? () => {} : onPauseButtonPressed,
            child: Icon(Icons.pause),
            backgroundColor: canPause() ? null : Colors.grey,
            heroTag: null,
            mini: false,
          ),
        );
      }

      //恢复暂停录像
      if (canResume()) {
        actionButtons.add(Container(
          height: 1,
          padding: EdgeInsets.only(right: 9.0),
        ));
        actionButtons.add(
          FloatingActionButton(
            onPressed: onResumeButtonPressed,
            child: Icon(Icons.play_circle_outline),
            backgroundColor: null, //Colors.grey,
            heroTag: null,
            mini: false,
          ),
        );
      }

      //结束录像
      actionButtons.add(Container(
        height: 1,
        padding: EdgeInsets.only(right: 9.0),
      ));
      actionButtons.add(
        FloatingActionButton(
          onPressed: !isRecordingVideo() ? () => {} : onStopButtonPressed,
          child: Icon(Icons.stop),
          backgroundColor: isRecordingVideo() ? null : Colors.grey,
          heroTag: null,
          mini: false,
        ),
      );
    } else {
      actionButtons.add(
        FloatingActionButton(
          onPressed: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back),
          heroTag: null,
        ),
      );
    }

    return Stack(alignment: FractionalOffset.center, children: <Widget>[
      AspectRatio(
        key: _keyCameraPreview,
        aspectRatio: aspectRatio(),
        child: makeCameraPreview(),
      ),
      Container(
        child: _faceDetectWidget(),
      ),
      !isTimerWorking()
          ? Container()
          : Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Stack(
                    alignment: FractionalOffset.center,
                    children: <Widget>[
                      CircleWaveProgress(
                        size: 100,
                        borderWidth: 10.0,
                        backgroundColor: Colors.transparent,
                        borderColor: Colors.white54,
                        waveColor: Colors.white30,
                        progress: counterProgress(),
                      ),
                      Text(
                        "${currentSecond()} 秒",
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.red,
                        ),
                      ),
                    ]),
              ),
            ),
      _confirmWidget(),
      _faceCompareOriginalPic(),
      Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: actionButtons,
          ),
        ),
      ),
      Align(alignment: Alignment.bottomRight, child: _cameraLensSwitch()),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      body: Container(
        child: Center(
          child: _cameraPreviewWidget(),
        ),
        decoration: BoxDecoration(
          color: Colors.lightBlue,
          border: Border.all(
            color: isRecordingVideo() ? Colors.redAccent : Colors.grey,
            width: 1.0,
          ),
        ),
      ),
    );
  }
}
