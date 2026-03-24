// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../browser_detection.dart';

/// Provides mappings from Flutter's autofill hints to the web platform's
/// autocomplete attribute values.
///
/// Different browsers may require different values for optimal autofill
/// behavior, particularly Safari for credit card fields.
class AutofillHintMapper {
  /// Returns the appropriate autofill hint value for the current browser.
  ///
  /// Safari requires specific autocomplete values for credit card fields
  /// to work properly with its autofill functionality.
  static String getAutofillHint(String flutterAutofillHint) {
    // Check if we have a Safari-specific mapping
    if (browserEngine == BrowserEngine.webkit) {
      final String? safariHint = _kSafariAutofillHints[flutterAutofillHint];
      if (safariHint != null) {
        return safariHint;
      }
    }
    
    // Fall back to standard web autofill hints
    return _kFlutterToWebAutofillHint[flutterAutofillHint] ?? flutterAutofillHint;
  }
}

/// Safari-specific autofill hint mappings.
///
/// Safari uses different autocomplete values for certain fields,
/// particularly credit card fields. These mappings ensure proper
/// autofill behavior on Safari/WebKit browsers.
const Map<String, String> _kSafariAutofillHints = <String, String>{
  // Credit card fields - Safari uses specific naming conventions
  'creditCardNumber': 'cc-number',
  'creditCardSecurityCode': 'cc-csc',
  'creditCardExpirationDate': 'cc-exp',
  'creditCardExpirationMonth': 'cc-exp-month',
  'creditCardExpirationYear': 'cc-exp-year',
  'creditCardName': 'cc-name',
  'creditCardGivenName': 'cc-given-name',
  'creditCardMiddleName': 'cc-additional-name',
  'creditCardFamilyName': 'cc-family-name',
  'creditCardType': 'cc-type',
};

/// The full mapping from Flutter's autofill hint strings to web
/// platform autocomplete attribute values.
///
/// See also:
///
///  * https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#autofilling-form-controls:-the-autocomplete-attribute
///  * https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete
const Map<String, String> _kFlutterToWebAutofillHint = <String, String>{
  // Address fields
  'addressCity': 'address-level2',
  'addressCityAndState': 'address-level1 address-level2',
  'addressState': 'address-level1',
  'countryCode': 'country',
  'countryName': 'country-name',
  'fullStreetAddress': 'street-address',
  'postalCode': 'postal-code',
  'streetAddressLevel1': 'address-line1',
  'streetAddressLevel2': 'address-line2',
  'streetAddressLevel3': 'address-line3',
  'streetAddressLevel4': 'address-line4',
  'sublocality': 'address-level3',

  // Credit card fields
  'creditCardExpirationDate': 'cc-exp',
  'creditCardExpirationMonth': 'cc-exp-month',
  'creditCardExpirationYear': 'cc-exp-year',
  'creditCardFamilyName': 'cc-family-name',
  'creditCardGivenName': 'cc-given-name',
  'creditCardMiddleName': 'cc-additional-name',
  'creditCardName': 'cc-name',
  'creditCardNumber': 'cc-number',
  'creditCardSecurityCode': 'cc-csc',
  'creditCardType': 'cc-type',

  // Email
  'email': 'email',

  // Name fields
  'familyName': 'family-name',
  'fullName': 'name',
  'givenName': 'given-name',
  'middleInitial': 'additional-name-initial',
  'middleName': 'additional-name',
  'name': 'name',
  'namePrefix': 'honorific-prefix',
  'nameSuffix': 'honorific-suffix',
  'newPassword': 'new-password',
  'newUsername': 'new-username',
  'nickname': 'nickname',
  'oneTimeCode': 'one-time-code',
  'organizationName': 'organization',
  'password': 'current-password',

  // Phone fields
  'telephoneNumber': 'tel',
  'telephoneNumberAreaCode': 'tel-area-code',
  'telephoneNumberCountryCode': 'tel-country-code',
  'telephoneNumberDevice': 'tel',
  'telephoneNumberExtension': 'tel-extension',
  'telephoneNumberLocal': 'tel-local',
  'telephoneNumberLocalPrefix': 'tel-local-prefix',
  'telephoneNumberLocalSuffix': 'tel-local-suffix',
  'telephoneNumberNational': 'tel-national',

  // Transaction fields
  'transactionAmount': 'transaction-amount',
  'transactionCurrency': 'transaction-currency',

  // URL and username
  'url': 'url',
  'username': 'username',

  // Birthday fields
  'birthday': 'bday',
  'birthdayDay': 'bday-day',
  'birthdayMonth': 'bday-month',
  'birthdayYear': 'bday-year',

  // Gender
  'gender': 'sex',

  // Photo and IMPP
  'photo': 'photo',
  'impp': 'impp',

  // Job title
  'jobTitle': 'organization-title',

  // Language
  'language': 'language',
};

/// Converts a Flutter autofill hint to the appropriate web autocomplete value.
///
/// This function handles browser-specific differences in autocomplete values.
String mapFlutterAutofillHintToWeb(String flutterHint) {
  return AutofillHintMapper.getAutofillHint(flutterHint);
}
