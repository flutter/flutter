// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'button_bar.dart';
import 'colors.dart';
import 'debug.dart';
import 'dialog_theme.dart';
import 'ink_well.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'theme.dart';
import 'theme_data.dart';

// Examples can assume:
// enum Department { treasury, state }
// late BuildContext context;

const EdgeInsets _defaultInsetPadding = EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0);

/// A material design dialog.
///
/// This dialog widget does not have any opinion about the contents of the
/// dialog. Rather than using this widget directly, consider using [AlertDialog]
/// or [SimpleDialog], which implement specific kinds of material design
/// dialogs.
///
/// See also:
///
///  * [AlertDialog], for dialogs that have a message and some buttons.
///  * [SimpleDialog], for dialogs that offer a variety of options.
///  * [showDialog], which actually displays the dialog and returns its result.
///  * <https://material.io/design/components/dialogs.html>
class Dialog extends StatelessWidget {
  /// Creates a dialog.
  ///
  /// Typically used in conjunction with [showDialog].
  const Dialog({
    Key? key,
    this.backgroundColor,
    this.elevation,
    this.insetAnimationDuration = const Duration(milliseconds: 100),
    this.insetAnimationCurve = Curves.decelerate,
    this.insetPadding = _defaultInsetPadding,
    this.clipBehavior = Clip.none,
    this.shape,
    this.child,
  }) : assert(clipBehavior != null),
       super(key: key);

  /// {@template flutter.material.dialog.backgroundColor}
  /// The background color of the surface of this [Dialog].
  ///
  /// This sets the [Material.color] on this [Dialog]'s [Material].
  ///
  /// If `null`, [ThemeData.dialogBackgroundColor] is used.
  /// {@endtemplate}
  final Color? backgroundColor;

  /// {@template flutter.material.dialog.elevation}
  /// The z-coordinate of this [Dialog].
  ///
  /// If null then [DialogTheme.elevation] is used, and if that's null then the
  /// dialog's elevation is 24.0.
  /// {@endtemplate}
  /// {@macro flutter.material.material.elevation}
  final double? elevation;

  /// {@template flutter.material.dialog.insetAnimationDuration}
  /// The duration of the animation to show when the system keyboard intrudes
  /// into the space that the dialog is placed in.
  ///
  /// Defaults to 100 milliseconds.
  /// {@endtemplate}
  final Duration insetAnimationDuration;

  /// {@template flutter.material.dialog.insetAnimationCurve}
  /// The curve to use for the animation shown when the system keyboard intrudes
  /// into the space that the dialog is placed in.
  ///
  /// Defaults to [Curves.decelerate].
  /// {@endtemplate}
  final Curve insetAnimationCurve;

  /// {@template flutter.material.dialog.insetPadding}
  /// The amount of padding added to [MediaQueryData.viewInsets] on the outside
  /// of the dialog. This defines the minimum space between the screen's edges
  /// and the dialog.
  ///
  /// Defaults to `EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0)`.
  /// {@endtemplate}
  final EdgeInsets? insetPadding;

  /// {@template flutter.material.dialog.clipBehavior}
  /// Controls how the contents of the dialog are clipped (or not) to the given
  /// [shape].
  ///
  /// See the enum [Clip] for details of all possible options and their common
  /// use cases.
  ///
  /// Defaults to [Clip.none], and must not be null.
  /// {@endtemplate}
  final Clip clipBehavior;

