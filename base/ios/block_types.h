// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_IOS_BLOCK_TYPES_H_
#define BASE_IOS_BLOCK_TYPES_H_

// A generic procedural block type that takes no arguments and returns nothing.
typedef void (^ProceduralBlock)(void);

// A block that takes no arguments and returns a bool.
typedef bool (^ConditionBlock)(void);

#endif  // BASE_IOS_BLOCK_TYPES_H_
