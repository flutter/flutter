// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Annotate as 'internal' so developers don't accidentally import this.
@internal
library universal_io.choose.browser;

import 'dart:html' as html;

import 'package:meta/meta.dart';

import 'browser/http_client.dart';
import 'io_impl_js.dart';

String get locale {
  final languages = html.window.navigator.languages;
  if (languages != null && languages.isNotEmpty) {
    return languages.first;
  }
  return 'en-US';
}

String get operatingSystem {
  final s = html.window.navigator.userAgent.toLowerCase();
  if (s.contains('iphone') ||
      s.contains('ipad') ||
      s.contains('ipod') ||
      s.contains('watch os')) {
    return 'ios';
  }
  if (s.contains('mac os')) {
    return 'macos';
  }
  if (s.contains('fuchsia')) {
    return 'fuchsia';
  }
  if (s.contains('android')) {
    return 'android';
  }
  if (s.contains('linux') || s.contains('cros') || s.contains('chromebook')) {
    return 'linux';
  }
  if (s.contains('windows')) {
    return 'windows';
  }
  return '';
}

String get operatingSystemVersion {
  final userAgent = html.window.navigator.userAgent;

  // Android?
  {
    final regExp = RegExp('Android ([a-zA-Z0-9.-_]+)');
    final match = regExp.firstMatch(userAgent);
    if (match != null) {
      final version = match.group(1) ?? '';
      return version;
    }
  }

  // iPhone OS?
  {
    final regExp = RegExp('iPhone OS ([a-zA-Z0-9.-_]+) ([a-zA-Z0-9.-_]+)');
    final match = regExp.firstMatch(userAgent);
    if (match != null) {
      final version = (match.group(2) ?? '').replaceAll('_', '.');
      return version;
    }
  }

  // Mac OS X?
  {
    final regExp = RegExp('Mac OS X ([a-zA-Z0-9.-_]+)');
    final match = regExp.firstMatch(userAgent);
    if (match != null) {
      final version = (match.group(1) ?? '').replaceAll('_', '.');
      return version;
    }
  }

  // Chrome OS?
  {
    final regExp = RegExp('CrOS ([a-zA-Z0-9.-_]+) ([a-zA-Z0-9.-_]+)');
    final match = regExp.firstMatch(userAgent);
    if (match != null) {
      final version = match.group(2) ?? '';
      return version;
    }
  }

  // Windows NT?
  {
    final regExp = RegExp('Windows NT ([a-zA-Z0-9.-_]+)');
    final match = regExp.firstMatch(userAgent);
    if (match != null) {
      final version = (match.group(1) ?? '');
      return version;
    }
  }

  return '';
}

HttpClient newHttpClient() {
  return BrowserHttpClient();
}
