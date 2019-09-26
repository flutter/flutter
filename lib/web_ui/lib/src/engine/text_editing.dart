// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// Make the content editable span visible to facilitate debugging.
const bool _debugVisibleTextEditing = false;

void _emptyCallback(dynamic _) {}

/// These style attributes are constant throughout the life time of an input
/// element.
///
/// They are assigned once during the creation of the dom element.
void _setStaticStyleAttributes(html.HtmlElement domElement) {
  final html.CssStyleDeclaration elementStyle = domElement.style;
  elementStyle
    ..whiteSpace = 'pre'
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
    ..transformOrigin = '0 0 0';

  /// This property makes the input's blinking cursor transparent.
  elementStyle.setProperty('caret-color', 'transparent');

  if (_debugVisibleTextEditing) {
    elementStyle
      ..color = 'purple'
      ..outline = '1px solid purple';
  }
}

/// The current text and selection state of a text field.
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
  EditingState.fromFlutter(Map<String, dynamic> flutterEditingState)
      : text = flutterEditingState['text'],
        baseOffset = flutterEditingState['selectionBase'],
        extentOffset = flutterEditingState['selectionExtent'];

  /// The counterpart of [EditingState.fromFlutter]. It generates a Map that
  /// can be sent to Flutter.
  // TODO(mdebbar): Should we get `selectionAffinity` and other properties from flutter's editing state?
  Map<String, dynamic> toFlutter() => <String, dynamic>{
        'text': text,
        'selectionBase': baseOffset,
        'selectionExtent': extentOffset,
      };

  /// The current text being edited.
  final String text;

  /// The offset at which the text selection originates.
  final int baseOffset;

  /// The offset at which the text selection terminates.
  final int extentOffset;

  /// Whether the current editing state is valid or not.
  bool get isValid => baseOffset >= 0 && extentOffset >= 0;

  @override
  int get hashCode => ui.hashValues(text, baseOffset, extentOffset);

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    final EditingState typedOther = other;
    return text == typedOther.text &&
        baseOffset == typedOther.baseOffset &&
        extentOffset == typedOther.extentOffset;
  }

  @override
  String toString() {
    return assertionsEnabled
        ? 'EditingState("$text", base:$baseOffset, extent:$extentOffset)'
        : super.toString();
  }
}

/// Various types of inputs used in text fields.
///
/// These types are coming from Flutter's [TextInputType]. Currently, we don't
/// support all the types. We fallback to [InputType.text] when Flutter sends
/// a type that isn't supported.
// TODO(flutter_web): Support more types.
enum InputType {
  /// Single-line plain text.
  text,

  /// Multi-line text.
  multiline,
}

InputType _getInputTypeFromString(String inputType) {
  switch (inputType) {
    case 'TextInputType.multiline':
      return InputType.multiline;

    case 'TextInputType.text':
    default:
      return InputType.text;
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
    this.inputType,
    this.obscureText = false,
  });

  InputConfiguration.fromFlutter(Map<String, dynamic> flutterInputConfiguration)
      : inputType = _getInputTypeFromString(
            flutterInputConfiguration['inputType']['name']),
        obscureText = flutterInputConfiguration['obscureText'];

  /// The type of information being edited in the input control.
  final InputType inputType;

  /// Whether to hide the text being edited.
  final bool obscureText;
}

typedef _OnChangeCallback = void Function(EditingState editingState);

enum ElementType {
  /// The backing element is an `<input>`.
  input,

  /// The backing element is a `<textarea>`.
  textarea,

  /// The backing element is a `<span contenteditable="true">`.
  contentEditable,
}

ElementType _getTypeFromElement(html.HtmlElement domElement) {
  if (domElement is html.InputElement) {
    return ElementType.input;
  }
  if (domElement is html.TextAreaElement) {
    return ElementType.textarea;
  }
  final String contentEditable = domElement.contentEditable;
  if (contentEditable != null &&
      contentEditable.isNotEmpty &&
      contentEditable != 'inherit') {
    return ElementType.contentEditable;
  }
  return null;
}

