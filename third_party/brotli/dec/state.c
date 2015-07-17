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

#include "./state.h"

#include <stdlib.h>
#include <string.h>

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

void BrotliStateInit(BrotliState* s) {
  int i;

  s->state = BROTLI_STATE_UNINITED;
  s->sub_state[0] = BROTLI_STATE_SUB_NONE;
  s->sub_state[1] = BROTLI_STATE_SUB_NONE;

  s->block_type_trees = NULL;
  s->block_len_trees = NULL;
  s->ringbuffer = NULL;

  s->context_map = NULL;
  s->context_modes = NULL;
  s->dist_context_map = NULL;
  s->context_map_slice = NULL;
  s->dist_context_map_slice = NULL;

  for (i = 0; i < 3; ++i) {
    s->hgroup[i].codes = NULL;
    s->hgroup[i].htrees = NULL;
  }

  s->code_lengths = NULL;
  s->context_map_table = NULL;
}

void BrotliStateCleanup(BrotliState* s) {
  int i;

  if (s->context_map_table != 0) {
    free(s->context_map_table);
  }
  if (s->code_lengths != 0) {
    free(s->code_lengths);
  }

  if (s->context_modes != 0) {
    free(s->context_modes);
  }
  if (s->context_map != 0) {
    free(s->context_map);
  }
  if (s->dist_context_map != 0) {
    free(s->dist_context_map);
  }
  for (i = 0; i < 3; ++i) {
    BrotliHuffmanTreeGroupRelease(&s->hgroup[i]);
  }

  if (s->ringbuffer != 0) {
    free(s->ringbuffer);
  }
  if (s->block_type_trees != 0) {
    free(s->block_type_trees);
  }
  if (s->block_len_trees != 0) {
    free(s->block_len_trees);
  }
}

#if defined(__cplusplus) || defined(c_plusplus)
} /* extern "C" */
#endif
