/*
 * x86 feature check
 *
 * Copyright (C) 2013 Intel Corporation. All rights reserved.
 * Author:
 *  Jim Kukunas
 * 
 * For conditions of distribution and use, see copyright notice in zlib.h
 */

#include "x86.h"

int x86_cpu_enable_simd = 0;

#ifndef _MSC_VER
#include <pthread.h>

pthread_once_t cpu_check_inited_once = PTHREAD_ONCE_INIT;
static void _x86_check_features(void);

void x86_check_features(void)
{
  pthread_once(&cpu_check_inited_once, _x86_check_features);
}

static void _x86_check_features(void)
{
    int x86_cpu_has_sse2;
    int x86_cpu_has_sse42;
    int x86_cpu_has_pclmulqdq;
    unsigned eax, ebx, ecx, edx;

    eax = 1;
#ifdef __i386__
    __asm__ __volatile__ (
        "xchg %%ebx, %1\n\t"
        "cpuid\n\t"
        "xchg %1, %%ebx\n\t"
    : "+a" (eax), "=S" (ebx), "=c" (ecx), "=d" (edx)
    );
#else
    __asm__ __volatile__ (
        "cpuid\n\t"
    : "+a" (eax), "=b" (ebx), "=c" (ecx), "=d" (edx)
    );
#endif  /* (__i386__) */

    x86_cpu_has_sse2 = edx & 0x4000000;
    x86_cpu_has_sse42 = ecx & 0x100000;
    x86_cpu_has_pclmulqdq = ecx & 0x2;

    x86_cpu_enable_simd = x86_cpu_has_sse2 &&
                          x86_cpu_has_sse42 &&
                          x86_cpu_has_pclmulqdq;
}
#else
#include <intrin.h>
#include <windows.h>
#include <stdint.h>

static volatile int32_t once_control = 0;
static void _x86_check_features(void);
static int fake_pthread_once(volatile int32_t *once_control,
                             void (*init_routine)(void));

void x86_check_features(void)
{
    fake_pthread_once(&once_control, _x86_check_features);
}

/* Copied from "perftools_pthread_once" in tcmalloc */
static int fake_pthread_once(volatile int32_t *once_control,
                             void (*init_routine)(void)) {
    // Try for a fast path first. Note: this should be an acquire semantics read
    // It is on x86 and x64, where Windows runs.
    if (*once_control != 1) {
        while (1) {
            switch (InterlockedCompareExchange(once_control, 2, 0)) {
                case 0:
                    init_routine();
                    InterlockedExchange(once_control, 1);
                    return 0;
                case 1:
                    // The initializer has already been executed
                    return 0;
                default:
                    // The initializer is being processed by another thread
                    SwitchToThread();
            }
        }
    }
    return 0;
}

static void _x86_check_features(void)
{
    int x86_cpu_has_sse2;
    int x86_cpu_has_sse42;
    int x86_cpu_has_pclmulqdq;
    int regs[4];

    __cpuid(regs, 1);

    x86_cpu_has_sse2 = regs[3] & 0x4000000;
    x86_cpu_has_sse42= regs[2] & 0x100000;
    x86_cpu_has_pclmulqdq = regs[2] & 0x2;

    x86_cpu_enable_simd = x86_cpu_has_sse2 &&
                          x86_cpu_has_sse42 &&
                          x86_cpu_has_pclmulqdq;
}
#endif  /* _MSC_VER */
