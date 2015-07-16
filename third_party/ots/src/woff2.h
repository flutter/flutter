// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_WOFF2_H_
#define OTS_WOFF2_H_

namespace ots {

// Compute the size of the final uncompressed font, or 0 on error.
size_t ComputeWOFF2FinalSize(const uint8_t *data, size_t length);

// Decompresses the font into the target buffer. The result_length should
// be the same as determined by ComputeFinalSize(). Returns true on successful
// decompression.
bool ConvertWOFF2ToSFNT(OpenTypeFile *file, uint8_t *result, size_t result_length,
                        const uint8_t *data, size_t length);
}

#endif  // OTS_WOFF2_H_
