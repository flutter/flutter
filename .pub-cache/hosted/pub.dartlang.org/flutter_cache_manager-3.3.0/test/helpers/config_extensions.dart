import 'package:file/file.dart';
import 'package:flutter_cache_manager/src/config/config.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:mockito/mockito.dart';

import 'mock_cache_info_repository.dart';
import 'mock_file_service.dart';

extension ConfigExtensions on Config {
  MockCacheInfoRepository get mockRepo => repo as MockCacheInfoRepository;
  MockFileService get mockFileService => fileService as MockFileService;

  Future<File> returnsFile(String fileName, {List<int>? data}) async {
    var file = await fileSystem.createFile(fileName);
    await (file.openWrite()..add(data ?? [1, 3])).close();
    return file;
  }

  void returnsCacheObject(
    String fileUrl,
    String fileName,
    DateTime validTill, {
    String? key,
    int? id,
  }) {
    when(repo.get(key ?? fileUrl))
        .thenAnswer((realInvocation) async => CacheObject(
              fileUrl,
              relativePath: fileName,
              validTill: validTill,
              key: key ?? fileUrl,
              id: id,
            ));
  }

  void returnsNoCacheObject(String fileUrl) {
    when(repo.get(fileUrl)).thenAnswer((realInvocation) async => null);
  }

  void verifyNoDownloadCall() {
    verifyNoMoreInteractions(fileService);
    verifyNever(
      mockFileService.get(any, headers: anyNamed('headers')),
    );
    verifyNever(mockFileService.get(any));
  }

  Future<void> waitForDownload() async {
    await untilCalled(mockFileService.get(any, headers: anyNamed('headers')));
  }

  void verifyDownloadCall([int count = 1]) {
    verify(
      mockFileService.get(any, headers: anyNamed('headers')),
    ).called(count);
  }
}
