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

/// Cloud Storage JSON API - v1
///
/// Stores and retrieves potentially large, immutable data objects.
///
/// For more information, see
/// <https://developers.google.com/storage/docs/json_api/>
///
/// Create an instance of [StorageApi] to access these resources:
///
/// - [BucketAccessControlsResource]
/// - [BucketsResource]
/// - [ChannelsResource]
/// - [DefaultObjectAccessControlsResource]
/// - [NotificationsResource]
/// - [ObjectAccessControlsResource]
/// - [ObjectsResource]
/// - [ProjectsResource]
///   - [ProjectsHmacKeysResource]
///   - [ProjectsServiceAccountResource]
library storage.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show
        ApiRequestError,
        DetailedApiRequestError,
        Media,
        UploadOptions,
        ResumableUploadOptions,
        DownloadOptions,
        PartialDownloadOptions,
        ByteRange;

/// Stores and retrieves potentially large, immutable data objects.
class StorageApi {
  /// View and manage your data across Google Cloud Platform services
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View your data across Google Cloud Platform services
  static const cloudPlatformReadOnlyScope =
      'https://www.googleapis.com/auth/cloud-platform.read-only';

  /// Manage your data and permissions in Google Cloud Storage
  static const devstorageFullControlScope =
      'https://www.googleapis.com/auth/devstorage.full_control';

  /// View your data in Google Cloud Storage
  static const devstorageReadOnlyScope =
      'https://www.googleapis.com/auth/devstorage.read_only';

  /// Manage your data in Google Cloud Storage
  static const devstorageReadWriteScope =
      'https://www.googleapis.com/auth/devstorage.read_write';

  final commons.ApiRequester _requester;

