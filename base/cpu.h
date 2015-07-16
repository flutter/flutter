// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_CPU_H_
#define BASE_CPU_H_

#include <string>

#include "base/base_export.h"

namespace base {

// Query information about the processor.
class BASE_EXPORT CPU {
 public:
  // Constructor
  CPU();

  enum IntelMicroArchitecture {
    PENTIUM,
    SSE,
    SSE2,
    SSE3,
    SSSE3,
    SSE41,
    SSE42,
    AVX,
    MAX_INTEL_MICRO_ARCHITECTURE
  };

  // Accessors for CPU information.
  const std::string& vendor_name() const { return cpu_vendor_; }
  int signature() const { return signature_; }
  int stepping() const { return stepping_; }
  int model() const { return model_; }
  int family() const { return family_; }
  int type() const { return type_; }
  int extended_model() const { return ext_model_; }
  int extended_family() const { return ext_family_; }
  bool has_mmx() const { return has_mmx_; }
  bool has_sse() const { return has_sse_; }
  bool has_sse2() const { return has_sse2_; }
  bool has_sse3() const { return has_sse3_; }
  bool has_ssse3() const { return has_ssse3_; }
  bool has_sse41() const { return has_sse41_; }
  bool has_sse42() const { return has_sse42_; }
  bool has_avx() const { return has_avx_; }
  // has_avx_hardware returns true when AVX is present in the CPU. This might
  // differ from the value of |has_avx()| because |has_avx()| also tests for
  // operating system support needed to actually call AVX instuctions.
  // Note: you should never need to call this function. It was added in order
  // to workaround a bug in NSS but |has_avx()| is what you want.
  bool has_avx_hardware() const { return has_avx_hardware_; }
  bool has_aesni() const { return has_aesni_; }
  bool has_non_stop_time_stamp_counter() const {
    return has_non_stop_time_stamp_counter_;
  }
  // has_broken_neon is only valid on ARM chips. If true, it indicates that we
  // believe that the NEON unit on the current CPU is flawed and cannot execute
  // some code. See https://code.google.com/p/chromium/issues/detail?id=341598
  bool has_broken_neon() const { return has_broken_neon_; }

  IntelMicroArchitecture GetIntelMicroArchitecture() const;
  const std::string& cpu_brand() const { return cpu_brand_; }

 private:
  // Query the processor for CPUID information.
  void Initialize();

  int signature_;  // raw form of type, family, model, and stepping
  int type_;  // process type
  int family_;  // family of the processor
  int model_;  // model of processor
  int stepping_;  // processor revision number
  int ext_model_;
  int ext_family_;
  bool has_mmx_;
  bool has_sse_;
  bool has_sse2_;
  bool has_sse3_;
  bool has_ssse3_;
  bool has_sse41_;
  bool has_sse42_;
  bool has_avx_;
  bool has_avx_hardware_;
  bool has_aesni_;
  bool has_non_stop_time_stamp_counter_;
  bool has_broken_neon_;
  std::string cpu_vendor_;
  std::string cpu_brand_;
};

}  // namespace base

#endif  // BASE_CPU_H_
