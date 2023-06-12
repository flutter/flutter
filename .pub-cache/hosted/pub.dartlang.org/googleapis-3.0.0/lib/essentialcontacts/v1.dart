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

/// Essential Contacts API - v1
///
/// For more information, see <https://cloud.google.com/essentialcontacts/docs/>
///
/// Create an instance of [EssentialcontactsApi] to access these resources:
///
/// - [FoldersResource]
///   - [FoldersContactsResource]
/// - [OrganizationsResource]
///   - [OrganizationsContactsResource]
/// - [ProjectsResource]
///   - [ProjectsContactsResource]
library essentialcontacts.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

class EssentialcontactsApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  FoldersResource get folders => FoldersResource(_requester);
  OrganizationsResource get organizations => OrganizationsResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);

  EssentialcontactsApi(http.Client client,
      {core.String rootUrl = 'https://essentialcontacts.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class FoldersResource {
  final commons.ApiRequester _requester;

  FoldersContactsResource get contacts => FoldersContactsResource(_requester);

  FoldersResource(commons.ApiRequester client) : _requester = client;
}

class FoldersContactsResource {
  final commons.ApiRequester _requester;

  FoldersContactsResource(commons.ApiRequester client) : _requester = client;

  /// Lists all contacts for the resource that are subscribed to the specified
  /// notification categories, including contacts inherited from any parent
  /// resources.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the resource to compute contacts for.
  /// Format: organizations/{organization_id}, folders/{folder_id} or
  /// projects/{project_id}
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [notificationCategories] - The categories of notifications to compute
  /// contacts for. If ALL is included in this list, contacts subscribed to any
  /// notification category will be returned.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of
  /// `next_page_token` in the response indicates that more results might be
  /// available. If not specified, the default page_size is 100.
  ///
  /// [pageToken] - Optional. If present, retrieves the next batch of results
  /// from the preceding call to this method. `page_token` must be the value of
  /// `next_page_token` from the previous response. The values of other method
  /// parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1ComputeContactsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1ComputeContactsResponse> compute(
    core.String parent, {
    core.List<core.String>? notificationCategories,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (notificationCategories != null)
        'notificationCategories': notificationCategories,
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/contacts:compute';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1ComputeContactsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Adds a new contact for a resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource to save this contact for. Format:
  /// organizations/{organization_id}, folders/{folder_id} or
  /// projects/{project_id}
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1Contact].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1Contact> create(
    GoogleCloudEssentialcontactsV1Contact request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/contacts';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1Contact.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a contact.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the contact to delete. Format:
  /// organizations/{organization_id}/contacts/{contact_id},
  /// folders/{folder_id}/contacts/{contact_id} or
  /// projects/{project_id}/contacts/{contact_id}
  /// Value must have pattern `^folders/\[^/\]+/contacts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a single contact.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the contact to retrieve. Format:
  /// organizations/{organization_id}/contacts/{contact_id},
  /// folders/{folder_id}/contacts/{contact_id} or
  /// projects/{project_id}/contacts/{contact_id}
  /// Value must have pattern `^folders/\[^/\]+/contacts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1Contact].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1Contact> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1Contact.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the contacts that have been set on a resource.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name. Format:
  /// organizations/{organization_id}, folders/{folder_id} or
  /// projects/{project_id}
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of
  /// `next_page_token` in the response indicates that more results might be
  /// available. If not specified, the default page_size is 100.
  ///
  /// [pageToken] - Optional. If present, retrieves the next batch of results
  /// from the preceding call to this method. `page_token` must be the value of
  /// `next_page_token` from the previous response. The values of other method
  /// parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1ListContactsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1ListContactsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/contacts';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1ListContactsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a contact.
  ///
  /// Note: A contact's email address cannot be changed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The identifier for the contact. Format:
  /// {resource_type}/{resource_id}/contacts/{contact_id}
  /// Value must have pattern `^folders/\[^/\]+/contacts/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. The update mask applied to the resource. For the
  /// `FieldMask` definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1Contact].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1Contact> patch(
    GoogleCloudEssentialcontactsV1Contact request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1Contact.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Allows a contact admin to send a test message to contact to verify that it
  /// has been configured correctly.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Required. The name of the resource to send the test message
  /// for. All contacts must either be set directly on this resource or
  /// inherited from another resource that is an ancestor of this one. Format:
  /// organizations/{organization_id}, folders/{folder_id} or
  /// projects/{project_id}
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> sendTestMessage(
    GoogleCloudEssentialcontactsV1SendTestMessageRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$resource') + '/contacts:sendTestMessage';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsResource {
  final commons.ApiRequester _requester;

  OrganizationsContactsResource get contacts =>
      OrganizationsContactsResource(_requester);

  OrganizationsResource(commons.ApiRequester client) : _requester = client;
}

class OrganizationsContactsResource {
  final commons.ApiRequester _requester;

  OrganizationsContactsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists all contacts for the resource that are subscribed to the specified
  /// notification categories, including contacts inherited from any parent
  /// resources.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the resource to compute contacts for.
  /// Format: organizations/{organization_id}, folders/{folder_id} or
  /// projects/{project_id}
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [notificationCategories] - The categories of notifications to compute
  /// contacts for. If ALL is included in this list, contacts subscribed to any
  /// notification category will be returned.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of
  /// `next_page_token` in the response indicates that more results might be
  /// available. If not specified, the default page_size is 100.
  ///
  /// [pageToken] - Optional. If present, retrieves the next batch of results
  /// from the preceding call to this method. `page_token` must be the value of
  /// `next_page_token` from the previous response. The values of other method
  /// parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1ComputeContactsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1ComputeContactsResponse> compute(
    core.String parent, {
    core.List<core.String>? notificationCategories,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (notificationCategories != null)
        'notificationCategories': notificationCategories,
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/contacts:compute';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1ComputeContactsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Adds a new contact for a resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource to save this contact for. Format:
  /// organizations/{organization_id}, folders/{folder_id} or
  /// projects/{project_id}
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1Contact].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1Contact> create(
    GoogleCloudEssentialcontactsV1Contact request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/contacts';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1Contact.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a contact.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the contact to delete. Format:
  /// organizations/{organization_id}/contacts/{contact_id},
  /// folders/{folder_id}/contacts/{contact_id} or
  /// projects/{project_id}/contacts/{contact_id}
  /// Value must have pattern `^organizations/\[^/\]+/contacts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a single contact.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the contact to retrieve. Format:
  /// organizations/{organization_id}/contacts/{contact_id},
  /// folders/{folder_id}/contacts/{contact_id} or
  /// projects/{project_id}/contacts/{contact_id}
  /// Value must have pattern `^organizations/\[^/\]+/contacts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1Contact].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1Contact> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1Contact.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the contacts that have been set on a resource.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name. Format:
  /// organizations/{organization_id}, folders/{folder_id} or
  /// projects/{project_id}
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of
  /// `next_page_token` in the response indicates that more results might be
  /// available. If not specified, the default page_size is 100.
  ///
  /// [pageToken] - Optional. If present, retrieves the next batch of results
  /// from the preceding call to this method. `page_token` must be the value of
  /// `next_page_token` from the previous response. The values of other method
  /// parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1ListContactsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1ListContactsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/contacts';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1ListContactsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a contact.
  ///
  /// Note: A contact's email address cannot be changed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The identifier for the contact. Format:
  /// {resource_type}/{resource_id}/contacts/{contact_id}
  /// Value must have pattern `^organizations/\[^/\]+/contacts/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. The update mask applied to the resource. For the
  /// `FieldMask` definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1Contact].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1Contact> patch(
    GoogleCloudEssentialcontactsV1Contact request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1Contact.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Allows a contact admin to send a test message to contact to verify that it
  /// has been configured correctly.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Required. The name of the resource to send the test message
  /// for. All contacts must either be set directly on this resource or
  /// inherited from another resource that is an ancestor of this one. Format:
  /// organizations/{organization_id}, folders/{folder_id} or
  /// projects/{project_id}
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> sendTestMessage(
    GoogleCloudEssentialcontactsV1SendTestMessageRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$resource') + '/contacts:sendTestMessage';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsContactsResource get contacts => ProjectsContactsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsContactsResource {
  final commons.ApiRequester _requester;

  ProjectsContactsResource(commons.ApiRequester client) : _requester = client;

  /// Lists all contacts for the resource that are subscribed to the specified
  /// notification categories, including contacts inherited from any parent
  /// resources.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the resource to compute contacts for.
  /// Format: organizations/{organization_id}, folders/{folder_id} or
  /// projects/{project_id}
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [notificationCategories] - The categories of notifications to compute
  /// contacts for. If ALL is included in this list, contacts subscribed to any
  /// notification category will be returned.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of
  /// `next_page_token` in the response indicates that more results might be
  /// available. If not specified, the default page_size is 100.
  ///
  /// [pageToken] - Optional. If present, retrieves the next batch of results
  /// from the preceding call to this method. `page_token` must be the value of
  /// `next_page_token` from the previous response. The values of other method
  /// parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1ComputeContactsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1ComputeContactsResponse> compute(
    core.String parent, {
    core.List<core.String>? notificationCategories,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (notificationCategories != null)
        'notificationCategories': notificationCategories,
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/contacts:compute';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1ComputeContactsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Adds a new contact for a resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource to save this contact for. Format:
  /// organizations/{organization_id}, folders/{folder_id} or
  /// projects/{project_id}
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1Contact].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1Contact> create(
    GoogleCloudEssentialcontactsV1Contact request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/contacts';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1Contact.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a contact.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the contact to delete. Format:
  /// organizations/{organization_id}/contacts/{contact_id},
  /// folders/{folder_id}/contacts/{contact_id} or
  /// projects/{project_id}/contacts/{contact_id}
  /// Value must have pattern `^projects/\[^/\]+/contacts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a single contact.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the contact to retrieve. Format:
  /// organizations/{organization_id}/contacts/{contact_id},
  /// folders/{folder_id}/contacts/{contact_id} or
  /// projects/{project_id}/contacts/{contact_id}
  /// Value must have pattern `^projects/\[^/\]+/contacts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1Contact].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1Contact> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1Contact.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the contacts that have been set on a resource.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name. Format:
  /// organizations/{organization_id}, folders/{folder_id} or
  /// projects/{project_id}
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of
  /// `next_page_token` in the response indicates that more results might be
  /// available. If not specified, the default page_size is 100.
  ///
  /// [pageToken] - Optional. If present, retrieves the next batch of results
  /// from the preceding call to this method. `page_token` must be the value of
  /// `next_page_token` from the previous response. The values of other method
  /// parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1ListContactsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1ListContactsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/contacts';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1ListContactsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a contact.
  ///
  /// Note: A contact's email address cannot be changed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The identifier for the contact. Format:
  /// {resource_type}/{resource_id}/contacts/{contact_id}
  /// Value must have pattern `^projects/\[^/\]+/contacts/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. The update mask applied to the resource. For the
  /// `FieldMask` definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudEssentialcontactsV1Contact].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudEssentialcontactsV1Contact> patch(
    GoogleCloudEssentialcontactsV1Contact request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudEssentialcontactsV1Contact.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Allows a contact admin to send a test message to contact to verify that it
  /// has been configured correctly.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Required. The name of the resource to send the test message
  /// for. All contacts must either be set directly on this resource or
  /// inherited from another resource that is an ancestor of this one. Format:
  /// organizations/{organization_id}, folders/{folder_id} or
  /// projects/{project_id}
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> sendTestMessage(
    GoogleCloudEssentialcontactsV1SendTestMessageRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$resource') + '/contacts:sendTestMessage';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Response message for the ComputeContacts method.
class GoogleCloudEssentialcontactsV1ComputeContactsResponse {
  /// All contacts for the resource that are subscribed to the specified
  /// notification categories, including contacts inherited from any parent
  /// resources.
  core.List<GoogleCloudEssentialcontactsV1Contact>? contacts;

  /// If there are more results than those appearing in this response, then
  /// `next_page_token` is included.
  ///
  /// To get the next set of results, call this method again using the value of
  /// `next_page_token` as `page_token` and the rest of the parameters the same
  /// as the original request.
  core.String? nextPageToken;

  GoogleCloudEssentialcontactsV1ComputeContactsResponse();

  GoogleCloudEssentialcontactsV1ComputeContactsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('contacts')) {
      contacts = (_json['contacts'] as core.List)
          .map<GoogleCloudEssentialcontactsV1Contact>((value) =>
              GoogleCloudEssentialcontactsV1Contact.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contacts != null)
          'contacts': contacts!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A contact that will receive notifications from Google Cloud.
class GoogleCloudEssentialcontactsV1Contact {
  /// The email address to send notifications to.
  ///
  /// This does not need to be a Google account.
  ///
  /// Required.
  core.String? email;

  /// The preferred language for notifications, as a ISO 639-1 language code.
  ///
  /// See
  /// [Supported languages](https://cloud.google.com/resource-manager/docs/managing-notification-contacts#supported-languages)
  /// for a list of supported languages.
  core.String? languageTag;

  /// The identifier for the contact.
  ///
  /// Format: {resource_type}/{resource_id}/contacts/{contact_id}
  core.String? name;

  /// The categories of notifications that the contact will receive
  /// communications for.
  core.List<core.String>? notificationCategorySubscriptions;

  /// The last time the validation_state was updated, either manually or
  /// automatically.
  ///
  /// A contact is considered stale if its validation state was updated more
  /// than 1 year ago.
  core.String? validateTime;

  /// The validity of the contact.
  ///
  /// A contact is considered valid if it is the correct recipient for
  /// notifications for a particular resource.
  /// Possible string values are:
  /// - "VALIDATION_STATE_UNSPECIFIED" : The validation state is unknown or
  /// unspecified.
  /// - "VALID" : The contact is marked as valid. This is usually done manually
  /// by the contact admin. All new contacts begin in the valid state.
  /// - "INVALID" : The contact is considered invalid. This may become the state
  /// if the contact's email is found to be unreachable.
  core.String? validationState;

  GoogleCloudEssentialcontactsV1Contact();

  GoogleCloudEssentialcontactsV1Contact.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('languageTag')) {
      languageTag = _json['languageTag'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('notificationCategorySubscriptions')) {
      notificationCategorySubscriptions =
          (_json['notificationCategorySubscriptions'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('validateTime')) {
      validateTime = _json['validateTime'] as core.String;
    }
    if (_json.containsKey('validationState')) {
      validationState = _json['validationState'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (languageTag != null) 'languageTag': languageTag!,
        if (name != null) 'name': name!,
        if (notificationCategorySubscriptions != null)
          'notificationCategorySubscriptions':
              notificationCategorySubscriptions!,
        if (validateTime != null) 'validateTime': validateTime!,
        if (validationState != null) 'validationState': validationState!,
      };
}

/// Response message for the ListContacts method.
class GoogleCloudEssentialcontactsV1ListContactsResponse {
  /// The contacts for the specified resource.
  core.List<GoogleCloudEssentialcontactsV1Contact>? contacts;

  /// If there are more results than those appearing in this response, then
  /// `next_page_token` is included.
  ///
  /// To get the next set of results, call this method again using the value of
  /// `next_page_token` as `page_token` and the rest of the parameters the same
  /// as the original request.
  core.String? nextPageToken;

  GoogleCloudEssentialcontactsV1ListContactsResponse();

  GoogleCloudEssentialcontactsV1ListContactsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('contacts')) {
      contacts = (_json['contacts'] as core.List)
          .map<GoogleCloudEssentialcontactsV1Contact>((value) =>
              GoogleCloudEssentialcontactsV1Contact.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contacts != null)
          'contacts': contacts!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Request message for the SendTestMessage method.
class GoogleCloudEssentialcontactsV1SendTestMessageRequest {
  /// The list of names of the contacts to send a test message to.
  ///
  /// Format: organizations/{organization_id}/contacts/{contact_id},
  /// folders/{folder_id}/contacts/{contact_id} or
  /// projects/{project_id}/contacts/{contact_id}
  ///
  /// Required.
  core.List<core.String>? contacts;

  /// The notification category to send the test message for.
  ///
  /// All contacts must be subscribed to this category.
  ///
  /// Required.
  /// Possible string values are:
  /// - "NOTIFICATION_CATEGORY_UNSPECIFIED" : Notification category is
  /// unrecognized or unspecified.
  /// - "ALL" : All notifications related to the resource, including
  /// notifications pertaining to categories added in the future.
  /// - "SUSPENSION" : Notifications related to imminent account suspension.
  /// - "SECURITY" : Notifications related to security/privacy incidents,
  /// notifications, and vulnerabilities.
  /// - "TECHNICAL" : Notifications related to technical events and issues such
  /// as outages, errors, or bugs.
  /// - "BILLING" : Notifications related to billing and payments notifications,
  /// price updates, errors, or credits.
  /// - "LEGAL" : Notifications related to enforcement actions, regulatory
  /// compliance, or government notices.
  /// - "PRODUCT_UPDATES" : Notifications related to new versions, product terms
  /// updates, or deprecations.
  /// - "TECHNICAL_INCIDENTS" : Child category of TECHNICAL. If assigned,
  /// technical incident notifications will go to these contacts instead of
  /// TECHNICAL.
  core.String? notificationCategory;

  GoogleCloudEssentialcontactsV1SendTestMessageRequest();

  GoogleCloudEssentialcontactsV1SendTestMessageRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('contacts')) {
      contacts = (_json['contacts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('notificationCategory')) {
      notificationCategory = _json['notificationCategory'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contacts != null) 'contacts': contacts!,
        if (notificationCategory != null)
          'notificationCategory': notificationCategory!,
      };
}

/// A generic empty message that you can re-use to avoid defining duplicated
/// empty messages in your APIs.
///
/// A typical example is to use it as the request or the response type of an API
/// method. For instance: service Foo { rpc Bar(google.protobuf.Empty) returns
/// (google.protobuf.Empty); } The JSON representation for `Empty` is empty JSON
/// object `{}`.
class GoogleProtobufEmpty {
  GoogleProtobufEmpty();

  GoogleProtobufEmpty.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}
