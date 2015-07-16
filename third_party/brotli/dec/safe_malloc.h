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

   Size-checked memory allocation.
*/

#ifndef BROTLI_DEC_SAFE_MALLOC_H_
#define BROTLI_DEC_SAFE_MALLOC_H_

#include <assert.h>

#include "./types.h"

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

/* This is the maximum memory amount that we will ever try to allocate. */
#define BROTLI_MAX_ALLOCABLE_MEMORY (1 << 30)

/* size-checking safe malloc/calloc: verify that the requested size is not too
   large, or return NULL. You don't need to call these for constructs like
   malloc(sizeof(foo)), but only if there's font-dependent size involved
   somewhere (like: malloc(decoded_size * sizeof(*something))). That's why this
   safe malloc() borrows the signature from calloc(), pointing at the dangerous
   underlying multiply involved.
*/
void* BrotliSafeMalloc(uint64_t nmemb, size_t size);

#if defined(__cplusplus) || defined(c_plusplus)
}    /* extern "C" */
#endif

#endif  /* BROTLI_DEC_SAFE_MALLOC_H_ */