/// Wraps the DOM element used to provide text editing capabilities.
///
/// The backing DOM element could be one of:
///
/// 1. `<input>`.
/// 2. `<textarea>`.
/// 3. `<span contenteditable="true">`.
class TextEditingElement {
  /// Creates a non-persistent [TextEditingElement].
  ///
  /// See [TextEditingElement.persistent] to understand what persistent mode is.
  TextEditingElement(this.owner);

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
  Timer _positionInputElementTimer;
  static const Duration _delayBeforePositioning =
      const Duration(milliseconds: 100);

  final HybridTextEditing owner;
  bool _enabled = false;

  html.HtmlElement domElement;
  EditingState _lastEditingState;
  _OnChangeCallback _onChange;

  SelectionChangeDetection _selectionDetection;

  final List<StreamSubscription<html.Event>> _subscriptions =
      <StreamSubscription<html.Event>>[];

  ElementType get _elementType {
    final ElementType type = _getTypeFromElement(domElement);
    assert(type != null);
    return type;
  }

  /// On iOS, sets the location of the input element after focusing on it.
  ///
  /// On iOS, keyboard causes scrolling in the UI. This scrolling does not
  /// trigger an event. In order not to trigger a shift on the page, it is
  /// important we set it's final location after focusing on it (after keyboard
  /// is up).
  ///
  /// This method is called after a delay.
  /// See [_positionInputElementTimer].
  void configureInputElementForIOS() {
    if (browserEngine != BrowserEngine.webkit ||
        operatingSystem != OperatingSystem.iOs) {
      // Only relevant on Safari-based on iOS.
      return;
    }

    if (domElement != null) {
      owner.setStyle(domElement);
      owner.inputPositioned = true;
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
    @required _OnChangeCallback onChange,
  }) {
    assert(!_enabled);

    _initDomElement(inputConfig);
    _enabled = true;
    _selectionDetection = SelectionChangeDetection(domElement);
    _onChange = onChange;

    // Chrome on Android will hide the onscreen keyboard when you tap outside
    // the text box. Instead, we want the framework to tell us to hide the
    // keyboard via `TextInput.clearClient` or `TextInput.hide`.
    //
    // Safari on iOS does not hide the keyboard as a side-effect of tapping
    // outside the editable box. Instead it provides an explicit "done" button,
    // which is reported as "blur", so we must not reacquire focus when we see
    // a "blur" event and let the keyboard disappear.
    if (browserEngine == BrowserEngine.blink ||
        browserEngine == BrowserEngine.unknown) {
      _subscriptions.add(domElement.onBlur.listen((_) {
        if (_enabled) {
          _refocus();
        }
      }));
    }

    if (owner.doesKeyboardShiftInput) {
      _preventShiftDuringFocus();
    }
    domElement.focus();

    if (_lastEditingState != null) {
      setEditingState(_lastEditingState);
    }

    // Subscribe to text and selection changes.
    _subscriptions
      ..add(html.document.onSelectionChange.listen(_handleChange))
      ..add(domElement.onInput.listen(_handleChange));

    // In Firefox, when cursor moves, nor selectionChange neither onInput
    // events are triggered. We are listening to keyup event to decide
    // if the user shifted the cursor.
    // See [SelectionChangeDetection].
    if (browserEngine == BrowserEngine.firefox) {
      _subscriptions.add(domElement.onKeyUp.listen((event) {
        if (_selectionDetection.detectChange()) {
          _handleChange(event);
        }
      }));
    }
  }

  /// Disables the element so it's no longer used for text editing.
  ///
  /// Calling [disable] also removes any registered event listeners.
  void disable() {
    assert(_enabled);

    _enabled = false;
    _lastEditingState = null;

    for (int i = 0; i < _subscriptions.length; i++) {
      _subscriptions[i].cancel();
    }
    _subscriptions.clear();
    _positionInputElementTimer?.cancel();
    _positionInputElementTimer = null;
    owner.inputPositioned = false;
    _removeDomElement();
    _selectionDetection = null;
  }

