import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/src/google_fonts_family_with_variant.dart';
import 'package:google_fonts/src/google_fonts_variant.dart';

void main() {
  testWidgets('toString() works for normal w400', (tester) async {
    const familyWithVariant = GoogleFontsFamilyWithVariant(
      family: 'Foo',
      googleFontsVariant: GoogleFontsVariant(
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w400,
      ),
    );

    expect(familyWithVariant.toString(), equals('Foo_regular'));
  });

  testWidgets('toString() works for italic w100', (tester) async {
    const familyWithVariant = GoogleFontsFamilyWithVariant(
      family: 'Foo',
      googleFontsVariant: GoogleFontsVariant(
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w100,
      ),
    );

    expect(familyWithVariant.toString(), equals('Foo_100italic'));
  });

  testWidgets('toApiFilenamePrefix() works for italic w100', (tester) async {
    const familyWithVariant = GoogleFontsFamilyWithVariant(
      family: 'Foo',
      googleFontsVariant: GoogleFontsVariant(
        fontWeight: FontWeight.w100,
        fontStyle: FontStyle.italic,
      ),
    );

    expect(familyWithVariant.toApiFilenamePrefix(), equals('Foo-ThinItalic'));
  });

  testWidgets('toApiFilenamePrefix() works for regular', (tester) async {
    const familyWithVariant = GoogleFontsFamilyWithVariant(
      family: 'Foo',
      googleFontsVariant: GoogleFontsVariant(
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.normal,
      ),
    );

    expect(familyWithVariant.toApiFilenamePrefix(), equals('Foo-Regular'));
  });
}
