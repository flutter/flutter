// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:math' as math;

import 'package:ui/src/engine.dart' as engine;
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

void main() async {
  await ui_web.bootstrapEngine(
    runApp: () {
      final demoApp = HtmlInCanvasDemoApp();
      demoApp.start();
    },
  );
}

class HtmlInCanvasDemoApp {
  HtmlInCanvasDemoApp() {
    _initPlatformViews();
    _initDomEvents();
  }

  int _selectedTab = 0; // 0: BackdropFilter, 1: Interleaving, 2: Security
  double _time = 0.0;
  double _lastTimestamp = 0.0;
  double _fps = 60.0;
  int _frameCount = 0;
  double _fpsTimer = 0.0;

  static const int kViewIdScene1 = 101;
  static const int kViewIdScene2 = 102;
  static const int kViewIdScene3 = 103;

  void _initPlatformViews() {
    // Scene 1: Interactive HTML element for BackdropFilter blur demonstration
    ui_web.platformViewRegistry.registerViewFactory('demo-html-element-scene1', (int viewId) {
      final engine.DomHTMLDivElement container = engine.createDomHTMLDivElement();
      container.id = 'scene1-element';
      container.setAttribute(
        'style',
        'width: 100%; height: 100%; background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); '
            'border-radius: 16px; box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3); padding: 24px; '
            'box-sizing: border-box; color: #ffffff; font-family: system-ui, -apple-system, sans-serif; '
            'display: flex; flex-direction: column; justify-content: space-between;',
      );

      final engine.DomElement title = engine.domDocument.createElement('h3');
      title.innerText = 'Interactive HTML Platform View';
      title.setAttribute('style', 'margin: 0 0 12px 0; font-size: 20px; color: #64B5F6;');

      final engine.DomHTMLParagraphElement description = engine.createDomHTMLParagraphElement();
      description.innerText = 'This is a real HTML DOM element composited directly into the single CanvasKit WebGL texture via texElementSubImage2D.';
      description.setAttribute('style', 'margin: 0 0 16px 0; font-size: 14px; line-height: 1.5;');

      final engine.DomHTMLInputElement input = engine.createDomHTMLInputElement();
      input.type = 'text';
      input.value = 'Edit this HTML input while blurred!';
      input.setAttribute(
        'style',
        'width: 100%; padding: 10px 14px; border-radius: 8px; border: 1px solid rgba(255, 255, 255, 0.3); '
            'background: rgba(255, 255, 255, 0.15); color: #ffffff; font-size: 14px; box-sizing: border-box; outline: none;',
      );

      final engine.DomHTMLButtonElement button = engine.createDomHTMLButtonElement();
      button.innerText = 'Interactive HTML Button';
      button.setAttribute(
        'style',
        'padding: 10px 20px; border-radius: 8px; border: none; background: #4CAF50; color: #ffffff; '
            'font-weight: bold; cursor: pointer; margin-top: 12px;',
      );

      container.appendChild(title);
      container.appendChild(description);
      container.appendChild(input);
      container.appendChild(button);
      return container;
    });

    // Scene 2: Middle-layer HTML element for 3-layer interleaving demonstration
    ui_web.platformViewRegistry.registerViewFactory('demo-html-element-scene2', (int viewId) {
      final engine.DomHTMLDivElement card = engine.createDomHTMLDivElement();
      card.id = 'scene2-element';
      card.setAttribute(
        'style',
        'width: 100%; height: 100%; background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); '
            'border-radius: 16px; box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3); padding: 24px; '
            'box-sizing: border-box; color: #ffffff; font-family: system-ui, -apple-system, sans-serif; '
            'display: flex; flex-direction: column; justify-content: center; align-items: center;',
      );

      final engine.DomElement title = engine.domDocument.createElement('h3');
      title.innerText = 'Layer 2: HTML Content (Middle)';
      title.setAttribute('style', 'margin: 0 0 12px 0;');

      final engine.DomHTMLDivElement badge = engine.createDomHTMLDivElement();
      badge.innerText = 'Single CanvasKit Surface • Zero Overlays';
      badge.setAttribute(
        'style',
        'background: rgba(0, 0, 0, 0.25); padding: 6px 16px; border-radius: 20px; font-size: 13px; font-weight: 600;',
      );

      card.appendChild(title);
      card.appendChild(badge);
      return card;
    });

    // Scene 3: Security & origin boundary demo
    ui_web.platformViewRegistry.registerViewFactory('demo-html-element-scene3', (int viewId) {
      final engine.DomHTMLDivElement container = engine.createDomHTMLDivElement();
      container.id = 'scene3-element';
      container.setAttribute(
        'style',
        'width: 100%; height: 100%; background: #1e1e24; border-radius: 16px; border: 1px solid #3f3f46; '
            'padding: 24px; box-sizing: border-box; color: #e4e4e7; font-family: system-ui, -apple-system, sans-serif;',
      );

      final engine.DomElement title = engine.domDocument.createElement('h3');
      title.innerText = 'Origin Isolation & Security Guard';
      title.setAttribute('style', 'color: #ef4444; margin: 0 0 12px 0;');

      final engine.DomHTMLParagraphElement p = engine.createDomHTMLParagraphElement();
      p.innerText = 'Blink CanvasDrawElement enforces web platform security boundaries. Cross-origin frames without CORS headers cannot expose untainted pixels to WebGL, and browser hit-testing preserves sandboxed interaction via updateElementGeometry.';
      p.setAttribute('style', 'line-height: 1.6;');

      final engine.DomHTMLDivElement statusBox = engine.createDomHTMLDivElement();
      statusBox.innerText = 'Origin Clean: SECURED • Hit-testing: DELEGATED TO BLINK';
      statusBox.setAttribute(
        'style',
        'background: rgba(239, 68, 68, 0.15); border: 1px solid #ef4444; border-radius: 8px; '
            'padding: 12px; margin-top: 16px; font-family: monospace; font-size: 12px;',
      );

      container.appendChild(title);
      container.appendChild(p);
      container.appendChild(statusBox);
      return container;
    });

    // Render content for the platform views
    engine.PlatformViewManager.instance.renderContent(
      'demo-html-element-scene1',
      kViewIdScene1,
      null,
    );
    engine.PlatformViewManager.instance.renderContent(
      'demo-html-element-scene2',
      kViewIdScene2,
      null,
    );
    engine.PlatformViewManager.instance.renderContent(
      'demo-html-element-scene3',
      kViewIdScene3,
      null,
    );
  }