  void _initDomElement(InputConfiguration inputConfig) {
    switch (inputConfig.inputType) {
      case InputType.text:
        domElement = owner.createInputElement();
        break;

      case InputType.multiline:
        domElement = owner.createTextAreaElement();
        break;

      default:
        throw UnsupportedError(
            'Unsupported input type: ${inputConfig.inputType}');
    }
    html.document.body.append(domElement);
  }

  void _removeDomElement() {
    domElement.remove();
    domElement = null;
  }

  void _refocus() {
    domElement.focus();
  }

  void _preventShiftDuringFocus() {
    // Position the element outside of the page before focusing on it.
    //
    // See [_positionInputElementTimer].
    owner.setStyleOutsideOfScreen(domElement);

    _subscriptions.add(domElement.onFocus.listen((_) {
      // Cancel previous timer if exists.
      _positionInputElementTimer?.cancel();
      _positionInputElementTimer = Timer(_delayBeforePositioning, () {
        if (textEditing.inputElementNeedsToBePositioned) {
          configureInputElementForIOS();
        }
      });

      // When the virtual keyboard is closed on iOS, onBlur is triggered.
      _subscriptions.add(domElement.onBlur.listen((_) {
        // Cancel the timer since there is no need to set the location of the
        // input element anymore. It needs to be focused again to be editable
        // by the user.
        _positionInputElementTimer?.cancel();
        _positionInputElementTimer = null;
      }));
    }));
  }

  void setEditingState(EditingState editingState) {
    _lastEditingState = editingState;
    if (!_enabled || !editingState.isValid) {
      return;
    }

    switch (_elementType) {
      case ElementType.input:
        final html.InputElement input = domElement;
        input.value = editingState.text;
        input.setSelectionRange(
          editingState.baseOffset,
          editingState.extentOffset,
        );
        break;

      case ElementType.textarea:
        final html.TextAreaElement textarea = domElement;
        textarea.value = editingState.text;
        textarea.setSelectionRange(
          editingState.baseOffset,
          editingState.extentOffset,
        );
        break;

      case ElementType.contentEditable:
        domRenderer.clearDom(domElement);
        domElement.append(html.Text(editingState.text));
        html.window.getSelection()
          ..removeAllRanges()
          ..addRange(_createRange(editingState));
        break;
    }

    if (owner.inputElementNeedsToBePositioned) {
      _preventShiftDuringFocus();
    }

    // Re-focuses when setting editing state.
    domElement.focus();
  }

  /// Swap out the current DOM element and replace it with a new one of type
  /// [newElementType].
  ///
  /// Ideally, swapping the underlying DOM element should be seamless to the
  /// user of this class.
  ///
  /// See also:
  ///
  /// * [PersistentTextEditingElement._swapDomElement], which notifies its users
  ///   that the element has been swapped.
  void _swapDomElement(ElementType newElementType) {
    // TODO(mdebbar): Create the appropriate dom element and initialize it.
  }

  void _handleChange(html.Event event) {
    _lastEditingState = calculateEditingState();
    _onChange(_lastEditingState);
  }

