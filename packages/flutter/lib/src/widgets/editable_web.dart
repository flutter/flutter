// ignore_for_file: public_member_api_docs
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:ui' as ui; // change to ui_web when you update

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class EditableWeb extends StatefulWidget {
  const EditableWeb({
    super.key,
    this.textStyle,
    required this.cursorColor,
    required this.showCursor,
    required this.forceLine,
    required this.hasFocus,
    required this.maxLines,
    this.minLines,
    required this.expands,
    this.selectionColor,
    required this.textScaler,
    required this.textAlign,
    required this.textDirection,
    this.locale,
    required this.offset,
    this.rendererIgnoresPointer = false,
    required this.devicePixelRatio,
    required this.clipBehavior,
    required this.requestKeyboard,
    required this.clientId,
    required this.performAction,
    required this.textInputConfiguration, // contains a bunch of things like obscureText, readOnly, autofillHints, etc.
    this.currentAutofillScope, // contains a bunch of things like obscureText, readOnly, autofillHints, etc.
    required this.scrollTop,
    required this.scrollLeft,
    required this.textEditingValue,
    required this.updateEditingValue,
  });

  final TextStyle? textStyle;
  final Color cursorColor;
  final ValueNotifier<bool> showCursor;
  final bool forceLine;
  final bool hasFocus;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final Color? selectionColor;
  final TextScaler textScaler;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Locale? locale;
  final ViewportOffset offset;
  final bool rendererIgnoresPointer;
  final double devicePixelRatio;
  final Clip clipBehavior;
  final void Function() requestKeyboard;
  final int clientId;
  final void Function(TextInputAction) performAction;
  final TextInputConfiguration textInputConfiguration;
  final AutofillScope? currentAutofillScope;
  final double scrollTop;
  final double scrollLeft;
  final String textEditingValue;
  final void Function(TextEditingValue) updateEditingValue;

  @override
  State<EditableWeb> createState() => _EditableWebState();
}

class _EditableWebState extends State<EditableWeb> {
  late html.HtmlElement _inputEl;
  html.InputElement? _inputElement;
  html.TextAreaElement? _textAreaElement;
  double sizedBoxHeight = 24;
  late final int _maxLines;
  TextEditingValue? lastEditingState;
  bool get _isMultiline => widget.maxLines != 1;

  @override
  void initState() {
    super.initState();
    _maxLines = widget.maxLines ?? 1;
  }

  @override
  void dispose() {
    (EditableText.effectivePlugin as NativeWebTextEditingPlugin).deregisterInstance(widget.clientId);
    super.dispose();
  }

  String colorToCss(Color color) {
    // hard coding opacity to 1 for now because EditableText passes cursorColor with 0 opacity.
    return 'rgba(${color.red}, ${color.green}, ${color.blue}, ${color.opacity == 0 ? 1 : color.opacity})';
  }

  String textStyleToCss(TextStyle style) {
    final List<String> cssProperties = <String>[];

    if (style.color != null) {
      cssProperties.add('color: ${colorToCss(style.color!)}');
    }

    if (style.fontSize != null) {
      cssProperties.add('font-size: ${style.fontSize}px');
    }

    if (style.fontWeight != null) {
      cssProperties.add('font-weight: ${style.fontWeight!.value}');
    }

    if (style.fontStyle != null) {
      cssProperties.add(
          'font-style: ${style.fontStyle == FontStyle.italic ? 'italic' : 'normal'}');
    }

    if (style.fontFamily != null) {
      cssProperties.add('font-family: "${style.fontFamily}"');
    }

    if (style.letterSpacing != null) {
      cssProperties.add('letter-spacing: ${style.letterSpacing}px');
    }

    if (style.wordSpacing != null) {
      cssProperties.add('word-spacing: ${style.wordSpacing}');
    }

    if (style.decoration != null) {
      final List<String> textDecorations = <String>[];
      final TextDecoration decoration = style.decoration!;

      if (decoration == TextDecoration.none) {
        textDecorations.add('none');
      } else {
        if (decoration.contains(TextDecoration.underline)) {
          textDecorations.add('underline');
        }

        if (decoration.contains(TextDecoration.underline)) {
          textDecorations.add('underline');
        }

        if (decoration.contains(TextDecoration.underline)) {
          textDecorations.add('underline');
        }
      }

      cssProperties.add('text-decoration: ${textDecorations.join(' ')}');
    }

    return cssProperties.join('; ');
  }

