import 'package:flutter/material.dart';

class IconWithCircleSpot extends StatelessWidget {
  final double size;
  final Color color;
  final Widget icon;

  const IconWithCircleSpot(
      {Key? key,
      this.size = 12.0,
      this.color = Colors.redAccent,
      this.icon = const Text('')})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: <Widget>[
        icon,
        Container(
            child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Container(
            alignment: Alignment.topRight,
            height: size,
            width: size,
            color: color,
          ),
        ))
      ],
    );
  }
}

class CircleDotText extends StatelessWidget {
  final double size;
  final double top;
  final double right;
  final Color color;
  final String text;
  const CircleDotText(
      {Key? key,
      this.size = 20.0,
      this.top = 0,
      this.right = 5,
      this.color = Colors.redAccent,
      this.text = 'new'})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: top,
        right: right,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25.0),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(left: 1, right: 1),
            height: size,
            width: size,
            color: color,
            child:
                Text(text, style: TextStyle(color: Colors.white, fontSize: 9)),
          ),
        ));
  }
}
