/* cpu_features.c -- Processor features detection.
 *
 * Copyright 2018 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the Chromium source repository LICENSE file.
 */

#include "cpu_features.h"
#include "zutil.h"

#include <stdint.h>
#if defined(_MSC_VER)
#include <intrin.h>
#elif defined(ADLER32_SIMD_SSSE3)
#include <cpuid.h>
#endif

/* TODO(cavalcantii): remove checks for x86_flags on deflate.
 */
#if defined(ARMV8_OS_MACOS)
/* crc32 is a baseline feature in ARMv8.1-A, and macOS running on arm64 is new
 * enough that this can be assumed without runtime detection. */
int ZLIB_INTERNAL arm_cpu_enable_crc32 = 1;
#else
int ZLIB_INTERNAL arm_cpu_enable_crc32 = 0;
#endif
int ZLIB_INTERNAL arm_cpu_enable_pmull = 0;
int ZLIB_INTERNAL x86_cpu_enable_sse2 = 0;
int ZLIB_INTERNAL x86_cpu_enable_ssse3 = 0;
int ZLIB_INTERNAL x86_cpu_enable_simd = 0;

#ifndef CPU_NO_SIMD

#if defined(ARMV8_OS_ANDROID) || defined(ARMV8_OS_LINUX) || defined(ARMV8_OS_FUCHSIA)
#include <pthread.h>
#endif

#if defined(ARMV8_OS_ANDROID)
#include <cpu-features.h>
#elif defined(ARMV8_OS_LINUX)
#include <asm/hwcap.h>
#include <sys/auxv.h>
#elif defined(ARMV8_OS_FUCHSIA)
#include <zircon/features.h>
#include <zircon/syscalls.h>
#include <zircon/types.h>
#elif defined(ARMV8_OS_WINDOWS) || defined(X86_WINDOWS)
#include <windows.h>
#elif !defined(_MSC_VER)
#include <pthread.h>
#else
#error cpu_features.c CPU feature detection in not defined for your platform
#endif

#if !defined(CPU_NO_SIMD) && !defined(ARMV8_OS_MACOS) && !defined(ARM_OS_IOS)
static void _cpu_check_features(void);
#endif

#if defined(ARMV8_OS_ANDROID) || defined(ARMV8_OS_LINUX) || defined(ARMV8_OS_MACOS) || defined(ARMV8_OS_FUCHSIA) || defined(X86_NOT_WINDOWS)
#if !defined(ARMV8_OS_MACOS)
// _cpu_check_features() doesn't need to do anything on mac/arm since all
// features are known at build time, so don't call it.
// Do provide cpu_check_features() (with a no-op implementation) so that we
// don't have to make all callers of it check for mac/arm.
static pthread_once_t cpu_check_inited_once = PTHREAD_ONCE_INIT;
#endif
void ZLIB_INTERNAL cpu_check_features(void)
{
#if !defined(ARMV8_OS_MACOS)
    pthread_once(&cpu_check_inited_once, _cpu_check_features);
#endif
}
#elif defined(ARMV8_OS_WINDOWS) || defined(X86_WINDOWS)
static INIT_ONCE cpu_check_inited_once = INIT_ONCE_STATIC_INIT;
static BOOL CALLBACK _cpu_check_features_forwarder(PINIT_ONCE once, PVOID param, PVOID* context)
{
    _cpu_check_features();
    return TRUE;
}
void ZLIB_INTERNAL cpu_check_features(void)
{
    InitOnceExecuteOnce(&cpu_check_inited_once, _cpu_check_features_forwarder,
                        NULL, NULL);
}
#endif

#if (defined(__ARM_NEON__) || defined(__ARM_NEON))
/*
 * iOS@ARM is a special case where we always have NEON but don't check
 * for crypto extensions.
 */
#if !defined(ARMV8_OS_MACOS) && !defined(ARM_OS_IOS)
/*
 * See http://bit.ly/2CcoEsr for run-time detection of ARM features and also
 * crbug.com/931275 for android_getCpuFeatures() use in the Android sandbox.
 */
