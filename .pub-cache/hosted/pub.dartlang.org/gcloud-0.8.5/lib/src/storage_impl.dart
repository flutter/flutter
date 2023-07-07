// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of gcloud.storage;

const String _absolutePrefix = 'gs://';
const String _directoryDelimiter = '/';

/// Representation of an absolute name consisting of bucket name and object
/// name.
class _AbsoluteName {
  final String bucketName;
  final String objectName;

  _AbsoluteName._(this.bucketName, this.objectName);

  factory _AbsoluteName.parse(String absoluteName) {
    if (!absoluteName.startsWith(_absolutePrefix)) {
      throw FormatException("Absolute name '$absoluteName' does not start "
          "with '$_absolutePrefix'");
    }
    var index = absoluteName.indexOf('/', _absolutePrefix.length);
    if (index == -1 || index == _absolutePrefix.length) {
      throw FormatException("Absolute name '$absoluteName' does not have "
          'a bucket name');
    }
    if (index == absoluteName.length - 1) {
      throw FormatException("Absolute name '$absoluteName' does not have "
          'an object name');
    }
    final bucketName = absoluteName.substring(_absolutePrefix.length, index);
    final objectName = absoluteName.substring(index + 1);

    return _AbsoluteName._(bucketName, objectName);
  }
}

/// Storage API implementation providing access to buckets.
class _StorageImpl implements Storage {
  final String project;
  final storage_api.StorageApi _api;

  _StorageImpl(http.Client client, this.project)
      : _api = storage_api.StorageApi(client);

  @override
  Future createBucket(String bucketName,
      {PredefinedAcl? predefinedAcl, Acl? acl}) {
    var bucket = storage_api.Bucket()..name = bucketName;
    var predefinedName = predefinedAcl?._name;
    if (acl != null) {
      bucket.acl = acl._toBucketAccessControlList();
    }
    return _api.buckets
        .insert(bucket, project, predefinedAcl: predefinedName)
        .then((bucket) => null);
  }

  @override
  Future deleteBucket(String bucketName) {
    return _api.buckets.delete(bucketName);
  }

  @override
  Bucket bucket(String bucketName,
      {PredefinedAcl? defaultPredefinedObjectAcl, Acl? defaultObjectAcl}) {
    return _BucketImpl(
        this, bucketName, defaultPredefinedObjectAcl, defaultObjectAcl);
  }

  @override
  Future<bool> bucketExists(String bucketName) {
    bool notFoundError(e) {
      return e is storage_api.DetailedApiRequestError && e.status == 404;
    }

    return _api.buckets
        .get(bucketName)
        .then((_) => true)
        .catchError((e) => false, test: notFoundError);
  }

  @override
  Future<BucketInfo> bucketInfo(String bucketName) {
    return _api.buckets
        .get(bucketName, projection: 'full')
        .then((bucket) => _BucketInfoImpl(bucket));
  }

  @override
  Stream<String> listBucketNames() {
    Future<_BucketPageImpl> firstPage(int pageSize) {
      return _listBuckets(pageSize, null)
          .then((response) => _BucketPageImpl(this, pageSize, response));
    }

    return StreamFromPages<String>(firstPage).stream;
  }

  @override
  Future<Page<String>> pageBucketNames({int pageSize = 50}) {
    return _listBuckets(pageSize, null).then((response) {
      return _BucketPageImpl(this, pageSize, response);
    });
  }

  @override
  Future copyObject(String src, String dest) {
    var srcName = _AbsoluteName.parse(src);
    var destName = _AbsoluteName.parse(dest);
    return _api.objects
        .copy(storage_api.Object(), srcName.bucketName, srcName.objectName,
            destName.bucketName, destName.objectName)
        .then((_) => null);
  }

  Future<storage_api.Buckets> _listBuckets(
      int pageSize, String? nextPageToken) {
    return _api.buckets
        .list(project, maxResults: pageSize, pageToken: nextPageToken);
  }
}

class _BucketInfoImpl implements BucketInfo {
  final storage_api.Bucket _bucket;

