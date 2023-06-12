part of 'device.dart';

class GenericLaptopFramePainter extends CustomPainter {
  const GenericLaptopFramePainter({
    required this.platform,
    required this.windowPosition,
    this.outerBodyColor = defaultOuterBodyColor,
    this.innerBodyColor = defaultInnerBodyColor,
    this.outerBodyRadius = defaultOuterBodyRadius,
    this.innerBodyRadius = defaultInnerBodyRadius,
    this.innerBodyInsets = defaultInnerBodyInsets,
    this.screenInsets = defaultScreenInsets,
    this.screenRadius = defaultScreenRadius,
    this.windowRadius = defaultWindowRadius,
    this.bodyHeight = defaultBodyHeight,
    this.bodyPadHeight = defaultBodyPadHeight,
    this.bodyInsets = defaultBodyInsets,
    this.cameraBorderColor = defaultCameraBorderColor,
    this.cameraInnerColor = defaultCameraInnerColor,
    this.cameraReflectColor = defaultCameraReflectColor,
    this.cameraRadius = defaultCameraRadius,
    this.cameraBorderWidth = defaultCameraBorderWidth,
    this.baseBodyBottomColor = defaultBaseBodyBottomColor,
    this.baseBodyTopColor = defaultBaseBodyTopColor,
    this.baseBodyPadColor = defaultBaseBodyPadColor,
  });

  Size calculateFrameSize(Size screenSize) {
    return Size(
      screenSize.width +
          innerBodyInsets.horizontal +
          screenInsets.horizontal +
          defaultBodyInsets * 2,
      screenSize.height +
          innerBodyInsets.vertical +
          screenInsets.vertical +
          bodyHeight +
          bodyPadHeight,
    );
  }

  Size get effectiveWindowSize {
    return Size(
      windowPosition.width,
      windowPosition.height - barHeight,
    );
  }

  double get barHeight {
    switch (platform) {
      case TargetPlatform.macOS:
        return 30;
      default:
        return 40;
    }
  }

  Offset get _windowLocation {
    return Offset(
      defaultBodyInsets +
          innerBodyInsets.left +
          screenInsets.left +
          windowPosition.left,
      innerBodyInsets.top + screenInsets.top + windowPosition.top,
    );
  }

  Path createScreenPath(Size screenSize) {
    final result = Path();
    result.addRRect(
      RRect.fromRectAndCorners(
        (_windowLocation + Offset(0, barHeight)) & effectiveWindowSize,
        bottomLeft: windowRadius,
        bottomRight: windowRadius,
      ),
    );
    return result;
  }

  final Rect windowPosition;
  final TargetPlatform platform;
  final Color outerBodyColor;
  final Radius outerBodyRadius;
  final Color innerBodyColor;
  final Radius innerBodyRadius;
  final Radius screenRadius;
  final Radius windowRadius;
  final EdgeInsets innerBodyInsets;
  final EdgeInsets screenInsets;
  final double bodyHeight;
  final double bodyPadHeight;
  final double bodyInsets;
  final Color cameraBorderColor;
  final Color cameraInnerColor;
  final Color cameraReflectColor;
  final double cameraRadius;
  final double cameraBorderWidth;
  final Color baseBodyTopColor;
  final Color baseBodyBottomColor;
  final Color baseBodyPadColor;

  static const Color defaultBaseBodyTopColor = Color(0xff3A4245);
  static const Color defaultBaseBodyBottomColor = Color(0xff323434);
  static const Color defaultBaseBodyPadColor = Color(0xff222626);
  static const Color defaultOuterBodyColor = Color(0xff3A4245);
  static const Radius defaultOuterBodyRadius = Radius.circular(30);
  static const Color defaultInnerBodyColor = Color(0xff121515);
  static const Radius defaultInnerBodyRadius = Radius.circular(20);
  static const Radius defaultScreenRadius = Radius.circular(10);
  static const Radius defaultWindowRadius = Radius.circular(6);
  static const double defaultBodyHeight = 60;
  static const double defaultBodyPadHeight = 16;
  static const double defaultBodyInsets = 200;
  static const Color defaultCameraBorderColor = Color(0xff262C2D);
  static const Color defaultCameraInnerColor = Color(0xff121515);
  static const Color defaultCameraReflectColor = Color(0xff465256);
  static const double defaultCameraRadius = 8.0;
  static const double defaultCameraBorderWidth = 5.0;

