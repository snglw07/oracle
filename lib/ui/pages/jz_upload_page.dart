import 'dart:async';

import 'package:amap_core_fluttify/amap_core_fluttify.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/ui/widgets/Iform_item.dart';

class JzUploadPage extends StatefulWidget {
  final String? recordId;
  final String? idcardNumber;
  final ValueChanged<Map>? onSave;

  const JzUploadPage(
      {super.key, this.recordId, this.idcardNumber, this.onSave});

  @override
  JzUploadPageState createState() => JzUploadPageState(
      recordId: recordId, idcardNumber: idcardNumber, onSave: onSave);
}

class JzUploadPageState extends State<JzUploadPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final String? recordId;
  final String? idcardNumber;
  final ValueChanged<Map>? onSave;
  String? token;
  JzUploadPageState({this.recordId, this.idcardNumber, this.onSave}) {
    token = this.recordId;
  }

  Map<String, dynamic> doc = {};
  Map<String, dynamic> address = {};

  String location = ""; // 定位
  StreamSubscription<Map<String, dynamic>>? nfcIdCardStreamSubscription;

  bool loading = false;

  @override
  void dispose() {
    nfcIdCardStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    AmapCore.init('ios key');
    _location();
    _initListenNfcIdCard();

    doc['recordId'] = this.recordId ?? '';
    doc['personName'] = '';
    doc['idcardNumber'] = this.idcardNumber ?? '';
    doc['phoneNumber'] = '';
    doc['ywfr'] = '';
    doc['bodyTemp'] = '';
    doc['refer'] = "APP";
    doc['recordDate'] =
        intl.DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

    if (ObjectUtil.isNotEmpty(this.recordId)) {
      Notify.loading(context: context);
      WbNetApi.queryUpload(recordId: this.recordId).then((map) {
        Notify.dismissAll();
        var res = map?['exec'] as Map<String, dynamic>?;
        setState(() {
          doc.addAll(res ?? <String, dynamic>{});
        });
      });
    }
    if (ObjectUtil.isNotEmpty(this.idcardNumber)) {
      _idCardNoChange(this.idcardNumber, queryRisk: true);
    }
  }

  void _initListenNfcIdCard() async {
    MainBloc? mainBloc = BlocProvider.of<MainBloc>(context);
    nfcIdCardStreamSubscription =
        mainBloc?.nfcIdCardStream.listen((Map<String, dynamic> map) {
      if (ObjectUtil.isNotEmpty(map) && ObjectUtil.isNotEmpty(map['card_no']))
        _queryPhone(map['card_no'], personName: map['name'] ?? '');
    });
  }

  void _queryPhone(String value, {String? personName}) async {
    try {
      var res = await WbNetApi.exec('wx.yqfk.person.info.grv',
              params: {'idcardNo': value, 'personName': personName ?? ""}) ??
          <String, dynamic>{};
      if (ObjectUtil.isNotEmpty(res) && ObjectUtil.isNotEmpty(res['exec'])) {
        var resp = res['exec'] as Map?;
        setState(() {
          doc['idcardNumber'] = value;
          doc['personName'] = ObjectUtil.isNotEmpty(personName)
              ? personName
              : resp?['personName'];
          doc['phoneNumber'] = resp?['phoneNumber'] ?? '';
        });
      } else {
        setState(() {
          doc['personName'] = personName ?? '';
          doc['phoneNumber'] = '';
          doc['idcardNumber'] = value;
        });
      }
      _idCardNoChange(value,
          personName: personName,
          phoneNumber: doc['phoneNumber']?.toString(),
          queryRisk: true);
    } catch (e) {}
  }

  void _idCardNoChange(String? idcardNumber,
      {String? personName, String? phoneNumber, bool queryRisk = false}) {
    Notify.loading(context: context);
    if (queryRisk)
      WbNetApi.queryPersonRiskLevel({'idcardNo': idcardNumber}).then((map) {
        var res = map?['exec'] as Map?;
        Notify.dismissAll();
        if (ObjectUtil.isNotEmpty(res)) {
          setState(() {
            doc['personName'] = ObjectUtil.isNotEmpty(personName)
                ? personName
                : res!['personName'];
            doc['phoneNumber'] = phoneNumber ?? res!['phoneNumber'];
          });
          onConfirm(
              res?['msg'] ??
                  (((ObjectUtil.isNotEmpty(personName)
                              ? personName
                              : res?['personName']) ??
                          "该人员") +
                      "较低风险"),
              phoneNumber ?? res?['phoneNumber']);
        } else {
          onConfirm(
              (((ObjectUtil.isNotEmpty(personName)
                          ? personName
                          : res?['personName']) ??
                      "该人员") +
                  "较低风险"),
              phoneNumber ?? res?['phoneNumber']);
        }
      });
  }

  onConfirm(String msg, String phoneNumber) {
    try {
      WbUtils.confirm(context, content: msg ?? "", okCb: (_) {
        onQueryGis(phoneNumber);
      }, cancelCb: (_) {
        onQueryGis(phoneNumber);
      });
    } catch (e) {}
  }

  /// 查询gis 轨迹信息
  onQueryGis(phoneNumber) async {
    if (ObjectUtil.isEmpty(phoneNumber)) return;
    Map homeRes = await WbNetApi.getHomePageSource() ?? Map();
    if (WbUtils.isCTPhone(phoneNumber) && homeRes['dxOk'] == 'Y') {
      //电信手机
      Clipboard.setData(ClipboardData(text: phoneNumber));
      Notify.error('请将剪贴板的电信手机号码：$phoneNumber 粘贴到页面后，点击获取验证码查询',
              context: context, duration: Duration(seconds: 5))
          .then((_) {
        NavigatorUtil.pushWeb(context, url: homeRes['dxUri'], title: '行程查询')
            .then((_) {
          Notify.info("请继续完善上报内容。", context: context);
        });
      });
    } else if (WbUtils.isCUPhone(phoneNumber) && homeRes['ltOk'] == 'Y') {
      //联通手机
      /* try {
        DioUtil().requestR<Map<String, dynamic>>(
            Method.post, 'http://search1.cubigdata.cn/msg-notify/sms',
            data: {'phone': '$phoneNumber'});
      } catch (e) {} */
      Clipboard.setData(ClipboardData(text: phoneNumber));
      Notify.error('请将剪贴板的联通手机号码：$phoneNumber 粘贴到页面后，点击获取验证码查询',
              context: context, duration: Duration(seconds: 5))
          .then((_) {
        NavigatorUtil.pushWeb(context,
                url: (homeRes['ltUri'] + "&phone=$phoneNumber"), title: '行程查询')
            .then((_) {
          Notify.info("请继续完善上报内容。", context: context);
        });
      });
    } else if (WbUtils.isChinaPhoneLegal(phoneNumber) &&
        homeRes['ydOk'] == 'Y') {
      //移动手机
      Clipboard.setData(ClipboardData(text: phoneNumber));
      Notify.error('请将剪贴板的移动手机号码：$phoneNumber 粘贴到页面后，点击获取验证码查询',
              context: context, duration: Duration(seconds: 5))
          .then((_) {
        NavigatorUtil.pushWeb(context, url: homeRes['ydUri'], title: '行程查询')
            .then((_) {
          Notify.info("请继续完善上报内容。", context: context);
        });
      });
    }
  }
