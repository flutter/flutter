import 'package:flutter/material.dart';
import 'breakpoint.dart';

const double defaultCompactBreakpoint = 0;
const double defaultMediumBreakpoint = 600;
const double defaultExpandedBreakpoint = 840;

class CompactBreakpoint extends Breakpoint {
  @override
  bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width >= defaultCompactBreakpoint;
  }
}

class MediumBreakpoint extends Breakpoint {
  const MediumBreakpoint();

  @override
  bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width >= defaultMediumBreakpoint;
  }
}

class ExpandedBreakpoint extends Breakpoint {
  const ExpandedBreakpoint();

  @override
  bool isActive(BuildContext context) {
    return MediaQuery.of(context).size.width >= defaultExpandedBreakpoint;
  }
}
