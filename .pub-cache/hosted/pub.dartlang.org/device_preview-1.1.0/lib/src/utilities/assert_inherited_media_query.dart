import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Indicate whether [child] uses an inherited [MediaQuery].
///
/// Note that its will try its best to evaluate this by seeing if child is a [WidgetsApp] and will eventually
/// look at children if child is a [ProxyWidget], [MultiChildRenderObjectWidget] or [SingleChildRenderObjectWidget].
bool isWidgetsAppUsingInheritedMediaQuery(
  Widget child, [
  bool fallback = true,
]) {
  if (child is MaterialApp) return child.useInheritedMediaQuery;
  if (child is CupertinoApp) return child.useInheritedMediaQuery;
  if (child is WidgetsApp) return child.useInheritedMediaQuery;
  if (child is WidgetsApp) return child.useInheritedMediaQuery;

  if (child is ProxyWidget) {
    return isWidgetsAppUsingInheritedMediaQuery(child.child);
  }
  if (child is SingleChildRenderObjectWidget) {
    return child.child == null ||
        isWidgetsAppUsingInheritedMediaQuery(child.child!);
  }

  if (child is MultiChildRenderObjectWidget) {
    return child.children.every(isWidgetsAppUsingInheritedMediaQuery);
  }

  return fallback;
}
