import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/services.dart';

import 'flutter_android_launcher_method_channel.dart';

abstract class FlutterAndroidLauncherPlatform extends PlatformInterface {
  /// Constructs a FlutterAndroidLauncherPlatform.
  FlutterAndroidLauncherPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAndroidLauncherPlatform _instance = MethodChannelFlutterAndroidLauncher();

  /// The default instance of [FlutterAndroidLauncherPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAndroidLauncher].
  static FlutterAndroidLauncherPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAndroidLauncherPlatform] when
  /// they register themselves.
  static set instance(FlutterAndroidLauncherPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List<Map<String, String>>> getInstalledApps() {
    throw UnimplementedError('getInstalledApps() has not been implemented.');
  }

  Future<void> launchApp(String packageName, String profile) {
    throw UnimplementedError('launchApp() has not been implemented.');
  }

  Future<List<Map<String, String>>> getLauncherUserInfo() {
    throw UnimplementedError('getLauncherUserInfo() has not been implemented.');
  }

  Future<bool> isQuietModeEnabled(String profile) {
    throw UnimplementedError('isQuietModeEnabled() has not been implemented.');
  }

  Future<bool> requestQuietModeEnabled(bool enableQuietMode, String profile) {
    throw UnimplementedError('requestQuietModeEnabled() has not been implemented.');
  }

  void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    throw UnimplementedError('setMethodCallHandler() has not been implemented.');
  }
}
