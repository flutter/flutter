// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PointerProperties_h
#define PointerProperties_h

namespace blink {

// The values of these enums must match their corresponding enums in
// WebSettings.h.

// Used as a bitfield so enums must be powers of 2.
enum PointerType {
    PointerTypeNone = 1,
    PointerTypeCoarse = 2,
    PointerTypeFine = 4
};

// Used as a bitfield so enums must be powers of 2.
enum HoverType {
    HoverTypeNone = 1,
    // Indicates that the primary pointing system can hover, but it requires
    // a significant action on the user’s part. e.g. hover on “long press”.
    HoverTypeOnDemand = 2,
    HoverTypeHover = 4
};

}

#endif
