import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:wbyq/common/component_index.dart';

///- 可以传入 imageUrl imageProvider md5 进行页面图片预览
///- 优先级是 md5>imageProvider>imageUrl 加载失败时候可以设置默认图片为： <ImageProvider> defaultImage
class SimpleImagePage extends StatelessWidget {
  final String? imageUrl;
  final String? md5;
  final String? title;
  final ImageProvider? defaultImage;
  final ImageProvider<Object>? imageProvider;

  SimpleImagePage({
    Key? key,
    this.md5,
    this.imageProvider,
    this.imageUrl,
    this.title,
    this.defaultImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? "图片查看"),
        centerTitle: true,
      ),
      body: Container(
          child: Center(
        child: (ObjectUtil.isNotEmpty(md5) && md5 != null)
            ? Md5Image(md5!, defaultImage: defaultImage)
            : null != imageProvider
                ? PhotoView(imageProvider: imageProvider)
                : (null != imageUrl && !ObjectUtil.isEmptyString(imageUrl)
                    ? PhotoView(
                        imageProvider: NetworkImage(imageUrl!),
                        //loadingChild: ProgressView()
                      )
                    : PhotoView(
                        imageProvider:
                            AssetImage('assets/images/img_not_available.png'))),
      )),
    );
  }
}

class Md5Image extends StatelessWidget {
  final String md5;
  final ImageProvider? defaultImage;
  final ImageProvider defaultNoneImage =
      AssetImage('assets/images/img_not_available.png');

  Md5Image(
    this.md5, {
    this.defaultImage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: WbUtils.loadCachedMd5Image(
            md5, this.defaultImage ?? defaultNoneImage),
        builder: (_, AsyncSnapshot<ImageProvider> snapshot) => PhotoView(
            imageProvider:
                (snapshot.data ?? (defaultImage ?? defaultNoneImage))));
  }
}
