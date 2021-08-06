///初始化bugly，响应对象
class InitResultInfo {
  String message = "";
  String appId = "";
  bool isSuccess = false;

  InitResultInfo.fromJson(Map<String, dynamic> json)
      : message = json['message'],
        appId = json['appId'],
        isSuccess = json['isSuccess'];

  InitResultInfo.noSupport() {
    this.message = '不支持非Android平台';
    this.isSuccess = false;
  }
}