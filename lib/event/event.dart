import 'package:wbyq/common/component_index.dart';

class StatusEvent {
  String labelId;
  RefreshStatus status;
  int? cid;

  StatusEvent(this.labelId, this.status, {this.cid});
}
