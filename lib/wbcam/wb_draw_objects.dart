import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class DrawObjects extends CustomPainter {
  final GlobalKey<State<StatefulWidget>> keyCameraPreview;
  final Size imageSize;
  final Rect faceRect;
  final String tip;
  final double scanLinePosScale;
  final bool drawTimeLine;

  DrawObjects(this.keyCameraPreview, this.imageSize, this.faceRect, this.tip,
      this.scanLinePosScale,
      {this.drawTimeLine = false});

  void drawFaceRect() {}

  @override
  void paint(Canvas canvas, Size size) {
    var renderPreview =
        keyCameraPreview.currentContext?.findRenderObject() as RenderBox?;

    if (renderPreview == null) return;

    final sizeRed = renderPreview.size;

    final positionRed = renderPreview.localToGlobal(Offset.zero);
    var offsetX = positionRed.dx;
    var offsetY = positionRed.dy;

    var ratioW = sizeRed.width / imageSize.width;
    var ratioH = sizeRed.height / imageSize.height;

    Paint paint = Paint();
    paint.color = Color(0xFF0099ff); // Color.fromARGB(255, 0, 0, 255);
    paint.strokeWidth = 4;
    var rect = faceRect;
    double x1 = offsetX + rect.left * ratioW,
        x2 = offsetX + rect.right * ratioW,
        y1 = offsetY + rect.top * ratioH,
        y2 = offsetY + rect.bottom * ratioH;
    TextSpan span = TextSpan(
        style: TextStyle(
            color: Colors.blue,
            //background: paint,
            fontWeight: FontWeight.bold,
            fontSize: 14),
        text: tip);
    TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x1 + 1, y1 + 1));

    final highlighter = Paint()
      ..style = PaintingStyle.fill
      //..style = PaintingStyle.stroke
      //..strokeWidth = size.longestSide / 100
      ..color = paint.color.withOpacity(0.3);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, y2)
      ..lineTo(x2, y2)
      ..lineTo(x2, y1)
      ..lineTo(x1, y1)
      ..lineTo(x1, y2)
      ..lineTo(0, y2)
      ..lineTo(0, 0);
    canvas.drawPath(path, highlighter);

    if (rect.width > 0 && rect.height > 0) {
      var offset = 20;
      canvas.drawLine(Offset(x1, y1), Offset(x1 + offset, y1), paint);
      canvas.drawLine(Offset(x1, y1), Offset(x1, y1 + offset), paint);

      canvas.drawLine(Offset(x2, y1), Offset(x2 - offset, y1), paint);
      canvas.drawLine(Offset(x2, y1), Offset(x2, y1 + offset), paint);

      canvas.drawLine(Offset(x1, y2), Offset(x1, y2 - offset), paint);
      canvas.drawLine(Offset(x1, y2), Offset(x1 + offset, y2), paint);

      canvas.drawLine(Offset(x2, y2), Offset(x2, y2 - offset), paint);
      canvas.drawLine(Offset(x2, y2), Offset(x2 - offset, y2), paint);

      if (drawTimeLine) {
        var dstY = (y2 - y1) * scanLinePosScale;

        Paint paint1 = Paint();
        paint1.color = Color(0xFF0099ff);
        paint1.strokeWidth = 1;

        canvas.drawLine(
            Offset(x1 + 40, y1 + dstY), Offset(x2 - 40, y1 + dstY), paint1);
      }
    }
  }

  @override
  bool shouldRepaint(DrawObjects oldDelegate) {
    return true;
  }
}
