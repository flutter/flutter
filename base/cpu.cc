// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/cpu.h"

#include <stdlib.h>
#include <string.h>

#include <algorithm>

#include "base/basictypes.h"
#include "base/strings/string_piece.h"
#include "build/build_config.h"

#if defined(ARCH_CPU_ARM_FAMILY) && (defined(OS_ANDROID) || defined(OS_LINUX))
#include "base/files/file_util.h"
#include "base/lazy_instance.h"
#endif

#if defined(ARCH_CPU_X86_FAMILY)
#if defined(_MSC_VER)
#include <intrin.h>
#include <immintrin.h>  // For _xgetbv()
#endif
#endif

namespace base {

CPU::CPU()
  : signature_(0),
    type_(0),
    family_(0),
    model_(0),
    stepping_(0),
    ext_model_(0),
    ext_family_(0),
    has_mmx_(false),
    has_sse_(false),
    has_sse2_(false),
    has_sse3_(false),
    has_ssse3_(false),
    has_sse41_(false),
    has_sse42_(false),
    has_avx_(false),
    has_avx_hardware_(false),
    has_aesni_(false),
    has_non_stop_time_stamp_counter_(false),
    has_broken_neon_(false),
    cpu_vendor_("unknown") {
  Initialize();
}

namespace {

#if defined(ARCH_CPU_X86_FAMILY)
#ifndef _MSC_VER

#if defined(__pic__) && defined(__i386__)

void __cpuid(int cpu_info[4], int info_type) {
  __asm__ volatile (
    "mov %%ebx, %%edi\n"
    "cpuid\n"
    "xchg %%edi, %%ebx\n"
    : "=a"(cpu_info[0]), "=D"(cpu_info[1]), "=c"(cpu_info[2]), "=d"(cpu_info[3])
    : "a"(info_type)
  );
}

#else

void __cpuid(int cpu_info[4], int info_type) {
  __asm__ volatile (
    "cpuid \n\t"
    : "=a"(cpu_info[0]), "=b"(cpu_info[1]), "=c"(cpu_info[2]), "=d"(cpu_info[3])
    : "a"(info_type)
  );
}

#endif

// _xgetbv returns the value of an Intel Extended Control Register (XCR).
// Currently only XCR0 is defined by Intel so |xcr| should always be zero.
uint64 _xgetbv(uint32 xcr) {
  uint32 eax, edx;

  __asm__ volatile ("xgetbv" : "=a" (eax), "=d" (edx) : "c" (xcr));
  return (static_cast<uint64>(edx) << 32) | eax;
}

#endif  // !_MSC_VER
#endif  // ARCH_CPU_X86_FAMILY

#if defined(ARCH_CPU_ARM_FAMILY) && (defined(OS_ANDROID) || defined(OS_LINUX))
class LazyCpuInfoValue {
 public:
  LazyCpuInfoValue() : has_broken_neon_(false) {
    // This function finds the value from /proc/cpuinfo under the key "model
    // name" or "Processor". "model name" is used in Linux 3.8 and later (3.7
    // and later for arm64) and is shown once per CPU. "Processor" is used in
    // earler versions and is shown only once at the top of /proc/cpuinfo
    // regardless of the number CPUs.
    const char kModelNamePrefix[] = "model name\t: ";
    const char kProcessorPrefix[] = "Processor\t: ";

    // This function also calculates whether we believe that this CPU has a
    // broken NEON unit based on these fields from cpuinfo:
    unsigned implementer = 0, architecture = 0, variant = 0, part = 0,
             revision = 0;
    const struct {
      const char key[17];
      unsigned *result;
    } kUnsignedValues[] = {
      {"CPU implementer", &implementer},
      {"CPU architecture", &architecture},
      {"CPU variant", &variant},
      {"CPU part", &part},
      {"CPU revision", &revision},
    };

    std::string contents;
    ReadFileToString(FilePath("/proc/cpuinfo"), &contents);
    DCHECK(!contents.empty());
    if (contents.empty()) {
      return;
    }

    std::istringstream iss(contents);
    std::string line;
    while (std::getline(iss, line)) {
      if (brand_.empty() &&
          (line.compare(0, strlen(kModelNamePrefix), kModelNamePrefix) == 0 ||
           line.compare(0, strlen(kProcessorPrefix), kProcessorPrefix) == 0)) {
        brand_.assign(line.substr(strlen(kModelNamePrefix)));
      }

      for (size_t i = 0; i < arraysize(kUnsignedValues); i++) {
        const char *key = kUnsignedValues[i].key;
        const size_t len = strlen(key);

        if (line.compare(0, len, key) == 0 &&
            line.size() >= len + 1 &&
            (line[len] == '\t' || line[len] == ' ' || line[len] == ':')) {
          size_t colon_pos = line.find(':', len);
          if (colon_pos == std::string::npos) {
            continue;
          }

          const StringPiece line_sp(line);
          StringPiece value_sp = line_sp.substr(colon_pos + 1);
          while (!value_sp.empty() &&
                 (value_sp[0] == ' ' || value_sp[0] == '\t')) {
            value_sp = value_sp.substr(1);
          }

          // The string may have leading "0x" or not, so we use strtoul to
          // handle that.
          char *endptr;
          std::string value(value_sp.as_string());
          unsigned long int result = strtoul(value.c_str(), &endptr, 0);
          if (*endptr == 0 && result <= UINT_MAX) {
            *kUnsignedValues[i].result = result;
          }
        }
      }
    }

    has_broken_neon_ =
      implementer == 0x51 &&
      architecture == 7 &&
      variant == 1 &&
      part == 0x4d &&
      revision == 0;
  }

