import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'flutter_android_launcher_platform_interface.dart';

/// An implementation of [FlutterAndroidLauncherPlatform] that uses method channels.
class MethodChannelFlutterAndroidLauncher extends FlutterAndroidLauncherPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_android_launcher');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List<Map<String, String>>> getInstalledApps() async {
    final result = await methodChannel.invokeMethod<String>('getInstalledApps');
    final List<dynamic> jsonList = jsonDecode(result ?? '[]');
    return jsonList.map((e) => {
      'appName': e['appName'].toString(),
      'packageName': e['packageName'].toString(),
      'profile': e['profile'].toString(),
      'iconUri': e['iconUri'].toString()
    }).toList();
  }

  @override
  Future<void> launchApp(String packageName, String profile) async {
    await methodChannel.invokeMethod('launchApp', {'packageName': packageName, 'profile': profile});
  }

  @override
  Future<List<Map<String, String>>> getLauncherUserInfo() async {
    final result = await methodChannel.invokeMethod<String>('getLauncherUserInfo');
    final List<dynamic> jsonList = jsonDecode(result ?? '[]');
    return jsonList.map((e) => {
      'userProfile': e['userProfile'].toString(),
      'userType': e['userType'].toString()
    }).toList();
  }

  @override
  Future<bool> isQuietModeEnabled(String profile) async {
    final result = await methodChannel.invokeMethod<bool>('isQuietModeEnabled', {'profile': profile});
    return result == true;
  }

  @override
  Future<bool> requestQuietModeEnabled(bool enableQuietMode, String profile) async {
    final result = await methodChannel.invokeMethod<bool>('requestQuietModeEnabled', {
      'enableQuietMode': enableQuietMode,
      'profile': profile,
    });
    return result == true;
  }

  @override
  void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    methodChannel.setMethodCallHandler(handler);
  }
}
