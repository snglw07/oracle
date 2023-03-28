import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SharePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    LogUtil.e("SharePage ${ScreenUtil.getInstance().screenWidth}");
    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
            title: Text(IntlUtil.getString(context, Ids.titleShare)),
            centerTitle: true),
        body: SingleChildScrollView(
            child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(top: 20),
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Card(
                      child: Container(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(children: <Widget>[
                            Container(
                              alignment: Alignment.center,
                              width: ScreenUtil.getInstance().getWidth(220),
                              height: ScreenUtil.getInstance().getWidth(220),
                              child: InkWell(
                                  onTap: () {
                                    NavigatorUtil.launchInBrowser(
                                        '${Constant.SERVER_ADDRESS}wbyq_nc.apk?_v=${AppConfig.androidVersion}&_code=${AppConfig.versionCode}');
                                  },
                                  child: QrImage(
                                      data:
                                          "${Constant.SERVER_ADDRESS}wbyq_nc.apk?_v=${AppConfig.androidVersion}&_code=${AppConfig.versionCode}",
                                      size: 200.0)),
                            ),
                            const Text(
                                'ANDROID ${AppConfig.androidVersion} [${AppConfig.versionCode}]')
                            /* Container(
                                alignment: Alignment.center,
                                width: ScreenUtil.getInstance().getWidth(220),
                                height: ScreenUtil.getInstance().getWidth(220),
                                child: QrImage(
                                    data: "${Constant.IOS_APP_DOWNLOAD_PATH}",
                                    size: 200.0)),
                            Text('IOS ${AppConfig.iosVersion}版') */
                          ]))),
                  Gaps.vGap15,
                  const Text('请使用浏览器或相机APP扫描二维码\n或直接点击二维码下载安装包\n',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18.0))
                ]))));
  }
}
