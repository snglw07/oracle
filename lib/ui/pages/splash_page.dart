import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';

class SplashPage extends StatefulWidget {
  final bool isLoginIn;

  SplashPage(this.isLoginIn);

  @override
  State<StatefulWidget> createState() {
    return SplashPageState();
  }
}

class SplashPageState extends State<SplashPage> {
  TimerUtil? _timerUtil;

  @override
  void initState() {
    super.initState();
    _doCountDown();
  }

  @override
  void dispose() {
    super.dispose();
    _timerUtil?.cancel(); //记得中dispose里面把timer cancel。
  }

  // 初始opacityLevel为1.0为可见状态，为0.0时不可见
  double opacityLevel = 0;

  int _tick = 0;

  void _doCountDown() {
    _timerUtil = new TimerUtil(mInterval: 1000, mTotalTime: 2500);

    _timerUtil?.setOnTimerTickCallback((int tick) {
      setState(() {
        opacityLevel = (opacityLevel + 0.1) > 1 ? 1 : (opacityLevel + 0.5);
        _tick = tick ~/ 1000;
      });

      if (_tick == 0) {
        _goMain();
      }
    });

    _timerUtil?.startCountDown();
  }

  Widget _buildSplashBg() {
    return AnimatedOpacity(
        // 使用一个AnimatedOpacity Widget
        opacity: opacityLevel,
        duration: new Duration(seconds: 1), //过渡时间：1
        child: new Container(
            child: Image.asset(
          Utils.getImgPath('welcome'),
          width: double.infinity,
          fit: BoxFit.fill,
          height: double.infinity,
        )));
  }

  Widget _buildCountDownBox() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 45),
        child: new Container(
            padding: EdgeInsets.all(10.0),
            child: InkWell(
              child: Text(
                '跳过($_tick)',
                style: new TextStyle(fontSize: 14.0, color: Colors.white),
              ),
              onTap: () {
                _goMain();
              },
            ),
            decoration: new BoxDecoration(
                color: Color(0x66000000),
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                border: new Border.all(width: 0.33, color: Colours.divider))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        child: new Stack(children: <Widget>[
      _buildSplashBg(),
      _buildCountDownBox(),
    ]));
  }

  void _goMain() {
    SpUtil.getInstance().then((_) {
      SpUtil.putString(
          "splashVersion",
          (Platform.isAndroid
              ? AppConfig.androidVersion
              : AppConfig.iosVersion));
    });

    if (widget.isLoginIn)
      Navigator.of(context).pushReplacementNamed('/MainPage');
    else
      Navigator.of(context).pushReplacementNamed('/Login');
  }
}