/* 
  void _showPrompt(String phoneNumber) {
    String lastFour = phoneNumber.substring(7);
    String code = '';
    showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('提示'),
              content: SingleChildScrollView(
                  child: ListBody(children: <Widget>[
                Text('请输入手机尾号$lastFour 收到的验证码：'),
                TextField(
                    decoration: InputDecoration(hintText: '验证码'),
                    onChanged: (val) {
                      setState(() {
                        code = val;
                      });
                    })
              ])),
              actions: <Widget>[
                FlatButton(
                    child: Text('确定'),
                    onPressed: () {
                      if (code.length == 6) {
                        Navigator.of(context).pop(code);
                      } else {
                        Notify.error("验证码长度不正确");
                      }
                    })
              ]);
        }).then((val) {});
  } */

  void _location() {
    WbUtils.locationAddress().then((Map<String, dynamic> map) {
      if (map.containsKey("error")) {
        Notify.error(map["error"], context: context);
      }
      setState(() {
        doc['position'] = map['address'];
        address = map['addressMap'] ?? {};
        doc['locationStamp'] = address['time'];
        doc['longitude'] = address['longitude'];
        doc['latitude'] = address['latitude'];
        doc['address'] = address['address'] ?? address['name'] ?? "";
        location = (address['address'] ?? address['name'] ?? "").toString();
      });
    });
  }

  void _onSubmit(BuildContext context) async {
    if (loading) {
      Notify.error("处理中，请勿重复点击。", context: context);
      return;
    }
    // 获取token
    loading = true;
    if (ObjectUtil.isEmpty(this.recordId) && ObjectUtil.isEmpty(token)) {
      token = await WbNetApi.token();
    }
    loading = false;

    Map<String, dynamic> map = Map.from(doc);
    map['token'] = token;
    if (ObjectUtil.isEmpty(map['recordId']))
      map['recordId'] = this.recordId ?? "";
    // 获取定位
    if (ObjectUtil.isEmpty(doc['longitude']) || ObjectUtil.isEmpty(location)) {
      Notify.error("请允许应用获取定位信息。",
          context: context, duration: Duration(seconds: 3));
      _location();
      return;
    }
    // 提交内容校验
    var errTag = "";
    if (ObjectUtil.isNotEmpty(map['bodyTemp'])) {
      try {
        num temp = num.tryParse(doc['bodyTemp']!.toString()) ?? 0;
        if (temp < 34 || temp > 44) errTag = "请输入正确的体温";
      } catch (e) {}
    }

    if (!WbUtils.isChinaPhoneLegal(doc['phoneNumber']?.toString() ?? ""))
      errTag = "请输入正确的联系电话";
    if (!RegexUtil.isIDCard18Exact(doc['idcardNumber']?.toString() ?? ""))
      errTag = "请输入正确的身份证号";
    if (ObjectUtil.isEmpty(map['personName'])) errTag = "请输入姓名";

    if ("" != errTag) {
      Notify.error(errTag, context: context, duration: Duration(seconds: 3));
      return;
    }
    _doSubmit(map);
  }

  void _doSubmit(map) {
    print(map);
    showDialog<Null>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return LoadingDialog(text: '正在保存...');
        });

    WbNetApi.storeJzUpload(map).then((Map<String, dynamic>? result) {
      Navigator.pop(context);
      if (result?.containsKey('error') == true)
        Notify.error(result!["error"] ?? "保存失败",
            context: context, duration: Duration(seconds: 4));
      else {
        Notify.success("保存上报记录成功",
            context: context, duration: Duration(seconds: 4));
        doc['recordId'] = result?['recordId'] ?? doc['token'];
        if (ObjectUtil.isNotEmpty(this.onSave)) {
          this.onSave!(result ?? Map());
        }
      }
    });
  }

  Widget _buildPage(BuildContext context) {
    return ListView(children: <Widget>[
      ITextFieldItem(
          requiredValue: true,
          labelText: '身份证号:',
          hintText: '请输入或NFC读取（需设备支持）',
          inputText: doc['idcardNumber']?.toString() ?? "",
          onChange: (value) async {
            doc['idcardNumber'] = (value ?? "").toUpperCase();
            if (value.length == 18) {
              value = value.toUpperCase();
              if (!RegexUtil.isIDCard18Exact(value)) {
                Notify.error("请输入正确的身份证号", context: context);
                return;
              } else {
                setState(() {
                  doc['idcardNumber'] = value.toUpperCase();
                });
              }
            }
            if (ObjectUtil.isEmpty(this.recordId) &&
                RegexUtil.isIDCard18(value)) {
              _queryPhone(value);
            }
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '姓        名：',
          inputText: doc['personName']?.toString() ?? "",
          onChange: (value) {
            doc['personName'] = value;
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '联系电话：',
          keyboardType: TextInputType.phone,
          inputText: doc['phoneNumber']?.toString() ?? "",
          onChange: (value) {
            doc['phoneNumber'] = value;
          }),
      IFormItem.selectEnumType(
          context, '是否发热:', doc['ywfr']?.toString() ?? "", "BOOL_TYPE",
          cb: (Map res) {
        setState(() {
          doc['ywfr'] = res['value'];
        });
      }),
      ITextFieldItem(
          labelText: '体温(℃)：',
          keyboardType: TextInputType.number,
          inputText: doc['bodyTemp']?.toString() ?? "",
          onChange: (value) {
            doc['bodyTemp'] = value;
          }),
      Container(
          child: Text("当前位置：" + (location ?? '未获取到定位信息。'),
              style: TextStyle(fontSize: 16)))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: AppBar(title: Text("就诊上报"), centerTitle: true, actions: [
          Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 64.0,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.indigoAccent,
                      ),
                      child: Text("保存", style: TextStyle(fontSize: 12.0)),
                      onPressed: () {
                        //onQueryGis("17612809570");
                        _onSubmit(context);
                      })))
        ]),
        body: Container(
            child: Column(children: <Widget>[
          Expanded(
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: _buildPage(context)))
        ])));
  }
}
