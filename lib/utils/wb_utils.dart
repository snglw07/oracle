import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:amap_location_fluttify/amap_location_fluttify.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wbyq/common/common.dart';
import 'package:wbyq/common/sp_helper.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/data/net/dio_util.dart';
import 'package:wbyq/ui/widgets/widget_index.dart';
import 'package:wbyq/utils/location_map.dart';
import 'package:wbyq/utils/util_index.dart';
import 'package:flutter/services.dart';

import 'media_util.dart';

bool isTypeOf<ThisType, OfType>() => _Instance<ThisType>() is _Instance<OfType>;

class _Instance<T> {
  //
}

class Pair<S, T> {
  S first;
  T second;
  Pair(this.first, this.second);
}

class IdCardParse {
  int age = 0;
  late String sex;
  late String sexDesc;
  late String birthDate;
  late String error;
  IdCardParse(String? idcardNo) {
    if (ObjectUtil.isEmpty(idcardNo) || !RegexUtil.isIDCard18Exact(idcardNo!)) {
      error = '不是合法的身份证号';
      return;
    }
    try {
      birthDate = idcardNo!.substring(6, 14);
      age = WbUtils.getAge(DateTime.tryParse(birthDate));
      sex = int.parse(idcardNo.substring(16, 17)) / 2 == 0 ? "FEMALE" : "MALE";
      sexDesc = int.parse(idcardNo.substring(16, 17)) / 2 == 0 ? "女" : "男";
    } catch (e) {
      error = "解析身份证出错";
    }
  }
}

class WbUtils {
  ///加载后台md5图，并缓存，若 defaultImage 为空 则 加载md5图失败时缺省显示Assests/images/normal_user_icon.png
  static Future<ImageProvider> loadCachedMd5Image(String? md5,
      [ImageProvider? defaultImage]) async {
    //缺省图像顺位 defaultImage->normal_user_icon.png
    var placeHolderImage =
        defaultImage ?? AssetImage(Utils.getImgPath('normal_user_icon'));

    if (ObjectUtil.isEmptyString(md5)) return placeHolderImage;

    Directory dir = await getTemporaryDirectory();

    final String path = "${dir.path}/${md5!}";

    final File file = File(path);

    bool exist = await file.exists();
    // 若文件不存在 下载图像文件 下载出错 使用占位符图像
    if (!exist) {
      return await DioUtil()
              .download(
                  '${Constant.SERVER_ADDRESS}w/control/resdownb/$md5', path)
              ?.then((_) {
            return FileImage(file);
          }).catchError((_) {
            return placeHolderImage;
          }) ??
          placeHolderImage;
    }

    return FileImage(file);
  }

