import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/ui/pages/page_index.dart';
import 'package:wbyq/ui/widgets/circular_md5_image.dart';

class MainLeftPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MainLeftPageState();
}

class PageInfo {
  PageInfo(this.titleId, this.iconData, this.page,
      {this.func, this.withScaffold = true});
  String titleId;
  IconData iconData;
  Widget page;
  VoidCallback? func;
  bool withScaffold;
}

class _MainLeftPageState extends State<MainLeftPage> {
  List<PageInfo> _pageInfo = [];
  _MainLeftPageState();

  @override
  void initState() {
    super.initState();
    /*  _pageInfo.add(
        PageInfo(Ids.titleCollection, Icons.collections, CollectionPage())); */
    _pageInfo.add(PageInfo(Ids.titleSetting, Icons.settings, SettingPage()));
    _pageInfo.add(PageInfo(Ids.titleAbout, Icons.info, AboutPage()));
    //_pageInfo.add(PageInfo(Ids.permissionSetting, Icons.perm_data_setting, AboutPermissionPage()));
    _pageInfo.add(PageInfo(Ids.titleShare, Icons.share, SharePage()));
    _pageInfo.add(
        PageInfo(Ids.titleSignOut, FontAwesomeIcons.signOutAlt, SharePage()));
    _pageInfo.add(PageInfo(
        Ids.titleLogout, Icons.power_settings_new, SharePage(),
        func: () => exit(0)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
              color: Theme.of(context).primaryColor,
              padding: EdgeInsets.only(
                  top: ScreenUtil.getInstance().statusBarHeight,
                  left: 12,
                  bottom: 10),
              child: buildUserLoginPage()),
          Expanded(
            child: Container(
                child: ListView.builder(
                    padding: const EdgeInsets.all(0.0),
                    itemCount: _pageInfo.length,
                    itemBuilder: (BuildContext context, int index) {
                      PageInfo pageInfo = _pageInfo[index];
                      return ListTile(
                        leading: Icon(pageInfo.iconData),
                        title:
                            Text(IntlUtil.getString(context, pageInfo.titleId)),
                        onTap: () async {
                          if (pageInfo.titleId == Ids.titleSignOut) {
                            WbUtils.confirm(context,
                                content: "注销后需重新打开App进行登陆，是否确认？", okCb: (_) {
                              try {
                                WbNetApi.api("app.session.logout");
                                SpUtil.remove("_ACCESS_TOKEN");
                                Future.delayed(Duration(milliseconds: 300), () {
                                  exit(0);
                                });
                              } catch (e) {
                                SpUtil.remove("_ACCESS_TOKEN");
                                Future.delayed(Duration(milliseconds: 300), () {
                                  exit(0);
                                });
                              }
                            }, cancelCb: (_) {});
                            // Navigator.of(context) .pushReplacementNamed('/Login');
                          } else {
                            if (null != pageInfo.func)
                              pageInfo.func!();
                            else
                              NavigatorUtil.pushPage(context, pageInfo.page,
                                  pageName: pageInfo.titleId);
                          }
                        },
                      );
                    })),
            flex: 1,
          )
        ],
      ),
    );
  }

  Widget buildUserLoginPage() {
    final MainBloc? bloc = BlocProvider.of<MainBloc>(context);

    return StreamBuilder<Map<String, dynamic>>(
        stream: bloc?.checkLoginStream,
        initialData: null,
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (!snapshot.hasData) return ProgressView();

          String companyName = snapshot.data?["companyName"] ?? "无";
          String lastName = snapshot.data?["lastName"] ?? "无";
          String thumbMd5 = snapshot.data?["thumb"];

          return SizedBox(
            height: 145.0,
            width: double.infinity,
            child: Stack(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircularMd5Image(thumbMd5,
                        size: 80.0, marginTop: 10.0, marginBottom: 10.0),
                    Text(
                      lastName,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      companyName,
                      style: TextStyle(color: Colors.white, fontSize: 12.0),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }
}
