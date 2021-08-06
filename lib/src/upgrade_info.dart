class UpgradeInfo {
  ///唯一标识
  String? id = "";

  ///升级提示标题
  String? title = "";

  ///升级特性描述
  String? newFeature = "";

  ///升级发布时间,ms
  int? publishTime = 0;

  ///升级类型 0测试 1正式
  int? publishType = 0;

  ///升级策略 1建议 2强制 3手工
  int? upgradeType = 1;

  ///提醒次数
  int? popTimes = 0;

  ///提醒间隔
  int? popInterval = 0;

  ///版本号
  int? versionCode = 0;

  ///版本名称
  String? versionName = "";

  ///包md5值
  String? apkMd5;

  ///APK的CDN外网下载地址
  String? apkUrl;

  ///APK文件的大小
  int? fileSize;

  /// 图片url
  String? imageUrl;

  ///升级类型
  int? updateType;

  UpgradeInfo.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        newFeature = json['newFeature'],
        publishTime = json['publishTime'],
        publishType = json['publishType'],
        upgradeType = json['upgradeType'],
        popTimes = json['popTimes'],
        popInterval = json['popInterval'],
        versionCode = json['versionCode'],
        versionName = json['versionName'],
        apkMd5 = json['apkMd5'],
        apkUrl = json['apkUrl'],
        fileSize = json['fileSize'],
        imageUrl = json['imageUrl'],
        updateType = json['updateType'];

  ///校验对象是否有效
  bool checkData() {
    return id != null && apkMd5 != null && apkUrl != null;
  }
}