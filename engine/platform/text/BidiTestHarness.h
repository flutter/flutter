/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef BidiTestHarness_h
#define BidiTestHarness_h

#include <istream>
#include <map>
#include <stdio.h>
#include <string>
#include <vector>

// FIXME: We don't have any business owning this code. We should try to
// upstream this to unicode.org if possible (for other implementations to use).
// Unicode.org provides a reference implmentation, including parser:
// http://www.unicode.org/Public/PROGRAMS/BidiReferenceC/6.3.0/source/brtest.c
// But it, like the other implementations I've found, is rather tied to
// the algorithms it is testing. This file seeks to only implement the parser bits.

// Other C/C++ implementations of this parser:
// https://github.com/googlei18n/fribidi-vs-unicode/blob/master/test.c
// http://source.icu-project.org/repos/icu/icu/trunk/source/test/intltest/bidiconf.cpp
// Both of those are too tied to their respective projects to be use to Blink.

// There are non-C implmentations to parse BidiTest.txt as well, including:
// https://github.com/twitter/twitter-cldr-rb/blob/master/spec/bidi/bidi_spec.rb

// NOTE: None of this file is currently written to be thread-safe.

namespace bidi_test {

enum ParagraphDirection {
    DirectionAutoLTR = 1,
    DirectionLTR = 2,
    DirectionRTL = 4,
};
const int kMaxParagraphDirection = DirectionAutoLTR | DirectionLTR | DirectionRTL;

// For error printing:
std::string nameFromParagraphDirection(ParagraphDirection paragraphDirection)
{
    switch (paragraphDirection) {
    case bidi_test::DirectionAutoLTR:
        return "Auto-LTR";
    case bidi_test::DirectionLTR:
        return "LTR";
    case bidi_test::DirectionRTL:
        return "RTL";
    }
    // This should never be reached.
    return "";
}

template<class Runner>
class Harness {
public:
    Harness(Runner& runner)
        : m_runner(runner)
    {
    }
    void parse(std::istream& bidiTestFile);

private:
    Runner& m_runner;
};

// We could use boost::trim, but no other part of Blink uses boost yet.
inline void ltrim(std::string& s)
{
    static const std::string separators(" \t");
    s.erase(0, s.find_first_not_of(separators));
}

inline void rtrim(std::string& s)
{
    static const std::string separators(" \t");
    size_t lastNonSpace = s.find_last_not_of(separators);
    if (lastNonSpace == std::string::npos) {
        s.erase();
        return;
    }
    size_t firstSpaceAtEndOfString = lastNonSpace + 1;
    if (firstSpaceAtEndOfString >= s.size())
        return; // lastNonSpace was the last char.
    s.erase(firstSpaceAtEndOfString, std::string::npos); // erase to the end of the string.
}

inline void trim(std::string& s)
{
    rtrim(s);
    ltrim(s);
}

static std::vector<std::string> parseStringList(const std::string& str)
{
    std::vector<std::string> strings;
    static const std::string separators(" \t");
    size_t lastPos = str.find_first_not_of(separators); // skip leading spaces
    size_t pos = str.find_first_of(separators, lastPos); // find next space

    while (std::string::npos != pos || std::string::npos != lastPos) {
        strings.push_back(str.substr(lastPos, pos - lastPos));
        lastPos = str.find_first_not_of(separators, pos);
        pos = str.find_first_of(separators, lastPos);
    }
    return strings;
}

static std::vector<int> parseIntList(const std::string& str)
{
    std::vector<int> ints;
    std::vector<std::string> strings = parseStringList(str);
    for (size_t x = 0; x < strings.size(); x++) {
        int i = atoi(strings[x].c_str());
        ints.push_back(i);
    }
    return ints;
}

static std::vector<int> parseLevels(const std::string& line)
{
    std::vector<int> levels;
    std::vector<std::string> strings = parseStringList(line);
    for (size_t x = 0; x < strings.size(); x++) {
        const std::string& levelString = strings[x];
        int i;
        if (levelString == "x")
            i = -1;
        else
            i = atoi(levelString.c_str());
        levels.push_back(i);
    }
    return levels;
}

// This is not thread-safe as written.
static std::basic_string<UChar> parseTestString(const std::string& line)
{
    std::basic_string<UChar> testString;
    static std::map<std::string, UChar> charClassExamples;
    if (charClassExamples.empty()) {
        // FIXME: Explicit make_pair is ugly, but required for C++98 compat.
        charClassExamples.insert(std::make_pair("L", 0x6c)); // 'l' for L
        charClassExamples.insert(std::make_pair("R", 0x05D0)); // HEBREW ALEF
        charClassExamples.insert(std::make_pair("EN", 0x33)); // '3' for EN
        charClassExamples.insert(std::make_pair("ES", 0x2d)); // '-' for ES
        charClassExamples.insert(std::make_pair("ET", 0x25)); // '%' for ET
        charClassExamples.insert(std::make_pair("AN", 0x0660)); // arabic 0
        charClassExamples.insert(std::make_pair("CS", 0x2c)); // ',' for CS
        charClassExamples.insert(std::make_pair("B", 0x0A)); // <control-000A>
        charClassExamples.insert(std::make_pair("S", 0x09)); // <control-0009>
        charClassExamples.insert(std::make_pair("WS", 0x20)); // ' ' for WS
        charClassExamples.insert(std::make_pair("ON", 0x3d)); // '=' for ON
        charClassExamples.insert(std::make_pair("NSM", 0x05BF)); // HEBREW POINT RAFE
        charClassExamples.insert(std::make_pair("AL", 0x0608)); // ARABIC RAY
        charClassExamples.insert(std::make_pair("BN", 0x00AD)); // SOFT HYPHEN
        charClassExamples.insert(std::make_pair("LRE", 0x202A));
        charClassExamples.insert(std::make_pair("RLE", 0x202B));
        charClassExamples.insert(std::make_pair("PDF", 0x202C));
        charClassExamples.insert(std::make_pair("LRO", 0x202D));
        charClassExamples.insert(std::make_pair("RLO", 0x202E));
        charClassExamples.insert(std::make_pair("LRI", 0x2066));
        charClassExamples.insert(std::make_pair("RLI", 0x2067));
        charClassExamples.insert(std::make_pair("FSI", 0x2068));
        charClassExamples.insert(std::make_pair("PDI", 0x2069));
    }

    std::vector<std::string> charClasses = parseStringList(line);
    for (size_t i = 0; i < charClasses.size(); i++) {
        // FIXME: If the lookup failed we could return false for a parse error.
        testString.push_back(charClassExamples.find(charClasses[i])->second);
    }
    return testString;
}

static bool parseParagraphDirectionMask(const std::string& line, int& modeMask)
{
    modeMask = atoi(line.c_str());
    return modeMask >= 1 && modeMask <= kMaxParagraphDirection;
}

static void parseError(const std::string& line, size_t lineNumber)
{
    // Use printf to avoid the expense of std::cout.
    printf("Parse error, line %zu : %s\n", lineNumber, line.c_str());
}

template<class Runner>
void Harness<Runner>::parse(std::istream& bidiTestFile)
{
    static const std::string levelsPrefix("@Levels");
    static const std::string reorderPrefix("@Reorder");

    // FIXME: UChar is an ICU type and cheating a bit to use here.
    // uint16_t might be more portable.
    std::basic_string<UChar> testString;
    std::vector<int> levels;
    std::vector<int> reorder;
    int paragraphDirectionMask;

    std::string line;
    size_t lineNumber = 0;
    while (std::getline(bidiTestFile, line)) {
        lineNumber++;
        const std::string originalLine = line;
        size_t commentStart = line.find_first_of('#');
        if (commentStart != std::string::npos)
            line = line.substr(0, commentStart);
        trim(line);
        if (line.empty())
            continue;
        if (line[0] == '@') {
            if (!line.find(levelsPrefix)) {
                levels = parseLevels(line.substr(levelsPrefix.length() + 1));
                continue;
            }
            if (!line.find(reorderPrefix)) {
                reorder = parseIntList(line.substr(reorderPrefix.length() + 1));
                continue;
            }
        } else {
            // Assume it's a data line.
            size_t seperatorIndex = line.find_first_of(';');
            if (seperatorIndex == std::string::npos) {
                parseError(originalLine, lineNumber);
                continue;
            }
            testString = parseTestString(line.substr(0, seperatorIndex));
            if (!parseParagraphDirectionMask(line.substr(seperatorIndex + 1), paragraphDirectionMask)) {
                parseError(originalLine, lineNumber);
                continue;
            }

            if (paragraphDirectionMask & DirectionAutoLTR)
                m_runner.runTest(testString, reorder, levels, DirectionAutoLTR, originalLine, lineNumber);
            if (paragraphDirectionMask & DirectionLTR)
                m_runner.runTest(testString, reorder, levels, DirectionLTR, originalLine, lineNumber);
            if (paragraphDirectionMask & DirectionRTL)
                m_runner.runTest(testString, reorder, levels, DirectionRTL, originalLine, lineNumber);
        }
    }
}

} // namespace bidi_test

#endif // BidiTestHarness_h
