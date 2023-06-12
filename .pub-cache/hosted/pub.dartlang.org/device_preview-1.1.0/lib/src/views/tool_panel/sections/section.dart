import 'package:flutter/material.dart';

/// A [Sliver] representing a section in the [DevicePreview] menu.
///
/// It is only composed of a section [title] header and a list of [children].
class ToolPanelSection extends StatelessWidget {
  /// Create a new panel section with the given [title] and [children].
  const ToolPanelSection({
    Key? key,
    required this.title,
    required this.children,
  }) : super(key: key);

  /// The section header content.
  final String title;

  /// The section children widgets.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 32.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            SafeArea(
              top: false,
              bottom: false,
              minimum: const EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: 4,
              ),
              child: Text(
                title.toUpperCase(),
                style: theme.textTheme.subtitle2?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
