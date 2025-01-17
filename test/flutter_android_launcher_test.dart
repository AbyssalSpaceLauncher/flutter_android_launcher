import 'package:flutter/src/services/message_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_android_launcher/flutter_android_launcher.dart';
import 'package:flutter_android_launcher/flutter_android_launcher_platform_interface.dart';
import 'package:flutter_android_launcher/flutter_android_launcher_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAndroidLauncherPlatform
    with MockPlatformInterfaceMixin
    implements FlutterAndroidLauncherPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<List<Map<String, String>>> getInstalledApps() {
    // TODO: implement getInstalledApps
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, String>>> getLauncherUserInfo() {
    // TODO: implement getLauncherUserInfo
    throw UnimplementedError();
  }

  @override
  Future<bool> isQuietModeEnabled(String profile) {
    // TODO: implement isQuietModeEnabled
    throw UnimplementedError();
  }

  @override
  Future<void> launchApp(String packageName, String profile) {
    // TODO: implement launchApp
    throw UnimplementedError();
  }

  @override
  Future<bool> requestQuietModeEnabled(bool enableQuietMode, String profile) {
    // TODO: implement requestQuietModeEnabled
    throw UnimplementedError();
  }

  @override
  void setMethodCallHandler(Future Function(MethodCall call)? handler) {
    // TODO: implement setMethodCallHandler
  }
}

void main() {
  final FlutterAndroidLauncherPlatform initialPlatform = FlutterAndroidLauncherPlatform.instance;

  test('$MethodChannelFlutterAndroidLauncher is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterAndroidLauncher>());
  });

  test('getPlatformVersion', () async {
    FlutterAndroidLauncher flutterAndroidLauncherPlugin = FlutterAndroidLauncher();
    MockFlutterAndroidLauncherPlatform fakePlatform = MockFlutterAndroidLauncherPlatform();
    FlutterAndroidLauncherPlatform.instance = fakePlatform;

    expect(await flutterAndroidLauncherPlugin.getPlatformVersion(), '42');
  });
}
