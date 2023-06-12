## 3.3.0 - December 29, 2022

- Improved EXIF data management
- Fix character code issue with BitmapFont.
- This is the last 3.x update before the big 4.0 release.

## 3.2.2 - October 15, 2022

- Fix transparency issue with animated GIF images.

## 3.2.1 - October 15, 2022

- Fixes for APNG: fix exception from some APNG files, and some frames were not composited correctly.

## 3.2.0 - May 18, 2022

- Update SDK dependency to >2.15.0 and XML package dependency to >6.0.0

## 3.1.3 - February 17, 2022

- Optimize Image.getWhiteBalance function, add asDouble argument to return double value.

## 3.1.2 - February 17, 2022

- Add BmpEncoder to encode BMP images, along with encodeBmp function. Currently, only 24-bit or 32-bit BMP images will be encoded.

## 3.1.1 - January 12, 2022

- Fix error loading some tiff images
- Fix jpeg comments to support non-strict utf8 text

## 3.1.0 - November 30, 2021

- Update archive version requirement
- Fix JPGDecoder to return correct nullable types.

## 3.0.8 - October 02, 2021

- Fix WebP lossless decoder.

## 3.0.7 - September 29, 2021

- Change LICENSE to MIT.

## 3.0.6 - September 29, 2021

- Clean up LICENSE file, moving other license references to LICENSE-other.

## 3.0.5

- Fix copyResize for landscape oriented images.

## 3.0.4

- Fix Dart warnings from the previous release.

## 3.0.3

- Fix #320 - copyResize incorrectly applies linear and cubic.
- Apply EXIF orientation when decoding JPEG images.

## 3.0.2

- Dithering support for GIF encoder.
- Fix PNGEncoder issue if addFrame is called directly instead than encodeImage or encodeAnimation.
- Optimization for drawImage.

## 3.0.1

- Improve NeuralQuantizer to fix issue encoding small GIF images.
- Code cleanup resolving lint issues.

## 3.0.0

- Migrate to null safety.

## 2.1.19 - November 11, 2020

- Refactor HdrImage to better support more diverse formats, used for Hdr Tiff decoding.
- TiffDecoder will maintain Tag data after decoding, allowing them to be read to process image metadata.
- Added TiffEncoder. Still needs work to be able to add tag data to an encoded image.
- Clean up print statements from BmpDecoder.

## 2.1.18 - September 25, 2020

- Added 64-bit float format to TIFF decoder.
- Fixed issues with TiffDecoder.decodeHdrImage.
- Added range clamping to copyCrop to avoid out-of-bound errors.
- Variable FPS for animated GIF encoding.

## 2.1.17 - September 20, 2020

- Added 32-bit float and 16-bit half-float formats to the TIFF decoder.

## 2.1.16 - September 19, 2020

- Downgrade Meta dependency to be compatible with flutter_test in the stable channel.

## 2.1.15 - September 13, 2020

- Fix Image.getBytes for cropping images
- Fix bakeOrientation EXIF data
- Added ICO format decoder
- Fix JpegData.validate for unintended exceptions with non jpeg images

## 2.1.14 - June 14, 2020

- Update xml dependency to 4.2.0

## 2.1.13 - May 21, 2020

- Improvements for JPEG EXIF decoding
- Fix for the GIF animation decoder
- APNG encoder time delay correctly to milliseconds

## 2.1.12 - January 14, 2020

- drawChar now uses color parameter.
- Fix index out of range bug in drawImage.
- Fix transparency with animated WebP images.


## 2.1.11 - December 30, 2019

- Fix GIF animation loopCount encoding. Some viewers were not seeing the repeat count correctly.
- Resolve analysis warnings.

## 2.1.10 - December 04, 2019

- Applied Pub's Health suggestions.
- Optimize use of slow typed_data methods.
- Add drawStringCentered function
- Add fillCircle function
- Fix drawLine thickness for axis-aligned lines

## 2.1.9 - November 15, 2019

- JpegDecoder optimizations. Decoding an 8k jpeg went from 2048ms to 1340ms.

## 2.1.8 - November 05, 2019

- Fix issue with XML parsing for font files not reading some files
- Fix bug with trim function for non-transparent trim mode

## 2.1.7 - October 30, 2019

- Add ICO and CUR encoder.
- Fix BMP decoder for top-down BMP image files.

## 2.1.6 - October 29, 2019

- Add BMP decoder, currently only supporting 24-bit and 32-bit non compressed BMP images. (Thanks Ryan Kauk)

