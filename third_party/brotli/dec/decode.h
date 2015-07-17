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

/* API for Brotli decompression */

#ifndef BROTLI_DEC_DECODE_H_
#define BROTLI_DEC_DECODE_H_

#include "./state.h"
#include "./streams.h"
#include "./types.h"

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

typedef enum {
  /* Decoding error, e.g. corrupt input or no memory */
  BROTLI_RESULT_ERROR = 0,
  /* Successfully completely done */
  BROTLI_RESULT_SUCCESS = 1,
  /* Partially done, but must be called again with more input */
  BROTLI_RESULT_NEEDS_MORE_INPUT = 2,
  /* Partially done, but must be called again with more output */
  BROTLI_RESULT_NEEDS_MORE_OUTPUT = 3
} BrotliResult;

/* Sets *decoded_size to the decompressed size of the given encoded stream. */
/* This function only works if the encoded buffer has a single meta block, */
/* or if it has two meta-blocks, where the first is uncompressed and the */
/* second is empty. */
/* Returns 1 on success, 0 on failure. */
BrotliResult BrotliDecompressedSize(size_t encoded_size,
                                    const uint8_t* encoded_buffer,
                                    size_t* decoded_size);

/* Decompresses the data in encoded_buffer into decoded_buffer, and sets */
/* *decoded_size to the decompressed length. */
/* Returns 0 if there was either a bit stream error or memory allocation */
/* error, and 1 otherwise. */
/* If decoded size is zero, returns 1 and keeps decoded_buffer unchanged. */
BrotliResult BrotliDecompressBuffer(size_t encoded_size,
                                    const uint8_t* encoded_buffer,
                                    size_t* decoded_size,
                                    uint8_t* decoded_buffer);

/* Same as above, but uses the specified input and output callbacks instead */
/* of reading from and writing to pre-allocated memory buffers. */
BrotliResult BrotliDecompress(BrotliInput input, BrotliOutput output);

/* Same as above, but supports the caller to call the decoder repeatedly with
   partial data to support streaming. The state must be initialized with
   BrotliStateInit and reused with every call for the same stream.
   Return values:
   0: failure.
   1: success, and done.
   2: success so far, end not reached so should call again with more input.
   The finish parameter is used as follows, for a series of calls with the
   same state:
   0: Every call except the last one must be called with finish set to 0. The
      last call may have finish set to either 0 or 1. Only if finish is 0, can
      the function return 2. It may also return 0 or 1, in that case no more
      calls (even with finish 1) may be made.
   1: Only the last call may have finish set to 1. It's ok to give empty input
      if all input was already given to previous calls. It is also ok to have
      only one single call in total, with finish 1, and with all input
      available immediately. That matches the non-streaming case. If finish is
      1, the function can only return 0 or 1, never 2. After a finish, no more
      calls may be done.
   After everything is done, the state must be cleaned with BrotliStateCleanup
   to free allocated resources.
   The given BrotliOutput must always accept all output and make enough space,
   it returning a smaller value than the amount of bytes to write always results
   in an error.
*/
BrotliResult BrotliDecompressStreaming(BrotliInput input, BrotliOutput output,
                                       int finish, BrotliState* s);

/* Same as above, but with memory buffers.
   Must be called with an allocated input buffer in *next_in and an allocated
   output buffer in *next_out. The values *available_in and *available_out
   must specify the allocated size in *next_in and *next_out respectively.
   The value *total_out must be 0 initially, and will be summed with the
   amount of output bytes written after each call, so that at the end it
   gives the complete decoded size.
   After each call, *available_in will be decremented by the amount of input
   bytes consumed, and the *next_in pointer will be incremented by that amount.
   Similarly, *available_out will be decremented by the amount of output
   bytes written, and the *next_out pointer will be incremented by that
   amount.

   The input may be partial. With each next function call, *next_in and
   *available_in must be updated to point to a next part of the compressed
   input. The current implementation will always consume all input unless
   an error occurs, so normally *available_in will always be 0 after
   calling this function and the next adjacent part of input is desired.

   In the current implementation, the function requires that there is enough
   output buffer size to write all currently processed input, so
   *available_out must be large enough. Since the function updates *next_out
   each time, as long as the output buffer is large enough you can keep
   reusing this variable. It is also possible to update *next_out and
   *available_out yourself before a next call, e.g. to point to a new larger
   buffer.
*/
BrotliResult BrotliDecompressBufferStreaming(size_t* available_in,
                                             const uint8_t** next_in,
                                             int finish,
                                             size_t* available_out,
                                             uint8_t** next_out,
                                             size_t* total_out,
                                             BrotliState* s);

#if defined(__cplusplus) || defined(c_plusplus)
} /* extern "C" */
#endif

#endif  /* BROTLI_DEC_DECODE_H_ */
