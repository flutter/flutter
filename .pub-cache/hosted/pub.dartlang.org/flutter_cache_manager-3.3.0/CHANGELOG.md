## [3.3.0] - 2021-11-29
* Added option to manage the log level. Doesn't print failed downloads by default anymore. You can set it like this:
```dart
CacheManager.logLevel = CacheManagerLogLevel.verbose;
```

## [3.2.0] - 2021-11-27
* [Bugfix] getSingleFile now downloads a new file before completing as the outdated file might have been deleted.

## [3.1.3] - 2021-11-05
* Disabled resizing of cached gifs as this was broken.

## [3.1.2] - 2021-06-17
* removeFile function now completes after the file is removed from disk and not earlier ([#323](https://github.com/Baseflow/flutter_cache_manager/pull/323))
* Image resizing doesn't block ui anymore and doesn't use image package but existing Flutter components ([#319](https://github.com/Baseflow/flutter_cache_manager/pull/319))

## [3.1.1] - 2021-06-03
* Move File to separate file. You can add it using the following import:
```dart
import 'package:flutter_cache_manager/file.dart' as cache_file;
```

## [3.1.0] - 2021-05-28
* Export File from package file ([#302](https://github.com/Baseflow/flutter_cache_manager/pull/302))
* Bugfix for eTag on Flutter Web ([#304](https://github.com/Baseflow/flutter_cache_manager/pull/315))
* Bugfix for loading multiple images simultaneously ([#315](https://github.com/Baseflow/flutter_cache_manager/pull/315))

## [3.0.2] - 2021-05-10
* Include rxdart 0.27 as possible dependency

## [3.0.1] - 2021-03-29
* Include file 6.0.0 as possible dependency

## [3.0.0] - 2021-03-27
* Bug fix on removing a relatively new file from cache
* Migration to nullsafety.

## [3.0.0-nullsafety.3] - 2021-03-26
* Add null-check on id in removeFile

## [3.0.0-nullsafety.2] - 2021-03-22
* Fix sqflite warning

## [3.0.0-nullsafety.1] - 2021-03-02
* Bug fix for NonStoringObjectProvider.

## [3.0.0-nullsafety.0] - 2021-02-25
* Migration to nullsafety.

## [2.1.2] - 2021-03-09
* Update dependencies
* Bug fix for JsonCacheInfoRepository when file is corrupted.

## [2.1.1] - 2021-01-14
* Update minimal dependency sqflite
* Small fix for non-existing directory (PR [#264](https://github.com/Baseflow/flutter_cache_manager/pull/264))

## [2.1.0] - 2020-12-21
* Added ImageCacheManager with support for image resizing.
* Upgrade dependencies.

## [2.0.0] - 2020-10-16
* Restructured the configuration of the CacheManager. Look at the ReadMe for more information.
* Added queueing mechanism for downloading new files. By default, the cache manager downloads a maximum of 10 files
 at the same time.
* Moved SQFlite database file from sqflite database path to application support directory.
* Add putFileStream to add an external file to the cache.
* Add option to use a key to get files from the cache which can be different from the url.
* Added JsonCacheInfoRepository for Windows and Linux.
* **BREAKING CHANGE** Creating a CacheManager now requires a Config object, see the readme for complete example.
* **BREAKING CHANGE** Renamed `maxAgeCacheObject` to `stalePeriod`
* **BREAKING CHANGE** Custom CacheInfoRepository need to include a key and some extra methods.
* **BREAKING CHANGE** A CacheInfoRepository is now assumed to allow multiple connections, which means you can call
 'open' multiple times and the repo keeps track on the number of connections.


## [2.0.0-beta.1] - 2020-10-10
* Reintroduced BaseCacheManager interface for backwards compatibility.
* Renamed putExistFile to putFileStream. This is equally efficient, but more clear in what it does.

## [2.0.0-beta] - 2020-10-01
* Added option for a key different from the url.
* Added a new CacheInfoRepository: JsonCacheInfoRepository, which is not used by default on the existing platforms, 
but can be used on any.
* Added support for Windows and Linux using the JsonCacheInfoRepository by default.
* Added support for adding an existing file.
* **BREAKING CHANGE** Creating a CacheManager now requires a Config object, see the readme for complete example.
* **BREAKING CHANGE** Renamed `maxAgeCacheObject` to `stalePeriod`
* **BREAKING CHANGE** Custom CacheInfoRepository need to include a key and some extra methods.
* **BREAKING CHANGE** A CacheInfoRepository is now assumed to allow multiple connections, which means you can call
 'open' multiple times and the repo keeps track on the number of connections.


## [1.4.2] - 2020-09-10
* Compatibility with Flutter version 1.22.

## [1.4.1] - 2020-06-14
* Bugfix: CacheManager returned a file that didn't exist when the file was removed by the OS (or any other external system)
while the app was active. This also prevented the CacheManager to redownload the file ([PR #190](https://github.com/Baseflow/flutter_cache_manager/pull/190)).

## [1.4.0] - 2020-06-04
* Allow cleaning of memory cache ([PR #183](https://github.com/Baseflow/flutter_cache_manager/pull/183)).
* Bugfix: Cleaning doesn't want to delete a file twice anymore ([PR #185](https://github.com/Baseflow/flutter_cache_manager/pull/185)).

## [1.3.0] - 2020-05-28
* Basic web support. (At least it downloads the file for you.)
* Support for the following mimetypes:
    * application/vnd.android.package-archive (apk)
    * audio/x-aac (aac)
    * video/quicktime (mov)

## [1.2.2] - 2020-04-16
* Support for RxDart 0.24.x

## [1.2.1] - 2020-04-14
* Fixed optional parameters in the Content-Type header ([#164](https://github.com/Baseflow/flutter_cache_manager/issues/164)).

## [1.2.0] - 2020-04-10
* Added getFileStream to CacheManager
    * getFileStream has an optional parameter 'withProgress' to receive progress.
    * getFileStream returns a FileResponse which is either a FileInfo or a DownloadProgress.
* Changes to FileFetcher and FileFetcherResponse:
    * FileFetcher is now replaced with a FileService which is a class instead of a function.
    * FileServiceResponse doesn't just give magic headers, but concrete implementation of the needed information.
    * FileServiceResponse gives a contentStream instead of content for more efficient handling of the data.
    * FileServiceResponse contains contentLength with information about the total size of the content.
* Changes in CacheStore for testability:
    * CleanupRunMinInterval can now be set.
    * Expects a mockable directory instead of a path.
* Added CacheInfoRepository interface to possibly replace the current CacheObjectProvider based on sqflite.
* Changes in WebHelper
  * Files are now always saved with a new name. Files are first saved to storage before old file is removed.
* General code quality improvements

## [1.1.3] - 2019-10-17
* Use try-catch in WebHelper so VM understands that errors are not uncaught.

## [1.1.2] - 2019-10-16

* Better error handling (really better this time).
* Fix that oldest files are removed, and not the newest.
* Fix error when cache data exists, but file is already removed.
* await on putFile

## [1.1.1] - 2019-07-23

* Changed error handling back to throwing the error as it is supposed to be.

## [1.1.0] - 2019-07-13

* New method to get fileinfo from memory.
* Better error handling.

## [1.0.0] - 2019-06-27

* Keep SQL connection open during session.
* Update dependencies

## [0.3.2] - 2019-03-06

* Fixed image loading after loading failed once.

## [0.3.1] - 2019-02-27

* Added method to clear cache

## [0.3.0] - 2019-02-18

* Complete refactor of library
* Use of SQFlite instead of shared preferences for cache info
* Added the option to use a custom file fetcher (for example for firebase)
* Support for AndroidX

## [0.2.0] - 2018-10-13

* Fixed library compatibility issue

## [0.1.2] - 2018-08-30

* Fixed library compatibility issue
* Improved some synchronization

## [0.1.1] - 2018-04-27

* Fixed some issues when file could not be downloaded the first time it is trying to be retrieved.

## [0.1.0] - 2018-04-14

* Fixed ConcurrentModificationError in cache cleaning
* Added optional headers
* Moved to Dart 2.0

## [0.0.4+1] - 2018-02-16

* Fixed nullpointer when non-updated file (a 304 response) has no cache-control period. 

## [0.0.4] - 2018-01-31

* Fixed issues with cache cleaning

## [0.0.3] - 2018-01-08

* Fixed relative paths on iOS.

## [0.0.2] - 2017-12-29

* Did some refactoring and made a useful readme.

## [0.0.1] - 2017-12-28

* Extracted the cache manager from cached_network_image