  _BucketInfoImpl(this._bucket);

  @override
  String get bucketName => _bucket.name!;

  @override
  String get etag => _bucket.etag!;

  @override
  DateTime get created => _bucket.timeCreated!;

  @override
  String get id => _bucket.id!;

  @override
  Acl get acl => Acl._fromBucketAcl(_bucket);
}

/// Bucket API implementation providing access to objects.
class _BucketImpl implements Bucket {
  final storage_api.StorageApi _api;
  final PredefinedAcl? _defaultPredefinedObjectAcl;
  final Acl? _defaultObjectAcl;
  @override
  final String bucketName;

  _BucketImpl(_StorageImpl storage, this.bucketName,
      this._defaultPredefinedObjectAcl, this._defaultObjectAcl)
      : _api = storage._api;

  @override
  String absoluteObjectName(String objectName) {
    return '$_absolutePrefix$bucketName/$objectName';
  }

  @override
  StreamSink<List<int>> write(String objectName,
      {int? length,
      ObjectMetadata? metadata,
      Acl? acl,
      PredefinedAcl? predefinedAcl,
      String? contentType}) {
    storage_api.Object object;
    if (metadata == null) {
      metadata = _ObjectMetadata(acl: acl, contentType: contentType);
    } else {
      if (acl != null) {
        metadata = metadata.replace(acl: acl);
      }
      if (contentType != null) {
        metadata = metadata.replace(contentType: contentType);
      }
    }
    var objectMetadata = metadata as _ObjectMetadata;
    object = objectMetadata._object;

    // If no predefined ACL is passed use the default (if any).
    String? predefinedName;
    if (predefinedAcl != null || _defaultPredefinedObjectAcl != null) {
      var predefined = predefinedAcl ?? _defaultPredefinedObjectAcl!;
      predefinedName = predefined._name;
    }

    // If no ACL is passed use the default (if any).
    if (object.acl == null && _defaultObjectAcl != null) {
      object.acl = _defaultObjectAcl!._toObjectAccessControlList();
    }

    // Fill properties not passed in metadata.
    object.name = objectName;

    var sink = _MediaUploadStreamSink(
        _api, bucketName, objectName, object, predefinedName, length);
    return sink;
  }

  @override
  Future<ObjectInfo> writeBytes(String objectName, List<int> bytes,
      {ObjectMetadata? metadata,
      Acl? acl,
      PredefinedAcl? predefinedAcl,
      String? contentType}) {
    var sink = write(objectName,
        length: bytes.length,
        metadata: metadata,
        acl: acl,
        predefinedAcl: predefinedAcl,
        contentType: contentType) as _MediaUploadStreamSink;
    sink.add(bytes);
    return sink.close();
  }

  @override
  Stream<List<int>> read(String objectName, {int? offset, int? length}) async* {
    offset ??= 0;

    if (offset != 0 && length == null) {
      throw ArgumentError('length must have a value if offset is non-zero.');
    }

    var options = storage_api.DownloadOptions.fullMedia;

    if (length != null) {
      if (length <= 0) {
        throw ArgumentError.value(
            length, 'length', 'If provided, length must greater than zero.');
      }
      // For ByteRange, end is *inclusive*.
      var end = offset + length - 1;
      var range = storage_api.ByteRange(offset, end);
      assert(range.length == length);
      options = storage_api.PartialDownloadOptions(range);
    }

    var media = (await _api.objects.get(bucketName, objectName,
        downloadOptions: options)) as commons.Media;

    yield* media.stream;
  }

  @override
  Future<ObjectInfo> info(String objectName) {
    return _api.objects
        .get(bucketName, objectName, projection: 'full')
        .then((object) => _ObjectInfoImpl(object as storage_api.Object));
  }

  @override
  Future delete(String objectName) {
    return _api.objects.delete(bucketName, objectName);
  }