  /// {@template flutter.material.dialog.shape}
  /// The shape of this dialog's border.
  ///
  /// Defines the dialog's [Material.shape].
  ///
  /// The default shape is a [RoundedRectangleBorder] with a radius of 4.0
  /// {@endtemplate}
  final ShapeBorder? shape;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  static const RoundedRectangleBorder _defaultDialogShape =
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)));
  static const double _defaultElevation = 24.0;

  @override
  Widget build(BuildContext context) {
    final DialogTheme dialogTheme = DialogTheme.of(context);
    final EdgeInsets effectivePadding = MediaQuery.of(context).viewInsets + (insetPadding ?? EdgeInsets.zero);
    return AnimatedPadding(
      padding: effectivePadding,
      duration: insetAnimationDuration,
      curve: insetAnimationCurve,
      child: MediaQuery.removeViewInsets(
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        context: context,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280.0),
            child: Material(
              color: backgroundColor ?? dialogTheme.backgroundColor ?? Theme.of(context).dialogBackgroundColor,
              elevation: elevation ?? dialogTheme.elevation ?? _defaultElevation,
              shape: shape ?? dialogTheme.shape ?? _defaultDialogShape,
              type: MaterialType.card,
              clipBehavior: clipBehavior,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A material design alert dialog.
///
/// An alert dialog informs the user about situations that require
/// acknowledgement. An alert dialog has an optional title and an optional list
/// of actions. The title is displayed above the content and the actions are
/// displayed below the content.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=75CsnyRXf5I}
///
/// If the content is too large to fit on the screen vertically, the dialog will
/// display the title and the actions and let the content overflow, which is
/// rarely desired. Consider using a scrolling widget for [content], such as
/// [SingleChildScrollView], to avoid overflow. (However, be aware that since
/// [AlertDialog] tries to size itself using the intrinsic dimensions of its
/// children, widgets such as [ListView], [GridView], and [CustomScrollView],
/// which use lazy viewports, will not work. If this is a problem, consider
/// using [Dialog] directly.)
///
/// For dialogs that offer the user a choice between several options, consider
/// using a [SimpleDialog].
///
/// Typically passed as the child widget to [showDialog], which displays the
/// dialog.
///
/// {@animation 350 622 https://flutter.github.io/assets-for-api-docs/assets/material/alert_dialog.mp4}
///
/// {@tool snippet}
///
/// This snippet shows a method in a [State] which, when called, displays a dialog box
/// and returns a [Future] that completes when the dialog is dismissed.
///
/// ```dart
/// Future<void> _showMyDialog() async {
///   return showDialog<void>(
///     context: context,
///     barrierDismissible: false, // user must tap button!
///     builder: (BuildContext context) {
///       return AlertDialog(
///         title: const Text('AlertDialog Title'),
///         content: SingleChildScrollView(
///           child: ListBody(
///             children: const <Widget>[
///               Text('This is a demo alert dialog.'),
///               Text('Would you like to approve of this message?'),
///             ],
///           ),
///         ),
///         actions: <Widget>[
///           TextButton(
///             child: const Text('Approve'),
///             onPressed: () {
///               Navigator.of(context).pop();
///             },
///           ),
///         ],
///       );
///     },
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateless_widget_scaffold_center}
///
/// This demo shows a [TextButton] which when pressed, calls [showDialog]. When called, this method
/// displays a Material dialog above the current contents of the app and returns
/// a [Future] that completes when the dialog is dismissed.
///
/// ```dart
/// Widget build(BuildContext context) {
///   return TextButton(
///     onPressed: () => showDialog<String>(
///       context: context,
///       builder: (BuildContext context) => AlertDialog(
///         title: const Text('AlertDialog Tilte'),
///         content: const Text('AlertDialog description'),
///         actions: <Widget>[
///           TextButton(
///             onPressed: () => Navigator.pop(context, 'Cancel'),
///             child: const Text('Cancel'),
///           ),
///           TextButton(
///             onPressed: () => Navigator.pop(context, 'OK'),
///             child: const Text('OK'),
///           ),
///         ],
///       ),
///     ),
///     child: const Text('Show Dialog'),
///   );
/// }
///
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [SimpleDialog], which handles the scrolling of the contents but has no [actions].
///  * [Dialog], on which [AlertDialog] and [SimpleDialog] are based.
///  * [CupertinoAlertDialog], an iOS-styled alert dialog.
///  * [showDialog], which actually displays the dialog and returns its result.
///  * <https://material.io/design/components/dialogs.html#alert-dialog>
class AlertDialog extends StatelessWidget {
  /// Creates an alert dialog.
  ///
  /// Typically used in conjunction with [showDialog].
  ///
  /// The [contentPadding] must not be null. The [titlePadding] defaults to
  /// null, which implies a default that depends on the values of the other
  /// properties. See the documentation of [titlePadding] for details.
  const AlertDialog({
    Key? key,
    this.title,
    this.titlePadding,
    this.titleTextStyle,
    this.content,
    this.contentPadding = const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
    this.contentTextStyle,
    this.actions,
    this.actionsPadding = EdgeInsets.zero,
    this.actionsOverflowDirection,
    this.actionsOverflowButtonSpacing,
    this.buttonPadding,
    this.backgroundColor,
    this.elevation,
    this.semanticLabel,
    this.insetPadding = _defaultInsetPadding,
    this.clipBehavior = Clip.none,
    this.shape,
    this.scrollable = false,
  }) : assert(contentPadding != null),
       assert(clipBehavior != null),
       super(key: key);

  /// The (optional) title of the dialog is displayed in a large font at the top
  /// of the dialog.
  ///
  /// Typically a [Text] widget.
  final Widget? title;

  /// Padding around the title.
  ///
  /// If there is no title, no padding will be provided. Otherwise, this padding
  /// is used.
  ///
  /// This property defaults to providing 24 pixels on the top, left, and right
  /// of the title. If the [content] is not null, then no bottom padding is
  /// provided (but see [contentPadding]). If it _is_ null, then an extra 20
  /// pixels of bottom padding is added to separate the [title] from the
  /// [actions].
  final EdgeInsetsGeometry? titlePadding;

  /// Style for the text in the [title] of this [AlertDialog].
  ///
  /// If null, [DialogTheme.titleTextStyle] is used. If that's null, defaults to
  /// [TextTheme.headline6] of [ThemeData.textTheme].
  final TextStyle? titleTextStyle;

  /// The (optional) content of the dialog is displayed in the center of the
  /// dialog in a lighter font.
  ///
  /// Typically this is a [SingleChildScrollView] that contains the dialog's
  /// message. As noted in the [AlertDialog] documentation, it's important
  /// to use a [SingleChildScrollView] if there's any risk that the content
  /// will not fit.
  final Widget? content;

  /// Padding around the content.
  ///
  /// If there is no content, no padding will be provided. Otherwise, padding of
  /// 20 pixels is provided above the content to separate the content from the
  /// title, and padding of 24 pixels is provided on the left, right, and bottom
  /// to separate the content from the other edges of the dialog.
  final EdgeInsetsGeometry contentPadding;

  /// Style for the text in the [content] of this [AlertDialog].
  ///
  /// If null, [DialogTheme.contentTextStyle] is used. If that's null, defaults
  /// to [TextTheme.subtitle1] of [ThemeData.textTheme].
  final TextStyle? contentTextStyle;

  /// The (optional) set of actions that are displayed at the bottom of the
  /// dialog.
  ///
  /// Typically this is a list of [TextButton] widgets. It is recommended to
  /// set the [Text.textAlign] to [TextAlign.end] for the [Text] within the
  /// [TextButton], so that buttons whose labels wrap to an extra line align
  /// with the overall [ButtonBar]'s alignment within the dialog.
  ///
  /// These widgets will be wrapped in a [ButtonBar], which introduces 8 pixels
  /// of padding on each side.
  ///
  /// If the [title] is not null but the [content] _is_ null, then an extra 20
  /// pixels of padding is added above the [ButtonBar] to separate the [title]
  /// from the [actions].
  final List<Widget>? actions;

  /// Padding around the set of [actions] at the bottom of the dialog.
  ///
  /// Typically used to provide padding to the button bar between the button bar
  /// and the edges of the dialog.
  ///
  /// If are no [actions], then no padding will be included. The padding around
  /// the button bar defaults to zero. It is also important to note that
  /// [buttonPadding] may contribute to the padding on the edges of [actions] as
  /// well.
  ///
  /// {@tool snippet}
  /// This is an example of a set of actions aligned with the content widget.
  /// ```dart
  /// AlertDialog(
  ///   title: const Text('Title'),
  ///   content: Container(width: 200, height: 200, color: Colors.green),
  ///   actions: <Widget>[
  ///     ElevatedButton(onPressed: () {}, child: const Text('Button 1')),
  ///     ElevatedButton(onPressed: () {}, child: const Text('Button 2')),
  ///   ],
  ///   actionsPadding: const EdgeInsets.symmetric(horizontal: 8.0),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  /// * [ButtonBar], which [actions] configures to lay itself out.
  final EdgeInsetsGeometry actionsPadding;

  /// The vertical direction of [actions] if the children overflow
  /// horizontally.
  ///
  /// If the dialog's [actions] do not fit into a single row, then they
  /// are arranged in a column. The first action is at the top of the
  /// column if this property is set to [VerticalDirection.down], since it
  /// "starts" at the top and "ends" at the bottom. On the other hand,
  /// the first action will be at the bottom of the column if this
  /// property is set to [VerticalDirection.up], since it "starts" at the
  /// bottom and "ends" at the top.
  ///
  /// If null then it will use the surrounding
  /// [ButtonBarThemeData.overflowDirection]. If that is null, it will
  /// default to [VerticalDirection.down].
  ///
  /// See also:
  ///
  /// * [ButtonBar], which [actions] configures to lay itself out.
  final VerticalDirection? actionsOverflowDirection;

  /// The spacing between [actions] when the button bar overflows.
  ///
  /// If the widgets in [actions] do not fit into a single row, they are
  /// arranged into a column. This parameter provides additional
  /// vertical space in between buttons when it does overflow.
  ///
  /// Note that the button spacing may appear to be more than
  /// the value provided. This is because most buttons adhere to the
  /// [MaterialTapTargetSize] of 48px. So, even though a button
  /// might visually be 36px in height, it might still take up to
  /// 48px vertically.
  ///
  /// If null then no spacing will be added in between buttons in
  /// an overflow state.
  final double? actionsOverflowButtonSpacing;

  /// The padding that surrounds each button in [actions].
  ///
  /// This is different from [actionsPadding], which defines the padding
  /// between the entire button bar and the edges of the dialog.
  ///
  /// If this property is null, then it will default to
  /// 8.0 logical pixels on the left and right.
  final EdgeInsetsGeometry? buttonPadding;

  /// {@macro flutter.material.dialog.backgroundColor}
  final Color? backgroundColor;

  /// {@macro flutter.material.dialog.elevation}
  /// {@macro flutter.material.material.elevation}
  final double? elevation;

  /// The semantic label of the dialog used by accessibility frameworks to
  /// announce screen transitions when the dialog is opened and closed.
  ///
  /// In iOS, if this label is not provided, a semantic label will be inferred
  /// from the [title] if it is not null.
  ///
  /// In Android, if this label is not provided, the dialog will use the
  /// [MaterialLocalizations.alertDialogLabel] as its label.
  ///
  /// See also:
  ///
  ///  * [SemanticsConfiguration.namesRoute], for a description of how this
  ///    value is used.
  final String? semanticLabel;

  /// {@macro flutter.material.dialog.insetPadding}
  final EdgeInsets insetPadding;

  /// {@macro flutter.material.dialog.clipBehavior}
  final Clip clipBehavior;

  /// {@macro flutter.material.dialog.shape}
  final ShapeBorder? shape;

  /// Determines whether the [title] and [content] widgets are wrapped in a
  /// scrollable.
  ///
  /// This configuration is used when the [title] and [content] are expected
  /// to overflow. Both [title] and [content] are wrapped in a scroll view,
  /// allowing all overflowed content to be visible while still showing the
  /// button bar.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final ThemeData theme = Theme.of(context);
    final DialogTheme dialogTheme = DialogTheme.of(context);

    String? label = semanticLabel;
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        label ??= MaterialLocalizations.of(context).alertDialogLabel;
    }

    // The paddingScaleFactor is used to adjust the padding of Dialog's
    // children.
    final double paddingScaleFactor = _paddingScaleFactor(MediaQuery.of(context).textScaleFactor);
    final TextDirection? textDirection = Directionality.maybeOf(context);

    Widget? titleWidget;
    Widget? contentWidget;
    Widget? actionsWidget;
    if (title != null) {
      final EdgeInsets defaultTitlePadding = EdgeInsets.fromLTRB(24.0, 24.0, 24.0, content == null ? 20.0 : 0.0);
      final EdgeInsets effectiveTitlePadding = titlePadding?.resolve(textDirection) ?? defaultTitlePadding;
      titleWidget = Padding(
        padding: EdgeInsets.only(
          left: effectiveTitlePadding.left * paddingScaleFactor,
          right: effectiveTitlePadding.right * paddingScaleFactor,
          top: effectiveTitlePadding.top * paddingScaleFactor,
          bottom: effectiveTitlePadding.bottom,
        ),
        child: DefaultTextStyle(
          style: titleTextStyle ?? dialogTheme.titleTextStyle ?? theme.textTheme.headline6!,
          child: Semantics(
            child: title,
            namesRoute: label == null,
            container: true,
          ),
        ),
      );
    }

    if (content != null) {
      final EdgeInsets effectiveContentPadding = contentPadding.resolve(textDirection);
      contentWidget = Padding(
        padding: EdgeInsets.only(
          left: effectiveContentPadding.left * paddingScaleFactor,
          right: effectiveContentPadding.right * paddingScaleFactor,
          top: title == null ? effectiveContentPadding.top * paddingScaleFactor : effectiveContentPadding.top,
          bottom: effectiveContentPadding.bottom,
        ),
        child: DefaultTextStyle(
          style: contentTextStyle ?? dialogTheme.contentTextStyle ?? theme.textTheme.subtitle1!,
          child: Semantics(
            container: true,
            child: content!,
          ),
        ),
      );
    }


    if (actions != null) {
      final double spacing = (buttonPadding?.horizontal ?? 16) / 2;
      actionsWidget = Padding(
        padding: actionsPadding,
        child: Container(
          alignment: AlignmentDirectional.centerEnd,
          padding: EdgeInsets.all(spacing),
          child: OverflowBar(
            spacing: spacing,
            overflowAlignment: OverflowBarAlignment.end,
            overflowDirection: actionsOverflowDirection ?? VerticalDirection.down,
            overflowSpacing: actionsOverflowButtonSpacing ?? 0,
            children: actions!,
          ),
        ),
      );
    }

    List<Widget> columnChildren;
    if (scrollable) {
      columnChildren = <Widget>[
        if (title != null || content != null)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (title != null) titleWidget!,
                  if (content != null) contentWidget!,
                ],
              ),
            ),
          ),
        if (actions != null)
          actionsWidget!,
      ];
    } else {
      columnChildren = <Widget>[
        if (title != null) titleWidget!,
        if (content != null) Flexible(child: contentWidget!),
        if (actions != null) actionsWidget!,
      ];
    }

    Widget dialogChild = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: columnChildren,
      ),
    );

    if (label != null)
      dialogChild = Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: label,
        child: dialogChild,
      );

    return Dialog(
      backgroundColor: backgroundColor,
      elevation: elevation,
      insetPadding: insetPadding,
      clipBehavior: clipBehavior,
      shape: shape,
      child: dialogChild,
    );
  }
}

