import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/src/google_fonts_variant.dart';

void main() {
  testWidgets('toString() works for normal w400', (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
    );

    expect(variant.toString(), equals('regular'));
  });

  testWidgets('toString() works for italic w400', (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
    );

    expect(variant.toString(), equals('italic'));
  });

  testWidgets('toString() works for normal w500', (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.normal,
    );

    expect(variant.toString(), equals('500'));
  });

  testWidgets('toString() works for italic w500', (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
    );

    expect(variant.toString(), equals('500italic'));
  });

  testWidgets('fromString() works for regular', (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
    );

    expect(GoogleFontsVariant.fromString('regular'), equals(variant));
  });

  testWidgets('fromString() works for italic', (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
    );

    expect(GoogleFontsVariant.fromString('italic'), equals(variant));
  });

  testWidgets('fromString() works for 500', (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.normal,
    );

    expect(GoogleFontsVariant.fromString('500'), equals(variant));
  });

  testWidgets('fromString() works for 500italic', (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
    );

    expect(GoogleFontsVariant.fromString('500italic'), equals(variant));
  });

  testWidgets('toApiFilenamePart() works for all normal combintaions',
      (tester) async {
    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w100,
        fontStyle: FontStyle.normal,
      ).toApiFilenamePart(),
      equals('Thin'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w200,
        fontStyle: FontStyle.normal,
      ).toApiFilenamePart(),
      equals('ExtraLight'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.normal,
      ).toApiFilenamePart(),
      equals('Light'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.normal,
      ).toApiFilenamePart(),
      equals('Regular'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.normal,
      ).toApiFilenamePart(),
      equals('Medium'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.normal,
      ).toApiFilenamePart(),
      equals('SemiBold'),
    );

    expect(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ).toApiFilenamePart(),
        equals('Bold'));

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.normal,
      ).toApiFilenamePart(),
      equals('ExtraBold'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.normal,
      ).toApiFilenamePart(),
      equals('Black'),
    );
  });

  testWidgets('toApiFilenamePart() works for all italic combintaions',
      (tester) async {
    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w100,
        fontStyle: FontStyle.italic,
      ).toApiFilenamePart(),
      equals('ThinItalic'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w200,
        fontStyle: FontStyle.italic,
      ).toApiFilenamePart(),
      equals('ExtraLightItalic'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.italic,
      ).toApiFilenamePart(),
      equals('LightItalic'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
      ).toApiFilenamePart(),
      equals('Italic'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
      ).toApiFilenamePart(),
      equals('MediumItalic'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
      ).toApiFilenamePart(),
      equals('SemiBoldItalic'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
      ).toApiFilenamePart(),
      equals('BoldItalic'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
      ).toApiFilenamePart(),
      equals('ExtraBoldItalic'),
    );

    expect(
      const GoogleFontsVariant(
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
      ).toApiFilenamePart(),
      equals('BlackItalic'),
    );
  });

  testWidgets('fromApiFilenamePart() works for all normal combintaions',
      (tester) async {
    expect(
      GoogleFontsVariant.fromApiFilenamePart('Thin'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w100,
          fontStyle: FontStyle.normal,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('ExtraLight'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w200,
          fontStyle: FontStyle.normal,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('Light'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.normal,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('Regular'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('Medium'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.normal,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('SemiBold'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.normal,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('Bold'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('ExtraBold'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.normal,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('Black'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.normal,
        ),
      ),
    );
  });

  testWidgets('fromApiFilenamePart() works for all italic combintaions',
      (tester) async {
    expect(
      GoogleFontsVariant.fromApiFilenamePart('ThinItalic'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w100,
          fontStyle: FontStyle.italic,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('ExtraLightItalic'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w200,
          fontStyle: FontStyle.italic,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('LightItalic'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.italic,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('Italic'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('MediumItalic'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('SemiBoldItalic'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('BoldItalic'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('ExtraBoldItalic'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
        ),
      ),
    );

    expect(
      GoogleFontsVariant.fromApiFilenamePart('BlackItalic'),
      equals(
        const GoogleFontsVariant(
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  });

  testWidgets('== works for for identical variants', (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
    );
    const otherVariant = variant;

    expect(variant == otherVariant, isTrue);
  });

  testWidgets('== works for for clone variants', (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
    );
    const otherVariant = GoogleFontsVariant(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
    );
    expect(variant == otherVariant, isTrue);
  });

  testWidgets('== fails for different fontWeights', (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
    );
    const otherVariant = GoogleFontsVariant(
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
    );
    expect(variant == otherVariant, isFalse);
  });

  testWidgets('== fails for different fontStyles', (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
    );
    const otherVariant = GoogleFontsVariant(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.normal,
    );
    expect(variant == otherVariant, isFalse);
  });

  testWidgets('== fails for different fontWeights and different fontStyles',
      (tester) async {
    const variant = GoogleFontsVariant(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
    );
    const otherVariant = GoogleFontsVariant(
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.normal,
    );
    expect(variant == otherVariant, isFalse);
  });
}
