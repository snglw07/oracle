import 'dart:collection';
import 'dart:io';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/data/repository/wan_repository.dart';
import 'package:wbyq/event/event.dart';
import 'package:wbyq/models/UserLoginModel.dart';

import '../a_z_list_view/az_common.dart';
import '../application.dart';

class MainBloc implements BlocBase {
  ///****** ****** ****** Home ****** ****** ****** /

  BehaviorSubject<List<BannerModel>> _banner =
      BehaviorSubject<List<BannerModel>>();

  Sink<List<BannerModel>> get _bannerSink => _banner.sink;

  Stream<List<BannerModel>> get bannerStream => _banner.stream;

  BehaviorSubject<List<ReposModel>> _recRepos =
      BehaviorSubject<List<ReposModel>>();

  Sink<List<ReposModel>> get _recReposSink => _recRepos.sink;

  Stream<List<ReposModel>> get recReposStream => _recRepos.stream;

  BehaviorSubject<List<ReposModel>> _recWxArticle =
      BehaviorSubject<List<ReposModel>>();

  Sink<List<ReposModel>> get _recWxArticleSink => _recWxArticle.sink;

  Stream<List<ReposModel>> get recWxArticleStream => _recWxArticle.stream;

  ///****** ****** ****** Home ****** ****** ****** /

  ///****** ****** ****** Repos ****** ****** ****** /
  BehaviorSubject<List<ReposModel>> _repos =
      BehaviorSubject<List<ReposModel>>();

  Sink<List<ReposModel>> get _reposSink => _repos.sink;

  Stream<List<ReposModel>> get reposStream => _repos.stream;

  List<ReposModel>? _reposList;
  int _reposPage = 0;

  ///****** ****** ****** Repos ****** ****** ****** /

  ///****** ****** ****** Events ****** ****** ****** /

  BehaviorSubject<List<ReposModel>> _events =
      BehaviorSubject<List<ReposModel>>();

  Sink<List<ReposModel>> get _eventsSink => _events.sink;

  Stream<List<ReposModel>> get eventsStream => _events.stream;

  List<ReposModel>? _eventsList;
  int _eventsPage = 0;

  ///****** ****** ****** Events ****** ****** ****** /

  ///****** ****** ****** System ****** ****** ****** /

  BehaviorSubject<List<TreeModel>> _tree = BehaviorSubject<List<TreeModel>>();

  Sink<List<TreeModel>> get _treeSink => _tree.sink;

  Stream<List<TreeModel>> get treeStream => _tree.stream;

  List<TreeModel>? _treeList;

  ///****** ****** ****** System ****** ****** ****** /

  ///****** ****** ****** Version ****** ****** ****** /

  BehaviorSubject<VersionModel> _version = BehaviorSubject<VersionModel>();

  Sink<VersionModel> get _versionSink => _version.sink;

  Stream<VersionModel> get versionStream => _version.stream.asBroadcastStream();

  VersionModel? _versionModel;

  BehaviorSubject<StatusEvent> _homeEvent = BehaviorSubject<StatusEvent>();

  Sink<StatusEvent> get _homeEventSink => _homeEvent.sink;

  Stream<StatusEvent> get homeEventStream =>
      _homeEvent.stream.asBroadcastStream();

  ///****** ****** ****** personal ****** ****** ****** /

  BehaviorSubject<ComModel> _recItem = BehaviorSubject<ComModel>();

  Sink<ComModel> get _recItemSink => _recItem.sink;

  Stream<ComModel> get recItemStream => _recItem.stream.asBroadcastStream();

  ComModel? hotRecModel;

  BehaviorSubject<List<ComModel>> _recList = BehaviorSubject<List<ComModel>>();

  Sink<List<ComModel>> get _recListSink => _recList.sink;

  Stream<List<ComModel>> get recListStream =>
      _recList.stream.asBroadcastStream();

  List<ComModel>? hotRecList;

  ///****** ****** ****** personal ****** ****** ****** /

