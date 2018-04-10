// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'themes.dart';

// TBD restore platform option

class GalleryOptions {
  const GalleryOptions({
    this.theme,
    this.textScaleFactor,
    this.textDirection: TextDirection.ltr,
    this.timeDilation: 1.0,
    this.showOffscreenLayersCheckerboard: false,
    this.showRasterCacheImagesCheckerboard: false,
    this.showPerformanceOverlay: false,
  });

  final GalleryTheme theme;
  final double textScaleFactor;
  final TextDirection textDirection;
  final double timeDilation;
  final bool showPerformanceOverlay;
  final showRasterCacheImagesCheckerboard;
  final showOffscreenLayersCheckerboard;

  GalleryOptions copyWith({
    GalleryTheme theme,
    double textScaleFactor,
    TextDirection textDirection,
    double timeDilation,
    bool showPerformanceOverlay,
    bool showRasterCacheImagesCheckerboard,
    bool showOffscreenLayersCheckerboard,
  }) {
    return new GalleryOptions(
      theme: theme ?? this.theme,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      textDirection: textDirection ?? this.textDirection,
      timeDilation: timeDilation ?? this.timeDilation,
      showPerformanceOverlay: showPerformanceOverlay ?? this.showPerformanceOverlay,
      showOffscreenLayersCheckerboard: showOffscreenLayersCheckerboard ?? this.showOffscreenLayersCheckerboard,
      showRasterCacheImagesCheckerboard: showRasterCacheImagesCheckerboard ?? this.showRasterCacheImagesCheckerboard,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    final GalleryOptions typedOther = other;
    return theme == typedOther.theme
        && textScaleFactor == typedOther.textScaleFactor
        && textDirection == typedOther.textDirection
        && showPerformanceOverlay == typedOther.showPerformanceOverlay
        && showRasterCacheImagesCheckerboard == typedOther.showRasterCacheImagesCheckerboard
        && showOffscreenLayersCheckerboard == typedOther.showRasterCacheImagesCheckerboard;
  }

  @override
  int get hashCode => hashValues(
    theme,
    textScaleFactor,
    textDirection,
    timeDilation,
    showPerformanceOverlay,
    showRasterCacheImagesCheckerboard,
    showOffscreenLayersCheckerboard,
  );

  @override
  String toString() {
    return '$runtimeType($theme)';
  }
}

const double _kItemHeight = 48.0;
const EdgeInsetsDirectional _kItemPadding = const EdgeInsetsDirectional.only(start: 56.0);

class _OptionsItem extends StatelessWidget {
  const _OptionsItem({ Key key, this.child }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double textScaleFactor = MediaQuery.of(context)?.textScaleFactor ?? 1.0;

    return new Container(
      height: _kItemHeight * textScaleFactor,
      padding: _kItemPadding,
      alignment: AlignmentDirectional.centerStart,
      child: new DefaultTextStyle(
        style: DefaultTextStyle.of(context).style,
        maxLines: 2,
        overflow: TextOverflow.fade,
        child: child,
      ),
    );
  }
}

class _BooleanItem extends StatelessWidget {
  const _BooleanItem(this.title, this.value, this.onChanged);

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return new _OptionsItem(
      child: new Row(
        children: <Widget>[
          new Expanded(child: new Text(title)),
          new Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem(this.text, this.onTap);

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return new _OptionsItem(
      child: new _FlatButton(
        onPressed: onTap,
        child: new Text(text),
      ),
    );
  }
}

class _FlatButton extends StatelessWidget {
  const _FlatButton({ Key key, this.onPressed, this.child }) : super(key: key);

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new FlatButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: new DefaultTextStyle(
        style: Theme.of(context).primaryTextTheme.subhead,
        child: child,
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return new Semantics(
      header: true,
      child: new _OptionsItem(
        child: new DefaultTextStyle(
          style: Theme.of(context).textTheme.body1.copyWith(color: const Color(0xFF84EDFE)),
          child: new Text(text),
        ),
      ),
    );
  }
}

class _ThemeItem extends StatelessWidget {
  const _ThemeItem(this.options, this.onOptionsChanged);

  final GalleryOptions options;
  final ValueChanged<GalleryOptions> onOptionsChanged;

  void _handleTap() {
    int index = kAllGalleryThemes.indexOf(options.theme);
    onOptionsChanged(
      options.copyWith(
        theme: kAllGalleryThemes[(index + 1) % kAllGalleryThemes.length],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new _OptionsItem(
      child: new _FlatButton(
        onPressed: _handleTap,
        child: new Text(options.theme.name),
      ),
    );
  }
}

class _TextScaleFactorItem extends StatelessWidget {
  static final Map<double, String> textSizes = <double, String>{
    null: 'System Default',
    0.8: 'Small',
    1.0: 'Normal',
    1.3: 'Large',
    2.0: 'Huge',
  };

  static final Map<double, double> nextTextSizes = <double, double>{
    null: 0.8,
    0.8: 1.0,
    1.0: 1.3,
    1.3: 2.0,
    2.0: null,
  };

  const _TextScaleFactorItem(this.options, this.onOptionsChanged);

  final GalleryOptions options;
  final ValueChanged<GalleryOptions> onOptionsChanged;

  void _handleTap() {
    onOptionsChanged(
      options.copyWith(
        textScaleFactor: nextTextSizes[options.textScaleFactor] ?? 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new _OptionsItem(
      child: new _FlatButton(
        onPressed: _handleTap,
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Text scale factor'),
            new Text(textSizes[options.textScaleFactor] ?? '${options.textScaleFactor}X'),
          ],
        ),
      ),
    );
  }
}

class _TextDirectionItem extends StatelessWidget {
  const _TextDirectionItem(this.options, this.onOptionsChanged);

  final GalleryOptions options;
  final ValueChanged<GalleryOptions> onOptionsChanged;

  @override
  Widget build(BuildContext context) {
    return new _BooleanItem(
      'Force RTL',
      options.textDirection == TextDirection.rtl,
      (bool value) {
        onOptionsChanged(
          options.copyWith(
            textDirection: value ? TextDirection.rtl : TextDirection.ltr,
          ),
        );
      },
    );
  }
}

class _TimeDilationItem extends StatelessWidget {
  const _TimeDilationItem(this.options, this.onOptionsChanged);

  final GalleryOptions options;
  final ValueChanged<GalleryOptions> onOptionsChanged;

  void _handleTap() {
    onOptionsChanged(
      options.copyWith(
        timeDilation: options.timeDilation == 1.0 ? 20.0 : 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new _OptionsItem(
      child: new _FlatButton(
        onPressed: _handleTap,
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Slow motion'),
            new Text(options.timeDilation == 1.0 ? 'Animate at normal speed' : 'Animate slowly'),
          ],
        ),
      ),
    );
  }
}

class GalleryOptionsPage extends StatelessWidget {
  const GalleryOptionsPage({
    Key key,
    this.options,
    this.onOptionsChanged,
    this.onAboutFlutterGallery,
    this.onSendFeedback,
  }) : super(key: key);

  final GalleryOptions options;
  final ValueChanged<GalleryOptions> onOptionsChanged;
  final VoidCallback onAboutFlutterGallery;
  final VoidCallback onSendFeedback;

  List<Widget> _enabledDiagnosticItems() {
    // Boolean showFoo options with a value of null: don't display
    // the showFoo option at all.
    if (null == options.showOffscreenLayersCheckerboard
             ?? options.showRasterCacheImagesCheckerboard
             ?? options.showPerformanceOverlay)
      return const <Widget>[];

    List<Widget> items = <Widget>[
      const Divider(),
      const _Heading('Diagnostics'),
    ];

    if (options.showOffscreenLayersCheckerboard != null) {
      items.add(
        new _BooleanItem(
          'Highlight offscreen layers',
          options.showOffscreenLayersCheckerboard,
          (bool value) {
            onOptionsChanged(options.copyWith(showOffscreenLayersCheckerboard: value));
          }
        ),
      );
    }
    if (options.showRasterCacheImagesCheckerboard != null) {
      items.add(
        new _BooleanItem(
          'Highlight raster cache images',
          options.showRasterCacheImagesCheckerboard,
          (bool value) {
            onOptionsChanged(options.copyWith(showRasterCacheImagesCheckerboard: value));
          },
        ),
      );
    }
    if (options.showPerformanceOverlay != null) {
      items.add(
        new _BooleanItem(
          'Show performance overlay',
          options.showPerformanceOverlay,
          (bool value) {
            onOptionsChanged(options.copyWith(showPerformanceOverlay: value));
          },
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return new DefaultTextStyle(
      style: theme.primaryTextTheme.subhead,
      child: new ListView(
        padding: const EdgeInsets.only(bottom: 124.0),
        children: <Widget>[
          const _Heading('Display'),
          new _ThemeItem(options, onOptionsChanged),
          new _TextScaleFactorItem(options, onOptionsChanged),
          new _TextDirectionItem(options, onOptionsChanged),
          new _TimeDilationItem(options, onOptionsChanged),
        ]..addAll(
          _enabledDiagnosticItems(),
        )..addAll(
          <Widget>[
            const Divider(),
            const _Heading('Flutter gallery'),
            new _ActionItem('About Flutter gallery', onAboutFlutterGallery),
            new _ActionItem('Send feedback', onSendFeedback),
          ],
        ),
      ),
    );
  }
}
