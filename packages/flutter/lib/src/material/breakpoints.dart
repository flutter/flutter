import 'package:flutter/widgets.dart';
import 'theme.dart';

const List<TargetPlatform> _desktop = <TargetPlatform>[TargetPlatform.fuchsia, TargetPlatform.linux, TargetPlatform.macOS, TargetPlatform.windows];
const List<TargetPlatform> _mobile = <TargetPlatform>[TargetPlatform.iOS, TargetPlatform.android];

/// Standard Breakpoints.
class Breakpoints {
  /// Small breakpoint. Open bounded.
  static const Breakpoint small =  _Breakpoint(begin: 0);
  /// Small breakpoint for non-mobile. Open bounded.
  static const Breakpoint smallDesktop =  _Breakpoint(begin: 0, platform: _desktop);
  /// Small breakpoint for non-mobile. Close bounded.
  static const Breakpoint onlySmallDesktop =  _Breakpoint(begin: 0, end: 800, platform: _desktop);
  /// Small breakpoint for mobile. Open bounded.
  static const Breakpoint smallMobile =  _Breakpoint(begin: 0, platform: _mobile);
  /// Medium breakpoint. Close bounded.
  static const Breakpoint medium = _Breakpoint(begin: 800, end: 1000);
  /// Medium breakpoint for non-mobile. Close bounded.
  static const Breakpoint mediumDesktop = _Breakpoint(begin: 800, end: 1000, platform: _desktop);
  /// Medium breakpoint for mobile. Close bounded.
  static const Breakpoint mediumMobile = _Breakpoint(begin: 800, end: 1000, platform: _mobile);
  /// Large breakpoint. Open bounded.
  static const Breakpoint large = _Breakpoint(begin: 1000);
  /// Large breakpoint for non-mobile. Open bounded.
  static const Breakpoint largeDesktop = _Breakpoint(begin: 1000, platform: _desktop);
  /// Large breakpoint for mobile. Open bounded.
  static const Breakpoint largeMobile = _Breakpoint(begin: 1000, platform: _mobile);
}


class _Breakpoint extends Breakpoint {
  const _Breakpoint({this.begin, this.end, this.platform});
  final double? begin;
  final double? end;
  final List<TargetPlatform>? platform;

  @override
  bool isActive(BuildContext context) {
    bool size = false;
    final bool isRightPlatform = platform?.contains(Theme.of(context).platform) ?? true;
    if (begin != null && end != null) {
      size = MediaQuery.of(context).size.width >= begin! && MediaQuery.of(context).size.width < end!;
    } else if (begin != null && end == null) {
      size = MediaQuery.of(context).size.width >= begin!;
    } else if (begin == null && end != null) {
      size = MediaQuery.of(context).size.width < end!;
    }
    return size && isRightPlatform;
  }
}