static void _cpu_check_features(void)
{
#if defined(ARMV8_OS_ANDROID) && defined(__aarch64__)
    uint64_t features = android_getCpuFeatures();
    arm_cpu_enable_crc32 = !!(features & ANDROID_CPU_ARM64_FEATURE_CRC32);
    arm_cpu_enable_pmull = !!(features & ANDROID_CPU_ARM64_FEATURE_PMULL);
#elif defined(ARMV8_OS_ANDROID) /* aarch32 */
    uint64_t features = android_getCpuFeatures();
    arm_cpu_enable_crc32 = !!(features & ANDROID_CPU_ARM_FEATURE_CRC32);
    arm_cpu_enable_pmull = !!(features & ANDROID_CPU_ARM_FEATURE_PMULL);
#elif defined(ARMV8_OS_LINUX) && defined(__aarch64__)
    unsigned long features = getauxval(AT_HWCAP);
    arm_cpu_enable_crc32 = !!(features & HWCAP_CRC32);
    arm_cpu_enable_pmull = !!(features & HWCAP_PMULL);
#elif defined(ARMV8_OS_LINUX) && (defined(__ARM_NEON) || defined(__ARM_NEON__))
    /* Query HWCAP2 for ARMV8-A SoCs running in aarch32 mode */
    unsigned long features = getauxval(AT_HWCAP2);
    arm_cpu_enable_crc32 = !!(features & HWCAP2_CRC32);
    arm_cpu_enable_pmull = !!(features & HWCAP2_PMULL);
#elif defined(ARMV8_OS_FUCHSIA)
    uint32_t features;
    zx_status_t rc = zx_system_get_features(ZX_FEATURE_KIND_CPU, &features);
    if (rc != ZX_OK || (features & ZX_ARM64_FEATURE_ISA_ASIMD) == 0)
        return;  /* Report nothing if ASIMD(NEON) is missing */
    arm_cpu_enable_crc32 = !!(features & ZX_ARM64_FEATURE_ISA_CRC32);
    arm_cpu_enable_pmull = !!(features & ZX_ARM64_FEATURE_ISA_PMULL);
#elif defined(ARMV8_OS_WINDOWS)
    arm_cpu_enable_crc32 = IsProcessorFeaturePresent(PF_ARM_V8_CRC32_INSTRUCTIONS_AVAILABLE);
    arm_cpu_enable_pmull = IsProcessorFeaturePresent(PF_ARM_V8_CRYPTO_INSTRUCTIONS_AVAILABLE);
#endif
}
#endif
#elif defined(X86_NOT_WINDOWS) || defined(X86_WINDOWS)
/*
 * iOS@x86 (i.e. emulator) is another special case where we disable
 * SIMD optimizations.
 */
#ifndef CPU_NO_SIMD
/* On x86 we simply use a instruction to check the CPU features.
 * (i.e. CPUID).
 */
static void _cpu_check_features(void)
{
    int x86_cpu_has_sse2;
    int x86_cpu_has_ssse3;
    int x86_cpu_has_sse42;
    int x86_cpu_has_pclmulqdq;
    int abcd[4];

#ifdef _MSC_VER
    __cpuid(abcd, 1);
#else
    __cpuid(1, abcd[0], abcd[1], abcd[2], abcd[3]);
#endif

    x86_cpu_has_sse2 = abcd[3] & 0x4000000;
    x86_cpu_has_ssse3 = abcd[2] & 0x000200;
    x86_cpu_has_sse42 = abcd[2] & 0x100000;
    x86_cpu_has_pclmulqdq = abcd[2] & 0x2;

    x86_cpu_enable_sse2 = x86_cpu_has_sse2;

    x86_cpu_enable_ssse3 = x86_cpu_has_ssse3;

    x86_cpu_enable_simd = x86_cpu_has_sse2 &&
                          x86_cpu_has_sse42 &&
                          x86_cpu_has_pclmulqdq;
}
#endif
#endif
#endif
