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

#ifndef MINIKIN_MEASUREMENT_H
#define MINIKIN_MEASUREMENT_H

#include <minikin/Layout.h>

namespace minikin {

float getRunAdvance(const float* advances,
                    const uint16_t* buf,
                    size_t start,
                    size_t count,
                    size_t offset);

size_t getOffsetForAdvance(const float* advances,
                           const uint16_t* buf,
                           size_t start,
                           size_t count,
                           float advance);

}  // namespace minikin

#endif  // MINIKIN_MEASUREMENT_H
