import 'package:flutter/cupertino.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigatorUtil {
  static Future pushPage(BuildContext? context, Widget? page,
      {String? pageName}) {
    if (context == null || page == null) return Future.value();
    return Navigator.push(
        context, CupertinoPageRoute<void>(builder: (ctx) => page));
  }

  static Future pushWeb(BuildContext context,
      {String? title, String? titleId, String? url, bool isHome = false}) {
    if (context == null || ObjectUtil.isEmpty(url)) return Future.value();
    if (url?.endsWith(".apk") == true) {
      return launchInBrowser(url!, title: title ?? titleId ?? "");
    } else {
      return Navigator.push(
          context,
          CupertinoPageRoute<void>(
              builder: (ctx) => WebScaffold(
                    title: title ?? "",
                    titleId: titleId ?? "",
                    url: url ?? "",
                  )));
    }
  }

  static Future pushRpx(BuildContext context,
      {String? title, String? titleId, String? url, bool isHome = false}) {
    return Navigator.push(
        context,
        CupertinoPageRoute<void>(
            builder: (ctx) => RpxWebScaffold(
                title: title ?? titleId ?? "",
                titleId: titleId ?? "",
                url: url ?? "")));
  }

  static Future<void> launchInBrowser(String url, {String? title}) async {
    var uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        //forceSafariVC: false, forceWebView: false
      );
    } else {
      throw 'Could not launch $url';
    }
  }
}
