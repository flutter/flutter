// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'text_input.dart';

// TODO(LongCatIsLooong): expand the list to include every predefined value.
/// A collection of commonly used autofill hint strings on different platforms.
class AutofillHints {
  AutofillHints._();

  /// The client represents an input field that expects a credit card number.
  ///
  /// Translates to [UITextContentType.creditCardNumber](https://developer.apple.com/documentation/uikit/uitextcontenttype/1778267-creditcardnumber)
  /// on iOS, [.AUTOFILL_HINT_CREDIT_CARD_NUMBER](https://developer.android.com/reference/androidx/autofill/HintConstants#AUTOFILL_HINT_CREDIT_CARD_NUMBER)
  /// on Android, and [cc-number](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete)
  /// on web.
  static const String creditCardNumber = 'creditCardNumber';

  /// The client represents an input field that expects the a credit card security
  /// code.
  ///
  /// Translates to [.AUTOFILL_HINT_CREDIT_SECURITY_CODE](https://developer.android.com/reference/androidx/autofill/HintConstants#AUTOFILL_HINT_CREDIT_CARD_SECURITY_CODE)
  /// on Android, and [cc-csc](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete)
  /// on web.
  static const String creditCardSecurityCode = 'creditCardSecurityCode';

  /// The client represents an input field that takes a newly created password for
  /// save/update.
  ///
  /// Translates to [UITextContentType.username](https://developer.apple.com/documentation/uikit/uitextcontenttype/2980929-newpassword),
  /// on iOS, [.AUTOFILL_HINT_NEW_PASSWORD](https://developer.android.com/reference/androidx/autofill/HintConstants#AUTOFILL_HINT_NEW_PASSWORD)
  /// on Android, and [new-password](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete)
  /// on web.
  static const String newPassword = 'newPassword';

  /// The client represents an input field that expects a telephone number.
  ///
  /// Translates to [UITextContentType.telephoneNumber](https://developer.apple.com/documentation/uikit/uitextcontenttype/1649664-telephonenumber),
  /// on iOS, [.AUTOFILL_HINT_PHONE_NUMBER](https://developer.android.com/reference/androidx/autofill/HintConstants#AUTOFILL_HINT_PHONE_NUMBER)
  /// on Android, and [tel](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete)
  /// on web.
  static const String telephoneNumber = 'telephoneNumber';

  /// The client represents an input field that expects the first line of a street
  /// address.
  ///
  /// Translates to [UITextContentType.streetAddressLine1](https://developer.apple.com/documentation/uikit/uitextcontenttype/1649663-streetaddressline1),
  /// on iOS, [.AUTOFILL_HINT_POSTAL_ADDRESS](https://developer.android.com/reference/androidx/autofill/HintConstants#AUTOFILL_HINT_POSTAL_ADDRESS)
  /// on Android, and [address-line1](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete)
  /// on web.
  static const String streetAddressLine1 = 'streetAddressLine1';

  /// The client represents an input field that expects the second line of a street
  /// address.
  ///
  /// Translates to [UITextContentType.streetAddressLine2](https://developer.apple.com/documentation/uikit/uitextcontenttype/1649658-streetaddressline2),
  /// on iOS, [.AUTOFILL_HINT_POSTAL_ADDRESS_EXTENDED_ADDRESS](https://developer.android.com/reference/androidx/autofill/HintConstants#AUTOFILL_HINT_POSTAL_ADDRESS_EXTENDED_ADDRESS)
  /// on Android, and [address-line2](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete)
  /// on web.
  static const String streetAddressLine2 = 'streetAddressLine2';

  /// The client represents a password field.
  ///
  /// Translates to [UITextContentType.password](https://developer.apple.com/documentation/uikit/uitextcontenttype/2865813-password),
  /// on iOS, [.AUTOFILL_HINT_PASSWORD](https://developer.android.com/reference/androidx/autofill/HintConstants#AUTOFILL_HINT_PASSWORD)
  /// on Android, and [current-password](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete)
  /// on web.
  static const String password = 'password';