  @visibleForTesting
  EditingState calculateEditingState() {
    assert(domElement != null);

    EditingState editingState;
    switch (_elementType) {
      case ElementType.input:
        final html.InputElement inputElement = domElement;
        editingState = EditingState(
          text: inputElement.value,
          baseOffset: inputElement.selectionStart,
          extentOffset: inputElement.selectionEnd,
        );
        break;

      case ElementType.textarea:
        final html.TextAreaElement textAreaElement = domElement;
        editingState = EditingState(
          text: textAreaElement.value,
          baseOffset: textAreaElement.selectionStart,
          extentOffset: textAreaElement.selectionEnd,
        );
        break;

      case ElementType.contentEditable:
        // In a contenteditable element, we want `innerText` since it correctly
        // converts <br> to newline characters, for example.
        //
        // If we later decide to use <input> and/or <textarea> then we can go back
        // to using `textContent` (or `value` in the case of <input>)
        final String text = js_util.getProperty(domElement, 'innerText');
        if (domElement.childNodes.length > 1) {
          // Having multiple child nodes in a content editable element means one of
          // two things:
          // 1. Text contains new lines.
          // 2. User pasted rich text.
          final int prevSelectionEnd = math.max(
              _lastEditingState.baseOffset, _lastEditingState.extentOffset);
          final String prevText = _lastEditingState.text;
          final int offsetFromEnd = prevText.length - prevSelectionEnd;

          final int newSelectionExtent = text.length - offsetFromEnd;
          // TODO(mdebbar): we may need to `setEditingState()` here.
          editingState = EditingState(
            text: text,
            baseOffset: newSelectionExtent,
            extentOffset: newSelectionExtent,
          );
        } else {
          final html.Selection selection = html.window.getSelection();
          editingState = EditingState(
            text: text,
            baseOffset: selection.baseOffset,
            extentOffset: selection.extentOffset,
          );
        }
    }

    assert(editingState != null);
    return editingState;
  }

  html.Range _createRange(EditingState editingState) {
    final html.Node firstChild = domElement.firstChild;
    return html.document.createRange()
      ..setStart(firstChild, editingState.baseOffset)
      ..setEnd(firstChild, editingState.extentOffset);
  }
}

/// The implementation of a persistent mode for [TextEditingElement].
///
/// Persistent mode assumes the caller will own the creation, insertion and
/// disposal of the DOM element.
///
/// This class is still responsible for hooking up the DOM element with the
/// [HybridTextEditing] instance so that changes are communicated to Flutter.
///
/// Persistent mode is useful for callers that want to have full control over
/// the placement and lifecycle of the DOM element. An example of such a caller
/// is Semantic's TextField that needs to put the DOM element inside the
/// semantic tree. It also requires that the DOM element remains in the tree
/// when the user isn't editing.
class PersistentTextEditingElement extends TextEditingElement {
  /// Creates a [PersistentTextEditingElement] that eagerly instantiates
  /// [domElement] so the caller can insert it before calling
  /// [PersistentTextEditingElement.enable].
  PersistentTextEditingElement(
    HybridTextEditing owner,
    html.HtmlElement domElement, {
    @required html.VoidCallback onDomElementSwap,
  })  : _onDomElementSwap = onDomElementSwap,
        super(owner) {
    // Make sure the dom element is of a type that we support for text editing.
    // TODO(yjbanov): move into initializer list when https://github.com/dart-lang/sdk/issues/37881 is fixed.
    assert(_getTypeFromElement(domElement) != null);
    this.domElement = domElement;
  }

  final html.VoidCallback _onDomElementSwap;

  @override
  void _initDomElement(InputConfiguration inputConfig) {
    // In persistent mode, the user of this class is supposed to insert the
    // [domElement] on their own. Let's make sure they did.
    assert(domElement != null);
    assert(html.document.body.contains(domElement));
  }

  @override
  void _removeDomElement() {
    // In persistent mode, we don't want to remove the DOM element because the
    // caller is responsible for that.
    //
    // Remove focus from the editable element to cause the keyboard to hide.
    // Otherwise, the keyboard stays on screen even when the user navigates to
    // a different screen (e.g. by hitting the "back" button).
    domElement.blur();
  }

  @override
  void _refocus() {
    // The semantic text field on Android listens to the focus event in order to
    // switch to a new text field. If we refocus here, we break that
    // functionality and the user can't switch from one text field to another in
    // accessibility mode.
  }

  @override
  void _swapDomElement(ElementType newElementType) {
    super._swapDomElement(newElementType);

    // Unfortunately, in persistent mode, the user of this class has to be
    // notified that the element is being swapped.
    // TODO(mdebbar): do we need to call `old.replaceWith(new)` here?
    _onDomElementSwap();
  }
}

