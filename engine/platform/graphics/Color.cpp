/*
 * Copyright (C) 2003, 2004, 2005, 2006, 2008 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/graphics/Color.h"

#include "platform/Decimal.h"
#include "wtf/Assertions.h"
#include "wtf/HexNumber.h"
#include "wtf/MathExtras.h"
#include "wtf/dtoa.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

#if !COMPILER(MSVC)
// FIXME: Use C++11 strong enums to avoid static data member with initializer definition problems.
const RGBA32 Color::black;
const RGBA32 Color::white;
const RGBA32 Color::darkGray;
const RGBA32 Color::gray;
const RGBA32 Color::lightGray;
const RGBA32 Color::transparent;
#endif

static const RGBA32 lightenedBlack = 0xFF545454;
static const RGBA32 darkenedWhite = 0xFFABABAB;

RGBA32 makeRGB(int r, int g, int b)
{
    return 0xFF000000 | std::max(0, std::min(r, 255)) << 16 | std::max(0, std::min(g, 255)) << 8 | std::max(0, std::min(b, 255));
}

RGBA32 makeRGBA(int r, int g, int b, int a)
{
    return std::max(0, std::min(a, 255)) << 24 | std::max(0, std::min(r, 255)) << 16 | std::max(0, std::min(g, 255)) << 8 | std::max(0, std::min(b, 255));
}

static int colorFloatToRGBAByte(float f)
{
    // We use lroundf and 255 instead of nextafterf(256, 0) to match CG's rounding
    return std::max(0, std::min(static_cast<int>(lroundf(255.0f * f)), 255));
}

RGBA32 makeRGBA32FromFloats(float r, float g, float b, float a)
{
    return colorFloatToRGBAByte(a) << 24 | colorFloatToRGBAByte(r) << 16 | colorFloatToRGBAByte(g) << 8 | colorFloatToRGBAByte(b);
}

RGBA32 colorWithOverrideAlpha(RGBA32 color, float overrideAlpha)
{
    RGBA32 rgbOnly = color & 0x00FFFFFF;
    RGBA32 rgba = rgbOnly | colorFloatToRGBAByte(overrideAlpha) << 24;
    return rgba;
}

static double calcHue(double temp1, double temp2, double hueVal)
{
    if (hueVal < 0.0)
        hueVal++;
    else if (hueVal > 1.0)
        hueVal--;
    if (hueVal * 6.0 < 1.0)
        return temp1 + (temp2 - temp1) * hueVal * 6.0;
    if (hueVal * 2.0 < 1.0)
        return temp2;
    if (hueVal * 3.0 < 2.0)
        return temp1 + (temp2 - temp1) * (2.0 / 3.0 - hueVal) * 6.0;
    return temp1;
}

// Explanation of this algorithm can be found in the CSS3 Color Module
// specification at http://www.w3.org/TR/css3-color/#hsl-color with further
// explanation available at http://en.wikipedia.org/wiki/HSL_color_space

// all values are in the range of 0 to 1.0
RGBA32 makeRGBAFromHSLA(double hue, double saturation, double lightness, double alpha)
{
    const double scaleFactor = nextafter(256.0, 0.0);

    if (!saturation) {
        int greyValue = static_cast<int>(lightness * scaleFactor);
        return makeRGBA(greyValue, greyValue, greyValue, static_cast<int>(alpha * scaleFactor));
    }

    double temp2 = lightness < 0.5 ? lightness * (1.0 + saturation) : lightness + saturation - lightness * saturation;
    double temp1 = 2.0 * lightness - temp2;

    return makeRGBA(static_cast<int>(calcHue(temp1, temp2, hue + 1.0 / 3.0) * scaleFactor),
                    static_cast<int>(calcHue(temp1, temp2, hue) * scaleFactor),
                    static_cast<int>(calcHue(temp1, temp2, hue - 1.0 / 3.0) * scaleFactor),
                    static_cast<int>(alpha * scaleFactor));
}

RGBA32 makeRGBAFromCMYKA(float c, float m, float y, float k, float a)
{
    double colors = 1 - k;
    int r = static_cast<int>(nextafter(256, 0) * (colors * (1 - c)));
    int g = static_cast<int>(nextafter(256, 0) * (colors * (1 - m)));
    int b = static_cast<int>(nextafter(256, 0) * (colors * (1 - y)));
    return makeRGBA(r, g, b, static_cast<float>(nextafter(256, 0) * a));
}

// originally moved here from the CSS parser
template <typename CharacterType>
static inline bool parseHexColorInternal(const CharacterType* name, unsigned length, RGBA32& rgb)
{
    if (length != 3 && length != 6)
        return false;
    unsigned value = 0;
    for (unsigned i = 0; i < length; ++i) {
        if (!isASCIIHexDigit(name[i]))
            return false;
        value <<= 4;
        value |= toASCIIHexValue(name[i]);
    }
    if (length == 6) {
        rgb = 0xFF000000 | value;
        return true;
    }
    // #abc converts to #aabbcc
    rgb = 0xFF000000
        | (value & 0xF00) << 12 | (value & 0xF00) << 8
        | (value & 0xF0) << 8 | (value & 0xF0) << 4
        | (value & 0xF) << 4 | (value & 0xF);
    return true;
}

bool Color::parseHexColor(const LChar* name, unsigned length, RGBA32& rgb)
{
    return parseHexColorInternal(name, length, rgb);
}

bool Color::parseHexColor(const UChar* name, unsigned length, RGBA32& rgb)
{
    return parseHexColorInternal(name, length, rgb);
}

bool Color::parseHexColor(const String& name, RGBA32& rgb)
{
    unsigned length = name.length();

    if (!length)
        return false;
    if (name.is8Bit())
        return parseHexColor(name.characters8(), name.length(), rgb);
    return parseHexColor(name.characters16(), name.length(), rgb);
}

int differenceSquared(const Color& c1, const Color& c2)
{
    int dR = c1.red() - c2.red();
    int dG = c1.green() - c2.green();
    int dB = c1.blue() - c2.blue();
    return dR * dR + dG * dG + dB * dB;
}

bool Color::setFromString(const String& name)
{
    if (name[0] != '#')
        return setNamedColor(name);
    if (name.is8Bit())
        return parseHexColor(name.characters8() + 1, name.length() - 1, m_color);
    return parseHexColor(name.characters16() + 1, name.length() - 1, m_color);
}

String Color::serializedAsCSSComponentValue() const
{
    StringBuilder result;
    result.reserveCapacity(32);
    bool colorHasAlpha = hasAlpha();
    if (colorHasAlpha)
        result.appendLiteral("rgba(");
    else
        result.appendLiteral("rgb(");

    result.appendNumber(static_cast<unsigned char>(red()));
    result.appendLiteral(", ");

    result.appendNumber(static_cast<unsigned char>(green()));
    result.appendLiteral(", ");

    result.appendNumber(static_cast<unsigned char>(blue()));
    if (colorHasAlpha) {
        result.appendLiteral(", ");

        NumberToStringBuffer buffer;
        const char* alphaString = numberToFixedPrecisionString(alpha() / 255.0f, 6, buffer, true);
        result.append(alphaString, strlen(alphaString));
    }

    result.append(')');
    return result.toString();
}

String Color::serialized() const
{
    if (!hasAlpha()) {
        StringBuilder builder;
        builder.reserveCapacity(7);
        builder.append('#');
        appendByteAsHex(red(), builder, Lowercase);
        appendByteAsHex(green(), builder, Lowercase);
        appendByteAsHex(blue(), builder, Lowercase);
        return builder.toString();
    }

    StringBuilder result;
    result.reserveCapacity(28);

    result.appendLiteral("rgba(");
    result.appendNumber(red());
    result.appendLiteral(", ");
    result.appendNumber(green());
    result.appendLiteral(", ");
    result.appendNumber(blue());
    result.appendLiteral(", ");

    if (!alpha())
        result.append('0');
    else {
        result.append(Decimal::fromDouble(alpha() / 255.0).toString());
    }

    result.append(')');
    return result.toString();
}

String Color::nameForRenderTreeAsText() const
{
    if (alpha() < 0xFF)
        return String::format("#%02X%02X%02X%02X", red(), green(), blue(), alpha());
    return String::format("#%02X%02X%02X", red(), green(), blue());
}

static inline const NamedColor* findNamedColor(const String& name)
{
    char buffer[64]; // easily big enough for the longest color name
    unsigned length = name.length();
    if (length > sizeof(buffer) - 1)
        return 0;
    for (unsigned i = 0; i < length; ++i) {
        UChar c = name[i];
        if (!c || c > 0x7F)
            return 0;
        buffer[i] = toASCIILower(static_cast<char>(c));
    }
    buffer[length] = '\0';
    return findColor(buffer, length);
}

bool Color::setNamedColor(const String& name)
{
    const NamedColor* foundColor = findNamedColor(name);
    m_color = foundColor ? foundColor->ARGBValue : 0;
    return foundColor;
}

Color Color::light() const
{
    // Hardcode this common case for speed.
    if (m_color == black)
        return lightenedBlack;

    const float scaleFactor = nextafterf(256.0f, 0.0f);

    float r, g, b, a;
    getRGBA(r, g, b, a);

    float v = std::max(r, std::max(g, b));

    if (v == 0.0f)
        // Lightened black with alpha.
        return Color(0x54, 0x54, 0x54, alpha());

    float multiplier = std::min(1.0f, v + 0.33f) / v;

    return Color(static_cast<int>(multiplier * r * scaleFactor),
                 static_cast<int>(multiplier * g * scaleFactor),
                 static_cast<int>(multiplier * b * scaleFactor),
                 alpha());
}

Color Color::dark() const
{
    // Hardcode this common case for speed.
    if (m_color == white)
        return darkenedWhite;

    const float scaleFactor = nextafterf(256.0f, 0.0f);

    float r, g, b, a;
    getRGBA(r, g, b, a);

    float v = std::max(r, std::max(g, b));
    float multiplier = std::max(0.0f, (v - 0.33f) / v);

    return Color(static_cast<int>(multiplier * r * scaleFactor),
                 static_cast<int>(multiplier * g * scaleFactor),
                 static_cast<int>(multiplier * b * scaleFactor),
                 alpha());
}

Color Color::combineWithAlpha(float otherAlpha) const
{
    return colorWithOverrideAlpha(rgb(), (alpha() / 255.f) * otherAlpha);
}

static int blendComponent(int c, int a)
{
    // We use white.
    float alpha = a / 255.0f;
    int whiteBlend = 255 - a;
    c -= whiteBlend;
    return static_cast<int>(c / alpha);
}

const int cStartAlpha = 153; // 60%
const int cEndAlpha = 204; // 80%;
const int cAlphaIncrement = 17; // Increments in between.

Color Color::blend(const Color& source) const
{
    if (!alpha() || !source.hasAlpha())
        return source;

    if (!source.alpha())
        return *this;

    int d = 255 * (alpha() + source.alpha()) - alpha() * source.alpha();
    int a = d / 255;
    int r = (red() * alpha() * (255 - source.alpha()) + 255 * source.alpha() * source.red()) / d;
    int g = (green() * alpha() * (255 - source.alpha()) + 255 * source.alpha() * source.green()) / d;
    int b = (blue() * alpha() * (255 - source.alpha()) + 255 * source.alpha() * source.blue()) / d;
    return Color(r, g, b, a);
}

Color Color::blendWithWhite() const
{
    // If the color contains alpha already, we leave it alone.
    if (hasAlpha())
        return *this;

    Color newColor;
    for (int alpha = cStartAlpha; alpha <= cEndAlpha; alpha += cAlphaIncrement) {
        // We have a solid color.  Convert to an equivalent color that looks the same when blended with white
        // at the current alpha.  Try using less transparency if the numbers end up being negative.
        int r = blendComponent(red(), alpha);
        int g = blendComponent(green(), alpha);
        int b = blendComponent(blue(), alpha);

        newColor = Color(r, g, b, alpha);

        if (r >= 0 && g >= 0 && b >= 0)
            break;
    }
    return newColor;
}

void Color::getRGBA(float& r, float& g, float& b, float& a) const
{
    r = red() / 255.0f;
    g = green() / 255.0f;
    b = blue() / 255.0f;
    a = alpha() / 255.0f;
}

void Color::getRGBA(double& r, double& g, double& b, double& a) const
{
    r = red() / 255.0;
    g = green() / 255.0;
    b = blue() / 255.0;
    a = alpha() / 255.0;
}

void Color::getHSL(double& hue, double& saturation, double& lightness) const
{
    // http://en.wikipedia.org/wiki/HSL_color_space. This is a direct copy of
    // the algorithm therein, although it's 360^o based and we end up wanting
    // [0...1) based. It's clearer if we stick to 360^o until the end.
    double r = static_cast<double>(red()) / 255.0;
    double g = static_cast<double>(green()) / 255.0;
    double b = static_cast<double>(blue()) / 255.0;
    double max = std::max(std::max(r, g), b);
    double min = std::min(std::min(r, g), b);

    if (max == min)
        hue = 0.0;
    else if (max == r)
        hue = (60.0 * ((g - b) / (max - min))) + 360.0;
    else if (max == g)
        hue = (60.0 * ((b - r) / (max - min))) + 120.0;
    else
        hue = (60.0 * ((r - g) / (max - min))) + 240.0;

    if (hue >= 360.0)
        hue -= 360.0;

    // makeRGBAFromHSLA assumes that hue is in [0...1).
    hue /= 360.0;

    lightness = 0.5 * (max + min);
    if (max == min)
        saturation = 0.0;
    else if (lightness <= 0.5)
        saturation = ((max - min) / (max + min));
    else
        saturation = ((max - min) / (2.0 - (max + min)));
}

Color colorFromPremultipliedARGB(RGBA32 pixelColor)
{
    int alpha = alphaChannel(pixelColor);
    if (alpha && alpha < 255) {
        return Color::createUnchecked(
            redChannel(pixelColor) * 255 / alpha,
            greenChannel(pixelColor) * 255 / alpha,
            blueChannel(pixelColor) * 255 / alpha,
            alpha);
    } else
        return Color(pixelColor);
}

RGBA32 premultipliedARGBFromColor(const Color& color)
{
    unsigned pixelColor;

    unsigned alpha = color.alpha();
    if (alpha < 255) {
        pixelColor = Color::createUnchecked(
            (color.red() * alpha  + 254) / 255,
            (color.green() * alpha  + 254) / 255,
            (color.blue() * alpha  + 254) / 255,
            alpha).rgb();
    } else
         pixelColor = color.rgb();

    return pixelColor;
}

} // namespace blink
