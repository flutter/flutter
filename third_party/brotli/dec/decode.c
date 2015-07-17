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
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "./bit_reader.h"
#include "./context.h"
#include "./decode.h"
#include "./dictionary.h"
#include "./transform.h"
#include "./huffman.h"
#include "./prefix.h"
#include "./safe_malloc.h"

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

#ifdef BROTLI_DECODE_DEBUG
#define BROTLI_LOG_UINT(name)                                    \
  printf("[%s] %s = %lu\n", __func__, #name, (unsigned long)(name))
#define BROTLI_LOG_ARRAY_INDEX(array_name, idx)                  \
  printf("[%s] %s[%lu] = %lu\n", __func__, #array_name, \
         (unsigned long)(idx), (unsigned long)array_name[idx])
#else
#define BROTLI_LOG_UINT(name)
#define BROTLI_LOG_ARRAY_INDEX(array_name, idx)
#endif

static const uint8_t kDefaultCodeLength = 8;
static const uint8_t kCodeLengthRepeatCode = 16;
static const int kNumLiteralCodes = 256;
static const int kNumInsertAndCopyCodes = 704;
static const int kNumBlockLengthCodes = 26;
static const int kLiteralContextBits = 6;
static const int kDistanceContextBits = 2;

#define HUFFMAN_TABLE_BITS      8
#define HUFFMAN_TABLE_MASK      0xff

#define CODE_LENGTH_CODES 18
static const uint8_t kCodeLengthCodeOrder[CODE_LENGTH_CODES] = {
  1, 2, 3, 4, 0, 5, 17, 6, 16, 7, 8, 9, 10, 11, 12, 13, 14, 15,
};

#define NUM_DISTANCE_SHORT_CODES 16
static const int kDistanceShortCodeIndexOffset[NUM_DISTANCE_SHORT_CODES] = {
  3, 2, 1, 0, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2
};

static const int kDistanceShortCodeValueOffset[NUM_DISTANCE_SHORT_CODES] = {
  0, 0, 0, 0, -1, 1, -2, 2, -3, 3, -1, 1, -2, 2, -3, 3
};

static BROTLI_INLINE int DecodeWindowBits(BrotliBitReader* br) {
  if (BrotliReadBits(br, 1)) {
    return 17 + (int)BrotliReadBits(br, 3);
  } else {
    return 16;
  }
}

/* Decodes a number in the range [0..255], by reading 1 - 11 bits. */
static BROTLI_INLINE int DecodeVarLenUint8(BrotliBitReader* br) {
  if (BrotliReadBits(br, 1)) {
    int nbits = (int)BrotliReadBits(br, 3);
    if (nbits == 0) {
      return 1;
    } else {
      return (int)BrotliReadBits(br, nbits) + (1 << nbits);
    }
  }
  return 0;
}

/* Advances the bit reader position to the next byte boundary and verifies
   that any skipped bits are set to zero. */
static BROTLI_INLINE int JumpToByteBoundary(BrotliBitReader* br) {
  uint32_t new_bit_pos = (br->bit_pos_ + 7) & (uint32_t)(~7UL);
  uint32_t pad_bits = BrotliReadBits(br, (int)(new_bit_pos - br->bit_pos_));
  return pad_bits == 0;
}

static int DecodeMetaBlockLength(BrotliBitReader* br,
                                 int* meta_block_length,
                                 int* input_end,
                                 int* is_metadata,
                                 int* is_uncompressed) {
  int size_nibbles;
  int size_bytes;
  int i;
  *input_end = (int)BrotliReadBits(br, 1);
  *meta_block_length = 0;
  *is_uncompressed = 0;
  *is_metadata = 0;
  if (*input_end && BrotliReadBits(br, 1)) {
    return 1;
  }
  size_nibbles = (int)BrotliReadBits(br, 2) + 4;
  if (size_nibbles == 7) {
    *is_metadata = 1;
    /* Verify reserved bit. */
    if (BrotliReadBits(br, 1) != 0) {
      return 0;
    }
    size_bytes = (int)BrotliReadBits(br, 2);
    if (size_bytes == 0) {
      return 1;
    }
    for (i = 0; i < size_bytes; ++i) {
      int next_byte = (int)BrotliReadBits(br, 8);
      if (i + 1 == size_bytes && size_bytes > 1 && next_byte == 0) {
        return 0;
      }
      *meta_block_length |= next_byte << (i * 8);
    }
  } else {
    for (i = 0; i < size_nibbles; ++i) {
      int next_nibble = (int)BrotliReadBits(br, 4);
      if (i + 1 == size_nibbles && size_nibbles > 4 && next_nibble == 0) {
        return 0;
      }
      *meta_block_length |= next_nibble << (i * 4);
    }
  }
  ++(*meta_block_length);
  if (!*input_end && !*is_metadata) {
    *is_uncompressed = (int)BrotliReadBits(br, 1);
  }
  return 1;
}

/* Decodes the next Huffman code from bit-stream. */
static BROTLI_INLINE int ReadSymbol(const HuffmanCode* table,
                                    BrotliBitReader* br) {
  int nbits;
  BrotliFillBitWindow(br);
  table += (int)(br->val_ >> br->bit_pos_) & HUFFMAN_TABLE_MASK;
  nbits = table->bits - HUFFMAN_TABLE_BITS;
  if (nbits > 0) {
    br->bit_pos_ += HUFFMAN_TABLE_BITS;
    table += table->value;
    table += (int)(br->val_ >> br->bit_pos_) & ((1 << nbits) - 1);
  }
  br->bit_pos_ += table->bits;
  return table->value;
}

static void PrintUcharVector(const uint8_t* v, int len) {
  while (len-- > 0) printf(" %d", *v++);
  printf("\n");
}

static BrotliResult ReadHuffmanCodeLengths(
    const uint8_t* code_length_code_lengths,
    int num_symbols, uint8_t* code_lengths,
    BrotliState* s) {
  BrotliBitReader* br = &s->br;
  switch (s->sub_state[1]) {
    case BROTLI_STATE_SUB_HUFFMAN_LENGTH_BEGIN:
      s->symbol = 0;
      s->prev_code_len = kDefaultCodeLength;
      s->repeat = 0;
      s->repeat_code_len = 0;
      s->space = 32768;

      if (!BrotliBuildHuffmanTable(s->table, 5,
                                   code_length_code_lengths,
                                   CODE_LENGTH_CODES)) {
        printf("[ReadHuffmanCodeLengths] Building code length tree failed: ");
        PrintUcharVector(code_length_code_lengths, CODE_LENGTH_CODES);
        return BROTLI_RESULT_ERROR;
      }
      s->sub_state[1] = BROTLI_STATE_SUB_HUFFMAN_LENGTH_SYMBOLS;
      /* No break, continue to next state. */
    case BROTLI_STATE_SUB_HUFFMAN_LENGTH_SYMBOLS:
      while (s->symbol < num_symbols && s->space > 0) {
        const HuffmanCode* p = s->table;
        uint8_t code_len;
        if (!BrotliReadMoreInput(br)) {
          return BROTLI_RESULT_NEEDS_MORE_INPUT;
        }
        BrotliFillBitWindow(br);
        p += (br->val_ >> br->bit_pos_) & 31;
        br->bit_pos_ += p->bits;
        code_len = (uint8_t)p->value;
        if (code_len < kCodeLengthRepeatCode) {
          s->repeat = 0;
          code_lengths[s->symbol++] = code_len;
          if (code_len != 0) {
            s->prev_code_len = code_len;
            s->space -= 32768 >> code_len;
          }
        } else {
          const int extra_bits = code_len - 14;
          int old_repeat;
          int repeat_delta;
          uint8_t new_len = 0;
          if (code_len == kCodeLengthRepeatCode) {
            new_len =  s->prev_code_len;
          }
          if (s->repeat_code_len != new_len) {
            s->repeat = 0;
            s->repeat_code_len = new_len;
          }
          old_repeat = s->repeat;
          if (s->repeat > 0) {
            s->repeat -= 2;
            s->repeat <<= extra_bits;
          }
          s->repeat += (int)BrotliReadBits(br, extra_bits) + 3;
          repeat_delta = s->repeat - old_repeat;
          if (s->symbol + repeat_delta > num_symbols) {
            return BROTLI_RESULT_ERROR;
          }
          memset(&code_lengths[s->symbol], s->repeat_code_len,
                 (size_t)repeat_delta);
          s->symbol += repeat_delta;
          if (s->repeat_code_len != 0) {
            s->space -= repeat_delta << (15 - s->repeat_code_len);
          }
        }
      }
      if (s->space != 0) {
        printf("[ReadHuffmanCodeLengths] s->space = %d\n", s->space);
        return BROTLI_RESULT_ERROR;
      }
      memset(&code_lengths[s->symbol], 0, (size_t)(num_symbols - s->symbol));
      s->sub_state[1] = BROTLI_STATE_SUB_NONE;
      return BROTLI_RESULT_SUCCESS;
    default:
      return BROTLI_RESULT_ERROR;
  }
  return BROTLI_RESULT_ERROR;
}

static BrotliResult ReadHuffmanCode(int alphabet_size,
                                    HuffmanCode* table,
                                    int* opt_table_size,
                                    BrotliState* s) {
  BrotliBitReader* br = &s->br;
  BrotliResult result = BROTLI_RESULT_SUCCESS;
  int table_size = 0;
  /* State machine */
  for (;;) {
    switch(s->sub_state[1]) {
      case BROTLI_STATE_SUB_NONE:
        if (!BrotliReadMoreInput(br)) {
          return BROTLI_RESULT_NEEDS_MORE_INPUT;
        }
        s->code_lengths =
            (uint8_t*)BrotliSafeMalloc((uint64_t)alphabet_size,
                                       sizeof(*s->code_lengths));
        if (s->code_lengths == NULL) {
          return BROTLI_RESULT_ERROR;
        }
        /* simple_code_or_skip is used as follows:
           1 for simple code;
           0 for no skipping, 2 skips 2 code lengths, 3 skips 3 code lengths */
        s->simple_code_or_skip = (int)BrotliReadBits(br, 2);
        BROTLI_LOG_UINT(s->simple_code_or_skip);
        if (s->simple_code_or_skip == 1) {
          /* Read symbols, codes & code lengths directly. */
          int i;
          int max_bits_counter = alphabet_size - 1;
          int max_bits = 0;
          int symbols[4] = { 0 };
          const int num_symbols = (int)BrotliReadBits(br, 2) + 1;
          while (max_bits_counter) {
            max_bits_counter >>= 1;
            ++max_bits;
          }
          memset(s->code_lengths, 0, (size_t)alphabet_size);
          for (i = 0; i < num_symbols; ++i) {
            symbols[i] = (int)BrotliReadBits(br, max_bits);
            if (symbols[i] >= alphabet_size) {
              return BROTLI_RESULT_ERROR;
            }
            s->code_lengths[symbols[i]] = 2;
          }
          s->code_lengths[symbols[0]] = 1;
          switch (num_symbols) {
            case 1:
              break;
            case 3:
              if ((symbols[0] == symbols[1]) ||
                  (symbols[0] == symbols[2]) ||
                  (symbols[1] == symbols[2])) {
                return BROTLI_RESULT_ERROR;
              }
              break;
            case 2:
              if (symbols[0] == symbols[1]) {
                return BROTLI_RESULT_ERROR;
              }
              s->code_lengths[symbols[1]] = 1;
              break;
            case 4:
              if ((symbols[0] == symbols[1]) ||
                  (symbols[0] == symbols[2]) ||
                  (symbols[0] == symbols[3]) ||
                  (symbols[1] == symbols[2]) ||
                  (symbols[1] == symbols[3]) ||
                  (symbols[2] == symbols[3])) {
                return BROTLI_RESULT_ERROR;
              }
              if (BrotliReadBits(br, 1)) {
                s->code_lengths[symbols[2]] = 3;
                s->code_lengths[symbols[3]] = 3;
              } else {
                s->code_lengths[symbols[0]] = 2;
              }
              break;
          }
          BROTLI_LOG_UINT(num_symbols);
          s->sub_state[1] = BROTLI_STATE_SUB_HUFFMAN_DONE;
          break;
        } else {  /* Decode Huffman-coded code lengths. */
          int i;
          int space = 32;
          int num_codes = 0;
          /* Static Huffman code for the code length code lengths */
          static const HuffmanCode huff[16] = {
            {2, 0}, {2, 4}, {2, 3}, {3, 2}, {2, 0}, {2, 4}, {2, 3}, {4, 1},
            {2, 0}, {2, 4}, {2, 3}, {3, 2}, {2, 0}, {2, 4}, {2, 3}, {4, 5},
          };
          for (i = 0; i < CODE_LENGTH_CODES; i++) {
            s->code_length_code_lengths[i] = 0;
          }
          for (i = s->simple_code_or_skip;
              i < CODE_LENGTH_CODES && space > 0; ++i) {
            const int code_len_idx = kCodeLengthCodeOrder[i];
            const HuffmanCode* p = huff;
            uint8_t v;
            BrotliFillBitWindow(br);
            p += (br->val_ >> br->bit_pos_) & 15;
            br->bit_pos_ += p->bits;
            v = (uint8_t)p->value;
            s->code_length_code_lengths[code_len_idx] = v;
            BROTLI_LOG_ARRAY_INDEX(s->code_length_code_lengths, code_len_idx);
            if (v != 0) {
              space -= (32 >> v);
              ++num_codes;
            }
          }
          if (!(num_codes == 1 || space == 0)) {
            return BROTLI_RESULT_ERROR;
          }
          s->sub_state[1] = BROTLI_STATE_SUB_HUFFMAN_LENGTH_BEGIN;
        }
        /* No break, go to next state */
      case BROTLI_STATE_SUB_HUFFMAN_LENGTH_BEGIN:
      case BROTLI_STATE_SUB_HUFFMAN_LENGTH_SYMBOLS:
        result = ReadHuffmanCodeLengths(s->code_length_code_lengths,
                                        alphabet_size, s->code_lengths, s);
        if (result != BROTLI_RESULT_SUCCESS) return result;
        s->sub_state[1] = BROTLI_STATE_SUB_HUFFMAN_DONE;
        /* No break, go to next state */
      case BROTLI_STATE_SUB_HUFFMAN_DONE:
        table_size = BrotliBuildHuffmanTable(table, HUFFMAN_TABLE_BITS,
                                             s->code_lengths, alphabet_size);
        if (table_size == 0) {
          printf("[ReadHuffmanCode] BuildHuffmanTable failed: ");
          PrintUcharVector(s->code_lengths, alphabet_size);
          return BROTLI_RESULT_ERROR;
        }
        free(s->code_lengths);
        s->code_lengths = NULL;
        if (opt_table_size) {
          *opt_table_size = table_size;
        }
        s->sub_state[1] = BROTLI_STATE_SUB_NONE;
        return result;
      default:
        return BROTLI_RESULT_ERROR;  /* unknown state */
    }
  }

  return BROTLI_RESULT_ERROR;
}

static BROTLI_INLINE int ReadBlockLength(const HuffmanCode* table,
                                         BrotliBitReader* br) {
  int code;
  int nbits;
  code = ReadSymbol(table, br);
  nbits = kBlockLengthPrefixCode[code].nbits;
  return kBlockLengthPrefixCode[code].offset + (int)BrotliReadBits(br, nbits);
}

static int TranslateShortCodes(int code, int* ringbuffer, int index) {
  int val;
  if (code < NUM_DISTANCE_SHORT_CODES) {
    index += kDistanceShortCodeIndexOffset[code];
    index &= 3;
    val = ringbuffer[index] + kDistanceShortCodeValueOffset[code];
  } else {
    val = code - NUM_DISTANCE_SHORT_CODES + 1;
  }
  return val;
}

static void InverseMoveToFrontTransform(uint8_t* v, int v_len) {
  uint8_t mtf[256];
  int i;
  for (i = 0; i < 256; ++i) {
    mtf[i] = (uint8_t)i;
  }
  for (i = 0; i < v_len; ++i) {
    uint8_t index = v[i];
    uint8_t value = mtf[index];
    v[i] = value;
    for (; index; --index) {
      mtf[index] = mtf[index - 1];
    }
    mtf[0] = value;
  }
}

static BrotliResult HuffmanTreeGroupDecode(HuffmanTreeGroup* group,
                                           BrotliState* s) {
  switch (s->sub_state[0]) {
    case BROTLI_STATE_SUB_NONE:
      s->next = group->codes;
      s->htree_index = 0;
      s->sub_state[0] = BROTLI_STATE_SUB_TREE_GROUP;
      /* No break, continue to next state. */
    case BROTLI_STATE_SUB_TREE_GROUP:
      while (s->htree_index < group->num_htrees) {
        int table_size;
        BrotliResult result =
            ReadHuffmanCode(group->alphabet_size, s->next, &table_size, s);
        if (result != BROTLI_RESULT_SUCCESS) return result;
        group->htrees[s->htree_index] = s->next;
        s->next += table_size;
        if (table_size == 0) {
          return BROTLI_RESULT_ERROR;
        }
        ++s->htree_index;
      }
      s->sub_state[0] = BROTLI_STATE_SUB_NONE;
      return BROTLI_RESULT_SUCCESS;
    default:
      return BROTLI_RESULT_ERROR;  /* unknown state */
  }

  return BROTLI_RESULT_ERROR;
}

static BrotliResult DecodeContextMap(int context_map_size,
                                     int* num_htrees,
                                     uint8_t** context_map,
                                     BrotliState* s) {
  BrotliBitReader* br = &s->br;
  BrotliResult result = BROTLI_RESULT_SUCCESS;
  int use_rle_for_zeros;

  switch(s->sub_state[0]) {
    case BROTLI_STATE_SUB_NONE:
      if (!BrotliReadMoreInput(br)) {
        return BROTLI_RESULT_NEEDS_MORE_INPUT;
      }
      *num_htrees = DecodeVarLenUint8(br) + 1;

      s->context_index = 0;

      BROTLI_LOG_UINT(context_map_size);
      BROTLI_LOG_UINT(*num_htrees);

      *context_map = (uint8_t*)malloc((size_t)context_map_size);
      if (*context_map == 0) {
        return BROTLI_RESULT_ERROR;
      }
      if (*num_htrees <= 1) {
        memset(*context_map, 0, (size_t)context_map_size);
        return BROTLI_RESULT_SUCCESS;
      }

      use_rle_for_zeros = (int)BrotliReadBits(br, 1);
      if (use_rle_for_zeros) {
        s->max_run_length_prefix = (int)BrotliReadBits(br, 4) + 1;
      } else {
        s->max_run_length_prefix = 0;
      }
      s->context_map_table = (HuffmanCode*)malloc(
          BROTLI_HUFFMAN_MAX_TABLE_SIZE * sizeof(*s->context_map_table));
      if (s->context_map_table == NULL) {
        return BROTLI_RESULT_ERROR;
      }
      s->sub_state[0] = BROTLI_STATE_SUB_CONTEXT_MAP_HUFFMAN;
      /* No break, continue to next state. */
    case BROTLI_STATE_SUB_CONTEXT_MAP_HUFFMAN:
      result = ReadHuffmanCode(*num_htrees + s->max_run_length_prefix,
                               s->context_map_table, NULL, s);
      if (result != BROTLI_RESULT_SUCCESS) return result;
      s->sub_state[0] = BROTLI_STATE_SUB_CONTEXT_MAPS;
      /* No break, continue to next state. */
    case BROTLI_STATE_SUB_CONTEXT_MAPS:
      while (s->context_index < context_map_size) {
        int code;
        if (!BrotliReadMoreInput(br)) {
          return BROTLI_RESULT_NEEDS_MORE_INPUT;
        }
        code = ReadSymbol(s->context_map_table, br);
        if (code == 0) {
          (*context_map)[s->context_index] = 0;
          ++s->context_index;
        } else if (code <= s->max_run_length_prefix) {
          int reps = 1 + (1 << code) + (int)BrotliReadBits(br, code);
          while (--reps) {
            if (s->context_index >= context_map_size) {
              return BROTLI_RESULT_ERROR;
            }
            (*context_map)[s->context_index] = 0;
            ++s->context_index;
          }
        } else {
          (*context_map)[s->context_index] =
              (uint8_t)(code - s->max_run_length_prefix);
          ++s->context_index;
        }
      }
      if (BrotliReadBits(br, 1)) {
        InverseMoveToFrontTransform(*context_map, context_map_size);
      }
      free(s->context_map_table);
      s->context_map_table = NULL;
      s->sub_state[0] = BROTLI_STATE_SUB_NONE;
      return BROTLI_RESULT_SUCCESS;
    default:
      return BROTLI_RESULT_ERROR;  /* unknown state */
  }

  return BROTLI_RESULT_ERROR;
}

static BROTLI_INLINE void DecodeBlockType(const int max_block_type,
                                          const HuffmanCode* trees,
                                          int tree_type,
                                          int* block_types,
                                          int* ringbuffers,
                                          int* indexes,
                                          BrotliBitReader* br) {
  int* ringbuffer = ringbuffers + tree_type * 2;
  int* index = indexes + tree_type;
  int type_code =
      ReadSymbol(&trees[tree_type * BROTLI_HUFFMAN_MAX_TABLE_SIZE], br);
  int block_type;
  if (type_code == 0) {
    block_type = ringbuffer[*index & 1];
  } else if (type_code == 1) {
    block_type = ringbuffer[(*index - 1) & 1] + 1;
  } else {
    block_type = type_code - 2;
  }
  if (block_type >= max_block_type) {
    block_type -= max_block_type;
  }
  block_types[tree_type] = block_type;
  ringbuffer[(*index) & 1] = block_type;
  ++(*index);
}

/* Decodes the block type and updates the state for literal context. */
static BROTLI_INLINE void DecodeBlockTypeWithContext(BrotliState* s,
                                                     BrotliBitReader* br) {
  DecodeBlockType(s->num_block_types[0],
                  s->block_type_trees, 0,
                  s->block_type, s->block_type_rb,
                  s->block_type_rb_index, br);
  s->block_length[0] = ReadBlockLength(s->block_len_trees, br);
  s->context_offset = s->block_type[0] << kLiteralContextBits;
  s->context_map_slice = s->context_map + s->context_offset;
  s->literal_htree_index = s->context_map_slice[0];
  s->context_mode = s->context_modes[s->block_type[0]];
  s->context_lookup_offset1 = kContextLookupOffsets[s->context_mode];
  s->context_lookup_offset2 = kContextLookupOffsets[s->context_mode + 1];
}

/* Copy len bytes from src to dst. It can write up to ten extra bytes
   after the end of the copy.

   The main part of this loop is a simple copy of eight bytes at a time until
   we've copied (at least) the requested amount of bytes.  However, if dst and
   src are less than eight bytes apart (indicating a repeating pattern of
   length < 8), we first need to expand the pattern in order to get the correct
   results. For instance, if the buffer looks like this, with the eight-byte
   <src> and <dst> patterns marked as intervals:

      abxxxxxxxxxxxx
      [------]           src
        [------]         dst

   a single eight-byte copy from <src> to <dst> will repeat the pattern once,
   after which we can move <dst> two bytes without moving <src>:

      ababxxxxxxxxxx
      [------]           src
          [------]       dst

   and repeat the exercise until the two no longer overlap.

   This allows us to do very well in the special case of one single byte
   repeated many times, without taking a big hit for more general cases.

   The worst case of extra writing past the end of the match occurs when
   dst - src == 1 and len == 1; the last copy will read from byte positions
   [0..7] and write to [4..11], whereas it was only supposed to write to
   position 1. Thus, ten excess bytes.
*/
static BROTLI_INLINE void IncrementalCopyFastPath(
    uint8_t* dst, const uint8_t* src, int len) {
  if (src < dst) {
    while (dst - src < 8) {
      UNALIGNED_MOVE64(dst, src);
      len -= (int)(dst - src);
      dst += dst - src;
    }
  }
  while (len > 0) {
    UNALIGNED_COPY64(dst, src);
    src += 8;
    dst += 8;
    len -= 8;
  }
}

BrotliResult CopyUncompressedBlockToOutput(BrotliOutput output,
                                           int pos,
                                           BrotliState* s) {
  const int rb_size = s->ringbuffer_mask + 1;
  uint8_t* ringbuffer_end = s->ringbuffer + rb_size;
  int rb_pos = pos & s->ringbuffer_mask;
  int br_pos = s->br.pos_ & BROTLI_IBUF_MASK;
  uint32_t remaining_bits;
  int num_read;
  int num_written;

  /* State machine */
  for (;;) {
    switch (s->sub_state[0]) {
      case BROTLI_STATE_SUB_NONE:
        /* For short lengths copy byte-by-byte */
        if (s->meta_block_remaining_len < 8 || s->br.bit_pos_ +
            (uint32_t)(s->meta_block_remaining_len << 3) < s->br.bit_end_pos_) {
          s->sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_SHORT;
          break;
        }
        if (s->br.bit_end_pos_ < 64) {
          return BROTLI_RESULT_ERROR;
        }
        /*
         * Copy remaining 0-4 in 32-bit case or 0-8 bytes in the 64-bit case
         * from s->br.val_ to ringbuffer.
         */
#if (BROTLI_USE_64_BITS)
        remaining_bits = 64;
#else
        remaining_bits = 32;
#endif
        while (s->br.bit_pos_ < remaining_bits) {
          s->ringbuffer[rb_pos] = (uint8_t)(s->br.val_ >> s->br.bit_pos_);
          s->br.bit_pos_ += 8;
          ++rb_pos;
          --s->meta_block_remaining_len;
        }

        /* Copy remaining bytes from s->br.buf_ to ringbuffer. */
        s->nbytes = (int)(s->br.bit_end_pos_ - s->br.bit_pos_) >> 3;
        if (br_pos + s->nbytes > BROTLI_IBUF_MASK) {
          int tail = BROTLI_IBUF_MASK + 1 - br_pos;
          memcpy(&s->ringbuffer[rb_pos], &s->br.buf_[br_pos], (size_t)tail);
          s->nbytes -= tail;
          rb_pos += tail;
          s->meta_block_remaining_len -= tail;
          br_pos = 0;
        }
        memcpy(&s->ringbuffer[rb_pos], &s->br.buf_[br_pos], (size_t)s->nbytes);
        rb_pos += s->nbytes;
        s->meta_block_remaining_len -= s->nbytes;

        s->partially_written = 0;
        s->sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_1;
        /* No break, continue to next state */
      case BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_1:
        /* If we wrote past the logical end of the ringbuffer, copy the tail of
           the ringbuffer to its beginning and flush the ringbuffer to the
           output. */
        if (rb_pos >= rb_size) {
          num_written = BrotliWrite(output,
                                    s->ringbuffer + s->partially_written,
                                    (size_t)(rb_size - s->partially_written));
          if (num_written < 0) {
            return BROTLI_RESULT_ERROR;
          }
          s->partially_written += num_written;
          if (s->partially_written < rb_size) {
            return BROTLI_RESULT_NEEDS_MORE_OUTPUT;
          }
          rb_pos -= rb_size;
          s->meta_block_remaining_len += rb_size;
          memcpy(s->ringbuffer, ringbuffer_end, (size_t)rb_pos);
        }
        s->sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_FILL;
        break;
      case BROTLI_STATE_SUB_UNCOMPRESSED_SHORT:
        while (s->meta_block_remaining_len > 0) {
          if (!BrotliReadMoreInput(&s->br)) {
            return BROTLI_RESULT_NEEDS_MORE_INPUT;
          }
          s->ringbuffer[rb_pos++] = (uint8_t)BrotliReadBits(&s->br, 8);
          if (rb_pos == rb_size) {
            s->partially_written = 0;
            s->sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_2;
            break;
          }
          s->meta_block_remaining_len--;
        }
        if (s->sub_state[0] == BROTLI_STATE_SUB_UNCOMPRESSED_SHORT) {
          s->sub_state[0] = BROTLI_STATE_SUB_NONE;
          return BROTLI_RESULT_SUCCESS;
        }
        /* No break, if state is updated, continue to next state */
      case BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_2:
        num_written = BrotliWrite(output, s->ringbuffer + s->partially_written,
                                  (size_t)(rb_size - s->partially_written));
        if (num_written < 0) {
          return BROTLI_RESULT_ERROR;
        }
        s->partially_written += num_written;
        if (s->partially_written < rb_size) {
          return BROTLI_RESULT_NEEDS_MORE_OUTPUT;
        }
        rb_pos = 0;
        s->meta_block_remaining_len--;
        s->sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_SHORT;
        break;
      case BROTLI_STATE_SUB_UNCOMPRESSED_FILL:
        /* If we have more to copy than the remaining size of the ringbuffer,
           then we first fill the ringbuffer from the input and then flush the
           ringbuffer to the output */
        if (rb_pos + s->meta_block_remaining_len >= rb_size) {
          s->nbytes = rb_size - rb_pos;
          if (BrotliRead(s->br.input_, &s->ringbuffer[rb_pos],
                         (size_t)s->nbytes) < s->nbytes) {
            return BROTLI_RESULT_NEEDS_MORE_INPUT;
          }
          s->partially_written = 0;
          s->sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_3;
        } else {
          s->sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_COPY;
          break;
        }
        /* No break, continue to next state */
      case BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_3:
        num_written = BrotliWrite(output, s->ringbuffer + s->partially_written,
                                  (size_t)(rb_size - s->partially_written));
        if (num_written < 0) {
          return BROTLI_RESULT_ERROR;
        }
        s->partially_written += num_written;
        if (s->partially_written < rb_size) {
          return BROTLI_RESULT_NEEDS_MORE_OUTPUT;
        }
        s->meta_block_remaining_len -= s->nbytes;
        rb_pos = 0;
        s->sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_FILL;
        break;
      case BROTLI_STATE_SUB_UNCOMPRESSED_COPY:
        /* Copy straight from the input onto the ringbuffer. The ringbuffer will
           be flushed to the output at a later time. */
        num_read = BrotliRead(s->br.input_, &s->ringbuffer[rb_pos],
                              (size_t)s->meta_block_remaining_len);
        s->meta_block_remaining_len -= num_read;
        if (s->meta_block_remaining_len > 0) {
          return BROTLI_RESULT_NEEDS_MORE_INPUT;
        }

        /* Restore the state of the bit reader. */
        BrotliInitBitReader(&s->br, s->br.input_, s->br.finish_);
        s->sub_state[0] = BROTLI_STATE_SUB_UNCOMPRESSED_WARMUP;
        /* No break, continue to next state */
      case BROTLI_STATE_SUB_UNCOMPRESSED_WARMUP:
        if (!BrotliWarmupBitReader(&s->br)) {
          return BROTLI_RESULT_NEEDS_MORE_INPUT;
        }
        s->sub_state[0] = BROTLI_STATE_SUB_NONE;
        return BROTLI_RESULT_SUCCESS;
        break;
      default:
        return BROTLI_RESULT_ERROR;  /* Unknown state */
    }
  }
  return BROTLI_RESULT_ERROR;
}

BrotliResult BrotliDecompressedSize(size_t encoded_size,
                                    const uint8_t* encoded_buffer,
                                    size_t* decoded_size) {
  int i;
  uint64_t val = 0;
  int bit_pos = 0;
  int is_last;
  int is_uncompressed = 0;
  int size_nibbles;
  int meta_block_len = 0;
  if (encoded_size == 0) {
    return BROTLI_RESULT_ERROR;
  }
  /* Look at the first 8 bytes, it is enough to decode the length of the first
     meta-block. */
  for (i = 0; (size_t)i < encoded_size && i < 8; ++i) {
    val |= (uint64_t)encoded_buffer[i] << (8 * i);
  }
  /* Skip the window bits. */
  bit_pos += (val & 1) ? 4 : 1;
  /* Decode the ISLAST bit. */
  is_last = (val >> bit_pos) & 1;
  ++bit_pos;
  if (is_last) {
    /* Decode the ISEMPTY bit, if it is set to 1, we are done. */
    if ((val >> bit_pos) & 1) {
      *decoded_size = 0;
      return BROTLI_RESULT_SUCCESS;
    }
    ++bit_pos;
  }
  /* Decode the length of the first meta-block. */
  size_nibbles = (int)((val >> bit_pos) & 3) + 4;
  bit_pos += 2;
  for (i = 0; i < size_nibbles; ++i) {
    meta_block_len |= (int)((val >> bit_pos) & 0xf) << (4 * i);
    bit_pos += 4;
  }
  ++meta_block_len;
  if (is_last) {
    /* If this meta-block is the only one, we are done. */
    *decoded_size = (size_t)meta_block_len;
    return BROTLI_RESULT_SUCCESS;
  }
  is_uncompressed = (val >> bit_pos) & 1;
  ++bit_pos;
  if (is_uncompressed) {
    /* If the first meta-block is uncompressed, we skip it and look at the
       first two bits (ISLAST and ISEMPTY) of the next meta-block, and if
       both are set to 1, we have a stream with an uncompressed meta-block
       followed by an empty one, so the decompressed size is the size of the
       first meta-block. */
    size_t offset = (size_t)((bit_pos + 7) >> 3) + (size_t)meta_block_len;
    if (offset < encoded_size && ((encoded_buffer[offset] & 3) == 3)) {
      *decoded_size = (size_t)meta_block_len;
      return BROTLI_RESULT_SUCCESS;
    }
  }
  return BROTLI_RESULT_ERROR;
}

BrotliResult BrotliDecompressBuffer(size_t encoded_size,
                                    const uint8_t* encoded_buffer,
                                    size_t* decoded_size,
                                    uint8_t* decoded_buffer) {
  BrotliMemInput memin;
  BrotliInput in = BrotliInitMemInput(encoded_buffer, encoded_size, &memin);
  BrotliMemOutput mout;
  BrotliOutput out = BrotliInitMemOutput(decoded_buffer, *decoded_size, &mout);
  BrotliResult success = BrotliDecompress(in, out);
  *decoded_size = mout.pos;
  return success;
}

BrotliResult BrotliDecompress(BrotliInput input, BrotliOutput output) {
  BrotliState s;
  BrotliResult result;
  BrotliStateInit(&s);
  result = BrotliDecompressStreaming(input, output, 1, &s);
  if (result == BROTLI_RESULT_NEEDS_MORE_INPUT) {
    /* Not ok: it didn't finish even though this is a non-streaming function. */
    result = BROTLI_RESULT_ERROR;
  }
  BrotliStateCleanup(&s);
  return result;
}

BrotliResult BrotliDecompressBufferStreaming(size_t* available_in,
                                             const uint8_t** next_in,
                                             int finish,
                                             size_t* available_out,
                                             uint8_t** next_out,
                                             size_t* total_out,
                                             BrotliState* s) {
  BrotliResult result;
  BrotliMemInput memin;
  BrotliInput in = BrotliInitMemInput(*next_in, *available_in, &memin);
  BrotliMemOutput memout;
  BrotliOutput out = BrotliInitMemOutput(*next_out, *available_out, &memout);

  result = BrotliDecompressStreaming(in, out, finish, s);

  /* The current implementation reads everything, so 0 bytes are available. */
  *next_in += memin.pos;
  *available_in -= memin.pos;

  /* Update the output position to where we write next. */
  *next_out += memout.pos;
  *available_out -= memout.pos;
  *total_out += memout.pos;

  return result;
}

BrotliResult BrotliDecompressStreaming(BrotliInput input, BrotliOutput output,
                                       int finish, BrotliState* s) {
  uint8_t context;
  int pos = s->pos;
  int i = s->loop_counter;
  BrotliResult result = BROTLI_RESULT_SUCCESS;
  BrotliBitReader* br = &s->br;
  int initial_remaining_len;
  int bytes_copied;
  int num_written;

  /* We need the slack region for the following reasons:
       - always doing two 8-byte copies for fast backward copying
       - transforms
       - flushing the input s->ringbuffer when decoding uncompressed blocks */
  static const int kRingBufferWriteAheadSlack = 128 + BROTLI_READ_SIZE;

  s->br.finish_ = finish;

  /* State machine */
  for (;;) {
    if (result != BROTLI_RESULT_SUCCESS) {
      if (result == BROTLI_RESULT_NEEDS_MORE_INPUT && finish) {
        printf("Unexpected end of input. State: %d\n", s->state);
        result = BROTLI_RESULT_ERROR;
      }
      break;  /* Fail, or partial data. */
    }

    switch (s->state) {
      case BROTLI_STATE_UNINITED:
        pos = 0;
        s->input_end = 0;
        s->window_bits = 0;
        s->max_distance = 0;
        s->dist_rb[0] = 16;
        s->dist_rb[1] = 15;
        s->dist_rb[2] = 11;
        s->dist_rb[3] = 4;
        s->dist_rb_idx = 0;
        s->prev_byte1 = 0;
        s->prev_byte2 = 0;
        s->block_type_trees = NULL;
        s->block_len_trees = NULL;

        BrotliInitBitReader(br, input, finish);

        s->state = BROTLI_STATE_BITREADER_WARMUP;
        /* No break, continue to next state */
      case BROTLI_STATE_BITREADER_WARMUP:
        if (!BrotliWarmupBitReader(br)) {
          result = BROTLI_RESULT_NEEDS_MORE_INPUT;
          break;
        }
        /* Decode window size. */
        s->window_bits = DecodeWindowBits(br);
        s->max_backward_distance = (1 << s->window_bits) - 16;

        s->ringbuffer_size = 1 << s->window_bits;
        s->ringbuffer_mask = s->ringbuffer_size - 1;
        s->ringbuffer = (uint8_t*)malloc((size_t)(s->ringbuffer_size +
                                               kRingBufferWriteAheadSlack +
                                               kMaxDictionaryWordLength));
        if (!s->ringbuffer) {
          result = BROTLI_RESULT_ERROR;
          break;
        }
        s->ringbuffer_end = s->ringbuffer + s->ringbuffer_size;

        s->block_type_trees = (HuffmanCode*)malloc(
            3 * BROTLI_HUFFMAN_MAX_TABLE_SIZE * sizeof(HuffmanCode));
        s->block_len_trees = (HuffmanCode*)malloc(
            3 * BROTLI_HUFFMAN_MAX_TABLE_SIZE * sizeof(HuffmanCode));
        if (s->block_type_trees == NULL || s->block_len_trees == NULL) {
          result = BROTLI_RESULT_ERROR;
          break;
        }

        s->state = BROTLI_STATE_METABLOCK_BEGIN;
        /* No break, continue to next state */
      case BROTLI_STATE_METABLOCK_BEGIN:
        if (!BrotliReadMoreInput(br)) {
          result = BROTLI_RESULT_NEEDS_MORE_INPUT;
          break;
        }
        if (s->input_end) {
          s->partially_written = 0;
          s->state = BROTLI_STATE_DONE;
          break;
        }
        s->meta_block_remaining_len = 0;
        s->block_length[0] = 1 << 28;
        s->block_length[1] = 1 << 28;
        s->block_length[2] = 1 << 28;
        s->block_type[0] = 0;
        s->num_block_types[0] = 1;
        s->num_block_types[1] = 1;
        s->num_block_types[2] = 1;
        s->block_type_rb[0] = 0;
        s->block_type_rb[1] = 1;
        s->block_type_rb[2] = 0;
        s->block_type_rb[3] = 1;
        s->block_type_rb[4] = 0;
        s->block_type_rb[5] = 1;
        s->block_type_rb_index[0] = 0;
        s->context_map = NULL;
        s->context_modes = NULL;
        s->dist_context_map = NULL;
        s->context_offset = 0;
        s->context_map_slice = NULL;
        s->literal_htree_index = 0;
        s->dist_context_offset = 0;
        s->dist_context_map_slice = NULL;
        s->dist_htree_index = 0;
        s->context_lookup_offset1 = 0;
        s->context_lookup_offset2 = 0;
        for (i = 0; i < 3; ++i) {
          s->hgroup[i].codes = NULL;
          s->hgroup[i].htrees = NULL;
        }
        s->state = BROTLI_STATE_METABLOCK_HEADER_1;
        /* No break, continue to next state */
      case BROTLI_STATE_METABLOCK_HEADER_1:
        if (!BrotliReadMoreInput(br)) {
          result = BROTLI_RESULT_NEEDS_MORE_INPUT;
          break;
        }
        BROTLI_LOG_UINT(pos);
        if (!DecodeMetaBlockLength(br,
                                   &s->meta_block_remaining_len,
                                   &s->input_end,
                                   &s->is_metadata,
                                   &s->is_uncompressed)) {
          result = BROTLI_RESULT_ERROR;
          break;
        }
        BROTLI_LOG_UINT(s->meta_block_remaining_len);
        if (s->is_metadata) {
          if (!JumpToByteBoundary(&s->br)) {
            result = BROTLI_RESULT_ERROR;
            break;
          }
          s->state = BROTLI_STATE_METADATA;
          break;
        }
        if (s->meta_block_remaining_len == 0) {
          s->state = BROTLI_STATE_METABLOCK_DONE;
          break;
        }
        if (s->is_uncompressed) {
          if (!JumpToByteBoundary(&s->br)) {
            result = BROTLI_RESULT_ERROR;
            break;
          }
          s->state = BROTLI_STATE_UNCOMPRESSED;
          break;
        }
        i = 0;
        s->state = BROTLI_STATE_HUFFMAN_CODE_0;
        break;
      case BROTLI_STATE_UNCOMPRESSED:
        initial_remaining_len = s->meta_block_remaining_len;
        /* pos is given as argument since s->pos is only updated at the end. */
        result = CopyUncompressedBlockToOutput(output, pos, s);
        if (result == BROTLI_RESULT_NEEDS_MORE_OUTPUT) {
          break;
        }
        bytes_copied = initial_remaining_len - s->meta_block_remaining_len;
        pos += bytes_copied;
        if (bytes_copied > 0) {
          s->prev_byte2 = bytes_copied == 1 ? s->prev_byte1 :
              s->ringbuffer[(pos - 2) & s->ringbuffer_mask];
          s->prev_byte1 = s->ringbuffer[(pos - 1) & s->ringbuffer_mask];
        }
        if (result != BROTLI_RESULT_SUCCESS) break;
        s->state = BROTLI_STATE_METABLOCK_DONE;
        break;
      case BROTLI_STATE_METADATA:
        for (; s->meta_block_remaining_len > 0; --s->meta_block_remaining_len) {
          if (!BrotliReadMoreInput(&s->br)) {
            result = BROTLI_RESULT_NEEDS_MORE_INPUT;
            break;
          }
          /* Read one byte and ignore it. */
          BrotliReadBits(&s->br, 8);
        }
        s->state = BROTLI_STATE_METABLOCK_DONE;
        break;
      case BROTLI_STATE_HUFFMAN_CODE_0:
        if (i >= 3) {
          BROTLI_LOG_UINT(s->num_block_types[0]);
          BROTLI_LOG_UINT(s->num_block_types[1]);
          BROTLI_LOG_UINT(s->num_block_types[2]);
          BROTLI_LOG_UINT(s->block_length[0]);
          BROTLI_LOG_UINT(s->block_length[1]);
          BROTLI_LOG_UINT(s->block_length[2]);

          s->state = BROTLI_STATE_METABLOCK_HEADER_2;
          break;
        }
        s->num_block_types[i] = DecodeVarLenUint8(br) + 1;
        s->state = BROTLI_STATE_HUFFMAN_CODE_1;
        /* No break, continue to next state */
      case BROTLI_STATE_HUFFMAN_CODE_1:
        if (s->num_block_types[i] >= 2) {
          result = ReadHuffmanCode(s->num_block_types[i] + 2,
              &s->block_type_trees[i * BROTLI_HUFFMAN_MAX_TABLE_SIZE],
              NULL, s);
          if (result != BROTLI_RESULT_SUCCESS) break;
          s->state = BROTLI_STATE_HUFFMAN_CODE_2;
        } else {
          i++;
          s->state = BROTLI_STATE_HUFFMAN_CODE_0;
          break;
        }
        /* No break, continue to next state */
      case BROTLI_STATE_HUFFMAN_CODE_2:
        result = ReadHuffmanCode(kNumBlockLengthCodes,
            &s->block_len_trees[i * BROTLI_HUFFMAN_MAX_TABLE_SIZE],
            NULL, s);
        if (result != BROTLI_RESULT_SUCCESS) break;
        s->block_length[i] = ReadBlockLength(
            &s->block_len_trees[i * BROTLI_HUFFMAN_MAX_TABLE_SIZE], br);
        s->block_type_rb_index[i] = 1;
        i++;
        s->state = BROTLI_STATE_HUFFMAN_CODE_0;
        break;
      case BROTLI_STATE_METABLOCK_HEADER_2:
        if (!BrotliReadMoreInput(br)) {
          result = BROTLI_RESULT_NEEDS_MORE_INPUT;
          break;
        }
        s->distance_postfix_bits = (int)BrotliReadBits(br, 2);
        s->num_direct_distance_codes = NUM_DISTANCE_SHORT_CODES +
            ((int)BrotliReadBits(br, 4) << s->distance_postfix_bits);
        s->distance_postfix_mask = (1 << s->distance_postfix_bits) - 1;
        s->num_distance_codes = (s->num_direct_distance_codes +
                              (48 << s->distance_postfix_bits));
        s->context_modes = (uint8_t*)malloc((size_t)s->num_block_types[0]);
        if (s->context_modes == 0) {
          result = BROTLI_RESULT_ERROR;
          break;
        }
        for (i = 0; i < s->num_block_types[0]; ++i) {
          s->context_modes[i] = (uint8_t)(BrotliReadBits(br, 2) << 1);
          BROTLI_LOG_ARRAY_INDEX(s->context_modes, i);
        }
        BROTLI_LOG_UINT(s->num_direct_distance_codes);
        BROTLI_LOG_UINT(s->distance_postfix_bits);
        s->state = BROTLI_STATE_CONTEXT_MAP_1;
        /* No break, continue to next state */
      case BROTLI_STATE_CONTEXT_MAP_1:
        result = DecodeContextMap(s->num_block_types[0] << kLiteralContextBits,
                                  &s->num_literal_htrees, &s->context_map, s);

        s->trivial_literal_context = 1;
        for (i = 0; i < s->num_block_types[0] << kLiteralContextBits; i++) {
          if (s->context_map[i] != i >> kLiteralContextBits) {
            s->trivial_literal_context = 0;
            break;
          }
        }

        if (result != BROTLI_RESULT_SUCCESS) break;
        s->state = BROTLI_STATE_CONTEXT_MAP_2;
        /* No break, continue to next state */
      case BROTLI_STATE_CONTEXT_MAP_2:
        result = DecodeContextMap(s->num_block_types[2] << kDistanceContextBits,
                                  &s->num_dist_htrees, &s->dist_context_map, s);
        if (result != BROTLI_RESULT_SUCCESS) break;

        BrotliHuffmanTreeGroupInit(&s->hgroup[0], kNumLiteralCodes,
                                   s->num_literal_htrees);
        BrotliHuffmanTreeGroupInit(&s->hgroup[1], kNumInsertAndCopyCodes,
                                   s->num_block_types[1]);
        BrotliHuffmanTreeGroupInit(&s->hgroup[2], s->num_distance_codes,
                                   s->num_dist_htrees);
        i = 0;
        s->state = BROTLI_STATE_TREE_GROUP;
        /* No break, continue to next state */
      case BROTLI_STATE_TREE_GROUP:
        result = HuffmanTreeGroupDecode(&s->hgroup[i], s);
        if (result != BROTLI_RESULT_SUCCESS) break;
        i++;

        if (i >= 3) {
          s->context_map_slice = s->context_map;
          s->dist_context_map_slice = s->dist_context_map;
          s->context_mode = s->context_modes[s->block_type[0]];
          s->context_lookup_offset1 = kContextLookupOffsets[s->context_mode];
          s->context_lookup_offset2 =
              kContextLookupOffsets[s->context_mode + 1];
          s->htree_command = s->hgroup[1].htrees[0];

          s->state = BROTLI_STATE_BLOCK_BEGIN;
          break;
        }

        break;
      case BROTLI_STATE_BLOCK_BEGIN:
 /* Block decoding is the inner loop, jumping with goto makes it 3% faster */
 BlockBegin:
        if (!BrotliReadMoreInput(br)) {
          result = BROTLI_RESULT_NEEDS_MORE_INPUT;
          break;
        }
        if (s->meta_block_remaining_len <= 0) {
          /* Protect pos from overflow, wrap it around at every GB of input. */
          pos &= 0x3fffffff;

          /* Next metablock, if any */
          s->state = BROTLI_STATE_METABLOCK_DONE;
          break;
        }

        if (s->block_length[1] == 0) {
          DecodeBlockType(s->num_block_types[1],
                          s->block_type_trees, 1,
                          s->block_type, s->block_type_rb,
                          s->block_type_rb_index, br);
          s->block_length[1] = ReadBlockLength(
              &s->block_len_trees[BROTLI_HUFFMAN_MAX_TABLE_SIZE], br);
          s->htree_command = s->hgroup[1].htrees[s->block_type[1]];
        }
        --s->block_length[1];
        s->cmd_code = ReadSymbol(s->htree_command, br);
        s->range_idx = s->cmd_code >> 6;
        if (s->range_idx >= 2) {
          s->range_idx -= 2;
          s->distance_code = -1;
        } else {
          s->distance_code = 0;
        }
        s->insert_code =
            kInsertRangeLut[s->range_idx] + ((s->cmd_code >> 3) & 7);
        s->copy_code = kCopyRangeLut[s->range_idx] + (s->cmd_code & 7);
        s->insert_length = kInsertLengthPrefixCode[s->insert_code].offset +
            (int)BrotliReadBits(br,
                                kInsertLengthPrefixCode[s->insert_code].nbits);
        s->copy_length = kCopyLengthPrefixCode[s->copy_code].offset +
            (int)BrotliReadBits(br, kCopyLengthPrefixCode[s->copy_code].nbits);
        BROTLI_LOG_UINT(s->insert_length);
        BROTLI_LOG_UINT(s->copy_length);
        BROTLI_LOG_UINT(s->distance_code);

        i = 0;
        s->state = BROTLI_STATE_BLOCK_INNER;
        /* No break, go to next state */
      case BROTLI_STATE_BLOCK_INNER:
        if (s->trivial_literal_context) {
          while (i < s->insert_length) {
            if (!BrotliReadMoreInput(br)) {
              result = BROTLI_RESULT_NEEDS_MORE_INPUT;
              break;
            }
            if (s->block_length[0] == 0) {
              DecodeBlockTypeWithContext(s, br);
            }

            s->ringbuffer[pos & s->ringbuffer_mask] = (uint8_t)ReadSymbol(
                s->hgroup[0].htrees[s->literal_htree_index], br);

            --s->block_length[0];
            BROTLI_LOG_UINT(s->literal_htree_index);
            BROTLI_LOG_ARRAY_INDEX(s->ringbuffer, pos & s->ringbuffer_mask);
            if ((pos & s->ringbuffer_mask) == s->ringbuffer_mask) {
              s->partially_written = 0;
              s->state = BROTLI_STATE_BLOCK_INNER_WRITE;
              break;
            }
            /* Modifications to this code shold be reflected in
            BROTLI_STATE_BLOCK_INNER_WRITE case */
            ++pos;
            ++i;
          }
        } else {
          while (i < s->insert_length) {
            if (!BrotliReadMoreInput(br)) {
              result = BROTLI_RESULT_NEEDS_MORE_INPUT;
              break;
            }
            if (s->block_length[0] == 0) {
              DecodeBlockTypeWithContext(s, br);
            }

            context =
                (kContextLookup[s->context_lookup_offset1 + s->prev_byte1] |
                 kContextLookup[s->context_lookup_offset2 + s->prev_byte2]);
            BROTLI_LOG_UINT(context);
            s->literal_htree_index = s->context_map_slice[context];
            --s->block_length[0];
            s->prev_byte2 = s->prev_byte1;
            s->prev_byte1 = (uint8_t)ReadSymbol(
                s->hgroup[0].htrees[s->literal_htree_index], br);
            s->ringbuffer[pos & s->ringbuffer_mask] = s->prev_byte1;
            BROTLI_LOG_UINT(s->literal_htree_index);
            BROTLI_LOG_ARRAY_INDEX(s->ringbuffer, pos & s->ringbuffer_mask);
            if ((pos & s->ringbuffer_mask) == s->ringbuffer_mask) {
              s->partially_written = 0;
              s->state = BROTLI_STATE_BLOCK_INNER_WRITE;
              break;
            }
            /* Modifications to this code shold be reflected in
            BROTLI_STATE_BLOCK_INNER_WRITE case */
            ++pos;
            ++i;
          }
        }
        if (result != BROTLI_RESULT_SUCCESS ||
            s->state == BROTLI_STATE_BLOCK_INNER_WRITE) break;

        s->meta_block_remaining_len -= s->insert_length;
        if (s->meta_block_remaining_len <= 0) {
          s->state = BROTLI_STATE_METABLOCK_DONE;
          break;
        } else if (s->distance_code < 0) {
          s->state = BROTLI_STATE_BLOCK_DISTANCE;
        } else {
          s->state = BROTLI_STATE_BLOCK_POST;
          break;
        }
        /* No break, go to next state */
      case BROTLI_STATE_BLOCK_DISTANCE:
        if (!BrotliReadMoreInput(br)) {
          result = BROTLI_RESULT_NEEDS_MORE_INPUT;
          break;
        }
        assert(s->distance_code < 0);

        if (s->block_length[2] == 0) {
          DecodeBlockType(s->num_block_types[2],
                          s->block_type_trees, 2,
                          s->block_type, s->block_type_rb,
                          s->block_type_rb_index, br);
          s->block_length[2] = ReadBlockLength(
              &s->block_len_trees[2 * BROTLI_HUFFMAN_MAX_TABLE_SIZE], br);
          s->dist_context_offset = s->block_type[2] << kDistanceContextBits;
          s->dist_context_map_slice =
              s->dist_context_map + s->dist_context_offset;
        }
        --s->block_length[2];
        context = (uint8_t)(s->copy_length > 4 ? 3 : s->copy_length - 2);
        s->dist_htree_index = s->dist_context_map_slice[context];
        s->distance_code =
            ReadSymbol(s->hgroup[2].htrees[s->dist_htree_index], br);
        if (s->distance_code >= s->num_direct_distance_codes) {
          int nbits;
          int postfix;
          int offset;
          s->distance_code -= s->num_direct_distance_codes;
          postfix = s->distance_code & s->distance_postfix_mask;
          s->distance_code >>= s->distance_postfix_bits;
          nbits = (s->distance_code >> 1) + 1;
          offset = ((2 + (s->distance_code & 1)) << nbits) - 4;
          s->distance_code = s->num_direct_distance_codes +
              ((offset + (int)BrotliReadBits(br, nbits)) <<
               s->distance_postfix_bits) + postfix;
        }
        s->state = BROTLI_STATE_BLOCK_POST;
        /* No break, go to next state */
      case BROTLI_STATE_BLOCK_POST:
        if (!BrotliReadMoreInput(br)) {
          result = BROTLI_RESULT_NEEDS_MORE_INPUT;
          break;
        }
        /* Convert the distance code to the actual distance by possibly */
        /* looking up past distnaces from the s->ringbuffer. */
        s->distance =
            TranslateShortCodes(s->distance_code, s->dist_rb, s->dist_rb_idx);
        if (s->distance < 0) {
          result = BROTLI_RESULT_ERROR;
          break;
        }
        BROTLI_LOG_UINT(s->distance);

        if (pos < s->max_backward_distance &&
            s->max_distance != s->max_backward_distance) {
          s->max_distance = pos;
        } else {
          s->max_distance = s->max_backward_distance;
        }

        s->copy_dst = &s->ringbuffer[pos & s->ringbuffer_mask];

        if (s->distance > s->max_distance) {
          if (s->copy_length >= kMinDictionaryWordLength &&
              s->copy_length <= kMaxDictionaryWordLength) {
            int offset = kBrotliDictionaryOffsetsByLength[s->copy_length];
            int word_id = s->distance - s->max_distance - 1;
            int shift = kBrotliDictionarySizeBitsByLength[s->copy_length];
            int mask = (1 << shift) - 1;
            int word_idx = word_id & mask;
            int transform_idx = word_id >> shift;
            offset += word_idx * s->copy_length;
            if (transform_idx < kNumTransforms) {
              const uint8_t* word = &kBrotliDictionary[offset];
              int len = TransformDictionaryWord(
                  s->copy_dst, word, s->copy_length, transform_idx);
              s->copy_dst += len;
              pos += len;
              s->meta_block_remaining_len -= len;
              if (s->copy_dst >= s->ringbuffer_end) {
                s->partially_written = 0;
                num_written = BrotliWrite(output, s->ringbuffer,
                                          (size_t)s->ringbuffer_size);
                if (num_written < 0) {
                  result = BROTLI_RESULT_ERROR;
                  break;
                }
                s->partially_written += num_written;
                if (s->partially_written < s->ringbuffer_size) {
                  result = BROTLI_RESULT_NEEDS_MORE_OUTPUT;
                  s->state = BROTLI_STATE_BLOCK_POST_WRITE_1;
                  break;
                }
                /* Modifications to this code shold be reflected in
                BROTLI_STATE_BLOCK_POST_WRITE_1 case */
                memcpy(s->ringbuffer, s->ringbuffer_end,
                       (size_t)(s->copy_dst - s->ringbuffer_end));
              }
            } else {
              printf("Invalid backward reference. pos: %d distance: %d "
                     "len: %d bytes left: %d\n",
                     pos, s->distance, s->copy_length,
                     s->meta_block_remaining_len);
              result = BROTLI_RESULT_ERROR;
              break;
            }
          } else {
            printf("Invalid backward reference. pos: %d distance: %d "
                   "len: %d bytes left: %d\n", pos, s->distance, s->copy_length,
                   s->meta_block_remaining_len);
            result = BROTLI_RESULT_ERROR;
            break;
          }
        } else {
          if (s->distance_code > 0) {
            s->dist_rb[s->dist_rb_idx & 3] = s->distance;
            ++s->dist_rb_idx;
          }

          if (s->copy_length > s->meta_block_remaining_len) {
            printf("Invalid backward reference. pos: %d distance: %d "
                   "len: %d bytes left: %d\n", pos, s->distance, s->copy_length,
                   s->meta_block_remaining_len);
            result = BROTLI_RESULT_ERROR;
            break;
          }

          s->copy_src =
              &s->ringbuffer[(pos - s->distance) & s->ringbuffer_mask];

#if (defined(__x86_64__) || defined(_M_X64))
          if (s->copy_src + s->copy_length <= s->ringbuffer_end &&
              s->copy_dst + s->copy_length < s->ringbuffer_end) {
            if (s->copy_length <= 16 && s->distance >= 8) {
              UNALIGNED_COPY64(s->copy_dst, s->copy_src);
              UNALIGNED_COPY64(s->copy_dst + 8, s->copy_src + 8);
            } else {
              IncrementalCopyFastPath(s->copy_dst, s->copy_src, s->copy_length);
            }
            pos += s->copy_length;
            s->meta_block_remaining_len -= s->copy_length;
            s->copy_length = 0;
          }
#endif
          /* Modifications to this loop shold be reflected in
          BROTLI_STATE_BLOCK_POST_WRITE_2 case */
          for (i = 0; i < s->copy_length; ++i) {
            s->ringbuffer[pos & s->ringbuffer_mask] =
                s->ringbuffer[(pos - s->distance) & s->ringbuffer_mask];
            if ((pos & s->ringbuffer_mask) == s->ringbuffer_mask) {
              s->partially_written = 0;
              num_written = BrotliWrite(output, s->ringbuffer,
                              (size_t)s->ringbuffer_size);
              if (num_written < 0) {
                result = BROTLI_RESULT_ERROR;
                break;
              }
              s->partially_written += num_written;
              if (s->partially_written < s->ringbuffer_size) {
                result = BROTLI_RESULT_NEEDS_MORE_OUTPUT;
                s->state = BROTLI_STATE_BLOCK_POST_WRITE_2;
                break;
              }
            }
            ++pos;
            --s->meta_block_remaining_len;
          }
          if (result == BROTLI_RESULT_NEEDS_MORE_OUTPUT) {
            break;
          }
        }
        /* No break, continue to next state */
      case BROTLI_STATE_BLOCK_POST_CONTINUE:
        /* When we get here, we must have inserted at least one literal and */
        /* made a copy of at least length two, therefore accessing the last 2 */
        /* bytes is valid. */
        s->prev_byte1 = s->ringbuffer[(pos - 1) & s->ringbuffer_mask];
        s->prev_byte2 = s->ringbuffer[(pos - 2) & s->ringbuffer_mask];
        s->state = BROTLI_STATE_BLOCK_BEGIN;
        goto BlockBegin;
      case BROTLI_STATE_BLOCK_INNER_WRITE:
      case BROTLI_STATE_BLOCK_POST_WRITE_1:
      case BROTLI_STATE_BLOCK_POST_WRITE_2:
        num_written = BrotliWrite(
            output, s->ringbuffer + s->partially_written,
            (size_t)(s->ringbuffer_size - s->partially_written));
        if (num_written < 0) {
          result = BROTLI_RESULT_ERROR;
          break;
        }
        s->partially_written += num_written;
        if (s->partially_written < s->ringbuffer_size) {
          result = BROTLI_RESULT_NEEDS_MORE_OUTPUT;
          break;
        }
        if (s->state == BROTLI_STATE_BLOCK_POST_WRITE_1) {
          memcpy(s->ringbuffer, s->ringbuffer_end,
                 (size_t)(s->copy_dst - s->ringbuffer_end));
          s->state = BROTLI_STATE_BLOCK_POST_CONTINUE;
        } else if (s->state == BROTLI_STATE_BLOCK_POST_WRITE_2) {
          /* The tail of "i < s->copy_length" loop. */
          ++pos;
          --s->meta_block_remaining_len;
          ++i;
          /* Reenter the loop. */
          for (; i < s->copy_length; ++i) {
            s->ringbuffer[pos & s->ringbuffer_mask] =
                s->ringbuffer[(pos - s->distance) & s->ringbuffer_mask];
            if ((pos & s->ringbuffer_mask) == s->ringbuffer_mask) {
              s->partially_written = 0;
              num_written = BrotliWrite(output, s->ringbuffer,
                                        (size_t)s->ringbuffer_size);
              if (num_written < 0) {
                result = BROTLI_RESULT_ERROR;
                break;
              }
              s->partially_written += num_written;
              if (s->partially_written < s->ringbuffer_size) {
                result = BROTLI_RESULT_NEEDS_MORE_OUTPUT;
                break;
              }
            }
            ++pos;
            --s->meta_block_remaining_len;
          }
          if (result == BROTLI_RESULT_NEEDS_MORE_OUTPUT) {
            break;
          }
          s->state = BROTLI_STATE_BLOCK_POST_CONTINUE;
        } else {  /* BROTLI_STATE_BLOCK_INNER_WRITE */
          /* The tail of "i < s->insert_length" loop. */
          ++pos;
          ++i;
          s->state = BROTLI_STATE_BLOCK_INNER;
        }
        break;
      case BROTLI_STATE_METABLOCK_DONE:
        if (s->context_modes != 0) {
          free(s->context_modes);
          s->context_modes = NULL;
        }
        if (s->context_map != 0) {
          free(s->context_map);
          s->context_map = NULL;
        }
        if (s->dist_context_map != 0) {
          free(s->dist_context_map);
          s->dist_context_map = NULL;
        }
        for (i = 0; i < 3; ++i) {
          BrotliHuffmanTreeGroupRelease(&s->hgroup[i]);
          s->hgroup[i].codes = NULL;
          s->hgroup[i].htrees = NULL;
        }
        s->state = BROTLI_STATE_METABLOCK_BEGIN;
        break;
      case BROTLI_STATE_DONE:
        if (s->ringbuffer != 0) {
          num_written = BrotliWrite(
              output, s->ringbuffer + s->partially_written,
              (size_t)((pos & s->ringbuffer_mask) - s->partially_written));
          if (num_written < 0) {
            result = BROTLI_RESULT_ERROR;
          }
          s->partially_written += num_written;
          if (s->partially_written < (pos & s->ringbuffer_mask)) {
            result = BROTLI_RESULT_NEEDS_MORE_OUTPUT;
            break;
          }
        }
        if (!JumpToByteBoundary(&s->br)) {
          result = BROTLI_RESULT_ERROR;
        }
        return result;
      default:
        printf("Unknown state %d\n", s->state);
        result = BROTLI_RESULT_ERROR;
    }
  }

  s->pos = pos;
  s->loop_counter = i;
  return result;
}

#if defined(__cplusplus) || defined(c_plusplus)
}    /* extern "C" */
#endif
