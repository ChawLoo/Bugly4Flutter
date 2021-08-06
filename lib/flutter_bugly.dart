import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:bugly/src/init_result_info.dart';
import 'package:bugly/src/upgrade_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterBugly {
  FlutterBugly._();

  static const MethodChannel _channel = MethodChannel('com.qw.flutter.plugins/bugly');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }


  static final _onCheckUpgrade = StreamController<UpgradeInfo>.broadcast();
  static int _checkUpgradeCount = 0;
  static int _count = 0;

  ///bugly是否已经初始化了
  static bool isInit = false;

  ///捕获到异常时，回调该方法
  static Function(String crashMessage, String crashDetail)? _onCatchCallback;

  ///初始化
  ///[androidAppId] Android appId
  ///[iOSAppId] ios目前没使用
  ///[channel]自定义渠道标识
  ///[autoInit]自动初始化开关：true表示app启动自动初始化升级模块; false不会自动初始化
  ///[autoCheckUpgrade]自动检查更新开关：true表示初始化时自动检查升级; false表示不会自动检查升级,需要手动调用Beta.checkUpgrade()方法
  ///[autoDownloadOnWifi]设置Wifi下自动下载：如果你想在Wifi网络下自动下载，可以将这个接口设置为true，默认值为false
  ///[enableHotfix]热更新开关：升级SDK默认是开启热更新能力的，如果你不需要使用热更新，可以将这个接口设置为false
  ///[enableNotification]设置是否显示消息通知：如果你不想在通知栏显示下载进度，你可以将这个接口设置为false，默认值为true
  ///[showInterruptedStrategy] 设置开启显示打断策略：true，设置点击过确认的弹窗在App下次启动自动检查更新时会再次显示
  ///[canShowApkInfo]设置是否显示弹窗中的apk信息：如果你使用bugly默认弹窗是会显示apk信息的，如果你不想显示可以将这个接口设置为false
  ///[initDelay]延迟初始化：设置启动延时为（默认延时3s），APP启动3s后初始化SDK，避免影响APP启动速度;
  ///[upgradeCheckPeriod] 升级检查周期设置：设置升级检查周期为60s(默认检查周期为0s)，60s内SDK不重复向后台请求策略);
  ///[customUpgrade]  是否自定义升级
  ///[checkUpgradeCount] UpgradeInfo为null时，再次check的次数，经测试1为最佳
  static Future<InitResultInfo> init({
    String? androidAppId,
    String? iOSAppId,
    String? channel,
    bool autoInit = true,
    bool autoCheckUpgrade = true,
    bool autoDownloadOnWifi = false,
    bool enableHotfix = false,
    bool enableNotification = true,
    bool showInterruptedStrategy = true,
    bool canShowApkInfo = true,
    int initDelay = 3,
    int upgradeCheckPeriod = 0,
    bool customUpgrade = false,
    int checkUpgradeCount = 1,
  }) async {
    if (!Platform.isAndroid) {
      return InitResultInfo.noSupport();
    }

    assert((Platform.isAndroid && androidAppId != null) || (Platform.isIOS && iOSAppId != null));

    _channel.setMethodCallHandler(_handleMessages);
    _checkUpgradeCount = checkUpgradeCount;

    Map<String, Object> map = {
      "appId": (Platform.isAndroid ? androidAppId : iOSAppId) ?? '',
      "channel": channel ?? '',
      "autoInit": autoInit,
      "autoCheckUpgrade": autoCheckUpgrade,
      "autoDownloadOnWifi": autoDownloadOnWifi,
      "enableHotfix": enableHotfix,
      "enableNotification": enableNotification,
      "showInterruptedStrategy": showInterruptedStrategy,
      "canShowApkInfo": canShowApkInfo,
      "initDelay": initDelay,
      "upgradeCheckPeriod": upgradeCheckPeriod,
      "customUpgrade": customUpgrade,
    };

    final String result = await _channel.invokeMethod('initBugly', map);
    Map<String, dynamic> resultMap = json.decode(result);
    var resultBean = InitResultInfo.fromJson(resultMap);

    isInit = true;
    return resultBean;
  }

  static Future<void> _handleMessages(MethodCall call) async {
    switch (call.method) {
      case 'onCheckUpgrade':
        UpgradeInfo? _info = _decodeUpgradeInfo(call.arguments["upgradeInfo"]);
        if (_info != null && _info.checkData()) {
          _count = 0;
          _onCheckUpgrade.add(_info);
        } else {
          if (_count < _checkUpgradeCount) {
            _count++;
            checkUpgrade(isManual: false);
          }
        }
        break;
    }
  }

  ///自定义渠道标识 android专用
  static Future<void> setAppChannel(String channel) async {
    if (!Platform.isAndroid) {
      return;
    }

    Map<String, Object> map = {
      "channel": channel,
    };
    await _channel.invokeMethod('setAppChannel', map);
  }

  ///设置用户标识
  static Future<void> setUserId(String userId) async {
    if (!Platform.isAndroid) {
      return;
    }

    Map<String, Object> map = {
      "userId": userId,
    };
    await _channel.invokeMethod('setUserId', map);
  }

  ///设置标签
  ///userTag 标签ID，可在网站生成
  static Future<void> setUserTag(int userTag) async {
    if (!Platform.isAndroid) {
      return;
    }

    Map<String, Object> map = {
      "userTag": userTag,
    };
    await _channel.invokeMethod('setUserTag', map);
  }

  ///设置关键数据，随崩溃信息上报
  static Future<void> putUserData({required String key, required String value}) async {
    if (!Platform.isAndroid) {
      return;
    }

    assert(key.isNotEmpty);
    assert(value.isNotEmpty);

    Map<String, Object> map = {
      "key": key,
      "value": value,
    };
    await _channel.invokeMethod('putUserData', map);
  }

  ///获取本地已有升级策略（非实时，可用于界面红点展示）
  static Future<UpgradeInfo?> getUpgradeInfo() async {
    if (!Platform.isAndroid) {
      return null;
    }

    final String result = await _channel.invokeMethod('getUpgradeInfo');
    var info = _decodeUpgradeInfo(result);
    return info;
  }

  ///检查更新
  ///[isManual]用户手动点击检查，非用户点击操作请传false
  ///[isSilence]是否显示弹窗等交互，[true:没有弹窗和toast] [false:有弹窗或toast]
  ///return 更新策略信息
  static Future<void> checkUpgrade({
    bool isManual = true,
    bool isSilence = false,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }

    if (isManual) _count = 0;
    Map<String, Object> map = {
      "isManual": isManual,
      "isSilence": isSilence,
    };
    await _channel.invokeMethod('checkUpgrade', map);
  }

  ///全局异常捕获，用于bugly异常上报，[app]#[main]方法中调用
  ///如果不使用该方法，可以自行捕获异常后，调用[FlutterBugly]#[uploadException]方法手动上报异常到bugly
  ///[callback]
  ///[onCatchCallback] 异常捕捉后，回调该方法
  ///[filterRegExp] 异常上报过滤正则，针对异常message
  ///[debugUpload] debug模式，是否上传错误日志到bugly
  static void postCatchException<T>(
    T Function() callback, {
    Function(String crashMessage, String crashDetail)? onCatchCallback,
    String? filterRegExp,
    bool debugUpload = false,
  }) {
    bool isDebug = false;
    assert(isDebug = true);

    _onCatchCallback = onCatchCallback;

    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.stack != null) {
        Zone.current.handleUncaughtError(details.exception, details.stack!);
      }
    };

    Isolate.current.addErrorListener(RawReceivePort((dynamic pair) {
      var isolateError = pair as List<dynamic>;
      var _error = isolateError.first;
      var _stackTrace = isolateError.last;

      Zone.current.handleUncaughtError(_error, _stackTrace);
    }).sendPort);
    runZonedGuarded<Future<void>>(() async {
      callback();
    }, (error, stackTrace) {
      FlutterErrorDetails details = FlutterErrorDetails(exception: error, stack: stackTrace);
      if (_filterException(debugUpload, isDebug, filterRegExp, details)) {
        _onCatchCallback?.call(details.exception.toString(), details.stack.toString());
      } else {
        uploadException(message: details.exception.toString(), detail: details.stack.toString());
      }
    });
  }

  ///[return] 返回，是否过滤异常
  static bool _filterException(
    bool debugUpload,
    bool _isDebug,
    String? filterRegExp,
    FlutterErrorDetails details,
  ) {
    if (_isDebug) {
      ///debug模式,控制台打印异常日志
      FlutterError.dumpErrorToConsole(details);
    }

    ///默认debug下打印异常，不上传异常
    if (!debugUpload && _isDebug) {
      return true;
    }

    ///异常过滤
    if (filterRegExp != null) {
      RegExp reg = RegExp(filterRegExp);
      Iterable<Match> matches = reg.allMatches(details.exception.toString());
      if (matches.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  ///上报自定义异常信息，data为文本附件
  ///Android 错误分析=>跟踪数据=>extraMessage.txt
  ///iOS 错误分析=>跟踪数据=>crash_attach.log
  static Future<void> uploadException({
    required String message,
    required String detail,
    Map? data,
  }) async {
    ///同时将上报的异常日志回传到调用者，用于打印或保存为文件
    _onCatchCallback?.call(message, detail);

    if (!Platform.isAndroid || !isInit) {
      return;
    }

    var map = {};
    map.putIfAbsent("crash_message", () => message);
    map.putIfAbsent("crash_detail", () => detail);
    if (data != null) map.putIfAbsent("crash_data", () => data);

    ///bugly上传日志
    await _channel.invokeMethod('postCatchedException', map);
  }

  ///解析json获取UpgradeInfo对象
  static UpgradeInfo? _decodeUpgradeInfo(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    Map<String, dynamic> resultMap = json.decode(jsonStr);
    var info = UpgradeInfo.fromJson(resultMap);
    return info;
  }

  ///当配置 customUpgrade=true 时，可以通过onCheckUpgrade接收自定义升级回调
  static Stream<UpgradeInfo> get onCheckUpgrade => _onCheckUpgrade.stream;

  ///应用退出时调用该方法
  static void dispose() {
    _count = 0;
    _onCheckUpgrade.close();
  }
}
