/*
 * Copyright (C) 2013 The Android Open Source Project
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

#ifndef MINIKIN_CSS_PARSE_H
#define MINIKIN_CSS_PARSE_H

#include <map>
#include <string>

namespace android {

enum CssTag {
    unknown,
    fontSize,
    fontWeight,
    fontStyle,
    minikinHinting,
    minikinBidi,
};

const std::string cssTagNames[] = {
    "unknown",
    "font-size",
    "font-weight",
    "font-style",
    "-minikin-hinting",
    "-minikin-bidi",
};

class CssValue {
public:
    enum Type {
        UNKNOWN,
        FLOAT
    };
    enum Units {
        SCALAR,
        PERCENT,
        PX,
        EM
    };
    CssValue() : mType(UNKNOWN) { }
    explicit CssValue(double v) :
        mType(FLOAT), floatValue(v), mUnits(SCALAR) { }
    Type getType() const { return mType; }
    double getFloatValue() const { return floatValue; }
    int getIntValue() const { return floatValue; }
    std::string toString(CssTag tag) const;
    void setFloatValue(double v) {
        mType = FLOAT;
        floatValue = v;
    }
private:
    Type mType;
    double floatValue;
    Units mUnits;
};

class CssProperties {
public:
    bool parse(const std::string& str);
    bool hasTag(CssTag tag) const;
    CssValue value(CssTag tag) const;

    // primarily for debugging
    std::string toString() const;
private:
    // We'll use STL map for now but can replace it with something
    // more efficient if needed
    std::map<CssTag, CssValue> mMap;
};

}  // namespace android

#endif  // MINIKIN_CSS_PARSE_H