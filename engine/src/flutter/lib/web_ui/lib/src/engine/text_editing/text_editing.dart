// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../browser_detection.dart';
import '../embedder.dart';
import '../host_node.dart';
import '../platform_dispatcher.dart';
import '../safe_browser_api.dart';
import '../semantics.dart';
import '../services.dart';
import '../text/paragraph.dart';
import '../util.dart';
import 'autofill_hint.dart';
import 'input_type.dart';
import 'text_capitalization.dart';

/// Make the content editable span visible to facilitate debugging.
bool _debugVisibleTextEditing = false;

/// Set this to `true` to print when text input commands are scheduled and run.
bool _debugPrintTextInputCommands = false;

/// The `keyCode` of the "Enter" key.
const int _kReturnKeyCode = 13;

/// Blink and Webkit engines, bring an overlay on top of the text field when it
/// is autofilled.
bool browserHasAutofillOverlay() =>
    browserEngine == BrowserEngine.blink ||
    browserEngine == BrowserEngine.samsung ||
    browserEngine == BrowserEngine.webkit;

/// `transparentTextEditing` class is configured to make the autofill overlay
/// transparent.
const String transparentTextEditingClass = 'transparentTextEditing';

void _emptyCallback(dynamic _) {}

/// The default [HostNode] that hosts all DOM required for text editing when a11y is not enabled.
@visibleForTesting
HostNode get defaultTextEditingRoot => flutterViewEmbedder.glassPaneShadow!;

/// These style attributes are constant throughout the life time of an input
/// element.
///
/// They are assigned once during the creation of the DOM element.
void _setStaticStyleAttributes(html.HtmlElement domElement) {
  domElement.classes.add(HybridTextEditing.textEditingClass);

  final html.CssStyleDeclaration elementStyle = domElement.style;
  elementStyle
    ..whiteSpace = 'pre-wrap'
    ..alignContent = 'center'
    ..position = 'absolute'
    ..top = '0'
    ..left = '0'
    ..padding = '0'
    ..opacity = '1'
    ..color = 'transparent'
    ..backgroundColor = 'transparent'
    ..background = 'transparent'
    ..outline = 'none'
    ..border = 'none'
    ..resize = 'none'
    ..textShadow = 'transparent'
    ..overflow = 'hidden'
    ..transformOrigin = '0 0 0';

  if (browserHasAutofillOverlay()) {
    domElement.classes.add(transparentTextEditingClass);
  }

  // This property makes the input's blinking cursor transparent.
  elementStyle.setProperty('caret-color', 'transparent');

  if (_debugVisibleTextEditing) {
    elementStyle
      ..color = 'purple'
      ..outline = '1px solid purple';
  }
}

/// Sets attributes to hide autofill elements.
///
/// These style attributes are constant throughout the life time of an input
/// element.
///
/// They are assigned once during the creation of the DOM element.
void _hideAutofillElements(html.HtmlElement domElement,
    {bool isOffScreen = false}) {
  final html.CssStyleDeclaration elementStyle = domElement.style;
  elementStyle
    ..whiteSpace = 'pre-wrap'
    ..alignContent = 'center'
    ..padding = '0'
    ..opacity = '1'
    ..color = 'transparent'
    ..backgroundColor = 'transparent'
    ..background = 'transparent'
    ..outline = 'none'
    ..border = 'none'
    ..resize = 'none'
    ..width = '0'
    ..height = '0'
    ..textShadow = 'transparent'
    ..transformOrigin = '0 0 0';

  if (isOffScreen) {
    elementStyle
      ..top = '-9999px'
      ..left = '-9999px';
  }

  if (browserHasAutofillOverlay()) {
    domElement.classes.add(transparentTextEditingClass);
  }

  /// This property makes the input's blinking cursor transparent.
  elementStyle.setProperty('caret-color', 'transparent');
}

/// Form that contains all the fields in the same AutofillGroup.
///
/// An [EngineAutofillForm] will only be constructed when autofill is enabled
/// (the default) on the current input field. See the [fromFrameworkMessage]
/// static method.
class EngineAutofillForm {
  EngineAutofillForm({
    required this.formElement,
    this.elements,
    this.items,
    this.formIdentifier = '',
  });

  final html.FormElement formElement;

  final Map<String, html.HtmlElement>? elements;

  final Map<String, AutofillInfo>? items;

  /// Identifier for the form.
  ///
  /// It is constructed by concatenating unique ids of input elements on the
  /// form.
  ///
  /// It is used for storing the form until submission.
  /// See [formsOnTheDom].
  final String formIdentifier;

  /// Creates an [EngineAutofillFrom] from the JSON representation of a Flutter
  /// framework `TextInputConfiguration` object.
  ///
  /// The `focusedElementAutofill` argument corresponds to the "autofill" field
  /// in a `TextInputConfiguration`. Not having this field indicates autofill
  /// is explicitly disabled on the text field by the developer.
  ///
  /// The `fields` argument corresponds to the "fields" field in a
  /// `TextInputConfiguration`.
  ///
  /// Returns null if autofill is disabled for the input field.
  static EngineAutofillForm? fromFrameworkMessage(
    Map<String, dynamic>? focusedElementAutofill,
    List<dynamic>? fields,
  ) {
    // Autofill value will be null if the developer explicitly disables it on
    // the input field.
    if (focusedElementAutofill == null) {
      return null;
    }

    // If there is only one text field in the autofill model, `fields` will be
    // null. `focusedElementAutofill` contains the information about the one
    // text field.
    final Map<String, html.HtmlElement> elements = <String, html.HtmlElement>{};
    final Map<String, AutofillInfo> items = <String, AutofillInfo>{};
    final html.FormElement formElement = html.FormElement();

    // Validation is in the framework side.
    formElement.noValidate = true;
    formElement.method = 'post';
    formElement.action = '#';
    formElement.addEventListener('submit', (html.Event e) {
      e.preventDefault();
    });

    _hideAutofillElements(formElement);

    // We keep the ids in a list then sort them later, in case the text fields'
    // locations are re-ordered on the framework side.
    final List<String> ids = List<String>.empty(growable: true);

    // The focused text editing element will not be created here.
    final AutofillInfo focusedElement =
        AutofillInfo.fromFrameworkMessage(focusedElementAutofill);

    if (fields != null) {
      for (final Map<String, dynamic> field in
          fields.cast<Map<String, dynamic>>()) {
        final Map<String, dynamic> autofillInfo = field.readJson('autofill');
        final AutofillInfo autofill = AutofillInfo.fromFrameworkMessage(
          autofillInfo,
          textCapitalization: TextCapitalizationConfig.fromInputConfiguration(
            field.readString('textCapitalization'),
          ),
        );

        ids.add(autofill.uniqueIdentifier);

        if (autofill.uniqueIdentifier != focusedElement.uniqueIdentifier) {
          final EngineInputType engineInputType = EngineInputType.fromName(
            field.readJson('inputType').readString('name'),
          );

          final html.HtmlElement htmlElement = engineInputType.createDomElement();
          autofill.editingState.applyToDomElement(htmlElement);
          autofill.applyToDomElement(htmlElement);
          _hideAutofillElements(htmlElement);

          items[autofill.uniqueIdentifier] = autofill;
          elements[autofill.uniqueIdentifier] = htmlElement;
          formElement.append(htmlElement);
        }
      }
    } else {
      // There is one input element in the form.
      ids.add(focusedElement.uniqueIdentifier);
    }

    ids.sort();
    final StringBuffer idBuffer = StringBuffer();

    // Add a separator between element identifiers.
    for (final String id in ids) {
      if (idBuffer.length > 0) {
        idBuffer.write('*');
      }
      idBuffer.write(id);
    }

    final String formIdentifier = idBuffer.toString();

    // If a form with the same Autofill elements is already on the dom, remove
    // it from DOM.
    final html.FormElement? form = formsOnTheDom[formIdentifier];
    form?.remove();

    // In order to submit the form when Framework sends a `TextInput.commit`
    // message, we add a submit button to the form.
    final html.InputElement submitButton = html.InputElement();
    _hideAutofillElements(submitButton, isOffScreen: true);
    submitButton.className = 'submitBtn';
    submitButton.type = 'submit';

    formElement.append(submitButton);

    return EngineAutofillForm(
      formElement: formElement,
      elements: elements,
      items: items,
      formIdentifier: formIdentifier,
    );
  }