## 2.1.5

- Updated some tests to use `test`-syntax.
- Fixed null value in `GifEncoder`.
- Added Dart syntax highlighting in the readme file.
- Formatted package using `dartfmt`.
- Fixed "Unnecessary new" and other Dart analyzer warnings.
- Added the `samplingFactor` parameter to GIF encoding, which allows to significantly speed up
  encoding times of GIF encoding.

## 2.1.4 - June 01, 2019

- Optimize fillRect, drawPixel, and other drawing functions when opaque colors are used.

## 2.1.3 - May 26, 2019

- Revert the internal color format to #AABBGGRR.

## 2.1.2 - May 25, 2019

- Fix crash decoding some Jpeg images.
- Fix infinite recursion crash with fillFlood when fill color is the same as the start pixel color.

## 2.1.1 - May 22, 2019

- Fix typo and missing license in license file.

## 2.1.0 - May 15, 2019

- Big API clean-up to bring it up to a more modern Dart syntax.

## 2.0.9 - May 10, 2019

- Use strict dartanalysys settings and clean up code.

## 2.0.8 - May 8, 2019

- Add ability to quantize an image to any number of colors.
- Optimizations for the JPEG decoder.
- Use #AARRGGBB for colors instead of #AABBGGRR, to be compatible with Flutter image class.
- Add floodfill drawing function.
- CopyRectify to transform an arbitrary quad to the full image.
- Improve performance of CopyResize.

## 2.0.7 - February 5, 2019

- Improve JPEG decoding performance.
- Decode and encode ICC profile data from PNG images.

## 2.0.6 - January 26, 2019

- bakeOrientation will clear the image's exif orientation properties.
- copyResize will correctly maintain the image's orientation.

## 2.0.5 - December 1, 2018

- Added APNG (animated PNG) encoding.
- Optimized drawString function.

## 2.0.3 - June 6, 2018

- copyResize can maintain aspect ratio when resizing height by using -1 for the width.
- Added example for loading and processing images in an isolate.

## 2.0.2 - June 1, 2018

- Re-added decoding of orientation exif value from jpeg images.
- Added bake_orientation function, which will rotate an image so that it physically matches its orientation exif value,
useful for rotating an image prior to exporting it to a format that does not support exif data.

## 2.0.1 - May 28, 2018

Fix for bad jpeg files when encoding EXIF data.

## 2.0.0 - May 22, 2018

Remove the use of Dart 1 upper-case constants.
Update SDK dependency to a 2.0 development release.

## 1.1.33 - May 16, 2018

  Maintain EXIF data from JPEG images.

## 1.1.32 - May 9, 2018

  Remove the use of `part` and `part of` in the main library.

## 1.1.30 - March 10, 2018

  Update pubspec to account for the new version of xml package that has been
  published.

## 1.1.29 - September 18, 2017

- Add fixes for strong mode support.

## 1.1.28 - May 27, 2017

- Update pubspec to fix recent pub issues.
- Rename changelog.txt to CHANGELOG.md.
- Fix for 8-bit PNG decoding.

## 1.1.27 - May 14, 2017

- Fix crash decoding some jpeg images.


## 1.1.24 - January 23, 2015

- PVR encoding/decoding
- Fix 16-bit tiff decoding


## 1.1.23 - September 15, 2014

- Fix alpha for PSD images.


## 1.1.22 - July 31, 2014

- Various bug fixes


## 1.1.21 - June 19, 2014

- Add drawImage function
- Update XML dependency to 2.0.0


## 1.1.20 - April 26, 2014

- Fix OpenEXR decoder for dart2js


## 1.1.19 - April 15, 2014

- OpenEXR fixes.


## 1.1.18 - April 06, 2014

- Added OpenEXR format decoder.


## 1.1.17 - April 02, 2014

- Add Photoshop PSD format decoder


## 1.1.16 - March 24, 2014

- Fix JPEG encoder for compression quality < 100.


## 1.1.15 - March 10, 2014

- Update to new version of archive.


## 1.1.14 - February 26, 2014

- Optimizations


## 1.1.13 - February 16, 2014

- Added TIFF decoder


## 1.1.10 - February 11, 2014

- Added APNG animated PNG decoding support.
- Improved JPEG decoding performance
- Various bug fixes


## 1.1.8 - February 01, 2014

- Added GIF decoding support, including animated gifs.


## 1.1.7 - January 28, 2014

- Added WebP decoding support, included animated WebP.
