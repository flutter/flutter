import 'package:file/file.dart';
import 'package:flutter_cache_manager/src/config/config.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:mockito/mockito.dart';

extension ConfigExtensions on Config {
  Future<File> returnsFile(String fileName, {List<int> data}) async {
    var file = await fileSystem.createFile(fileName);
    await (file.openWrite()..add(data ?? [1, 3])).close();
    return file;
  }

  void returnsCacheObject(
    String fileUrl,
    String fileName,
    DateTime validTill, {
    String key,
  }) {
    when(repo.get(key ?? fileUrl))
        .thenAnswer((realInvocation) async => CacheObject(
              fileUrl,
              relativePath: fileName,
              validTill: validTill,
              key: key ?? fileUrl,
            ));
  }

  void returnsNoCacheObject(String fileUrl) {
    when(repo.get(fileUrl)).thenAnswer((realInvocation) async => null);
  }

  void verifyNoDownloadCall() {
    verifyNoMoreInteractions(fileService);
    verifyNever(
      fileService.get(any, headers: anyNamed('headers')),
    );
    verifyNever(fileService.get(any));
  }

  Future<void> waitForDownload() async {
    await untilCalled(fileService.get(any, headers: anyNamed('headers')));
  }

  void verifyDownloadCall([int count = 1]) {
    verify(
      fileService.get(any, headers: anyNamed('headers')),
    ).called(1);
  }
}
