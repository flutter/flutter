// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

/**
 * Represents a resource, or a holder of resources, which may be released once they are no longer
 * needed.
 */
interface Releasable {
  /** Notify that that the reference to an object will be removed by a holder. */
  void release();
}