  /// NOTE: Taken from engine
  /// TODO: make more functional, set autocap attr outside of function using return val
  /// Sets `autocapitalize` attribute on input elements.
  ///
  /// This attribute is only available for mobile browsers.
  ///
  /// Note that in mobile browsers the onscreen keyboards provide sentence
  /// level capitalization as default as apposed to no capitalization on desktop
  /// browser.
  ///
  /// See: https://developers.google.com/web/updates/2015/04/autocapitalize
  /// https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/autocapitalize
  void setAutocapitalizeAttribute(html.HtmlElement inputEl) {
    String autocapitalize = '';
    switch (widget.textInputConfiguration.textCapitalization) {
      case TextCapitalization.words:
        // TODO(mdebbar): There is a bug for `words` level capitalization in IOS now.
        // For now go back to default. Remove the check after bug is resolved.
        // https://bugs.webkit.org/show_bug.cgi?id=148504
        // TODO add browser engines
        // if (browserEngine == BrowserEngine.webkit) {
        //   autocapitalize = 'sentences';
        // } else {
        //   autocapitalize = 'words';
        // }
        autocapitalize = 'words';
      case TextCapitalization.characters:
        autocapitalize = 'characters';
      case TextCapitalization.sentences:
        autocapitalize = 'sentences';
      case TextCapitalization.none:
      default:
        autocapitalize = 'off';
        break;
    }
    inputEl.setAttribute('autocapitalize', autocapitalize);
    // inputEl.autocapitalize = autocapitalize;
  }

  /// NOTE: Taken from engine.
  /// Converts [align] to its corresponding CSS value.
  ///
  /// This value is used as the "text-align" CSS property, e.g.:
  ///
  /// ```css
  /// text-align: right;
  /// ```
  String textAlignToCssValue(
      ui.TextAlign? align, ui.TextDirection textDirection) {
    switch (align) {
      case ui.TextAlign.left:
        return 'left';
      case ui.TextAlign.right:
        return 'right';
      case ui.TextAlign.center:
        return 'center';
      case ui.TextAlign.justify:
        return 'justify';
      case ui.TextAlign.end:
        switch (textDirection) {
          case ui.TextDirection.ltr:
            return 'end';
          case ui.TextDirection.rtl:
            return 'left';
        }
      case ui.TextAlign.start:
        switch (textDirection) {
          case ui.TextDirection.ltr:
            return ''; // it's the default
          case ui.TextDirection.rtl:
            return 'right';
        }
      case null:
        // If align is not specified return default.
        return '';
    }
  }

  /// Takes a font size read from the style property (e.g. '16px) and scales it
  /// by some factor. Returns the scaled font size in a CSS friendly format.
  /// TODO
  // String scaleFontSize(String fontSize, double textScaleFactor) {
  //   assert(fontSize.endsWith('px'));
  //   final String strippedFontSize = fontSize.replaceAll('px', '');
  //   final double parsedFontSize = double.parse(strippedFontSize);
  //   final int scaledFontSize = (parsedFontSize * textScaleFactor).round();

  //   return '${scaledFontSize}px';
  // }

  Map<String, String> getKeyboardTypeAttributes(TextInputType inputType) {
    final bool isDecimal = inputType.decimal ?? false; // appropriate default?

    switch (inputType) {
      case TextInputType.number:
        return <String, String>{
          'type': 'number',
          'inputmode': isDecimal ? 'decimal' : 'numeric'
        };
      case TextInputType.phone:
        return <String, String>{'type': 'tel', 'inputmode': 'tel'};
      case TextInputType.emailAddress:
        return <String, String>{'type': 'email', 'inputmode': 'email'};
      case TextInputType.url:
        return <String, String>{'type': 'url', 'inputmode': 'url'};
      case TextInputType.none:
        return <String, String>{'type': 'text', 'inputmode': 'none'};
      case TextInputType.text:
        return <String, String>{'type': 'text', 'inputmode': 'text'};
      default:
        return <String, String>{'type': 'text', 'inputmode': 'text'};
    }
  }

  String? getEnterKeyHint(TextInputAction inputAction) {
    switch (inputAction) {
      case TextInputAction.continueAction:
      case TextInputAction.next:
        return 'next';
      case TextInputAction.previous:
        return 'previous';
      case TextInputAction.done:
        return 'done';
      case TextInputAction.go:
        return 'go';
      case TextInputAction.newline:
        return 'enter';
      case TextInputAction.search:
        return 'search';
      case TextInputAction.send:
        return 'send';
      case TextInputAction.emergencyCall:
      case TextInputAction.join:
      case TextInputAction.none:
      case TextInputAction.route:
      case TextInputAction.unspecified:
      default:
        return null;
    }
  }

