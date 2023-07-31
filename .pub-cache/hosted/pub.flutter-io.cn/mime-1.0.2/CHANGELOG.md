# 1.0.2

* Add audio/x-aiff mimeType lookup by header bytes.
* Add audio/x-flac mimeType lookup by header bytes.
* Add audio/x-wav mimeType lookup by header bytes.
* Add audio/mp4 mimeType lookup by file path.

# 1.0.1

* Add image/webp mimeType lookup by header bytes.

# 1.0.0

* Stable null safety release.

# 1.0.0-nullsafety.0

* Update to null safety.

# 0.9.7

* Add `extensionFromMime` utility function.

# 0.9.6+3

* Change the mime type for Dart source from `application/dart` to `text/x-dart`.
* Add example.
* Fix links and code in README.

# 0.9.6+2

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

# 0.9.6+1

* Stop using deprecated constants from the SDK.

# 0.9.6

* Updates to support Dart 2.0 core library changes (wave
  2.2). See [issue 31847][sdk#31847] for details.

  [sdk#31847]: https://github.com/dart-lang/sdk/issues/31847

# 0.9.5

* Add support for the WebAssembly format.

# 0.9.4

* Updated Dart SDK requirement to `>= 1.8.3 <2.0.0`

* Strong-mode clean.

* Added support for glTF text and binary formats.

# 0.9.3

* Fixed erroneous behavior for listening and when pausing/resuming
  stream of parts.

# 0.9.2

* Fixed erroneous behavior when pausing/canceling stream of parts but already
  listened to one part.

# 0.9.1

* Handle parsing of MIME multipart content with no parts.
