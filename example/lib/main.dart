import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter_android_launcher/flutter_android_launcher.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, String>> _installedApps = [];
  List<Map<String, String>> _userProfiles = [];
  final Map<String, Uint8List> _iconCache = {};
  String _quietModeStatus = 'Enabled';
  String? _privateProfile;
  final _flutterAndroidLauncherPlugin = FlutterAndroidLauncher();

  Future<void> _getInstalledApps() async {
    List<Map<String, String>> installedApps;
    try {
      installedApps = await _flutterAndroidLauncherPlugin.getInstalledApps();
    } on PlatformException catch (e) {
      installedApps = [{
        'appName': 'Error',
        'packageName': "Failed to get installed apps: '${e.message}'.",
        'profile': 'N/A',
        'iconBase64': ''
      }];
    }

    setState(() {
      _installedApps = installedApps;
      for (var app in installedApps) {
        final iconBase64 = app['iconBase64']!;
        if (!_iconCache.containsKey(iconBase64)) {
          _iconCache[iconBase64] = base64Decode(iconBase64);
        }
      }
    });
  }

  Future<void> _launchApp(String packageName, String profile) async {
    try {
      await _flutterAndroidLauncherPlugin.launchApp(packageName, profile);
    } on PlatformException catch (e) {
      print("Failed to launch app: '${e.message}'.");
    }
  }

  Future<void> _getLauncherUserInfo() async {
    try {
      final userProfiles = await _flutterAndroidLauncherPlugin.getLauncherUserInfo();
      setState(() {
        _userProfiles = userProfiles;
        for (var profile in userProfiles) {
          print('UserProfile: ${profile['userProfile']}, UserType: ${profile['userType']}');
        }

        _privateProfile = userProfiles.firstWhereOrNull(
          (profile) => profile['userType'] == 'android.os.usertype.profile.PRIVATE'
        )?['userProfile'];
        print('Private profile: $_privateProfile');
      });
    } on PlatformException catch (e) {
      setState(() {
        _userProfiles = [{
          'userProfile': 'Error',
          'userType': "Failed to get user info: '${e.message}'"
        }];
      });
    }
  }

  Future<void> _checkQuietMode(String profile) async {
    try {
      final result = await _flutterAndroidLauncherPlugin.isQuietModeEnabled(profile);
      setState(() {
        _quietModeStatus = result ? 'Enabled' : 'Disabled';
      });
    } on PlatformException catch (e) {
      setState(() {
        _quietModeStatus = "Failed to check quiet mode: '${e.message}'";
      });
    }
  }

  Future<void> _toggleQuietMode(String profile) async {
    try {
      final enableQuietMode = _quietModeStatus == 'Disabled';
      await _flutterAndroidLauncherPlugin.requestQuietModeEnabled(enableQuietMode, profile);
    } on PlatformException catch (e) {
      setState(() {
        _quietModeStatus = "Failed to toggle quiet mode: '${e.message}'";
      });
    }
  }

  @override
  void initState() {
    _getInstalledApps();
    _getLauncherUserInfo().then((_) {
      if (_privateProfile != null) {
        _checkQuietMode(_privateProfile!);
      }
    });
    _flutterAndroidLauncherPlugin.setMethodCallHandler((FlutterAndroidLauncherMethodCall call) async {
      if (call.method == "updateQuietModeStatus") {
        final isQuietModeEnabled = call.arguments as bool;
        setState(() {
          _quietModeStatus = isQuietModeEnabled ? 'Enabled' : 'Disabled';
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: DefaultTextStyle(
            style: TextStyle(color: Colors.white),
            child: Column(
              children: [
                if (_privateProfile != null) Text('Quiet Mode: $_quietModeStatus'),
                _userProfiles.isEmpty
                    ? const CircularProgressIndicator()
                    : Column(
                        children: _userProfiles.map((profile) {
                          return Text('Profile: ${profile['userProfile']}, Type: ${profile['userType']}');
                        }).toList(),
                      ),
                Expanded(
                  child: _installedApps.isEmpty
                      ? const SizedBox()
                      : ListView.builder(
                          itemCount: _installedApps.length,
                          itemBuilder: (context, index) {
                            final app = _installedApps[index];
                            final iconBase64 = app['iconBase64']!;
                            return ListTile(
                              leading: _iconCache.containsKey(iconBase64)
                                  ? Image.memory(_iconCache[iconBase64]!)
                                  : Image.memory(base64Decode(iconBase64)),
                                title: Text(
                                app['appName']!,
                                style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                'Package: ${app['packageName']!}\nProfile: ${app['profile']!}',
                                style: TextStyle(color: Colors.white),
                                ),
                              onTap: () => _launchApp(app['packageName']!, app['profile']!),
                              trailing: ElevatedButton(
                                onPressed: () => _launchApp(app['packageName']!, app['profile']!),
                                child: const Text('Launch'),
                              ),
                            );
                          },
                        ),
                ),
                if (_privateProfile != null)
                  ElevatedButton(
                    onPressed: () => _toggleQuietMode(_privateProfile!),
                    child: Text(_quietModeStatus == 'Enabled' ? 'Disable Quiet Mode' : 'Enable Quiet Mode'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
