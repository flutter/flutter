# font_asset_package

A package that provides an icon font (`HookIcons`) through its build hook with
`package:font_asset`, and exposes `HookIcons.add` for it, like an icon font
package would. The hook generates the font file into its output directory from
the base64 data in `lib/src/font_data.dart`, because this repository does not
contain binary files. It is used as a dependency in the `font_assets`
integration test.
