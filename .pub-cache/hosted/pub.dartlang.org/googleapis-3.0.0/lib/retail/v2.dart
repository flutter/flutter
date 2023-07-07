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

/// Retail API - v2
///
/// Cloud Retail service enables customers to build end-to-end personalized
/// recommendation systems without requiring a high level of expertise in
/// machine learning, recommendation system, or Google Cloud.
///
/// For more information, see <https://cloud.google.com/recommendations>
///
/// Create an instance of [CloudRetailApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsCatalogsResource]
///       - [ProjectsLocationsCatalogsBranchesResource]
///         - [ProjectsLocationsCatalogsBranchesOperationsResource]
///         - [ProjectsLocationsCatalogsBranchesProductsResource]
///       - [ProjectsLocationsCatalogsOperationsResource]
///       - [ProjectsLocationsCatalogsPlacementsResource]
///       - [ProjectsLocationsCatalogsUserEventsResource]
///     - [ProjectsLocationsOperationsResource]
library retail.v2;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Cloud Retail service enables customers to build end-to-end personalized
/// recommendation systems without requiring a high level of expertise in
/// machine learning, recommendation system, or Google Cloud.
class CloudRetailApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  CloudRetailApi(http.Client client,
      {core.String rootUrl = 'https://retail.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsResource get locations =>
      ProjectsLocationsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsCatalogsResource get catalogs =>
      ProjectsLocationsCatalogsResource(_requester);
  ProjectsLocationsOperationsResource get operations =>
      ProjectsLocationsOperationsResource(_requester);

  ProjectsLocationsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsCatalogsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsCatalogsBranchesResource get branches =>
      ProjectsLocationsCatalogsBranchesResource(_requester);
  ProjectsLocationsCatalogsOperationsResource get operations =>
      ProjectsLocationsCatalogsOperationsResource(_requester);
  ProjectsLocationsCatalogsPlacementsResource get placements =>
      ProjectsLocationsCatalogsPlacementsResource(_requester);
  ProjectsLocationsCatalogsUserEventsResource get userEvents =>
      ProjectsLocationsCatalogsUserEventsResource(_requester);

  ProjectsLocationsCatalogsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists all the Catalogs associated with the project.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The account resource name with an associated
  /// location. If the caller does not have permission to list Catalogs under
  /// this location, regardless of whether or not this location exists, a
  /// PERMISSION_DENIED error is returned.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - Maximum number of Catalogs to return. If unspecified,
  /// defaults to 50. The maximum allowed value is 1000. Values above 1000 will
  /// be coerced to 1000. If this field is negative, an INVALID_ARGUMENT is
  /// returned.
  ///
  /// [pageToken] - A page token ListCatalogsResponse.next_page_token, received
  /// from a previous CatalogService.ListCatalogs call. Provide this to retrieve
  /// the subsequent page. When paginating, all other parameters provided to
  /// CatalogService.ListCatalogs must match the call that provided the page
  /// token. Otherwise, an INVALID_ARGUMENT error is returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRetailV2ListCatalogsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRetailV2ListCatalogsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/catalogs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudRetailV2ListCatalogsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the Catalogs.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Immutable. The fully qualified resource name of the
  /// catalog.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+$`.
  ///
  /// [updateMask] - Indicates which fields in the provided Catalog to update.
  /// If an unsupported or unknown field is provided, an INVALID_ARGUMENT error
  /// is returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRetailV2Catalog].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRetailV2Catalog> patch(
    GoogleCloudRetailV2Catalog request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudRetailV2Catalog.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsCatalogsBranchesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsCatalogsBranchesOperationsResource get operations =>
      ProjectsLocationsCatalogsBranchesOperationsResource(_requester);
  ProjectsLocationsCatalogsBranchesProductsResource get products =>
      ProjectsLocationsCatalogsBranchesProductsResource(_requester);

  ProjectsLocationsCatalogsBranchesResource(commons.ApiRequester client)
      : _requester = client;
}

class ProjectsLocationsCatalogsBranchesOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsCatalogsBranchesOperationsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Gets the latest state of a long-running operation.
  ///
  /// Clients can use this method to poll the operation result at intervals as
  /// recommended by the API service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+/branches/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsCatalogsBranchesProductsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsCatalogsBranchesProductsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a Product.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent catalog resource name, such as `projects /
  /// * /locations/global/catalogs/default_catalog/branches/default_branch`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+/branches/\[^/\]+$`.
  ///
  /// [productId] - Required. The ID to use for the Product, which will become
  /// the final component of the Product.name. If the caller does not have
  /// permission to create the Product, regardless of whether or not it exists,
  /// a PERMISSION_DENIED error is returned. This field must be unique among all
  /// Products with the same parent. Otherwise, an ALREADY_EXISTS error is
  /// returned. This field must be a UTF-8 encoded string with a length limit of
  /// 128 characters. Otherwise, an INVALID_ARGUMENT error is returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRetailV2Product].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRetailV2Product> create(
    GoogleCloudRetailV2Product request,
    core.String parent, {
    core.String? productId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (productId != null) 'productId': [productId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/products';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudRetailV2Product.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a Product.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Full resource name of Product, such as `projects / *
  /// /locations/global/catalogs/default_catalog/branches/default_branch/products/some_product_id`.
  /// If the caller does not have permission to delete the Product, regardless
  /// of whether or not it exists, a PERMISSION_DENIED error is returned. If the
  /// Product to delete does not exist, a NOT_FOUND error is returned. The
  /// Product to delete can neither be a Product.Type.COLLECTION Product member
  /// nor a Product.Type.PRIMARY Product with more than one variants. Otherwise,
  /// an INVALID_ARGUMENT error is returned. All inventory information for the
  /// named Product will be deleted.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+/branches/\[^/\]+/products/.*$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a Product.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Full resource name of Product, such as `projects / *
  /// /locations/global/catalogs/default_catalog/branches/default_branch/products/some_product_id`.
  /// If the caller does not have permission to access the Product, regardless
  /// of whether or not it exists, a PERMISSION_DENIED error is returned. If the
  /// requested Product does not exist, a NOT_FOUND error is returned.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+/branches/\[^/\]+/products/.*$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRetailV2Product].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRetailV2Product> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudRetailV2Product.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Bulk import of multiple Products.
  ///
  /// Request processing may be synchronous. No partial updating is supported.
  /// Non-existing items are created. Note that it is possible for a subset of
  /// the Products to be successfully updated.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required.
  /// `projects/1234/locations/global/catalogs/default_catalog/branches/default_branch`
  /// If no updateMask is specified, requires products.create permission. If
  /// updateMask is specified, requires products.update permission.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+/branches/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> import(
    GoogleCloudRetailV2ImportProductsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/products:import';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a Product.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Immutable. Full resource name of the product, such as `projects /
  /// *
  /// /locations/global/catalogs/default_catalog/branches/default_branch/products/product_id`.
  /// The branch ID must be "default_branch".
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+/branches/\[^/\]+/products/.*$`.
  ///
  /// [allowMissing] - If set to true, and the Product is not found, a new
  /// Product will be created. In this situation, `update_mask` is ignored.
  ///
  /// [updateMask] - Indicates which fields in the provided Product to update.
  /// The immutable and output only fields are NOT supported. If not set, all
  /// supported fields (the fields that are neither immutable nor output only)
  /// are updated. If an unsupported or unknown field is provided, an
  /// INVALID_ARGUMENT error is returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRetailV2Product].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRetailV2Product> patch(
    GoogleCloudRetailV2Product request,
    core.String name, {
    core.bool? allowMissing,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (allowMissing != null) 'allowMissing': ['${allowMissing}'],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudRetailV2Product.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsCatalogsOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsCatalogsOperationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the latest state of a long-running operation.
  ///
  /// Clients can use this method to poll the operation result at intervals as
  /// recommended by the API service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists operations that match the specified filter in the request.
  ///
  /// If the server doesn't support this method, it returns `UNIMPLEMENTED`.
  /// NOTE: the `name` binding allows API services to override the binding to
  /// use different resource name schemes, such as `users / * /operations`. To
  /// override the binding, API services can add a binding such as
  /// `"/v1/{name=users / * }/operations"` to their service configuration. For
  /// backwards compatibility, the default name includes the operations
  /// collection id, however overriding users must ensure the name binding is
  /// the parent resource, without the operations collection id.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation's parent resource.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+$`.
  ///
  /// [filter] - The standard list filter.
  ///
  /// [pageSize] - The standard list page size.
  ///
  /// [pageToken] - The standard list page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningListOperationsResponse> list(
    core.String name, {
    core.String? filter,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name') + '/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsCatalogsPlacementsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsCatalogsPlacementsResource(commons.ApiRequester client)
      : _requester = client;

  /// Makes a recommendation prediction.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [placement] - Required. Full resource name of the format: {name=projects /
  /// * /locations/global/catalogs/default_catalog/placements / * } The ID of
  /// the Recommendations AI placement. Before you can request predictions from
  /// your model, you must create at least one placement for it. For more
  /// information, see
  /// [Managing placements](https://cloud.google.com/retail/recommendations-ai/docs/manage-placements).
  /// The full list of available placements can be seen at
  /// https://console.cloud.google.com/recommendation/catalogs/default_catalog/placements
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+/placements/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRetailV2PredictResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRetailV2PredictResponse> predict(
    GoogleCloudRetailV2PredictRequest request,
    core.String placement, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$placement') + ':predict';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudRetailV2PredictResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsCatalogsUserEventsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsCatalogsUserEventsResource(commons.ApiRequester client)
      : _requester = client;

  /// Writes a single user event from the browser.
  ///
  /// This uses a GET request to due to browser restriction of POST-ing to a 3rd
  /// party domain. This method is used only by the Retail API JavaScript pixel
  /// and Google Tag Manager. Users should not call this method directly.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent catalog name, such as
  /// `projects/1234/locations/global/catalogs/default_catalog`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+$`.
  ///
  /// [ets] - The event timestamp in milliseconds. This prevents browser caching
  /// of otherwise identical get requests. The name is abbreviated to reduce the
  /// payload bytes.
  ///
  /// [uri] - The URL including cgi-parameters but excluding the hash fragment
  /// with a length limit of 5,000 characters. This is often more useful than
  /// the referer URL, because many browsers only send the domain for 3rd party
  /// requests.
  ///
  /// [userEvent] - Required. URL encoded UserEvent proto with a length limit of
  /// 2,000,000 characters.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleApiHttpBody].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleApiHttpBody> collect(
    core.String parent, {
    core.String? ets,
    core.String? uri,
    core.String? userEvent,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ets != null) 'ets': [ets],
      if (uri != null) 'uri': [uri],
      if (userEvent != null) 'userEvent': [userEvent],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/userEvents:collect';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleApiHttpBody.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Bulk import of User events.
  ///
  /// Request processing might be synchronous. Events that already exist are
  /// skipped. Use this method for backfilling historical user events.
  /// Operation.response is of type ImportResponse. Note that it is possible for
  /// a subset of the items to be successfully inserted. Operation.metadata is
  /// of type ImportMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required.
  /// `projects/1234/locations/global/catalogs/default_catalog`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> import(
    GoogleCloudRetailV2ImportUserEventsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/userEvents:import';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes permanently all user events specified by the filter provided.
  ///
  /// Depending on the number of events specified by the filter, this operation
  /// could take hours or days to complete. To test a filter, use the list
  /// command first.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the catalog under which the
  /// events are created. The format is
  /// `projects/${projectId}/locations/global/catalogs/${catalogId}`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> purge(
    GoogleCloudRetailV2PurgeUserEventsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/userEvents:purge';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Triggers a user event rejoin operation with latest product catalog.
  ///
  /// Events will not be annotated with detailed product information if product
  /// is missing from the catalog at the time the user event is ingested, and
  /// these events are stored as unjoined events with a limited usage on
  /// training and serving. This API can be used to trigger a 'join' operation
  /// on specified events with latest version of product catalog. It can also be
  /// used to correct events joined with wrong product catalog.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent catalog resource name, such as
  /// `projects/1234/locations/global/catalogs/default_catalog`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> rejoin(
    GoogleCloudRetailV2RejoinUserEventsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/userEvents:rejoin';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Writes a single user event.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent catalog resource name, such as
  /// `projects/1234/locations/global/catalogs/default_catalog`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/catalogs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRetailV2UserEvent].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRetailV2UserEvent> write(
    GoogleCloudRetailV2UserEvent request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/userEvents:write';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudRetailV2UserEvent.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsOperationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the latest state of a long-running operation.
  ///
  /// Clients can use this method to poll the operation result at intervals as
  /// recommended by the API service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists operations that match the specified filter in the request.
  ///
  /// If the server doesn't support this method, it returns `UNIMPLEMENTED`.
  /// NOTE: the `name` binding allows API services to override the binding to
  /// use different resource name schemes, such as `users / * /operations`. To
  /// override the binding, API services can add a binding such as
  /// `"/v1/{name=users / * }/operations"` to their service configuration. For
  /// backwards compatibility, the default name includes the operations
  /// collection id, however overriding users must ensure the name binding is
  /// the parent resource, without the operations collection id.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation's parent resource.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [filter] - The standard list filter.
  ///
  /// [pageSize] - The standard list page size.
  ///
  /// [pageToken] - The standard list page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningListOperationsResponse> list(
    core.String name, {
    core.String? filter,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name') + '/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Message that represents an arbitrary HTTP body.
///
/// It should only be used for payload formats that can't be represented as
/// JSON, such as raw binary or an HTML page. This message can be used both in
/// streaming and non-streaming API methods in the request as well as the
/// response. It can be used as a top-level request field, which is convenient
/// if one wants to extract parameters from either the URL or HTTP template into
/// the request fields and also want access to the raw HTTP body. Example:
/// message GetResourceRequest { // A unique request id. string request_id = 1;
/// // The raw HTTP body is bound to this field. google.api.HttpBody http_body =
/// 2; } service ResourceService { rpc GetResource(GetResourceRequest) returns
/// (google.api.HttpBody); rpc UpdateResource(google.api.HttpBody) returns
/// (google.protobuf.Empty); } Example with streaming methods: service
/// CaldavService { rpc GetCalendar(stream google.api.HttpBody) returns (stream
/// google.api.HttpBody); rpc UpdateCalendar(stream google.api.HttpBody) returns
/// (stream google.api.HttpBody); } Use of this type only changes how the
/// request and response bodies are handled, all other features will continue to
/// work unchanged.
class GoogleApiHttpBody {
  /// The HTTP Content-Type header value specifying the content type of the
  /// body.
  core.String? contentType;

  /// The HTTP request/response body as raw binary.
  core.String? data;
  core.List<core.int> get dataAsBytes => convert.base64.decode(data!);

  set dataAsBytes(core.List<core.int> _bytes) {
    data =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Application specific response metadata.
  ///
  /// Must be set in the first response for streaming APIs.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? extensions;

  GoogleApiHttpBody();

  GoogleApiHttpBody.fromJson(core.Map _json) {
    if (_json.containsKey('contentType')) {
      contentType = _json['contentType'] as core.String;
    }
    if (_json.containsKey('data')) {
      data = _json['data'] as core.String;
    }
    if (_json.containsKey('extensions')) {
      extensions = (_json['extensions'] as core.List)
          .map<core.Map<core.String, core.Object>>(
              (value) => (value as core.Map<core.String, core.dynamic>).map(
                    (key, item) => core.MapEntry(
                      key,
                      item as core.Object,
                    ),
                  ))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentType != null) 'contentType': contentType!,
        if (data != null) 'data': data!,
        if (extensions != null) 'extensions': extensions!,
      };
}

/// A description of the context in which an error occurred.
class GoogleCloudRetailLoggingErrorContext {
  /// The HTTP request which was processed when the error was triggered.
  GoogleCloudRetailLoggingHttpRequestContext? httpRequest;

  /// The location in the source code where the decision was made to report the
  /// error, usually the place where it was logged.
  GoogleCloudRetailLoggingSourceLocation? reportLocation;

  GoogleCloudRetailLoggingErrorContext();

  GoogleCloudRetailLoggingErrorContext.fromJson(core.Map _json) {
    if (_json.containsKey('httpRequest')) {
      httpRequest = GoogleCloudRetailLoggingHttpRequestContext.fromJson(
          _json['httpRequest'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reportLocation')) {
      reportLocation = GoogleCloudRetailLoggingSourceLocation.fromJson(
          _json['reportLocation'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (httpRequest != null) 'httpRequest': httpRequest!.toJson(),
        if (reportLocation != null) 'reportLocation': reportLocation!.toJson(),
      };
}

/// An error log which is reported to the Error Reporting system.
///
/// This proto a superset of
/// google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent.
class GoogleCloudRetailLoggingErrorLog {
  /// A description of the context in which the error occurred.
  GoogleCloudRetailLoggingErrorContext? context;

  /// The error payload that is populated on LRO import APIs.
  GoogleCloudRetailLoggingImportErrorContext? importPayload;

  /// A message describing the error.
  core.String? message;

  /// The API request payload, represented as a protocol buffer.
  ///
  /// Most API request types are supported. For example:
  /// "type.googleapis.com/google.cloud.retail.v2.ProductService.CreateProductRequest"
  /// "type.googleapis.com/google.cloud.retail.v2.UserEventService.WriteUserEventRequest"
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? requestPayload;

  /// The API response payload, represented as a protocol buffer.
  ///
  /// This is used to log some "soft errors", where the response is valid but we
  /// consider there are some quality issues like unjoined events. The following
  /// API responses are supported and no PII is included:
  /// "google.cloud.retail.v2.PredictionService.Predict"
  /// "google.cloud.retail.v2.UserEventService.WriteUserEvent"
  /// "google.cloud.retail.v2.UserEventService.CollectUserEvent"
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? responsePayload;

  /// The service context in which this error has occurred.
  GoogleCloudRetailLoggingServiceContext? serviceContext;

  /// The RPC status associated with the error log.
  GoogleRpcStatus? status;

  GoogleCloudRetailLoggingErrorLog();

  GoogleCloudRetailLoggingErrorLog.fromJson(core.Map _json) {
    if (_json.containsKey('context')) {
      context = GoogleCloudRetailLoggingErrorContext.fromJson(
          _json['context'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('importPayload')) {
      importPayload = GoogleCloudRetailLoggingImportErrorContext.fromJson(
          _json['importPayload'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('requestPayload')) {
      requestPayload =
          (_json['requestPayload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('responsePayload')) {
      responsePayload =
          (_json['responsePayload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('serviceContext')) {
      serviceContext = GoogleCloudRetailLoggingServiceContext.fromJson(
          _json['serviceContext'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = GoogleRpcStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (context != null) 'context': context!.toJson(),
        if (importPayload != null) 'importPayload': importPayload!.toJson(),
        if (message != null) 'message': message!,
        if (requestPayload != null) 'requestPayload': requestPayload!,
        if (responsePayload != null) 'responsePayload': responsePayload!,
        if (serviceContext != null) 'serviceContext': serviceContext!.toJson(),
        if (status != null) 'status': status!.toJson(),
      };
}

/// HTTP request data that is related to a reported error.
class GoogleCloudRetailLoggingHttpRequestContext {
  /// The HTTP response status code for the request.
  core.int? responseStatusCode;

  GoogleCloudRetailLoggingHttpRequestContext();

  GoogleCloudRetailLoggingHttpRequestContext.fromJson(core.Map _json) {
    if (_json.containsKey('responseStatusCode')) {
      responseStatusCode = _json['responseStatusCode'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (responseStatusCode != null)
          'responseStatusCode': responseStatusCode!,
      };
}

/// The error payload that is populated on LRO import APIs.
///
/// Including: "google.cloud.retail.v2.ProductService.ImportProducts"
/// "google.cloud.retail.v2.EventService.ImportUserEvents"
class GoogleCloudRetailLoggingImportErrorContext {
  /// The detailed content which caused the error on importing a catalog item.
  core.String? catalogItem;

  /// Cloud Storage file path of the import source.
  ///
  /// Can be set for batch operation error.
  core.String? gcsPath;

  /// Line number of the content in file.
  ///
  /// Should be empty for permission or batch operation error.
  core.String? lineNumber;

  /// The operation resource name of the LRO.
  core.String? operationName;

  /// The detailed content which caused the error on importing a product.
  core.String? product;

  /// The detailed content which caused the error on importing a user event.
  core.String? userEvent;

  GoogleCloudRetailLoggingImportErrorContext();

  GoogleCloudRetailLoggingImportErrorContext.fromJson(core.Map _json) {
    if (_json.containsKey('catalogItem')) {
      catalogItem = _json['catalogItem'] as core.String;
    }
    if (_json.containsKey('gcsPath')) {
      gcsPath = _json['gcsPath'] as core.String;
    }
    if (_json.containsKey('lineNumber')) {
      lineNumber = _json['lineNumber'] as core.String;
    }
    if (_json.containsKey('operationName')) {
      operationName = _json['operationName'] as core.String;
    }
    if (_json.containsKey('product')) {
      product = _json['product'] as core.String;
    }
    if (_json.containsKey('userEvent')) {
      userEvent = _json['userEvent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (catalogItem != null) 'catalogItem': catalogItem!,
        if (gcsPath != null) 'gcsPath': gcsPath!,
        if (lineNumber != null) 'lineNumber': lineNumber!,
        if (operationName != null) 'operationName': operationName!,
        if (product != null) 'product': product!,
        if (userEvent != null) 'userEvent': userEvent!,
      };
}

/// Describes a running service that sends errors.
class GoogleCloudRetailLoggingServiceContext {
  /// An identifier of the service.
  ///
  /// For example, "retail.googleapis.com".
  core.String? service;

  GoogleCloudRetailLoggingServiceContext();

  GoogleCloudRetailLoggingServiceContext.fromJson(core.Map _json) {
    if (_json.containsKey('service')) {
      service = _json['service'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (service != null) 'service': service!,
      };
}

/// Indicates a location in the source code of the service for which errors are
/// reported.
class GoogleCloudRetailLoggingSourceLocation {
  /// Human-readable name of a function or method.
  ///
  /// For example, "google.cloud.retail.v2.UserEventService.ImportUserEvents".
  core.String? functionName;

  GoogleCloudRetailLoggingSourceLocation();

  GoogleCloudRetailLoggingSourceLocation.fromJson(core.Map _json) {
    if (_json.containsKey('functionName')) {
      functionName = _json['functionName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (functionName != null) 'functionName': functionName!,
      };
}

/// BigQuery source import data from.
class GoogleCloudRetailV2BigQuerySource {
  /// The schema to use when parsing the data from the source.
  ///
  /// Supported values for product imports: * `product` (default): One JSON
  /// Product per line. Each product must have a valid Product.id. *
  /// `product_merchant_center`: See
  /// [Importing catalog data from Merchant Center](https://cloud.google.com/retail/recommendations-ai/docs/upload-catalog#mc).
  /// Supported values for user events imports: * `user_event` (default): One
  /// JSON UserEvent per line. * `user_event_ga360`: Using
  /// https://support.google.com/analytics/answer/3437719?hl=en.
  core.String? dataSchema;

  /// The BigQuery data set to copy the data from with a length limit of 1,024
  /// characters.
  ///
  /// Required.
  core.String? datasetId;

  /// Intermediate Cloud Storage directory used for the import with a length
  /// limit of 2,000 characters.
  ///
  /// Can be specified if one wants to have the BigQuery export to a specific
  /// Cloud Storage directory.
  core.String? gcsStagingDir;

  /// The project ID (can be project # or ID) that the BigQuery source is in
  /// with a length limit of 128 characters.
  ///
  /// If not specified, inherits the project ID from the parent request.
  core.String? projectId;

  /// The BigQuery table to copy the data from with a length limit of 1,024
  /// characters.
  ///
  /// Required.
  core.String? tableId;

  GoogleCloudRetailV2BigQuerySource();

  GoogleCloudRetailV2BigQuerySource.fromJson(core.Map _json) {
    if (_json.containsKey('dataSchema')) {
      dataSchema = _json['dataSchema'] as core.String;
    }
    if (_json.containsKey('datasetId')) {
      datasetId = _json['datasetId'] as core.String;
    }
    if (_json.containsKey('gcsStagingDir')) {
      gcsStagingDir = _json['gcsStagingDir'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('tableId')) {
      tableId = _json['tableId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSchema != null) 'dataSchema': dataSchema!,
        if (datasetId != null) 'datasetId': datasetId!,
        if (gcsStagingDir != null) 'gcsStagingDir': gcsStagingDir!,
        if (projectId != null) 'projectId': projectId!,
        if (tableId != null) 'tableId': tableId!,
      };
}

/// The catalog configuration.
class GoogleCloudRetailV2Catalog {
  /// The catalog display name.
  ///
  /// This field must be a UTF-8 encoded string with a length limit of 128
  /// characters. Otherwise, an INVALID_ARGUMENT error is returned.
  ///
  /// Required. Immutable.
  core.String? displayName;

  /// The fully qualified resource name of the catalog.
  ///
  /// Required. Immutable.
  core.String? name;

  /// The product level configuration.
  ///
  /// Required.
  GoogleCloudRetailV2ProductLevelConfig? productLevelConfig;

  GoogleCloudRetailV2Catalog();

  GoogleCloudRetailV2Catalog.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('productLevelConfig')) {
      productLevelConfig = GoogleCloudRetailV2ProductLevelConfig.fromJson(
          _json['productLevelConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
        if (productLevelConfig != null)
          'productLevelConfig': productLevelConfig!.toJson(),
      };
}

/// A custom attribute that is not explicitly modeled in Product.
class GoogleCloudRetailV2CustomAttribute {
  /// The numerical values of this custom attribute.
  ///
  /// For example, `[2.3, 15.4]` when the key is "lengths_cm". At most 400
  /// values are allowed.Otherwise, an INVALID_ARGUMENT error is returned.
  /// Exactly one of text or numbers should be set. Otherwise, an
  /// INVALID_ARGUMENT error is returned.
  core.List<core.double>? numbers;

  /// The textual values of this custom attribute.
  ///
  /// For example, `["yellow", "green"]` when the key is "color". At most 400
  /// values are allowed. Empty values are not allowed. Each value must be a
  /// UTF-8 encoded string with a length limit of 256 characters. Otherwise, an
  /// INVALID_ARGUMENT error is returned. Exactly one of text or numbers should
  /// be set. Otherwise, an INVALID_ARGUMENT error is returned.
  core.List<core.String>? text;

  GoogleCloudRetailV2CustomAttribute();

  GoogleCloudRetailV2CustomAttribute.fromJson(core.Map _json) {
    if (_json.containsKey('numbers')) {
      numbers = (_json['numbers'] as core.List)
          .map<core.double>((value) => (value as core.num).toDouble())
          .toList();
    }
    if (_json.containsKey('text')) {
      text = (_json['text'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (numbers != null) 'numbers': numbers!,
        if (text != null) 'text': text!,
      };
}

/// Google Cloud Storage location for input content.
///
/// format.
class GoogleCloudRetailV2GcsSource {
  /// The schema to use when parsing the data from the source.
  ///
  /// Supported values for product imports: * `product` (default): One JSON
  /// Product per line. Each product must have a valid Product.id. *
  /// `product_merchant_center`: See
  /// [Importing catalog data from Merchant Center](https://cloud.google.com/retail/recommendations-ai/docs/upload-catalog#mc).
  /// Supported values for user events imports: * `user_event` (default): One
  /// JSON UserEvent per line. * `user_event_ga360`: Using
  /// https://support.google.com/analytics/answer/3437719?hl=en.
  core.String? dataSchema;

  /// Google Cloud Storage URIs to input files.
  ///
  /// URI can be up to 2000 characters long. URIs can match the full object path
  /// (for example, `gs://bucket/directory/object.json`) or a pattern matching
  /// one or more files, such as `gs://bucket/directory / * .json`. A request
  /// can contain at most 100 files, and each file can be up to 2 GB. See
  /// [Importing product information](https://cloud.google.com/retail/recommendations-ai/docs/upload-catalog)
  /// for the expected file format and setup instructions.
  ///
  /// Required.
  core.List<core.String>? inputUris;

  GoogleCloudRetailV2GcsSource();

  GoogleCloudRetailV2GcsSource.fromJson(core.Map _json) {
    if (_json.containsKey('dataSchema')) {
      dataSchema = _json['dataSchema'] as core.String;
    }
    if (_json.containsKey('inputUris')) {
      inputUris = (_json['inputUris'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSchema != null) 'dataSchema': dataSchema!,
        if (inputUris != null) 'inputUris': inputUris!,
      };
}

/// Product thumbnail/detail image.
class GoogleCloudRetailV2Image {
  /// Height of the image in number of pixels.
  ///
  /// This field must be nonnegative. Otherwise, an INVALID_ARGUMENT error is
  /// returned.
  core.int? height;

  /// URI of the image.
  ///
  /// This field must be a valid UTF-8 encoded URI with a length limit of 5,000
  /// characters. Otherwise, an INVALID_ARGUMENT error is returned. Google
  /// Merchant Center property
  /// [image_link](https://support.google.com/merchants/answer/6324350).
  /// Schema.org property [Product.image](https://schema.org/image).
  ///
  /// Required.
  core.String? uri;

  /// Width of the image in number of pixels.
  ///
  /// This field must be nonnegative. Otherwise, an INVALID_ARGUMENT error is
  /// returned.
  core.int? width;

  GoogleCloudRetailV2Image();

  GoogleCloudRetailV2Image.fromJson(core.Map _json) {
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (height != null) 'height': height!,
        if (uri != null) 'uri': uri!,
        if (width != null) 'width': width!,
      };
}

/// Configuration of destination for Import related errors.
class GoogleCloudRetailV2ImportErrorsConfig {
  /// Google Cloud Storage path for import errors.
  ///
  /// This must be an empty, existing Cloud Storage bucket. Import errors will
  /// be written to a file in this bucket, one per line, as a JSON-encoded
  /// `google.rpc.Status` message.
  core.String? gcsPrefix;

  GoogleCloudRetailV2ImportErrorsConfig();

  GoogleCloudRetailV2ImportErrorsConfig.fromJson(core.Map _json) {
    if (_json.containsKey('gcsPrefix')) {
      gcsPrefix = _json['gcsPrefix'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gcsPrefix != null) 'gcsPrefix': gcsPrefix!,
      };
}

/// Metadata related to the progress of the Import operation.
///
/// This will be returned by the google.longrunning.Operation.metadata field.
class GoogleCloudRetailV2ImportMetadata {
  /// Operation create time.
  core.String? createTime;

  /// Count of entries that encountered errors while processing.
  core.String? failureCount;

  /// Count of entries that were processed successfully.
  core.String? successCount;

  /// Operation last update time.
  ///
  /// If the operation is done, this is also the finish time.
  core.String? updateTime;

  GoogleCloudRetailV2ImportMetadata();

  GoogleCloudRetailV2ImportMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('failureCount')) {
      failureCount = _json['failureCount'] as core.String;
    }
    if (_json.containsKey('successCount')) {
      successCount = _json['successCount'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (failureCount != null) 'failureCount': failureCount!,
        if (successCount != null) 'successCount': successCount!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Request message for Import methods.
class GoogleCloudRetailV2ImportProductsRequest {
  /// The desired location of errors incurred during the Import.
  GoogleCloudRetailV2ImportErrorsConfig? errorsConfig;

  /// The desired input location of the data.
  ///
  /// Required.
  GoogleCloudRetailV2ProductInputConfig? inputConfig;

  /// Indicates which fields in the provided imported 'products' to update.
  ///
  /// If not set, will by default update all fields.
  core.String? updateMask;

  GoogleCloudRetailV2ImportProductsRequest();

  GoogleCloudRetailV2ImportProductsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('errorsConfig')) {
      errorsConfig = GoogleCloudRetailV2ImportErrorsConfig.fromJson(
          _json['errorsConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inputConfig')) {
      inputConfig = GoogleCloudRetailV2ProductInputConfig.fromJson(
          _json['inputConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateMask')) {
      updateMask = _json['updateMask'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorsConfig != null) 'errorsConfig': errorsConfig!.toJson(),
        if (inputConfig != null) 'inputConfig': inputConfig!.toJson(),
        if (updateMask != null) 'updateMask': updateMask!,
      };
}

/// Response of the ImportProductsRequest.
///
/// If the long running operation is done, then this message is returned by the
/// google.longrunning.Operations.response field if the operation was
/// successful.
class GoogleCloudRetailV2ImportProductsResponse {
  /// A sample of errors encountered while processing the request.
  core.List<GoogleRpcStatus>? errorSamples;

  /// Echoes the destination for the complete errors in the request if set.
  GoogleCloudRetailV2ImportErrorsConfig? errorsConfig;

  GoogleCloudRetailV2ImportProductsResponse();

  GoogleCloudRetailV2ImportProductsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('errorSamples')) {
      errorSamples = (_json['errorSamples'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('errorsConfig')) {
      errorsConfig = GoogleCloudRetailV2ImportErrorsConfig.fromJson(
          _json['errorsConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorSamples != null)
          'errorSamples': errorSamples!.map((value) => value.toJson()).toList(),
        if (errorsConfig != null) 'errorsConfig': errorsConfig!.toJson(),
      };
}

/// Request message for the ImportUserEvents request.
class GoogleCloudRetailV2ImportUserEventsRequest {
  /// The desired location of errors incurred during the Import.
  ///
  /// Cannot be set for inline user event imports.
  GoogleCloudRetailV2ImportErrorsConfig? errorsConfig;

  /// The desired input location of the data.
  ///
  /// Required.
  GoogleCloudRetailV2UserEventInputConfig? inputConfig;

  GoogleCloudRetailV2ImportUserEventsRequest();

  GoogleCloudRetailV2ImportUserEventsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('errorsConfig')) {
      errorsConfig = GoogleCloudRetailV2ImportErrorsConfig.fromJson(
          _json['errorsConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inputConfig')) {
      inputConfig = GoogleCloudRetailV2UserEventInputConfig.fromJson(
          _json['inputConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorsConfig != null) 'errorsConfig': errorsConfig!.toJson(),
        if (inputConfig != null) 'inputConfig': inputConfig!.toJson(),
      };
}

/// Response of the ImportUserEventsRequest.
///
/// If the long running operation was successful, then this message is returned
/// by the google.longrunning.Operations.response field if the operation was
/// successful.
class GoogleCloudRetailV2ImportUserEventsResponse {
  /// A sample of errors encountered while processing the request.
  core.List<GoogleRpcStatus>? errorSamples;

  /// Echoes the destination for the complete errors if this field was set in
  /// the request.
  GoogleCloudRetailV2ImportErrorsConfig? errorsConfig;

  /// Aggregated statistics of user event import status.
  GoogleCloudRetailV2UserEventImportSummary? importSummary;

  GoogleCloudRetailV2ImportUserEventsResponse();

  GoogleCloudRetailV2ImportUserEventsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('errorSamples')) {
      errorSamples = (_json['errorSamples'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('errorsConfig')) {
      errorsConfig = GoogleCloudRetailV2ImportErrorsConfig.fromJson(
          _json['errorsConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('importSummary')) {
      importSummary = GoogleCloudRetailV2UserEventImportSummary.fromJson(
          _json['importSummary'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorSamples != null)
          'errorSamples': errorSamples!.map((value) => value.toJson()).toList(),
        if (errorsConfig != null) 'errorsConfig': errorsConfig!.toJson(),
        if (importSummary != null) 'importSummary': importSummary!.toJson(),
      };
}

/// Response for CatalogService.ListCatalogs method.
class GoogleCloudRetailV2ListCatalogsResponse {
  /// All the customer's Catalogs.
  core.List<GoogleCloudRetailV2Catalog>? catalogs;

  /// A token that can be sent as ListCatalogsRequest.page_token to retrieve the
  /// next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  GoogleCloudRetailV2ListCatalogsResponse();

  GoogleCloudRetailV2ListCatalogsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('catalogs')) {
      catalogs = (_json['catalogs'] as core.List)
          .map<GoogleCloudRetailV2Catalog>((value) =>
              GoogleCloudRetailV2Catalog.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (catalogs != null)
          'catalogs': catalogs!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Request message for Predict method.
class GoogleCloudRetailV2PredictRequest {
  /// Filter for restricting prediction results with a length limit of 5,000
  /// characters.
  ///
  /// Accepts values for tags and the `filterOutOfStockItems` flag. * Tag
  /// expressions. Restricts predictions to products that match all of the
  /// specified tags. Boolean operators `OR` and `NOT` are supported if the
  /// expression is enclosed in parentheses, and must be separated from the tag
  /// values by a space. `-"tagA"` is also supported and is equivalent to `NOT
  /// "tagA"`. Tag values must be double quoted UTF-8 encoded strings with a
  /// size limit of 1,000 characters. Note: "Recently viewed" models don't
  /// support tag filtering at the moment. * filterOutOfStockItems. Restricts
  /// predictions to products that do not have a stockState value of
  /// OUT_OF_STOCK. Examples: * tag=("Red" OR "Blue") tag="New-Arrival" tag=(NOT
  /// "promotional") * filterOutOfStockItems tag=(-"promotional") *
  /// filterOutOfStockItems If your filter blocks all prediction results,
  /// nothing will be returned. If you want generic (unfiltered) popular
  /// products to be returned instead, set `strictFiltering` to false in
  /// `PredictRequest.params`.
  core.String? filter;

  /// The labels applied to a resource must meet the following requirements: *
  /// Each resource can have multiple labels, up to a maximum of 64.
  ///
  /// * Each label must be a key-value pair. * Keys have a minimum length of 1
  /// character and a maximum length of 63 characters, and cannot be empty.
  /// Values can be empty, and have a maximum length of 63 characters. * Keys
  /// and values can contain only lowercase letters, numeric characters,
  /// underscores, and dashes. All characters must use UTF-8 encoding, and
  /// international characters are allowed. * The key portion of a label must be
  /// unique. However, you can use the same key with multiple resources. * Keys
  /// must start with a lowercase letter or international character. See
  /// [Google Cloud Document](https://cloud.google.com/resource-manager/docs/creating-managing-labels#requirements)
  /// for more details.
  core.Map<core.String, core.String>? labels;

  /// Maximum number of results to return per page.
  ///
  /// Set this property to the number of prediction results needed. If zero, the
  /// service will choose a reasonable default. The maximum allowed value is
  /// 100. Values above 100 will be coerced to 100.
  core.int? pageSize;

  /// The previous PredictResponse.next_page_token.
  core.String? pageToken;

  /// Additional domain specific parameters for the predictions.
  ///
  /// Allowed values: * `returnProduct`: Boolean. If set to true, the associated
  /// product object will be returned in the `results.metadata` field in the
  /// prediction response. * `returnScore`: Boolean. If set to true, the
  /// prediction 'score' corresponding to each returned product will be set in
  /// the `results.metadata` field in the prediction response. The given 'score'
  /// indicates the probability of an product being clicked/purchased given the
  /// user's context and history. * `strictFiltering`: Boolean. True by default.
  /// If set to false, the service will return generic (unfiltered) popular
  /// products instead of empty if your filter blocks all prediction results.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? params;

  /// Context about the user, what they are looking at and what action they took
  /// to trigger the predict request.
  ///
  /// Note that this user event detail won't be ingested to userEvent logs.
  /// Thus, a separate userEvent write request is required for event logging.
  ///
  /// Required.
  GoogleCloudRetailV2UserEvent? userEvent;

  /// Use validate only mode for this prediction query.
  ///
  /// If set to true, a dummy model will be used that returns arbitrary
  /// products. Note that the validate only mode should only be used for testing
  /// the API, or if the model is not ready.
  core.bool? validateOnly;

  GoogleCloudRetailV2PredictRequest();

  GoogleCloudRetailV2PredictRequest.fromJson(core.Map _json) {
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
    if (_json.containsKey('params')) {
      params = (_json['params'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('userEvent')) {
      userEvent = GoogleCloudRetailV2UserEvent.fromJson(
          _json['userEvent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('validateOnly')) {
      validateOnly = _json['validateOnly'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filter != null) 'filter': filter!,
        if (labels != null) 'labels': labels!,
        if (pageSize != null) 'pageSize': pageSize!,
        if (pageToken != null) 'pageToken': pageToken!,
        if (params != null) 'params': params!,
        if (userEvent != null) 'userEvent': userEvent!.toJson(),
        if (validateOnly != null) 'validateOnly': validateOnly!,
      };
}

/// Response message for predict method.
class GoogleCloudRetailV2PredictResponse {
  /// A unique attribution token.
  ///
  /// This should be included in the UserEvent logs resulting from this
  /// recommendation, which enables accurate attribution of recommendation model
  /// performance.
  core.String? attributionToken;

  /// IDs of products in the request that were missing from the inventory.
  core.List<core.String>? missingIds;

  /// A list of recommended products.
  ///
  /// The order represents the ranking (from the most relevant product to the
  /// least).
  core.List<GoogleCloudRetailV2PredictResponsePredictionResult>? results;

  /// True if the validateOnly property was set in the request.
  core.bool? validateOnly;

  GoogleCloudRetailV2PredictResponse();

  GoogleCloudRetailV2PredictResponse.fromJson(core.Map _json) {
    if (_json.containsKey('attributionToken')) {
      attributionToken = _json['attributionToken'] as core.String;
    }
    if (_json.containsKey('missingIds')) {
      missingIds = (_json['missingIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.List)
          .map<GoogleCloudRetailV2PredictResponsePredictionResult>((value) =>
              GoogleCloudRetailV2PredictResponsePredictionResult.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('validateOnly')) {
      validateOnly = _json['validateOnly'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributionToken != null) 'attributionToken': attributionToken!,
        if (missingIds != null) 'missingIds': missingIds!,
        if (results != null)
          'results': results!.map((value) => value.toJson()).toList(),
        if (validateOnly != null) 'validateOnly': validateOnly!,
      };
}

/// PredictionResult represents the recommendation prediction results.
class GoogleCloudRetailV2PredictResponsePredictionResult {
  /// ID of the recommended product
  core.String? id;

  /// Additional product metadata / annotations.
  ///
  /// Possible values: * `product`: JSON representation of the product. Will be
  /// set if `returnProduct` is set to true in `PredictRequest.params`. *
  /// `score`: Prediction score in double value. Will be set if `returnScore` is
  /// set to true in `PredictRequest.params`.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  GoogleCloudRetailV2PredictResponsePredictionResult();

  GoogleCloudRetailV2PredictResponsePredictionResult.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (metadata != null) 'metadata': metadata!,
      };
}

/// The price information of a Product.
class GoogleCloudRetailV2PriceInfo {
  /// The costs associated with the sale of a particular product.
  ///
  /// Used for gross profit reporting. * Profit = price - cost Google Merchant
  /// Center property
  /// [cost_of_goods_sold](https://support.google.com/merchants/answer/9017895).
  core.double? cost;

  /// The 3-letter currency code defined in
  /// [ISO 4217](https://www.iso.org/iso-4217-currency-codes.html).
  ///
  /// If this field is an unrecognizable currency code, an INVALID_ARGUMENT
  /// error is returned.
  core.String? currencyCode;

  /// Price of the product without any discount.
  ///
  /// If zero, by default set to be the price.
  core.double? originalPrice;

  /// Price of the product.
  ///
  /// Google Merchant Center property
  /// [price](https://support.google.com/merchants/answer/6324371). Schema.org
  /// property
  /// [Offer.priceSpecification](https://schema.org/priceSpecification).
  core.double? price;

  GoogleCloudRetailV2PriceInfo();

  GoogleCloudRetailV2PriceInfo.fromJson(core.Map _json) {
    if (_json.containsKey('cost')) {
      cost = (_json['cost'] as core.num).toDouble();
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('originalPrice')) {
      originalPrice = (_json['originalPrice'] as core.num).toDouble();
    }
    if (_json.containsKey('price')) {
      price = (_json['price'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cost != null) 'cost': cost!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (originalPrice != null) 'originalPrice': originalPrice!,
        if (price != null) 'price': price!,
      };
}

/// Product captures all metadata information of items to be recommended or
/// searched.
class GoogleCloudRetailV2Product {
  /// Highly encouraged.
  ///
  /// Extra product attributes to be included. For example, for products, this
  /// could include the store name, vendor, style, color, etc. These are very
  /// strong signals for recommendation model, thus we highly recommend
  /// providing the attributes here. Features that can take on one of a limited
  /// number of possible values. Two types of features can be set are: Textual
  /// features. some examples would be the brand/maker of a product, or country
  /// of a customer. Numerical features. Some examples would be the
  /// height/weight of a product, or age of a customer. For example: `{
  /// "vendor": {"text": ["vendor123", "vendor456"]}, "lengths_cm":
  /// {"numbers":[2.3, 15.4]}, "heights_cm": {"numbers":[8.1, 6.4]} }`. This
  /// field needs to pass all below criteria, otherwise an INVALID_ARGUMENT
  /// error is returned: * Max entries count: 200 by default; 100 for
  /// Type.VARIANT. * The key must be a UTF-8 encoded string with a length limit
  /// of 128 characters.
  core.Map<core.String, GoogleCloudRetailV2CustomAttribute>? attributes;

  /// The online availability of the Product.
  ///
  /// Default to Availability.IN_STOCK. Google Merchant Center Property
  /// [availability](https://support.google.com/merchants/answer/6324448).
  /// Schema.org Property [Offer.availability](https://schema.org/availability).
  /// Possible string values are:
  /// - "AVAILABILITY_UNSPECIFIED" : Default product availability. Default to
  /// Availability.IN_STOCK if unset.
  /// - "IN_STOCK" : Product in stock.
  /// - "OUT_OF_STOCK" : Product out of stock.
  /// - "PREORDER" : Product that is in pre-order state.
  /// - "BACKORDER" : Product that is back-ordered (i.e. temporarily out of
  /// stock).
  core.String? availability;

  /// The available quantity of the item.
  core.int? availableQuantity;

  /// The timestamp when this Product becomes available for recommendation.
  core.String? availableTime;

  /// Product categories.
  ///
  /// This field is repeated for supporting one product belonging to several
  /// parallel categories. Strongly recommended using the full path for better
  /// search / recommendation quality. To represent full path of category, use
  /// '>' sign to separate different hierarchies. If '>' is part of the category
  /// name, please replace it with other character(s). For example, if a shoes
  /// product belongs to both \["Shoes & Accessories" -> "Shoes"\] and \["Sports
  /// & Fitness" -> "Athletic Clothing" -> "Shoes"\], it could be represented
  /// as: "categories": \[ "Shoes & Accessories > Shoes", "Sports & Fitness >
  /// Athletic Clothing > Shoes" \] Must be set for Type.PRIMARY Product
  /// otherwise an INVALID_ARGUMENT error is returned. At most 250 values are
  /// allowed per Product. Empty values are not allowed. Each value must be a
  /// UTF-8 encoded string with a length limit of 5,000 characters. Otherwise,
  /// an INVALID_ARGUMENT error is returned. Google Merchant Center property
  /// google_product_category. Schema.org property
  /// [Product.category](https://schema.org/category).
  /// \[mc_google_product_category\]:
  /// https://support.google.com/merchants/answer/6324436
  core.List<core.String>? categories;

  /// Product description.
  ///
  /// This field must be a UTF-8 encoded string with a length limit of 5,000
  /// characters. Otherwise, an INVALID_ARGUMENT error is returned. Google
  /// Merchant Center property
  /// [description](https://support.google.com/merchants/answer/6324468).
  /// schema.org property [Product.description](https://schema.org/description).
  core.String? description;

  /// Product identifier, which is the final component of name.
  ///
  /// For example, this field is "id_1", if name is `projects / *
  /// /locations/global/catalogs/default_catalog/branches/default_branch/products/id_1`.
  /// This field must be a UTF-8 encoded string with a length limit of 128
  /// characters. Otherwise, an INVALID_ARGUMENT error is returned. Google
  /// Merchant Center property
  /// [id](https://support.google.com/merchants/answer/6324405). Schema.org
  /// Property [Product.sku](https://schema.org/sku).
  ///
  /// Immutable.
  core.String? id;

  /// Product images for the product.Highly recommended to put the main image to
  /// the first.
  ///
  /// A maximum of 300 images are allowed. Google Merchant Center property
  /// [image_link](https://support.google.com/merchants/answer/6324350).
  /// Schema.org property [Product.image](https://schema.org/image).
  core.List<GoogleCloudRetailV2Image>? images;

  /// Full resource name of the product, such as `projects / *
  /// /locations/global/catalogs/default_catalog/branches/default_branch/products/product_id`.
  ///
  /// The branch ID must be "default_branch".
  ///
  /// Immutable.
  core.String? name;

  /// Product price and cost information.
  ///
  /// Google Merchant Center property
  /// [price](https://support.google.com/merchants/answer/6324371).
  GoogleCloudRetailV2PriceInfo? priceInfo;

  /// Variant group identifier.
  ///
  /// Must be an id, with the same parent branch with this product. Otherwise,
  /// an error is thrown. For Type.PRIMARY Products, this field can only be
  /// empty or set to the same value as id. For VARIANT Products, this field
  /// cannot be empty. A maximum of 2,000 products are allowed to share the same
  /// Type.PRIMARY Product. Otherwise, an INVALID_ARGUMENT error is returned.
  /// Google Merchant Center Property
  /// [item_group_id](https://support.google.com/merchants/answer/6324507).
  /// Schema.org Property
  /// [Product.inProductGroupWithID](https://schema.org/inProductGroupWithID).
  /// This field must be enabled before it can be used. \[Learn
  /// more\](/recommendations-ai/docs/catalog#item-group-id).
  core.String? primaryProductId;

  /// Custom tags associated with the product.
  ///
  /// At most 250 values are allowed per Product. This value must be a UTF-8
  /// encoded string with a length limit of 1,000 characters. Otherwise, an
  /// INVALID_ARGUMENT error is returned. This tag can be used for filtering
  /// recommendation results by passing the tag as part of the
  /// PredictRequest.filter. Google Merchant Center property
  /// \[custom_label_0–4\](https://support.google.com/merchants/answer/6324473).
  core.List<core.String>? tags;

  /// Product title.
  ///
  /// This field must be a UTF-8 encoded string with a length limit of 1,000
  /// characters. Otherwise, an INVALID_ARGUMENT error is returned. Google
  /// Merchant Center property
  /// [title](https://support.google.com/merchants/answer/6324415). Schema.org
  /// property [Product.name](https://schema.org/name).
  ///
  /// Required.
  core.String? title;

  /// The type of the product.
  ///
  /// Default to Catalog.product_level_config.ingestion_product_type if unset.
  ///
  /// Immutable.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default value. Default to
  /// Catalog.product_level_config.ingestion_product_type if unset.
  /// - "PRIMARY" : The primary type. As the primary unit for predicting,
  /// indexing and search serving, a Type.PRIMARY Product is grouped with
  /// multiple Type.VARIANT Products.
  /// - "VARIANT" : The variant type. Type.VARIANT Products usually share some
  /// common attributes on the same Type.PRIMARY Products, but they have variant
  /// attributes like different colors, sizes and prices, etc.
  /// - "COLLECTION" : The collection type. Collection products are bundled
  /// Type.PRIMARY Products or Type.VARIANT Products that are sold together,
  /// such as a jewelry set with necklaces, earrings and rings, etc.
  core.String? type;

  /// Canonical URL directly linking to the product detail page.
  ///
  /// It is strongly recommended to provide a valid uri for the product,
  /// otherwise the service performance could be significantly degraded. This
  /// field must be a UTF-8 encoded string with a length limit of 5,000
  /// characters. Otherwise, an INVALID_ARGUMENT error is returned. Google
  /// Merchant Center property
  /// [link](https://support.google.com/merchants/answer/6324416). Schema.org
  /// property [Offer.url](https://schema.org/url).
  core.String? uri;

  GoogleCloudRetailV2Product();

  GoogleCloudRetailV2Product.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes =
          (_json['attributes'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          GoogleCloudRetailV2CustomAttribute.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('availability')) {
      availability = _json['availability'] as core.String;
    }
    if (_json.containsKey('availableQuantity')) {
      availableQuantity = _json['availableQuantity'] as core.int;
    }
    if (_json.containsKey('availableTime')) {
      availableTime = _json['availableTime'] as core.String;
    }
    if (_json.containsKey('categories')) {
      categories = (_json['categories'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('images')) {
      images = (_json['images'] as core.List)
          .map<GoogleCloudRetailV2Image>((value) =>
              GoogleCloudRetailV2Image.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('priceInfo')) {
      priceInfo = GoogleCloudRetailV2PriceInfo.fromJson(
          _json['priceInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('primaryProductId')) {
      primaryProductId = _json['primaryProductId'] as core.String;
    }
    if (_json.containsKey('tags')) {
      tags = (_json['tags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null)
          'attributes':
              attributes!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (availability != null) 'availability': availability!,
        if (availableQuantity != null) 'availableQuantity': availableQuantity!,
        if (availableTime != null) 'availableTime': availableTime!,
        if (categories != null) 'categories': categories!,
        if (description != null) 'description': description!,
        if (id != null) 'id': id!,
        if (images != null)
          'images': images!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (priceInfo != null) 'priceInfo': priceInfo!.toJson(),
        if (primaryProductId != null) 'primaryProductId': primaryProductId!,
        if (tags != null) 'tags': tags!,
        if (title != null) 'title': title!,
        if (type != null) 'type': type!,
        if (uri != null) 'uri': uri!,
      };
}

/// Detailed product information associated with a user event.
class GoogleCloudRetailV2ProductDetail {
  /// Product information.
  ///
  /// Only Product.id field is used when ingesting an event, all other product
  /// fields are ignored as we will look them up from the catalog.
  ///
  /// Required.
  GoogleCloudRetailV2Product? product;

  /// Quantity of the product associated with the user event.
  ///
  /// For example, this field will be 2 if two products are added to the
  /// shopping cart for `purchase-complete` event. Required for `add-to-cart`
  /// and `purchase-complete` event types.
  core.int? quantity;

  GoogleCloudRetailV2ProductDetail();

  GoogleCloudRetailV2ProductDetail.fromJson(core.Map _json) {
    if (_json.containsKey('product')) {
      product = GoogleCloudRetailV2Product.fromJson(
          _json['product'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (product != null) 'product': product!.toJson(),
        if (quantity != null) 'quantity': quantity!,
      };
}

/// The inline source for the input config for ImportProducts method.
class GoogleCloudRetailV2ProductInlineSource {
  /// A list of products to update/create.
  ///
  /// Each product must have a valid Product.id. Recommended max of 10k items.
  ///
  /// Required.
  core.List<GoogleCloudRetailV2Product>? products;

  GoogleCloudRetailV2ProductInlineSource();

  GoogleCloudRetailV2ProductInlineSource.fromJson(core.Map _json) {
    if (_json.containsKey('products')) {
      products = (_json['products'] as core.List)
          .map<GoogleCloudRetailV2Product>((value) =>
              GoogleCloudRetailV2Product.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (products != null)
          'products': products!.map((value) => value.toJson()).toList(),
      };
}

/// The input config source for products.
class GoogleCloudRetailV2ProductInputConfig {
  /// BigQuery input source.
  GoogleCloudRetailV2BigQuerySource? bigQuerySource;

  /// Google Cloud Storage location for the input content.
  GoogleCloudRetailV2GcsSource? gcsSource;

  /// The Inline source for the input content for products.
  GoogleCloudRetailV2ProductInlineSource? productInlineSource;

  GoogleCloudRetailV2ProductInputConfig();

  GoogleCloudRetailV2ProductInputConfig.fromJson(core.Map _json) {
    if (_json.containsKey('bigQuerySource')) {
      bigQuerySource = GoogleCloudRetailV2BigQuerySource.fromJson(
          _json['bigQuerySource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gcsSource')) {
      gcsSource = GoogleCloudRetailV2GcsSource.fromJson(
          _json['gcsSource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('productInlineSource')) {
      productInlineSource = GoogleCloudRetailV2ProductInlineSource.fromJson(
          _json['productInlineSource'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bigQuerySource != null) 'bigQuerySource': bigQuerySource!.toJson(),
        if (gcsSource != null) 'gcsSource': gcsSource!.toJson(),
        if (productInlineSource != null)
          'productInlineSource': productInlineSource!.toJson(),
      };
}

/// Configures what level the product should be uploaded with regards to how
/// users will be send events and how predictions will be made.
class GoogleCloudRetailV2ProductLevelConfig {
  /// The type of Products allowed to be ingested into the catalog.
  ///
  /// Acceptable values are: * `primary` (default): You can only ingest
  /// Product.Type.PRIMARY Products. This means Product.primary_product_id can
  /// only be empty or set to the same value as Product.id. * `variant`: You can
  /// only ingest Product.Type.VARIANT Products. This means
  /// Product.primary_product_id cannot be empty. If this field is set to an
  /// invalid value other than these, an INVALID_ARGUMENT error is returned. If
  /// this field is `variant` and merchant_center_product_id_field is
  /// `itemGroupId`, an INVALID_ARGUMENT error is returned. See
  /// [Using product levels](https://cloud.google.com/retail/recommendations-ai/docs/catalog#product-levels)
  /// for more details.
  core.String? ingestionProductType;

  /// Which field of \[Merchant Center
  /// Product\](/bigquery-transfer/docs/merchant-center-products-schema) should
  /// be imported as Product.id.
  ///
  /// Acceptable values are: * `offerId` (default): Import `offerId` as the
  /// product ID. * `itemGroupId`: Import `itemGroupId` as the product ID.
  /// Notice that Retail API will choose one item from the ones with the same
  /// `itemGroupId`, and use it to represent the item group. If this field is
  /// set to an invalid value other than these, an INVALID_ARGUMENT error is
  /// returned. If this field is `itemGroupId` and ingestion_product_type is
  /// `variant`, an INVALID_ARGUMENT error is returned. See
  /// [Using product levels](https://cloud.google.com/retail/recommendations-ai/docs/catalog#product-levels)
  /// for more details.
  core.String? merchantCenterProductIdField;

  GoogleCloudRetailV2ProductLevelConfig();

  GoogleCloudRetailV2ProductLevelConfig.fromJson(core.Map _json) {
    if (_json.containsKey('ingestionProductType')) {
      ingestionProductType = _json['ingestionProductType'] as core.String;
    }
    if (_json.containsKey('merchantCenterProductIdField')) {
      merchantCenterProductIdField =
          _json['merchantCenterProductIdField'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ingestionProductType != null)
          'ingestionProductType': ingestionProductType!,
        if (merchantCenterProductIdField != null)
          'merchantCenterProductIdField': merchantCenterProductIdField!,
      };
}

/// A transaction represents the entire purchase transaction.
class GoogleCloudRetailV2PurchaseTransaction {
  /// All the costs associated with the products.
  ///
  /// These can be manufacturing costs, shipping expenses not borne by the end
  /// user, or any other costs, such that: * Profit = revenue - tax - cost
  core.double? cost;

  /// Currency code.
  ///
  /// Use three-character ISO-4217 code.
  ///
  /// Required.
  core.String? currencyCode;

  /// The transaction ID with a length limit of 128 characters.
  core.String? id;

  /// Total non-zero revenue or grand total associated with the transaction.
  ///
  /// This value include shipping, tax, or other adjustments to total revenue
  /// that you want to include as part of your revenue calculations.
  ///
  /// Required.
  core.double? revenue;

  /// All the taxes associated with the transaction.
  core.double? tax;

  GoogleCloudRetailV2PurchaseTransaction();

  GoogleCloudRetailV2PurchaseTransaction.fromJson(core.Map _json) {
    if (_json.containsKey('cost')) {
      cost = (_json['cost'] as core.num).toDouble();
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('revenue')) {
      revenue = (_json['revenue'] as core.num).toDouble();
    }
    if (_json.containsKey('tax')) {
      tax = (_json['tax'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cost != null) 'cost': cost!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (id != null) 'id': id!,
        if (revenue != null) 'revenue': revenue!,
        if (tax != null) 'tax': tax!,
      };
}

/// Metadata related to the progress of the Purge operation.
///
/// This will be returned by the google.longrunning.Operation.metadata field.
class GoogleCloudRetailV2PurgeMetadata {
  GoogleCloudRetailV2PurgeMetadata();

  GoogleCloudRetailV2PurgeMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request message for PurgeUserEvents method.
class GoogleCloudRetailV2PurgeUserEventsRequest {
  /// The filter string to specify the events to be deleted with a length limit
  /// of 5,000 characters.
  ///
  /// Empty string filter is not allowed. The eligible fields for filtering are:
  /// * `eventType`: Double quoted UserEvent.event_type string. * `eventTime`:
  /// in ISO 8601 "zulu" format. * `visitorId`: Double quoted string. Specifying
  /// this will delete all events associated with a visitor. * `userId`: Double
  /// quoted string. Specifying this will delete all events associated with a
  /// user. Examples: * Deleting all events in a time range: `eventTime >
  /// "2012-04-23T18:25:43.511Z" eventTime < "2012-04-23T18:30:43.511Z"` *
  /// Deleting specific eventType in time range: `eventTime >
  /// "2012-04-23T18:25:43.511Z" eventType = "detail-page-view"` * Deleting all
  /// events for a specific visitor: `visitorId = "visitor1024"` The filtering
  /// fields are assumed to have an implicit AND.
  ///
  /// Required.
  core.String? filter;

  /// Actually perform the purge.
  ///
  /// If `force` is set to false, the method will return the expected purge
  /// count without deleting any user events.
  core.bool? force;

  GoogleCloudRetailV2PurgeUserEventsRequest();

  GoogleCloudRetailV2PurgeUserEventsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('force')) {
      force = _json['force'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filter != null) 'filter': filter!,
        if (force != null) 'force': force!,
      };
}

/// Response of the PurgeUserEventsRequest.
///
/// If the long running operation is successfully done, then this message is
/// returned by the google.longrunning.Operations.response field.
class GoogleCloudRetailV2PurgeUserEventsResponse {
  /// The total count of events purged as a result of the operation.
  core.String? purgedEventsCount;

  GoogleCloudRetailV2PurgeUserEventsResponse();

  GoogleCloudRetailV2PurgeUserEventsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('purgedEventsCount')) {
      purgedEventsCount = _json['purgedEventsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (purgedEventsCount != null) 'purgedEventsCount': purgedEventsCount!,
      };
}

/// Metadata for RejoinUserEvents method.
class GoogleCloudRetailV2RejoinUserEventsMetadata {
  GoogleCloudRetailV2RejoinUserEventsMetadata();

  GoogleCloudRetailV2RejoinUserEventsMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request message for RejoinUserEvents method.
class GoogleCloudRetailV2RejoinUserEventsRequest {
  /// The type of the user event rejoin to define the scope and range of the
  /// user events to be rejoined with the latest product catalog.
  ///
  /// Defaults to USER_EVENT_REJOIN_SCOPE_UNSPECIFIED if this field is not set,
  /// or set to an invalid integer value.
  /// Possible string values are:
  /// - "USER_EVENT_REJOIN_SCOPE_UNSPECIFIED" : Rejoin all events with the
  /// latest product catalog, including both joined events and unjoined events.
  /// - "JOINED_EVENTS" : Only rejoin joined events with the latest product
  /// catalog.
  /// - "UNJOINED_EVENTS" : Only rejoin unjoined events with the latest product
  /// catalog.
  core.String? userEventRejoinScope;

  GoogleCloudRetailV2RejoinUserEventsRequest();

  GoogleCloudRetailV2RejoinUserEventsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('userEventRejoinScope')) {
      userEventRejoinScope = _json['userEventRejoinScope'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (userEventRejoinScope != null)
          'userEventRejoinScope': userEventRejoinScope!,
      };
}

/// Response message for RejoinUserEvents method.
class GoogleCloudRetailV2RejoinUserEventsResponse {
  /// Number of user events that were joined with latest product catalog.
  core.String? rejoinedUserEventsCount;

  GoogleCloudRetailV2RejoinUserEventsResponse();

  GoogleCloudRetailV2RejoinUserEventsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('rejoinedUserEventsCount')) {
      rejoinedUserEventsCount = _json['rejoinedUserEventsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rejoinedUserEventsCount != null)
          'rejoinedUserEventsCount': rejoinedUserEventsCount!,
      };
}

/// UserEvent captures all metadata information Retail API needs to know about
/// how end users interact with customers' website.
class GoogleCloudRetailV2UserEvent {
  /// Extra user event features to include in the recommendation model.
  ///
  /// The key must be a UTF-8 encoded string with a length limit of 5,000
  /// characters. Otherwise, an INVALID_ARGUMENT error is returned. For product
  /// recommendation, an example of extra user information is traffic_channel,
  /// i.e. how user arrives at the site. Users can arrive at the site by coming
  /// to the site directly, or coming through Google search, and etc.
  core.Map<core.String, GoogleCloudRetailV2CustomAttribute>? attributes;

  /// Highly recommended for user events that are the result of
  /// PredictionService.Predict.
  ///
  /// This field enables accurate attribution of recommendation model
  /// performance. The value must be a valid PredictResponse.attribution_token
  /// for user events that are the result of PredictionService.Predict. This
  /// token enables us to accurately attribute page view or purchase back to the
  /// event and the particular predict response containing this
  /// clicked/purchased product. If user clicks on product K in the
  /// recommendation results, pass PredictResponse.attribution_token as a URL
  /// parameter to product K's page. When recording events on product K's page,
  /// log the PredictResponse.attribution_token to this field.
  core.String? attributionToken;

  /// The id or name of the associated shopping cart.
  ///
  /// This id is used to associate multiple items added or present in the cart
  /// before purchase. This can only be set for `add-to-cart`,
  /// `purchase-complete`, or `shopping-cart-page-view` events.
  core.String? cartId;

  /// Only required for UserEventService.ImportUserEvents method.
  ///
  /// Timestamp of when the user event happened.
  core.String? eventTime;

  /// User event type.
  ///
  /// Allowed values are: * `add-to-cart`: Products being added to cart. *
  /// `category-page-view`: Special pages such as sale or promotion pages
  /// viewed. * `detail-page-view`: Products detail page viewed. *
  /// `home-page-view`: Homepage viewed. * `promotion-offered`: Promotion is
  /// offered to a user. * `promotion-not-offered`: Promotion is not offered to
  /// a user. * `purchase-complete`: User finishing a purchase. * `search`:
  /// Product search. * `shopping-cart-page-view`: User viewing a shopping cart.
  ///
  /// Required.
  core.String? eventType;

  /// A list of identifiers for the independent experiment groups this user
  /// event belongs to.
  ///
  /// This is used to distinguish between user events associated with different
  /// experiment setups (e.g. using Retail API, using different recommendation
  /// models).
  core.List<core.String>? experimentIds;

  /// The categories associated with a category page.
  ///
  /// To represent full path of category, use '>' sign to separate different
  /// hierarchies. If '>' is part of the category name, please replace it with
  /// other character(s). Category pages include special pages such as sales or
  /// promotions. For instance, a special sale page may have the category
  /// hierarchy: "pageCategories" : \["Sales > 2017 Black Friday Deals"\].
  /// Required for `category-page-view` events. At least one of search_query or
  /// page_categories is required for `search` events. Other event types should
  /// not set this field. Otherwise, an INVALID_ARGUMENT error is returned.
  core.List<core.String>? pageCategories;

  /// A unique id of a web page view.
  ///
  /// This should be kept the same for all user events triggered from the same
  /// pageview. For example, an item detail page view could trigger multiple
  /// events as the user is browsing the page. The `pageViewId` property should
  /// be kept the same for all these events so that they can be grouped together
  /// properly. When using the client side event reporting with JavaScript pixel
  /// and Google Tag Manager, this value is filled in automatically.
  core.String? pageViewId;

  /// The main product details related to the event.
  ///
  /// This field is required for the following event types: * `add-to-cart` *
  /// `detail-page-view` * `purchase-complete` In a `search` event, this field
  /// represents the products returned to the end user on the current page (the
  /// end user may have not finished broswing the whole page yet). When a new
  /// page is returned to the end user, after pagination/filtering/ordering even
  /// for the same query, a new `search` event with different product_details is
  /// desired. The end user may have not finished broswing the whole page yet.
  core.List<GoogleCloudRetailV2ProductDetail>? productDetails;

  /// A transaction represents the entire purchase transaction.
  ///
  /// Required for `purchase-complete` events. Other event types should not set
  /// this field. Otherwise, an INVALID_ARGUMENT error is returned.
  GoogleCloudRetailV2PurchaseTransaction? purchaseTransaction;

  /// The referrer URL of the current page.
  ///
  /// When using the client side event reporting with JavaScript pixel and
  /// Google Tag Manager, this value is filled in automatically.
  core.String? referrerUri;

  /// The user's search query.
  ///
  /// The value must be a UTF-8 encoded string with a length limit of 5,000
  /// characters. Otherwise, an INVALID_ARGUMENT error is returned. At least one
  /// of search_query or page_categories is required for `search` events. Other
  /// event types should not set this field. Otherwise, an INVALID_ARGUMENT
  /// error is returned.
  core.String? searchQuery;

  /// Complete URL (window.location.href) of the user's current page.
  ///
  /// When using the client side event reporting with JavaScript pixel and
  /// Google Tag Manager, this value is filled in automatically. Maximum length
  /// 5,000 characters.
  core.String? uri;

  /// User information.
  GoogleCloudRetailV2UserInfo? userInfo;

  /// A unique identifier for tracking visitors.
  ///
  /// For example, this could be implemented with an HTTP cookie, which should
  /// be able to uniquely identify a visitor on a single device. This unique
  /// identifier should not change if the visitor log in/out of the website. The
  /// field must be a UTF-8 encoded string with a length limit of 128
  /// characters. Otherwise, an INVALID_ARGUMENT error is returned. The field
  /// should not contain PII or user-data. We recommend to use Google Analystics
  /// [Client ID](https://developers.google.com/analytics/devguides/collection/analyticsjs/field-reference#clientId)
  /// for this field.
  ///
  /// Required.
  core.String? visitorId;

  GoogleCloudRetailV2UserEvent();

  GoogleCloudRetailV2UserEvent.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes =
          (_json['attributes'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          GoogleCloudRetailV2CustomAttribute.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('attributionToken')) {
      attributionToken = _json['attributionToken'] as core.String;
    }
    if (_json.containsKey('cartId')) {
      cartId = _json['cartId'] as core.String;
    }
    if (_json.containsKey('eventTime')) {
      eventTime = _json['eventTime'] as core.String;
    }
    if (_json.containsKey('eventType')) {
      eventType = _json['eventType'] as core.String;
    }
    if (_json.containsKey('experimentIds')) {
      experimentIds = (_json['experimentIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('pageCategories')) {
      pageCategories = (_json['pageCategories'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('pageViewId')) {
      pageViewId = _json['pageViewId'] as core.String;
    }
    if (_json.containsKey('productDetails')) {
      productDetails = (_json['productDetails'] as core.List)
          .map<GoogleCloudRetailV2ProductDetail>((value) =>
              GoogleCloudRetailV2ProductDetail.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('purchaseTransaction')) {
      purchaseTransaction = GoogleCloudRetailV2PurchaseTransaction.fromJson(
          _json['purchaseTransaction'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('referrerUri')) {
      referrerUri = _json['referrerUri'] as core.String;
    }
    if (_json.containsKey('searchQuery')) {
      searchQuery = _json['searchQuery'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
    if (_json.containsKey('userInfo')) {
      userInfo = GoogleCloudRetailV2UserInfo.fromJson(
          _json['userInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('visitorId')) {
      visitorId = _json['visitorId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null)
          'attributes':
              attributes!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (attributionToken != null) 'attributionToken': attributionToken!,
        if (cartId != null) 'cartId': cartId!,
        if (eventTime != null) 'eventTime': eventTime!,
        if (eventType != null) 'eventType': eventType!,
        if (experimentIds != null) 'experimentIds': experimentIds!,
        if (pageCategories != null) 'pageCategories': pageCategories!,
        if (pageViewId != null) 'pageViewId': pageViewId!,
        if (productDetails != null)
          'productDetails':
              productDetails!.map((value) => value.toJson()).toList(),
        if (purchaseTransaction != null)
          'purchaseTransaction': purchaseTransaction!.toJson(),
        if (referrerUri != null) 'referrerUri': referrerUri!,
        if (searchQuery != null) 'searchQuery': searchQuery!,
        if (uri != null) 'uri': uri!,
        if (userInfo != null) 'userInfo': userInfo!.toJson(),
        if (visitorId != null) 'visitorId': visitorId!,
      };
}

/// A summary of import result.
///
/// The UserEventImportSummary summarizes the import status for user events.
class GoogleCloudRetailV2UserEventImportSummary {
  /// Count of user events imported with complete existing catalog information.
  core.String? joinedEventsCount;

  /// Count of user events imported, but with catalog information not found in
  /// the imported catalog.
  core.String? unjoinedEventsCount;

  GoogleCloudRetailV2UserEventImportSummary();

  GoogleCloudRetailV2UserEventImportSummary.fromJson(core.Map _json) {
    if (_json.containsKey('joinedEventsCount')) {
      joinedEventsCount = _json['joinedEventsCount'] as core.String;
    }
    if (_json.containsKey('unjoinedEventsCount')) {
      unjoinedEventsCount = _json['unjoinedEventsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (joinedEventsCount != null) 'joinedEventsCount': joinedEventsCount!,
        if (unjoinedEventsCount != null)
          'unjoinedEventsCount': unjoinedEventsCount!,
      };
}

/// The inline source for the input config for ImportUserEvents method.
class GoogleCloudRetailV2UserEventInlineSource {
  /// A list of user events to import.
  ///
  /// Recommended max of 10k items.
  ///
  /// Required.
  core.List<GoogleCloudRetailV2UserEvent>? userEvents;

  GoogleCloudRetailV2UserEventInlineSource();

  GoogleCloudRetailV2UserEventInlineSource.fromJson(core.Map _json) {
    if (_json.containsKey('userEvents')) {
      userEvents = (_json['userEvents'] as core.List)
          .map<GoogleCloudRetailV2UserEvent>((value) =>
              GoogleCloudRetailV2UserEvent.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (userEvents != null)
          'userEvents': userEvents!.map((value) => value.toJson()).toList(),
      };
}

/// The input config source for user events.
class GoogleCloudRetailV2UserEventInputConfig {
  /// BigQuery input source.
  ///
  /// Required.
  GoogleCloudRetailV2BigQuerySource? bigQuerySource;

  /// Google Cloud Storage location for the input content.
  ///
  /// Required.
  GoogleCloudRetailV2GcsSource? gcsSource;

  /// The Inline source for the input content for UserEvents.
  ///
  /// Required.
  GoogleCloudRetailV2UserEventInlineSource? userEventInlineSource;

  GoogleCloudRetailV2UserEventInputConfig();

  GoogleCloudRetailV2UserEventInputConfig.fromJson(core.Map _json) {
    if (_json.containsKey('bigQuerySource')) {
      bigQuerySource = GoogleCloudRetailV2BigQuerySource.fromJson(
          _json['bigQuerySource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gcsSource')) {
      gcsSource = GoogleCloudRetailV2GcsSource.fromJson(
          _json['gcsSource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('userEventInlineSource')) {
      userEventInlineSource = GoogleCloudRetailV2UserEventInlineSource.fromJson(
          _json['userEventInlineSource']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bigQuerySource != null) 'bigQuerySource': bigQuerySource!.toJson(),
        if (gcsSource != null) 'gcsSource': gcsSource!.toJson(),
        if (userEventInlineSource != null)
          'userEventInlineSource': userEventInlineSource!.toJson(),
      };
}

/// Information of an end user.
class GoogleCloudRetailV2UserInfo {
  /// True if the request is made directly from the end user, in which case the
  /// ip_address and user_agent can be populated from the HTTP request.
  ///
  /// This flag should be set only if the API request is made directly from the
  /// end user such as a mobile app (and not if a gateway or a server is
  /// processing and pushing the user events). This should not be set when using
  /// the JavaScript tag in UserEventService.CollectUserEvent.
  core.bool? directUserRequest;

  /// The end user's IP address.
  ///
  /// This field is used to extract location information for personalization.
  /// This field must be either an IPv4 address (e.g. "104.133.9.80") or an IPv6
  /// address (e.g. "2001:0db8:85a3:0000:0000:8a2e:0370:7334"). Otherwise, an
  /// INVALID_ARGUMENT error is returned. This should not be set when using the
  /// JavaScript tag in UserEventService.CollectUserEvent or if
  /// direct_user_request is set.
  core.String? ipAddress;

  /// User agent as included in the HTTP header.
  ///
  /// The field must be a UTF-8 encoded string with a length limit of 1,000
  /// characters. Otherwise, an INVALID_ARGUMENT error is returned. This should
  /// not be set when using the client side event reporting with GTM or
  /// JavaScript tag in UserEventService.CollectUserEvent or if
  /// direct_user_request is set.
  core.String? userAgent;

  /// Highly recommended for logged-in users.
  ///
  /// Unique identifier for logged-in user, such as a user name. The field must
  /// be a UTF-8 encoded string with a length limit of 128 characters.
  /// Otherwise, an INVALID_ARGUMENT error is returned.
  core.String? userId;

  GoogleCloudRetailV2UserInfo();

  GoogleCloudRetailV2UserInfo.fromJson(core.Map _json) {
    if (_json.containsKey('directUserRequest')) {
      directUserRequest = _json['directUserRequest'] as core.bool;
    }
    if (_json.containsKey('ipAddress')) {
      ipAddress = _json['ipAddress'] as core.String;
    }
    if (_json.containsKey('userAgent')) {
      userAgent = _json['userAgent'] as core.String;
    }
    if (_json.containsKey('userId')) {
      userId = _json['userId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (directUserRequest != null) 'directUserRequest': directUserRequest!,
        if (ipAddress != null) 'ipAddress': ipAddress!,
        if (userAgent != null) 'userAgent': userAgent!,
        if (userId != null) 'userId': userId!,
      };
}

/// Configuration of destination for Export related errors.
class GoogleCloudRetailV2alphaExportErrorsConfig {
  /// Google Cloud Storage path for import errors.
  ///
  /// This must be an empty, existing Cloud Storage bucket. Export errors will
  /// be written to a file in this bucket, one per line, as a JSON-encoded
  /// `google.rpc.Status` message.
  core.String? gcsPrefix;

  GoogleCloudRetailV2alphaExportErrorsConfig();

  GoogleCloudRetailV2alphaExportErrorsConfig.fromJson(core.Map _json) {
    if (_json.containsKey('gcsPrefix')) {
      gcsPrefix = _json['gcsPrefix'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gcsPrefix != null) 'gcsPrefix': gcsPrefix!,
      };
}

/// Metadata related to the progress of the Export operation.
///
/// This will be returned by the google.longrunning.Operation.metadata field.
class GoogleCloudRetailV2alphaExportMetadata {
  /// Operation create time.
  core.String? createTime;

  /// Operation last update time.
  ///
  /// If the operation is done, this is also the finish time.
  core.String? updateTime;

  GoogleCloudRetailV2alphaExportMetadata();

  GoogleCloudRetailV2alphaExportMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Response of the ExportProductsRequest.
///
/// If the long running operation is done, then this message is returned by the
/// google.longrunning.Operations.response field if the operation was
/// successful.
class GoogleCloudRetailV2alphaExportProductsResponse {
  /// A sample of errors encountered while processing the request.
  core.List<GoogleRpcStatus>? errorSamples;

  /// Echoes the destination for the complete errors in the request if set.
  GoogleCloudRetailV2alphaExportErrorsConfig? errorsConfig;

  GoogleCloudRetailV2alphaExportProductsResponse();

  GoogleCloudRetailV2alphaExportProductsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('errorSamples')) {
      errorSamples = (_json['errorSamples'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('errorsConfig')) {
      errorsConfig = GoogleCloudRetailV2alphaExportErrorsConfig.fromJson(
          _json['errorsConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorSamples != null)
          'errorSamples': errorSamples!.map((value) => value.toJson()).toList(),
        if (errorsConfig != null) 'errorsConfig': errorsConfig!.toJson(),
      };
}

/// Response of the ExportUserEventsRequest.
///
/// If the long running operation was successful, then this message is returned
/// by the google.longrunning.Operations.response field if the operation was
/// successful.
class GoogleCloudRetailV2alphaExportUserEventsResponse {
  /// A sample of errors encountered while processing the request.
  core.List<GoogleRpcStatus>? errorSamples;

  /// Echoes the destination for the complete errors if this field was set in
  /// the request.
  GoogleCloudRetailV2alphaExportErrorsConfig? errorsConfig;

  GoogleCloudRetailV2alphaExportUserEventsResponse();

  GoogleCloudRetailV2alphaExportUserEventsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('errorSamples')) {
      errorSamples = (_json['errorSamples'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('errorsConfig')) {
      errorsConfig = GoogleCloudRetailV2alphaExportErrorsConfig.fromJson(
          _json['errorsConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorSamples != null)
          'errorSamples': errorSamples!.map((value) => value.toJson()).toList(),
        if (errorsConfig != null) 'errorsConfig': errorsConfig!.toJson(),
      };
}

/// Configuration of destination for Import related errors.
class GoogleCloudRetailV2alphaImportErrorsConfig {
  /// Google Cloud Storage path for import errors.
  ///
  /// This must be an empty, existing Cloud Storage bucket. Import errors will
  /// be written to a file in this bucket, one per line, as a JSON-encoded
  /// `google.rpc.Status` message.
  core.String? gcsPrefix;

  GoogleCloudRetailV2alphaImportErrorsConfig();

  GoogleCloudRetailV2alphaImportErrorsConfig.fromJson(core.Map _json) {
    if (_json.containsKey('gcsPrefix')) {
      gcsPrefix = _json['gcsPrefix'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gcsPrefix != null) 'gcsPrefix': gcsPrefix!,
      };
}

/// Metadata related to the progress of the Import operation.
///
/// This will be returned by the google.longrunning.Operation.metadata field.
class GoogleCloudRetailV2alphaImportMetadata {
  /// Operation create time.
  core.String? createTime;

  /// Count of entries that encountered errors while processing.
  core.String? failureCount;

  /// Count of entries that were processed successfully.
  core.String? successCount;

  /// Operation last update time.
  ///
  /// If the operation is done, this is also the finish time.
  core.String? updateTime;

  GoogleCloudRetailV2alphaImportMetadata();

  GoogleCloudRetailV2alphaImportMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('failureCount')) {
      failureCount = _json['failureCount'] as core.String;
    }
    if (_json.containsKey('successCount')) {
      successCount = _json['successCount'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (failureCount != null) 'failureCount': failureCount!,
        if (successCount != null) 'successCount': successCount!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Response of the ImportProductsRequest.
///
/// If the long running operation is done, then this message is returned by the
/// google.longrunning.Operations.response field if the operation was
/// successful.
class GoogleCloudRetailV2alphaImportProductsResponse {
  /// A sample of errors encountered while processing the request.
  core.List<GoogleRpcStatus>? errorSamples;

  /// Echoes the destination for the complete errors in the request if set.
  GoogleCloudRetailV2alphaImportErrorsConfig? errorsConfig;

  GoogleCloudRetailV2alphaImportProductsResponse();

  GoogleCloudRetailV2alphaImportProductsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('errorSamples')) {
      errorSamples = (_json['errorSamples'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('errorsConfig')) {
      errorsConfig = GoogleCloudRetailV2alphaImportErrorsConfig.fromJson(
          _json['errorsConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorSamples != null)
          'errorSamples': errorSamples!.map((value) => value.toJson()).toList(),
        if (errorsConfig != null) 'errorsConfig': errorsConfig!.toJson(),
      };
}

/// Response of the ImportUserEventsRequest.
///
/// If the long running operation was successful, then this message is returned
/// by the google.longrunning.Operations.response field if the operation was
/// successful.
class GoogleCloudRetailV2alphaImportUserEventsResponse {
  /// A sample of errors encountered while processing the request.
  core.List<GoogleRpcStatus>? errorSamples;

  /// Echoes the destination for the complete errors if this field was set in
  /// the request.
  GoogleCloudRetailV2alphaImportErrorsConfig? errorsConfig;

  /// Aggregated statistics of user event import status.
  GoogleCloudRetailV2alphaUserEventImportSummary? importSummary;

  GoogleCloudRetailV2alphaImportUserEventsResponse();

  GoogleCloudRetailV2alphaImportUserEventsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('errorSamples')) {
      errorSamples = (_json['errorSamples'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('errorsConfig')) {
      errorsConfig = GoogleCloudRetailV2alphaImportErrorsConfig.fromJson(
          _json['errorsConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('importSummary')) {
      importSummary = GoogleCloudRetailV2alphaUserEventImportSummary.fromJson(
          _json['importSummary'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorSamples != null)
          'errorSamples': errorSamples!.map((value) => value.toJson()).toList(),
        if (errorsConfig != null) 'errorsConfig': errorsConfig!.toJson(),
        if (importSummary != null) 'importSummary': importSummary!.toJson(),
      };
}

/// Metadata related to the progress of the Purge operation.
///
/// This will be returned by the google.longrunning.Operation.metadata field.
class GoogleCloudRetailV2alphaPurgeMetadata {
  GoogleCloudRetailV2alphaPurgeMetadata();

  GoogleCloudRetailV2alphaPurgeMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Response of the PurgeUserEventsRequest.
///
/// If the long running operation is successfully done, then this message is
/// returned by the google.longrunning.Operations.response field.
class GoogleCloudRetailV2alphaPurgeUserEventsResponse {
  /// The total count of events purged as a result of the operation.
  core.String? purgedEventsCount;

  GoogleCloudRetailV2alphaPurgeUserEventsResponse();

  GoogleCloudRetailV2alphaPurgeUserEventsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('purgedEventsCount')) {
      purgedEventsCount = _json['purgedEventsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (purgedEventsCount != null) 'purgedEventsCount': purgedEventsCount!,
      };
}

/// Metadata for RejoinUserEvents method.
class GoogleCloudRetailV2alphaRejoinUserEventsMetadata {
  GoogleCloudRetailV2alphaRejoinUserEventsMetadata();

  GoogleCloudRetailV2alphaRejoinUserEventsMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Response message for RejoinUserEvents method.
class GoogleCloudRetailV2alphaRejoinUserEventsResponse {
  /// Number of user events that were joined with latest product catalog.
  core.String? rejoinedUserEventsCount;

  GoogleCloudRetailV2alphaRejoinUserEventsResponse();

  GoogleCloudRetailV2alphaRejoinUserEventsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('rejoinedUserEventsCount')) {
      rejoinedUserEventsCount = _json['rejoinedUserEventsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rejoinedUserEventsCount != null)
          'rejoinedUserEventsCount': rejoinedUserEventsCount!,
      };
}

/// A summary of import result.
///
/// The UserEventImportSummary summarizes the import status for user events.
class GoogleCloudRetailV2alphaUserEventImportSummary {
  /// Count of user events imported with complete existing catalog information.
  core.String? joinedEventsCount;

  /// Count of user events imported, but with catalog information not found in
  /// the imported catalog.
  core.String? unjoinedEventsCount;

  GoogleCloudRetailV2alphaUserEventImportSummary();

  GoogleCloudRetailV2alphaUserEventImportSummary.fromJson(core.Map _json) {
    if (_json.containsKey('joinedEventsCount')) {
      joinedEventsCount = _json['joinedEventsCount'] as core.String;
    }
    if (_json.containsKey('unjoinedEventsCount')) {
      unjoinedEventsCount = _json['unjoinedEventsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (joinedEventsCount != null) 'joinedEventsCount': joinedEventsCount!,
        if (unjoinedEventsCount != null)
          'unjoinedEventsCount': unjoinedEventsCount!,
      };
}

/// Configuration of destination for Export related errors.
class GoogleCloudRetailV2betaExportErrorsConfig {
  /// Google Cloud Storage path for import errors.
  ///
  /// This must be an empty, existing Cloud Storage bucket. Export errors will
  /// be written to a file in this bucket, one per line, as a JSON-encoded
  /// `google.rpc.Status` message.
  core.String? gcsPrefix;

  GoogleCloudRetailV2betaExportErrorsConfig();

  GoogleCloudRetailV2betaExportErrorsConfig.fromJson(core.Map _json) {
    if (_json.containsKey('gcsPrefix')) {
      gcsPrefix = _json['gcsPrefix'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gcsPrefix != null) 'gcsPrefix': gcsPrefix!,
      };
}

/// Metadata related to the progress of the Export operation.
///
/// This will be returned by the google.longrunning.Operation.metadata field.
class GoogleCloudRetailV2betaExportMetadata {
  /// Operation create time.
  core.String? createTime;

  /// Operation last update time.
  ///
  /// If the operation is done, this is also the finish time.
  core.String? updateTime;

  GoogleCloudRetailV2betaExportMetadata();

  GoogleCloudRetailV2betaExportMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Response of the ExportProductsRequest.
///
/// If the long running operation is done, then this message is returned by the
/// google.longrunning.Operations.response field if the operation was
/// successful.
class GoogleCloudRetailV2betaExportProductsResponse {
  /// A sample of errors encountered while processing the request.
  core.List<GoogleRpcStatus>? errorSamples;

  /// Echoes the destination for the complete errors in the request if set.
  GoogleCloudRetailV2betaExportErrorsConfig? errorsConfig;

  GoogleCloudRetailV2betaExportProductsResponse();

  GoogleCloudRetailV2betaExportProductsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('errorSamples')) {
      errorSamples = (_json['errorSamples'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('errorsConfig')) {
      errorsConfig = GoogleCloudRetailV2betaExportErrorsConfig.fromJson(
          _json['errorsConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorSamples != null)
          'errorSamples': errorSamples!.map((value) => value.toJson()).toList(),
        if (errorsConfig != null) 'errorsConfig': errorsConfig!.toJson(),
      };
}

/// Response of the ExportUserEventsRequest.
///
/// If the long running operation was successful, then this message is returned
/// by the google.longrunning.Operations.response field if the operation was
/// successful.
class GoogleCloudRetailV2betaExportUserEventsResponse {
  /// A sample of errors encountered while processing the request.
  core.List<GoogleRpcStatus>? errorSamples;

  /// Echoes the destination for the complete errors if this field was set in
  /// the request.
  GoogleCloudRetailV2betaExportErrorsConfig? errorsConfig;

  GoogleCloudRetailV2betaExportUserEventsResponse();

  GoogleCloudRetailV2betaExportUserEventsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('errorSamples')) {
      errorSamples = (_json['errorSamples'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('errorsConfig')) {
      errorsConfig = GoogleCloudRetailV2betaExportErrorsConfig.fromJson(
          _json['errorsConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorSamples != null)
          'errorSamples': errorSamples!.map((value) => value.toJson()).toList(),
        if (errorsConfig != null) 'errorsConfig': errorsConfig!.toJson(),
      };
}

/// Configuration of destination for Import related errors.
class GoogleCloudRetailV2betaImportErrorsConfig {
  /// Google Cloud Storage path for import errors.
  ///
  /// This must be an empty, existing Cloud Storage bucket. Import errors will
  /// be written to a file in this bucket, one per line, as a JSON-encoded
  /// `google.rpc.Status` message.
  core.String? gcsPrefix;

  GoogleCloudRetailV2betaImportErrorsConfig();

  GoogleCloudRetailV2betaImportErrorsConfig.fromJson(core.Map _json) {
    if (_json.containsKey('gcsPrefix')) {
      gcsPrefix = _json['gcsPrefix'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gcsPrefix != null) 'gcsPrefix': gcsPrefix!,
      };
}

/// Metadata related to the progress of the Import operation.
///
/// This will be returned by the google.longrunning.Operation.metadata field.
class GoogleCloudRetailV2betaImportMetadata {
  /// Operation create time.
  core.String? createTime;

  /// Count of entries that encountered errors while processing.
  core.String? failureCount;

  /// Count of entries that were processed successfully.
  core.String? successCount;

  /// Operation last update time.
  ///
  /// If the operation is done, this is also the finish time.
  core.String? updateTime;

  GoogleCloudRetailV2betaImportMetadata();

  GoogleCloudRetailV2betaImportMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('failureCount')) {
      failureCount = _json['failureCount'] as core.String;
    }
    if (_json.containsKey('successCount')) {
      successCount = _json['successCount'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (failureCount != null) 'failureCount': failureCount!,
        if (successCount != null) 'successCount': successCount!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Response of the ImportProductsRequest.
///
/// If the long running operation is done, then this message is returned by the
/// google.longrunning.Operations.response field if the operation was
/// successful.
class GoogleCloudRetailV2betaImportProductsResponse {
  /// A sample of errors encountered while processing the request.
  core.List<GoogleRpcStatus>? errorSamples;

  /// Echoes the destination for the complete errors in the request if set.
  GoogleCloudRetailV2betaImportErrorsConfig? errorsConfig;

  GoogleCloudRetailV2betaImportProductsResponse();

  GoogleCloudRetailV2betaImportProductsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('errorSamples')) {
      errorSamples = (_json['errorSamples'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('errorsConfig')) {
      errorsConfig = GoogleCloudRetailV2betaImportErrorsConfig.fromJson(
          _json['errorsConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorSamples != null)
          'errorSamples': errorSamples!.map((value) => value.toJson()).toList(),
        if (errorsConfig != null) 'errorsConfig': errorsConfig!.toJson(),
      };
}

/// Response of the ImportUserEventsRequest.
///
/// If the long running operation was successful, then this message is returned
/// by the google.longrunning.Operations.response field if the operation was
/// successful.
class GoogleCloudRetailV2betaImportUserEventsResponse {
  /// A sample of errors encountered while processing the request.
  core.List<GoogleRpcStatus>? errorSamples;

  /// Echoes the destination for the complete errors if this field was set in
  /// the request.
  GoogleCloudRetailV2betaImportErrorsConfig? errorsConfig;

  /// Aggregated statistics of user event import status.
  GoogleCloudRetailV2betaUserEventImportSummary? importSummary;

  GoogleCloudRetailV2betaImportUserEventsResponse();

  GoogleCloudRetailV2betaImportUserEventsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('errorSamples')) {
      errorSamples = (_json['errorSamples'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('errorsConfig')) {
      errorsConfig = GoogleCloudRetailV2betaImportErrorsConfig.fromJson(
          _json['errorsConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('importSummary')) {
      importSummary = GoogleCloudRetailV2betaUserEventImportSummary.fromJson(
          _json['importSummary'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorSamples != null)
          'errorSamples': errorSamples!.map((value) => value.toJson()).toList(),
        if (errorsConfig != null) 'errorsConfig': errorsConfig!.toJson(),
        if (importSummary != null) 'importSummary': importSummary!.toJson(),
      };
}

/// Metadata related to the progress of the Purge operation.
///
/// This will be returned by the google.longrunning.Operation.metadata field.
class GoogleCloudRetailV2betaPurgeMetadata {
  GoogleCloudRetailV2betaPurgeMetadata();

  GoogleCloudRetailV2betaPurgeMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Response of the PurgeUserEventsRequest.
///
/// If the long running operation is successfully done, then this message is
/// returned by the google.longrunning.Operations.response field.
class GoogleCloudRetailV2betaPurgeUserEventsResponse {
  /// The total count of events purged as a result of the operation.
  core.String? purgedEventsCount;

  GoogleCloudRetailV2betaPurgeUserEventsResponse();

  GoogleCloudRetailV2betaPurgeUserEventsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('purgedEventsCount')) {
      purgedEventsCount = _json['purgedEventsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (purgedEventsCount != null) 'purgedEventsCount': purgedEventsCount!,
      };
}

/// Metadata for RejoinUserEvents method.
class GoogleCloudRetailV2betaRejoinUserEventsMetadata {
  GoogleCloudRetailV2betaRejoinUserEventsMetadata();

  GoogleCloudRetailV2betaRejoinUserEventsMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Response message for RejoinUserEvents method.
class GoogleCloudRetailV2betaRejoinUserEventsResponse {
  /// Number of user events that were joined with latest product catalog.
  core.String? rejoinedUserEventsCount;

  GoogleCloudRetailV2betaRejoinUserEventsResponse();

  GoogleCloudRetailV2betaRejoinUserEventsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('rejoinedUserEventsCount')) {
      rejoinedUserEventsCount = _json['rejoinedUserEventsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rejoinedUserEventsCount != null)
          'rejoinedUserEventsCount': rejoinedUserEventsCount!,
      };
}

/// A summary of import result.
///
/// The UserEventImportSummary summarizes the import status for user events.
class GoogleCloudRetailV2betaUserEventImportSummary {
  /// Count of user events imported with complete existing catalog information.
  core.String? joinedEventsCount;

  /// Count of user events imported, but with catalog information not found in
  /// the imported catalog.
  core.String? unjoinedEventsCount;

  GoogleCloudRetailV2betaUserEventImportSummary();

  GoogleCloudRetailV2betaUserEventImportSummary.fromJson(core.Map _json) {
    if (_json.containsKey('joinedEventsCount')) {
      joinedEventsCount = _json['joinedEventsCount'] as core.String;
    }
    if (_json.containsKey('unjoinedEventsCount')) {
      unjoinedEventsCount = _json['unjoinedEventsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (joinedEventsCount != null) 'joinedEventsCount': joinedEventsCount!,
        if (unjoinedEventsCount != null)
          'unjoinedEventsCount': unjoinedEventsCount!,
      };
}

/// The response message for Operations.ListOperations.
class GoogleLongrunningListOperationsResponse {
  /// The standard List next-page token.
  core.String? nextPageToken;

  /// A list of operations that matches the specified filter in the request.
  core.List<GoogleLongrunningOperation>? operations;

  GoogleLongrunningListOperationsResponse();

  GoogleLongrunningListOperationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<GoogleLongrunningOperation>((value) =>
              GoogleLongrunningOperation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
      };
}

/// This resource represents a long-running operation that is the result of a
/// network API call.
class GoogleLongrunningOperation {
  /// If the value is `false`, it means the operation is still in progress.
  ///
  /// If `true`, the operation is completed, and either `error` or `response` is
  /// available.
  core.bool? done;

  /// The error result of the operation in case of failure or cancellation.
  GoogleRpcStatus? error;

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

  GoogleLongrunningOperation();

  GoogleLongrunningOperation.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
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

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class GoogleRpcStatus {
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

  GoogleRpcStatus();

  GoogleRpcStatus.fromJson(core.Map _json) {
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
