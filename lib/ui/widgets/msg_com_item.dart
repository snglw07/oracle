import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/models/msg_com_model.dart';

class MsgComArrowItem extends StatelessWidget {
  const MsgComArrowItem(this.model, {Key? key}) : super(key: key);
  final MsgComModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: Decorations.bottom,
        child: Material(
            color: Colors.white,
            child: Stack(children: <Widget>[
              ListTile(
                  onTap: () {
                    if (model.page == null) {
                      NavigatorUtil.pushWeb(context,
                          title: model.title, url: model.url, isHome: true);
                    } else {
                      NavigatorUtil.pushPage(context, model.page,
                          pageName: model.title);
                    }
                  },
                  leading: Container(
                      padding: EdgeInsets.only(left: 5, right: 0),
                      child: ObjectUtil.isNotEmpty(model.icon)
                          ? model.icon
                          : Icon(FontAwesomeIcons.bell,
                              size: 36,
                              color: ObjectUtil.isNotEmpty(model.color)
                                  ? model.color
                                  : Colors.orange)),
                  title: Container(
                      padding: EdgeInsets.only(top: 10, bottom: 5),
                      child:
                          Text(model.title ?? "", style: TextStyles.listTitle)),
                  subtitle:
                      Text(model.content ?? "", style: TextStyles.listContent)),
              model.msgNum != '0'
                  ? CircleDotText(
                      text: model.msgNum ?? 'new', top: 10, right: 10)
                  : Text('')
            ])));
  }
}

class Notify {
  static const MethodChannel _channel =
      const MethodChannel('PonnamKarthik/fluttertoast');

  static Future<bool> cancel() async {
    bool res = await _channel.invokeMethod("cancel");
    return res;
  }

  static Future<ToastFuture> success(String msg,
      {required BuildContext context,
      Duration duration = const Duration(seconds: 2, milliseconds: 300),
      ToastPosition position = ToastPosition.top,
      TextStyle textStyle = const TextStyle(fontSize: 16),
      EdgeInsetsGeometry textPadding = const EdgeInsets.all(10),
      Color backgroundColor = Colors.green,
      double radius = 10,
      VoidCallback? onDismiss,
      TextDirection? textDirection,
      bool dismissOtherToast = false,
      TextAlign? textAlign}) async {
    return showToast(msg,
        context: context,
        duration: duration,
        position: position,
        textStyle: textStyle,
        textPadding: textPadding,
        backgroundColor: backgroundColor,
        radius: radius,
        onDismiss: onDismiss,
        textDirection: textDirection,
        dismissOtherToast: dismissOtherToast,
        textAlign: textAlign);
  }

  static Future<ToastFuture> error(String msg,
      {required BuildContext context,
      Duration duration = const Duration(seconds: 2, milliseconds: 300),
      ToastPosition position = ToastPosition.top,
      TextStyle textStyle = const TextStyle(fontSize: 16),
      EdgeInsetsGeometry textPadding = const EdgeInsets.all(10),
      Color backgroundColor = Colors.red,
      double radius = 10,
      VoidCallback? onDismiss,
      TextDirection? textDirection,
      bool dismissOtherToast = false,
      TextAlign? textAlign}) async {
    return showToast(msg,
        context: context,
        duration: duration,
        position: position,
        textStyle: textStyle,
        textPadding: textPadding,
        backgroundColor: backgroundColor,
        radius: radius,
        onDismiss: onDismiss,
        textDirection: textDirection,
        dismissOtherToast: dismissOtherToast,
        textAlign: textAlign);
  }

  static Future<ToastFuture> info(String msg,
      {required BuildContext context,
      Duration duration = const Duration(seconds: 2, milliseconds: 300),
      ToastPosition position = ToastPosition.top,
      TextStyle textStyle = const TextStyle(fontSize: 16),
      EdgeInsetsGeometry textPadding = const EdgeInsets.all(10),
      Color? backgroundColor,
      double radius = 10,
      VoidCallback? onDismiss,
      TextDirection? textDirection,
      bool dismissOtherToast = false,
      TextAlign? textAlign}) async {
    return showToast(msg,
        context: context,
        duration: duration,
        position: position,
        textStyle: textStyle,
        textPadding: textPadding,
        backgroundColor: backgroundColor,
        radius: radius,
        onDismiss: onDismiss,
        textDirection: textDirection,
        dismissOtherToast: dismissOtherToast,
        textAlign: textAlign);
  }

  static Future<ToastFuture> loading(
      {String msg = '加载中...',
      required BuildContext context,
      Duration duration = const Duration(seconds: 2, milliseconds: 300),
      ToastPosition position = ToastPosition.top,
      TextStyle textStyle = const TextStyle(fontSize: 16),
      EdgeInsetsGeometry textPadding = const EdgeInsets.all(10),
      Color backgroundColor = Colors.grey,
      double radius = 10,
      VoidCallback? onDismiss,
      TextDirection? textDirection,
      bool dismissOtherToast = false,
      TextAlign? textAlign}) async {
    return showToast(msg,
        context: context,
        duration: duration,
        position: position,
        textStyle: textStyle,
        textPadding: textPadding,
        backgroundColor: backgroundColor,
        radius: radius,
        onDismiss: onDismiss,
        textDirection: textDirection,
        dismissOtherToast: dismissOtherToast,
        textAlign: textAlign);
  }

  static void dismissAll() {
    dismissAllToast();
  }

  static Widget noneWidget({String msg = '什么都没有....'}) {
    return Container(
        width: double.infinity,
        height: 300,
        child: Column(children: [
          Expanded(
              child: Container(
                  alignment: Alignment(0, 0.5),
                  child: Icon(FontAwesomeIcons.ravelry,
                      color: Colors.grey.withOpacity(0.5), size: 100)),
              flex: 1),
          Expanded(child: Text(msg, style: TextStyle(fontSize: 18)), flex: 1)
        ]));
  }
}