  static const EdgeInsets defaultInnerBodyInsets = EdgeInsets.only(
    left: 6,
    top: 6,
    right: 6,
    bottom: 0,
  );
  static const EdgeInsets defaultScreenInsets = EdgeInsets.only(
    left: 20,
    top: 80,
    right: 20,
    bottom: 100,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final bounds = Rect.fromLTWH(
      defaultBodyInsets,
      0,
      size.width - defaultBodyInsets * 2,
      size.height - bodyPadHeight - bodyHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        bounds,
        topLeft: outerBodyRadius,
        topRight: outerBodyRadius,
      ),
      paint..color = outerBodyColor,
    );
    final innerBounds = Rect.fromCenter(
      center: bounds.center,
      width: bounds.width - innerBodyInsets.horizontal,
      height: bounds.height - innerBodyInsets.vertical,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        innerBounds,
        topLeft: innerBodyRadius,
        topRight: innerBodyRadius,
      ),
      paint..color = innerBodyColor,
    );

    canvas.drawCamera(
      paint: paint,
      center: Offset(
        bounds.center.dx,
        innerBodyInsets.top + (screenInsets.top / 2),
      ),
      borderColor: cameraBorderColor,
      borderWidth: cameraBorderWidth,
      innerColor: cameraInnerColor,
      radius: cameraRadius,
      reflectColor: cameraReflectColor,
    );

    // Body
    final padRadius = Radius.circular(bodyPadHeight);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Offset(
              outerBodyRadius.x + bodyPadHeight * 4,
              bounds.bottom + bodyHeight - 1,
            ) &
            Size(
              size.width - 2 * outerBodyRadius.x - bodyPadHeight * 8,
              bodyPadHeight + 1,
            ),
        bottomLeft: padRadius,
        bottomRight: padRadius,
      ),
      paint..color = baseBodyPadColor,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Offset(0, bounds.bottom + bodyHeight * 0.2 - 1) &
            Size(size.width, bodyHeight * 0.8 + 1),
        bottomLeft: outerBodyRadius,
        bottomRight: outerBodyRadius,
      ),
      paint..color = baseBodyBottomColor,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Offset(0, bounds.bottom) & Size(size.width, bodyHeight * 0.2),
        topLeft: Radius.circular(innerBodyRadius.x * 0.5),
        topRight: Radius.circular(innerBodyRadius.x * 0.5),
      ),
      paint..color = baseBodyTopColor,
    );

    const bodyNotchWidth = 300.0;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Offset(
              bounds.center.dx - bodyNotchWidth * 0.5,
              bounds.bottom + bodyHeight * 0.2 - 1,
            ) &
            Size(bodyNotchWidth, bodyHeight * 0.2),
        bottomLeft: Radius.circular(bodyHeight * 0.2),
        bottomRight: Radius.circular(bodyHeight * 0.2),
      ),
      paint..color = baseBodyTopColor,
    );

    final screenBounds = Rect.fromLTWH(
      defaultBodyInsets + innerBodyInsets.left + screenInsets.left,
      innerBodyInsets.top + screenInsets.top,
      bounds.width - innerBodyInsets.horizontal - screenInsets.horizontal,
      bounds.height - innerBodyInsets.vertical - screenInsets.vertical,
    );
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        screenBounds,
        screenRadius,
      ),
    );
    canvas.drawDefaultWallpaper(
      platform: platform,
      bounds: screenBounds,
    );

    final windowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          _windowLocation & effectiveWindowSize,
          windowRadius,
        ),
      );
    canvas.drawPath(
      windowPath,
      Paint()
        ..blendMode = BlendMode.multiply
        ..color = const Color(0xFF3F2548).withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.outer,
          56,
        ),
    );

    canvas.drawWindowBar(
      platform: platform,
      bounds: _windowLocation &
          Size(
            windowPosition.width,
            barHeight,
          ),
      windowRadius: windowRadius,
    );
  }

  @override
  bool shouldRepaint(covariant GenericLaptopFramePainter oldDelegate) {
    return false;
  }
}
