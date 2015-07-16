// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Module "mojo/public/js/threading"
//
// Note: This file is for documentation purposes only. The code here is not
// actually executed. The real module is implemented natively in Mojo.
//
// This module provides a way for a Mojo application implemented in JS
// to exit by quitting the current message loop. This module is not
// intended to be used by Mojo JS application started by the JS
// content handler.

while (1);

/**
 * Quits the current message loop, esssentially:
 * base::MessageLoop::current()->QuitNow();
*/
function quit() { [native code] }