  void placeForm(html.HtmlElement mainTextEditingElement) {
    formElement.append(mainTextEditingElement);
    defaultTextEditingRoot.append(formElement);
  }

  void storeForm() {
    formsOnTheDom[formIdentifier] = formElement;
    _hideAutofillElements(formElement, isOffScreen: true);
  }

  /// Listens to `onInput` event on the form fields.
  ///
  /// Registering to the listeners could have been done in the constructor.
  /// On the other hand, overall for text editing there is already a lifecycle
  /// for subscriptions: All the subscriptions of the DOM elements are to the
  /// `subscriptions` property of [DefaultTextEditingStrategy].
  /// [TextEditingStrategy] manages all subscription lifecyle. All
  /// listeners with no exceptions are added during
  /// [TextEditingStrategy.addEventHandlers] method call and all
  /// listeners are removed during [TextEditingStrategy.disable] method call.
  List<StreamSubscription<html.Event>> addInputEventListeners() {
    final Iterable<String> keys = elements!.keys;
    final List<StreamSubscription<html.Event>> subscriptions =
        <StreamSubscription<html.Event>>[];

    void addSubscriptionForKey(String key) {
        final html.Element element = elements![key]!;
        subscriptions.add(
            element.onInput.listen((html.Event e) {
              if (items![key] == null) {
                throw StateError(
                    'AutofillInfo must have a valid uniqueIdentifier.');
              } else {
                final AutofillInfo autofillInfo = items![key]!;
                handleChange(element, autofillInfo);
              }
            })
        );
    }

    keys.forEach(addSubscriptionForKey);
    return subscriptions;
  }

  void handleChange(html.Element domElement, AutofillInfo autofillInfo) {
    final EditingState newEditingState = EditingState.fromDomElement(
        domElement as html.HtmlElement?);

    _sendAutofillEditingState(autofillInfo.uniqueIdentifier, newEditingState);
  }

  /// Sends the 'TextInputClient.updateEditingStateWithTag' message to the framework.
  void _sendAutofillEditingState(String? tag, EditingState editingState) {
    EnginePlatformDispatcher.instance.invokeOnPlatformMessage(
      'flutter/textinput',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall(
          'TextInputClient.updateEditingStateWithTag',
          <dynamic>[
            0,
            <String?, dynamic>{tag: editingState.toFlutter()}
          ],
        ),
      ),
      _emptyCallback,
    );
  }
}

/// Autofill related values.
///
/// These values are to be used when a text field have autofill enabled.
@visibleForTesting
class AutofillInfo {
  AutofillInfo({
    required this.editingState,
    required this.uniqueIdentifier,
    required this.autofillHint,
    required this.textCapitalization,
    this.placeholder,
  });

  /// The current text and selection state of a text field.
  final EditingState editingState;

  /// Unique value set by the developer or generated by the framework.
  ///
  /// Used as id of the text field.
  ///
  /// An example an id generated by the framework: `EditableText-285283643`.
  final String uniqueIdentifier;

  /// Information on how should autofilled text capitalized.
  ///
  /// For example for [TextCapitalization.characters] each letter is converted
  /// to upper case.
  ///
  /// This value is not necessary for autofilling the focused element since
  /// [DefaultTextEditingStrategy.inputConfiguration] already has this
  /// information.
  ///
  /// On the other hand for the multi element forms, for the input elements
  /// other the focused field, we need to use this information.
  final TextCapitalizationConfig textCapitalization;

  /// The type of information expected in the field, specified by the developer.
  ///
  /// Used as a guidance to the browser as to the type of information expected
  /// in the field.
  /// See: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete
  final String? autofillHint;

  /// The optional hint text placed on the view that typically suggests what
  /// sort of input the field accepts, for example "enter your password here".
  ///
  /// If the developer does not specify any [autofillHints], the [placeholder]
  /// can be a useful indication to the platform autofill service as to what
  /// information is expected in this field.
  final String? placeholder;

  factory AutofillInfo.fromFrameworkMessage(Map<String, dynamic> autofill,
      {TextCapitalizationConfig textCapitalization =
          const TextCapitalizationConfig.defaultCapitalization()}) {
    assert(autofill != null); // ignore: unnecessary_null_comparison
    final String uniqueIdentifier = autofill.readString('uniqueIdentifier');
    final List<dynamic>? hintsList = autofill.tryList('hints');
    final String? firstHint = (hintsList == null || hintsList.isEmpty) ? null : hintsList.first as String;
    final EditingState editingState =
        EditingState.fromFrameworkMessage(autofill.readJson('editingValue'));
    return AutofillInfo(
      uniqueIdentifier: uniqueIdentifier,
      autofillHint: (firstHint != null) ? BrowserAutofillHints.instance.flutterToEngine(firstHint) : null,
      editingState: editingState,
      placeholder: autofill.tryString('hintText'),
      textCapitalization: textCapitalization,
    );
  }

  void applyToDomElement(html.HtmlElement domElement,
      {bool focusedElement = false}) {
    final String? autofillHint = this.autofillHint;
    final String? placeholder = this.placeholder;
    if (domElement is html.InputElement) {
      final html.InputElement element = domElement;
      if (placeholder != null) {
        element.placeholder = placeholder;
      }
      if (autofillHint != null) {
        element.name = autofillHint;
        element.id = autofillHint;
        if (autofillHint.contains('password')) {
          element.type = 'password';
        } else {
          element.type = 'text';
        }
      }
      element.autocomplete = autofillHint ?? 'on';
    } else if (domElement is html.TextAreaElement) {
      if (placeholder != null) {
        domElement.placeholder = placeholder;
      }
      if (autofillHint != null) {
        domElement.name = autofillHint;
        domElement.id = autofillHint;
      }
      domElement.setAttribute('autocomplete', autofillHint ?? 'on');
    }
  }
}

/// The current text and selection state of a text field.
class EditingState {
  EditingState({this.text, int? baseOffset, int? extentOffset}) :
    // Don't allow negative numbers. Pick the smallest selection index for base.
    baseOffset = math.max(0, math.min(baseOffset ?? 0, extentOffset ?? 0)),
    // Don't allow negative numbers. Pick the greatest selection index for extent.
    extentOffset = math.max(0, math.max(baseOffset ?? 0, extentOffset ?? 0));

  /// Creates an [EditingState] instance using values from an editing state Map
  /// coming from Flutter.
  ///
  /// The `editingState` Map has the following structure:
  /// ```json
  /// {
  ///   "text": "The text here",
  ///   "selectionBase": 0,
  ///   "selectionExtent": 0,
  ///   "selectionAffinity": "TextAffinity.upstream",
  ///   "selectionIsDirectional": false,
  ///   "composingBase": -1,
  ///   "composingExtent": -1
  /// }
  /// ```
  ///
  /// Flutter Framework can send the [selectionBase] and [selectionExtent] as
  /// -1, if so 0 assigned to the [baseOffset] and [extentOffset]. -1 is not a
  /// valid selection range for input DOM elements.
  factory EditingState.fromFrameworkMessage(
      Map<String, dynamic> flutterEditingState) {
    final int selectionBase = flutterEditingState.readInt('selectionBase');
    final int selectionExtent = flutterEditingState.readInt('selectionExtent');
    final String? text = flutterEditingState.tryString('text');

    return EditingState(
      text: text,
      baseOffset: selectionBase,
      extentOffset: selectionExtent,
    );
  }

