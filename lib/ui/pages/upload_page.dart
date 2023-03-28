import 'dart:async';

import 'package:amap_core_fluttify/amap_core_fluttify.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:city_pickers/city_pickers.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/ui/widgets/Iform_item.dart';

class UploadPage extends StatefulWidget {
  final String? recordId;
  final ValueChanged<Map<String, dynamic>>? onSave;

  const UploadPage({super.key, this.recordId, this.onSave, bool scan = false});

  @override
  State createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? token;

  Map<String, dynamic> doc = {};
  Map<String, dynamic> address = {};
  Map<String, dynamic> cc = {};

  bool toNc = true;
  bool personToNc = false;
  String originLabel = ''; //到达城市
  String toLabel = ''; // 去城市
  String ccLabel = ""; // 车次
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

    token = widget.recordId;

    _initListenNfcIdCard();
    //获取定位 ios的需要初始化ios key
    AmapCore.init('ios key');
    _location();
    doc = {
      'recordId': widget.recordId ?? '',
      'scheduleId': '',
      'personName': '',
      'idcardNumber': '',
      'phoneNumber': '',
      'ywfr': '',
      'toNc': '',
      'withChild': 'N',
      'childrenNum': '',
      'jkzm': '',
      'toXxAddress': '',
      'refer': 'APP',
    };
    if (ObjectUtil.isNotEmpty(widget.recordId)) {
      WbNetApi.queryUpload(recordId: widget.recordId).then((map) {
        Map<String, dynamic> res = map?['exec'] ?? {};
        setState(() {
          doc.addAll(res);
          originLabel = res['fromDistrictName'] ?? "" as dynamic;
          toLabel = res['toDistrictName'] ?? "" as dynamic;
          personToNc = res['personToNc'] == 'Y';
          if (res.containsKey("scheduleId")) {
            ccLabel = res['ccLabel'] ?? "" as dynamic;
          }
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
        address = map['addressMap'] ?? <String, dynamic>{};
        doc['locationStamp'] = address['time'];
        doc['longitude'] = address['longitude'];
        doc['latitude'] = address['latitude'];
        location = address['address'] ?? address['name'] ?? "" as dynamic;
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

  void _validateContinue(ccMap) {
    if (ObjectUtil.isNotEmpty(ccMap)) {
      int carrierNum = ccMap['carrierNum'] ?? 1;
      int checknum = ccMap['checknum'] ?? 0;
      if (carrierNum <= checknum) {
        WbUtils.confirm(context, content: "当前车次已全部上报，是否确认继续增加或修改？",
            cancelCb: (context) {
          Navigator.pop(context);
          return;
        });
      }
    }
  }

  void _queryPhone(String value, {String? personName}) async {
    try {
      Map<String, dynamic>? res = await WbNetApi.exec('wx.yqfk.person.info.grv',
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
    } catch (e) {}
  }

  _ccChecked(result) {
    setState(() {
      _validateContinue(result);
      if (ObjectUtil.isNotEmpty(result)) {
        if ((result['toNc'] == 'Y') != personToNc) {
          toNc = true;
          cc = <String, dynamic>{};
          doc['scheduleId'] = '';
          ccLabel = '请选择';
          Notify.error("您选择的班次与乘客行程类型有冲突，请核实。", context: context);
          return;
        }
        cc = result;
        toNc = cc['toNc'] == 'Y';
        doc['toNc'] = cc['toNc'];
        doc['scheduleId'] = cc['value'];
        ccLabel = cc['description'] ?? '请选择' as dynamic;
        if (ObjectUtil.isEmpty(widget.recordId)) {
          if (toNc) {
            toLabel = '南川区';
            originLabel = '';
            doc['fromDistrictId'] = '';
            doc['toProvinceId'] = '500000';
            doc['toCityId'] = '500100';
            doc['toDistrictId'] = '500119';
            doc['toDistrictName'] = '南川区';
            doc["toCityNameFull"] = "重庆市市辖区南川区";
          } else {
            toLabel = '';
            originLabel = '南川区';
            doc['toDistrictId'] = '';
            doc['fromProvinceId'] = '500000';
            doc['fromCityId'] = '500100';
            doc['fromDistrictId'] = '500119';
            doc['fromDistrictName'] = '南川区';
            doc['fromAddress'] = '重庆市市辖区南川区';
          }
        }
      }
    });
  }

  void _onSubmit(BuildContext context) async {
    // 获取token
    if (loading) {
      Notify.error("处理中，请勿重复点击。", context: context);
      return;
    }
    loading = true;
    if (ObjectUtil.isEmpty(widget.recordId) && ObjectUtil.isEmpty(token)) {
      token = await WbNetApi.token();
    }
    loading = false;

    Map<String, dynamic> map = Map.from(doc);
    map['token'] = token;
    if (ObjectUtil.isEmpty(map['recordId'])) {
      map['recordId'] = widget.recordId ?? "";
    }

    // 获取定位
    if (ObjectUtil.isEmpty(doc['longitude']) || ObjectUtil.isEmpty(location)) {
      Notify.error("请允许应用获取定位信息。",
          context: context, duration: Duration(seconds: 3));
      _location();
      return;
    }
    // 校验车次上面人员 是否已经全部扫描
    _validateContinue(cc);
    // 提交内容校验
    var errTag = "";
    if (toNc) {
      if (ObjectUtil.isEmpty(map['fromDistrictId']) ||
          ObjectUtil.isEmpty(map['withChild']) ||
          ObjectUtil.isEmpty(map['toDistrictId']) ||
          ObjectUtil.isEmpty(map['toXxAddress']) ||
          ObjectUtil.isEmpty(map['jkzm']) ||
          ObjectUtil.isEmpty(map['sffr']) ||
          ObjectUtil.isEmpty(map['ywfr'])) errTag = "请检查必录项是否已经正确录入";
      if ('Y' == map['jkzm'] && ObjectUtil.isEmpty(map['hospitalName'])) {
        errTag = "有健康证明时，开具医院不能为空。";
      }
    } else {
      if (ObjectUtil.isEmpty(map['withChild']) ||
          ObjectUtil.isEmpty(map['fromDistrictId']) ||
          ObjectUtil.isEmpty(map['toDistrictId'])) errTag = "请检查必录项是否已经正确录入";
    }
    if ('Y' == map['withChild']) {
      if (ObjectUtil.isEmpty(map['childrenNum']) ||
          !RegexUtil.matches("[1-9]", map['childrenNum'] ?? "")) {
        errTag = "请输入正确的免费儿童数量";
      }
    }
    if (ObjectUtil.isEmpty(map['personName'])) errTag = "请输入乘客姓名";
    if (!WbUtils.isChinaPhoneLegal(doc['phoneNumber'] ?? "" as dynamic)) {
      errTag = "请输入正确的联系电话";
    }
    if (!RegexUtil.isIDCard18Exact(doc['idcardNumber'] ?? "" as dynamic)) {
      errTag = "请输入正确的身份证号";
    }
    if (ObjectUtil.isEmpty(map['scheduleId'])) errTag = "请选择车次信息";

    if ("" != errTag) {
      Notify.error(errTag,
          context: context, duration: const Duration(seconds: 3));
      return;
    }
    if (ObjectUtil.isEmpty(widget.recordId) &&
        ObjectUtil.isNotEmpty(map["toCityNameFull"])) {
      map['toAddress'] = map["toCityNameFull"] + map['toXxAddress'];
    }

    _doSubmit(map);
  }

  void _doSubmit(map) {
    if (kDebugMode) {
      print(map);
    }
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return LoadingDialog(text: '正在保存...');
        });

    WbNetApi.storeUpload(map).then((Map<String, dynamic>? result) {
      Navigator.pop(context);
      if (result?.containsKey('error') == true) {
        Notify.error(result!["error"] ?? "保存失败",
            context: context, duration: const Duration(seconds: 4));
      } else {
        Notify.success("保存上报记录成功",
            context: context, duration: const Duration(seconds: 4));
        doc['recordId'] = result?['recordId'] ?? doc['token'];
        if (ObjectUtil.isNotEmpty(widget.onSave)) {
          widget.onSave!(result ?? <String, dynamic>{});
        }
      }
    });
  }

  _buildCCinfo() {
    return Container(
        height: 48,
        decoration: Decorations.bottom2,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          const Expanded(
              flex: 1,
              child: Row(children: <Widget>[
                Text("*", style: TextStyle(fontSize: 16, color: Colors.red)),
                Text("车次信息：", style: TextStyle(fontSize: 16))
              ])),
          Expanded(
              flex: 2,
              child: Container(
                  padding: const EdgeInsets.only(left: 10),
                  child: FutureBuilder(
                      future: WbNetApi.querySchedule(),
                      builder: (BuildContext context,
                          AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                        if (!snapshot.hasData) {
                          return const Text("请选择",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16));
                        }

                        List list = (snapshot.data!["exec"] ?? []) as List;
                        return ShowBottomSheet(
                            hintText: Text(
                                ObjectUtil.isNotEmpty(ccLabel)
                                    ? ccLabel
                                    : "请选择",
                                textAlign: TextAlign.start,
                                style: const TextStyle(fontSize: 16)),
                            dataList: list,
                            callBack: (var result) {
                              _ccChecked(result);
                            });
                      }))),
          const SizedBox(width: 24, child: Icon(Icons.arrow_drop_down))
        ]));
  }

  Widget _buildPage(BuildContext context) {
    return ListView(children: <Widget>[
      _buildCCinfo(),
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
            if (ObjectUtil.isEmpty(widget.recordId) &&
                RegexUtil.isIDCard18Exact(value)) {
              _queryPhone(value);
            }
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '乘客姓名：',
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
      IFormItem.selectEnumType(
          context, '携带免费儿童:', doc['withChild'] ?? "" as dynamic, "BOOL_TYPE",
          requiredValue: true, flex1: 4, flex2: 5, cb: (Map res) {
        setState(() {
          doc['withChild'] = res['value'];
        });
      }),
      ITextFieldItem(
          requiredValue: doc['withChild'] == 'Y',
          labelText: '免费儿童数量：',
          keyboardType: TextInputType.number,
          inputText: doc['childrenNum'] ?? "" as dynamic,
          flex1: 4,
          flex2: 5,
          onChange: (value) {
            doc['childrenNum'] = value;
          }),
      IFormItem.selectCity(
          context,
          '出发地:',
          originLabel ?? "请选择",
          ObjectUtil.isEmpty(doc['fromDistrictId'])
              ? "500000"
              : doc['fromDistrictId'] ?? "" as dynamic,
          requiredValue: true, cb: (Map res) async {
        Result result = res['result'];
        if (ObjectUtil.isNotEmpty(result)) {
          String ywfr = "N";
          try {
            Map<String, dynamic>? map =
                await WbNetApi.api("yqfk.rish.level", params: {
              "provinceId": "${result.provinceId}000000",
              "cityId": "${result.cityId}000000",
              "districtId": '${result.areaId}000000',
            });

            if (ObjectUtil.isNotEmpty(map) && 'Y' == map!['highRisk']) {
              ywfr = 'Y';
            }
          } catch (e) {
            log(e.toString());
          }

          setState(() {
            doc['ywfr'] = ywfr;
            doc['fromProvinceId'] = result.provinceId;
            doc['fromCityId'] = result.cityId;
            doc['fromDistrictId'] = result.areaId;
            doc['fromDistrictName'] = result.areaName;
            doc['fromAddress'] =
                "${result.provinceName}${result.cityName}${result.areaName}";

            originLabel = result.areaName ?? "";
          });
        }
      }),
      /*   ITextFieldItem(
          requiredValue: true,
          labelText: '详细出发地:',
          inputText: doc['fromAddress'],
          onChange: (value) {
            doc['fromAddress'] = value;
          }), */
      IFormItem.selectCity(
          context,
          '目的地:',
          toLabel ?? "请选择",
          ObjectUtil.isEmpty(doc['toDistrictId'])
              ? "500119"
              : doc['toDistrictId'] ?? "" as dynamic,
          requiredValue: true, cb: (Map res) {
        setState(() {
          Result result = res['result'];
          if (ObjectUtil.isNotEmpty(result)) {
            setState(() {
              doc['toProvinceId'] = result.provinceId;
              doc['toCityId'] = result.cityId;
              doc['toDistrictId'] = result.areaId;
              doc['toDistrictName'] = result.areaName;
              doc['toCityNameFull'] =
                  "${result.provinceName}${result.cityName}${result.areaName}";
              toLabel = result.areaName ?? "";
            });
          }
        });
      }),
      ITextFieldItem(
          requiredValue: toNc,
          labelText: '详细目的地:',
          inputText: doc['toXxAddress'] ?? "" as dynamic,
          hintText: ObjectUtil.isNotEmpty(doc['toXxAddress'])
              ? doc['toXxAddress'] ?? "" as dynamic
              : "X乡镇(街道)X小区X栋X号",
          onChange: (value) {
            doc['toXxAddress'] = value;
          }),
      IFormItem.selectEnumType(
          context, '高风险地区乘客:', doc['ywfr'] ?? "" as dynamic, "BOOL_TYPE",
          requiredValue: toNc, flex1: 4, flex2: 5, cb: (Map res) {
        setState(() {
          doc['ywfr'] = res['value'];
        });
      }),
      IFormItem.selectType(
          context,
          '发热症状:',
          doc['sffr'] ?? "" as dynamic,
          [
            {'value': 'Y', 'description': '有'},
            {'value': 'N', 'description': '无'}
          ],
          requiredValue: toNc, cb: (Map res) {
        setState(() {
          doc['sffr'] = res['value'];
        });
      }),
      IFormItem.selectType(
          context,
          '健康证明:',
          doc['jkzm'] ?? "" as dynamic,
          [
            {'value': 'Y', 'description': '有'},
            {'value': 'N', 'description': '无'}
          ],
          requiredValue: toNc, cb: (Map res) {
        setState(() {
          doc['jkzm'] = res['value'];
        });
      }),
      ITextFieldItem(
          requiredValue: doc['jkzm'] == 'Y',
          labelText: '开具医院:',
          inputText: doc['hospitalName'] ?? "" as dynamic,
          onChange: (value) {
            doc['hospitalName'] = value;
          }),
      Text("当前位置：$location", style: const TextStyle(fontSize: 16))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: AppBar(title: const Text("乘客上报"), centerTitle: true, actions: [
          Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 64.0,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.indigoAccent,
                      ),
                      child: const Text("保存", style: TextStyle(fontSize: 12.0)),
                      onPressed: () {
                        _onSubmit(context);
                      })))
        ]),
        body: Column(children: <Widget>[
          Expanded(
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildPage(context)))
        ]));
  }
}
