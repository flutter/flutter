// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Annotation values for `@pragma('dart2js:load-priority:xxx')` annotations.
enum LoadLibraryPriority {
  // Order is important as it is the `index` of the enum that is passed to the
  // runtime helper.

  // Normal priority, if there is no `dart2js:load-priority:xxx` annotation.
  normal,

  // High priority.
  high,

  // TODO(sra): Do we want more priorities, e.g. "background", where the loader
  // defers any work until the next microtask, and is conservative about
  // initialization jank.
}