  /// Creates an [EditingState] instance using values from the editing element
  /// in the DOM.
  ///
  /// [domElement] can be a [InputElement] or a [TextAreaElement] depending on
  /// the [InputType] of the text field.
  factory EditingState.fromDomElement(html.HtmlElement? domElement) {
    if (domElement is html.InputElement) {
      final html.InputElement element = domElement;
      return EditingState(
          text: element.value,
          baseOffset: element.selectionStart,
          extentOffset: element.selectionEnd);
    } else if (domElement is html.TextAreaElement) {
      final html.TextAreaElement element = domElement;
      return EditingState(
          text: element.value,
          baseOffset: element.selectionStart,
          extentOffset: element.selectionEnd);
    } else {
      throw UnsupportedError('Initialized with unsupported input type');
    }
  }

  /// The counterpart of [EditingState.fromFrameworkMessage]. It generates a Map that
  /// can be sent to Flutter.
  // TODO(mdebbar): Should we get `selectionAffinity` and other properties from flutter's editing state?
  Map<String, dynamic> toFlutter() => <String, dynamic>{
        'text': text,
        'selectionBase': baseOffset,
        'selectionExtent': extentOffset,
      };

  /// The current text being edited.
  final String? text;

  /// The offset at which the text selection originates.
  final int? baseOffset;

  /// The offset at which the text selection terminates.
  final int? extentOffset;

  /// Whether the current editing state is valid or not.
  bool get isValid => baseOffset! >= 0 && extentOffset! >= 0;

  @override
  int get hashCode => ui.hashValues(text, baseOffset, extentOffset);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is EditingState &&
        other.text == text &&
        other.baseOffset == baseOffset &&
        other.extentOffset == extentOffset;
  }

  @override
  String toString() {
    return assertionsEnabled
        ? 'EditingState("$text", base:$baseOffset, extent:$extentOffset)'
        : super.toString();
  }

  /// Sets the selection values of a DOM element using this [EditingState].
  ///
  /// [domElement] can be a [InputElement] or a [TextAreaElement] depending on
  /// the [InputType] of the text field.
  ///
  /// This should only be used by focused elements only, because only focused
  /// elements can have their text selection range set. Attempting to set
  /// selection range on a non-focused element will cause it to request focus.
  ///
  /// See also:
  ///
  ///  * [applyTextToDomElement], which is used for non-focused elements.
  void applyToDomElement(html.HtmlElement? domElement) {
    if (domElement is html.InputElement) {
      final html.InputElement element = domElement;
      element.value = text;
      element.setSelectionRange(baseOffset!, extentOffset!);
    } else if (domElement is html.TextAreaElement) {
      final html.TextAreaElement element = domElement;
      element.value = text;
      element.setSelectionRange(baseOffset!, extentOffset!);
    } else {
      throw UnsupportedError('Unsupported DOM element type: <${domElement?.tagName}> (${domElement.runtimeType})');
    }
  }

  /// Applies the [text] to the [domElement].
  ///
  /// This is used by non-focused elements.
  ///
  /// See also:
  ///
  ///  * [applyToDomElement], which is used for focused elements.
  void applyTextToDomElement(html.HtmlElement? domElement) {
    if (domElement is html.InputElement) {
      final html.InputElement element = domElement;
      element.value = text;
    } else if (domElement is html.TextAreaElement) {
      final html.TextAreaElement element = domElement;
      element.value = text;
    } else {
      throw UnsupportedError('Unsupported DOM element type');
    }
  }
}

/// Controls the appearance of the input control being edited.
///
/// For example, [inputType] determines whether we should use `<input>` or
/// `<textarea>` as a backing DOM element.
///
/// This corresponds to Flutter's [TextInputConfiguration].
class InputConfiguration {
  InputConfiguration({
    this.inputType = EngineInputType.text,
    this.inputAction = 'TextInputAction.done',
    this.obscureText = false,
    this.readOnly = false,
    this.autocorrect = true,
    this.textCapitalization =
        const TextCapitalizationConfig.defaultCapitalization(),
    this.autofill,
    this.autofillGroup,
  });

  InputConfiguration.fromFrameworkMessage(
      Map<String, dynamic> flutterInputConfiguration)
      : inputType = EngineInputType.fromName(
          flutterInputConfiguration.readJson('inputType').readString('name'),
          isDecimal: flutterInputConfiguration.readJson('inputType').tryBool('decimal') ?? false,
        ),
        inputAction =
            flutterInputConfiguration.tryString('inputAction') ?? 'TextInputAction.done',
        obscureText = flutterInputConfiguration.tryBool('obscureText') ?? false,
        readOnly = flutterInputConfiguration.tryBool('readOnly') ?? false,
        autocorrect = flutterInputConfiguration.tryBool('autocorrect') ?? true,
        textCapitalization = TextCapitalizationConfig.fromInputConfiguration(
          flutterInputConfiguration.readString('textCapitalization'),
        ),
        autofill = flutterInputConfiguration.containsKey('autofill')
            ? AutofillInfo.fromFrameworkMessage(
                flutterInputConfiguration.readJson('autofill'))
            : null,
        autofillGroup = EngineAutofillForm.fromFrameworkMessage(
          flutterInputConfiguration.tryJson('autofill'),
          flutterInputConfiguration.tryList('fields'),
        );

  /// The type of information being edited in the input control.
  final EngineInputType inputType;

  /// The default action for the input field.
  final String inputAction;

  /// Whether the text field can be edited or not.
  ///
  /// Defaults to false.
  final bool readOnly;

  /// Whether to hide the text being edited.
  final bool obscureText;

  /// Whether to enable autocorrection.
  ///
  /// Definition of autocorrect can be found in:
  /// https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  ///
  /// For future manual tests, note that autocorrect is an attribute only
  /// supported by Safari.
  final bool autocorrect;

  final AutofillInfo? autofill;

  final EngineAutofillForm? autofillGroup;

  final TextCapitalizationConfig textCapitalization;
}

typedef OnChangeCallback = void Function(EditingState? editingState);
typedef OnActionCallback = void Function(String? inputAction);

/// Provides HTML DOM functionality for editable text.
///
/// A concrete implementation is picked at runtime based on the current
/// operating system, web browser, and accessibility mode.
abstract class TextEditingStrategy {
  void initializeTextEditing(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  });

  /// Sets the initial placement of the DOM element on the UI.
  ///
  /// The element must be located exactly in the same place with the editable
  /// widget. However, its contents and cursor will be invisible.
  ///
  /// Users can interact with the element and use the functionality of the
  /// right-click menu, such as copy, paste, cut, select, translate, etc.
  void initializeElementPlacement();

  /// Register event listeners to the DOM element.
  ///
  /// These event listener will be removed in [disable].
  void addEventHandlers();

  /// Update the element's position.
  ///
  /// The position will be updated everytime Flutter Framework sends
  /// 'TextInput.setEditableSizeAndTransform' message.
  void updateElementPlacement(EditableTextGeometry geometry);

  /// Set editing state of the element.
  ///
  /// This includes text and selection relelated states. The editing state will
  /// be updated everytime Flutter Framework sends 'TextInput.setEditingState'
  /// message.
  void setEditingState(EditingState editingState);

  /// Set style to the native DOM element used for text editing.
  void updateElementStyle(EditableTextStyle style);

  /// Disables the element so it's no longer used for text editing.
  ///
  /// Calling [disable] also removes any registered event listeners.
  void disable();
}

