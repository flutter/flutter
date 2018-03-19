// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:quiver/time.dart';

import '../globals.dart';
import 'context.dart';
import 'file_system.dart';
import 'platform.dart';

const BotDetector _kBotDetector = const BotDetector();

class BotDetector {
  const BotDetector();

  bool get isRunningOnBot {
    return
      platform.environment['BOT'] == 'true' ||

          // https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables
          platform.environment['TRAVIS'] == 'true' ||
          platform.environment['CONTINUOUS_INTEGRATION'] == 'true' ||
          platform.environment.containsKey('CI') || // Travis and AppVeyor

          // https://www.appveyor.com/docs/environment-variables/
          platform.environment.containsKey('APPVEYOR') ||

          // https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-env-vars.html
          (platform.environment.containsKey('AWS_REGION') && platform.environment.containsKey('CODEBUILD_INITIATOR')) ||

          // https://wiki.jenkins.io/display/JENKINS/Building+a+software+project#Buildingasoftwareproject-belowJenkinsSetEnvironmentVariables
          platform.environment.containsKey('JENKINS_URL') ||

          // Properties on Flutter's Chrome Infra bots.
          platform.environment['CHROME_HEADLESS'] == '1' ||
          platform.environment.containsKey('BUILDBOT_BUILDERNAME');
  }
}

bool get isRunningOnBot {
  final BotDetector botDetector = context?.getVariable(BotDetector) ?? _kBotDetector;
  return botDetector.isRunningOnBot;
}

String hex(List<int> bytes) {
  final StringBuffer result = new StringBuffer();
  for (int part in bytes)
    result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  return result.toString();
}

String calculateSha(File file) {
  return hex(sha1.convert(file.readAsBytesSync()).bytes);
}

/// Convert `foo_bar` to `fooBar`.
String camelCase(String str) {
  int index = str.indexOf('_');
  while (index != -1 && index < str.length - 2) {
    str = str.substring(0, index) +
      str.substring(index + 1, index + 2).toUpperCase() +
      str.substring(index + 2);
    index = str.indexOf('_');
  }
  return str;
}

String toTitleCase(String str) {
  if (str.isEmpty)
    return str;
  return str.substring(0, 1).toUpperCase() + str.substring(1);
}

/// Return the plural of the given word (`cat(s)`).
String pluralize(String word, int count) => count == 1 ? word : word + 's';

/// Return the name of an enum item.
String getEnumName(dynamic enumItem) {
  final String name = '$enumItem';
  final int index = name.indexOf('.');
  return index == -1 ? name : name.substring(index + 1);
}

File getUniqueFile(Directory dir, String baseName, String ext) {
  final FileSystem fs = dir.fileSystem;
  int i = 1;

  while (true) {
    final String name = '${baseName}_${i.toString().padLeft(2, '0')}.$ext';
    final File file = fs.file(fs.path.join(dir.path, name));
    if (!file.existsSync())
      return file;
    i++;
  }
}

String toPrettyJson(Object jsonable) {
  return const JsonEncoder.withIndent('  ').convert(jsonable) + '\n';
}

/// Return a String - with units - for the size in MB of the given number of bytes.
String getSizeAsMB(int bytesLength) {
  return '${(bytesLength / (1024 * 1024)).toStringAsFixed(1)}MB';
}

final NumberFormat kSecondsFormat = new NumberFormat('0.0');
final NumberFormat kMillisecondsFormat = new NumberFormat.decimalPattern();

String getElapsedAsSeconds(Duration duration) {
  final double seconds = duration.inMilliseconds / Duration.millisecondsPerSecond;
  return '${kSecondsFormat.format(seconds)}s';
}

String getElapsedAsMilliseconds(Duration duration) {
  return '${kMillisecondsFormat.format(duration.inMilliseconds)}ms';
}

/// Return a relative path if [fullPath] is contained by the cwd, else return an
/// absolute path.
String getDisplayPath(String fullPath) {
  final String cwd = fs.currentDirectory.path + fs.path.separator;
  return fullPath.startsWith(cwd) ? fullPath.substring(cwd.length) : fullPath;
}

/// A class to maintain a list of items, fire events when items are added or
/// removed, and calculate a diff of changes when a new list of items is
/// available.
class ItemListNotifier<T> {
  ItemListNotifier() {
    _items = new Set<T>();
  }

