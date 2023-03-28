import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/ui/pages/home_page.dart';
import 'package:wbyq/ui/pages/main_left_page.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);
  @override
  _BottomNavigationState createState() => new _BottomNavigationState();
}

class _BottomNavigationState extends State<MainPage> {
  var _key = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  void openDrawer() {
    if (_key.currentContext != null) {
      var scaffold = Scaffold.of(_key.currentContext!);
      scaffold.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    int last = DateTime.now().millisecondsSinceEpoch;
    Future<bool> onWillPop() {
      int now = DateTime.now().millisecondsSinceEpoch;
      if (now - last > 800) {
        Notify.info('再按一次退出',
            context: context, backgroundColor: Colors.black.withOpacity(0.8));
        last = now;
        return Future.value(false);
      } else {
        return Future.value(true);
      }
    }

    return WillPopScope(
      child: Scaffold(
        drawer: Drawer(
          child: MainLeftPage(),
        ),
        body: PageView(
          key: _key,
          children: <Widget>[
            HomePage(
              openDrawer: openDrawer,
              labelId: Ids.titleHome,
            )
          ],
          //controller: _pageController,
          physics: BouncingScrollPhysics(),
          //onPageChanged: onPageChanged,
        ),
        //bottomNavigationBar: MainMavBar(navigationTapped, _page)
      ),
      onWillPop: onWillPop,
    );
  }
}
