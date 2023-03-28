import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/ui/pages/simple_image_page.dart';
import 'package:wbyq/utils/navigator_util.dart';
import 'package:wbyq/utils/utils.dart';
import 'package:wbyq/utils/wb_utils.dart';

import 'circular_image.dart';

class CircularMd5Image extends StatelessWidget {
  final String? md5;

  final double size;
  final double marginTop, marginBottom, marginLeft, marginRight;

  final ImageProvider? defaultImage;

  final ImageProvider defaultHeadImage =
      AssetImage(Utils.getImgPath('normal_user_icon'));

  CircularMd5Image(
    this.md5, {
    super.key,
    this.size = 0,
    this.marginTop = 0.0,
    this.marginBottom = 0.0,
    this.marginLeft = 0.0,
    this.marginRight = 0.0,
    this.defaultImage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future:
            WbUtils.loadCachedMd5Image(md5, defaultImage ?? defaultHeadImage),
        builder: (_, AsyncSnapshot<ImageProvider> snapshot) => CircularImage(
              snapshot.data ?? (defaultImage ?? defaultHeadImage),
              size: size,
              marginTop: marginTop,
              marginBottom: marginBottom,
              marginLeft: marginLeft,
            ));
  }
}

class CircularUserLoginImage extends StatelessWidget {
  final String userLoginId;
  final double size;
  final double marginTop, marginBottom, marginLeft, marginRight;
  final bool isForce;
  final ImageProvider? defaultImage;
  final ImageProvider defaultHeadImage =
      AssetImage(Utils.getImgPath('normal_user_icon'));

  CircularUserLoginImage(this.userLoginId,
      {super.key,
      this.size = 0,
      this.marginTop = 0.0,
      this.marginBottom = 0.0,
      this.marginLeft = 0.0,
      this.marginRight = 0.0,
      this.defaultImage,
      this.isForce = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: WbUtils.loadCachedUserLoginImage(
            userLoginId, defaultImage ?? defaultHeadImage, isForce),
        builder: (_, AsyncSnapshot<ImageProvider> snapshot) => CircularImage(
              snapshot.data ?? (defaultImage ?? defaultHeadImage),
              size: size,
              marginTop: marginTop,
              marginBottom: marginBottom,
              marginLeft: marginLeft,
            ));
  }
}

class ImageView extends StatelessWidget {
  // 上传成功的map
  final Map res;

  const ImageView(this.res, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String md5 = res['md5'];
    String storeId = res['storeId'].toString();
    String thumbStoreId = res['thumbStoreId'].toString();

    return Container(
        margin: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
        child: Material(
            clipBehavior: Clip.hardEdge,
            child: InkWell(
                onTap: () {
                  NavigatorUtil.pushPage(
                      context,
                      SimpleImagePage(
                          md5: md5,
                          imageUrl: Constant.APPD_STOREFILE_PREFIX + storeId));
                },
                borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                child: CachedNetworkImage(
                    imageUrl:
                        "${Constant.APPD_STOREFILE_PREFIX}$thumbStoreId?isThumb=Y",
                    width: 100.0,
                    height: 100.0,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                        width: 100.0,
                        height: 100.0,
                        padding: const EdgeInsets.all(70.0),
                        decoration: const BoxDecoration(
                            color: Colours.gray_cc,
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0))),
                        child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colours.app_main))),
                    errorWidget: (context, url, error) => Material(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8.0)),
                        clipBehavior: Clip.hardEdge,
                        child: Image.asset('images/img_not_available.png',
                            width: 100.0,
                            height: 100.0,
                            fit: BoxFit.cover))))));
  }
}
