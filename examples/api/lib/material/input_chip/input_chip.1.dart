import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Topping {
  final String name;
  final String? emoji;

  const Topping(this.name, {this.emoji});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Topping &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return 'Topping{$name}';
  }
}

const availableToppings = <Topping>[
  Topping("Avocado", emoji: "🥑"),
  Topping("Tomato", emoji: "🍅"),
  Topping("Cheese", emoji: "🧀"),
  Topping("Lettuce", emoji: "🥬"),
  Topping("Cucumber", emoji: "🥒"),
  Topping("Beans"),
];

void main() => runApp(const EditableChipFieldApp());

class EditableChipFieldApp extends StatelessWidget {
  const EditableChipFieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var _suggestions = <Topping>[];
  var _toppings = <Topping>{
    const Topping("Ham", emoji: "🍖"),
  };

  var _results = <Topping>{};

  final _chipFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toppings'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ChipsInput<Topping>(
              values: _toppings,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: 'Search'),
              focusNode: _chipFocusNode,
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
              chipBuilder: _chipBuilder,
              onTextChanged: _onSearchChanged,
            ),
          ),
          if (_results.isEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (BuildContext context, int index) {
                  return _suggestionBuilder(context, _suggestions[index]);
                },
              ),
            ),
          if (_results.isNotEmpty) ...[
            Text("You selected: ${_results.length} topping/s!"),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (BuildContext context, int index) {
                  return _resultBuilder(context, _results.elementAt(index));
                },
              ),
            )
          ],
        ],
      ),
    );
  }

  void _onSearchChanged(String value) async {
    final results = await _suggestionCallback(value);
    setState(() {
      _results = <Topping>{};
      _suggestions =
          results.where((topping) => !_toppings.contains(topping)).toList();
    });
  }

  Widget _chipBuilder(BuildContext context, Topping topping) {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      child: InputChip(
        key: ObjectKey(topping),
        label: Text(topping.name),
        avatar: CircleAvatar(
            child: Text(topping.emoji ?? topping.name[0].toUpperCase())),
        onDeleted: () => _deleteChip(topping),
        onSelected: (_) => _onChipTapped(topping),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(2),
      ),
    );
  }

  void _deleteChip(Topping topping) {
    setState(() {
      _toppings.remove(topping);
    });
  }

  Widget _suggestionBuilder(BuildContext context, Topping topping) {
    return ListTile(
      key: ObjectKey(topping),
      leading: CircleAvatar(
          child: Text(topping.emoji ?? topping.name[0].toUpperCase())),
      title: Text(topping.name),
      onTap: () => _selectSuggestion(topping),
    );
  }

  Widget _resultBuilder(BuildContext context, Topping topping) {
    return ListTile(
      key: ObjectKey(topping),
      leading: CircleAvatar(
          child: Text(topping.emoji ?? topping.name[0].toUpperCase())),
      title: Text(topping.name),
    );
  }

  void _selectSuggestion(Topping topping) {
    setState(() {
      _toppings.add(topping);
      _suggestions = List.empty();
    });
  }

  void _onChipTapped(Topping topping) {}

  void _onSubmitted(String text) {
    if (text.trim().isNotEmpty) {
      setState(() {
        _toppings = {..._toppings, Topping(text.trim())};
      });
    } else {
      _chipFocusNode.unfocus();
      setState(() {
        _results = {..._toppings};
        _toppings = <Topping>{};
      });
    }
  }

  void _onChanged(Set<Topping> data) {
    print('_onChanged: $data');
    setState(() {
      _toppings = data;
    });
  }

  FutureOr<List<Topping>> _suggestionCallback(String text) {
    if (text.isNotEmpty) {
      return availableToppings.where((topping) {
        return topping.name.toLowerCase().contains(text.toLowerCase());
      }).toList();
    }
    return const <Topping>[];
  }
}

class ChipsInput<T> extends StatefulWidget {
  final Set<T> values;

  final InputDecoration decoration;

  final FocusNode? focusNode;

  final ValueChanged<Set<T>> onChanged;
  final ValueChanged<T>? onChipTapped;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onTextChanged;

