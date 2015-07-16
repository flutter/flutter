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

#include <stdlib.h>
#include "./safe_malloc.h"

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

/* Returns 0 in case of overflow of nmemb * size. */
static int CheckSizeArgumentsOverflow(uint64_t nmemb, size_t size) {
  const uint64_t total_size = nmemb * size;
  if (nmemb == 0) return 1;
  if ((uint64_t)size > BROTLI_MAX_ALLOCABLE_MEMORY / nmemb) return 0;
  if (total_size != (size_t)total_size) return 0;
  return 1;
}

void* BrotliSafeMalloc(uint64_t nmemb, size_t size) {
  if (!CheckSizeArgumentsOverflow(nmemb, size)) return NULL;
  assert(nmemb * size > 0);
  return malloc((size_t)(nmemb * size));
}

#if defined(__cplusplus) || defined(c_plusplus)
}    /* extern "C" */
#endif