/// An option used in a [SimpleDialog].
///
/// A simple dialog offers the user a choice between several options. This
/// widget is commonly used to represent each of the options. If the user
/// selects this option, the widget will call the [onPressed] callback, which
/// typically uses [Navigator.pop] to close the dialog.
///
/// The padding on a [SimpleDialogOption] is configured to combine with the
/// default [SimpleDialog.contentPadding] so that each option ends up 8 pixels
/// from the other vertically, with 20 pixels of spacing between the dialog's
/// title and the first option, and 24 pixels of spacing between the last option
/// and the bottom of the dialog.
///
/// {@tool snippet}
///
/// ```dart
/// SimpleDialogOption(
///   onPressed: () { Navigator.pop(context, Department.treasury); },
///   child: const Text('Treasury department'),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [SimpleDialog], for a dialog in which to use this widget.
///  * [showDialog], which actually displays the dialog and returns its result.
///  * [TextButton], which are commonly used as actions in other kinds of
///    dialogs, such as [AlertDialog]s.
///  * <https://material.io/design/components/dialogs.html#simple-dialog>
class SimpleDialogOption extends StatelessWidget {
  /// Creates an option for a [SimpleDialog].
  const SimpleDialogOption({
    Key? key,
    this.onPressed,
    this.padding,
    this.child,
  }) : super(key: key);