  const std::string& brand() const { return brand_; }
  bool has_broken_neon() const { return has_broken_neon_; }

 private:
  std::string brand_;
  bool has_broken_neon_;
  DISALLOW_COPY_AND_ASSIGN(LazyCpuInfoValue);
};

base::LazyInstance<LazyCpuInfoValue>::Leaky g_lazy_cpuinfo =
    LAZY_INSTANCE_INITIALIZER;

#endif  // defined(ARCH_CPU_ARM_FAMILY) && (defined(OS_ANDROID) ||
        // defined(OS_LINUX))

}  // anonymous namespace

void CPU::Initialize() {
#if defined(ARCH_CPU_X86_FAMILY)
  int cpu_info[4] = {-1};
  char cpu_string[48];

  // __cpuid with an InfoType argument of 0 returns the number of
  // valid Ids in CPUInfo[0] and the CPU identification string in
  // the other three array elements. The CPU identification string is
  // not in linear order. The code below arranges the information
  // in a human readable form. The human readable order is CPUInfo[1] |
  // CPUInfo[3] | CPUInfo[2]. CPUInfo[2] and CPUInfo[3] are swapped
  // before using memcpy to copy these three array elements to cpu_string.
  __cpuid(cpu_info, 0);
  int num_ids = cpu_info[0];
  std::swap(cpu_info[2], cpu_info[3]);
  memcpy(cpu_string, &cpu_info[1], 3 * sizeof(cpu_info[1]));
  cpu_vendor_.assign(cpu_string, 3 * sizeof(cpu_info[1]));

  // Interpret CPU feature information.
  if (num_ids > 0) {
    __cpuid(cpu_info, 1);
    signature_ = cpu_info[0];
    stepping_ = cpu_info[0] & 0xf;
    model_ = ((cpu_info[0] >> 4) & 0xf) + ((cpu_info[0] >> 12) & 0xf0);
    family_ = (cpu_info[0] >> 8) & 0xf;
    type_ = (cpu_info[0] >> 12) & 0x3;
    ext_model_ = (cpu_info[0] >> 16) & 0xf;
    ext_family_ = (cpu_info[0] >> 20) & 0xff;
    has_mmx_ =   (cpu_info[3] & 0x00800000) != 0;
    has_sse_ =   (cpu_info[3] & 0x02000000) != 0;
    has_sse2_ =  (cpu_info[3] & 0x04000000) != 0;
    has_sse3_ =  (cpu_info[2] & 0x00000001) != 0;
    has_ssse3_ = (cpu_info[2] & 0x00000200) != 0;
    has_sse41_ = (cpu_info[2] & 0x00080000) != 0;
    has_sse42_ = (cpu_info[2] & 0x00100000) != 0;
    has_avx_hardware_ =
                 (cpu_info[2] & 0x10000000) != 0;
    // AVX instructions will generate an illegal instruction exception unless
    //   a) they are supported by the CPU,
    //   b) XSAVE is supported by the CPU and
    //   c) XSAVE is enabled by the kernel.
    // See http://software.intel.com/en-us/blogs/2011/04/14/is-avx-enabled
    //
    // In addition, we have observed some crashes with the xgetbv instruction
    // even after following Intel's example code. (See crbug.com/375968.)
    // Because of that, we also test the XSAVE bit because its description in
    // the CPUID documentation suggests that it signals xgetbv support.
    has_avx_ =
        has_avx_hardware_ &&
        (cpu_info[2] & 0x04000000) != 0 /* XSAVE */ &&
        (cpu_info[2] & 0x08000000) != 0 /* OSXSAVE */ &&
        (_xgetbv(0) & 6) == 6 /* XSAVE enabled by kernel */;
    has_aesni_ = (cpu_info[2] & 0x02000000) != 0;
  }

  // Get the brand string of the cpu.
  __cpuid(cpu_info, 0x80000000);
  const int parameter_end = 0x80000004;
  int max_parameter = cpu_info[0];

  if (cpu_info[0] >= parameter_end) {
    char* cpu_string_ptr = cpu_string;

    for (int parameter = 0x80000002; parameter <= parameter_end &&
         cpu_string_ptr < &cpu_string[sizeof(cpu_string)]; parameter++) {
      __cpuid(cpu_info, parameter);
      memcpy(cpu_string_ptr, cpu_info, sizeof(cpu_info));
      cpu_string_ptr += sizeof(cpu_info);
    }
    cpu_brand_.assign(cpu_string, cpu_string_ptr - cpu_string);
  }

  const int parameter_containing_non_stop_time_stamp_counter = 0x80000007;
  if (max_parameter >= parameter_containing_non_stop_time_stamp_counter) {
    __cpuid(cpu_info, parameter_containing_non_stop_time_stamp_counter);
    has_non_stop_time_stamp_counter_ = (cpu_info[3] & (1 << 8)) != 0;
  }
#elif defined(ARCH_CPU_ARM_FAMILY) && (defined(OS_ANDROID) || defined(OS_LINUX))
  cpu_brand_.assign(g_lazy_cpuinfo.Get().brand());
  has_broken_neon_ = g_lazy_cpuinfo.Get().has_broken_neon();
#endif
}

CPU::IntelMicroArchitecture CPU::GetIntelMicroArchitecture() const {
  if (has_avx()) return AVX;
  if (has_sse42()) return SSE42;
  if (has_sse41()) return SSE41;
  if (has_ssse3()) return SSSE3;
  if (has_sse3()) return SSE3;
  if (has_sse2()) return SSE2;
  if (has_sse()) return SSE;
  return PENTIUM;
}

}  // namespace base
