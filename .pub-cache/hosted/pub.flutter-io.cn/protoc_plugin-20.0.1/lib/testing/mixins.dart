abstract class Mixin1 {
  String get overriddenString => 'mixin1';

  String get interfaceString;
  set interfaceString(String string);
  bool hasInterfaceString();
}

abstract class Mixin2 {
  String get overriddenString => 'mixin2';

  bool hasOverriddenHasMethod() => false;
}

abstract class Mixin3 {}
