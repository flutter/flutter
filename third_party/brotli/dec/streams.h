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

   Functions for streaming input and output.
*/

#ifndef BROTLI_DEC_STREAMS_H_
#define BROTLI_DEC_STREAMS_H_

#include <stdio.h>
#include "./types.h"

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

/* Function pointer type used to read len bytes into buf. Returns the */
/* number of bytes read or -1 on error. */
typedef int (*BrotliInputFunction)(void* data, uint8_t* buf, size_t len);

/* Input callback function with associated data. */
typedef struct {
  BrotliInputFunction cb_;
  void* data_;
} BrotliInput;

/* Reads len bytes into buf, using the in callback. */
static BROTLI_INLINE int BrotliRead(BrotliInput in, uint8_t* buf, size_t len) {
  return in.cb_(in.data_, buf, len);
}

/* Function pointer type used to write len bytes into buf. Returns the */
/* number of bytes written or -1 on error. */
typedef int (*BrotliOutputFunction)(void* data, const uint8_t* buf, size_t len);

/* Output callback function with associated data. */
typedef struct {
  BrotliOutputFunction cb_;
  void* data_;
} BrotliOutput;

/* Writes len bytes into buf, using the out callback. */
static BROTLI_INLINE int BrotliWrite(BrotliOutput out,
                                     const uint8_t* buf, size_t len) {
  return out.cb_(out.data_, buf, len);
}

/* Memory region with position. */
typedef struct {
  const uint8_t* buffer;
  size_t length;
  size_t pos;
} BrotliMemInput;

/* Input callback where *data is a BrotliMemInput struct. */
int BrotliMemInputFunction(void* data, uint8_t* buf, size_t count);

/* Returns an input callback that wraps the given memory region. */
BrotliInput BrotliInitMemInput(const uint8_t* buffer, size_t length,
                               BrotliMemInput* mem_input);

/* Output buffer with position. */
typedef struct {
  uint8_t* buffer;
  size_t length;
  size_t pos;
} BrotliMemOutput;

/* Output callback where *data is a BrotliMemOutput struct. */
int BrotliMemOutputFunction(void* data, const uint8_t* buf, size_t count);

/* Returns an output callback that wraps the given memory region. */
BrotliOutput BrotliInitMemOutput(uint8_t* buffer, size_t length,
                                 BrotliMemOutput* mem_output);

/* Input callback that reads from standard input. */
int BrotliStdinInputFunction(void* data, uint8_t* buf, size_t count);
BrotliInput BrotliStdinInput();

/* Output callback that writes to standard output. */
int BrotliStdoutOutputFunction(void* data, const uint8_t* buf, size_t count);
BrotliOutput BrotliStdoutOutput();

/* Input callback that reads from a file. */
int BrotliFileInputFunction(void* data, uint8_t* buf, size_t count);
BrotliInput BrotliFileInput(FILE* f);

/* Output callback that writes to a file. */
int BrotliFileOutputFunction(void* data, const uint8_t* buf, size_t count);
BrotliOutput BrotliFileOutput(FILE* f);

#if defined(__cplusplus) || defined(c_plusplus)
}    /* extern "C" */
#endif

#endif  /* BROTLI_DEC_STREAMS_H_ */
