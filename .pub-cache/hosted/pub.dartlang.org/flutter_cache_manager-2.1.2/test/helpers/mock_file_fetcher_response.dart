import 'package:flutter_cache_manager/src/web/file_service.dart';

class MockFileFetcherResponse implements FileServiceResponse {
  final Stream<List<int>> _content;
  final int _contentLength;
  final String _eTag;
  final String _fileExtension;
  final int _statusCode;
  final DateTime _validTill;

  factory MockFileFetcherResponse.basic(){
    return MockFileFetcherResponse(
        Stream.value([0, 1, 2, 3, 4, 5]),
        6,
        'testv1',
        '.jpg',
        200,
        DateTime.now());
  }

  MockFileFetcherResponse(this._content, this._contentLength, this._eTag,
      this._fileExtension, this._statusCode, this._validTill);

  @override
  Stream<List<int>> get content => _content;

  @override
  // TODO: implement eTag
  String get eTag => _eTag;

  @override
  // TODO: implement fileExtension
  String get fileExtension => _fileExtension;

  @override
  // TODO: implement statusCode
  int get statusCode => _statusCode;

  @override
  // TODO: implement validTill
  DateTime get validTill => _validTill;

  @override
  // TODO: implement contentLength
  int get contentLength => _contentLength;
}
