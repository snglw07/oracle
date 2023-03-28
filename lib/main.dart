import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';

import 'package:amap_location_fluttify/amap_location_fluttify.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oktoast/oktoast.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/net/dio_util.dart';
import 'package:wbyq/ui/pages/main_page.dart';
import 'package:wbyq/ui/pages/splash_page.dart';
import 'package:wbyq/wb_id_cloud.dart';

import 'data/api/wbnet_api.dart';
import 'db/db.dart';
import 'ui/pages/login_page.dart';
import 'utils/wb_utils.dart';
import 'wb_plugin.dart';

void main() {
  runApp(BlocProvider<ApplicationBloc>(
      bloc: ApplicationBloc(),
      child: BlocProvider<MainBloc>(
          bloc: MainBloc(), child: OKToast(child: MyApp()))));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> with AutomaticKeepAliveClientMixin {
  Locale? _locale;
  Color _themeColor = Colours.app_main;
  StreamSubscription<Map<String, dynamic>>? userLoginSubscription;
  StreamSubscription<Map<String, dynamic>>? checkLoginSubscription;
  StreamSubscription<int>? appEventSubscription;
  StreamSubscription<WbMessage>? wbmsgSubscription;
  String? appId;
  String versionCode = '1';

  //final AsyncMemoizer _memoizer = AsyncMemoizer();

  @override
  void dispose() {
    userLoginSubscription?.cancel();
    checkLoginSubscription?.cancel();
    appEventSubscription?.cancel();
    wbmsgSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setLocalizedValues(localizedValues);

    //请求权限
    WbUtils.requestAllPermissions();

    _initAsync();
    _initListener();
    _initIdCloud();
    _initAmap();

    WbNetApi.enumMap.clear();
    WbNetApi.homeMap.clear();
  }

  _initAmap() async {
    await AmapLocation.instance.updatePrivacyShow(true);
    await AmapLocation.instance.updatePrivacyAgree(true);

    await AmapLocation.instance.init(iosKey: "ioskey");
  }

  _initIdCloud() async {
    WbIdCloud.instance().showDlg = (Widget dlg, Map<String, dynamic>? map) {
      showToastWidget(dlg, duration: const Duration(milliseconds: 3500));
      final MainBloc? bloc = BlocProvider.of<MainBloc>(context);
      if (ObjectUtil.isNotEmpty(map)) bloc?.nfcIdCard(map!);
    };
  }

  ///初始化app 配置信息 获取版本号 appid 等信息
  _initAppCfg() async {
    appId = await WbUtils.getAppId();
    Map<String, dynamic> map =
        await WbNetApi.getAppClientCfg(appId ?? "") ?? {};
    SpUtil.putObject("APP_CFG", map);

    if (map.containsKey("error")) {
      Notify.error(map['error'], context: context);
    } else {
      var cfg;
      if (Platform.isIOS && map['ipaCfg'] != null) {
        cfg = json.decode(map['ipaCfg']);
        WbPlugin.checkAppUpdate(cfg);
      } else if (Platform.isAndroid && map['apkCfg'] != null) {
        cfg = json.decode(map['apkCfg']);
        WbPlugin.checkAppUpdate(cfg);
      }
      Map<String, dynamic> cfgMap = Map<String, dynamic>.from(cfg);
      versionCode = cfgMap['minVerCode'].toString();
    }
  }

  Future<void> _setDioAccessToken() async {
    if (Constant.RUN_ENV < 4) DioUtil.openDebug();
    await SpUtil.getInstance();

    var accessToken = SpUtil.getString("_ACCESS_TOKEN");
    BaseOptions options = DioUtil.getDefOptions();
    options.baseUrl = Constant.SERVER_ADDRESS;
    var headers = options.headers;

    // 不为空则设置 accessToken 为空进行标记 需要用accessToken
    if (ObjectUtil.isNotEmpty(accessToken)) {
      headers["_ACCESS_TOKEN"] = accessToken;
    } else {
      headers["_ACCESS_TOKEN"] = "";
    }

    var deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      headers["User-Agent"] =
          'Mozilla/5.0 (Linux; Android ${androidInfo.version.release}; ${androidInfo.model} Build/${androidInfo.fingerprint}; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/70.0.3239.83 Mobile Safari/537.36 Dart dart-io wbyq/${AppConfig.androidVersion}/${AppConfig.versionCode}';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      headers["User-Agent"] =
          'Mozilla/5.0 (${iosInfo.model}; ${iosInfo.systemName} ${iosInfo.systemVersion}; CPU like Mac OS X;zh-CN) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/70.0.3239.83 Mobile Safari/537.36 Dart dart-io wbyq/${AppConfig.iosVersion}/${AppConfig.versionCode}';
    }

    options.headers = headers;

    //HttpConfig config =new HttpConfig(options: options, msg: "error", data: null);

    DioUtil().setConfig(options);
  }

  void _initAsync() async {
    try {
      await DB.initAsync();
    } catch (e) {
      print('初始化db出错$e');
    }

    await _initUserLoginAsync();

    if (!mounted) return;

    _loadLocale();
    _initAppCfg();
  }

  Future<void> _initUserLoginAsync() async {
    await _setDioAccessToken();

    final MainBloc? bloc = BlocProvider.of<MainBloc>(context);

    bloc?.checkLogin();
  }

  /// 初始化app监听 登录后设置别名 设置融云id...
  void _initListener() {
    final ApplicationBloc? bloc = BlocProvider.of<ApplicationBloc>(context);
    final MainBloc? mainBloc = BlocProvider.of<MainBloc>(context);
    appEventSubscription = bloc?.appEventStream.listen((value) {
      _loadLocale();
    });

    userLoginSubscription = mainBloc?.userLoginStream.listen((map) {
      var hasError = map.containsKey("error");

      if (map.containsKey('accessToken')) {
        SpUtil.putString("_ACCESS_TOKEN", map["accessToken"]!)?.then(
            (_) => hasError ? _setDioAccessToken() : _initUserLoginAsync());
      }
    });

    ///登录成功后
    checkLoginSubscription = mainBloc?.checkLoginStream.listen((map) {
      if (!map.containsKey("error")) {
        final String userLoginId = map["userLoginId"];
        WbPlugin.get('lastUserLoginId').then((lastUserLoginId) {
          if (ObjectUtil.isEmpty(lastUserLoginId) ||
              lastUserLoginId != userLoginId) {
            print(".............................setAlias==>$userLoginId");
            WbPlugin.setPushAlias(userLoginId);
          }
        });
      }
    });
  }

  void _loadLocale() {
    setState(() {
      LanguageModel? model = SpHelper.getLanguageModel();
      if (model != null) {
        _locale = Locale(model.languageCode, model.countryCode);
      } else {
        _locale = null;
      }

      String colorKey = SpHelper.getThemeColor();
      if (themeColorMap[colorKey] != null) {
        _themeColor = themeColorMap[colorKey]!;
      }
    });
  }

  final Map<String, Function> routes = {
    '/MainPage': (ctx, {arguments}) => MainPage(),
    '/Login': (ctx, {arguments}) => LoginPage(),
  };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MaterialApp(
      title: '健康南川',
      onGenerateRoute: (RouteSettings settings) {
        // 统一处理
        final String? name = settings.name;
        final Function? pageContentBuilder = routes[name];
        if (pageContentBuilder != null) {
          final Route route = MaterialPageRoute(
              builder: (context) =>
                  pageContentBuilder(context, arguments: settings.arguments));

          return route;
        } else {
          return null;
        }
      },
      home: ObjectUtil.isNotEmpty(SpUtil.getString("_ACCESS_TOKEN"))
          ? FutureBuilder<Map<String, dynamic>>(
              future: WbNetApi.getMyLoginInfo(),
              initialData: null,
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, dynamic>> snapshot) {
                if (snapshot.data == null) return const ProgressView();
                Map<String, dynamic>? data;
                if (snapshot.data != null) data = snapshot.data;

                var isLoginIn = false;
                if (data != null) isLoginIn = data["userLoginId"] != null;

                return SplashPage(isLoginIn);
              })
          : SplashPage(false),
      theme: ThemeData.light().copyWith(
        primaryColor: _themeColor,
        //accentColor: _themeColor,
        indicatorColor: Colors.white,
      ),
      locale: _locale,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        CustomLocalizations.delegate,
        //Fcl.GlobalCupertinoLocalizations.delegate, //解决长按 textfield 弹出 菜单 ios上出错
      ],
      supportedLocales: CustomLocalizations.supportedLocales,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
