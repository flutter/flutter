// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package system

import "mojo/public/platform/native_cgo"

// Linux uses the CGo based system implementation.
func init() {
	sysImpl = &native_cgo.CGoSystem{}
}