/// A [TextEditingStrategy] that places its [domElement] assuming no
/// prior transform or sizing is applied to it.
///
/// This implementation is used by text editables when semantics is not
/// enabled. With semantics enabled the placement is provided by the semantics
/// tree.
class GloballyPositionedTextEditingStrategy extends DefaultTextEditingStrategy {
  GloballyPositionedTextEditingStrategy(HybridTextEditing owner) : super(owner);

  @override
  void placeElement() {
    geometry?.applyToDomElement(activeDomElement);
    if (hasAutofillGroup) {
      placeForm();
      // Set the last editing state if it exists, this is critical for a
      // users ongoing work to continue uninterrupted when there is an update to
      // the transform.
      lastEditingState?.applyToDomElement(domElement);
      // On Chrome, when a form is focused, it opens an autofill menu
      // immediately.
      // Flutter framework sends `setEditableSizeAndTransform` for informing
      // the engine about the location of the text field. This call will
      // arrive after `show` call.
      // Therefore on Chrome we place the element when
      //  `setEditableSizeAndTransform` method is called and focus on the form
      // only after placing it to the correct position. Hence autofill menu
      // does not appear on top-left of the page.
      // Refocus on the elements after applying the geometry.
      focusedFormElement!.focus();
      activeDomElement.focus();
    }
  }
}

/// A [TextEditingStrategy] for Safari Desktop Browser.
///
/// It places its [domElement] assuming no prior transform or sizing is applied
/// to it.
///
/// In case of an autofill enabled form, it does not append the form element
/// to the DOM, until the geometry information is updated.
///
/// This implementation is used by text editables when semantics is not
/// enabled. With semantics enabled the placement is provided by the semantics
/// tree.
class SafariDesktopTextEditingStrategy extends DefaultTextEditingStrategy {
  SafariDesktopTextEditingStrategy(HybridTextEditing owner) : super(owner);

  /// Appending an element on the DOM for Safari Desktop Browser.
  ///
  /// This method is only called when geometry information is updated by
  /// 'TextInput.setEditableSizeAndTransform' message.
  ///
  /// This method is similar to the [GloballyPositionedTextEditingStrategy].
  /// The only part different: this method does not call `super.placeElement()`,
  /// which in current state calls `domElement.focus()`.
  ///
  /// Making an extra `focus` request causes flickering in Safari.
  @override
  void placeElement() {
    geometry?.applyToDomElement(activeDomElement);
    if (hasAutofillGroup) {
      placeForm();
      // On Safari Desktop, when a form is focused, it opens an autofill menu
      // immediately.
      // Flutter framework sends `setEditableSizeAndTransform` for informing
      // the engine about the location of the text field. This call will
      // arrive after `show` call. Therefore form is placed, when
      //  `setEditableSizeAndTransform` method is called and focus called on the
      // form only after placing it to the correct position and only once after
      // that. Calling focus multiple times causes flickering.
      focusedFormElement!.focus();

      // Set the last editing state if it exists, this is critical for a
      // users ongoing work to continue uninterrupted when there is an update to
      // the transform.
      // If domElement is not focused cursor location will not be correct.
      activeDomElement.focus();
      lastEditingState?.applyToDomElement(activeDomElement);
    }
  }

  @override
  void initializeElementPlacement() {
    activeDomElement.focus();
  }
}

/// Class implementing the default editing strategies for text editing.
///
/// This class uses a DOM element to provide text editing capabilities.
///
/// The backing DOM element could be one of:
///
/// 1. `<input>`.
/// 2. `<textarea>`.
/// 3. `<span contenteditable="true">`.
///
/// This class includes all the default behaviour for an editing element as
/// well as the common properties such as [domElement].
///
/// Strategies written for different form factors and browsers should extend
/// this class instead of extending the interface [TextEditingStrategy]. In
/// particular, a concrete implementation is expected to override
/// [placeElement] that places the DOM element accordingly. The default
/// implementation of [placeElement] does not position the element.
///
/// Unless a formfactor/browser requires specific implementation for a specific
/// strategy the methods in this class should be used.
abstract class DefaultTextEditingStrategy implements TextEditingStrategy {
  final HybridTextEditing owner;

  DefaultTextEditingStrategy(this.owner);

  bool isEnabled = false;

  /// The DOM element used for editing, if any.
  html.HtmlElement? domElement;

  /// Same as [domElement] but null-checked.
  ///
  /// This must only be called in places that know for sure that a DOM element
  /// is currently available for editing.
  html.HtmlElement get activeDomElement {
    assert(
      domElement != null,
      'The DOM element of this text editing strategy is not currently active.',
    );
    return domElement!;
  }

  late InputConfiguration inputConfiguration;
  EditingState? lastEditingState;

  /// Styles associated with the editable text.
  EditableTextStyle? style;

  /// Size and transform of the editable text on the page.
  EditableTextGeometry? geometry;

  OnChangeCallback? onChange;
  OnActionCallback? onAction;

  final List<StreamSubscription<html.Event>> subscriptions =
      <StreamSubscription<html.Event>>[];

  bool get hasAutofillGroup => inputConfiguration.autofillGroup != null;

  /// Whether the focused input element is part of a form.
  bool get appendedToForm => _appendedToForm;
  bool _appendedToForm = false;

  html.FormElement? get focusedFormElement =>
      inputConfiguration.autofillGroup?.formElement;