  ///****** ****** ****** check login ****** ****** ****** /
  var _checkLogin = BehaviorSubject<Map<String, dynamic>>();
  Sink<Map<String, dynamic>> get checkLoginSink => _checkLogin.sink;
  Stream<Map<String, dynamic>> get checkLoginStream => _checkLogin.stream;

  ///****** ****** ****** check login ****** ****** ****** /

  ///****** ****** ****** user login ****** ****** ****** /
  var _userLogin = PublishSubject<Map<String, dynamic>>();

  Sink<Map<String, dynamic>> get userLoginSink => _userLogin.sink;

  Stream<Map<String, dynamic>> get userLoginStream =>
      _userLogin.stream.asBroadcastStream();

  var _heartBeat = BehaviorSubject<Map<String, dynamic>>();

  Sink<Map<String, dynamic>> get heartBeatSink => _heartBeat.sink;

  Stream<Map<String, dynamic>> get heartBeatStream =>
      _heartBeat.stream.asBroadcastStream();

  ///****** ****** ****** user login ****** ****** ****** /

  ///****** ****** ****** user login ex ****** ****** ****** /
  var _userLoginExInfo = PublishSubject<Map<String, dynamic>>();

  Sink<Map<String, dynamic>> get userLoginExInfoSink => _userLoginExInfo.sink;

  Stream<Map<String, dynamic>> get userLoginExInfoStream =>
      _userLoginExInfo.stream.asBroadcastStream();

  var _signCount = PublishSubject<Map<String, dynamic>>();

  Sink<Map<String, dynamic>> get signCountSink => _signCount.sink;

  Stream<Map<String, dynamic>> get signCountStream =>
      _signCount.stream.asBroadcastStream();

  ///****** ****** ****** user login ex ****** ****** ****** /

  ///****** ****** ****** enumeration ****** ****** ****** /
  var _enumeration = BehaviorSubject<Map<String, dynamic>>();

  Sink<Map<String, dynamic>> get enumerationSink => _enumeration.sink;

  Stream<Map<String, dynamic>> get enumerationStream =>
      _enumeration.stream.asBroadcastStream();

  var _smsCode = PublishSubject<Map<String, dynamic>>();

  Sink<Map<String, dynamic>> get smsCodeSink => _smsCode.sink;

  Stream<Map<String, dynamic>> get smsCodeStream =>
      _smsCode.stream.asBroadcastStream();

  ///****** ****** ****** enumeration ****** ****** ****** /

  var _patientCount = PublishSubject<Map<String, dynamic>>();

  Sink<Map<String, dynamic>> get patientCountSink => _patientCount.sink;

  Stream<Map<String, dynamic>> get patientCountStream =>
      _patientCount.stream.asBroadcastStream();

  var _patientList = PublishSubject<Map<String, dynamic>>();

  Sink<Map<String, dynamic>> get patientListSink => _patientList.sink;

  Stream<Map<String, dynamic>> get patientListStream =>
      _patientList.stream.asBroadcastStream();

  var _nfcIdCard = PublishSubject<Map<String, dynamic>>();

  Sink<Map<String, dynamic>> get nfcIdCardSink => _nfcIdCard.sink;

  Stream<Map<String, dynamic>> get nfcIdCardStream =>
      _nfcIdCard.stream.asBroadcastStream();

  WanRepository wanRepository = new WanRepository();

  HttpUtils httpUtils = new HttpUtils();

  MainBloc() {
    LogUtil.e("MainBloc......");
  }

  @override
  Future getData({String? labelId, int? page}) {
    switch (labelId) {
      case Ids.titleHome:
        return getHomeData(labelId);
      case Ids.titleRepos:
        return getArticleListProject(labelId, page);
      case Ids.titleEvents:
        return getArticleList(labelId, page);
      case Ids.titleSystem:
        return getTree(labelId);
      default:
        return Future.delayed(new Duration(seconds: 1));
    }
  }

