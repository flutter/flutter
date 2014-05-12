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

#include <string>
#include <cstdlib>
#include <cstring>
#include <cstdio> // for sprintf - for debugging

#include <minikin/CssParse.h>

using std::map;
using std::pair;
using std::string;

namespace android {

bool strEqC(const string str, size_t off, size_t len, const char* str2) {
    if (len != strlen(str2)) return false;
    return !memcmp(str.data() + off, str2, len);
}

CssTag parseTag(const string str, size_t off, size_t len) {
    if (len == 0) return unknown;
    char c = str[off];
    if (c == 'f') {
        if (strEqC(str, off, len, "font-size")) return fontSize;
        if (strEqC(str, off, len, "font-weight")) return fontWeight;
        if (strEqC(str, off, len, "font-style")) return fontStyle;
    } else if (c == '-') {
        if (strEqC(str, off, len, "-minikin-hinting")) return minikinHinting;
        if (strEqC(str, off, len, "-minikin-bidi")) return minikinBidi;
    }
    return unknown;
}

bool parseValue(const string str, size_t *off, size_t len, CssTag tag,
        CssValue* v) {
    const char* data = str.data();
    char* endptr;
    double fv = strtod(data + *off, &endptr);
    if (endptr == data + *off) {
        // No numeric value, try tag-specific idents
        size_t end;
        for (end = *off; end < len; end++) {
            char c = data[end];
            if (c != '-' && !(c >= 'a' && c <= 'z') &&
                !(c >= '0' && c <= '9')) break;
        }
        size_t taglen = end - *off;
        endptr += taglen;
        if (tag == fontStyle) {
            if (strEqC(str, *off, taglen, "normal")) {
                fv = 0;
            } else if (strEqC(str, *off, taglen, "italic")) {
                fv = 1;
                // TODO: oblique, but who really cares?
            } else {
                return false;
            }
        } else if (tag == fontWeight) {
            if (strEqC(str, *off, taglen, "normal")) {
                fv = 400;
            } else if (strEqC(str, *off, taglen, "bold")) {
                fv = 700;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }
    v->setFloatValue(fv);
    *off = endptr - data;
    return true;
}

string CssValue::toString(CssTag tag) const {
    if (mType == FLOAT) {
        if (tag == fontStyle) {
            return floatValue ? "italic" : "normal";
        }
        char buf[64];
        sprintf(buf, "%g", floatValue);
        return string(buf);
    }
    return "";
}

bool CssProperties::parse(const string& str) {
    size_t len = str.size();
    size_t i = 0;
    while (true) {
        size_t j = i;
        while (j < len && str[j] == ' ') j++;
        if (j == len) break;
        size_t k = str.find_first_of(':', j);
        if (k == string::npos) {
            return false;  // error: junk after end
        }
        CssTag tag = parseTag(str, j, k - j);
#ifdef VERBOSE
        printf("parseTag result %d, ijk %lu %lu %lu\n", tag, i, j, k);
#endif
        if (tag == unknown) return false; // error: unknown tag
        k++;  // skip over colon
        while (k < len && str[k] == ' ') k++;
        if (k == len) return false; // error: missing value
        CssValue v;
        if (!parseValue(str, &k, len, tag, &v)) break;
#ifdef VERBOSE
        printf("parseValue ok\n");
#endif
        mMap.insert(pair<CssTag, CssValue>(tag, v));
        while (k < len && str[k] == ' ') k++;
        if (k < len) {
            if (str[k] != ';') return false;
            k++;
        }
        i = k;
    }
    return true;
}

bool CssProperties::hasTag(CssTag tag) const {
    return (mMap.find(tag) != mMap.end());
}

CssValue CssProperties::value(CssTag tag) const {
    map<CssTag, CssValue>::const_iterator it = mMap.find(tag);
    if (it == mMap.end()) {
        CssValue unknown;
        return unknown;
    } else {
        return it->second;
    }
}

string CssProperties::toString() const {
    string result;
    for (map<CssTag, CssValue>::const_iterator it = mMap.begin();
        it != mMap.end(); it++) {
        result += cssTagNames[it->first];
        result += ": ";
        result += it->second.toString(it->first);
        result += ";\n";
    }
    return result;
}

}  // namespace android
