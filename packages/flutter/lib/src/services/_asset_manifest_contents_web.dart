import 'dart:js' as js;

/// The contents of the asset manifest generated at build time.
///
/// For most web apps, the generated entry point code includes code that writes
/// the asset manifest's contents to a JS global as a base64-encoded string.
/// This implementation reads that global.
final String? assetManifestContents =
  js.context['_flutter_base64EncodedAssetManifest'] as String?;
