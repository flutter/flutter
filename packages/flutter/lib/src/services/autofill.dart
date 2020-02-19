import 'dart:ui' show
  FontWeight,
  Offset,
  Size,
  TextAffinity,
  TextAlign,
  TextDirection,
  hashValues;

import 'package:flutter/foundation.dart';

import 'message_codec.dart';
import 'platform_channel.dart';
import 'system_channels.dart';
import 'system_chrome.dart';
import 'text_editing.dart';
import 'text_input.dart' show TextEditingValue, TextInputConfiguration;

@immutable
class AutofillConfiguration {
  const AutofillConfiguration({
    @required this.uniqueIdentifier,
    @required this.autofillHints,
    @required this.allAutofillableFields,
    this.currentEditingValue,
  }) : assert(uniqueIdentifier != null),
       assert(autofillHints != null),
       assert(allAutofillableFields != null);

  final String uniqueIdentifier;
  final String autofillHints;
  final TextEditingValue currentEditingValue;
  final List<TextInputConfiguration> allAutofillableFields;

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'identifier': uniqueIdentifier,
      'hints': autofillHints,
      'editingValue': currentEditingValue.toJSON(),
      'allFields': allAutofillableFields
        .map((TextInputConfiguration config) => config.toJson())
        .toList(growable: false),
    };
  }
}