  ///返回扫码结果 pair.first==true则pair.second为码值,
  ///pair.first==false则pair.second为错误提示,
  ///pair.first==null则为取消了扫码操作,
  static Future<Pair<bool?, String>> scanBarCode() async {
    try {
      var barcode = await BarcodeScanner.scan();

      return Pair(true, barcode.rawContent);
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        return Pair(false, '未分配摄像头权限');
      } else {
        return Pair(false, '未知错误:$e');
      }
    } on FormatException {
      return Pair(null, "用户按 『返回』键取消了扫码操作");
    } catch (e) {
      return Pair(false, '未知错误:$e');
    }
  }

  ///大陆手机号码11位数，匹配格式：前三位固定格式+后8位任意数
  /// 此方法中前三位格式有：
  /// 13+任意数 * 15+除4的任意数 * 18+除1和4的任意数 * 17+除9的任意数 * 147
  static bool isChinaPhoneLegal(String str) {
    return RegexUtil.isMobileExact(str);
    /*  return new RegExp(
            '^((13[0-9])|(15[^4])|(166)|(17[0-8])|(18[0-9])|(19[8-9])|(147,145))\\d{8}\$')
        .hasMatch(str); */
  }

  static bool isPlateNoLegal(String str) {
    String plateNoRegex =
        "^[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领]{1}[A-Z]{1}[A-Z0-9]{4}[A-Z0-9挂学警港澳]{1}\$";
    return RegexUtil.matches(plateNoRegex, str);
  }

  /// 移动手机号
  static bool isCMPhone(String str) {
    String regex =
        "(^1(3[4-9]|4[7]|5[0-27-9]|7[8]|8[2-478])\\d{8}\$)|(^1705\\d{7}\$)";
    return RegexUtil.matches(regex, str);
  }

  /// 联通手机号
  static bool isCUPhone(String str) {
    String regex = "(^1(3[0-2]|4[5]|5[56]|7[6]|8[56])\\d{8}\$)|(^1709\\d{7}\$)";
    return RegexUtil.matches(regex, str);
  }

  /// 电信手机号
  static bool isCTPhone(String str) {
    String regex =
        "^(((133)|(149)|(153)|(162)|(17[3,7])|(18[0,1,9])|(19[0,1,3,9]))\\d{8}\$)|^(((170[0-2])|(174[0-5]))\\d{7}\$)";
    return RegexUtil.matches(regex, str);
  }

  ///加载根据userLoginId加载头像图，并缓存md5 3天，若defaultImage 为空 则 加载md5图失败时缺省显示Assests/images/normal_user_icon.png
  static Future<ImageProvider> loadCachedUserLoginImage(String userLoginId,
      [ImageProvider? defaultImage, isForce = false]) async {
    Map<String, dynamic>? query;
    DateTime lastFetchTime = DateTime.now();
    Map<String, dynamic>? map =
        SpUtil.getObject("headImg:$userLoginId") as dynamic;
    String md5;

    if (isForce || ObjectUtil.isEmpty(map)) {
      query = await WbNetApi.queryUserLoginExInfo(userLoginId: userLoginId);
      query?['lastFetchTime'] = DateTime.now().millisecondsSinceEpoch;
    } else {
      try {
        lastFetchTime = DateTime.fromMillisecondsSinceEpoch(
            map!['lastFetchTime'] as dynamic);
      } catch (e) {}
      if ((DateTime.now()
          .subtract(const Duration(days: 3))
          .isAfter(lastFetchTime))) {
        query = await WbNetApi.queryUserLoginExInfo(userLoginId: userLoginId);
        query?['lastFetchTime'] = DateTime.now().millisecondsSinceEpoch;
      } else {
        query = map;
      }
    }
    SpHelper.putObject("headImg:$userLoginId", query);
    Map? exec = query!['exec'] as dynamic;
    md5 = exec != null && exec.containsKey('thumb') ? exec['thumb'] : "";
    return loadCachedMd5Image(md5, defaultImage);
  }

  static Future<String> getAppId() {
    return PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      var arr = packageInfo.packageName.split('.'); //wbyq
      return arr[arr.length - 1];
    });
  }

  static num myStrHashCode(String? str) {
    num h = 0;
    if (null == str) return h;
    if (h == 0 && str.isNotEmpty) {
      List val = str.codeUnits;
      for (int i = 0; i < val.length; i++) {
        h = 7 * h + val[i];
      }
    }
    return h;
  }

  /// 扫码并返回结果
  static Future<String?> scanBarcode(BuildContext context) async {
    try {
      var result = await BarcodeScanner.scan();
      return result.rawContent;
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        Notify.error("未授权使用摄像头。", context: context);
      } else {
        Notify.error("未知错误：$e", context: context);
      }
    } on FormatException {
      Notify.error("未扫描到结果。", context: context);
    } catch (e) {
      Notify.error("未知错误：$e", context: context);
    }
    return null;
  }

  /// 带回调方法的扫码
  static scanBarcodeF(
      BuildContext context,
      void Function(BuildContext context, Map<String, dynamic> map)
          hcCallback) async {
    String? barcode = await WbUtils.scanBarcode(context);
    if (ObjectUtil.isEmpty(barcode)) {
      Notify.error('未扫描到结果', context: context);
      return;
    }
    //扫码结果分类处理
    if (RegexUtil.isURL(barcode!)) {
      // url
      confirm(context, content: '确认在浏览器打开以下链接？\n$barcode', okCb: (ctx) {
        NavigatorUtil.launchInBrowser(barcode);
      });
    } else if (RegexUtil.isMobileExact(barcode)) {
      // 手机号
      confirm(context, content: '确认呼叫以下电话号码？\n$barcode', okCb: (ctx) {
        NavigatorUtil.launchInBrowser("tel:$barcode");
      });
    } else if (RegexUtil.isIDCard18Exact(barcode)) {
      // 身份证号查询
    } else if (barcode.endsWith(":0") || barcode.endsWith(":1")) {
      // 纯数字 (暂设为健康卡 和 personId 查找)
      /* Map<String, dynamic> p =
          await WbNetApi.queryGwPersonByHealthCardNo(barcode: barcode);
      if (ObjectUtil.isEmpty(p) || !p['existsPerson']) {
        Notify.error('未找到$barcode 对应的公卫建档居民。');
        return;
      }
      p['referer'] = 'scanHc';
      if (ObjectUtil.isNotEmpty(hcCallback)) hcCallback(context, p); */
    } else {
      Notify.error('未定义的扫描结果：\n $barcode', context: context);
    }
  }

  /// 确认提示框
  static confirm(BuildContext context,
      {String title = '提示',
      required String content,
      bool showCancel = true,
      void okCb(BuildContext context)?,
      void cancelCb(BuildContext context)?}) async {
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          return AlertDialog(
              title: const Text('提示'),
              content: SingleChildScrollView(child: Text(content)),
              actions: <Widget>[
                showCancel
                    ? TextButton(
                        child: const Text('取消'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (ObjectUtil.isNotEmpty(cancelCb)) {
                            cancelCb!(context);
                          }
                        })
                    : Container(),
                TextButton(
                    child: const Text('确定'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (ObjectUtil.isNotEmpty(okCb)) okCb!(context);
                    })
              ]);
        });
  }

  //请求权限：相册，相机，麦克风
  static void requestAllPermissions() {
    MediaUtil.instance.requestPermissions([
      Permission.phone,
      Permission.photos,
      Permission.camera,
      //Permission.microphone,
      Permission.location,
    ]);
  }

  static Future<bool> requestLocationPermission() async {
    var result = await MediaUtil.instance.requestPermissions([
      Permission.location,
    ]);

    return result;
  }

  static Future<Map<String, dynamic>> locationAddress() async {
    Map<String, dynamic> map = Map();
    if (await WbUtils.requestLocationPermission()) {
      final Location location = await AmapLocation.instance.fetchLocation();
      var latLng = location.latLng;
      if (latLng?.latitude == 0.0 || latLng?.longitude == 0.0) {
        map["error"] = "获取定位失败，请检查设备定位设置";
        return map;
      }
      String address = await LocationMap(location).toJsonString();
      Map addressMap = const JsonCodec().decode(address);
      addressMap['refer'] = "wbyq";
      addressMap['provider'] = "amap";
      map["address"] = const JsonCodec().encode(addressMap);
      map["addressMap"] = addressMap;
      return map;
    } else {
      map["error"] = "获取定位失败，请检查设备定位设置";
      return map;
    }
  }

  static int getAge(DateTime? brt) {
    if (brt == null) return 0;

    int age = 0;
    DateTime dateTime = DateTime.now();
    int yearNow = dateTime.year; //当前年份
    int monthNow = dateTime.month; //当前月份
    int dayOfMonthNow = dateTime.day; //当前日期

    int yearBirth = brt.year;
    int monthBirth = brt.month;
    int dayOfMonthBirth = brt.day;
    age = yearNow - yearBirth; //计算整岁数
    if (monthNow <= monthBirth) {
      if (monthNow == monthBirth) {
        if (dayOfMonthNow < dayOfMonthBirth) age--; //当前日期在生日之前，年龄减一
      } else {
        age--; //当前月份在生日之前，年龄减一
      }
    }
    return age;
  }
}
