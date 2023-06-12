// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: camel_case_types
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_string_interpolations

/// Books API - v1
///
/// The Google Books API allows clients to access the Google Books repository.
///
/// For more information, see
/// <https://code.google.com/apis/books/docs/v1/getting_started.html>
///
/// Create an instance of [BooksApi] to access these resources:
///
/// - [BookshelvesResource]
///   - [BookshelvesVolumesResource]
/// - [CloudloadingResource]
/// - [DictionaryResource]
/// - [FamilysharingResource]
/// - [LayersResource]
///   - [LayersAnnotationDataResource]
///   - [LayersVolumeAnnotationsResource]
/// - [MyconfigResource]
/// - [MylibraryResource]
///   - [MylibraryAnnotationsResource]
///   - [MylibraryBookshelvesResource]
///     - [MylibraryBookshelvesVolumesResource]
///   - [MylibraryReadingpositionsResource]
/// - [NotificationResource]
/// - [OnboardingResource]
/// - [PersonalizedstreamResource]
/// - [PromoofferResource]
/// - [SeriesResource]
///   - [SeriesMembershipResource]
/// - [VolumesResource]
///   - [VolumesAssociatedResource]
///   - [VolumesMybooksResource]
///   - [VolumesRecommendedResource]
///   - [VolumesUseruploadedResource]
library books.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The Google Books API allows clients to access the Google Books repository.
class BooksApi {
  /// Manage your books
  static const booksScope = 'https://www.googleapis.com/auth/books';

  final commons.ApiRequester _requester;

  BookshelvesResource get bookshelves => BookshelvesResource(_requester);
  CloudloadingResource get cloudloading => CloudloadingResource(_requester);
  DictionaryResource get dictionary => DictionaryResource(_requester);
  FamilysharingResource get familysharing => FamilysharingResource(_requester);
  LayersResource get layers => LayersResource(_requester);
  MyconfigResource get myconfig => MyconfigResource(_requester);
  MylibraryResource get mylibrary => MylibraryResource(_requester);
  NotificationResource get notification => NotificationResource(_requester);
  OnboardingResource get onboarding => OnboardingResource(_requester);
  PersonalizedstreamResource get personalizedstream =>
      PersonalizedstreamResource(_requester);
  PromoofferResource get promooffer => PromoofferResource(_requester);
  SeriesResource get series => SeriesResource(_requester);
  VolumesResource get volumes => VolumesResource(_requester);

