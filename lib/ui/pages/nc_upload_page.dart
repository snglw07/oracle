import 'dart:async';
import 'package:city_pickers/modal/result.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' as intl;

import 'package:amap_core_fluttify/amap_core_fluttify.dart';
import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/ui/widgets/Iform_item.dart';

/// 返南人员登记
class NcUploadPage extends StatefulWidget {
  final String? recordId;
  final ValueChanged<Map>? onSave;

  const NcUploadPage({super.key, this.recordId, this.onSave});

  @override
  NcUploadPageState createState() =>
      NcUploadPageState(recordId: recordId, onSave: onSave);
}

class NcUploadPageState extends State<NcUploadPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  NcUploadPageState({this.recordId, this.onSave}) {
    token = this.recordId;
  }

  final String? recordId;
  final ValueChanged<Map>? onSave;
  String? token;

  Map<String, Object?> doc = Map();

  String location = ""; // 定位
  bool loading = false;

  StreamSubscription<Map<String, dynamic>>? nfcIdCardStreamSubscription;
  @override
  void dispose() {
    nfcIdCardStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initListenNfcIdCard();
    //获取定位 ios的需要初始化ios key
    AmapCore.init('ios key');
    _location();
    _initDoc();
  }

  void _initDoc() {
    doc = {
      'recordId': this.recordId ?? '',
      'idcardNumber': '',
      'personName': '',
      'phoneNumber': '',
      'personType': '',
      'toncDate': DateTime.now(),
      'toncType': '',
      'inland': '',
      'gdjs': '',
      'jkzm': '',
      'unitName': '',
      'healthState': '',
      'remark': '',
      'fcitySelected': '',
      'fdistrictId': '',
      'fromAddress': '',
      'streetName': '',
      'raddress': '',
      'refer': 'APP',
    };
    if (ObjectUtil.isNotEmpty(this.recordId)) {
      WbNetApi.exec('app.yqfk.ncupload', params: {'recordId': this.recordId})
          .then((map) {
        var res = map?['exec'];
        setState(() {
          if (res != null) doc.addAll(res as dynamic);
        });
      });
    }
  }

  void _location() {
    WbUtils.locationAddress().then((Map<String, dynamic> map) {
      if (map.containsKey("error")) {
        Notify.error(map["error"], context: context);
      }
      setState(() {
        doc['position'] = map['address'];
        Map<String, dynamic> address = map['addressMap'] ?? {};
        doc['locationStamp'] = address['time'];
        doc['longitude'] = address['longitude'];
        doc['latitude'] = address['latitude'];
        location = (address['address'] ?? address['name'] ?? "").toString();
      });
    });
  }

  void _initListenNfcIdCard() async {
    MainBloc? mainBloc = BlocProvider.of<MainBloc>(context);
    nfcIdCardStreamSubscription =
        mainBloc?.nfcIdCardStream.listen((Map<String, dynamic>? map) {
      if (ObjectUtil.isNotEmpty(map) &&
          ObjectUtil.isNotEmpty(map!['card_no'])) {
        _queryPhone(map['card_no'], personName: map['name'] ?? '');
      }
    });
  }

  void _queryPhone(String value, {String? personName}) async {
    try {
      Map<String, dynamic>? person = await WbNetApi.exec(
          'yqfk.ncperson.uplaod.grv',
          params: {'idcardNo': value});

      if (ObjectUtil.isNotEmpty(person) &&
          ObjectUtil.isNotEmpty(person!['exec'])) {
        Map<String, dynamic>? resp = person['exec'] as dynamic;
        if (kDebugMode) {
          print(resp);
        }
        if (ObjectUtil.isNotEmpty(resp?['toncDate'])) {
          resp!['toncDate'] = DateTime.tryParse(resp['toncDate']);
        }

        setState(() {
          doc = resp ?? Map();
        });
      } else {
        Map<String, dynamic>? res = await WbNetApi.exec(
            'wx.yqfk.person.info.grv',
            params: {'idcardNo': value, 'personName': personName ?? ""});
        if (ObjectUtil.isNotEmpty(res) && ObjectUtil.isNotEmpty(res!['exec'])) {
          Map<String, dynamic> resp = res['exec'] as dynamic;
          setState(() {
            doc['idcardNumber'] = value;
            doc['phoneNumber'] = resp['phoneNumber'] ?? '';
            doc['personName'] = personName ?? resp['personName'];
          });
        } else {
          setState(() {
            doc['personName'] = personName ?? '';
            doc['phoneNumber'] = '';
            doc['idcardNumber'] = value;
          });
        }
      }
    } catch (e) {}
  }

  void _onSubmit(BuildContext context) async {
    // 获取token
    if (loading) {
      Notify.error("处理中，请勿重复点击。", context: context);
      return;
    }

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
    if (ObjectUtil.isEmpty(map['personType']) ||
        ObjectUtil.isEmpty(map['toncDate']) ||
        ObjectUtil.isEmpty(map['toncType']) ||
        ObjectUtil.isEmpty(map['inland']) ||
        ObjectUtil.isEmpty(map['fromAddress']) ||
        ObjectUtil.isEmpty(map['gdjs']) ||
        ObjectUtil.isEmpty(map['streetName']) ||
        ObjectUtil.isEmpty(map['raddress']) ||
        ObjectUtil.isEmpty(map['jkzm']) ||
        ObjectUtil.isEmpty(map['healthState'])) errTag = "请检查必录项是否已经正确录入";

    if (doc['personType'] != '1' && ObjectUtil.isEmpty(map['unitName']))
      errTag = "工作单位不能为空";

    if ('Y' == map['inland'] && ObjectUtil.isEmpty(map['fdistrictId']))
      errTag = "来源地地址不能为空。";

    if ('N' == map['inland'] && ObjectUtil.isEmpty(doc['country']))
      errTag = "来源地国家不能为空";

    if (ObjectUtil.isEmpty(map['personName'])) errTag = "请输入姓名";
    if (!WbUtils.isChinaPhoneLegal(doc['phoneNumber'] as dynamic))
      errTag = "请输入正确的联系电话";
    if (!RegexUtil.isIDCard18Exact(doc['idcardNumber'] as dynamic))
      errTag = "请输入正确的身份证号";

    if ("" != errTag) {
      Notify.error(errTag, context: context, duration: Duration(seconds: 3));
      return;
    }
    DateTime toncDate = map['toncDate'];
    map['toncDate'] = intl.DateFormat("yyyy-MM-dd HH:mm:ss").format(toncDate);
    try {
      IdCardParse idCardParse = IdCardParse(map['idcardNumber']);
      map['age'] = idCardParse.age;
      map['sexId'] = idCardParse.sex;
    } catch (e) {}
    _doSubmit(map);
  }

  void _doSubmit(map) {
    print(map);
    showDialog<Null>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new LoadingDialog(text: '正在保存...');
        });

    WbNetApi.api('app.yqfk.zzsb.store', params: map)
        .then((Map<String, dynamic>? result) {
      Navigator.pop(context);
      if (result?.containsKey('error') == true)
        Notify.error(result!["error"] ?? "保存失败",
            context: context, duration: Duration(seconds: 4));
      else {
        Notify.success("保存上报记录成功",
            context: context, duration: Duration(seconds: 4));
        doc['recordId'] = result?['recordId'] ?? doc['token'];
        if (ObjectUtil.isNotEmpty(this.onSave)) {
          this.onSave!(result!);
        }
      }
    });
  }

  Widget _buildPage(BuildContext context) {
    return ListView(children: <Widget>[
      ITextFieldItem(
          requiredValue: true,
          labelText: '身份证号:',
          inputText: doc['idcardNumber'] ?? "" as dynamic,
          hintText: '请输入或NFC读取（需设备支持）',
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
                RegexUtil.isIDCard18Exact(value)) {
              _queryPhone(value);
            }
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '姓       名：',
          inputText: doc['personName'] ?? "" as dynamic,
          onChange: (value) {
            doc['personName'] = value;
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '联系电话：',
          keyboardType: TextInputType.phone,
          inputText: doc['phoneNumber'] ?? "" as dynamic,
          onChange: (value) {
            doc['phoneNumber'] = value;
          }),
      IFormItem.selectType(
          context,
          '人员类型:',
          doc['personType'] ?? "" as dynamic,
          [
            {'value': '1', 'description': '社区居民'},
            {'value': '2', 'description': '机关事业单位'},
            {'value': '2', 'description': '企业'},
          ],
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['personType'] = res['value'];
          if (res['value'] == '1') doc['unitName'] = '';
        });
      }),
      doc['personType'] != '1'
          ? ITextFieldItem(
              requiredValue: doc['personType'] != '1',
              labelText: '工作单位:',
              inputText: doc['unitName'] ?? "" as dynamic,
              onChange: (value) {
                doc['unitName'] = value;
              })
          : Container(),
      IFormItem.selectDate(context, "返南日期：", doc['toncDate'] ?? "" as dynamic,
          requiredValue: true, lastDate: DateTime.now(), cb: (DateTime res) {
        setState(() {
          doc['toncDate'] = res;
        });
      }),
      IFormItem.selectType(
          context,
          '返南方式:',
          doc['toncType'] ?? "" as dynamic,
          [
            {'value': 'ZJ', 'description': '自驾、专车'},
            {'value': 'GJ', 'description': '公共交通'},
          ],
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['toncType'] = res['value'];
        });
      }),
      IFormItem.selectType(
          context,
          '来  源  地:',
          doc['inland'] as dynamic,
          [
            {'value': 'Y', 'description': '国内'},
            {'value': 'N', 'description': '国外'},
          ],
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['inland'] = res['value'];
          doc['country'] = '';
          doc['fprovinceId'] = '';
          doc['fcityId'] = '';
          doc['fdistrictId'] = '';
          doc['fdistrictName'] = '';
          doc['fcitySelected'] = '';
          doc['fromAddress'] = '';
        });
      }),
      doc['inland'] == 'N'
          ? ITextFieldItem(
              requiredValue: true,
              labelText: '国        家：',
              keyboardType: TextInputType.phone,
              inputText: doc['country'] ?? '' as dynamic,
              onChange: (value) {
                doc['country'] = value;
              })
          : IFormItem.selectCity(
              context,
              '地        址:',
              doc['fcitySelected'] ?? '' as dynamic,
              (ObjectUtil.isEmpty(doc['fdistrictId'])
                      ? "500000"
                      : (doc['fdistrictId'].toString().length > 6
                          ? doc['fdistrictId'].toString().substring(0, 6)
                          : doc['fdistrictId']))!
                  .toString(),
              requiredValue: true, cb: (Map res) async {
              Result result = res['result'];
              if (ObjectUtil.isNotEmpty(result)) {
                setState(() {
                  doc['fprovinceId'] = "${result.provinceId}000000";
                  doc['fcityId'] = "${result.cityId}000000";
                  doc['fdistrictId'] = "${result.areaId}000000";
                  doc['fdistrictName'] = result.areaName;
                  doc['fcitySelected'] =
                      "${result.provinceName}${result.cityName}${result.areaName}";
                });
              }
            }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '详细地址：',
          inputText: doc['fromAddress'] as dynamic,
          onChange: (value) {
            doc['fromAddress'] = value;
          }),
      IFormItem.selectType(
          context,
          '南川固定居所:',
          doc['gdjs'] ?? "" as dynamic,
          [
            {'value': 'Y', 'description': '有'},
            {'value': 'N', 'description': '无'}
          ],
          flex1: 4,
          flex2: 5,
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['gdjs'] = res['value'];
        });
      }),
      IFormItem.selectExecType(context, '现住地址:',
          doc['streetName'] ?? "" as dynamic, 'app.ncjtqy.geolist',
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['streetName'] = res['value'];
        });
      }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '详细地址：',
          inputText: doc['raddress'] ?? "" as dynamic,
          onChange: (value) {
            doc['raddress'] = value;
          }),
      IFormItem.selectType(
          context,
          '健康证明:',
          doc['jkzm'] ?? "" as dynamic,
          [
            {'value': 'Y', 'description': '有'},
            {'value': 'N', 'description': '无'}
          ],
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['jkzm'] = res['value'];
        });
      }),
      IFormItem.selectType(
          context,
          '身体状况:',
          doc['healthState'] ?? "" as dynamic,
          [
            {'value': 'Y', 'description': '健康'},
            {'value': 'N', 'description': '有异常'}
          ],
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['healthState'] = res['value'];
        });
      }),
      doc['healthState'] == 'N'
          ? ITextFieldItem(
              labelText: '异常描述:',
              inputText: doc['healthRemark'] ?? "" as dynamic,
              requiredValue: doc['healthState'] == 'N',
              onChange: (value) {
                doc['healthRemark'] = value;
              })
          : Container(),
      ITextFieldItem(
          labelText: '备        注:',
          inputText: doc['remark'] ?? "" as dynamic,
          onChange: (value) {
            doc['remark'] = value;
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
        appBar: AppBar(title: Text("返南人员登记"), centerTitle: true, actions: [
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