/// Text editing singleton.
final HybridTextEditing textEditing = HybridTextEditing();

/// Should be used as a singleton to provide support for text editing in
/// Flutter Web.
///
/// The approach is "hybrid" because it relies on Flutter for
/// displaying, and HTML for user interactions:
///
/// - HTML's contentEditable feature handles typing and text changes.
/// - HTML's selection API handles selection changes and cursor movements.
class HybridTextEditing {
  /// The default HTML element used to manage editing state when a custom
  /// element is not provided via [useCustomEditableElement].
  TextEditingElement _defaultEditingElement;

  /// Private constructor so this class can be a singleton.
  HybridTextEditing() {
    _defaultEditingElement = TextEditingElement(this);
  }

  /// The HTML element used to manage editing state.
  ///
  /// This field is populated using [useCustomEditableElement]. If `null` the
  /// [_defaultEditableElement] is used instead.
  TextEditingElement _customEditingElement;

  TextEditingElement get editingElement {
    if (_customEditingElement != null) {
      return _customEditingElement;
    }
    return _defaultEditingElement;
  }

  /// Requests that [customEditingElement] is used for managing text editing state
  /// instead of the hidden default element.
  ///
  /// Use [stopUsingCustomEditableElement] to switch back to default element.
  void useCustomEditableElement(TextEditingElement customEditingElement) {
    if (_isEditing && customEditingElement != _customEditingElement) {
      stopEditing();
    }
    _customEditingElement = customEditingElement;
  }

  /// Switches back to using the built-in default element for managing text
  /// editing state.
  void stopUsingCustomEditableElement() {
    useCustomEditableElement(null);
  }

  int _clientId;

  /// Flag which shows if there is an ongoing editing.
  ///
  /// Also used to define if a keyboard is needed.
  bool _isEditing = false;

  /// Indicates whether the input element needs to be positioned.
  ///
  /// See [TextEditingElement._delayBeforePositioning].
  bool get inputElementNeedsToBePositioned =>
      !inputPositioned && _isEditing && doesKeyboardShiftInput;

  /// Flag indicating whether the input element's position is set.
  ///
  /// See [inputElementNeedsToBePositioned].
  bool inputPositioned = false;

  Map<String, dynamic> _configuration;

  /// All "flutter/textinput" platform messages should be sent to this method.
  void handleTextInput(ByteData data) {
    final MethodCall call = const JSONMethodCodec().decodeMethodCall(data);
    switch (call.method) {
      case 'TextInput.setClient':
        final bool clientIdChanged =
            _clientId != null && _clientId != call.arguments[0];
        if (clientIdChanged && _isEditing) {
          stopEditing();
        }
        _clientId = call.arguments[0];
        _configuration = call.arguments[1];
        break;

      case 'TextInput.setEditingState':
        editingElement
            .setEditingState(EditingState.fromFlutter(call.arguments));
        break;

      case 'TextInput.show':
        if (!_isEditing) {
          _startEditing();
        }
        break;

      case 'TextInput.setEditableSizeAndTransform':
        _setLocation(call.arguments);
        break;

      case 'TextInput.setStyle':
        _setFontStyle(call.arguments);
        break;

      case 'TextInput.clearClient':
      case 'TextInput.hide':
        if (_isEditing) {
          stopEditing();
        }
        break;
    }
  }

  void _startEditing() {
    assert(!_isEditing);
    _isEditing = true;
    editingElement.enable(
      InputConfiguration.fromFlutter(_configuration),
      onChange: _syncEditingStateToFlutter,
    );
  }

  void stopEditing() {
    assert(_isEditing);
    _isEditing = false;
    editingElement.disable();
  }

  _EditingStyle _editingStyle;
  _EditingStyle get editingStyle => _editingStyle;

  /// Use the font size received from Flutter if set.
  String font() {
    assert(_editingStyle != null);
    return '${_editingStyle.fontWeight} ${_editingStyle.fontSize}px ${_editingStyle.fontFamily}';
  }

