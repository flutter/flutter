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

/// Street View Publish API - v1
///
/// Publishes 360 photos to Google Maps, along with position, orientation, and
/// connectivity metadata. Apps can offer an interface for positioning,
/// connecting, and uploading user-generated Street View images.
///
/// For more information, see
/// <https://developers.google.com/streetview/publish/>
///
/// Create an instance of [StreetViewPublishApi] to access these resources:
///
/// - [PhotoResource]
/// - [PhotosResource]
library streetviewpublish.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Publishes 360 photos to Google Maps, along with position, orientation, and
/// connectivity metadata.
///
/// Apps can offer an interface for positioning, connecting, and uploading
/// user-generated Street View images.
class StreetViewPublishApi {
  /// Publish and manage your 360 photos on Google Street View
  static const streetviewpublishScope =
      'https://www.googleapis.com/auth/streetviewpublish';

  final commons.ApiRequester _requester;

  PhotoResource get photo => PhotoResource(_requester);
  PhotosResource get photos => PhotosResource(_requester);

  StreetViewPublishApi(http.Client client,
      {core.String rootUrl = 'https://streetviewpublish.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class PhotoResource {
  final commons.ApiRequester _requester;

  PhotoResource(commons.ApiRequester client) : _requester = client;

  /// After the client finishes uploading the photo with the returned UploadRef,
  /// CreatePhoto publishes the uploaded Photo to Street View on Google Maps.
  ///
  /// Currently, the only way to set heading, pitch, and roll in CreatePhoto is
  /// through the
  /// [Photo Sphere XMP metadata](https://developers.google.com/streetview/spherical-metadata)
  /// in the photo bytes. CreatePhoto ignores the `pose.heading`, `pose.pitch`,
  /// `pose.roll`, `pose.altitude`, and `pose.level` fields in Pose. This method
  /// returns the following error codes: * google.rpc.Code.INVALID_ARGUMENT if
  /// the request is malformed or if the uploaded photo is not a 360 photo. *
  /// google.rpc.Code.NOT_FOUND if the upload reference does not exist. *
  /// google.rpc.Code.RESOURCE_EXHAUSTED if the account has reached the storage
  /// limit.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Photo].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Photo> create(
    Photo request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/photo';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Photo.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a Photo and its metadata.
  ///
  /// This method returns the following error codes: *
  /// google.rpc.Code.PERMISSION_DENIED if the requesting user did not create
  /// the requested photo. * google.rpc.Code.NOT_FOUND if the photo ID does not
  /// exist.
  ///
  /// Request parameters:
  ///
  /// [photoId] - Required. ID of the Photo.
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
    core.String photoId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/photo/' + commons.escapeVariable('$photoId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the metadata of the specified Photo.
  ///
  /// This method returns the following error codes: *
  /// google.rpc.Code.PERMISSION_DENIED if the requesting user did not create
  /// the requested Photo. * google.rpc.Code.NOT_FOUND if the requested Photo
  /// does not exist. * google.rpc.Code.UNAVAILABLE if the requested Photo is
  /// still being indexed.
  ///
  /// Request parameters:
  ///
  /// [photoId] - Required. ID of the Photo.
  ///
  /// [languageCode] - The BCP-47 language code, such as "en-US" or "sr-Latn".
  /// For more information, see
  /// http://www.unicode.org/reports/tr35/#Unicode_locale_identifier. If
  /// language_code is unspecified, the user's language preference for Google
  /// services is used.
  ///
  /// [view] - Required. Specifies if a download URL for the photo bytes should
  /// be returned in the Photo response.
  /// Possible string values are:
  /// - "BASIC" : Server responses do not include the download URL for the photo
  /// bytes. The default value.
  /// - "INCLUDE_DOWNLOAD_URL" : Server responses include the download URL for
  /// the photo bytes.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Photo].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Photo> get(
    core.String photoId, {
    core.String? languageCode,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/photo/' + commons.escapeVariable('$photoId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Photo.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates an upload session to start uploading photo bytes.
  ///
  /// The method uses the upload URL of the returned UploadRef to upload the
  /// bytes for the Photo. In addition to the photo requirements shown in
  /// https://support.google.com/maps/answer/7012050?ref_topic=6275604, the
  /// photo must meet the following requirements: * Photo Sphere XMP metadata
  /// must be included in the photo metadata. See
  /// https://developers.google.com/streetview/spherical-metadata for the
  /// required fields. * The pixel size of the photo must meet the size
  /// requirements listed in
  /// https://support.google.com/maps/answer/7012050?ref_topic=6275604, and the
  /// photo must be a full 360 horizontally. After the upload completes, the
  /// method uses UploadRef with CreatePhoto to create the Photo object entry.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UploadRef].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UploadRef> startUpload(
    Empty request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/photo:startUpload';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return UploadRef.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the metadata of a Photo, such as pose, place association,
  /// connections, etc.
  ///
  /// Changing the pixels of a photo is not supported. Only the fields specified
  /// in the updateMask field are used. If `updateMask` is not present, the
  /// update applies to all fields. This method returns the following error
  /// codes: * google.rpc.Code.PERMISSION_DENIED if the requesting user did not
  /// create the requested photo. * google.rpc.Code.INVALID_ARGUMENT if the
  /// request is malformed. * google.rpc.Code.NOT_FOUND if the requested photo
  /// does not exist. * google.rpc.Code.UNAVAILABLE if the requested Photo is
  /// still being indexed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [id] - Required. A unique identifier for a photo.
  ///
  /// [updateMask] - Required. Mask that identifies fields on the photo metadata
  /// to update. If not present, the old Photo metadata is entirely replaced
  /// with the new Photo metadata in this request. The update fails if invalid
  /// fields are specified. Multiple fields can be specified in a
  /// comma-delimited list. The following fields are valid: * `pose.heading` *
  /// `pose.latLngPair` * `pose.pitch` * `pose.roll` * `pose.level` *
  /// `pose.altitude` * `connections` * `places` *Note:* When updateMask
  /// contains repeated fields, the entire set of repeated values get replaced
  /// with the new contents. For example, if updateMask contains `connections`
  /// and `UpdatePhotoRequest.photo.connections` is empty, all connections are
  /// removed.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Photo].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Photo> update(
    Photo request,
    core.String id, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/photo/' + commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Photo.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class PhotosResource {
  final commons.ApiRequester _requester;

  PhotosResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a list of Photos and their metadata.
  ///
  /// Note that if BatchDeletePhotos fails, either critical fields are missing
  /// or there is an authentication error. Even if BatchDeletePhotos succeeds,
  /// individual photos in the batch may have failures. These failures are
  /// specified in each PhotoResponse.status in
  /// BatchDeletePhotosResponse.results. See DeletePhoto for specific failures
  /// that can occur per photo.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchDeletePhotosResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchDeletePhotosResponse> batchDelete(
    BatchDeletePhotosRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/photos:batchDelete';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BatchDeletePhotosResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the metadata of the specified Photo batch.
  ///
  /// Note that if BatchGetPhotos fails, either critical fields are missing or
  /// there is an authentication error. Even if BatchGetPhotos succeeds,
  /// individual photos in the batch may have failures. These failures are
  /// specified in each PhotoResponse.status in BatchGetPhotosResponse.results.
  /// See GetPhoto for specific failures that can occur per photo.
  ///
  /// Request parameters:
  ///
  /// [languageCode] - The BCP-47 language code, such as "en-US" or "sr-Latn".
  /// For more information, see
  /// http://www.unicode.org/reports/tr35/#Unicode_locale_identifier. If
  /// language_code is unspecified, the user's language preference for Google
  /// services is used.
  ///
  /// [photoIds] - Required. IDs of the Photos. For HTTP GET requests, the URL
  /// query parameter should be `photoIds=&photoIds=&...`.
  ///
  /// [view] - Required. Specifies if a download URL for the photo bytes should
  /// be returned in the Photo response.
  /// Possible string values are:
  /// - "BASIC" : Server responses do not include the download URL for the photo
  /// bytes. The default value.
  /// - "INCLUDE_DOWNLOAD_URL" : Server responses include the download URL for
  /// the photo bytes.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchGetPhotosResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchGetPhotosResponse> batchGet({
    core.String? languageCode,
    core.List<core.String>? photoIds,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if (photoIds != null) 'photoIds': photoIds,
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/photos:batchGet';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BatchGetPhotosResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the metadata of Photos, such as pose, place association,
  /// connections, etc.
  ///
  /// Changing the pixels of photos is not supported. Note that if
  /// BatchUpdatePhotos fails, either critical fields are missing or there is an
  /// authentication error. Even if BatchUpdatePhotos succeeds, individual
  /// photos in the batch may have failures. These failures are specified in
  /// each PhotoResponse.status in BatchUpdatePhotosResponse.results. See
  /// UpdatePhoto for specific failures that can occur per photo. Only the
  /// fields specified in updateMask field are used. If `updateMask` is not
  /// present, the update applies to all fields. The number of
  /// UpdatePhotoRequest messages in a BatchUpdatePhotosRequest must not exceed
  /// 20. *Note:* To update Pose.altitude, Pose.latLngPair has to be filled as
  /// well. Otherwise, the request will fail.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchUpdatePhotosResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchUpdatePhotosResponse> batchUpdate(
    BatchUpdatePhotosRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/photos:batchUpdate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BatchUpdatePhotosResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the Photos that belong to the user.
  ///
  /// *Note:* Recently created photos that are still being indexed are not
  /// returned in the response.
  ///
  /// Request parameters:
  ///
  /// [filter] - Required. The filter expression. For example:
  /// `placeId=ChIJj61dQgK6j4AR4GeTYWZsKWw`. The only filter supported at the
  /// moment is `placeId`.
  ///
  /// [languageCode] - The BCP-47 language code, such as "en-US" or "sr-Latn".
  /// For more information, see
  /// http://www.unicode.org/reports/tr35/#Unicode_locale_identifier. If
  /// language_code is unspecified, the user's language preference for Google
  /// services is used.
  ///
  /// [pageSize] - The maximum number of photos to return. `pageSize` must be
  /// non-negative. If `pageSize` is zero or is not provided, the default page
  /// size of 100 is used. The number of photos returned in the response may be
  /// less than `pageSize` if the number of photos that belong to the user is
  /// less than `pageSize`.
  ///
  /// [pageToken] - The nextPageToken value returned from a previous ListPhotos
  /// request, if any.
  ///
  /// [view] - Required. Specifies if a download URL for the photos bytes should
  /// be returned in the Photos response.
  /// Possible string values are:
  /// - "BASIC" : Server responses do not include the download URL for the photo
  /// bytes. The default value.
  /// - "INCLUDE_DOWNLOAD_URL" : Server responses include the download URL for
  /// the photo bytes.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListPhotosResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListPhotosResponse> list({
    core.String? filter,
    core.String? languageCode,
    core.int? pageSize,
    core.String? pageToken,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (languageCode != null) 'languageCode': [languageCode],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/photos';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListPhotosResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Request to delete multiple Photos.
class BatchDeletePhotosRequest {
  /// IDs of the Photos.
  ///
  /// HTTP GET requests require the following syntax for the URL query
  /// parameter: `photoIds=&photoIds=&...`.
  ///
  /// Required.
  core.List<core.String>? photoIds;

  BatchDeletePhotosRequest();

  BatchDeletePhotosRequest.fromJson(core.Map _json) {
    if (_json.containsKey('photoIds')) {
      photoIds = (_json['photoIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (photoIds != null) 'photoIds': photoIds!,
      };
}

/// Response to batch delete of one or more Photos.
class BatchDeletePhotosResponse {
  /// The status for the operation to delete a single Photo in the batch
  /// request.
  core.List<Status>? status;

  BatchDeletePhotosResponse();

  BatchDeletePhotosResponse.fromJson(core.Map _json) {
    if (_json.containsKey('status')) {
      status = (_json['status'] as core.List)
          .map<Status>((value) =>
              Status.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (status != null)
          'status': status!.map((value) => value.toJson()).toList(),
      };
}

/// Response to batch get of Photos.
class BatchGetPhotosResponse {
  /// List of results for each individual Photo requested, in the same order as
  /// the requests in BatchGetPhotos.
  core.List<PhotoResponse>? results;

  BatchGetPhotosResponse();

  BatchGetPhotosResponse.fromJson(core.Map _json) {
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.List)
          .map<PhotoResponse>((value) => PhotoResponse.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (results != null)
          'results': results!.map((value) => value.toJson()).toList(),
      };
}

/// Request to update the metadata of photos.
///
/// Updating the pixels of photos is not supported.
class BatchUpdatePhotosRequest {
  /// List of UpdatePhotoRequests.
  ///
  /// Required.
  core.List<UpdatePhotoRequest>? updatePhotoRequests;

  BatchUpdatePhotosRequest();

  BatchUpdatePhotosRequest.fromJson(core.Map _json) {
    if (_json.containsKey('updatePhotoRequests')) {
      updatePhotoRequests = (_json['updatePhotoRequests'] as core.List)
          .map<UpdatePhotoRequest>((value) => UpdatePhotoRequest.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (updatePhotoRequests != null)
          'updatePhotoRequests':
              updatePhotoRequests!.map((value) => value.toJson()).toList(),
      };
}

/// Response to batch update of metadata of one or more Photos.
class BatchUpdatePhotosResponse {
  /// List of results for each individual Photo updated, in the same order as
  /// the request.
  core.List<PhotoResponse>? results;

  BatchUpdatePhotosResponse();

  BatchUpdatePhotosResponse.fromJson(core.Map _json) {
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.List)
          .map<PhotoResponse>((value) => PhotoResponse.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (results != null)
          'results': results!.map((value) => value.toJson()).toList(),
      };
}

/// A connection is the link from a source photo to a destination photo.
class Connection {
  /// The destination of the connection from the containing photo to another
  /// photo.
  ///
  /// Required.
  PhotoId? target;

  Connection();

  Connection.fromJson(core.Map _json) {
    if (_json.containsKey('target')) {
      target = PhotoId.fromJson(
          _json['target'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (target != null) 'target': target!.toJson(),
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

/// An object that represents a latitude/longitude pair.
///
/// This is expressed as a pair of doubles to represent degrees latitude and
/// degrees longitude. Unless specified otherwise, this object must conform to
/// the WGS84 standard. Values must be within normalized ranges.
class LatLng {
  /// The latitude in degrees.
  ///
  /// It must be in the range \[-90.0, +90.0\].
  core.double? latitude;

  /// The longitude in degrees.
  ///
  /// It must be in the range \[-180.0, +180.0\].
  core.double? longitude;

  LatLng();

  LatLng.fromJson(core.Map _json) {
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

/// Level information containing level number and its corresponding name.
class Level {
  /// A name assigned to this Level, restricted to 3 characters.
  ///
  /// Consider how the elevator buttons would be labeled for this level if there
  /// was an elevator.
  ///
  /// Required.
  core.String? name;

  /// Floor number, used for ordering.
  ///
  /// 0 indicates the ground level, 1 indicates the first level above ground
  /// level, -1 indicates the first level under ground level. Non-integer values
  /// are OK.
  core.double? number;

  Level();

  Level.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('number')) {
      number = (_json['number'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (number != null) 'number': number!,
      };
}

/// Response to list all photos that belong to a user.
class ListPhotosResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// List of photos.
  ///
  /// The pageSize field in the request determines the number of items returned.
  core.List<Photo>? photos;

  ListPhotosResponse();

  ListPhotosResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('photos')) {
      photos = (_json['photos'] as core.List)
          .map<Photo>((value) =>
              Photo.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (photos != null)
          'photos': photos!.map((value) => value.toJson()).toList(),
      };
}

/// This resource represents a long-running operation that is the result of a
/// network API call.
class Operation {
  /// If the value is `false`, it means the operation is still in progress.
  ///
  /// If `true`, the operation is completed, and either `error` or `response` is
  /// available.
  core.bool? done;

  /// The error result of the operation in case of failure or cancellation.
  Status? error;

  /// Service-specific metadata associated with the operation.
  ///
  /// It typically contains progress information and common metadata such as
  /// create time. Some services might not provide such metadata. Any method
  /// that returns a long-running operation should document the metadata type,
  /// if any.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  /// The server-assigned name, which is only unique within the same service
  /// that originally returns it.
  ///
  /// If you use the default HTTP mapping, the `name` should be a resource name
  /// ending with `operations/{unique_id}`.
  core.String? name;

  /// The normal response of the operation in case of success.
  ///
  /// If the original method returns no data on success, such as `Delete`, the
  /// response is `google.protobuf.Empty`. If the original method is standard
  /// `Get`/`Create`/`Update`, the response should be the resource. For other
  /// methods, the response should have the type `XxxResponse`, where `Xxx` is
  /// the original method name. For example, if the original method name is
  /// `TakeSnapshot()`, the inferred response type is `TakeSnapshotResponse`.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? response;

  Operation();

  Operation.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('error')) {
      error = Status.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('response')) {
      response = (_json['response'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (done != null) 'done': done!,
        if (error != null) 'error': error!.toJson(),
        if (metadata != null) 'metadata': metadata!,
        if (name != null) 'name': name!,
        if (response != null) 'response': response!,
      };
}

/// Photo is used to store 360 photos along with photo metadata.
class Photo {
  /// Absolute time when the photo was captured.
  ///
  /// When the photo has no exif timestamp, this is used to set a timestamp in
  /// the photo metadata.
  core.String? captureTime;

  /// Connections to other photos.
  ///
  /// A connection represents the link from this photo to another photo.
  core.List<Connection>? connections;

  /// The download URL for the photo bytes.
  ///
  /// This field is set only when GetPhotoRequest.view is set to
  /// PhotoView.INCLUDE_DOWNLOAD_URL.
  ///
  /// Output only.
  core.String? downloadUrl;

  /// Status in Google Maps, whether this photo was published or rejected.
  ///
  /// Not currently populated.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "UNSPECIFIED_MAPS_PUBLISH_STATUS" : The status of the photo is unknown.
  /// - "PUBLISHED" : The photo is published to the public through Google Maps.
  /// - "REJECTED_UNKNOWN" : The photo has been rejected for an unknown reason.
  core.String? mapsPublishStatus;

  /// Required when updating a photo.
  ///
  /// Output only when creating a photo. Identifier for the photo, which is
  /// unique among all photos in Google.
  PhotoId? photoId;

  /// Places where this photo belongs.
  core.List<Place>? places;

  /// Pose of the photo.
  Pose? pose;

  /// The share link for the photo.
  ///
  /// Output only.
  core.String? shareLink;

  /// The thumbnail URL for showing a preview of the given photo.
  ///
  /// Output only.
  core.String? thumbnailUrl;

  /// Status of rights transfer on this photo.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "TRANSFER_STATUS_UNKNOWN" : The status of this transfer is unspecified.
  /// - "NEVER_TRANSFERRED" : This photo has never been in a transfer.
  /// - "PENDING" : This photo transfer has been initiated, but the receiver has
  /// not yet responded.
  /// - "COMPLETED" : The photo transfer has been completed, and this photo has
  /// been transferred to the recipient.
  /// - "REJECTED" : The recipient rejected this photo transfer.
  /// - "EXPIRED" : The photo transfer expired before the recipient took any
  /// action.
  /// - "CANCELLED" : The sender cancelled this photo transfer.
  /// - "RECEIVED_VIA_TRANSFER" : The recipient owns this photo due to a rights
  /// transfer.
  core.String? transferStatus;

  /// Required when creating a photo.
  ///
  /// Input only. The resource URL where the photo bytes are uploaded to.
  UploadRef? uploadReference;

  /// View count of the photo.
  ///
  /// Output only.
  core.String? viewCount;

  Photo();

  Photo.fromJson(core.Map _json) {
    if (_json.containsKey('captureTime')) {
      captureTime = _json['captureTime'] as core.String;
    }
    if (_json.containsKey('connections')) {
      connections = (_json['connections'] as core.List)
          .map<Connection>((value) =>
              Connection.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('downloadUrl')) {
      downloadUrl = _json['downloadUrl'] as core.String;
    }
    if (_json.containsKey('mapsPublishStatus')) {
      mapsPublishStatus = _json['mapsPublishStatus'] as core.String;
    }
    if (_json.containsKey('photoId')) {
      photoId = PhotoId.fromJson(
          _json['photoId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('places')) {
      places = (_json['places'] as core.List)
          .map<Place>((value) =>
              Place.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('pose')) {
      pose =
          Pose.fromJson(_json['pose'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shareLink')) {
      shareLink = _json['shareLink'] as core.String;
    }
    if (_json.containsKey('thumbnailUrl')) {
      thumbnailUrl = _json['thumbnailUrl'] as core.String;
    }
    if (_json.containsKey('transferStatus')) {
      transferStatus = _json['transferStatus'] as core.String;
    }
    if (_json.containsKey('uploadReference')) {
      uploadReference = UploadRef.fromJson(
          _json['uploadReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('viewCount')) {
      viewCount = _json['viewCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (captureTime != null) 'captureTime': captureTime!,
        if (connections != null)
          'connections': connections!.map((value) => value.toJson()).toList(),
        if (downloadUrl != null) 'downloadUrl': downloadUrl!,
        if (mapsPublishStatus != null) 'mapsPublishStatus': mapsPublishStatus!,
        if (photoId != null) 'photoId': photoId!.toJson(),
        if (places != null)
          'places': places!.map((value) => value.toJson()).toList(),
        if (pose != null) 'pose': pose!.toJson(),
        if (shareLink != null) 'shareLink': shareLink!,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl!,
        if (transferStatus != null) 'transferStatus': transferStatus!,
        if (uploadReference != null)
          'uploadReference': uploadReference!.toJson(),
        if (viewCount != null) 'viewCount': viewCount!,
      };
}

/// Identifier for a Photo.
class PhotoId {
  /// A unique identifier for a photo.
  ///
  /// Required.
  core.String? id;

  PhotoId();

  PhotoId.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
      };
}

/// Response payload for a single Photo in batch operations including
/// BatchGetPhotos and BatchUpdatePhotos.
class PhotoResponse {
  /// The Photo resource, if the request was successful.
  Photo? photo;

  /// The status for the operation to get or update a single photo in the batch
  /// request.
  Status? status;

  PhotoResponse();

  PhotoResponse.fromJson(core.Map _json) {
    if (_json.containsKey('photo')) {
      photo =
          Photo.fromJson(_json['photo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = Status.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (photo != null) 'photo': photo!.toJson(),
        if (status != null) 'status': status!.toJson(),
      };
}

/// Place metadata for an entity.
class Place {
  /// Output-only.
  ///
  /// The language_code that the name is localized with. This should be the
  /// language_code specified in the request, but may be a fallback.
  core.String? languageCode;

  /// Output-only.
  ///
  /// The name of the place, localized to the language_code.
  core.String? name;

  /// Place identifier, as described in
  /// https://developers.google.com/places/place-id.
  core.String? placeId;

  Place();

  Place.fromJson(core.Map _json) {
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('placeId')) {
      placeId = _json['placeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (languageCode != null) 'languageCode': languageCode!,
        if (name != null) 'name': name!,
        if (placeId != null) 'placeId': placeId!,
      };
}

/// Raw pose measurement for an entity.
class Pose {
  /// The estimated horizontal accuracy of this pose in meters with 68%
  /// confidence (one standard deviation).
  ///
  /// For example, on Android, this value is available from this method:
  /// https://developer.android.com/reference/android/location/Location#getAccuracy().
  /// Other platforms have different methods of obtaining similar accuracy
  /// estimations.
  core.double? accuracyMeters;

  /// Altitude of the pose in meters above WGS84 ellipsoid.
  ///
  /// NaN indicates an unmeasured quantity.
  core.double? altitude;

  /// Compass heading, measured at the center of the photo in degrees clockwise
  /// from North.
  ///
  /// Value must be >=0 and <360. NaN indicates an unmeasured quantity.
  core.double? heading;

  /// Latitude and longitude pair of the pose, as explained here:
  /// https://cloud.google.com/datastore/docs/reference/rest/Shared.Types/LatLng
  /// When creating a Photo, if the latitude and longitude pair are not
  /// provided, the geolocation from the exif header is used.
  ///
  /// A latitude and longitude pair not provided in the photo or exif header
  /// causes the photo process to fail.
  LatLng? latLngPair;

  /// Level (the floor in a building) used to configure vertical navigation.
  Level? level;

  /// Pitch, measured at the center of the photo in degrees.
  ///
  /// Value must be >=-90 and <= 90. A value of -90 means looking directly down,
  /// and a value of 90 means looking directly up. NaN indicates an unmeasured
  /// quantity.
  core.double? pitch;

  /// Roll, measured in degrees.
  ///
  /// Value must be >= 0 and <360. A value of 0 means level with the horizon.
  /// NaN indicates an unmeasured quantity.
  core.double? roll;

  Pose();

  Pose.fromJson(core.Map _json) {
    if (_json.containsKey('accuracyMeters')) {
      accuracyMeters = (_json['accuracyMeters'] as core.num).toDouble();
    }
    if (_json.containsKey('altitude')) {
      altitude = (_json['altitude'] as core.num).toDouble();
    }
    if (_json.containsKey('heading')) {
      heading = (_json['heading'] as core.num).toDouble();
    }
    if (_json.containsKey('latLngPair')) {
      latLngPair = LatLng.fromJson(
          _json['latLngPair'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('level')) {
      level =
          Level.fromJson(_json['level'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pitch')) {
      pitch = (_json['pitch'] as core.num).toDouble();
    }
    if (_json.containsKey('roll')) {
      roll = (_json['roll'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters!,
        if (altitude != null) 'altitude': altitude!,
        if (heading != null) 'heading': heading!,
        if (latLngPair != null) 'latLngPair': latLngPair!.toJson(),
        if (level != null) 'level': level!.toJson(),
        if (pitch != null) 'pitch': pitch!,
        if (roll != null) 'roll': roll!,
      };
}

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class Status {
  /// The status code, which should be an enum value of google.rpc.Code.
  core.int? code;

  /// A list of messages that carry the error details.
  ///
  /// There is a common set of message types for APIs to use.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? details;

  /// A developer-facing error message, which should be in English.
  ///
  /// Any user-facing error message should be localized and sent in the
  /// google.rpc.Status.details field, or localized by the client.
  core.String? message;

  Status();

  Status.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.int;
    }
    if (_json.containsKey('details')) {
      details = (_json['details'] as core.List)
          .map<core.Map<core.String, core.Object>>(
              (value) => (value as core.Map<core.String, core.dynamic>).map(
                    (key, item) => core.MapEntry(
                      key,
                      item as core.Object,
                    ),
                  ))
          .toList();
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (details != null) 'details': details!,
        if (message != null) 'message': message!,
      };
}

/// Request to update the metadata of a Photo.
///
/// Updating the pixels of a photo is not supported.
class UpdatePhotoRequest {
  /// Photo object containing the new metadata.
  ///
  /// Required.
  Photo? photo;

  /// Mask that identifies fields on the photo metadata to update.
  ///
  /// If not present, the old Photo metadata is entirely replaced with the new
  /// Photo metadata in this request. The update fails if invalid fields are
  /// specified. Multiple fields can be specified in a comma-delimited list. The
  /// following fields are valid: * `pose.heading` * `pose.latLngPair` *
  /// `pose.pitch` * `pose.roll` * `pose.level` * `pose.altitude` *
  /// `connections` * `places` *Note:* When updateMask contains repeated fields,
  /// the entire set of repeated values get replaced with the new contents. For
  /// example, if updateMask contains `connections` and
  /// `UpdatePhotoRequest.photo.connections` is empty, all connections are
  /// removed.
  ///
  /// Required.
  core.String? updateMask;

  UpdatePhotoRequest();

  UpdatePhotoRequest.fromJson(core.Map _json) {
    if (_json.containsKey('photo')) {
      photo =
          Photo.fromJson(_json['photo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateMask')) {
      updateMask = _json['updateMask'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (photo != null) 'photo': photo!.toJson(),
        if (updateMask != null) 'updateMask': updateMask!,
      };
}

/// Upload reference for media files.
class UploadRef {
  /// An upload reference should be unique for each user.
  ///
  /// It follows the form:
  /// "https://streetviewpublish.googleapis.com/media/user/{account_id}/photo/{upload_reference}"
  core.String? uploadUrl;

  UploadRef();

  UploadRef.fromJson(core.Map _json) {
    if (_json.containsKey('uploadUrl')) {
      uploadUrl = _json['uploadUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (uploadUrl != null) 'uploadUrl': uploadUrl!,
      };
}