  @override
  Future onLoadMore({String? labelId}) {
    int _page = 0;
    switch (labelId) {
      case Ids.titleHome:
        break;
      case Ids.titleRepos:
        _page = ++_reposPage;
        break;
      case Ids.titleEvents:
        _page = ++_eventsPage;
        break;
      case Ids.titleSystem:
        break;
      default:
        break;
    }
    LogUtil.e("onLoadMore labelId: $labelId" +
        "   _page: $_page" +
        "   _reposPage: $_reposPage");
    return getData(labelId: labelId, page: _page);
  }

  @override
  Future onRefresh({String? labelId}) {
    switch (labelId) {
      case Ids.titleHome:
        getHotRecItem();
        break;
      case Ids.titleRepos:
        _reposPage = 0;
        break;
      case Ids.titleEvents:
        _eventsPage = 0;
        break;
      case Ids.titleSystem:
        break;
      default:
        break;
    }
    LogUtil.e("onRefresh labelId: $labelId" + "   _reposPage: $_reposPage");
    return getData(labelId: labelId, page: 0);
  }

  Future getHomeData(String? labelId) {
    getRecRepos(labelId);
    getRecWxArticle(labelId);
    return getBanner(labelId);
  }

  Future getBanner(String? labelId) {
    return wanRepository.getBanner().then((list) {
      _bannerSink.add(UnmodifiableListView<BannerModel>(list));
    });
  }

  Future getRecRepos(String? labelId) async {
    ComReq _comReq = new ComReq(402);
    wanRepository.getProjectList(data: _comReq.toJson()).then((list) {
      if (list.length > 6) {
        list = list.sublist(0, 6);
      }
      _recReposSink.add(UnmodifiableListView<ReposModel>(list));
    });
  }

  Future getRecWxArticle(String? labelId) async {
    int _id = 408;
    wanRepository.getWxArticleList(id: _id).then((list) {
      if (list.length > 6) {
        list = list.sublist(0, 6);
      }
      _recWxArticleSink.add(UnmodifiableListView<ReposModel>(list));
    });
  }

  Future getArticleListProject(String? labelId, int? page) {
    return wanRepository.getArticleListProject(page ?? 0).then((list) {
      if (_reposList == null) {
        _reposList = [];
      }
      if (page == 0) {
        _reposList?.clear();
      }
      _reposList?.addAll(list);
      _reposSink.add(UnmodifiableListView<ReposModel>(_reposList!));
      _homeEventSink.add(new StatusEvent(
          labelId ?? "",
          ObjectUtil.isEmpty(list)
              ? RefreshStatus.noMore
              : RefreshStatus.idle));
    }).catchError((_) {
      _reposPage--;
      _homeEventSink.add(new StatusEvent(labelId ?? "", RefreshStatus.failed));
    });
  }

  Future getArticleList(String? labelId, int? page) {
    return wanRepository.getArticleList(page: page ?? 0).then((list) {
      if (_eventsList == null) {
        _eventsList = [];
      }
      if (page == 0) {
        _eventsList?.clear();
      }
      _eventsList?.addAll(list);
      _eventsSink.add(UnmodifiableListView<ReposModel>(_eventsList!));
      _homeEventSink.add(new StatusEvent(
          labelId ?? "",
          ObjectUtil.isEmpty(list)
              ? RefreshStatus.noMore
              : RefreshStatus.idle));
    }).catchError((_) {
      _eventsPage--;
      _homeEventSink.add(new StatusEvent(labelId ?? "", RefreshStatus.failed));
    });
  }

  Future getTree(String? labelId) {
    return wanRepository.getTree().then((list) {
      if (_treeList == null) {
        _treeList = [];
      }

      for (int i = 0, length = list.length; i < length; i++) {
        String tag = Utils.getPinyin(list[i].name ?? '');
        if (RegExp("[A-Z]").hasMatch(tag)) {
          list[i].tagIndex = tag;
        } else {
          list[i].tagIndex = "#";
        }
      }
      SuspensionUtil.sortListBySuspensionTag(list);

      _treeList?.clear();
      _treeList?.addAll(list);
      _treeSink.add(UnmodifiableListView<TreeModel>(_treeList!));
      _homeEventSink.add(new StatusEvent(
          labelId ?? "",
          ObjectUtil.isEmpty(list)
              ? RefreshStatus.noMore
              : RefreshStatus.idle));
    }).catchError((_) {
      _homeEventSink.add(new StatusEvent(labelId ?? "", RefreshStatus.failed));
    });
  }

