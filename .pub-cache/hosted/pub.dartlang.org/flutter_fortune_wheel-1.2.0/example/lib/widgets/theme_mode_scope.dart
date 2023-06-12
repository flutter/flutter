import 'package:flutter/material.dart';

typedef ThemeModeBuilder = Widget Function(BuildContext, ThemeMode);

abstract class ThemeModeProvider {
  ThemeMode get themeMode;

  void changeThemeMode(ThemeMode mode);

  static ThemeModeProvider of(BuildContext context) {
    final state = context.findAncestorStateOfType<_ThemeModeScopeState>();
    if (state == null) {
      throw Error();
    }
    return state;
  }
}

class ThemeModeScope extends StatefulWidget {
  final ThemeModeBuilder builder;

  const ThemeModeScope({required this.builder});

  @override
  _ThemeModeScopeState createState() => _ThemeModeScopeState();
}

class _ThemeModeScopeState extends State<ThemeModeScope>
    implements ThemeModeProvider {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get themeMode => _mode;

  void changeThemeMode(ThemeMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => widget.builder(context, _mode),
    );
  }
}
