import 'dart:ui' as ui;
import 'package:flutter/material.dart';

extension GenericDeviceFramePainterExtensions on Canvas {
  void drawDeviceBody({
    required final paint,
    required Rect bounds,
    required Color outerBodyColor,
    required Radius outerBodyRadius,
    required Color innerBodyColor,
    required Radius innerBodyRadius,
    required EdgeInsets innerBodyInsets,
  }) {
    drawRRect(
      RRect.fromRectAndRadius(bounds, outerBodyRadius),
      paint..color = outerBodyColor,
    );
    bounds = Rect.fromCenter(
      center: bounds.center,
      width: bounds.width - innerBodyInsets.horizontal,
      height: bounds.height - innerBodyInsets.vertical,
    );
    drawRRect(
      RRect.fromRectAndRadius(bounds, innerBodyRadius),
      paint..color = innerBodyColor,
    );
  }

  void drawCamera({
    required final paint,
    required Offset center,
    required double radius,
    required double borderWidth,
    required Color borderColor,
    required Color innerColor,
    required Color reflectColor,
  }) {
    drawCircle(
      center,
      radius + borderWidth,
      paint..color = borderColor,
    );
    drawCircle(
      center,
      radius,
      paint..color = innerColor,
    );
    drawCircle(
      center - Offset(0, radius * 0.25),
      radius / 3,
      paint..color = reflectColor,
    );
  }

  void drawSideButtons({
    required final paint,
    required Rect bounds,
    required Color color,
    required double buttonWidth,
    required SideButtonSide side,
    required bool inverted,
    required List<double> gapsAndSizes,
  }) {
    if (gapsAndSizes.length > 1) {
      double x;
      double y;

      switch (side) {
        case SideButtonSide.left:
          x = bounds.left;
          y = bounds.top;
          break;
        case SideButtonSide.right:
          x = bounds.right;
          y = bounds.top;
          break;
        case SideButtonSide.top:
          y = bounds.top;
          x = bounds.left;
          break;
        case SideButtonSide.bottom:
          y = bounds.bottom;
          x = bounds.left;
          break;
      }

      final buttonRadius = Radius.circular(buttonWidth);
      for (var i = 0; i < gapsAndSizes.length; i++) {
        final current = gapsAndSizes[i];
        final isGap = (i % 2) == 0;
        if (!isGap) {
          final rect = () {
            switch (side) {
              case SideButtonSide.left:
              case SideButtonSide.right:
                return Rect.fromLTWH(
                  x - buttonWidth,
                  inverted ? (bounds.bottom - y - current) : y,
                  buttonWidth * 2,
                  current,
                );
              case SideButtonSide.top:
              case SideButtonSide.bottom:
                return Rect.fromLTWH(
                  inverted ? (bounds.right - x - current) : x,
                  y - buttonWidth,
                  current,
                  buttonWidth * 2,
                );
            }
          }();

          drawRRect(
            RRect.fromRectAndRadius(rect, buttonRadius),
            paint..color = color,
          );
        }
        switch (side) {
          case SideButtonSide.left:
          case SideButtonSide.right:
            y += current;
            break;
          case SideButtonSide.top:
          case SideButtonSide.bottom:
            x += current;
            break;
        }
      }
    }
  }

  /// Draws a background wallpaper, adapted to the given [platform].
  void drawDefaultWallpaper({
    required TargetPlatform platform,
    required Rect bounds,
  }) {
    final paint = Paint();
    switch (platform) {
      case TargetPlatform.macOS:
        paint.shader = ui.Gradient.radial(
          Offset(0, bounds.height),
          bounds.width,
          [
            const Color(0xff4817A6),
            const Color(0xffB236AF),
            const Color(0xffC7BDD6),
            const Color(0xffC870A2),
          ],
          [
            0,
            0.380208,
            0.578125,
            0.828125,
          ],
        );
        break;
      case TargetPlatform.linux:
        paint.shader = ui.Gradient.radial(
          Offset(0, bounds.height),
          bounds.width,
          [
            const Color(0xffBE15DA),
            const Color(0xffE22888),
            const Color(0xffD84E00),
          ],
          [0, 0.421875, 1],
        );
        break;
      default:
        paint.shader = ui.Gradient.radial(
          Offset(0, bounds.height),
          bounds.width,
          [
            const Color(0xff1491F8).withOpacity(1),
            const Color(0xff0043D8).withOpacity(1)
          ],
          [
            0,
            1,
          ],
        );
    }
    drawRect(
      bounds,
      paint,
    );
  }

