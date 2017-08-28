/*
 * Copyright (C) 2015 The Android Open Source Project
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

#ifndef MINIKIN_TEST_ICU_TEST_BASE_H
#define MINIKIN_TEST_ICU_TEST_BASE_H

#include <gtest/gtest.h>
#include <unicode/uclean.h>
#include <unicode/udata.h>

// low level file access for mapping ICU data
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>

namespace minikin {

class ICUTestBase : public testing::Test {
 protected:
  virtual void SetUp() override {
    const char* fn = "/system/usr/icu/" U_ICUDATA_NAME ".dat";
    int fd = open(fn, O_RDONLY);
    ASSERT_NE(-1, fd);
    struct stat sb;
    ASSERT_EQ(0, fstat(fd, &sb));
    void* data = mmap(NULL, sb.st_size, PROT_READ, MAP_SHARED, fd, 0);

    UErrorCode errorCode = U_ZERO_ERROR;
    udata_setCommonData(data, &errorCode);
    ASSERT_TRUE(U_SUCCESS(errorCode));
    u_init(&errorCode);
    ASSERT_TRUE(U_SUCCESS(errorCode));
  }

  virtual void TearDown() override { u_cleanup(); }
};

}  // namespace minikin
#endif  //  MINIKIN_TEST_ICU_TEST_BASE_H
