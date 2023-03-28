import 'package:wbyq/blocs/bloc_provider.dart';
import 'package:rxdart/rxdart.dart';

import '../wb_plugin.dart';

class ApplicationBloc implements BlocBase {
  BehaviorSubject<int> _appEvent = BehaviorSubject<int>();

  Sink<int> get _appEventSink => _appEvent.sink;

  Stream<int> get appEventStream => _appEvent.stream;

  //wbpush消息
  PublishSubject<WbMessage> _wbmsg = PublishSubject<WbMessage>();

  Sink<WbMessage> get wbmsgSink => _wbmsg.sink;

  Stream<WbMessage> get wbmsgStream => _wbmsg.stream.asBroadcastStream();

  //wbpush消息 处理 回调
  PublishSubject<Map> _wbmsgCB = PublishSubject<Map>();

  //Sink<Map> get wbmsgCBSink => _wbmsgCB.sink;

  //Stream<Map> get wbmsgCBStream =>_wbmsgCB.stream.asBroadcastStream();

  @override
  void dispose() {
    _appEvent.close();
    _wbmsg.close();
    _wbmsgCB.close();
  }

  @override
  Future<dynamic> getData({String? labelId, int? page}) {
    return Future.value(null);
  }

  @override
  Future onLoadMore({String? labelId}) {
    return Future.value(null);
  }

  @override
  Future onRefresh({String? labelId}) {
    return Future.value(null);
  }

  void sendAppEvent(int type) {
    _appEventSink.add(type);
  }
}
