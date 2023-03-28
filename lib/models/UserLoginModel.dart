class UserLoginModel {
  String? userLoginId;
  String? lastName;
  String? sex;
  String? accessToken;

  String? thumb;

  UserLoginModel({this.userLoginId, this.lastName, this.sex, this.accessToken});

  UserLoginModel.fromJson(Map<String, dynamic> json)
      : userLoginId = json['userLoginId'],
        lastName = json['lastName'],
        sex = json['sex'],
        accessToken = json['accessToken'],
        thumb = json['thumb'];

  Map<String, dynamic> toJson() => {
        'userLoginId': userLoginId,
        'lastName': lastName,
        'sex': sex,
        'accessToken': accessToken,
        'thumb': thumb,
      };

  @override
  String toString() {
    StringBuffer sb = StringBuffer('{');
    sb.write("\"userLoginId\":\"$userLoginId\"");
    sb.write(",\"lastName\":\"$lastName\"");
    sb.write(",\"sex\":\"$sex\"");
    sb.write(",\"accessToken\":\"$accessToken\"");
    sb.write(",\"thumb\":\"$thumb\"");
    sb.write('}');
    return sb.toString();
  }
}
