// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// Make the content editable span visible to facilitate debugging.
const bool _debugVisibleTextEditing = false;

void _emptyCallback(dynamic _) {}

void _styleEditingElement(html.HtmlElement domElement) {
  domElement.style
    ..position = 'fixed'
    ..whiteSpace = 'pre';
  if (_debugVisibleTextEditing) {
    domElement.style
      ..bottom = '0'
      ..right = '0'
      ..font = '24px sans-serif'
      ..color = 'purple'
      ..backgroundColor = 'pink';
  } else {
    domElement.style
      ..overflow = 'hidden'
      ..transform = 'translate(-99999px, -99999px)'
      // width and height can't be zero because then the element would stop
      // receiving edits when its content is empty.
      ..width = '1px'
      ..height = '1px';
  }
  if (browserEngine == BrowserEngine.webkit) {
    // TODO(flutter_web): Remove once webkit issue of paragraphs incorrectly
    // rendering (shifting up) is resolved. Temporarily force relayout
    // a frame after input is created.
    html.window.animationFrame.then((num _) {
      domElement.style
        ..position = 'absolute'
        ..bottom = '0'
        ..right = '0';
    });
  }
}

html.InputElement _createInputElement() {
  final html.InputElement input = html.InputElement();
  _styleEditingElement(input);
  return input;
}

html.TextAreaElement _createTextAreaElement() {
  final html.TextAreaElement textarea = html.TextAreaElement();
  _styleEditingElement(textarea);
  return textarea;
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
  TextEditingElement();

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
        domElement = _createInputElement();
        break;

      case InputType.multiline:
        domElement = _createTextAreaElement();
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
    html.HtmlElement domElement, {
    @required html.VoidCallback onDomElementSwap,
  })  : _onDomElementSwap = onDomElementSwap,
        // Make sure the dom element is of a type that we support for text editing.
        assert(_getTypeFromElement(domElement) != null) {
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
  TextEditingElement _defaultEditingElement = TextEditingElement();

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
      _stopEditing();
    }
    _customEditingElement = customEditingElement;
  }

  /// Switches back to using the built-in default element for managing text
  /// editing state.
  void stopUsingCustomEditableElement() {
    useCustomEditableElement(null);
  }

  int _clientId;
  bool _isEditing = false;
  Map<String, dynamic> _configuration;

  /// All "flutter/textinput" platform messages should be sent to this method.
  void handleTextInput(ByteData data) {
    final MethodCall call = const JSONMethodCodec().decodeMethodCall(data);
    switch (call.method) {
      case 'TextInput.setClient':
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

      case 'TextInput.clearClient':
      case 'TextInput.hide':
        if (_isEditing) {
          _stopEditing();
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

  void _stopEditing() {
    assert(_isEditing);
    _isEditing = false;
    editingElement.disable();
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
}
