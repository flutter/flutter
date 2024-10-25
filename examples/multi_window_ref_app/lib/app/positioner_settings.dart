import 'package:flutter/material.dart';

class PositionerSetting {
  PositionerSetting(
      {required this.name,
      required this.parentAnchor,
      required this.childAnchor,
      required this.offset,
      required this.constraintAdjustments});
  final String name;
  final WindowPositionerAnchor parentAnchor;
  final WindowPositionerAnchor childAnchor;
  final Offset offset;
  final Set<WindowPositionerConstraintAdjustment> constraintAdjustments;
}

class PositionerSettingsContainer {
  List<PositionerSetting> positionerSettingsList = [
    PositionerSetting(
        name: "Left",
        parentAnchor: WindowPositionerAnchor.left,
        childAnchor: WindowPositionerAnchor.right,
        offset: const Offset(0, 0),
        constraintAdjustments: {
          WindowPositionerConstraintAdjustment.slideX,
          WindowPositionerConstraintAdjustment.slideY
        }),
    PositionerSetting(
        name: "Right",
        parentAnchor: WindowPositionerAnchor.right,
        childAnchor: WindowPositionerAnchor.left,
        offset: const Offset(0, 0),
        constraintAdjustments: {
          WindowPositionerConstraintAdjustment.slideX,
          WindowPositionerConstraintAdjustment.slideY
        }),
    PositionerSetting(
        name: "Bottom Left",
        parentAnchor: WindowPositionerAnchor.bottomLeft,
        childAnchor: WindowPositionerAnchor.topRight,
        offset: const Offset(0, 0),
        constraintAdjustments: {
          WindowPositionerConstraintAdjustment.slideX,
          WindowPositionerConstraintAdjustment.slideY
        }),
    PositionerSetting(
        name: "Bottom",
        parentAnchor: WindowPositionerAnchor.bottom,
        childAnchor: WindowPositionerAnchor.top,
        offset: const Offset(0, 0),
        constraintAdjustments: {
          WindowPositionerConstraintAdjustment.slideX,
          WindowPositionerConstraintAdjustment.slideY
        }),
    PositionerSetting(
        name: "Bottom Right",
        parentAnchor: WindowPositionerAnchor.bottomRight,
        childAnchor: WindowPositionerAnchor.topLeft,
        offset: const Offset(0, 0),
        constraintAdjustments: {
          WindowPositionerConstraintAdjustment.slideX,
          WindowPositionerConstraintAdjustment.slideY
        }),
    PositionerSetting(
        name: "Center",
        parentAnchor: WindowPositionerAnchor.center,
        childAnchor: WindowPositionerAnchor.center,
        offset: const Offset(0, 0),
        constraintAdjustments: {
          WindowPositionerConstraintAdjustment.slideX,
          WindowPositionerConstraintAdjustment.slideY
        }),
    PositionerSetting(
        name: "Custom",
        parentAnchor: WindowPositionerAnchor.left,
        childAnchor: WindowPositionerAnchor.right,
        offset: const Offset(0, 50),
        constraintAdjustments: {
          WindowPositionerConstraintAdjustment.slideX,
          WindowPositionerConstraintAdjustment.slideY
        })
  ];
}