  void _initDomEvents() {
    engine.domWindow.addEventListener(
      'pointerdown',
      (engine.DomEvent event) {
        final mouseEvent = event as engine.DomMouseEvent;
        final double x = mouseEvent.clientX;
        final double y = mouseEvent.clientY;

        if (y >= 70 && y <= 110) {
          if (x >= 40 && x <= 250) {
            _selectedTab = 0;
          } else if (x >= 260 && x <= 490) {
            _selectedTab = 1;
          } else if (x >= 500 && x <= 750) {
            _selectedTab = 2;
          }
        }
      }.toJS,
    );
  }

  void start() {
    _renderLoop(0.0);
  }

  void _renderLoop(double timestamp) {
    if (_lastTimestamp != 0.0) {
      final double delta = (timestamp - _lastTimestamp) / 1000.0;
      _time += delta;
      _frameCount++;
      _fpsTimer += delta;
      if (_fpsTimer >= 0.5) {
        _fps = _frameCount / _fpsTimer;
        _frameCount = 0;
        _fpsTimer = 0.0;
      }
    }
    _lastTimestamp = timestamp;

    _renderFrame();
    engine.domWindow.requestAnimationFrame((JSNumber ts) {
      _renderLoop(ts.toDartDouble);
    });
  }

  void _renderFrame() {
    final engine.EngineFlutterWindow? implicitView =
        engine.EnginePlatformDispatcher.instance.implicitView;
    if (implicitView == null) {
      return;
    }

    final ui.Size size = implicitView.physicalSize;
    if (size.isEmpty) {
      return;
    }

    final double width = size.width;
    final double height = size.height;

    final sb = ui.SceneBuilder();

    // 1. Render App Header and Navigation Bar
    final headerRecorder = ui.PictureRecorder();
    final headerCanvas = ui.Canvas(headerRecorder);

    // Dark background for whole viewport
    headerCanvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint()..color = const ui.Color(0xFF0F172A),
    );

