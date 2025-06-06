// packages/flutter/lib/src/widgets/adaptive_button.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AdaptiveButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final EdgeInsets? padding;

  const AdaptiveButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;

    if (platform == TargetPlatform.iOS) {
      return CupertinoButton(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onPressed: onPressed,
        child: child,
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: padding != null ? MaterialStateProperty.all(padding) : null,
        ),
        child: child,
      );
    }
  }
}
