import '../a_z_list_view/az_common.dart';

class StudentInfoModel extends ISuspensionBean {
  String? studentId;
  String? name;
  String? idcardNumber;
  String? schoolName;
  String? gradeName;
  String? className;
  String? detailId;
  String? hasSymptom;
  String? statusName;
  String? personType;
  String? statusCode;
  String? tagIndex;
  String? pinyin;

  StudentInfoModel(
      {this.studentId,
      this.name,
      this.idcardNumber,
      this.schoolName,
      this.gradeName,
      this.className,
      this.detailId,
      this.hasSymptom,
      this.statusName,
      this.personType,
      this.statusCode,
      this.tagIndex,
      this.pinyin});

  StudentInfoModel.fromJson(Map<String, dynamic> json)
      : studentId = json['studentId'],
        name = json['name'],
        idcardNumber = json['idcardNumber'],
        schoolName = json['schoolName'],
        gradeName = json['gradeName'],
        className = json['className'],
        detailId = json['detailId'],
        hasSymptom = json['hasSymptom'],
        statusName = json['statusName'],
        personType = json['personType'],
        statusCode = json['statusCode'],
        pinyin = json['pinyin'],
        tagIndex = json['tagIndex'];

  get patientName => null;

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'name': name,
        'idcardNumber': idcardNumber,
        'schoolName': schoolName,
        'gradeName': gradeName,
        'className': className,
        'detailId': detailId,
        'hasSymptom': hasSymptom,
        'linkmanIdNo': statusName,
        'personType': personType,
        'statusCode': statusCode,
        'tagIndex': tagIndex,
        'pinyin': pinyin
      };

  @override
  String getSuspensionTag() => tagIndex ?? '';
}