  Future getVersion() async {
    httpUtils.getVersion().then((model) {
      _versionModel = model;
      _versionSink.add(_versionModel!);
    });
  }

  Future getHotRecItem() async {
    httpUtils.getRecItem().then((model) {
      hotRecModel = model;
      _recItemSink.add(hotRecModel!);
    });
  }

  Future getHotRecList(String labelId) async {
    httpUtils.getRecList().then((list) {
      hotRecList = list;
      _recListSink.add(UnmodifiableListView<ComModel>(list));
      _homeEventSink.add(new StatusEvent(
          labelId,
          ObjectUtil.isEmpty(list)
              ? RefreshStatus.noMore
              : RefreshStatus.idle));
    }).catchError((_) {
      _homeEventSink.add(new StatusEvent(labelId, RefreshStatus.failed));
    });
  }

  Future<Map<String, dynamic>> checkLogin() {
    return WbNetApi.getMyLoginInfo().then((Map<String, dynamic> result) {
      if (!result.containsKey("error")) {
        Application.userLoginModel = UserLoginModel.fromJson(result);
      }

      _checkLogin.sink.add(result);

      return result;
    });
  }

  Future<Map<String, dynamic>> loginForAccessToken(String userLoginId,
      String password, String checkcode, String logintype, String other,
      {String? sign, String? deviceType}) {
    return WbNetApi.loginForAccessToken(userLoginId,
            password: password,
            checkcode: checkcode,
            logintype: logintype,
            other: other,
            sign: sign,
            deviceType: deviceType)
        .then((Map<String, dynamic>? result) {
      result ??= <String, dynamic>{};

      if (result.containsKey("user")) {
        var user = result['user'];
        Application.userLoginModel = UserLoginModel.fromJson(user);
      }

      _userLogin.sink.add(result);

      return result;
    });
  }

  Future<Map<String, dynamic>> sendSmsCode(String phoneNumber) async {
    Map<String, dynamic>? query = await WbNetApi.sendSmsCode(phoneNumber);
    _smsCode.sink.add(query ?? Map());
    return query ?? Map();
  }

  Future<Map<String, dynamic>> appHeartbeat(
      String appId, String userLoginId, String onlineStatus) async {
    String key = "$appId.$userLoginId.onlineStatus";
    SpUtil.putString(key, onlineStatus);
    await WbNetApi.appHeartbeat(appId, onlineStatus);
    Map<String, dynamic> result = {'onlineStatus': onlineStatus};
    _heartBeat.sink.add(result);
    return result;
  }

  Future<Map<String, dynamic>> patientList(String companyId,
      {String? depId, String? bqId, String? param}) async {
    return WbNetApi.getPatientList(companyId, param: param)
        .then((Map<String, dynamic>? result) {
      _patientList.sink.add(result ?? Map());
      return result ?? Map();
    });
  }

  Future<Map<String, dynamic>> fileUpload(File file, String fileName) async {
    Map<String, dynamic>? result = await WbNetApi.postFile(file, fileName);
    return result ?? Map();
  }

  Future<Map<String, dynamic>> nfcIdCard(Map<String, dynamic> map) async {
    _nfcIdCard.sink.add(map);
    return map;
  }

  @override
  void dispose() {
    _banner.close();
    _recRepos.close();
    _recWxArticle.close();
    _repos.close();
    _events.close();
    _tree.close();
    _homeEvent.close();
    _version.close();
    _recItem.close();
    _recList.close();
    _userLogin.close();
    _heartBeat.close();
    _checkLogin.close();
    _userLoginExInfo.close();
    _signCount.close();
    _smsCode.close();
    _enumeration.close();
    _patientCount.close();
    _patientList.close();
    _nfcIdCard.close();
  }
}