  BooksApi(http.Client client,
      {core.String rootUrl = 'https://books.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class BookshelvesResource {
  final commons.ApiRequester _requester;

  BookshelvesVolumesResource get volumes =>
      BookshelvesVolumesResource(_requester);

  BookshelvesResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves metadata for a specific bookshelf for the specified user.
  ///
  /// Request parameters:
  ///
  /// [userId] - ID of user for whom to retrieve bookshelves.
  ///
  /// [shelf] - ID of bookshelf to retrieve.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Bookshelf].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Bookshelf> get(
    core.String userId,
    core.String shelf, {
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/users/' +
        commons.escapeVariable('$userId') +
        '/bookshelves/' +
        commons.escapeVariable('$shelf');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Bookshelf.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of public bookshelves for the specified user.
  ///
  /// Request parameters:
  ///
  /// [userId] - ID of user for whom to retrieve bookshelves.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Bookshelves].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Bookshelves> list(
    core.String userId, {
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'books/v1/users/' + commons.escapeVariable('$userId') + '/bookshelves';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Bookshelves.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BookshelvesVolumesResource {
  final commons.ApiRequester _requester;

  BookshelvesVolumesResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves volumes in a specific bookshelf for the specified user.
  ///
  /// Request parameters:
  ///
  /// [userId] - ID of user for whom to retrieve bookshelf volumes.
  ///
  /// [shelf] - ID of bookshelf to retrieve volumes.
  ///
  /// [maxResults] - Maximum number of results to return
  ///
  /// [showPreorders] - Set to true to show pre-ordered books. Defaults to
  /// false.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [startIndex] - Index of the first element to return (starts at 0)
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Volumes].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Volumes> list(
    core.String userId,
    core.String shelf, {
    core.int? maxResults,
    core.bool? showPreorders,
    core.String? source,
    core.int? startIndex,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (showPreorders != null) 'showPreorders': ['${showPreorders}'],
      if (source != null) 'source': [source],
      if (startIndex != null) 'startIndex': ['${startIndex}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/users/' +
        commons.escapeVariable('$userId') +
        '/bookshelves/' +
        commons.escapeVariable('$shelf') +
        '/volumes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Volumes.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class CloudloadingResource {
  final commons.ApiRequester _requester;

  CloudloadingResource(commons.ApiRequester client) : _requester = client;

  /// Add a user-upload volume and triggers processing.
  ///
  /// Request parameters:
  ///
  /// [driveDocumentId] - A drive document id. The upload_client_token must not
  /// be set.
  ///
  /// [mimeType] - The document MIME type. It can be set only if the
  /// drive_document_id is set.
  ///
  /// [name] - The document name. It can be set only if the drive_document_id is
  /// set.
  ///
  /// [uploadClientToken] - Scotty upload token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BooksCloudloadingResource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BooksCloudloadingResource> addBook({
    core.String? driveDocumentId,
    core.String? mimeType,
    core.String? name,
    core.String? uploadClientToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (driveDocumentId != null) 'drive_document_id': [driveDocumentId],
      if (mimeType != null) 'mime_type': [mimeType],
      if (name != null) 'name': [name],
      if (uploadClientToken != null) 'upload_client_token': [uploadClientToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/cloudloading/addBook';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return BooksCloudloadingResource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Remove the book and its contents
  ///
  /// Request parameters:
  ///
  /// [volumeId] - The id of the book to be removed.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> deleteBook(
    core.String volumeId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'volumeId': [volumeId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/cloudloading/deleteBook';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a user-upload volume.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BooksCloudloadingResource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BooksCloudloadingResource> updateBook(
    BooksCloudloadingResource request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/cloudloading/updateBook';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BooksCloudloadingResource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class DictionaryResource {
  final commons.ApiRequester _requester;

  DictionaryResource(commons.ApiRequester client) : _requester = client;

  /// Returns a list of offline dictionary metadata available
  ///
  /// Request parameters:
  ///
  /// [cpksver] - The device/version ID from which to request the data.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Metadata].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Metadata> listOfflineMetadata(
    core.String cpksver, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'cpksver': [cpksver],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/dictionary/listOfflineMetadata';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Metadata.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class FamilysharingResource {
  final commons.ApiRequester _requester;

  FamilysharingResource(commons.ApiRequester client) : _requester = client;

  /// Gets information regarding the family that the user is part of.
  ///
  /// Request parameters:
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FamilyInfo].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FamilyInfo> getFamilyInfo({
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/familysharing/getFamilyInfo';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FamilyInfo.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Initiates sharing of the content with the user's family.
  ///
  /// Empty response indicates success.
  ///
  /// Request parameters:
  ///
  /// [docId] - The docid to share.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [volumeId] - The volume to share.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> share({
    core.String? docId,
    core.String? source,
    core.String? volumeId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (docId != null) 'docId': [docId],
      if (source != null) 'source': [source],
      if (volumeId != null) 'volumeId': [volumeId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/familysharing/share';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Initiates revoking content that has already been shared with the user's
  /// family.
  ///
  /// Empty response indicates success.
  ///
  /// Request parameters:
  ///
  /// [docId] - The docid to unshare.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [volumeId] - The volume to unshare.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> unshare({
    core.String? docId,
    core.String? source,
    core.String? volumeId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (docId != null) 'docId': [docId],
      if (source != null) 'source': [source],
      if (volumeId != null) 'volumeId': [volumeId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/familysharing/unshare';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class LayersResource {
  final commons.ApiRequester _requester;

  LayersAnnotationDataResource get annotationData =>
      LayersAnnotationDataResource(_requester);
  LayersVolumeAnnotationsResource get volumeAnnotations =>
      LayersVolumeAnnotationsResource(_requester);

  LayersResource(commons.ApiRequester client) : _requester = client;

  /// Gets the layer summary for a volume.
  ///
  /// Request parameters:
  ///
  /// [volumeId] - The volume to retrieve layers for.
  ///
  /// [summaryId] - The ID for the layer to get the summary for.
  ///
  /// [contentVersion] - The content version for the requested volume.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Layersummary].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Layersummary> get(
    core.String volumeId,
    core.String summaryId, {
    core.String? contentVersion,
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (contentVersion != null) 'contentVersion': [contentVersion],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/volumes/' +
        commons.escapeVariable('$volumeId') +
        '/layersummary/' +
        commons.escapeVariable('$summaryId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Layersummary.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List the layer summaries for a volume.
  ///
  /// Request parameters:
  ///
  /// [volumeId] - The volume to retrieve layers for.
  ///
  /// [contentVersion] - The content version for the requested volume.
  ///
  /// [maxResults] - Maximum number of results to return
  /// Value must be between "0" and "200".
  ///
  /// [pageToken] - The value of the nextToken from the previous page.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Layersummaries].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Layersummaries> list(
    core.String volumeId, {
    core.String? contentVersion,
    core.int? maxResults,
    core.String? pageToken,
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (contentVersion != null) 'contentVersion': [contentVersion],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/volumes/' +
        commons.escapeVariable('$volumeId') +
        '/layersummary';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Layersummaries.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class LayersAnnotationDataResource {
  final commons.ApiRequester _requester;

  LayersAnnotationDataResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the annotation data.
  ///
  /// Request parameters:
  ///
  /// [volumeId] - The volume to retrieve annotations for.
  ///
  /// [layerId] - The ID for the layer to get the annotations.
  ///
  /// [annotationDataId] - The ID of the annotation data to retrieve.
  ///
  /// [contentVersion] - The content version for the volume you are trying to
  /// retrieve.
  ///
  /// [allowWebDefinitions] - For the dictionary layer. Whether or not to allow
  /// web definitions.
  ///
  /// [h] - The requested pixel height for any images. If height is provided
  /// width must also be provided.
  ///
  /// [locale] - The locale information for the data. ISO-639-1 language and
  /// ISO-3166-1 country code. Ex: 'en_US'.
  ///
  /// [scale] - The requested scale for the image.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [w] - The requested pixel width for any images. If width is provided
  /// height must also be provided.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DictionaryAnnotationdata].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DictionaryAnnotationdata> get(
    core.String volumeId,
    core.String layerId,
    core.String annotationDataId,
    core.String contentVersion, {
    core.bool? allowWebDefinitions,
    core.int? h,
    core.String? locale,
    core.int? scale,
    core.String? source,
    core.int? w,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'contentVersion': [contentVersion],
      if (allowWebDefinitions != null)
        'allowWebDefinitions': ['${allowWebDefinitions}'],
      if (h != null) 'h': ['${h}'],
      if (locale != null) 'locale': [locale],
      if (scale != null) 'scale': ['${scale}'],
      if (source != null) 'source': [source],
      if (w != null) 'w': ['${w}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/volumes/' +
        commons.escapeVariable('$volumeId') +
        '/layers/' +
        commons.escapeVariable('$layerId') +
        '/data/' +
        commons.escapeVariable('$annotationDataId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DictionaryAnnotationdata.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the annotation data for a volume and layer.
  ///
  /// Request parameters:
  ///
  /// [volumeId] - The volume to retrieve annotation data for.
  ///
  /// [layerId] - The ID for the layer to get the annotation data.
  ///
  /// [contentVersion] - The content version for the requested volume.
  ///
  /// [annotationDataId] - The list of Annotation Data Ids to retrieve.
  /// Pagination is ignored if this is set.
  ///
  /// [h] - The requested pixel height for any images. If height is provided
  /// width must also be provided.
  ///
  /// [locale] - The locale information for the data. ISO-639-1 language and
  /// ISO-3166-1 country code. Ex: 'en_US'.
  ///
  /// [maxResults] - Maximum number of results to return
  /// Value must be between "0" and "200".
  ///
  /// [pageToken] - The value of the nextToken from the previous page.
  ///
  /// [scale] - The requested scale for the image.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [updatedMax] - RFC 3339 timestamp to restrict to items updated prior to
  /// this timestamp (exclusive).
  ///
  /// [updatedMin] - RFC 3339 timestamp to restrict to items updated since this
  /// timestamp (inclusive).
  ///
  /// [w] - The requested pixel width for any images. If width is provided
  /// height must also be provided.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Annotationsdata].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Annotationsdata> list(
    core.String volumeId,
    core.String layerId,
    core.String contentVersion, {
    core.List<core.String>? annotationDataId,
    core.int? h,
    core.String? locale,
    core.int? maxResults,
    core.String? pageToken,
    core.int? scale,
    core.String? source,
    core.String? updatedMax,
    core.String? updatedMin,
    core.int? w,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'contentVersion': [contentVersion],
      if (annotationDataId != null) 'annotationDataId': annotationDataId,
      if (h != null) 'h': ['${h}'],
      if (locale != null) 'locale': [locale],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (scale != null) 'scale': ['${scale}'],
      if (source != null) 'source': [source],
      if (updatedMax != null) 'updatedMax': [updatedMax],
      if (updatedMin != null) 'updatedMin': [updatedMin],
      if (w != null) 'w': ['${w}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/volumes/' +
        commons.escapeVariable('$volumeId') +
        '/layers/' +
        commons.escapeVariable('$layerId') +
        '/data';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Annotationsdata.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class LayersVolumeAnnotationsResource {
  final commons.ApiRequester _requester;

  LayersVolumeAnnotationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the volume annotation.
  ///
  /// Request parameters:
  ///
  /// [volumeId] - The volume to retrieve annotations for.
  ///
  /// [layerId] - The ID for the layer to get the annotations.
  ///
  /// [annotationId] - The ID of the volume annotation to retrieve.
  ///
  /// [locale] - The locale information for the data. ISO-639-1 language and
  /// ISO-3166-1 country code. Ex: 'en_US'.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Volumeannotation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Volumeannotation> get(
    core.String volumeId,
    core.String layerId,
    core.String annotationId, {
    core.String? locale,
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (locale != null) 'locale': [locale],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/volumes/' +
        commons.escapeVariable('$volumeId') +
        '/layers/' +
        commons.escapeVariable('$layerId') +
        '/annotations/' +
        commons.escapeVariable('$annotationId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Volumeannotation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the volume annotations for a volume and layer.
  ///
  /// Request parameters:
  ///
  /// [volumeId] - The volume to retrieve annotations for.
  ///
  /// [layerId] - The ID for the layer to get the annotations.
  ///
  /// [contentVersion] - The content version for the requested volume.
  ///
  /// [endOffset] - The end offset to end retrieving data from.
  ///
  /// [endPosition] - The end position to end retrieving data from.
  ///
  /// [locale] - The locale information for the data. ISO-639-1 language and
  /// ISO-3166-1 country code. Ex: 'en_US'.
  ///
  /// [maxResults] - Maximum number of results to return
  /// Value must be between "0" and "200".
  ///
  /// [pageToken] - The value of the nextToken from the previous page.
  ///
  /// [showDeleted] - Set to true to return deleted annotations. updatedMin must
  /// be in the request to use this. Defaults to false.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [startOffset] - The start offset to start retrieving data from.
  ///
  /// [startPosition] - The start position to start retrieving data from.
  ///
  /// [updatedMax] - RFC 3339 timestamp to restrict to items updated prior to
  /// this timestamp (exclusive).
  ///
  /// [updatedMin] - RFC 3339 timestamp to restrict to items updated since this
  /// timestamp (inclusive).
  ///
  /// [volumeAnnotationsVersion] - The version of the volume annotations that
  /// you are requesting.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Volumeannotations].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Volumeannotations> list(
    core.String volumeId,
    core.String layerId,
    core.String contentVersion, {
    core.String? endOffset,
    core.String? endPosition,
    core.String? locale,
    core.int? maxResults,
    core.String? pageToken,
    core.bool? showDeleted,
    core.String? source,
    core.String? startOffset,
    core.String? startPosition,
    core.String? updatedMax,
    core.String? updatedMin,
    core.String? volumeAnnotationsVersion,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'contentVersion': [contentVersion],
      if (endOffset != null) 'endOffset': [endOffset],
      if (endPosition != null) 'endPosition': [endPosition],
      if (locale != null) 'locale': [locale],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (showDeleted != null) 'showDeleted': ['${showDeleted}'],
      if (source != null) 'source': [source],
      if (startOffset != null) 'startOffset': [startOffset],
      if (startPosition != null) 'startPosition': [startPosition],
      if (updatedMax != null) 'updatedMax': [updatedMax],
      if (updatedMin != null) 'updatedMin': [updatedMin],
      if (volumeAnnotationsVersion != null)
        'volumeAnnotationsVersion': [volumeAnnotationsVersion],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/volumes/' +
        commons.escapeVariable('$volumeId') +
        '/layers/' +
        commons.escapeVariable('$layerId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Volumeannotations.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MyconfigResource {
  final commons.ApiRequester _requester;

  MyconfigResource(commons.ApiRequester client) : _requester = client;

  /// Gets the current settings for the user.
  ///
  /// Request parameters:
  ///
  /// [country] - Unused. Added only to workaround TEX mandatory request
  /// template requirement
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Usersettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Usersettings> getUserSettings({
    core.String? country,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (country != null) 'country': [country],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/myconfig/getUserSettings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Usersettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Release downloaded content access restriction.
  ///
  /// Request parameters:
  ///
  /// [cpksver] - The device/version ID from which to release the restriction.
  ///
  /// [volumeIds] - The volume(s) to release restrictions for.
  ///
  /// [locale] - ISO-639-1, ISO-3166-1 codes for message localization, i.e.
  /// en_US.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DownloadAccesses].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DownloadAccesses> releaseDownloadAccess(
    core.String cpksver,
    core.List<core.String> volumeIds, {
    core.String? locale,
    core.String? source,
    core.String? $fields,
  }) async {
    if (volumeIds.isEmpty) {
      throw core.ArgumentError('Parameter volumeIds cannot be empty.');
    }
    final _queryParams = <core.String, core.List<core.String>>{
      'cpksver': [cpksver],
      'volumeIds': volumeIds,
      if (locale != null) 'locale': [locale],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/myconfig/releaseDownloadAccess';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return DownloadAccesses.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Request concurrent and download access restrictions.
  ///
  /// Request parameters:
  ///
  /// [cpksver] - The device/version ID from which to request the restrictions.
  ///
  /// [nonce] - The client nonce value.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [volumeId] - The volume to request concurrent/download restrictions for.
  ///
  /// [licenseTypes] - The type of access license to request. If not specified,
  /// the default is BOTH.
  /// Possible string values are:
  /// - "LICENSE_TYPES_UNDEFINED"
  /// - "BOTH" : Both concurrent and download licenses.
  /// - "CONCURRENT" : Concurrent access license.
  /// - "DOWNLOAD" : Offline download access license.
  ///
  /// [locale] - ISO-639-1, ISO-3166-1 codes for message localization, i.e.
  /// en_US.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RequestAccessData].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RequestAccessData> requestAccess(
    core.String cpksver,
    core.String nonce,
    core.String source,
    core.String volumeId, {
    core.String? licenseTypes,
    core.String? locale,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'cpksver': [cpksver],
      'nonce': [nonce],
      'source': [source],
      'volumeId': [volumeId],
      if (licenseTypes != null) 'licenseTypes': [licenseTypes],
      if (locale != null) 'locale': [locale],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/myconfig/requestAccess';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return RequestAccessData.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Request downloaded content access for specified volumes on the My eBooks
  /// shelf.
  ///
  /// Request parameters:
  ///
  /// [cpksver] - The device/version ID from which to release the restriction.
  ///
  /// [nonce] - The client nonce value.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [features] - List of features supported by the client, i.e., 'RENTALS'
  ///
  /// [includeNonComicsSeries] - Set to true to include non-comics series.
  /// Defaults to false.
  ///
  /// [locale] - ISO-639-1, ISO-3166-1 codes for message localization, i.e.
  /// en_US.
  ///
  /// [showPreorders] - Set to true to show pre-ordered books. Defaults to
  /// false.
  ///
  /// [volumeIds] - The volume(s) to request download restrictions for.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Volumes].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Volumes> syncVolumeLicenses(
    core.String cpksver,
    core.String nonce,
    core.String source, {
    core.List<core.String>? features,
    core.bool? includeNonComicsSeries,
    core.String? locale,
    core.bool? showPreorders,
    core.List<core.String>? volumeIds,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'cpksver': [cpksver],
      'nonce': [nonce],
      'source': [source],
      if (features != null) 'features': features,
      if (includeNonComicsSeries != null)
        'includeNonComicsSeries': ['${includeNonComicsSeries}'],
      if (locale != null) 'locale': [locale],
      if (showPreorders != null) 'showPreorders': ['${showPreorders}'],
      if (volumeIds != null) 'volumeIds': volumeIds,
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/myconfig/syncVolumeLicenses';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Volumes.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the settings for the user.
  ///
  /// If a sub-object is specified, it will overwrite the existing sub-object
  /// stored in the server. Unspecified sub-objects will retain the existing
  /// value.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Usersettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Usersettings> updateUserSettings(
    Usersettings request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/myconfig/updateUserSettings';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Usersettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MylibraryResource {
  final commons.ApiRequester _requester;

  MylibraryAnnotationsResource get annotations =>
      MylibraryAnnotationsResource(_requester);
  MylibraryBookshelvesResource get bookshelves =>
      MylibraryBookshelvesResource(_requester);
  MylibraryReadingpositionsResource get readingpositions =>
      MylibraryReadingpositionsResource(_requester);

  MylibraryResource(commons.ApiRequester client) : _requester = client;
}

class MylibraryAnnotationsResource {
  final commons.ApiRequester _requester;

  MylibraryAnnotationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes an annotation.
  ///
  /// Request parameters:
  ///
  /// [annotationId] - The ID for the annotation to delete.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> delete(
    core.String annotationId, {
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/mylibrary/annotations/' +
        commons.escapeVariable('$annotationId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new annotation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [annotationId] - The ID for the annotation to insert.
  ///
  /// [country] - ISO-3166-1 code to override the IP-based location.
  ///
  /// [showOnlySummaryInResponse] - Requests that only the summary of the
  /// specified layer be provided in the response.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Annotation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Annotation> insert(
    Annotation request, {
    core.String? annotationId,
    core.String? country,
    core.bool? showOnlySummaryInResponse,
    core.String? source,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (annotationId != null) 'annotationId': [annotationId],
      if (country != null) 'country': [country],
      if (showOnlySummaryInResponse != null)
        'showOnlySummaryInResponse': ['${showOnlySummaryInResponse}'],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/mylibrary/annotations';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Annotation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of annotations, possibly filtered.
  ///
  /// Request parameters:
  ///
  /// [contentVersion] - The content version for the requested volume.
  ///
  /// [layerId] - The layer ID to limit annotation by.
  ///
  /// [layerIds] - The layer ID(s) to limit annotation by.
  ///
  /// [maxResults] - Maximum number of results to return
  /// Value must be between "0" and "40".
  ///
  /// [pageToken] - The value of the nextToken from the previous page.
  ///
  /// [showDeleted] - Set to true to return deleted annotations. updatedMin must
  /// be in the request to use this. Defaults to false.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [updatedMax] - RFC 3339 timestamp to restrict to items updated prior to
  /// this timestamp (exclusive).
  ///
  /// [updatedMin] - RFC 3339 timestamp to restrict to items updated since this
  /// timestamp (inclusive).
  ///
  /// [volumeId] - The volume to restrict annotations to.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Annotations].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Annotations> list({
    core.String? contentVersion,
    core.String? layerId,
    core.List<core.String>? layerIds,
    core.int? maxResults,
    core.String? pageToken,
    core.bool? showDeleted,
    core.String? source,
    core.String? updatedMax,
    core.String? updatedMin,
    core.String? volumeId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (contentVersion != null) 'contentVersion': [contentVersion],
      if (layerId != null) 'layerId': [layerId],
      if (layerIds != null) 'layerIds': layerIds,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (showDeleted != null) 'showDeleted': ['${showDeleted}'],
      if (source != null) 'source': [source],
      if (updatedMax != null) 'updatedMax': [updatedMax],
      if (updatedMin != null) 'updatedMin': [updatedMin],
      if (volumeId != null) 'volumeId': [volumeId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/mylibrary/annotations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Annotations.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the summary of specified layers.
  ///
  /// Request parameters:
  ///
  /// [layerIds] - Array of layer IDs to get the summary for.
  ///
  /// [volumeId] - Volume id to get the summary for.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AnnotationsSummary].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AnnotationsSummary> summary(
    core.List<core.String> layerIds,
    core.String volumeId, {
    core.String? $fields,
  }) async {
    if (layerIds.isEmpty) {
      throw core.ArgumentError('Parameter layerIds cannot be empty.');
    }
    final _queryParams = <core.String, core.List<core.String>>{
      'layerIds': layerIds,
      'volumeId': [volumeId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/mylibrary/annotations/summary';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return AnnotationsSummary.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing annotation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [annotationId] - The ID for the annotation to update.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Annotation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Annotation> update(
    Annotation request,
    core.String annotationId, {
    core.String? source,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/mylibrary/annotations/' +
        commons.escapeVariable('$annotationId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Annotation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MylibraryBookshelvesResource {
  final commons.ApiRequester _requester;

  MylibraryBookshelvesVolumesResource get volumes =>
      MylibraryBookshelvesVolumesResource(_requester);

  MylibraryBookshelvesResource(commons.ApiRequester client)
      : _requester = client;

  /// Adds a volume to a bookshelf.
  ///
  /// Request parameters:
  ///
  /// [shelf] - ID of bookshelf to which to add a volume.
  ///
  /// [volumeId] - ID of volume to add.
  ///
  /// [reason] - The reason for which the book is added to the library.
  /// Possible string values are:
  /// - "REASON_UNDEFINED"
  /// - "IOS_PREX" : Volumes added from the PREX flow on iOS.
  /// - "IOS_SEARCH" : Volumes added from the Search flow on iOS.
  /// - "ONBOARDING" : Volumes added from the Onboarding flow.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> addVolume(
    core.String shelf,
    core.String volumeId, {
    core.String? reason,
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'volumeId': [volumeId],
      if (reason != null) 'reason': [reason],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/mylibrary/bookshelves/' +
        commons.escapeVariable('$shelf') +
        '/addVolume';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Clears all volumes from a bookshelf.
  ///
  /// Request parameters:
  ///
  /// [shelf] - ID of bookshelf from which to remove a volume.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> clearVolumes(
    core.String shelf, {
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/mylibrary/bookshelves/' +
        commons.escapeVariable('$shelf') +
        '/clearVolumes';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves metadata for a specific bookshelf belonging to the authenticated
  /// user.
  ///
  /// Request parameters:
  ///
  /// [shelf] - ID of bookshelf to retrieve.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Bookshelf].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Bookshelf> get(
    core.String shelf, {
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'books/v1/mylibrary/bookshelves/' + commons.escapeVariable('$shelf');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Bookshelf.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of bookshelves belonging to the authenticated user.
  ///
  /// Request parameters:
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Bookshelves].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Bookshelves> list({
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/mylibrary/bookshelves';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Bookshelves.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Moves a volume within a bookshelf.
  ///
  /// Request parameters:
  ///
  /// [shelf] - ID of bookshelf with the volume.
  ///
  /// [volumeId] - ID of volume to move.
  ///
  /// [volumePosition] - Position on shelf to move the item (0 puts the item
  /// before the current first item, 1 puts it between the first and the second
  /// and so on.)
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> moveVolume(
    core.String shelf,
    core.String volumeId,
    core.int volumePosition, {
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'volumeId': [volumeId],
      'volumePosition': ['${volumePosition}'],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/mylibrary/bookshelves/' +
        commons.escapeVariable('$shelf') +
        '/moveVolume';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Removes a volume from a bookshelf.
  ///
  /// Request parameters:
  ///
  /// [shelf] - ID of bookshelf from which to remove a volume.
  ///
  /// [volumeId] - ID of volume to remove.
  ///
  /// [reason] - The reason for which the book is removed from the library.
  /// Possible string values are:
  /// - "REASON_UNDEFINED"
  /// - "ONBOARDING" : Samples removed from the Onboarding flow.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> removeVolume(
    core.String shelf,
    core.String volumeId, {
    core.String? reason,
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'volumeId': [volumeId],
      if (reason != null) 'reason': [reason],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/mylibrary/bookshelves/' +
        commons.escapeVariable('$shelf') +
        '/removeVolume';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class MylibraryBookshelvesVolumesResource {
  final commons.ApiRequester _requester;

  MylibraryBookshelvesVolumesResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets volume information for volumes on a bookshelf.
  ///
  /// Request parameters:
  ///
  /// [shelf] - The bookshelf ID or name retrieve volumes for.
  ///
  /// [country] - ISO-3166-1 code to override the IP-based location.
  ///
  /// [maxResults] - Maximum number of results to return
  ///
  /// [projection] - Restrict information returned to a set of selected fields.
  /// Possible string values are:
  /// - "PROJECTION_UNDEFINED"
  /// - "FULL" : Includes all volume data.
  /// - "LITE" : Includes a subset of fields in volumeInfo and accessInfo.
  ///
  /// [q] - Full-text search query string in this bookshelf.
  ///
  /// [showPreorders] - Set to true to show pre-ordered books. Defaults to
  /// false.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [startIndex] - Index of the first element to return (starts at 0)
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Volumes].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Volumes> list(
    core.String shelf, {
    core.String? country,
    core.int? maxResults,
    core.String? projection,
    core.String? q,
    core.bool? showPreorders,
    core.String? source,
    core.int? startIndex,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (country != null) 'country': [country],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (projection != null) 'projection': [projection],
      if (q != null) 'q': [q],
      if (showPreorders != null) 'showPreorders': ['${showPreorders}'],
      if (source != null) 'source': [source],
      if (startIndex != null) 'startIndex': ['${startIndex}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/mylibrary/bookshelves/' +
        commons.escapeVariable('$shelf') +
        '/volumes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Volumes.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class MylibraryReadingpositionsResource {
  final commons.ApiRequester _requester;

  MylibraryReadingpositionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Retrieves my reading position information for a volume.
  ///
  /// Request parameters:
  ///
  /// [volumeId] - ID of volume for which to retrieve a reading position.
  ///
  /// [contentVersion] - Volume content version for which this reading position
  /// is requested.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReadingPosition].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReadingPosition> get(
    core.String volumeId, {
    core.String? contentVersion,
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (contentVersion != null) 'contentVersion': [contentVersion],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/mylibrary/readingpositions/' +
        commons.escapeVariable('$volumeId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ReadingPosition.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets my reading position information for a volume.
  ///
  /// Request parameters:
  ///
  /// [volumeId] - ID of volume for which to update the reading position.
  ///
  /// [position] - Position string for the new volume reading position.
  ///
  /// [timestamp] - RFC 3339 UTC format timestamp associated with this reading
  /// position.
  ///
  /// [action] - Action that caused this reading position to be set.
  /// Possible string values are:
  /// - "ACTION_UNDEFINED"
  /// - "bookmark" : User chose bookmark within volume.
  /// - "chapter" : User selected chapter from list.
  /// - "next-page" : Next page event.
  /// - "prev-page" : Previous page event.
  /// - "scroll" : User navigated to page.
  /// - "search" : User chose search results within volume.
  ///
  /// [contentVersion] - Volume content version for which this reading position
  /// applies.
  ///
  /// [deviceCookie] - Random persistent device cookie optional on set position.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> setPosition(
    core.String volumeId,
    core.String position,
    core.String timestamp, {
    core.String? action,
    core.String? contentVersion,
    core.String? deviceCookie,
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'position': [position],
      'timestamp': [timestamp],
      if (action != null) 'action': [action],
      if (contentVersion != null) 'contentVersion': [contentVersion],
      if (deviceCookie != null) 'deviceCookie': [deviceCookie],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/mylibrary/readingpositions/' +
        commons.escapeVariable('$volumeId') +
        '/setPosition';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class NotificationResource {
  final commons.ApiRequester _requester;

  NotificationResource(commons.ApiRequester client) : _requester = client;

  /// Returns notification details for a given notification id.
  ///
  /// Request parameters:
  ///
  /// [notificationId] - String to identify the notification.
  ///
  /// [locale] - ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  /// Used for generating notification title and body.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Notification].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Notification> get(
    core.String notificationId, {
    core.String? locale,
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'notification_id': [notificationId],
      if (locale != null) 'locale': [locale],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/notification/get';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Notification.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OnboardingResource {
  final commons.ApiRequester _requester;

  OnboardingResource(commons.ApiRequester client) : _requester = client;

  /// List categories for onboarding experience.
  ///
  /// Request parameters:
  ///
  /// [locale] - ISO-639-1 language and ISO-3166-1 country code. Default is
  /// en-US if unset.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Category].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Category> listCategories({
    core.String? locale,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (locale != null) 'locale': [locale],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/onboarding/listCategories';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Category.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List available volumes under categories for onboarding experience.
  ///
  /// Request parameters:
  ///
  /// [categoryId] - List of category ids requested.
  ///
  /// [locale] - ISO-639-1 language and ISO-3166-1 country code. Default is
  /// en-US if unset.
  ///
  /// [maxAllowedMaturityRating] - The maximum allowed maturity rating of
  /// returned volumes. Books with a higher maturity rating are filtered out.
  /// Possible string values are:
  /// - "MAX_ALLOWED_MATURITY_RATING_UNDEFINED"
  /// - "MATURE" : Show books which are rated mature or lower.
  /// - "not-mature" : Show books which are rated not mature.
  ///
  /// [pageSize] - Number of maximum results per page to be included in the
  /// response.
  ///
  /// [pageToken] - The value of the nextToken from the previous page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Volume2].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Volume2> listCategoryVolumes({
    core.List<core.String>? categoryId,
    core.String? locale,
    core.String? maxAllowedMaturityRating,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (categoryId != null) 'categoryId': categoryId,
      if (locale != null) 'locale': [locale],
      if (maxAllowedMaturityRating != null)
        'maxAllowedMaturityRating': [maxAllowedMaturityRating],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/onboarding/listCategoryVolumes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Volume2.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class PersonalizedstreamResource {
  final commons.ApiRequester _requester;

  PersonalizedstreamResource(commons.ApiRequester client) : _requester = client;

  /// Returns a stream of personalized book clusters
  ///
  /// Request parameters:
  ///
  /// [locale] - ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  /// Used for generating recommendations.
  ///
  /// [maxAllowedMaturityRating] - The maximum allowed maturity rating of
  /// returned recommendations. Books with a higher maturity rating are filtered
  /// out.
  /// Possible string values are:
  /// - "MAX_ALLOWED_MATURITY_RATING_UNDEFINED"
  /// - "MATURE" : Show books which are rated mature or lower.
  /// - "not-mature" : Show books which are rated not mature.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Discoveryclusters].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Discoveryclusters> get({
    core.String? locale,
    core.String? maxAllowedMaturityRating,
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (locale != null) 'locale': [locale],
      if (maxAllowedMaturityRating != null)
        'maxAllowedMaturityRating': [maxAllowedMaturityRating],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/personalizedstream/get';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Discoveryclusters.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PromoofferResource {
  final commons.ApiRequester _requester;

  PromoofferResource(commons.ApiRequester client) : _requester = client;

  /// Accepts the promo offer.
  ///
  /// Request parameters:
  ///
  /// [androidId] - device android_id
  ///
  /// [device] - device device
  ///
  /// [manufacturer] - device manufacturer
  ///
  /// [model] - device model
  ///
  /// [offerId] - null
  ///
  /// [product] - device product
  ///
  /// [serial] - device serial
  ///
  /// [volumeId] - Volume id to exercise the offer
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> accept({
    core.String? androidId,
    core.String? device,
    core.String? manufacturer,
    core.String? model,
    core.String? offerId,
    core.String? product,
    core.String? serial,
    core.String? volumeId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (androidId != null) 'androidId': [androidId],
      if (device != null) 'device': [device],
      if (manufacturer != null) 'manufacturer': [manufacturer],
      if (model != null) 'model': [model],
      if (offerId != null) 'offerId': [offerId],
      if (product != null) 'product': [product],
      if (serial != null) 'serial': [serial],
      if (volumeId != null) 'volumeId': [volumeId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/promooffer/accept';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Marks the promo offer as dismissed.
  ///
  /// Request parameters:
  ///
  /// [androidId] - device android_id
  ///
  /// [device] - device device
  ///
  /// [manufacturer] - device manufacturer
  ///
  /// [model] - device model
  ///
  /// [offerId] - Offer to dimiss
  ///
  /// [product] - device product
  ///
  /// [serial] - device serial
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> dismiss({
    core.String? androidId,
    core.String? device,
    core.String? manufacturer,
    core.String? model,
    core.String? offerId,
    core.String? product,
    core.String? serial,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (androidId != null) 'androidId': [androidId],
      if (device != null) 'device': [device],
      if (manufacturer != null) 'manufacturer': [manufacturer],
      if (model != null) 'model': [model],
      if (offerId != null) 'offerId': [offerId],
      if (product != null) 'product': [product],
      if (serial != null) 'serial': [serial],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/promooffer/dismiss';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns a list of promo offers available to the user
  ///
  /// Request parameters:
  ///
  /// [androidId] - device android_id
  ///
  /// [device] - device device
  ///
  /// [manufacturer] - device manufacturer
  ///
  /// [model] - device model
  ///
  /// [product] - device product
  ///
  /// [serial] - device serial
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Offers].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Offers> get({
    core.String? androidId,
    core.String? device,
    core.String? manufacturer,
    core.String? model,
    core.String? product,
    core.String? serial,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (androidId != null) 'androidId': [androidId],
      if (device != null) 'device': [device],
      if (manufacturer != null) 'manufacturer': [manufacturer],
      if (model != null) 'model': [model],
      if (product != null) 'product': [product],
      if (serial != null) 'serial': [serial],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/promooffer/get';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Offers.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SeriesResource {
  final commons.ApiRequester _requester;

  SeriesMembershipResource get membership =>
      SeriesMembershipResource(_requester);

  SeriesResource(commons.ApiRequester client) : _requester = client;

  /// Returns Series metadata for the given series ids.
  ///
  /// Request parameters:
  ///
  /// [seriesId] - String that identifies the series
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Series].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Series> get(
    core.List<core.String> seriesId, {
    core.String? $fields,
  }) async {
    if (seriesId.isEmpty) {
      throw core.ArgumentError('Parameter seriesId cannot be empty.');
    }
    final _queryParams = <core.String, core.List<core.String>>{
      'series_id': seriesId,
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/series/get';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Series.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SeriesMembershipResource {
  final commons.ApiRequester _requester;

  SeriesMembershipResource(commons.ApiRequester client) : _requester = client;

  /// Returns Series membership data given the series id.
  ///
  /// Request parameters:
  ///
  /// [seriesId] - String that identifies the series
  ///
  /// [pageSize] - Number of maximum results per page to be included in the
  /// response.
  ///
  /// [pageToken] - The value of the nextToken from the previous page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Seriesmembership].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Seriesmembership> get(
    core.String seriesId, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'series_id': [seriesId],
      if (pageSize != null) 'page_size': ['${pageSize}'],
      if (pageToken != null) 'page_token': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/series/membership/get';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Seriesmembership.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class VolumesResource {
  final commons.ApiRequester _requester;

  VolumesAssociatedResource get associated =>
      VolumesAssociatedResource(_requester);
  VolumesMybooksResource get mybooks => VolumesMybooksResource(_requester);
  VolumesRecommendedResource get recommended =>
      VolumesRecommendedResource(_requester);
  VolumesUseruploadedResource get useruploaded =>
      VolumesUseruploadedResource(_requester);

  VolumesResource(commons.ApiRequester client) : _requester = client;

  /// Gets volume information for a single volume.
  ///
  /// Request parameters:
  ///
  /// [volumeId] - ID of volume to retrieve.
  ///
  /// [country] - ISO-3166-1 code to override the IP-based location.
  ///
  /// [includeNonComicsSeries] - Set to true to include non-comics series.
  /// Defaults to false.
  ///
  /// [partner] - Brand results for partner ID.
  ///
  /// [projection] - Restrict information returned to a set of selected fields.
  /// Possible string values are:
  /// - "PROJECTION_UNDEFINED"
  /// - "FULL" : Includes all volume data.
  /// - "LITE" : Includes a subset of fields in volumeInfo and accessInfo.
  ///
  /// [source] - string to identify the originator of this request.
  ///
  /// [userLibraryConsistentRead] - null
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Volume].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Volume> get(
    core.String volumeId, {
    core.String? country,
    core.bool? includeNonComicsSeries,
    core.String? partner,
    core.String? projection,
    core.String? source,
    core.bool? userLibraryConsistentRead,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (country != null) 'country': [country],
      if (includeNonComicsSeries != null)
        'includeNonComicsSeries': ['${includeNonComicsSeries}'],
      if (partner != null) 'partner': [partner],
      if (projection != null) 'projection': [projection],
      if (source != null) 'source': [source],
      if (userLibraryConsistentRead != null)
        'user_library_consistent_read': ['${userLibraryConsistentRead}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/volumes/' + commons.escapeVariable('$volumeId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Volume.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Performs a book search.
  ///
  /// Request parameters:
  ///
  /// [q] - Full-text search query string.
  ///
  /// [download] - Restrict to volumes by download availability.
  /// Possible string values are:
  /// - "DOWNLOAD_UNDEFINED"
  /// - "EPUB" : All volumes with epub.
  ///
  /// [filter] - Filter search results.
  /// Possible string values are:
  /// - "FILTER_UNDEFINED"
  /// - "ebooks" : All Google eBooks.
  /// - "free-ebooks" : Google eBook with full volume text viewability.
  /// - "full" : Public can view entire volume text.
  /// - "paid-ebooks" : Google eBook with a price.
  /// - "partial" : Public able to see parts of text.
  ///
  /// [langRestrict] - Restrict results to books with this language code.
  ///
  /// [libraryRestrict] - Restrict search to this user's library.
  /// Possible string values are:
  /// - "LIBRARY_RESTRICT_UNDEFINED"
  /// - "my-library" : Restrict to the user's library, any shelf.
  /// - "no-restrict" : Do not restrict based on user's library.
  ///
  /// [maxAllowedMaturityRating] - The maximum allowed maturity rating of
  /// returned recommendations. Books with a higher maturity rating are filtered
  /// out.
  /// Possible string values are:
  /// - "MAX_ALLOWED_MATURITY_RATING_UNDEFINED"
  /// - "MATURE" : Show books which are rated mature or lower.
  /// - "not-mature" : Show books which are rated not mature.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "40".
  ///
  /// [orderBy] - Sort search results.
  /// Possible string values are:
  /// - "ORDER_BY_UNDEFINED"
  /// - "newest" : Most recently published.
  /// - "relevance" : Relevance to search terms.
  ///
  /// [partner] - Restrict and brand results for partner ID.
  ///
  /// [printType] - Restrict to books or magazines.
  /// Possible string values are:
  /// - "PRINT_TYPE_UNDEFINED"
  /// - "ALL" : All volume content types.
  /// - "BOOKS" : Just books.
  /// - "MAGAZINES" : Just magazines.
  ///
  /// [projection] - Restrict information returned to a set of selected fields.
  /// Possible string values are:
  /// - "PROJECTION_UNDEFINED"
  /// - "FULL" : Includes all volume data.
  /// - "LITE" : Includes a subset of fields in volumeInfo and accessInfo.
  ///
  /// [showPreorders] - Set to true to show books available for preorder.
  /// Defaults to false.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [startIndex] - Index of the first result to return (starts at 0)
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Volumes].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Volumes> list(
    core.String q, {
    core.String? download,
    core.String? filter,
    core.String? langRestrict,
    core.String? libraryRestrict,
    core.String? maxAllowedMaturityRating,
    core.int? maxResults,
    core.String? orderBy,
    core.String? partner,
    core.String? printType,
    core.String? projection,
    core.bool? showPreorders,
    core.String? source,
    core.int? startIndex,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'q': [q],
      if (download != null) 'download': [download],
      if (filter != null) 'filter': [filter],
      if (langRestrict != null) 'langRestrict': [langRestrict],
      if (libraryRestrict != null) 'libraryRestrict': [libraryRestrict],
      if (maxAllowedMaturityRating != null)
        'maxAllowedMaturityRating': [maxAllowedMaturityRating],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (partner != null) 'partner': [partner],
      if (printType != null) 'printType': [printType],
      if (projection != null) 'projection': [projection],
      if (showPreorders != null) 'showPreorders': ['${showPreorders}'],
      if (source != null) 'source': [source],
      if (startIndex != null) 'startIndex': ['${startIndex}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/volumes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Volumes.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class VolumesAssociatedResource {
  final commons.ApiRequester _requester;

  VolumesAssociatedResource(commons.ApiRequester client) : _requester = client;

  /// Return a list of associated books.
  ///
  /// Request parameters:
  ///
  /// [volumeId] - ID of the source volume.
  ///
  /// [association] - Association type.
  /// Possible string values are:
  /// - "ASSOCIATION_UNDEFINED"
  /// - "end-of-sample" : Recommendations for display end-of-sample.
  /// - "end-of-volume" : Recommendations for display end-of-volume.
  /// - "related-for-play" : Related volumes for Play Store.
  ///
  /// [locale] - ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  /// Used for generating recommendations.
  ///
  /// [maxAllowedMaturityRating] - The maximum allowed maturity rating of
  /// returned recommendations. Books with a higher maturity rating are filtered
  /// out.
  /// Possible string values are:
  /// - "MAX_ALLOWED_MATURITY_RATING_UNDEFINED"
  /// - "MATURE" : Show books which are rated mature or lower.
  /// - "not-mature" : Show books which are rated not mature.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Volumes].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Volumes> list(
    core.String volumeId, {
    core.String? association,
    core.String? locale,
    core.String? maxAllowedMaturityRating,
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (association != null) 'association': [association],
      if (locale != null) 'locale': [locale],
      if (maxAllowedMaturityRating != null)
        'maxAllowedMaturityRating': [maxAllowedMaturityRating],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'books/v1/volumes/' +
        commons.escapeVariable('$volumeId') +
        '/associated';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Volumes.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class VolumesMybooksResource {
  final commons.ApiRequester _requester;

  VolumesMybooksResource(commons.ApiRequester client) : _requester = client;

  /// Return a list of books in My Library.
  ///
  /// Request parameters:
  ///
  /// [acquireMethod] - How the book was acquired
  ///
  /// [country] - ISO-3166-1 code to override the IP-based location.
  ///
  /// [locale] - ISO-639-1 language and ISO-3166-1 country code. Ex:'en_US'.
  /// Used for generating recommendations.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "100".
  ///
  /// [processingState] - The processing state of the user uploaded volumes to
  /// be returned. Applicable only if the UPLOADED is specified in the
  /// acquireMethod.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [startIndex] - Index of the first result to return (starts at 0)
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Volumes].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Volumes> list({
    core.List<core.String>? acquireMethod,
    core.String? country,
    core.String? locale,
    core.int? maxResults,
    core.List<core.String>? processingState,
    core.String? source,
    core.int? startIndex,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (acquireMethod != null) 'acquireMethod': acquireMethod,
      if (country != null) 'country': [country],
      if (locale != null) 'locale': [locale],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (processingState != null) 'processingState': processingState,
      if (source != null) 'source': [source],
      if (startIndex != null) 'startIndex': ['${startIndex}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/volumes/mybooks';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Volumes.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class VolumesRecommendedResource {
  final commons.ApiRequester _requester;

  VolumesRecommendedResource(commons.ApiRequester client) : _requester = client;

  /// Return a list of recommended books for the current user.
  ///
  /// Request parameters:
  ///
  /// [locale] - ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  /// Used for generating recommendations.
  ///
  /// [maxAllowedMaturityRating] - The maximum allowed maturity rating of
  /// returned recommendations. Books with a higher maturity rating are filtered
  /// out.
  /// Possible string values are:
  /// - "MAX_ALLOWED_MATURITY_RATING_UNDEFINED"
  /// - "MATURE" : Show books which are rated mature or lower.
  /// - "not-mature" : Show books which are rated not mature.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Volumes].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Volumes> list({
    core.String? locale,
    core.String? maxAllowedMaturityRating,
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (locale != null) 'locale': [locale],
      if (maxAllowedMaturityRating != null)
        'maxAllowedMaturityRating': [maxAllowedMaturityRating],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/volumes/recommended';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Volumes.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Rate a recommended book for the current user.
  ///
  /// Request parameters:
  ///
  /// [rating] - Rating to be given to the volume.
  /// Possible string values are:
  /// - "RATING_UNDEFINED"
  /// - "HAVE_IT" : Rating indicating a dismissal due to ownership.
  /// - "NOT_INTERESTED" : Rating indicating a negative dismissal of a volume.
  ///
  /// [volumeId] - ID of the source volume.
  ///
  /// [locale] - ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  /// Used for generating recommendations.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BooksVolumesRecommendedRateResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BooksVolumesRecommendedRateResponse> rate(
    core.String rating,
    core.String volumeId, {
    core.String? locale,
    core.String? source,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'rating': [rating],
      'volumeId': [volumeId],
      if (locale != null) 'locale': [locale],
      if (source != null) 'source': [source],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/volumes/recommended/rate';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return BooksVolumesRecommendedRateResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class VolumesUseruploadedResource {
  final commons.ApiRequester _requester;

  VolumesUseruploadedResource(commons.ApiRequester client)
      : _requester = client;

  /// Return a list of books uploaded by the current user.
  ///
  /// Request parameters:
  ///
  /// [locale] - ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  /// Used for generating recommendations.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "40".
  ///
  /// [processingState] - The processing state of the user uploaded volumes to
  /// be returned.
  ///
  /// [source] - String to identify the originator of this request.
  ///
  /// [startIndex] - Index of the first result to return (starts at 0)
  ///
  /// [volumeId] - The ids of the volumes to be returned. If not specified all
  /// that match the processingState are returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Volumes].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Volumes> list({
    core.String? locale,
    core.int? maxResults,
    core.List<core.String>? processingState,
    core.String? source,
    core.int? startIndex,
    core.List<core.String>? volumeId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (locale != null) 'locale': [locale],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (processingState != null) 'processingState': processingState,
      if (source != null) 'source': [source],
      if (startIndex != null) 'startIndex': ['${startIndex}'],
      if (volumeId != null) 'volumeId': volumeId,
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'books/v1/volumes/useruploaded';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Volumes.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// Selection ranges sent from the client.
class AnnotationClientVersionRanges {
  /// Range in CFI format for this annotation sent by client.
  BooksAnnotationsRange? cfiRange;

  /// Content version the client sent in.
  core.String? contentVersion;

  /// Range in GB image format for this annotation sent by client.
  BooksAnnotationsRange? gbImageRange;

  /// Range in GB text format for this annotation sent by client.
  BooksAnnotationsRange? gbTextRange;

  /// Range in image CFI format for this annotation sent by client.
  BooksAnnotationsRange? imageCfiRange;

  AnnotationClientVersionRanges();

  AnnotationClientVersionRanges.fromJson(core.Map _json) {
    if (_json.containsKey('cfiRange')) {
      cfiRange = BooksAnnotationsRange.fromJson(
          _json['cfiRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentVersion')) {
      contentVersion = _json['contentVersion'] as core.String;
    }
    if (_json.containsKey('gbImageRange')) {
      gbImageRange = BooksAnnotationsRange.fromJson(
          _json['gbImageRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gbTextRange')) {
      gbTextRange = BooksAnnotationsRange.fromJson(
          _json['gbTextRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('imageCfiRange')) {
      imageCfiRange = BooksAnnotationsRange.fromJson(
          _json['imageCfiRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cfiRange != null) 'cfiRange': cfiRange!.toJson(),
        if (contentVersion != null) 'contentVersion': contentVersion!,
        if (gbImageRange != null) 'gbImageRange': gbImageRange!.toJson(),
        if (gbTextRange != null) 'gbTextRange': gbTextRange!.toJson(),
        if (imageCfiRange != null) 'imageCfiRange': imageCfiRange!.toJson(),
      };
}

/// Selection ranges for the most recent content version.
class AnnotationCurrentVersionRanges {
  /// Range in CFI format for this annotation for version above.
  BooksAnnotationsRange? cfiRange;

  /// Content version applicable to ranges below.
  core.String? contentVersion;

  /// Range in GB image format for this annotation for version above.
  BooksAnnotationsRange? gbImageRange;

  /// Range in GB text format for this annotation for version above.
  BooksAnnotationsRange? gbTextRange;

  /// Range in image CFI format for this annotation for version above.
  BooksAnnotationsRange? imageCfiRange;

  AnnotationCurrentVersionRanges();

  AnnotationCurrentVersionRanges.fromJson(core.Map _json) {
    if (_json.containsKey('cfiRange')) {
      cfiRange = BooksAnnotationsRange.fromJson(
          _json['cfiRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentVersion')) {
      contentVersion = _json['contentVersion'] as core.String;
    }
    if (_json.containsKey('gbImageRange')) {
      gbImageRange = BooksAnnotationsRange.fromJson(
          _json['gbImageRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gbTextRange')) {
      gbTextRange = BooksAnnotationsRange.fromJson(
          _json['gbTextRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('imageCfiRange')) {
      imageCfiRange = BooksAnnotationsRange.fromJson(
          _json['imageCfiRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cfiRange != null) 'cfiRange': cfiRange!.toJson(),
        if (contentVersion != null) 'contentVersion': contentVersion!,
        if (gbImageRange != null) 'gbImageRange': gbImageRange!.toJson(),
        if (gbTextRange != null) 'gbTextRange': gbTextRange!.toJson(),
        if (imageCfiRange != null) 'imageCfiRange': imageCfiRange!.toJson(),
      };
}

class AnnotationLayerSummary {
  /// Maximum allowed characters on this layer, especially for the "copy" layer.
  core.int? allowedCharacterCount;

  /// Type of limitation on this layer.
  ///
  /// "limited" or "unlimited" for the "copy" layer.
  core.String? limitType;

  /// Remaining allowed characters on this layer, especially for the "copy"
  /// layer.
  core.int? remainingCharacterCount;

  AnnotationLayerSummary();

  AnnotationLayerSummary.fromJson(core.Map _json) {
    if (_json.containsKey('allowedCharacterCount')) {
      allowedCharacterCount = _json['allowedCharacterCount'] as core.int;
    }
    if (_json.containsKey('limitType')) {
      limitType = _json['limitType'] as core.String;
    }
    if (_json.containsKey('remainingCharacterCount')) {
      remainingCharacterCount = _json['remainingCharacterCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedCharacterCount != null)
          'allowedCharacterCount': allowedCharacterCount!,
        if (limitType != null) 'limitType': limitType!,
        if (remainingCharacterCount != null)
          'remainingCharacterCount': remainingCharacterCount!,
      };
}

class Annotation {
  /// Anchor text after excerpt.
  ///
  /// For requests, if the user bookmarked a screen that has no flowing text on
  /// it, then this field should be empty.
  core.String? afterSelectedText;

  /// Anchor text before excerpt.
  ///
  /// For requests, if the user bookmarked a screen that has no flowing text on
  /// it, then this field should be empty.
  core.String? beforeSelectedText;

  /// Selection ranges sent from the client.
  AnnotationClientVersionRanges? clientVersionRanges;

  /// Timestamp for the created time of this annotation.
  core.String? created;

  /// Selection ranges for the most recent content version.
  AnnotationCurrentVersionRanges? currentVersionRanges;

  /// User-created data for this annotation.
  core.String? data;

  /// Indicates that this annotation is deleted.
  core.bool? deleted;

  /// The highlight style for this annotation.
  core.String? highlightStyle;

  /// Id of this annotation, in the form of a GUID.
  core.String? id;

  /// Resource type.
  core.String? kind;

  /// The layer this annotation is for.
  core.String? layerId;
  AnnotationLayerSummary? layerSummary;

  /// Pages that this annotation spans.
  core.List<core.String>? pageIds;

  /// Excerpt from the volume.
  core.String? selectedText;

  /// URL to this resource.
  core.String? selfLink;

  /// Timestamp for the last time this annotation was modified.
  core.String? updated;

  /// The volume that this annotation belongs to.
  core.String? volumeId;

  Annotation();

  Annotation.fromJson(core.Map _json) {
    if (_json.containsKey('afterSelectedText')) {
      afterSelectedText = _json['afterSelectedText'] as core.String;
    }
    if (_json.containsKey('beforeSelectedText')) {
      beforeSelectedText = _json['beforeSelectedText'] as core.String;
    }
    if (_json.containsKey('clientVersionRanges')) {
      clientVersionRanges = AnnotationClientVersionRanges.fromJson(
          _json['clientVersionRanges'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('created')) {
      created = _json['created'] as core.String;
    }
    if (_json.containsKey('currentVersionRanges')) {
      currentVersionRanges = AnnotationCurrentVersionRanges.fromJson(
          _json['currentVersionRanges'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('data')) {
      data = _json['data'] as core.String;
    }
    if (_json.containsKey('deleted')) {
      deleted = _json['deleted'] as core.bool;
    }
    if (_json.containsKey('highlightStyle')) {
      highlightStyle = _json['highlightStyle'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('layerId')) {
      layerId = _json['layerId'] as core.String;
    }
    if (_json.containsKey('layerSummary')) {
      layerSummary = AnnotationLayerSummary.fromJson(
          _json['layerSummary'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pageIds')) {
      pageIds = (_json['pageIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('selectedText')) {
      selectedText = _json['selectedText'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('updated')) {
      updated = _json['updated'] as core.String;
    }
    if (_json.containsKey('volumeId')) {
      volumeId = _json['volumeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (afterSelectedText != null) 'afterSelectedText': afterSelectedText!,
        if (beforeSelectedText != null)
          'beforeSelectedText': beforeSelectedText!,
        if (clientVersionRanges != null)
          'clientVersionRanges': clientVersionRanges!.toJson(),
        if (created != null) 'created': created!,
        if (currentVersionRanges != null)
          'currentVersionRanges': currentVersionRanges!.toJson(),
        if (data != null) 'data': data!,
        if (deleted != null) 'deleted': deleted!,
        if (highlightStyle != null) 'highlightStyle': highlightStyle!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (layerId != null) 'layerId': layerId!,
        if (layerSummary != null) 'layerSummary': layerSummary!.toJson(),
        if (pageIds != null) 'pageIds': pageIds!,
        if (selectedText != null) 'selectedText': selectedText!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (updated != null) 'updated': updated!,
        if (volumeId != null) 'volumeId': volumeId!,
      };
}

class Annotations {
  /// A list of annotations.
  core.List<Annotation>? items;

  /// Resource type.
  core.String? kind;

  /// Token to pass in for pagination for the next page.
  ///
  /// This will not be present if this request does not have more results.
  core.String? nextPageToken;

  /// Total number of annotations found.
  ///
  /// This may be greater than the number of notes returned in this response if
  /// results have been paginated.
  core.int? totalItems;

  Annotations();

  Annotations.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Annotation>((value) =>
              Annotation.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('totalItems')) {
      totalItems = _json['totalItems'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (totalItems != null) 'totalItems': totalItems!,
      };
}

class AnnotationsSummaryLayers {
  core.int? allowedCharacterCount;
  core.String? layerId;
  core.String? limitType;
  core.int? remainingCharacterCount;
  core.String? updated;

  AnnotationsSummaryLayers();

  AnnotationsSummaryLayers.fromJson(core.Map _json) {
    if (_json.containsKey('allowedCharacterCount')) {
      allowedCharacterCount = _json['allowedCharacterCount'] as core.int;
    }
    if (_json.containsKey('layerId')) {
      layerId = _json['layerId'] as core.String;
    }
    if (_json.containsKey('limitType')) {
      limitType = _json['limitType'] as core.String;
    }
    if (_json.containsKey('remainingCharacterCount')) {
      remainingCharacterCount = _json['remainingCharacterCount'] as core.int;
    }
    if (_json.containsKey('updated')) {
      updated = _json['updated'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedCharacterCount != null)
          'allowedCharacterCount': allowedCharacterCount!,
        if (layerId != null) 'layerId': layerId!,
        if (limitType != null) 'limitType': limitType!,
        if (remainingCharacterCount != null)
          'remainingCharacterCount': remainingCharacterCount!,
        if (updated != null) 'updated': updated!,
      };
}

class AnnotationsSummary {
  core.String? kind;
  core.List<AnnotationsSummaryLayers>? layers;

  AnnotationsSummary();

  AnnotationsSummary.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('layers')) {
      layers = (_json['layers'] as core.List)
          .map<AnnotationsSummaryLayers>((value) =>
              AnnotationsSummaryLayers.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (layers != null)
          'layers': layers!.map((value) => value.toJson()).toList(),
      };
}

class Annotationsdata {
  /// A list of Annotation Data.
  core.List<GeoAnnotationdata>? items;

  /// Resource type
  core.String? kind;

  /// Token to pass in for pagination for the next page.
  ///
  /// This will not be present if this request does not have more results.
  core.String? nextPageToken;

  /// The total number of volume annotations found.
  core.int? totalItems;

  Annotationsdata();

  Annotationsdata.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<GeoAnnotationdata>((value) => GeoAnnotationdata.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('totalItems')) {
      totalItems = _json['totalItems'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (totalItems != null) 'totalItems': totalItems!,
      };
}

class BooksAnnotationsRange {
  /// The offset from the ending position.
  core.String? endOffset;

  /// The ending position for the range.
  core.String? endPosition;

  /// The offset from the starting position.
  core.String? startOffset;

  /// The starting position for the range.
  core.String? startPosition;

  BooksAnnotationsRange();

  BooksAnnotationsRange.fromJson(core.Map _json) {
    if (_json.containsKey('endOffset')) {
      endOffset = _json['endOffset'] as core.String;
    }
    if (_json.containsKey('endPosition')) {
      endPosition = _json['endPosition'] as core.String;
    }
    if (_json.containsKey('startOffset')) {
      startOffset = _json['startOffset'] as core.String;
    }
    if (_json.containsKey('startPosition')) {
      startPosition = _json['startPosition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endOffset != null) 'endOffset': endOffset!,
        if (endPosition != null) 'endPosition': endPosition!,
        if (startOffset != null) 'startOffset': startOffset!,
        if (startPosition != null) 'startPosition': startPosition!,
      };
}

class BooksCloudloadingResource {
  core.String? author;
  core.String? processingState;
  core.String? title;
  core.String? volumeId;

  BooksCloudloadingResource();

  BooksCloudloadingResource.fromJson(core.Map _json) {
    if (_json.containsKey('author')) {
      author = _json['author'] as core.String;
    }
    if (_json.containsKey('processingState')) {
      processingState = _json['processingState'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('volumeId')) {
      volumeId = _json['volumeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (author != null) 'author': author!,
        if (processingState != null) 'processingState': processingState!,
        if (title != null) 'title': title!,
        if (volumeId != null) 'volumeId': volumeId!,
      };
}

class BooksVolumesRecommendedRateResponse {
  core.String? consistencyToken;

  BooksVolumesRecommendedRateResponse();

  BooksVolumesRecommendedRateResponse.fromJson(core.Map _json) {
    if (_json.containsKey('consistency_token')) {
      consistencyToken = _json['consistency_token'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (consistencyToken != null) 'consistency_token': consistencyToken!,
      };
}

class Bookshelf {
  /// Whether this bookshelf is PUBLIC or PRIVATE.
  core.String? access;

  /// Created time for this bookshelf (formatted UTC timestamp with millisecond
  /// resolution).
  core.String? created;

  /// Description of this bookshelf.
  core.String? description;

  /// Id of this bookshelf, only unique by user.
  core.int? id;

  /// Resource type for bookshelf metadata.
  core.String? kind;

  /// URL to this resource.
  core.String? selfLink;

  /// Title of this bookshelf.
  core.String? title;

  /// Last modified time of this bookshelf (formatted UTC timestamp with
  /// millisecond resolution).
  core.String? updated;

  /// Number of volumes in this bookshelf.
  core.int? volumeCount;

  /// Last time a volume was added or removed from this bookshelf (formatted UTC
  /// timestamp with millisecond resolution).
  core.String? volumesLastUpdated;

  Bookshelf();

  Bookshelf.fromJson(core.Map _json) {
    if (_json.containsKey('access')) {
      access = _json['access'] as core.String;
    }
    if (_json.containsKey('created')) {
      created = _json['created'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.int;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('updated')) {
      updated = _json['updated'] as core.String;
    }
    if (_json.containsKey('volumeCount')) {
      volumeCount = _json['volumeCount'] as core.int;
    }
    if (_json.containsKey('volumesLastUpdated')) {
      volumesLastUpdated = _json['volumesLastUpdated'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (access != null) 'access': access!,
        if (created != null) 'created': created!,
        if (description != null) 'description': description!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (title != null) 'title': title!,
        if (updated != null) 'updated': updated!,
        if (volumeCount != null) 'volumeCount': volumeCount!,
        if (volumesLastUpdated != null)
          'volumesLastUpdated': volumesLastUpdated!,
      };
}

class Bookshelves {
  /// A list of bookshelves.
  core.List<Bookshelf>? items;

  /// Resource type.
  core.String? kind;

  Bookshelves();

  Bookshelves.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Bookshelf>((value) =>
              Bookshelf.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class CategoryItems {
  core.String? badgeUrl;
  core.String? categoryId;
  core.String? name;

  CategoryItems();

  CategoryItems.fromJson(core.Map _json) {
    if (_json.containsKey('badgeUrl')) {
      badgeUrl = _json['badgeUrl'] as core.String;
    }
    if (_json.containsKey('categoryId')) {
      categoryId = _json['categoryId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (badgeUrl != null) 'badgeUrl': badgeUrl!,
        if (categoryId != null) 'categoryId': categoryId!,
        if (name != null) 'name': name!,
      };
}

class Category {
  /// A list of onboarding categories.
  core.List<CategoryItems>? items;

  /// Resource type.
  core.String? kind;

  Category();

  Category.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<CategoryItems>((value) => CategoryItems.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class ConcurrentAccessRestriction {
  /// Whether access is granted for this (user, device, volume).
  core.bool? deviceAllowed;

  /// Resource type.
  core.String? kind;

  /// The maximum number of concurrent access licenses for this volume.
  core.int? maxConcurrentDevices;

  /// Error/warning message.
  core.String? message;

  /// Client nonce for verification.
  ///
  /// Download access and client-validation only.
  core.String? nonce;

  /// Error/warning reason code.
  core.String? reasonCode;

  /// Whether this volume has any concurrent access restrictions.
  core.bool? restricted;

  /// Response signature.
  core.String? signature;

  /// Client app identifier for verification.
  ///
  /// Download access and client-validation only.
  core.String? source;

  /// Time in seconds for license auto-expiration.
  core.int? timeWindowSeconds;

  /// Identifies the volume for which this entry applies.
  core.String? volumeId;

  ConcurrentAccessRestriction();

  ConcurrentAccessRestriction.fromJson(core.Map _json) {
    if (_json.containsKey('deviceAllowed')) {
      deviceAllowed = _json['deviceAllowed'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('maxConcurrentDevices')) {
      maxConcurrentDevices = _json['maxConcurrentDevices'] as core.int;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('nonce')) {
      nonce = _json['nonce'] as core.String;
    }
    if (_json.containsKey('reasonCode')) {
      reasonCode = _json['reasonCode'] as core.String;
    }
    if (_json.containsKey('restricted')) {
      restricted = _json['restricted'] as core.bool;
    }
    if (_json.containsKey('signature')) {
      signature = _json['signature'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
    if (_json.containsKey('timeWindowSeconds')) {
      timeWindowSeconds = _json['timeWindowSeconds'] as core.int;
    }
    if (_json.containsKey('volumeId')) {
      volumeId = _json['volumeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceAllowed != null) 'deviceAllowed': deviceAllowed!,
        if (kind != null) 'kind': kind!,
        if (maxConcurrentDevices != null)
          'maxConcurrentDevices': maxConcurrentDevices!,
        if (message != null) 'message': message!,
        if (nonce != null) 'nonce': nonce!,
        if (reasonCode != null) 'reasonCode': reasonCode!,
        if (restricted != null) 'restricted': restricted!,
        if (signature != null) 'signature': signature!,
        if (source != null) 'source': source!,
        if (timeWindowSeconds != null) 'timeWindowSeconds': timeWindowSeconds!,
        if (volumeId != null) 'volumeId': volumeId!,
      };
}

class DictionaryAnnotationdata {
  /// The type of annotation this data is for.
  core.String? annotationType;

  /// JSON encoded data for this dictionary annotation data.
  ///
  /// Emitted with name 'data' in JSON output. Either this or geo_data will be
  /// populated.
  Dictlayerdata? data;

  /// Base64 encoded data for this annotation data.
  core.String? encodedData;
  core.List<core.int> get encodedDataAsBytes =>
      convert.base64.decode(encodedData!);

  set encodedDataAsBytes(core.List<core.int> _bytes) {
    encodedData =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Unique id for this annotation data.
  core.String? id;

  /// Resource Type
  core.String? kind;

  /// The Layer id for this data.
  ///
  /// *
  core.String? layerId;

  /// URL for this resource.
  ///
  /// *
  core.String? selfLink;

  /// Timestamp for the last time this data was updated.
  ///
  /// (RFC 3339 UTC date-time format).
  core.String? updated;

  /// The volume id for this data.
  ///
  /// *
  core.String? volumeId;

  DictionaryAnnotationdata();

  DictionaryAnnotationdata.fromJson(core.Map _json) {
    if (_json.containsKey('annotationType')) {
      annotationType = _json['annotationType'] as core.String;
    }
    if (_json.containsKey('data')) {
      data = Dictlayerdata.fromJson(
          _json['data'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('encodedData')) {
      encodedData = _json['encodedData'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('layerId')) {
      layerId = _json['layerId'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('updated')) {
      updated = _json['updated'] as core.String;
    }
    if (_json.containsKey('volumeId')) {
      volumeId = _json['volumeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationType != null) 'annotationType': annotationType!,
        if (data != null) 'data': data!.toJson(),
        if (encodedData != null) 'encodedData': encodedData!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (layerId != null) 'layerId': layerId!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (updated != null) 'updated': updated!,
        if (volumeId != null) 'volumeId': volumeId!,
      };
}

class DictlayerdataCommon {
  /// The display title and localized canonical name to use when searching for
  /// this entity on Google search.
  core.String? title;

  DictlayerdataCommon();

  DictlayerdataCommon.fromJson(core.Map _json) {
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (title != null) 'title': title!,
      };
}

/// The source, url and attribution for this dictionary data.
class DictlayerdataDictSource {
  core.String? attribution;
  core.String? url;

  DictlayerdataDictSource();

  DictlayerdataDictSource.fromJson(core.Map _json) {
    if (_json.containsKey('attribution')) {
      attribution = _json['attribution'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attribution != null) 'attribution': attribution!,
        if (url != null) 'url': url!,
      };
}

class DictlayerdataDictWordsDerivativesSource {
  core.String? attribution;
  core.String? url;

  DictlayerdataDictWordsDerivativesSource();

  DictlayerdataDictWordsDerivativesSource.fromJson(core.Map _json) {
    if (_json.containsKey('attribution')) {
      attribution = _json['attribution'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attribution != null) 'attribution': attribution!,
        if (url != null) 'url': url!,
      };
}

class DictlayerdataDictWordsDerivatives {
  DictlayerdataDictWordsDerivativesSource? source;
  core.String? text;

  DictlayerdataDictWordsDerivatives();

  DictlayerdataDictWordsDerivatives.fromJson(core.Map _json) {
    if (_json.containsKey('source')) {
      source = DictlayerdataDictWordsDerivativesSource.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (source != null) 'source': source!.toJson(),
        if (text != null) 'text': text!,
      };
}

class DictlayerdataDictWordsExamplesSource {
  core.String? attribution;
  core.String? url;

  DictlayerdataDictWordsExamplesSource();

  DictlayerdataDictWordsExamplesSource.fromJson(core.Map _json) {
    if (_json.containsKey('attribution')) {
      attribution = _json['attribution'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attribution != null) 'attribution': attribution!,
        if (url != null) 'url': url!,
      };
}

class DictlayerdataDictWordsExamples {
  DictlayerdataDictWordsExamplesSource? source;
  core.String? text;

  DictlayerdataDictWordsExamples();

  DictlayerdataDictWordsExamples.fromJson(core.Map _json) {
    if (_json.containsKey('source')) {
      source = DictlayerdataDictWordsExamplesSource.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (source != null) 'source': source!.toJson(),
        if (text != null) 'text': text!,
      };
}

class DictlayerdataDictWordsSensesConjugations {
  core.String? type;
  core.String? value;

  DictlayerdataDictWordsSensesConjugations();

  DictlayerdataDictWordsSensesConjugations.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
      };
}

class DictlayerdataDictWordsSensesDefinitionsExamplesSource {
  core.String? attribution;
  core.String? url;

  DictlayerdataDictWordsSensesDefinitionsExamplesSource();

  DictlayerdataDictWordsSensesDefinitionsExamplesSource.fromJson(
      core.Map _json) {
    if (_json.containsKey('attribution')) {
      attribution = _json['attribution'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attribution != null) 'attribution': attribution!,
        if (url != null) 'url': url!,
      };
}

class DictlayerdataDictWordsSensesDefinitionsExamples {
  DictlayerdataDictWordsSensesDefinitionsExamplesSource? source;
  core.String? text;

  DictlayerdataDictWordsSensesDefinitionsExamples();

  DictlayerdataDictWordsSensesDefinitionsExamples.fromJson(core.Map _json) {
    if (_json.containsKey('source')) {
      source = DictlayerdataDictWordsSensesDefinitionsExamplesSource.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (source != null) 'source': source!.toJson(),
        if (text != null) 'text': text!,
      };
}

class DictlayerdataDictWordsSensesDefinitions {
  core.String? definition;
  core.List<DictlayerdataDictWordsSensesDefinitionsExamples>? examples;

  DictlayerdataDictWordsSensesDefinitions();

  DictlayerdataDictWordsSensesDefinitions.fromJson(core.Map _json) {
    if (_json.containsKey('definition')) {
      definition = _json['definition'] as core.String;
    }
    if (_json.containsKey('examples')) {
      examples = (_json['examples'] as core.List)
          .map<DictlayerdataDictWordsSensesDefinitionsExamples>((value) =>
              DictlayerdataDictWordsSensesDefinitionsExamples.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (definition != null) 'definition': definition!,
        if (examples != null)
          'examples': examples!.map((value) => value.toJson()).toList(),
      };
}

class DictlayerdataDictWordsSensesSource {
  core.String? attribution;
  core.String? url;

  DictlayerdataDictWordsSensesSource();

  DictlayerdataDictWordsSensesSource.fromJson(core.Map _json) {
    if (_json.containsKey('attribution')) {
      attribution = _json['attribution'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attribution != null) 'attribution': attribution!,
        if (url != null) 'url': url!,
      };
}

class DictlayerdataDictWordsSensesSynonymsSource {
  core.String? attribution;
  core.String? url;

  DictlayerdataDictWordsSensesSynonymsSource();

  DictlayerdataDictWordsSensesSynonymsSource.fromJson(core.Map _json) {
    if (_json.containsKey('attribution')) {
      attribution = _json['attribution'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attribution != null) 'attribution': attribution!,
        if (url != null) 'url': url!,
      };
}

class DictlayerdataDictWordsSensesSynonyms {
  DictlayerdataDictWordsSensesSynonymsSource? source;
  core.String? text;

  DictlayerdataDictWordsSensesSynonyms();

  DictlayerdataDictWordsSensesSynonyms.fromJson(core.Map _json) {
    if (_json.containsKey('source')) {
      source = DictlayerdataDictWordsSensesSynonymsSource.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (source != null) 'source': source!.toJson(),
        if (text != null) 'text': text!,
      };
}

class DictlayerdataDictWordsSenses {
  core.List<DictlayerdataDictWordsSensesConjugations>? conjugations;
  core.List<DictlayerdataDictWordsSensesDefinitions>? definitions;
  core.String? partOfSpeech;
  core.String? pronunciation;
  core.String? pronunciationUrl;
  DictlayerdataDictWordsSensesSource? source;
  core.String? syllabification;
  core.List<DictlayerdataDictWordsSensesSynonyms>? synonyms;

  DictlayerdataDictWordsSenses();

  DictlayerdataDictWordsSenses.fromJson(core.Map _json) {
    if (_json.containsKey('conjugations')) {
      conjugations = (_json['conjugations'] as core.List)
          .map<DictlayerdataDictWordsSensesConjugations>((value) =>
              DictlayerdataDictWordsSensesConjugations.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('definitions')) {
      definitions = (_json['definitions'] as core.List)
          .map<DictlayerdataDictWordsSensesDefinitions>((value) =>
              DictlayerdataDictWordsSensesDefinitions.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('partOfSpeech')) {
      partOfSpeech = _json['partOfSpeech'] as core.String;
    }
    if (_json.containsKey('pronunciation')) {
      pronunciation = _json['pronunciation'] as core.String;
    }
    if (_json.containsKey('pronunciationUrl')) {
      pronunciationUrl = _json['pronunciationUrl'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = DictlayerdataDictWordsSensesSource.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('syllabification')) {
      syllabification = _json['syllabification'] as core.String;
    }
    if (_json.containsKey('synonyms')) {
      synonyms = (_json['synonyms'] as core.List)
          .map<DictlayerdataDictWordsSensesSynonyms>((value) =>
              DictlayerdataDictWordsSensesSynonyms.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conjugations != null)
          'conjugations': conjugations!.map((value) => value.toJson()).toList(),
        if (definitions != null)
          'definitions': definitions!.map((value) => value.toJson()).toList(),
        if (partOfSpeech != null) 'partOfSpeech': partOfSpeech!,
        if (pronunciation != null) 'pronunciation': pronunciation!,
        if (pronunciationUrl != null) 'pronunciationUrl': pronunciationUrl!,
        if (source != null) 'source': source!.toJson(),
        if (syllabification != null) 'syllabification': syllabification!,
        if (synonyms != null)
          'synonyms': synonyms!.map((value) => value.toJson()).toList(),
      };
}

/// The words with different meanings but not related words, e.g. "go" (game)
/// and "go" (verb).
class DictlayerdataDictWordsSource {
  core.String? attribution;
  core.String? url;

  DictlayerdataDictWordsSource();

  DictlayerdataDictWordsSource.fromJson(core.Map _json) {
    if (_json.containsKey('attribution')) {
      attribution = _json['attribution'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attribution != null) 'attribution': attribution!,
        if (url != null) 'url': url!,
      };
}

class DictlayerdataDictWords {
  core.List<DictlayerdataDictWordsDerivatives>? derivatives;
  core.List<DictlayerdataDictWordsExamples>? examples;
  core.List<DictlayerdataDictWordsSenses>? senses;

  /// The words with different meanings but not related words, e.g. "go" (game)
  /// and "go" (verb).
  DictlayerdataDictWordsSource? source;

  DictlayerdataDictWords();

  DictlayerdataDictWords.fromJson(core.Map _json) {
    if (_json.containsKey('derivatives')) {
      derivatives = (_json['derivatives'] as core.List)
          .map<DictlayerdataDictWordsDerivatives>((value) =>
              DictlayerdataDictWordsDerivatives.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('examples')) {
      examples = (_json['examples'] as core.List)
          .map<DictlayerdataDictWordsExamples>((value) =>
              DictlayerdataDictWordsExamples.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('senses')) {
      senses = (_json['senses'] as core.List)
          .map<DictlayerdataDictWordsSenses>((value) =>
              DictlayerdataDictWordsSenses.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('source')) {
      source = DictlayerdataDictWordsSource.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (derivatives != null)
          'derivatives': derivatives!.map((value) => value.toJson()).toList(),
        if (examples != null)
          'examples': examples!.map((value) => value.toJson()).toList(),
        if (senses != null)
          'senses': senses!.map((value) => value.toJson()).toList(),
        if (source != null) 'source': source!.toJson(),
      };
}

class DictlayerdataDict {
  /// The source, url and attribution for this dictionary data.
  DictlayerdataDictSource? source;
  core.List<DictlayerdataDictWords>? words;

  DictlayerdataDict();

  DictlayerdataDict.fromJson(core.Map _json) {
    if (_json.containsKey('source')) {
      source = DictlayerdataDictSource.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('words')) {
      words = (_json['words'] as core.List)
          .map<DictlayerdataDictWords>((value) =>
              DictlayerdataDictWords.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (source != null) 'source': source!.toJson(),
        if (words != null)
          'words': words!.map((value) => value.toJson()).toList(),
      };
}

class Dictlayerdata {
  DictlayerdataCommon? common;
  DictlayerdataDict? dict;
  core.String? kind;

  Dictlayerdata();

  Dictlayerdata.fromJson(core.Map _json) {
    if (_json.containsKey('common')) {
      common = DictlayerdataCommon.fromJson(
          _json['common'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dict')) {
      dict = DictlayerdataDict.fromJson(
          _json['dict'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (common != null) 'common': common!.toJson(),
        if (dict != null) 'dict': dict!.toJson(),
        if (kind != null) 'kind': kind!,
      };
}

class DiscoveryclustersClustersBannerWithContentContainer {
  core.String? fillColorArgb;
  core.String? imageUrl;
  core.String? maskColorArgb;
  core.String? moreButtonText;
  core.String? moreButtonUrl;
  core.String? textColorArgb;

  DiscoveryclustersClustersBannerWithContentContainer();

  DiscoveryclustersClustersBannerWithContentContainer.fromJson(core.Map _json) {
    if (_json.containsKey('fillColorArgb')) {
      fillColorArgb = _json['fillColorArgb'] as core.String;
    }
    if (_json.containsKey('imageUrl')) {
      imageUrl = _json['imageUrl'] as core.String;
    }
    if (_json.containsKey('maskColorArgb')) {
      maskColorArgb = _json['maskColorArgb'] as core.String;
    }
    if (_json.containsKey('moreButtonText')) {
      moreButtonText = _json['moreButtonText'] as core.String;
    }
    if (_json.containsKey('moreButtonUrl')) {
      moreButtonUrl = _json['moreButtonUrl'] as core.String;
    }
    if (_json.containsKey('textColorArgb')) {
      textColorArgb = _json['textColorArgb'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fillColorArgb != null) 'fillColorArgb': fillColorArgb!,
        if (imageUrl != null) 'imageUrl': imageUrl!,
        if (maskColorArgb != null) 'maskColorArgb': maskColorArgb!,
        if (moreButtonText != null) 'moreButtonText': moreButtonText!,
        if (moreButtonUrl != null) 'moreButtonUrl': moreButtonUrl!,
        if (textColorArgb != null) 'textColorArgb': textColorArgb!,
      };
}

class DiscoveryclustersClusters {
  DiscoveryclustersClustersBannerWithContentContainer?
      bannerWithContentContainer;
  core.String? subTitle;
  core.String? title;
  core.int? totalVolumes;
  core.String? uid;
  core.List<Volume>? volumes;

  DiscoveryclustersClusters();

  DiscoveryclustersClusters.fromJson(core.Map _json) {
    if (_json.containsKey('banner_with_content_container')) {
      bannerWithContentContainer =
          DiscoveryclustersClustersBannerWithContentContainer.fromJson(
              _json['banner_with_content_container']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subTitle')) {
      subTitle = _json['subTitle'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('totalVolumes')) {
      totalVolumes = _json['totalVolumes'] as core.int;
    }
    if (_json.containsKey('uid')) {
      uid = _json['uid'] as core.String;
    }
    if (_json.containsKey('volumes')) {
      volumes = (_json['volumes'] as core.List)
          .map<Volume>((value) =>
              Volume.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bannerWithContentContainer != null)
          'banner_with_content_container': bannerWithContentContainer!.toJson(),
        if (subTitle != null) 'subTitle': subTitle!,
        if (title != null) 'title': title!,
        if (totalVolumes != null) 'totalVolumes': totalVolumes!,
        if (uid != null) 'uid': uid!,
        if (volumes != null)
          'volumes': volumes!.map((value) => value.toJson()).toList(),
      };
}

class Discoveryclusters {
  core.List<DiscoveryclustersClusters>? clusters;

  /// Resorce type.
  core.String? kind;
  core.int? totalClusters;

  Discoveryclusters();

  Discoveryclusters.fromJson(core.Map _json) {
    if (_json.containsKey('clusters')) {
      clusters = (_json['clusters'] as core.List)
          .map<DiscoveryclustersClusters>((value) =>
              DiscoveryclustersClusters.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('totalClusters')) {
      totalClusters = _json['totalClusters'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusters != null)
          'clusters': clusters!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (totalClusters != null) 'totalClusters': totalClusters!,
      };
}

class DownloadAccessRestriction {
  /// If restricted, whether access is granted for this (user, device, volume).
  core.bool? deviceAllowed;

  /// If restricted, the number of content download licenses already acquired
  /// (including the requesting client, if licensed).
  core.int? downloadsAcquired;

  /// If deviceAllowed, whether access was just acquired with this request.
  core.bool? justAcquired;

  /// Resource type.
  core.String? kind;

  /// If restricted, the maximum number of content download licenses for this
  /// volume.
  core.int? maxDownloadDevices;

  /// Error/warning message.
  core.String? message;

  /// Client nonce for verification.
  ///
  /// Download access and client-validation only.
  core.String? nonce;

  /// Error/warning reason code.
  ///
  /// Additional codes may be added in the future. 0 OK 100
  /// ACCESS_DENIED_PUBLISHER_LIMIT 101 ACCESS_DENIED_LIMIT 200
  /// WARNING_USED_LAST_ACCESS
  core.String? reasonCode;

  /// Whether this volume has any download access restrictions.
  core.bool? restricted;

  /// Response signature.
  core.String? signature;

  /// Client app identifier for verification.
  ///
  /// Download access and client-validation only.
  core.String? source;

  /// Identifies the volume for which this entry applies.
  core.String? volumeId;

  DownloadAccessRestriction();

  DownloadAccessRestriction.fromJson(core.Map _json) {
    if (_json.containsKey('deviceAllowed')) {
      deviceAllowed = _json['deviceAllowed'] as core.bool;
    }
    if (_json.containsKey('downloadsAcquired')) {
      downloadsAcquired = _json['downloadsAcquired'] as core.int;
    }
    if (_json.containsKey('justAcquired')) {
      justAcquired = _json['justAcquired'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('maxDownloadDevices')) {
      maxDownloadDevices = _json['maxDownloadDevices'] as core.int;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('nonce')) {
      nonce = _json['nonce'] as core.String;
    }
    if (_json.containsKey('reasonCode')) {
      reasonCode = _json['reasonCode'] as core.String;
    }
    if (_json.containsKey('restricted')) {
      restricted = _json['restricted'] as core.bool;
    }
    if (_json.containsKey('signature')) {
      signature = _json['signature'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
    if (_json.containsKey('volumeId')) {
      volumeId = _json['volumeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceAllowed != null) 'deviceAllowed': deviceAllowed!,
        if (downloadsAcquired != null) 'downloadsAcquired': downloadsAcquired!,
        if (justAcquired != null) 'justAcquired': justAcquired!,
        if (kind != null) 'kind': kind!,
        if (maxDownloadDevices != null)
          'maxDownloadDevices': maxDownloadDevices!,
        if (message != null) 'message': message!,
        if (nonce != null) 'nonce': nonce!,
        if (reasonCode != null) 'reasonCode': reasonCode!,
        if (restricted != null) 'restricted': restricted!,
        if (signature != null) 'signature': signature!,
        if (source != null) 'source': source!,
        if (volumeId != null) 'volumeId': volumeId!,
      };
}

class DownloadAccesses {
  /// A list of download access responses.
  core.List<DownloadAccessRestriction>? downloadAccessList;

  /// Resource type.
  core.String? kind;

  DownloadAccesses();

  DownloadAccesses.fromJson(core.Map _json) {
    if (_json.containsKey('downloadAccessList')) {
      downloadAccessList = (_json['downloadAccessList'] as core.List)
          .map<DownloadAccessRestriction>((value) =>
              DownloadAccessRestriction.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (downloadAccessList != null)
          'downloadAccessList':
              downloadAccessList!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// A generic empty message that you can re-use to avoid defining duplicated
/// empty messages in your APIs.
///
/// A typical example is to use it as the request or the response type of an API
/// method. For instance: service Foo { rpc Bar(google.protobuf.Empty) returns
/// (google.protobuf.Empty); } The JSON representation for `Empty` is empty JSON
/// object `{}`.
class Empty {
  Empty();

  Empty.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Family membership info of the user that made the request.
class FamilyInfoMembership {
  /// Restrictions on user buying and acquiring content.
  core.String? acquirePermission;

  /// The age group of the user.
  core.String? ageGroup;

  /// The maximum allowed maturity rating for the user.
  core.String? allowedMaturityRating;
  core.bool? isInFamily;

  /// The role of the user in the family.
  core.String? role;

  FamilyInfoMembership();

  FamilyInfoMembership.fromJson(core.Map _json) {
    if (_json.containsKey('acquirePermission')) {
      acquirePermission = _json['acquirePermission'] as core.String;
    }
    if (_json.containsKey('ageGroup')) {
      ageGroup = _json['ageGroup'] as core.String;
    }
    if (_json.containsKey('allowedMaturityRating')) {
      allowedMaturityRating = _json['allowedMaturityRating'] as core.String;
    }
    if (_json.containsKey('isInFamily')) {
      isInFamily = _json['isInFamily'] as core.bool;
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (acquirePermission != null) 'acquirePermission': acquirePermission!,
        if (ageGroup != null) 'ageGroup': ageGroup!,
        if (allowedMaturityRating != null)
          'allowedMaturityRating': allowedMaturityRating!,
        if (isInFamily != null) 'isInFamily': isInFamily!,
        if (role != null) 'role': role!,
      };
}

class FamilyInfo {
  /// Resource type.
  core.String? kind;

  /// Family membership info of the user that made the request.
  FamilyInfoMembership? membership;

  FamilyInfo();

  FamilyInfo.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('membership')) {
      membership = FamilyInfoMembership.fromJson(
          _json['membership'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (membership != null) 'membership': membership!.toJson(),
      };
}

class GeoAnnotationdata {
  /// The type of annotation this data is for.
  core.String? annotationType;

  /// JSON encoded data for this geo annotation data.
  ///
  /// Emitted with name 'data' in JSON output. Either this or dict_data will be
  /// populated.
  Geolayerdata? data;

  /// Base64 encoded data for this annotation data.
  core.String? encodedData;
  core.List<core.int> get encodedDataAsBytes =>
      convert.base64.decode(encodedData!);

  set encodedDataAsBytes(core.List<core.int> _bytes) {
    encodedData =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Unique id for this annotation data.
  core.String? id;

  /// Resource Type
  core.String? kind;

  /// The Layer id for this data.
  ///
  /// *
  core.String? layerId;

  /// URL for this resource.
  ///
  /// *
  core.String? selfLink;

  /// Timestamp for the last time this data was updated.
  ///
  /// (RFC 3339 UTC date-time format).
  core.String? updated;

  /// The volume id for this data.
  ///
  /// *
  core.String? volumeId;

  GeoAnnotationdata();

  GeoAnnotationdata.fromJson(core.Map _json) {
    if (_json.containsKey('annotationType')) {
      annotationType = _json['annotationType'] as core.String;
    }
    if (_json.containsKey('data')) {
      data = Geolayerdata.fromJson(
          _json['data'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('encodedData')) {
      encodedData = _json['encodedData'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('layerId')) {
      layerId = _json['layerId'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('updated')) {
      updated = _json['updated'] as core.String;
    }
    if (_json.containsKey('volumeId')) {
      volumeId = _json['volumeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationType != null) 'annotationType': annotationType!,
        if (data != null) 'data': data!.toJson(),
        if (encodedData != null) 'encodedData': encodedData!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (layerId != null) 'layerId': layerId!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (updated != null) 'updated': updated!,
        if (volumeId != null) 'volumeId': volumeId!,
      };
}

class GeolayerdataCommon {
  /// The language of the information url and description.
  core.String? lang;

  /// The URL for the preview image information.
  core.String? previewImageUrl;

  /// The description for this location.
  core.String? snippet;

  /// The URL for information for this location.
  ///
  /// Ex: wikipedia link.
  core.String? snippetUrl;

  /// The display title and localized canonical name to use when searching for
  /// this entity on Google search.
  core.String? title;

  GeolayerdataCommon();

  GeolayerdataCommon.fromJson(core.Map _json) {
    if (_json.containsKey('lang')) {
      lang = _json['lang'] as core.String;
    }
    if (_json.containsKey('previewImageUrl')) {
      previewImageUrl = _json['previewImageUrl'] as core.String;
    }
    if (_json.containsKey('snippet')) {
      snippet = _json['snippet'] as core.String;
    }
    if (_json.containsKey('snippetUrl')) {
      snippetUrl = _json['snippetUrl'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lang != null) 'lang': lang!,
        if (previewImageUrl != null) 'previewImageUrl': previewImageUrl!,
        if (snippet != null) 'snippet': snippet!,
        if (snippetUrl != null) 'snippetUrl': snippetUrl!,
        if (title != null) 'title': title!,
      };
}

class GeolayerdataGeoViewportHi {
  core.double? latitude;
  core.double? longitude;

  GeolayerdataGeoViewportHi();

  GeolayerdataGeoViewportHi.fromJson(core.Map _json) {
    if (_json.containsKey('latitude')) {
      latitude = (_json['latitude'] as core.num).toDouble();
    }
    if (_json.containsKey('longitude')) {
      longitude = (_json['longitude'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (latitude != null) 'latitude': latitude!,
        if (longitude != null) 'longitude': longitude!,
      };
}

class GeolayerdataGeoViewportLo {
  core.double? latitude;
  core.double? longitude;

  GeolayerdataGeoViewportLo();

  GeolayerdataGeoViewportLo.fromJson(core.Map _json) {
    if (_json.containsKey('latitude')) {
      latitude = (_json['latitude'] as core.num).toDouble();
    }
    if (_json.containsKey('longitude')) {
      longitude = (_json['longitude'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (latitude != null) 'latitude': latitude!,
        if (longitude != null) 'longitude': longitude!,
      };
}

/// The viewport for showing this location.
///
/// This is a latitude, longitude rectangle.
class GeolayerdataGeoViewport {
  GeolayerdataGeoViewportHi? hi;
  GeolayerdataGeoViewportLo? lo;

  GeolayerdataGeoViewport();

  GeolayerdataGeoViewport.fromJson(core.Map _json) {
    if (_json.containsKey('hi')) {
      hi = GeolayerdataGeoViewportHi.fromJson(
          _json['hi'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lo')) {
      lo = GeolayerdataGeoViewportLo.fromJson(
          _json['lo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hi != null) 'hi': hi!.toJson(),
        if (lo != null) 'lo': lo!.toJson(),
      };
}

class GeolayerdataGeo {
  /// The boundary of the location as a set of loops containing pairs of
  /// latitude, longitude coordinates.
  core.List<core.String>? boundary;

  /// The cache policy active for this data.
  ///
  /// EX: UNRESTRICTED, RESTRICTED, NEVER
  core.String? cachePolicy;

  /// The country code of the location.
  core.String? countryCode;

  /// The latitude of the location.
  core.double? latitude;

  /// The longitude of the location.
  core.double? longitude;

  /// The type of map that should be used for this location.
  ///
  /// EX: HYBRID, ROADMAP, SATELLITE, TERRAIN
  core.String? mapType;

  /// The viewport for showing this location.
  ///
  /// This is a latitude, longitude rectangle.
  GeolayerdataGeoViewport? viewport;

  /// The Zoom level to use for the map.
  ///
  /// Zoom levels between 0 (the lowest zoom level, in which the entire world
  /// can be seen on one map) to 21+ (down to individual buildings). See: https:
  /// //developers.google.com/maps/documentation/staticmaps/#Zoomlevels
  core.int? zoom;

  GeolayerdataGeo();

  GeolayerdataGeo.fromJson(core.Map _json) {
    if (_json.containsKey('boundary')) {
      boundary = (_json['boundary'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('cachePolicy')) {
      cachePolicy = _json['cachePolicy'] as core.String;
    }
    if (_json.containsKey('countryCode')) {
      countryCode = _json['countryCode'] as core.String;
    }
    if (_json.containsKey('latitude')) {
      latitude = (_json['latitude'] as core.num).toDouble();
    }
    if (_json.containsKey('longitude')) {
      longitude = (_json['longitude'] as core.num).toDouble();
    }
    if (_json.containsKey('mapType')) {
      mapType = _json['mapType'] as core.String;
    }
    if (_json.containsKey('viewport')) {
      viewport = GeolayerdataGeoViewport.fromJson(
          _json['viewport'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('zoom')) {
      zoom = _json['zoom'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (boundary != null) 'boundary': boundary!,
        if (cachePolicy != null) 'cachePolicy': cachePolicy!,
        if (countryCode != null) 'countryCode': countryCode!,
        if (latitude != null) 'latitude': latitude!,
        if (longitude != null) 'longitude': longitude!,
        if (mapType != null) 'mapType': mapType!,
        if (viewport != null) 'viewport': viewport!.toJson(),
        if (zoom != null) 'zoom': zoom!,
      };
}

class Geolayerdata {
  GeolayerdataCommon? common;
  GeolayerdataGeo? geo;
  core.String? kind;

  Geolayerdata();

  Geolayerdata.fromJson(core.Map _json) {
    if (_json.containsKey('common')) {
      common = GeolayerdataCommon.fromJson(
          _json['common'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('geo')) {
      geo = GeolayerdataGeo.fromJson(
          _json['geo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (common != null) 'common': common!.toJson(),
        if (geo != null) 'geo': geo!.toJson(),
        if (kind != null) 'kind': kind!,
      };
}

class Layersummaries {
  /// A list of layer summary items.
  core.List<Layersummary>? items;

  /// Resource type.
  core.String? kind;

  /// The total number of layer summaries found.
  core.int? totalItems;

  Layersummaries();

  Layersummaries.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Layersummary>((value) => Layersummary.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('totalItems')) {
      totalItems = _json['totalItems'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (totalItems != null) 'totalItems': totalItems!,
      };
}

class Layersummary {
  /// The number of annotations for this layer.
  core.int? annotationCount;

  /// The list of annotation types contained for this layer.
  core.List<core.String>? annotationTypes;

  /// Link to get data for this annotation.
  core.String? annotationsDataLink;

  /// The link to get the annotations for this layer.
  core.String? annotationsLink;

  /// The content version this resource is for.
  core.String? contentVersion;

  /// The number of data items for this layer.
  core.int? dataCount;

  /// Unique id of this layer summary.
  core.String? id;

  /// Resource Type
  core.String? kind;

  /// The layer id for this summary.
  core.String? layerId;

  /// URL to this resource.
  core.String? selfLink;

  /// Timestamp for the last time an item in this layer was updated.
  ///
  /// (RFC 3339 UTC date-time format).
  core.String? updated;

  /// The current version of this layer's volume annotations.
  ///
  /// Note that this version applies only to the data in the
  /// books.layers.volumeAnnotations.* responses. The actual annotation data is
  /// versioned separately.
  core.String? volumeAnnotationsVersion;

  /// The volume id this resource is for.
  core.String? volumeId;

  Layersummary();

  Layersummary.fromJson(core.Map _json) {
    if (_json.containsKey('annotationCount')) {
      annotationCount = _json['annotationCount'] as core.int;
    }
    if (_json.containsKey('annotationTypes')) {
      annotationTypes = (_json['annotationTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('annotationsDataLink')) {
      annotationsDataLink = _json['annotationsDataLink'] as core.String;
    }
    if (_json.containsKey('annotationsLink')) {
      annotationsLink = _json['annotationsLink'] as core.String;
    }
    if (_json.containsKey('contentVersion')) {
      contentVersion = _json['contentVersion'] as core.String;
    }
    if (_json.containsKey('dataCount')) {
      dataCount = _json['dataCount'] as core.int;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('layerId')) {
      layerId = _json['layerId'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('updated')) {
      updated = _json['updated'] as core.String;
    }
    if (_json.containsKey('volumeAnnotationsVersion')) {
      volumeAnnotationsVersion =
          _json['volumeAnnotationsVersion'] as core.String;
    }
    if (_json.containsKey('volumeId')) {
      volumeId = _json['volumeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationCount != null) 'annotationCount': annotationCount!,
        if (annotationTypes != null) 'annotationTypes': annotationTypes!,
        if (annotationsDataLink != null)
          'annotationsDataLink': annotationsDataLink!,
        if (annotationsLink != null) 'annotationsLink': annotationsLink!,
        if (contentVersion != null) 'contentVersion': contentVersion!,
        if (dataCount != null) 'dataCount': dataCount!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (layerId != null) 'layerId': layerId!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (updated != null) 'updated': updated!,
        if (volumeAnnotationsVersion != null)
          'volumeAnnotationsVersion': volumeAnnotationsVersion!,
        if (volumeId != null) 'volumeId': volumeId!,
      };
}

class MetadataItems {
  core.String? downloadUrl;
  core.String? encryptedKey;
  core.String? language;
  core.String? size;
  core.String? version;

  MetadataItems();

  MetadataItems.fromJson(core.Map _json) {
    if (_json.containsKey('download_url')) {
      downloadUrl = _json['download_url'] as core.String;
    }
    if (_json.containsKey('encrypted_key')) {
      encryptedKey = _json['encrypted_key'] as core.String;
    }
    if (_json.containsKey('language')) {
      language = _json['language'] as core.String;
    }
    if (_json.containsKey('size')) {
      size = _json['size'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (downloadUrl != null) 'download_url': downloadUrl!,
        if (encryptedKey != null) 'encrypted_key': encryptedKey!,
        if (language != null) 'language': language!,
        if (size != null) 'size': size!,
        if (version != null) 'version': version!,
      };
}

class Metadata {
  /// A list of offline dictionary metadata.
  core.List<MetadataItems>? items;

  /// Resource type.
  core.String? kind;

  Metadata();

  Metadata.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<MetadataItems>((value) => MetadataItems.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class Notification {
  core.String? body;

  /// The list of crm experiment ids.
  core.List<core.String>? crmExperimentIds;
  core.String? docId;
  core.String? docType;
  core.bool? dontShowNotification;
  core.String? iconUrl;
  core.bool? isDocumentMature;

  /// Resource type.
  core.String? kind;
  core.String? notificationGroup;
  core.String? notificationType;
  core.String? pcampaignId;
  core.String? reason;
  core.bool? showNotificationSettingsAction;
  core.String? targetUrl;
  core.String? timeToExpireMs;
  core.String? title;

  Notification();

  Notification.fromJson(core.Map _json) {
    if (_json.containsKey('body')) {
      body = _json['body'] as core.String;
    }
    if (_json.containsKey('crmExperimentIds')) {
      crmExperimentIds = (_json['crmExperimentIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('doc_id')) {
      docId = _json['doc_id'] as core.String;
    }
    if (_json.containsKey('doc_type')) {
      docType = _json['doc_type'] as core.String;
    }
    if (_json.containsKey('dont_show_notification')) {
      dontShowNotification = _json['dont_show_notification'] as core.bool;
    }
    if (_json.containsKey('iconUrl')) {
      iconUrl = _json['iconUrl'] as core.String;
    }
    if (_json.containsKey('is_document_mature')) {
      isDocumentMature = _json['is_document_mature'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('notificationGroup')) {
      notificationGroup = _json['notificationGroup'] as core.String;
    }
    if (_json.containsKey('notification_type')) {
      notificationType = _json['notification_type'] as core.String;
    }
    if (_json.containsKey('pcampaign_id')) {
      pcampaignId = _json['pcampaign_id'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('show_notification_settings_action')) {
      showNotificationSettingsAction =
          _json['show_notification_settings_action'] as core.bool;
    }
    if (_json.containsKey('targetUrl')) {
      targetUrl = _json['targetUrl'] as core.String;
    }
    if (_json.containsKey('timeToExpireMs')) {
      timeToExpireMs = _json['timeToExpireMs'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (body != null) 'body': body!,
        if (crmExperimentIds != null) 'crmExperimentIds': crmExperimentIds!,
        if (docId != null) 'doc_id': docId!,
        if (docType != null) 'doc_type': docType!,
        if (dontShowNotification != null)
          'dont_show_notification': dontShowNotification!,
        if (iconUrl != null) 'iconUrl': iconUrl!,
        if (isDocumentMature != null) 'is_document_mature': isDocumentMature!,
        if (kind != null) 'kind': kind!,
        if (notificationGroup != null) 'notificationGroup': notificationGroup!,
        if (notificationType != null) 'notification_type': notificationType!,
        if (pcampaignId != null) 'pcampaign_id': pcampaignId!,
        if (reason != null) 'reason': reason!,
        if (showNotificationSettingsAction != null)
          'show_notification_settings_action': showNotificationSettingsAction!,
        if (targetUrl != null) 'targetUrl': targetUrl!,
        if (timeToExpireMs != null) 'timeToExpireMs': timeToExpireMs!,
        if (title != null) 'title': title!,
      };
}

class OffersItemsItems {
  core.String? author;
  core.String? canonicalVolumeLink;
  core.String? coverUrl;
  core.String? description;
  core.String? title;
  core.String? volumeId;

  OffersItemsItems();

  OffersItemsItems.fromJson(core.Map _json) {
    if (_json.containsKey('author')) {
      author = _json['author'] as core.String;
    }
    if (_json.containsKey('canonicalVolumeLink')) {
      canonicalVolumeLink = _json['canonicalVolumeLink'] as core.String;
    }
    if (_json.containsKey('coverUrl')) {
      coverUrl = _json['coverUrl'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('volumeId')) {
      volumeId = _json['volumeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (author != null) 'author': author!,
        if (canonicalVolumeLink != null)
          'canonicalVolumeLink': canonicalVolumeLink!,
        if (coverUrl != null) 'coverUrl': coverUrl!,
        if (description != null) 'description': description!,
        if (title != null) 'title': title!,
        if (volumeId != null) 'volumeId': volumeId!,
      };
}

class OffersItems {
  core.String? artUrl;
  core.String? gservicesKey;
  core.String? id;
  core.List<OffersItemsItems>? items;

  OffersItems();

  OffersItems.fromJson(core.Map _json) {
    if (_json.containsKey('artUrl')) {
      artUrl = _json['artUrl'] as core.String;
    }
    if (_json.containsKey('gservicesKey')) {
      gservicesKey = _json['gservicesKey'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<OffersItemsItems>((value) => OffersItemsItems.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (artUrl != null) 'artUrl': artUrl!,
        if (gservicesKey != null) 'gservicesKey': gservicesKey!,
        if (id != null) 'id': id!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
      };
}

class Offers {
  /// A list of offers.
  core.List<OffersItems>? items;

  /// Resource type.
  core.String? kind;

  Offers();

  Offers.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<OffersItems>((value) => OffersItems.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class ReadingPosition {
  /// Position in an EPUB as a CFI.
  core.String? epubCfiPosition;

  /// Position in a volume for image-based content.
  core.String? gbImagePosition;

  /// Position in a volume for text-based content.
  core.String? gbTextPosition;

  /// Resource type for a reading position.
  core.String? kind;

  /// Position in a PDF file.
  core.String? pdfPosition;

  /// Timestamp when this reading position was last updated (formatted UTC
  /// timestamp with millisecond resolution).
  core.String? updated;

  /// Volume id associated with this reading position.
  core.String? volumeId;

  ReadingPosition();

  ReadingPosition.fromJson(core.Map _json) {
    if (_json.containsKey('epubCfiPosition')) {
      epubCfiPosition = _json['epubCfiPosition'] as core.String;
    }
    if (_json.containsKey('gbImagePosition')) {
      gbImagePosition = _json['gbImagePosition'] as core.String;
    }
    if (_json.containsKey('gbTextPosition')) {
      gbTextPosition = _json['gbTextPosition'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('pdfPosition')) {
      pdfPosition = _json['pdfPosition'] as core.String;
    }
    if (_json.containsKey('updated')) {
      updated = _json['updated'] as core.String;
    }
    if (_json.containsKey('volumeId')) {
      volumeId = _json['volumeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (epubCfiPosition != null) 'epubCfiPosition': epubCfiPosition!,
        if (gbImagePosition != null) 'gbImagePosition': gbImagePosition!,
        if (gbTextPosition != null) 'gbTextPosition': gbTextPosition!,
        if (kind != null) 'kind': kind!,
        if (pdfPosition != null) 'pdfPosition': pdfPosition!,
        if (updated != null) 'updated': updated!,
        if (volumeId != null) 'volumeId': volumeId!,
      };
}

class RequestAccessData {
  /// A concurrent access response.
  ConcurrentAccessRestriction? concurrentAccess;

  /// A download access response.
  DownloadAccessRestriction? downloadAccess;

  /// Resource type.
  core.String? kind;

  RequestAccessData();

  RequestAccessData.fromJson(core.Map _json) {
    if (_json.containsKey('concurrentAccess')) {
      concurrentAccess = ConcurrentAccessRestriction.fromJson(
          _json['concurrentAccess'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('downloadAccess')) {
      downloadAccess = DownloadAccessRestriction.fromJson(
          _json['downloadAccess'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (concurrentAccess != null)
          'concurrentAccess': concurrentAccess!.toJson(),
        if (downloadAccess != null) 'downloadAccess': downloadAccess!.toJson(),
        if (kind != null) 'kind': kind!,
      };
}

/// Author of this review.
class ReviewAuthor {
  /// Name of this person.
  core.String? displayName;

  ReviewAuthor();

  ReviewAuthor.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
      };
}

/// Information regarding the source of this review, when the review is not from
/// a Google Books user.
class ReviewSource {
  /// Name of the source.
  core.String? description;

  /// Extra text about the source of the review.
  core.String? extraDescription;

  /// URL of the source of the review.
  core.String? url;

  ReviewSource();

  ReviewSource.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('extraDescription')) {
      extraDescription = _json['extraDescription'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (extraDescription != null) 'extraDescription': extraDescription!,
        if (url != null) 'url': url!,
      };
}

class Review {
  /// Author of this review.
  ReviewAuthor? author;

  /// Review text.
  core.String? content;

  /// Date of this review.
  core.String? date;

  /// URL for the full review text, for reviews gathered from the web.
  core.String? fullTextUrl;

  /// Resource type for a review.
  core.String? kind;

  /// Star rating for this review.
  ///
  /// Possible values are ONE, TWO, THREE, FOUR, FIVE or NOT_RATED.
  core.String? rating;

  /// Information regarding the source of this review, when the review is not
  /// from a Google Books user.
  ReviewSource? source;

  /// Title for this review.
  core.String? title;

  /// Source type for this review.
  ///
  /// Possible values are EDITORIAL, WEB_USER or GOOGLE_USER.
  core.String? type;

  /// Volume that this review is for.
  core.String? volumeId;

  Review();

  Review.fromJson(core.Map _json) {
    if (_json.containsKey('author')) {
      author = ReviewAuthor.fromJson(
          _json['author'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('date')) {
      date = _json['date'] as core.String;
    }
    if (_json.containsKey('fullTextUrl')) {
      fullTextUrl = _json['fullTextUrl'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('rating')) {
      rating = _json['rating'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = ReviewSource.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('volumeId')) {
      volumeId = _json['volumeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (author != null) 'author': author!.toJson(),
        if (content != null) 'content': content!,
        if (date != null) 'date': date!,
        if (fullTextUrl != null) 'fullTextUrl': fullTextUrl!,
        if (kind != null) 'kind': kind!,
        if (rating != null) 'rating': rating!,
        if (source != null) 'source': source!.toJson(),
        if (title != null) 'title': title!,
        if (type != null) 'type': type!,
        if (volumeId != null) 'volumeId': volumeId!,
      };
}

class SeriesSeriesSeriesSubscriptionReleaseInfoCurrentReleaseInfo {
  core.double? amountInMicros;
  core.String? currencyCode;
  core.String? releaseNumber;
  core.String? releaseTime;

  SeriesSeriesSeriesSubscriptionReleaseInfoCurrentReleaseInfo();

  SeriesSeriesSeriesSubscriptionReleaseInfoCurrentReleaseInfo.fromJson(
      core.Map _json) {
    if (_json.containsKey('amountInMicros')) {
      amountInMicros = (_json['amountInMicros'] as core.num).toDouble();
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('releaseNumber')) {
      releaseNumber = _json['releaseNumber'] as core.String;
    }
    if (_json.containsKey('releaseTime')) {
      releaseTime = _json['releaseTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amountInMicros != null) 'amountInMicros': amountInMicros!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (releaseNumber != null) 'releaseNumber': releaseNumber!,
        if (releaseTime != null) 'releaseTime': releaseTime!,
      };
}

class SeriesSeriesSeriesSubscriptionReleaseInfoNextReleaseInfo {
  core.double? amountInMicros;
  core.String? currencyCode;
  core.String? releaseNumber;
  core.String? releaseTime;

  SeriesSeriesSeriesSubscriptionReleaseInfoNextReleaseInfo();

  SeriesSeriesSeriesSubscriptionReleaseInfoNextReleaseInfo.fromJson(
      core.Map _json) {
    if (_json.containsKey('amountInMicros')) {
      amountInMicros = (_json['amountInMicros'] as core.num).toDouble();
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('releaseNumber')) {
      releaseNumber = _json['releaseNumber'] as core.String;
    }
    if (_json.containsKey('releaseTime')) {
      releaseTime = _json['releaseTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amountInMicros != null) 'amountInMicros': amountInMicros!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (releaseNumber != null) 'releaseNumber': releaseNumber!,
        if (releaseTime != null) 'releaseTime': releaseTime!,
      };
}

class SeriesSeriesSeriesSubscriptionReleaseInfo {
  core.String? cancelTime;
  SeriesSeriesSeriesSubscriptionReleaseInfoCurrentReleaseInfo?
      currentReleaseInfo;
  SeriesSeriesSeriesSubscriptionReleaseInfoNextReleaseInfo? nextReleaseInfo;
  core.String? seriesSubscriptionType;

  SeriesSeriesSeriesSubscriptionReleaseInfo();

  SeriesSeriesSeriesSubscriptionReleaseInfo.fromJson(core.Map _json) {
    if (_json.containsKey('cancelTime')) {
      cancelTime = _json['cancelTime'] as core.String;
    }
    if (_json.containsKey('currentReleaseInfo')) {
      currentReleaseInfo =
          SeriesSeriesSeriesSubscriptionReleaseInfoCurrentReleaseInfo.fromJson(
              _json['currentReleaseInfo']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nextReleaseInfo')) {
      nextReleaseInfo =
          SeriesSeriesSeriesSubscriptionReleaseInfoNextReleaseInfo.fromJson(
              _json['nextReleaseInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('seriesSubscriptionType')) {
      seriesSubscriptionType = _json['seriesSubscriptionType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cancelTime != null) 'cancelTime': cancelTime!,
        if (currentReleaseInfo != null)
          'currentReleaseInfo': currentReleaseInfo!.toJson(),
        if (nextReleaseInfo != null)
          'nextReleaseInfo': nextReleaseInfo!.toJson(),
        if (seriesSubscriptionType != null)
          'seriesSubscriptionType': seriesSubscriptionType!,
      };
}

class SeriesSeries {
  core.String? bannerImageUrl;
  core.bool? eligibleForSubscription;
  core.String? imageUrl;
  core.bool? isComplete;
  core.String? seriesFormatType;
  core.String? seriesId;
  SeriesSeriesSeriesSubscriptionReleaseInfo? seriesSubscriptionReleaseInfo;
  core.String? seriesType;
  core.String? subscriptionId;
  core.String? title;

  SeriesSeries();

  SeriesSeries.fromJson(core.Map _json) {
    if (_json.containsKey('bannerImageUrl')) {
      bannerImageUrl = _json['bannerImageUrl'] as core.String;
    }
    if (_json.containsKey('eligibleForSubscription')) {
      eligibleForSubscription = _json['eligibleForSubscription'] as core.bool;
    }
    if (_json.containsKey('imageUrl')) {
      imageUrl = _json['imageUrl'] as core.String;
    }
    if (_json.containsKey('isComplete')) {
      isComplete = _json['isComplete'] as core.bool;
    }
    if (_json.containsKey('seriesFormatType')) {
      seriesFormatType = _json['seriesFormatType'] as core.String;
    }
    if (_json.containsKey('seriesId')) {
      seriesId = _json['seriesId'] as core.String;
    }
    if (_json.containsKey('seriesSubscriptionReleaseInfo')) {
      seriesSubscriptionReleaseInfo =
          SeriesSeriesSeriesSubscriptionReleaseInfo.fromJson(
              _json['seriesSubscriptionReleaseInfo']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('seriesType')) {
      seriesType = _json['seriesType'] as core.String;
    }
    if (_json.containsKey('subscriptionId')) {
      subscriptionId = _json['subscriptionId'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bannerImageUrl != null) 'bannerImageUrl': bannerImageUrl!,
        if (eligibleForSubscription != null)
          'eligibleForSubscription': eligibleForSubscription!,
        if (imageUrl != null) 'imageUrl': imageUrl!,
        if (isComplete != null) 'isComplete': isComplete!,
        if (seriesFormatType != null) 'seriesFormatType': seriesFormatType!,
        if (seriesId != null) 'seriesId': seriesId!,
        if (seriesSubscriptionReleaseInfo != null)
          'seriesSubscriptionReleaseInfo':
              seriesSubscriptionReleaseInfo!.toJson(),
        if (seriesType != null) 'seriesType': seriesType!,
        if (subscriptionId != null) 'subscriptionId': subscriptionId!,
        if (title != null) 'title': title!,
      };
}

class Series {
  /// Resource type.
  core.String? kind;
  core.List<SeriesSeries>? series;

  Series();

  Series.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('series')) {
      series = (_json['series'] as core.List)
          .map<SeriesSeries>((value) => SeriesSeries.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (series != null)
          'series': series!.map((value) => value.toJson()).toList(),
      };
}

class Seriesmembership {
  /// Resorce type.
  core.String? kind;
  core.List<Volume>? member;
  core.String? nextPageToken;

  Seriesmembership();

  Seriesmembership.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('member')) {
      member = (_json['member'] as core.List)
          .map<Volume>((value) =>
              Volume.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (member != null)
          'member': member!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// User settings in sub-objects, each for different purposes.
class UsersettingsNotesExport {
  core.String? folderName;
  core.bool? isEnabled;

  UsersettingsNotesExport();

  UsersettingsNotesExport.fromJson(core.Map _json) {
    if (_json.containsKey('folderName')) {
      folderName = _json['folderName'] as core.String;
    }
    if (_json.containsKey('isEnabled')) {
      isEnabled = _json['isEnabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (folderName != null) 'folderName': folderName!,
        if (isEnabled != null) 'isEnabled': isEnabled!,
      };
}

class UsersettingsNotificationMatchMyInterests {
  core.String? optedState;

  UsersettingsNotificationMatchMyInterests();

  UsersettingsNotificationMatchMyInterests.fromJson(core.Map _json) {
    if (_json.containsKey('opted_state')) {
      optedState = _json['opted_state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (optedState != null) 'opted_state': optedState!,
      };
}

class UsersettingsNotificationMoreFromAuthors {
  core.String? optedState;

  UsersettingsNotificationMoreFromAuthors();

  UsersettingsNotificationMoreFromAuthors.fromJson(core.Map _json) {
    if (_json.containsKey('opted_state')) {
      optedState = _json['opted_state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (optedState != null) 'opted_state': optedState!,
      };
}

class UsersettingsNotificationMoreFromSeries {
  core.String? optedState;

  UsersettingsNotificationMoreFromSeries();

  UsersettingsNotificationMoreFromSeries.fromJson(core.Map _json) {
    if (_json.containsKey('opted_state')) {
      optedState = _json['opted_state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (optedState != null) 'opted_state': optedState!,
      };
}

class UsersettingsNotificationPriceDrop {
  core.String? optedState;

  UsersettingsNotificationPriceDrop();

  UsersettingsNotificationPriceDrop.fromJson(core.Map _json) {
    if (_json.containsKey('opted_state')) {
      optedState = _json['opted_state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (optedState != null) 'opted_state': optedState!,
      };
}

class UsersettingsNotificationRewardExpirations {
  core.String? optedState;

  UsersettingsNotificationRewardExpirations();

  UsersettingsNotificationRewardExpirations.fromJson(core.Map _json) {
    if (_json.containsKey('opted_state')) {
      optedState = _json['opted_state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (optedState != null) 'opted_state': optedState!,
      };
}

class UsersettingsNotification {
  UsersettingsNotificationMatchMyInterests? matchMyInterests;
  UsersettingsNotificationMoreFromAuthors? moreFromAuthors;
  UsersettingsNotificationMoreFromSeries? moreFromSeries;
  UsersettingsNotificationPriceDrop? priceDrop;
  UsersettingsNotificationRewardExpirations? rewardExpirations;

  UsersettingsNotification();

  UsersettingsNotification.fromJson(core.Map _json) {
    if (_json.containsKey('matchMyInterests')) {
      matchMyInterests = UsersettingsNotificationMatchMyInterests.fromJson(
          _json['matchMyInterests'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('moreFromAuthors')) {
      moreFromAuthors = UsersettingsNotificationMoreFromAuthors.fromJson(
          _json['moreFromAuthors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('moreFromSeries')) {
      moreFromSeries = UsersettingsNotificationMoreFromSeries.fromJson(
          _json['moreFromSeries'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('priceDrop')) {
      priceDrop = UsersettingsNotificationPriceDrop.fromJson(
          _json['priceDrop'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rewardExpirations')) {
      rewardExpirations = UsersettingsNotificationRewardExpirations.fromJson(
          _json['rewardExpirations'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (matchMyInterests != null)
          'matchMyInterests': matchMyInterests!.toJson(),
        if (moreFromAuthors != null)
          'moreFromAuthors': moreFromAuthors!.toJson(),
        if (moreFromSeries != null) 'moreFromSeries': moreFromSeries!.toJson(),
        if (priceDrop != null) 'priceDrop': priceDrop!.toJson(),
        if (rewardExpirations != null)
          'rewardExpirations': rewardExpirations!.toJson(),
      };
}

class Usersettings {
  /// Resource type.
  core.String? kind;

  /// User settings in sub-objects, each for different purposes.
  UsersettingsNotesExport? notesExport;
  UsersettingsNotification? notification;

  Usersettings();

  Usersettings.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('notesExport')) {
      notesExport = UsersettingsNotesExport.fromJson(
          _json['notesExport'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('notification')) {
      notification = UsersettingsNotification.fromJson(
          _json['notification'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (notesExport != null) 'notesExport': notesExport!.toJson(),
        if (notification != null) 'notification': notification!.toJson(),
      };
}

/// Information about epub content.
///
/// (In LITE projection.)
class VolumeAccessInfoEpub {
  /// URL to retrieve ACS token for epub download.
  ///
  /// (In LITE projection.)
  core.String? acsTokenLink;

  /// URL to download epub.
  ///
  /// (In LITE projection.)
  core.String? downloadLink;

  /// Is a flowing text epub available either as public domain or for purchase.
  ///
  /// (In LITE projection.)
  core.bool? isAvailable;

  VolumeAccessInfoEpub();

  VolumeAccessInfoEpub.fromJson(core.Map _json) {
    if (_json.containsKey('acsTokenLink')) {
      acsTokenLink = _json['acsTokenLink'] as core.String;
    }
    if (_json.containsKey('downloadLink')) {
      downloadLink = _json['downloadLink'] as core.String;
    }
    if (_json.containsKey('isAvailable')) {
      isAvailable = _json['isAvailable'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (acsTokenLink != null) 'acsTokenLink': acsTokenLink!,
        if (downloadLink != null) 'downloadLink': downloadLink!,
        if (isAvailable != null) 'isAvailable': isAvailable!,
      };
}

/// Information about pdf content.
///
/// (In LITE projection.)
class VolumeAccessInfoPdf {
  /// URL to retrieve ACS token for pdf download.
  ///
  /// (In LITE projection.)
  core.String? acsTokenLink;

  /// URL to download pdf.
  ///
  /// (In LITE projection.)
  core.String? downloadLink;

  /// Is a scanned image pdf available either as public domain or for purchase.
  ///
  /// (In LITE projection.)
  core.bool? isAvailable;

  VolumeAccessInfoPdf();

  VolumeAccessInfoPdf.fromJson(core.Map _json) {
    if (_json.containsKey('acsTokenLink')) {
      acsTokenLink = _json['acsTokenLink'] as core.String;
    }
    if (_json.containsKey('downloadLink')) {
      downloadLink = _json['downloadLink'] as core.String;
    }
    if (_json.containsKey('isAvailable')) {
      isAvailable = _json['isAvailable'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (acsTokenLink != null) 'acsTokenLink': acsTokenLink!,
        if (downloadLink != null) 'downloadLink': downloadLink!,
        if (isAvailable != null) 'isAvailable': isAvailable!,
      };
}

/// Any information about a volume related to reading or obtaining that volume
/// text.
///
/// This information can depend on country (books may be public domain in one
/// country but not in another, e.g.).
class VolumeAccessInfo {
  /// Combines the access and viewability of this volume into a single status
  /// field for this user.
  ///
  /// Values can be FULL_PURCHASED, FULL_PUBLIC_DOMAIN, SAMPLE or NONE. (In LITE
  /// projection.)
  core.String? accessViewStatus;

  /// The two-letter ISO_3166-1 country code for which this access information
  /// is valid.
  ///
  /// (In LITE projection.)
  core.String? country;

  /// Information about a volume's download license access restrictions.
  DownloadAccessRestriction? downloadAccess;

  /// URL to the Google Drive viewer if this volume is uploaded by the user by
  /// selecting the file from Google Drive.
  core.String? driveImportedContentLink;

  /// Whether this volume can be embedded in a viewport using the Embedded
  /// Viewer API.
  core.bool? embeddable;

  /// Information about epub content.
  ///
  /// (In LITE projection.)
  VolumeAccessInfoEpub? epub;

  /// Whether this volume requires that the client explicitly request offline
  /// download license rather than have it done automatically when loading the
  /// content, if the client supports it.
  core.bool? explicitOfflineLicenseManagement;

  /// Information about pdf content.
  ///
  /// (In LITE projection.)
  VolumeAccessInfoPdf? pdf;

  /// Whether or not this book is public domain in the country listed above.
  core.bool? publicDomain;

  /// Whether quote sharing is allowed for this volume.
  core.bool? quoteSharingAllowed;

  /// Whether text-to-speech is permitted for this volume.
  ///
  /// Values can be ALLOWED, ALLOWED_FOR_ACCESSIBILITY, or NOT_ALLOWED.
  core.String? textToSpeechPermission;

  /// For ordered but not yet processed orders, we give a URL that can be used
  /// to go to the appropriate Google Wallet page.
  core.String? viewOrderUrl;

  /// The read access of a volume.
  ///
  /// Possible values are PARTIAL, ALL_PAGES, NO_PAGES or UNKNOWN. This value
  /// depends on the country listed above. A value of PARTIAL means that the
  /// publisher has allowed some portion of the volume to be viewed publicly,
  /// without purchase. This can apply to eBooks as well as non-eBooks. Public
  /// domain books will always have a value of ALL_PAGES.
  core.String? viewability;

  /// URL to read this volume on the Google Books site.
  ///
  /// Link will not allow users to read non-viewable volumes.
  core.String? webReaderLink;

  VolumeAccessInfo();

  VolumeAccessInfo.fromJson(core.Map _json) {
    if (_json.containsKey('accessViewStatus')) {
      accessViewStatus = _json['accessViewStatus'] as core.String;
    }
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('downloadAccess')) {
      downloadAccess = DownloadAccessRestriction.fromJson(
          _json['downloadAccess'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('driveImportedContentLink')) {
      driveImportedContentLink =
          _json['driveImportedContentLink'] as core.String;
    }
    if (_json.containsKey('embeddable')) {
      embeddable = _json['embeddable'] as core.bool;
    }
    if (_json.containsKey('epub')) {
      epub = VolumeAccessInfoEpub.fromJson(
          _json['epub'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('explicitOfflineLicenseManagement')) {
      explicitOfflineLicenseManagement =
          _json['explicitOfflineLicenseManagement'] as core.bool;
    }
    if (_json.containsKey('pdf')) {
      pdf = VolumeAccessInfoPdf.fromJson(
          _json['pdf'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('publicDomain')) {
      publicDomain = _json['publicDomain'] as core.bool;
    }
    if (_json.containsKey('quoteSharingAllowed')) {
      quoteSharingAllowed = _json['quoteSharingAllowed'] as core.bool;
    }
    if (_json.containsKey('textToSpeechPermission')) {
      textToSpeechPermission = _json['textToSpeechPermission'] as core.String;
    }
    if (_json.containsKey('viewOrderUrl')) {
      viewOrderUrl = _json['viewOrderUrl'] as core.String;
    }
    if (_json.containsKey('viewability')) {
      viewability = _json['viewability'] as core.String;
    }
    if (_json.containsKey('webReaderLink')) {
      webReaderLink = _json['webReaderLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessViewStatus != null) 'accessViewStatus': accessViewStatus!,
        if (country != null) 'country': country!,
        if (downloadAccess != null) 'downloadAccess': downloadAccess!.toJson(),
        if (driveImportedContentLink != null)
          'driveImportedContentLink': driveImportedContentLink!,
        if (embeddable != null) 'embeddable': embeddable!,
        if (epub != null) 'epub': epub!.toJson(),
        if (explicitOfflineLicenseManagement != null)
          'explicitOfflineLicenseManagement': explicitOfflineLicenseManagement!,
        if (pdf != null) 'pdf': pdf!.toJson(),
        if (publicDomain != null) 'publicDomain': publicDomain!,
        if (quoteSharingAllowed != null)
          'quoteSharingAllowed': quoteSharingAllowed!,
        if (textToSpeechPermission != null)
          'textToSpeechPermission': textToSpeechPermission!,
        if (viewOrderUrl != null) 'viewOrderUrl': viewOrderUrl!,
        if (viewability != null) 'viewability': viewability!,
        if (webReaderLink != null) 'webReaderLink': webReaderLink!,
      };
}

class VolumeLayerInfoLayers {
  /// The layer id of this layer (e.g. "geo").
  core.String? layerId;

  /// The current version of this layer's volume annotations.
  ///
  /// Note that this version applies only to the data in the
  /// books.layers.volumeAnnotations.* responses. The actual annotation data is
  /// versioned separately.
  core.String? volumeAnnotationsVersion;

  VolumeLayerInfoLayers();

  VolumeLayerInfoLayers.fromJson(core.Map _json) {
    if (_json.containsKey('layerId')) {
      layerId = _json['layerId'] as core.String;
    }
    if (_json.containsKey('volumeAnnotationsVersion')) {
      volumeAnnotationsVersion =
          _json['volumeAnnotationsVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (layerId != null) 'layerId': layerId!,
        if (volumeAnnotationsVersion != null)
          'volumeAnnotationsVersion': volumeAnnotationsVersion!,
      };
}

/// What layers exist in this volume and high level information about them.
class VolumeLayerInfo {
  /// A layer should appear here if and only if the layer exists for this book.
  core.List<VolumeLayerInfoLayers>? layers;

  VolumeLayerInfo();

  VolumeLayerInfo.fromJson(core.Map _json) {
    if (_json.containsKey('layers')) {
      layers = (_json['layers'] as core.List)
          .map<VolumeLayerInfoLayers>((value) => VolumeLayerInfoLayers.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (layers != null)
          'layers': layers!.map((value) => value.toJson()).toList(),
      };
}

/// Recommendation related information for this volume.
class VolumeRecommendedInfo {
  /// A text explaining why this volume is recommended.
  core.String? explanation;

  VolumeRecommendedInfo();

  VolumeRecommendedInfo.fromJson(core.Map _json) {
    if (_json.containsKey('explanation')) {
      explanation = _json['explanation'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (explanation != null) 'explanation': explanation!,
      };
}

/// Suggested retail price.
///
/// (In LITE projection.)
class VolumeSaleInfoListPrice {
  /// Amount in the currency listed below.
  ///
  /// (In LITE projection.)
  core.double? amount;

  /// An ISO 4217, three-letter currency code.
  ///
  /// (In LITE projection.)
  core.String? currencyCode;

  VolumeSaleInfoListPrice();

  VolumeSaleInfoListPrice.fromJson(core.Map _json) {
    if (_json.containsKey('amount')) {
      amount = (_json['amount'] as core.num).toDouble();
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amount != null) 'amount': amount!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
      };
}

/// Offer list (=undiscounted) price in Micros.
class VolumeSaleInfoOffersListPrice {
  core.double? amountInMicros;
  core.String? currencyCode;

  VolumeSaleInfoOffersListPrice();

  VolumeSaleInfoOffersListPrice.fromJson(core.Map _json) {
    if (_json.containsKey('amountInMicros')) {
      amountInMicros = (_json['amountInMicros'] as core.num).toDouble();
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amountInMicros != null) 'amountInMicros': amountInMicros!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
      };
}

/// The rental duration (for rental offers only).
class VolumeSaleInfoOffersRentalDuration {
  core.double? count;
  core.String? unit;

  VolumeSaleInfoOffersRentalDuration();

  VolumeSaleInfoOffersRentalDuration.fromJson(core.Map _json) {
    if (_json.containsKey('count')) {
      count = (_json['count'] as core.num).toDouble();
    }
    if (_json.containsKey('unit')) {
      unit = _json['unit'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (count != null) 'count': count!,
        if (unit != null) 'unit': unit!,
      };
}

/// Offer retail (=discounted) price in Micros
class VolumeSaleInfoOffersRetailPrice {
  core.double? amountInMicros;
  core.String? currencyCode;

  VolumeSaleInfoOffersRetailPrice();

  VolumeSaleInfoOffersRetailPrice.fromJson(core.Map _json) {
    if (_json.containsKey('amountInMicros')) {
      amountInMicros = (_json['amountInMicros'] as core.num).toDouble();
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amountInMicros != null) 'amountInMicros': amountInMicros!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
      };
}

class VolumeSaleInfoOffers {
  /// The finsky offer type (e.g., PURCHASE=0 RENTAL=3)
  core.int? finskyOfferType;

  /// Indicates whether the offer is giftable.
  core.bool? giftable;

  /// Offer list (=undiscounted) price in Micros.
  VolumeSaleInfoOffersListPrice? listPrice;

  /// The rental duration (for rental offers only).
  VolumeSaleInfoOffersRentalDuration? rentalDuration;

  /// Offer retail (=discounted) price in Micros
  VolumeSaleInfoOffersRetailPrice? retailPrice;

  VolumeSaleInfoOffers();

  VolumeSaleInfoOffers.fromJson(core.Map _json) {
    if (_json.containsKey('finskyOfferType')) {
      finskyOfferType = _json['finskyOfferType'] as core.int;
    }
    if (_json.containsKey('giftable')) {
      giftable = _json['giftable'] as core.bool;
    }
    if (_json.containsKey('listPrice')) {
      listPrice = VolumeSaleInfoOffersListPrice.fromJson(
          _json['listPrice'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rentalDuration')) {
      rentalDuration = VolumeSaleInfoOffersRentalDuration.fromJson(
          _json['rentalDuration'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('retailPrice')) {
      retailPrice = VolumeSaleInfoOffersRetailPrice.fromJson(
          _json['retailPrice'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (finskyOfferType != null) 'finskyOfferType': finskyOfferType!,
        if (giftable != null) 'giftable': giftable!,
        if (listPrice != null) 'listPrice': listPrice!.toJson(),
        if (rentalDuration != null) 'rentalDuration': rentalDuration!.toJson(),
        if (retailPrice != null) 'retailPrice': retailPrice!.toJson(),
      };
}

/// The actual selling price of the book.
///
/// This is the same as the suggested retail or list price unless there are
/// offers or discounts on this volume. (In LITE projection.)
class VolumeSaleInfoRetailPrice {
  /// Amount in the currency listed below.
  ///
  /// (In LITE projection.)
  core.double? amount;

  /// An ISO 4217, three-letter currency code.
  ///
  /// (In LITE projection.)
  core.String? currencyCode;

  VolumeSaleInfoRetailPrice();

  VolumeSaleInfoRetailPrice.fromJson(core.Map _json) {
    if (_json.containsKey('amount')) {
      amount = (_json['amount'] as core.num).toDouble();
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amount != null) 'amount': amount!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
      };
}

/// Any information about a volume related to the eBookstore and/or
/// purchaseability.
///
/// This information can depend on the country where the request originates from
/// (i.e. books may not be for sale in certain countries).
class VolumeSaleInfo {
  /// URL to purchase this volume on the Google Books site.
  ///
  /// (In LITE projection)
  core.String? buyLink;

  /// The two-letter ISO_3166-1 country code for which this sale information is
  /// valid.
  ///
  /// (In LITE projection.)
  core.String? country;

  /// Whether or not this volume is an eBook (can be added to the My eBooks
  /// shelf).
  core.bool? isEbook;

  /// Suggested retail price.
  ///
  /// (In LITE projection.)
  VolumeSaleInfoListPrice? listPrice;

  /// Offers available for this volume (sales and rentals).
  core.List<VolumeSaleInfoOffers>? offers;

  /// The date on which this book is available for sale.
  core.String? onSaleDate;

  /// The actual selling price of the book.
  ///
  /// This is the same as the suggested retail or list price unless there are
  /// offers or discounts on this volume. (In LITE projection.)
  VolumeSaleInfoRetailPrice? retailPrice;

  /// Whether or not this book is available for sale or offered for free in the
  /// Google eBookstore for the country listed above.
  ///
  /// Possible values are FOR_SALE, FOR_RENTAL_ONLY, FOR_SALE_AND_RENTAL, FREE,
  /// NOT_FOR_SALE, or FOR_PREORDER.
  core.String? saleability;

  VolumeSaleInfo();

  VolumeSaleInfo.fromJson(core.Map _json) {
    if (_json.containsKey('buyLink')) {
      buyLink = _json['buyLink'] as core.String;
    }
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('isEbook')) {
      isEbook = _json['isEbook'] as core.bool;
    }
    if (_json.containsKey('listPrice')) {
      listPrice = VolumeSaleInfoListPrice.fromJson(
          _json['listPrice'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('offers')) {
      offers = (_json['offers'] as core.List)
          .map<VolumeSaleInfoOffers>((value) => VolumeSaleInfoOffers.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('onSaleDate')) {
      onSaleDate = _json['onSaleDate'] as core.String;
    }
    if (_json.containsKey('retailPrice')) {
      retailPrice = VolumeSaleInfoRetailPrice.fromJson(
          _json['retailPrice'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('saleability')) {
      saleability = _json['saleability'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buyLink != null) 'buyLink': buyLink!,
        if (country != null) 'country': country!,
        if (isEbook != null) 'isEbook': isEbook!,
        if (listPrice != null) 'listPrice': listPrice!.toJson(),
        if (offers != null)
          'offers': offers!.map((value) => value.toJson()).toList(),
        if (onSaleDate != null) 'onSaleDate': onSaleDate!,
        if (retailPrice != null) 'retailPrice': retailPrice!.toJson(),
        if (saleability != null) 'saleability': saleability!,
      };
}

/// Search result information related to this volume.
class VolumeSearchInfo {
  /// A text snippet containing the search query.
  core.String? textSnippet;

  VolumeSearchInfo();

  VolumeSearchInfo.fromJson(core.Map _json) {
    if (_json.containsKey('textSnippet')) {
      textSnippet = _json['textSnippet'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (textSnippet != null) 'textSnippet': textSnippet!,
      };
}

/// Copy/Paste accounting information.
class VolumeUserInfoCopy {
  core.int? allowedCharacterCount;
  core.String? limitType;
  core.int? remainingCharacterCount;
  core.String? updated;

  VolumeUserInfoCopy();

  VolumeUserInfoCopy.fromJson(core.Map _json) {
    if (_json.containsKey('allowedCharacterCount')) {
      allowedCharacterCount = _json['allowedCharacterCount'] as core.int;
    }
    if (_json.containsKey('limitType')) {
      limitType = _json['limitType'] as core.String;
    }
    if (_json.containsKey('remainingCharacterCount')) {
      remainingCharacterCount = _json['remainingCharacterCount'] as core.int;
    }
    if (_json.containsKey('updated')) {
      updated = _json['updated'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedCharacterCount != null)
          'allowedCharacterCount': allowedCharacterCount!,
        if (limitType != null) 'limitType': limitType!,
        if (remainingCharacterCount != null)
          'remainingCharacterCount': remainingCharacterCount!,
        if (updated != null) 'updated': updated!,
      };
}

/// Information on the ability to share with the family.
class VolumeUserInfoFamilySharing {
  /// The role of the user in the family.
  core.String? familyRole;

  /// Whether or not this volume can be shared with the family by the user.
  ///
  /// This includes sharing eligibility of both the volume and the user. If the
  /// value is true, the user can initiate a family sharing action.
  core.bool? isSharingAllowed;

  /// Whether or not sharing this volume is temporarily disabled due to issues
  /// with the Family Wallet.
  core.bool? isSharingDisabledByFop;

  VolumeUserInfoFamilySharing();

  VolumeUserInfoFamilySharing.fromJson(core.Map _json) {
    if (_json.containsKey('familyRole')) {
      familyRole = _json['familyRole'] as core.String;
    }
    if (_json.containsKey('isSharingAllowed')) {
      isSharingAllowed = _json['isSharingAllowed'] as core.bool;
    }
    if (_json.containsKey('isSharingDisabledByFop')) {
      isSharingDisabledByFop = _json['isSharingDisabledByFop'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (familyRole != null) 'familyRole': familyRole!,
        if (isSharingAllowed != null) 'isSharingAllowed': isSharingAllowed!,
        if (isSharingDisabledByFop != null)
          'isSharingDisabledByFop': isSharingDisabledByFop!,
      };
}

/// Period during this book is/was a valid rental.
class VolumeUserInfoRentalPeriod {
  core.String? endUtcSec;
  core.String? startUtcSec;

  VolumeUserInfoRentalPeriod();

  VolumeUserInfoRentalPeriod.fromJson(core.Map _json) {
    if (_json.containsKey('endUtcSec')) {
      endUtcSec = _json['endUtcSec'] as core.String;
    }
    if (_json.containsKey('startUtcSec')) {
      startUtcSec = _json['startUtcSec'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endUtcSec != null) 'endUtcSec': endUtcSec!,
        if (startUtcSec != null) 'startUtcSec': startUtcSec!,
      };
}

class VolumeUserInfoUserUploadedVolumeInfo {
  core.String? processingState;

  VolumeUserInfoUserUploadedVolumeInfo();

  VolumeUserInfoUserUploadedVolumeInfo.fromJson(core.Map _json) {
    if (_json.containsKey('processingState')) {
      processingState = _json['processingState'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (processingState != null) 'processingState': processingState!,
      };
}

/// User specific information related to this volume.
///
/// (e.g. page this user last read or whether they purchased this book)
class VolumeUserInfo {
  /// Timestamp when this volume was acquired by the user.
  ///
  /// (RFC 3339 UTC date-time format) Acquiring includes purchase, user upload,
  /// receiving family sharing, etc.
  core.String? acquiredTime;

  /// How this volume was acquired.
  core.int? acquisitionType;

  /// Copy/Paste accounting information.
  VolumeUserInfoCopy? copy;

  /// Whether this volume is purchased, sample, pd download etc.
  core.int? entitlementType;

  /// Information on the ability to share with the family.
  VolumeUserInfoFamilySharing? familySharing;

  /// Whether or not the user shared this volume with the family.
  core.bool? isFamilySharedFromUser;

  /// Whether or not the user received this volume through family sharing.
  core.bool? isFamilySharedToUser;

  /// Deprecated: Replaced by familySharing.
  core.bool? isFamilySharingAllowed;

  /// Deprecated: Replaced by familySharing.
  core.bool? isFamilySharingDisabledByFop;

  /// Whether or not this volume is currently in "my books."
  core.bool? isInMyBooks;

  /// Whether or not this volume was pre-ordered by the authenticated user
  /// making the request.
  ///
  /// (In LITE projection.)
  core.bool? isPreordered;

  /// Whether or not this volume was purchased by the authenticated user making
  /// the request.
  ///
  /// (In LITE projection.)
  core.bool? isPurchased;

  /// Whether or not this volume was user uploaded.
  core.bool? isUploaded;

  /// The user's current reading position in the volume, if one is available.
  ///
  /// (In LITE projection.)
  ReadingPosition? readingPosition;

  /// Period during this book is/was a valid rental.
  VolumeUserInfoRentalPeriod? rentalPeriod;

  /// Whether this book is an active or an expired rental.
  core.String? rentalState;

  /// This user's review of this volume, if one exists.
  Review? review;

  /// Timestamp when this volume was last modified by a user action, such as a
  /// reading position update, volume purchase or writing a review.
  ///
  /// (RFC 3339 UTC date-time format).
  core.String? updated;
  VolumeUserInfoUserUploadedVolumeInfo? userUploadedVolumeInfo;

  VolumeUserInfo();

  VolumeUserInfo.fromJson(core.Map _json) {
    if (_json.containsKey('acquiredTime')) {
      acquiredTime = _json['acquiredTime'] as core.String;
    }
    if (_json.containsKey('acquisitionType')) {
      acquisitionType = _json['acquisitionType'] as core.int;
    }
    if (_json.containsKey('copy')) {
      copy = VolumeUserInfoCopy.fromJson(
          _json['copy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('entitlementType')) {
      entitlementType = _json['entitlementType'] as core.int;
    }
    if (_json.containsKey('familySharing')) {
      familySharing = VolumeUserInfoFamilySharing.fromJson(
          _json['familySharing'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isFamilySharedFromUser')) {
      isFamilySharedFromUser = _json['isFamilySharedFromUser'] as core.bool;
    }
    if (_json.containsKey('isFamilySharedToUser')) {
      isFamilySharedToUser = _json['isFamilySharedToUser'] as core.bool;
    }
    if (_json.containsKey('isFamilySharingAllowed')) {
      isFamilySharingAllowed = _json['isFamilySharingAllowed'] as core.bool;
    }
    if (_json.containsKey('isFamilySharingDisabledByFop')) {
      isFamilySharingDisabledByFop =
          _json['isFamilySharingDisabledByFop'] as core.bool;
    }
    if (_json.containsKey('isInMyBooks')) {
      isInMyBooks = _json['isInMyBooks'] as core.bool;
    }
    if (_json.containsKey('isPreordered')) {
      isPreordered = _json['isPreordered'] as core.bool;
    }
    if (_json.containsKey('isPurchased')) {
      isPurchased = _json['isPurchased'] as core.bool;
    }
    if (_json.containsKey('isUploaded')) {
      isUploaded = _json['isUploaded'] as core.bool;
    }
    if (_json.containsKey('readingPosition')) {
      readingPosition = ReadingPosition.fromJson(
          _json['readingPosition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rentalPeriod')) {
      rentalPeriod = VolumeUserInfoRentalPeriod.fromJson(
          _json['rentalPeriod'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rentalState')) {
      rentalState = _json['rentalState'] as core.String;
    }
    if (_json.containsKey('review')) {
      review = Review.fromJson(
          _json['review'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updated')) {
      updated = _json['updated'] as core.String;
    }
    if (_json.containsKey('userUploadedVolumeInfo')) {
      userUploadedVolumeInfo = VolumeUserInfoUserUploadedVolumeInfo.fromJson(
          _json['userUploadedVolumeInfo']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (acquiredTime != null) 'acquiredTime': acquiredTime!,
        if (acquisitionType != null) 'acquisitionType': acquisitionType!,
        if (copy != null) 'copy': copy!.toJson(),
        if (entitlementType != null) 'entitlementType': entitlementType!,
        if (familySharing != null) 'familySharing': familySharing!.toJson(),
        if (isFamilySharedFromUser != null)
          'isFamilySharedFromUser': isFamilySharedFromUser!,
        if (isFamilySharedToUser != null)
          'isFamilySharedToUser': isFamilySharedToUser!,
        if (isFamilySharingAllowed != null)
          'isFamilySharingAllowed': isFamilySharingAllowed!,
        if (isFamilySharingDisabledByFop != null)
          'isFamilySharingDisabledByFop': isFamilySharingDisabledByFop!,
        if (isInMyBooks != null) 'isInMyBooks': isInMyBooks!,
        if (isPreordered != null) 'isPreordered': isPreordered!,
        if (isPurchased != null) 'isPurchased': isPurchased!,
        if (isUploaded != null) 'isUploaded': isUploaded!,
        if (readingPosition != null)
          'readingPosition': readingPosition!.toJson(),
        if (rentalPeriod != null) 'rentalPeriod': rentalPeriod!.toJson(),
        if (rentalState != null) 'rentalState': rentalState!,
        if (review != null) 'review': review!.toJson(),
        if (updated != null) 'updated': updated!,
        if (userUploadedVolumeInfo != null)
          'userUploadedVolumeInfo': userUploadedVolumeInfo!.toJson(),
      };
}

/// Physical dimensions of this volume.
class VolumeVolumeInfoDimensions {
  /// Height or length of this volume (in cm).
  core.String? height;

  /// Thickness of this volume (in cm).
  core.String? thickness;

  /// Width of this volume (in cm).
  core.String? width;

  VolumeVolumeInfoDimensions();

  VolumeVolumeInfoDimensions.fromJson(core.Map _json) {
    if (_json.containsKey('height')) {
      height = _json['height'] as core.String;
    }
    if (_json.containsKey('thickness')) {
      thickness = _json['thickness'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (height != null) 'height': height!,
        if (thickness != null) 'thickness': thickness!,
        if (width != null) 'width': width!,
      };
}

/// A list of image links for all the sizes that are available.
///
/// (In LITE projection.)
class VolumeVolumeInfoImageLinks {
  /// Image link for extra large size (width of ~1280 pixels).
  ///
  /// (In LITE projection)
  core.String? extraLarge;

  /// Image link for large size (width of ~800 pixels).
  ///
  /// (In LITE projection)
  core.String? large;

  /// Image link for medium size (width of ~575 pixels).
  ///
  /// (In LITE projection)
  core.String? medium;

  /// Image link for small size (width of ~300 pixels).
  ///
  /// (In LITE projection)
  core.String? small;

  /// Image link for small thumbnail size (width of ~80 pixels).
  ///
  /// (In LITE projection)
  core.String? smallThumbnail;

  /// Image link for thumbnail size (width of ~128 pixels).
  ///
  /// (In LITE projection)
  core.String? thumbnail;

  VolumeVolumeInfoImageLinks();

  VolumeVolumeInfoImageLinks.fromJson(core.Map _json) {
    if (_json.containsKey('extraLarge')) {
      extraLarge = _json['extraLarge'] as core.String;
    }
    if (_json.containsKey('large')) {
      large = _json['large'] as core.String;
    }
    if (_json.containsKey('medium')) {
      medium = _json['medium'] as core.String;
    }
    if (_json.containsKey('small')) {
      small = _json['small'] as core.String;
    }
    if (_json.containsKey('smallThumbnail')) {
      smallThumbnail = _json['smallThumbnail'] as core.String;
    }
    if (_json.containsKey('thumbnail')) {
      thumbnail = _json['thumbnail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (extraLarge != null) 'extraLarge': extraLarge!,
        if (large != null) 'large': large!,
        if (medium != null) 'medium': medium!,
        if (small != null) 'small': small!,
        if (smallThumbnail != null) 'smallThumbnail': smallThumbnail!,
        if (thumbnail != null) 'thumbnail': thumbnail!,
      };
}

class VolumeVolumeInfoIndustryIdentifiers {
  /// Industry specific volume identifier.
  core.String? identifier;

  /// Identifier type.
  ///
  /// Possible values are ISBN_10, ISBN_13, ISSN and OTHER.
  core.String? type;

  VolumeVolumeInfoIndustryIdentifiers();

  VolumeVolumeInfoIndustryIdentifiers.fromJson(core.Map _json) {
    if (_json.containsKey('identifier')) {
      identifier = _json['identifier'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (identifier != null) 'identifier': identifier!,
        if (type != null) 'type': type!,
      };
}

/// A top-level summary of the panelization info in this volume.
class VolumeVolumeInfoPanelizationSummary {
  core.bool? containsEpubBubbles;
  core.bool? containsImageBubbles;
  core.String? epubBubbleVersion;
  core.String? imageBubbleVersion;

  VolumeVolumeInfoPanelizationSummary();

  VolumeVolumeInfoPanelizationSummary.fromJson(core.Map _json) {
    if (_json.containsKey('containsEpubBubbles')) {
      containsEpubBubbles = _json['containsEpubBubbles'] as core.bool;
    }
    if (_json.containsKey('containsImageBubbles')) {
      containsImageBubbles = _json['containsImageBubbles'] as core.bool;
    }
    if (_json.containsKey('epubBubbleVersion')) {
      epubBubbleVersion = _json['epubBubbleVersion'] as core.String;
    }
    if (_json.containsKey('imageBubbleVersion')) {
      imageBubbleVersion = _json['imageBubbleVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (containsEpubBubbles != null)
          'containsEpubBubbles': containsEpubBubbles!,
        if (containsImageBubbles != null)
          'containsImageBubbles': containsImageBubbles!,
        if (epubBubbleVersion != null) 'epubBubbleVersion': epubBubbleVersion!,
        if (imageBubbleVersion != null)
          'imageBubbleVersion': imageBubbleVersion!,
      };
}

/// The reading modes available for this volume.
class VolumeVolumeInfoReadingModes {
  core.bool? image;
  core.bool? text;

  VolumeVolumeInfoReadingModes();

  VolumeVolumeInfoReadingModes.fromJson(core.Map _json) {
    if (_json.containsKey('image')) {
      image = _json['image'] as core.bool;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (image != null) 'image': image!,
        if (text != null) 'text': text!,
      };
}

/// General volume information.
class VolumeVolumeInfo {
  /// Whether anonymous logging should be allowed.
  core.bool? allowAnonLogging;

  /// The names of the authors and/or editors for this volume.
  ///
  /// (In LITE projection)
  core.List<core.String>? authors;

  /// The mean review rating for this volume.
  ///
  /// (min = 1.0, max = 5.0)
  core.double? averageRating;

  /// Canonical URL for a volume.
  ///
  /// (In LITE projection.)
  core.String? canonicalVolumeLink;

  /// A list of subject categories, such as "Fiction", "Suspense", etc.
  core.List<core.String>? categories;

  /// Whether the volume has comics content.
  core.bool? comicsContent;

  /// An identifier for the version of the volume content (text & images).
  ///
  /// (In LITE projection)
  core.String? contentVersion;

  /// A synopsis of the volume.
  ///
  /// The text of the description is formatted in HTML and includes simple
  /// formatting elements, such as b, i, and br tags. (In LITE projection.)
  core.String? description;

  /// Physical dimensions of this volume.
  VolumeVolumeInfoDimensions? dimensions;

  /// A list of image links for all the sizes that are available.
  ///
  /// (In LITE projection.)
  VolumeVolumeInfoImageLinks? imageLinks;

  /// Industry standard identifiers for this volume.
  core.List<VolumeVolumeInfoIndustryIdentifiers>? industryIdentifiers;

  /// URL to view information about this volume on the Google Books site.
  ///
  /// (In LITE projection)
  core.String? infoLink;

  /// Best language for this volume (based on content).
  ///
  /// It is the two-letter ISO 639-1 code such as 'fr', 'en', etc.
  core.String? language;

  /// The main category to which this volume belongs.
  ///
  /// It will be the category from the categories list returned below that has
  /// the highest weight.
  core.String? mainCategory;
  core.String? maturityRating;

  /// Total number of pages as per publisher metadata.
  core.int? pageCount;

  /// A top-level summary of the panelization info in this volume.
  VolumeVolumeInfoPanelizationSummary? panelizationSummary;

  /// URL to preview this volume on the Google Books site.
  core.String? previewLink;

  /// Type of publication of this volume.
  ///
  /// Possible values are BOOK or MAGAZINE.
  core.String? printType;

  /// Total number of printed pages in generated pdf representation.
  core.int? printedPageCount;

  /// Date of publication.
  ///
  /// (In LITE projection.)
  core.String? publishedDate;

  /// Publisher of this volume.
  ///
  /// (In LITE projection.)
  core.String? publisher;

  /// The number of review ratings for this volume.
  core.int? ratingsCount;

  /// The reading modes available for this volume.
  VolumeVolumeInfoReadingModes? readingModes;

  /// Total number of sample pages as per publisher metadata.
  core.int? samplePageCount;
  Volumeseriesinfo? seriesInfo;

  /// Volume subtitle.
  ///
  /// (In LITE projection.)
  core.String? subtitle;

  /// Volume title.
  ///
  /// (In LITE projection.)
  core.String? title;

  VolumeVolumeInfo();

  VolumeVolumeInfo.fromJson(core.Map _json) {
    if (_json.containsKey('allowAnonLogging')) {
      allowAnonLogging = _json['allowAnonLogging'] as core.bool;
    }
    if (_json.containsKey('authors')) {
      authors = (_json['authors'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('averageRating')) {
      averageRating = (_json['averageRating'] as core.num).toDouble();
    }
    if (_json.containsKey('canonicalVolumeLink')) {
      canonicalVolumeLink = _json['canonicalVolumeLink'] as core.String;
    }
    if (_json.containsKey('categories')) {
      categories = (_json['categories'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('comicsContent')) {
      comicsContent = _json['comicsContent'] as core.bool;
    }
    if (_json.containsKey('contentVersion')) {
      contentVersion = _json['contentVersion'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('dimensions')) {
      dimensions = VolumeVolumeInfoDimensions.fromJson(
          _json['dimensions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('imageLinks')) {
      imageLinks = VolumeVolumeInfoImageLinks.fromJson(
          _json['imageLinks'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('industryIdentifiers')) {
      industryIdentifiers = (_json['industryIdentifiers'] as core.List)
          .map<VolumeVolumeInfoIndustryIdentifiers>((value) =>
              VolumeVolumeInfoIndustryIdentifiers.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('infoLink')) {
      infoLink = _json['infoLink'] as core.String;
    }
    if (_json.containsKey('language')) {
      language = _json['language'] as core.String;
    }
    if (_json.containsKey('mainCategory')) {
      mainCategory = _json['mainCategory'] as core.String;
    }
    if (_json.containsKey('maturityRating')) {
      maturityRating = _json['maturityRating'] as core.String;
    }
    if (_json.containsKey('pageCount')) {
      pageCount = _json['pageCount'] as core.int;
    }
    if (_json.containsKey('panelizationSummary')) {
      panelizationSummary = VolumeVolumeInfoPanelizationSummary.fromJson(
          _json['panelizationSummary'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('previewLink')) {
      previewLink = _json['previewLink'] as core.String;
    }
    if (_json.containsKey('printType')) {
      printType = _json['printType'] as core.String;
    }
    if (_json.containsKey('printedPageCount')) {
      printedPageCount = _json['printedPageCount'] as core.int;
    }
    if (_json.containsKey('publishedDate')) {
      publishedDate = _json['publishedDate'] as core.String;
    }
    if (_json.containsKey('publisher')) {
      publisher = _json['publisher'] as core.String;
    }
    if (_json.containsKey('ratingsCount')) {
      ratingsCount = _json['ratingsCount'] as core.int;
    }
    if (_json.containsKey('readingModes')) {
      readingModes = VolumeVolumeInfoReadingModes.fromJson(
          _json['readingModes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('samplePageCount')) {
      samplePageCount = _json['samplePageCount'] as core.int;
    }
    if (_json.containsKey('seriesInfo')) {
      seriesInfo = Volumeseriesinfo.fromJson(
          _json['seriesInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subtitle')) {
      subtitle = _json['subtitle'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowAnonLogging != null) 'allowAnonLogging': allowAnonLogging!,
        if (authors != null) 'authors': authors!,
        if (averageRating != null) 'averageRating': averageRating!,
        if (canonicalVolumeLink != null)
          'canonicalVolumeLink': canonicalVolumeLink!,
        if (categories != null) 'categories': categories!,
        if (comicsContent != null) 'comicsContent': comicsContent!,
        if (contentVersion != null) 'contentVersion': contentVersion!,
        if (description != null) 'description': description!,
        if (dimensions != null) 'dimensions': dimensions!.toJson(),
        if (imageLinks != null) 'imageLinks': imageLinks!.toJson(),
        if (industryIdentifiers != null)
          'industryIdentifiers':
              industryIdentifiers!.map((value) => value.toJson()).toList(),
        if (infoLink != null) 'infoLink': infoLink!,
        if (language != null) 'language': language!,
        if (mainCategory != null) 'mainCategory': mainCategory!,
        if (maturityRating != null) 'maturityRating': maturityRating!,
        if (pageCount != null) 'pageCount': pageCount!,
        if (panelizationSummary != null)
          'panelizationSummary': panelizationSummary!.toJson(),
        if (previewLink != null) 'previewLink': previewLink!,
        if (printType != null) 'printType': printType!,
        if (printedPageCount != null) 'printedPageCount': printedPageCount!,
        if (publishedDate != null) 'publishedDate': publishedDate!,
        if (publisher != null) 'publisher': publisher!,
        if (ratingsCount != null) 'ratingsCount': ratingsCount!,
        if (readingModes != null) 'readingModes': readingModes!.toJson(),
        if (samplePageCount != null) 'samplePageCount': samplePageCount!,
        if (seriesInfo != null) 'seriesInfo': seriesInfo!.toJson(),
        if (subtitle != null) 'subtitle': subtitle!,
        if (title != null) 'title': title!,
      };
}

class Volume {
  /// Any information about a volume related to reading or obtaining that volume
  /// text.
  ///
  /// This information can depend on country (books may be public domain in one
  /// country but not in another, e.g.).
  VolumeAccessInfo? accessInfo;

  /// Opaque identifier for a specific version of a volume resource.
  ///
  /// (In LITE projection)
  core.String? etag;

  /// Unique identifier for a volume.
  ///
  /// (In LITE projection.)
  core.String? id;

  /// Resource type for a volume.
  ///
  /// (In LITE projection.)
  core.String? kind;

  /// What layers exist in this volume and high level information about them.
  VolumeLayerInfo? layerInfo;

  /// Recommendation related information for this volume.
  VolumeRecommendedInfo? recommendedInfo;

  /// Any information about a volume related to the eBookstore and/or
  /// purchaseability.
  ///
  /// This information can depend on the country where the request originates
  /// from (i.e. books may not be for sale in certain countries).
  VolumeSaleInfo? saleInfo;

  /// Search result information related to this volume.
  VolumeSearchInfo? searchInfo;

  /// URL to this resource.
  ///
  /// (In LITE projection.)
  core.String? selfLink;

  /// User specific information related to this volume.
  ///
  /// (e.g. page this user last read or whether they purchased this book)
  VolumeUserInfo? userInfo;

  /// General volume information.
  VolumeVolumeInfo? volumeInfo;

  Volume();

  Volume.fromJson(core.Map _json) {
    if (_json.containsKey('accessInfo')) {
      accessInfo = VolumeAccessInfo.fromJson(
          _json['accessInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('layerInfo')) {
      layerInfo = VolumeLayerInfo.fromJson(
          _json['layerInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('recommendedInfo')) {
      recommendedInfo = VolumeRecommendedInfo.fromJson(
          _json['recommendedInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('saleInfo')) {
      saleInfo = VolumeSaleInfo.fromJson(
          _json['saleInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('searchInfo')) {
      searchInfo = VolumeSearchInfo.fromJson(
          _json['searchInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('userInfo')) {
      userInfo = VolumeUserInfo.fromJson(
          _json['userInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('volumeInfo')) {
      volumeInfo = VolumeVolumeInfo.fromJson(
          _json['volumeInfo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessInfo != null) 'accessInfo': accessInfo!.toJson(),
        if (etag != null) 'etag': etag!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (layerInfo != null) 'layerInfo': layerInfo!.toJson(),
        if (recommendedInfo != null)
          'recommendedInfo': recommendedInfo!.toJson(),
        if (saleInfo != null) 'saleInfo': saleInfo!.toJson(),
        if (searchInfo != null) 'searchInfo': searchInfo!.toJson(),
        if (selfLink != null) 'selfLink': selfLink!,
        if (userInfo != null) 'userInfo': userInfo!.toJson(),
        if (volumeInfo != null) 'volumeInfo': volumeInfo!.toJson(),
      };
}

class Volume2 {
  /// A list of volumes.
  core.List<Volume>? items;

  /// Resource type.
  core.String? kind;
  core.String? nextPageToken;

  Volume2();

  Volume2.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Volume>((value) =>
              Volume.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The content ranges to identify the selected text.
class VolumeannotationContentRanges {
  /// Range in CFI format for this annotation for version above.
  BooksAnnotationsRange? cfiRange;

  /// Content version applicable to ranges below.
  core.String? contentVersion;

  /// Range in GB image format for this annotation for version above.
  BooksAnnotationsRange? gbImageRange;

  /// Range in GB text format for this annotation for version above.
  BooksAnnotationsRange? gbTextRange;

  VolumeannotationContentRanges();

  VolumeannotationContentRanges.fromJson(core.Map _json) {
    if (_json.containsKey('cfiRange')) {
      cfiRange = BooksAnnotationsRange.fromJson(
          _json['cfiRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentVersion')) {
      contentVersion = _json['contentVersion'] as core.String;
    }
    if (_json.containsKey('gbImageRange')) {
      gbImageRange = BooksAnnotationsRange.fromJson(
          _json['gbImageRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gbTextRange')) {
      gbTextRange = BooksAnnotationsRange.fromJson(
          _json['gbTextRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cfiRange != null) 'cfiRange': cfiRange!.toJson(),
        if (contentVersion != null) 'contentVersion': contentVersion!,
        if (gbImageRange != null) 'gbImageRange': gbImageRange!.toJson(),
        if (gbTextRange != null) 'gbTextRange': gbTextRange!.toJson(),
      };
}

class Volumeannotation {
  /// The annotation data id for this volume annotation.
  core.String? annotationDataId;

  /// Link to get data for this annotation.
  core.String? annotationDataLink;

  /// The type of annotation this is.
  core.String? annotationType;

  /// The content ranges to identify the selected text.
  VolumeannotationContentRanges? contentRanges;

  /// Data for this annotation.
  core.String? data;

  /// Indicates that this annotation is deleted.
  core.bool? deleted;

  /// Unique id of this volume annotation.
  core.String? id;

  /// Resource Type
  core.String? kind;

  /// The Layer this annotation is for.
  core.String? layerId;

  /// Pages the annotation spans.
  core.List<core.String>? pageIds;

  /// Excerpt from the volume.
  core.String? selectedText;

  /// URL to this resource.
  core.String? selfLink;

  /// Timestamp for the last time this anntoation was updated.
  ///
  /// (RFC 3339 UTC date-time format).
  core.String? updated;

  /// The Volume this annotation is for.
  core.String? volumeId;

  Volumeannotation();

  Volumeannotation.fromJson(core.Map _json) {
    if (_json.containsKey('annotationDataId')) {
      annotationDataId = _json['annotationDataId'] as core.String;
    }
    if (_json.containsKey('annotationDataLink')) {
      annotationDataLink = _json['annotationDataLink'] as core.String;
    }
    if (_json.containsKey('annotationType')) {
      annotationType = _json['annotationType'] as core.String;
    }
    if (_json.containsKey('contentRanges')) {
      contentRanges = VolumeannotationContentRanges.fromJson(
          _json['contentRanges'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('data')) {
      data = _json['data'] as core.String;
    }
    if (_json.containsKey('deleted')) {
      deleted = _json['deleted'] as core.bool;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('layerId')) {
      layerId = _json['layerId'] as core.String;
    }
    if (_json.containsKey('pageIds')) {
      pageIds = (_json['pageIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('selectedText')) {
      selectedText = _json['selectedText'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('updated')) {
      updated = _json['updated'] as core.String;
    }
    if (_json.containsKey('volumeId')) {
      volumeId = _json['volumeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationDataId != null) 'annotationDataId': annotationDataId!,
        if (annotationDataLink != null)
          'annotationDataLink': annotationDataLink!,
        if (annotationType != null) 'annotationType': annotationType!,
        if (contentRanges != null) 'contentRanges': contentRanges!.toJson(),
        if (data != null) 'data': data!,
        if (deleted != null) 'deleted': deleted!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (layerId != null) 'layerId': layerId!,
        if (pageIds != null) 'pageIds': pageIds!,
        if (selectedText != null) 'selectedText': selectedText!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (updated != null) 'updated': updated!,
        if (volumeId != null) 'volumeId': volumeId!,
      };
}

class Volumeannotations {
  /// A list of volume annotations.
  core.List<Volumeannotation>? items;

  /// Resource type
  core.String? kind;

  /// Token to pass in for pagination for the next page.
  ///
  /// This will not be present if this request does not have more results.
  core.String? nextPageToken;

  /// The total number of volume annotations found.
  core.int? totalItems;

  /// The version string for all of the volume annotations in this layer (not
  /// just the ones in this response).
  ///
  /// Note: the version string doesn't apply to the annotation data, just the
  /// information in this response (e.g. the location of annotations in the
  /// book).
  core.String? version;

  Volumeannotations();

  Volumeannotations.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Volumeannotation>((value) => Volumeannotation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('totalItems')) {
      totalItems = _json['totalItems'] as core.int;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (totalItems != null) 'totalItems': totalItems!,
        if (version != null) 'version': version!,
      };
}

class Volumes {
  /// A list of volumes.
  core.List<Volume>? items;

  /// Resource type.
  core.String? kind;

  /// Total number of volumes found.
  ///
  /// This might be greater than the number of volumes returned in this response
  /// if results have been paginated.
  core.int? totalItems;

  Volumes();

  Volumes.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Volume>((value) =>
              Volume.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('totalItems')) {
      totalItems = _json['totalItems'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (totalItems != null) 'totalItems': totalItems!,
      };
}

class VolumeseriesinfoVolumeSeriesIssue {
  core.String? issueDisplayNumber;
  core.int? issueOrderNumber;

  VolumeseriesinfoVolumeSeriesIssue();

  VolumeseriesinfoVolumeSeriesIssue.fromJson(core.Map _json) {
    if (_json.containsKey('issueDisplayNumber')) {
      issueDisplayNumber = _json['issueDisplayNumber'] as core.String;
    }
    if (_json.containsKey('issueOrderNumber')) {
      issueOrderNumber = _json['issueOrderNumber'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (issueDisplayNumber != null)
          'issueDisplayNumber': issueDisplayNumber!,
        if (issueOrderNumber != null) 'issueOrderNumber': issueOrderNumber!,
      };
}

class VolumeseriesinfoVolumeSeries {
  /// List of issues.
  ///
  /// Applicable only for Collection Edition and Omnibus.
  core.List<VolumeseriesinfoVolumeSeriesIssue>? issue;

  /// The book order number in the series.
  core.int? orderNumber;

  /// The book type in the context of series.
  ///
  /// Examples - Single Issue, Collection Edition, etc.
  core.String? seriesBookType;

  /// The series id.
  core.String? seriesId;

  VolumeseriesinfoVolumeSeries();

  VolumeseriesinfoVolumeSeries.fromJson(core.Map _json) {
    if (_json.containsKey('issue')) {
      issue = (_json['issue'] as core.List)
          .map<VolumeseriesinfoVolumeSeriesIssue>((value) =>
              VolumeseriesinfoVolumeSeriesIssue.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('orderNumber')) {
      orderNumber = _json['orderNumber'] as core.int;
    }
    if (_json.containsKey('seriesBookType')) {
      seriesBookType = _json['seriesBookType'] as core.String;
    }
    if (_json.containsKey('seriesId')) {
      seriesId = _json['seriesId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (issue != null)
          'issue': issue!.map((value) => value.toJson()).toList(),
        if (orderNumber != null) 'orderNumber': orderNumber!,
        if (seriesBookType != null) 'seriesBookType': seriesBookType!,
        if (seriesId != null) 'seriesId': seriesId!,
      };
}

class Volumeseriesinfo {
  /// The display number string.
  ///
  /// This should be used only for display purposes and the actual sequence
  /// should be inferred from the below orderNumber.
  core.String? bookDisplayNumber;

  /// Resource type.
  core.String? kind;

  /// Short book title in the context of the series.
  core.String? shortSeriesBookTitle;
  core.List<VolumeseriesinfoVolumeSeries>? volumeSeries;

  Volumeseriesinfo();

  Volumeseriesinfo.fromJson(core.Map _json) {
    if (_json.containsKey('bookDisplayNumber')) {
      bookDisplayNumber = _json['bookDisplayNumber'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('shortSeriesBookTitle')) {
      shortSeriesBookTitle = _json['shortSeriesBookTitle'] as core.String;
    }
    if (_json.containsKey('volumeSeries')) {
      volumeSeries = (_json['volumeSeries'] as core.List)
          .map<VolumeseriesinfoVolumeSeries>((value) =>
              VolumeseriesinfoVolumeSeries.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bookDisplayNumber != null) 'bookDisplayNumber': bookDisplayNumber!,
        if (kind != null) 'kind': kind!,
        if (shortSeriesBookTitle != null)
          'shortSeriesBookTitle': shortSeriesBookTitle!,
        if (volumeSeries != null)
          'volumeSeries': volumeSeries!.map((value) => value.toJson()).toList(),
      };
}