  /// The client represents a username field or an account name.
  ///
  /// Translates to [UITextContentType.username](https://developer.apple.com/documentation/uikit/uitextcontenttype/2866088-username),
  /// on iOS, [.AUTOFILL_HINT_USERNAME](https://developer.android.com/reference/androidx/autofill/HintConstants#AUTOFILL_HINT_USERNAME)
  /// on Android, and [username] (https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete)
  /// on web.
  static const String username = 'username';
}

/// A collection of autofill related information that represents an [AutofillClient].
///
/// Typically used in [TextInputConfiguration.autofillConfiguration].
@immutable
class AutofillConfiguration {
  /// Creates autofill related configuration information that can be sent to the
  /// platform.
  const AutofillConfiguration({
    @required this.uniqueIdentifier,
    @required this.autofillHints,
    this.currentEditingValue,
  }) : assert(uniqueIdentifier != null),
       assert(autofillHints != null);

  /// A string that uniquely identifies the current [AutofillClient].
  ///
  /// The identifier needs to be unique within the [AutofillScope] for the
  /// [AutofillClient] to receive the correct autofill value.
  ///
  /// Must not be null.
  final String uniqueIdentifier;

  /// A list of strings that helps the autofill service identify the type of the
  /// [AutofillClient].
  ///
  /// {@template flutter.services.autofill.autofillHints}
  /// The common values of each hint can be found in [AutofillHints]. Using a custom
  /// string value is not recommended as it may not be understood by the platform.
  /// Each hint in the list, if not ignored, will be translated to the platform's
  /// autofill hint type understood by its autofill services:
  ///
  /// * On iOS, only the first hint in the list is accounted for. The hint will
  /// be translated to a [UITextContentType](https://developer.apple.com/documentation/uikit/uitextcontenttype).
  ///
  /// * On Android, all hints in the list are translated to Android hint strings.
  ///
  /// * On web, only the first hint is accounted for and will be translated to
  /// an "autocomplete" string.
  ///
  /// See also:
  ///
  /// * [AutofillHints], a list of autofill hint strings that is predefined on at
  /// least one platform.
  ///
  /// * [UITextContentType](https://developer.apple.com/documentation/uikit/uitextcontenttype),
  /// the iOS equivalent.
  ///
  /// * Android [autofillHints](https://developer.android.com/reference/android/view/View#setAutofillHints(java.lang.String...)),
  /// the Android equivalent.
  ///
  /// * The [autocomplete](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete) attribute,
  /// the web equivalent.
  /// {@endtemplate}
  final List<String> autofillHints;

  /// The current [TextEditingValue] of the [AutofillClient].
  final TextEditingValue currentEditingValue;

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uniqueIdentifier': uniqueIdentifier,
      'hints': autofillHints,
      'editingValue': currentEditingValue.toJSON(),
    };
  }
}

/// A client that represents an autofillable input field in the autofill workflow.
abstract class AutofillClient {
  /// The unique identifier of this [AutofillClient].
  ///
  /// This [AutofillClient] will not participate in autofill until the [autofillId]
  /// becomes non-null.
  String get autofillId;

  /// The [TextInputConfiguration] that describes this [AutofillClient].
  TextInputConfiguration get textInputConfiguration;

  /// Requests this [AutofillClient] update its [TextEditingState] to the given
  /// state.
  void updateEditingValue(TextEditingValue newEditingValue);
}

/// A [TextInputClient] that triggers autofill when focused.
///
/// This is typically a [State] or [Element], and should be able to gain focus in
/// order to trigger autofill.
abstract class AutofillTrigger extends TextInputClient {
  /// The [AutofillScope] that this [AutofillTrigger] belongs to.
  ///
  /// This [AutofillTrigger] will participate in autofill alone if null.
  AutofillScope get currentAutofillScope;
}

mixin AutofillClientMixin implements AutofillClient {
  @override
  String get autofillId {
    final AutofillConfiguration configuration = textInputConfiguration.autofillConfiguration;
    final String identifier = configuration?.uniqueIdentifier;
    assert(configuration == null || identifier != null);
    return identifier;
  }
}

