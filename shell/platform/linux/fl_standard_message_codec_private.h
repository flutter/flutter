// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_STANDARD_MESSAGE_CODEC_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_STANDARD_MESSAGE_CODEC_PRIVATE_H_

#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_message_codec.h"

G_BEGIN_DECLS

/**
 * fl_standard_message_codec_write_size:
 * @codec: an #FlStandardMessageCodec.
 * @buffer: buffer to write into.
 * @size: size value to write.
 *
 * Writes a size field in Flutter Standard encoding.
 */
void fl_standard_message_codec_write_size(FlStandardMessageCodec* codec,
                                          GByteArray* buffer,
                                          uint32_t size);

/**
 * fl_standard_message_codec_read_size:
 * @codec: an #FlStandardMessageCodec.
 * @buffer: buffer to read from.
 * @offset: (inout): read position in @buffer.
 * @value: location to read size.
 * @error: (allow-none): #GError location to store the error occurring, or
 * %NULL.
 *
 * Reads a size field in Flutter Standard encoding.
 *
 * Returns: %TRUE on success.
 */
gboolean fl_standard_message_codec_read_size(FlStandardMessageCodec* codec,
                                             GBytes* buffer,
                                             size_t* offset,
                                             uint32_t* value,
                                             GError** error);

/**
 * fl_standard_message_codec_write_value:
 * @codec: an #FlStandardMessageCodec.
 * @buffer: buffer to write into.
 * @value: (allow-none): value to write.
 * @error: (allow-none): #GError location to store the error occurring, or
 * %NULL.
 *
 * Writes an #FlValue in Flutter Standard encoding.
 *
 * Returns: %TRUE on success.
 */
gboolean fl_standard_message_codec_write_value(FlStandardMessageCodec* codec,
                                               GByteArray* buffer,
                                               FlValue* value,
                                               GError** error);

/**
 * fl_standard_message_codec_read_value:
 * @codec: an #FlStandardMessageCodec.
 * @buffer: buffer to read from.
 * @offset: (inout): read position in @buffer.
 * @value: location to read size.
 * @error: (allow-none): #GError location to store the error occurring, or
 * %NULL.
 *
 * Reads an #FlValue in Flutter Standard encoding.
 *
 * Returns: a new #FlValue or %NULL on error.
 */
FlValue* fl_standard_message_codec_read_value(FlStandardMessageCodec* codec,
                                              GBytes* buffer,
                                              size_t* offset,
                                              GError** error);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_STANDARD_MESSAGE_CODEC_PRIVATE_H_