  /// The callback that is called when this option is selected.
  ///
  /// If this is set to null, the option cannot be selected.
  ///
  /// When used in a [SimpleDialog], this will typically call [Navigator.pop]
  /// with a value for [showDialog] to complete its future with.
  final VoidCallback? onPressed;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget? child;

  /// The amount of space to surround the [child] with.
  ///
  /// Defaults to EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0).
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
        child: child,
      ),
    );
  }
}

/// A simple material design dialog.
///
/// A simple dialog offers the user a choice between several options. A simple
/// dialog has an optional title that is displayed above the choices.
///
/// Choices are normally represented using [SimpleDialogOption] widgets. If
/// other widgets are used, see [contentPadding] for notes regarding the
/// conventions for obtaining the spacing expected by Material Design.
///
/// For dialogs that inform the user about a situation, consider using an
/// [AlertDialog].
///
/// Typically passed as the child widget to [showDialog], which displays the
/// dialog.
///
/// {@animation 350 622 https://flutter.github.io/assets-for-api-docs/assets/material/simple_dialog.mp4}
///
/// {@tool snippet}
///
/// In this example, the user is asked to select between two options. These
/// options are represented as an enum. The [showDialog] method here returns
/// a [Future] that completes to a value of that enum. If the user cancels
/// the dialog (e.g. by hitting the back button on Android, or tapping on the
/// mask behind the dialog) then the future completes with the null value.
///
/// The return value in this example is used as the index for a switch statement.
/// One advantage of using an enum as the return value and then using that to
/// drive a switch statement is that the analyzer will flag any switch statement
/// that doesn't mention every value in the enum.
///
/// ```dart
/// Future<void> _askedToLead() async {
///   switch (await showDialog<Department>(
///     context: context,
///     builder: (BuildContext context) {
///       return SimpleDialog(
///         title: const Text('Select assignment'),
///         children: <Widget>[
///           SimpleDialogOption(
///             onPressed: () { Navigator.pop(context, Department.treasury); },
///             child: const Text('Treasury department'),
///           ),
///           SimpleDialogOption(
///             onPressed: () { Navigator.pop(context, Department.state); },
///             child: const Text('State department'),
///           ),
///         ],
///       );
///     }
///   )) {
///     case Department.treasury:
///       // Let's go.
///       // ...
///     break;
///     case Department.state:
///       // ...
///     break;
///     case null:
///       // dialog dismissed
///     break;
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [SimpleDialogOption], which are options used in this type of dialog.
///  * [AlertDialog], for dialogs that have a row of buttons below the body.
///  * [Dialog], on which [SimpleDialog] and [AlertDialog] are based.
///  * [showDialog], which actually displays the dialog and returns its result.
///  * <https://material.io/design/components/dialogs.html#simple-dialog>
class SimpleDialog extends StatelessWidget {
  /// Creates a simple dialog.
  ///
  /// Typically used in conjunction with [showDialog].
  ///
  /// The [titlePadding] and [contentPadding] arguments must not be null.
  const SimpleDialog({
    Key? key,
    this.title,
    this.titlePadding = const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
    this.titleTextStyle,
    this.children,
    this.contentPadding = const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 16.0),
    this.backgroundColor,
    this.elevation,
    this.semanticLabel,
    this.insetPadding = _defaultInsetPadding,
    this.clipBehavior = Clip.none,
    this.shape,
  }) : assert(titlePadding != null),
       assert(contentPadding != null),
       super(key: key);

  /// The (optional) title of the dialog is displayed in a large font at the top
  /// of the dialog.
  ///
  /// Typically a [Text] widget.
  final Widget? title;

  /// Padding around the title.
  ///
  /// If there is no title, no padding will be provided.
  ///
  /// By default, this provides the recommend Material Design padding of 24
  /// pixels around the left, top, and right edges of the title.
  ///
  /// See [contentPadding] for the conventions regarding padding between the
  /// [title] and the [children].
  final EdgeInsetsGeometry titlePadding;

  /// Style for the text in the [title] of this [SimpleDialog].
  ///
  /// If null, [DialogTheme.titleTextStyle] is used. If that's null, defaults to
  /// [TextTheme.headline6] of [ThemeData.textTheme].
  final TextStyle? titleTextStyle;

  /// The (optional) content of the dialog is displayed in a
  /// [SingleChildScrollView] underneath the title.
  ///
  /// Typically a list of [SimpleDialogOption]s.
  final List<Widget>? children;

  /// Padding around the content.
  ///
  /// By default, this is 12 pixels on the top and 16 pixels on the bottom. This
  /// is intended to be combined with children that have 24 pixels of padding on
  /// the left and right, and 8 pixels of padding on the top and bottom, so that
  /// the content ends up being indented 20 pixels from the title, 24 pixels
  /// from the bottom, and 24 pixels from the sides.
  ///
  /// The [SimpleDialogOption] widget uses such padding.
  ///
  /// If there is no [title], the [contentPadding] should be adjusted so that
  /// the top padding ends up being 24 pixels.
  final EdgeInsetsGeometry contentPadding;

  /// {@macro flutter.material.dialog.backgroundColor}
  final Color? backgroundColor;

  /// {@macro flutter.material.dialog.elevation}
  /// {@macro flutter.material.material.elevation}
  final double? elevation;

  /// The semantic label of the dialog used by accessibility frameworks to
  /// announce screen transitions when the dialog is opened and closed.
  ///
  /// If this label is not provided, a semantic label will be inferred from the
  /// [title] if it is not null.  If there is no title, the label will be taken
  /// from [MaterialLocalizations.dialogLabel].
  ///
  /// See also:
  ///
  ///  * [SemanticsConfiguration.namesRoute], for a description of how this
  ///    value is used.
  final String? semanticLabel;

  /// {@macro flutter.material.dialog.insetPadding}
  final EdgeInsets insetPadding;

  /// {@macro flutter.material.dialog.clipBehavior}
  final Clip clipBehavior;

  /// {@macro flutter.material.dialog.shape}
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final ThemeData theme = Theme.of(context);

    String? label = semanticLabel;
    if (title == null) {
      switch (theme.platform) {
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          label = semanticLabel ?? MaterialLocalizations.of(context).dialogLabel;
      }
    }

    // The paddingScaleFactor is used to adjust the padding of Dialog
    // children.
    final double paddingScaleFactor = _paddingScaleFactor(MediaQuery.of(context).textScaleFactor);
    final TextDirection? textDirection = Directionality.maybeOf(context);

    Widget? titleWidget;
    if (title != null) {
      final EdgeInsets effectiveTitlePadding = titlePadding.resolve(textDirection);
      titleWidget = Padding(
        padding: EdgeInsets.only(
          left: effectiveTitlePadding.left * paddingScaleFactor,
          right: effectiveTitlePadding.right * paddingScaleFactor,
          top: effectiveTitlePadding.top * paddingScaleFactor,
          bottom: children == null ? effectiveTitlePadding.bottom * paddingScaleFactor : effectiveTitlePadding.bottom,
        ),
        child: DefaultTextStyle(
          style: titleTextStyle ?? DialogTheme.of(context).titleTextStyle ?? theme.textTheme.headline6!,
          child: Semantics(
            namesRoute: label == null,
            container: true,
            child: title,
          ),
        ),
      );
    }

    Widget? contentWidget;
    if (children != null) {
      final EdgeInsets effectiveContentPadding = contentPadding.resolve(textDirection);
      contentWidget = Flexible(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: effectiveContentPadding.left * paddingScaleFactor,
            right: effectiveContentPadding.right * paddingScaleFactor,
            top: title == null ? effectiveContentPadding.top * paddingScaleFactor : effectiveContentPadding.top,
            bottom: effectiveContentPadding.bottom * paddingScaleFactor,
          ),
          child: ListBody(children: children!),
        ),
      );
    }

    Widget dialogChild = IntrinsicWidth(
      stepWidth: 56.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (title != null) titleWidget!,
            if (children != null) contentWidget!,
          ],
        ),
      ),
    );

    if (label != null)
      dialogChild = Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: label,
        child: dialogChild,
      );
    return Dialog(
      backgroundColor: backgroundColor,
      elevation: elevation,
      insetPadding: insetPadding,
      clipBehavior: clipBehavior,
      shape: shape,
      child: dialogChild,
    );
  }
}