  @override
  void initializeTextEditing(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  }) {
    assert(!isEnabled);

    domElement = inputConfig.inputType.createDomElement();
    applyConfiguration(inputConfig);

    _setStaticStyleAttributes(activeDomElement);
    style?.applyToDomElement(activeDomElement);

    if (!hasAutofillGroup) {
      // If there is an Autofill Group the `FormElement`, it will be appended to the
      // DOM later, when the first location information arrived.
      // Otherwise, on Blink based Desktop browsers, the autofill menu appears
      // on top left of the screen.
      defaultTextEditingRoot.append(activeDomElement);
      _appendedToForm = false;
    }

    initializeElementPlacement();

    isEnabled = true;
    this.onChange = onChange;
    this.onAction = onAction;
  }

  void applyConfiguration(InputConfiguration config) {
    inputConfiguration = config;

    if (config.readOnly) {
      activeDomElement.setAttribute('readonly', 'readonly');
    } else {
      activeDomElement.removeAttribute('readonly');
    }

    if (config.obscureText) {
      activeDomElement.setAttribute('type', 'password');
    }

    if (config.inputType == EngineInputType.none) {
      activeDomElement.setAttribute('inputmode', 'none');
    }

    final AutofillInfo? autofill = config.autofill;
    if (autofill != null) {
      autofill.applyToDomElement(activeDomElement, focusedElement: true);
    } else {
      activeDomElement.setAttribute('autocomplete', 'off');
    }

    final String autocorrectValue = config.autocorrect ? 'on' : 'off';
    activeDomElement.setAttribute('autocorrect', autocorrectValue);
  }

  @override
  void initializeElementPlacement() {
    placeElement();
  }

  @override
  void addEventHandlers() {
    if (inputConfiguration.autofillGroup != null) {
      subscriptions
          .addAll(inputConfiguration.autofillGroup!.addInputEventListeners());
    }

    // Subscribe to text and selection changes.
    subscriptions.add(activeDomElement.onInput.listen(handleChange));

    subscriptions.add(activeDomElement.onKeyDown.listen(maybeSendAction));

    subscriptions.add(html.document.onSelectionChange.listen(handleChange));

    // Refocus on the activeDomElement after blur, so that user can keep editing the
    // text field.
    subscriptions.add(activeDomElement.onBlur.listen((_) {
      activeDomElement.focus();
    }));

    preventDefaultForMouseEvents();
  }

  @override
  void updateElementPlacement(EditableTextGeometry textGeometry) {
    geometry = textGeometry;
    if (isEnabled) {
      placeElement();
    }
  }

  @override
  void updateElementStyle(EditableTextStyle textStyle) {
    style = textStyle;
    if (isEnabled) {
      textStyle.applyToDomElement(activeDomElement);
    }
  }

  @override
  void disable() {
    assert(isEnabled);

    isEnabled = false;
    lastEditingState = null;
    style = null;
    geometry = null;

    for (int i = 0; i < subscriptions.length; i++) {
      subscriptions[i].cancel();
    }
    subscriptions.clear();
    // If focused element is a part of a form, it needs to stay on the DOM
    // until the autofill context of the form is finalized.
    // More details on `TextInput.finishAutofillContext` call.
    if (_appendedToForm &&
        inputConfiguration.autofillGroup?.formElement != null) {
      // Subscriptions are removed, listeners won't be triggered.
      activeDomElement.blur();
      _hideAutofillElements(activeDomElement, isOffScreen: true);
      inputConfiguration.autofillGroup?.storeForm();
    } else {
      activeDomElement.remove();
    }
    domElement = null;
  }

  @override
  void setEditingState(EditingState? editingState) {
    lastEditingState = editingState;
    if (!isEnabled || !editingState!.isValid) {
      return;
    }
    lastEditingState!.applyToDomElement(domElement);
  }

  void placeElement() {
    activeDomElement.focus();
  }

  void placeForm() {
    inputConfiguration.autofillGroup!.placeForm(activeDomElement);
    _appendedToForm = true;
  }

  void handleChange(html.Event event) {
    assert(isEnabled);

    final EditingState newEditingState = EditingState.fromDomElement(activeDomElement);

    if (newEditingState != lastEditingState) {
      lastEditingState = newEditingState;
      onChange!(lastEditingState);
    }
  }

  void maybeSendAction(html.Event event) {
    if (event is html.KeyboardEvent) {
      if (inputConfiguration.inputType.submitActionOnEnter &&
          event.keyCode == _kReturnKeyCode) {
        event.preventDefault();
        onAction!(inputConfiguration.inputAction);
      }
    }
  }

  /// Enables the element so it can be used to edit text.
  ///
  /// Register [callback] so that it gets invoked whenever any change occurs in
  /// the text editing element.
  ///
  /// Changes could be:
  /// - Text changes, or
  /// - Selection changes.
  void enable(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  }) {
    assert(!isEnabled);

    initializeTextEditing(inputConfig, onChange: onChange, onAction: onAction);

    addEventHandlers();

    if (lastEditingState != null) {
      setEditingState(lastEditingState);
    }

    // Re-focuses after setting editing state.
    activeDomElement.focus();
  }

  /// Prevent default behavior for mouse down, up and move.
  ///
  /// When normal mouse events are not prevented, in desktop browsers, mouse
  /// selection conflicts with selection sent from the framework, which creates
  /// flickering during selection by mouse.
  void preventDefaultForMouseEvents() {
    subscriptions.add(activeDomElement.onMouseDown.listen((_) {
      _.preventDefault();
    }));

    subscriptions.add(activeDomElement.onMouseUp.listen((_) {
      _.preventDefault();
    }));

    subscriptions.add(activeDomElement.onMouseMove.listen((_) {
      _.preventDefault();
    }));
  }
}

/// IOS/Safari behaviour for text editing.
///
/// In iOS, the virtual keyboard might shifts the screen up to make input
/// visible depending on the location of the focused input element.
///
/// Due to this [initializeElementPlacement] and [updateElementPlacement]
/// strategies are different.
///
/// [disable] is also different since the [_positionInputElementTimer]
/// also needs to be cleaned.
///
/// inputmodeAttribute needs to be set for mobile devices. Due to this
/// [initializeTextEditing] is different.
class IOSTextEditingStrategy extends GloballyPositionedTextEditingStrategy {
  IOSTextEditingStrategy(HybridTextEditing owner) : super(owner);

  /// Timer that times when to set the location of the input text.
  ///
  /// This is only used for iOS. In iOS, virtual keyboard shifts the screen.
  /// There is no callback to know if the keyboard is up and how much the screen
  /// has shifted. Therefore instead of listening to the shift and passing this
  /// information to Flutter Framework, we are trying to stop the shift.
  ///
  /// In iOS, the virtual keyboard shifts the screen up if the focused input
  /// element is under the keyboard or very close to the keyboard. Before the
  /// focus is called we are positioning it offscreen. The location of the input
  /// in iOS is set to correct place, 100ms after focus. We use this timer for
  /// timing this delay.
  Timer? _positionInputElementTimer;
  static const Duration _delayBeforePlacement = Duration(milliseconds: 100);

  /// Whether or not the input element can be positioned at this point in time.
  ///
  /// This is currently only used in iOS. It's set to false before focusing the
  /// input field, and set back to true after a short timer. We do this because
  /// if the input field is positioned before focus, it could be pushed to an
  /// incorrect position by the virtual keyboard.
  ///
  /// See:
  ///
  /// * [_delayBeforePlacement] which controls how long to wait before
  ///   positioning the input field.
  bool _canPosition = true;

  @override
  void initializeTextEditing(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  }) {
    super.initializeTextEditing(inputConfig,
        onChange: onChange, onAction: onAction);
    inputConfig.inputType.configureInputMode(activeDomElement);
    if (hasAutofillGroup) {
      placeForm();
    }
    inputConfig.textCapitalization.setAutocapitalizeAttribute(activeDomElement);
  }

  @override
  void initializeElementPlacement() {
    /// Position the element outside of the page before focusing on it. This is
    /// useful for not triggering a scroll when iOS virtual keyboard is
    /// coming up.
    activeDomElement.style.transform = 'translate(-9999px, -9999px)';

    _canPosition = false;
  }

  @override
  void addEventHandlers() {
    if (inputConfiguration.autofillGroup != null) {
      subscriptions
          .addAll(inputConfiguration.autofillGroup!.addInputEventListeners());
    }

    // Subscribe to text and selection changes.
    subscriptions.add(activeDomElement.onInput.listen(handleChange));

    subscriptions.add(activeDomElement.onKeyDown.listen(maybeSendAction));

    subscriptions.add(html.document.onSelectionChange.listen(handleChange));

    // Position the DOM element after it is focused.
    subscriptions.add(activeDomElement.onFocus.listen((_) {
      // Cancel previous timer if exists.
      _schedulePlacement();
    }));

    _addTapListener();

    // On iOS, blur is trigerred in the following cases:
    //
    // 1. The browser app is sent to the background (or the tab is changed). In
    //    this case, the window loses focus (see [windowHasFocus]),
    //    so we close the input connection with the framework.
    // 2. The user taps on another focusable element. In this case, we refocus
    //    the input field and wait for the framework to manage the focus change.
    // 3. The virtual keyboard is closed by tapping "done". We can't detect this
    //    programmatically, so we end up refocusing the input field. This is
    //    okay because the virtual keyboard will hide, and as soon as the user
    //    taps the text field again, the virtual keyboard will come up.
    subscriptions.add(activeDomElement.onBlur.listen((_) {
      if (windowHasFocus) {
        activeDomElement.focus();
      } else {
        owner.sendTextConnectionClosedToFrameworkIfAny();
      }
    }));
  }

  @override
  void updateElementPlacement(EditableTextGeometry textGeometry) {
    geometry = textGeometry;
    if (isEnabled && _canPosition) {
      placeElement();
    }
  }

  @override
  void disable() {
    super.disable();
    _positionInputElementTimer?.cancel();
    _positionInputElementTimer = null;
  }

  /// On iOS long press works differently than a single tap.
  ///
  /// On a normal tap the virtual keyboard comes up and users can enter text
  /// using the keyboard.
  ///
  /// The long press on the other hand focuses on the element without bringing
  /// up the virtual keyboard. It allows the users to modify the field by using
  /// copy/cut/select/paste etc.
  ///
  /// After a long press [domElement] is positioned to the correct place. If the
  /// user later single-tap on the [domElement] the virtual keyboard will come
  /// and might shift the page up.
  ///
  /// In order to prevent this shift, on a `click` event the position of the
  /// element is again set somewhere outside of the page and
  /// [_positionInputElementTimer] timer is restarted. The element will be
  /// placed to its correct position after [_delayBeforePlacement].
  void _addTapListener() {
    subscriptions.add(activeDomElement.onClick.listen((_) {
      // Check if the element is already positioned. If not this does not fall
      // under `The user was using the long press, now they want to enter text
      // via keyboard` journey.
      if (_canPosition) {
        // Re-place the element somewhere outside of the screen.
        initializeElementPlacement();

        // Re-configure the timer to place the element.
        _schedulePlacement();
      }
    }));
  }

  void _schedulePlacement() {
    _positionInputElementTimer?.cancel();
    _positionInputElementTimer = Timer(_delayBeforePlacement, () {
      _canPosition = true;
      placeElement();
    });
  }

  @override
  void placeElement() {
    activeDomElement.focus();
    geometry?.applyToDomElement(activeDomElement);
  }
}

