import '../a_z_list_view/az_common.dart';

class PatientInfoModel extends ISuspensionBean {
  String? patientId;
  String? patientName;
  String? bunkId;
  num? credentialType;
  String? credentialNum;
  String? credentialTypeName;
  String? hospitalId;
  String? treatDeptCode;
  String? medicalNum;
  num? validateCount;
  String? treatDate;
  String? faceTicket;
  String? vEnabled;
  num? dayCount;
  num? indays;
  num? sexId;
  String? tagIndex;
  String? pinyin;

  PatientInfoModel(
      {this.patientId,
      this.patientName,
      this.bunkId,
      this.credentialType,
      this.credentialNum,
      this.credentialTypeName,
      this.hospitalId,
      this.treatDeptCode,
      this.medicalNum,
      this.validateCount,
      this.treatDate,
      this.faceTicket,
      this.vEnabled,
      this.dayCount,
      this.indays,
      this.sexId,
      this.tagIndex,
      this.pinyin});

  PatientInfoModel.fromJson(Map<String, dynamic> json)
      : patientId = json['patientId'],
        patientName = json['patientName'],
        bunkId = json['bunkId'],
        credentialType = json['credentialType'],
        credentialNum = json['credentialNum'],
        credentialTypeName = json['credentialTypeName'],
        hospitalId = json['hospitalId'],
        treatDeptCode = json['treatDeptCode'],
        medicalNum = json['medicalNum'],
        validateCount = json['validateCount'],
        treatDate = json['treatDate'],
        faceTicket = json['faceTicket'],
        vEnabled = json['vEnabled'],
        dayCount = json['dayCount'],
        indays = json['indays'],
        sexId = json['sexId'],
        pinyin = json['pinyin'],
        tagIndex = json['tagIndex'];

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'patientName': patientName,
        'bunkId': bunkId,
        'credentialType': credentialType,
        'credentialNum': credentialNum,
        'credentialTypeName': credentialTypeName,
        'hospitalId': hospitalId,
        'treatDeptCode': treatDeptCode,
        'medicalNum': medicalNum,
        'validateCount': validateCount,
        'treatDate': treatDate,
        'faceTicket': faceTicket,
        'vEnabled': vEnabled,
        'dayCount': dayCount,
        'indays': indays,
        'sexId': sexId,
        'tagIndex': tagIndex,
        'pinyin': pinyin,
      };

  @override
  String toString() {
    StringBuffer sb = new StringBuffer('{');
    sb.write("\"userLoginId\":\"$patientId\"");
    sb.write(",\"lastName\":\"$patientName\"");
    sb.write(",\"sex\":\"$bunkId\"");
    sb.write(",\"accessToken\":\"$credentialType\"");
    sb.write(",\"thumb\":\"$credentialNum\"");
    sb.write(",\"thumb\":\"$credentialTypeName\"");
    sb.write(",\"thumb\":\"$hospitalId\"");
    sb.write(",\"thumb\":\"$treatDeptCode\"");
    sb.write(",\"thumb\":\"$medicalNum\"");
    sb.write(",\"thumb\":\"$validateCount\"");
    sb.write(",\"thumb\":\"$treatDate\"");
    sb.write(",\"thumb\":\"$faceTicket\"");
    sb.write(",\"thumb\":\"$vEnabled\"");
    sb.write(",\"thumb\":\"$dayCount\"");
    sb.write(",\"thumb\":\"$indays\"");
    sb.write(",\"thumb\":\"$sexId\"");
    sb.write(",\"thumb\":\"$tagIndex\"");
    sb.write(",\"thumb\":\"$pinyin\"");
    sb.write('}');
    return sb.toString();
  }

  @override
  String getSuspensionTag() => tagIndex ?? '';
}
