## Updating the fonts

If you notice fonts that are on [fonts.google.com](https://fonts.google.com) that do not appear in
this package, it means that the generator needs to be run. The generator will
check [fonts.google.com](https://fonts.google.com) for any new fonts, manually test each URL, and
regenerate the dart code.

The generator is run multiple times a month by a GitHub [workflow](https://github.com/material-foundation/flutter-packages/blob/main/.github/workflows/google_fonts_update.yml).

To run it manually, run `dart generator/generator.dart`.
