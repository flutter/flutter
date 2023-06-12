// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

finalLocalBool(int? x) {
  final bool b = x == null;
  if (!b) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

finalLocalBool_untyped(int? x) {
  final b = x == null;
  if (!b) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

localBool(int? x) {
  bool b = x == null;
  if (!b) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

localBool_untyped(int? x) {
  var b = x == null;
  if (!b) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

localBool_assigned(int? x, bool b1) {
  bool b2 = b1;
  b2 = x == null;
  if (!b2) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

localBool_assigned_untyped(int? x, bool b1) {
  var b2 = b1;
  b2 = x == null;
  if (!b2) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

localBool_assignedDynamic(int? x, bool b1) {
  dynamic b2 = b1;
  b2 = x == null;
  if (!b2) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

parameter_assigned(int? x, bool b) {
  b = x == null;
  if (!b) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

parameter_assigned_untyped(int? x, b) {
  b = x == null;
  if (!b) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

parameter_assignedDynamic(int? x, dynamic b) {
  b = x == null;
  if (!b) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

lateFinalLocalBool(int? x) {
  late final bool b = x == null;
  if (!b) {
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    x;
  } else {
    x;
  }
}

lateFinalLocalBool_untyped(int? x) {
  late final b = x == null;
  if (!b) {
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    x;
  } else {
    x;
  }
}

lateLocalBool(int? x) {
  late bool b = x == null;
  if (!b) {
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    x;
  } else {
    x;
  }
}

lateLocalBool_untyped(int? x) {
  late var b = x == null;
  if (!b) {
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    x;
  } else {
    x;
  }
}

lateLocalBool_assignedAndInitialized(int? x, bool b1) {
  late bool b2 = b1;
  b2 = x == null;
  if (!b2) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

lateLocalBool_assignedAndInitialized_untyped(int? x, bool b1) {
  late var b2 = b1;
  b2 = x == null;
  if (!b2) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

lateLocalBool_assignedButNotInitialized(int? x) {
  late bool b;
  b = x == null;
  if (!b) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

lateLocalBool_assignedButNotInitialized_untyped(int? x) {
  late var b;
  b = x == null;
  if (!b) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

rebaseWithDemotion(int? x, int? y, int? z, int? a) {
  x;
  y;
  z;
  if (y == null) return;
  x;
  /*nonNullable*/ y;
  z;
  bool b = x == null;
  x;
  /*nonNullable*/ y;
  z;
  if (z == null) return;
  x;
  /*nonNullable*/ y;
  /*nonNullable*/ z;
  y = a;
  x;
  y;
  /*nonNullable*/ z;
  if (b) return;
  /*nonNullable*/ x;
  y;
  /*nonNullable*/ z;
}

compoundAssignment(int? x, dynamic b) {
  b += x == null;
  if (!b) {
    // It's not safe to promote, because there's no guarantee that value of `b`
    // has anything to do with the result of `x == null`.
    x;
  } else {
    x;
  }
}

ifNullAssignment(int? x, dynamic b) {
  b ??= x == null;
  if (!b) {
    // It's not safe to promote, because there's no guarantee that value of `b`
    // has anything to do with the result of `x == null`.
    x;
  } else {
    x;
  }
}
