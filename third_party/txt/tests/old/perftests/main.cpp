/*
 * Copyright (C) 2016 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include <benchmark/benchmark.h>

#include <cutils/log.h>

#include <unicode/uclean.h>
#include <unicode/udata.h>

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>

int main(int argc, char** argv) {
  const char* fn = "/system/usr/icu/" U_ICUDATA_NAME ".dat";
  int fd = open(fn, O_RDONLY);
  LOG_ALWAYS_FATAL_IF(fd == -1);
  struct stat st;
  LOG_ALWAYS_FATAL_IF(fstat(fd, &st) != 0);
  void* data = mmap(NULL, st.st_size, PROT_READ, MAP_SHARED, fd, 0);

  UErrorCode errorCode = U_ZERO_ERROR;
  udata_setCommonData(data, &errorCode);
  LOG_ALWAYS_FATAL_IF(U_FAILURE(errorCode));
  u_init(&errorCode);
  LOG_ALWAYS_FATAL_IF(U_FAILURE(errorCode));

  benchmark::Initialize(&argc, argv);
  benchmark::RunSpecifiedBenchmarks();

  u_cleanup();
  return 0;
}
