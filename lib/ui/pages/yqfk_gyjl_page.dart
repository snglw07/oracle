import 'dart:async';
import 'dart:io';

import 'package:amap_core_fluttify/amap_core_fluttify.dart';
import 'package:city_pickers/city_pickers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:permission_handler/permission_handler.dart';
import 'package:wbyq/application.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/ui/widgets/Iform_item.dart';
import 'package:wbyq/ui/widgets/circular_md5_image.dart';
import 'package:wbyq/utils/media_util.dart';

/// 购药记录
class YqfkGyjlPage extends StatefulWidget {
  final String? recordId;
  final ValueChanged<Map>? onSave;

  const YqfkGyjlPage({super.key, this.recordId, this.onSave});

  @override
  YqfkGyjlPageState createState() =>
      YqfkGyjlPageState(recordId: recordId, onSave: onSave);
}

class YqfkGyjlPageState extends State<YqfkGyjlPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  YqfkGyjlPageState({this.recordId, this.onSave}) {
    token = this.recordId;
  }

  final String? recordId;
  final ValueChanged<Map>? onSave;
  String? token;
  List<Map<String, dynamic>> ypList = [];
  String imageUrl = '';
  bool isLoading = false;

  Map<String, dynamic> doc = {};

  String? location; // 定位
  bool loading = false;

  final String myId = Application.userLoginModel.userLoginId ?? "";

  MainBloc? mainBloc;
  ApplicationBloc? bloc;

  StreamSubscription<Map<String, dynamic>>? nfcIdCardStreamSubscription;

  @override
  void dispose() {
    nfcIdCardStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    bloc = BlocProvider.of<ApplicationBloc>(context);
    super.initState();
    _initListenNfcIdCard();
    //获取定位 ios的需要初始化ios key
    AmapCore.init('ios key');
    _location();
    _initDoc();
    //请求权限

    MediaUtil.instance.requestPermissions([
      Permission.phone,
      Permission.photos,
      Permission.camera,
      Permission.microphone,
    ]);
  }

  Future getImage(ImageSource source, var index) async {
    var imagePicker = ImagePicker();
    var imageFile = await imagePicker.pickImage(source: source);
    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      print(imageFile);

      Map<String, dynamic>? result =
          await WbNetApi.postFile(File(imageFile.path), imageFile.path);
      if (result?.containsKey("error") == true) {
        Notify.error(result!["error"] ?? "" as dynamic, context: context);
      } else {
        ypList.forEach((m) {
          if (m['index'] == index) {
            List<Map<String, dynamic>> l = <Map<String, dynamic>>[];
            l = m['imageList'] as dynamic;
            l.add(result ?? <String, dynamic>{});
            setState(() {
              m['imageList'] = l;
            });
          }
        });
        Notify.success("保存图片成功",
            context: context, duration: Duration(seconds: 2));
      }
      //uploadFile();
    }
  }

  void _initDoc() {
    setState(() {
      List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
      //ypList = list;
      ypList = [];
      ypList.add({"ypName": "", "index": 0, "ypType": "", "imageList": list});
      doc = {
        'recordId': '',
        'idcardNumber': '',
        'personName': '',
        'phoneNumber': '',
        'sexId': '',
        'ypType': '',
        'age': '',
        'sojourn': '',
        'fprovinceId': '',
        'fcityId': '',
        'fdistrictId': '',
        'fromAddress': '',
        'toncDate': DateTime.now(),
        'rdistrictId': '',
        'raddress': '',
        'contactHistory': '',
        'temperature': '',
        'symptomCode': '',
        'symptomCodeStr': '',
        'symptomDesc': '',
        'ypName': '',
        'latitude': '',
        'longitude': '',
        'position': '',
        'locationStamp': '',
      };
    });
  }

  void _location() {
    WbUtils.locationAddress().then((Map<String, dynamic> map) {
      if (map.containsKey("error")) {
        Notify.error(map["error"], context: context);
      }
      setState(() {
        doc['position'] = map['address'];
        Map<String, Object?> address = map['addressMap'];
        doc['locationStamp'] = address['time'] as dynamic;
        doc['longitude'] = address['longitude'] as dynamic;
        doc['latitude'] = address['latitude'] as dynamic;
        location = address['address'] ?? address['name'] as dynamic;
      });
    });
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
      IdCardParse idCardParse = IdCardParse(value);
      print("------------------------");
      print(idCardParse.sex);
      setState(() {
        doc['age'] = idCardParse.age;
        doc['sexId'] = idCardParse.sex == 'MALE'
            ? '1'
            : idCardParse.sex == 'FEMALE'
                ? '2'
                : '';
      });

      Map<String, dynamic>? res = await WbNetApi.exec('wx.yqfk.person.info.grv',
          params: {'idcardNo': value, 'personName': personName ?? ""});
      if (ObjectUtil.isNotEmpty(res) && ObjectUtil.isNotEmpty(res!['exec'])) {
        Map resp = res['exec'] as dynamic;
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

  void _onSubmit(BuildContext context) async {
    print(doc);
    print(ypList);
    // 获取token
    if (loading) {
      Notify.error("处理中，请勿重复点击。", context: context);
      return;
    }

    loading = true;
    /*if (ObjectUtil.isEmpty(this.recordId) && ObjectUtil.isEmpty(token)) {
      token = await WbNetApi.token();
    }*/
    loading = false;

    Map<String, dynamic> map = Map.from(doc);
    //map['token'] = token;
    if (ObjectUtil.isEmpty(map['recordId']))
      map['recordId'] = this.recordId ?? "";

    // 提交内容校验
    var errTag = "";
    if (ObjectUtil.isEmpty(map['idcardNumber']) ||
        ObjectUtil.isEmpty(map['personName']) ||
        ObjectUtil.isEmpty(map['phoneNumber']) ||
        ObjectUtil.isEmpty(map['sexId']) ||
        ObjectUtil.isEmpty(map['raddress']) ||
        ObjectUtil.isEmpty(map['sojourn']) ||
        ObjectUtil.isEmpty(map['contactHistory']) ||
        ObjectUtil.isEmpty(map['symptomCode']) ||
        ObjectUtil.isEmpty(map['rdistrictId'])) errTag = "请检查必录项是否已经正确录入";

    if (map['sojourn'] == '1' && ObjectUtil.isEmpty(map['fdistrictId']))
      errTag = "来源地地址不能为空。";

    if (map['sojourn'] == '1' && ObjectUtil.isEmpty(map['toncDate']))
      errTag = "返南时间不能为空。";

    if (ypList.length == 0) errTag = "药品信息不能少于一条";

    ypList.forEach((m) {
      if (m['ypName'] == "" ||
          ObjectUtil.isEmpty(m['ypName']) ||
          m['ypType'] == "" ||
          ObjectUtil.isEmpty(m['ypType'])) {
        errTag = "药品名称或药名类型不能为空。";
      }
      List<Map<String, dynamic>> l = [];
      List<Map<String, dynamic>> list = [];
      l = m['imageList'] as dynamic;
      for (var it in l) {
        list.add({'storeId': it['storeId'].toString()});
      }
      m['imageList'] = list;
    });

    if (ObjectUtil.isEmpty(map['personName'])) errTag = "请输入姓名";
    if (!WbUtils.isChinaPhoneLegal(doc['phoneNumber'] ?? "" as dynamic))
      errTag = "请输入正确的联系电话";
    if (!RegexUtil.isIDCard18Exact(doc['idcardNumber'] ?? "" as dynamic))
      errTag = "请输入正确的身份证号";

    map['ypList'] = ypList.toString();

    if ("" != errTag) {
      Notify.error(errTag, context: context, duration: Duration(seconds: 3));
      return;
    }

    DateTime toncDate = map['toncDate'];
    map['toncDate'] = intl.DateFormat("yyyy-MM-dd HH:mm:ss").format(toncDate);

    _doSubmit(map);
  }

  void _addYpList() {
    print("========================");
    print(ypList);
    var size = ypList.length;
    List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
    setState(() {
      ypList
          .add({"ypName": "", "index": size, 'ypType': "", "imageList": list});
    });
  }

  void _deleteYpList(index) {
    print(index);
    print(ypList);
    if (ypList.length == 1) {
      Notify.error("最少输入一个药品名称",
          context: context, duration: const Duration(seconds: 4));
      return;
    }
    ypList.forEach((m) {
      if (m['index'] == index) {
        setState(() {
          ypList.remove(m);
        });
      }
    });
  }

  void _doSubmit(map) {
    print(map);
    showDialog<Null>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new LoadingDialog(text: '正在保存...');
        });

    WbNetApi.api('yqfk.app.save.gyjl', params: map)
        .then((Map<String, dynamic>? result) {
      Navigator.pop(context);
      if (result?.containsKey('error') == true)
        Notify.error(result!["error"] ?? "保存失败",
            context: context, duration: Duration(seconds: 4));
      else {
        Notify.success("保存记录成功",
            context: context, duration: Duration(seconds: 4));
        //doc['recordId'] = result['recordId'] ?? doc['token'];
        _initDoc();
        /*if (ObjectUtil.isNotEmpty(this.onSave)) {
          this.onSave(result);
        }*/
      }
    });
  }

  Widget _buildPage(BuildContext context) {
    //是否有如下症状 0:自觉正常 1:发热37.3℃以下  2:发热37.3℃（含）以上 3:干咳 4:乏力 5:寒战
    // 6:咳痰 7:鼻塞 8:流涕 9:咽痛 10:头痛 11:气促 12:肌肉酸痛 13:胸闷 14:胸痛 15:关节酸痛 16:恶心 17:呕吐 18:呼吸困难 19:腹泻 20:腹痛 21:结膜充血 99: 其他症状
    List<Map<String, dynamic>> symptom = [
      {'description': "发热", 'value': "发热"},
      {'description': "咳嗽", 'value': "咳嗽"},
      {'description': "咽痛", 'value': "咽痛"},
      {'description': "胸闷", 'value': "胸闷"},
      {'description': "呼吸困难", 'value': "呼吸困难"},
      {'description': "轻度纳差", 'value': "轻度纳差"},
      {'description': "乏力", 'value': "乏力"},
      {'description': "精神稍差", 'value': "精神稍差"},
      {'description': "腹泻", 'value': "腹泻"},
      {'description': "头痛", 'value': "头痛"},
      {'description': "心慌", 'value': "心慌"},
      {'description': "结膜炎", 'value': "结膜炎"},
      {'description': "轻度四肢或腰背部肌肉酸痛", 'value': "轻度四肢或腰背部肌肉酸痛"},
    ];

    List<Map<String, dynamic>> symptomCode = [
      {'description': "发热", 'value': "1"},
      {'description': "咳嗽", 'value': "2"},
      {'description': "咽痛", 'value': "3"},
      {'description': "胸闷", 'value': "4"},
      {'description': "呼吸困难", 'value': "5"},
      {'description': "轻度纳差", 'value': "6"},
      {'description': "乏力", 'value': "7"},
      {'description': "精神稍差", 'value': "8"},
      {'description': "腹泻", 'value': "9"},
      {'description': "头痛", 'value': "10"},
      {'description': "心慌", 'value': "11"},
      {'description': "结膜炎", 'value': "12"},
      {'description': "轻度四肢或腰背部肌肉酸痛", 'value': "13"},
    ];

    return ListView(children: <Widget>[
      ITextFieldItem(
          requiredValue: true,
          labelText: '身份证号:',
          inputText: doc['idcardNumber'] ?? "" as dynamic,
          hintText: '请输入或NFC读取（需设备支持）',
          onChange: (value) async {
            doc['idcardNumber'] = (value ?? "").toUpperCase();
            if (value.length == 18) {
              print(value);
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
          '性       别：',
          doc['sexId'] ?? "" as dynamic,
          [
            {'value': '1', 'description': '男'},
            {'value': '2', 'description': '女'},
          ],
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['sexId'] = res['value'];
        });
      }),
      IFormItem.selectExecType(context, '现住地址:',
          doc['rdistrictId'] ?? "" as dynamic, 'app.ncjtqy.geolist.wbyq',
          requiredValue: true, cb: (Map res) {
        setState(() {
          print(res);
          doc['rdistrictId'] = res['value'];
          doc['raddress'] = res['text'];
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
          '近一个月旅居史：',
          doc['sojourn'] ?? "" as dynamic,
          [
            {'value': '1', 'description': '中国大陆其他省（自治区）市'},
            {'value': '2', 'description': '中国港澳台地区'},
            {'value': '3', 'description': '国外'},
            {'value': ' ', 'description': '无'},
          ],
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['sojourn'] = res['value'];
          if (doc['sojourn'] == ' ' ||
              doc['sojourn'] == '2' ||
              doc['sojourn'] == '3') {
            doc['fprovinceId'] = '';
            doc['fcityId'] = '';
            doc['fdistrictId'] = '';
            doc['fromAddress'] = '';
          }
        });
      }),
      if (doc['sojourn'] == '1')
        IFormItem.selectCity(context, '来    源   地:',
            doc['fromAddress'] ?? "" as dynamic, "500000", requiredValue: true,
            cb: (Map res) async {
          Result result = res['result'];
          if (ObjectUtil.isNotEmpty(result)) {
            setState(() {
              doc['fprovinceId'] = "${result.provinceId}000000";
              doc['fcityId'] = "${result.cityId}000000";
              doc['fdistrictId'] = "${result.areaId}000000";
              //doc['fdistrictName'] = result.areaName;
              doc['fromAddress'] =
                  "${result.provinceName}${result.cityName}${result.areaName}";
            });
          }
        }),
      if (doc['sojourn'] == '1' ||
          doc['sojourn'] == '2' ||
          doc['sojourn'] == '3')
        IFormItem.selectDate(context, "返南日期：", doc['toncDate'] ?? "" as dynamic,
            requiredValue: true, lastDate: DateTime.now(), cb: (DateTime res) {
          setState(() {
            doc['toncDate'] = res;
          });
        }),
      IFormItem.selectType(
          context,
          '14日内新冠接触史：',
          doc['contactHistory'] ?? "" as dynamic,
          [
            {'value': 'Y', 'description': '有'},
            {'value': 'N', 'description': '无'},
          ],
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['contactHistory'] = res['value'];
        });
      }),
      IFormItem.selectCheckBox(context, '症        状:',
          doc['symptomCodeStr'] ?? "" as dynamic, symptom, requiredValue: true,
          cb: (Map res) {
        print(res);
        setState(() {
          print(res);
          doc['symptomCodeStr'] = res['strValue'];
          var list = [];
          res['value'].forEach((var contagion) {
            for (var it in symptomCode) {
              if (contagion == it['description']) {
                list.add(it['value']);
                continue;
              }
            }
          });
          doc['symptomCode'] = list.toString();
        });
      }),
      ITextFieldItem(
          labelText: '其他症状:',
          inputText: doc['symptomDesc'] ?? "" as dynamic,
          onChange: (value) {
            doc['symptomDesc'] = value;
          }),
      Container(
          child: Wrap(
              spacing: 22,
              children: ypList.map((Map m) {
                return Column(children: <Widget>[
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          width: 500,
                          height: 40,
                          //color: Colors.pink,
                          child: ITextFieldItem(
                              labelText: '药品名称：',
                              inputText: m['ypName'],
                              requiredValue: true,
                              onChange: (value) {
                                m['ypName'] = value;
                              }),
                        ),
                        BtnWithCircle('拍照',
                            size: 35, icon: Icon(Icons.photo_camera, size: 25),
                            onPressed: () {
                          getImage(ImageSource.camera, m['index']);
                        }),
                        BtnWithCircle('图片',
                            size: 35,
                            icon: Icon(Icons.image, size: 25), onPressed: () {
                          getImage(ImageSource.gallery, m['index']);
                        }),
                        BtnWithCircle('删除',
                            size: 35,
                            icon: Icon(Icons.delete, size: 25), onPressed: () {
                          _deleteYpList(m['index']);
                        }),
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 500,
                          height: 40,
                          //color: Colors.pink,
                          child: IFormItem.selectType(
                              context,
                              '药品类型：',
                              m['ypType'],
                              [
                                {'value': '1', 'description': '止咳'},
                                {'value': '2', 'description': '退烧'},
                                {'value': '3', 'description': '抗病毒'},
                                {'value': '4', 'description': '抗感染'},
                              ],
                              requiredValue: true, cb: (Map res) {
                            setState(() {
                              m['ypType'] = res['value'];
                            });
                          }),
                        ),
                      ]),
                  Row(
                      //mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        if (ObjectUtil.isEmpty(m['imageList']) ||
                            m['imageList'].length == 0)
                          Container(
                            height: 100,
                            //color: Colors.pink,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: Colors.white,
                              ),
                              onPressed: () {},
                              child: Text("药品图片"),
                            ),
                          ),
                        if (ObjectUtil.isNotEmpty(m['imageList']) ||
                            m['imageList'].length != 0)
                          Container(
                              child: Wrap(
                                  spacing: 22,
                                  children: m['imageList'].map<Widget>((a) {
                                    return ImageView(a);
                                  }).toList())),
                      ]),
                ]);
              }).toList())),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            width: 100,
            height: 40,
            //color: Colors.pink,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                _addYpList();
              },
              child: Text("添加药品"),
            ),
          ),
        ],
      ),
      Container(
          child: Text("当前位置：" + (location ?? '未获取到定位信息。'),
              style: TextStyle(fontSize: 16)))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: AppBar(title: Text("售药登记"), centerTitle: true, actions: [
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
