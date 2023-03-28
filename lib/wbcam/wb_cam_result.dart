import 'dart:typed_data';

class WbCamResult {
  final bool isOK;
  final String tip;
  final Uint8List? faceImageData;
  final Uint8List? fullImageData;
  final String? videoFileName;
  final double score;

  WbCamResult({
    required this.isOK,
    this.tip = "",
    this.score = 0,
    required this.faceImageData,
    required this.fullImageData,
    required this.videoFileName,
  });
}
