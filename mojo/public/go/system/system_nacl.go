// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package system

import "runtime/nacl"

// NaCl uses the runtime's Mojo IRT based system implementation.
func init() {
	sysImpl = &nacl.MojoNaClSystem{}
}
