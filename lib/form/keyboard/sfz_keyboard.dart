import 'package:cool_ui/cool_ui.dart';
import 'package:flutter/material.dart';

class SfzKeyboard extends StatelessWidget {
  static CKTextInputType inputType = CKTextInputType(name: "CKSfzKeyboard");

  static double getHeight(BuildContext ctx) {
    MediaQueryData mediaQuery = MediaQuery.of(ctx);
    return mediaQuery.size.width / 3 / 2 * 4;
  }

  final String? str;
  final KeyboardController? controller;
  const SfzKeyboard({this.controller, this.str});

  static register() {
    CoolKeyboard.addKeyboard(
        SfzKeyboard.inputType,
        KeyboardConfig(
            builder: (context, controller, str) {
              return SfzKeyboard(controller: controller);
            },
            getHeight: SfzKeyboard.getHeight));
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
            decoration: BoxDecoration(color: Color(0xffafafaf)),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: GridView.count(
                      childAspectRatio: 1.5 / 1,
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
                        buildButton('X'),
                        buildButton('0'),
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
                          ),
                        ),
                      ]),
                ),
                Expanded(
                    flex: 1,
                    child: GridView.count(
                        childAspectRatio: 0.75 / 1,
                        mainAxisSpacing: 0.5,
                        crossAxisSpacing: 0.5,
                        padding: EdgeInsets.only(left: 0.5),
                        crossAxisCount: 1,
                        children: <Widget>[
                          Container(
                            color: Color(0xFFd3d6dd),
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              child: Center(
                                child: Icon(Icons.delete),
                              ),
                              onTap: () {
                                while ((controller?.text.length ?? 0) > 0)
                                  controller?.deleteOne();
                              },
                            ),
                          ),
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
                        ])
                    /*child:Padding(padding: EdgeInsets.only(left:0.5),child:Container(
        color: Color(0xFFd3d6dd),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: Center(child: Text('完成'),),
          onTap: (){
            controller.doneAction();
          },
        ),
      ),), */
                    )
              ],
            ),
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