  void _setFontStyle(Map<String, dynamic> style) {
    assert(style.containsKey('fontSize'));
    assert(style.containsKey('fontFamily'));
    assert(style.containsKey('textAlignIndex'));
    assert(style.containsKey('textDirectionIndex'));

    final int textAlignIndex = style['textAlignIndex'];
    final int textDirectionIndex = style['textDirectionIndex'];

    /// Converts integer value coming as fontWeightIndex from TextInput.setStyle
    /// to its CSS equivalent value.
    /// Converts index of TextAlign to enum value.
    _editingStyle = _EditingStyle(
        textDirection: ui.TextDirection.values[textDirectionIndex],
        fontSize: style['fontSize'],
        textAlign: ui.TextAlign.values[textAlignIndex],
        fontFamily: style['fontFamily'],
        fontWeightIndex: style['fontWeightIndex']);
  }

  /// Size and transform of the editable text on the page.
  _EditableSizeAndTransform _editingLocationAndSize;
  _EditableSizeAndTransform get editingLocationAndSize =>
      _editingLocationAndSize;

  void _setLocation(Map<String, dynamic> editingLocationAndSize) {
    assert(editingLocationAndSize.containsKey('width'));
    assert(editingLocationAndSize.containsKey('height'));
    assert(editingLocationAndSize.containsKey('transform'));

    final List<double> transformList =
        List<double>.from(editingLocationAndSize['transform']);
    _editingLocationAndSize = _EditableSizeAndTransform(
      width: editingLocationAndSize['width'],
      height: editingLocationAndSize['height'],
      transform: Float64List.fromList(transformList),
    );

    if (editingElement.domElement != null) {
      _setDynamicStyleAttributes(editingElement.domElement);
    }
  }

  void _syncEditingStateToFlutter(EditingState editingState) {
    ui.window.onPlatformMessage(
      'flutter/textinput',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('TextInputClient.updateEditingState', <dynamic>[
          _clientId,
          editingState.toFlutter(),
        ]),
      ),
      _emptyCallback,
    );
  }

  /// Positioning of input element is only done if we are not expecting input
  /// to be shifted by a virtual keyboard or if the input is already positioned.
  ///
  /// Otherwise positioning will be done after focusing on the input.
  /// See [TextEditingElement._delayBeforePositioning].
  bool get _canPositionInput => inputPositioned || !doesKeyboardShiftInput;

  /// Indicates whether virtual keyboard shifts the location of input element.
  ///
  /// Value decided using the operating system and the browser engine.
  ///
  /// In iOS, the virtual keyboard might shifts the screen up to make input
  /// visible depending on the location of the focused input element.
  bool get doesKeyboardShiftInput =>
      browserEngine == BrowserEngine.webkit &&
      operatingSystem == OperatingSystem.iOs;

  /// These style attributes are dynamic throughout the life time of an input
  /// element.
  ///
  /// They are changed depending on the messages coming from method calls:
  /// "TextInput.setStyle", "TextInput.setEditableSizeAndTransform".
  void _setDynamicStyleAttributes(html.HtmlElement domElement) {
    if (_editingLocationAndSize != null && _canPositionInput) {
      setStyle(domElement);
    }
  }

  /// Set style to the native dom element used for text editing.
  ///
  /// It will be located exactly in the same place with the editable widgets,
  /// however it's contents and cursor will be invisible.
  ///
  /// Users can interact with the element and use the functionalities of the
  /// right-click menu. Such as copy,paste, cut, select, translate...
  void setStyle(html.HtmlElement domElement) {
    final String transformCss =
        float64ListToCssTransform(_editingLocationAndSize.transform);
    domElement.style
      ..width = '${_editingLocationAndSize.width}px'
      ..height = '${_editingLocationAndSize.height}px'
      ..textAlign = _editingStyle.align
      ..font = font()
      ..transform = transformCss;
  }

  // TODO(flutter_web): After the browser closes and re-opens the virtual
  // shifts the page in iOS. Call this method from visibility change listener
  // attached to body.
  /// Set the dom element's location somewhere outside of the screen.
  ///
  /// This is useful for not triggering a scroll when iOS virtual keyboard is
  /// coming up.
  ///
  /// See [TextEditingElement._delayBeforePositioning].
  void setStyleOutsideOfScreen(html.HtmlElement domElement) {
    domElement.style.transform = 'translate(-9999px, -9999px)';
  }

  html.InputElement createInputElement() {
    final html.InputElement input = html.InputElement();
    _setStaticStyleAttributes(input);
    _setDynamicStyleAttributes(input);
    return input;
  }

  html.TextAreaElement createTextAreaElement() {
    final html.TextAreaElement textarea = html.TextAreaElement();
    _setStaticStyleAttributes(textarea);
    _setDynamicStyleAttributes(textarea);
    return textarea;
  }
}

