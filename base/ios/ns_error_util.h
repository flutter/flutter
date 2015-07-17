// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_IOS_NS_ERROR_UTIL_H_
#define BASE_IOS_NS_ERROR_UTIL_H_

@class NSError;

namespace base {
namespace ios {

// Iterates through |error|'s underlying errors and returns the first error for
// which there is no underlying error.
NSError* GetFinalUnderlyingErrorFromError(NSError* error);

// Returns a copy of |original_error| with |underlying_error| appended to the
// end of its underlying error chain.
NSError* ErrorWithAppendedUnderlyingError(NSError* original_error,
                                          NSError* underlying_error);

}  // namespace ios
}  // namespace base

#endif  // BASE_IOS_NS_ERROR_UTIL_H_
