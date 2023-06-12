part of 'device.dart';

class GenericTabletFramePainter extends CustomPainter {
  const GenericTabletFramePainter({
    this.outerBodyColor = defaultOuterBodyColor,
    this.innerBodyColor = defaultInnerBodyColor,
    this.outerBodyRadius = defaultOuterBodyRadius,
    this.innerBodyRadius = defaultInnerBodyRadius,
    this.innerBodyInsets = defaultInnerBodyInsets,
    this.screenInsets = defaultScreenInsets,
    this.buttonWidth = defaultButtonWidth,
    this.buttonColor = defaultButtonColor,
    this.screenRadius = defaultScreenRadius,
    this.rightSideButtonsGapsAndSizes = defaultRightSideButtonsGapsAndSizes,
    this.topSideButtonsGapsAndSizes = defaultTopSideButtonsGapsAndSizes,
    this.cameraBorderColor = defaultCameraBorderColor,
    this.cameraInnerColor = defaultCameraInnerColor,
    this.cameraReflectColor = defaultCameraReflectColor,
    this.cameraRadius = defaultCameraRadius,
    this.cameraBorderWidth = defaultCameraBorderWidth,
  });

  Size calculateFrameSize(Size screenSize) {
    return Size(
      screenSize.width +
          innerBodyInsets.horizontal +
          screenInsets.horizontal +
          buttonWidth,
      screenSize.height +
          innerBodyInsets.vertical +
          screenInsets.vertical +
          buttonWidth,
    );
  }

  Path createScreenPath(Size screenSize) {
    final rect = Offset(
          innerBodyInsets.left + screenInsets.left,
          innerBodyInsets.top + screenInsets.top,
        ) &
        screenSize;
    final result = Path();
    result.addRRect(RRect.fromRectAndRadius(rect, screenRadius));
    return result;
  }

  final Color outerBodyColor;
  final Radius outerBodyRadius;
  final Color innerBodyColor;
  final Radius innerBodyRadius;
  final Radius screenRadius;
  final EdgeInsets innerBodyInsets;
  final EdgeInsets screenInsets;
  final double buttonWidth;
  final Color buttonColor;
  final Color cameraBorderColor;
  final Color cameraInnerColor;
  final Color cameraReflectColor;
  final double cameraRadius;
  final double cameraBorderWidth;

  /// Starts with a gap from top to bottom, then a button size, and so on.
  final List<double> rightSideButtonsGapsAndSizes;

  /// Starts with a gap from right to left, then a button size, and so on.
  final List<double> topSideButtonsGapsAndSizes;

  static const Color defaultButtonColor = Color(0xff121515);
  static const Color defaultOuterBodyColor = Color(0xff3A4245);
  static const Radius defaultOuterBodyRadius = Radius.circular(40);
  static const Color defaultInnerBodyColor = Color(0xff121515);
  static const Color defaultCameraBorderColor = Color(0xff262C2D);
  static const Color defaultCameraInnerColor = Color(0xff121515);
  static const Color defaultCameraReflectColor = Color(0xff465256);
  static const Radius defaultInnerBodyRadius = Radius.circular(35);
  static const Radius defaultScreenRadius = Radius.circular(10);
  static const double defaultButtonWidth = 4.0;
  static const double defaultCameraRadius = 6.0;
  static const double defaultCameraBorderWidth = 4.0;
  static const List<double> defaultRightSideButtonsGapsAndSizes = [
    100,
    80,
    15,
    80,
  ];
  static const List<double> defaultTopSideButtonsGapsAndSizes = [
    50,
    80,
  ];

  static const EdgeInsets defaultInnerBodyInsets = EdgeInsets.only(
    left: 6,
    top: 6,
    right: 6,
    bottom: 6,
  );
  static const EdgeInsets defaultScreenInsets = EdgeInsets.only(
    left: 25,
    top: 120,
    right: 25,
    bottom: 80,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final bounds = Rect.fromLTWH(
      0,
      buttonWidth,
      size.width - buttonWidth,
      size.height - buttonWidth,
    );
    canvas.drawSideButtons(
      paint: paint,
      bounds: bounds,
      buttonWidth: buttonWidth,
      color: buttonColor,
      gapsAndSizes: topSideButtonsGapsAndSizes,
      inverted: true,
      side: SideButtonSide.top,
    );
    canvas.drawSideButtons(
      paint: paint,
      bounds: bounds,
      buttonWidth: buttonWidth,
      color: buttonColor,
      gapsAndSizes: rightSideButtonsGapsAndSizes,
      inverted: false,
      side: SideButtonSide.right,
    );
    canvas.drawDeviceBody(
      paint: paint,
      bounds: bounds,
      innerBodyColor: innerBodyColor,
      innerBodyInsets: innerBodyInsets,
      innerBodyRadius: innerBodyRadius,
      outerBodyColor: outerBodyColor,
      outerBodyRadius: outerBodyRadius,
    );
    canvas.drawCamera(
      paint: paint,
      center: Offset(
        (size.width - buttonWidth) * 0.5,
        buttonWidth + innerBodyInsets.top + (screenInsets.top / 2),
      ),
      borderColor: cameraBorderColor,
      borderWidth: cameraBorderWidth,
      innerColor: cameraInnerColor,
      radius: cameraRadius,
      reflectColor: cameraReflectColor,
    );
  }

  @override
  bool shouldRepaint(covariant GenericTabletFramePainter oldDelegate) {
    return false;
  }
}
