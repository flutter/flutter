// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/version.dart';
import '../doctor.dart';
import '../globals.dart';
import '../intellij/intellij.dart';
import 'android_studio.dart';

class AndroidStudioValidator extends DoctorValidator {
  AndroidStudioValidator(this._studio) : super('Android Studio');

  final AndroidStudio _studio;

  static List<DoctorValidator> get allValidators {
    final List<DoctorValidator> validators = <DoctorValidator>[];
    final List<AndroidStudio> studios = AndroidStudio.allInstalled();
    if (studios.isEmpty) {
      validators.add(NoAndroidStudioValidator());
    } else {
      validators.addAll(studios
          .map<DoctorValidator>((AndroidStudio studio) => AndroidStudioValidator(studio)));
    }
    return validators;
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType type = ValidationType.missing;

    final String studioVersionText = _studio.version == Version.unknown
        ? null
        : 'version ${_studio.version}';
    messages
        .add(ValidationMessage('Android Studio at ${_studio.directory}'));

    final IntelliJPlugins plugins = IntelliJPlugins(_studio.pluginsPath);
    plugins.validatePackage(messages, <String>['flutter-intellij', 'flutter-intellij.jar'],
        'Flutter', minVersion: IntelliJPlugins.kMinFlutterPluginVersion);
    plugins.validatePackage(messages, <String>['Dart'], 'Dart');

    if (_studio.isValid) {
      type = ValidationType.installed;
      messages.addAll(_studio.validationMessages
          .map<ValidationMessage>((String m) => ValidationMessage(m)));
    } else {
      type = ValidationType.partial;
      messages.addAll(_studio.validationMessages
          .map<ValidationMessage>((String m) => ValidationMessage.error(m)));
      messages.add(ValidationMessage(
          'Try updating or re-installing Android Studio.'));
      if (_studio.configured != null) {
        messages.add(ValidationMessage(
            'Consider removing your android-studio-dir setting by running:\nflutter config --android-studio-dir='));
      }
    }

    return ValidationResult(type, messages, statusInfo: studioVersionText);
  }
}

class NoAndroidStudioValidator extends DoctorValidator {
  NoAndroidStudioValidator() : super('Android Studio');

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    final String cfgAndroidStudio = config.getValue('android-studio-dir');
    if (cfgAndroidStudio != null) {
      messages.add(
          ValidationMessage.error('android-studio-dir = $cfgAndroidStudio\n'
              'but Android Studio not found at this location.'));
    }
    messages.add(ValidationMessage(
        'Android Studio not found; download from https://developer.android.com/studio/index.html\n'
        '(or visit https://flutter.io/setup/#android-setup for detailed instructions).'));

    return ValidationResult(ValidationType.notAvailable, messages,
        statusInfo: 'not installed');
  }
}
