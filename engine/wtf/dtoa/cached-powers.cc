// Copyright 2006-2008 the V8 project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
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

#include "config.h"

#include <stdarg.h>
#include <limits.h>
#include <math.h>

#include "cached-powers.h"
#include "utils.h"

namespace WTF {

namespace double_conversion {

    struct CachedPower {
        uint64_t significand;
        int16_t binary_exponent;
        int16_t decimal_exponent;
    };

    static const double kD_1_LOG2_10 = 0.30102999566398114;  //  1 / lg(10)
    static const CachedPower kCachedPowers[] = {
        {UINT64_2PART_C(0xfa8fd5a0, 081c0288), -1220, -348},
        {UINT64_2PART_C(0xbaaee17f, a23ebf76), -1193, -340},
        {UINT64_2PART_C(0x8b16fb20, 3055ac76), -1166, -332},
        {UINT64_2PART_C(0xcf42894a, 5dce35ea), -1140, -324},
        {UINT64_2PART_C(0x9a6bb0aa, 55653b2d), -1113, -316},
        {UINT64_2PART_C(0xe61acf03, 3d1a45df), -1087, -308},
        {UINT64_2PART_C(0xab70fe17, c79ac6ca), -1060, -300},
        {UINT64_2PART_C(0xff77b1fc, bebcdc4f), -1034, -292},
        {UINT64_2PART_C(0xbe5691ef, 416bd60c), -1007, -284},
        {UINT64_2PART_C(0x8dd01fad, 907ffc3c), -980, -276},
        {UINT64_2PART_C(0xd3515c28, 31559a83), -954, -268},
        {UINT64_2PART_C(0x9d71ac8f, ada6c9b5), -927, -260},
        {UINT64_2PART_C(0xea9c2277, 23ee8bcb), -901, -252},
        {UINT64_2PART_C(0xaecc4991, 4078536d), -874, -244},
        {UINT64_2PART_C(0x823c1279, 5db6ce57), -847, -236},
        {UINT64_2PART_C(0xc2109436, 4dfb5637), -821, -228},
        {UINT64_2PART_C(0x9096ea6f, 3848984f), -794, -220},
        {UINT64_2PART_C(0xd77485cb, 25823ac7), -768, -212},
        {UINT64_2PART_C(0xa086cfcd, 97bf97f4), -741, -204},
        {UINT64_2PART_C(0xef340a98, 172aace5), -715, -196},
        {UINT64_2PART_C(0xb23867fb, 2a35b28e), -688, -188},
        {UINT64_2PART_C(0x84c8d4df, d2c63f3b), -661, -180},
        {UINT64_2PART_C(0xc5dd4427, 1ad3cdba), -635, -172},
        {UINT64_2PART_C(0x936b9fce, bb25c996), -608, -164},
        {UINT64_2PART_C(0xdbac6c24, 7d62a584), -582, -156},
        {UINT64_2PART_C(0xa3ab6658, 0d5fdaf6), -555, -148},
        {UINT64_2PART_C(0xf3e2f893, dec3f126), -529, -140},
        {UINT64_2PART_C(0xb5b5ada8, aaff80b8), -502, -132},
        {UINT64_2PART_C(0x87625f05, 6c7c4a8b), -475, -124},
        {UINT64_2PART_C(0xc9bcff60, 34c13053), -449, -116},
        {UINT64_2PART_C(0x964e858c, 91ba2655), -422, -108},
        {UINT64_2PART_C(0xdff97724, 70297ebd), -396, -100},
        {UINT64_2PART_C(0xa6dfbd9f, b8e5b88f), -369, -92},
        {UINT64_2PART_C(0xf8a95fcf, 88747d94), -343, -84},
        {UINT64_2PART_C(0xb9447093, 8fa89bcf), -316, -76},
        {UINT64_2PART_C(0x8a08f0f8, bf0f156b), -289, -68},
        {UINT64_2PART_C(0xcdb02555, 653131b6), -263, -60},
        {UINT64_2PART_C(0x993fe2c6, d07b7fac), -236, -52},
        {UINT64_2PART_C(0xe45c10c4, 2a2b3b06), -210, -44},
        {UINT64_2PART_C(0xaa242499, 697392d3), -183, -36},
        {UINT64_2PART_C(0xfd87b5f2, 8300ca0e), -157, -28},
        {UINT64_2PART_C(0xbce50864, 92111aeb), -130, -20},
        {UINT64_2PART_C(0x8cbccc09, 6f5088cc), -103, -12},
        {UINT64_2PART_C(0xd1b71758, e219652c), -77, -4},
        {UINT64_2PART_C(0x9c400000, 00000000), -50, 4},
        {UINT64_2PART_C(0xe8d4a510, 00000000), -24, 12},
        {UINT64_2PART_C(0xad78ebc5, ac620000), 3, 20},
        {UINT64_2PART_C(0x813f3978, f8940984), 30, 28},
        {UINT64_2PART_C(0xc097ce7b, c90715b3), 56, 36},
        {UINT64_2PART_C(0x8f7e32ce, 7bea5c70), 83, 44},
        {UINT64_2PART_C(0xd5d238a4, abe98068), 109, 52},
        {UINT64_2PART_C(0x9f4f2726, 179a2245), 136, 60},
        {UINT64_2PART_C(0xed63a231, d4c4fb27), 162, 68},
        {UINT64_2PART_C(0xb0de6538, 8cc8ada8), 189, 76},
        {UINT64_2PART_C(0x83c7088e, 1aab65db), 216, 84},
        {UINT64_2PART_C(0xc45d1df9, 42711d9a), 242, 92},
        {UINT64_2PART_C(0x924d692c, a61be758), 269, 100},
        {UINT64_2PART_C(0xda01ee64, 1a708dea), 295, 108},
        {UINT64_2PART_C(0xa26da399, 9aef774a), 322, 116},
        {UINT64_2PART_C(0xf209787b, b47d6b85), 348, 124},
        {UINT64_2PART_C(0xb454e4a1, 79dd1877), 375, 132},
        {UINT64_2PART_C(0x865b8692, 5b9bc5c2), 402, 140},
        {UINT64_2PART_C(0xc83553c5, c8965d3d), 428, 148},
        {UINT64_2PART_C(0x952ab45c, fa97a0b3), 455, 156},
        {UINT64_2PART_C(0xde469fbd, 99a05fe3), 481, 164},
        {UINT64_2PART_C(0xa59bc234, db398c25), 508, 172},
        {UINT64_2PART_C(0xf6c69a72, a3989f5c), 534, 180},
        {UINT64_2PART_C(0xb7dcbf53, 54e9bece), 561, 188},
        {UINT64_2PART_C(0x88fcf317, f22241e2), 588, 196},
        {UINT64_2PART_C(0xcc20ce9b, d35c78a5), 614, 204},
        {UINT64_2PART_C(0x98165af3, 7b2153df), 641, 212},
        {UINT64_2PART_C(0xe2a0b5dc, 971f303a), 667, 220},
        {UINT64_2PART_C(0xa8d9d153, 5ce3b396), 694, 228},
        {UINT64_2PART_C(0xfb9b7cd9, a4a7443c), 720, 236},
        {UINT64_2PART_C(0xbb764c4c, a7a44410), 747, 244},
        {UINT64_2PART_C(0x8bab8eef, b6409c1a), 774, 252},
        {UINT64_2PART_C(0xd01fef10, a657842c), 800, 260},
        {UINT64_2PART_C(0x9b10a4e5, e9913129), 827, 268},
        {UINT64_2PART_C(0xe7109bfb, a19c0c9d), 853, 276},
        {UINT64_2PART_C(0xac2820d9, 623bf429), 880, 284},
        {UINT64_2PART_C(0x80444b5e, 7aa7cf85), 907, 292},
        {UINT64_2PART_C(0xbf21e440, 03acdd2d), 933, 300},
        {UINT64_2PART_C(0x8e679c2f, 5e44ff8f), 960, 308},
        {UINT64_2PART_C(0xd433179d, 9c8cb841), 986, 316},
        {UINT64_2PART_C(0x9e19db92, b4e31ba9), 1013, 324},
        {UINT64_2PART_C(0xeb96bf6e, badf77d9), 1039, 332},
        {UINT64_2PART_C(0xaf87023b, 9bf0ee6b), 1066, 340},
    };
    static const int kCachedPowersOffset = 348; // -kCachedPowers[0].decimal_exponent