  final Widget Function(BuildContext context, T data) chipBuilder;

  const ChipsInput({
    Key? key,
    this.values = const {},
    this.decoration = const InputDecoration(),
    required this.chipBuilder,
    required this.onChanged,
    this.onChipTapped,
    this.onSubmitted,
    this.onTextChanged,
    this.focusNode,
  }) : super(key: key);

  @override
  ChipsInputState<T> createState() => ChipsInputState<T>();
}

class ChipsInputState<T> extends State<ChipsInput<T>>
    implements TextInputClient {
  static const kObjectReplacementChar = 0xFFFD;

  FocusNode? _lastChipFocusNode;

  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  TextEditingValue _value = TextEditingValue.empty;
  TextInputConnection? _connection;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);

    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    if (widget.focusNode != null) {
      //dispose here just if it was not passed from the parent widget
      _focusNode.dispose();
    }

    _scrollController.dispose();
    _closeInputConnectionIfNeeded();
    super.dispose();
  }

  @override
  TextEditingValue get currentTextEditingValue => _value;

  @override
  void updateEditingValue(TextEditingValue value) {
    print("New: '${value.text}' Old: '${_value.text}'");
    final oldCount = _countReplacements(_value);
    final newCount = _countReplacements(value);
    print("New count: $newCount Old count: $oldCount");

    setState(() {
      if (newCount < oldCount) {
        widget.onChanged(widget.values.take(newCount).toSet());
      }
      _value = value;
    });
    _scrollToEnd();
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
  void didChangeInputControl(
      TextInputControl? oldControl, TextInputControl? newControl) {}

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
    //_updateTextInputState();
    _syncTextValue();

    var chipsChildren = widget.values.map<Widget>(
      (data) {
        final child = widget.chipBuilder(context, data);
        if (_lastChipFocusNode != null) {
          _lastChipFocusNode!.requestFocus();
          return Focus(focusNode: _lastChipFocusNode, child: child);
        }
        return child;
      },
    ).toList();

    chipsChildren.add(
      SizedBox(
        height: 36.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text),
            _TextCaret(
              resumed: _focusNode.hasFocus,
            ),
          ],
        ),
      ),
    );

    _scrollToEnd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _requestKeyboard,
          child: InputDecorator(
            decoration: widget.decoration,
            isFocused: _focusNode.hasFocus,
            isEmpty: _value.text.isEmpty,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(children: chipsChildren),
            ),
          ),
        ),
      ],
    );
  }

  String get text {
    return String.fromCharCodes(
      _value.text.codeUnits.where((ch) => ch != kObjectReplacementChar),
    );
  }

  bool get _hasInputConnection => _connection?.attached == true;

  void _requestKeyboard() {
    if (_focusNode.hasFocus == true) {
      _openInputConnection();
    } else {
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  void _scrollToEnd() {
    Future.delayed(
        const Duration(milliseconds: 100),
        () => _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeIn));
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
    return value.codeUnits.where((ch) => ch == kObjectReplacementChar).length;
  }

  int get currentReplacementCount => _countReplacements(_value);

  void _syncTextValue() {
    final currentTextEditingValue = _value;
    final newChipCount = widget.values.length;
    final oldChipCount = _countReplacements(currentTextEditingValue);

    var text =
        String.fromCharCodes(List.filled(newChipCount, kObjectReplacementChar));
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

class _TextCaret extends StatefulWidget {
  const _TextCaret({
    Key? key,
    this.duration = const Duration(milliseconds: 500),
    this.resumed = false,
  }) : super(key: key);

  final Duration duration;
  final bool resumed;

  @override
  _TextCursorState createState() => _TextCursorState();
}

class _TextCursorState extends State<_TextCaret>
    with SingleTickerProviderStateMixin {
  bool _displayed = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.duration, _onTimer);
  }

  void _onTimer(Timer timer) {
    setState(() => _displayed = !_displayed);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Opacity(
        opacity: _displayed && widget.resumed ? 1.0 : 0.0,
        child: Container(
          width: 2.0,
          color: theme.primaryColor,
        ),
      ),
    );
  }
}
