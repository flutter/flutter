import 'package:hooks/hooks.dart';

class FontAsset {
  FontAsset({required this.file, required this.name, required this.package});
  factory FontAsset.fromEncoded(EncodedAsset encodedAsset) {
    final Map<String, Object?> encoding = encodedAsset.encoding;
    return FontAsset(
      file: Uri.parse(encoding[_fileKey]! as String),
      name: encoding[_nameKey]! as String,
      package: encoding[_packageKey]! as String,
    );
  }

  final Uri file;
  final String name;
  final String package;

  static const _fileKey = 'file';
  static const _nameKey = 'name';
  static const _packageKey = 'package';
  static const _type = 'font_asset';

  EncodedAsset encode() {
    return EncodedAsset(_type, {
      _fileKey: file.toFilePath(windows: false),
      _nameKey: name,
      _packageKey: package,
    });
  }
}

extension FontAssetExt on EncodedAsset {
  bool get isFontAsset => type == FontAsset._type;
}
