import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/utils/util_index.dart';

class ProgressView extends StatelessWidget {
  final Widget? widget;
  const ProgressView({Key? key, this.widget}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      children: <Widget>[
        SizedBox(
            width: 24.0,
            height: 24.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
            )),
        ObjectUtil.isNotEmpty(widget) ? widget! : Text('')
      ],
    ));
  }
}

class CardWithRoundedRectTlBr extends StatelessWidget {
  final Widget? child;
  const CardWithRoundedRectTlBr({Key? key, this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.zero,
                bottomLeft: Radius.zero,
                bottomRight: Radius.circular(20.0))),
        child: child);
  }
}

class CardWithRoundedRectTrBl extends StatelessWidget {
  final Widget? child;
  const CardWithRoundedRectTrBl({Key? key, this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.circular(20.0),
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.zero)),
        child: child);
  }
}

class CardWithRoundedRect extends StatelessWidget {
  final Widget? child;
  const CardWithRoundedRect({Key? key, this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0))),
        child: child);
  }
}

class MessageTime extends StatelessWidget {
  final String time;
  const MessageTime(this.time, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(10),
        child: Container(
          padding: EdgeInsets.only(top: 2, bottom: 2, left: 5, right: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.grey.withOpacity(0.4),
          ),
          child: Text(
            time ?? '',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ));
  }
}

class BtnWithCircle extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Icon icon;
  final double size;

  const BtnWithCircle(this.text,
      {Key? key,
      required this.onPressed,
      this.color = Colors.blue,
      this.size = 50,
      this.icon = const Icon(Icons.ac_unit)})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.all(Radius.circular(50.0)),
          ),
          child: IconButton(
              padding: EdgeInsets.all(4),
              icon: icon,
              color: color,
              onPressed: onPressed),
        ),
        Text(text,
            style: size > 45 ? TextStyles.listHeader15 : TextStyles.listBlack13)
      ],
    );
  }
}

class BtnWithText extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Icon icon;
  const BtnWithText(this.text,
      {Key? key,
      required this.onPressed,
      this.color = Colors.blue,
      this.icon = const Icon(Icons.ac_unit)})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          child: IconButton(
            padding: EdgeInsets.all(2),
            icon: icon,
            color: color,
            onPressed: onPressed,
          ),
        ),
        Text(
          text,
          style: TextStyles.listBlack13,
        )
      ],
    );
  }
}

class OnLineStatusIconMap {
  static const Map<String, dynamic> statusMap = {
    'online': online,
    'busy': busy,
    'leave': leave
  };
  static const Map<String, dynamic> online = {
    'icon': Icon(Icons.sentiment_satisfied, size: 16, color: Colors.black54),
    'color': Colors.orange,
    'text': '在线'
  };
  static const Map<String, dynamic> busy = {
    'icon': Icon(Icons.not_interested, size: 16, color: Colors.white54),
    'color': Colors.red,
    'text': '忙碌'
  };
  static const Map<String, dynamic> leave = {
    'icon': Icon(Icons.access_time, size: 16, color: Colors.white54),
    'color': Colors.grey,
    'text': '离开'
  };
}