/// An ordered group of [AutofillClient]s that are logically connected.
///
/// {@template flutter.services.autofill.AutofillScope}
/// [AutofillClient]s within the same [AutofillScope] are isolated from other
/// input fields during autofill. That is, when an [AutofillTrigger] gains focus,
/// only the [AutofillClient]s within the same [AutofillScope] will be visible to
/// the autofill service, in the same order as they appear in [autofillClients].
///
/// [AutofillScope] also allows [TextInput] to redirect autofill values from the
/// platform to the [AutofillClient] with the given identifier, by calling
/// [getAutofillClient].
///
/// An [AutofillClient] not tied to any [AutofillScope] will only participate in
/// autofill if the autofill is directly triggered by its own [AutofillTrigger].
/// {@endtemplate}
mixin AutofillScope {
  /// Gets the [AutofillScope] associated with the given [uniqueIdentifier], in
  /// this [AutofillScope].
  ///
  /// Returns null if there's no matching [AutofillClient].
  AutofillClient getAutofillClient(String uniqueIdentifier);

  /// The collection of [AutofillClient]s currently tied to this [AutofillScope].
  ///
  /// The [AutofillClient]s should appear in a sensible order, as the autofill
  /// service will see these [AutofillClient]s in the exact same order.
  Iterable<AutofillClient> get autofillClients;

  /// Allows an [AutofillTrigger] to attach to this scope. This method should be
  /// called in lieu of [TextInput.attach], when the [AutofillTrigger] wishes to
  /// participate in autofill.
  TextInputConnection attach(AutofillTrigger trigger, TextInputConfiguration configuration);
}

@immutable
class _AutofillScopeTextInputConfiguration extends TextInputConfiguration {
  _AutofillScopeTextInputConfiguration({
    @required this.allConfigurations,
    @required TextInputConfiguration currentClientConfiguration,
  }) : assert(allConfigurations != null),
       assert(currentClientConfiguration != null),
       super(inputType: currentClientConfiguration.inputType,
         obscureText: currentClientConfiguration.obscureText,
         autocorrect: currentClientConfiguration.autocorrect,
         smartDashesType: currentClientConfiguration.smartDashesType,
         smartQuotesType: currentClientConfiguration.smartQuotesType,
         enableSuggestions: currentClientConfiguration.enableSuggestions,
         inputAction: currentClientConfiguration.inputAction,
         textCapitalization: currentClientConfiguration.textCapitalization,
         keyboardAppearance: currentClientConfiguration.keyboardAppearance,
         actionLabel: currentClientConfiguration.actionLabel,
         autofillConfiguration: currentClientConfiguration.autofillConfiguration,
       );

  final Iterable<TextInputConfiguration> allConfigurations;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = super.toJson();
    result['allFields'] = allConfigurations
      .map((TextInputConfiguration configuration) => configuration.toJson())
      .toList(growable: false);
    return result;
  }
}

/// A partial implementation of [AutofillScope].
///
/// The mixin provides a default implementation for [AutofillScope.attach], which,
/// when called, caches the list of [AutofillClient]s by storing the contents of
/// [autofillClients] in a [Map]. This allows the implementation of [getAutofillClient]
/// to be more efficient.
mixin AutofillScopeMixin implements AutofillScope {
  final Map<String, AutofillClient> _clients = <String, AutofillClient>{};

  @override
  AutofillClient getAutofillClient(String tag) => _clients[tag];

  @override
  TextInputConnection attach(AutofillTrigger trigger, TextInputConfiguration configuration) {
    assert(trigger != null);
    // Caches clients on attach.
    _clients.clear();
    for (final AutofillClient c in autofillClients)
      _clients[c.autofillId] = c;
    return TextInput.attach(
      trigger,
      _AutofillScopeTextInputConfiguration(
        allConfigurations: autofillClients
          .map((AutofillClient client) => client.textInputConfiguration),
        currentClientConfiguration: configuration,
      ),
    );
  }
}
