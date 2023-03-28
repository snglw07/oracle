import 'package:flutter/material.dart';

class CircularImage extends StatelessWidget {
  final double size;
  final ImageProvider image;
  final double marginTop, marginBottom, marginLeft, marginRight;

  CircularImage(this.image,
      {this.size = 0,
      this.marginTop = 0.0,
      this.marginBottom = 0.0,
      this.marginLeft = 0.0,
      this.marginRight = 0.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.only(
          left: this.marginLeft,
          right: this.marginRight,
          top: this.marginTop,
          bottom: this.marginBottom),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(image: image, fit: BoxFit.fill),
        //  boxShadow: [
        //    BoxShadow(
        //      blurRadius: 10,
        //      color: Colors.black45,
        //    )
        //  ]
      ),
    );
  }
}