  String _getAutocompleteAttribute(String autofillHint) {
    switch (autofillHint) {
      case AutofillHints.birthday:
        return 'bday';
      case AutofillHints.birthdayDay:
        return 'bday-day';
      case AutofillHints.birthdayMonth:
        return 'bday-month';
      case AutofillHints.birthdayYear:
        return 'bday-year';
      case AutofillHints.countryCode:
        return 'country';
      case AutofillHints.countryName:
        return 'country-name';
      case AutofillHints.creditCardExpirationDate:
        return 'cc-exp';
      case AutofillHints.creditCardExpirationMonth:
        return 'cc-exp-month';
      case AutofillHints.creditCardExpirationYear:
        return 'cc-exp-year';
      case AutofillHints.creditCardFamilyName:
        return 'cc-family-name';
      case AutofillHints.creditCardGivenName:
        return 'cc-given-name';
      case AutofillHints.creditCardMiddleName:
        return 'cc-additional-name';
      case AutofillHints.creditCardName:
        return 'cc-name';
      case AutofillHints.creditCardNumber:
        return 'cc-number';
      case AutofillHints.creditCardSecurityCode:
        return 'cc-csc';
      case AutofillHints.creditCardType:
        return 'cc-type';
      case AutofillHints.email:
        return 'email';
      case AutofillHints.familyName:
        return 'family-name';
      case AutofillHints.fullStreetAddress:
        return 'street-address';
      case AutofillHints.gender:
        return 'sex';
      case AutofillHints.givenName:
        return 'given-name';
      case AutofillHints.impp:
        return 'impp';
      case AutofillHints.jobTitle:
        return 'organization-title';
      case AutofillHints.middleName:
        return 'middleName';
      case AutofillHints.name:
        return 'name';
      case AutofillHints.namePrefix:
        return 'honorific-prefix';
      case AutofillHints.nameSuffix:
        return 'honorific-suffix';
      case AutofillHints.newPassword:
        return 'new-password';
      case AutofillHints.nickname:
        return 'nickname';
      case AutofillHints.oneTimeCode:
        return 'one-time-code';
      case AutofillHints.organizationName:
        return 'organization';
      case AutofillHints.password:
        return 'current-password';
      case AutofillHints.photo:
        return 'photo';
      case AutofillHints.postalCode:
        return 'postal-code';
      case AutofillHints.streetAddressLevel1:
        return 'address-level1';
      case AutofillHints.streetAddressLevel2:
        return 'address-level2';
      case AutofillHints.streetAddressLevel3:
        return 'address-level3';
      case AutofillHints.streetAddressLevel4:
        return 'address-level4';
      case AutofillHints.streetAddressLine1:
        return 'address-line1';
      case AutofillHints.streetAddressLine2:
        return 'address-line2';
      case AutofillHints.streetAddressLine3:
        return 'address-line3';
      case AutofillHints.telephoneNumber:
        return 'tel';
      case AutofillHints.telephoneNumberAreaCode:
        return 'tel-area-code';
      case AutofillHints.telephoneNumberCountryCode:
        return 'tel-country-code';
      case AutofillHints.telephoneNumberExtension:
        return 'tel-extension';
      case AutofillHints.telephoneNumberLocal:
        return 'tel-local';
      case AutofillHints.telephoneNumberLocalPrefix:
        return 'tel-local-prefix';
      case AutofillHints.telephoneNumberLocalSuffix:
        return 'tel-local-suffix';
      case AutofillHints.telephoneNumberNational:
        return 'tel-national';
      case AutofillHints.transactionAmount:
        return 'transaction-amount';
      case AutofillHints.transactionCurrency:
        return 'transaction-currency';
      case AutofillHints.url:
        return 'url';
      case AutofillHints.username:
        return 'username';
      default:
        return autofillHint;
    }
  }

