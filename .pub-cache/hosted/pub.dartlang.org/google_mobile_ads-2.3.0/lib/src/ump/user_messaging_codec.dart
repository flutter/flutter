// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/services.dart';

import 'consent_form_impl.dart';
import 'consent_request_parameters.dart';

/// Codec for coding and decoding types in the UMP SDK.
class UserMessagingCodec extends StandardMessageCodec {
  static const int _valueConsentRequestParameters = 129;
  static const int _valueConsentDebugSettings = 130;
  static const int _valueConsentForm = 131;

  @override
  void writeValue(WriteBuffer buffer, dynamic value) {
    if (value is ConsentRequestParameters) {
      buffer.putUint8(_valueConsentRequestParameters);
      writeValue(buffer, value.tagForUnderAgeOfConsent);
      writeValue(buffer, value.consentDebugSettings);
    } else if (value is ConsentDebugSettings) {
      buffer.putUint8(_valueConsentDebugSettings);
      writeValue(buffer, value.debugGeography?.index);
      writeValue(buffer, value.testIdentifiers);
    } else if (value is ConsentFormImpl) {
      buffer.putUint8(_valueConsentForm);
      writeValue(buffer, value.platformHash);
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  dynamic readValueOfType(dynamic type, ReadBuffer buffer) {
    switch (type) {
      case _valueConsentRequestParameters:
        bool? tfuac = readValueOfType(buffer.getUint8(), buffer);
        ConsentDebugSettings? debugSettings =
            readValueOfType(buffer.getUint8(), buffer);
        return ConsentRequestParameters(
            tagForUnderAgeOfConsent: tfuac,
            consentDebugSettings: debugSettings);
      case _valueConsentDebugSettings:
        int? debugGeographyInt = readValueOfType(buffer.getUint8(), buffer);
        DebugGeography? debugGeography;
        if (debugGeographyInt != null) {
          debugGeography = DebugGeography.values[debugGeographyInt];
        }
        List<String>? testIds =
            readValueOfType(buffer.getUint8(), buffer)?.cast<String>();
        return ConsentDebugSettings(
            debugGeography: debugGeography, testIdentifiers: testIds);
      case _valueConsentForm:
        final int hashCode = readValueOfType(buffer.getUint8(), buffer);
        return ConsentFormImpl(hashCode);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}
