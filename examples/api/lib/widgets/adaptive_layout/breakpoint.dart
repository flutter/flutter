import 'package:flutter/material.dart';

abstract class Breakpoint {
  const Breakpoint();
  bool isActive(BuildContext context);
}
