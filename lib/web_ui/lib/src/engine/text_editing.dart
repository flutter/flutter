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

  final HybridTextEditing owner;
  bool _enabled = false;

  html.HtmlElement domElement;
  EditingState _lastEditingState;
  _OnChangeCallback _onChange;

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
  /// trigger an event. In order to position the input element correctly, it is
  /// important we set it's final location after focusing on it (after keyboard
  /// is up).
  ///
  /// This method is called in the end of the 'touchend' event, therefore it is
  /// called after the editing state is set.
  void configureInputElementForIOS() {
    if (browserEngine != BrowserEngine.webkit ||
        operatingSystem != OperatingSystem.iOs) {
      // Only relevant on Safari.
      return;
    }
    if (domElement != null) {
      owner.setStyle(domElement);
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

    domElement.focus();

    if (_lastEditingState != null) {
      setEditingState(_lastEditingState);
    }

    // Subscribe to text and selection changes.
    _subscriptions
      ..add(html.document.onSelectionChange.listen(_handleChange))
      ..add(domElement.onInput.listen(_handleChange));
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
    _removeDomElement();
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

    // Safari on iOS requires that we focus explicitly. Otherwise, the on-screen
    // keyboard won't show up.
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

  /// Flag indicating if the flutter framework requested a keyboard.
  bool get needsKeyboard => _isEditing;

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
      fontWeight:
          fontWeightIndexToCss(fontWeightIndex: style['fontWeightIndex']),
    );
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

  /// These style attributes are dynamic throughout the life time of an input
  /// element.
  ///
  /// They are changed depending on the messages coming from method calls:
  /// "TextInput.setStyle", "TextInput.setEditableSizeAndTransform".
  void _setDynamicStyleAttributes(html.HtmlElement domElement) {
    if (_editingLocationAndSize != null &&
        !(browserEngine == BrowserEngine.webkit &&
            operatingSystem == OperatingSystem.iOs)) {
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
    this.fontWeight,
  });

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
// TODO(flutter_web): send the location during the scroll for more frequent
// updates from the framework.
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
