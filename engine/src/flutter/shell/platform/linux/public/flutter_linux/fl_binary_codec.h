// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_BINARY_CODEC_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_BINARY_CODEC_H_

#if !defined(__FLUTTER_LINUX_INSIDE__) && !defined(FLUTTER_LINUX_COMPILATION)
#error "Only <flutter_linux/flutter_linux.h> can be included directly."
#endif

#include "fl_message_codec.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlBinaryCodec,
                     fl_standard_codec,
                     FL,
                     BINARY_CODEC,
                     FlMessageCodec)

/**
 * FlBinaryCodec:
 *
 * #FlBinaryCodec is a #FlMessageCodec that implements the Flutter binary
 * message encoding. This encodes and decodes #FlValue of type
 * #FL_VALUE_TYPE_UINT8_LIST.
 *
 * #FlBinaryCodec matches the BinaryCodec class in the Flutter services
 * library.
 */

/**
 * fl_binary_codec_new:
 *
 * Creates a #FlBinaryCodec.
 *
 * Returns: a new #FlBinaryCodec.
 */
FlBinaryCodec* fl_binary_codec_new();

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_BINARY_CODEC_H_