  /// Draws a desktop window bar, adapted to the given [platform].
  void drawWindowBar({
    required TargetPlatform platform,
    required Rect bounds,
    required Radius windowRadius,
  }) {
    final paint = Paint();
    switch (platform) {
      case TargetPlatform.linux:
        drawRRect(
          RRect.fromRectAndCorners(
            bounds,
            topLeft: windowRadius,
            topRight: windowRadius,
          ),
          paint..color = const Color(0xFE323030),
        );

        const iconSize = Size(22, 22);
        const innerIconSize = Size(8, 8);
        // Cross
        var iconBounds = bounds.centerRight -
                Offset(
                  iconSize.width * 1.5,
                  iconSize.height * 0.5,
                ) &
            iconSize;
        var innerBounds = iconBounds.center -
                ui.Offset(
                  innerIconSize.height * 0.5,
                  innerIconSize.height * 0.5 + 1,
                ) &
            innerIconSize;
        paint.color = const Color(0xFFE95420);
        drawCircle(
          iconBounds.center,
          iconBounds.width * 0.5,
          paint,
        );
        paint
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFFFFF);
        drawLine(
          innerBounds.topLeft,
          innerBounds.bottomRight,
          paint,
        );
        drawLine(
          innerBounds.topRight,
          innerBounds.bottomLeft,
          paint,
        );
        // Square
        iconBounds = iconBounds.topLeft -
                Offset(
                  iconSize.width * 2,
                  0,
                ) &
            iconSize;
        innerBounds = iconBounds.center -
                ui.Offset(
                  innerIconSize.height * 0.5,
                  innerIconSize.height * 0.5,
                ) &
            innerIconSize;
        drawRect(
          innerBounds,
          paint,
        );
        // bar
        iconBounds = iconBounds.topLeft -
                Offset(
                  iconSize.width * 2,
                  0,
                ) &
            iconSize;
        innerBounds = iconBounds.center -
                ui.Offset(
                  innerIconSize.height * 0.5,
                  innerIconSize.height * 0.5,
                ) &
            innerIconSize;
        drawLine(
          innerBounds.bottomLeft,
          innerBounds.bottomRight,
          paint,
        );
        break;
      case TargetPlatform.windows:
        drawRRect(
          RRect.fromRectAndCorners(
            bounds,
            topLeft: windowRadius,
            topRight: windowRadius,
          ),
          paint..color = const Color(0xBB000000),
        );
        paint
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFFFFF);
        const iconSize = Size(12, 12);
        // Cross
        var iconBounds = bounds.centerRight -
                Offset(
                  iconSize.width * 2.5,
                  iconSize.height * 0.5,
                ) &
            iconSize;
        drawLine(
          iconBounds.topLeft,
          iconBounds.bottomRight,
          paint,
        );
        drawLine(
          iconBounds.topRight,
          iconBounds.bottomLeft,
          paint,
        );
        // Square
        iconBounds = iconBounds.topLeft -
                Offset(
                  iconSize.width * 3,
                  0,
                ) &
            iconSize;
        drawRect(
          iconBounds,
          paint,
        );
        // bar
        iconBounds = iconBounds.topLeft -
                Offset(
                  iconSize.width * 3,
                  0,
                ) &
            iconSize;
        drawLine(
          iconBounds.centerLeft,
          iconBounds.centerRight,
          paint,
        );
        break;
      case TargetPlatform.macOS:
        drawRRect(
          RRect.fromRectAndCorners(
            bounds,
            topLeft: windowRadius,
            topRight: windowRadius,
          ),
          paint..color = const Color(0xBB000000),
        );
        const iconSize = Size(12, 12);
        const iconOffset = Offset(8, 8);
        // Close
        var iconBounds = bounds.topLeft + iconOffset & iconSize;
        drawCircle(
          iconBounds.center,
          iconBounds.width * 0.5,
          paint..color = const Color(0xFFEE695E),
        );
        // Minimize
        iconBounds = iconBounds.topRight +
                Offset(
                  iconOffset.dx,
                  0,
                ) &
            iconSize;
        drawCircle(
          iconBounds.center,
          iconBounds.width * 0.5,
          paint..color = const Color(0xFFF5BD4E),
        );
        // Maximize
        iconBounds = iconBounds.topRight +
                Offset(
                  iconOffset.dx,
                  0,
                ) &
            iconSize;
        drawCircle(
          iconBounds.center,
          iconBounds.width * 0.5,
          paint..color = const Color(0xFF61C354),
        );
        break;
      default:
        break;
    }
  }

  void drawMonitorFoot({
    required final paint,
    required Rect bounds,
    required Color outerBodyColor,
    required Radius outerBodyRadius,
    required Color innerBodyColor,
    required Radius innerBodyRadius,
    required double footBarWidth,
    required double footBarSpace,
    required double bottomHeight,
    required double baseHeight,
    required Radius baseTopRadius,
    required Radius baseBottomRadius,
  }) {
    // Left bar
    drawRect(
      Offset(
            bounds.center.dx - (footBarSpace / 2) - footBarWidth,
            bounds.top,
          ) &
          Size(footBarWidth, bounds.height - bottomHeight),
      paint..color = innerBodyColor,
    );
    // Right bar
    drawRect(
      Offset(
            bounds.center.dx + (footBarSpace / 2),
            bounds.top,
          ) &
          Size(footBarWidth, bounds.height - bottomHeight),
      paint..color = innerBodyColor,
    );
    // Base top
    drawRRect(
      ui.RRect.fromRectAndCorners(
        Rect.fromLTWH(
          bounds.left,
          bounds.bottom - bottomHeight - baseHeight,
          bounds.width,
          baseHeight * 0.5,
        ),
        topLeft: baseTopRadius,
        topRight: baseTopRadius,
      ),
      paint..color = outerBodyColor,
    );
    // Base bottom
    drawRRect(
      ui.RRect.fromRectAndCorners(
        Rect.fromLTWH(
          bounds.left,
          bounds.bottom - bottomHeight - (baseHeight * 0.5),
          bounds.width,
          baseHeight * 0.5,
        ),
        bottomLeft: baseBottomRadius,
        bottomRight: baseBottomRadius,
      ),
      paint..color = innerBodyColor,
    );
    // Bottom pads
    final bottomWidth = bottomHeight * 5;
    final bottomRadius = Radius.circular(bottomHeight);
    drawRRect(
      ui.RRect.fromRectAndCorners(
        Rect.fromLTWH(
          bounds.left + bottomWidth,
          bounds.bottom - bottomHeight,
          bottomWidth,
          bottomHeight,
        ),
        bottomLeft: bottomRadius,
        bottomRight: bottomRadius,
      ),
      paint..color = innerBodyColor,
    );
    drawRRect(
      ui.RRect.fromRectAndCorners(
        Rect.fromLTWH(
          bounds.right - bottomWidth * 2,
          bounds.bottom - bottomHeight,
          bottomWidth,
          bottomHeight,
        ),
        bottomLeft: bottomRadius,
        bottomRight: bottomRadius,
      ),
      paint..color = innerBodyColor,
    );
  }
}

enum SideButtonSide {
  top,
  left,
  right,
  bottom,
}
