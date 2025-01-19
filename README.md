# flutter_android_launcher

`flutter_android_launcher` is a Flutter plugin that helps developers create custom launchers for Android using Flutter. This plugin provides various functionalities to interact with installed apps, manage user profiles, and handle quiet mode settings. (ie.  Android 15 private space.) This plugin is developed for a currently in-progress launcher.

## Features

- Retrieve a list of installed apps.
- Launch an app with a specified profile.
- Get user profile information.
- Check if quiet mode is enabled for a profile.
- Request to enable or disable quiet mode for a profile.

Most of the relevant Android APIs are in [LauncherApps](https://developer.android.com/reference/android/content/pm/LauncherApps) such as [getApplicationInfo](https://developer.android.com/reference/android/content/pm/LauncherApps#getApplicationInfo(java.lang.String,%20int,%20android.os.UserHandle)), [getActivityList](https://developer.android.com/reference/android/content/pm/LauncherApps#getActivityList(java.lang.String,%20android.os.UserHandle)) and [startMainActivity](https://developer.android.com/reference/android/content/pm/LauncherApps#startMainActivity(android.content.ComponentName,%20android.os.UserHandle,%20android.graphics.Rect,%20android.os.Bundle)) as well as [UserManager](https://developer.android.com/reference/android/os/UserManager) via [getUserProfiles](https://developer.android.com/reference/android/os/UserManager#getUserProfiles()) and [requestQuietModeEnabled](https://developer.android.com/reference/android/os/UserManager#requestQuietModeEnabled(boolean,%20android.os.UserHandle,%20int)). These APIs are wrapped by this plugin. All the relevant APIs, and how they are used, can be seen in [FlutterAndroidLauncherPlugin.kt](https://github.com/AbyssalSpaceLauncher/flutter_android_launcher/blob/main/android/src/main/kotlin/com/example/flutter_android_launcher/FlutterAndroidLauncherPlugin.kt)

## Getting Started

To use this plugin, add `flutter_android_launcher` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_android_launcher:
```

### Android Setup

Add the following permissions and configs to your `AndroidManifest.xml` file:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- ...Add this... -->
    <uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
    <uses-permission android:name="android.permission.ACCESS_HIDDEN_PROFILES" />
    <application>
        <activity>
            <intent-filter>
                <!-- add this -->
                <category android:name="android.intent.category.HOME"/>
                <category android:name="android.intent.category.DEFAULT"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

## Example

A full example is provided in the `example` directory. The example demonstrates how to use the plugin to interact with installed apps, manage user profiles, and handle quiet mode settings.

To run the example:

1. Navigate to the `example` directory.
2. Run `flutter pub get` to install dependencies.
3. Run `flutter run` to start the example app.

### Basic Usage

Here is a brief example of how to use the API to display a list of apps and a button to launch them:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_android_launcher/flutter_android_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Android Launcher',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, String>> _installedApps = [];
  final _flutterAndroidLauncherPlugin = FlutterAndroidLauncher();

  @override
  void initState() {
    super.initState();
    _getInstalledApps();
  }

  Future<void> _getInstalledApps() async {
    try {
      final installedApps = await _flutterAndroidLauncherPlugin.getInstalledApps();
      setState(() {
        _installedApps = installedApps;
      });
    } on PlatformException catch (e) {
      print("Failed to get installed apps: '${e.message}'.");
    }
  }

  Future<void> _launchApp(String packageName) async {
    try {
      await _flutterAndroidLauncherPlugin.launchApp(packageName, 'default');
    } on PlatformException catch (e) {
      print("Failed to launch app: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Apps'),
      ),
      body: _installedApps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _installedApps.length,
              itemBuilder: (context, index) {
                final app = _installedApps[index];
                return ListTile(
                  title: Text(app['appName']!),
                  subtitle: Text(app['packageName']!),
                  trailing: ElevatedButton(
                    onPressed: () => _launchApp(app['packageName']!),
                    child: const Text('Launch'),
                  ),
                );
              },
            ),
    );
  }
}
```

### Wallpaper

To make the system wallpaper viewable from your app, follow these steps:

1.  Add the following style to `android/app/src/main/res/values/styles.xml` and  =`android/app/src/main/res/values-night/styles.xml`:

```xml
<style name="Theme.Transparent" parent="android:Theme">
  <item name="android:windowBackground">@android:color/white</item>
  <item name="android:windowContentOverlay">@null</item>
  <item name="android:windowNoTitle">true</item>
  <item name="android:backgroundDimEnabled">false</item>
  <item name="android:windowShowWallpaper">true</item>
</style>
```

This style is used to display the system wallpaper as the activity background for both light and dark mode.

3. Update the theme of `MainActivity` in `android/app/src/main/AndroidManifest.xml` to use the `Theme.Transparent`:

```xml
<activity
    android:name=".MainActivity"
    android:theme="@style/Theme.Transparent">
    <!-- ...existing code... -->
</activity>
```

4. Remove the following meta-data from the same file:

```xml
<!-- Remove the following meta-data -->
<meta-data
    android:name="io.flutter.embedding.android.NormalTheme"
    android:resource="@style/NormalTheme"/>
```

5. Update `MainActivity.kt` as follows to set the background mode to transparent:

```kotlin
package com.example.flutter_android_launcher_example //keep your current package name

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode.transparent

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        intent.putExtra("background_mode", transparent.toString())
        super.onCreate(savedInstanceState)
    }
}
```

6. Set your Scaffold to transparent

```dart
Scaffold(
    backgroundColor: Colors.transparent,
    // ...existing code...
)
```

To remove the status and navigation bars, do the folowing:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}
```

### Detailed Example

Here is a more detailed example that includes retrieving user profiles and handling quiet mode settings. It is recommended to run the example app as well, which is similar to the below code, to see how it works.

```dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:uri_content/uri_content.dart';
import 'package:collection/collection.dart';
import 'package:flutter_android_launcher/flutter_android_launcher.dart';

void main() {
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
        'iconUri': ''
      }];
    }

    setState(() {
      _installedApps = installedApps;
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
      body: SafeArea(
        child: Center(
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
                          final iconUri = app['iconUri']!;
                          return ListTile(
                            leading: _iconCache.containsKey(iconUri)
                                ? Image.memory(_iconCache[iconUri]!)
                                : FutureBuilder<Uint8List>(
                                    future: UriContent().from(Uri.parse(iconUri)),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                        _iconCache[iconUri] = snapshot.data!;
                                        return Image.memory(snapshot.data!);
                                      } else {
                                        return const CircularProgressIndicator();
                                      }
                                    },
                                  ),
                            title: Text(app['appName']!),
                            subtitle: Text('Package: ${app['packageName']!}\nProfile: ${app['profile']!}'),
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
    );
  }
}
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