    const int PowersOfTenCache::kDecimalExponentDistance = 8; // kCachedPowers[1].decimal_exponent - kCachedPowers[0].decimal_exponent
    const int PowersOfTenCache::kMinDecimalExponent = -348; // kCachedPowers[0].decimal_exponent
    const int PowersOfTenCache::kMaxDecimalExponent = 340; // kCachedPowers[kCachedPowersLength - 1].decimal_exponent

#if ENABLE(ASSERT)
    static const int kCachedPowersLength = ARRAY_SIZE(kCachedPowers);

    // Check that the static constants match the values in kCachedPowers.
    static void validateStaticConstants() {
        ASSERT(kCachedPowersOffset == -kCachedPowers[0].decimal_exponent);
        ASSERT(PowersOfTenCache::kDecimalExponentDistance == (kCachedPowers[1].decimal_exponent - kCachedPowers[0].decimal_exponent));
        ASSERT(PowersOfTenCache::kMinDecimalExponent == kCachedPowers[0].decimal_exponent);
        ASSERT(PowersOfTenCache::kMaxDecimalExponent == kCachedPowers[kCachedPowersLength - 1].decimal_exponent);
    }
#endif

    void PowersOfTenCache::GetCachedPowerForBinaryExponentRange(
                                                                int min_exponent,
                                                                int max_exponent,
                                                                DiyFp* power,
                                                                int* decimal_exponent) {
#if ENABLE(ASSERT)
        validateStaticConstants();
#endif
        int kQ = DiyFp::kSignificandSize;
        double k = ceil((min_exponent + kQ - 1) * kD_1_LOG2_10);
        int foo = kCachedPowersOffset;
        int index =
        (foo + static_cast<int>(k) - 1) / kDecimalExponentDistance + 1;
        ASSERT(0 <= index && index < kCachedPowersLength);
        CachedPower cached_power = kCachedPowers[index];
        ASSERT(min_exponent <= cached_power.binary_exponent);
        ASSERT(cached_power.binary_exponent <= max_exponent);
        *decimal_exponent = cached_power.decimal_exponent;
        *power = DiyFp(cached_power.significand, cached_power.binary_exponent);
    }


    void PowersOfTenCache::GetCachedPowerForDecimalExponent(int requested_exponent,
                                                            DiyFp* power,
                                                            int* found_exponent) {
        ASSERT(kMinDecimalExponent <= requested_exponent);
        ASSERT(requested_exponent < kMaxDecimalExponent + kDecimalExponentDistance);
#if ENABLE(ASSERT)
        validateStaticConstants();
#endif
        int index =
        (requested_exponent + kCachedPowersOffset) / kDecimalExponentDistance;
        CachedPower cached_power = kCachedPowers[index];
        *power = DiyFp(cached_power.significand, cached_power.binary_exponent);
        *found_exponent = cached_power.decimal_exponent;
        ASSERT(*found_exponent <= requested_exponent);
        ASSERT(requested_exponent < *found_exponent + kDecimalExponentDistance);
    }

}  // namespace double_conversion

} // namespace WTF
