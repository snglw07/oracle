import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:wbyq/application.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/ui/pages/jz_upload_page.dart';
import 'package:wbyq/ui/pages/my_jz_upload_page.dart';
import 'package:wbyq/ui/pages/my_person_upload_page.dart';
import 'package:wbyq/ui/pages/my_upload_page.dart';
import 'package:wbyq/ui/pages/nc_upload_page.dart';
import 'package:wbyq/ui/pages/schedule_page.dart';
import 'package:wbyq/ui/pages/yqfk_gyjl_page.dart';
import 'package:wbyq/ui/pages/student_class_page.dart';
import 'package:wbyq/ui/pages/student_list_page.dart';
import 'package:wbyq/ui/pages/upload_page.dart';
import 'package:wbyq/ui/widgets/circular_md5_image.dart';
import 'package:wbyq/wb_plugin.dart';
import 'dart:convert' as convert;

import '../../marquee_widget.dart';

bool isHomeInit = true;

class HeadImgLeading extends StatelessWidget {
  const HeadImgLeading({super.key});

  @override
  Widget build(BuildContext context) {
    final MainBloc? bloc = BlocProvider.of<MainBloc>(context);
    return StreamBuilder<Map<String, dynamic>>(
        stream: bloc?.checkLoginStream,
        initialData: null,
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, dynamic>> snapshot) {
          String? thumbMd5 =
              snapshot.data == null ? null : snapshot.data!["thumb"];

          return CircularMd5Image(thumbMd5);
        });
  }
}

