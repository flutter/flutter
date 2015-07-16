// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_COCOA_PROTOCOLS_H_
#define BASE_MAC_COCOA_PROTOCOLS_H_

#import <Cocoa/Cocoa.h>

// New Mac OS X SDKs introduce new protocols used for delegates.  These
// protocol defintions aren't not present in earlier releases of the Mac OS X
// SDK.  In order to support building against the new SDK, which requires
// delegates to conform to these protocols, and earlier SDKs, which do not
// define these protocols at all, this file will provide empty protocol
// definitions when used with earlier SDK versions.

#define DEFINE_EMPTY_PROTOCOL(p) \
@protocol p \
@end

#if !defined(MAC_OS_X_VERSION_10_7) || \
    MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_7

DEFINE_EMPTY_PROTOCOL(NSDraggingDestination)
DEFINE_EMPTY_PROTOCOL(ICCameraDeviceDownloadDelegate)

#endif  // MAC_OS_X_VERSION_10_7

#undef DEFINE_EMPTY_PROTOCOL

#endif  // BASE_MAC_COCOA_PROTOCOLS_H_
