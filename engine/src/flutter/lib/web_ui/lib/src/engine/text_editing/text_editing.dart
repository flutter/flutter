// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// Make the content editable span visible to facilitate debugging.
bool _debugVisibleTextEditing = false;

/// The `keyCode` of the "Enter" key.
const int _kReturnKeyCode = 13;

/// Blink and Webkit engines, bring an overlay on top of the text field when it
/// is autofilled.
bool browserHasAutofillOverlay() =>
    browserEngine == BrowserEngine.blink ||
    browserEngine == BrowserEngine.webkit;

/// `transparentTextEditing` class is configured to make the autofill overlay
/// transparent.
const String transparentTextEditingClass = 'transparentTextEditing';

void _emptyCallback(dynamic _) {}

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
/// These values are to be used when autofill is enabled and there is a group of
/// text fields with more than one text field.
class EngineAutofillForm {
  EngineAutofillForm(
      {required this.formElement,
      this.elements,
      this.items,
      this.formIdentifier = ''});

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

  static EngineAutofillForm? fromFrameworkMessage(
    Map<String, dynamic>? focusedElementAutofill,
    List<dynamic>? fields,
  ) {
    // Autofill value can be null if focused text element does not have an
    // autofill hint set.
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
    formElement.addEventListener('submit', (e) {
      e.preventDefault();
    });

    _hideAutofillElements(formElement);

    // We keep the ids in a list then sort them later, in case the text fields'
    // locations are re-ordered on the framework side.
    final List<String> ids = List.empty(growable: true);

    // The focused text editing element will not be created here.
    final AutofillInfo focusedElement =
        AutofillInfo.fromFrameworkMessage(focusedElementAutofill);

    if (fields != null) {
      for (Map<String, dynamic> field in fields.cast<Map<String, dynamic>>()) {
        final Map<String, dynamic> autofillInfo = field['autofill'];
        final AutofillInfo autofill = AutofillInfo.fromFrameworkMessage(
            autofillInfo,
            textCapitalization: TextCapitalizationConfig.fromInputConfiguration(
                field['textCapitalization']));

        ids.add(autofill.uniqueIdentifier);

        if (autofill.uniqueIdentifier != focusedElement.uniqueIdentifier) {
          EngineInputType engineInputType =
              EngineInputType.fromName(field['inputType']['name']);

          html.HtmlElement htmlElement = engineInputType.createDomElement();
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

    // Add a seperator between element identifiers.
    for (final String id in ids) {
      if (idBuffer.length > 0) {
        idBuffer.write('*');
      }
      idBuffer.write(id);
    }

    final String formIdentifier = idBuffer.toString();

    // If a form with the same Autofill elements is already on the dom, remove
    // it from DOM.
    html.FormElement? form = formsOnTheDom[formIdentifier];
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
    domRenderer.glassPaneElement!.append(formElement);
  }

  void storeForm() {
    formsOnTheDom[formIdentifier] = this.formElement;
    _hideAutofillElements(formElement, isOffScreen: true);
  }

  /// Listens to `onInput` event on the form fields.
  ///
  /// Registering to the listeners could have been done in the constructor.
  /// On the other hand, overall for text editing there is already a lifecycle
  /// for subscriptions: All the subscriptions of the DOM elements are to the
  /// `_subscriptions` property of [DefaultTextEditingStrategy].
  /// [TextEditingStrategy] manages all subscription lifecyle. All
  /// listeners with no exceptions are added during
  /// [TextEditingStrategy.addEventHandlers] method call and all
  /// listeners are removed during [TextEditingStrategy.disable] method call.
  List<StreamSubscription<html.Event>> addInputEventListeners() {
    Iterable<String> keys = elements!.keys;
    List<StreamSubscription<html.Event>> subscriptions =
        <StreamSubscription<html.Event>>[];
    keys.forEach((String key) {
      final html.Element element = elements![key]!;
      subscriptions.add(element.onInput.listen((html.Event e) {
        if (items![key] == null) {
          throw StateError(
              'Autofill would not work withuot Autofill value set');
        } else {
          final AutofillInfo autofillInfo = items![key]!;
          _handleChange(element, autofillInfo);
        }
      }));
    });
    return subscriptions;
  }

  void _handleChange(html.Element domElement, AutofillInfo autofillInfo) {
    EditingState newEditingState = EditingState.fromDomElement(
        domElement as html.HtmlElement?,
        textCapitalization: autofillInfo.textCapitalization);

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
  AutofillInfo(
      {required this.editingState,
      required this.uniqueIdentifier,
      required this.hint,
      required this.textCapitalization});

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
  /// [DefaultTextEditingStrategy._inputConfiguration] already has this
  /// information.
  ///
  /// On the other hand for the multi element forms, for the input elements
  /// other the focused field, we need to use this information.
  final TextCapitalizationConfig textCapitalization;

  /// Attribute used for autofill.
  ///
  /// Used as a guidance to the browser as to the type of information expected
  /// in the field.
  /// See: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete
  final String hint;

  factory AutofillInfo.fromFrameworkMessage(Map<String, dynamic> autofill,
      {TextCapitalizationConfig textCapitalization =
          const TextCapitalizationConfig.defaultCapitalization()}) {
    assert(autofill != null); // ignore: unnecessary_null_comparison
    final String uniqueIdentifier = autofill['uniqueIdentifier']!;
    final List<dynamic> hintsList = autofill['hints'];
    final EditingState editingState =
        EditingState.fromFrameworkMessage(autofill['editingValue']);
    return AutofillInfo(
        uniqueIdentifier: uniqueIdentifier,
        hint: BrowserAutofillHints.instance.flutterToEngine(hintsList[0]),
        editingState: editingState,
        textCapitalization: textCapitalization);
  }

  void applyToDomElement(html.HtmlElement domElement,
      {bool focusedElement = false}) {
    domElement.id = hint;
    if (domElement is html.InputElement) {
      html.InputElement element = domElement;
      element.name = hint;
      element.id = hint;
      element.autocomplete = hint;
      if (hint.contains('password')) {
        element.type = 'password';
      } else {
        element.type = 'text';
      }
    } else if (domElement is html.TextAreaElement) {
      html.TextAreaElement element = domElement;
      element.name = hint;
      element.id = hint;
      element.setAttribute('autocomplete', hint);
    }
  }
}

/// The current text and selection state of a text field.
@visibleForTesting
class EditingState {
  EditingState({this.text, this.baseOffset = 0, this.extentOffset = 0});

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
    final int selectionBase = flutterEditingState['selectionBase'];
    final int selectionExtent = flutterEditingState['selectionExtent'];
    final String? text = flutterEditingState['text'];

    return EditingState(
        text: text,
        baseOffset: math.max(0, selectionBase),
        extentOffset: math.max(0, selectionExtent));
  }

  /// Creates an [EditingState] instance using values from the editing element
  /// in the DOM.
  ///
  /// [domElement] can be a [InputElement] or a [TextAreaElement] depending on
  /// the [InputType] of the text field.
  factory EditingState.fromDomElement(html.HtmlElement? domElement,
      {TextCapitalizationConfig textCapitalization =
          const TextCapitalizationConfig.defaultCapitalization()}) {
    if (domElement is html.InputElement) {
      html.InputElement element = domElement;
      return EditingState(
          text: element.value,
          baseOffset: element.selectionStart,
          extentOffset: element.selectionEnd);
    } else if (domElement is html.TextAreaElement) {
      html.TextAreaElement element = domElement;
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
  void applyToDomElement(html.HtmlElement? domElement) {
    if (domElement is html.InputElement) {
      html.InputElement element = domElement;
      element.value = text;
      element.setSelectionRange(baseOffset!, extentOffset!);
    } else if (domElement is html.TextAreaElement) {
      html.TextAreaElement element = domElement;
      element.value = text;
      element.setSelectionRange(baseOffset!, extentOffset!);
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
          flutterInputConfiguration['inputType']['name'],
          isDecimal: flutterInputConfiguration['inputType']['decimal'] ?? false,
        ),
        inputAction =
            flutterInputConfiguration['inputAction'] ?? 'TextInputAction.done',
        obscureText = flutterInputConfiguration['obscureText'] ?? false,
        readOnly = flutterInputConfiguration['readOnly'] ?? false,
        autocorrect = flutterInputConfiguration['autocorrect'] ?? true,
        textCapitalization = TextCapitalizationConfig.fromInputConfiguration(
          flutterInputConfiguration['textCapitalization'],
        ),
        autofill = flutterInputConfiguration.containsKey('autofill')
            ? AutofillInfo.fromFrameworkMessage(
                flutterInputConfiguration['autofill'])
            : null,
        autofillGroup = EngineAutofillForm.fromFrameworkMessage(
            flutterInputConfiguration['autofill'],
            flutterInputConfiguration['fields']);

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

typedef _OnChangeCallback = void Function(EditingState? editingState);
typedef _OnActionCallback = void Function(String? inputAction);

/// Provides HTML DOM functionality for editable text.
///
/// A concrete implementation is picked at runtime based on the current
/// operating system, web browser, and accessibility mode.
abstract class TextEditingStrategy {
  void initializeTextEditing(
    InputConfiguration inputConfig, {
    required _OnChangeCallback onChange,
    required _OnActionCallback onAction,
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
    if (hasAutofillGroup) {
      _geometry?.applyToDomElement(focusedFormElement!);
      placeForm();
      // Set the last editing state if it exists, this is critical for a
      // users ongoing work to continue uninterrupted when there is an update to
      // the transform.
      if (_lastEditingState != null) {
        _lastEditingState!.applyToDomElement(domElement);
      }
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
      domElement.focus();
    } else {
      _geometry?.applyToDomElement(domElement);
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
    _geometry?.applyToDomElement(domElement);
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
      domElement.focus();
      if (_lastEditingState != null) {
        _lastEditingState!.applyToDomElement(domElement);
      }
    }
  }

  @override
  void initializeElementPlacement() {
    domElement.focus();
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

  @visibleForTesting
  bool isEnabled = false;

  html.HtmlElement get domElement => _domElement!;
  set domElement(html.HtmlElement element) {
    _domElement = element;
  }

  html.HtmlElement? _domElement;

  late InputConfiguration _inputConfiguration;
  EditingState? _lastEditingState;

  /// Styles associated with the editable text.
  EditableTextStyle? _style;

  /// Size and transform of the editable text on the page.
  EditableTextGeometry? _geometry;

  _OnChangeCallback? _onChange;
  _OnActionCallback? _onAction;

  final List<StreamSubscription<html.Event>> _subscriptions =
      <StreamSubscription<html.Event>>[];

  bool get hasAutofillGroup => _inputConfiguration.autofillGroup != null;

  /// Whether the focused input element is part of a form.
  bool get appendedToForm => _appendedToForm;
  bool _appendedToForm = false;

  html.FormElement? get focusedFormElement =>
      _inputConfiguration.autofillGroup?.formElement;

  @override
  void initializeTextEditing(
    InputConfiguration inputConfig, {
    required _OnChangeCallback onChange,
    required _OnActionCallback onAction,
  }) {
    assert(!isEnabled);

    _domElement = inputConfig.inputType.createDomElement();
    _applyConfiguration(inputConfig);

    _setStaticStyleAttributes(domElement);
    _style?.applyToDomElement(domElement);

    if (!hasAutofillGroup) {
      // If there is an Autofill Group the `FormElement`, it will be appended to the
      // DOM later, when the first location information arrived.
      // Otherwise, on Blink based Desktop browsers, the autofill menu appears
      // on top left of the screen.
      domRenderer.glassPaneElement!.append(domElement);
      _appendedToForm = false;
    }

    initializeElementPlacement();

    isEnabled = true;
    _onChange = onChange;
    _onAction = onAction;
  }

  void _applyConfiguration(InputConfiguration config) {
    _inputConfiguration = config;

    if (config.readOnly) {
      domElement.setAttribute('readonly', 'readonly');
    } else {
      domElement.removeAttribute('readonly');
    }

    if (config.obscureText) {
      domElement.setAttribute('type', 'password');
    }

    config.autofill?.applyToDomElement(domElement, focusedElement: true);

    final String autocorrectValue = config.autocorrect ? 'on' : 'off';
    domElement.setAttribute('autocorrect', autocorrectValue);
  }

  @override
  void initializeElementPlacement() {
    placeElement();
  }

  @override
  void addEventHandlers() {
    if (_inputConfiguration.autofillGroup != null) {
      _subscriptions
          .addAll(_inputConfiguration.autofillGroup!.addInputEventListeners());
    }

    // Subscribe to text and selection changes.
    _subscriptions.add(domElement.onInput.listen(_handleChange));

    _subscriptions.add(domElement.onKeyDown.listen(_maybeSendAction));

    _subscriptions.add(html.document.onSelectionChange.listen(_handleChange));

    // Refocus on the domElement after blur, so that user can keep editing the
    // text field.
    _subscriptions.add(domElement.onBlur.listen((_) {
      domElement.focus();
    }));

    preventDefaultForMouseEvents();
  }

  @override
  void updateElementPlacement(EditableTextGeometry geometry) {
    _geometry = geometry;
    if (isEnabled) {
      placeElement();
    }
  }

  @mustCallSuper
  @override
  void updateElementStyle(EditableTextStyle style) {
    _style = style;
    if (isEnabled) {
      _style!.applyToDomElement(domElement);
    }
  }

  @override
  void disable() {
    assert(isEnabled);

    isEnabled = false;
    _lastEditingState = null;
    _style = null;
    _geometry = null;

    for (int i = 0; i < _subscriptions.length; i++) {
      _subscriptions[i].cancel();
    }
    _subscriptions.clear();
    // If focused element is a part of a form, it needs to stay on the DOM
    // until the autofill context of the form is finalized.
    // More details on `TextInput.finishAutofillContext` call.
    if (_appendedToForm &&
        _inputConfiguration.autofillGroup?.formElement != null) {
      // Subscriptions are removed, listeners won't be triggered.
      domElement.blur();
      _hideAutofillElements(domElement, isOffScreen: true);
      _inputConfiguration.autofillGroup?.storeForm();
    } else {
      domElement.remove();
    }
    _domElement = null;
  }

  @mustCallSuper
  @override
  void setEditingState(EditingState? editingState) {
    _lastEditingState = editingState;
    if (!isEnabled || !editingState!.isValid) {
      return;
    }
    _lastEditingState!.applyToDomElement(domElement);
  }

  void placeElement() {
    domElement.focus();
  }

  void placeForm() {
    _inputConfiguration.autofillGroup!.placeForm(domElement);
    _appendedToForm = true;
  }

  void _handleChange(html.Event event) {
    assert(isEnabled);

    EditingState newEditingState = EditingState.fromDomElement(domElement,
        textCapitalization: _inputConfiguration.textCapitalization);

    if (newEditingState != _lastEditingState) {
      _lastEditingState = newEditingState;
      _onChange!(_lastEditingState);
    }
  }

  void _maybeSendAction(html.Event event) {
    if (event is html.KeyboardEvent) {
      if (_inputConfiguration.inputType.submitActionOnEnter &&
          event.keyCode == _kReturnKeyCode) {
        event.preventDefault();
        _onAction!(_inputConfiguration.inputAction);
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
    required _OnChangeCallback onChange,
    required _OnActionCallback onAction,
  }) {
    assert(!isEnabled);

    initializeTextEditing(inputConfig, onChange: onChange, onAction: onAction);

    addEventHandlers();

    if (_lastEditingState != null) {
      setEditingState(this._lastEditingState);
    }

    // Re-focuses after setting editing state.
    domElement.focus();
  }

  /// Prevent default behavior for mouse down, up and move.
  ///
  /// When normal mouse events are not prevented, in desktop browsers, mouse
  /// selection conflicts with selection sent from the framework, which creates
  /// flickering during selection by mouse.
  void preventDefaultForMouseEvents() {
    _subscriptions.add(domElement.onMouseDown.listen((_) {
      _.preventDefault();
    }));

    _subscriptions.add(domElement.onMouseUp.listen((_) {
      _.preventDefault();
    }));

    _subscriptions.add(domElement.onMouseMove.listen((_) {
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
  static const Duration _delayBeforePlacement =
      const Duration(milliseconds: 100);

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
    required _OnChangeCallback onChange,
    required _OnActionCallback onAction,
  }) {
    super.initializeTextEditing(inputConfig,
        onChange: onChange, onAction: onAction);
    inputConfig.inputType.configureInputMode(domElement);
    if (hasAutofillGroup) {
      placeForm();
    }
    inputConfig.textCapitalization.setAutocapitalizeAttribute(domElement);
  }

  @override
  void initializeElementPlacement() {
    /// Position the element outside of the page before focusing on it. This is
    /// useful for not triggering a scroll when iOS virtual keyboard is
    /// coming up.
    domElement.style.transform = 'translate(-9999px, -9999px)';

    _canPosition = false;
  }

  @override
  void addEventHandlers() {
    if (_inputConfiguration.autofillGroup != null) {
      _subscriptions
          .addAll(_inputConfiguration.autofillGroup!.addInputEventListeners());
    }

    // Subscribe to text and selection changes.
    _subscriptions.add(domElement.onInput.listen(_handleChange));

    _subscriptions.add(domElement.onKeyDown.listen(_maybeSendAction));

    _subscriptions.add(html.document.onSelectionChange.listen(_handleChange));

    // Position the DOM element after it is focused.
    _subscriptions.add(domElement.onFocus.listen((_) {
      // Cancel previous timer if exists.
      _schedulePlacement();
    }));

    _addTapListener();

    // On iOS, blur is trigerred if the virtual keyboard is closed or the
    // browser is sent to background or the browser tab is changed.
    //
    // Since in all these cases, the connection needs to be closed,
    // [domRenderer.windowHasFocus] is not checked in [IOSTextEditingStrategy].
    _subscriptions.add(domElement.onBlur.listen((_) {
      owner.sendTextConnectionClosedToFrameworkIfAny();
    }));
  }

  @override
  void updateElementPlacement(EditableTextGeometry geometry) {
    _geometry = geometry;
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
    _subscriptions.add(domElement.onClick.listen((_) {
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
    domElement.focus();
    _geometry?.applyToDomElement(domElement);
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
    required _OnChangeCallback onChange,
    required _OnActionCallback onAction,
  }) {
    super.initializeTextEditing(inputConfig,
        onChange: onChange, onAction: onAction);
    inputConfig.inputType.configureInputMode(domElement);
    if (hasAutofillGroup) {
      placeForm();
    } else {
      domRenderer.glassPaneElement!.append(domElement);
    }
    inputConfig.textCapitalization.setAutocapitalizeAttribute(domElement);
  }

  @override
  void addEventHandlers() {
    if (_inputConfiguration.autofillGroup != null) {
      _subscriptions
          .addAll(_inputConfiguration.autofillGroup!.addInputEventListeners());
    }

    // Subscribe to text and selection changes.
    _subscriptions.add(domElement.onInput.listen(_handleChange));

    _subscriptions.add(domElement.onKeyDown.listen(_maybeSendAction));

    _subscriptions.add(html.document.onSelectionChange.listen(_handleChange));

    _subscriptions.add(domElement.onBlur.listen((_) {
      if (domRenderer.windowHasFocus!) {
        // Chrome on Android will hide the onscreen keyboard when you tap outside
        // the text box. Instead, we want the framework to tell us to hide the
        // keyboard via `TextInput.clearClient` or `TextInput.hide`. Therefore
        // refocus as long as [domRenderer.windowHasFocus] is true.
        domElement.focus();
      } else {
        owner.sendTextConnectionClosedToFrameworkIfAny();
      }
    }));
  }

  @override
  void placeElement() {
    domElement.focus();
    _geometry?.applyToDomElement(domElement);
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
    required _OnChangeCallback onChange,
    required _OnActionCallback onAction,
  }) {
    super.initializeTextEditing(inputConfig,
        onChange: onChange, onAction: onAction);
    if (hasAutofillGroup) {
      placeForm();
    }
  }

  @override
  void addEventHandlers() {
    if (_inputConfiguration.autofillGroup != null) {
      _subscriptions
          .addAll(_inputConfiguration.autofillGroup!.addInputEventListeners());
    }

    // Subscribe to text and selection changes.
    _subscriptions.add(domElement.onInput.listen(_handleChange));

    _subscriptions.add(domElement.onKeyDown.listen(_maybeSendAction));

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
    _subscriptions.add(domElement.onKeyUp.listen((event) {
      _handleChange(event);
    }));

    // In Firefox the context menu item "Select All" does not work without
    // listening to onSelect. On the other browsers onSelectionChange is
    // enough for covering "Select All" functionality.
    _subscriptions.add(domElement.onSelect.listen(_handleChange));

    // Refocus on the domElement after blur, so that user can keep editing the
    // text field.
    _subscriptions.add(domElement.onBlur.listen((_) {
      domElement.focus();
    }));

    preventDefaultForMouseEvents();
  }

  @override
  void placeElement() {
    domElement.focus();
    _geometry?.applyToDomElement(domElement);
    // Set the last editing state if it exists, this is critical for a
    // users ongoing work to continue uninterrupted when there is an update to
    // the transform.
    if (_lastEditingState != null) {
      _lastEditingState!.applyToDomElement(domElement);
    }
  }
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
    switch (call.method) {
      case 'TextInput.setClient':
        implementation.setClient(
          call.arguments[0],
          InputConfiguration.fromFrameworkMessage(call.arguments[1]),
        );
        break;

      case 'TextInput.updateConfig':
        final config = InputConfiguration.fromFrameworkMessage(call.arguments);
        implementation.updateConfig(config);
        break;

      case 'TextInput.setEditingState':
        implementation
            .setEditingState(EditingState.fromFrameworkMessage(call.arguments));
        break;

      case 'TextInput.show':
        implementation.show();
        break;

      case 'TextInput.setEditableSizeAndTransform':
        implementation.setEditableSizeAndTransform(
            EditableTextGeometry.fromFrameworkMessage(call.arguments));
        break;

      case 'TextInput.setStyle':
        implementation
            .setStyle(EditableTextStyle.fromFrameworkMessage(call.arguments));
        break;

      case 'TextInput.clearClient':
        implementation.clearClient();
        break;

      case 'TextInput.hide':
        implementation.hide();
        break;

      case 'TextInput.requestAutofill':
        // No-op:  This message is sent by the framework to requests the platform autofill UI to appear.
        // Since autofill UI is a part of the browser, web engine does not need to utilize this method.
        break;

      case 'TextInput.finishAutofillContext':
        final bool saveForm = call.arguments as bool;
        // Close the text editing connection. Form is finalizing.
        implementation.sendTextConnectionClosedToFrameworkIfAny();
        if (saveForm) {
          saveForms();
        }
        // Clean the forms from DOM after submitting them.
        cleanForms();
        break;

      case 'TextInput.setMarkedTextRect':
        // No-op: this message is currently only used on iOS to implement
        // UITextInput.firstRecForRange.
        break;

      default:
        throw StateError(
            'Unsupported method call on the flutter/textinput channel: ${call.method}');
    }
    EnginePlatformDispatcher.instance
        ._replyToPlatformMessage(callback, codec.encodeSuccessEnvelope(true));
  }

  /// Used for submitting the forms attached on the DOM.
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

  /// Used for removing the forms on the DOM.
  ///
  /// Called when the form is finalized.
  void cleanForms() {
    for (html.FormElement form in formsOnTheDom.values) {
      form.remove();
    }
    formsOnTheDom.clear();
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
    Map<String, html.FormElement>();

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
  HybridTextEditing() {
    if (browserEngine == BrowserEngine.webkit &&
        operatingSystem == OperatingSystem.iOs) {
      this._defaultEditingElement = IOSTextEditingStrategy(this);
    } else if (browserEngine == BrowserEngine.webkit) {
      this._defaultEditingElement = SafariDesktopTextEditingStrategy(this);
    } else if (browserEngine == BrowserEngine.blink &&
        operatingSystem == OperatingSystem.android) {
      this._defaultEditingElement = AndroidTextEditingStrategy(this);
    } else if (browserEngine == BrowserEngine.firefox) {
      this._defaultEditingElement = FirefoxTextEditingStrategy(this);
    } else {
      this._defaultEditingElement = GloballyPositionedTextEditingStrategy(this);
    }
    channel = TextEditingChannel(this);
  }

  late TextEditingChannel channel;

  /// The text editing stategy used. It can change depending on the
  /// formfactor/browser.
  ///
  /// It uses an HTML element to manage editing state when a custom element is
  /// not provided via [useCustomEditableElement]
  late final DefaultTextEditingStrategy _defaultEditingElement;

  /// The HTML element used to manage editing state.
  ///
  /// This field is populated using [useCustomEditableElement]. If `null` the
  /// [_defaultEditingElement] is used instead.
  DefaultTextEditingStrategy? _customEditingElement;

  DefaultTextEditingStrategy get editingElement {
    return _customEditingElement ?? _defaultEditingElement;
  }

  /// Responds to the 'TextInput.setClient' message.
  void setClient(int? clientId, InputConfiguration configuration) {
    final bool clientIdChanged = _clientId != null && _clientId != clientId;
    if (clientIdChanged && isEditing) {
      stopEditing();
    }
    _clientId = clientId;
    _configuration = configuration;
  }

  void updateConfig(InputConfiguration configuration) {
    _configuration = configuration;
    editingElement._applyConfiguration(_configuration);
  }

  /// Responds to the 'TextInput.setEditingState' message.
  void setEditingState(EditingState state) {
    editingElement.setEditingState(state);
  }

  /// Responds to the 'TextInput.show' message.
  void show() {
    if (!isEditing) {
      _startEditing();
    }
  }

  /// Responds to the 'TextInput.setEditableSizeAndTransform' message.
  void setEditableSizeAndTransform(EditableTextGeometry geometry) {
    editingElement.updateElementPlacement(geometry);
  }

  /// Responds to the 'TextInput.setStyle' message.
  void setStyle(EditableTextStyle style) {
    editingElement.updateElementStyle(style);
  }

  /// Responds to the 'TextInput.clearClient' message.
  void clearClient() {
    // We do not distinguish between "clearClient" and "hide" on the Web.
    hide();
  }

  /// Responds to the 'TextInput.hide' message.
  void hide() {
    if (isEditing) {
      stopEditing();
    }
  }

  /// A CSS class name used to identify all elements used for text editing.
  @visibleForTesting
  static const String textEditingClass = 'flt-text-editing';

  static bool isEditingElement(html.Element element) {
    return element.classes.contains(textEditingClass);
  }

  /// Requests that [customEditingElement] is used for managing text editing state
  /// instead of the hidden default element.
  ///
  /// Use [stopUsingCustomEditableElement] to switch back to default element.
  void useCustomEditableElement(
      DefaultTextEditingStrategy? customEditingElement) {
    if (isEditing && customEditingElement != _customEditingElement) {
      stopEditing();
    }
    _customEditingElement = customEditingElement;
  }

  /// Switches back to using the built-in default element for managing text
  /// editing state.
  void stopUsingCustomEditableElement() {
    useCustomEditableElement(null);
  }

  int? _clientId;

  /// Flag which shows if there is an ongoing editing.
  ///
  /// Also used to define if a keyboard is needed.
  @visibleForTesting
  bool isEditing = false;

  late InputConfiguration _configuration;

  void _startEditing() {
    assert(!isEditing);
    isEditing = true;
    editingElement.enable(
      _configuration,
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
    editingElement.disable();
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

    final int textAlignIndex = flutterStyle['textAlignIndex'];
    final int textDirectionIndex = flutterStyle['textDirectionIndex'];
    final int? fontWeightIndex = flutterStyle['fontWeightIndex'];

    // Convert [fontWeightIndex] to its CSS equivalent value.
    final String fontWeight = fontWeightIndex != null
        ? fontWeightIndexToCss(fontWeightIndex: fontWeightIndex)
        : 'normal';

    // Also convert [textAlignIndex] and [textDirectionIndex] to their
    // corresponding enum values in [ui.TextAlign] and [ui.TextDirection]
    // respectively.
    return EditableTextStyle(
      fontSize: flutterStyle['fontSize'],
      fontFamily: flutterStyle['fontFamily'],
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
      '${fontWeight} ${fontSize}px ${canonicalizeFontFamily(fontFamily)}';

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
  EditableTextGeometry({
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
        List<double>.from(encodedGeometry['transform']);
    return EditableTextGeometry(
      width: encodedGeometry['width'],
      height: encodedGeometry['height'],
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
