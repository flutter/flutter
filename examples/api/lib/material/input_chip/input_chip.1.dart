// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const List<String> _pizzaTopings = <String>[
  'Avocado',
  'Tomato',
  'Cheese',
  'Pepperoni',
  'Pickles',
  'Onion',
  'Jalapeno',
  'Mushrooms',
  'Pineapple',
];

void main() => runApp(const EditableChipFieldApp());

class EditableChipFieldApp extends StatelessWidget {
  const EditableChipFieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const EditableChipFieldExample(),
    );
  }
}

class EditableChipFieldExample extends StatefulWidget {
  const EditableChipFieldExample({super.key});

  @override
  EditableChipFieldExampleState createState() => EditableChipFieldExampleState();
}

class EditableChipFieldExampleState extends State<EditableChipFieldExample> {
  final FocusNode _chipFocusNode = FocusNode();
  Set<String> _toppings = <String>{ _pizzaTopings.first };
  List<String> _suggestions = <String>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editable Chip Field Sample'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ChipsInput<String>(
              values: _toppings,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.local_pizza_rounded),
                hintText: 'Search for toppings',
              ),
              focusNode: _chipFocusNode,
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
              chipBuilder: _chipBuilder,
              onTextChanged: _onSearchChanged,
            ),
          ),
          if (_suggestions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (BuildContext context, int index) {
                  return _suggestionBuilder(context, _suggestions[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onSearchChanged(String value) async {
    final List<String> results = await _suggestionCallback(value);
    setState(() {
      _suggestions = results
        .where((String topping) => !_toppings.contains(topping))
        .toList();
    });
  }

  Widget _chipBuilder(BuildContext context, String topping) {
    return InputChip(
      key: ObjectKey(topping),
      label: Text(topping),
      avatar: CircleAvatar(
        child: Text(topping[0].toUpperCase()),
      ),
      onDeleted: () => _deleteChip(topping),
      onSelected: (_) => _onChipTapped(topping),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.all(2),
    );
  }

  Widget _suggestionBuilder(BuildContext context, String topping) {
    return ListTile(
      key: ObjectKey(topping),
      leading: CircleAvatar(
        child: Text(topping[0].toUpperCase()),
      ),
      title: Text(topping),
      onTap: () => _selectSuggestion(topping),
    );
  }

  void _selectSuggestion(String topping) {
    setState(() {
      _toppings.add(topping);
      _suggestions = <String>[];
    });
  }

  void _onChipTapped(String topping) {}

  void _deleteChip(String topping) {
    setState(() {
      _toppings.remove(topping);
      _suggestions = <String>[];
    });
  }

  void _onSubmitted(String text) {
    if (text.trim().isNotEmpty) {
      setState(() {
        _toppings = <String>{..._toppings, text.trim()};
      });
    } else {
      _chipFocusNode.unfocus();
      setState(() {
        _toppings = <String>{};
      });
    }
  }

  void _onChanged(Set<String> data) {
    setState(() {
      _toppings = data;
    });
  }

  FutureOr<List<String>> _suggestionCallback(String text) {
    if (text.isNotEmpty) {
      return _pizzaTopings.where((String topping) {
        return topping.toLowerCase().contains(text.toLowerCase());
      }).toList();
    }
    return const <String>[];
  }
}

class ChipsInput<T> extends StatefulWidget {
  const ChipsInput({
    super.key,
    required this.values,
    this.decoration = const InputDecoration(),
    required this.chipBuilder,
    required this.onChanged,
    this.onChipTapped,
    this.onSubmitted,
    this.onTextChanged,
    this.focusNode,
  });

  final Set<T> values;
  final InputDecoration decoration;
  final FocusNode? focusNode;

  final ValueChanged<Set<T>> onChanged;
  final ValueChanged<T>? onChipTapped;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onTextChanged;

  final Widget Function(BuildContext context, T data) chipBuilder;

  @override
  ChipsInputState<T> createState() => ChipsInputState<T>();
}

class ChipsInputState<T> extends State<ChipsInput<T>> implements TextInputClient {
  static const int kObjectReplacementChar = 0xFFFE;

  FocusNode? _lastChipFocusNode;

  late final FocusNode _focusNode;
  TextEditingValue _value = TextEditingValue.empty;
  TextInputConnection? _connection;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _closeInputConnectionIfNeeded();
    super.dispose();
  }

  @override
  TextEditingValue get currentTextEditingValue => _value;

  @override
  void updateEditingValue(TextEditingValue value) {
    final int oldCount = _countReplacements(_value);
    final int newCount = _countReplacements(value);

    setState(() {
      if (newCount < oldCount) {
        widget.onChanged(widget.values.take(newCount).toSet());
      }
      _value = value;
    });
    widget.onTextChanged?.call(text);
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void connectionClosed() {
    _focusNode.unfocus();
  }

  @override
  void performAction(TextInputAction action) {
    widget.onSubmitted?.call(text);
  }

  @override
  AutofillScope? get currentAutofillScope => throw UnimplementedError();

  @override
  void didChangeInputControl(TextInputControl? oldControl, TextInputControl? newControl) {}

  @override
  void insertContent(KeyboardInsertedContent content) {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void performSelector(String selectorName) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void showToolbar() {}

  @override
  Widget build(BuildContext context) {
    _syncTextValue();

    final List<Widget> chipsChildren = widget.values.map<Widget>(
      (T data) {
        final Widget child = widget.chipBuilder(context, data);
        if (_lastChipFocusNode != null) {
          _lastChipFocusNode!.requestFocus();
          return Focus(focusNode: _lastChipFocusNode, child: child);
        }
        return child;
      },
    ).toList();

    chipsChildren.add(Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(text),
        TextCaret(
          resumed: _focusNode.hasFocus,
        ),
      ],
    ));

    return GestureDetector(
      onTap: _requestKeyboard,
      child: InputDecorator(
        decoration: widget.decoration,
        isFocused: _focusNode.hasFocus,
        isEmpty: _value.text.isEmpty,
        textAlignVertical: TextAlignVertical.center,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4,
          spacing: 4,
          children: chipsChildren,
        ),
      ),
    );
  }

  String get text {
    return String.fromCharCodes(
      _value.text.codeUnits.where((int ch) => ch != kObjectReplacementChar),
    );
  }

  bool get _hasInputConnection => _connection?.attached ?? false;

  void _requestKeyboard() {
    if (_focusNode.hasFocus) {
      _openInputConnection();
    } else {
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _openInputConnection();
    } else {
      _closeInputConnectionIfNeeded();
    }
  }

  void _openInputConnection() {
    if (!_hasInputConnection) {
      _connection = TextInput.attach(this, const TextInputConfiguration());
      _connection!.setEditingState(_value);
    }
    _connection?.show();
  }

  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _connection!.close();
      _connection = null;
    }
  }

  int _countReplacements(TextEditingValue value) {
    return _countReplacementsInString(value.text);
  }

  int _countReplacementsInString(String value) {
    return value.codeUnits
      .where((int ch) => ch == kObjectReplacementChar)
      .length;
  }

  int get currentReplacementCount => _countReplacements(_value);

  void _syncTextValue() {
    final TextEditingValue currentTextEditingValue = _value;
    final int newChipCount = widget.values.length;
    final int oldChipCount = _countReplacements(currentTextEditingValue);

    String text = String.fromCharCodes(List<int>.filled(newChipCount, kObjectReplacementChar));
    if (newChipCount == oldChipCount) {
      text += this.text;
    }
    _value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _connection?.setEditingState(_value);
  }
}

class TextCaret extends StatefulWidget {
  const TextCaret({super.key, this.resumed = false});

  final bool resumed;

  @override
  TextCursorState createState() => TextCursorState();
}

class TextCursorState extends State<TextCaret> with SingleTickerProviderStateMixin {
  final Duration _duration = const Duration(milliseconds: 500);
  bool _displayed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_duration, _onTimer);
  }

  void _onTimer(Timer timer) {
    setState(() {
      _displayed = !_displayed;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Opacity(
      opacity: _displayed && widget.resumed ? 1.0 : 0.0,
      child: Container(
        width: 2.0,
        height: 20,
        color: theme.primaryColor,
      ),
    );
  }
}