  void setElementStyles(html.HtmlElement inputEl) {
    // style based on TextStyle
    if (widget.textStyle != null) {
      inputEl.style.cssText = textStyleToCss(widget.textStyle!);
    }

    // reset input styles
    inputEl.style
      ..width = '100%'
      ..height = '100%'
      ..setProperty(
          'caret-color',
          widget.showCursor.value
              ? colorToCss(widget.cursorColor)
              : 'transparent')
      ..outline = 'none'
      ..border = 'none'
      ..background = 'transparent'
      ..padding = '0'
      ..overflow = 'hidden'
      ..textAlign = textAlignToCssValue(widget.textAlign, widget.textDirection)
      // ..pointerEvents = widget.rendererIgnoresPointer ? 'none' : 'auto' // Can't use this, material3 text field sets this to none
      ..direction = widget.textDirection.name
      ..lineHeight = '1.5'; // can this be modified by a property?

    // Removes autofill overlay which clashes with Flutter styles
    inputEl.classes.add('transparentTextEditing');

    // debug
    // if (widget.textInputConfiguration.obscureText) {
    //   inputEl.style.outline = '1px solid red'; // debug
    // }

    if (widget.selectionColor != null) {
      /*
        Needs the following code in engine
          sheet.insertRule('''
            $cssSelectorPrefix flt-glass-pane {
              --selection-background: #000000; 
            }
          ''', sheet.cssRules.length);

          sheet.insertRule('''
            $cssSelectorPrefix .customInputSelection::selection {
              background-color: var(--selection-background);
            }
          ''', sheet.cssRules.length);
      */
      // There is no easy way to modify pseudoclasses via js. We are accomplishing this
      // here via modifying a css var that is responsible for this ::selection style
      html.document.querySelector('flt-glass-pane')!.style.setProperty(
          '--selection-background', colorToCss(widget.selectionColor!));

      // To ensure we're only modifying selection on this specific input, we attach a custom class
      // instead of adding a blanket rule for all inputs.
      inputEl.classes.add('customInputSelection');
    }
  }

  // TODO: Handle composition and delta model?
  // TODO: Clean up type stuff
  void handleChange(html.Event event) {
    if (isTextArea(_inputEl)) {
      final html.TextAreaElement element = _inputEl as html.TextAreaElement;
      final String text = element.value!;
      final TextSelection selection = TextSelection(
          baseOffset: element.selectionStart ?? 0,
          extentOffset: element.selectionEnd ?? 0);

      print('handle change value ${text}');
      print(
          'handle change selection ${element.selectionStart} - ${element.selectionEnd}');
      final TextEditingValue newEditingState =
          TextEditingValue(text: text, selection: selection);

      if (newEditingState != lastEditingState) {
        lastEditingState = newEditingState;
        print('updateEditingState');
        updateEditingState(newEditingState);
      }
    } else if(isInput(_inputEl)) {
      final html.InputElement element = _inputEl as html.InputElement;
      final String text = element.value!;
      final TextSelection selection = TextSelection(
          baseOffset: element.selectionStart ?? 0,
          extentOffset: element.selectionEnd ?? 0);

      print('handle change value ${text}');
      print(
          'handle change selection ${element.selectionStart} - ${element.selectionEnd}');
      final TextEditingValue newEditingState =
          TextEditingValue(text: text, selection: selection);

      if (newEditingState != lastEditingState) {
        lastEditingState = newEditingState;
        print('updateEditingState');
        updateEditingState(newEditingState);
      }
    }
  }

  void setElementListeners(html.HtmlElement inputEl) {
    // listen for events
    inputEl.onInput.listen((html.Event e) {
      handleChange(e);
    });

    inputEl.onFocus.listen((html.Event e) {
      widget.requestKeyboard();

      if (widget.selectionColor != null) {
        // Since we're relying on a CSS variable to handle selection background, we
        // run into an issue when there are multiple inputs with multiple selection background
        // values. In that case, the variable is always set to whatever the last rendered input's selection
        // background value was set to.  To fix this, we update that CSS variable to the currently focused
        // element's selection color value.
        inputEl.classes.add('customInputSelection');
        html.document.querySelector('flt-glass-pane')!.style.setProperty(
            '--selection-background', colorToCss(widget.selectionColor!));
      }
    });

    inputEl.onKeyDown.listen((html.KeyboardEvent event) {
      maybeSendAction(event);
    });

    // Prevent default for mouse events to prevent selection interference/flickering.
    // We want to let the framework handle these pointerevents.
    // NEW 10/10 - we actually want the browser to handle these.
    // inputEl.onMouseDown.listen((html.MouseEvent event) {
    //   event.preventDefault();
    // });

    // inputEl.onMouseUp.listen((html.MouseEvent event) {
    //   event.preventDefault();
    // });

    // inputEl.onMouseMove.listen((html.MouseEvent event) {
    //   event.preventDefault();
    // });
  }

