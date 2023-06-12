<b>BREAKING CHANGES IN V2</b>

CacheManager v2 introduced some breaking changes when configuring a custom CacheManager. [See the bottom of this page
 for the changes.](#breaking-changes-in-v2)

# flutter_cache_manager

[![pub package](https://img.shields.io/pub/v/flutter_cache_manager.svg)](https://pub.dartlang.org/packages/flutter_cache_manager)
[![build](https://github.com/Baseflow/flutter_cache_manager/actions/workflows/build.yaml/badge.svg)](https://github.com/Baseflow/flutter_cache_manager/actions/workflows/build.yaml)
[![codecov](https://codecov.io/gh/Baseflow/flutter_cache_manager/branch/master/graph/badge.svg)](https://codecov.io/gh/Baseflow/flutter_cache_manager)

A CacheManager to download and cache files in the cache directory of the app. Various settings on how long to keep a file can be changed.

It uses the cache-control http header to efficiently retrieve files.

The more basic usage is explained here. See the complete docs for more info.


## Usage

The cache manager can be used to get a file on various ways
The easiest way to get a single file is call `.getSingleFile`.

```
    var file = await DefaultCacheManager().getSingleFile(url);
```
`getFileStream(url)` returns a stream with the first result being the cached file and later optionally the downloaded file.

`getFileStream(url, withProgress: true)` when you set withProgress on true, this stream will also emit DownloadProgress when the file is not found in the cache.

`downloadFile(url)` directly downloads from the web.

`getFileFromCache` only retrieves from cache and returns no file when the file is not in the cache.


`putFile` gives the option to put a new file into the cache without downloading it.

`removeFile` removes a file from the cache. 

`emptyCache` removes all files from the cache. 

### ImageCacheManager
If you use the ImageCacheManager mixin on the CacheManager (which is already done on the DefaultCacheManager) you 
get the following `getImageFile` method for free:

```
Stream<FileResponse> getImageFile(String url, {
    String key,
    Map<String, String> headers,
    bool withProgress,
    int maxHeight,  // This is extra
    int maxWidth,   // This is extra as well
})
```
The image from the url is resized within the specifications, and the resized images is stored in the cache. It 
always tries to keep the existing aspect ratios. The original image is also cached and used to resize the image if 
you call this method with other height/width parameters.

## Other implementations
When your files are stored on Firebase Storage you can use [flutter_cache_manager_firebase](https://pub.dev/packages/flutter_cache_manager_firebase).

## Customize
The cache manager is customizable by creating a new CacheManager. It is very important to not create more than 1
 CacheManager instance with the same key as these bite each other. In the example down here the manager is created as a 
 Singleton, but you could also use for example Provider to Provide a CacheManager on the top level of your app.
Below is an example with other settings for the maximum age of files, maximum number of objects
and a custom FileService. The key parameter in the constructor is mandatory, all other variables are optional.

```
class CustomCacheManager {
  static const key = 'customCacheKey';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 20,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );
}
```
## Frequently Asked Questions
- [How are the cache files stored?](#how-are-the-cache-files-stored)
- [When are the cached files updated?](#when-are-the-cached-files-updated)
- [When are cached files removed?](#when-are-cached-files-removed)


### How are the cache files stored?
By default the cached files are stored in the temporary directory of the app. This means the OS can delete the files any time.

Information about the files is stored in a database using sqflite on Android, iOS and macOs, or in a plain JSON file
 on other platforms. The file name of the database is the key of the cacheManager, that's why that has to be unique.

### When are the cached files updated?
A valid url response should contain a Cache-Control header. More info on the header can be found 
[here](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control), but in summary it says for how long
the image can be expected to be up to date. It also contains an 'eTag' which can be used to check (after that time) 
whether the file did change or if it is actually still valid.

When a file is in the cache that is always directly returned when calling `getSingleFile` or `getFileStream`. 
After that the information is check if the file is actually still valid. If the file is outdated according to the 
Cache-Control headers the manager tries to update the file and store the new one in the cache. When you use 
`getFileStream` this updated file will also be returned in the stream.

### When are cached files removed?
The files can be removed by the cache manager or by the operating system. By default the files are stored in a cache
 folder, which is sometimes cleaned for example on Android with an app update.

The cache manager uses 2 variables to determine when to delete a file, the `maxNrOfCacheObjects` and the `stalePeriod`.
The cache knows when files have been used latest. When cleaning the cache (which happens continuously), the cache
deletes files when there are too many, ordered by last use, and when files just haven't been used for longer than
the stale period.


## Breaking changes in v2
- There is no longer a need to extend on BaseCacheManager, you can directly call the constructor. The BaseCacheManager
 is now only an interface. CacheManager is the implementation you can use directly. 

- The constructor now expects a Config object with some settings you were used to, but some are slightly different.
For example the system where you want to store your files is not just a dictionary anymore, but a FileSystem. That way
you have more freedom on where to store your files.

-  See the example in [Customize](#customize).
