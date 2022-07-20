// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

// ignore: avoid_classes_with_only_static_members
class Breakpoints {
  static const Breakpoint small =  _SmallBreakpoint();
  static const Breakpoint medium = _MediumBreakpoint();
  static const Breakpoint large = _LargeBreakpoint();
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
    return MediaQuery.of(context).size.width > 0 && MediaQuery.of(context).size.width < 800;
  }
}
class _MediumBreakpoint extends Breakpoint {
  const _MediumBreakpoint();

  @override bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width > 800 && MediaQuery.of(context).size.width < 1000;
  }
}
class _LargeBreakpoint extends Breakpoint {
  const _LargeBreakpoint();

  @override bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width > 1000;
  }
}
