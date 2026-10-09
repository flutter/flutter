# font_asset_package

A package that provides an icon font (`HookIcons`) through its build hook with
`package:font_asset`, and exposes `HookIcons.add` for it. The font file comes
from the Flutter SDK cache because this repository does not contain binaries.
It is used as a dependency in the `font_assets` integration test.
