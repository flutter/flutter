import 'package:flutter/material.dart';

class ValueNotifier<T> extends ChangeNotifier {
  ValueNotifier({required T value}) : _value = value;

  T _value;
  T get value => _value;
  set value(T v) {
    _value = v;
    notifyListeners();
  }
}

class WindowSettings {
  WindowSettings(
      {Size regularSize = const Size(400, 300),
      Size popupSize = const Size(200, 200),
      Rect anchorRect = const Rect.fromLTWH(0, 0, 1000, 1000),
      bool anchorToWindow = false})
      : _regularSize = ValueNotifier(value: regularSize),
        _popupSize = ValueNotifier(value: popupSize),
        _anchorRect = ValueNotifier(value: anchorRect),
        _anchorToWindow = ValueNotifier(value: anchorToWindow);

  final ValueNotifier<Size> _regularSize;
  ValueNotifier<Size> get regularSizeNotifier => _regularSize;
  set regularSize(Size value) {
    _regularSize.value = value;
  }

  final ValueNotifier<Size> _popupSize;
  ValueNotifier<Size> get popupSizeNotifier => _popupSize;
  set popupSize(Size value) {
    _popupSize.value = value;
  }

  final ValueNotifier<Rect> _anchorRect;
  ValueNotifier<Rect> get anchorRectNotifier => _anchorRect;
  set anchorRect(Rect value) {
    _anchorRect.value = value;
  }

  final ValueNotifier<bool> _anchorToWindow;
  ValueNotifier<bool> get anchorToWindowNotifier => _anchorToWindow;
  set anchorToWindow(bool value) {
    _anchorToWindow.value = value;
  }
}
