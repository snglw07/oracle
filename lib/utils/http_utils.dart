import 'dart:io';
import 'package:wbyq/common/common.dart';
import 'package:wbyq/models/models.dart';

//模拟网络请求数据
class HttpUtils {
  Future<VersionModel> getVersion() async {
    return Future.delayed(new Duration(milliseconds: 300), () {
      return new VersionModel(
        title: '有新版本v0.1.2，去更新吧！',
        content: '',
        url:
            'https://raw.githubusercontent.com/Sky24n/LDocuments/master/AppStore/flutter_wanandroid_new.apk',
        version: (Platform.isAndroid
            ? AppConfig.androidVersion
            : AppConfig.iosVersion),
      );
    });
  }

  Future<ComModel?> getRecItem() async {
    return Future.delayed(new Duration(milliseconds: 300), () {
      return null;
    });
  }

  Future<List<ComModel>> getRecList() async {
    return Future.delayed(new Duration(milliseconds: 300), () {
      return [];
    });
  }
}
