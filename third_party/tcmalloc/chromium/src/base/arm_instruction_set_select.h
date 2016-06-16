// Copyright (c) 2011, Google Inc.
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
//
// Author: Alexander Levitskiy
//
// Generalizes the plethora of ARM flavors available to an easier to manage set
// Defs reference is at https://wiki.edubuntu.org/ARM/Thumb2PortingHowto

#ifndef ARM_INSTRUCTION_SET_SELECT_H_
#define ARM_INSTRUCTION_SET_SELECT_H_

#if defined(__ARM_ARCH_8A__)
# define ARMV8 1
#endif

#if defined(ARMV8) || \
    defined(__ARM_ARCH_7__) || \
    defined(__ARM_ARCH_7R__) || \
    defined(__ARM_ARCH_7A__)
# define ARMV7 1
#endif

#if defined(ARMV7) || \
    defined(__ARM_ARCH_6__) || \
    defined(__ARM_ARCH_6J__) || \
    defined(__ARM_ARCH_6K__) || \
    defined(__ARM_ARCH_6Z__) || \
    defined(__ARM_ARCH_6T2__) || \
    defined(__ARM_ARCH_6ZK__)
# define ARMV6 1
#endif

#if defined(ARMV6) || \
    defined(__ARM_ARCH_5T__) || \
    defined(__ARM_ARCH_5E__) || \
    defined(__ARM_ARCH_5TE__) || \
    defined(__ARM_ARCH_5TEJ__)
# define ARMV5 1
#endif

#if defined(ARMV5) || \
    defined(__ARM_ARCH_4__) || \
    defined(__ARM_ARCH_4T__)
# define ARMV4 1
#endif

#if defined(ARMV4) || \
    defined(__ARM_ARCH_3__) || \
    defined(__ARM_ARCH_3M__)
# define ARMV3 1
#endif

#if defined(ARMV3) || \
    defined(__ARM_ARCH_2__)
# define ARMV2 1
#endif

#endif  // ARM_INSTRUCTION_SET_SELECT_H_