  void setGeneralAttributes(html.HtmlElement inputEl) {
    // calculate box size based on specified lines
    // TODO: can we make this better?
    sizedBoxHeight *= _maxLines;

    setAutocapitalizeAttribute(inputEl);

    inputEl.setAttribute('autocorrect',
        widget.textInputConfiguration.autocorrect ? 'on' : 'off');

    final String? enterKeyHint =
        getEnterKeyHint(widget.textInputConfiguration.inputAction);

    if (enterKeyHint != null) {
      inputEl.setAttribute('enterkeyhint', enterKeyHint);
    }
  }

  void setInputElementAttributes(html.InputElement inputEl) {
    // set attributes
    inputEl.value = widget.textEditingValue;
    inputEl.readOnly = widget.textInputConfiguration.readOnly;

    if (widget.textInputConfiguration.obscureText) {
      inputEl.type = 'password';
    } else {
      final Map<String, String> attributes =
          getKeyboardTypeAttributes(widget.textInputConfiguration.inputType);
      inputEl.type = attributes['type'];
      inputEl.inputMode = attributes['inputmode'];
    }

    if (widget.textInputConfiguration.autofillConfiguration.autofillHints
        .isNotEmpty) {
      // browsers can only use one autocomplete attribute
      final String autocomplete = _getAutocompleteAttribute(widget
          .textInputConfiguration.autofillConfiguration.autofillHints.first);
      inputEl.id = autocomplete;
      inputEl.name = autocomplete;
      inputEl.autocomplete = autocomplete;
    }

    _inputElement = inputEl;
  }

  void setTextAreaElementAttributes(html.TextAreaElement textAreaEl) {
    textAreaEl.value = widget.textEditingValue;
    textAreaEl.rows = _maxLines;
    textAreaEl.readOnly = widget.textInputConfiguration.readOnly;
    _textAreaElement = textAreaEl;
  }

  // TODO add a submit type input to each autofill group
  void setupAutofill(html.HtmlElement inputEl) {
    // No autofill group, nothing to setup
    if (widget.currentAutofillScope == null) {
      return;
    }

    // Create a unique id for the form id and form attribute
    // Taken from engine.
    final Iterable<AutofillClient> autofillClients =
        widget.currentAutofillScope!.autofillClients;
    final List<String> ids = List<String>.empty(growable: true);

    for (final AutofillClient autofillClient in autofillClients) {
      ids.add(autofillClient.autofillId);
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

    final String formId = idBuffer.toString();

    // Only create form if it doesn't already exist.
    if (html.document.getElementById(formId) == null) {
      final html.FormElement formElement = html.FormElement();
      formElement.id = formId;

      // Append the form to the glasspane
      html.document.querySelector('flt-glass-pane')!.append(formElement);
    }

    final String autofillId =
        widget.textInputConfiguration.autofillConfiguration.uniqueIdentifier;

    // verify the current element is inside the autofill group.
    if (widget.currentAutofillScope?.getAutofillClient(autofillId) != null) {
      // associate with created form using form attribute and formId.
      inputEl.setAttribute('form', formId);
    }
  }

  void initializePlatformView(html.HtmlElement inputEl) {
    _isMultiline
        ? setTextAreaElementAttributes(inputEl as html.TextAreaElement)
        : setInputElementAttributes(inputEl as html.InputElement);
    setElementStyles(inputEl);
    setElementListeners(inputEl);
    setGeneralAttributes(inputEl);
    setupAutofill(inputEl);

    _inputEl = inputEl;

    // register instance via clientId.
    (EditableText.effectivePlugin as NativeWebTextEditingPlugin).registerInstance(widget.clientId, this);
  }

  /* Incoming methods (back to framework)
    - TextInputClient.updateEditingState -> send new editing state
    -- right now, this calls _updateEditingValue (on TextInput instance), which calls
    -- updateEditingValue (on the TextInputClient, which is EditableText). 
    - TextInputClient.updateEditingStateWithTag - ?
    - TextInputClient.performAction -> 
    - TextInputClient.requestExistingInputState
    - TextInputClient.onConnectionClosed
  */
  void updateEditingState(TextEditingValue value) {
    // todo: we replaced TextInput.updateEditingValue - this wrapper is probably redundant
    widget.updateEditingValue(value);
  }

  void updateEditingStateWithTag() {
    // autofill stuff?
  }

  void performAction(TextInputAction action) {
    widget.performAction(action);
  }

  void requestExistingInputState() {
    // no-op
  }

  void onConnectionClosed() {
    // no-op?
  }

  void maybeSendAction(html.KeyboardEvent event) {
    if (event.keyCode == html.KeyCode.ENTER) {
      performAction(widget.textInputConfiguration.inputAction);

      // Prevent the browser from inserting a new line when it's not a multiline input.
      // note: taken from engine. Do we still need?
      if (widget.textInputConfiguration.inputType != TextInputType.multiline) {
        event.preventDefault();
      }
    }
  }

  @override
  void didUpdateWidget(EditableWeb oldWidget) {
    super.didUpdateWidget(oldWidget);

    /*
      should we listen to the hasFocus attribute? Focus seems fine for now. 
    */

    // we do this because widget can sometimes selectionColor can be passed
    // as conditionally null depending on some state that's determined in a layer
    // above (e.g. `hasFocus`), so we need to keep track of the selectionColor
    // and set it when appropriate.
    if (widget.selectionColor != oldWidget.selectionColor) {
      if (widget.selectionColor != null) {
        html.document.querySelector('flt-glass-pane')!.style.setProperty(
            '--selection-background', colorToCss(widget.selectionColor!));
        _inputEl.classes.add('customInputSelection');
      }
    }
  }

  // single EditableWeb that is a form owner for both cases.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: sizedBoxHeight,
      child: ExcludeFocus(
        child: HtmlElementView.fromTagName(
          tagName: _isMultiline ? 'textarea' : 'input',
          onElementCreated: (Object element) {
            initializePlatformView(element as html.HtmlElement);
          },
        ),
      ),
    );
  }
}