  ItemListNotifier.from(List<T> items) {
    _items = new Set<T>.from(items);
  }

  Set<T> _items;

  final StreamController<T> _addedController = new StreamController<T>.broadcast();
  final StreamController<T> _removedController = new StreamController<T>.broadcast();

  Stream<T> get onAdded => _addedController.stream;
  Stream<T> get onRemoved => _removedController.stream;

  List<T> get items => _items.toList();

  void updateWithNewList(List<T> updatedList) {
    final Set<T> updatedSet = new Set<T>.from(updatedList);

    final Set<T> addedItems = updatedSet.difference(_items);
    final Set<T> removedItems = _items.difference(updatedSet);

    _items = updatedSet;

    addedItems.forEach(_addedController.add);
    removedItems.forEach(_removedController.add);
  }

  /// Close the streams.
  void dispose() {
    _addedController.close();
    _removedController.close();
  }
}

class SettingsFile {
  SettingsFile();

  SettingsFile.parse(String contents) {
    for (String line in contents.split('\n')) {
      line = line.trim();
      if (line.startsWith('#') || line.isEmpty)
        continue;
      final int index = line.indexOf('=');
      if (index != -1)
        values[line.substring(0, index)] = line.substring(index + 1);
    }
  }

  factory SettingsFile.parseFromFile(File file) {
    return new SettingsFile.parse(file.readAsStringSync());
  }

  final Map<String, String> values = <String, String>{};

  void writeContents(File file) {
    file.writeAsStringSync(values.keys.map((String key) {
      return '$key=${values[key]}';
    }).join('\n'));
  }
}

/// A UUID generator. This will generate unique IDs in the format:
///
///     f47ac10b-58cc-4372-a567-0e02b2c3d479
///
/// The generated UUIDs are 128 bit numbers encoded in a specific string format.
///
/// For more information, see
/// http://en.wikipedia.org/wiki/Universally_unique_identifier.
class Uuid {
  final Random _random = new Random();

  /// Generate a version 4 (random) UUID. This is a UUID scheme that only uses
  /// random numbers as the source of the generated UUID.
  String generateV4() {
    // Generate xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx / 8-4-4-4-12.
    final int special = 8 + _random.nextInt(4);

    return
      '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}-'
          '${_bitsDigits(16, 4)}-'
          '4${_bitsDigits(12, 3)}-'
          '${_printDigits(special, 1)}${_bitsDigits(12, 3)}-'
          '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}';
  }

  String _bitsDigits(int bitCount, int digitCount) =>
      _printDigits(_generateBits(bitCount), digitCount);

  int _generateBits(int bitCount) => _random.nextInt(1 << bitCount);

  String _printDigits(int value, int count) =>
      value.toRadixString(16).padLeft(count, '0');
}

Clock get clock => context.putIfAbsent(Clock, () => const Clock());

typedef Future<Null> AsyncCallback();

/// A [Timer] inspired class that:
///   - has a different initial value for the first callback delay
///   - waits for a callback to be complete before it starts the next timer
class Poller {
  Poller(this.callback, this.pollingInterval, { this.initialDelay: Duration.zero }) {
    new Future<Null>.delayed(initialDelay, _handleCallback);
  }

  final AsyncCallback callback;
  final Duration initialDelay;
  final Duration pollingInterval;

  bool _cancelled = false;
  Timer _timer;

  Future<Null> _handleCallback() async {
    if (_cancelled)
      return;

    try {
      await callback();
    } catch (error) {
      printTrace('Error from poller: $error');
    }

    if (!_cancelled)
      _timer = new Timer(pollingInterval, _handleCallback);
  }

  /// Cancels the poller.
  void cancel() {
    _cancelled = true;
    _timer?.cancel();
    _timer = null;
  }
}

/// Returns a [Future] that completes when all given [Future]s complete.
///
/// Uses [Future.wait] but removes null elements from the provided
/// `futures` iterable first.
///
/// The returned [Future<List>] will be shorter than the given `futures` if
/// it contains nulls.
Future<List<T>> waitGroup<T>(Iterable<Future<T>> futures) {
  return Future.wait<T>(futures.where((Future<T> future) => future != null));
}
