import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'wb_face.dart';

class WbCamAlert extends StatelessWidget {
  final WbCamModel model;
  final VoidCallback? onOK;
  final VoidCallback? onTry;
  final VoidCallback? onCancel;

  final double score;
  final Widget? faceImg;
  final Widget? fullImg;
  final String? tip;

  WbCamAlert({
    required this.model,
    this.onOK,
    this.onTry,
    this.onCancel,
    this.score = 0,
    required this.faceImg,
    required this.fullImg,
    this.tip,
  });

  Widget buildAlert(String title, List<Widget> children, List<Widget> buttons) {
    return AlertDialog(
        title: Row(children: <Widget>[
          Padding(child: Text(title), padding: EdgeInsets.only(left: 12.0))
        ]),
        titleTextStyle: TextStyle(
            color: Colors.blueAccent,
            fontSize: 18.0,
            fontWeight: FontWeight.w600),
        content: Column(mainAxisSize: MainAxisSize.min, children: children),
        contentTextStyle: TextStyle(
            color: Colors.greenAccent,
            fontSize: 16.0,
            fontWeight: FontWeight.w300),
        contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
        elevation: 10.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14.0))),
        actions: buttons);
  }

  //tip对话框
  Widget buildTipAlert() {
    return buildAlert('消息提示', <Widget>[
      Text(this.tip ?? "",
          style:
              TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900))
    ], <Widget>[
      //FlatButton(child: Text("确定"), onPressed:this.onOK),
      TextButton(child: Text("重试"), onPressed: this.onTry),
      TextButton(child: Text("取消"), onPressed: this.onCancel),
    ]);
  }

  //录像确认框
  Widget buildRecordingAlert() {
    return buildAlert('请确认', <Widget>[
      Text('录像成功')
    ], <Widget>[
      TextButton(child: Text("确定"), onPressed: this.onOK),
      TextButton(child: Text("重试"), onPressed: this.onTry),
      TextButton(child: Text("取消"), onPressed: this.onCancel),
    ]);
  }

  //人脸1:1
  Widget buildFaceCompareAlert() {
    int s = (score * 100).toInt();
    return buildAlert('比对结果[' + s.toString() + ']', <Widget>[
      faceImg!,
      Text('现场采集照片')
    ], <Widget>[
      TextButton(child: Text("确定"), onPressed: this.onOK),
      TextButton(child: Text("重试"), onPressed: this.onTry),
      TextButton(child: Text("取消"), onPressed: this.onCancel),
    ]);
  }

  //人脸采集
  Widget buildFaceCaptureAlert() {
    return buildAlert('采集图像', <Widget>[
      faceImg!,
      Text('现场采集照片')
    ], <Widget>[
      TextButton(child: Text("确定"), onPressed: this.onOK),
      TextButton(child: Text("重试"), onPressed: this.onTry),
      TextButton(child: Text("取消"), onPressed: this.onCancel),
    ]);
  }

  //图像采集
  Widget buildCaptureAlert() {
    return buildAlert('采集图像', <Widget>[
      fullImg!,
      Text('现场采集照片')
    ], <Widget>[
      TextButton(child: Text("确定"), onPressed: this.onOK),
      TextButton(child: Text("重试"), onPressed: this.onTry),
      TextButton(child: Text("取消"), onPressed: this.onCancel),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (this.tip != null)
      return buildTipAlert();
    else if (model == WbCamModel.FACE_CAPTURE ||
        model == WbCamModel.FACE_PHOTO_CAPTURE)
      return buildFaceCaptureAlert();
    else if (model == WbCamModel.FACE_COMPARE ||
        model == WbCamModel.FACE_RECOGNIZER)
      return buildFaceCompareAlert();
    else if (model == WbCamModel.TAKE_PHOTO)
      return buildCaptureAlert();
    else if (model == WbCamModel.VIDEO_AUDIO_RECORDING ||
        model == WbCamModel.VIDEO_RECORDING) return buildRecordingAlert();

    return Container();
  }
}