Widget _buildMaterialDialogTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  return FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ),
    child: child,
  );
}

/// Displays a Material dialog above the current contents of the app, with
/// Material entrance and exit animations, modal barrier color, and modal
/// barrier behavior (dialog is dismissible with a tap on the barrier).
///
/// This function takes a `builder` which typically builds a [Dialog] widget.
/// Content below the dialog is dimmed with a [ModalBarrier]. The widget
/// returned by the `builder` does not share a context with the location that
/// `showDialog` is originally called from. Use a [StatefulBuilder] or a
/// custom [StatefulWidget] if the dialog needs to update dynamically.
///
/// The `child` argument is deprecated, and should be replaced with `builder`.
///
/// The `context` argument is used to look up the [Navigator] and [Theme] for
/// the dialog. It is only used when the method is called. Its corresponding
/// widget can be safely removed from the tree before the dialog is closed.
///
/// The `barrierDismissible` argument is used to indicate whether tapping on the
/// barrier will dismiss the dialog. It is `true` by default and can not be `null`.
///
/// The `barrierColor` argument is used to specify the color of the modal
/// barrier that darkens everything below the dialog. If `null` the default color
/// `Colors.black54` is used.
///
/// The `useSafeArea` argument is used to indicate if the dialog should only
/// display in 'safe' areas of the screen not used by the operating system
/// (see [SafeArea] for more details). It is `true` by default, which means
/// the dialog will not overlap operating system areas. If it is set to `false`
/// the dialog will only be constrained by the screen size. It can not be `null`.
///
/// The `useRootNavigator` argument is used to determine whether to push the
/// dialog to the [Navigator] furthest from or nearest to the given `context`.
/// By default, `useRootNavigator` is `true` and the dialog route created by
/// this method is pushed to the root navigator. It can not be `null`.
///
/// The `routeSettings` argument is passed to [showGeneralDialog],
/// see [RouteSettings] for details.
///
/// If the application has multiple [Navigator] objects, it may be necessary to
/// call `Navigator.of(context, rootNavigator: true).pop(result)` to close the
/// dialog rather than just `Navigator.pop(context, result)`.
///
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the dialog was closed.
///
/// ### State Restoration in Dialogs
///
/// Using this method will not enable state restoration for the dialog. In order
/// to enable state restoration for a dialog, use [Navigator.restorablePush]
/// or [Navigator.restorablePushNamed] with [DialogRoute].
///
/// For more information about state restoration, see [RestorationManager].
///
/// {@tool sample --template=stateless_widget_restoration_material}
///
/// This sample demonstrates how to create a restorable Material dialog. This is
/// accomplished by enabling state restoration by specifying
/// [MaterialApp.restorationScopeId] and using [Navigator.restorablePush] to
/// push [DialogRoute] when the button is tapped.
///
/// {@macro flutter.widgets.RestorationManager}
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Center(
///       child: OutlinedButton(
///         onPressed: () {
///           Navigator.of(context).restorablePush(_dialogBuilder);
///         },
///         child: const Text('Open Dialog'),
///       ),
///     ),
///   );
/// }
///
/// static Route<Object?> _dialogBuilder(BuildContext context, Object? arguments) {
///   return DialogRoute<void>(
///     context: context,
///     builder: (BuildContext context) => const AlertDialog(title: Text('Material Alert!')),
///   );
/// }
/// ```
///
/// {@end-tool}
///
/// See also:
///
///  * [AlertDialog], for dialogs that have a row of buttons below a body.
///  * [SimpleDialog], which handles the scrolling of the contents and does
///    not show buttons below its body.
///  * [Dialog], on which [SimpleDialog] and [AlertDialog] are based.
///  * [showCupertinoDialog], which displays an iOS-style dialog.
///  * [showGeneralDialog], which allows for customization of the dialog popup.
///  * <https://material.io/design/components/dialogs.html>
Future<T?> showDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor = Colors.black54,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  assert(builder != null);
  assert(barrierDismissible != null);
  assert(useSafeArea != null);
  assert(useRootNavigator != null);
  assert(debugCheckHasMaterialLocalizations(context));

  final CapturedThemes themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(
      context,
      rootNavigator: useRootNavigator,
    ).context,
  );

  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(DialogRoute<T>(
    context: context,
    builder: builder,
    barrierColor: barrierColor,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    settings: routeSettings,
    themes: themes,
  ));
}

