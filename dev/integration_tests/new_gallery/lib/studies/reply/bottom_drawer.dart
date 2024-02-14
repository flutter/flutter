import 'package:flutter/material.dart';
import 'package:gallery/studies/reply/colors.dart';

class BottomDrawer extends StatelessWidget {
  const BottomDrawer({
    super.key,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    required this.leading,
    required this.trailing,
  });

  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;
  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: Material(
        color: theme.bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: ListView(
          padding: const EdgeInsets.all(12),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 28),
            leading,
            const SizedBox(height: 8),
            const Divider(
              color: ReplyColors.blue200,
              thickness: 0.25,
              indent: 18,
              endIndent: 160,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 18),
              child: Text(
                'FOLDERS',
                style: theme.textTheme.bodySmall!.copyWith(
                  color:
                      theme.navigationRailTheme.unselectedLabelTextStyle!.color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            trailing,
          ],
        ),
      ),
    );
  }
}