  BucketAccessControlsResource get bucketAccessControls =>
      BucketAccessControlsResource(_requester);
  BucketsResource get buckets => BucketsResource(_requester);
  ChannelsResource get channels => ChannelsResource(_requester);
  DefaultObjectAccessControlsResource get defaultObjectAccessControls =>
      DefaultObjectAccessControlsResource(_requester);
  NotificationsResource get notifications => NotificationsResource(_requester);
  ObjectAccessControlsResource get objectAccessControls =>
      ObjectAccessControlsResource(_requester);
  ObjectsResource get objects => ObjectsResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);

  StorageApi(http.Client client,
      {core.String rootUrl = 'https://storage.googleapis.com/',
      core.String servicePath = 'storage/v1/'})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class BucketAccessControlsResource {
  final commons.ApiRequester _requester;

  BucketAccessControlsResource(commons.ApiRequester client)
      : _requester = client;

  /// Permanently deletes the ACL entry for the specified entity on the
  /// specified bucket.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [entity] - The entity holding the permission. Can be user-userId,
  /// user-emailAddress, group-groupId, group-emailAddress, allUsers, or
  /// allAuthenticatedUsers.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String bucket,
    core.String entity, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/acl/' +
        commons.escapeVariable('$entity');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Returns the ACL entry for the specified entity on the specified bucket.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [entity] - The entity holding the permission. Can be user-userId,
  /// user-emailAddress, group-groupId, group-emailAddress, allUsers, or
  /// allAuthenticatedUsers.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BucketAccessControl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BucketAccessControl> get(
    core.String bucket,
    core.String entity, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/acl/' +
        commons.escapeVariable('$entity');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BucketAccessControl.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new ACL entry on the specified bucket.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BucketAccessControl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BucketAccessControl> insert(
    BucketAccessControl request,
    core.String bucket, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' + commons.escapeVariable('$bucket') + '/acl';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BucketAccessControl.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves ACL entries on the specified bucket.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BucketAccessControls].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BucketAccessControls> list(
    core.String bucket, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' + commons.escapeVariable('$bucket') + '/acl';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BucketAccessControls.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Patches an ACL entry on the specified bucket.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [entity] - The entity holding the permission. Can be user-userId,
  /// user-emailAddress, group-groupId, group-emailAddress, allUsers, or
  /// allAuthenticatedUsers.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BucketAccessControl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BucketAccessControl> patch(
    BucketAccessControl request,
    core.String bucket,
    core.String entity, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/acl/' +
        commons.escapeVariable('$entity');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return BucketAccessControl.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an ACL entry on the specified bucket.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [entity] - The entity holding the permission. Can be user-userId,
  /// user-emailAddress, group-groupId, group-emailAddress, allUsers, or
  /// allAuthenticatedUsers.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BucketAccessControl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BucketAccessControl> update(
    BucketAccessControl request,
    core.String bucket,
    core.String entity, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/acl/' +
        commons.escapeVariable('$entity');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return BucketAccessControl.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BucketsResource {
  final commons.ApiRequester _requester;

  BucketsResource(commons.ApiRequester client) : _requester = client;

  /// Permanently deletes an empty bucket.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [ifMetagenerationMatch] - If set, only deletes the bucket if its
  /// metageneration matches this value.
  ///
  /// [ifMetagenerationNotMatch] - If set, only deletes the bucket if its
  /// metageneration does not match this value.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String bucket, {
    core.String? ifMetagenerationMatch,
    core.String? ifMetagenerationNotMatch,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (ifMetagenerationNotMatch != null)
        'ifMetagenerationNotMatch': [ifMetagenerationNotMatch],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' + commons.escapeVariable('$bucket');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Returns metadata for the specified bucket.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [ifMetagenerationMatch] - Makes the return of the bucket metadata
  /// conditional on whether the bucket's current metageneration matches the
  /// given value.
  ///
  /// [ifMetagenerationNotMatch] - Makes the return of the bucket metadata
  /// conditional on whether the bucket's current metageneration does not match
  /// the given value.
  ///
  /// [projection] - Set of properties to return. Defaults to noAcl.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit owner, acl and defaultObjectAcl properties.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Bucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Bucket> get(
    core.String bucket, {
    core.String? ifMetagenerationMatch,
    core.String? ifMetagenerationNotMatch,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (ifMetagenerationNotMatch != null)
        'ifMetagenerationNotMatch': [ifMetagenerationNotMatch],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' + commons.escapeVariable('$bucket');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Bucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns an IAM policy for the specified bucket.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [optionsRequestedPolicyVersion] - The IAM policy format version to be
  /// returned. If the optionsRequestedPolicyVersion is for an older version
  /// that doesn't support part of the requested IAM policy, the request fails.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> getIamPolicy(
    core.String bucket, {
    core.int? optionsRequestedPolicyVersion,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (optionsRequestedPolicyVersion != null)
        'optionsRequestedPolicyVersion': ['${optionsRequestedPolicyVersion}'],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' + commons.escapeVariable('$bucket') + '/iam';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new bucket.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [project] - A valid API project identifier.
  ///
  /// [predefinedAcl] - Apply a predefined set of access controls to this
  /// bucket.
  /// Possible string values are:
  /// - "authenticatedRead" : Project team owners get OWNER access, and
  /// allAuthenticatedUsers get READER access.
  /// - "private" : Project team owners get OWNER access.
  /// - "projectPrivate" : Project team members get access according to their
  /// roles.
  /// - "publicRead" : Project team owners get OWNER access, and allUsers get
  /// READER access.
  /// - "publicReadWrite" : Project team owners get OWNER access, and allUsers
  /// get WRITER access.
  ///
  /// [predefinedDefaultObjectAcl] - Apply a predefined set of default object
  /// access controls to this bucket.
  /// Possible string values are:
  /// - "authenticatedRead" : Object owner gets OWNER access, and
  /// allAuthenticatedUsers get READER access.
  /// - "bucketOwnerFullControl" : Object owner gets OWNER access, and project
  /// team owners get OWNER access.
  /// - "bucketOwnerRead" : Object owner gets OWNER access, and project team
  /// owners get READER access.
  /// - "private" : Object owner gets OWNER access.
  /// - "projectPrivate" : Object owner gets OWNER access, and project team
  /// members get access according to their roles.
  /// - "publicRead" : Object owner gets OWNER access, and allUsers get READER
  /// access.
  ///
  /// [projection] - Set of properties to return. Defaults to noAcl, unless the
  /// bucket resource specifies acl or defaultObjectAcl properties, when it
  /// defaults to full.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit owner, acl and defaultObjectAcl properties.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Bucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Bucket> insert(
    Bucket request,
    core.String project, {
    core.String? predefinedAcl,
    core.String? predefinedDefaultObjectAcl,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'project': [project],
      if (predefinedAcl != null) 'predefinedAcl': [predefinedAcl],
      if (predefinedDefaultObjectAcl != null)
        'predefinedDefaultObjectAcl': [predefinedDefaultObjectAcl],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'b';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Bucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of buckets for a given project.
  ///
  /// Request parameters:
  ///
  /// [project] - A valid API project identifier.
  ///
  /// [maxResults] - Maximum number of buckets to return in a single response.
  /// The service will use this parameter or 1,000 items, whichever is smaller.
  ///
  /// [pageToken] - A previously-returned page token representing part of the
  /// larger set of results to view.
  ///
  /// [prefix] - Filter results to buckets whose names begin with this prefix.
  ///
  /// [projection] - Set of properties to return. Defaults to noAcl.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit owner, acl and defaultObjectAcl properties.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Buckets].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Buckets> list(
    core.String project, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? prefix,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'project': [project],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (prefix != null) 'prefix': [prefix],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'b';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Buckets.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Locks retention policy on a bucket.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [ifMetagenerationMatch] - Makes the operation conditional on whether
  /// bucket's current metageneration matches the given value.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Bucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Bucket> lockRetentionPolicy(
    core.String bucket,
    core.String ifMetagenerationMatch, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'b/' + commons.escapeVariable('$bucket') + '/lockRetentionPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Bucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Patches a bucket.
  ///
  /// Changes to the bucket will be readable immediately after writing, but
  /// configuration changes may take time to propagate.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [ifMetagenerationMatch] - Makes the return of the bucket metadata
  /// conditional on whether the bucket's current metageneration matches the
  /// given value.
  ///
  /// [ifMetagenerationNotMatch] - Makes the return of the bucket metadata
  /// conditional on whether the bucket's current metageneration does not match
  /// the given value.
  ///
  /// [predefinedAcl] - Apply a predefined set of access controls to this
  /// bucket.
  /// Possible string values are:
  /// - "authenticatedRead" : Project team owners get OWNER access, and
  /// allAuthenticatedUsers get READER access.
  /// - "private" : Project team owners get OWNER access.
  /// - "projectPrivate" : Project team members get access according to their
  /// roles.
  /// - "publicRead" : Project team owners get OWNER access, and allUsers get
  /// READER access.
  /// - "publicReadWrite" : Project team owners get OWNER access, and allUsers
  /// get WRITER access.
  ///
  /// [predefinedDefaultObjectAcl] - Apply a predefined set of default object
  /// access controls to this bucket.
  /// Possible string values are:
  /// - "authenticatedRead" : Object owner gets OWNER access, and
  /// allAuthenticatedUsers get READER access.
  /// - "bucketOwnerFullControl" : Object owner gets OWNER access, and project
  /// team owners get OWNER access.
  /// - "bucketOwnerRead" : Object owner gets OWNER access, and project team
  /// owners get READER access.
  /// - "private" : Object owner gets OWNER access.
  /// - "projectPrivate" : Object owner gets OWNER access, and project team
  /// members get access according to their roles.
  /// - "publicRead" : Object owner gets OWNER access, and allUsers get READER
  /// access.
  ///
  /// [projection] - Set of properties to return. Defaults to full.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit owner, acl and defaultObjectAcl properties.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Bucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Bucket> patch(
    Bucket request,
    core.String bucket, {
    core.String? ifMetagenerationMatch,
    core.String? ifMetagenerationNotMatch,
    core.String? predefinedAcl,
    core.String? predefinedDefaultObjectAcl,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (ifMetagenerationNotMatch != null)
        'ifMetagenerationNotMatch': [ifMetagenerationNotMatch],
      if (predefinedAcl != null) 'predefinedAcl': [predefinedAcl],
      if (predefinedDefaultObjectAcl != null)
        'predefinedDefaultObjectAcl': [predefinedDefaultObjectAcl],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' + commons.escapeVariable('$bucket');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Bucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an IAM policy for the specified bucket.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> setIamPolicy(
    Policy request,
    core.String bucket, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' + commons.escapeVariable('$bucket') + '/iam';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Tests a set of permissions on the given bucket to see which, if any, are
  /// held by the caller.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [permissions] - Permissions to test.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TestIamPermissionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TestIamPermissionsResponse> testIamPermissions(
    core.String bucket,
    core.List<core.String> permissions, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    if (permissions.isEmpty) {
      throw core.ArgumentError('Parameter permissions cannot be empty.');
    }
    final _queryParams = <core.String, core.List<core.String>>{
      'permissions': permissions,
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'b/' + commons.escapeVariable('$bucket') + '/iam/testPermissions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TestIamPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a bucket.
  ///
  /// Changes to the bucket will be readable immediately after writing, but
  /// configuration changes may take time to propagate.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [ifMetagenerationMatch] - Makes the return of the bucket metadata
  /// conditional on whether the bucket's current metageneration matches the
  /// given value.
  ///
  /// [ifMetagenerationNotMatch] - Makes the return of the bucket metadata
  /// conditional on whether the bucket's current metageneration does not match
  /// the given value.
  ///
  /// [predefinedAcl] - Apply a predefined set of access controls to this
  /// bucket.
  /// Possible string values are:
  /// - "authenticatedRead" : Project team owners get OWNER access, and
  /// allAuthenticatedUsers get READER access.
  /// - "private" : Project team owners get OWNER access.
  /// - "projectPrivate" : Project team members get access according to their
  /// roles.
  /// - "publicRead" : Project team owners get OWNER access, and allUsers get
  /// READER access.
  /// - "publicReadWrite" : Project team owners get OWNER access, and allUsers
  /// get WRITER access.
  ///
  /// [predefinedDefaultObjectAcl] - Apply a predefined set of default object
  /// access controls to this bucket.
  /// Possible string values are:
  /// - "authenticatedRead" : Object owner gets OWNER access, and
  /// allAuthenticatedUsers get READER access.
  /// - "bucketOwnerFullControl" : Object owner gets OWNER access, and project
  /// team owners get OWNER access.
  /// - "bucketOwnerRead" : Object owner gets OWNER access, and project team
  /// owners get READER access.
  /// - "private" : Object owner gets OWNER access.
  /// - "projectPrivate" : Object owner gets OWNER access, and project team
  /// members get access according to their roles.
  /// - "publicRead" : Object owner gets OWNER access, and allUsers get READER
  /// access.
  ///
  /// [projection] - Set of properties to return. Defaults to full.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit owner, acl and defaultObjectAcl properties.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Bucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Bucket> update(
    Bucket request,
    core.String bucket, {
    core.String? ifMetagenerationMatch,
    core.String? ifMetagenerationNotMatch,
    core.String? predefinedAcl,
    core.String? predefinedDefaultObjectAcl,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (ifMetagenerationNotMatch != null)
        'ifMetagenerationNotMatch': [ifMetagenerationNotMatch],
      if (predefinedAcl != null) 'predefinedAcl': [predefinedAcl],
      if (predefinedDefaultObjectAcl != null)
        'predefinedDefaultObjectAcl': [predefinedDefaultObjectAcl],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' + commons.escapeVariable('$bucket');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Bucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ChannelsResource {
  final commons.ApiRequester _requester;

  ChannelsResource(commons.ApiRequester client) : _requester = client;

  /// Stop watching resources through this channel
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> stop(
    Channel request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'channels/stop';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }
}

class DefaultObjectAccessControlsResource {
  final commons.ApiRequester _requester;

  DefaultObjectAccessControlsResource(commons.ApiRequester client)
      : _requester = client;

  /// Permanently deletes the default object ACL entry for the specified entity
  /// on the specified bucket.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [entity] - The entity holding the permission. Can be user-userId,
  /// user-emailAddress, group-groupId, group-emailAddress, allUsers, or
  /// allAuthenticatedUsers.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String bucket,
    core.String entity, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/defaultObjectAcl/' +
        commons.escapeVariable('$entity');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Returns the default object ACL entry for the specified entity on the
  /// specified bucket.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [entity] - The entity holding the permission. Can be user-userId,
  /// user-emailAddress, group-groupId, group-emailAddress, allUsers, or
  /// allAuthenticatedUsers.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ObjectAccessControl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ObjectAccessControl> get(
    core.String bucket,
    core.String entity, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/defaultObjectAcl/' +
        commons.escapeVariable('$entity');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ObjectAccessControl.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new default object ACL entry on the specified bucket.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ObjectAccessControl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ObjectAccessControl> insert(
    ObjectAccessControl request,
    core.String bucket, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' + commons.escapeVariable('$bucket') + '/defaultObjectAcl';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ObjectAccessControl.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves default object ACL entries on the specified bucket.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [ifMetagenerationMatch] - If present, only return default ACL listing if
  /// the bucket's current metageneration matches this value.
  ///
  /// [ifMetagenerationNotMatch] - If present, only return default ACL listing
  /// if the bucket's current metageneration does not match the given value.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ObjectAccessControls].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ObjectAccessControls> list(
    core.String bucket, {
    core.String? ifMetagenerationMatch,
    core.String? ifMetagenerationNotMatch,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (ifMetagenerationNotMatch != null)
        'ifMetagenerationNotMatch': [ifMetagenerationNotMatch],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' + commons.escapeVariable('$bucket') + '/defaultObjectAcl';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ObjectAccessControls.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Patches a default object ACL entry on the specified bucket.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [entity] - The entity holding the permission. Can be user-userId,
  /// user-emailAddress, group-groupId, group-emailAddress, allUsers, or
  /// allAuthenticatedUsers.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ObjectAccessControl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ObjectAccessControl> patch(
    ObjectAccessControl request,
    core.String bucket,
    core.String entity, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/defaultObjectAcl/' +
        commons.escapeVariable('$entity');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return ObjectAccessControl.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a default object ACL entry on the specified bucket.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [entity] - The entity holding the permission. Can be user-userId,
  /// user-emailAddress, group-groupId, group-emailAddress, allUsers, or
  /// allAuthenticatedUsers.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ObjectAccessControl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ObjectAccessControl> update(
    ObjectAccessControl request,
    core.String bucket,
    core.String entity, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/defaultObjectAcl/' +
        commons.escapeVariable('$entity');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return ObjectAccessControl.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class NotificationsResource {
  final commons.ApiRequester _requester;

  NotificationsResource(commons.ApiRequester client) : _requester = client;

  /// Permanently deletes a notification subscription.
  ///
  /// Request parameters:
  ///
  /// [bucket] - The parent bucket of the notification.
  ///
  /// [notification] - ID of the notification to delete.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String bucket,
    core.String notification, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/notificationConfigs/' +
        commons.escapeVariable('$notification');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// View a notification configuration.
  ///
  /// Request parameters:
  ///
  /// [bucket] - The parent bucket of the notification.
  ///
  /// [notification] - Notification ID
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
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
    core.String bucket,
    core.String notification, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/notificationConfigs/' +
        commons.escapeVariable('$notification');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Notification.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a notification subscription for a given bucket.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - The parent bucket of the notification.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
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
  async.Future<Notification> insert(
    Notification request,
    core.String bucket, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'b/' + commons.escapeVariable('$bucket') + '/notificationConfigs';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Notification.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of notification subscriptions for a given bucket.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a Google Cloud Storage bucket.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Notifications].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Notifications> list(
    core.String bucket, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'b/' + commons.escapeVariable('$bucket') + '/notificationConfigs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Notifications.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ObjectAccessControlsResource {
  final commons.ApiRequester _requester;

  ObjectAccessControlsResource(commons.ApiRequester client)
      : _requester = client;

  /// Permanently deletes the ACL entry for the specified entity on the
  /// specified object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [entity] - The entity holding the permission. Can be user-userId,
  /// user-emailAddress, group-groupId, group-emailAddress, allUsers, or
  /// allAuthenticatedUsers.
  ///
  /// [generation] - If present, selects a specific revision of this object (as
  /// opposed to the latest version, the default).
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String bucket,
    core.String object,
    core.String entity, {
    core.String? generation,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (generation != null) 'generation': [generation],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object') +
        '/acl/' +
        commons.escapeVariable('$entity');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Returns the ACL entry for the specified entity on the specified object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [entity] - The entity holding the permission. Can be user-userId,
  /// user-emailAddress, group-groupId, group-emailAddress, allUsers, or
  /// allAuthenticatedUsers.
  ///
  /// [generation] - If present, selects a specific revision of this object (as
  /// opposed to the latest version, the default).
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ObjectAccessControl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ObjectAccessControl> get(
    core.String bucket,
    core.String object,
    core.String entity, {
    core.String? generation,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (generation != null) 'generation': [generation],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object') +
        '/acl/' +
        commons.escapeVariable('$entity');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ObjectAccessControl.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new ACL entry on the specified object.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [generation] - If present, selects a specific revision of this object (as
  /// opposed to the latest version, the default).
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ObjectAccessControl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ObjectAccessControl> insert(
    ObjectAccessControl request,
    core.String bucket,
    core.String object, {
    core.String? generation,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (generation != null) 'generation': [generation],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object') +
        '/acl';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ObjectAccessControl.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves ACL entries on the specified object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [generation] - If present, selects a specific revision of this object (as
  /// opposed to the latest version, the default).
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ObjectAccessControls].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ObjectAccessControls> list(
    core.String bucket,
    core.String object, {
    core.String? generation,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (generation != null) 'generation': [generation],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object') +
        '/acl';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ObjectAccessControls.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Patches an ACL entry on the specified object.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [entity] - The entity holding the permission. Can be user-userId,
  /// user-emailAddress, group-groupId, group-emailAddress, allUsers, or
  /// allAuthenticatedUsers.
  ///
  /// [generation] - If present, selects a specific revision of this object (as
  /// opposed to the latest version, the default).
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ObjectAccessControl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ObjectAccessControl> patch(
    ObjectAccessControl request,
    core.String bucket,
    core.String object,
    core.String entity, {
    core.String? generation,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (generation != null) 'generation': [generation],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object') +
        '/acl/' +
        commons.escapeVariable('$entity');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return ObjectAccessControl.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an ACL entry on the specified object.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of a bucket.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [entity] - The entity holding the permission. Can be user-userId,
  /// user-emailAddress, group-groupId, group-emailAddress, allUsers, or
  /// allAuthenticatedUsers.
  ///
  /// [generation] - If present, selects a specific revision of this object (as
  /// opposed to the latest version, the default).
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ObjectAccessControl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ObjectAccessControl> update(
    ObjectAccessControl request,
    core.String bucket,
    core.String object,
    core.String entity, {
    core.String? generation,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (generation != null) 'generation': [generation],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object') +
        '/acl/' +
        commons.escapeVariable('$entity');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return ObjectAccessControl.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ObjectsResource {
  final commons.ApiRequester _requester;

  ObjectsResource(commons.ApiRequester client) : _requester = client;

  /// Concatenates a list of existing objects into a new object in the same
  /// bucket.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [destinationBucket] - Name of the bucket containing the source objects.
  /// The destination object is stored in this bucket.
  ///
  /// [destinationObject] - Name of the new object. For information about how to
  /// URL encode object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [destinationPredefinedAcl] - Apply a predefined set of access controls to
  /// the destination object.
  /// Possible string values are:
  /// - "authenticatedRead" : Object owner gets OWNER access, and
  /// allAuthenticatedUsers get READER access.
  /// - "bucketOwnerFullControl" : Object owner gets OWNER access, and project
  /// team owners get OWNER access.
  /// - "bucketOwnerRead" : Object owner gets OWNER access, and project team
  /// owners get READER access.
  /// - "private" : Object owner gets OWNER access.
  /// - "projectPrivate" : Object owner gets OWNER access, and project team
  /// members get access according to their roles.
  /// - "publicRead" : Object owner gets OWNER access, and allUsers get READER
  /// access.
  ///
  /// [ifGenerationMatch] - Makes the operation conditional on whether the
  /// object's current generation matches the given value. Setting to 0 makes
  /// the operation succeed only if there are no live versions of the object.
  ///
  /// [ifMetagenerationMatch] - Makes the operation conditional on whether the
  /// object's current metageneration matches the given value.
  ///
  /// [kmsKeyName] - Resource name of the Cloud KMS key, of the form
  /// projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key,
  /// that will be used to encrypt the object. Overrides the object metadata's
  /// kms_key_name value, if any.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Object].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Object> compose(
    ComposeRequest request,
    core.String destinationBucket,
    core.String destinationObject, {
    core.String? destinationPredefinedAcl,
    core.String? ifGenerationMatch,
    core.String? ifMetagenerationMatch,
    core.String? kmsKeyName,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (destinationPredefinedAcl != null)
        'destinationPredefinedAcl': [destinationPredefinedAcl],
      if (ifGenerationMatch != null) 'ifGenerationMatch': [ifGenerationMatch],
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (kmsKeyName != null) 'kmsKeyName': [kmsKeyName],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$destinationBucket') +
        '/o/' +
        commons.escapeVariable('$destinationObject') +
        '/compose';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Object.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Copies a source object to a destination object.
  ///
  /// Optionally overrides metadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [sourceBucket] - Name of the bucket in which to find the source object.
  ///
  /// [sourceObject] - Name of the source object. For information about how to
  /// URL encode object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [destinationBucket] - Name of the bucket in which to store the new object.
  /// Overrides the provided object metadata's bucket value, if any.For
  /// information about how to URL encode object names to be path safe, see
  /// Encoding URI Path Parts.
  ///
  /// [destinationObject] - Name of the new object. Required when the object
  /// metadata is not otherwise provided. Overrides the object metadata's name
  /// value, if any.
  ///
  /// [destinationKmsKeyName] - Resource name of the Cloud KMS key, of the form
  /// projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key,
  /// that will be used to encrypt the object. Overrides the object metadata's
  /// kms_key_name value, if any.
  ///
  /// [destinationPredefinedAcl] - Apply a predefined set of access controls to
  /// the destination object.
  /// Possible string values are:
  /// - "authenticatedRead" : Object owner gets OWNER access, and
  /// allAuthenticatedUsers get READER access.
  /// - "bucketOwnerFullControl" : Object owner gets OWNER access, and project
  /// team owners get OWNER access.
  /// - "bucketOwnerRead" : Object owner gets OWNER access, and project team
  /// owners get READER access.
  /// - "private" : Object owner gets OWNER access.
  /// - "projectPrivate" : Object owner gets OWNER access, and project team
  /// members get access according to their roles.
  /// - "publicRead" : Object owner gets OWNER access, and allUsers get READER
  /// access.
  ///
  /// [ifGenerationMatch] - Makes the operation conditional on whether the
  /// destination object's current generation matches the given value. Setting
  /// to 0 makes the operation succeed only if there are no live versions of the
  /// object.
  ///
  /// [ifGenerationNotMatch] - Makes the operation conditional on whether the
  /// destination object's current generation does not match the given value. If
  /// no live object exists, the precondition fails. Setting to 0 makes the
  /// operation succeed only if there is a live version of the object.
  ///
  /// [ifMetagenerationMatch] - Makes the operation conditional on whether the
  /// destination object's current metageneration matches the given value.
  ///
  /// [ifMetagenerationNotMatch] - Makes the operation conditional on whether
  /// the destination object's current metageneration does not match the given
  /// value.
  ///
  /// [ifSourceGenerationMatch] - Makes the operation conditional on whether the
  /// source object's current generation matches the given value.
  ///
  /// [ifSourceGenerationNotMatch] - Makes the operation conditional on whether
  /// the source object's current generation does not match the given value.
  ///
  /// [ifSourceMetagenerationMatch] - Makes the operation conditional on whether
  /// the source object's current metageneration matches the given value.
  ///
  /// [ifSourceMetagenerationNotMatch] - Makes the operation conditional on
  /// whether the source object's current metageneration does not match the
  /// given value.
  ///
  /// [projection] - Set of properties to return. Defaults to noAcl, unless the
  /// object resource specifies the acl property, when it defaults to full.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit the owner, acl property.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [sourceGeneration] - If present, selects a specific revision of the source
  /// object (as opposed to the latest version, the default).
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Object].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Object> copy(
    Object request,
    core.String sourceBucket,
    core.String sourceObject,
    core.String destinationBucket,
    core.String destinationObject, {
    core.String? destinationKmsKeyName,
    core.String? destinationPredefinedAcl,
    core.String? ifGenerationMatch,
    core.String? ifGenerationNotMatch,
    core.String? ifMetagenerationMatch,
    core.String? ifMetagenerationNotMatch,
    core.String? ifSourceGenerationMatch,
    core.String? ifSourceGenerationNotMatch,
    core.String? ifSourceMetagenerationMatch,
    core.String? ifSourceMetagenerationNotMatch,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? sourceGeneration,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (destinationKmsKeyName != null)
        'destinationKmsKeyName': [destinationKmsKeyName],
      if (destinationPredefinedAcl != null)
        'destinationPredefinedAcl': [destinationPredefinedAcl],
      if (ifGenerationMatch != null) 'ifGenerationMatch': [ifGenerationMatch],
      if (ifGenerationNotMatch != null)
        'ifGenerationNotMatch': [ifGenerationNotMatch],
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (ifMetagenerationNotMatch != null)
        'ifMetagenerationNotMatch': [ifMetagenerationNotMatch],
      if (ifSourceGenerationMatch != null)
        'ifSourceGenerationMatch': [ifSourceGenerationMatch],
      if (ifSourceGenerationNotMatch != null)
        'ifSourceGenerationNotMatch': [ifSourceGenerationNotMatch],
      if (ifSourceMetagenerationMatch != null)
        'ifSourceMetagenerationMatch': [ifSourceMetagenerationMatch],
      if (ifSourceMetagenerationNotMatch != null)
        'ifSourceMetagenerationNotMatch': [ifSourceMetagenerationNotMatch],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (sourceGeneration != null) 'sourceGeneration': [sourceGeneration],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$sourceBucket') +
        '/o/' +
        commons.escapeVariable('$sourceObject') +
        '/copyTo/b/' +
        commons.escapeVariable('$destinationBucket') +
        '/o/' +
        commons.escapeVariable('$destinationObject');

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Object.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an object and its metadata.
  ///
  /// Deletions are permanent if versioning is not enabled for the bucket, or if
  /// the generation parameter is used.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of the bucket in which the object resides.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [generation] - If present, permanently deletes a specific revision of this
  /// object (as opposed to the latest version, the default).
  ///
  /// [ifGenerationMatch] - Makes the operation conditional on whether the
  /// object's current generation matches the given value. Setting to 0 makes
  /// the operation succeed only if there are no live versions of the object.
  ///
  /// [ifGenerationNotMatch] - Makes the operation conditional on whether the
  /// object's current generation does not match the given value. If no live
  /// object exists, the precondition fails. Setting to 0 makes the operation
  /// succeed only if there is a live version of the object.
  ///
  /// [ifMetagenerationMatch] - Makes the operation conditional on whether the
  /// object's current metageneration matches the given value.
  ///
  /// [ifMetagenerationNotMatch] - Makes the operation conditional on whether
  /// the object's current metageneration does not match the given value.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String bucket,
    core.String object, {
    core.String? generation,
    core.String? ifGenerationMatch,
    core.String? ifGenerationNotMatch,
    core.String? ifMetagenerationMatch,
    core.String? ifMetagenerationNotMatch,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (generation != null) 'generation': [generation],
      if (ifGenerationMatch != null) 'ifGenerationMatch': [ifGenerationMatch],
      if (ifGenerationNotMatch != null)
        'ifGenerationNotMatch': [ifGenerationNotMatch],
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (ifMetagenerationNotMatch != null)
        'ifMetagenerationNotMatch': [ifMetagenerationNotMatch],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves an object or its metadata.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of the bucket in which the object resides.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [generation] - If present, selects a specific revision of this object (as
  /// opposed to the latest version, the default).
  ///
  /// [ifGenerationMatch] - Makes the operation conditional on whether the
  /// object's current generation matches the given value. Setting to 0 makes
  /// the operation succeed only if there are no live versions of the object.
  ///
  /// [ifGenerationNotMatch] - Makes the operation conditional on whether the
  /// object's current generation does not match the given value. If no live
  /// object exists, the precondition fails. Setting to 0 makes the operation
  /// succeed only if there is a live version of the object.
  ///
  /// [ifMetagenerationMatch] - Makes the operation conditional on whether the
  /// object's current metageneration matches the given value.
  ///
  /// [ifMetagenerationNotMatch] - Makes the operation conditional on whether
  /// the object's current metageneration does not match the given value.
  ///
  /// [projection] - Set of properties to return. Defaults to noAcl.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit the owner, acl property.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [downloadOptions] - Options for downloading. A download can be either a
  /// Metadata (default) or Media download. Partial Media downloads are possible
  /// as well.
  ///
  /// Completes with a
  ///
  /// - [Object] for Metadata downloads (see [downloadOptions]).
  ///
  /// - [commons.Media] for Media downloads (see [downloadOptions]).
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<core.Object> get(
    core.String bucket,
    core.String object, {
    core.String? generation,
    core.String? ifGenerationMatch,
    core.String? ifGenerationNotMatch,
    core.String? ifMetagenerationMatch,
    core.String? ifMetagenerationNotMatch,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
    commons.DownloadOptions downloadOptions = commons.DownloadOptions.metadata,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (generation != null) 'generation': [generation],
      if (ifGenerationMatch != null) 'ifGenerationMatch': [ifGenerationMatch],
      if (ifGenerationNotMatch != null)
        'ifGenerationNotMatch': [ifGenerationNotMatch],
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (ifMetagenerationNotMatch != null)
        'ifMetagenerationNotMatch': [ifMetagenerationNotMatch],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
      downloadOptions: downloadOptions,
    );
    if (downloadOptions.isMetadataDownload) {
      return Object.fromJson(_response as core.Map<core.String, core.dynamic>);
    } else {
      return _response as commons.Media;
    }
  }

  /// Returns an IAM policy for the specified object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of the bucket in which the object resides.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [generation] - If present, selects a specific revision of this object (as
  /// opposed to the latest version, the default).
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> getIamPolicy(
    core.String bucket,
    core.String object, {
    core.String? generation,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (generation != null) 'generation': [generation],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object') +
        '/iam';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Stores a new object and metadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of the bucket in which to store the new object. Overrides
  /// the provided object metadata's bucket value, if any.
  ///
  /// [contentEncoding] - If set, sets the contentEncoding property of the final
  /// object to this value. Setting this parameter is equivalent to setting the
  /// contentEncoding metadata property. This can be useful when uploading an
  /// object with uploadType=media to indicate the encoding of the content being
  /// uploaded.
  ///
  /// [ifGenerationMatch] - Makes the operation conditional on whether the
  /// object's current generation matches the given value. Setting to 0 makes
  /// the operation succeed only if there are no live versions of the object.
  ///
  /// [ifGenerationNotMatch] - Makes the operation conditional on whether the
  /// object's current generation does not match the given value. If no live
  /// object exists, the precondition fails. Setting to 0 makes the operation
  /// succeed only if there is a live version of the object.
  ///
  /// [ifMetagenerationMatch] - Makes the operation conditional on whether the
  /// object's current metageneration matches the given value.
  ///
  /// [ifMetagenerationNotMatch] - Makes the operation conditional on whether
  /// the object's current metageneration does not match the given value.
  ///
  /// [kmsKeyName] - Resource name of the Cloud KMS key, of the form
  /// projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key,
  /// that will be used to encrypt the object. Overrides the object metadata's
  /// kms_key_name value, if any.
  ///
  /// [name] - Name of the object. Required when the object metadata is not
  /// otherwise provided. Overrides the object metadata's name value, if any.
  /// For information about how to URL encode object names to be path safe, see
  /// Encoding URI Path Parts.
  ///
  /// [predefinedAcl] - Apply a predefined set of access controls to this
  /// object.
  /// Possible string values are:
  /// - "authenticatedRead" : Object owner gets OWNER access, and
  /// allAuthenticatedUsers get READER access.
  /// - "bucketOwnerFullControl" : Object owner gets OWNER access, and project
  /// team owners get OWNER access.
  /// - "bucketOwnerRead" : Object owner gets OWNER access, and project team
  /// owners get READER access.
  /// - "private" : Object owner gets OWNER access.
  /// - "projectPrivate" : Object owner gets OWNER access, and project team
  /// members get access according to their roles.
  /// - "publicRead" : Object owner gets OWNER access, and allUsers get READER
  /// access.
  ///
  /// [projection] - Set of properties to return. Defaults to noAcl, unless the
  /// object resource specifies the acl property, when it defaults to full.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit the owner, acl property.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [uploadMedia] - The media to upload.
  ///
  /// [uploadOptions] - Options for the media upload. Streaming Media without
  /// the length being known ahead of time is only supported via resumable
  /// uploads.
  ///
  /// Completes with a [Object].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Object> insert(
    Object request,
    core.String bucket, {
    core.String? contentEncoding,
    core.String? ifGenerationMatch,
    core.String? ifGenerationNotMatch,
    core.String? ifMetagenerationMatch,
    core.String? ifMetagenerationNotMatch,
    core.String? kmsKeyName,
    core.String? name,
    core.String? predefinedAcl,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
    commons.UploadOptions uploadOptions = commons.UploadOptions.defaultOptions,
    commons.Media? uploadMedia,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (contentEncoding != null) 'contentEncoding': [contentEncoding],
      if (ifGenerationMatch != null) 'ifGenerationMatch': [ifGenerationMatch],
      if (ifGenerationNotMatch != null)
        'ifGenerationNotMatch': [ifGenerationNotMatch],
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (ifMetagenerationNotMatch != null)
        'ifMetagenerationNotMatch': [ifMetagenerationNotMatch],
      if (kmsKeyName != null) 'kmsKeyName': [kmsKeyName],
      if (name != null) 'name': [name],
      if (predefinedAcl != null) 'predefinedAcl': [predefinedAcl],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    core.String _url;
    if (uploadMedia == null) {
      _url = 'b/' + commons.escapeVariable('$bucket') + '/o';
    } else if (uploadOptions is commons.ResumableUploadOptions) {
      _url = '/resumable/upload/storage/v1/b/' +
          commons.escapeVariable('$bucket') +
          '/o';
    } else {
      _url = '/upload/storage/v1/b/' + commons.escapeVariable('$bucket') + '/o';
    }

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      uploadMedia: uploadMedia,
      uploadOptions: uploadOptions,
    );
    return Object.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of objects matching the criteria.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of the bucket in which to look for objects.
  ///
  /// [delimiter] - Returns results in a directory-like mode. items will contain
  /// only objects whose names, aside from the prefix, do not contain delimiter.
  /// Objects whose names, aside from the prefix, contain delimiter will have
  /// their name, truncated after the delimiter, returned in prefixes. Duplicate
  /// prefixes are omitted.
  ///
  /// [endOffset] - Filter results to objects whose names are lexicographically
  /// before endOffset. If startOffset is also set, the objects listed will have
  /// names between startOffset (inclusive) and endOffset (exclusive).
  ///
  /// [includeTrailingDelimiter] - If true, objects that end in exactly one
  /// instance of delimiter will have their metadata included in items in
  /// addition to prefixes.
  ///
  /// [maxResults] - Maximum number of items plus prefixes to return in a single
  /// page of responses. As duplicate prefixes are omitted, fewer total results
  /// may be returned than requested. The service will use this parameter or
  /// 1,000 items, whichever is smaller.
  ///
  /// [pageToken] - A previously-returned page token representing part of the
  /// larger set of results to view.
  ///
  /// [prefix] - Filter results to objects whose names begin with this prefix.
  ///
  /// [projection] - Set of properties to return. Defaults to noAcl.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit the owner, acl property.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [startOffset] - Filter results to objects whose names are
  /// lexicographically equal to or after startOffset. If endOffset is also set,
  /// the objects listed will have names between startOffset (inclusive) and
  /// endOffset (exclusive).
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [versions] - If true, lists all versions of an object as distinct results.
  /// The default is false. For more information, see Object Versioning.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Objects].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Objects> list(
    core.String bucket, {
    core.String? delimiter,
    core.String? endOffset,
    core.bool? includeTrailingDelimiter,
    core.int? maxResults,
    core.String? pageToken,
    core.String? prefix,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? startOffset,
    core.String? userProject,
    core.bool? versions,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (delimiter != null) 'delimiter': [delimiter],
      if (endOffset != null) 'endOffset': [endOffset],
      if (includeTrailingDelimiter != null)
        'includeTrailingDelimiter': ['${includeTrailingDelimiter}'],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (prefix != null) 'prefix': [prefix],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (startOffset != null) 'startOffset': [startOffset],
      if (userProject != null) 'userProject': [userProject],
      if (versions != null) 'versions': ['${versions}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' + commons.escapeVariable('$bucket') + '/o';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Objects.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Patches an object's metadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of the bucket in which the object resides.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [generation] - If present, selects a specific revision of this object (as
  /// opposed to the latest version, the default).
  ///
  /// [ifGenerationMatch] - Makes the operation conditional on whether the
  /// object's current generation matches the given value. Setting to 0 makes
  /// the operation succeed only if there are no live versions of the object.
  ///
  /// [ifGenerationNotMatch] - Makes the operation conditional on whether the
  /// object's current generation does not match the given value. If no live
  /// object exists, the precondition fails. Setting to 0 makes the operation
  /// succeed only if there is a live version of the object.
  ///
  /// [ifMetagenerationMatch] - Makes the operation conditional on whether the
  /// object's current metageneration matches the given value.
  ///
  /// [ifMetagenerationNotMatch] - Makes the operation conditional on whether
  /// the object's current metageneration does not match the given value.
  ///
  /// [predefinedAcl] - Apply a predefined set of access controls to this
  /// object.
  /// Possible string values are:
  /// - "authenticatedRead" : Object owner gets OWNER access, and
  /// allAuthenticatedUsers get READER access.
  /// - "bucketOwnerFullControl" : Object owner gets OWNER access, and project
  /// team owners get OWNER access.
  /// - "bucketOwnerRead" : Object owner gets OWNER access, and project team
  /// owners get READER access.
  /// - "private" : Object owner gets OWNER access.
  /// - "projectPrivate" : Object owner gets OWNER access, and project team
  /// members get access according to their roles.
  /// - "publicRead" : Object owner gets OWNER access, and allUsers get READER
  /// access.
  ///
  /// [projection] - Set of properties to return. Defaults to full.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit the owner, acl property.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request, for Requester
  /// Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Object].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Object> patch(
    Object request,
    core.String bucket,
    core.String object, {
    core.String? generation,
    core.String? ifGenerationMatch,
    core.String? ifGenerationNotMatch,
    core.String? ifMetagenerationMatch,
    core.String? ifMetagenerationNotMatch,
    core.String? predefinedAcl,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (generation != null) 'generation': [generation],
      if (ifGenerationMatch != null) 'ifGenerationMatch': [ifGenerationMatch],
      if (ifGenerationNotMatch != null)
        'ifGenerationNotMatch': [ifGenerationNotMatch],
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (ifMetagenerationNotMatch != null)
        'ifMetagenerationNotMatch': [ifMetagenerationNotMatch],
      if (predefinedAcl != null) 'predefinedAcl': [predefinedAcl],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Object.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Rewrites a source object to a destination object.
  ///
  /// Optionally overrides metadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [sourceBucket] - Name of the bucket in which to find the source object.
  ///
  /// [sourceObject] - Name of the source object. For information about how to
  /// URL encode object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [destinationBucket] - Name of the bucket in which to store the new object.
  /// Overrides the provided object metadata's bucket value, if any.
  ///
  /// [destinationObject] - Name of the new object. Required when the object
  /// metadata is not otherwise provided. Overrides the object metadata's name
  /// value, if any. For information about how to URL encode object names to be
  /// path safe, see Encoding URI Path Parts.
  ///
  /// [destinationKmsKeyName] - Resource name of the Cloud KMS key, of the form
  /// projects/my-project/locations/global/keyRings/my-kr/cryptoKeys/my-key,
  /// that will be used to encrypt the object. Overrides the object metadata's
  /// kms_key_name value, if any.
  ///
  /// [destinationPredefinedAcl] - Apply a predefined set of access controls to
  /// the destination object.
  /// Possible string values are:
  /// - "authenticatedRead" : Object owner gets OWNER access, and
  /// allAuthenticatedUsers get READER access.
  /// - "bucketOwnerFullControl" : Object owner gets OWNER access, and project
  /// team owners get OWNER access.
  /// - "bucketOwnerRead" : Object owner gets OWNER access, and project team
  /// owners get READER access.
  /// - "private" : Object owner gets OWNER access.
  /// - "projectPrivate" : Object owner gets OWNER access, and project team
  /// members get access according to their roles.
  /// - "publicRead" : Object owner gets OWNER access, and allUsers get READER
  /// access.
  ///
  /// [ifGenerationMatch] - Makes the operation conditional on whether the
  /// object's current generation matches the given value. Setting to 0 makes
  /// the operation succeed only if there are no live versions of the object.
  ///
  /// [ifGenerationNotMatch] - Makes the operation conditional on whether the
  /// object's current generation does not match the given value. If no live
  /// object exists, the precondition fails. Setting to 0 makes the operation
  /// succeed only if there is a live version of the object.
  ///
  /// [ifMetagenerationMatch] - Makes the operation conditional on whether the
  /// destination object's current metageneration matches the given value.
  ///
  /// [ifMetagenerationNotMatch] - Makes the operation conditional on whether
  /// the destination object's current metageneration does not match the given
  /// value.
  ///
  /// [ifSourceGenerationMatch] - Makes the operation conditional on whether the
  /// source object's current generation matches the given value.
  ///
  /// [ifSourceGenerationNotMatch] - Makes the operation conditional on whether
  /// the source object's current generation does not match the given value.
  ///
  /// [ifSourceMetagenerationMatch] - Makes the operation conditional on whether
  /// the source object's current metageneration matches the given value.
  ///
  /// [ifSourceMetagenerationNotMatch] - Makes the operation conditional on
  /// whether the source object's current metageneration does not match the
  /// given value.
  ///
  /// [maxBytesRewrittenPerCall] - The maximum number of bytes that will be
  /// rewritten per rewrite request. Most callers shouldn't need to specify this
  /// parameter - it is primarily in place to support testing. If specified the
  /// value must be an integral multiple of 1 MiB (1048576). Also, this only
  /// applies to requests where the source and destination span locations and/or
  /// storage classes. Finally, this value must not change across rewrite calls
  /// else you'll get an error that the rewriteToken is invalid.
  ///
  /// [projection] - Set of properties to return. Defaults to noAcl, unless the
  /// object resource specifies the acl property, when it defaults to full.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit the owner, acl property.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [rewriteToken] - Include this field (from the previous rewrite response)
  /// on each rewrite request after the first one, until the rewrite response
  /// 'done' flag is true. Calls that provide a rewriteToken can omit all other
  /// request fields, but if included those fields must match the values
  /// provided in the first rewrite request.
  ///
  /// [sourceGeneration] - If present, selects a specific revision of the source
  /// object (as opposed to the latest version, the default).
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RewriteResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RewriteResponse> rewrite(
    Object request,
    core.String sourceBucket,
    core.String sourceObject,
    core.String destinationBucket,
    core.String destinationObject, {
    core.String? destinationKmsKeyName,
    core.String? destinationPredefinedAcl,
    core.String? ifGenerationMatch,
    core.String? ifGenerationNotMatch,
    core.String? ifMetagenerationMatch,
    core.String? ifMetagenerationNotMatch,
    core.String? ifSourceGenerationMatch,
    core.String? ifSourceGenerationNotMatch,
    core.String? ifSourceMetagenerationMatch,
    core.String? ifSourceMetagenerationNotMatch,
    core.String? maxBytesRewrittenPerCall,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? rewriteToken,
    core.String? sourceGeneration,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (destinationKmsKeyName != null)
        'destinationKmsKeyName': [destinationKmsKeyName],
      if (destinationPredefinedAcl != null)
        'destinationPredefinedAcl': [destinationPredefinedAcl],
      if (ifGenerationMatch != null) 'ifGenerationMatch': [ifGenerationMatch],
      if (ifGenerationNotMatch != null)
        'ifGenerationNotMatch': [ifGenerationNotMatch],
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (ifMetagenerationNotMatch != null)
        'ifMetagenerationNotMatch': [ifMetagenerationNotMatch],
      if (ifSourceGenerationMatch != null)
        'ifSourceGenerationMatch': [ifSourceGenerationMatch],
      if (ifSourceGenerationNotMatch != null)
        'ifSourceGenerationNotMatch': [ifSourceGenerationNotMatch],
      if (ifSourceMetagenerationMatch != null)
        'ifSourceMetagenerationMatch': [ifSourceMetagenerationMatch],
      if (ifSourceMetagenerationNotMatch != null)
        'ifSourceMetagenerationNotMatch': [ifSourceMetagenerationNotMatch],
      if (maxBytesRewrittenPerCall != null)
        'maxBytesRewrittenPerCall': [maxBytesRewrittenPerCall],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (rewriteToken != null) 'rewriteToken': [rewriteToken],
      if (sourceGeneration != null) 'sourceGeneration': [sourceGeneration],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$sourceBucket') +
        '/o/' +
        commons.escapeVariable('$sourceObject') +
        '/rewriteTo/b/' +
        commons.escapeVariable('$destinationBucket') +
        '/o/' +
        commons.escapeVariable('$destinationObject');

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return RewriteResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an IAM policy for the specified object.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of the bucket in which the object resides.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [generation] - If present, selects a specific revision of this object (as
  /// opposed to the latest version, the default).
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> setIamPolicy(
    Policy request,
    core.String bucket,
    core.String object, {
    core.String? generation,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (generation != null) 'generation': [generation],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object') +
        '/iam';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Tests a set of permissions on the given object to see which, if any, are
  /// held by the caller.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of the bucket in which the object resides.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [permissions] - Permissions to test.
  ///
  /// [generation] - If present, selects a specific revision of this object (as
  /// opposed to the latest version, the default).
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TestIamPermissionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TestIamPermissionsResponse> testIamPermissions(
    core.String bucket,
    core.String object,
    core.List<core.String> permissions, {
    core.String? generation,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    if (permissions.isEmpty) {
      throw core.ArgumentError('Parameter permissions cannot be empty.');
    }
    final _queryParams = <core.String, core.List<core.String>>{
      'permissions': permissions,
      if (generation != null) 'generation': [generation],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object') +
        '/iam/testPermissions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TestIamPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an object's metadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of the bucket in which the object resides.
  ///
  /// [object] - Name of the object. For information about how to URL encode
  /// object names to be path safe, see Encoding URI Path Parts.
  ///
  /// [generation] - If present, selects a specific revision of this object (as
  /// opposed to the latest version, the default).
  ///
  /// [ifGenerationMatch] - Makes the operation conditional on whether the
  /// object's current generation matches the given value. Setting to 0 makes
  /// the operation succeed only if there are no live versions of the object.
  ///
  /// [ifGenerationNotMatch] - Makes the operation conditional on whether the
  /// object's current generation does not match the given value. If no live
  /// object exists, the precondition fails. Setting to 0 makes the operation
  /// succeed only if there is a live version of the object.
  ///
  /// [ifMetagenerationMatch] - Makes the operation conditional on whether the
  /// object's current metageneration matches the given value.
  ///
  /// [ifMetagenerationNotMatch] - Makes the operation conditional on whether
  /// the object's current metageneration does not match the given value.
  ///
  /// [predefinedAcl] - Apply a predefined set of access controls to this
  /// object.
  /// Possible string values are:
  /// - "authenticatedRead" : Object owner gets OWNER access, and
  /// allAuthenticatedUsers get READER access.
  /// - "bucketOwnerFullControl" : Object owner gets OWNER access, and project
  /// team owners get OWNER access.
  /// - "bucketOwnerRead" : Object owner gets OWNER access, and project team
  /// owners get READER access.
  /// - "private" : Object owner gets OWNER access.
  /// - "projectPrivate" : Object owner gets OWNER access, and project team
  /// members get access according to their roles.
  /// - "publicRead" : Object owner gets OWNER access, and allUsers get READER
  /// access.
  ///
  /// [projection] - Set of properties to return. Defaults to full.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit the owner, acl property.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Object].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Object> update(
    Object request,
    core.String bucket,
    core.String object, {
    core.String? generation,
    core.String? ifGenerationMatch,
    core.String? ifGenerationNotMatch,
    core.String? ifMetagenerationMatch,
    core.String? ifMetagenerationNotMatch,
    core.String? predefinedAcl,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (generation != null) 'generation': [generation],
      if (ifGenerationMatch != null) 'ifGenerationMatch': [ifGenerationMatch],
      if (ifGenerationNotMatch != null)
        'ifGenerationNotMatch': [ifGenerationNotMatch],
      if (ifMetagenerationMatch != null)
        'ifMetagenerationMatch': [ifMetagenerationMatch],
      if (ifMetagenerationNotMatch != null)
        'ifMetagenerationNotMatch': [ifMetagenerationNotMatch],
      if (predefinedAcl != null) 'predefinedAcl': [predefinedAcl],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' +
        commons.escapeVariable('$bucket') +
        '/o/' +
        commons.escapeVariable('$object');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Object.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Watch for changes on all objects in a bucket.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [bucket] - Name of the bucket in which to look for objects.
  ///
  /// [delimiter] - Returns results in a directory-like mode. items will contain
  /// only objects whose names, aside from the prefix, do not contain delimiter.
  /// Objects whose names, aside from the prefix, contain delimiter will have
  /// their name, truncated after the delimiter, returned in prefixes. Duplicate
  /// prefixes are omitted.
  ///
  /// [endOffset] - Filter results to objects whose names are lexicographically
  /// before endOffset. If startOffset is also set, the objects listed will have
  /// names between startOffset (inclusive) and endOffset (exclusive).
  ///
  /// [includeTrailingDelimiter] - If true, objects that end in exactly one
  /// instance of delimiter will have their metadata included in items in
  /// addition to prefixes.
  ///
  /// [maxResults] - Maximum number of items plus prefixes to return in a single
  /// page of responses. As duplicate prefixes are omitted, fewer total results
  /// may be returned than requested. The service will use this parameter or
  /// 1,000 items, whichever is smaller.
  ///
  /// [pageToken] - A previously-returned page token representing part of the
  /// larger set of results to view.
  ///
  /// [prefix] - Filter results to objects whose names begin with this prefix.
  ///
  /// [projection] - Set of properties to return. Defaults to noAcl.
  /// Possible string values are:
  /// - "full" : Include all properties.
  /// - "noAcl" : Omit the owner, acl property.
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [startOffset] - Filter results to objects whose names are
  /// lexicographically equal to or after startOffset. If endOffset is also set,
  /// the objects listed will have names between startOffset (inclusive) and
  /// endOffset (exclusive).
  ///
  /// [userProject] - The project to be billed for this request. Required for
  /// Requester Pays buckets.
  ///
  /// [versions] - If true, lists all versions of an object as distinct results.
  /// The default is false. For more information, see Object Versioning.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Channel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Channel> watchAll(
    Channel request,
    core.String bucket, {
    core.String? delimiter,
    core.String? endOffset,
    core.bool? includeTrailingDelimiter,
    core.int? maxResults,
    core.String? pageToken,
    core.String? prefix,
    core.String? projection,
    core.String? provisionalUserProject,
    core.String? startOffset,
    core.String? userProject,
    core.bool? versions,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (delimiter != null) 'delimiter': [delimiter],
      if (endOffset != null) 'endOffset': [endOffset],
      if (includeTrailingDelimiter != null)
        'includeTrailingDelimiter': ['${includeTrailingDelimiter}'],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (prefix != null) 'prefix': [prefix],
      if (projection != null) 'projection': [projection],
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (startOffset != null) 'startOffset': [startOffset],
      if (userProject != null) 'userProject': [userProject],
      if (versions != null) 'versions': ['${versions}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'b/' + commons.escapeVariable('$bucket') + '/o/watch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Channel.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsHmacKeysResource get hmacKeys => ProjectsHmacKeysResource(_requester);
  ProjectsServiceAccountResource get serviceAccount =>
      ProjectsServiceAccountResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsHmacKeysResource {
  final commons.ApiRequester _requester;

  ProjectsHmacKeysResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new HMAC key for the specified service account.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID owning the service account.
  ///
  /// [serviceAccountEmail] - Email address of the service account.
  ///
  /// [userProject] - The project to be billed for this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [HmacKey].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<HmacKey> create(
    core.String projectId,
    core.String serviceAccountEmail, {
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'serviceAccountEmail': [serviceAccountEmail],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'projects/' + commons.escapeVariable('$projectId') + '/hmacKeys';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return HmacKey.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an HMAC key.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID owning the requested key
  ///
  /// [accessId] - Name of the HMAC key to be deleted.
  ///
  /// [userProject] - The project to be billed for this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String projectId,
    core.String accessId, {
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/hmacKeys/' +
        commons.escapeVariable('$accessId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves an HMAC key's metadata
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID owning the service account of the requested key.
  ///
  /// [accessId] - Name of the HMAC key.
  ///
  /// [userProject] - The project to be billed for this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [HmacKeyMetadata].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<HmacKeyMetadata> get(
    core.String projectId,
    core.String accessId, {
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/hmacKeys/' +
        commons.escapeVariable('$accessId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return HmacKeyMetadata.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of HMAC keys matching the criteria.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Name of the project in which to look for HMAC keys.
  ///
  /// [maxResults] - Maximum number of items to return in a single page of
  /// responses. The service uses this parameter or 250 items, whichever is
  /// smaller. The max number of items per page will also be limited by the
  /// number of distinct service accounts in the response. If the number of
  /// service accounts in a single response is too high, the page will truncated
  /// and a next page token will be returned.
  ///
  /// [pageToken] - A previously-returned page token representing part of the
  /// larger set of results to view.
  ///
  /// [serviceAccountEmail] - If present, only keys for the given service
  /// account are returned.
  ///
  /// [showDeletedKeys] - Whether or not to show keys in the DELETED state.
  ///
  /// [userProject] - The project to be billed for this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [HmacKeysMetadata].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<HmacKeysMetadata> list(
    core.String projectId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? serviceAccountEmail,
    core.bool? showDeletedKeys,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (serviceAccountEmail != null)
        'serviceAccountEmail': [serviceAccountEmail],
      if (showDeletedKeys != null) 'showDeletedKeys': ['${showDeletedKeys}'],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'projects/' + commons.escapeVariable('$projectId') + '/hmacKeys';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return HmacKeysMetadata.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the state of an HMAC key.
  ///
  /// See the HMAC Key resource descriptor for valid states.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID owning the service account of the updated key.
  ///
  /// [accessId] - Name of the HMAC key being updated.
  ///
  /// [userProject] - The project to be billed for this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [HmacKeyMetadata].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<HmacKeyMetadata> update(
    HmacKeyMetadata request,
    core.String projectId,
    core.String accessId, {
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/hmacKeys/' +
        commons.escapeVariable('$accessId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return HmacKeyMetadata.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsServiceAccountResource {
  final commons.ApiRequester _requester;

  ProjectsServiceAccountResource(commons.ApiRequester client)
      : _requester = client;

  /// Get the email address of this project's Google Cloud Storage service
  /// account.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID
  ///
  /// [provisionalUserProject] - The project to be billed for this request if
  /// the target bucket is requester-pays bucket.
  ///
  /// [userProject] - The project to be billed for this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ServiceAccount].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ServiceAccount> get(
    core.String projectId, {
    core.String? provisionalUserProject,
    core.String? userProject,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (provisionalUserProject != null)
        'provisionalUserProject': [provisionalUserProject],
      if (userProject != null) 'userProject': [userProject],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'projects/' + commons.escapeVariable('$projectId') + '/serviceAccount';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ServiceAccount.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// The bucket's billing configuration.
class BucketBilling {
  /// When set to true, Requester Pays is enabled for this bucket.
  core.bool? requesterPays;

  BucketBilling();

  BucketBilling.fromJson(core.Map _json) {
    if (_json.containsKey('requesterPays')) {
      requesterPays = _json['requesterPays'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requesterPays != null) 'requesterPays': requesterPays!,
      };
}

class BucketCors {
  /// The value, in seconds, to return in the Access-Control-Max-Age header used
  /// in preflight responses.
  core.int? maxAgeSeconds;

  /// The list of HTTP methods on which to include CORS response headers, (GET,
  /// OPTIONS, POST, etc) Note: "*" is permitted in the list of methods, and
  /// means "any method".
  core.List<core.String>? method;

  /// The list of Origins eligible to receive CORS response headers.
  ///
  /// Note: "*" is permitted in the list of origins, and means "any Origin".
  core.List<core.String>? origin;

  /// The list of HTTP headers other than the simple response headers to give
  /// permission for the user-agent to share across domains.
  core.List<core.String>? responseHeader;

  BucketCors();

  BucketCors.fromJson(core.Map _json) {
    if (_json.containsKey('maxAgeSeconds')) {
      maxAgeSeconds = _json['maxAgeSeconds'] as core.int;
    }
    if (_json.containsKey('method')) {
      method = (_json['method'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('origin')) {
      origin = (_json['origin'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('responseHeader')) {
      responseHeader = (_json['responseHeader'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maxAgeSeconds != null) 'maxAgeSeconds': maxAgeSeconds!,
        if (method != null) 'method': method!,
        if (origin != null) 'origin': origin!,
        if (responseHeader != null) 'responseHeader': responseHeader!,
      };
}

/// Encryption configuration for a bucket.
class BucketEncryption {
  /// A Cloud KMS key that will be used to encrypt objects inserted into this
  /// bucket, if no encryption method is specified.
  core.String? defaultKmsKeyName;

  BucketEncryption();

  BucketEncryption.fromJson(core.Map _json) {
    if (_json.containsKey('defaultKmsKeyName')) {
      defaultKmsKeyName = _json['defaultKmsKeyName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultKmsKeyName != null) 'defaultKmsKeyName': defaultKmsKeyName!,
      };
}

/// The bucket's uniform bucket-level access configuration.
///
/// The feature was formerly known as Bucket Policy Only. For backward
/// compatibility, this field will be populated with identical information as
/// the uniformBucketLevelAccess field. We recommend using the
/// uniformBucketLevelAccess field to enable and disable the feature.
class BucketIamConfigurationBucketPolicyOnly {
  /// If set, access is controlled only by bucket-level or above IAM policies.
  core.bool? enabled;

  /// The deadline for changing iamConfiguration.bucketPolicyOnly.enabled from
  /// true to false in RFC 3339 format.
  ///
  /// iamConfiguration.bucketPolicyOnly.enabled may be changed from true to
  /// false until the locked time, after which the field is immutable.
  core.DateTime? lockedTime;

  BucketIamConfigurationBucketPolicyOnly();

  BucketIamConfigurationBucketPolicyOnly.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
    if (_json.containsKey('lockedTime')) {
      lockedTime = core.DateTime.parse(_json['lockedTime'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
        if (lockedTime != null) 'lockedTime': lockedTime!.toIso8601String(),
      };
}

/// The bucket's uniform bucket-level access configuration.
class BucketIamConfigurationUniformBucketLevelAccess {
  /// If set, access is controlled only by bucket-level or above IAM policies.
  core.bool? enabled;

  /// The deadline for changing
  /// iamConfiguration.uniformBucketLevelAccess.enabled from true to false in
  /// RFC 3339 format.
  ///
  /// iamConfiguration.uniformBucketLevelAccess.enabled may be changed from true
  /// to false until the locked time, after which the field is immutable.
  core.DateTime? lockedTime;

  BucketIamConfigurationUniformBucketLevelAccess();

  BucketIamConfigurationUniformBucketLevelAccess.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
    if (_json.containsKey('lockedTime')) {
      lockedTime = core.DateTime.parse(_json['lockedTime'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
        if (lockedTime != null) 'lockedTime': lockedTime!.toIso8601String(),
      };
}

/// The bucket's IAM configuration.
class BucketIamConfiguration {
  /// The bucket's uniform bucket-level access configuration.
  ///
  /// The feature was formerly known as Bucket Policy Only. For backward
  /// compatibility, this field will be populated with identical information as
  /// the uniformBucketLevelAccess field. We recommend using the
  /// uniformBucketLevelAccess field to enable and disable the feature.
  BucketIamConfigurationBucketPolicyOnly? bucketPolicyOnly;

  /// The bucket's Public Access Prevention configuration.
  ///
  /// Currently, 'unspecified' and 'enforced' are supported.
  core.String? publicAccessPrevention;

  /// The bucket's uniform bucket-level access configuration.
  BucketIamConfigurationUniformBucketLevelAccess? uniformBucketLevelAccess;

  BucketIamConfiguration();

  BucketIamConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('bucketPolicyOnly')) {
      bucketPolicyOnly = BucketIamConfigurationBucketPolicyOnly.fromJson(
          _json['bucketPolicyOnly'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('publicAccessPrevention')) {
      publicAccessPrevention = _json['publicAccessPrevention'] as core.String;
    }
    if (_json.containsKey('uniformBucketLevelAccess')) {
      uniformBucketLevelAccess =
          BucketIamConfigurationUniformBucketLevelAccess.fromJson(
              _json['uniformBucketLevelAccess']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bucketPolicyOnly != null)
          'bucketPolicyOnly': bucketPolicyOnly!.toJson(),
        if (publicAccessPrevention != null)
          'publicAccessPrevention': publicAccessPrevention!,
        if (uniformBucketLevelAccess != null)
          'uniformBucketLevelAccess': uniformBucketLevelAccess!.toJson(),
      };
}

/// The action to take.
class BucketLifecycleRuleAction {
  /// Target storage class.
  ///
  /// Required iff the type of the action is SetStorageClass.
  core.String? storageClass;

  /// Type of the action.
  ///
  /// Currently, only Delete and SetStorageClass are supported.
  core.String? type;

  BucketLifecycleRuleAction();

  BucketLifecycleRuleAction.fromJson(core.Map _json) {
    if (_json.containsKey('storageClass')) {
      storageClass = _json['storageClass'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (storageClass != null) 'storageClass': storageClass!,
        if (type != null) 'type': type!,
      };
}

/// The condition(s) under which the action will be taken.
class BucketLifecycleRuleCondition {
  /// Age of an object (in days).
  ///
  /// This condition is satisfied when an object reaches the specified age.
  core.int? age;

  /// A date in RFC 3339 format with only the date part (for instance,
  /// "2013-01-15").
  ///
  /// This condition is satisfied when an object is created before midnight of
  /// the specified date in UTC.
  core.DateTime? createdBefore;

  /// A date in RFC 3339 format with only the date part (for instance,
  /// "2013-01-15").
  ///
  /// This condition is satisfied when the custom time on an object is before
  /// this date in UTC.
  core.DateTime? customTimeBefore;

  /// Number of days elapsed since the user-specified timestamp set on an
  /// object.
  ///
  /// The condition is satisfied if the days elapsed is at least this number. If
  /// no custom timestamp is specified on an object, the condition does not
  /// apply.
  core.int? daysSinceCustomTime;

  /// Number of days elapsed since the noncurrent timestamp of an object.
  ///
  /// The condition is satisfied if the days elapsed is at least this number.
  /// This condition is relevant only for versioned objects. The value of the
  /// field must be a nonnegative integer. If it's zero, the object version will
  /// become eligible for Lifecycle action as soon as it becomes noncurrent.
  core.int? daysSinceNoncurrentTime;

  /// Relevant only for versioned objects.
  ///
  /// If the value is true, this condition matches live objects; if the value is
  /// false, it matches archived objects.
  core.bool? isLive;

  /// A regular expression that satisfies the RE2 syntax.
  ///
  /// This condition is satisfied when the name of the object matches the RE2
  /// pattern. Note: This feature is currently in the "Early Access" launch
  /// stage and is only available to a whitelisted set of users; that means that
  /// this feature may be changed in backward-incompatible ways and that it is
  /// not guaranteed to be released.
  core.String? matchesPattern;

  /// Objects having any of the storage classes specified by this condition will
  /// be matched.
  ///
  /// Values include MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE,
  /// STANDARD, and DURABLE_REDUCED_AVAILABILITY.
  core.List<core.String>? matchesStorageClass;

  /// A date in RFC 3339 format with only the date part (for instance,
  /// "2013-01-15").
  ///
  /// This condition is satisfied when the noncurrent time on an object is
  /// before this date in UTC. This condition is relevant only for versioned
  /// objects.
  core.DateTime? noncurrentTimeBefore;

  /// Relevant only for versioned objects.
  ///
  /// If the value is N, this condition is satisfied when there are at least N
  /// versions (including the live version) newer than this version of the
  /// object.
  core.int? numNewerVersions;

  BucketLifecycleRuleCondition();

  BucketLifecycleRuleCondition.fromJson(core.Map _json) {
    if (_json.containsKey('age')) {
      age = _json['age'] as core.int;
    }
    if (_json.containsKey('createdBefore')) {
      createdBefore =
          core.DateTime.parse(_json['createdBefore'] as core.String);
    }
    if (_json.containsKey('customTimeBefore')) {
      customTimeBefore =
          core.DateTime.parse(_json['customTimeBefore'] as core.String);
    }
    if (_json.containsKey('daysSinceCustomTime')) {
      daysSinceCustomTime = _json['daysSinceCustomTime'] as core.int;
    }
    if (_json.containsKey('daysSinceNoncurrentTime')) {
      daysSinceNoncurrentTime = _json['daysSinceNoncurrentTime'] as core.int;
    }
    if (_json.containsKey('isLive')) {
      isLive = _json['isLive'] as core.bool;
    }
    if (_json.containsKey('matchesPattern')) {
      matchesPattern = _json['matchesPattern'] as core.String;
    }
    if (_json.containsKey('matchesStorageClass')) {
      matchesStorageClass = (_json['matchesStorageClass'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('noncurrentTimeBefore')) {
      noncurrentTimeBefore =
          core.DateTime.parse(_json['noncurrentTimeBefore'] as core.String);
    }
    if (_json.containsKey('numNewerVersions')) {
      numNewerVersions = _json['numNewerVersions'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (age != null) 'age': age!,
        if (createdBefore != null)
          'createdBefore':
              "${(createdBefore!).year.toString().padLeft(4, '0')}-${(createdBefore!).month.toString().padLeft(2, '0')}-${(createdBefore!).day.toString().padLeft(2, '0')}",
        if (customTimeBefore != null)
          'customTimeBefore':
              "${(customTimeBefore!).year.toString().padLeft(4, '0')}-${(customTimeBefore!).month.toString().padLeft(2, '0')}-${(customTimeBefore!).day.toString().padLeft(2, '0')}",
        if (daysSinceCustomTime != null)
          'daysSinceCustomTime': daysSinceCustomTime!,
        if (daysSinceNoncurrentTime != null)
          'daysSinceNoncurrentTime': daysSinceNoncurrentTime!,
        if (isLive != null) 'isLive': isLive!,
        if (matchesPattern != null) 'matchesPattern': matchesPattern!,
        if (matchesStorageClass != null)
          'matchesStorageClass': matchesStorageClass!,
        if (noncurrentTimeBefore != null)
          'noncurrentTimeBefore':
              "${(noncurrentTimeBefore!).year.toString().padLeft(4, '0')}-${(noncurrentTimeBefore!).month.toString().padLeft(2, '0')}-${(noncurrentTimeBefore!).day.toString().padLeft(2, '0')}",
        if (numNewerVersions != null) 'numNewerVersions': numNewerVersions!,
      };
}

class BucketLifecycleRule {
  /// The action to take.
  BucketLifecycleRuleAction? action;

  /// The condition(s) under which the action will be taken.
  BucketLifecycleRuleCondition? condition;

  BucketLifecycleRule();

  BucketLifecycleRule.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = BucketLifecycleRuleAction.fromJson(
          _json['action'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('condition')) {
      condition = BucketLifecycleRuleCondition.fromJson(
          _json['condition'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!.toJson(),
        if (condition != null) 'condition': condition!.toJson(),
      };
}

/// The bucket's lifecycle configuration.
///
/// See lifecycle management for more information.
class BucketLifecycle {
  /// A lifecycle management rule, which is made of an action to take and the
  /// condition(s) under which the action will be taken.
  core.List<BucketLifecycleRule>? rule;

  BucketLifecycle();

  BucketLifecycle.fromJson(core.Map _json) {
    if (_json.containsKey('rule')) {
      rule = (_json['rule'] as core.List)
          .map<BucketLifecycleRule>((value) => BucketLifecycleRule.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rule != null) 'rule': rule!.map((value) => value.toJson()).toList(),
      };
}

/// The bucket's logging configuration, which defines the destination bucket and
/// optional name prefix for the current bucket's logs.
class BucketLogging {
  /// The destination bucket where the current bucket's logs should be placed.
  core.String? logBucket;

  /// A prefix for log object names.
  core.String? logObjectPrefix;

  BucketLogging();

  BucketLogging.fromJson(core.Map _json) {
    if (_json.containsKey('logBucket')) {
      logBucket = _json['logBucket'] as core.String;
    }
    if (_json.containsKey('logObjectPrefix')) {
      logObjectPrefix = _json['logObjectPrefix'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (logBucket != null) 'logBucket': logBucket!,
        if (logObjectPrefix != null) 'logObjectPrefix': logObjectPrefix!,
      };
}

/// The owner of the bucket.
///
/// This is always the project team's owner group.
class BucketOwner {
  /// The entity, in the form project-owner-projectId.
  core.String? entity;

  /// The ID for the entity.
  core.String? entityId;

  BucketOwner();

  BucketOwner.fromJson(core.Map _json) {
    if (_json.containsKey('entity')) {
      entity = _json['entity'] as core.String;
    }
    if (_json.containsKey('entityId')) {
      entityId = _json['entityId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entity != null) 'entity': entity!,
        if (entityId != null) 'entityId': entityId!,
      };
}

/// The bucket's retention policy.
///
/// The retention policy enforces a minimum retention time for all objects
/// contained in the bucket, based on their creation time. Any attempt to
/// overwrite or delete objects younger than the retention period will result in
/// a PERMISSION_DENIED error. An unlocked retention policy can be modified or
/// removed from the bucket via a storage.buckets.update operation. A locked
/// retention policy cannot be removed or shortened in duration for the lifetime
/// of the bucket. Attempting to remove or decrease period of a locked retention
/// policy will result in a PERMISSION_DENIED error.
class BucketRetentionPolicy {
  /// Server-determined value that indicates the time from which policy was
  /// enforced and effective.
  ///
  /// This value is in RFC 3339 format.
  core.DateTime? effectiveTime;

  /// Once locked, an object retention policy cannot be modified.
  core.bool? isLocked;

  /// The duration in seconds that objects need to be retained.
  ///
  /// Retention duration must be greater than zero and less than 100 years. Note
  /// that enforcement of retention periods less than a day is not guaranteed.
  /// Such periods should only be used for testing purposes.
  core.String? retentionPeriod;

  BucketRetentionPolicy();

  BucketRetentionPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('effectiveTime')) {
      effectiveTime =
          core.DateTime.parse(_json['effectiveTime'] as core.String);
    }
    if (_json.containsKey('isLocked')) {
      isLocked = _json['isLocked'] as core.bool;
    }
    if (_json.containsKey('retentionPeriod')) {
      retentionPeriod = _json['retentionPeriod'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (effectiveTime != null)
          'effectiveTime': effectiveTime!.toIso8601String(),
        if (isLocked != null) 'isLocked': isLocked!,
        if (retentionPeriod != null) 'retentionPeriod': retentionPeriod!,
      };
}

/// The bucket's versioning configuration.
class BucketVersioning {
  /// While set to true, versioning is fully enabled for this bucket.
  core.bool? enabled;

  BucketVersioning();

  BucketVersioning.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// The bucket's website configuration, controlling how the service behaves when
/// accessing bucket contents as a web site.
///
/// See the Static Website Examples for more information.
class BucketWebsite {
  /// If the requested object path is missing, the service will ensure the path
  /// has a trailing '/', append this suffix, and attempt to retrieve the
  /// resulting object.
  ///
  /// This allows the creation of index.html objects to represent directory
  /// pages.
  core.String? mainPageSuffix;

  /// If the requested object path is missing, and any mainPageSuffix object is
  /// missing, if applicable, the service will return the named object from this
  /// bucket as the content for a 404 Not Found result.
  core.String? notFoundPage;

  BucketWebsite();

  BucketWebsite.fromJson(core.Map _json) {
    if (_json.containsKey('mainPageSuffix')) {
      mainPageSuffix = _json['mainPageSuffix'] as core.String;
    }
    if (_json.containsKey('notFoundPage')) {
      notFoundPage = _json['notFoundPage'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mainPageSuffix != null) 'mainPageSuffix': mainPageSuffix!,
        if (notFoundPage != null) 'notFoundPage': notFoundPage!,
      };
}

/// A bucket.
class Bucket {
  /// Access controls on the bucket.
  core.List<BucketAccessControl>? acl;

  /// The bucket's billing configuration.
  BucketBilling? billing;

  /// The bucket's Cross-Origin Resource Sharing (CORS) configuration.
  core.List<BucketCors>? cors;

  /// The default value for event-based hold on newly created objects in this
  /// bucket.
  ///
  /// Event-based hold is a way to retain objects indefinitely until an event
  /// occurs, signified by the hold's release. After being released, such
  /// objects will be subject to bucket-level retention (if any). One sample use
  /// case of this flag is for banks to hold loan documents for at least 3 years
  /// after loan is paid in full. Here, bucket-level retention is 3 years and
  /// the event is loan being paid in full. In this example, these objects will
  /// be held intact for any number of years until the event has occurred
  /// (event-based hold on the object is released) and then 3 more years after
  /// that. That means retention duration of the objects begins from the moment
  /// event-based hold transitioned from true to false. Objects under
  /// event-based hold cannot be deleted, overwritten or archived until the hold
  /// is removed.
  core.bool? defaultEventBasedHold;

  /// Default access controls to apply to new objects when no ACL is provided.
  core.List<ObjectAccessControl>? defaultObjectAcl;

  /// Encryption configuration for a bucket.
  BucketEncryption? encryption;

  /// HTTP 1.1 Entity tag for the bucket.
  core.String? etag;

  /// The bucket's IAM configuration.
  BucketIamConfiguration? iamConfiguration;

  /// The ID of the bucket.
  ///
  /// For buckets, the id and name properties are the same.
  core.String? id;

  /// The kind of item this is.
  ///
  /// For buckets, this is always storage#bucket.
  core.String? kind;

  /// User-provided labels, in key/value pairs.
  core.Map<core.String, core.String>? labels;

  /// The bucket's lifecycle configuration.
  ///
  /// See lifecycle management for more information.
  BucketLifecycle? lifecycle;

  /// The location of the bucket.
  ///
  /// Object data for objects in the bucket resides in physical storage within
  /// this region. Defaults to US. See the developer's guide for the
  /// authoritative list.
  core.String? location;

  /// The type of the bucket location.
  core.String? locationType;

  /// The bucket's logging configuration, which defines the destination bucket
  /// and optional name prefix for the current bucket's logs.
  BucketLogging? logging;

  /// The metadata generation of this bucket.
  core.String? metageneration;

  /// The name of the bucket.
  core.String? name;

  /// The owner of the bucket.
  ///
  /// This is always the project team's owner group.
  BucketOwner? owner;

  /// The project number of the project the bucket belongs to.
  core.String? projectNumber;

  /// The bucket's retention policy.
  ///
  /// The retention policy enforces a minimum retention time for all objects
  /// contained in the bucket, based on their creation time. Any attempt to
  /// overwrite or delete objects younger than the retention period will result
  /// in a PERMISSION_DENIED error. An unlocked retention policy can be modified
  /// or removed from the bucket via a storage.buckets.update operation. A
  /// locked retention policy cannot be removed or shortened in duration for the
  /// lifetime of the bucket. Attempting to remove or decrease period of a
  /// locked retention policy will result in a PERMISSION_DENIED error.
  BucketRetentionPolicy? retentionPolicy;

  /// Reserved for future use.
  core.bool? satisfiesPZS;

  /// The URI of this bucket.
  core.String? selfLink;

  /// The bucket's default storage class, used whenever no storageClass is
  /// specified for a newly-created object.
  ///
  /// This defines how objects in the bucket are stored and determines the SLA
  /// and the cost of storage. Values include MULTI_REGIONAL, REGIONAL,
  /// STANDARD, NEARLINE, COLDLINE, ARCHIVE, and DURABLE_REDUCED_AVAILABILITY.
  /// If this value is not specified when the bucket is created, it will default
  /// to STANDARD. For more information, see storage classes.
  core.String? storageClass;

  /// The creation time of the bucket in RFC 3339 format.
  core.DateTime? timeCreated;

  /// The modification time of the bucket in RFC 3339 format.
  core.DateTime? updated;

  /// The bucket's versioning configuration.
  BucketVersioning? versioning;

  /// The bucket's website configuration, controlling how the service behaves
  /// when accessing bucket contents as a web site.
  ///
  /// See the Static Website Examples for more information.
  BucketWebsite? website;

  /// The zone or zones from which the bucket is intended to use zonal quota.
  ///
  /// Requests for data from outside the specified affinities are still allowed
  /// but won't be able to use zonal quota. The zone or zones need to be within
  /// the bucket location otherwise the requests will fail with a 400 Bad
  /// Request response.
  core.List<core.String>? zoneAffinity;

  Bucket();

  Bucket.fromJson(core.Map _json) {
    if (_json.containsKey('acl')) {
      acl = (_json['acl'] as core.List)
          .map<BucketAccessControl>((value) => BucketAccessControl.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('billing')) {
      billing = BucketBilling.fromJson(
          _json['billing'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('cors')) {
      cors = (_json['cors'] as core.List)
          .map<BucketCors>((value) =>
              BucketCors.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('defaultEventBasedHold')) {
      defaultEventBasedHold = _json['defaultEventBasedHold'] as core.bool;
    }
    if (_json.containsKey('defaultObjectAcl')) {
      defaultObjectAcl = (_json['defaultObjectAcl'] as core.List)
          .map<ObjectAccessControl>((value) => ObjectAccessControl.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('encryption')) {
      encryption = BucketEncryption.fromJson(
          _json['encryption'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('iamConfiguration')) {
      iamConfiguration = BucketIamConfiguration.fromJson(
          _json['iamConfiguration'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('lifecycle')) {
      lifecycle = BucketLifecycle.fromJson(
          _json['lifecycle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('locationType')) {
      locationType = _json['locationType'] as core.String;
    }
    if (_json.containsKey('logging')) {
      logging = BucketLogging.fromJson(
          _json['logging'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metageneration')) {
      metageneration = _json['metageneration'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('owner')) {
      owner = BucketOwner.fromJson(
          _json['owner'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('projectNumber')) {
      projectNumber = _json['projectNumber'] as core.String;
    }
    if (_json.containsKey('retentionPolicy')) {
      retentionPolicy = BucketRetentionPolicy.fromJson(
          _json['retentionPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('satisfiesPZS')) {
      satisfiesPZS = _json['satisfiesPZS'] as core.bool;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('storageClass')) {
      storageClass = _json['storageClass'] as core.String;
    }
    if (_json.containsKey('timeCreated')) {
      timeCreated = core.DateTime.parse(_json['timeCreated'] as core.String);
    }
    if (_json.containsKey('updated')) {
      updated = core.DateTime.parse(_json['updated'] as core.String);
    }
    if (_json.containsKey('versioning')) {
      versioning = BucketVersioning.fromJson(
          _json['versioning'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('website')) {
      website = BucketWebsite.fromJson(
          _json['website'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('zoneAffinity')) {
      zoneAffinity = (_json['zoneAffinity'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (acl != null) 'acl': acl!.map((value) => value.toJson()).toList(),
        if (billing != null) 'billing': billing!.toJson(),
        if (cors != null) 'cors': cors!.map((value) => value.toJson()).toList(),
        if (defaultEventBasedHold != null)
          'defaultEventBasedHold': defaultEventBasedHold!,
        if (defaultObjectAcl != null)
          'defaultObjectAcl':
              defaultObjectAcl!.map((value) => value.toJson()).toList(),
        if (encryption != null) 'encryption': encryption!.toJson(),
        if (etag != null) 'etag': etag!,
        if (iamConfiguration != null)
          'iamConfiguration': iamConfiguration!.toJson(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (labels != null) 'labels': labels!,
        if (lifecycle != null) 'lifecycle': lifecycle!.toJson(),
        if (location != null) 'location': location!,
        if (locationType != null) 'locationType': locationType!,
        if (logging != null) 'logging': logging!.toJson(),
        if (metageneration != null) 'metageneration': metageneration!,
        if (name != null) 'name': name!,
        if (owner != null) 'owner': owner!.toJson(),
        if (projectNumber != null) 'projectNumber': projectNumber!,
        if (retentionPolicy != null)
          'retentionPolicy': retentionPolicy!.toJson(),
        if (satisfiesPZS != null) 'satisfiesPZS': satisfiesPZS!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (storageClass != null) 'storageClass': storageClass!,
        if (timeCreated != null) 'timeCreated': timeCreated!.toIso8601String(),
        if (updated != null) 'updated': updated!.toIso8601String(),
        if (versioning != null) 'versioning': versioning!.toJson(),
        if (website != null) 'website': website!.toJson(),
        if (zoneAffinity != null) 'zoneAffinity': zoneAffinity!,
      };
}

/// The project team associated with the entity, if any.
class BucketAccessControlProjectTeam {
  /// The project number.
  core.String? projectNumber;

  /// The team.
  core.String? team;

  BucketAccessControlProjectTeam();

  BucketAccessControlProjectTeam.fromJson(core.Map _json) {
    if (_json.containsKey('projectNumber')) {
      projectNumber = _json['projectNumber'] as core.String;
    }
    if (_json.containsKey('team')) {
      team = _json['team'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (projectNumber != null) 'projectNumber': projectNumber!,
        if (team != null) 'team': team!,
      };
}

/// An access-control entry.
class BucketAccessControl {
  /// The name of the bucket.
  core.String? bucket;

  /// The domain associated with the entity, if any.
  core.String? domain;

  /// The email address associated with the entity, if any.
  core.String? email;

  /// The entity holding the permission, in one of the following forms:
  /// - user-userId
  /// - user-email
  /// - group-groupId
  /// - group-email
  /// - domain-domain
  /// - project-team-projectId
  /// - allUsers
  /// - allAuthenticatedUsers Examples:
  /// - The user liz@example.com would be user-liz@example.com.
  ///
  ///
  /// - The group example@googlegroups.com would be
  /// group-example@googlegroups.com.
  /// - To refer to all members of the Google Apps for Business domain
  /// example.com, the entity would be domain-example.com.
  core.String? entity;

  /// The ID for the entity, if any.
  core.String? entityId;

  /// HTTP 1.1 Entity tag for the access-control entry.
  core.String? etag;

  /// The ID of the access-control entry.
  core.String? id;

  /// The kind of item this is.
  ///
  /// For bucket access control entries, this is always
  /// storage#bucketAccessControl.
  core.String? kind;

  /// The project team associated with the entity, if any.
  BucketAccessControlProjectTeam? projectTeam;

  /// The access permission for the entity.
  core.String? role;

  /// The link to this access-control entry.
  core.String? selfLink;

  BucketAccessControl();

  BucketAccessControl.fromJson(core.Map _json) {
    if (_json.containsKey('bucket')) {
      bucket = _json['bucket'] as core.String;
    }
    if (_json.containsKey('domain')) {
      domain = _json['domain'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('entity')) {
      entity = _json['entity'] as core.String;
    }
    if (_json.containsKey('entityId')) {
      entityId = _json['entityId'] as core.String;
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
    if (_json.containsKey('projectTeam')) {
      projectTeam = BucketAccessControlProjectTeam.fromJson(
          _json['projectTeam'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bucket != null) 'bucket': bucket!,
        if (domain != null) 'domain': domain!,
        if (email != null) 'email': email!,
        if (entity != null) 'entity': entity!,
        if (entityId != null) 'entityId': entityId!,
        if (etag != null) 'etag': etag!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (projectTeam != null) 'projectTeam': projectTeam!.toJson(),
        if (role != null) 'role': role!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// An access-control list.
class BucketAccessControls {
  /// The list of items.
  core.List<BucketAccessControl>? items;

  /// The kind of item this is.
  ///
  /// For lists of bucket access control entries, this is always
  /// storage#bucketAccessControls.
  core.String? kind;

  BucketAccessControls();

  BucketAccessControls.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<BucketAccessControl>((value) => BucketAccessControl.fromJson(
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

/// A list of buckets.
class Buckets {
  /// The list of items.
  core.List<Bucket>? items;

  /// The kind of item this is.
  ///
  /// For lists of buckets, this is always storage#buckets.
  core.String? kind;

  /// The continuation token, used to page through large result sets.
  ///
  /// Provide this value in a subsequent request to return the next page of
  /// results.
  core.String? nextPageToken;

  Buckets();

  Buckets.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Bucket>((value) =>
              Bucket.fromJson(value as core.Map<core.String, core.dynamic>))
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

/// An notification channel used to watch for resource changes.
class Channel {
  /// The address where notifications are delivered for this channel.
  core.String? address;

  /// Date and time of notification channel expiration, expressed as a Unix
  /// timestamp, in milliseconds.
  ///
  /// Optional.
  core.String? expiration;

  /// A UUID or similar unique string that identifies this channel.
  core.String? id;

  /// Identifies this as a notification channel used to watch for changes to a
  /// resource, which is "api#channel".
  core.String? kind;

  /// Additional parameters controlling delivery channel behavior.
  ///
  /// Optional.
  core.Map<core.String, core.String>? params;

  /// A Boolean value to indicate whether payload is wanted.
  ///
  /// Optional.
  core.bool? payload;

  /// An opaque ID that identifies the resource being watched on this channel.
  ///
  /// Stable across different API versions.
  core.String? resourceId;

  /// A version-specific identifier for the watched resource.
  core.String? resourceUri;

  /// An arbitrary string delivered to the target address with each notification
  /// delivered over this channel.
  ///
  /// Optional.
  core.String? token;

  /// The type of delivery mechanism used for this channel.
  core.String? type;

  Channel();

  Channel.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = _json['address'] as core.String;
    }
    if (_json.containsKey('expiration')) {
      expiration = _json['expiration'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('params')) {
      params = (_json['params'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('payload')) {
      payload = _json['payload'] as core.bool;
    }
    if (_json.containsKey('resourceId')) {
      resourceId = _json['resourceId'] as core.String;
    }
    if (_json.containsKey('resourceUri')) {
      resourceUri = _json['resourceUri'] as core.String;
    }
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!,
        if (expiration != null) 'expiration': expiration!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (params != null) 'params': params!,
        if (payload != null) 'payload': payload!,
        if (resourceId != null) 'resourceId': resourceId!,
        if (resourceUri != null) 'resourceUri': resourceUri!,
        if (token != null) 'token': token!,
        if (type != null) 'type': type!,
      };
}

/// Conditions that must be met for this operation to execute.
class ComposeRequestSourceObjectsObjectPreconditions {
  /// Only perform the composition if the generation of the source object that
  /// would be used matches this value.
  ///
  /// If this value and a generation are both specified, they must be the same
  /// value or the call will fail.
  core.String? ifGenerationMatch;

  ComposeRequestSourceObjectsObjectPreconditions();

  ComposeRequestSourceObjectsObjectPreconditions.fromJson(core.Map _json) {
    if (_json.containsKey('ifGenerationMatch')) {
      ifGenerationMatch = _json['ifGenerationMatch'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ifGenerationMatch != null) 'ifGenerationMatch': ifGenerationMatch!,
      };
}

class ComposeRequestSourceObjects {
  /// The generation of this object to use as the source.
  core.String? generation;

  /// The source object's name.
  ///
  /// All source objects must reside in the same bucket.
  core.String? name;

  /// Conditions that must be met for this operation to execute.
  ComposeRequestSourceObjectsObjectPreconditions? objectPreconditions;

  ComposeRequestSourceObjects();

  ComposeRequestSourceObjects.fromJson(core.Map _json) {
    if (_json.containsKey('generation')) {
      generation = _json['generation'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('objectPreconditions')) {
      objectPreconditions =
          ComposeRequestSourceObjectsObjectPreconditions.fromJson(
              _json['objectPreconditions']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (generation != null) 'generation': generation!,
        if (name != null) 'name': name!,
        if (objectPreconditions != null)
          'objectPreconditions': objectPreconditions!.toJson(),
      };
}

/// A Compose request.
class ComposeRequest {
  /// Properties of the resulting object.
  Object? destination;

  /// The kind of item this is.
  core.String? kind;

  /// The list of source objects that will be concatenated into a single object.
  core.List<ComposeRequestSourceObjects>? sourceObjects;

  ComposeRequest();

  ComposeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('destination')) {
      destination = Object.fromJson(
          _json['destination'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('sourceObjects')) {
      sourceObjects = (_json['sourceObjects'] as core.List)
          .map<ComposeRequestSourceObjects>((value) =>
              ComposeRequestSourceObjects.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destination != null) 'destination': destination!.toJson(),
        if (kind != null) 'kind': kind!,
        if (sourceObjects != null)
          'sourceObjects':
              sourceObjects!.map((value) => value.toJson()).toList(),
      };
}

/// Represents an expression text.
///
/// Example: title: "User account presence" description: "Determines whether the
/// request has a user account" expression: "size(request.user) > 0"
class Expr {
  /// An optional description of the expression.
  ///
  /// This is a longer text which describes the expression, e.g. when hovered
  /// over it in a UI.
  core.String? description;

  /// Textual representation of an expression in Common Expression Language
  /// syntax.
  ///
  /// The application context of the containing message determines which
  /// well-known feature set of CEL is supported.
  core.String? expression;

  /// An optional string indicating the location of the expression for error
  /// reporting, e.g. a file name and a position in the file.
  core.String? location;

  /// An optional title for the expression, i.e. a short string describing its
  /// purpose.
  ///
  /// This can be used e.g. in UIs which allow to enter the expression.
  core.String? title;

  Expr();

  Expr.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('expression')) {
      expression = _json['expression'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (expression != null) 'expression': expression!,
        if (location != null) 'location': location!,
        if (title != null) 'title': title!,
      };
}

/// JSON template to produce a JSON-style HMAC Key resource for Create
/// responses.
class HmacKey {
  /// The kind of item this is.
  ///
  /// For HMAC keys, this is always storage#hmacKey.
  core.String? kind;

  /// Key metadata.
  HmacKeyMetadata? metadata;

  /// HMAC secret key material.
  core.String? secret;

  HmacKey();

  HmacKey.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = HmacKeyMetadata.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('secret')) {
      secret = _json['secret'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (secret != null) 'secret': secret!,
      };
}

/// JSON template to produce a JSON-style HMAC Key metadata resource.
class HmacKeyMetadata {
  /// The ID of the HMAC Key.
  core.String? accessId;

  /// HTTP 1.1 Entity tag for the HMAC key.
  core.String? etag;

  /// The ID of the HMAC key, including the Project ID and the Access ID.
  core.String? id;

  /// The kind of item this is.
  ///
  /// For HMAC Key metadata, this is always storage#hmacKeyMetadata.
  core.String? kind;

  /// Project ID owning the service account to which the key authenticates.
  core.String? projectId;

  /// The link to this resource.
  core.String? selfLink;

  /// The email address of the key's associated service account.
  core.String? serviceAccountEmail;

  /// The state of the key.
  ///
  /// Can be one of ACTIVE, INACTIVE, or DELETED.
  core.String? state;

  /// The creation time of the HMAC key in RFC 3339 format.
  core.DateTime? timeCreated;

  /// The last modification time of the HMAC key metadata in RFC 3339 format.
  core.DateTime? updated;

  HmacKeyMetadata();

  HmacKeyMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('accessId')) {
      accessId = _json['accessId'] as core.String;
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
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('serviceAccountEmail')) {
      serviceAccountEmail = _json['serviceAccountEmail'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('timeCreated')) {
      timeCreated = core.DateTime.parse(_json['timeCreated'] as core.String);
    }
    if (_json.containsKey('updated')) {
      updated = core.DateTime.parse(_json['updated'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessId != null) 'accessId': accessId!,
        if (etag != null) 'etag': etag!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (projectId != null) 'projectId': projectId!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (serviceAccountEmail != null)
          'serviceAccountEmail': serviceAccountEmail!,
        if (state != null) 'state': state!,
        if (timeCreated != null) 'timeCreated': timeCreated!.toIso8601String(),
        if (updated != null) 'updated': updated!.toIso8601String(),
      };
}

/// A list of hmacKeys.
class HmacKeysMetadata {
  /// The list of items.
  core.List<HmacKeyMetadata>? items;

  /// The kind of item this is.
  ///
  /// For lists of hmacKeys, this is always storage#hmacKeysMetadata.
  core.String? kind;

  /// The continuation token, used to page through large result sets.
  ///
  /// Provide this value in a subsequent request to return the next page of
  /// results.
  core.String? nextPageToken;

  HmacKeysMetadata();

  HmacKeysMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<HmacKeyMetadata>((value) => HmacKeyMetadata.fromJson(
              value as core.Map<core.String, core.dynamic>))
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

/// A subscription to receive Google PubSub notifications.
class Notification {
  /// An optional list of additional attributes to attach to each Cloud PubSub
  /// message published for this notification subscription.
  core.Map<core.String, core.String>? customAttributes;

  /// HTTP 1.1 Entity tag for this subscription notification.
  core.String? etag;

  /// If present, only send notifications about listed event types.
  ///
  /// If empty, sent notifications for all event types.
  core.List<core.String>? eventTypes;

  /// The ID of the notification.
  core.String? id;

  /// The kind of item this is.
  ///
  /// For notifications, this is always storage#notification.
  core.String? kind;

  /// If present, only apply this notification configuration to object names
  /// that begin with this prefix.
  core.String? objectNamePrefix;

  /// The desired content of the Payload.
  core.String? payloadFormat;

  /// The canonical URL of this notification.
  core.String? selfLink;

  /// The Cloud PubSub topic to which this subscription publishes.
  ///
  /// Formatted as:
  /// '//pubsub.googleapis.com/projects/{project-identifier}/topics/{my-topic}'
  core.String? topic;

  Notification();

  Notification.fromJson(core.Map _json) {
    if (_json.containsKey('custom_attributes')) {
      customAttributes =
          (_json['custom_attributes'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('event_types')) {
      eventTypes = (_json['event_types'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('object_name_prefix')) {
      objectNamePrefix = _json['object_name_prefix'] as core.String;
    }
    if (_json.containsKey('payload_format')) {
      payloadFormat = _json['payload_format'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('topic')) {
      topic = _json['topic'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customAttributes != null) 'custom_attributes': customAttributes!,
        if (etag != null) 'etag': etag!,
        if (eventTypes != null) 'event_types': eventTypes!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (objectNamePrefix != null) 'object_name_prefix': objectNamePrefix!,
        if (payloadFormat != null) 'payload_format': payloadFormat!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (topic != null) 'topic': topic!,
      };
}

/// A list of notification subscriptions.
class Notifications {
  /// The list of items.
  core.List<Notification>? items;

  /// The kind of item this is.
  ///
  /// For lists of notifications, this is always storage#notifications.
  core.String? kind;

  Notifications();

  Notifications.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Notification>((value) => Notification.fromJson(
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

/// Metadata of customer-supplied encryption key, if the object is encrypted by
/// such a key.
class ObjectCustomerEncryption {
  /// The encryption algorithm.
  core.String? encryptionAlgorithm;

  /// SHA256 hash value of the encryption key.
  core.String? keySha256;

  ObjectCustomerEncryption();

  ObjectCustomerEncryption.fromJson(core.Map _json) {
    if (_json.containsKey('encryptionAlgorithm')) {
      encryptionAlgorithm = _json['encryptionAlgorithm'] as core.String;
    }
    if (_json.containsKey('keySha256')) {
      keySha256 = _json['keySha256'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (encryptionAlgorithm != null)
          'encryptionAlgorithm': encryptionAlgorithm!,
        if (keySha256 != null) 'keySha256': keySha256!,
      };
}

/// The owner of the object.
///
/// This will always be the uploader of the object.
class ObjectOwner {
  /// The entity, in the form user-userId.
  core.String? entity;

  /// The ID for the entity.
  core.String? entityId;

  ObjectOwner();

  ObjectOwner.fromJson(core.Map _json) {
    if (_json.containsKey('entity')) {
      entity = _json['entity'] as core.String;
    }
    if (_json.containsKey('entityId')) {
      entityId = _json['entityId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entity != null) 'entity': entity!,
        if (entityId != null) 'entityId': entityId!,
      };
}

/// An object.
class Object {
  /// Access controls on the object.
  core.List<ObjectAccessControl>? acl;

  /// The name of the bucket containing this object.
  core.String? bucket;

  /// Cache-Control directive for the object data.
  ///
  /// If omitted, and the object is accessible to all anonymous users, the
  /// default will be public, max-age=3600.
  core.String? cacheControl;

  /// Number of underlying components that make up this object.
  ///
  /// Components are accumulated by compose operations.
  core.int? componentCount;

  /// Content-Disposition of the object data.
  core.String? contentDisposition;

  /// Content-Encoding of the object data.
  core.String? contentEncoding;

  /// Content-Language of the object data.
  core.String? contentLanguage;

  /// Content-Type of the object data.
  ///
  /// If an object is stored without a Content-Type, it is served as
  /// application/octet-stream.
  core.String? contentType;

  /// CRC32c checksum, as described in RFC 4960, Appendix B; encoded using
  /// base64 in big-endian byte order.
  ///
  /// For more information about using the CRC32c checksum, see Hashes and
  /// ETags: Best Practices.
  core.String? crc32c;

  /// A timestamp in RFC 3339 format specified by the user for an object.
  core.DateTime? customTime;

  /// Metadata of customer-supplied encryption key, if the object is encrypted
  /// by such a key.
  ObjectCustomerEncryption? customerEncryption;

  /// HTTP 1.1 Entity tag for the object.
  core.String? etag;

  /// Whether an object is under event-based hold.
  ///
  /// Event-based hold is a way to retain objects until an event occurs, which
  /// is signified by the hold's release (i.e. this value is set to false).
  /// After being released (set to false), such objects will be subject to
  /// bucket-level retention (if any). One sample use case of this flag is for
  /// banks to hold loan documents for at least 3 years after loan is paid in
  /// full. Here, bucket-level retention is 3 years and the event is the loan
  /// being paid in full. In this example, these objects will be held intact for
  /// any number of years until the event has occurred (event-based hold on the
  /// object is released) and then 3 more years after that. That means retention
  /// duration of the objects begins from the moment event-based hold
  /// transitioned from true to false.
  core.bool? eventBasedHold;

  /// The content generation of this object.
  ///
  /// Used for object versioning.
  core.String? generation;

  /// The ID of the object, including the bucket name, object name, and
  /// generation number.
  core.String? id;

  /// The kind of item this is.
  ///
  /// For objects, this is always storage#object.
  core.String? kind;

  /// Not currently supported.
  ///
  /// Specifying the parameter causes the request to fail with status code 400 -
  /// Bad Request.
  core.String? kmsKeyName;

  /// MD5 hash of the data; encoded using base64.
  ///
  /// For more information about using the MD5 hash, see Hashes and ETags: Best
  /// Practices.
  core.String? md5Hash;

  /// Media download link.
  core.String? mediaLink;

  /// User-provided metadata, in key/value pairs.
  core.Map<core.String, core.String>? metadata;

  /// The version of the metadata for this object at this generation.
  ///
  /// Used for preconditions and for detecting changes in metadata. A
  /// metageneration number is only meaningful in the context of a particular
  /// generation of a particular object.
  core.String? metageneration;

  /// The name of the object.
  ///
  /// Required if not specified by URL parameter.
  core.String? name;

  /// The owner of the object.
  ///
  /// This will always be the uploader of the object.
  ObjectOwner? owner;

  /// A server-determined value that specifies the earliest time that the
  /// object's retention period expires.
  ///
  /// This value is in RFC 3339 format. Note 1: This field is not provided for
  /// objects with an active event-based hold, since retention expiration is
  /// unknown until the hold is removed. Note 2: This value can be provided even
  /// when temporary hold is set (so that the user can reason about policy
  /// without having to first unset the temporary hold).
  core.DateTime? retentionExpirationTime;

  /// The link to this object.
  core.String? selfLink;

  /// Content-Length of the data in bytes.
  core.String? size;

  /// Storage class of the object.
  core.String? storageClass;

  /// Whether an object is under temporary hold.
  ///
  /// While this flag is set to true, the object is protected against deletion
  /// and overwrites. A common use case of this flag is regulatory
  /// investigations where objects need to be retained while the investigation
  /// is ongoing. Note that unlike event-based hold, temporary hold does not
  /// impact retention expiration time of an object.
  core.bool? temporaryHold;

  /// The creation time of the object in RFC 3339 format.
  core.DateTime? timeCreated;

  /// The deletion time of the object in RFC 3339 format.
  ///
  /// Will be returned if and only if this version of the object has been
  /// deleted.
  core.DateTime? timeDeleted;

  /// The time at which the object's storage class was last changed.
  ///
  /// When the object is initially created, it will be set to timeCreated.
  core.DateTime? timeStorageClassUpdated;

  /// The modification time of the object metadata in RFC 3339 format.
  core.DateTime? updated;

  Object();

  Object.fromJson(core.Map _json) {
    if (_json.containsKey('acl')) {
      acl = (_json['acl'] as core.List)
          .map<ObjectAccessControl>((value) => ObjectAccessControl.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('bucket')) {
      bucket = _json['bucket'] as core.String;
    }
    if (_json.containsKey('cacheControl')) {
      cacheControl = _json['cacheControl'] as core.String;
    }
    if (_json.containsKey('componentCount')) {
      componentCount = _json['componentCount'] as core.int;
    }
    if (_json.containsKey('contentDisposition')) {
      contentDisposition = _json['contentDisposition'] as core.String;
    }
    if (_json.containsKey('contentEncoding')) {
      contentEncoding = _json['contentEncoding'] as core.String;
    }
    if (_json.containsKey('contentLanguage')) {
      contentLanguage = _json['contentLanguage'] as core.String;
    }
    if (_json.containsKey('contentType')) {
      contentType = _json['contentType'] as core.String;
    }
    if (_json.containsKey('crc32c')) {
      crc32c = _json['crc32c'] as core.String;
    }
    if (_json.containsKey('customTime')) {
      customTime = core.DateTime.parse(_json['customTime'] as core.String);
    }
    if (_json.containsKey('customerEncryption')) {
      customerEncryption = ObjectCustomerEncryption.fromJson(
          _json['customerEncryption'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('eventBasedHold')) {
      eventBasedHold = _json['eventBasedHold'] as core.bool;
    }
    if (_json.containsKey('generation')) {
      generation = _json['generation'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('kmsKeyName')) {
      kmsKeyName = _json['kmsKeyName'] as core.String;
    }
    if (_json.containsKey('md5Hash')) {
      md5Hash = _json['md5Hash'] as core.String;
    }
    if (_json.containsKey('mediaLink')) {
      mediaLink = _json['mediaLink'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('metageneration')) {
      metageneration = _json['metageneration'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('owner')) {
      owner = ObjectOwner.fromJson(
          _json['owner'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('retentionExpirationTime')) {
      retentionExpirationTime =
          core.DateTime.parse(_json['retentionExpirationTime'] as core.String);
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('size')) {
      size = _json['size'] as core.String;
    }
    if (_json.containsKey('storageClass')) {
      storageClass = _json['storageClass'] as core.String;
    }
    if (_json.containsKey('temporaryHold')) {
      temporaryHold = _json['temporaryHold'] as core.bool;
    }
    if (_json.containsKey('timeCreated')) {
      timeCreated = core.DateTime.parse(_json['timeCreated'] as core.String);
    }
    if (_json.containsKey('timeDeleted')) {
      timeDeleted = core.DateTime.parse(_json['timeDeleted'] as core.String);
    }
    if (_json.containsKey('timeStorageClassUpdated')) {
      timeStorageClassUpdated =
          core.DateTime.parse(_json['timeStorageClassUpdated'] as core.String);
    }
    if (_json.containsKey('updated')) {
      updated = core.DateTime.parse(_json['updated'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (acl != null) 'acl': acl!.map((value) => value.toJson()).toList(),
        if (bucket != null) 'bucket': bucket!,
        if (cacheControl != null) 'cacheControl': cacheControl!,
        if (componentCount != null) 'componentCount': componentCount!,
        if (contentDisposition != null)
          'contentDisposition': contentDisposition!,
        if (contentEncoding != null) 'contentEncoding': contentEncoding!,
        if (contentLanguage != null) 'contentLanguage': contentLanguage!,
        if (contentType != null) 'contentType': contentType!,
        if (crc32c != null) 'crc32c': crc32c!,
        if (customTime != null) 'customTime': customTime!.toIso8601String(),
        if (customerEncryption != null)
          'customerEncryption': customerEncryption!.toJson(),
        if (etag != null) 'etag': etag!,
        if (eventBasedHold != null) 'eventBasedHold': eventBasedHold!,
        if (generation != null) 'generation': generation!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (kmsKeyName != null) 'kmsKeyName': kmsKeyName!,
        if (md5Hash != null) 'md5Hash': md5Hash!,
        if (mediaLink != null) 'mediaLink': mediaLink!,
        if (metadata != null) 'metadata': metadata!,
        if (metageneration != null) 'metageneration': metageneration!,
        if (name != null) 'name': name!,
        if (owner != null) 'owner': owner!.toJson(),
        if (retentionExpirationTime != null)
          'retentionExpirationTime': retentionExpirationTime!.toIso8601String(),
        if (selfLink != null) 'selfLink': selfLink!,
        if (size != null) 'size': size!,
        if (storageClass != null) 'storageClass': storageClass!,
        if (temporaryHold != null) 'temporaryHold': temporaryHold!,
        if (timeCreated != null) 'timeCreated': timeCreated!.toIso8601String(),
        if (timeDeleted != null) 'timeDeleted': timeDeleted!.toIso8601String(),
        if (timeStorageClassUpdated != null)
          'timeStorageClassUpdated': timeStorageClassUpdated!.toIso8601String(),
        if (updated != null) 'updated': updated!.toIso8601String(),
      };
}

/// The project team associated with the entity, if any.
class ObjectAccessControlProjectTeam {
  /// The project number.
  core.String? projectNumber;

  /// The team.
  core.String? team;

  ObjectAccessControlProjectTeam();

  ObjectAccessControlProjectTeam.fromJson(core.Map _json) {
    if (_json.containsKey('projectNumber')) {
      projectNumber = _json['projectNumber'] as core.String;
    }
    if (_json.containsKey('team')) {
      team = _json['team'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (projectNumber != null) 'projectNumber': projectNumber!,
        if (team != null) 'team': team!,
      };
}

/// An access-control entry.
class ObjectAccessControl {
  /// The name of the bucket.
  core.String? bucket;

  /// The domain associated with the entity, if any.
  core.String? domain;

  /// The email address associated with the entity, if any.
  core.String? email;

  /// The entity holding the permission, in one of the following forms:
  /// - user-userId
  /// - user-email
  /// - group-groupId
  /// - group-email
  /// - domain-domain
  /// - project-team-projectId
  /// - allUsers
  /// - allAuthenticatedUsers Examples:
  /// - The user liz@example.com would be user-liz@example.com.
  ///
  ///
  /// - The group example@googlegroups.com would be
  /// group-example@googlegroups.com.
  /// - To refer to all members of the Google Apps for Business domain
  /// example.com, the entity would be domain-example.com.
  core.String? entity;

  /// The ID for the entity, if any.
  core.String? entityId;

  /// HTTP 1.1 Entity tag for the access-control entry.
  core.String? etag;

  /// The content generation of the object, if applied to an object.
  core.String? generation;

  /// The ID of the access-control entry.
  core.String? id;

  /// The kind of item this is.
  ///
  /// For object access control entries, this is always
  /// storage#objectAccessControl.
  core.String? kind;

  /// The name of the object, if applied to an object.
  core.String? object;

  /// The project team associated with the entity, if any.
  ObjectAccessControlProjectTeam? projectTeam;

  /// The access permission for the entity.
  core.String? role;

  /// The link to this access-control entry.
  core.String? selfLink;

  ObjectAccessControl();

  ObjectAccessControl.fromJson(core.Map _json) {
    if (_json.containsKey('bucket')) {
      bucket = _json['bucket'] as core.String;
    }
    if (_json.containsKey('domain')) {
      domain = _json['domain'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('entity')) {
      entity = _json['entity'] as core.String;
    }
    if (_json.containsKey('entityId')) {
      entityId = _json['entityId'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('generation')) {
      generation = _json['generation'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('object')) {
      object = _json['object'] as core.String;
    }
    if (_json.containsKey('projectTeam')) {
      projectTeam = ObjectAccessControlProjectTeam.fromJson(
          _json['projectTeam'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bucket != null) 'bucket': bucket!,
        if (domain != null) 'domain': domain!,
        if (email != null) 'email': email!,
        if (entity != null) 'entity': entity!,
        if (entityId != null) 'entityId': entityId!,
        if (etag != null) 'etag': etag!,
        if (generation != null) 'generation': generation!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (object != null) 'object': object!,
        if (projectTeam != null) 'projectTeam': projectTeam!.toJson(),
        if (role != null) 'role': role!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

/// An access-control list.
class ObjectAccessControls {
  /// The list of items.
  core.List<ObjectAccessControl>? items;

  /// The kind of item this is.
  ///
  /// For lists of object access control entries, this is always
  /// storage#objectAccessControls.
  core.String? kind;

  ObjectAccessControls();

  ObjectAccessControls.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<ObjectAccessControl>((value) => ObjectAccessControl.fromJson(
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

/// A list of objects.
class Objects {
  /// The list of items.
  core.List<Object>? items;

  /// The kind of item this is.
  ///
  /// For lists of objects, this is always storage#objects.
  core.String? kind;

  /// The continuation token, used to page through large result sets.
  ///
  /// Provide this value in a subsequent request to return the next page of
  /// results.
  core.String? nextPageToken;

  /// The list of prefixes of objects matching-but-not-listed up to and
  /// including the requested delimiter.
  core.List<core.String>? prefixes;

  Objects();

  Objects.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Object>((value) =>
              Object.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('prefixes')) {
      prefixes = (_json['prefixes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (prefixes != null) 'prefixes': prefixes!,
      };
}

class PolicyBindings {
  /// The condition that is associated with this binding.
  ///
  /// NOTE: an unsatisfied condition will not allow user access via current
  /// binding. Different bindings, including their conditions, are examined
  /// independently.
  Expr? condition;

  /// A collection of identifiers for members who may assume the provided role.
  ///
  /// Recognized identifiers are as follows:
  /// - allUsers — A special identifier that represents anyone on the internet;
  /// with or without a Google account.
  /// - allAuthenticatedUsers — A special identifier that represents anyone who
  /// is authenticated with a Google account or a service account.
  /// - user:emailid — An email address that represents a specific account. For
  /// example, user:alice@gmail.com or user:joe@example.com.
  /// - serviceAccount:emailid — An email address that represents a service
  /// account. For example,
  /// serviceAccount:my-other-app@appspot.gserviceaccount.com .
  /// - group:emailid — An email address that represents a Google group. For
  /// example, group:admins@example.com.
  /// - domain:domain — A Google Apps domain name that represents all the users
  /// of that domain. For example, domain:google.com or domain:example.com.
  /// - projectOwner:projectid — Owners of the given project. For example,
  /// projectOwner:my-example-project
  /// - projectEditor:projectid — Editors of the given project. For example,
  /// projectEditor:my-example-project
  /// - projectViewer:projectid — Viewers of the given project. For example,
  /// projectViewer:my-example-project
  core.List<core.String>? members;

  /// The role to which members belong.
  ///
  /// Two types of roles are supported: new IAM roles, which grant permissions
  /// that do not map directly to those provided by ACLs, and legacy IAM roles,
  /// which do map directly to ACL permissions. All roles are of the format
  /// roles/storage.specificRole.
  /// The new IAM roles are:
  /// - roles/storage.admin — Full control of Google Cloud Storage resources.
  /// - roles/storage.objectViewer — Read-Only access to Google Cloud Storage
  /// objects.
  /// - roles/storage.objectCreator — Access to create objects in Google Cloud
  /// Storage.
  /// - roles/storage.objectAdmin — Full control of Google Cloud Storage
  /// objects. The legacy IAM roles are:
  /// - roles/storage.legacyObjectReader — Read-only access to objects without
  /// listing. Equivalent to an ACL entry on an object with the READER role.
  /// - roles/storage.legacyObjectOwner — Read/write access to existing objects
  /// without listing. Equivalent to an ACL entry on an object with the OWNER
  /// role.
  /// - roles/storage.legacyBucketReader — Read access to buckets with object
  /// listing. Equivalent to an ACL entry on a bucket with the READER role.
  /// - roles/storage.legacyBucketWriter — Read access to buckets with object
  /// listing/creation/deletion. Equivalent to an ACL entry on a bucket with the
  /// WRITER role.
  /// - roles/storage.legacyBucketOwner — Read and write access to existing
  /// buckets with object listing/creation/deletion. Equivalent to an ACL entry
  /// on a bucket with the OWNER role.
  core.String? role;

  PolicyBindings();

  PolicyBindings.fromJson(core.Map _json) {
    if (_json.containsKey('condition')) {
      condition = Expr.fromJson(
          _json['condition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('members')) {
      members = (_json['members'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (condition != null) 'condition': condition!.toJson(),
        if (members != null) 'members': members!,
        if (role != null) 'role': role!,
      };
}

/// A bucket/object IAM policy.
class Policy {
  /// An association between a role, which comes with a set of permissions, and
  /// members who may assume that role.
  core.List<PolicyBindings>? bindings;

  /// HTTP 1.1  Entity tag for the policy.
  core.String? etag;
  core.List<core.int> get etagAsBytes => convert.base64.decode(etag!);

  set etagAsBytes(core.List<core.int> _bytes) {
    etag =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The kind of item this is.
  ///
  /// For policies, this is always storage#policy. This field is ignored on
  /// input.
  core.String? kind;

  /// The ID of the resource to which this policy belongs.
  ///
  /// Will be of the form projects/_/buckets/bucket for buckets, and
  /// projects/_/buckets/bucket/objects/object for objects. A specific
  /// generation may be specified by appending #generationNumber to the end of
  /// the object name, e.g. projects/_/buckets/my-bucket/objects/data.txt#17.
  /// The current generation can be denoted with #0. This field is ignored on
  /// input.
  core.String? resourceId;

  /// The IAM policy format version.
  core.int? version;

  Policy();

  Policy.fromJson(core.Map _json) {
    if (_json.containsKey('bindings')) {
      bindings = (_json['bindings'] as core.List)
          .map<PolicyBindings>((value) => PolicyBindings.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('resourceId')) {
      resourceId = _json['resourceId'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bindings != null)
          'bindings': bindings!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (resourceId != null) 'resourceId': resourceId!,
        if (version != null) 'version': version!,
      };
}

/// A rewrite response.
class RewriteResponse {
  /// true if the copy is finished; otherwise, false if the copy is in progress.
  ///
  /// This property is always present in the response.
  core.bool? done;

  /// The kind of item this is.
  core.String? kind;

  /// The total size of the object being copied in bytes.
  ///
  /// This property is always present in the response.
  core.String? objectSize;

  /// A resource containing the metadata for the copied-to object.
  ///
  /// This property is present in the response only when copying completes.
  Object? resource;

  /// A token to use in subsequent requests to continue copying data.
  ///
  /// This token is present in the response only when there is more data to
  /// copy.
  core.String? rewriteToken;

  /// The total bytes written so far, which can be used to provide a waiting
  /// user with a progress indicator.
  ///
  /// This property is always present in the response.
  core.String? totalBytesRewritten;

  RewriteResponse();

  RewriteResponse.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('objectSize')) {
      objectSize = _json['objectSize'] as core.String;
    }
    if (_json.containsKey('resource')) {
      resource = Object.fromJson(
          _json['resource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rewriteToken')) {
      rewriteToken = _json['rewriteToken'] as core.String;
    }
    if (_json.containsKey('totalBytesRewritten')) {
      totalBytesRewritten = _json['totalBytesRewritten'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (done != null) 'done': done!,
        if (kind != null) 'kind': kind!,
        if (objectSize != null) 'objectSize': objectSize!,
        if (resource != null) 'resource': resource!.toJson(),
        if (rewriteToken != null) 'rewriteToken': rewriteToken!,
        if (totalBytesRewritten != null)
          'totalBytesRewritten': totalBytesRewritten!,
      };
}

/// A subscription to receive Google PubSub notifications.
class ServiceAccount {
  /// The ID of the notification.
  core.String? emailAddress;

  /// The kind of item this is.
  ///
  /// For notifications, this is always storage#notification.
  core.String? kind;

  ServiceAccount();

  ServiceAccount.fromJson(core.Map _json) {
    if (_json.containsKey('email_address')) {
      emailAddress = _json['email_address'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (emailAddress != null) 'email_address': emailAddress!,
        if (kind != null) 'kind': kind!,
      };
}

/// A storage.(buckets|objects).testIamPermissions response.
class TestIamPermissionsResponse {
  /// The kind of item this is.
  core.String? kind;

  /// The permissions held by the caller.
  ///
  /// Permissions are always of the format storage.resource.capability, where
  /// resource is one of buckets or objects. The supported permissions are as
  /// follows:
  /// - storage.buckets.delete — Delete bucket.
  /// - storage.buckets.get — Read bucket metadata.
  /// - storage.buckets.getIamPolicy — Read bucket IAM policy.
  /// - storage.buckets.create — Create bucket.
  /// - storage.buckets.list — List buckets.
  /// - storage.buckets.setIamPolicy — Update bucket IAM policy.
  /// - storage.buckets.update — Update bucket metadata.
  /// - storage.objects.delete — Delete object.
  /// - storage.objects.get — Read object data and metadata.
  /// - storage.objects.getIamPolicy — Read object IAM policy.
  /// - storage.objects.create — Create object.
  /// - storage.objects.list — List objects.
  /// - storage.objects.setIamPolicy — Update object IAM policy.
  /// - storage.objects.update — Update object metadata.
  core.List<core.String>? permissions;

  TestIamPermissionsResponse();

  TestIamPermissionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (permissions != null) 'permissions': permissions!,
      };
}
