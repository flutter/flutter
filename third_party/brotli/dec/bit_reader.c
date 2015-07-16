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

   Bit reading helpers
*/

#include <assert.h>
#include <stdlib.h>

#include "./bit_reader.h"

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

int BrotliInitBitReader(BrotliBitReader* const br, BrotliInput input) {
  size_t i;
  assert(br != NULL);

  br->buf_ptr_ = br->buf_;
  br->input_ = input;
  br->val_ = 0;
  br->pos_ = 0;
  br->bit_pos_ = 0;
  br->bit_end_pos_ = 0;
  br->eos_ = 0;
  if (!BrotliReadMoreInput(br)) {
    return 0;
  }
  for (i = 0; i < sizeof(br->val_); ++i) {
    br->val_ |= ((uint64_t)br->buf_[br->pos_]) << (8 * i);
    ++br->pos_;
  }
  return (br->bit_end_pos_ > 0);
}

#if defined(__cplusplus) || defined(c_plusplus)
}    /* extern "C" */
#endif
