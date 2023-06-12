## 3.3.7 - April 01, 2023

* Add Zip AES-256 decryption
* Fix symlink encoding for tar files

## 3.3.6 - January 27, 2023

* Fix errors decoding XZ files.

## 3.3.5 - November 22, 2022

* Fix file content when decoding zips

## 3.3.4 - November 11, 2022

* Fix analysis errors.

## 3.3.3 - November 11, 2022

* Support symlinks in ZIP archives
* Fix ZIP decryption for ZipCrypto format 

## 3.3.2 - October 16, 2022

* Fix for UTF-8 file name caused problem on Windows.

## 3.3.1 - July 19, 2022

* Fix for Inflate crashing on some compressed files.

## 3.3.0 - March 25, 2022

* IO encoders (ZipFileEncoder, TarFileEncoder), will now include directories and empty directories.
* Fix for ZipEncoder file lastModTime.
* Fix for ArchiveFile.string.
* Add PAX format to tar decoder.
* Make more file operations async. 

## 3.2.2 - March 09, 2022

* Re-add List<int> content data for ArchiveFile.
* Add String and TypedData (Int32List, Float32List, etc) content data for ArchiveFile. 

## 3.2.1 - February 17, 2022

* Added buffer to OutputFileStream to improve performance by reducing the number of file writes.

## 3.2.0 - February 12, 2022

* For non-web applications, use native 'inflate' decompression when decompressing zip files.
* Add asyncWrite option to extractArchiveToDisk and extractFileToDisk, moving file write operations to be async.
* ArchiveFile.writeContent will release its memory after the data has been written, reducing overall memory usage.
* Add clear method to ArchiveFile, clearing any decompressed data memory it's storing.

## 3.1.11 - January 29, 2022

* Fix indexing bug in Archive.addFile. 

## 3.1.10 - January 29, 2022

* Fix performance regression with Archive.

## 3.1.9 - January 19, 2022

* Fix FileInputStream to work with ZipDecoder.

## 3.1.8 - January 01, 2022

* Catch invalid UTF8 string decoding.

## 3.1.7 - January 01, 2022

* Fix for UTF8 filenames

## 3.1.6 - October 11, 2021

* Fix problem with non-terminating long filenames.
* File modification dates were incorrectly stored in milliseconds instead of seconds.

## 3.1.5 - September 29, 2021

* Disable XZ format CRC64 for html builds to fix errors.

## 3.1.4 - September 29, 2021

* Changed LICENSE to MIT.
 
## 3.1.3 - September 29, 2021

* Cleaned up LICENSE, moving other licenses to LICENSE-other.md.

## 3.1.2

* Added the ability to override the timestamp encoded in a Zip file.

## 3.1.1

* Fix zip encoder so that zip files created on Windows will open correctly on Linux.

## 3.1.0-dev

* Added `const` constructors to `ZLibDecoder`, `ZLibEncoder`, and 
  `ZLibDecoderBase`.

## 3.0.0 - February 3, 2021

* Stable release supporting null safety.

## 3.0.0-nullsafety.0 - January 20, 2021

* Migrate to null safety.

## 2.0.13 - January 02, 2020

* Switch to dart strong mode; refactor code to resolve all dartanalyzer warnings.

## 2.0.12 - December 30, 2019

* Fix dartanalyzer warnings

## 2.0.11 - November 8, 2019

* Set the default permission for ArchiveFile to something more reasonable (0644 -rw-r--r--)

## 2.0.10 - June 11, 2019

* Fix for decoding empty zip files.

## 2.0.9 - May 16, 2019

* Add isSymbolicLink and nameOfLinkedFile to ArchiveFile.
* Fix for encoding empty files.

## 2.0.8

* Fix zip isFile

## 2.0.7

* Fix zip file attributes.

## 2.0.6

* Support GNU tar long file names
* Maintain unix file permissions in zip archives.

## 2.0.5

* Use dart:io ZLibCodec when run from dart:io.

## 2.0.4

* Fix InputStream when a Uint8ListView is used as input data.

## 2.0.3

* Use Utf8 for reading strings in archive archive files, for filenames and comments.

## 2.0.2

* Fixes for ZipFileEncoder.

## 2.0.1

* Remove the use of `part` and `part of` in the main library.
* Added ZipFileEncoder to encode files and directories using dart:io.
* Added createArchiveFromDirectory function to create an Archive object from a dart:io Directory.

## 2.0.0

* Moved version up for Dart 2 support.
* Fixed an issue with file compression flags when decoding zip archives.
* Fixed an issue with bzip2 decoding in production code.

## 1.0.33

* Support the latest version of `package:args`.

## 1.0.30 - May 27, 2017

- Add archive_io sub-package for supporting file streaming rather than storing everything in memory.
  **This is a work-in-progress and under development.**

## 1.0.29 - May 25, 2017

- Fix issue with POSIX tar files.
- Upgrade dependency on `archive` to `>=1.0.0 <2.0.0`

## 1.0.20 - Jun2 21, 2015

- Improve performance decompressing large files in zip archives.

## 1.0.19 - February 23, 2014

- Disable CRC verification by default when decoding archives.

## 1.0.18 - October 09, 2014

- Add support for encoding uncompressed files in zip archives.

## 1.0.17 - April 25, 2014

- Fix a bug in InputStream.

## 1.0.16 - March 02, 2014

- Add stream support to Inflate decompression.

## 1.0.15 - February 16, 2014

- Improved performance when writing large blocks.

## 1.0.14 - February 12, 2014

- Misc updates and fixes.

## 1.0.13 - February 06, 2014

- Added BZip2 encoder.

- *BREAKING CHANGE*: `File` was renamed to `ArchiveFile`, to avoid conflicts with
  `dart:io`.

## 1.0.12 - February 04, 2014

- Added BZip2 decoder.

## 1.0.11 - February 02, 2014

- Changed `InputStream` to work with typed_data instead of `List<int>`, should
  reduce memory and increase performance.

## 1.0.10 - January 19, 2013

- Renamed `InputBuffer` and `OutputBuffer` to `InputStream` and `OutputStream`,
  respectively.

- Added `readBits` method to `InputStream`.
