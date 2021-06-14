// Copyright (C) 2020 The Khronos Group Inc.
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
//    Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
//    Redistributions in binary form must reproduce the above
//    copyright notice, this list of conditions and the following
//    disclaimer in the documentation and/or other materials provided
//    with the distribution.
//
//    Neither the name of The Khronos Group Inc. nor the names of its
//    contributors may be used to endorse or promote products derived
//    from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
// ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#ifndef GLSLANG_BUILD_INFO
#define GLSLANG_BUILD_INFO

// 11.4.0
#define GLSLANG_VERSION_MAJOR 11
#define GLSLANG_VERSION_MINOR 4
#define GLSLANG_VERSION_PATCH 0
#define GLSLANG_VERSION_FLAVOR "flutter"

#define GLSLANG_VERSION_GREATER_THAN(major, minor, patch) \
  (((major) > GLSLANG_VERSION_MAJOR) ||                   \
   ((major) == GLSLANG_VERSION_MAJOR &&                   \
    (((minor) > GLSLANG_VERSION_MINOR) ||                 \
     ((minor) == GLSLANG_VERSION_MINOR &&                 \
      ((patch) > GLSLANG_VERSION_PATCH)))))

#define GLSLANG_VERSION_GREATER_OR_EQUAL_TO(major, minor, patch) \
  (((major) > GLSLANG_VERSION_MAJOR) ||                          \
   ((major) == GLSLANG_VERSION_MAJOR &&                          \
    (((minor) > GLSLANG_VERSION_MINOR) ||                        \
     ((minor) == GLSLANG_VERSION_MINOR &&                        \
      ((patch) >= GLSLANG_VERSION_PATCH)))))

#define GLSLANG_VERSION_LESS_THAN(major, minor, patch) \
  (((major) < GLSLANG_VERSION_MAJOR) ||                \
   ((major) == GLSLANG_VERSION_MAJOR &&                \
    (((minor) < GLSLANG_VERSION_MINOR) ||              \
     ((minor) == GLSLANG_VERSION_MINOR &&              \
      ((patch) < GLSLANG_VERSION_PATCH)))))

#define GLSLANG_VERSION_LESS_OR_EQUAL_TO(major, minor, patch) \
  (((major) < GLSLANG_VERSION_MAJOR) ||                       \
   ((major) == GLSLANG_VERSION_MAJOR &&                       \
    (((minor) < GLSLANG_VERSION_MINOR) ||                     \
     ((minor) == GLSLANG_VERSION_MINOR &&                     \
      ((patch) <= GLSLANG_VERSION_PATCH)))))

#endif  // GLSLANG_BUILD_INFO