class HeadStausLeading extends StatelessWidget {
  final String onlineStatus;
  const HeadStausLeading(this.onlineStatus, {super.key});
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? icon =
        OnLineStatusIconMap.statusMap[onlineStatus] as dynamic;
    if (ObjectUtil.isNotEmpty(icon)) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Container(
              height: 16,
              width: 16,
              child: icon!['icon'],
              color: icon['color']));
    } else {
      return Container();
    }
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback? openDrawer;
  final String? labelId;
  const HomePage({Key? key, this.labelId, this.openDrawer}) : super(key: key);

  @override
  _HomePageState createState() =>
      _HomePageState(labelId: labelId, openDrawer: openDrawer);
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final VoidCallback? openDrawer;
  final String? labelId;
  _HomePageState({this.labelId, this.openDrawer});
  MainBloc? bloc;
  String appId = 'wbyq';
  String? userLoginId = Application.userLoginModel.userLoginId;
  bool canScanBarcode = false;

  bool jt = false;
  bool yy = false;
  bool xx = false;
  bool yf = false;
  bool admin = false;

  Map<String, dynamic> homeRes = {};
  @override
  void initState() {
    super.initState();
    bloc = BlocProvider.of<MainBloc>(context);
    _initStatus();
  }

  _initStatus() async {
    appId = await WbUtils.getAppId();
    try {
      setState(() {});
    } catch (e) {}
  }

  @override
  bool get wantKeepAlive => true;

  Widget buildMainGridView(BuildContext context, String tag) {
    List<Map<String, dynamic>> allBusiness = [
      {
        "id": 'scan',
        "name": "扫码识别",
        "icon": const Icon(IconFont.icon_saoyisaojianjiban, size: 20),
        "page": "scan",
        "color": Colors.black
      },
    ];
    List<Map<String, dynamic>> jtBusiness = [
      {
        "id": 'schedule',
        "name": "车次排班",
        "icon": const Icon(Icons.access_alarms, size: 28),
        "color": Colors.orange
      },
      {
        "id": 'upload',
        "name": "乘客上报",
        "icon": const Icon(IconFont.icon_icon_1),
        "color": Colors.orange
      },
      {
        "id": 'myupload',
        "name": "我的上报",
        "icon": const Icon(Icons.view_list),
        "color": Colors.orange
      }
    ];
    if (jt || admin) allBusiness.addAll(jtBusiness);
    if (yy || admin) {
      allBusiness.add({
        "id": 'jzUpload',
        "name": "就诊上报",
        "icon": const Icon(IconFont.icon_icon_1),
        "color": Colors.cyan
      });
      if (homeRes['xccx'] == 'Y') {
        allBusiness.add(
          {
            "id": 'xcQuery',
            "name": "行程查询",
            "icon": const Icon(Icons.departure_board),
            "color": Colors.cyan,
          },
        );
      }
      allBusiness.add({
        "id": 'myJzUpload',
        "name": "上报记录",
        "icon": const Icon(Icons.view_list),
        "color": Colors.cyan
      });

      // !!! @Todo 注释下一行
      if (homeRes['fnry'] == 'Y') {
        allBusiness.add({
          "id": 'backNcPerson',
          "name": "返南人员",
          "icon": const Icon(Icons.people),
          "color": Colors.teal
        });
        allBusiness.add({
          "id": 'myNcPersonUpload',
          "name": "人员记录",
          "icon": const Icon(Icons.view_list),
          "color": Colors.teal
        });
      }
    }

    if (xx || admin) {
      allBusiness.add({
        "id": 'studentList',
        "name": "晨午检登记",
        "icon": const Icon(Icons.school),
        "color": Colors.teal
      });
    }

    if (yf || admin) {
      allBusiness.add({
        "id": 'ypsb',
        "name": "售药登记",
        "icon": const Icon(Icons.school),
        "color": Colors.teal
      });
    }

    return Container(
        padding: const EdgeInsets.all(18),
        child: Wrap(
            spacing: 22,
            children: allBusiness.map((var business) {
              return Container(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                  color: (business["color"] as dynamic) ??
                                      Colors.green,
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(50.0))),
                            child: IconButton(
                                icon: business["icon"] as Widget,
                                color: business["color"] as Color,
                                onPressed: () async {
                                  await btnPressed(context, business);
                                })),
                        Text(business["name"]?.toString() ?? "",
                            style: const TextStyle(fontSize: 16.0))
                      ]));
            }).toList()));
  }

  showChooseYYS(context) {
    List<String> list = [];
    List btns = [];
    if (homeRes['ydOk'] == 'Y') {
      list.add("移动");
      btns.add(TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            NavigatorUtil.pushWeb(context,
                url: homeRes['ydUri']?.toString(),
                title: '行程查询',
                titleId: 'xinchen');
          },
          child: const Text('移动')));
    }
    if (homeRes['ltOk'] == 'Y') {
      list.add("联通");
      btns.add(TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            NavigatorUtil.pushWeb(context,
                url: homeRes['ltUri']?.toString(),
                title: '行程查询',
                titleId: 'xinchen');
          },
          child: const Text('联通')));
    }
    if (homeRes['dxOk'] == 'Y') {
      list.add("电信");
      btns.add(TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            NavigatorUtil.pushWeb(context,
                url: homeRes['dxUri']?.toString(),
                title: '行程查询',
                titleId: 'xinchen');
          },
          child: const Text('电信')));
    }
    String zc = list.join("、");
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          return AlertDialog(
              contentPadding: const EdgeInsets.all(10),
              title: const Text('提示'),
              content: SingleChildScrollView(
                  child: Column(
                      children: <Widget>[Text('请选择运营商，目前支持：$zc'), ...btns])),
              actions: <Widget>[
                TextButton(
                    child: const Text('取消'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    })
              ]);
        });
  }

  _handleScRes(scanRes) {
    if (kDebugMode) {
      print(scanRes + "===================");
    }
    var split = scanRes.split("|");
    if (split.length == 3) {
      String tag = split[0];
      String value1 = split[1];
      //解码
      List<int> bytes = convert.base64Decode(value1);
      // 网上找的很多都是String.fromCharCodes，这个中文会乱码
      //String txt1 = String.fromCharCodes(bytes);
      value1 = convert.utf8.decode(bytes);
      if (kDebugMode) {
        print("$value1============================");
      }

      String value2 = split[2];
      // 交通乘客上报
      if (tag == 'jt' && value1 == 'psupload' && (jt || admin)) {
        NavigatorUtil.pushPage(
            context,
            UploadPage(
                recordId: value2,
                scan: true,
                onSave: (result) {
                  Notify.success("扫码上报成功！",
                      context: context, duration: const Duration(seconds: 4));
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    Navigator.of(context).pop();
                  });
                }));
        // 南川健康验证 二维码
      } else if (tag == 'NCJK' &&
          RegexUtil.isIDCard18(value1) &&
          (yy || admin)) {
        NavigatorUtil.pushPage(
            context,
            JzUploadPage(
                //scan: true,
                idcardNumber: value1,
                onSave: (result) {
                  Notify.success("扫码上报成功！",
                      context: context, duration: Duration(seconds: 4));
                  Future.delayed(Duration(milliseconds: 1000), () {
                    Navigator.of(context).pop();
                  });
                }));
      } else if (tag == 'NCJK' && (!yy || !admin)) {
        Notify.error("二维码有误,请扫描居民健康二维码。",
            context: context, duration: const Duration(seconds: 4));
      } else if (tag == 'jt' && (!admin || !jt)) {
        Notify.error("二维码有误,请扫描交通防控登记二维码。",
            context: context, duration: const Duration(seconds: 4));
      } else {
        Notify.error("二维码有误,请扫描对应服务的二维码。",
            context: context, duration: const Duration(seconds: 4));
      }
    } else {
      if (scanRes.indexOf("取消") == -1)
        Notify.error("二维码有误,请扫描 南川区公众健康服务平台 微信公众号相应服务生成的二维码",
            context: context, duration: const Duration(seconds: 4));
    }
  }

  btnPressed(context, business) async {
    // 扫描二维码
    if ((business["id"] ?? "") == 'scan') {
      var value = await WbUtils.scanBarCode();
      String scanRes = value.second;
      _handleScRes(scanRes);
    } else if (business["id"] == 'schedule') {
      NavigatorUtil.pushPage(context, SchedulePage(onSave: (result) {
        if (homeRes['autoBack'] == 'Y') {
          Future.delayed(const Duration(milliseconds: 1000), () {
            Navigator.of(context).pop();
          });
        }
      }), pageName: "车次排班");
    } else if (business["id"] == 'upload') {
      NavigatorUtil.pushPage(context, UploadPage(onSave: (result) {
        if (homeRes['autoBack'] == 'Y') {
          Future.delayed(const Duration(milliseconds: 1000), () {
            Navigator.of(context).pop();
          });
        }
      }), pageName: "乘客上报");
    } else if (business["id"] == 'jzUpload') {
      NavigatorUtil.pushPage(context, JzUploadPage(), pageName: "就诊上报");
    } else if (business["id"] == 'backNcPerson') {
      NavigatorUtil.pushPage(context, NcUploadPage(onSave: (result) {
        if (homeRes['autoBack'] == 'Y') {
          Future.delayed(const Duration(milliseconds: 1000), () {
            Navigator.of(context).pop();
          });
        }
      }), pageName: "返南人员");
    } else if (business["id"] == 'xcQuery') {
      showChooseYYS(context);
    } else if (business["id"] == "myupload") {
      NavigatorUtil.pushPage(context, MyUploadPage(), pageName: "我的上报");
    } else if (business["id"] == "myJzUpload") {
      NavigatorUtil.pushPage(context, MyJzUploadPage(), pageName: "我的上报");
    } else if (business["id"] == "myNcPersonUpload") {
      NavigatorUtil.pushPage(context, MyRyUploadPage(), pageName: "我的上报");
    } else if (business["id"] == "studentList") {
      WbNetApi.teacherClassRelation(
              Application.userLoginModel.userLoginId ?? '')
          .then((res) {
        List? classList = res?['exec'] as List?;
        if (ObjectUtil.isNotEmpty(classList)) {
          if (classList?.length == 1) {
            Map<String, String> map = {
              "companyId": classList![0]["companyId"],
              "gradeId": classList[0]["gradeId"],
              "classId": classList[0]["classId"],
            };
            NavigatorUtil.pushPage(context, StudentListPage("学生列表", data: map),
                pageName: "学生列表");
          } else {
            NavigatorUtil.pushPage(context, StudentClassPage(classList ?? []),
                pageName: "选择班级");
          }
        } else {
          Notify.error("请联系管理员维护所管理班级",
              context: context, position: ToastPosition.bottom);
        }
      });
    } else if (business["id"] == "ypsb") {
      NavigatorUtil.pushPage(context, YqfkGyjlPage(), pageName: "售药登记");
    } else {
      Notify.error('功能建设中，暂未开放...', context: context);
    }
  }

  buildDynMsgs(homeMarquee) {
    return Container(
        height: 30,
        child: MarqueeWidget(
            text: homeMarquee,
            textStyle:
                TextStyle(fontSize: 18, color: Colors.red), // 背景比较暗 选择白色或者其他亮色
            scrollAxis: Axis.horizontal));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
        appBar: AppBar(
            leading: Stack(children: [
              GestureDetector(onTap: openDrawer, child: HeadImgLeading())
            ]),
            title: Row(children: <Widget>[
              const Expanded(flex: 3, child: Text('健康南川')),
              Expanded(
                  flex: 1,
                  child: Container(
                      padding: const EdgeInsets.only(top: 20),
                      child: InkWell(
                          onTap: () async {
                            String appId = await WbUtils.getAppId();
                            Map<String, dynamic> map =
                                await WbNetApi.getAppClientCfg(appId) ?? {};
                            setState(() {
                              WbNetApi.getHomePageSource(clearCache: true);
                            });
                            if (map.containsKey("error")) {
                              Notify.error(map['error'], context: context);
                            } else {
                              var cfg;
                              if (Platform.isIOS && map['ipaCfg'] != null) {
                                cfg = json.decode(map['ipaCfg']);
                                WbPlugin.checkAppUpdate(cfg);
                              } else if (Platform.isAndroid &&
                                  map['apkCfg'] != null) {
                                cfg = json.decode(map['apkCfg']);
                                WbPlugin.checkAppUpdate(cfg);
                              }
                            }
                          },
                          child: const Text('v ${AppConfig.androidVersion}',
                              style: TextStyle(fontSize: 16)))))
            ])),
        body: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
              Image.asset(Utils.getImgPath('app_title'), fit: BoxFit.fill),
              Container(decoration: Decorations.bottom10),
              FutureBuilder(
                  future: WbNetApi.getHomePageSource(),
                  builder: (BuildContext context,
                      AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                    if (!snapshot.hasData) return const ProgressView();

                    var map = snapshot.data!;
                    String tag = map["tag"] ?? "";
                    String homeMarquee = map["homeMarquee"];
                    String appCanRun = map["stopMsg"] ?? 'Y';
                    jt = tag.contains("JT");
                    yy = tag.contains("YQ_YY"); // 疫情防控 医院
                    xx = tag.contains("XX"); //学校
                    yf = tag.contains("YF"); //药房
                    admin = tag.contains("ADMIN"); // admin机构
                    return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          buildDynMsgs(homeMarquee),
                          Container(decoration: Decorations.bottom10),
                          'Y' == appCanRun
                              ? buildMainGridView(context, tag)
                              : Notify.noneWidget(
                                  msg: map["stopMsg"] ?? '无可用服务')
                        ]);
                  })
            ])));
  }
}