  @override
  Stream<BucketEntry> list({String? prefix, String? delimiter}) {
    delimiter ??= _directoryDelimiter;
    Future<_ObjectPageImpl> firstPage(int pageSize) async {
      final response =
          await _listObjects(bucketName, prefix, delimiter, 50, null);
      return _ObjectPageImpl(this, prefix, delimiter, pageSize, response);
    }

    return StreamFromPages<BucketEntry>(firstPage).stream;
  }

  @override
  Future<Page<BucketEntry>> page(
      {String? prefix, String? delimiter, int pageSize = 50}) async {
    delimiter ??= _directoryDelimiter;
    final response =
        await _listObjects(bucketName, prefix, delimiter, pageSize, null);
    return _ObjectPageImpl(this, prefix, delimiter, pageSize, response);
  }

  @override
  Future updateMetadata(String objectName, ObjectMetadata metadata) {
    // TODO: support other ObjectMetadata implementations?
    var md = metadata as _ObjectMetadata;
    var object = md._object;
    if (md._object.acl == null && _defaultObjectAcl == null) {
      throw ArgumentError('ACL is required for update');
    }
    if (md.contentType == null) {
      throw ArgumentError('Content-Type is required for update');
    }
    md._object.acl ??= _defaultObjectAcl!._toObjectAccessControlList();
    return _api.objects.update(object, bucketName, objectName);
  }

  Future<storage_api.Objects> _listObjects(String bucketName, String? prefix,
      String? delimiter, int pageSize, String? nextPageToken) {
    return _api.objects.list(bucketName,
        prefix: prefix,
        delimiter: delimiter,
        maxResults: pageSize,
        pageToken: nextPageToken);
  }
}

class _BucketPageImpl implements Page<String> {
  final _StorageImpl _storage;
  final int? _pageSize;
  final String? _nextPageToken;
  @override
  final List<String> items;

  _BucketPageImpl(this._storage, this._pageSize, storage_api.Buckets response)
      : items = [
          for (final item in response.items ?? const <storage_api.Bucket>[])
            item.name!
        ],
        _nextPageToken = response.nextPageToken;

  @override
  bool get isLast => _nextPageToken == null;

  @override
  Future<Page<String>> next({int? pageSize}) async {
    if (isLast) {
      throw StateError('Page.next() cannot be called when Page.isLast == true');
    }
    pageSize ??= _pageSize;

    return _storage._listBuckets(pageSize!, _nextPageToken).then((response) {
      return _BucketPageImpl(_storage, pageSize, response);
    });
  }
}

class _ObjectPageImpl implements Page<BucketEntry> {
  final _BucketImpl _bucket;
  final String? _prefix;
  final String? _delimiter;
  final int? _pageSize;
  final String? _nextPageToken;
  @override
  final List<BucketEntry> items;

  _ObjectPageImpl(this._bucket, this._prefix, this._delimiter, this._pageSize,
      storage_api.Objects response)
      : items = [
          for (final item in response.prefixes ?? const <String>[])
            BucketEntry._directory(item),
          for (final item in response.items ?? const <storage_api.Object>[])
            BucketEntry._object(item.name!)
        ],
        _nextPageToken = response.nextPageToken;

  @override
  bool get isLast => _nextPageToken == null;

  @override
  Future<Page<BucketEntry>> next({int? pageSize}) async {
    if (isLast) {
      throw StateError('Page.next() cannot be called when Page.isLast == true');
    }
    pageSize ??= _pageSize;

    return _bucket
        ._listObjects(
            _bucket.bucketName, _prefix, _delimiter, pageSize!, _nextPageToken)
        .then((response) {
      return _ObjectPageImpl(_bucket, _prefix, _delimiter, pageSize, response);
    });
  }
}

class _ObjectGenerationImpl implements ObjectGeneration {
  @override
  final String objectGeneration;
  @override
  final int metaGeneration;

  _ObjectGenerationImpl(this.objectGeneration, this.metaGeneration);
}

class _ObjectInfoImpl implements ObjectInfo {
  final storage_api.Object _object;
  final ObjectMetadata _metadata;
  Uri? _downloadLink;
  ObjectGeneration? _generation;

