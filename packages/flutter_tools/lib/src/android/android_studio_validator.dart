// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/config.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../base/user_messages.dart';
import '../doctor_validator.dart';
import '../intellij/intellij.dart';
import 'android_studio.dart';

const String _androidStudioTitle = 'Android Studio';
const String _androidStudioId = 'AndroidStudio';
const String _androidStudioPreviewTitle = 'Android Studio Preview';
const String _androidStudioPreviewId = 'AndroidStudioPreview';

class AndroidStudioValidator extends DoctorValidator {
  AndroidStudioValidator(this._studio, { required final FileSystem fileSystem })
    : _fileSystem = fileSystem,
      super('Android Studio');

  final AndroidStudio _studio;
  final FileSystem _fileSystem;

  static const Map<String, String> idToTitle = <String, String>{
    _androidStudioId: _androidStudioTitle,
    _androidStudioPreviewId: _androidStudioPreviewTitle,
  };

  static List<DoctorValidator> allValidators(final Config config, final Platform platform, final FileSystem fileSystem, final UserMessages userMessages) {
    final List<AndroidStudio> studios = AndroidStudio.allInstalled();
    return <DoctorValidator>[
      if (studios.isEmpty)
        NoAndroidStudioValidator(config: config, platform: platform, userMessages: userMessages)
      else
        ...studios.map<DoctorValidator>(
          (final AndroidStudio studio) => AndroidStudioValidator(studio, fileSystem: fileSystem)
        ),
    ];
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType type = ValidationType.missing;

    final String? studioVersionText = _studio.version == null
      ? null
      : userMessages.androidStudioVersion(_studio.version.toString());
    messages.add(ValidationMessage(
      userMessages.androidStudioLocation(_studio.directory),
    ));

    if (_studio.pluginsPath != null) {
      final IntelliJPlugins plugins = IntelliJPlugins(_studio.pluginsPath!, fileSystem: _fileSystem);
      plugins.validatePackage(
        messages,
        <String>['flutter-intellij', 'flutter-intellij.jar'],
        'Flutter',
        IntelliJPlugins.kIntellijFlutterPluginUrl,
        minVersion: IntelliJPlugins.kMinFlutterPluginVersion,
      );
      plugins.validatePackage(
        messages,
        <String>['Dart'],
        'Dart',
        IntelliJPlugins.kIntellijDartPluginUrl,
      );
    }

    if (_studio.isValid) {
      type = _hasIssues(messages)
        ? ValidationType.partial
        : ValidationType.success;
      messages.addAll(_studio.validationMessages.map<ValidationMessage>(
        (final String m) => ValidationMessage(m),
      ));
    } else {
      type = ValidationType.partial;
      messages.addAll(_studio.validationMessages.map<ValidationMessage>(
        (final String m) => ValidationMessage.error(m),
      ));
      messages.add(ValidationMessage(userMessages.androidStudioNeedsUpdate));
      if (_studio.configuredPath != null) {
        messages.add(ValidationMessage(userMessages.androidStudioResetDir));
      }
    }

    return ValidationResult(type, messages, statusInfo: studioVersionText);
  }

  bool _hasIssues(final List<ValidationMessage> messages) {
    return messages.any((final ValidationMessage message) => message.isError);
  }
}

class NoAndroidStudioValidator extends DoctorValidator {
  NoAndroidStudioValidator({
    required final Config config,
    required final Platform platform,
    required final UserMessages userMessages,
  }) : _config = config,
       _platform = platform,
       _userMessages = userMessages,
       super('Android Studio');

  final Config _config;
  final Platform _platform;
  final UserMessages _userMessages;

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    final String? cfgAndroidStudio = _config.getValue(
      'android-studio-dir',
    ) as String?;
    if (cfgAndroidStudio != null) {
      messages.add(ValidationMessage.error(
        _userMessages.androidStudioMissing(cfgAndroidStudio),
      ));
    }
    messages.add(ValidationMessage(_userMessages.androidStudioInstallation(_platform)));

    return ValidationResult(
      ValidationType.notAvailable,
      messages,
      statusInfo: 'not installed',
    );
  }
}
