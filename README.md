# flutter_android_launcher

`flutter_android_launcher` is a Flutter plugin that helps users create custom launchers for Android using Flutter. This plugin provides various functionalities to interact with installed apps, manage user profiles, and handle quiet mode settings. (ie.  Android 15 private space.)

## Features

- Retrieve a list of installed apps.
- Launch an app with a specified profile.
- Get user profile information.
- Check if quiet mode is enabled for a profile.
- Request to enable or disable quiet mode for a profile.

## Getting Started

To use this plugin, add `flutter_android_launcher` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_android_launcher:
    path: ../
```

## Example

A full example is provided in the `example` directory. The example demonstrates how to use the plugin to interact with installed apps, manage user profiles, and handle quiet mode settings.

To run the example:

1. Navigate to the `example` directory.
2. Run `flutter pub get` to install dependencies.
3. Run `flutter run` to start the example app.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
