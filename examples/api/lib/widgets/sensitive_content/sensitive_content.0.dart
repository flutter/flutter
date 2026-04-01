// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Flutter code sample for [SensitiveContent].

void main() => runApp(const SensitiveContentApp());

class SensitiveContentApp extends StatelessWidget {
  const SensitiveContentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFF000000),
      builder: (BuildContext context, Widget? child) {
        return const SensitiveContentExample();
      },
    );
  }
}

class SensitiveContentExample extends StatefulWidget {
  const SensitiveContentExample({super.key});

  @override
  State<SensitiveContentExample> createState() =>
      _SensitiveContentExampleState();
}

class _SensitiveContentExampleState extends State<SensitiveContentExample> {
  static const List<ContentSensitivity> _availableSensitivities =
      ContentSensitivity.values;

  final SensitiveContentService _sensitiveContentService =
      SensitiveContentService();
  ContentSensitivity _sensitivity = ContentSensitivity.autoSensitive;
  late final Future<bool> _isSupported = _sensitiveContentService.isSupported();

  void _updateSensitivity(ContentSensitivity value) {
    setState(() {
      _sensitivity = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'SensitiveContent Sample',
              style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12.0),
            const Text(
              'Choose how this screen should be treated during screen sharing.',
            ),
            const SizedBox(height: 8.0),
            Text(
              'Selected sensitivity: ${_sensitivity.name}',
              style: const TextStyle(fontSize: 15.0),
            ),
            const SizedBox(height: 16.0),
            FutureBuilder<bool>(
              future: _isSupported,
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                final String supportStatus = switch (snapshot.connectionState) {
                  ConnectionState.done =>
                    (snapshot.data ?? false) ? 'Yes' : 'No',
                  _ => 'Checking...',
                };

                return _OutlinedPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('SensitiveContentService.isSupported()'),
                      Text('Supported on this device: $supportStatus'),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
            Wrap(
              spacing: 8.0,
              children: _availableSensitivities.map((ContentSensitivity value) {
                return _SensitivityButton(
                  label: _labelFor(value),
                  value: value,
                  selected: _sensitivity == value,
                  onPressed: _updateSensitivity,
                );
              }).toList(),
            ),
            const SizedBox(height: 24.0),
            Expanded(
              child: SensitiveContent(
                sensitivity: _sensitivity,
                child: const _AccountDetailsCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns the display label used for a [ContentSensitivity] option.
String _labelFor(ContentSensitivity sensitivity) {
  return switch (sensitivity) {
    ContentSensitivity.notSensitive => 'Not sensitive',
    ContentSensitivity.autoSensitive => 'Auto',
    ContentSensitivity.sensitive => 'Sensitive',
    _ => 'Unknown',
  };
}

/// A reusable outlined container used to group related sample content.
class _OutlinedPanel extends StatelessWidget {
  const _OutlinedPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBDBDBD)),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: child,
    );
  }
}

/// A simple selectable control for changing the sample's sensitivity mode.
class _SensitivityButton extends StatelessWidget {
  const _SensitivityButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final ContentSensitivity value;
  final bool selected;
  final ValueChanged<ContentSensitivity> onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPressed(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCFD8DC) : const Color(0xFFEEEEEE),
          border: Border.all(color: const Color(0xFFBDBDBD)),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF0D47A1) : const Color(0xFF212121),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Displays the dummy account information wrapped by [SensitiveContent].
class _AccountDetailsCard extends StatelessWidget {
  const _AccountDetailsCard();

  @override
  Widget build(BuildContext context) {
    return const _OutlinedPanel(
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: _AccountDetailsContent(),
      ),
    );
  }
}

/// The static contents shown inside the sample account details panel.
class _AccountDetailsContent extends StatelessWidget {
  const _AccountDetailsContent();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Checking Account',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.0),
          Text('Account number: 123456789'),
          Text('Routing number: 987654321'),
          SizedBox(height: 12.0),
          Text('One-time passcode: 246810'),
          SizedBox(height: 12.0),
          Text(
            'Use ContentSensitivity.sensitive for screens that should be obscured when the app screen is shared.',
          ),
        ],
      ),
    );
  }
}