/// Android behaviour for text editing.
///
/// inputmodeAttribute needs to be set for mobile devices. Due to this
/// [initializeTextEditing] is different.
///
/// Keyboard acts differently than other devices. [addEventHandlers] handles
/// this case as an extra.
class AndroidTextEditingStrategy extends GloballyPositionedTextEditingStrategy {
  AndroidTextEditingStrategy(HybridTextEditing owner) : super(owner);

  @override
  void initializeTextEditing(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  }) {
    super.initializeTextEditing(inputConfig,
        onChange: onChange, onAction: onAction);
    inputConfig.inputType.configureInputMode(activeDomElement);
    if (hasAutofillGroup) {
      placeForm();
    } else {
      defaultTextEditingRoot.append(activeDomElement);
    }
    inputConfig.textCapitalization.setAutocapitalizeAttribute(activeDomElement);
  }

  @override
  void addEventHandlers() {
    if (inputConfiguration.autofillGroup != null) {
      subscriptions
          .addAll(inputConfiguration.autofillGroup!.addInputEventListeners());
    }

    // Subscribe to text and selection changes.
    subscriptions.add(activeDomElement.onInput.listen(handleChange));

    subscriptions.add(activeDomElement.onKeyDown.listen(maybeSendAction));

    subscriptions.add(html.document.onSelectionChange.listen(handleChange));

    subscriptions.add(activeDomElement.onBlur.listen((_) {
      if (windowHasFocus) {
        // Chrome on Android will hide the onscreen keyboard when you tap outside
        // the text box. Instead, we want the framework to tell us to hide the
        // keyboard via `TextInput.clearClient` or `TextInput.hide`. Therefore
        // refocus as long as [windowHasFocus] is true.
        activeDomElement.focus();
      } else {
        owner.sendTextConnectionClosedToFrameworkIfAny();
      }
    }));
  }

  @override
  void placeElement() {
    activeDomElement.focus();
    geometry?.applyToDomElement(activeDomElement);
  }
}

/// Firefox behaviour for text editing.
///
/// Selections are different in Firefox. [addEventHandlers] strategy is
/// impelemented diefferently in Firefox.
class FirefoxTextEditingStrategy extends GloballyPositionedTextEditingStrategy {
  FirefoxTextEditingStrategy(HybridTextEditing owner) : super(owner);

  @override
  void initializeTextEditing(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  }) {
    super.initializeTextEditing(inputConfig,
        onChange: onChange, onAction: onAction);
    if (hasAutofillGroup) {
      placeForm();
    }
  }

  @override
  void addEventHandlers() {
    if (inputConfiguration.autofillGroup != null) {
      subscriptions
          .addAll(inputConfiguration.autofillGroup!.addInputEventListeners());
    }

    // Subscribe to text and selection changes.
    subscriptions.add(activeDomElement.onInput.listen(handleChange));

    subscriptions.add(activeDomElement.onKeyDown.listen(maybeSendAction));

    // Detects changes in text selection.
    //
    // In Firefox, when cursor moves, neither selectionChange nor onInput
    // events are triggered. We are listening to keyup event. Selection start,
    // end values are used to decide if the text cursor moved.
    //
    // Specific keycodes are not checked since users/applications can bind
    // their own keys to move the text cursor.
    // Decides if the selection has changed (cursor moved) compared to the
    // previous values.
    //
    // After each keyup, the start/end values of the selection is compared to
    // the previously saved editing state.
    subscriptions.add(activeDomElement.onKeyUp.listen((html.KeyboardEvent event) {
      handleChange(event);
    }));

    // In Firefox the context menu item "Select All" does not work without
    // listening to onSelect. On the other browsers onSelectionChange is
    // enough for covering "Select All" functionality.
    subscriptions.add(activeDomElement.onSelect.listen(handleChange));

    // Refocus on the activeDomElement after blur, so that user can keep editing the
    // text field.
    subscriptions.add(activeDomElement.onBlur.listen((_) {
      _postponeFocus();
    }));

    preventDefaultForMouseEvents();
  }

  void _postponeFocus() {
    // Firefox does not focus on the editing element if we call the focus
    // inside the blur event, therefore we postpone the focus.
    // Calling focus inside a Timer for `0` milliseconds guarantee that it is
    // called after blur event propagation is completed.
    Timer(const Duration(milliseconds: 0), () {
      activeDomElement.focus();
    });
  }

  @override
  void placeElement() {
    activeDomElement.focus();
    geometry?.applyToDomElement(activeDomElement);
    // Set the last editing state if it exists, this is critical for a
    // users ongoing work to continue uninterrupted when there is an update to
    // the transform.
    lastEditingState?.applyToDomElement(activeDomElement);
  }
}

/// Base class for all `TextInput` commands sent through the `flutter/textinput`
/// channel.
@immutable
abstract class TextInputCommand {
  const TextInputCommand();

  /// Executes the logic for this command.
  void run(HybridTextEditing textEditing);
}

/// Responds to the 'TextInput.setClient' message.
class TextInputSetClient extends TextInputCommand {
  const TextInputSetClient({
    required this.clientId,
    required this.configuration,
  });

  final int clientId;
  final InputConfiguration configuration;

  @override
  void run(HybridTextEditing textEditing) {
    final bool clientIdChanged = textEditing._clientId != null && textEditing._clientId != clientId;
    if (clientIdChanged && textEditing.isEditing) {
      // We're connecting a new client. Any pending command for the previous client
      // are irrelevant at this point.
      textEditing.stopEditing();
    }
    textEditing._clientId = clientId;
    textEditing.configuration = configuration;
  }
}

/// Creates the text editing strategy used in non-a11y mode.
DefaultTextEditingStrategy createDefaultTextEditingStrategy(HybridTextEditing textEditing) {
  DefaultTextEditingStrategy strategy;
  if (browserEngine == BrowserEngine.webkit &&
      operatingSystem == OperatingSystem.iOs) {
    strategy = IOSTextEditingStrategy(textEditing);
  } else if (browserEngine == BrowserEngine.webkit) {
    strategy = SafariDesktopTextEditingStrategy(textEditing);
  } else if (browserEngine == BrowserEngine.blink &&
      operatingSystem == OperatingSystem.android) {
    strategy = AndroidTextEditingStrategy(textEditing);
  } else if (browserEngine == BrowserEngine.firefox) {
    strategy = FirefoxTextEditingStrategy(textEditing);
  } else {
    strategy = GloballyPositionedTextEditingStrategy(textEditing);
  }
  return strategy;
}

