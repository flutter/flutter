// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_SCOPED_NSEXCEPTION_ENABLER_H_
#define BASE_MAC_SCOPED_NSEXCEPTION_ENABLER_H_

#import <Foundation/Foundation.h>

#include "base/base_export.h"
#include "base/basictypes.h"

namespace base {
namespace mac {

// BrowserCrApplication attempts to restrict throwing of NSExceptions
// because they interact badly with C++ scoping rules.  Unfortunately,
// there are some cases where exceptions must be supported, such as
// when third-party printer drivers are used.  These helpers can be
// used to enable exceptions for narrow windows.

// Make it easy to safely allow NSException to be thrown in a limited
// scope.  Note that if an exception is thrown, then this object will
// not be appropriately destructed!  If the exception ends up in the
// top-level event loop, things are cleared in -reportException:.  If
// the exception is caught at a lower level, a higher level scoper
// should eventually reset things.
class BASE_EXPORT ScopedNSExceptionEnabler {
 public:
  ScopedNSExceptionEnabler();
  ~ScopedNSExceptionEnabler();

 private:
  bool was_enabled_;

  DISALLOW_COPY_AND_ASSIGN(ScopedNSExceptionEnabler);
};

// Access the exception setting for the current thread.  This is for
// the support code in BrowserCrApplication, other code should use
// the scoper.
BASE_EXPORT bool GetNSExceptionsAllowed();
BASE_EXPORT void SetNSExceptionsAllowed(bool allowed);

// Executes |block| with fatal-exceptions turned off, and returns the
// result.  If an exception is thrown during the perform, nil is
// returned.
typedef id (^BlockReturningId)();
BASE_EXPORT id RunBlockIgnoringExceptions(BlockReturningId block);

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_SCOPED_NSEXCEPTION_ENABLER_H_