bool isInput(html.HtmlElement el) {
  return el.tagName.toUpperCase() == 'INPUT';
}

bool isTextArea(html.HtmlElement el) {
  return el.tagName.toUpperCase() == 'TEXTAREA';
}

class NativeWebTextEditingPlugin extends TextEditingPlugin {
  /// docs
  TextInputConnection? _textInputConnection;

  // docs
  @override
  TextInputConnection? get textInputConnection => _textInputConnection;

  @override
  set textInputConnection(TextInputConnection? value) {
    // this will be the attach hook
    if(value != null) {
      _attach(value.client.clientId);
    }

    _textInputConnection = value;
  }

  Map<int, _EditableWebState> editableWebMap = <int, _EditableWebState>{};
  html.HtmlElement? _currentInputElement;
  _EditableWebState? _currentEditableWebInstance;

  // We should only ever have one selectionchange event listener on the document.
  // We should add the listener on `attach()` and remove it on `detach()` to make
  // sure that the listener is only ever added for the currently "active" input element.
  late void Function(html.Event) handleChangeRef;

  // html.HtmlElement? get _inputEl => TextInput._instance._inputEl;

  /// Register an input element. We use an EditableText clientId because we need
  /// an id that can be referenced from a TextInputClient (due to attach's function
  /// signature).
  void registerInstance(int clientId, _EditableWebState instance) {
    editableWebMap[clientId] = instance;
  }

  /// De-register an input element.
  void deregisterInstance(int clientId) {
    editableWebMap.remove(clientId);
  }

  // TODO: We should set the configuration here.
  void _attach(int clientId) {
    // set currentInputElement by grabbing it from the map. This is why we have to register
    // the id of the TextInputClient (editabletext) above, because we need that id in attach.
    _currentEditableWebInstance = editableWebMap[clientId];
    _currentInputElement = _currentEditableWebInstance!._inputEl;

    // Add selectionchange listener. attach() seems like the best place to put this
    // as this is the agreed upon place with the framework where an input gets activated.
    // Other options: Listen to focus and blur changes in the EditableWeb widget and keep it there.
    // Or we can keep logic within a method of our EditableWeb instance and just call it here.
    handleChangeRef = _currentEditableWebInstance!.handleChange;
    html.document.addEventListener('selectionchange', handleChangeRef);
  }

  void _detach() {
    // Blur here since order goes detach -> hide.
    _currentInputElement!.blur();

    // Remove selectionchange listener.
    html.document.removeEventListener('selectionchange', handleChangeRef);

    // Reset current elements.
    _currentEditableWebInstance = null;
    _currentInputElement = null;
  }

