import 'dart:async';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:wbyq/blocs/bloc_provider.dart';
import 'package:wbyq/blocs/main_bloc.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/data/net/dio_util.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberFieldKey = new GlobalKey<FormFieldState<String>>();

  String _userLoginId = Constant.TEST_USER_LOGIN,
      _password = AppConfig.isDebug ? "111111" : '',
      _checkCode = '';
  bool _hasCheckCode = false;

  bool _agreeProtocol = true;
  String _protocolContent = '';

  String _phoneNumber = '', _phoneVerifyCode = '';
  String _phoneVerifyStr = '获取验证码';
  int _seconds = 0;

  bool _isObscure = true;
  Color? _eyeColor;
  Timer? _timer;
  String _msgTip = '';
  bool isLogin = false;
  int _ticks = DateTime.now().millisecondsSinceEpoch;

  int _loginType = 0; //0:密码登录，1:手机验证码登录

  _startTimer(int seconds) {
    _cancelTimer();

    _seconds = seconds;

    _timer = new Timer.periodic(new Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        _cancelTimer();
        return;
      }

      _seconds--;
      _phoneVerifyStr = '$_seconds(秒)';
      setState(() {});
      if (_seconds == 0) {
        _phoneVerifyStr = '重新发送';
      }
    });
  }

  _cancelTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    super.dispose();
    _cancelTimer();
  }

  @override
  void initState() {
    super.initState();
  }

  void _changeMsgTip() {
    if (_msgTip.length == 0) return;
    setState(() {
      _msgTip = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    children
      ..add(SizedBox(height: kToolbarHeight))
      ..add(buildTitle())
      ..add(SizedBox(height: 30.0))
      ..add(buildMsgTip());

    if (_loginType == 0) {
      //密码登录
      children
        ..add(SizedBox(height: 30.0))
        ..add(buildUserLoginIdField())
        ..add(SizedBox(height: 30.0))
        ..add(buildPasswordTextField(context));

      if (_hasCheckCode) {
        children
          ..add(SizedBox(height: 30.0))
          ..add(_buildCheckCodeEdit());
      }
    } else {
      //手机验证码登录
      children
        ..add(SizedBox(height: 30.0))
        ..add(buildPhoneNumberField())
        ..add(SizedBox(height: 30.0))
        ..add(_buildPhoneVerifyCodeEdit());
    }

    children
      ..add(SizedBox(height: 30.0))
      ..add(buildProtocol())
      ..add(SizedBox(height: 60.0))
      ..add(buildLoginButton(context))
      ..add(SizedBox(height: 30.0))
      ..add(buildLoginSwitch(context));

    return Scaffold(
        body: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 22.0),
              children: children,
            )));
  }

  Align buildLoginSwitch(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.only(top: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              child: Text(
                _loginType == 0 ? '手机验证码登录' : '密码登录',
                style: TextStyle(color: Colors.grey, fontSize: 14.0),
              ),
              onTap: () {
                setState(() {
                  _loginType = 1 - _loginType;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Align buildLoginButton(BuildContext context) {
    final MainBloc? bloc = BlocProvider.of<MainBloc>(context);

    doLogin() async {
      if (isLogin) {
        Notify.error('登录中，请勿重复点击。', context: context);
        return;
      }
      isLogin = true;
      Notify.loading(
          msg: '登录中...', context: context, duration: Duration(seconds: 15));
      _formKey.currentState?.save();
      String _uuid = "";
      String _deviceType = "";
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        var androidIdPlugin = AndroidId();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _uuid = await androidIdPlugin.getId() ?? androidInfo.id;
        _deviceType = (androidInfo.manufacturer ?? '') +
            " - " +
            (androidInfo.model ?? '');
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        _uuid = iosInfo.identifierForVendor ?? "";
        _deviceType = (iosInfo.model ?? '') + " - " + (iosInfo.name ?? '');
      }

      Map<String, dynamic>? result = await bloc?.loginForAccessToken(
          _loginType == 1 ? _phoneNumber : _userLoginId,
          _password,
          _checkCode,
          _loginType == 1 ? 'DYN-SMS' : 'PWD',
          _phoneVerifyCode,
          sign: _uuid,
          deviceType: _deviceType);
      isLogin = false;
      Future.delayed(Duration(milliseconds: 500), () {
        Notify.dismissAll();
      });

      if (result?.containsKey('error') == true) {
        Notify.error(result!['error'], context: context);
        setState(() {
          _hasCheckCode = result['hasCheckCode'] == true;
          _msgTip = result['error'] ?? '';

          if (result['changeCheckCode'] == true)
            _ticks = DateTime.now().millisecondsSinceEpoch;
        });
      } else {
        Navigator.of(context).pushReplacementNamed('/MainPage');
        WbNetApi.enumMap.clear();
        WbNetApi.homeMap.clear();
      }
    }

    onLogin() async {
      if (!_agreeProtocol) {
        setState(() {
          _msgTip = "仅当同意协议后才能登录";
        });
        return;
      }

      //只有输入的内容符合要求通过才会到达此处
      if (_formKey.currentState?.validate() == true) {
        doLogin();
      }
    }

    return Align(
      child: SizedBox(
        height: 45.0,
        width: 270.0,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black,
            shape: StadiumBorder(side: BorderSide()),
          ),
          child: Text(
            '登录',
            style: Theme.of(context).primaryTextTheme.headlineMedium,
          ),
          onPressed: () {
            onLogin();
          },
        ),
      ),
    );
  }

  TextFormField buildPasswordTextField(BuildContext context) {
    return TextFormField(
      initialValue: _password,
      onSaved: (String? value) => _password = value ?? '',
      obscureText: _isObscure,
      validator: (String? value) {
        _changeMsgTip();

        if (value?.isEmpty == true) return '请输入密码';

        return null;
      },
      decoration: InputDecoration(
          labelText: '密码',
          suffixIcon: IconButton(
              icon: Icon(
                Icons.remove_red_eye,
                color: _eyeColor,
              ),
              onPressed: () {
                setState(() {
                  _isObscure = !_isObscure;
                  _eyeColor = _isObscure
                      ? Colors.grey
                      : Theme.of(context).iconTheme.color;
                });
              })),
    );
  }

  TextFormField buildUserLoginIdField() {
    return TextFormField(
      initialValue: _userLoginId,
      decoration: InputDecoration(
        labelText: '登录名',
      ),
      validator: (String? value) {
        _changeMsgTip();
        //var emailReg = RegExp(
        //    r"[\w!#$%&'*+/=?^_`{|}~-]+(?:\.[\w!#$%&'*+/=?^_`{|}~-]+)*@(?:[\w](?:[\w-]*[\w])?\.)+[\w](?:[\w-]*[\w])?");
        //if (!emailReg.hasMatch(value)) {
        //  return '请输入登录名';
        //}
        value ??= '';

        if (value.isEmpty || value.length < 4 || value.length > 30)
          return '请输入合法的登录名';

        return null;
      },
      onSaved: (String? value) => _userLoginId = value ?? '',
    );
  }

  TextFormField buildPhoneNumberField() {
    return TextFormField(
      key: _phoneNumberFieldKey,
      initialValue: _phoneNumber,
      maxLines: 1,
      maxLength: 11,
      //键盘展示为号码
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: '手机号',
      ),
      validator: (String? value) {
        _changeMsgTip();

        if (!WbUtils.isChinaPhoneLegal(value ?? '')) return '请输入合法的手机号';

        value ??= '';
        if (value.isEmpty || value.length < 5 || value.length > 30)
          return '请输入已注册的手机号';

        return null;
      },
      onSaved: (String? value) => _phoneNumber = value ?? '',
    );
  }

  void _sendSmsMsg() {
    _phoneNumber = _phoneNumberFieldKey.currentState?.value ?? '';

    if (!WbUtils.isChinaPhoneLegal(_phoneNumber)) {
      setState(() {
        _msgTip = '请输入合法手机号';
      });
      return;
    } else {
      setState(() {
        _msgTip = '';
      });
    }

    WbNetApi.sendSmsDynLoginCode(_phoneNumber)
        .then((Map<String, dynamic>? map) {
      if (map?.containsKey("error") == true) {
        setState(() {
          _msgTip = map?['error'];
        });
      } else {
        _startTimer(map?['seconds']);
      }
    });
  }

  Widget _buildPhoneVerifyCodeEdit() {
    var verifyCodeEdit = TextFormField(
      initialValue: _phoneVerifyCode,
      maxLines: 1,
      maxLength: 6,
      //键盘展示为号码
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: '验证码',
      ),
      validator: (String? value) {
        _changeMsgTip();

        if (ObjectUtil.isEmpty(value)) return '请输入短信验证码';

        return null;
      },
      onSaved: (String? value) => _phoneVerifyCode = value ?? '',
    );

    Widget verifyCodeBtn = new InkWell(
      onTap: (_seconds == 0) ? _sendSmsMsg : null,
      child: new Container(
        alignment: Alignment.center,
        width: 100.0,
        height: 36.0,
        decoration: new BoxDecoration(
          border: new Border.all(
            width: 1.0,
            color: Colors.blue,
          ),
        ),
        child: new Text(
          '$_phoneVerifyStr',
          style: new TextStyle(fontSize: 14.0),
        ),
      ),
    );

    return Stack(
      children: <Widget>[
        verifyCodeEdit,
        new Align(
          alignment: Alignment.topRight,
          child: verifyCodeBtn,
        ),
      ],
    );
  }

  Widget _buildCheckCodeEdit() {
    var field = TextFormField(
      initialValue: _checkCode,
      maxLines: 1,
      maxLength: 4,
      //键盘展示为号码
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: '验证码',
      ),
      validator: (String? value) {
        _changeMsgTip();

        if (ObjectUtil.isEmpty(value)) return '请输入验证码';
        return null;
      },
      onSaved: (String? value) => _checkCode = value ?? '',
    );

    var tbn = GestureDetector(
      onTap: () {
        setState(() {
          _ticks = DateTime.now().millisecondsSinceEpoch;
        });
      },
      child: Image.network(
          DioUtil.getAbsoluteUrl('w/control/checkcode?t=$_ticks'),
          headers: DioUtil.getDefHeaders(),
          width: 100,
          height: 40),
    );

    return Stack(
      children: <Widget>[
        field,
        new Align(
          alignment: Alignment.topRight,
          child: tbn, //Text('sss')
        ),
      ],
    );
  }

  Widget buildMsgTip() {
    return Text(
      _msgTip,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 15.0, color: Colors.red),
    );
  }

  Widget buildProtocol() {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, //子组件的排列方式为主轴两端对齐
      children: <Widget>[
        Expanded(
            flex: 1,
            child: Checkbox(
              activeColor: Colors.blue,
              tristate: false,
              value: _agreeProtocol,
              onChanged: (bool? value) {
                setState(() {
                  _agreeProtocol = value ?? false;
                  _msgTip = '';
                });
              },
            )),
        Expanded(
          flex: 3,
          child: GestureDetector(
              onTap: () => showProtocolDlag(),
              child: Text(
                "已阅读并同意\n《健康南川应用使用协议》",
                style: new TextStyle(
                    fontSize: 12.0,
                    color: _agreeProtocol ? Colors.blue : Colors.grey[500]),
              )),
        )
      ],
    );
  }

  Widget buildTitle() {
    return Align(
        alignment: Alignment.center,
        child: Padding(
            padding: EdgeInsets.only(top: 50.0),
            child: Text(
              '健康南川',
              style: TextStyle(fontSize: 25.0),
            )));
  }

  void showProtocolDlag() async {
    if (ObjectUtil.isEmpty(_protocolContent)) {
      _protocolContent =
          await rootBundle.loadString('assets/data/protocol.txt');
    }

    showDialog<void>(
        context: context,
        barrierDismissible: false, //
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.all(12),
            title: const Text('健康南川应用使用协议'),
            actions: <Widget>[
              TextButton(
                child: Text('关闭'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[Text(_protocolContent)],
              ),
            ),
          );
        });
  }
}
