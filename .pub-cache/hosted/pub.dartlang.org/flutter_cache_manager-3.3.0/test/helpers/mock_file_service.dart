import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/web/file_service.dart';
import 'package:mockito/mockito.dart';

import '../mock.mocks.dart';

class MockFileService extends MockFileServiceBase {
  MockFileService._();
  factory MockFileService({bool includeStandardResponse = true}) {
    var fileService = MockFileService._();
    if (includeStandardResponse) {
      when(fileService.concurrentFetches).thenReturn(2);
      when(fileService.get(any, headers: anyNamed('headers')))
          .thenAnswer((realInvocation) async {
        return TestResponse();
      });
    }
    return fileService;
  }
}

class TestResponse extends FileServiceResponse {
  @override
  Stream<List<int>> get content async* {
    var bytes = await File('test/images/image-120.png').readAsBytes();
    var length = bytes.length;
    var firstPart = (length / 2).floor();
    yield bytes.sublist(0, firstPart);
    yield bytes.sublist(firstPart);
  }

  @override
  int get contentLength => 0;

  @override
  String get eTag => 'test';

  @override
  String get fileExtension => '.jpg';

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => DateTime.now();
}