  @override
  bool get preventFlutterPaint => true;

  @override
  bool get disableFlutterPointerEventHandling => true;

  @override
  Widget editableBuilder(Editable editable, EditableTextState editableText) {
    return Stack(
        children: <Widget>[
        Positioned.fill(
          child: EditableWeb(
            textStyle: editable.inlineSpan.style,
            textEditingValue: editableText.textEditingValue.text,
            cursorColor: editable.cursorColor!,
            showCursor: editable.showCursor,
            forceLine: editable.forceLine,
            hasFocus: editable.hasFocus,
            maxLines: editable.maxLines,
            minLines: editable.minLines,
            expands: editable.expands,
            selectionColor: editable.selectionColor,
            textScaler: editable.textScaler,
            textAlign: editable.textAlign,
            textDirection: editable.textDirection,
            locale: editable.locale,
            offset: editable.offset,
            rendererIgnoresPointer: editable.rendererIgnoresPointer,
            devicePixelRatio: editable.devicePixelRatio,
            clipBehavior: editable.clipBehavior,
            requestKeyboard: editableText.requestKeyboard,
            clientId: editableText.clientId, // to register 
            performAction: editableText.performAction,
            // Have to use _effectiveAutofillClient.textInputConfiguration as it is the most accurate.
            // autofillHints always end up empty [] because of the way props are being passed from EditableText wrappers like TextField()
            // Instead, it exists in the autofillClient  
            textInputConfiguration: editableText.textInputConfiguration,
            currentAutofillScope: editableText.currentAutofillScope,
            scrollTop: editableText.widget.keyboardType == TextInputType.multiline ? editableText.scrollController.offset : 0,
            scrollLeft: editableText.widget.keyboardType == TextInputType.multiline ? editableText.scrollController.offset : 0,
            updateEditingValue: editableText.updateEditingValue,
          ),
        ),
        editable
      ],
    );
  }

  @override
  void show() {
    _currentInputElement!.focus();
  }

  @override
  void requestAutofill() {}

  // Currently, we directly set the visual appearance of our textfield by props
  // directly passed into EditableWeb. Should we use this instead?
  @override
  void updateConfig(TextInputConfiguration configuration) {}

  @override
  void setEditingState(TextEditingValue value) {
    print('setEditingState ${value}');
    final int minOffset =
        math.min(value.selection.baseOffset, value.selection.extentOffset);
    final int maxOffset =
        math.max(value.selection.baseOffset, value.selection.extentOffset);
    final TextAffinity affinity = value.selection.affinity;
    String direction;

    // do we need this?
    switch (affinity) {
      case TextAffinity.upstream:
        direction = 'backward';
      case TextAffinity.downstream:
        direction = 'forward';
    }

    final TextEditingValue lastEditingState = TextEditingValue(
      text: value.text,
      selection: TextSelection(
        baseOffset: value.selection.baseOffset,
        extentOffset: value.selection.extentOffset,
      ),
    );

    if(isInput(_currentInputElement!)){
      final html.InputElement element = _currentInputElement! as html.InputElement;

      element.value = value.text;
      element.setSelectionRange(minOffset, maxOffset);
    } else if (isTextArea(_currentInputElement!)) {
      final html.TextAreaElement element = _currentInputElement! as html.TextAreaElement;

      element.value = value.text;
      element.setSelectionRange(minOffset, maxOffset);
    }

    _currentEditableWebInstance!.lastEditingState = lastEditingState;
  }

  @override
  void setEditableSizeAndTransform(Size editableBoxSize, Matrix4 transform) {}

  @override
  void setComposingRect(Rect rect) {}

  @override
  void setCaretRect(Rect rect) {}

  @override
  void setSelectionRects(List<SelectionRect> selectionRects) {}
  
  @override
  void setStyle({
    required String? fontFamily,
    required double? fontSize,
    required FontWeight? fontWeight,
    required TextDirection textDirection,
    required TextAlign textAlign,
  }){}

  @override
  void setScrollState({
    required double scrollTop,
    required double scrollLeft,
  }) {
    _currentInputElement!.scrollTop = scrollTop.toInt();
    _currentInputElement!.scrollLeft = scrollLeft.toInt();
  }

  @override
  void close() {
    _detach();
    textInputConnection = null;
  }

  @override
  void connectionClosedReceived() {
    textInputConnection = null;
  }
}