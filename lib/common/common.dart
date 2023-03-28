class Constant {
  static const String keyLanguage = 'key_language';

  static const int STATUS_SUCCESS = 0;
  static const int STATUS_FAIL = -1;

  // TEST_ENV 为 4 正式环境
  static const int RUN_ENV = 4;

  static const String SERVER_ADDRESS = RUN_ENV == 0
      ? 'https://gw.cqblt.cn/'
      : RUN_ENV == 1
          ? 'http://192.168.1.9:8080/'
          : RUN_ENV == 2
              ? 'http://192.168.0.12/'
              : RUN_ENV == 3
                  ? 'http://192.168.8.67:8080/'
                  : RUN_ENV == 4
                      ? 'https://www.ncgzjk.cn/'
                      : 'https://gw.cqblt.cn/';

  // APP 默认登录账号
  static const String TEST_USER_LOGIN = RUN_ENV == 0
      ? ''
      : RUN_ENV == 1
          ? 'nc5001906005'
          : RUN_ENV == 2
              ? 'nc500119037092'
              : RUN_ENV == 3
                  ? 'nc500119031'
                  : '';

  static const IOS_APP_DOWNLOAD_PATH =
      'https://apps.apple.com/cn/app/南川区远程会诊/id1474032971';

  static const String WX_QRCODE_PREFIX =
      "https://mp.weixin.qq.com/cgi-bin/showqrcode?ticket=";

  // rpx 页面url前缀
  static const String RPX_PAGE_PREFIX =
      SERVER_ADDRESS + 'w/control/wxrpxview?ISAPP=true';

  static const String APPD_MD5FILE_PREFIX =
      SERVER_ADDRESS + 'w/control/resdownb/';

  static const String APPD_STOREFILE_PREFIX =
      SERVER_ADDRESS + 'w/control/bltdownfile/';

  static const int TYPE_SYS_UPDATE = 1;
  static const String KEY_THEME_COLOR = 'key_theme_color';
  static const String KEY_GUIDE = 'key_guide';
  static const String KEY_SPLASH_MODEL = 'key_splash_models';
}

class AppConfig {
  static const String androidVersion = '2.0.0';
  static const String iosVersion = '2.0.0';
  static const String versionCode = '2.0.0';
  static const bool isDebug = Constant.RUN_ENV > 3 ? false : true;
}
