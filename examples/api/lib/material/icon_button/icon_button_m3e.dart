// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This example demonstrates all Material 3 Expressive IconButton variants
/// and size options.
///
/// Import `material_3_expressive.dart` to get the M3E IconButton with
/// size variants, width variants, shape variants, and updated color tokens.
library;

import 'package:flutter/material_3_expressive.dart';

void main() => runApp(const M3EIconButtonExampleApp());

class M3EIconButtonExampleApp extends StatelessWidget {
  const M3EIconButtonExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M3E IconButton Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const M3EIconButtonExample(),
    );
  }
}

class M3EIconButtonExample extends StatefulWidget {
  const M3EIconButtonExample({super.key});

  @override
  State<M3EIconButtonExample> createState() => _M3EIconButtonExampleState();
}

class _M3EIconButtonExampleState extends State<M3EIconButtonExample> {
  final Set<String> _selected = <String>{};

  void _toggle(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('M3E IconButton Showcase')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Size Variants ---
            _SectionHeader('Size Variants (Standard)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _LabeledButton(
                  label: 'xSmall',
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite),
                    style: const ButtonStyle(size: IconButtonSize.xSmall),
                  ),
                ),
                _LabeledButton(
                  label: 'small (default)',
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite),
                    style: const ButtonStyle(size: IconButtonSize.small),
                  ),
                ),
                _LabeledButton(
                  label: 'medium',
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
                _LabeledButton(
                  label: 'large',
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite),
                    style: const ButtonStyle(size: IconButtonSize.large),
                  ),
                ),
                _LabeledButton(
                  label: 'xLarge',
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite),
                    style: const ButtonStyle(size: IconButtonSize.xLarge),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // --- All 4 Variants at Medium Size ---
            _SectionHeader('Variants (Medium)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _LabeledButton(
                  label: 'Standard',
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
                _LabeledButton(
                  label: 'Filled',
                  child: IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.settings),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
                _LabeledButton(
                  label: 'Filled Tonal',
                  child: IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.settings),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
                _LabeledButton(
                  label: 'Outlined',
                  child: IconButton.outlined(
                    onPressed: () {},
                    icon: const Icon(Icons.settings),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // --- Width Variants ---
            _SectionHeader('Width Variants (Small)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _LabeledButton(
                  label: 'narrow',
                  child: IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    style: const ButtonStyle(
                      iconButtonWidth: IconButtonWidth.narrow,
                    ),
                  ),
                ),
                _LabeledButton(
                  label: 'standard',
                  child: IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    style: const ButtonStyle(
                      iconButtonWidth: IconButtonWidth.standard,
                    ),
                  ),
                ),
                _LabeledButton(
                  label: 'wide',
                  child: IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    style: const ButtonStyle(
                      iconButtonWidth: IconButtonWidth.wide,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // --- Custom Shape Override ---
            _SectionHeader('Custom Shape Override (Medium)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _LabeledButton(
                  label: 'default',
                  child: IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.bolt),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
                _LabeledButton(
                  label: 'stadium',
                  child: IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.bolt),
                    style: const ButtonStyle(
                      size: IconButtonSize.medium,
                      shape: WidgetStatePropertyAll<OutlinedBorder>(
                        StadiumBorder(),
                      ),
                    ),
                  ),
                ),
                _LabeledButton(
                  label: 'rounded',
                  child: IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.bolt),
                    style: const ButtonStyle(
                      size: IconButtonSize.medium,
                      iconButtonWidth: IconButtonWidth.wide,
                      shape: WidgetStatePropertyAll<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16.0)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // --- Toggle / Selection ---
            _SectionHeader('Toggle Selection (Medium)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _LabeledButton(
                  label: 'Standard',
                  child: IconButton(
                    isSelected: _selected.contains('standard'),
                    onPressed: () => _toggle('standard'),
                    icon: const Icon(Icons.star_border),
                    selectedIcon: const Icon(Icons.star),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
                _LabeledButton(
                  label: 'Filled',
                  child: IconButton.filled(
                    isSelected: _selected.contains('filled'),
                    onPressed: () => _toggle('filled'),
                    icon: const Icon(Icons.bookmark_border),
                    selectedIcon: const Icon(Icons.bookmark),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
                _LabeledButton(
                  label: 'Filled Tonal',
                  child: IconButton.filledTonal(
                    isSelected: _selected.contains('tonal'),
                    onPressed: () => _toggle('tonal'),
                    icon: const Icon(Icons.favorite_border),
                    selectedIcon: const Icon(Icons.favorite),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
                _LabeledButton(
                  label: 'Outlined',
                  child: IconButton.outlined(
                    isSelected: _selected.contains('outlined'),
                    onPressed: () => _toggle('outlined'),
                    icon: const Icon(Icons.thumb_up_off_alt),
                    selectedIcon: const Icon(Icons.thumb_up),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // --- Disabled States ---
            _SectionHeader('Disabled (Medium)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _LabeledButton(
                  label: 'Standard',
                  child: IconButton(
                    onPressed: null,
                    icon: const Icon(Icons.settings),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
                _LabeledButton(
                  label: 'Filled',
                  child: IconButton.filled(
                    onPressed: null,
                    icon: const Icon(Icons.settings),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
                _LabeledButton(
                  label: 'Filled Tonal',
                  child: IconButton.filledTonal(
                    onPressed: null,
                    icon: const Icon(Icons.settings),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
                _LabeledButton(
                  label: 'Outlined',
                  child: IconButton.outlined(
                    onPressed: null,
                    icon: const Icon(Icons.settings),
                    style: const ButtonStyle(size: IconButtonSize.medium),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // --- Filled variant across all sizes ---
            _SectionHeader('Filled Variant — All Sizes'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                for (final size in IconButtonSize.values)
                  _LabeledButton(
                    label: size.name,
                    child: IconButton.filled(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      style: ButtonStyle(size: size),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // --- Theme-level overrides ---
            _SectionHeader('Theme Override (Large Wide)'),
            const Text(
              'All buttons below inherit size and width from the theme:',
            ),
            const SizedBox(height: 8),
            IconButtonTheme(
              data: const IconButtonThemeData(
                style: ButtonStyle(
                  size: IconButtonSize.large,
                  iconButtonWidth: IconButtonWidth.wide,
                ),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  IconButton(onPressed: () {}, icon: const Icon(Icons.home)),
                  IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications),
                  ),
                  IconButton.outlined(
                    onPressed: () {},
                    icon: const Icon(Icons.person),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _LabeledButton extends StatelessWidget {
  const _LabeledButton({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        child,
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
