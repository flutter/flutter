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

   Utilities for building Huffman decoding tables.
*/

#ifndef BROTLI_DEC_HUFFMAN_H_
#define BROTLI_DEC_HUFFMAN_H_

#include <assert.h>
#include "./types.h"

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

typedef struct {
  uint8_t bits;     /* number of bits used for this symbol */
  uint16_t value;   /* symbol value or table offset */
} HuffmanCode;

/* Builds Huffman lookup table assuming code lengths are in symbol order. */
/* Returns false in case of error (invalid tree or memory error). */
int BrotliBuildHuffmanTable(HuffmanCode* root_table,
                            int root_bits,
                            const uint8_t* const code_lengths,
                            int code_lengths_size);

#if defined(__cplusplus) || defined(c_plusplus)
}    /* extern "C" */
#endif

#endif  /* BROTLI_DEC_HUFFMAN_H_ */
