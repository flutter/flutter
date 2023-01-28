// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    title: 'Hardware Key Demo',
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Hardware Key Demo'),
      ),
      body: const Center(
        child: RawKeyboardDemo(),
      ),
    ),
  ));
}

class RawKeyboardDemo extends StatefulWidget {
  const RawKeyboardDemo({super.key});

  @override
  State<RawKeyboardDemo> createState() => _HardwareKeyDemoState();
}

class _HardwareKeyDemoState extends State<RawKeyboardDemo> {
  final FocusNode _focusNode = FocusNode();
  RawKeyEvent? _event;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, RawKeyEvent event) {
    setState(() {
      _event = event;
    });
    return KeyEventResult.ignored;
  }

  String _asHex(int value) => value != null ? '0x${value.toRadixString(16)}' : 'null';

  String _getEnumName(dynamic enumItem) {
    final String name = '$enumItem';
    final int index = name.indexOf('.');
    return index == -1 ? name : name.substring(index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Focus(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      autofocus: true,
      child: AnimatedBuilder(
        animation: _focusNode,
        builder: (BuildContext context, Widget? child) {
          if (!_focusNode.hasFocus) {
            return GestureDetector(
              onTap: () {
                _focusNode.requestFocus();
              },
              child: Text('Tap to focus', style: textTheme.headlineMedium),
            );
          }

          if (_event == null) {
            return Text('Press a key', style: textTheme.headlineMedium);
          }

          final RawKeyEventData? data = _event?.data;
          final String? modifierList = data?.modifiersPressed.keys.map<String>(_getEnumName).join(', ').replaceAll('Modifier', '');
          final List<Widget> dataText = <Widget>[
            Text('${_event.runtimeType}'),
            if (_event?.character?.isNotEmpty ?? false) Text('character produced: "${_event?.character}"'),
            Text('modifiers set: $modifierList'),
          ];
          if (data is RawKeyEventDataAndroid) {
            const int combiningCharacterMask = 0x7fffffff;
            final String codePointChar = String.fromCharCode(combiningCharacterMask & data.codePoint);
            dataText.add(Text('codePoint: ${data.codePoint} (${_asHex(data.codePoint)}: $codePointChar)'));
            final String plainCodePointChar = String.fromCharCode(combiningCharacterMask & data.plainCodePoint);
            dataText.add(Text('plainCodePoint: ${data.plainCodePoint} (${_asHex(data.plainCodePoint)}: $plainCodePointChar)'));
            dataText.add(Text('keyCode: ${data.keyCode} (${_asHex(data.keyCode)})'));
            dataText.add(Text('scanCode: ${data.scanCode} (${_asHex(data.scanCode)})'));
            dataText.add(Text('metaState: ${data.metaState} (${_asHex(data.metaState)})'));
            dataText.add(Text('source: ${data.eventSource} (${_asHex(data.eventSource)})'));
            dataText.add(Text('vendorId: ${data.vendorId} (${_asHex(data.vendorId)})'));
            dataText.add(Text('productId: ${data.productId} (${_asHex(data.productId)})'));
            dataText.add(Text('flags: ${data.flags} (${_asHex(data.flags)})'));
            dataText.add(Text('repeatCount: ${data.repeatCount} (${_asHex(data.repeatCount)})'));
          } else if (data is RawKeyEventDataFuchsia) {
            dataText.add(Text('codePoint: ${data.codePoint} (${_asHex(data.codePoint)})'));
            dataText.add(Text('hidUsage: ${data.hidUsage} (${_asHex(data.hidUsage)})'));
            dataText.add(Text('modifiers: ${data.modifiers} (${_asHex(data.modifiers)})'));
          } else if (data is RawKeyEventDataMacOs) {
            dataText.add(Text('keyCode: ${data.keyCode} (${_asHex(data.keyCode)})'));
            dataText.add(Text('characters: ${data.characters}'));
            dataText.add(Text('charactersIgnoringModifiers: ${data.charactersIgnoringModifiers}'));
            dataText.add(Text('modifiers: ${data.modifiers} (${_asHex(data.modifiers)})'));
          } else if (data is RawKeyEventDataLinux) {
            dataText.add(Text('keyCode: ${data.keyCode} (${_asHex(data.keyCode)})'));
            dataText.add(Text('scanCode: ${data.scanCode}'));
            dataText.add(Text('unicodeScalarValues: ${data.unicodeScalarValues}'));
            dataText.add(Text('modifiers: ${data.modifiers} (${_asHex(data.modifiers)})'));
          } else if (data is RawKeyEventDataWindows) {
            dataText.add(Text('keyCode: ${data.keyCode} (${_asHex(data.keyCode)})'));
            dataText.add(Text('scanCode: ${data.scanCode}'));
            dataText.add(Text('characterCodePoint: ${data.characterCodePoint}'));
            dataText.add(Text('modifiers: ${data.modifiers} (${_asHex(data.modifiers)})'));
          } else if (data is RawKeyEventDataWeb) {
            dataText.add(Text('key: ${data.key}'));
            dataText.add(Text('code: ${data.code}'));
            dataText.add(Text('metaState: ${data.metaState} (${_asHex(data.metaState)})'));
          }
          dataText.add(Text('logical: ${_event?.logicalKey}'));
          dataText.add(Text('physical: ${_event?.physicalKey}'));
          if (_event?.character != null) {
            dataText.add(Text('character: ${_event?.character}'));
          }
          for (final ModifierKey modifier in data!.modifiersPressed.keys) {
            for (final KeyboardSide side in KeyboardSide.values) {
              if (data.isModifierPressed(modifier, side: side)) {
                dataText.add(
                  Text('${_getEnumName(side)} ${_getEnumName(modifier).replaceAll('Modifier', '')} pressed'),
                );
              }
            }
          }
          final List<String> pressed = <String>['Pressed:'];
          for (final LogicalKeyboardKey key in RawKeyboard.instance.keysPressed) {
            pressed.add(key.debugName!);
          }
          dataText.add(Text(pressed.join(' ')));
          return DefaultTextStyle(
            style: textTheme.titleMedium!,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: dataText,
            ),
          );
        },
      ),
    );
  }
}
