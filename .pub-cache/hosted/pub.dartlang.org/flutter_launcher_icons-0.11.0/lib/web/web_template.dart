/// A Icon Template for Web
class WebIconTemplate {
  /// Size of the web icon
  final int size;

  /// Support for maskable icon
  ///
  /// Refer to https://web.dev/maskable-icon/
  final bool maskable;

  /// Creates an instance of [WebIconTemplate].
  const WebIconTemplate({
    required this.size,
    this.maskable = false,
  });

  /// Icon file name
  String get iconFile => 'Icon${maskable ? '-maskable' : ''}-$size.png';

  /// Icon config for manifest.json
  ///
  /// ```json
  ///  {
  ///         "src": "icons/Icon-maskable-192.png",
  ///         "sizes": "192x192",
  ///         "type": "image/png",
  ///         "purpose": "maskable"
  ///  },
  /// ```
  Map<String, dynamic> get iconManifest {
    return <String, dynamic>{
      'src': 'icons/$iconFile',
      'sizes': '${size}x$size',
      'type': 'image/png',
      if (maskable) 'purpose': 'maskable',
    };
  }
}