/// Information on the font and alignment of a text editing element.
///
/// This information is received via TextInput.setStyle message.
class _EditingStyle {
  _EditingStyle({
    @required this.textDirection,
    @required this.fontSize,
    @required this.textAlign,
    @required this.fontFamily,
    @required fontWeightIndex,
  }) : this.fontWeight = (fontWeightIndex != null)
            ? fontWeightIndexToCss(fontWeightIndex: fontWeightIndex)
            : 'normal';

  /// This information will be used for changing the style of the hidden input
  /// element, which will match it's size to the size of the editable widget.
  final double fontSize;
  final String fontWeight;
  final String fontFamily;
  final ui.TextAlign textAlign;
  final ui.TextDirection textDirection;

  String get align => textAlignToCssValue(textAlign, textDirection);
}

/// Information on the location and size of the editing element.
///
/// This information is received via "TextInput.setEditableSizeAndTransform"
/// message. Framework currently sends this information on paint.
class _EditableSizeAndTransform {
  _EditableSizeAndTransform({
    @required this.width,
    @required this.height,
    @required this.transform,
  });

  final double width;
  final double height;
  final Float64List transform;
}

/// Detects changes in text selection.
///
/// Currently only used in Firefox.
///
/// In Firefox, when cursor moves, neither selectionChange nor onInput
/// events are triggered. We are listening to keyup event. Selection start,
/// end values are used to decide if the text cursor moved.
///
/// Specific keycodes are not checked since users/applicatins can bind their own
/// keys to move the text cursor.
class SelectionChangeDetection {
  final html.HtmlElement _domElement;
  int _start = -1;
  int _end = -1;

  SelectionChangeDetection(this._domElement) {
    if (_domElement is html.InputElement) {
      html.InputElement element = _domElement;
      _saveSelection(element.selectionStart, element.selectionEnd);
    } else if (_domElement is html.TextAreaElement) {
      html.TextAreaElement element = _domElement;
      _saveSelection(element.selectionStart, element.selectionEnd);
    } else {
      throw UnsupportedError('Initialized with unsupported input type');
    }
  }

  /// Decides if the selection has changed (cursor moved) compared to the
  /// previous values.
  ///
  /// After each keyup, the start/end values of the selection is compared to the
  /// previously saved start/end values.
  bool detectChange() {
    if (_domElement is html.InputElement) {
      html.InputElement element = _domElement;
      return _compareSelection(element.selectionStart, element.selectionEnd);
    }
    if (_domElement is html.TextAreaElement) {
      html.TextAreaElement element = _domElement;
      return _compareSelection(element.selectionStart, element.selectionEnd);
    }
    throw UnsupportedError('Unsupported input type');
  }

  void _saveSelection(int selectionStart, int selectionEnd) {
    _start = selectionStart;
    _end = selectionEnd;
  }

  bool _compareSelection(int selectionStart, int selectionEnd) {
    if (selectionStart != _start || selectionEnd != _end) {
      _saveSelection(selectionStart, selectionEnd);
      return true;
    } else {
      return false;
    }
  }
}
