import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A search field for the tool menu.
class ToolbarSearchField extends StatefulWidget {
  /// Create a new search field with the given [text].
  ///
  /// An [hintText] which indicates what is the awaited content.
  ///
  /// The [onTextChanged] is invoked each time the [text] is changed by the user.
  const ToolbarSearchField({
    Key? key,
    required this.hintText,
    required this.onTextChanged,
    this.text = '',
  }) : super(key: key);

  /// The current field content.
  final String text;

  /// Indicates what is the awaited content.
  final String hintText;

  /// Invoked each time the [text] is changed by the user.
  final ValueChanged<String> onTextChanged;

  @override
  _ToolbarSearchFieldState createState() => _ToolbarSearchFieldState();
}

class _ToolbarSearchFieldState extends State<ToolbarSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void initState() {
    _controller.addListener(() {
      widget.onTextChanged(
        _controller.text.replaceAll(' ', '').toLowerCase(),
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  void didUpdateWidget(covariant ToolbarSearchField oldWidget) {
    if (widget.text != _controller.text) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _controller.text = widget.text;
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  void _clear() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.clear(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
            suffix: InkWell(
              child: const Icon(Icons.close),
              onTap: _clear,
            ),
          ),
        ),
      ),
    );
  }
}
