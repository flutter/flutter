/* Copyright 2015 Google Inc. All Rights Reserved.

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

/* Brotli state for partial streaming decoding. */

#ifndef BROTLI_DEC_STATE_H_
#define BROTLI_DEC_STATE_H_

#include <stdio.h>
#include "./bit_reader.h"
#include "./huffman.h"
#include "./streams.h"
#include "./types.h"

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

typedef enum {
  BROTLI_STATE_UNINITED = 0,
  BROTLI_STATE_BITREADER_WARMUP = 1,
  BROTLI_STATE_METABLOCK_BEGIN = 10,
  BROTLI_STATE_METABLOCK_HEADER_1 = 11,
  BROTLI_STATE_METABLOCK_HEADER_2 = 12,
  BROTLI_STATE_BLOCK_BEGIN = 13,
  BROTLI_STATE_BLOCK_INNER = 14,
  BROTLI_STATE_BLOCK_DISTANCE = 15,
  BROTLI_STATE_BLOCK_POST = 16,
  BROTLI_STATE_UNCOMPRESSED = 17,
  BROTLI_STATE_METADATA = 18,
  BROTLI_STATE_BLOCK_INNER_WRITE = 19,
  BROTLI_STATE_METABLOCK_DONE = 20,
  BROTLI_STATE_BLOCK_POST_WRITE_1 = 21,
  BROTLI_STATE_BLOCK_POST_WRITE_2 = 22,
  BROTLI_STATE_BLOCK_POST_CONTINUE = 23,
  BROTLI_STATE_HUFFMAN_CODE_0 = 30,
  BROTLI_STATE_HUFFMAN_CODE_1 = 31,
  BROTLI_STATE_HUFFMAN_CODE_2 = 32,
  BROTLI_STATE_CONTEXT_MAP_1 = 33,
  BROTLI_STATE_CONTEXT_MAP_2 = 34,
  BROTLI_STATE_TREE_GROUP = 35,
  BROTLI_STATE_SUB_NONE = 50,
  BROTLI_STATE_SUB_UNCOMPRESSED_SHORT = 51,
  BROTLI_STATE_SUB_UNCOMPRESSED_FILL = 52,
  BROTLI_STATE_SUB_UNCOMPRESSED_COPY = 53,
  BROTLI_STATE_SUB_UNCOMPRESSED_WARMUP = 54,
  BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_1 = 55,
  BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_2 = 56,
  BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_3 = 57,
  BROTLI_STATE_SUB_HUFFMAN_LENGTH_BEGIN = 60,
  BROTLI_STATE_SUB_HUFFMAN_LENGTH_SYMBOLS = 61,
  BROTLI_STATE_SUB_HUFFMAN_DONE = 62,
  BROTLI_STATE_SUB_TREE_GROUP = 70,
  BROTLI_STATE_SUB_CONTEXT_MAP_HUFFMAN = 80,
  BROTLI_STATE_SUB_CONTEXT_MAPS = 81,
  BROTLI_STATE_DONE = 100
} BrotliRunningState;

typedef struct {
  BrotliRunningState state;
  BrotliRunningState sub_state[2];  /* State inside function call */

  int pos;
  int input_end;
  int window_bits;
  int max_backward_distance;
  int max_distance;
  int ringbuffer_size;
  int ringbuffer_mask;
  uint8_t* ringbuffer;
  uint8_t* ringbuffer_end;
  /* This ring buffer holds a few past copy distances that will be used by */
  /* some special distance codes. */
  int dist_rb[4];
  int dist_rb_idx;
  /* The previous 2 bytes used for context. */
  uint8_t prev_byte1;
  uint8_t prev_byte2;
  HuffmanTreeGroup hgroup[3];
  HuffmanCode* block_type_trees;
  HuffmanCode* block_len_trees;
  BrotliBitReader br;
  /* This counter is reused for several disjoint loops. */
  int loop_counter;
  /* This is true if the literal context map histogram type always matches the
  block type. It is then not needed to keep the context (faster decoding). */
  int trivial_literal_context;

  int meta_block_remaining_len;
  int is_metadata;
  int is_uncompressed;
  int block_length[3];
  int block_type[3];
  int num_block_types[3];
  int block_type_rb[6];
  int block_type_rb_index[3];
  int distance_postfix_bits;
  int num_direct_distance_codes;
  int distance_postfix_mask;
  int num_distance_codes;
  uint8_t* context_map;
  uint8_t* context_modes;
  int num_literal_htrees;
  uint8_t* dist_context_map;
  int num_dist_htrees;
  int context_offset;
  uint8_t* context_map_slice;
  uint8_t literal_htree_index;
  int dist_context_offset;
  uint8_t* dist_context_map_slice;
  uint8_t dist_htree_index;
  int context_lookup_offset1;
  int context_lookup_offset2;
  uint8_t context_mode;
  HuffmanCode* htree_command;

  int cmd_code;
  int range_idx;
  int insert_code;
  int copy_code;
  int insert_length;
  int copy_length;
  int distance_code;
  int distance;
  const uint8_t* copy_src;
  uint8_t* copy_dst;

  /* For CopyUncompressedBlockToOutput */
  int nbytes;

  /* For partial write operations */
  int partially_written;

  /* For HuffmanTreeGroupDecode */
  int htrees_decoded;

  /* For ReadHuffmanCodeLengths */
  int symbol;
  uint8_t prev_code_len;
  int repeat;
  uint8_t repeat_code_len;
  int space;
  HuffmanCode table[32];
  uint8_t code_length_code_lengths[18];

  /* For ReadHuffmanCode */
  int simple_code_or_skip;
  uint8_t* code_lengths;

  /* For HuffmanTreeGroupDecode */
  int htree_index;
  HuffmanCode* next;

  /* For DecodeContextMap */
  int context_index;
  int max_run_length_prefix;
  HuffmanCode* context_map_table;
} BrotliState;

void BrotliStateInit(BrotliState* s);
void BrotliStateCleanup(BrotliState* s);

#if defined(__cplusplus) || defined(c_plusplus)
} /* extern "C" */
#endif

#endif  /* BROTLI_DEC_STATE_H_ */
