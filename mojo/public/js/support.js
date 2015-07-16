// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Module "mojo/public/js/support"
//
// Note: This file is for documentation purposes only. The code here is not
// actually executed. The real module is implemented natively in Mojo.

while (1);

/*
 * Waits on the given handle until the state indicated by |signals| is
 * satisfied.
 *
 * @param {MojoHandle} handle The handle to wait on.
 * @param {MojoHandleSignals} signals Specifies the condition to wait for.
 * @param {function (mojoResult)} callback Called with the result the wait is
 * complete. See MojoWait for possible result codes.
 *
 * @return {MojoWaitId} A waitId that can be passed to cancelWait to cancel the
 * wait.
 */
function asyncWait(handle, signals, callback) { [native code] }

/*
 * Cancels the asyncWait operation specified by the given |waitId|.
 * @param {MojoWaitId} waitId The waitId returned by asyncWait.
 */
function cancelWait(waitId) { [native code] }