/// Responds to the 'TextInput.updateConfig' message.
class TextInputUpdateConfig extends TextInputCommand {
  const TextInputUpdateConfig();

  @override
  void run(HybridTextEditing textEditing) {
    textEditing.strategy.applyConfiguration(textEditing.configuration!);
  }
}

/// Responds to the 'TextInput.setEditingState' message.
class TextInputSetEditingState extends TextInputCommand {
  const TextInputSetEditingState({
    required this.state,
  });

  final EditingState state;

  @override
  void run(HybridTextEditing textEditing) {
    textEditing.strategy.setEditingState(state);
  }
}

/// Responds to the 'TextInput.show' message.
class TextInputShow extends TextInputCommand {
  const TextInputShow();

  @override
  void run(HybridTextEditing textEditing) {
    if (!textEditing.isEditing) {
      textEditing._startEditing();
    }
  }
}

/// Responds to the 'TextInput.setEditableSizeAndTransform' message.
class TextInputSetEditableSizeAndTransform extends TextInputCommand {
  const TextInputSetEditableSizeAndTransform({
    required this.geometry,
  });

  final EditableTextGeometry geometry;

  @override
  void run(HybridTextEditing textEditing) {
    textEditing.strategy.updateElementPlacement(geometry);
  }
}

/// Responds to the 'TextInput.setStyle' message.
class TextInputSetStyle extends TextInputCommand {
  const TextInputSetStyle({
    required this.style,
  });

  final EditableTextStyle style;

  @override
  void run(HybridTextEditing textEditing) {
    textEditing.strategy.updateElementStyle(style);
  }
}

/// Responds to the 'TextInput.clearClient' message.
class TextInputClearClient extends TextInputCommand {
  const TextInputClearClient();

  @override
  void run(HybridTextEditing textEditing) {
    if (textEditing.isEditing) {
      textEditing.stopEditing();
    }
  }
}

/// Responds to the 'TextInput.hide' message.
class TextInputHide extends TextInputCommand {
  const TextInputHide();

  @override
  void run(HybridTextEditing textEditing) {
    if (textEditing.isEditing) {
      textEditing.stopEditing();
    }
  }
}

class TextInputSetMarkedTextRect extends TextInputCommand {
  const TextInputSetMarkedTextRect();

  @override
  void run(HybridTextEditing textEditing) {
    // No-op: this message is currently only used on iOS to implement
    // UITextInput.firstRecForRange.
  }
}

class TextInputSetCaretRect extends TextInputCommand {
  const TextInputSetCaretRect();

  @override
  void run(HybridTextEditing textEditing) {
    // No-op: not supported on this platform.
  }
}

class TextInputRequestAutofill extends TextInputCommand {
  const TextInputRequestAutofill();

  @override
  void run(HybridTextEditing textEditing) {
    // No-op: not supported on this platform.
  }
}

class TextInputFinishAutofillContext extends TextInputCommand {
  const TextInputFinishAutofillContext({
    required this.saveForm,
  });

  final bool saveForm;

  @override
  void run(HybridTextEditing textEditing) {
    // Close the text editing connection. Form is finalizing.
    textEditing.sendTextConnectionClosedToFrameworkIfAny();
    if (saveForm) {
      saveForms();
    }
    // Clean the forms from DOM after submitting them.
    cleanForms();
  }
}

/// Submits the forms currently attached to the DOM.
///
/// Browser will save the information entered to the form.
///
/// Called when the form is finalized with save option `true`.
/// See: https://github.com/flutter/flutter/blob/bf9f3a3dcfea3022f9cf2dfc3ab10b120b48b19d/packages/flutter/lib/src/services/text_input.dart#L1277
void saveForms() {
  formsOnTheDom.forEach((String identifier, html.FormElement form) {
    final html.InputElement submitBtn =
        form.getElementsByClassName('submitBtn').first as html.InputElement;
    submitBtn.click();
  });
}

/// Removes the forms from the DOM.
///
/// Called when the form is finalized.
void cleanForms() {
  for (final html.FormElement form in formsOnTheDom.values) {
    form.remove();
  }
  formsOnTheDom.clear();
}

/// Translates the message-based communication between the framework and the
/// engine [implementation].
///
/// This class is meant to be used as a singleton.
class TextEditingChannel {
  TextEditingChannel(this.implementation);

  /// Supplies the implementation that responds to the channel messages.
  final HybridTextEditing implementation;

  /// Handles "flutter/textinput" platform messages received from the framework.
  void handleTextInput(
      ByteData? data, ui.PlatformMessageResponseCallback? callback) {
    const JSONMethodCodec codec = JSONMethodCodec();
    final MethodCall call = codec.decodeMethodCall(data);
    final TextInputCommand command;
    switch (call.method) {
      case 'TextInput.setClient':
        command = TextInputSetClient(
          clientId: call.arguments[0] as int,
          configuration: InputConfiguration.fromFrameworkMessage(call.arguments[1] as Map<String, dynamic>),
        );
        break;

      case 'TextInput.updateConfig':
        // Set configuration eagerly because it contains data about the text
        // field used to flush the command queue. However, delaye applying the
        // configuration because the strategy may not be available yet.
        implementation.configuration = InputConfiguration.fromFrameworkMessage(
          call.arguments as Map<String, dynamic>
        );
        command = const TextInputUpdateConfig();
        break;

      case 'TextInput.setEditingState':
        command = TextInputSetEditingState(
          state: EditingState.fromFrameworkMessage(
            call.arguments as Map<String, dynamic>
          ),
        );
        break;

      case 'TextInput.show':
        command = const TextInputShow();
        break;

      case 'TextInput.setEditableSizeAndTransform':
        command = TextInputSetEditableSizeAndTransform(
          geometry: EditableTextGeometry.fromFrameworkMessage(
            call.arguments as Map<String, dynamic>
          ),
        );
        break;

      case 'TextInput.setStyle':
        command = TextInputSetStyle(
          style: EditableTextStyle.fromFrameworkMessage(
            call.arguments as Map<String, dynamic>,
          ),
        );
        break;

      case 'TextInput.clearClient':
        command = const TextInputClearClient();
        break;

      case 'TextInput.hide':
        command = const TextInputHide();
        break;

      case 'TextInput.requestAutofill':
        // There's no API to request autofill on the web. Instead we let the
        // browser show autofill options automatically, if available. We
        // therefore simply ignore this message.
        command = const TextInputRequestAutofill();
        break;

      case 'TextInput.finishAutofillContext':
        command = TextInputFinishAutofillContext(
          saveForm: call.arguments as bool,
        );
        break;

      case 'TextInput.setMarkedTextRect':
        command = const TextInputSetMarkedTextRect();
        break;

      case 'TextInput.setCaretRect':
        command = const TextInputSetCaretRect();
        break;

      default:
        EnginePlatformDispatcher.instance.replyToPlatformMessage(callback, null);
        return;
    }

    implementation.acceptCommand(command, () {
      EnginePlatformDispatcher.instance
          .replyToPlatformMessage(callback, codec.encodeSuccessEnvelope(true));
    });
  }

