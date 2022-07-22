import 'package:flutter/widgets.dart';
import 'theme.dart';

// ignore: avoid_classes_with_only_static_members
class Breakpoints {
  static const Breakpoint small =  _SmallBreakpoint();
  static const Breakpoint smallDesktop =  _SmallDesktopBreakpoint();
  static const Breakpoint smallMobile =  _SmallMobileBreakpoint();
  static const Breakpoint medium = _MediumBreakpoint();
  static const Breakpoint mediumDesktop = _MediumDesktopBreakpoint();
  static const Breakpoint mediumMobile = _MediumMobileBreakpoint();
  static const Breakpoint large = _LargeBreakpoint();
  static const Breakpoint largeDesktop = _LargeDesktopBreakpoint();
  static const Breakpoint largeMobile = _LargeMobileBreakpoint();
  static const Breakpoint standard = _StandardBreakpoint();
}


class _StandardBreakpoint extends Breakpoint {
  const _StandardBreakpoint();

  @override bool isActive(BuildContext context) {
    return true;
  }
}
class _SmallBreakpoint extends Breakpoint {
  const _SmallBreakpoint();

  @override bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width > 0;
  }
}
class _SmallDesktopBreakpoint extends Breakpoint {
  const _SmallDesktopBreakpoint();

  @override bool isActive(BuildContext context) {
    return Theme.of(context).platform != TargetPlatform.iOS &&
        Theme.of(context).platform != TargetPlatform.android &&
        MediaQuery.of(context).size.width > 0;
  }
}
class _SmallMobileBreakpoint extends Breakpoint {
  const _SmallMobileBreakpoint();

  @override bool isActive(BuildContext context) {
    return (Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.android) &&
        MediaQuery.of(context).size.width > 0;
  }
}
class _MediumBreakpoint extends Breakpoint {
  const _MediumBreakpoint();

  @override bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width > 800 && MediaQuery.of(context).size.width < 1000;
  }
}
class _MediumDesktopBreakpoint extends Breakpoint {
  const _MediumDesktopBreakpoint();

  @override bool isActive(BuildContext context) {
    return Theme.of(context).platform != TargetPlatform.iOS &&
        Theme.of(context).platform != TargetPlatform.android &&
        MediaQuery.of(context).size.width > 800 &&
        MediaQuery.of(context).size.width < 1000;
  }
}
class _MediumMobileBreakpoint extends Breakpoint {
  const _MediumMobileBreakpoint();

  @override bool isActive(BuildContext context) {
    return (Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.android) &&
        MediaQuery.of(context).size.width > 800 &&
        MediaQuery.of(context).size.width < 1000;
  }
}
class _LargeBreakpoint extends Breakpoint {
  const _LargeBreakpoint();

  @override bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width > 1000;
  }
}
class _LargeDesktopBreakpoint extends Breakpoint {
  const _LargeDesktopBreakpoint();

  @override bool isActive(BuildContext context) {
    return Theme.of(context).platform != TargetPlatform.iOS &&
        Theme.of(context).platform != TargetPlatform.android &&
        MediaQuery.of(context).size.width > 1000;
  }
}
class _LargeMobileBreakpoint extends Breakpoint {
  const _LargeMobileBreakpoint();

  @override bool isActive(BuildContext context) {
    return (Theme.of(context).platform != TargetPlatform.iOS || Theme.of(context).platform != TargetPlatform.android) &&
        MediaQuery.of(context).size.width > 1000;
  }
}
