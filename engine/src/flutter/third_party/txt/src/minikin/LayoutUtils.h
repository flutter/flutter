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

#ifndef MINIKIN_LAYOUT_UTILS_H
#define MINIKIN_LAYOUT_UTILS_H

#include <stddef.h>
#include <stdint.h>

namespace minikin {

/*
 * Determine whether the code unit is a word space for the purposes of
 * justification.
 */
bool isWordSpace(uint16_t code_unit);

/**
 * Return offset of previous word break. It is either < offset or == 0.
 *
 * For the purpose of layout, a word break is a boundary with no
 * kerning or complex script processing. This is necessarily a
 * heuristic, but should be accurate most of the time.
 */
size_t getPrevWordBreakForCache(const uint16_t* chars,
                                size_t offset,
                                size_t len);

/**
 * Return offset of next word break. It is either > offset or == len.
 *
 * For the purpose of layout, a word break is a boundary with no
 * kerning or complex script processing. This is necessarily a
 * heuristic, but should be accurate most of the time.
 */
size_t getNextWordBreakForCache(const uint16_t* chars,
                                size_t offset,
                                size_t len);

}  // namespace minikin
#endif  // MINIKIN_LAYOUT_UTILS_H
