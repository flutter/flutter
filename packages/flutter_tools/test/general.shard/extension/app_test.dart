// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/extension/app.dart';

import '../../src/common.dart';

void main() {
  test('Serialization of ApplicationBundle', () {
    const ApplicationBundle applicationBundle = ApplicationBundle(
      executable: 'hello',
      context: <String, Object>{
        'hi': 2
      }
    );

    expect(applicationBundle.toJson(), <String, Object>{
      'executable': 'hello',
      'context': <String, Object>{
        'hi': 2
      }
    });
  });

  test('Serialization of ApplicationBundle with default context', () {
    const ApplicationBundle applicationBundle = ApplicationBundle(
      executable: 'hello',
    );

    expect(applicationBundle.toJson(), <String, Object>{
      'executable': 'hello',
      'context': const <String, Object>{},
    });
  });

  test('Serialization of ApplicationBundle requires executable', () {
    expect(() => ApplicationBundle(executable: null), throwsA(isInstanceOf<AssertionError>()));
  });

  test('Serialization of ApplicationInstance', () {
    final ApplicationInstance applicationInstance = ApplicationInstance(
      vmserviceUri: Uri.parse('foo/bar'),
      context: <String, Object>{
        'hello': 2,
      },
    );

    expect(applicationInstance.toJson(), <String, Object>{
      'vmserviceUri': Uri.parse('foo/bar'),
      'context': <String, Object>{
        'hello': 2,
      }
    });
  });

  test('Serialization of ApplicationInstance with default context', () {
    final ApplicationInstance applicationInstance = ApplicationInstance(
      vmserviceUri: Uri.parse('foo/bar'),
    );

    expect(applicationInstance.toJson(), <String, Object>{
      'vmserviceUri': Uri.parse('foo/bar'),
      'context': const <String, Object>{}
    });
  });

  test('Serialization of ApplicationInstance without vmservice uri', () {
    const ApplicationInstance applicationInstance = ApplicationInstance();

    expect(applicationInstance.toJson(), <String, Object>{
      'vmserviceUri': null,
      'context': const <String, Object>{}
    });
  });
}