// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;
import 'dart:io';

/// Sanity checking of the @foo metadata in the English translations,
/// material_en.arb.
///
/// - For each @foo resource, there must be a corresponding foo, except
///   for plurals, for which there must be a fooOther.
/// - Each @foo resource must have a Map value with a String valued
///   description entry.
///
/// Returns an error message upon failure, null on success.
String validateEnglishLocalizations(File file) {
  final StringBuffer errorMessages = new StringBuffer();

  if (!file.existsSync()) {
    errorMessages.writeln('English localizations do not exist: $file');
    return errorMessages.toString();
  }

  final Map<String, dynamic> bundle = json.decode(file.readAsStringSync());
  for (String atResourceId in bundle.keys) {
    if (!atResourceId.startsWith('@'))
      continue;

    final dynamic atResourceValue = bundle[atResourceId];
    final Map<String, String> atResource = atResourceValue is Map ? atResourceValue : null;
    if (atResource == null) {
      errorMessages.writeln('A map value was not specified for $atResourceId');
      continue;
    }

    final String description = atResource['description'];
    if (description == null)
      errorMessages.writeln('No description specified for $atResourceId');

    final String plural = atResource['plural'];
    final String resourceId = atResourceId.substring(1);
    if (plural != null) {
      final String resourceIdOther = '${resourceId}Other';
      if (!bundle.containsKey(resourceIdOther))
        errorMessages.writeln('Default plural resource $resourceIdOther undefined');
    } else {
      if (!bundle.containsKey(resourceId))
        errorMessages.writeln('No matching $resourceId defined for $atResourceId');
    }
  }

  return errorMessages.isEmpty ? null : errorMessages.toString();
}

/// Enforces the following invariants in our localizations:
///
/// - Resource keys are valid, i.e. they appear in the canonical list.
/// - Resource keys are complete for language-level locales, e.g. "es", "he".
///
/// Uses "en" localizations as the canonical source of locale keys that other
/// locales are compared against.
///
/// If validation fails, return an error message, otherwise return null.
String validateLocalizations(
  Map<String, Map<String, String>> localeToResources,
  Map<String, Map<String, dynamic>> localeToAttributes,
) {
  final Map<String, String> canonicalLocalizations = localeToResources['en'];
  final Set<String> canonicalKeys = new Set<String>.from(canonicalLocalizations.keys);
  final StringBuffer errorMessages = new StringBuffer();
  bool explainMissingKeys = false;
  for (final String locale in localeToResources.keys) {
    final Map<String, String> resources = localeToResources[locale];

    // Whether `key` corresponds to one of the plural variations of a key with
    // the same prefix and suffix "Other".
    //
    // Many languages require only a subset of these variations, so we do not
    // require them so long as the "Other" variation exists.
    bool isPluralVariation(String key) {
      final RegExp pluralRegexp = new RegExp(r'(\w*)(Zero|One|Two|Few|Many)$');
      final Match pluralMatch = pluralRegexp.firstMatch(key);

      if (pluralMatch == null)
        return false;

      final String prefix = pluralMatch[1];
      return resources.containsKey('${prefix}Other');
    }

    final Set<String> keys = new Set<String>.from(
      resources.keys.where((String key) => !isPluralVariation(key))
    );

    // Make sure keys are valid (i.e. they also exist in the canonical
    // localizations)
    final Set<String> invalidKeys = keys.difference(canonicalKeys);
    if (invalidKeys.isNotEmpty)
      errorMessages.writeln('Locale "$locale" contains invalid resource keys: ${invalidKeys.join(', ')}');

    // For language-level locales only, check that they have a complete list of
    // keys, or opted out of using certain ones.
    if (locale.length == 2) {
      final Map<String, dynamic> attributes = localeToAttributes[locale];
      final List<String> missingKeys = <String>[];

      for (final String missingKey in canonicalKeys.difference(keys)) {
        final dynamic attribute = attributes[missingKey];
        final bool intentionallyOmitted = attribute is Map && attribute.containsKey('notUsed');
        if (!intentionallyOmitted && !isPluralVariation(missingKey))
          missingKeys.add(missingKey);
      }
      if (missingKeys.isNotEmpty) {
        explainMissingKeys = true;
        errorMessages.writeln('Locale "$locale" is missing the following resource keys: ${missingKeys.join(', ')}');
      }
    }
  }

  if (errorMessages.isNotEmpty) {
    if (explainMissingKeys) {
        errorMessages
          ..writeln()
          ..writeln(
            'If a resource key is intentionally omitted, add an attribute corresponding '
            'to the key name with a "notUsed" property explaining why. Example:'
          )
          ..writeln()
          ..writeln('"@anteMeridiemAbbreviation": {')
          ..writeln('  "notUsed": "Sindhi time format does not use a.m. indicator"')
          ..writeln('}');
    }
    return errorMessages.toString();
  }
  return null;
}
