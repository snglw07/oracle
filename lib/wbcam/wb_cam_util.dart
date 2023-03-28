import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as im;
import 'package:path_provider/path_provider.dart';

import 'wb_face.dart';

bool _isValidImage(Uint8List imageData) =>
    imageData != null && imageData.length > 16;

// JPEG (jpg)，文件头：FFD8FF
bool _isJpegImage(Uint8List imageData) =>
    imageData[0] == 0xff && imageData[1] == 0xd8 && imageData[2] == 0xff;

// PNG (png)，文件头：89504E47
bool _isPngImage(Uint8List imageData) =>
    imageData[0] == 0x89 &&
    imageData[1] == 0x50 &&
    imageData[2] == 0x4e &&
    imageData[3] == 0x47;

// GIF (gif)，文件头：47494638
bool _isGifImage(Uint8List imageData) =>
    imageData[0] == 0x47 &&
    imageData[1] == 0x49 &&
    imageData[2] == 0x46 &&
    imageData[3] == 0x38;

// TIFF (tif)，文件头：49492A00
bool _isTiffImage(Uint8List imageData) =>
    imageData[0] == 0x49 &&
    imageData[1] == 0x49 &&
    imageData[2] == 0x2a &&
    imageData[3] == 0x00;

// Windows Bitmap (bmp)，文件头：424D
bool _isBmpImage(Uint8List imageData) =>
    imageData[0] == 0x42 && imageData[1] == 0x4d;

ImageProvider? toImageProvider(Uint8List imageData) {
  if (!_isValidImage(imageData)) return null;

  if (_isJpegImage(imageData)) {
    var image = im.decodeJpg(imageData);
    if (image != null) {
      var png = im.encodePng(image);

      return MemoryImage(png as dynamic);
    }

    return null;
  }

  if (_isPngImage(imageData)) {
    return MemoryImage(imageData);
  }

  if (_isGifImage(imageData)) {
    var image = im.decodeGif(imageData);
    if (image != null) {
      var png = im.encodePng(image);

      return MemoryImage(png as dynamic);
    }
    return null;
  }

  if (_isTiffImage(imageData)) {
    var image = im.decodeTiff(imageData);
    if (image != null) {
      var png = im.encodePng(image);

      return MemoryImage(png as dynamic); //Image.memory(png);
    }
    return null;
  }

  if (_isBmpImage(imageData)) {
    //var image=im.decode(this.originalHead);
    //var png=im.encodePng(image);
  }

  return null;
}

Uint8List? toJpgImageData(Uint8List? imageData) {
  if (imageData == null || !_isValidImage(imageData)) return null;

  if (_isJpegImage(imageData)) {
    return imageData;
  }

  if (_isPngImage(imageData)) {
    var image = im.decodePng(imageData);
    if (image != null) {
      var jpg = im.encodeJpg(image);
      return jpg as dynamic;
    }
    return null;
  }

  if (_isGifImage(imageData)) {
    var image = im.decodeGif(imageData);
    if (image != null) {
      var jpg = im.encodeJpg(image);
      return jpg as dynamic;
    }
    return null;
  }

  if (_isTiffImage(imageData)) {
    var image = im.decodeTiff(imageData);
    if (image != null) {
      var jpg = im.encodeJpg(image);
      return jpg as dynamic;
    }
    return null;
  }

  if (_isBmpImage(imageData)) {
    //var image=im.decode(this.originalHead);
    //var png=im.encodePng(image);
  }

  return null;
}

Future<bool> initFaceDetectData() async {
  final Directory extDir = await getApplicationDocumentsDirectory();
  final String modelPath = '${extDir.path}/model';
  await Directory(modelPath).create(recursive: true);

  for (var filePath in [
    'fr_2_10.dat',
    'pd_2_00_pts81.dat',
    'pd_2_00_pts5.dat',
    'fd_2_00.dat'
  ]) {
    var file = File('$modelPath/$filePath');
    if (!await file.exists()) {
      ByteData data = await rootBundle.load("assets/model/$filePath");
      Uint8List bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File('$modelPath/$filePath').writeAsBytes(bytes);
    }
  }

  return WbFace.ensureFaceModelInitialized(modelPath);
}