    // Header Background Bar
    headerCanvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width, 60),
      ui.Paint()..color = const ui.Color(0xFF1E293B),
    );

    // Header Title
    final ui.Paragraph titleParagraph = _buildText(
      'Flutter Web: SingleSurfaceRasterizer (HTML-in-Canvas Compositing)',
      fontSize: 18,
      fontWeight: ui.FontWeight.bold,
      color: const ui.Color(0xFF38BDF8),
    );
    headerCanvas.drawParagraph(titleParagraph, const ui.Offset(40, 18));

    // FPS & Architecture badge
    final ui.Paragraph infoParagraph = _buildText(
      'FPS: ${_fps.toStringAsFixed(1)} | 1 Surface | texElementSubImage2D',
      fontWeight: ui.FontWeight.w600,
      color: const ui.Color(0xFF4ADE80),
    );
    headerCanvas.drawParagraph(infoParagraph, ui.Offset(math.max(width - 420, 500), 20));

    // Tab buttons
    _drawTab(
      headerCanvas,
      0,
      '1. BackdropFilter over HTML',
      const ui.Rect.fromLTWH(40, 70, 210, 36),
    );
    _drawTab(headerCanvas, 1, '2. 3-Layer Interleaving', const ui.Rect.fromLTWH(260, 70, 210, 36));
    _drawTab(
      headerCanvas,
      2,
      '3. Origin Isolation Security',
      const ui.Rect.fromLTWH(480, 70, 230, 36),
    );

    sb.addPicture(ui.Offset.zero, headerRecorder.endRecording());

    // 2. Render Selected Scene
    switch (_selectedTab) {
      case 0:
        _renderScene1BackdropFilter(sb, width, height);
      case 1:
        _renderScene2Interleaving(sb, width, height);
      case 2:
        _renderScene3Security(sb, width, height);
    }

    final ui.Scene scene = sb.build();
    implicitView.render(scene);
  }

  void _drawTab(ui.Canvas canvas, int tabIndex, String label, ui.Rect rect) {
    final isSelected = _selectedTab == tabIndex;
    final rrect = ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(8));

    // Tab Background
    canvas.drawRRect(
      rrect,
      ui.Paint()..color = isSelected ? const ui.Color(0xFF2563EB) : const ui.Color(0xFF334155),
    );

    // Tab Text
    final ui.Paragraph p = _buildText(
      label,
      fontSize: 13,
      fontWeight: isSelected ? ui.FontWeight.bold : ui.FontWeight.normal,
      color: isSelected ? const ui.Color(0xFFFFFFFF) : const ui.Color(0xFF94A3B8),
    );
    canvas.drawParagraph(p, ui.Offset(rect.left + 14, rect.top + 9));
  }

  void _renderScene1BackdropFilter(ui.SceneBuilder sb, double width, double height) {
    // Background vector grid
    final bgRecorder = ui.PictureRecorder();
    final bgCanvas = ui.Canvas(bgRecorder);

    final bgPaint = ui.Paint()
      ..color = const ui.Color(0x1538BDF8)
      ..strokeWidth = 1.0;
    for (double x = 0; x < width; x += 40) {
      bgCanvas.drawLine(ui.Offset(x, 120), ui.Offset(x, height), bgPaint);
    }
    for (double y = 120; y < height; y += 40) {
      bgCanvas.drawLine(ui.Offset(0, y), ui.Offset(width, y), bgPaint);
    }

    // Explanation card
    final ui.Paragraph note = _buildText(
      'Scene 1: Real-time Skia BackdropFilter applied directly over an interactive HTML DOM element.\n'
      'The blur radius oscillates in real-time. Notice the HTML input remains fully interactive while blurred!',
      fontSize: 15,
      color: const ui.Color(0xFFE2E8F0),
    );
    bgCanvas.drawParagraph(note, const ui.Offset(40, 125));

    sb.addPicture(ui.Offset.zero, bgRecorder.endRecording());

    // Layer 1: The HTML Platform View
    const pvX = 60.0;
    const pvY = 190.0;
    const pvW = 440.0;
    const pvH = 280.0;
    sb.addPlatformView(kViewIdScene1, offset: const ui.Offset(pvX, pvY), width: pvW, height: pvH);

    // Layer 2: Overlapping Flutter Frosted Glass card with oscillating BackdropFilter blur
    final double blurOscillation = (math.sin(_time * 2.5) + 1.0) / 2.0; // 0.0 to 1.0
    final double blurRadius = 4.0 + blurOscillation * 20.0; // 4px to 24px

    final double fgX = 240.0 + math.sin(_time * 1.5) * 30.0;
    const fgY = 240.0;
    const fgW = 380.0;
    const fgH = 260.0;
    final fgRect = ui.Rect.fromLTWH(fgX, fgY, fgW, fgH);
    final fgRRect = ui.RRect.fromRectAndRadius(fgRect, const ui.Radius.circular(16));

    // Clip to rounded card
    sb.pushClipRRect(fgRRect, clipBehavior: ui.Clip.antiAlias);

    // Apply BackdropFilter blur over the HTML element below
    sb.pushBackdropFilter(ui.ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius));

    // Paint translucent glass tint and vector UI inside the card
    final fgRecorder = ui.PictureRecorder();
    final fgCanvas = ui.Canvas(fgRecorder);

    // Translucent glass gradient
    final tintPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(fgX, fgY),
        ui.Offset(fgX + fgW, fgY + fgH),
        <ui.Color>[const ui.Color(0x55FFFFFF), const ui.Color(0x1AFFFFFF)],
      );
    fgCanvas.drawRRect(fgRRect, tintPaint);

    // Glass border
    final borderPaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const ui.Color(0x80FFFFFF);
    fgCanvas.drawRRect(fgRRect, borderPaint);

    // Glass card content
    final ui.Paragraph glassTitle = _buildText(
      'Flutter Glassmorphism Overlay',
      fontSize: 16,
      fontWeight: ui.FontWeight.bold,
    );
    fgCanvas.drawParagraph(glassTitle, ui.Offset(fgX + 20, fgY + 24));

    final ui.Paragraph glassMetrics = _buildText(
      'Live Skia Blur: ${blurRadius.toStringAsFixed(1)}px\n'
      'Filter Pipeline: Hardware WebGL SkImage\n'
      'Zero DOM overlay elements created',
      fontSize: 13,
      color: const ui.Color(0xFFF1F5F9),
    );
    fgCanvas.drawParagraph(glassMetrics, ui.Offset(fgX + 20, fgY + 60));

    // Draw glowing Flutter vector icon
    final iconPaint = ui.Paint()..color = const ui.Color(0xFF38BDF8);
    fgCanvas.drawCircle(ui.Offset(fgX + fgW - 45, fgY + 45), 18, iconPaint);

    sb.addPicture(ui.Offset.zero, fgRecorder.endRecording());

    sb.pop(); // Pop backdrop filter
    sb.pop(); // Pop clip
  }

  void _renderScene2Interleaving(ui.SceneBuilder sb, double width, double height) {
    // Layer 1 (Bottom): Animated Flutter Vector Graphics
    final bottomRecorder = ui.PictureRecorder();
    final bottomCanvas = ui.Canvas(bottomRecorder);

    final ui.Paragraph note = _buildText(
      'Scene 2: True 3-Layer Interleaving in a Single Surface.\n'
      'Layer 1 (Flutter Vector Background) -> Layer 2 (HTML Platform View) -> Layer 3 (Flutter Vector FAB & Badge).',
      fontSize: 15,
      color: const ui.Color(0xFFE2E8F0),
    );
    bottomCanvas.drawParagraph(note, const ui.Offset(40, 125));

    // Animated rotating vector rings behind the HTML element
    const centerX = 340.0;
    const centerY = 330.0;
    bottomCanvas.save();
    bottomCanvas.translate(centerX, centerY);
    bottomCanvas.rotate(_time * 0.8);

    final ringPaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..shader = ui.Gradient.sweep(ui.Offset.zero, <ui.Color>[
        const ui.Color(0xFFFF007A),
        const ui.Color(0xFF7928CA),
        const ui.Color(0xFF0070F3),
        const ui.Color(0xFFFF007A),
      ]);
    bottomCanvas.drawCircle(ui.Offset.zero, 180, ringPaint);

    // Decorative rotating rays
    for (var i = 0; i < 8; i++) {
      final double angle = i * math.pi / 4;
      final double rayX = math.cos(angle) * 220;
      final double rayY = math.sin(angle) * 220;
      bottomCanvas.drawLine(
        ui.Offset.zero,
        ui.Offset(rayX, rayY),
        ui.Paint()
          ..color = const ui.Color(0x30FFFFFF)
          ..strokeWidth = 3.0,
      );
    }
    bottomCanvas.restore();

    sb.addPicture(ui.Offset.zero, bottomRecorder.endRecording());

    // Layer 2 (Middle): HTML Platform View
    const pvX = 120.0;
    const pvY = 200.0;
    const pvW = 440.0;
    const pvH = 260.0;
    sb.addPlatformView(kViewIdScene2, offset: const ui.Offset(pvX, pvY), width: pvW, height: pvH);

    // Layer 3 (Top): Flutter Vector Overlays (FAB and status badge directly on top of HTML view)
    final topRecorder = ui.PictureRecorder();
    final topCanvas = ui.Canvas(topRecorder);

    // Floating Action Button overlapping bottom-right corner of HTML view
    const double fabX = pvX + pvW - 40.0;
    const double fabY = pvY + pvH - 40.0;

    // Glowing shadow
    topCanvas.drawCircle(
      const ui.Offset(fabX, fabY),
      34,
      ui.Paint()
        ..color = const ui.Color(0x8038BDF8)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12),
    );

    // FAB Body
    topCanvas.drawCircle(
      const ui.Offset(fabX, fabY),
      28,
      ui.Paint()..color = const ui.Color(0xFF0284C7),
    );

    // FAB '+' Icon
    final plusPaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..strokeWidth = 3.5
      ..strokeCap = ui.StrokeCap.round;
    topCanvas.drawLine(
      const ui.Offset(fabX - 12, fabY),
      const ui.Offset(fabX + 12, fabY),
      plusPaint,
    );
    topCanvas.drawLine(
      const ui.Offset(fabX, fabY - 12),
      const ui.Offset(fabX, fabY + 12),
      plusPaint,
    );

    // Floating Top Badge overlapping top-left of HTML view
    const badgeRect = ui.Rect.fromLTWH(pvX - 20, pvY - 16, 210, 36);
    final badgeRRect = ui.RRect.fromRectAndRadius(badgeRect, const ui.Radius.circular(18));

    topCanvas.drawRRect(badgeRRect, ui.Paint()..color = const ui.Color(0xFFE11D48));
    final ui.Paragraph badgeText = _buildText(
      'Layer 3: Flutter Vector Overlay',
      fontSize: 12,
      fontWeight: ui.FontWeight.bold,
    );
    topCanvas.drawParagraph(badgeText, ui.Offset(badgeRect.left + 14, badgeRect.top + 10));

    sb.addPicture(ui.Offset.zero, topRecorder.endRecording());
  }

  void _renderScene3Security(ui.SceneBuilder sb, double width, double height) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final ui.Paragraph note = _buildText(
      'Scene 3: Cross-Origin Iframe Security & Origin Isolation.\n'
      'The CanvasDrawElement Blink specification provides hardware-accelerated drawing without compromising origin boundaries.',
      fontSize: 15,
      color: const ui.Color(0xFFE2E8F0),
    );
    canvas.drawParagraph(note, const ui.Offset(40, 125));

    // Comparison security cards
    _drawSecurityCard(
      canvas,
      const ui.Rect.fromLTWH(40, 480, 340, 140),
      title: 'Same-Origin Content',
      color: const ui.Color(0xFF22C55E),
      details: '• Full pixel fidelity in WebGL\n• BackdropFilters & shaders supported\n• Snapshot uploaded via texElementSubImage2D',
    );

    _drawSecurityCard(
      canvas,
      const ui.Rect.fromLTWH(400, 480, 360, 140),
      title: 'Cross-Origin Sandboxed Iframe',
      color: const ui.Color(0xFFEF4444),
      details: '• Origin boundary strictly enforced\n• Disallows pixel exfiltration to JavaScript\n• Hit-testing delegated seamlessly by Blink',
    );

    sb.addPicture(ui.Offset.zero, recorder.endRecording());

    // HTML platform view representing sandboxed frame
    sb.addPlatformView(kViewIdScene3, offset: const ui.Offset(40, 180), width: 720, height: 260);
  }

  void _drawSecurityCard(
    ui.Canvas canvas,
    ui.Rect rect, {
    required String title,
    required ui.Color color,
    required String details,
  }) {
    final rrect = ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(12));
    canvas.drawRRect(rrect, ui.Paint()..color = const ui.Color(0xFF1E293B));
    canvas.drawRRect(
      rrect,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color,
    );

    final ui.Paragraph titleP = _buildText(
      title,
      fontSize: 15,
      fontWeight: ui.FontWeight.bold,
      color: color,
    );
    canvas.drawParagraph(titleP, ui.Offset(rect.left + 16, rect.top + 14));

    final ui.Paragraph detailsP = _buildText(
      details,
      fontSize: 13,
      color: const ui.Color(0xFFCBD5E1),
    );
    canvas.drawParagraph(detailsP, ui.Offset(rect.left + 16, rect.top + 42));
  }

  ui.Paragraph _buildText(
    String text, {
    double fontSize = 14.0,
    ui.FontWeight fontWeight = ui.FontWeight.normal,
    ui.Color color = const ui.Color(0xFFFFFFFF),
  }) {
    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: fontSize, fontWeight: fontWeight));
    pb.pushStyle(ui.TextStyle(color: color));
    pb.addText(text);
    pb.pop();
    final ui.Paragraph p = pb.build();
    p.layout(const ui.ParagraphConstraints(width: 800));
    return p;
  }
}
