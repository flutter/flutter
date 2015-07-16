/* Copyright 2013 Google Inc. All Rights Reserved.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   API for Brotli decompression
*/

#ifndef BROTLI_DEC_DECODE_H_
#define BROTLI_DEC_DECODE_H_

#include "./streams.h"
#include "./types.h"

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

/* Sets *decoded_size to the decompressed size of the given encoded stream. */
/* This function only works if the encoded buffer has a single meta block, */
/* or if it has two meta-blocks, where the first is uncompressed and the */
/* second is empty. */
/* Returns 1 on success, 0 on failure. */
int BrotliDecompressedSize(size_t encoded_size,
                           const uint8_t* encoded_buffer,
                           size_t* decoded_size);

/* Decompresses the data in encoded_buffer into decoded_buffer, and sets */
/* *decoded_size to the decompressed length. */
/* Returns 0 if there was either a bit stream error or memory allocation */
/* error, and 1 otherwise. */
/* If decoded size is zero, returns 1 and keeps decoded_buffer unchanged. */
int BrotliDecompressBuffer(size_t encoded_size,
                           const uint8_t* encoded_buffer,
                           size_t* decoded_size,
                           uint8_t* decoded_buffer);

/* Same as above, but uses the specified input and output callbacks instead */
/* of reading from and writing to pre-allocated memory buffers. */
int BrotliDecompress(BrotliInput input, BrotliOutput output);

#if defined(__cplusplus) || defined(c_plusplus)
}    /* extern "C" */
#endif

#endif  /* BROTLI_DEC_DECODE_H_ */
