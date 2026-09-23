// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const FindInPageDemoApp());
}

enum FindUiStyle {
  defaultFloating('Default Floating FindBar'),
  customBottomBar('Custom Bottom Pill (findBarBuilder)'),
  headlessAppBar('Headless AppBar Input (Controller Only)');

  const FindUiStyle(this.label);
  final String label;
}

class FindInPageDemoApp extends StatefulWidget {
  const FindInPageDemoApp({super.key});

  @override
  State<FindInPageDemoApp> createState() => _FindInPageDemoAppState();
}

class _FindInPageDemoAppState extends State<FindInPageDemoApp> {
  final FindInPageController _findController = FindInPageController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _headlessInputController = TextEditingController();
  final FocusNode _headlessFocusNode = FocusNode(debugLabel: 'HeadlessAppBarFind');

  bool _enableSelection = false; // Default to Find-Only mode!
  FindUiStyle _uiStyle = FindUiStyle.defaultFloating;
  int _buttonClickCount = 0;
  String _lastTriggerStatus = 'Press Cmd+F, Ctrl+F, Cmd+K, or / to invoke Find!';

  @override
  void initState() {
    super.initState();
    _findController.addListener(_syncHeadlessInput);

    // Pre-populate 'needle' once layout settles so all 12 matches across widgets
    // are immediately visible on load, and pressing Cmd+F focuses/selects the bar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _invokeFind(initialQuery: 'needle', triggerName: 'Initial Demo Load ("needle")');
      }
    });
  }

  void _syncHeadlessInput() {
    if (_headlessInputController.text != _findController.query) {
      _headlessInputController.value = TextEditingValue(
        text: _findController.query,
        selection: TextSelection.collapsed(offset: _findController.query.length),
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _handleUserConfiguredShortcut(String key, bool shift) {
    if (key == 'f' || key == 'k') {
      final label = key == 'f' ? 'Cmd+F / Ctrl+F' : 'Cmd+K / Ctrl+K';
      _invokeFind(
        initialQuery: _findController.query.isEmpty ? 'needle' : null,
        triggerName: label,
      );
    } else if (key == 'g') {
      if (!_findController.isOpen) {
        _invokeFind(initialQuery: 'needle', triggerName: 'Cmd+G');
      } else if (shift) {
        _findController.previousMatch();
        setState(() => _lastTriggerStatus = '⚡ Previous Match via Shift+Cmd+G');
      } else {
        _findController.nextMatch();
        setState(() => _lastTriggerStatus = '⚡ Next Match via Cmd+G');
      }
    }
  }

  void _invokeFind({String? initialQuery, required String triggerName}) {
    setState(() {
      _lastTriggerStatus = '⚡ Invoked via $triggerName';
    });
    _findController.open(initialQuery: initialQuery);
    if (_uiStyle == FindUiStyle.headlessAppBar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _headlessFocusNode.requestFocus();
          _headlessInputController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _headlessInputController.text.length,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _findController.removeListener(_syncHeadlessInput);
    _findController.dispose();
    _scrollController.dispose();
    _headlessInputController.dispose();
    _headlessFocusNode.dispose();
    super.dispose();
  }

  void _runPresetQuery(String query, {bool caseSensitive = false}) {
    _findController.caseSensitive = caseSensitive;
    _invokeFind(initialQuery: query, triggerName: 'Preset "$query"');
  }

  Widget _buildCustomBottomFindBar(BuildContext context, FindInPageController controller) {
    final int total = controller.matchCount;
    final int current = total == 0 ? 0 : controller.activeMatchIndex + 1;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFF0F172A),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF38BDF8), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.bolt, color: Color(0xFF38BDF8), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Custom Bottom Bar:',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Shortcuts(
                  shortcuts: controller.shortcuts,
                  child: Actions(
                    actions: controller.actions,
                    child: SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _headlessInputController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Find in page...',
                          hintStyle: TextStyle(color: Color(0xFF64748B)),
                          border: InputBorder.none,
                        ),
                        onChanged: (String v) => controller.query = v,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$current / $total',
                    style: const TextStyle(
                      color: Color(0xFFFDE047),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  color: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                  onPressed: controller.previousMatch,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  color: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  onPressed: controller.nextMatch,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  color: const Color(0xFF94A3B8),
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => controller.close(selectActiveMatch: _enableSelection),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App-Level Cmd+F Prototype (#65504)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF2563EB),
        ),
        useMaterial3: true,
      ),
      // App-level pluggable Shortcuts: the developer chooses which key bindings
      // invoke FindInPageController (e.g. Cmd+F, Ctrl+F, Cmd+K, or '/')!
      home: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
              _handleUserConfiguredShortcut('f', false),
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
              _handleUserConfiguredShortcut('f', false),
          const SingleActivator(LogicalKeyboardKey.keyG, meta: true): () =>
              _handleUserConfiguredShortcut('g', false),
          const SingleActivator(LogicalKeyboardKey.keyG, meta: true, shift: true): () =>
              _handleUserConfiguredShortcut('g', true),
          const SingleActivator(LogicalKeyboardKey.keyG, control: true): () =>
              _handleUserConfiguredShortcut('g', false),
          const SingleActivator(LogicalKeyboardKey.keyG, control: true, shift: true): () =>
              _handleUserConfiguredShortcut('g', true),
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
              _handleUserConfiguredShortcut('k', false),
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
              _handleUserConfiguredShortcut('k', false),
          const SingleActivator(LogicalKeyboardKey.slash): () {
            // Vim/GitHub style '/' shortcut when not typing in a text field!
            if (FocusManager.instance.primaryFocus?.context
                    ?.findAncestorWidgetOfExactType<EditableText>() ==
                null) {
              _invokeFind(
                initialQuery: _findController.query.isEmpty ? 'needle' : null,
                triggerName: 'Slash "/" Shortcut',
              );
            }
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (_findController.isOpen) {
              _findController.close(selectActiveMatch: _enableSelection);
              setState(() => _lastTriggerStatus = 'Closed Find Bar (Esc)');
            }
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 2,
              title: Row(
                children: <Widget>[
                  const Icon(Icons.manage_search, color: Color(0xFF38BDF8), size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Flutter Pluggable Find-in-Page (Cmd+F / Ctrl+F / Cmd+K / "/")',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Headless FindInPageController + Pluggable Invocation & UI (#65504)',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  // If the developer selects Headless AppBar UI mode, render the search input right in the AppBar!
                  if (_uiStyle == FindUiStyle.headlessAppBar)
                    Container(
                      width: 260,
                      height: 36,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.search, size: 16, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Shortcuts(
                              shortcuts: _findController.shortcuts,
                              child: Actions(
                                actions: _findController.actions,
                                child: TextField(
                                  controller: _headlessInputController,
                                  focusNode: _headlessFocusNode,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'AppBar Headless Find...',
                                    hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (String v) => _findController.query = v,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.arrow_upward, size: 15, color: Colors.white),
                            onPressed: _findController.previousMatch,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.arrow_downward, size: 15, color: Colors.white),
                            onPressed: _findController.nextMatch,
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF38BDF8)),
                    ),
                    child: Text(
                      _lastTriggerStatus,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _invokeFind(
                      initialQuery: _findController.query.isEmpty ? 'needle' : null,
                      triggerName: 'AppBar Button',
                    ),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Open Find (Cmd+F)'),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(88),
                child: Container(
                  color: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListenableBuilder(
                    listenable: _findController,
                    builder: (BuildContext context, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              const Text(
                                'Pluggable UI (findBarBuilder):',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              for (final FindUiStyle style in FindUiStyle.values)
                                ChoiceChip(
                                  selected: _uiStyle == style,
                                  selectedColor: const Color(0xFF2563EB),
                                  backgroundColor: const Color(0xFF334155),
                                  label: Text(
                                    style.label,
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                  onSelected: (bool selected) {
                                    if (selected) {
                                      setState(() => _uiStyle = style);
                                      _invokeFind(
                                        initialQuery: _findController.query.isEmpty
                                            ? 'needle'
                                            : null,
                                        triggerName: 'Switched UI to ${style.label}',
                                      );
                                    }
                                  },
                                ),
                              const SizedBox(width: 8),
                              FilterChip(
                                selected: !_enableSelection,
                                selectedColor: const Color(0xFF0284C7),
                                checkmarkColor: Colors.white,
                                backgroundColor: const Color(0xFF334155),
                                label: Text(
                                  !_enableSelection
                                      ? 'Mode: Find-Only (enableSelection: false)'
                                      : 'Mode: Selection + Find (enableSelection: true)',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                                onSelected: (bool findOnly) {
                                  setState(() {
                                    _enableSelection = !findOnly;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              const Text(
                                'Presets:',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              _PresetChip(
                                label: '"needle" (all 12 matches)',
                                onTap: () => _runPresetQuery('needle'),
                              ),
                              _PresetChip(
                                label: '"NEEDLE" (Aa case-sensitive)',
                                onTap: () => _runPresetQuery('NEEDLE', caseSensitive: true),
                              ),
                              _PresetChip(
                                label: '"WidgetSpan"',
                                onTap: () => _runPresetQuery('WidgetSpan'),
                              ),
                              _PresetChip(
                                label: '"Off-screen #20"',
                                onTap: () => _runPresetQuery('Off-screen #20'),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFDE047)),
                                ),
                                child: Text(
                                  _findController.matchCount > 0
                                      ? 'Active Highlight: ${_findController.activeMatchIndex + 1} of ${_findController.matchCount} (Query: "${_findController.query}")'
                                      : 'Matches: 0 (Query: "${_findController.query}")',
                                  style: const TextStyle(
                                    color: Color(0xFFFDE047),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            body: FindInPageScope(
              enableSelection: _enableSelection,
              controller: _findController,
              findBarBuilder: switch (_uiStyle) {
                FindUiStyle.defaultFloating => null, // Uses default SelectableRegionFindBar
                FindUiStyle.customBottomBar => _buildCustomBottomFindBar,
                FindUiStyle.headlessAppBar =>
                  (BuildContext _, FindInPageController _) => const SizedBox.shrink(),
              },
              child: SelectionArea(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                    children: <Widget>[
                      // Section 1: Pluggable Architecture Explanation
                      Card(
                        elevation: 0,
                        color: const Color(0xFFEFF6FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '1. Pluggable Invocation & Headless Controller (SelectionArea + FindInPageController)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'SelectableRegion is NOT hard-wired to a single shortcut or UI! '
                                'Your app controls how Find is invoked (try pressing Cmd+F, Ctrl+F, Cmd+K, or "/" '
                                'right now!) and how the UI is rendered (switch between the Default Floating FindBar, '
                                'a Custom Bottom Pill via findBarBuilder, or a completely Headless AppBar input). '
                                'Finding a needle in a haystack highlights passive matches in yellow (#66FFEB3B) '
                                'and the active needle in orange (#CCFF9800).',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 2: RichText + WidgetSpan inline badges
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                '2. RichText with Inline WidgetSpan Badges (U+FFFC Offset Alignment)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF334155),
                                    height: 1.6,
                                  ),
                                  children: <InlineSpan>[
                                    const TextSpan(
                                      text: 'Before inline WidgetSpan badge: lowercase needle and ',
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDBEAFE),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: const Color(0xFF93C5FD)),
                                        ),
                                        child: const Text(
                                          'BADGE needle',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1D4ED8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          ' after WidgetSpan badge: uppercase NEEDLE and mixed-case Needle! '
                                          'Because each _SelectableFragment paints its own local text range, '
                                          'character offsets never drift across embedded widgets.',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 3: Interactive Buttons & Chips
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Expanded(
                                    child: Text(
                                      '3. Interactive Buttons & Chips (Hover & Click Preserved)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Button Clicks: $_buttonClickCount',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Hover over the buttons and chips below: in Find-Only mode '
                                '(enableSelection: false), plain text keeps the normal arrow cursor while '
                                'buttons keep their pointer hand cursor and click handlers—yet their labels '
                                'still participate in Find-in-Page!',
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: <Widget>[
                                  ElevatedButton.icon(
                                    onPressed: () => setState(() => _buttonClickCount++),
                                    icon: const Icon(Icons.touch_app, size: 18),
                                    label: const Text('Elevated needle Action'),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: () => setState(() => _buttonClickCount++),
                                    icon: const Icon(Icons.bolt, size: 18),
                                    label: const Text('Tonal NEEDLE Button'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => setState(() => _buttonClickCount++),
                                    child: const Text('Outlined Needle Control'),
                                  ),
                                  const Chip(
                                    avatar: Icon(Icons.tag, size: 16),
                                    label: Text('Chip: needle-v1.0'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 4: DataTable
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                '4. Structured DataTable Cells & Multi-Column Traversal',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                  columns: const <DataColumn>[
                                    DataColumn(label: Text('Subsystem')),
                                    DataColumn(label: Text('Role in Cmd+F (needle)')),
                                    DataColumn(label: Text('Highlight Layer')),
                                  ],
                                  rows: const <DataRow>[
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('RenderParagraph')),
                                        DataCell(
                                          Text(
                                            'Exposes getPlainText() & showRangeOnScreen(needle)',
                                          ),
                                        ),
                                        DataCell(
                                          Text('Direct Canvas.drawRect inside _SelectableFragment'),
                                        ),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('SelectionArea')),
                                        DataCell(
                                          Text(
                                            'enableSelection: false + enableFind: true (Find-Only NEEDLE)',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            'Pluggable findBarBuilder or Headless FindInPageController',
                                          ),
                                        ),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('App Shortcuts')),
                                        DataCell(
                                          Text(
                                            'User-configured Cmd+F / Ctrl+F / Cmd+K / "/" needle',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            'Decoupled from SelectableRegion via Actions/Controller',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 5: Off-screen Scrollable List items
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                '5. Off-Screen Scrollable Items (Press Enter / Cmd+G / ↓ to Auto-Scroll!)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Step through matches using Enter, Cmd+G, or the ↑/↓ buttons '
                                'to watch RenderObject.showOnScreen scroll each target glyph box '
                                'smoothly into the viewport:',
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 12),
                              for (int i = 1; i <= 24; i++)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: i % 4 == 0
                                        ? const Color(0xFFFEFCE8)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: i % 4 == 0
                                          ? const Color(0xFFFDE047)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 32,
                                        height: 24,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '#$i',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          i % 4 == 0
                                              ? 'Off-screen #$i — Match target: hidden needle in scrollable SliverList row #$i (uppercase NEEDLE check)'
                                              : 'Off-screen #$i — Standard telemetry log row with no default keyword match',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: const Color(0xFF334155),
      side: const BorderSide(color: Color(0xFF475569)),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      onPressed: onTap,
    );
  }
}
