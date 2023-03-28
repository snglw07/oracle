import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/ui/pages/about_us_page.dart';
import 'package:wbyq/wb_plugin.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final MainBloc? bloc = BlocProvider.of<MainBloc>(context);
    ComModel other = ComModel(title: '关于我们', page: AboutUsPage());

    return Scaffold(
      appBar: AppBar(
        title: Text(IntlUtil.getString(context, Ids.titleAbout)),
        centerTitle: true,
      ),
      body: ListView(
        children: <Widget>[
          Container(
              height: 160.0,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Card(
                      color: Colors.white.withOpacity(0.90),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6.0))),
                      child: Image.asset(Utils.getImgPath('ic_launcher'),
                          fit: BoxFit.fill, width: 80.0, height: 80.0)),
                  Gaps.vGap5,
                  Text(
                    "版本号:${(Platform.isAndroid ? AppConfig.androidVersion : AppConfig.iosVersion)} [${AppConfig.versionCode}]",
                    style: TextStyle(color: Colours.gray_99, fontSize: 14.0),
                  )
                ],
              ),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(width: 0.33, color: Colours.divider))),
          StreamBuilder(
              stream: bloc?.versionStream,
              builder:
                  (BuildContext context, AsyncSnapshot<VersionModel> snapshot) {
                VersionModel? model = snapshot.data;
                return Container(
                  decoration: Decorations.bottom,
                  child: Material(
                    color: Colors.white,
                    child: ListTile(
                      onTap: () async {
                        String appId = await WbUtils.getAppId();
                        Map<String, dynamic> map =
                            await WbNetApi.getAppClientCfg(appId) ?? {};
                        if (map.containsKey("error") == true) {
                          Notify.error(map['error'] as dynamic,
                              context: context);
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
                      title: const Text('版本更新'),
                      //dense: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            Platform.isAndroid
                                ? AppConfig.androidVersion
                                : AppConfig.iosVersion,
                            style: TextStyle(
                                color: (model != null &&
                                        Utils.getUpdateStatus(
                                                model.version ?? '') !=
                                            0)
                                    ? Colors.red
                                    : Colors.grey,
                                fontSize: 14.0),
                          ),
                          const Icon(
                            Icons.navigate_next,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ComArrowItem(other),
        ],
      ),
    );
  }
}
