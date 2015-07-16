// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "third_party/ashmem/ashmem.h"

int main(void) {
  const int pages_purged = ashmem_purge_all();
  if (pages_purged < 0) {
    perror("ashmem_purge_all");
    return EXIT_FAILURE;
  }
  printf("Purged %d pages (%d KBytes)\n",
         pages_purged, pages_purged * getpagesize() / 1024);
  return EXIT_SUCCESS;
}
