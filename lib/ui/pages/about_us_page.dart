import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wbyq/common/component_index.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于我们'), centerTitle: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(30),
              child: Card(
                  color: Colors.white.withOpacity(0.90),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6.0))),
                  child: Image.asset(Utils.getImgPath('ic_launcher'),
                      fit: BoxFit.fill, width: 80.0, height: 80.0))),
          Container(
              alignment: Alignment.center,
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
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
                        ])))
              ])),
          Expanded(
            flex: 3,
            child: Container(),
          )
        ],
      ),
    );
  }
}
