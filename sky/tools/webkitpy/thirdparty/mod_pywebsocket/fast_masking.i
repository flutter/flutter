// Copyright 2013, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


%module fast_masking

%include "cstring.i"

%{
#include <cstring>

#ifdef __SSE2__
#include <emmintrin.h>
#endif
%}

%apply (char *STRING, int LENGTH) {
    (const char* payload, int payload_length),
    (const char* masking_key, int masking_key_length) };
%cstring_output_allocate_size(
    char** result, int* result_length, delete [] *$1);

%inline %{

void mask(
    const char* payload, int payload_length,
    const char* masking_key, int masking_key_length,
    int masking_key_index,
    char** result, int* result_length) {
  *result = new char[payload_length];
  *result_length = payload_length;
  memcpy(*result, payload, payload_length);

  char* cursor = *result;
  char* cursor_end = *result + *result_length;

#ifdef __SSE2__
  while ((cursor < cursor_end) &&
         (reinterpret_cast<size_t>(cursor) & 0xf)) {
    *cursor ^= masking_key[masking_key_index];
    ++cursor;
    masking_key_index = (masking_key_index + 1) % masking_key_length;
  }
  if (cursor == cursor_end) {
    return;
  }

  const int kBlockSize = 16;
  __m128i masking_key_block;
  for (int i = 0; i < kBlockSize; ++i) {
    *(reinterpret_cast<char*>(&masking_key_block) + i) =
        masking_key[masking_key_index];
    masking_key_index = (masking_key_index + 1) % masking_key_length;
  }

  while (cursor + kBlockSize <= cursor_end) {
    __m128i payload_block =
        _mm_load_si128(reinterpret_cast<__m128i*>(cursor));
    _mm_stream_si128(reinterpret_cast<__m128i*>(cursor),
                     _mm_xor_si128(payload_block, masking_key_block));
    cursor += kBlockSize;
  }
#endif

  while (cursor < cursor_end) {
    *cursor ^= masking_key[masking_key_index];
    ++cursor;
    masking_key_index = (masking_key_index + 1) % masking_key_length;
  }
}

%}
