import 'flutter_android_launcher_platform_interface.dart';
import 'package:flutter/services.dart';

class FlutterAndroidLauncher {
  Future<String?> getPlatformVersion() {
    return FlutterAndroidLauncherPlatform.instance.getPlatformVersion();
  }

  Future<List<Map<String, String>>> getInstalledApps() {
    return FlutterAndroidLauncherPlatform.instance.getInstalledApps();
  }

  Future<void> launchApp(String packageName, String profile) {
    return FlutterAndroidLauncherPlatform.instance.launchApp(packageName, profile);
  }

  Future<List<Map<String, String>>> getLauncherUserInfo() {
    return FlutterAndroidLauncherPlatform.instance.getLauncherUserInfo();
  }

  Future<bool> isQuietModeEnabled(String profile) {
    return FlutterAndroidLauncherPlatform.instance.isQuietModeEnabled(profile);
  }

  Future<bool> requestQuietModeEnabled(bool enableQuietMode, String profile) {
    return FlutterAndroidLauncherPlatform.instance.requestQuietModeEnabled(enableQuietMode, profile);
  }

  void setMethodCallHandler(Future<dynamic> Function(FlutterAndroidLauncherMethodCall call)? handler) {
    FlutterAndroidLauncherPlatform.instance.setMethodCallHandler((MethodCall call) async {
      if (handler != null) {
        return await handler(FlutterAndroidLauncherMethodCall(call.method, call.arguments));
      }
      return null;
    });
  }
}

class FlutterAndroidLauncherMethodCall {
  final String method;
  final dynamic arguments;

  FlutterAndroidLauncherMethodCall(this.method, this.arguments);
}