  _ObjectInfoImpl(storage_api.Object object)
      : _object = object,
        _metadata = _ObjectMetadata._(object);

  @override
  String get name => _object.name!;

  @override
  int get length => int.parse(_object.size!);

  @override
  DateTime get updated => _object.updated!;

  @override
  String get etag => _object.etag!;

  @override
  List<int> get md5Hash => base64.decode(_object.md5Hash!);

  @override
  int get crc32CChecksum {
    var list = base64.decode(_object.crc32c!);
    return (list[3] << 24) | (list[2] << 16) | (list[1] << 8) | list[0];
  }

  @override
  Uri get downloadLink {
    return _downloadLink ??= Uri.parse(_object.mediaLink!);
  }

  @override
  ObjectGeneration get generation {
    return _generation ??= _ObjectGenerationImpl(
        _object.generation!, int.parse(_object.metageneration!));
  }

  /// Additional metadata.
  @override
  ObjectMetadata get metadata => _metadata;
}

class _ObjectMetadata implements ObjectMetadata {
  final storage_api.Object _object;
  Acl? _cachedAcl;
  ObjectGeneration? _cachedGeneration;
  Map<String, String>? _cachedCustom;

  _ObjectMetadata(
      {Acl? acl,
      String? contentType,
      String? contentEncoding,
      String? cacheControl,
      String? contentDisposition,
      String? contentLanguage,
      Map<String, String>? custom})
      : _object = storage_api.Object() {
    _object.acl = acl?._toObjectAccessControlList();
    _object.contentType = contentType;
    _object.contentEncoding = contentEncoding;
    _object.cacheControl = cacheControl;
    _object.contentDisposition = contentDisposition;
    _object.contentLanguage = contentLanguage;
    if (custom != null) _object.metadata = custom;
  }

  _ObjectMetadata._(this._object);

  @override
  Acl? get acl {
    _cachedAcl ??= Acl._fromObjectAcl(_object);
    return _cachedAcl;
  }

  @override
  String? get contentType => _object.contentType;

  @override
  String? get contentEncoding => _object.contentEncoding;

  @override
  String? get cacheControl => _object.cacheControl;

  @override
  String? get contentDisposition => _object.contentDisposition;

  @override
  String? get contentLanguage => _object.contentLanguage;

  ObjectGeneration? get generation {
    _cachedGeneration ??= ObjectGeneration(
        _object.generation!, int.parse(_object.metageneration!));
    return _cachedGeneration;
  }

  @override
  Map<String, String>? get custom {
    if (_object.metadata == null) return null;
    _cachedCustom ??= UnmodifiableMapView<String, String>(_object.metadata!);
    return _cachedCustom;
  }

  @override
  ObjectMetadata replace(
      {Acl? acl,
      String? contentType,
      String? contentEncoding,
      String? cacheControl,
      String? contentDisposition,
      String? contentLanguage,
      Map<String, String>? custom}) {
    return _ObjectMetadata(
        acl: acl ?? this.acl,
        contentType: contentType ?? this.contentType,
        contentEncoding: contentEncoding ?? this.contentEncoding,
        cacheControl: cacheControl ?? this.cacheControl,
        contentDisposition: contentDisposition ?? this.contentEncoding,
        contentLanguage: contentLanguage ?? this.contentEncoding,
        custom: custom != null ? Map.from(custom) : this.custom);
  }
}

/// Implementation of StreamSink which handles Google media upload.
/// It provides a StreamSink and logic which selects whether to use normal
/// media upload (multipart mime) or resumable media upload.
class _MediaUploadStreamSink implements StreamSink<List<int>> {
  static const int _defaultMaxNormalUploadLength = 1024 * 1024;
  final storage_api.StorageApi _api;
  final String _bucketName;
  final String _objectName;
  final storage_api.Object _object;
  final String? _predefinedAcl;
  final int? _length;
  final int _maxNormalUploadLength;
  int _bufferLength = 0;
  final List<List<int>> buffer = <List<int>>[];
  final _controller = StreamController<List<int>>(sync: true);
  late StreamSubscription _subscription;
  late StreamController<List<int>> _resumableController;
  final _doneCompleter = Completer<ObjectInfo>();

