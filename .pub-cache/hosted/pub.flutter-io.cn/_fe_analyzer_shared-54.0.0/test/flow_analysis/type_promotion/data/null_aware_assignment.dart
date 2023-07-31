// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

unrelatedTypes(Object? x, String? y) {
  if (x is int?) {
    /*int?*/ x ??= y;
    x;
  }
}

unrelatedTypes_nonNull(Object? x, String y) {
  if (x is int?) {
    /*int?*/ x ??= y;
    // TODO(paulberry): in principle we could promote x to Object.
    // Should we?
    x;
  }
}

supertype_previouslyPromoted(Object? x, num? y) {
  if (x is num?) {
    if (/*num?*/ x is int?) {
      /*int?*/ x ??= y;
      /*num?*/ x;
    }
  }
}

supertype_previouslyPromoted_nonNull(Object? x, num y) {
  if (x is num?) {
    if (/*num?*/ x is int?) {
      /*int?*/ x ??= y;
      // TODO(paulberry): we don't promote to num because it's not a
      // type of interest.  Should we consider it a type of interest
      // so that x is known to be non-null here?
      /*num?*/ x;
    }
  }
}

supertype_notPreviouslyPromoted(Object? x, num? y) {
  if (x is int?) {
    /*int?*/ x ??= y;
    x;
  }
}

supertype_notPreviouslyPromoted_nonNull(Object? x, num y) {
  if (x is int?) {
    /*int?*/ x ??= y;
    // TODO(paulberry): we don't promote to Object because it's not a
    // type of interest.  Should we consider it a type of interest
    // so that x is known to be non-null here?
  }
}

sameType(Object? x, int? y) {
  if (x is int?) {
    /*int?*/ x ??= y;
    /*int?*/ x;
  }
}

sameType_nonNull(Object? x, int y) {
  if (x is int?) {
    /*int?*/ x ??= y;
    // The implicit null test in the `??=` makes `int` a type of
    // interest for `x`, so it is promoted.
    /*int*/ x;
  }
}

subtype(Object? x, int? y) {
  if (x is num?) {
    /*num?*/ x ??= y;
    /*num?*/ x;
  }
}

subtype_nonNull(Object? x, int y) {
  if (x is num?) {
    /*num?*/ x ??= y;
    // The implicit null test in the `??=` makes `num` a type of
    // interest for `x`, so it is promoted.
    /*num*/ x;
  }
}
