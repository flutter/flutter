// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../base/version.dart';
import '../doctor.dart';
import '../globals.dart';
import 'android_studio.dart';

class AndroidStudioValidator extends DoctorValidator {
  final AndroidStudio _studio;

  AndroidStudioValidator(this._studio) : super('Android Studio');

  static List<DoctorValidator> get allValidators {
    List<DoctorValidator> validators = <DoctorValidator>[];
    List<AndroidStudio> studios = AndroidStudio.allInstalled();
    if (studios.isEmpty) {
      validators.add(new NoAndroidStudioValidator());
    } else {
      validators.addAll(studios
          .map((AndroidStudio studio) => new AndroidStudioValidator(studio)));
    }
    String cfgGradleDir = config.getValue('gradle-dir');
    if (cfgGradleDir != null) {
      validators.add(new ConfiguredGradleValidator(cfgGradleDir));
    }
    return validators;
  }

  @override
  Future<ValidationResult> validate() async {
    List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType type = ValidationType.missing;
    String studioVersionText = 'version ${_studio.version}';
    messages
        .add(new ValidationMessage('Android Studio at ${_studio.directory}'));
    if (_studio.isValid) {
      type = ValidationType.installed;
      messages.addAll(_studio.validationMessages
          .map((String m) => new ValidationMessage(m)));
    } else {
      type = ValidationType.partial;
      messages.addAll(_studio.validationMessages
          .map((String m) => new ValidationMessage.error(m)));
      messages.add(new ValidationMessage(
          'Try updating or re-installing Android Studio.'));
      if (_studio.configured != null) {
        messages.add(new ValidationMessage(
            'Consider removing the android-studio-dir setting.'));
      }
    }

    return new ValidationResult(type, messages, statusInfo: studioVersionText);
  }
}

class NoAndroidStudioValidator extends DoctorValidator {
  NoAndroidStudioValidator() : super('Android Studio');

  @override
  Future<ValidationResult> validate() async {
    List<ValidationMessage> messages = <ValidationMessage>[];

    String cfgAndroidStudio = config.getValue('android-studio-dir');
    if (cfgAndroidStudio != null) {
      messages.add(
          new ValidationMessage.error('android-studio-dir = $cfgAndroidStudio\n'
              'but Android Studio not found at this location.'));
    }
    messages.add(new ValidationMessage(
        'Android Studio not found. Download from https://developer.android.com/studio/index.html\n'
        '(or visit https://flutter.io/setup/#android-setup for detailed instructions).'));

    return new ValidationResult(ValidationType.missing, messages,
        statusInfo: 'not installed');
  }
}

class ConfiguredGradleValidator extends DoctorValidator {
  final String cfgGradleDir;

  ConfiguredGradleValidator(this.cfgGradleDir) : super('Gradle');

  @override
  Future<ValidationResult> validate() async {
    ValidationType type = ValidationType.missing;
    List<ValidationMessage> messages = <ValidationMessage>[];

    messages.add(new ValidationMessage('gradle-dir = $cfgGradleDir'));

    String gradleExecutable = cfgGradleDir;
    if (!fs.isFileSync(cfgGradleDir)) {
      gradleExecutable = fs.path.join(
          cfgGradleDir, 'bin', platform.isWindows ? 'gradle.bat' : 'gradle');
    }
    String versionString;
    if (processManager.canRun(gradleExecutable)) {
      type = ValidationType.partial;
      ProcessResult result =
          processManager.runSync(<String>[gradleExecutable, '--version']);
      if (result.exitCode == 0) {
        versionString = result.stdout
            .toString()
            .split('\n')
            .firstWhere((String s) => s.startsWith('Gradle '))
            .substring('Gradle '.length);
        Version version = new Version.parse(versionString) ?? Version.unknown;
        if (version >= minGradleVersion) {
          type = ValidationType.installed;
        } else {
          messages.add(new ValidationMessage.error(
              'Gradle version $minGradleVersion required. Found version $versionString.'));
        }
      } else {
        messages
            .add(new ValidationMessage('Unable to determine Gradle version.'));
      }
    } else {
      messages
          .add(new ValidationMessage('Gradle not found at $gradleExecutable'));
    }

    messages.add(new ValidationMessage(
        'Consider removing the gradle-dir setting to use Gradle from Android Studio.'));
    return new ValidationResult(type, messages, statusInfo: versionString);
  }
}
