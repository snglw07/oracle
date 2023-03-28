import 'dart:io';
import 'dart:typed_data';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wbyq/data/net/dio_util.dart';
import 'package:wbyq/utils/utils.dart';

typedef ImageDataCallback = void Function(Uint8List bytes);

Future<ImageProvider> resolveImage(String url, String localImageFileName,
    [ImageDataCallback? cb, ImageProvider? defaultImage]) async {
  //缺省图像顺位 defaultImage->normal_user_icon.png
  var placeHolderImage =
      defaultImage ?? AssetImage(Utils.getImgPath('normal_user_icon'));

  if (ObjectUtil.isEmptyString(localImageFileName)) return placeHolderImage;

  Directory dir = await getTemporaryDirectory();

  final String path = dir.path + "/" + localImageFileName;

  final File file = File(path);

  bool exist = await file.exists();
  // 若文件不存在 下载图像文件 下载出错 使用占位符图像
  if (!exist)
    return await DioUtil().download(url, path)?.then((_) {
          if (cb != null) {
            file.readAsBytes().then((Uint8List bytes) {
              cb(bytes);
            });
          }

          return FileImage(file);
        }).catchError((_) {
          return placeHolderImage;
        }) ??
        placeHolderImage;

  if (cb != null) {
    file.readAsBytes().then((Uint8List bytes) {
      cb(bytes);
    });
  }

  return FileImage(file);
}
