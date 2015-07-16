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

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "./huffman.h"
#include "./safe_malloc.h"

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

#define MAX_LENGTH 15

/* Returns reverse(reverse(key, len) + 1, len), where reverse(key, len) is the
   bit-wise reversal of the len least significant bits of key. */
static BROTLI_INLINE int GetNextKey(int key, int len) {
  int step = 1 << (len - 1);
  while (key & step) {
    step >>= 1;
  }
  return (key & (step - 1)) + step;
}

/* Stores code in table[0], table[step], table[2*step], ..., table[end] */
/* Assumes that end is an integer multiple of step */
static BROTLI_INLINE void ReplicateValue(HuffmanCode* table,
                                         int step, int end,
                                         HuffmanCode code) {
  do {
    end -= step;
    table[end] = code;
  } while (end > 0);
}

/* Returns the table width of the next 2nd level table. count is the histogram
   of bit lengths for the remaining symbols, len is the code length of the next
   processed symbol */
static BROTLI_INLINE int NextTableBitSize(const int* const count,
                                          int len, int root_bits) {
  int left = 1 << (len - root_bits);
  while (len < MAX_LENGTH) {
    left -= count[len];
    if (left <= 0) break;
    ++len;
    left <<= 1;
  }
  return len - root_bits;
}

int BrotliBuildHuffmanTable(HuffmanCode* root_table,
                            int root_bits,
                            const uint8_t* const code_lengths,
                            int code_lengths_size) {
  HuffmanCode code;    /* current table entry */
  HuffmanCode* table;  /* next available space in table */
  int len;             /* current code length */
  int symbol;          /* symbol index in original or sorted table */
  int key;             /* reversed prefix code */
  int step;            /* step size to replicate values in current table */
  int low;             /* low bits for current root entry */
  int mask;            /* mask for low bits */
  int table_bits;      /* key length of current table */
  int table_size;      /* size of current table */
  int total_size;      /* sum of root table size and 2nd level table sizes */
  int* sorted;         /* symbols sorted by code length */
  int count[MAX_LENGTH + 1] = { 0 };  /* number of codes of each length */
  int offset[MAX_LENGTH + 1];  /* offsets in sorted table for each length */

  sorted = (int*)malloc((size_t)code_lengths_size * sizeof(*sorted));
  if (sorted == NULL) {
    return 0;
  }

  /* build histogram of code lengths */
  for (symbol = 0; symbol < code_lengths_size; symbol++) {
    count[code_lengths[symbol]]++;
  }

  /* generate offsets into sorted symbol table by code length */
  offset[1] = 0;
  for (len = 1; len < MAX_LENGTH; len++) {
    offset[len + 1] = offset[len] + count[len];
  }

  /* sort symbols by length, by symbol order within each length */
  for (symbol = 0; symbol < code_lengths_size; symbol++) {
    if (code_lengths[symbol] != 0) {
      sorted[offset[code_lengths[symbol]]++] = symbol;
    }
  }

  table = root_table;
  table_bits = root_bits;
  table_size = 1 << table_bits;
  total_size = table_size;

  /* special case code with only one value */
  if (offset[MAX_LENGTH] == 1) {
    code.bits = 0;
    code.value = (uint16_t)sorted[0];
    for (key = 0; key < total_size; ++key) {
      table[key] = code;
    }
    free(sorted);
    return total_size;
  }

  /* fill in root table */
  key = 0;
  symbol = 0;
  for (len = 1, step = 2; len <= root_bits; ++len, step <<= 1) {
    for (; count[len] > 0; --count[len]) {
      code.bits = (uint8_t)(len);
      code.value = (uint16_t)sorted[symbol++];
      ReplicateValue(&table[key], step, table_size, code);
      key = GetNextKey(key, len);
    }
  }

  /* fill in 2nd level tables and add pointers to root table */
  mask = total_size - 1;
  low = -1;
  for (len = root_bits + 1, step = 2; len <= MAX_LENGTH; ++len, step <<= 1) {
    for (; count[len] > 0; --count[len]) {
      if ((key & mask) != low) {
        table += table_size;
        table_bits = NextTableBitSize(count, len, root_bits);
        table_size = 1 << table_bits;
        total_size += table_size;
        low = key & mask;
        root_table[low].bits = (uint8_t)(table_bits + root_bits);
        root_table[low].value = (uint16_t)((table - root_table) - low);
      }
      code.bits = (uint8_t)(len - root_bits);
      code.value = (uint16_t)sorted[symbol++];
      ReplicateValue(&table[key >> root_bits], step, table_size, code);
      key = GetNextKey(key, len);
    }
  }

  free(sorted);
  return total_size;
}

#if defined(__cplusplus) || defined(c_plusplus)
}    /* extern "C" */
#endif
