// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_STANDARD_MESSAGE_CODEC_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_STANDARD_MESSAGE_CODEC_H_

#if !defined(__FLUTTER_LINUX_INSIDE__) && !defined(FLUTTER_LINUX_COMPILATION)
#error "Only <flutter_linux/flutter_linux.h> can be included directly."
#endif

#include <gmodule.h>

#include "fl_message_codec.h"

G_BEGIN_DECLS

G_MODULE_EXPORT
G_DECLARE_FINAL_TYPE(FlStandardMessageCodec,
                     fl_standard_message_codec,
                     FL,
                     STANDARD_CODEC,
                     FlMessageCodec)

/**
 * FlStandardMessageCodec:
 *
 * #FlStandardMessageCodec is an #FlMessageCodec that implements the Flutter
 * standard message encoding. This codec encodes and decodes #FlValue of type
 * #FL_VALUE_TYPE_NULL, #FL_VALUE_TYPE_BOOL, #FL_VALUE_TYPE_INT,
 * #FL_VALUE_TYPE_FLOAT, #FL_VALUE_TYPE_STRING, #FL_VALUE_TYPE_UINT8_LIST,
 * #FL_VALUE_TYPE_INT32_LIST, #FL_VALUE_TYPE_INT64_LIST,
 * #FL_VALUE_TYPE_FLOAT_LIST, #FL_VALUE_TYPE_LIST, and #FL_VALUE_TYPE_MAP.
 *
 * #FlStandardMessageCodec matches the StandardCodec class in the Flutter
 * services library.
 */

/*
 * fl_standard_message_codec_new:
 *
 * Creates an #FlStandardMessageCodec.
 *
 * Returns: a new #FlStandardMessageCodec.
 */
FlStandardMessageCodec* fl_standard_message_codec_new();

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_STANDARD_MESSAGE_CODEC_H_
