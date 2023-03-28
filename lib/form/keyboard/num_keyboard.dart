import 'package:cool_ui/cool_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NumKeyboard extends StatelessWidget {
  static const CKTextInputType inputType =
      const CKTextInputType(name: 'CKNumKeyboard');
  static double getHeight(BuildContext ctx) {
    MediaQueryData mediaQuery = MediaQuery.of(ctx);
    return mediaQuery.size.width / 3 / 2 * 4;
  }

  final String? str;
  final KeyboardController? controller;
  const NumKeyboard({this.controller, this.str});

  static register() {
    CoolKeyboard.addKeyboard(
        NumKeyboard.inputType,
        KeyboardConfig(
            builder: (context, controller, str) {
              return NumKeyboard(controller: controller);
            },
            getHeight: NumKeyboard.getHeight));
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQuery = MediaQuery.of(context);
    return Material(
      child: DefaultTextStyle(
          style: TextStyle(
              fontWeight: FontWeight.w500, color: Colors.black, fontSize: 23.0),
          child: Container(
            height: getHeight(context),
            width: mediaQuery.size.width,
            decoration: BoxDecoration(
              color: Color(0xffafafaf),
            ),
            child: GridView.count(
                childAspectRatio: 2 / 1,
                mainAxisSpacing: 0.5,
                crossAxisSpacing: 0.5,
                padding: EdgeInsets.all(0.0),
                crossAxisCount: 3,
                children: <Widget>[
                  buildButton('1'),
                  buildButton('2'),
                  buildButton('3'),
                  buildButton('4'),
                  buildButton('5'),
                  buildButton('6'),
                  buildButton('7'),
                  buildButton('8'),
                  buildButton('9'),
                  Container(
                    color: Color(0xFFd3d6dd),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      child: Center(
                        child: Icon(Icons.backspace),
                      ),
                      onTap: () {
                        controller?.deleteOne();
                      },
                      onLongPress: () {
                        while ((controller?.text.length ?? 0) > 0)
                          controller?.deleteOne();
                      },
                    ),
                  ),
                  buildButton('0'),
                  Container(
                    color: Color(0xFFd3d6dd),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      child: Center(
                        child: Text('完成'),
                      ),
                      onTap: () {
                        controller?.doneAction();
                      },
                    ),
                  ),
                ]),
          )),
    );
  }

  Widget buildButton(String title, {String? value}) {
    if (value == null) {
      value = title;
    }
    return Container(
      color: Colors.white,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: Text(title),
        ),
        onTap: () {
          controller?.addText(value!);
        },
      ),
    );
  }
}
