Flutter tests run via the `flutter test` command have access to several readily available test fonts, including [FlutterTest](#the-fluttertest-test-font) and [Ahem](https://www.w3.org/Style/CSS/Test/Fonts/Ahem/).

In tests, if [`fontFamily`](https://master-api.flutter.dev/flutter/painting/TextStyle/fontFamily.html) isn't specified or the specified font families are not available, the default test font `FlutterTest` will be used.
If you wish to use a custom font in tests, check out the [`FontLoader`](https://master-api.flutter.dev/flutter/services/FontLoader-class.html) class, and [this example](https://github.com/flutter/flutter/blob/6ec444506375cfa94535a45c2320e01094c295e0/packages/flutter/test/material/icons_test.dart#L149-L172).

## The `FlutterTest` test font

### Font Metrics (in design units)

| | Ascent | Descent | Line Gap (Leading) | Units Per EM | Underline Position |
| :-- | :---: | :---: | :---: | :---: | :---: |
| `FlutterTest` | 768 (0.75 em) above the baseline | 256 (0.25 em) below the baseline | 0 | 1024 | 146 under the baseline |
| `Ahem` | 800 (0.8 em) above the baseline | 200 (0.2 em) below the baseline | 0 | 1000 | 142 under the baseline |

The `FlutterTest` font's `1024 units-per-em` is a power of 2, making it less likely to introduce precision loss in metrics calculations, when used as a divisor.
Thanks to that, the `FlutterTest` font generally provides more precise and font-engine-agnostic font/glyph metrics than `Ahem`.

**Example**

You can expect this test to pass on all platforms (currently with the exception of the web HTML renderer):

```dart
final painter = TextPainter(
  text: const TextSpan(
    text: 'text',
    style: TextStyle(fontSize: 14.0, /* "fontFamily: 'FlutterTest'" is implied */),
  ),
  textDirection: TextDirection.ltr,
  textScaleFactor: 1.0,
);
final lineMetrics = textPainer.computeLineMetrics().first;

expect(lineMetrics.height, 14.0);
expect(lineMetrics.ascent, 10.5); // 0.75em * 14.0pt
expect(lineMetrics.descent, 3.5); // 0.25em * 14.0pt
// 'text' is 4 glyphs. Most glyphs are as wide as they are tall.
expect(lineMetrics.width, 14.0 * 4);
```

While with the `Ahem` font you would get [slightly different metrics on different platforms](https://github.com/flutter/flutter/issues/62819), since they use different font engines to scale the font.

### Glyphs

(images to be added)

The font covers most types of glyphs defined in the `Ahem` font.

| Square | Ascent Flushed | Descent Flushed | .notdef |
 | :---:  | :----:  | :----:  | :----:  |
| a box that fills the em square | the **Square** glyph but without the part above the baseline | the **Square** glyph but without the part below the baseline | a hollow box |

The remaining glyphs (for example, **Full Advance**, **1/2 Advance**) are defined with no outlines in the glyph, with different x-advances.


### Glyph Mapping

Unmapped codepoints will be mapped to the **.notdef** glyph in the test environment.

|     \ Script <br />Glyph | DFLT | grek | hani | latn |
 | :---  | :----:  | :----:  | :----:  | :----: |
| Square | **codepoint(s):** 0x21-0x26, 0x28-0x40, 0x5b-0x60, 0x7b-0x7e, 0xa1-0xa9, 0xab-0xb9, 0xbb-0xbf, 0xd7, 0xf7, 0x2c6-0x2c7, 0x2c9, 0x2d8-0x2dd, 0x2013-0x2014, 0x2018-0x201a, 0x201c-0x201e, 0x2020-0x2022, 0x2026, 0x2030, 0x2039-0x203a, 0x2044, 0x2122, 0x2202, 0x2206, 0x220f, 0x2211-0x2212, 0x2219-0x221a, 0x221e, 0x222b, 0x2248, 0x2260, 0x2264-0x2265, 0x22f2, 0x25ca, 0xf000-0xf002<br />**character(s):** `!` `"` `#` `$` `%` `&` `(` `)` `*` `+` `,` `-` `.` `/` `0` `1` `2` `3` `4` `5` `6` `7` `8` `9` `:` `;` `<` `=` `>` `?` `@` `[` `\` `]` `^` `_` `` ` `` `{` `\|` `}` `~` `¡` `¢` `£` `¤` `¥` `¦` `§` `¨` `©` `«` `¬` `<SOFT HYPHEN>` `®` `¯` `°` `±` `²` `³` `´` `µ` `¶` `·` `¸` `¹` `»` `¼` `½` `¾` `¿` `×` `÷` `ˆ` `ˇ` `ˉ` `˘` `˙` `˚` `˛` `˜` `˝` `–` `—` `‘` `’` `‚` `“` `”` `„` `†` `‡` `•` `…` `‰` `‹` `›` `⁄` `™` `∂` `∆` `∏` `∑` `−` `∙` `√` `∞` `∫` `≈` `≠` `≤` `≥` `⋲` `◊` `<0xf000>` `<0xf001>` `<0xf002>` | **codepoint(s):** 0x394, 0x3a5, 0x3a7, 0x3a9, 0x3bc, 0x3c0, 0x2126<br />**character(s):** `Δ` `Υ` `Χ` `Ω` `μ` `π` `Ω` | **codepoint(s):** 0x3007, 0x4e00, 0x4e03, 0x4e09, 0x4e2d, 0x4e5d, 0x4e8c, 0x4e94, 0x516b, 0x516d, 0x5341, 0x5426, 0x56d7, 0x56db, 0x571f, 0x6587, 0x6587, 0x662f, 0x6728, 0x672c, 0x6b63, 0x6c34, 0x6d4b, 0x706b, 0x786e, 0x8bd5, 0x91d1<br />**character(s):** `〇` `一` `七` `三` `中` `九` `二` `五` `八` `六` `十` `否` `囗` `四` `土` `文` `文` `是` `木` `本` `正` `水` `测` `火` `确` `试` `金` | **codepoint(s):** 0x41-0x5a, 0x61-0x7a, 0xaa, 0xba, 0xc0-0xc8, 0xca-0xd6, 0xd8-0xf6, 0xf8-0xff, 0x131, 0x152-0x153, 0x178, 0x192<br />**character(s):** `A` `B` `C` `D` `E` `F` `G` `H` `I` `J` `K` `L` `M` `N` `O` `P` `Q` `R` `S` `T` `U` `V` `W` `X` `Y` `Z` `a` `b` `c` `d` `e` `f` `g` `h` `i` `j` `k` `l` `m` `n` `o` `p` `q` `r` `s` `t` `u` `v` `w` `x` `y` `z` `ª` `º` `À` `Á` `Â` `Ã` `Ä` `Å` `Æ` `Ç` `È` `Ê` `Ë` `Ì` `Í` `Î` `Ï` `Ð` `Ñ` `Ò` `Ó` `Ô` `Õ` `Ö` `Ø` `Ù` `Ú` `Û` `Ü` `Ý` `Þ` `ß` `à` `á` `â` `ã` `ä` `å` `æ` `ç` `è` `é` `ê` `ë` `ì` `í` `î` `ï` `ð` `ñ` `ò` `ó` `ô` `õ` `ö` `ø` `ù` `ú` `û` `ü` `ý` `þ` `ÿ` `ı` `Œ` `œ` `Ÿ` `ƒ` |
| Ascent Flushed |  |  |  | **codepoint(s):** 0x70<br />**character(s):** `p` |
| Descent Flushed |  |  |  | **codepoint(s):** 0xc9<br />**character(s):** `É` |
| Full Advance | **codepoint(s):** 0x20<br />**character(s):** `<SPACE>` |  |  |  |
| 1/2 Advance | **codepoint(s):** 0x2002<br />**character(s):** `<EN SPACE>` |  |  |  |
| 1/3 Advance | **codepoint(s):** 0x2004<br />**character(s):** `<THREE-PER-EM SPACE>` |  |  |  |
| 1/4 Advance | **codepoint(s):** 0x2005<br />**character(s):** `<FOUR-PER-EM SPACE>` |  |  |  |
| 1/6 Advance | **codepoint(s):** 0x2006<br />**character(s):** `<SIX-PER-EM SPACE>` |  |  |  |
| 1/5 Advance | **codepoint(s):** 0x2009<br />**character(s):** `<THIN SPACE>` |  |  |  |
| 1/10 Advance | **codepoint(s):** 0x200a<br />**character(s):** `<HAIR SPACE>` |  |  |  |
| Zero Advance | **codepoint(s):** 0xfeff<br />**character(s):** `<ZERO WIDTH NO-BREAK SPACE>` |  |  |  |

### Caveats

To disable FreeType auto-hinter, the family name defined within the font is not `FlutterTest` but `MingLiU`. This typically doesn't affect framework tests as the font is registered under the name `FlutterTest`.

### Adding more Codepoints/Glyphs to the `FlutterTest` Font

The `FlutterTest` font is generated by [this script](https://github.com/flutter/engine/blob/170cbea/tools/gen_test_font.py).