  /// Sends the 'TextInputClient.updateEditingState' message to the framework.
  void updateEditingState(int? clientId, EditingState? editingState) {
    EnginePlatformDispatcher.instance.invokeOnPlatformMessage(
      'flutter/textinput',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('TextInputClient.updateEditingState', <dynamic>[
          clientId,
          editingState!.toFlutter(),
        ]),
      ),
      _emptyCallback,
    );
  }

  /// Sends the 'TextInputClient.performAction' message to the framework.
  void performAction(int? clientId, String? inputAction) {
    EnginePlatformDispatcher.instance.invokeOnPlatformMessage(
      'flutter/textinput',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall(
          'TextInputClient.performAction',
          <dynamic>[clientId, inputAction],
        ),
      ),
      _emptyCallback,
    );
  }

  /// Sends the 'TextInputClient.onConnectionClosed' message to the framework.
  void onConnectionClosed(int? clientId) {
    EnginePlatformDispatcher.instance.invokeOnPlatformMessage(
      'flutter/textinput',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall(
          'TextInputClient.onConnectionClosed',
          <dynamic>[clientId],
        ),
      ),
      _emptyCallback,
    );
  }
}

/// Text editing singleton.
final HybridTextEditing textEditing = HybridTextEditing();

/// Map for storing forms left attached on the DOM.
///
/// Used for keeping the form elements on the DOM until user confirms to
/// save or cancel them.
///
/// See: https://github.com/flutter/flutter/blob/bf9f3a3dcfea3022f9cf2dfc3ab10b120b48b19d/packages/flutter/lib/src/services/text_input.dart#L1277
final Map<String, html.FormElement> formsOnTheDom =
    <String, html.FormElement>{};

/// Should be used as a singleton to provide support for text editing in
/// Flutter Web.
///
/// The approach is "hybrid" because it relies on Flutter for
/// displaying, and HTML for user interactions:
///
/// - HTML's contentEditable feature handles typing and text changes.
/// - HTML's selection API handles selection changes and cursor movements.
class HybridTextEditing {
  /// Private constructor so this class can be a singleton.
  ///
  /// The constructor also decides which text editing strategy to use depending
  /// on the operating system and browser engine.
  HybridTextEditing();

  late final TextEditingChannel channel = TextEditingChannel(this);

  /// A CSS class name used to identify all elements used for text editing.
  @visibleForTesting
  static const String textEditingClass = 'flt-text-editing';

  int? _clientId;

  /// Flag which shows if there is an ongoing editing.
  ///
  /// Also used to define if a keyboard is needed.
  bool isEditing = false;

  InputConfiguration? configuration;

  DefaultTextEditingStrategy? debugTextEditingStrategyOverride;

  /// Supplies the DOM element used for editing.
  late final DefaultTextEditingStrategy strategy =
    debugTextEditingStrategyOverride ??
    (EngineSemanticsOwner.instance.semanticsEnabled
      ? SemanticsTextEditingStrategy.ensureInitialized(this)
      : createDefaultTextEditingStrategy(this));

  void acceptCommand(TextInputCommand command, ui.VoidCallback callback) {
    if (_debugPrintTextInputCommands) {
      print('flutter/textinput channel command: ${command.runtimeType}');
    }
    command.run(this);
    callback();
  }

  void _startEditing() {
    assert(!isEditing);
    isEditing = true;
    strategy.enable(
      configuration!,
      onChange: (EditingState? editingState) {
        channel.updateEditingState(_clientId, editingState);
      },
      onAction: (String? inputAction) {
        channel.performAction(_clientId, inputAction);
      },
    );
  }

  void stopEditing() {
    assert(isEditing);
    isEditing = false;
    strategy.disable();
  }

  void sendTextConnectionClosedToFrameworkIfAny() {
    if (isEditing) {
      stopEditing();
      channel.onConnectionClosed(_clientId);
    }
  }
}

/// Information on the font and alignment of a text editing element.
///
/// This information is received via TextInput.setStyle message.
class EditableTextStyle {
  EditableTextStyle({
    required this.textDirection,
    required this.fontSize,
    required this.textAlign,
    required this.fontFamily,
    required this.fontWeight,
  });

  factory EditableTextStyle.fromFrameworkMessage(
      Map<String, dynamic> flutterStyle) {
    assert(flutterStyle.containsKey('fontSize'));
    assert(flutterStyle.containsKey('fontFamily'));
    assert(flutterStyle.containsKey('textAlignIndex'));
    assert(flutterStyle.containsKey('textDirectionIndex'));

    final int textAlignIndex = flutterStyle['textAlignIndex'] as int;
    final int textDirectionIndex = flutterStyle['textDirectionIndex'] as int;
    final int? fontWeightIndex = flutterStyle['fontWeightIndex'] as int?;

    // Convert [fontWeightIndex] to its CSS equivalent value.
    final String fontWeight = fontWeightIndex != null
        ? fontWeightIndexToCss(fontWeightIndex: fontWeightIndex)
        : 'normal';

    // Also convert [textAlignIndex] and [textDirectionIndex] to their
    // corresponding enum values in [ui.TextAlign] and [ui.TextDirection]
    // respectively.
    return EditableTextStyle(
      fontSize: flutterStyle.tryDouble('fontSize'),
      fontFamily: flutterStyle.tryString('fontFamily'),
      textAlign: ui.TextAlign.values[textAlignIndex],
      textDirection: ui.TextDirection.values[textDirectionIndex],
      fontWeight: fontWeight,
    );
  }

  /// This information will be used for changing the style of the hidden input
  /// element, which will match it's size to the size of the editable widget.
  final double? fontSize;
  final String fontWeight;
  final String? fontFamily;
  final ui.TextAlign textAlign;
  final ui.TextDirection textDirection;

  String? get align => textAlignToCssValue(textAlign, textDirection);

  String get cssFont =>
      '$fontWeight ${fontSize}px ${canonicalizeFontFamily(fontFamily)}';

  void applyToDomElement(html.HtmlElement domElement) {
    domElement.style
      ..textAlign = align
      ..font = cssFont;
  }
}

/// Describes the location and size of the editing element on the screen.
///
/// This information is received via "TextInput.setEditableSizeAndTransform"
/// message from the framework.
@immutable
class EditableTextGeometry {
  const EditableTextGeometry({
    required this.width,
    required this.height,
    required this.globalTransform,
  });

  /// Parses the geometry from a message sent by the framework.
  factory EditableTextGeometry.fromFrameworkMessage(
    Map<String, dynamic> encodedGeometry,
  ) {
    assert(encodedGeometry.containsKey('width'));
    assert(encodedGeometry.containsKey('height'));
    assert(encodedGeometry.containsKey('transform'));

    final List<double> transformList =
        List<double>.from(encodedGeometry.readList('transform'));
    return EditableTextGeometry(
      width: encodedGeometry.readDouble('width'),
      height: encodedGeometry.readDouble('height'),
      globalTransform: Float32List.fromList(transformList),
    );
  }

  /// The width of the editable in local coordinates, i.e. before applying [globalTransform].
  final double width;

  /// The height of the editable in local coordinates, i.e. before applying [globalTransform].
  final double height;

  /// The aggregate transform rooted at the global (screen) coordinate system
  /// that places and sizes the editable.
  ///
  /// For correct sizing this transform must be applied to the [width] and
  /// [height] fields.
  final Float32List globalTransform;

  /// Applies this geometry to the DOM element.
  ///
  /// This assumes that the parent of the [domElement] has identity transform
  /// applied to it (i.e. the default). If the parent has a non-identity
  /// transform applied, this method will misplace the [domElement]. For
  /// example, if the editable DOM element is nested inside the semantics
  /// tree the semantics tree provides the placement parameters, in which
  /// case this method should not be used.
  void applyToDomElement(html.HtmlElement domElement) {
    final String cssTransform = float64ListToCssTransform(globalTransform);
    domElement.style
      ..width = '${width}px'
      ..height = '${height}px'
      ..transform = cssTransform;
  }
}