  static const int _stateLengthKnown = 0;
  static const int _stateProbingLength = 1;
  static const int _stateDecidedResumable = 2;
  int? _state;

  _MediaUploadStreamSink(this._api, this._bucketName, this._objectName,
      this._object, this._predefinedAcl, this._length,
      [this._maxNormalUploadLength = _defaultMaxNormalUploadLength]) {
    if (_length != null) {
      // If the length is known in advance decide on the upload strategy
      // immediately
      _state = _stateLengthKnown;
      if (_length! <= _maxNormalUploadLength) {
        _startNormalUpload(_controller.stream, _length);
      } else {
        _startResumableUpload(_controller.stream, _length);
      }
    } else {
      _state = _stateProbingLength;
      // If the length is not known in advance decide on the upload strategy
      // later. Start buffering until enough data has been read to decide.
      _subscription = _controller.stream
          .listen(_onData, onDone: _onDone, onError: _onError);
    }
  }

  @override
  void add(List<int> event) {
    _controller.add(event);
  }

  @override
  void addError(errorEvent, [StackTrace? stackTrace]) {
    _controller.addError(errorEvent, stackTrace);
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    return _controller.addStream(stream);
  }

  @override
  Future<ObjectInfo> close() {
    _controller.close();
    return _doneCompleter.future;
  }

  @override
  Future get done => _doneCompleter.future;

  void _onData(List<int> data) {
    assert(_state != _stateLengthKnown);
    if (_state == _stateProbingLength) {
      buffer.add(data);
      _bufferLength += data.length;
      if (_bufferLength > _maxNormalUploadLength) {
        // Start resumable upload.
        // TODO: Avoid using another stream-controller.
        _resumableController = StreamController<List<int>>(sync: true);
        buffer.forEach(_resumableController.add);
        _startResumableUpload(_resumableController.stream, _length);
        _state = _stateDecidedResumable;
      }
    } else {
      assert(_state == _stateDecidedResumable);
      _resumableController.add(data);
    }
  }

  void _onDone() {
    if (_state == _stateProbingLength) {
      // As the data is already cached don't bother to wait on somebody
      // listening on the stream before adding the data.
      _startNormalUpload(Stream<List<int>>.fromIterable(buffer), _bufferLength);
    } else {
      _resumableController.close();
    }
  }

  void _onError(Object e, StackTrace s) {
    // If still deciding on the strategy complete with error. Otherwise
    // forward the error for default processing.
    if (_state == _stateProbingLength) {
      _completeError(e, s);
    } else {
      _resumableController.addError(e, s);
    }
  }

  void _completeError(Object e, StackTrace s) {
    if (_state != _stateLengthKnown) {
      // Always cancel subscription on error.
      _subscription.cancel();
    }
    _doneCompleter.completeError(e, s);
  }

  void _startNormalUpload(Stream<List<int>> stream, int? length) {
    var contentType = _object.contentType ?? 'application/octet-stream';
    var media = storage_api.Media(stream, length, contentType: contentType);
    _api.objects
        .insert(_object, _bucketName,
            name: _objectName,
            predefinedAcl: _predefinedAcl,
            uploadMedia: media,
            uploadOptions: storage_api.UploadOptions.defaultOptions)
        .then((response) {
      _doneCompleter.complete(_ObjectInfoImpl(response));
    }, onError: _completeError);
  }

  void _startResumableUpload(Stream<List<int>> stream, int? length) {
    var contentType = _object.contentType ?? 'application/octet-stream';
    var media = storage_api.Media(stream, length, contentType: contentType);
    _api.objects
        .insert(_object, _bucketName,
            name: _objectName,
            predefinedAcl: _predefinedAcl,
            uploadMedia: media,
            uploadOptions: storage_api.UploadOptions.resumable)
        .then((response) {
      _doneCompleter.complete(_ObjectInfoImpl(response));
    }, onError: _completeError);
  }
}