/// A dialog route with Material entrance and exit animations,
/// modal barrier color, and modal barrier behavior (dialog is dismissible
/// with a tap on the barrier).
///
/// It is used internally by [showDialog] or can be directly pushed
/// onto the [Navigator] stack to enable state restoration. See
/// [showDialog] for a state restoration app example.
///
/// This function takes a `builder` which typically builds a [Dialog] widget.
/// Content below the dialog is dimmed with a [ModalBarrier]. The widget
/// returned by the `builder` does not share a context with the location that
/// `showDialog` is originally called from. Use a [StatefulBuilder] or a
/// custom [StatefulWidget] if the dialog needs to update dynamically.
///
/// The `context` argument is used to look up
/// [MaterialLocalizations.modalBarrierDismissLabel], which provides the
/// modal with a localized accessibility label that will be used for the
/// modal's barrier. However, a custom `barrierLabel` can be passed in as well.
///
/// The `barrierDismissible` argument is used to indicate whether tapping on the
/// barrier will dismiss the dialog. It is `true` by default and cannot be `null`.
///
/// The `barrierColor` argument is used to specify the color of the modal
/// barrier that darkens everything below the dialog. If `null`, the default
/// color `Colors.black54` is used.
///
/// The `useSafeArea` argument is used to indicate if the dialog should only
/// display in 'safe' areas of the screen not used by the operating system
/// (see [SafeArea] for more details). It is `true` by default, which means
/// the dialog will not overlap operating system areas. If it is set to `false`
/// the dialog will only be constrained by the screen size. It can not be `null`.
///
/// The `settings` argument define the settings for this route. See
/// [RouteSettings] for details.
///
/// See also:
///
///  * [showDialog], which is a way to display a DialogRoute.
///  * [showGeneralDialog], which allows for customization of the dialog popup.
///  * [showCupertinoDialog], which displays an iOS-style dialog.
class DialogRoute<T> extends RawDialogRoute<T> {
  /// A dialog route with Material entrance and exit animations,
  /// modal barrier color, and modal barrier behavior (dialog is dismissible
  /// with a tap on the barrier).
  DialogRoute({
    required BuildContext context,
    required WidgetBuilder builder,
    CapturedThemes? themes,
    Color? barrierColor = Colors.black54,
    bool barrierDismissible = true,
    String? barrierLabel,
    bool useSafeArea = true,
    RouteSettings? settings,
  }) : assert(barrierDismissible != null),
       super(
         pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
           final Widget pageChild = Builder(builder: builder);
           Widget dialog = themes?.wrap(pageChild) ?? pageChild;
           if (useSafeArea) {
             dialog = SafeArea(child: dialog);
           }
           return dialog;
         },
         barrierDismissible: barrierDismissible,
         barrierColor: barrierColor,
         barrierLabel: barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
         transitionDuration: const Duration(milliseconds: 150),
         transitionBuilder: _buildMaterialDialogTransitions,
         settings: settings,
       );
}

double _paddingScaleFactor(double textScaleFactor) {
  final double clampedTextScaleFactor = textScaleFactor.clamp(1.0, 2.0).toDouble();
  // The final padding scale factor is clamped between 1/3 and 1. For example,
  // a non-scaled padding of 24 will produce a padding between 24 and 8.
  return lerpDouble(1.0, 1.0 / 3.0, clampedTextScaleFactor - 1.0)!;
}
