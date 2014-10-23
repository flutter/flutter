/*
 * Copyright (C) 2012 University of Szeged
 * Copyright (C) 2012 Gabor Rapcsanyi
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY UNIVERSITY OF SZEGED ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL UNIVERSITY OF SZEGED OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef NEONHelpers_h
#define NEONHelpers_h

#if HAVE(ARM_NEON_INTRINSICS)

#include <arm_neon.h>

namespace blink {

inline float32x4_t loadRGBA8AsFloat(uint32_t* source)
{
    uint32x2_t temporary1 = {0, 0};
    temporary1 = vset_lane_u32(*source, temporary1, 0);
    uint16x4_t temporary2 = vget_low_u16(vmovl_u8(vreinterpret_u8_u32(temporary1)));
    return vcvtq_f32_u32(vmovl_u16(temporary2));
}

inline void storeFloatAsRGBA8(float32x4_t data, uint32_t* destination)
{
    uint16x4_t temporary1 = vmovn_u32(vcvtq_u32_f32(data));
    uint8x8_t temporary2 = vmovn_u16(vcombine_u16(temporary1, temporary1));
    *destination = vget_lane_u32(vreinterpret_u32_u8(temporary2), 0);
}

} // namespace blink

#endif // HAVE(ARM_NEON_INTRINSICS)

#endif // NEONHelpers_h
