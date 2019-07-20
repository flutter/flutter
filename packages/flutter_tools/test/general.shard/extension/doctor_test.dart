// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/extension/doctor.dart';

import '../src/common.dart';

void main() {
  test('serialization of ValidationType', () {
    expect(ValidationType.missing.toJson(), 0);
    expect(ValidationType.partial.toJson(), 1);
    expect(ValidationType.notAvailable.toJson(), 2);
    expect(ValidationType.installed.toJson(), 3);

    expect(ValidationType.fromJson(0), ValidationType.missing);
    expect(ValidationType.fromJson(1), ValidationType.partial);
    expect(ValidationType.fromJson(2), ValidationType.notAvailable);
    expect(ValidationType.fromJson(3), ValidationType.installed);
    expect(() => ValidationType.fromJson(9), throwsA(isA<ArgumentError>()));
  });

  test('serialization of ValidationMessageType', () {
    expect(ValidationMessageType.error.toJson(), 0);
    expect(ValidationMessageType.hint.toJson(), 1);
    expect(ValidationMessageType.information.toJson(), 2);

    expect(ValidationMessageType.fromJson(0), ValidationMessageType.error);
    expect(ValidationMessageType.fromJson(1), ValidationMessageType.hint);
    expect(ValidationMessageType.fromJson(2), ValidationMessageType.information);
    expect(() => ValidationMessageType.fromJson(9), throwsA(isA<ArgumentError>()));
  });

  test('serialization of ValidationMessage', () {
    const ValidationMessage messageOne = ValidationMessage('test1');
    const ValidationMessage messageTwo = ValidationMessage('test2', type: ValidationMessageType.error);
    const ValidationMessage messageThree = ValidationMessage('test3', type: ValidationMessageType.hint);

    expect(messageOne.toJson(), <String, Object>{
      'message': 'test1',
      'type': ValidationMessageType.information.toJson(),
    });
    expect(messageTwo.toJson(), <String, Object>{
      'message': 'test2',
      'type': ValidationMessageType.error.toJson(),
    });
    expect(messageThree.toJson(), <String, Object>{
      'message': 'test3',
      'type': ValidationMessageType.hint.toJson(),
    });

    expect(ValidationMessage.fromJson(<String, Object>{
      'message': 'test1',
      'type': 0
    }), const ValidationMessage('test1', type: ValidationMessageType.error));
  });

  test('serialization of ValidationResponse', () {
    const ValidationResult validationResponse = ValidationResult(
      messages: <ValidationMessage>[
        ValidationMessage('hello')
      ],
      type: ValidationType.installed,
      name: 'tester'
    );

    expect(validationResponse.toJson(), <String, Object>{
      'messages': <Object>[
        <String, Object>{'message': 'hello', 'type': 2},
      ],
      'type': 3,
      'name': 'tester',
      'statusText': null
    });

    final ValidationResult repsonse = ValidationResult.fromJson(<String, Object>{
      'messages': <Object>[
        <String, Object>{'message': 'goodbye', 'type': 0},
      ],
      'type': 0,
      'name': 'foobar',
      'statusText': null,
    });
    expect(repsonse.type, ValidationType.missing);
    expect(repsonse.messages.single, const ValidationMessage('goodbye', type: ValidationMessageType.error));
    expect(repsonse.name, 'foobar');
  });
}
