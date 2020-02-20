import 'package:flutter/foundation.dart';

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

abstract class AutofillClient<EditingValue> {
  TextInputConfiguration get textInputConfiguration;

  AutofillScope get currentScope;
  void updateEditingValue(EditingValue textEditingValue);
}

abstract class AutofillScope {
  AutofillClient getClient(String tag);
}
