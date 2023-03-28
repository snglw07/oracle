import 'package:amap_core_fluttify/amap_core_fluttify.dart';
import 'package:amap_location_fluttify/amap_location_fluttify.dart';
import 'package:wbyq/common/component_index.dart';

class LocationMap {
  /// 地址全称
  String address = '';

  /// 海拔
  double altitude = 0;

  /// 纬度
  double latitude = 0;

  /// 经度
  double longitude = 0;

  /// 国家
  String country = '';

  /// 省份
  String province = '';

  /// 城市
  String city = '';

  /// 区域
  String district = '';

  /// 街道
  String street = '';

  /// 定位时间
  int time = 0;

  /// poiname
  String name = '';

  late Location _location;
  Map _map = Map();

  LocationMap(Location location) {
    _location = location;
    initMapValue();
  }

  initMapValue() async {
    time = DateTime.now().millisecondsSinceEpoch;
    LatLng? latLng = _location.latLng;
    latitude = latLng?.latitude ?? 0;
    longitude = latLng?.longitude ?? 0;
    address = _location.address ?? "";
    altitude = _location.altitude ?? 0;
    country = _location.country ?? "";
    province = _location.province ?? "";
    city = _location.city ?? "";
    district = _location.district ?? "";
    street = _location.street ?? "";
    name = _location.poiName ?? "";
    _map['time'] = time;
    _map['latitude'] = latitude;
    _map['longitude'] = longitude;
    _map['address'] = address;
    _map['altitude'] = altitude;
    _map['country'] = country;
    _map['province'] = province;
    _map['city'] = city;
    _map['district'] = district;
    _map['street'] = street;
    _map['name'] = name;
  }

  Future<String> toJsonString() async {
    if (ObjectUtil.isEmpty(_map)) await initMapValue();
    return JsonCodec().encode(_map);
  }
}
