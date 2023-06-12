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

/// Display & Video 360 API - v1
///
/// Display & Video 360 API allows users to manage and create campaigns and
/// reports.
///
/// For more information, see <https://developers.google.com/display-video/>
///
/// Create an instance of [DisplayVideoApi] to access these resources:
///
/// - [AdvertisersResource]
///   - [AdvertisersAssetsResource]
///   - [AdvertisersCampaignsResource]
///     - [AdvertisersCampaignsTargetingTypesResource]
/// - [AdvertisersCampaignsTargetingTypesAssignedTargetingOptionsResource]
///   - [AdvertisersChannelsResource]
///     - [AdvertisersChannelsSitesResource]
///   - [AdvertisersCreativesResource]
///   - [AdvertisersInsertionOrdersResource]
///     - [AdvertisersInsertionOrdersTargetingTypesResource]
/// - [AdvertisersInsertionOrdersTargetingTypesAssignedTargetingOptionsResource]
///   - [AdvertisersInvoicesResource]
///   - [AdvertisersLineItemsResource]
///     - [AdvertisersLineItemsTargetingTypesResource]
/// - [AdvertisersLineItemsTargetingTypesAssignedTargetingOptionsResource]
///   - [AdvertisersLocationListsResource]
///     - [AdvertisersLocationListsAssignedLocationsResource]
///   - [AdvertisersManualTriggersResource]
///   - [AdvertisersNegativeKeywordListsResource]
///     - [AdvertisersNegativeKeywordListsNegativeKeywordsResource]
///   - [AdvertisersTargetingTypesResource]
///     - [AdvertisersTargetingTypesAssignedTargetingOptionsResource]
/// - [CombinedAudiencesResource]
/// - [CustomBiddingAlgorithmsResource]
/// - [CustomListsResource]
/// - [FirstAndThirdPartyAudiencesResource]
/// - [FloodlightGroupsResource]
/// - [GoogleAudiencesResource]
/// - [InventorySourceGroupsResource]
///   - [InventorySourceGroupsAssignedInventorySourcesResource]
/// - [InventorySourcesResource]
/// - [MediaResource]
/// - [PartnersResource]
///   - [PartnersChannelsResource]
///     - [PartnersChannelsSitesResource]
///   - [PartnersTargetingTypesResource]
///     - [PartnersTargetingTypesAssignedTargetingOptionsResource]
/// - [SdfdownloadtasksResource]
///   - [SdfdownloadtasksOperationsResource]
/// - [TargetingTypesResource]
///   - [TargetingTypesTargetingOptionsResource]
/// - [UsersResource]
library displayvideo.v1;

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

/// Display & Video 360 API allows users to manage and create campaigns and
/// reports.
class DisplayVideoApi {
  /// Create, see, edit, and permanently delete your Display & Video 360
  /// entities and reports
  static const displayVideoScope =
      'https://www.googleapis.com/auth/display-video';

  /// Create, see, and edit Display & Video 360 Campaign entities and see
  /// billing invoices
  static const displayVideoMediaplanningScope =
      'https://www.googleapis.com/auth/display-video-mediaplanning';

  /// Private Service:
  /// https://www.googleapis.com/auth/display-video-user-management
  static const displayVideoUserManagementScope =
      'https://www.googleapis.com/auth/display-video-user-management';

  /// View and manage your reports in DoubleClick Bid Manager
  static const doubleclickbidmanagerScope =
      'https://www.googleapis.com/auth/doubleclickbidmanager';

  final commons.ApiRequester _requester;

  AdvertisersResource get advertisers => AdvertisersResource(_requester);
  CombinedAudiencesResource get combinedAudiences =>
      CombinedAudiencesResource(_requester);
  CustomBiddingAlgorithmsResource get customBiddingAlgorithms =>
      CustomBiddingAlgorithmsResource(_requester);
  CustomListsResource get customLists => CustomListsResource(_requester);
  FirstAndThirdPartyAudiencesResource get firstAndThirdPartyAudiences =>
      FirstAndThirdPartyAudiencesResource(_requester);
  FloodlightGroupsResource get floodlightGroups =>
      FloodlightGroupsResource(_requester);
  GoogleAudiencesResource get googleAudiences =>
      GoogleAudiencesResource(_requester);
  InventorySourceGroupsResource get inventorySourceGroups =>
      InventorySourceGroupsResource(_requester);
  InventorySourcesResource get inventorySources =>
      InventorySourcesResource(_requester);
  MediaResource get media => MediaResource(_requester);
  PartnersResource get partners => PartnersResource(_requester);
  SdfdownloadtasksResource get sdfdownloadtasks =>
      SdfdownloadtasksResource(_requester);
  TargetingTypesResource get targetingTypes =>
      TargetingTypesResource(_requester);
  UsersResource get users => UsersResource(_requester);

  DisplayVideoApi(http.Client client,
      {core.String rootUrl = 'https://displayvideo.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AdvertisersResource {
  final commons.ApiRequester _requester;

  AdvertisersAssetsResource get assets => AdvertisersAssetsResource(_requester);
  AdvertisersCampaignsResource get campaigns =>
      AdvertisersCampaignsResource(_requester);
  AdvertisersChannelsResource get channels =>
      AdvertisersChannelsResource(_requester);
  AdvertisersCreativesResource get creatives =>
      AdvertisersCreativesResource(_requester);
  AdvertisersInsertionOrdersResource get insertionOrders =>
      AdvertisersInsertionOrdersResource(_requester);
  AdvertisersInvoicesResource get invoices =>
      AdvertisersInvoicesResource(_requester);
  AdvertisersLineItemsResource get lineItems =>
      AdvertisersLineItemsResource(_requester);
  AdvertisersLocationListsResource get locationLists =>
      AdvertisersLocationListsResource(_requester);
  AdvertisersManualTriggersResource get manualTriggers =>
      AdvertisersManualTriggersResource(_requester);
  AdvertisersNegativeKeywordListsResource get negativeKeywordLists =>
      AdvertisersNegativeKeywordListsResource(_requester);
  AdvertisersTargetingTypesResource get targetingTypes =>
      AdvertisersTargetingTypesResource(_requester);

  AdvertisersResource(commons.ApiRequester client) : _requester = client;

  /// Audits an advertiser.
  ///
  /// Returns the counts of used entities per resource type under the advertiser
  /// provided. Used entities count towards their respective resource limit. See
  /// https://support.google.com/displayvideo/answer/6071450.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser to audit.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [readMask] - Optional. The specific fields to return. If no mask is
  /// specified, all fields in the response proto will be filled. Valid values
  /// are: * usedLineItemsCount * usedInsertionOrdersCount * usedCampaignsCount
  /// * channelsCount * negativelyTargetedChannelsCount *
  /// negativeKeywordListsCount * adGroupCriteriaCount * campaignCriteriaCount
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AuditAdvertiserResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AuditAdvertiserResponse> audit(
    core.String advertiserId, {
    core.String? readMask,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (readMask != null) 'readMask': [readMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/advertisers/' + core.Uri.encodeFull('$advertiserId') + ':audit';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AuditAdvertiserResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Bulk edits targeting options under a single advertiser.
  ///
  /// The operation will delete the assigned targeting options provided in
  /// BulkEditAdvertiserAssignedTargetingOptionsRequest.delete_requests and then
  /// create the assigned targeting options provided in
  /// BulkEditAdvertiserAssignedTargetingOptionsRequest.create_requests .
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkEditAdvertiserAssignedTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkEditAdvertiserAssignedTargetingOptionsResponse>
      bulkEditAdvertiserAssignedTargetingOptions(
    BulkEditAdvertiserAssignedTargetingOptionsRequest request,
    core.String advertiserId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        ':bulkEditAdvertiserAssignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BulkEditAdvertiserAssignedTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists assigned targeting options of an advertiser across targeting types.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the line item belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by assigned targeting option properties.
  /// Supported syntax: * Filter expressions are made up of one or more
  /// restrictions. * Restrictions can be combined by the logical operator
  /// `OR`.. * A restriction has the form of `{field} {operator} {value}`. * The
  /// operator must be `EQUALS (=)`. * Supported fields: - `targetingType`
  /// Examples: * targetingType with value TARGETING_TYPE_CHANNEL
  /// `targetingType="TARGETING_TYPE_CHANNEL"` The length of this field should
  /// be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `targetingType` (default) The default sorting order is ascending. To
  /// specify descending order for a field, a suffix "desc" should be added to
  /// the field name. Example: `targetingType desc`.
  ///
  /// [pageSize] - Requested page size. The size must be an integer between `1`
  /// and `5000`. If unspecified, the default is '5000'. Returns error code
  /// `INVALID_ARGUMENT` if an invalid value is specified.
  ///
  /// [pageToken] - A token that lets the client fetch the next page of results.
  /// Typically, this is the value of next_page_token returned from the previous
  /// call to `BulkListAdvertiserAssignedTargetingOptions` method. If not
  /// specified, the first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkListAdvertiserAssignedTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkListAdvertiserAssignedTargetingOptionsResponse>
      bulkListAdvertiserAssignedTargetingOptions(
    core.String advertiserId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        ':bulkListAdvertiserAssignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BulkListAdvertiserAssignedTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new advertiser.
  ///
  /// Returns the newly created advertiser if successful. This method can take
  /// up to 180 seconds to complete.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Advertiser].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Advertiser> create(
    Advertiser request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/advertisers';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Advertiser.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an advertiser.
  ///
  /// Deleting an advertiser will delete all of its child resources, for
  /// example, campaigns, insertion orders and line items. A deleted advertiser
  /// cannot be recovered.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser we need to delete.
  /// Value must have pattern `^\[^/\]+$`.
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
    core.String advertiserId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' + core.Uri.encodeFull('$advertiserId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets an advertiser.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Advertiser].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Advertiser> get(
    core.String advertiserId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' + core.Uri.encodeFull('$advertiserId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Advertiser.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists advertisers that are accessible to the current user.
  ///
  /// The order is defined by the order_by parameter. A single partner_id is
  /// required. Cross-partner listing is not supported.
  ///
  /// Request parameters:
  ///
  /// [filter] - Allows filtering by advertiser properties. Supported syntax: *
  /// Filter expressions are made up of one or more restrictions. * Restrictions
  /// can be combined by `AND` or `OR` logical operators. A sequence of
  /// restrictions implicitly uses `AND`. * A restriction has the form of
  /// `{field} {operator} {value}`. * The operator used on `updateTime` must be
  /// `GREATER THAN OR EQUAL TO (>=)` or `LESS THAN OR EQUAL TO (<=)`. * The
  /// operator must be `EQUALS (=)`. * Supported fields: - `advertiserId` -
  /// `displayName` - `entityStatus` - `updateTime` (input in ISO 8601 format,
  /// or YYYY-MM-DDTHH:MM:SSZ) Examples: * All active advertisers under a
  /// partner: `entityStatus="ENTITY_STATUS_ACTIVE"` * All advertisers with an
  /// update time less than or equal to `2020-11-04T18:54:47Z (format of ISO
  /// 8601)`: `updateTime<="2020-11-04T18:54:47Z"` * All advertisers with an
  /// update time greater than or equal to `2020-11-04T18:54:47Z (format of ISO
  /// 8601)`: `updateTime>="2020-11-04T18:54:47Z"` The length of this field
  /// should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `displayName` (default) * `entityStatus` * `updateTime` The default
  /// sorting order is ascending. To specify descending order for a field, a
  /// suffix "desc" should be added to the field name. For example, `displayName
  /// desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListAdvertisers` method. If not specified, the first
  /// page of results will be returned.
  ///
  /// [partnerId] - Required. The ID of the partner that the fetched advertisers
  /// should all belong to. The system only supports listing advertisers for one
  /// partner at a time.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAdvertisersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAdvertisersResponse> list({
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/advertisers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAdvertisersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing advertiser.
  ///
  /// Returns the updated advertiser if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Output only. The unique ID of the advertiser. Assigned by
  /// the system.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Advertiser].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Advertiser> patch(
    Advertiser request,
    core.String advertiserId, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' + core.Uri.encodeFull('$advertiserId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Advertiser.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersAssetsResource {
  final commons.ApiRequester _requester;

  AdvertisersAssetsResource(commons.ApiRequester client) : _requester = client;

  /// Uploads an asset.
  ///
  /// Returns the ID of the newly uploaded asset if successful. The asset file
  /// size should be no more than 10 MB for images, 200 MB for ZIP files, and 1
  /// GB for videos.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser this asset belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [uploadMedia] - The media to upload.
  ///
  /// Completes with a [CreateAssetResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreateAssetResponse> upload(
    CreateAssetRequest request,
    core.String advertiserId, {
    core.String? $fields,
    commons.Media? uploadMedia,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    core.String _url;
    if (uploadMedia == null) {
      _url =
          'v1/advertisers/' + core.Uri.encodeFull('$advertiserId') + '/assets';
    } else {
      _url = '/upload/v1/advertisers/' +
          core.Uri.encodeFull('$advertiserId') +
          '/assets';
    }

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      uploadMedia: uploadMedia,
      uploadOptions: commons.UploadOptions.defaultOptions,
    );
    return CreateAssetResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersCampaignsResource {
  final commons.ApiRequester _requester;

  AdvertisersCampaignsTargetingTypesResource get targetingTypes =>
      AdvertisersCampaignsTargetingTypesResource(_requester);

  AdvertisersCampaignsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists assigned targeting options of a campaign across targeting types.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the campaign belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [campaignId] - Required. The ID of the campaign to list assigned targeting
  /// options for.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by assigned targeting option properties.
  /// Supported syntax: * Filter expressions are made up of one or more
  /// restrictions. * Restrictions can be combined by the logical operator `OR`
  /// on the same field. * A restriction has the form of `{field} {operator}
  /// {value}`. * The operator must be `EQUALS (=)`. * Supported fields: -
  /// `targetingType` - `inheritance` Examples: * AssignedTargetingOptions of
  /// targeting type TARGETING_TYPE_LANGUAGE or TARGETING_TYPE_GENDER
  /// `targetingType="TARGETING_TYPE_LANGUAGE" OR
  /// targetingType="TARGETING_TYPE_GENDER"` * AssignedTargetingOptions with
  /// inheritance status of NOT_INHERITED or INHERITED_FROM_PARTNER
  /// `inheritance="NOT_INHERITED" OR inheritance="INHERITED_FROM_PARTNER"` The
  /// length of this field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `targetingType` (default) The default sorting order is ascending. To
  /// specify descending order for a field, a suffix "desc" should be added to
  /// the field name. Example: `targetingType desc`.
  ///
  /// [pageSize] - Requested page size. The size must be an integer between `1`
  /// and `5000`. If unspecified, the default is `5000`. Returns error code
  /// `INVALID_ARGUMENT` if an invalid value is specified.
  ///
  /// [pageToken] - A token that lets the client fetch the next page of results.
  /// Typically, this is the value of next_page_token returned from the previous
  /// call to `BulkListCampaignAssignedTargetingOptions` method. If not
  /// specified, the first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkListCampaignAssignedTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkListCampaignAssignedTargetingOptionsResponse>
      bulkListCampaignAssignedTargetingOptions(
    core.String advertiserId,
    core.String campaignId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/campaigns/' +
        core.Uri.encodeFull('$campaignId') +
        ':bulkListCampaignAssignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BulkListCampaignAssignedTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new campaign.
  ///
  /// Returns the newly created campaign if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Output only. The unique ID of the advertiser the campaign
  /// belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Campaign].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Campaign> create(
    Campaign request,
    core.String advertiserId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/advertisers/' + core.Uri.encodeFull('$advertiserId') + '/campaigns';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Campaign.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Permanently deletes a campaign.
  ///
  /// A deleted campaign cannot be recovered. The campaign should be archived
  /// first, i.e. set entity_status to `ENTITY_STATUS_ARCHIVED`, to be able to
  /// delete it.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser this campaign belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [campaignId] - The ID of the campaign we need to delete.
  /// Value must have pattern `^\[^/\]+$`.
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
    core.String advertiserId,
    core.String campaignId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/campaigns/' +
        core.Uri.encodeFull('$campaignId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a campaign.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser this campaign belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [campaignId] - Required. The ID of the campaign to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Campaign].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Campaign> get(
    core.String advertiserId,
    core.String campaignId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/campaigns/' +
        core.Uri.encodeFull('$campaignId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Campaign.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists campaigns in an advertiser.
  ///
  /// The order is defined by the order_by parameter. If a filter by
  /// entity_status is not specified, campaigns with `ENTITY_STATUS_ARCHIVED`
  /// will not be included in the results.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser to list campaigns for.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by campaign properties. Supported syntax: *
  /// Filter expressions are made up of one or more restrictions. * Restrictions
  /// can be combined by `AND` or `OR` logical operators. A sequence of
  /// restrictions implicitly uses `AND`. * A restriction has the form of
  /// `{field} {operator} {value}`. * The operator used on `updateTime` must be
  /// `GREATER THAN OR EQUAL TO (>=)` or `LESS THAN OR EQUAL TO (<=)`. * The
  /// operator must be `EQUALS (=)`. * Supported fields: - `campaignId` -
  /// `displayName` - `entityStatus` - `updateTime` (input in ISO 8601 format,
  /// or YYYY-MM-DDTHH:MM:SSZ) Examples: * All `ENTITY_STATUS_ACTIVE` or
  /// `ENTITY_STATUS_PAUSED` campaigns under an advertiser:
  /// `(entityStatus="ENTITY_STATUS_ACTIVE" OR
  /// entityStatus="ENTITY_STATUS_PAUSED")` * All campaigns with an update time
  /// less than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`:
  /// `updateTime<="2020-11-04T18:54:47Z"` * All campaigns with an update time
  /// greater than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`:
  /// `updateTime>="2020-11-04T18:54:47Z"` The length of this field should be no
  /// more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `displayName` (default) * `entityStatus` * `updateTime` The default
  /// sorting order is ascending. To specify descending order for a field, a
  /// suffix "desc" should be added to the field name. Example: `displayName
  /// desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListCampaigns` method. If not specified, the first page
  /// of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCampaignsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCampaignsResponse> list(
    core.String advertiserId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/advertisers/' + core.Uri.encodeFull('$advertiserId') + '/campaigns';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCampaignsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing campaign.
  ///
  /// Returns the updated campaign if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Output only. The unique ID of the advertiser the campaign
  /// belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [campaignId] - Output only. The unique ID of the campaign. Assigned by the
  /// system.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Campaign].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Campaign> patch(
    Campaign request,
    core.String advertiserId,
    core.String campaignId, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/campaigns/' +
        core.Uri.encodeFull('$campaignId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Campaign.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersCampaignsTargetingTypesResource {
  final commons.ApiRequester _requester;

  AdvertisersCampaignsTargetingTypesAssignedTargetingOptionsResource
      get assignedTargetingOptions =>
          AdvertisersCampaignsTargetingTypesAssignedTargetingOptionsResource(
              _requester);

  AdvertisersCampaignsTargetingTypesResource(commons.ApiRequester client)
      : _requester = client;
}

class AdvertisersCampaignsTargetingTypesAssignedTargetingOptionsResource {
  final commons.ApiRequester _requester;

  AdvertisersCampaignsTargetingTypesAssignedTargetingOptionsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Gets a single targeting option assigned to a campaign.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the campaign belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [campaignId] - Required. The ID of the campaign the assigned targeting
  /// option belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of this assigned targeting
  /// option. Supported targeting types: * `TARGETING_TYPE_AGE_RANGE` *
  /// `TARGETING_TYPE_AUTHORIZED_SELLER_STATUS` *
  /// `TARGETING_TYPE_CONTENT_INSTREAM_POSITION` *
  /// `TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION` *
  /// `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` *
  /// `TARGETING_TYPE_ENVIRONMENT` * `TARGETING_TYPE_EXCHANGE` *
  /// `TARGETING_TYPE_GENDER` * `TARGETING_TYPE_GEO_REGION` *
  /// `TARGETING_TYPE_HOUSEHOLD_INCOME` * `TARGETING_TYPE_INVENTORY_SOURCE` *
  /// `TARGETING_TYPE_INVENTORY_SOURCE_GROUP` * `TARGETING_TYPE_LANGUAGE` *
  /// `TARGETING_TYPE_ON_SCREEN_POSITION` * `TARGETING_TYPE_PARENTAL_STATUS` *
  /// `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION` *
  /// `TARGETING_TYPE_SUB_EXCHANGE` * `TARGETING_TYPE_THIRD_PARTY_VERIFIER` *
  /// `TARGETING_TYPE_VIEWABILITY`
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [assignedTargetingOptionId] - Required. An identifier unique to the
  /// targeting type in this campaign that identifies the assigned targeting
  /// option being requested.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AssignedTargetingOption].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AssignedTargetingOption> get(
    core.String advertiserId,
    core.String campaignId,
    core.String targetingType,
    core.String assignedTargetingOptionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/campaigns/' +
        core.Uri.encodeFull('$campaignId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions/' +
        core.Uri.encodeFull('$assignedTargetingOptionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AssignedTargetingOption.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the targeting options assigned to a campaign for a specified
  /// targeting type.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the campaign belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [campaignId] - Required. The ID of the campaign to list assigned targeting
  /// options for.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of assigned targeting
  /// options to list. Supported targeting types: * `TARGETING_TYPE_AGE_RANGE` *
  /// `TARGETING_TYPE_AUTHORIZED_SELLER_STATUS` *
  /// `TARGETING_TYPE_CONTENT_INSTREAM_POSITION` *
  /// `TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION` *
  /// `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` *
  /// `TARGETING_TYPE_ENVIRONMENT` * `TARGETING_TYPE_EXCHANGE` *
  /// `TARGETING_TYPE_GENDER` * `TARGETING_TYPE_GEO_REGION` *
  /// `TARGETING_TYPE_HOUSEHOLD_INCOME` * `TARGETING_TYPE_INVENTORY_SOURCE` *
  /// `TARGETING_TYPE_INVENTORY_SOURCE_GROUP` * `TARGETING_TYPE_LANGUAGE` *
  /// `TARGETING_TYPE_ON_SCREEN_POSITION` * `TARGETING_TYPE_PARENTAL_STATUS` *
  /// `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION` *
  /// `TARGETING_TYPE_SUB_EXCHANGE` * `TARGETING_TYPE_THIRD_PARTY_VERIFIER` *
  /// `TARGETING_TYPE_VIEWABILITY`
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [filter] - Allows filtering by assigned targeting option properties.
  /// Supported syntax: * Filter expressions are made up of one or more
  /// restrictions. * Restrictions can be combined by the logical operator `OR`.
  /// * A restriction has the form of `{field} {operator} {value}`. * The
  /// operator must be `EQUALS (=)`. * Supported fields: -
  /// `assignedTargetingOptionId` - `inheritance` Examples: *
  /// AssignedTargetingOptions with ID 1 or 2 `assignedTargetingOptionId="1" OR
  /// assignedTargetingOptionId="2"` * AssignedTargetingOptions with inheritance
  /// status of NOT_INHERITED or INHERITED_FROM_PARTNER
  /// `inheritance="NOT_INHERITED" OR inheritance="INHERITED_FROM_PARTNER"` The
  /// length of this field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `assignedTargetingOptionId` (default) The default sorting order is
  /// ascending. To specify descending order for a field, a suffix "desc" should
  /// be added to the field name. Example: `assignedTargetingOptionId desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListCampaignAssignedTargetingOptions` method. If not
  /// specified, the first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCampaignAssignedTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCampaignAssignedTargetingOptionsResponse> list(
    core.String advertiserId,
    core.String campaignId,
    core.String targetingType, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/campaigns/' +
        core.Uri.encodeFull('$campaignId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCampaignAssignedTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersChannelsResource {
  final commons.ApiRequester _requester;

  AdvertisersChannelsSitesResource get sites =>
      AdvertisersChannelsSitesResource(_requester);

  AdvertisersChannelsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new channel.
  ///
  /// Returns the newly created channel if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that owns the created channel.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [partnerId] - The ID of the partner that owns the created channel.
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
  async.Future<Channel> create(
    Channel request,
    core.String advertiserId, {
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/advertisers/' + core.Uri.encodeFull('$advertiserId') + '/channels';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Channel.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a channel for a partner or advertiser.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that owns the fetched channel.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [channelId] - Required. The ID of the channel to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [partnerId] - The ID of the partner that owns the fetched channel.
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
  async.Future<Channel> get(
    core.String advertiserId,
    core.String channelId, {
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/channels/' +
        core.Uri.encodeFull('$channelId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Channel.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists channels for a partner or advertiser.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that owns the channels.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by channel fields. Supported syntax: * Filter
  /// expressions for channel currently can only contain at most one *
  /// restriction. * A restriction has the form of `{field} {operator} {value}`.
  /// * The operator must be `CONTAINS (:)`. * Supported fields: - `displayName`
  /// Examples: * All channels for which the display name contains "google":
  /// `displayName : "google"`. The length of this field should be no more than
  /// 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `displayName` (default) * `channelId` The default sorting order is
  /// ascending. To specify descending order for a field, a suffix " desc"
  /// should be added to the field name. Example: `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListChannels` method. If not specified, the first page
  /// of results will be returned.
  ///
  /// [partnerId] - The ID of the partner that owns the channels.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListChannelsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListChannelsResponse> list(
    core.String advertiserId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/advertisers/' + core.Uri.encodeFull('$advertiserId') + '/channels';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListChannelsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a channel.
  ///
  /// Returns the updated channel if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that owns the created channel.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [channelId] - Output only. The unique ID of the channel. Assigned by the
  /// system.
  ///
  /// [partnerId] - The ID of the partner that owns the created channel.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
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
  async.Future<Channel> patch(
    Channel request,
    core.String advertiserId,
    core.String channelId, {
    core.String? partnerId,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (partnerId != null) 'partnerId': [partnerId],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/channels/' +
        commons.escapeVariable('$channelId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Channel.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersChannelsSitesResource {
  final commons.ApiRequester _requester;

  AdvertisersChannelsSitesResource(commons.ApiRequester client)
      : _requester = client;

  /// Bulk edits sites under a single channel.
  ///
  /// The operation will delete the sites provided in
  /// BulkEditSitesRequest.deleted_sites and then create the sites provided in
  /// BulkEditSitesRequest.created_sites.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that owns the parent channel.
  ///
  /// [channelId] - Required. The ID of the parent channel to which the sites
  /// belong.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkEditSitesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkEditSitesResponse> bulkEdit(
    BulkEditSitesRequest request,
    core.String advertiserId,
    core.String channelId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        commons.escapeVariable('$advertiserId') +
        '/channels/' +
        core.Uri.encodeFull('$channelId') +
        '/sites:bulkEdit';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BulkEditSitesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a site in a channel.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that owns the parent channel.
  ///
  /// [channelId] - Required. The ID of the parent channel in which the site
  /// will be created.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [partnerId] - The ID of the partner that owns the parent channel.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Site].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Site> create(
    Site request,
    core.String advertiserId,
    core.String channelId, {
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        commons.escapeVariable('$advertiserId') +
        '/channels/' +
        core.Uri.encodeFull('$channelId') +
        '/sites';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Site.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a site from a channel.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that owns the parent channel.
  ///
  /// [channelId] - Required. The ID of the parent channel to which the site
  /// belongs.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [urlOrAppId] - Required. The URL or app ID of the site to delete.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [partnerId] - The ID of the partner that owns the parent channel.
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
    core.String advertiserId,
    core.String channelId,
    core.String urlOrAppId, {
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        commons.escapeVariable('$advertiserId') +
        '/channels/' +
        core.Uri.encodeFull('$channelId') +
        '/sites/' +
        core.Uri.encodeFull('$urlOrAppId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists sites in a channel.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that owns the parent channel.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [channelId] - Required. The ID of the parent channel to which the
  /// requested sites belong.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by site fields. Supported syntax: * Filter
  /// expressions for site currently can only contain at most one * restriction.
  /// * A restriction has the form of `{field} {operator} {value}`. * The
  /// operator must be `CONTAINS (:)`. * Supported fields: - `urlOrAppId`
  /// Examples: * All sites for which the URL or app ID contains "google":
  /// `urlOrAppId : "google"`
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `urlOrAppId` (default) The default sorting order is ascending. To specify
  /// descending order for a field, a suffix " desc" should be added to the
  /// field name. Example: `urlOrAppId desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `10000`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListSites` method. If not specified, the first page of
  /// results will be returned.
  ///
  /// [partnerId] - The ID of the partner that owns the parent channel.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSitesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSitesResponse> list(
    core.String advertiserId,
    core.String channelId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/channels/' +
        core.Uri.encodeFull('$channelId') +
        '/sites';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSitesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Replaces all of the sites under a single channel.
  ///
  /// The operation will replace the sites under a channel with the sites
  /// provided in ReplaceSitesRequest.new_sites.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that owns the parent channel.
  ///
  /// [channelId] - Required. The ID of the parent channel whose sites will be
  /// replaced.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReplaceSitesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReplaceSitesResponse> replace(
    ReplaceSitesRequest request,
    core.String advertiserId,
    core.String channelId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        commons.escapeVariable('$advertiserId') +
        '/channels/' +
        core.Uri.encodeFull('$channelId') +
        '/sites:replace';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ReplaceSitesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersCreativesResource {
  final commons.ApiRequester _requester;

  AdvertisersCreativesResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new creative.
  ///
  /// Returns the newly created creative if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Output only. The unique ID of the advertiser the creative
  /// belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Creative].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Creative> create(
    Creative request,
    core.String advertiserId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/advertisers/' + core.Uri.encodeFull('$advertiserId') + '/creatives';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Creative.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a creative.
  ///
  /// Returns error code `NOT_FOUND` if the creative does not exist. The
  /// creative should be archived first, i.e. set entity_status to
  /// `ENTITY_STATUS_ARCHIVED`, before it can be deleted.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser this creative belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [creativeId] - The ID of the creative to be deleted.
  /// Value must have pattern `^\[^/\]+$`.
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
    core.String advertiserId,
    core.String creativeId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/creatives/' +
        core.Uri.encodeFull('$creativeId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a creative.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser this creative belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [creativeId] - Required. The ID of the creative to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Creative].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Creative> get(
    core.String advertiserId,
    core.String creativeId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/creatives/' +
        core.Uri.encodeFull('$creativeId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Creative.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists creatives in an advertiser.
  ///
  /// The order is defined by the order_by parameter. If a filter by
  /// entity_status is not specified, creatives with `ENTITY_STATUS_ARCHIVED`
  /// will not be included in the results.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser to list creatives for.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by creative properties. Supported syntax: *
  /// Filter expressions are made up of one or more restrictions. * Restriction
  /// for the same field must be combined by `OR`. * Restriction for different
  /// fields must be combined by `AND`. * Between `(` and `)` there can only be
  /// restrictions combined by `OR` for the same field. * A restriction has the
  /// form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`
  /// for the following fields: - `entityStatus` - `creativeType`. -
  /// `dimensions` - `minDuration` - `maxDuration` - `approvalStatus` -
  /// `exchangeReviewStatus` - `dynamic` - `creativeId` * The operator must be
  /// `HAS (:)` for the following fields: - `lineItemIds` * For `entityStatus`,
  /// `minDuration`, `maxDuration`, and `dynamic` there may be at most one
  /// restriction. * For `dimensions`, the value is in the form of
  /// `"{width}x{height}"`. * For `exchangeReviewStatus`, the value is in the
  /// form of `{exchange}-{reviewStatus}`. * For `minDuration` and
  /// `maxDuration`, the value is in the form of `"{duration}s"`. Only seconds
  /// are supported with millisecond granularity. * There may be multiple
  /// `lineItemIds` restrictions in order to search against multiple possible
  /// line item IDs. * There may be multiple `creativeId` restrictions in order
  /// to search against multiple possible creative IDs. Examples: * All native
  /// creatives: `creativeType="CREATIVE_TYPE_NATIVE"` * All active creatives
  /// with 300x400 or 50x100 dimensions: `entityStatus="ENTITY_STATUS_ACTIVE"
  /// AND (dimensions="300x400" OR dimensions="50x100")` * All dynamic creatives
  /// that are approved by AdX or AppNexus, with a minimum duration of 5 seconds
  /// and 200ms. `dynamic="true" AND minDuration="5.2s" AND
  /// (exchangeReviewStatus="EXCHANGE_GOOGLE_AD_MANAGER-REVIEW_STATUS_APPROVED"
  /// OR exchangeReviewStatus="EXCHANGE_APPNEXUS-REVIEW_STATUS_APPROVED")` * All
  /// video creatives that are associated with line item ID 1 or 2:
  /// `creativeType="CREATIVE_TYPE_VIDEO" AND (lineItemIds:1 OR lineItemIds:2)`
  /// * Find creatives by multiple creative IDs: `creativeId=1 OR creativeId=2`
  /// The length of this field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `creativeId` (default) * `createTime` * `mediaDuration` * `dimensions`
  /// (sorts by width first, then by height) The default sorting order is
  /// ascending. To specify descending order for a field, a suffix "desc" should
  /// be added to the field name. Example: `createTime desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListCreatives` method. If not specified, the first page
  /// of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCreativesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCreativesResponse> list(
    core.String advertiserId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/advertisers/' + core.Uri.encodeFull('$advertiserId') + '/creatives';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCreativesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing creative.
  ///
  /// Returns the updated creative if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Output only. The unique ID of the advertiser the creative
  /// belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [creativeId] - Output only. The unique ID of the creative. Assigned by the
  /// system.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Creative].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Creative> patch(
    Creative request,
    core.String advertiserId,
    core.String creativeId, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/creatives/' +
        core.Uri.encodeFull('$creativeId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Creative.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersInsertionOrdersResource {
  final commons.ApiRequester _requester;

  AdvertisersInsertionOrdersTargetingTypesResource get targetingTypes =>
      AdvertisersInsertionOrdersTargetingTypesResource(_requester);

  AdvertisersInsertionOrdersResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists assigned targeting options of an insertion order across targeting
  /// types.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the insertion order
  /// belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [insertionOrderId] - Required. The ID of the insertion order to list
  /// assigned targeting options for.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by assigned targeting option properties.
  /// Supported syntax: * Filter expressions are made up of one or more
  /// restrictions. * Restrictions can be combined by the logical operator `OR`
  /// on the same field. * A restriction has the form of `{field} {operator}
  /// {value}`. * The operator must be `EQUALS (=)`. * Supported fields: -
  /// `targetingType` - `inheritance` Examples: * AssignedTargetingOptions of
  /// targeting type TARGETING_TYPE_PROXIMITY_LOCATION_LIST or
  /// TARGETING_TYPE_CHANNEL
  /// `targetingType="TARGETING_TYPE_PROXIMITY_LOCATION_LIST" OR
  /// targetingType="TARGETING_TYPE_CHANNEL"` * AssignedTargetingOptions with
  /// inheritance status of NOT_INHERITED or INHERITED_FROM_PARTNER
  /// `inheritance="NOT_INHERITED" OR inheritance="INHERITED_FROM_PARTNER"` The
  /// length of this field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `targetingType` (default) The default sorting order is ascending. To
  /// specify descending order for a field, a suffix "desc" should be added to
  /// the field name. Example: `targetingType desc`.
  ///
  /// [pageSize] - Requested page size. The size must be an integer between `1`
  /// and `5000`. If unspecified, the default is `5000`. Returns error code
  /// `INVALID_ARGUMENT` if an invalid value is specified.
  ///
  /// [pageToken] - A token that lets the client fetch the next page of results.
  /// Typically, this is the value of next_page_token returned from the previous
  /// call to `BulkListInsertionOrderAssignedTargetingOptions` method. If not
  /// specified, the first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkListInsertionOrderAssignedTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkListInsertionOrderAssignedTargetingOptionsResponse>
      bulkListInsertionOrderAssignedTargetingOptions(
    core.String advertiserId,
    core.String insertionOrderId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/insertionOrders/' +
        core.Uri.encodeFull('$insertionOrderId') +
        ':bulkListInsertionOrderAssignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BulkListInsertionOrderAssignedTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new insertion order.
  ///
  /// Returns the newly created insertion order if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Output only. The unique ID of the advertiser the
  /// insertion order belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [InsertionOrder].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<InsertionOrder> create(
    InsertionOrder request,
    core.String advertiserId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/insertionOrders';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return InsertionOrder.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an insertion order.
  ///
  /// Returns error code `NOT_FOUND` if the insertion order does not exist. The
  /// insertion order should be archived first, i.e. set entity_status to
  /// `ENTITY_STATUS_ARCHIVED`, to be able to delete it.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser this insertion order belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [insertionOrderId] - The ID of the insertion order we need to delete.
  /// Value must have pattern `^\[^/\]+$`.
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
    core.String advertiserId,
    core.String insertionOrderId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/insertionOrders/' +
        core.Uri.encodeFull('$insertionOrderId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets an insertion order.
  ///
  /// Returns error code `NOT_FOUND` if the insertion order does not exist.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser this insertion order
  /// belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [insertionOrderId] - Required. The ID of the insertion order to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [InsertionOrder].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<InsertionOrder> get(
    core.String advertiserId,
    core.String insertionOrderId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/insertionOrders/' +
        core.Uri.encodeFull('$insertionOrderId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return InsertionOrder.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists insertion orders in an advertiser.
  ///
  /// The order is defined by the order_by parameter. If a filter by
  /// entity_status is not specified, insertion orders with
  /// `ENTITY_STATUS_ARCHIVED` will not be included in the results.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser to list insertion
  /// orders for.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by insertion order properties. Supported
  /// syntax: * Filter expressions are made up of one or more restrictions. *
  /// Restrictions can be combined by `AND` or `OR` logical operators. A
  /// sequence of restrictions implicitly uses `AND`. * A restriction has the
  /// form of `{field} {operator} {value}`. * The operator used on
  /// `budget.budget_segments.date_range.end_date` must be LESS THAN (<). * The
  /// operator used on `updateTime` must be `GREATER THAN OR EQUAL TO (>=)` or
  /// `LESS THAN OR EQUAL TO (<=)`. * The operators used on all other fields
  /// must be `EQUALS (=)`. * Supported fields: - `campaignId` - `displayName` -
  /// `entityStatus` - `budget.budget_segments.date_range.end_date` (input as
  /// YYYY-MM-DD) - `updateTime` (input in ISO 8601 format, or
  /// YYYY-MM-DDTHH:MM:SSZ) Examples: * All insertion orders under a campaign:
  /// `campaignId="1234"` * All `ENTITY_STATUS_ACTIVE` or `ENTITY_STATUS_PAUSED`
  /// insertion orders under an advertiser:
  /// `(entityStatus="ENTITY_STATUS_ACTIVE" OR
  /// entityStatus="ENTITY_STATUS_PAUSED")` * All insertion orders whose budget
  /// segments' dates end before March 28, 2019:
  /// `budget.budget_segments.date_range.end_date<"2019-03-28"` * All insertion
  /// orders with an update time less than or equal to `2020-11-04T18:54:47Z
  /// (format of ISO 8601)`: `updateTime<="2020-11-04T18:54:47Z"` * All
  /// insertion orders with an update time greater than or equal to
  /// `2020-11-04T18:54:47Z (format of ISO 8601)`:
  /// `updateTime>="2020-11-04T18:54:47Z"` The length of this field should be no
  /// more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// "displayName" (default) * "entityStatus" * "updateTime" The default
  /// sorting order is ascending. To specify descending order for a field, a
  /// suffix "desc" should be added to the field name. Example: `displayName
  /// desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListInsertionOrders` method. If not specified, the first
  /// page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListInsertionOrdersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListInsertionOrdersResponse> list(
    core.String advertiserId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/insertionOrders';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListInsertionOrdersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing insertion order.
  ///
  /// Returns the updated insertion order if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Output only. The unique ID of the advertiser the
  /// insertion order belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [insertionOrderId] - Output only. The unique ID of the insertion order.
  /// Assigned by the system.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [InsertionOrder].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<InsertionOrder> patch(
    InsertionOrder request,
    core.String advertiserId,
    core.String insertionOrderId, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/insertionOrders/' +
        core.Uri.encodeFull('$insertionOrderId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return InsertionOrder.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersInsertionOrdersTargetingTypesResource {
  final commons.ApiRequester _requester;

  AdvertisersInsertionOrdersTargetingTypesAssignedTargetingOptionsResource
      get assignedTargetingOptions =>
          AdvertisersInsertionOrdersTargetingTypesAssignedTargetingOptionsResource(
              _requester);

  AdvertisersInsertionOrdersTargetingTypesResource(commons.ApiRequester client)
      : _requester = client;
}

class AdvertisersInsertionOrdersTargetingTypesAssignedTargetingOptionsResource {
  final commons.ApiRequester _requester;

  AdvertisersInsertionOrdersTargetingTypesAssignedTargetingOptionsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Gets a single targeting option assigned to an insertion order.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the insertion order
  /// belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [insertionOrderId] - Required. The ID of the insertion order the assigned
  /// targeting option belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of this assigned targeting
  /// option.
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [assignedTargetingOptionId] - Required. An identifier unique to the
  /// targeting type in this insertion order that identifies the assigned
  /// targeting option being requested.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AssignedTargetingOption].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AssignedTargetingOption> get(
    core.String advertiserId,
    core.String insertionOrderId,
    core.String targetingType,
    core.String assignedTargetingOptionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/insertionOrders/' +
        core.Uri.encodeFull('$insertionOrderId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions/' +
        core.Uri.encodeFull('$assignedTargetingOptionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AssignedTargetingOption.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the targeting options assigned to an insertion order.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the insertion order
  /// belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [insertionOrderId] - Required. The ID of the insertion order to list
  /// assigned targeting options for.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of assigned targeting
  /// options to list.
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [filter] - Allows filtering by assigned targeting option properties.
  /// Supported syntax: * Filter expressions are made up of one or more
  /// restrictions. * Restrictions can be combined by the logical operator `OR`.
  /// * A restriction has the form of `{field} {operator} {value}`. * The
  /// operator must be `EQUALS (=)`. * Supported fields: -
  /// `assignedTargetingOptionId` - `inheritance` Examples: *
  /// AssignedTargetingOptions with ID 1 or 2 `assignedTargetingOptionId="1" OR
  /// assignedTargetingOptionId="2"` * AssignedTargetingOptions with inheritance
  /// status of NOT_INHERITED or INHERITED_FROM_PARTNER
  /// `inheritance="NOT_INHERITED" OR inheritance="INHERITED_FROM_PARTNER"` The
  /// length of this field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `assignedTargetingOptionId` (default) The default sorting order is
  /// ascending. To specify descending order for a field, a suffix "desc" should
  /// be added to the field name. Example: `assignedTargetingOptionId desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListInsertionOrderAssignedTargetingOptions` method. If
  /// not specified, the first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListInsertionOrderAssignedTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListInsertionOrderAssignedTargetingOptionsResponse> list(
    core.String advertiserId,
    core.String insertionOrderId,
    core.String targetingType, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/insertionOrders/' +
        core.Uri.encodeFull('$insertionOrderId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListInsertionOrderAssignedTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersInvoicesResource {
  final commons.ApiRequester _requester;

  AdvertisersInvoicesResource(commons.ApiRequester client)
      : _requester = client;

  /// List invoices for an advertiser.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser to list invoices for.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [issueMonth] - Required. Month for which invoices are needed in the format
  /// YYYYMM.
  ///
  /// [loiSapinInvoiceType] - Select type of invoice to query for Loi Sapin
  /// advertisers. Otherwise its ignored.
  /// Possible string values are:
  /// - "LOI_SAPIN_INVOICE_TYPE_UNSPECIFIED" : Value is not specified.
  /// - "LOI_SAPIN_INVOICE_TYPE_MEDIA" : Invoices with Media cost.
  /// - "LOI_SAPIN_INVOICE_TYPE_PLATFORM" : Invoices with Platform fee.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of
  /// \[ListInvoicesResponse.next_page_token\] returned from the previous call
  /// to `ListInvoice` method. If not specified, the first page of results will
  /// be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListInvoicesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListInvoicesResponse> list(
    core.String advertiserId, {
    core.String? issueMonth,
    core.String? loiSapinInvoiceType,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (issueMonth != null) 'issueMonth': [issueMonth],
      if (loiSapinInvoiceType != null)
        'loiSapinInvoiceType': [loiSapinInvoiceType],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/advertisers/' + core.Uri.encodeFull('$advertiserId') + '/invoices';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListInvoicesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lookup invoice currency for an advertiser.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser to lookup currency
  /// for.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [invoiceMonth] - Month for which currency is needed in the format YYYYMM.
  /// If not set Api would return currency based on current settings.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LookupInvoiceCurrencyResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LookupInvoiceCurrencyResponse> lookupInvoiceCurrency(
    core.String advertiserId, {
    core.String? invoiceMonth,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (invoiceMonth != null) 'invoiceMonth': [invoiceMonth],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/invoices:lookupInvoiceCurrency';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LookupInvoiceCurrencyResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersLineItemsResource {
  final commons.ApiRequester _requester;

  AdvertisersLineItemsTargetingTypesResource get targetingTypes =>
      AdvertisersLineItemsTargetingTypesResource(_requester);

  AdvertisersLineItemsResource(commons.ApiRequester client)
      : _requester = client;

  /// Bulk edits targeting options under a single line item.
  ///
  /// The operation will delete the assigned targeting options provided in
  /// BulkEditLineItemAssignedTargetingOptionsRequest.delete_requests and then
  /// create the assigned targeting options provided in
  /// BulkEditLineItemAssignedTargetingOptionsRequest.create_requests .
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the line item belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [lineItemId] - Required. The ID of the line item the assigned targeting
  /// option will belong to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkEditLineItemAssignedTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkEditLineItemAssignedTargetingOptionsResponse>
      bulkEditLineItemAssignedTargetingOptions(
    BulkEditLineItemAssignedTargetingOptionsRequest request,
    core.String advertiserId,
    core.String lineItemId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/lineItems/' +
        core.Uri.encodeFull('$lineItemId') +
        ':bulkEditLineItemAssignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BulkEditLineItemAssignedTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists assigned targeting options of a line item across targeting types.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the line item belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [lineItemId] - Required. The ID of the line item to list assigned
  /// targeting options for.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by assigned targeting option properties.
  /// Supported syntax: * Filter expressions are made up of one or more
  /// restrictions. * Restrictions can be combined by the logical operator `OR`
  /// on the same field. * A restriction has the form of `{field} {operator}
  /// {value}`. * The operator must be `EQUALS (=)`. * Supported fields: -
  /// `targetingType` - `inheritance` Examples: * AssignedTargetingOptions of
  /// targeting type TARGETING_TYPE_PROXIMITY_LOCATION_LIST or
  /// TARGETING_TYPE_CHANNEL
  /// `targetingType="TARGETING_TYPE_PROXIMITY_LOCATION_LIST" OR
  /// targetingType="TARGETING_TYPE_CHANNEL"` * AssignedTargetingOptions with
  /// inheritance status of NOT_INHERITED or INHERITED_FROM_PARTNER
  /// `inheritance="NOT_INHERITED" OR inheritance="INHERITED_FROM_PARTNER"` The
  /// length of this field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `targetingType` (default) The default sorting order is ascending. To
  /// specify descending order for a field, a suffix "desc" should be added to
  /// the field name. Example: `targetingType desc`.
  ///
  /// [pageSize] - Requested page size. The size must be an integer between `1`
  /// and `5000`. If unspecified, the default is '5000'. Returns error code
  /// `INVALID_ARGUMENT` if an invalid value is specified.
  ///
  /// [pageToken] - A token that lets the client fetch the next page of results.
  /// Typically, this is the value of next_page_token returned from the previous
  /// call to `BulkListLineItemAssignedTargetingOptions` method. If not
  /// specified, the first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkListLineItemAssignedTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkListLineItemAssignedTargetingOptionsResponse>
      bulkListLineItemAssignedTargetingOptions(
    core.String advertiserId,
    core.String lineItemId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/lineItems/' +
        core.Uri.encodeFull('$lineItemId') +
        ':bulkListLineItemAssignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BulkListLineItemAssignedTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new line item.
  ///
  /// Returns the newly created line item if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Output only. The unique ID of the advertiser the line
  /// item belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LineItem].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LineItem> create(
    LineItem request,
    core.String advertiserId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/advertisers/' + core.Uri.encodeFull('$advertiserId') + '/lineItems';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LineItem.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a line item.
  ///
  /// Returns error code `NOT_FOUND` if the line item does not exist. The line
  /// item should be archived first, i.e. set entity_status to
  /// `ENTITY_STATUS_ARCHIVED`, to be able to delete it.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser this line item belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [lineItemId] - The ID of the line item we need to fetch.
  /// Value must have pattern `^\[^/\]+$`.
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
    core.String advertiserId,
    core.String lineItemId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/lineItems/' +
        core.Uri.encodeFull('$lineItemId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new line item with settings (including targeting) inherited from
  /// the insertion order and an `ENTITY_STATUS_DRAFT` entity_status.
  ///
  /// Returns the newly created line item if successful. There are default
  /// values based on the three fields: * The insertion order's
  /// insertion_order_type * The insertion order's automation_type * The given
  /// line_item_type
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser this line item belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LineItem].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LineItem> generateDefault(
    GenerateDefaultLineItemRequest request,
    core.String advertiserId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/lineItems:generateDefault';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LineItem.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a line item.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser this line item belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [lineItemId] - Required. The ID of the line item to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LineItem].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LineItem> get(
    core.String advertiserId,
    core.String lineItemId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/lineItems/' +
        core.Uri.encodeFull('$lineItemId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LineItem.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists line items in an advertiser.
  ///
  /// The order is defined by the order_by parameter. If a filter by
  /// entity_status is not specified, line items with `ENTITY_STATUS_ARCHIVED`
  /// will not be included in the results.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser to list line items
  /// for.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by line item properties. Supported syntax: *
  /// Filter expressions are made up of one or more restrictions. * Restrictions
  /// can be combined by `AND` or `OR` logical operators. A sequence of
  /// restrictions implicitly uses `AND`. * A restriction has the form of
  /// `{field} {operator} {value}`. * The operator used on
  /// `flight.dateRange.endDate` must be LESS THAN (<). * The operator used on
  /// `updateTime` must be `GREATER THAN OR EQUAL TO (>=)` or `LESS THAN OR
  /// EQUAL TO (<=)`. * The operator used on `warningMessages` must be `HAS
  /// (:)`. * The operators used on all other fields must be `EQUALS (=)`. *
  /// Supported properties: - `campaignId` - `displayName` - `insertionOrderId`
  /// - `entityStatus` - `lineItemId` - `lineItemType` -
  /// `flight.dateRange.endDate` (input formatted as YYYY-MM-DD) -
  /// `warningMessages` - `flight.triggerId` - `updateTime` (input in ISO 8601
  /// format, or YYYY-MM-DDTHH:MM:SSZ) - `targetedChannelId` -
  /// `targetedNegativeKeywordListId` Examples: * All line items under an
  /// insertion order: `insertionOrderId="1234"` * All `ENTITY_STATUS_ACTIVE` or
  /// `ENTITY_STATUS_PAUSED` and `LINE_ITEM_TYPE_DISPLAY_DEFAULT` line items
  /// under an advertiser: `(entityStatus="ENTITY_STATUS_ACTIVE" OR
  /// entityStatus="ENTITY_STATUS_PAUSED") AND
  /// lineItemType="LINE_ITEM_TYPE_DISPLAY_DEFAULT"` * All line items whose
  /// flight dates end before March 28, 2019:
  /// `flight.dateRange.endDate<"2019-03-28"` * All line items that have
  /// `NO_VALID_CREATIVE` in `warningMessages`:
  /// `warningMessages:"NO_VALID_CREATIVE"` * All line items with an update time
  /// less than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`:
  /// `updateTime<="2020-11-04T18:54:47Z"` * All line items with an update time
  /// greater than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`:
  /// `updateTime>="2020-11-04T18:54:47Z"` * All line items that are using both
  /// the specified channel and specified negative keyword list in their
  /// targeting: `targetedNegativeKeywordListId=789 AND targetedChannelId=12345`
  /// The length of this field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// "displayName" (default) * "entityStatus" * “flight.dateRange.endDate” *
  /// "updateTime" The default sorting order is ascending. To specify descending
  /// order for a field, a suffix "desc" should be added to the field name.
  /// Example: `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListLineItems` method. If not specified, the first page
  /// of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLineItemsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLineItemsResponse> list(
    core.String advertiserId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/advertisers/' + core.Uri.encodeFull('$advertiserId') + '/lineItems';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLineItemsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing line item.
  ///
  /// Returns the updated line item if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Output only. The unique ID of the advertiser the line
  /// item belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [lineItemId] - Output only. The unique ID of the line item. Assigned by
  /// the system.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LineItem].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LineItem> patch(
    LineItem request,
    core.String advertiserId,
    core.String lineItemId, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/lineItems/' +
        core.Uri.encodeFull('$lineItemId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return LineItem.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersLineItemsTargetingTypesResource {
  final commons.ApiRequester _requester;

  AdvertisersLineItemsTargetingTypesAssignedTargetingOptionsResource
      get assignedTargetingOptions =>
          AdvertisersLineItemsTargetingTypesAssignedTargetingOptionsResource(
              _requester);

  AdvertisersLineItemsTargetingTypesResource(commons.ApiRequester client)
      : _requester = client;
}

class AdvertisersLineItemsTargetingTypesAssignedTargetingOptionsResource {
  final commons.ApiRequester _requester;

  AdvertisersLineItemsTargetingTypesAssignedTargetingOptionsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Assigns a targeting option to a line item.
  ///
  /// Returns the assigned targeting option if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the line item belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [lineItemId] - Required. The ID of the line item the assigned targeting
  /// option will belong to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of this assigned targeting
  /// option.
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AssignedTargetingOption].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AssignedTargetingOption> create(
    AssignedTargetingOption request,
    core.String advertiserId,
    core.String lineItemId,
    core.String targetingType, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/lineItems/' +
        core.Uri.encodeFull('$lineItemId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AssignedTargetingOption.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an assigned targeting option from a line item.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the line item belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [lineItemId] - Required. The ID of the line item the assigned targeting
  /// option belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of this assigned targeting
  /// option.
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [assignedTargetingOptionId] - Required. The ID of the assigned targeting
  /// option to delete.
  /// Value must have pattern `^\[^/\]+$`.
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
    core.String advertiserId,
    core.String lineItemId,
    core.String targetingType,
    core.String assignedTargetingOptionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/lineItems/' +
        core.Uri.encodeFull('$lineItemId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions/' +
        core.Uri.encodeFull('$assignedTargetingOptionId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a single targeting option assigned to a line item.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the line item belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [lineItemId] - Required. The ID of the line item the assigned targeting
  /// option belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of this assigned targeting
  /// option.
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [assignedTargetingOptionId] - Required. An identifier unique to the
  /// targeting type in this line item that identifies the assigned targeting
  /// option being requested.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AssignedTargetingOption].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AssignedTargetingOption> get(
    core.String advertiserId,
    core.String lineItemId,
    core.String targetingType,
    core.String assignedTargetingOptionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/lineItems/' +
        core.Uri.encodeFull('$lineItemId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions/' +
        core.Uri.encodeFull('$assignedTargetingOptionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AssignedTargetingOption.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the targeting options assigned to a line item.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser the line item belongs
  /// to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [lineItemId] - Required. The ID of the line item to list assigned
  /// targeting options for.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of assigned targeting
  /// options to list.
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [filter] - Allows filtering by assigned targeting option properties.
  /// Supported syntax: * Filter expressions are made up of one or more
  /// restrictions. * Restrictions can be combined by the logical operator `OR`.
  /// * A restriction has the form of `{field} {operator} {value}`. * The
  /// operator must be `EQUALS (=)`. * Supported fields: -
  /// `assignedTargetingOptionId` - `inheritance` Examples: *
  /// AssignedTargetingOptions with ID 1 or 2 `assignedTargetingOptionId="1" OR
  /// assignedTargetingOptionId="2"` * AssignedTargetingOptions with inheritance
  /// status of NOT_INHERITED or INHERITED_FROM_PARTNER
  /// `inheritance="NOT_INHERITED" OR inheritance="INHERITED_FROM_PARTNER"` The
  /// length of this field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `assignedTargetingOptionId` (default) The default sorting order is
  /// ascending. To specify descending order for a field, a suffix "desc" should
  /// be added to the field name. Example: `assignedTargetingOptionId desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListLineItemAssignedTargetingOptions` method. If not
  /// specified, the first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLineItemAssignedTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLineItemAssignedTargetingOptionsResponse> list(
    core.String advertiserId,
    core.String lineItemId,
    core.String targetingType, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/lineItems/' +
        core.Uri.encodeFull('$lineItemId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLineItemAssignedTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersLocationListsResource {
  final commons.ApiRequester _requester;

  AdvertisersLocationListsAssignedLocationsResource get assignedLocations =>
      AdvertisersLocationListsAssignedLocationsResource(_requester);

  AdvertisersLocationListsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new location list.
  ///
  /// Returns the newly created location list if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// location list belongs.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LocationList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LocationList> create(
    LocationList request,
    core.String advertiserId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/locationLists';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LocationList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a location list.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// fetched location list belongs.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [locationListId] - Required. The ID of the location list to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LocationList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LocationList> get(
    core.String advertiserId,
    core.String locationListId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/locationLists/' +
        core.Uri.encodeFull('$locationListId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LocationList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists location lists based on a given advertiser id.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// fetched location lists belong.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by location list fields. Supported syntax: *
  /// Filter expressions are made up of one or more restrictions. * Restrictions
  /// can be combined by `AND` or `OR` logical operators. A sequence of
  /// restrictions implicitly uses `AND`. * A restriction has the form of
  /// `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. *
  /// Supported fields: - `locationType` Examples: * All regional location list:
  /// `locationType="TARGETING_LOCATION_TYPE_REGIONAL"` * All proximity location
  /// list: `locationType="TARGETING_LOCATION_TYPE_PROXIMITY"`
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `locationListId` (default) * `displayName` The default sorting order is
  /// ascending. To specify descending order for a field, a suffix "desc" should
  /// be added to the field name. Example: `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. Defaults
  /// to `100` if not set. Returns error code `INVALID_ARGUMENT` if an invalid
  /// value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListLocationLists` method. If not specified, the first
  /// page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLocationListsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLocationListsResponse> list(
    core.String advertiserId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/locationLists';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLocationListsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a location list.
  ///
  /// Returns the updated location list if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// location lists belongs.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [locationListId] - Output only. The unique ID of the location list.
  /// Assigned by the system.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LocationList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LocationList> patch(
    LocationList request,
    core.String advertiserId,
    core.String locationListId, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/locationLists/' +
        commons.escapeVariable('$locationListId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return LocationList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersLocationListsAssignedLocationsResource {
  final commons.ApiRequester _requester;

  AdvertisersLocationListsAssignedLocationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Bulk edits multiple assignments between locations and a single location
  /// list.
  ///
  /// The operation will delete the assigned locations provided in
  /// BulkEditAssignedLocationsRequest.deleted_assigned_locations and then
  /// create the assigned locations provided in
  /// BulkEditAssignedLocationsRequest.created_assigned_locations.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// location list belongs.
  ///
  /// [locationListId] - Required. The ID of the location list to which these
  /// assignments are assigned.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkEditAssignedLocationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkEditAssignedLocationsResponse> bulkEdit(
    BulkEditAssignedLocationsRequest request,
    core.String advertiserId,
    core.String locationListId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        commons.escapeVariable('$advertiserId') +
        '/locationLists/' +
        core.Uri.encodeFull('$locationListId') +
        '/assignedLocations:bulkEdit';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BulkEditAssignedLocationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates an assignment between a location and a location list.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// location list belongs.
  ///
  /// [locationListId] - Required. The ID of the location list for which the
  /// assignment will be created.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AssignedLocation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AssignedLocation> create(
    AssignedLocation request,
    core.String advertiserId,
    core.String locationListId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        commons.escapeVariable('$advertiserId') +
        '/locationLists/' +
        commons.escapeVariable('$locationListId') +
        '/assignedLocations';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AssignedLocation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the assignment between a location and a location list.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// location list belongs.
  ///
  /// [locationListId] - Required. The ID of the location list to which this
  /// assignment is assigned.
  ///
  /// [assignedLocationId] - Required. The ID of the assigned location to
  /// delete.
  /// Value must have pattern `^\[^/\]+$`.
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
    core.String advertiserId,
    core.String locationListId,
    core.String assignedLocationId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        commons.escapeVariable('$advertiserId') +
        '/locationLists/' +
        commons.escapeVariable('$locationListId') +
        '/assignedLocations/' +
        core.Uri.encodeFull('$assignedLocationId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists locations assigned to a location list.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// location list belongs.
  ///
  /// [locationListId] - Required. The ID of the location list to which these
  /// assignments are assigned.
  ///
  /// [filter] - Allows filtering by location list assignment fields. Supported
  /// syntax: * Filter expressions are made up of one or more restrictions. *
  /// Restrictions can be combined by the logical operator `OR`. * A restriction
  /// has the form of `{field} {operator} {value}`. * The operator must be
  /// `EQUALS (=)`. * Supported fields: - `assignedLocationId` The length of
  /// this field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `assignedLocationId` (default) The default sorting order is ascending. To
  /// specify descending order for a field, a suffix " desc" should be added to
  /// the field name. Example: `assignedLocationId desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListAssignedLocations` method. If not specified, the
  /// first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAssignedLocationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAssignedLocationsResponse> list(
    core.String advertiserId,
    core.String locationListId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        commons.escapeVariable('$advertiserId') +
        '/locationLists/' +
        commons.escapeVariable('$locationListId') +
        '/assignedLocations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAssignedLocationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersManualTriggersResource {
  final commons.ApiRequester _requester;

  AdvertisersManualTriggersResource(commons.ApiRequester client)
      : _requester = client;

  /// Activates a manual trigger.
  ///
  /// Each activation of the manual trigger must be at least 5 minutes apart,
  /// otherwise an error will be returned.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser that the manual
  /// trigger belongs.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [triggerId] - Required. The ID of the manual trigger to activate.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManualTrigger].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManualTrigger> activate(
    ActivateManualTriggerRequest request,
    core.String advertiserId,
    core.String triggerId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/manualTriggers/' +
        core.Uri.encodeFull('$triggerId') +
        ':activate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ManualTrigger.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new manual trigger.
  ///
  /// Returns the newly created manual trigger if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. Immutable. The unique ID of the advertiser that
  /// the manual trigger belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManualTrigger].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManualTrigger> create(
    ManualTrigger request,
    core.String advertiserId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/manualTriggers';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ManualTrigger.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deactivates a manual trigger.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser that the manual
  /// trigger belongs.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [triggerId] - Required. The ID of the manual trigger to deactivate.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManualTrigger].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManualTrigger> deactivate(
    DeactivateManualTriggerRequest request,
    core.String advertiserId,
    core.String triggerId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/manualTriggers/' +
        core.Uri.encodeFull('$triggerId') +
        ':deactivate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ManualTrigger.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a manual trigger.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser this manual trigger
  /// belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [triggerId] - Required. The ID of the manual trigger to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManualTrigger].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManualTrigger> get(
    core.String advertiserId,
    core.String triggerId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/manualTriggers/' +
        core.Uri.encodeFull('$triggerId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ManualTrigger.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists manual triggers that are accessible to the current user for a given
  /// advertiser ID.
  ///
  /// The order is defined by the order_by parameter. A single advertiser_id is
  /// required.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser that the fetched
  /// manual triggers belong to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by manual trigger properties. Supported
  /// syntax: * Filter expressions are made up of one or more restrictions. *
  /// Restrictions can be combined by `AND` or `OR` logical operators. A
  /// sequence of restrictions implicitly uses `AND`. * A restriction has the
  /// form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`.
  /// * Supported fields: - `displayName` - `state` Examples: * All active
  /// manual triggers under an advertiser: `state="ACTIVE"` The length of this
  /// field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `displayName` (default) * `state` The default sorting order is ascending.
  /// To specify descending order for a field, a suffix "desc" should be added
  /// to the field name. For example, `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListManualTriggers` method. If not specified, the first
  /// page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListManualTriggersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListManualTriggersResponse> list(
    core.String advertiserId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/manualTriggers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListManualTriggersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a manual trigger.
  ///
  /// Returns the updated manual trigger if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. Immutable. The unique ID of the advertiser that
  /// the manual trigger belongs to.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [triggerId] - Output only. The unique ID of the manual trigger.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManualTrigger].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManualTrigger> patch(
    ManualTrigger request,
    core.String advertiserId,
    core.String triggerId, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/manualTriggers/' +
        core.Uri.encodeFull('$triggerId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return ManualTrigger.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersNegativeKeywordListsResource {
  final commons.ApiRequester _requester;

  AdvertisersNegativeKeywordListsNegativeKeywordsResource
      get negativeKeywords =>
          AdvertisersNegativeKeywordListsNegativeKeywordsResource(_requester);

  AdvertisersNegativeKeywordListsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new negative keyword list.
  ///
  /// Returns the newly created negative keyword list if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// negative keyword list will belong.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [NegativeKeywordList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<NegativeKeywordList> create(
    NegativeKeywordList request,
    core.String advertiserId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/negativeKeywordLists';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return NegativeKeywordList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a negative keyword list given an advertiser ID and a negative
  /// keyword list ID.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// negative keyword list belongs.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [negativeKeywordListId] - Required. The ID of the negative keyword list to
  /// delete.
  /// Value must have pattern `^\[^/\]+$`.
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
    core.String advertiserId,
    core.String negativeKeywordListId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/negativeKeywordLists/' +
        core.Uri.encodeFull('$negativeKeywordListId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a negative keyword list given an advertiser ID and a negative keyword
  /// list ID.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// fetched negative keyword list belongs.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [negativeKeywordListId] - Required. The ID of the negative keyword list to
  /// fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [NegativeKeywordList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<NegativeKeywordList> get(
    core.String advertiserId,
    core.String negativeKeywordListId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/negativeKeywordLists/' +
        core.Uri.encodeFull('$negativeKeywordListId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return NegativeKeywordList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists negative keyword lists based on a given advertiser id.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// fetched negative keyword lists belong.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. Defaults
  /// to `100` if not set. Returns error code `INVALID_ARGUMENT` if an invalid
  /// value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListNegativeKeywordLists` method. If not specified, the
  /// first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListNegativeKeywordListsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListNegativeKeywordListsResponse> list(
    core.String advertiserId, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/negativeKeywordLists';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListNegativeKeywordListsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a negative keyword list.
  ///
  /// Returns the updated negative keyword list if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// negative keyword list belongs.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [negativeKeywordListId] - Output only. The unique ID of the negative
  /// keyword list. Assigned by the system.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [NegativeKeywordList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<NegativeKeywordList> patch(
    NegativeKeywordList request,
    core.String advertiserId,
    core.String negativeKeywordListId, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/negativeKeywordLists/' +
        commons.escapeVariable('$negativeKeywordListId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return NegativeKeywordList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersNegativeKeywordListsNegativeKeywordsResource {
  final commons.ApiRequester _requester;

  AdvertisersNegativeKeywordListsNegativeKeywordsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Bulk edits negative keywords in a single negative keyword list.
  ///
  /// The operation will delete the negative keywords provided in
  /// BulkEditNegativeKeywordsRequest.deleted_negative_keywords and then create
  /// the negative keywords provided in
  /// BulkEditNegativeKeywordsRequest.created_negative_keywords. This operation
  /// is guaranteed to be atomic and will never result in a partial success or
  /// partial failure.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// parent negative keyword list belongs.
  ///
  /// [negativeKeywordListId] - Required. The ID of the parent negative keyword
  /// list to which the negative keywords belong.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkEditNegativeKeywordsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkEditNegativeKeywordsResponse> bulkEdit(
    BulkEditNegativeKeywordsRequest request,
    core.String advertiserId,
    core.String negativeKeywordListId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        commons.escapeVariable('$advertiserId') +
        '/negativeKeywordLists/' +
        core.Uri.encodeFull('$negativeKeywordListId') +
        '/negativeKeywords:bulkEdit';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BulkEditNegativeKeywordsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a negative keyword in a negative keyword list.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// parent negative keyword list belongs.
  ///
  /// [negativeKeywordListId] - Required. The ID of the parent negative keyword
  /// list in which the negative keyword will be created.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [NegativeKeyword].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<NegativeKeyword> create(
    NegativeKeyword request,
    core.String advertiserId,
    core.String negativeKeywordListId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        commons.escapeVariable('$advertiserId') +
        '/negativeKeywordLists/' +
        core.Uri.encodeFull('$negativeKeywordListId') +
        '/negativeKeywords';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return NegativeKeyword.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a negative keyword from a negative keyword list.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// parent negative keyword list belongs.
  ///
  /// [negativeKeywordListId] - Required. The ID of the parent negative keyword
  /// list to which the negative keyword belongs.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [keywordValue] - Required. The keyword value of the negative keyword to
  /// delete.
  /// Value must have pattern `^\[^/\]+$`.
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
    core.String advertiserId,
    core.String negativeKeywordListId,
    core.String keywordValue, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        commons.escapeVariable('$advertiserId') +
        '/negativeKeywordLists/' +
        core.Uri.encodeFull('$negativeKeywordListId') +
        '/negativeKeywords/' +
        core.Uri.encodeFull('$keywordValue');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists negative keywords in a negative keyword list.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// parent negative keyword list belongs.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [negativeKeywordListId] - Required. The ID of the parent negative keyword
  /// list to which the requested negative keywords belong.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - Allows filtering by negative keyword fields. Supported syntax:
  /// * Filter expressions for negative keyword currently can only contain at
  /// most one * restriction. * A restriction has the form of `{field}
  /// {operator} {value}`. * The operator must be `CONTAINS (:)`. * Supported
  /// fields: - `keywordValue` Examples: * All negative keywords for which the
  /// keyword value contains "google": `keywordValue : "google"`
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `keywordValue` (default) The default sorting order is ascending. To
  /// specify descending order for a field, a suffix " desc" should be added to
  /// the field name. Example: `keywordValue desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `1000`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListNegativeKeywords` method. If not specified, the
  /// first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListNegativeKeywordsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListNegativeKeywordsResponse> list(
    core.String advertiserId,
    core.String negativeKeywordListId, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/negativeKeywordLists/' +
        core.Uri.encodeFull('$negativeKeywordListId') +
        '/negativeKeywords';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListNegativeKeywordsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Replaces all negative keywords in a single negative keyword list.
  ///
  /// The operation will replace the keywords in a negative keyword list with
  /// keywords provided in ReplaceNegativeKeywordsRequest.new_negative_keywords.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the DV360 advertiser to which the
  /// parent negative keyword list belongs.
  ///
  /// [negativeKeywordListId] - Required. The ID of the parent negative keyword
  /// list to which the negative keywords belong.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReplaceNegativeKeywordsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReplaceNegativeKeywordsResponse> replace(
    ReplaceNegativeKeywordsRequest request,
    core.String advertiserId,
    core.String negativeKeywordListId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        commons.escapeVariable('$advertiserId') +
        '/negativeKeywordLists/' +
        core.Uri.encodeFull('$negativeKeywordListId') +
        '/negativeKeywords:replace';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ReplaceNegativeKeywordsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersTargetingTypesResource {
  final commons.ApiRequester _requester;

  AdvertisersTargetingTypesAssignedTargetingOptionsResource
      get assignedTargetingOptions =>
          AdvertisersTargetingTypesAssignedTargetingOptionsResource(_requester);

  AdvertisersTargetingTypesResource(commons.ApiRequester client)
      : _requester = client;
}

class AdvertisersTargetingTypesAssignedTargetingOptionsResource {
  final commons.ApiRequester _requester;

  AdvertisersTargetingTypesAssignedTargetingOptionsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Assigns a targeting option to an advertiser.
  ///
  /// Returns the assigned targeting option if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of this assigned targeting
  /// option. Supported targeting types: * `TARGETING_TYPE_CHANNEL` *
  /// `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` *
  /// `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AssignedTargetingOption].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AssignedTargetingOption> create(
    AssignedTargetingOption request,
    core.String advertiserId,
    core.String targetingType, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AssignedTargetingOption.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an assigned targeting option from an advertiser.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of this assigned targeting
  /// option. Supported targeting types: * `TARGETING_TYPE_CHANNEL` *
  /// `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` *
  /// `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [assignedTargetingOptionId] - Required. The ID of the assigned targeting
  /// option to delete.
  /// Value must have pattern `^\[^/\]+$`.
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
    core.String advertiserId,
    core.String targetingType,
    core.String assignedTargetingOptionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions/' +
        core.Uri.encodeFull('$assignedTargetingOptionId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a single targeting option assigned to an advertiser.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of this assigned targeting
  /// option. Supported targeting types: * `TARGETING_TYPE_CHANNEL` *
  /// `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` *
  /// `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [assignedTargetingOptionId] - Required. An identifier unique to the
  /// targeting type in this advertiser that identifies the assigned targeting
  /// option being requested.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AssignedTargetingOption].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AssignedTargetingOption> get(
    core.String advertiserId,
    core.String targetingType,
    core.String assignedTargetingOptionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions/' +
        core.Uri.encodeFull('$assignedTargetingOptionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AssignedTargetingOption.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the targeting options assigned to an advertiser.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - Required. The ID of the advertiser.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of assigned targeting
  /// options to list. Supported targeting types: * `TARGETING_TYPE_CHANNEL` *
  /// `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` *
  /// `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [filter] - Allows filtering by assigned targeting option properties.
  /// Supported syntax: * Filter expressions are made up of one or more
  /// restrictions. * Restrictions can be combined by the logical operator `OR`.
  /// * A restriction has the form of `{field} {operator} {value}`. * The
  /// operator must be `EQUALS (=)`. * Supported fields: -
  /// `assignedTargetingOptionId` Examples: * AssignedTargetingOption with ID
  /// 123456 `assignedTargetingOptionId="123456"` The length of this field
  /// should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `assignedTargetingOptionId` (default) The default sorting order is
  /// ascending. To specify descending order for a field, a suffix "desc" should
  /// be added to the field name. Example: `assignedTargetingOptionId desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListAdvertiserAssignedTargetingOptions` method. If not
  /// specified, the first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAdvertiserAssignedTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAdvertiserAssignedTargetingOptionsResponse> list(
    core.String advertiserId,
    core.String targetingType, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/advertisers/' +
        core.Uri.encodeFull('$advertiserId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAdvertiserAssignedTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CombinedAudiencesResource {
  final commons.ApiRequester _requester;

  CombinedAudiencesResource(commons.ApiRequester client) : _requester = client;

  /// Gets a combined audience.
  ///
  /// Request parameters:
  ///
  /// [combinedAudienceId] - Required. The ID of the combined audience to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that has access to the fetched
  /// combined audience.
  ///
  /// [partnerId] - The ID of the partner that has access to the fetched
  /// combined audience.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CombinedAudience].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CombinedAudience> get(
    core.String combinedAudienceId, {
    core.String? advertiserId,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/combinedAudiences/' + core.Uri.encodeFull('$combinedAudienceId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CombinedAudience.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists combined audiences.
  ///
  /// The order is defined by the order_by parameter.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that has access to the fetched
  /// combined audiences.
  ///
  /// [filter] - Allows filtering by combined audience fields. Supported syntax:
  /// * Filter expressions for combined audiences currently can only contain at
  /// most one restriction. * A restriction has the form of `{field} {operator}
  /// {value}`. * The operator must be `CONTAINS (:)`. * Supported fields: -
  /// `displayName` Examples: * All combined audiences for which the display
  /// name contains "Google": `displayName : "Google"`. The length of this field
  /// should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `combinedAudienceId` (default) * `displayName` The default sorting order
  /// is ascending. To specify descending order for a field, a suffix "desc"
  /// should be added to the field name. Example: `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListCombinedAudiences` method. If not specified, the
  /// first page of results will be returned.
  ///
  /// [partnerId] - The ID of the partner that has access to the fetched
  /// combined audiences.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCombinedAudiencesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCombinedAudiencesResponse> list({
    core.String? advertiserId,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/combinedAudiences';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCombinedAudiencesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CustomBiddingAlgorithmsResource {
  final commons.ApiRequester _requester;

  CustomBiddingAlgorithmsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets a custom bidding algorithm.
  ///
  /// Request parameters:
  ///
  /// [customBiddingAlgorithmId] - Required. The ID of the custom bidding
  /// algorithm to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the DV360 partner that has access to the custom
  /// bidding algorithm.
  ///
  /// [partnerId] - The ID of the DV360 partner that has access to the custom
  /// bidding algorithm.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CustomBiddingAlgorithm].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CustomBiddingAlgorithm> get(
    core.String customBiddingAlgorithmId, {
    core.String? advertiserId,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/customBiddingAlgorithms/' +
        core.Uri.encodeFull('$customBiddingAlgorithmId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CustomBiddingAlgorithm.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists custom bidding algorithms that are accessible to the current user
  /// and can be used in bidding stratgies.
  ///
  /// The order is defined by the order_by parameter.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the DV360 advertiser that has access to the
  /// custom bidding algorithm.
  ///
  /// [filter] - Allows filtering by custom bidding algorithm fields. Supported
  /// syntax: * Filter expressions are made up of one or more restrictions. *
  /// Restrictions can be combined by `AND`. A sequence of restrictions *
  /// implicitly uses `AND`. * A restriction has the form of `{field} {operator}
  /// {value}`. * The operator must be `CONTAINS (:)` or `EQUALS (=)`. * The
  /// operator must be `CONTAINS (:)` for the following field: - `displayName` *
  /// The operator must be `EQUALS (=)` for the following field: -
  /// `customBiddingAlgorithmType` * For `displayName`, the value is a string.
  /// We return all custom bidding algorithms whose display_name contains such
  /// string. * For `customBiddingAlgorithmType`, the value is a string. We
  /// return all algorithms whose custom_bidding_algorithm_type is equal to the
  /// given type. Examples: * All custom bidding algorithms for which the
  /// display name contains "politics": `displayName:politics`. * All custom
  /// bidding algorithms for which the type is "SCRIPT_BASED":
  /// `customBiddingAlgorithmType=SCRIPT_BASED` The length of this field should
  /// be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `displayName` (default) The default sorting order is ascending. To specify
  /// descending order for a field, a suffix "desc" should be added to the field
  /// name. Example: `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListCustomBiddingAlgorithms` method. If not specified,
  /// the first page of results will be returned.
  ///
  /// [partnerId] - The ID of the DV360 partner that has access to the custom
  /// bidding algorithm.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCustomBiddingAlgorithmsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCustomBiddingAlgorithmsResponse> list({
    core.String? advertiserId,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/customBiddingAlgorithms';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCustomBiddingAlgorithmsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CustomListsResource {
  final commons.ApiRequester _requester;

  CustomListsResource(commons.ApiRequester client) : _requester = client;

  /// Gets a custom list.
  ///
  /// Request parameters:
  ///
  /// [customListId] - Required. The ID of the custom list to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the DV360 advertiser that has access to the
  /// fetched custom lists.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CustomList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CustomList> get(
    core.String customListId, {
    core.String? advertiserId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/customLists/' + core.Uri.encodeFull('$customListId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CustomList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists custom lists.
  ///
  /// The order is defined by the order_by parameter.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the DV360 advertiser that has access to the
  /// fetched custom lists.
  ///
  /// [filter] - Allows filtering by custom list fields. Supported syntax: *
  /// Filter expressions for custom lists currently can only contain at most one
  /// restriction. * A restriction has the form of `{field} {operator} {value}`.
  /// * The operator must be `CONTAINS (:)`. * Supported fields: - `displayName`
  /// Examples: * All custom lists for which the display name contains "Google":
  /// `displayName : "Google"`. The length of this field should be no more than
  /// 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `customListId` (default) * `displayName` The default sorting order is
  /// ascending. To specify descending order for a field, a suffix "desc" should
  /// be added to the field name. Example: `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListCustomLists` method. If not specified, the first
  /// page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCustomListsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCustomListsResponse> list({
    core.String? advertiserId,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/customLists';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCustomListsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FirstAndThirdPartyAudiencesResource {
  final commons.ApiRequester _requester;

  FirstAndThirdPartyAudiencesResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets a first and third party audience.
  ///
  /// Request parameters:
  ///
  /// [firstAndThirdPartyAudienceId] - Required. The ID of the first and third
  /// party audience to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that has access to the fetched
  /// first and third party audience.
  ///
  /// [partnerId] - The ID of the partner that has access to the fetched first
  /// and third party audience.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FirstAndThirdPartyAudience].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FirstAndThirdPartyAudience> get(
    core.String firstAndThirdPartyAudienceId, {
    core.String? advertiserId,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/firstAndThirdPartyAudiences/' +
        core.Uri.encodeFull('$firstAndThirdPartyAudienceId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FirstAndThirdPartyAudience.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists first and third party audiences.
  ///
  /// The order is defined by the order_by parameter.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that has access to the fetched
  /// first and third party audiences.
  ///
  /// [filter] - Allows filtering by first and third party audience fields.
  /// Supported syntax: * Filter expressions for first and third party audiences
  /// currently can only contain at most one restriction. * A restriction has
  /// the form of `{field} {operator} {value}`. * The operator must be `CONTAINS
  /// (:)`. * Supported fields: - `displayName` Examples: * All first and third
  /// party audiences for which the display name contains "Google": `displayName
  /// : "Google"`. The length of this field should be no more than 500
  /// characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `firstAndThirdPartyAudienceId` (default) * `displayName` The default
  /// sorting order is ascending. To specify descending order for a field, a
  /// suffix "desc" should be added to the field name. Example: `displayName
  /// desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListFirstAndThirdPartyAudiences` method. If not
  /// specified, the first page of results will be returned.
  ///
  /// [partnerId] - The ID of the partner that has access to the fetched first
  /// and third party audiences.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListFirstAndThirdPartyAudiencesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListFirstAndThirdPartyAudiencesResponse> list({
    core.String? advertiserId,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/firstAndThirdPartyAudiences';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListFirstAndThirdPartyAudiencesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FloodlightGroupsResource {
  final commons.ApiRequester _requester;

  FloodlightGroupsResource(commons.ApiRequester client) : _requester = client;

  /// Gets a Floodlight group.
  ///
  /// Request parameters:
  ///
  /// [floodlightGroupId] - Required. The ID of the Floodlight group to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [partnerId] - Required. The partner context by which the Floodlight group
  /// is being accessed.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightGroup> get(
    core.String floodlightGroupId, {
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/floodlightGroups/' + core.Uri.encodeFull('$floodlightGroupId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FloodlightGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing Floodlight group.
  ///
  /// Returns the updated Floodlight group if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [floodlightGroupId] - Output only. The unique ID of the Floodlight group.
  /// Assigned by the system.
  ///
  /// [partnerId] - Required. The partner context by which the Floodlight group
  /// is being accessed.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightGroup> patch(
    FloodlightGroup request,
    core.String floodlightGroupId, {
    core.String? partnerId,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (partnerId != null) 'partnerId': [partnerId],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/floodlightGroups/' + commons.escapeVariable('$floodlightGroupId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return FloodlightGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class GoogleAudiencesResource {
  final commons.ApiRequester _requester;

  GoogleAudiencesResource(commons.ApiRequester client) : _requester = client;

  /// Gets a Google audience.
  ///
  /// Request parameters:
  ///
  /// [googleAudienceId] - Required. The ID of the Google audience to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that has access to the fetched
  /// Google audience.
  ///
  /// [partnerId] - The ID of the partner that has access to the fetched Google
  /// audience.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleAudience].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleAudience> get(
    core.String googleAudienceId, {
    core.String? advertiserId,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/googleAudiences/' + core.Uri.encodeFull('$googleAudienceId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleAudience.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists Google audiences.
  ///
  /// The order is defined by the order_by parameter.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that has access to the fetched
  /// Google audiences.
  ///
  /// [filter] - Allows filtering by Google audience fields. Supported syntax: *
  /// Filter expressions for Google audiences currently can only contain at most
  /// one restriction. * A restriction has the form of `{field} {operator}
  /// {value}`. * The operator must be `CONTAINS (:)`. * Supported fields: -
  /// `displayName` Examples: * All Google audiences for which the display name
  /// contains "Google": `displayName : "Google"`. The length of this field
  /// should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `googleAudienceId` (default) * `displayName` The default sorting order is
  /// ascending. To specify descending order for a field, a suffix "desc" should
  /// be added to the field name. Example: `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListGoogleAudiences` method. If not specified, the first
  /// page of results will be returned.
  ///
  /// [partnerId] - The ID of the partner that has access to the fetched Google
  /// audiences.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListGoogleAudiencesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListGoogleAudiencesResponse> list({
    core.String? advertiserId,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/googleAudiences';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListGoogleAudiencesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class InventorySourceGroupsResource {
  final commons.ApiRequester _requester;

  InventorySourceGroupsAssignedInventorySourcesResource
      get assignedInventorySources =>
          InventorySourceGroupsAssignedInventorySourcesResource(_requester);

  InventorySourceGroupsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new inventory source group.
  ///
  /// Returns the newly created inventory source group if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that owns the inventory source
  /// group. The parent partner will not have access to this group.
  ///
  /// [partnerId] - The ID of the partner that owns the inventory source group.
  /// Only this partner will have write access to this group. Only advertisers
  /// to which this group is explicitly shared will have read access to this
  /// group.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [InventorySourceGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<InventorySourceGroup> create(
    InventorySourceGroup request, {
    core.String? advertiserId,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/inventorySourceGroups';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return InventorySourceGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an inventory source group.
  ///
  /// Request parameters:
  ///
  /// [inventorySourceGroupId] - Required. The ID of the inventory source group
  /// to delete.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that owns the inventory source
  /// group. The parent partner does not have access to this group.
  ///
  /// [partnerId] - The ID of the partner that owns the inventory source group.
  /// Only this partner has write access to this group.
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
    core.String inventorySourceGroupId, {
    core.String? advertiserId,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/inventorySourceGroups/' +
        core.Uri.encodeFull('$inventorySourceGroupId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets an inventory source group.
  ///
  /// Request parameters:
  ///
  /// [inventorySourceGroupId] - Required. The ID of the inventory source group
  /// to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that has access to the inventory
  /// source group. If an inventory source group is partner-owned, only
  /// advertisers to which the group is explicitly shared can access the group.
  ///
  /// [partnerId] - The ID of the partner that has access to the inventory
  /// source group. A partner cannot access an advertiser-owned inventory source
  /// group.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [InventorySourceGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<InventorySourceGroup> get(
    core.String inventorySourceGroupId, {
    core.String? advertiserId,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/inventorySourceGroups/' +
        core.Uri.encodeFull('$inventorySourceGroupId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return InventorySourceGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists inventory source groups that are accessible to the current user.
  ///
  /// The order is defined by the order_by parameter.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that has access to the inventory
  /// source group. If an inventory source group is partner-owned, only
  /// advertisers to which the group is explicitly shared can access the group.
  ///
  /// [filter] - Allows filtering by inventory source group properties.
  /// Supported syntax: * Filter expressions are made up of one or more
  /// restrictions. * Restrictions can be combined by the logical operator `OR`.
  /// * A restriction has the form of `{field} {operator} {value}`. * The
  /// operator must be `EQUALS (=)`. * Supported fields: -
  /// `inventorySourceGroupId` The length of this field should be no more than
  /// 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `displayName` (default) * `inventorySourceGroupId` The default sorting
  /// order is ascending. To specify descending order for a field, a suffix
  /// "desc" should be added to the field name. For example, `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListInventorySources` method. If not specified, the
  /// first page of results will be returned.
  ///
  /// [partnerId] - The ID of the partner that has access to the inventory
  /// source group. A partner cannot access advertiser-owned inventory source
  /// groups.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListInventorySourceGroupsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListInventorySourceGroupsResponse> list({
    core.String? advertiserId,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/inventorySourceGroups';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListInventorySourceGroupsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an inventory source group.
  ///
  /// Returns the updated inventory source group if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [inventorySourceGroupId] - Output only. The unique ID of the inventory
  /// source group. Assigned by the system.
  ///
  /// [advertiserId] - The ID of the advertiser that owns the inventory source
  /// group. The parent partner does not have access to this group.
  ///
  /// [partnerId] - The ID of the partner that owns the inventory source group.
  /// Only this partner has write access to this group.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [InventorySourceGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<InventorySourceGroup> patch(
    InventorySourceGroup request,
    core.String inventorySourceGroupId, {
    core.String? advertiserId,
    core.String? partnerId,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (partnerId != null) 'partnerId': [partnerId],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/inventorySourceGroups/' +
        commons.escapeVariable('$inventorySourceGroupId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return InventorySourceGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class InventorySourceGroupsAssignedInventorySourcesResource {
  final commons.ApiRequester _requester;

  InventorySourceGroupsAssignedInventorySourcesResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Bulk edits multiple assignments between inventory sources and a single
  /// inventory source group.
  ///
  /// The operation will delete the assigned inventory sources provided in
  /// BulkEditAssignedInventorySourcesRequest.deleted_assigned_inventory_sources
  /// and then create the assigned inventory sources provided in
  /// BulkEditAssignedInventorySourcesRequest.created_assigned_inventory_sources.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [inventorySourceGroupId] - Required. The ID of the inventory source group
  /// to which the assignments are assigned.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkEditAssignedInventorySourcesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkEditAssignedInventorySourcesResponse> bulkEdit(
    BulkEditAssignedInventorySourcesRequest request,
    core.String inventorySourceGroupId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/inventorySourceGroups/' +
        core.Uri.encodeFull('$inventorySourceGroupId') +
        '/assignedInventorySources:bulkEdit';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BulkEditAssignedInventorySourcesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates an assignment between an inventory source and an inventory source
  /// group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [inventorySourceGroupId] - Required. The ID of the inventory source group
  /// to which the assignment will be assigned.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that owns the parent inventory
  /// source group. The parent partner will not have access to this assigned
  /// inventory source.
  ///
  /// [partnerId] - The ID of the partner that owns the parent inventory source
  /// group. Only this partner will have write access to this assigned inventory
  /// source.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AssignedInventorySource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AssignedInventorySource> create(
    AssignedInventorySource request,
    core.String inventorySourceGroupId, {
    core.String? advertiserId,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/inventorySourceGroups/' +
        core.Uri.encodeFull('$inventorySourceGroupId') +
        '/assignedInventorySources';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AssignedInventorySource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the assignment between an inventory source and an inventory source
  /// group.
  ///
  /// Request parameters:
  ///
  /// [inventorySourceGroupId] - Required. The ID of the inventory source group
  /// to which this assignment is assigned.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [assignedInventorySourceId] - Required. The ID of the assigned inventory
  /// source to delete.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that owns the parent inventory
  /// source group. The parent partner does not have access to this assigned
  /// inventory source.
  ///
  /// [partnerId] - The ID of the partner that owns the parent inventory source
  /// group. Only this partner has write access to this assigned inventory
  /// source.
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
    core.String inventorySourceGroupId,
    core.String assignedInventorySourceId, {
    core.String? advertiserId,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/inventorySourceGroups/' +
        core.Uri.encodeFull('$inventorySourceGroupId') +
        '/assignedInventorySources/' +
        core.Uri.encodeFull('$assignedInventorySourceId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists inventory sources assigned to an inventory source group.
  ///
  /// Request parameters:
  ///
  /// [inventorySourceGroupId] - Required. The ID of the inventory source group
  /// to which these assignments are assigned.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that has access to the
  /// assignment. If the parent inventory source group is partner-owned, only
  /// advertisers to which the parent group is explicitly shared can access the
  /// assigned inventory source.
  ///
  /// [filter] - Allows filtering by assigned inventory source fields. Supported
  /// syntax: * Filter expressions are made up of one or more restrictions. *
  /// Restrictions can be combined by the logical operator `OR`. * A restriction
  /// has the form of `{field} {operator} {value}`. * The operator must be
  /// `EQUALS (=)`. * Supported fields: - `assignedInventorySourceId` The length
  /// of this field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `assignedInventorySourceId` (default) The default sorting order is
  /// ascending. To specify descending order for a field, a suffix " desc"
  /// should be added to the field name. Example: `assignedInventorySourceId
  /// desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListAssignedInventorySources` method. If not specified,
  /// the first page of results will be returned.
  ///
  /// [partnerId] - The ID of the partner that has access to the assignment. If
  /// the parent inventory source group is advertiser-owned, the assignment
  /// cannot be accessed via a partner.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAssignedInventorySourcesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAssignedInventorySourcesResponse> list(
    core.String inventorySourceGroupId, {
    core.String? advertiserId,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/inventorySourceGroups/' +
        core.Uri.encodeFull('$inventorySourceGroupId') +
        '/assignedInventorySources';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAssignedInventorySourcesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class InventorySourcesResource {
  final commons.ApiRequester _requester;

  InventorySourcesResource(commons.ApiRequester client) : _requester = client;

  /// Gets an inventory source.
  ///
  /// Request parameters:
  ///
  /// [inventorySourceId] - Required. The ID of the inventory source to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [partnerId] - Required. The ID of the DV360 partner to which the fetched
  /// inventory source is permissioned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [InventorySource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<InventorySource> get(
    core.String inventorySourceId, {
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/inventorySources/' + core.Uri.encodeFull('$inventorySourceId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return InventorySource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists inventory sources that are accessible to the current user.
  ///
  /// The order is defined by the order_by parameter. If a filter by
  /// entity_status is not specified, inventory sources with entity status
  /// `ENTITY_STATUS_ARCHIVED` will not be included in the results.
  ///
  /// Request parameters:
  ///
  /// [advertiserId] - The ID of the advertiser that has access to the inventory
  /// source.
  ///
  /// [filter] - Allows filtering by inventory source properties. Supported
  /// syntax: * Filter expressions are made up of one or more restrictions. *
  /// Restrictions can be combined by `AND` or `OR` logical operators. A
  /// sequence of restrictions implicitly uses `AND`. * A restriction has the
  /// form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`.
  /// * Supported fields: - `status.entityStatus` - `commitment` -
  /// `deliveryMethod` - `rateDetails.rateType` - `exchange` Examples: * All
  /// active inventory sources: `status.entityStatus="ENTITY_STATUS_ACTIVE"` *
  /// Inventory sources belonging to Google Ad Manager or Rubicon exchanges:
  /// `exchange="EXCHANGE_GOOGLE_AD_MANAGER" OR exchange="EXCHANGE_RUBICON"` The
  /// length of this field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `displayName` (default) The default sorting order is ascending. To specify
  /// descending order for a field, a suffix "desc" should be added to the field
  /// name. For example, `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListInventorySources` method. If not specified, the
  /// first page of results will be returned.
  ///
  /// [partnerId] - The ID of the partner that has access to the inventory
  /// source.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListInventorySourcesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListInventorySourcesResponse> list({
    core.String? advertiserId,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? partnerId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (partnerId != null) 'partnerId': [partnerId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/inventorySources';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListInventorySourcesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MediaResource {
  final commons.ApiRequester _requester;

  MediaResource(commons.ApiRequester client) : _requester = client;

  /// Downloads media.
  ///
  /// Download is supported on the URI `/download/{resource_name=**}?alt=media.`
  /// **Note**: Download requests will not be successful without including
  /// `alt=media` query string.
  ///
  /// Request parameters:
  ///
  /// [resourceName] - Name of the media that is being downloaded. See
  /// ReadRequest.resource_name.
  /// Value must have pattern `^.*$`.
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
  /// - [GoogleBytestreamMedia] for Metadata downloads (see [downloadOptions]).
  ///
  /// - [commons.Media] for Media downloads (see [downloadOptions]).
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<core.Object> download(
    core.String resourceName, {
    core.String? $fields,
    commons.DownloadOptions downloadOptions = commons.DownloadOptions.metadata,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'download/' + core.Uri.encodeFull('$resourceName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
      downloadOptions: downloadOptions,
    );
    if (downloadOptions.isMetadataDownload) {
      return GoogleBytestreamMedia.fromJson(
          _response as core.Map<core.String, core.dynamic>);
    } else {
      return _response as commons.Media;
    }
  }
}

class PartnersResource {
  final commons.ApiRequester _requester;

  PartnersChannelsResource get channels => PartnersChannelsResource(_requester);
  PartnersTargetingTypesResource get targetingTypes =>
      PartnersTargetingTypesResource(_requester);

  PartnersResource(commons.ApiRequester client) : _requester = client;

  /// Bulk edits targeting options under a single partner.
  ///
  /// The operation will delete the assigned targeting options provided in
  /// BulkEditPartnerAssignedTargetingOptionsRequest.deleteRequests and then
  /// create the assigned targeting options provided in
  /// BulkEditPartnerAssignedTargetingOptionsRequest.createRequests .
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - Required. The ID of the partner.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkEditPartnerAssignedTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkEditPartnerAssignedTargetingOptionsResponse>
      bulkEditPartnerAssignedTargetingOptions(
    BulkEditPartnerAssignedTargetingOptionsRequest request,
    core.String partnerId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' +
        core.Uri.encodeFull('$partnerId') +
        ':bulkEditPartnerAssignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BulkEditPartnerAssignedTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a partner.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - Required. The ID of the partner to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Partner].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Partner> get(
    core.String partnerId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' + core.Uri.encodeFull('$partnerId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Partner.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists partners that are accessible to the current user.
  ///
  /// The order is defined by the order_by parameter.
  ///
  /// Request parameters:
  ///
  /// [filter] - Allows filtering by partner properties. Supported syntax: *
  /// Filter expressions are made up of one or more restrictions. * Restrictions
  /// can be combined by `AND` or `OR` logical operators. A sequence of
  /// restrictions implicitly uses `AND`. * A restriction has the form of
  /// `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. *
  /// Supported fields: - `entityStatus` Examples: * All active partners:
  /// `entityStatus="ENTITY_STATUS_ACTIVE"` The length of this field should be
  /// no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `displayName` The default sorting order is ascending. To specify
  /// descending order for a field, a suffix "desc" should be added to the field
  /// name. For example, `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListPartners` method. If not specified, the first page
  /// of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListPartnersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListPartnersResponse> list({
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/partners';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListPartnersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PartnersChannelsResource {
  final commons.ApiRequester _requester;

  PartnersChannelsSitesResource get sites =>
      PartnersChannelsSitesResource(_requester);

  PartnersChannelsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new channel.
  ///
  /// Returns the newly created channel if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - The ID of the partner that owns the created channel.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that owns the created channel.
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
  async.Future<Channel> create(
    Channel request,
    core.String partnerId, {
    core.String? advertiserId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/partners/' + core.Uri.encodeFull('$partnerId') + '/channels';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Channel.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a channel for a partner or advertiser.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - The ID of the partner that owns the fetched channel.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [channelId] - Required. The ID of the channel to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that owns the fetched channel.
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
  async.Future<Channel> get(
    core.String partnerId,
    core.String channelId, {
    core.String? advertiserId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' +
        core.Uri.encodeFull('$partnerId') +
        '/channels/' +
        core.Uri.encodeFull('$channelId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Channel.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists channels for a partner or advertiser.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - The ID of the partner that owns the channels.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that owns the channels.
  ///
  /// [filter] - Allows filtering by channel fields. Supported syntax: * Filter
  /// expressions for channel currently can only contain at most one *
  /// restriction. * A restriction has the form of `{field} {operator} {value}`.
  /// * The operator must be `CONTAINS (:)`. * Supported fields: - `displayName`
  /// Examples: * All channels for which the display name contains "google":
  /// `displayName : "google"`. The length of this field should be no more than
  /// 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `displayName` (default) * `channelId` The default sorting order is
  /// ascending. To specify descending order for a field, a suffix " desc"
  /// should be added to the field name. Example: `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListChannels` method. If not specified, the first page
  /// of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListChannelsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListChannelsResponse> list(
    core.String partnerId, {
    core.String? advertiserId,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/partners/' + core.Uri.encodeFull('$partnerId') + '/channels';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListChannelsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a channel.
  ///
  /// Returns the updated channel if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - The ID of the partner that owns the created channel.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [channelId] - Output only. The unique ID of the channel. Assigned by the
  /// system.
  ///
  /// [advertiserId] - The ID of the advertiser that owns the created channel.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
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
  async.Future<Channel> patch(
    Channel request,
    core.String partnerId,
    core.String channelId, {
    core.String? advertiserId,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' +
        core.Uri.encodeFull('$partnerId') +
        '/channels/' +
        commons.escapeVariable('$channelId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Channel.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class PartnersChannelsSitesResource {
  final commons.ApiRequester _requester;

  PartnersChannelsSitesResource(commons.ApiRequester client)
      : _requester = client;

  /// Bulk edits sites under a single channel.
  ///
  /// The operation will delete the sites provided in
  /// BulkEditSitesRequest.deleted_sites and then create the sites provided in
  /// BulkEditSitesRequest.created_sites.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - The ID of the partner that owns the parent channel.
  ///
  /// [channelId] - Required. The ID of the parent channel to which the sites
  /// belong.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkEditSitesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkEditSitesResponse> bulkEdit(
    BulkEditSitesRequest request,
    core.String partnerId,
    core.String channelId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' +
        commons.escapeVariable('$partnerId') +
        '/channels/' +
        core.Uri.encodeFull('$channelId') +
        '/sites:bulkEdit';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BulkEditSitesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a site in a channel.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - The ID of the partner that owns the parent channel.
  ///
  /// [channelId] - Required. The ID of the parent channel in which the site
  /// will be created.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that owns the parent channel.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Site].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Site> create(
    Site request,
    core.String partnerId,
    core.String channelId, {
    core.String? advertiserId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' +
        commons.escapeVariable('$partnerId') +
        '/channels/' +
        core.Uri.encodeFull('$channelId') +
        '/sites';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Site.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a site from a channel.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - The ID of the partner that owns the parent channel.
  ///
  /// [channelId] - Required. The ID of the parent channel to which the site
  /// belongs.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [urlOrAppId] - Required. The URL or app ID of the site to delete.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that owns the parent channel.
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
    core.String partnerId,
    core.String channelId,
    core.String urlOrAppId, {
    core.String? advertiserId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' +
        commons.escapeVariable('$partnerId') +
        '/channels/' +
        core.Uri.encodeFull('$channelId') +
        '/sites/' +
        core.Uri.encodeFull('$urlOrAppId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists sites in a channel.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - The ID of the partner that owns the parent channel.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [channelId] - Required. The ID of the parent channel to which the
  /// requested sites belong.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - The ID of the advertiser that owns the parent channel.
  ///
  /// [filter] - Allows filtering by site fields. Supported syntax: * Filter
  /// expressions for site currently can only contain at most one * restriction.
  /// * A restriction has the form of `{field} {operator} {value}`. * The
  /// operator must be `CONTAINS (:)`. * Supported fields: - `urlOrAppId`
  /// Examples: * All sites for which the URL or app ID contains "google":
  /// `urlOrAppId : "google"`
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `urlOrAppId` (default) The default sorting order is ascending. To specify
  /// descending order for a field, a suffix " desc" should be added to the
  /// field name. Example: `urlOrAppId desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `10000`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListSites` method. If not specified, the first page of
  /// results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSitesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSitesResponse> list(
    core.String partnerId,
    core.String channelId, {
    core.String? advertiserId,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' +
        core.Uri.encodeFull('$partnerId') +
        '/channels/' +
        core.Uri.encodeFull('$channelId') +
        '/sites';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSitesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Replaces all of the sites under a single channel.
  ///
  /// The operation will replace the sites under a channel with the sites
  /// provided in ReplaceSitesRequest.new_sites.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - The ID of the partner that owns the parent channel.
  ///
  /// [channelId] - Required. The ID of the parent channel whose sites will be
  /// replaced.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReplaceSitesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReplaceSitesResponse> replace(
    ReplaceSitesRequest request,
    core.String partnerId,
    core.String channelId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' +
        commons.escapeVariable('$partnerId') +
        '/channels/' +
        core.Uri.encodeFull('$channelId') +
        '/sites:replace';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ReplaceSitesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PartnersTargetingTypesResource {
  final commons.ApiRequester _requester;

  PartnersTargetingTypesAssignedTargetingOptionsResource
      get assignedTargetingOptions =>
          PartnersTargetingTypesAssignedTargetingOptionsResource(_requester);

  PartnersTargetingTypesResource(commons.ApiRequester client)
      : _requester = client;
}

class PartnersTargetingTypesAssignedTargetingOptionsResource {
  final commons.ApiRequester _requester;

  PartnersTargetingTypesAssignedTargetingOptionsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Assigns a targeting option to a partner.
  ///
  /// Returns the assigned targeting option if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - Required. The ID of the partner.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of this assigned targeting
  /// option. Supported targeting types: * `TARGETING_TYPE_CHANNEL`
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AssignedTargetingOption].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AssignedTargetingOption> create(
    AssignedTargetingOption request,
    core.String partnerId,
    core.String targetingType, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' +
        core.Uri.encodeFull('$partnerId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AssignedTargetingOption.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an assigned targeting option from a partner.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - Required. The ID of the partner.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of this assigned targeting
  /// option. Supported targeting types: * `TARGETING_TYPE_CHANNEL`
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [assignedTargetingOptionId] - Required. The ID of the assigned targeting
  /// option to delete.
  /// Value must have pattern `^\[^/\]+$`.
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
    core.String partnerId,
    core.String targetingType,
    core.String assignedTargetingOptionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' +
        core.Uri.encodeFull('$partnerId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions/' +
        core.Uri.encodeFull('$assignedTargetingOptionId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a single targeting option assigned to a partner.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - Required. The ID of the partner.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of this assigned targeting
  /// option. Supported targeting types: * `TARGETING_TYPE_CHANNEL`
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [assignedTargetingOptionId] - Required. An identifier unique to the
  /// targeting type in this partner that identifies the assigned targeting
  /// option being requested.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AssignedTargetingOption].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AssignedTargetingOption> get(
    core.String partnerId,
    core.String targetingType,
    core.String assignedTargetingOptionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' +
        core.Uri.encodeFull('$partnerId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions/' +
        core.Uri.encodeFull('$assignedTargetingOptionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AssignedTargetingOption.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the targeting options assigned to a partner.
  ///
  /// Request parameters:
  ///
  /// [partnerId] - Required. The ID of the partner.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [targetingType] - Required. Identifies the type of assigned targeting
  /// options to list. Supported targeting types: * `TARGETING_TYPE_CHANNEL`
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [filter] - Allows filtering by assigned targeting option properties.
  /// Supported syntax: * Filter expressions are made up of one or more
  /// restrictions. * Restrictions can be combined by the logical operator `OR`.
  /// * A restriction has the form of `{field} {operator} {value}`. * The
  /// operator must be `EQUALS (=)`. * Supported fields: -
  /// `assignedTargetingOptionId` Examples: * AssignedTargetingOption with ID
  /// 123456 `assignedTargetingOptionId="123456"` The length of this field
  /// should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `assignedTargetingOptionId` (default) The default sorting order is
  /// ascending. To specify descending order for a field, a suffix "desc" should
  /// be added to the field name. Example: `assignedTargetingOptionId desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListPartnerAssignedTargetingOptions` method. If not
  /// specified, the first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListPartnerAssignedTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListPartnerAssignedTargetingOptionsResponse> list(
    core.String partnerId,
    core.String targetingType, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/partners/' +
        core.Uri.encodeFull('$partnerId') +
        '/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/assignedTargetingOptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListPartnerAssignedTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class SdfdownloadtasksResource {
  final commons.ApiRequester _requester;

  SdfdownloadtasksOperationsResource get operations =>
      SdfdownloadtasksOperationsResource(_requester);

  SdfdownloadtasksResource(commons.ApiRequester client) : _requester = client;

  /// Creates an SDF Download Task.
  ///
  /// Returns an Operation. An SDF Download Task is a long-running, asynchronous
  /// operation. The metadata type of this operation is SdfDownloadTaskMetadata.
  /// If the request is successful, the response type of the operation is
  /// SdfDownloadTask. The response will not include the download files, which
  /// must be retrieved with media.download. The state of operation can be
  /// retrieved with sdfdownloadtask.operations.get. Any errors can be found in
  /// the error.message. Note that error.details is expected to be empty.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> create(
    CreateSdfDownloadTaskRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/sdfdownloadtasks';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SdfdownloadtasksOperationsResource {
  final commons.ApiRequester _requester;

  SdfdownloadtasksOperationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the latest state of an asynchronous SDF download task operation.
  ///
  /// Clients should poll this method at intervals of 30 seconds.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern `^sdfdownloadtasks/operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> get(
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class TargetingTypesResource {
  final commons.ApiRequester _requester;

  TargetingTypesTargetingOptionsResource get targetingOptions =>
      TargetingTypesTargetingOptionsResource(_requester);

  TargetingTypesResource(commons.ApiRequester client) : _requester = client;
}

class TargetingTypesTargetingOptionsResource {
  final commons.ApiRequester _requester;

  TargetingTypesTargetingOptionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets a single targeting option.
  ///
  /// Request parameters:
  ///
  /// [targetingType] - Required. The type of targeting option to retrieve.
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [targetingOptionId] - Required. The ID of the of targeting option to
  /// retrieve.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [advertiserId] - Required. The Advertiser this request is being made in
  /// the context of.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TargetingOption].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TargetingOption> get(
    core.String targetingType,
    core.String targetingOptionId, {
    core.String? advertiserId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/targetingOptions/' +
        core.Uri.encodeFull('$targetingOptionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TargetingOption.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists targeting options of a given type.
  ///
  /// Request parameters:
  ///
  /// [targetingType] - Required. The type of targeting option to be listed.
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [advertiserId] - Required. The Advertiser this request is being made in
  /// the context of.
  ///
  /// [filter] - Allows filtering by targeting option properties. Supported
  /// syntax: * Filter expressions are made up of one or more restrictions. *
  /// Restrictions can be combined by `OR` logical operators. * A restriction
  /// has the form of `{field} {operator} {value}`. * The operator must be "="
  /// (equal sign). * Supported fields: - `carrierAndIspDetails.type` -
  /// `geoRegionDetails.geoRegionType` - `targetingOptionId` Examples: * All
  /// `GEO REGION` targeting options that belong to sub type
  /// `GEO_REGION_TYPE_COUNTRY` or `GEO_REGION_TYPE_STATE`:
  /// `geoRegionDetails.geoRegionType="GEO_REGION_TYPE_COUNTRY" OR
  /// geoRegionDetails.geoRegionType="GEO_REGION_TYPE_STATE"` * All `CARRIER AND
  /// ISP` targeting options that belong to sub type
  /// `CARRIER_AND_ISP_TYPE_CARRIER`:
  /// `carrierAndIspDetails.type="CARRIER_AND_ISP_TYPE_CARRIER"`. The length of
  /// this field should be no more than 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `targetingOptionId` (default) The default sorting order is ascending. To
  /// specify descending order for a field, a suffix "desc" should be added to
  /// the field name. Example: `targetingOptionId desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`. Returns error code `INVALID_ARGUMENT`
  /// if an invalid value is specified.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListTargetingOptions` method. If not specified, the
  /// first page of results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTargetingOptionsResponse> list(
    core.String targetingType, {
    core.String? advertiserId,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/targetingOptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Searches for targeting options of a given type based on the given search
  /// terms.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [targetingType] - Required. The type of targeting options to retrieve.
  /// Accepted values are: * `TARGETING_TYPE_GEO_REGION`
  /// Value must have pattern `^\[^/\]+$`.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchTargetingOptionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchTargetingOptionsResponse> search(
    SearchTargetingOptionsRequest request,
    core.String targetingType, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/targetingTypes/' +
        core.Uri.encodeFull('$targetingType') +
        '/targetingOptions:search';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SearchTargetingOptionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class UsersResource {
  final commons.ApiRequester _requester;

  UsersResource(commons.ApiRequester client) : _requester = client;

  /// Bulk edits user roles for a user.
  ///
  /// The operation will delete the assigned user roles provided in
  /// BulkEditAssignedUserRolesRequest.deletedAssignedUserRoles and then assign
  /// the user roles provided in
  /// BulkEditAssignedUserRolesRequest.createdAssignedUserRoles.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userId] - Required. The ID of the user to which the assigned user roles
  /// belong.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BulkEditAssignedUserRolesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BulkEditAssignedUserRolesResponse> bulkEditAssignedUserRoles(
    BulkEditAssignedUserRolesRequest request,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/users/' +
        core.Uri.encodeFull('$userId') +
        ':bulkEditAssignedUserRoles';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BulkEditAssignedUserRolesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new user.
  ///
  /// Returns the newly created user if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [User].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<User> create(
    User request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/users';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return User.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a user.
  ///
  /// Request parameters:
  ///
  /// [userId] - Required. The ID of the user to delete.
  /// Value must have pattern `^\[^/\]+$`.
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
    core.String userId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/users/' + core.Uri.encodeFull('$userId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a user.
  ///
  /// Request parameters:
  ///
  /// [userId] - Required. The ID of the user to fetch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [User].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<User> get(
    core.String userId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/users/' + core.Uri.encodeFull('$userId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return User.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists users that are accessible to the current user.
  ///
  /// If two users have user roles on the same partner or advertiser, they can
  /// access each other.
  ///
  /// Request parameters:
  ///
  /// [filter] - Allows filtering by user properties. Supported syntax: * Filter
  /// expressions are made up of one or more restrictions. * Restrictions can be
  /// combined by the logical operator `AND`. * A restriction has the form of
  /// `{field} {operator} {value}`. * The operator must be `CONTAINS (:)` or
  /// `EQUALS (=)`. * The operator must be `CONTAINS (:)` for the following
  /// fields: - `displayName` - `email` * The operator must be `EQUALS (=)` for
  /// the following fields: - `assignedUserRole.userRole` -
  /// `assignedUserRole.partnerId` - `assignedUserRole.advertiserId` -
  /// `assignedUserRole.entityType`: A synthetic field of AssignedUserRole used
  /// for filtering. Identifies the type of entity to which the user role is
  /// assigned. Valid values are `Partner` and `Advertiser`. -
  /// `assignedUserRole.parentPartnerId`: A synthetic field of AssignedUserRole
  /// used for filtering. Identifies the parent partner of the entity to which
  /// the user role is assigned." Examples: * The user with displayName
  /// containing `foo`: `displayName:"foo"` * The user with email containing
  /// `bar`: `email:"bar"` * All users with standard user roles:
  /// `assignedUserRole.userRole="STANDARD"` * All users with user roles for
  /// partner 123: `assignedUserRole.partnerId="123"` * All users with user
  /// roles for advertiser 123: `assignedUserRole.advertiserId="123"` * All
  /// users with partner level user roles: `entityType="PARTNER"` * All users
  /// with user roles for partner 123 and advertisers under partner 123:
  /// `parentPartnerId="123"` The length of this field should be no more than
  /// 500 characters.
  ///
  /// [orderBy] - Field by which to sort the list. Acceptable values are: *
  /// `displayName` (default) The default sorting order is ascending. To specify
  /// descending order for a field, a suffix "desc" should be added to the field
  /// name. For example, `displayName desc`.
  ///
  /// [pageSize] - Requested page size. Must be between `1` and `100`. If
  /// unspecified will default to `100`.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of next_page_token returned from the
  /// previous call to `ListUsers` method. If not specified, the first page of
  /// results will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListUsersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListUsersResponse> list({
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/users';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListUsersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing user.
  ///
  /// Returns the updated user if successful.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userId] - Output only. The unique ID of the user. Assigned by the system.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [updateMask] - Required. The mask to control which fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [User].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<User> patch(
    User request,
    core.String userId, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/users/' + core.Uri.encodeFull('$userId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return User.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// Request message for ManualTriggerService.ActivateManualTrigger.
class ActivateManualTriggerRequest {
  ActivateManualTriggerRequest();

  ActivateManualTriggerRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Configuration for custom Active View video viewability metrics.
class ActiveViewVideoViewabilityMetricConfig {
  /// The display name of the custom metric.
  ///
  /// Required.
  core.String? displayName;

  /// The minimum visible video duration required (in seconds) in order for an
  /// impression to be recorded.
  ///
  /// You must specify minimum_duration, minimum_quartile or both. If both are
  /// specified, an impression meets the metric criteria if either requirement
  /// is met (whichever happens first).
  /// Possible string values are:
  /// - "VIDEO_DURATION_UNSPECIFIED" : Value is not specified or is unknown in
  /// this version.
  /// - "VIDEO_DURATION_SECONDS_NONE" : No duration value.
  /// - "VIDEO_DURATION_SECONDS_0" : 0 seconds.
  /// - "VIDEO_DURATION_SECONDS_1" : 1 second.
  /// - "VIDEO_DURATION_SECONDS_2" : 2 seconds.
  /// - "VIDEO_DURATION_SECONDS_3" : 3 seconds.
  /// - "VIDEO_DURATION_SECONDS_4" : 4 seconds.
  /// - "VIDEO_DURATION_SECONDS_5" : 5 seconds.
  /// - "VIDEO_DURATION_SECONDS_6" : 6 seconds.
  /// - "VIDEO_DURATION_SECONDS_7" : 7 seconds.
  /// - "VIDEO_DURATION_SECONDS_8" : 8 seconds.
  /// - "VIDEO_DURATION_SECONDS_9" : 9 seconds.
  /// - "VIDEO_DURATION_SECONDS_10" : 10 seconds.
  /// - "VIDEO_DURATION_SECONDS_11" : 11 seconds.
  /// - "VIDEO_DURATION_SECONDS_12" : 12 seconds.
  /// - "VIDEO_DURATION_SECONDS_13" : 13 seconds.
  /// - "VIDEO_DURATION_SECONDS_14" : 14 seconds.
  /// - "VIDEO_DURATION_SECONDS_15" : 15 seconds.
  /// - "VIDEO_DURATION_SECONDS_30" : 30 seconds.
  /// - "VIDEO_DURATION_SECONDS_45" : 45 seconds.
  /// - "VIDEO_DURATION_SECONDS_60" : 60 seconds.
  core.String? minimumDuration;

  /// The minimum visible video duration required, based on the video quartiles,
  /// in order for an impression to be recorded.
  ///
  /// You must specify minimum_duration, minimum_quartile or both. If both are
  /// specified, an impression meets the metric criteria if either requirement
  /// is met (whichever happens first).
  /// Possible string values are:
  /// - "VIDEO_DURATION_QUARTILE_UNSPECIFIED" : Value is not specified or is
  /// unknown in this version.
  /// - "VIDEO_DURATION_QUARTILE_NONE" : No quartile value.
  /// - "VIDEO_DURATION_QUARTILE_FIRST" : First quartile.
  /// - "VIDEO_DURATION_QUARTILE_SECOND" : Second quartile (midpoint).
  /// - "VIDEO_DURATION_QUARTILE_THIRD" : Third quartile.
  /// - "VIDEO_DURATION_QUARTILE_FOURTH" : Fourth quartile (completion).
  core.String? minimumQuartile;

  /// The minimum percentage of the video ad's pixels visible on the screen in
  /// order for an impression to be recorded.
  ///
  /// Required.
  /// Possible string values are:
  /// - "VIEWABILITY_PERCENT_UNSPECIFIED" : Value is not specified or is unknown
  /// in this version.
  /// - "VIEWABILITY_PERCENT_0" : 0% viewable.
  /// - "VIEWABILITY_PERCENT_25" : 25% viewable.
  /// - "VIEWABILITY_PERCENT_50" : 50% viewable.
  /// - "VIEWABILITY_PERCENT_75" : 75% viewable.
  /// - "VIEWABILITY_PERCENT_100" : 100% viewable.
  core.String? minimumViewability;

  /// The minimum percentage of the video ad's volume required in order for an
  /// impression to be recorded.
  ///
  /// Required.
  /// Possible string values are:
  /// - "VIDEO_VOLUME_PERCENT_UNSPECIFIED" : Value is not specified or is
  /// unknown in this version.
  /// - "VIDEO_VOLUME_PERCENT_0" : 0% volume.
  /// - "VIDEO_VOLUME_PERCENT_10" : 10% volume.
  core.String? minimumVolume;

  ActiveViewVideoViewabilityMetricConfig();

  ActiveViewVideoViewabilityMetricConfig.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('minimumDuration')) {
      minimumDuration = _json['minimumDuration'] as core.String;
    }
    if (_json.containsKey('minimumQuartile')) {
      minimumQuartile = _json['minimumQuartile'] as core.String;
    }
    if (_json.containsKey('minimumViewability')) {
      minimumViewability = _json['minimumViewability'] as core.String;
    }
    if (_json.containsKey('minimumVolume')) {
      minimumVolume = _json['minimumVolume'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (minimumDuration != null) 'minimumDuration': minimumDuration!,
        if (minimumQuartile != null) 'minimumQuartile': minimumQuartile!,
        if (minimumViewability != null)
          'minimumViewability': minimumViewability!,
        if (minimumVolume != null) 'minimumVolume': minimumVolume!,
      };
}

/// Details of Adloox settings.
class Adloox {
  /// Adloox's brand safety settings.
  core.List<core.String>? excludedAdlooxCategories;

  Adloox();

  Adloox.fromJson(core.Map _json) {
    if (_json.containsKey('excludedAdlooxCategories')) {
      excludedAdlooxCategories =
          (_json['excludedAdlooxCategories'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (excludedAdlooxCategories != null)
          'excludedAdlooxCategories': excludedAdlooxCategories!,
      };
}

/// A single advertiser in Display & Video 360 (DV360).
class Advertiser {
  /// Ad server related settings of the advertiser.
  ///
  /// Required. Immutable.
  AdvertiserAdServerConfig? adServerConfig;

  /// The unique ID of the advertiser.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? advertiserId;

  /// Creative related settings of the advertiser.
  ///
  /// Required.
  AdvertiserCreativeConfig? creativeConfig;

  /// Settings that control how advertiser data may be accessed.
  AdvertiserDataAccessConfig? dataAccessConfig;

  /// The display name of the advertiser.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// Controls whether or not insertion orders and line items of the advertiser
  /// can spend their budgets and bid on inventory.
  ///
  /// * Accepted values are `ENTITY_STATUS_ACTIVE`, `ENTITY_STATUS_PAUSED` and
  /// `ENTITY_STATUS_SCHEDULED_FOR_DELETION`. * If set to
  /// `ENTITY_STATUS_SCHEDULED_FOR_DELETION`, the advertiser will be deleted 30
  /// days from when it was first scheduled for deletion.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ENTITY_STATUS_UNSPECIFIED" : Default value when status is not specified
  /// or is unknown in this version.
  /// - "ENTITY_STATUS_ACTIVE" : The entity is enabled to bid and spend budget.
  /// - "ENTITY_STATUS_ARCHIVED" : The entity is archived. Bidding and budget
  /// spending are disabled. An entity can be deleted after archived. Deleted
  /// entities cannot be retrieved.
  /// - "ENTITY_STATUS_DRAFT" : The entity is under draft. Bidding and budget
  /// spending are disabled.
  /// - "ENTITY_STATUS_PAUSED" : Bidding and budget spending are paused for the
  /// entity.
  /// - "ENTITY_STATUS_SCHEDULED_FOR_DELETION" : The entity is scheduled for
  /// deletion.
  core.String? entityStatus;

  /// General settings of the advertiser.
  ///
  /// Required.
  AdvertiserGeneralConfig? generalConfig;

  /// Integration details of the advertiser.
  ///
  /// Only integrationCode is currently applicable to advertiser. Other fields
  /// of IntegrationDetails are not supported and will be ignored if provided.
  IntegrationDetails? integrationDetails;

  /// The resource name of the advertiser.
  ///
  /// Output only.
  core.String? name;

  /// The unique ID of the partner that the advertiser belongs to.
  ///
  /// Required. Immutable.
  core.String? partnerId;

  /// Whether integration with Mediaocean (Prisma) is enabled.
  ///
  /// By enabling this: On behalf of my company, I authorize Mediaocean (Prisma)
  /// to send budget segment plans to Google, and I authorize Google to send
  /// corresponding reporting and invoices from DV360 to Mediaocean for the
  /// purposes of budget planning, billing, and reconciliation for this
  /// advertiser.
  core.bool? prismaEnabled;

  /// Targeting settings related to ad serving of the advertiser.
  AdvertiserTargetingConfig? servingConfig;

  /// The timestamp when the advertiser was last updated.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? updateTime;

  Advertiser();

  Advertiser.fromJson(core.Map _json) {
    if (_json.containsKey('adServerConfig')) {
      adServerConfig = AdvertiserAdServerConfig.fromJson(
          _json['adServerConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('creativeConfig')) {
      creativeConfig = AdvertiserCreativeConfig.fromJson(
          _json['creativeConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataAccessConfig')) {
      dataAccessConfig = AdvertiserDataAccessConfig.fromJson(
          _json['dataAccessConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('entityStatus')) {
      entityStatus = _json['entityStatus'] as core.String;
    }
    if (_json.containsKey('generalConfig')) {
      generalConfig = AdvertiserGeneralConfig.fromJson(
          _json['generalConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('integrationDetails')) {
      integrationDetails = IntegrationDetails.fromJson(
          _json['integrationDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('partnerId')) {
      partnerId = _json['partnerId'] as core.String;
    }
    if (_json.containsKey('prismaEnabled')) {
      prismaEnabled = _json['prismaEnabled'] as core.bool;
    }
    if (_json.containsKey('servingConfig')) {
      servingConfig = AdvertiserTargetingConfig.fromJson(
          _json['servingConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adServerConfig != null) 'adServerConfig': adServerConfig!.toJson(),
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (creativeConfig != null) 'creativeConfig': creativeConfig!.toJson(),
        if (dataAccessConfig != null)
          'dataAccessConfig': dataAccessConfig!.toJson(),
        if (displayName != null) 'displayName': displayName!,
        if (entityStatus != null) 'entityStatus': entityStatus!,
        if (generalConfig != null) 'generalConfig': generalConfig!.toJson(),
        if (integrationDetails != null)
          'integrationDetails': integrationDetails!.toJson(),
        if (name != null) 'name': name!,
        if (partnerId != null) 'partnerId': partnerId!,
        if (prismaEnabled != null) 'prismaEnabled': prismaEnabled!,
        if (servingConfig != null) 'servingConfig': servingConfig!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Ad server related settings of an advertiser.
class AdvertiserAdServerConfig {
  /// The configuration for advertisers that use both Campaign Manager 360
  /// (CM360) and third-party ad servers.
  CmHybridConfig? cmHybridConfig;

  /// The configuration for advertisers that use third-party ad servers only.
  ThirdPartyOnlyConfig? thirdPartyOnlyConfig;

  AdvertiserAdServerConfig();

  AdvertiserAdServerConfig.fromJson(core.Map _json) {
    if (_json.containsKey('cmHybridConfig')) {
      cmHybridConfig = CmHybridConfig.fromJson(
          _json['cmHybridConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('thirdPartyOnlyConfig')) {
      thirdPartyOnlyConfig = ThirdPartyOnlyConfig.fromJson(
          _json['thirdPartyOnlyConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cmHybridConfig != null) 'cmHybridConfig': cmHybridConfig!.toJson(),
        if (thirdPartyOnlyConfig != null)
          'thirdPartyOnlyConfig': thirdPartyOnlyConfig!.toJson(),
      };
}

/// Creatives related settings of an advertiser.
class AdvertiserCreativeConfig {
  /// Whether or not the advertiser is enabled for dynamic creatives.
  core.bool? dynamicCreativeEnabled;

  /// An ID for configuring campaign monitoring provided by Integral Ad Service
  /// (IAS).
  ///
  /// The DV360 system will append an IAS "Campaign Monitor" tag containing this
  /// ID to the creative tag.
  core.String? iasClientId;

  /// Whether or not to use DV360's Online Behavioral Advertising (OBA)
  /// compliance.
  ///
  /// Warning: Changing OBA settings may cause the audit status of your
  /// creatives to be reset by some ad exchanges, making them ineligible to
  /// serve until they are re-approved.
  core.bool? obaComplianceDisabled;

  /// By setting this field to `true`, you, on behalf of your company, authorize
  /// Google to use video creatives associated with this Display & Video 360
  /// advertiser to provide reporting and features related to the advertiser's
  /// television campaigns.
  ///
  /// Applicable only when the advertiser has a CM360 hybrid ad server
  /// configuration.
  core.bool? videoCreativeDataSharingAuthorized;

  AdvertiserCreativeConfig();

  AdvertiserCreativeConfig.fromJson(core.Map _json) {
    if (_json.containsKey('dynamicCreativeEnabled')) {
      dynamicCreativeEnabled = _json['dynamicCreativeEnabled'] as core.bool;
    }
    if (_json.containsKey('iasClientId')) {
      iasClientId = _json['iasClientId'] as core.String;
    }
    if (_json.containsKey('obaComplianceDisabled')) {
      obaComplianceDisabled = _json['obaComplianceDisabled'] as core.bool;
    }
    if (_json.containsKey('videoCreativeDataSharingAuthorized')) {
      videoCreativeDataSharingAuthorized =
          _json['videoCreativeDataSharingAuthorized'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dynamicCreativeEnabled != null)
          'dynamicCreativeEnabled': dynamicCreativeEnabled!,
        if (iasClientId != null) 'iasClientId': iasClientId!,
        if (obaComplianceDisabled != null)
          'obaComplianceDisabled': obaComplianceDisabled!,
        if (videoCreativeDataSharingAuthorized != null)
          'videoCreativeDataSharingAuthorized':
              videoCreativeDataSharingAuthorized!,
      };
}

/// Settings that control how advertiser related data may be accessed.
class AdvertiserDataAccessConfig {
  /// Structured Data Files (SDF) settings for the advertiser.
  ///
  /// If not specified, the SDF settings of the parent partner are used.
  AdvertiserSdfConfig? sdfConfig;

  AdvertiserDataAccessConfig();

  AdvertiserDataAccessConfig.fromJson(core.Map _json) {
    if (_json.containsKey('sdfConfig')) {
      sdfConfig = AdvertiserSdfConfig.fromJson(
          _json['sdfConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sdfConfig != null) 'sdfConfig': sdfConfig!.toJson(),
      };
}

/// General settings of an advertiser.
class AdvertiserGeneralConfig {
  /// Advertiser's currency in ISO 4217 format.
  ///
  /// Accepted codes and the currencies they represent are: Currency Code :
  /// Currency Name * `ARS` : Argentine Peso * `AUD` : Australian Dollar * `BRL`
  /// : Brazilian Real * `CAD` : Canadian Dollar * `CHF` : Swiss Franc * `CLP` :
  /// Chilean Peso * `CNY` : Chinese Yuan * `COP` : Colombian Peso * `CZK` :
  /// Czech Koruna * `DKK` : Danish Krone * `EGP` : Egyption Pound * `EUR` :
  /// Euro * `GBP` : British Pound * `HKD` : Hong Kong Dollar * `HUF` :
  /// Hungarian Forint * `IDR` : Indonesian Rupiah * `ILS` : Israeli Shekel *
  /// `INR` : Indian Rupee * `JPY` : Japanese Yen * `KRW` : South Korean Won *
  /// `MXN` : Mexican Pesos * `MYR` : Malaysian Ringgit * `NGN` : Nigerian Naira
  /// * `NOK` : Norwegian Krone * `NZD` : New Zealand Dollar * `PEN` : Peruvian
  /// Nuevo Sol * `PLN` : Polish Zloty * `RON` : New Romanian Leu * `RUB` :
  /// Russian Ruble * `SEK` : Swedish Krona * `TRY` : Turkish Lira * `TWD` : New
  /// Taiwan Dollar * `USD` : US Dollar * `ZAR` : South African Rand
  ///
  /// Required. Immutable.
  core.String? currencyCode;

  /// The domain URL of the advertiser's primary website.
  ///
  /// The system will send this information to publishers that require website
  /// URL to associate a campaign with an advertiser. Provide a URL with no path
  /// or query string, beginning with `http:` or `https:`. For example,
  /// http://www.example.com
  ///
  /// Required.
  core.String? domainUrl;

  /// The standard TZ database name of the advertiser's time zone.
  ///
  /// For example, `America/New_York`. See more at:
  /// https://en.wikipedia.org/wiki/List_of_tz_database_time_zones For CM360
  /// hybrid advertisers, the time zone is the same as that of the associated
  /// CM360 account; for third-party only advertisers, the time zone is the same
  /// as that of the parent partner.
  ///
  /// Output only.
  core.String? timeZone;

  AdvertiserGeneralConfig();

  AdvertiserGeneralConfig.fromJson(core.Map _json) {
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('domainUrl')) {
      domainUrl = _json['domainUrl'] as core.String;
    }
    if (_json.containsKey('timeZone')) {
      timeZone = _json['timeZone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (domainUrl != null) 'domainUrl': domainUrl!,
        if (timeZone != null) 'timeZone': timeZone!,
      };
}

/// Structured Data Files (SDF) settings of an advertiser.
class AdvertiserSdfConfig {
  /// Whether or not this advertiser overrides the SDF configuration of its
  /// parent partner.
  ///
  /// By default, an advertiser inherits the SDF configuration from the parent
  /// partner. To override the partner configuration, set this field to `true`
  /// and provide the new configuration in sdfConfig.
  core.bool? overridePartnerSdfConfig;

  /// The SDF configuration for the advertiser.
  ///
  /// * Required when overridePartnerSdfConfig is `true`. * Output only when
  /// overridePartnerSdfConfig is `false`.
  SdfConfig? sdfConfig;

  AdvertiserSdfConfig();

  AdvertiserSdfConfig.fromJson(core.Map _json) {
    if (_json.containsKey('overridePartnerSdfConfig')) {
      overridePartnerSdfConfig = _json['overridePartnerSdfConfig'] as core.bool;
    }
    if (_json.containsKey('sdfConfig')) {
      sdfConfig = SdfConfig.fromJson(
          _json['sdfConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (overridePartnerSdfConfig != null)
          'overridePartnerSdfConfig': overridePartnerSdfConfig!,
        if (sdfConfig != null) 'sdfConfig': sdfConfig!.toJson(),
      };
}

/// Targeting settings related to ad serving of an advertiser.
class AdvertiserTargetingConfig {
  /// Whether or not connected TV devices are exempt from viewability targeting
  /// for all video line items under the advertiser.
  core.bool? exemptTvFromViewabilityTargeting;

  AdvertiserTargetingConfig();

  AdvertiserTargetingConfig.fromJson(core.Map _json) {
    if (_json.containsKey('exemptTvFromViewabilityTargeting')) {
      exemptTvFromViewabilityTargeting =
          _json['exemptTvFromViewabilityTargeting'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exemptTvFromViewabilityTargeting != null)
          'exemptTvFromViewabilityTargeting': exemptTvFromViewabilityTargeting!,
      };
}

/// Represents a targetable age range.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_AGE_RANGE`.
class AgeRangeAssignedTargetingOptionDetails {
  /// The age range of an audience.
  ///
  /// We only support targeting a continuous age range of an audience. Thus, the
  /// age range represented in this field can be 1) targeted solely, or, 2) part
  /// of a larger continuous age range. The reach of a continuous age range
  /// targeting can be expanded by also targeting an audience of an unknown age.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "AGE_RANGE_UNSPECIFIED" : Default value when age range is not specified
  /// in this version. This enum is a placeholder for default value and does not
  /// represent a real age range option.
  /// - "AGE_RANGE_18_24" : The age range of the audience is 18 to 24.
  /// - "AGE_RANGE_25_34" : The age range of the audience is 25 to 34.
  /// - "AGE_RANGE_35_44" : The age range of the audience is 35 to 44.
  /// - "AGE_RANGE_45_54" : The age range of the audience is 45 to 54.
  /// - "AGE_RANGE_55_64" : The age range of the audience is 55 to 64.
  /// - "AGE_RANGE_65_PLUS" : The age range of the audience is 65 and up.
  /// - "AGE_RANGE_UNKNOWN" : The age range of the audience is unknown.
  core.String? ageRange;

  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_AGE_RANGE`.
  ///
  /// Required.
  core.String? targetingOptionId;

  AgeRangeAssignedTargetingOptionDetails();

  AgeRangeAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('ageRange')) {
      ageRange = _json['ageRange'] as core.String;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ageRange != null) 'ageRange': ageRange!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable age range.
///
/// This will be populated in the age_range_details field when targeting_type is
/// `TARGETING_TYPE_AGE_RANGE`.
class AgeRangeTargetingOptionDetails {
  /// The age range of an audience.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "AGE_RANGE_UNSPECIFIED" : Default value when age range is not specified
  /// in this version. This enum is a placeholder for default value and does not
  /// represent a real age range option.
  /// - "AGE_RANGE_18_24" : The age range of the audience is 18 to 24.
  /// - "AGE_RANGE_25_34" : The age range of the audience is 25 to 34.
  /// - "AGE_RANGE_35_44" : The age range of the audience is 35 to 44.
  /// - "AGE_RANGE_45_54" : The age range of the audience is 45 to 54.
  /// - "AGE_RANGE_55_64" : The age range of the audience is 55 to 64.
  /// - "AGE_RANGE_65_PLUS" : The age range of the audience is 65 and up.
  /// - "AGE_RANGE_UNKNOWN" : The age range of the audience is unknown.
  core.String? ageRange;

  AgeRangeTargetingOptionDetails();

  AgeRangeTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('ageRange')) {
      ageRange = _json['ageRange'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ageRange != null) 'ageRange': ageRange!,
      };
}

/// Details for assigned app targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_APP`.
class AppAssignedTargetingOptionDetails {
  /// The ID of the app.
  ///
  /// Android's Play store app uses bundle ID, for example
  /// `com.google.android.gm`. Apple's App store app ID uses 9 digit string, for
  /// example `422689480`.
  ///
  /// Required.
  core.String? appId;

  /// Indicates the platform of the targeted app.
  ///
  /// If this field is not specified, the app platform will be assumed to be
  /// mobile (i.e., Android or iOS), and we will derive the appropriate mobile
  /// platform from the app ID.
  /// Possible string values are:
  /// - "APP_PLATFORM_UNSPECIFIED" : Default value when app platform is not
  /// specified in this version. This enum is a placeholder for default value
  /// and does not represent a real platform option.
  /// - "APP_PLATFORM_IOS" : The app platform is iOS.
  /// - "APP_PLATFORM_ANDROID" : The app platform is Android.
  /// - "APP_PLATFORM_ROKU" : The app platform is Roku.
  /// - "APP_PLATFORM_AMAZON_FIRETV" : The app platform is Amazon FireTV.
  /// - "APP_PLATFORM_PLAYSTATION" : The app platform is Playstation.
  /// - "APP_PLATFORM_APPLE_TV" : The app platform is Apple TV.
  /// - "APP_PLATFORM_XBOX" : The app platform is Xbox.
  /// - "APP_PLATFORM_SAMSUNG_TV" : The app platform is Samsung TV.
  /// - "APP_PLATFORM_ANDROID_TV" : The app platform is Android TV.
  /// - "APP_PLATFORM_GENERIC_CTV" : The app platform is a CTV platform that is
  /// not explicitly listed elsewhere.
  core.String? appPlatform;

  /// The display name of the app.
  ///
  /// Output only.
  core.String? displayName;

  /// Indicates if this option is being negatively targeted.
  core.bool? negative;

  AppAssignedTargetingOptionDetails();

  AppAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('appId')) {
      appId = _json['appId'] as core.String;
    }
    if (_json.containsKey('appPlatform')) {
      appPlatform = _json['appPlatform'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appId != null) 'appId': appId!,
        if (appPlatform != null) 'appPlatform': appPlatform!,
        if (displayName != null) 'displayName': displayName!,
        if (negative != null) 'negative': negative!,
      };
}

/// Details for assigned app category targeting option.
///
/// This will be populated in the app_category_details field of an
/// AssignedTargetingOption when targeting_type is
/// `TARGETING_TYPE_APP_CATEGORY`.
class AppCategoryAssignedTargetingOptionDetails {
  /// The display name of the app category.
  ///
  /// Output only.
  core.String? displayName;

  /// Indicates if this option is being negatively targeted.
  core.bool? negative;

  /// The targeting_option_id field when targeting_type is
  /// `TARGETING_TYPE_APP_CATEGORY`.
  ///
  /// Required.
  core.String? targetingOptionId;

  AppCategoryAssignedTargetingOptionDetails();

  AppCategoryAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (negative != null) 'negative': negative!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable collection of apps.
///
/// A collection lets you target dynamic groups of related apps that are
/// maintained by the platform, for example `All Apps/Google Play/Games`. This
/// will be populated in the app_category_details field when targeting_type is
/// `TARGETING_TYPE_APP_CATEGORY`.
class AppCategoryTargetingOptionDetails {
  /// The name of the app collection.
  ///
  /// Output only.
  core.String? displayName;

  AppCategoryTargetingOptionDetails();

  AppCategoryTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
      };
}

/// A single asset.
class Asset {
  /// The asset content.
  ///
  /// For uploaded assets, the content is the serving path.
  core.String? content;

  /// Media ID of the uploaded asset.
  ///
  /// This is a unique identifier for the asset. This ID can be passed to other
  /// API calls, e.g. CreateCreative to associate the asset with a creative.
  core.String? mediaId;

  Asset();

  Asset.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('mediaId')) {
      mediaId = _json['mediaId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (mediaId != null) 'mediaId': mediaId!,
      };
}

/// Asset association for the creative.
class AssetAssociation {
  /// The associated asset.
  Asset? asset;

  /// The role of this asset for the creative.
  /// Possible string values are:
  /// - "ASSET_ROLE_UNSPECIFIED" : Asset role is not specified or is unknown in
  /// this version.
  /// - "ASSET_ROLE_MAIN" : The asset is the main asset of the creative.
  /// - "ASSET_ROLE_BACKUP" : The asset is a backup asset of the creative.
  /// - "ASSET_ROLE_POLITE_LOAD" : The asset is a polite load asset of the
  /// creative.
  /// - "ASSET_ROLE_HEADLINE" : Headline of a native creative. The content must
  /// be UTF-8 encoded with a length of no more than 25 characters. This role is
  /// only supported in following creative_type: * `CREATIVE_TYPE_NATIVE` *
  /// `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  /// - "ASSET_ROLE_LONG_HEADLINE" : Long headline of a native creative. The
  /// content must be UTF-8 encoded with a length of no more than 50 characters.
  /// This role is only supported in following creative_type: *
  /// `CREATIVE_TYPE_NATIVE` * `CREATIVE_TYPE_NATIVE_SITE_SQUARE` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  /// - "ASSET_ROLE_BODY" : Body text of a native creative. The content must be
  /// UTF-8 encoded with a length of no more than 90 characters. This role is
  /// only supported in following creative_type: * `CREATIVE_TYPE_NATIVE` *
  /// `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  /// - "ASSET_ROLE_LONG_BODY" : Long body text of a native creative. The
  /// content must be UTF-8 encoded with a length of no more than 150
  /// characters. This role is only supported in following creative_type: *
  /// `CREATIVE_TYPE_NATIVE` * `CREATIVE_TYPE_NATIVE_SITE_SQUARE` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  /// - "ASSET_ROLE_CAPTION_URL" : A short, friendly version of the landing page
  /// URL to show in the creative. This URL gives people an idea of where
  /// they'll arrive after they click on the creative. The content must be UTF-8
  /// encoded with a length of no more than 30 characters. For example, if the
  /// landing page URL is 'http://www.example.com/page', the caption URL can be
  /// 'example.com'. The protocol (http://) is optional, but the URL can't
  /// contain spaces or special characters. This role is only supported in
  /// following creative_type: * `CREATIVE_TYPE_NATIVE` *
  /// `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  /// - "ASSET_ROLE_CALL_TO_ACTION" : The text to use on the call-to-action
  /// button of a native creative. The content must be UTF-8 encoded with a
  /// length of no more than 15 characters. This role is only supported in
  /// following creative_type: * `CREATIVE_TYPE_NATIVE` *
  /// `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  /// - "ASSET_ROLE_ADVERTISER_NAME" : The text that identifies the advertiser
  /// or brand name. The content must be UTF-8 encoded with a length of no more
  /// than 25 characters. This role is only supported in following
  /// creative_type: * `CREATIVE_TYPE_NATIVE` *
  /// `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  /// - "ASSET_ROLE_PRICE" : The purchase price of your app in the Google play
  /// store or iOS app store (for example, $5.99). Note that this value is not
  /// automatically synced with the actual value listed in the store. It will
  /// always be the one provided when save the creative. The content must be
  /// UTF-8 encoded with a length of no more than 15 characters. This role is
  /// only supported in following creative_type: *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE`
  /// - "ASSET_ROLE_ANDROID_APP_ID" : The ID of an Android app in the Google
  /// play store. You can find this ID in the App’s Google Play Store URL after
  /// ‘id’. For example, in
  /// https://play.google.com/store/apps/details?id=com.company.appname the
  /// identifier is com.company.appname. This role is only supported in
  /// following creative_type: * `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE`
  /// - "ASSET_ROLE_IOS_APP_ID" : The ID of an iOS app in the Apple app store.
  /// This ID number can be found in the Apple App Store URL as the string of
  /// numbers directly after "id". For example, in
  /// https://apps.apple.com/us/app/gmail-email-by-google/id422689480 the ID is
  /// 422689480. This role is only supported in following creative_type: *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE`
  /// - "ASSET_ROLE_RATING" : The rating of an app in the Google play store or
  /// iOS app store. Note that this value is not automatically synced with the
  /// actual rating in the store. It will always be the one provided when save
  /// the creative. This role is only supported in following creative_type: *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE`
  /// - "ASSET_ROLE_ICON" : The icon of a creative. This role is only supported
  /// and required in following creative_type: * `CREATIVE_TYPE_NATIVE` *
  /// `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE`
  /// - "ASSET_ROLE_COVER_IMAGE" : The cover image of a native video creative.
  /// This role is only supported and required in following creative_type: *
  /// `CREATIVE_TYPE_VIDEO`
  core.String? role;

  AssetAssociation();

  AssetAssociation.fromJson(core.Map _json) {
    if (_json.containsKey('asset')) {
      asset =
          Asset.fromJson(_json['asset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (asset != null) 'asset': asset!.toJson(),
        if (role != null) 'role': role!,
      };
}

/// An assignment between a targetable inventory source and an inventory source
/// group.
class AssignedInventorySource {
  /// The unique ID of the assigned inventory source.
  ///
  /// The ID is only unique within a given inventory source group. It may be
  /// reused in other contexts.
  ///
  /// Output only.
  core.String? assignedInventorySourceId;

  /// The ID of the inventory source entity being targeted.
  ///
  /// Required.
  core.String? inventorySourceId;

  /// The resource name of the assigned inventory source.
  ///
  /// Output only.
  core.String? name;

  AssignedInventorySource();

  AssignedInventorySource.fromJson(core.Map _json) {
    if (_json.containsKey('assignedInventorySourceId')) {
      assignedInventorySourceId =
          _json['assignedInventorySourceId'] as core.String;
    }
    if (_json.containsKey('inventorySourceId')) {
      inventorySourceId = _json['inventorySourceId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedInventorySourceId != null)
          'assignedInventorySourceId': assignedInventorySourceId!,
        if (inventorySourceId != null) 'inventorySourceId': inventorySourceId!,
        if (name != null) 'name': name!,
      };
}

/// An assignment between a location list and a relevant targeting option.
///
/// Currently, geo region targeting options are the only supported option for
/// assignment.
class AssignedLocation {
  /// The unique ID of the assigned location.
  ///
  /// The ID is only unique within a location list. It may be reused in other
  /// contexts.
  ///
  /// Output only.
  core.String? assignedLocationId;

  /// The resource name of the assigned location.
  ///
  /// Output only.
  core.String? name;

  /// The ID of the targeting option assigned to the location list.
  ///
  /// Must be of type TARGETING_TYPE_GEO_REGION.
  ///
  /// Required.
  core.String? targetingOptionId;

  AssignedLocation();

  AssignedLocation.fromJson(core.Map _json) {
    if (_json.containsKey('assignedLocationId')) {
      assignedLocationId = _json['assignedLocationId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedLocationId != null)
          'assignedLocationId': assignedLocationId!,
        if (name != null) 'name': name!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// A single assigned targeting option, which defines the state of a targeting
/// option for an entity with targeting settings.
class AssignedTargetingOption {
  /// Age range details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_AGE_RANGE`.
  AgeRangeAssignedTargetingOptionDetails? ageRangeDetails;

  /// App category details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_APP_CATEGORY`.
  AppCategoryAssignedTargetingOptionDetails? appCategoryDetails;

  /// App details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_APP`.
  AppAssignedTargetingOptionDetails? appDetails;

  /// The unique ID of the assigned targeting option.
  ///
  /// The ID is only unique within a given resource and targeting type. It may
  /// be reused in other contexts.
  ///
  /// Output only.
  core.String? assignedTargetingOptionId;

  /// Audience targeting details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_AUDIENCE_GROUP`. You can only target one audience group
  /// option per resource.
  AudienceGroupAssignedTargetingOptionDetails? audienceGroupDetails;

  /// Authorized seller status details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_AUTHORIZED_SELLER_STATUS`. You can only target one
  /// authorized seller status option per resource. If a resource doesn't have
  /// an authorized seller status option, all authorized sellers indicated as
  /// DIRECT or RESELLER in the ads.txt file are targeted by default.
  AuthorizedSellerStatusAssignedTargetingOptionDetails?
      authorizedSellerStatusDetails;

  /// Browser details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_BROWSER`.
  BrowserAssignedTargetingOptionDetails? browserDetails;

  /// Carrier and ISP details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_CARRIER_AND_ISP`.
  CarrierAndIspAssignedTargetingOptionDetails? carrierAndIspDetails;

  /// Category details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_CATEGORY`. Targeting a category will also target its
  /// subcategories. If a category is excluded from targeting and a subcategory
  /// is included, the exclusion will take precedence.
  CategoryAssignedTargetingOptionDetails? categoryDetails;

  /// Channel details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_CHANNEL`.
  ChannelAssignedTargetingOptionDetails? channelDetails;

  /// Content instream position details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_CONTENT_INSTREAM_POSITION`.
  ContentInstreamPositionAssignedTargetingOptionDetails?
      contentInstreamPositionDetails;

  /// Content outstream position details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION`.
  ContentOutstreamPositionAssignedTargetingOptionDetails?
      contentOutstreamPositionDetails;

  /// Day and time details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_DAY_AND_TIME`.
  DayAndTimeAssignedTargetingOptionDetails? dayAndTimeDetails;

  /// Device make and model details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_DEVICE_MAKE_MODEL`.
  DeviceMakeModelAssignedTargetingOptionDetails? deviceMakeModelDetails;

  /// Device Type details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_DEVICE_TYPE`.
  DeviceTypeAssignedTargetingOptionDetails? deviceTypeDetails;

  /// Digital content label details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION`. Digital content labels
  /// are targeting exclusions. Advertiser level digital content label
  /// exclusions, if set, are always applied in serving (even though they aren't
  /// visible in resource settings). Resource settings can exclude content
  /// labels in addition to advertiser exclusions, but can't override them. A
  /// line item won't serve if all the digital content labels are excluded.
  DigitalContentLabelAssignedTargetingOptionDetails?
      digitalContentLabelExclusionDetails;

  /// Environment details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_ENVIRONMENT`.
  EnvironmentAssignedTargetingOptionDetails? environmentDetails;

  /// Exchange details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_EXCHANGE`.
  ExchangeAssignedTargetingOptionDetails? exchangeDetails;

  /// Gender details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_GENDER`.
  GenderAssignedTargetingOptionDetails? genderDetails;

  /// Geographic region details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_GEO_REGION`.
  GeoRegionAssignedTargetingOptionDetails? geoRegionDetails;

  /// Household income details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_HOUSEHOLD_INCOME`.
  HouseholdIncomeAssignedTargetingOptionDetails? householdIncomeDetails;

  /// The inheritance status of the assigned targeting option.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "INHERITANCE_UNSPECIFIED" : The inheritance is unspecified or unknown.
  /// - "NOT_INHERITED" : The assigned targeting option is not inherited from
  /// higher level entity.
  /// - "INHERITED_FROM_PARTNER" : The assigned targeting option is inherited
  /// from partner targeting settings.
  /// - "INHERITED_FROM_ADVERTISER" : The assigned targeting option is inherited
  /// from advertiser targeting settings.
  core.String? inheritance;

  /// Inventory source details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_INVENTORY_SOURCE`.
  InventorySourceAssignedTargetingOptionDetails? inventorySourceDetails;

  /// Inventory source group details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_INVENTORY_SOURCE_GROUP`.
  InventorySourceGroupAssignedTargetingOptionDetails?
      inventorySourceGroupDetails;

  /// Keyword details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_KEYWORD`. A maximum of 5000 direct negative keywords can
  /// be assigned to a resource. No limit on number of positive keywords that
  /// can be assigned.
  KeywordAssignedTargetingOptionDetails? keywordDetails;

  /// Language details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_LANGUAGE`.
  LanguageAssignedTargetingOptionDetails? languageDetails;

  /// The resource name for this assigned targeting option.
  ///
  /// Output only.
  core.String? name;

  /// Native content position details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_NATIVE_CONTENT_POSITION`.
  NativeContentPositionAssignedTargetingOptionDetails?
      nativeContentPositionDetails;

  /// Keyword details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_NEGATIVE_KEYWORD_LIST`. A maximum of 4 negative keyword
  /// lists can be assigned to a resource.
  NegativeKeywordListAssignedTargetingOptionDetails? negativeKeywordListDetails;

  /// On screen position details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_ON_SCREEN_POSITION`.
  OnScreenPositionAssignedTargetingOptionDetails? onScreenPositionDetails;

  /// Operating system details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_OPERATING_SYSTEM`.
  OperatingSystemAssignedTargetingOptionDetails? operatingSystemDetails;

  /// Parental status details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_PARENTAL_STATUS`.
  ParentalStatusAssignedTargetingOptionDetails? parentalStatusDetails;

  /// Proximity location list details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_PROXIMITY_LOCATION_LIST`.
  ProximityLocationListAssignedTargetingOptionDetails?
      proximityLocationListDetails;

  /// Regional location list details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_REGIONAL_LOCATION_LIST`.
  RegionalLocationListAssignedTargetingOptionDetails?
      regionalLocationListDetails;

  /// Sensitive category details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`. Sensitive categories are
  /// targeting exclusions. Advertiser level sensitive category exclusions, if
  /// set, are always applied in serving (even though they aren't visible in
  /// resource settings). Resource settings can exclude sensitive categories in
  /// addition to advertiser exclusions, but can't override them.
  SensitiveCategoryAssignedTargetingOptionDetails?
      sensitiveCategoryExclusionDetails;

  /// Sub-exchange details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_SUB_EXCHANGE`.
  SubExchangeAssignedTargetingOptionDetails? subExchangeDetails;

  /// Identifies the type of this assigned targeting option.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  core.String? targetingType;

  /// Third party verification details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_THIRD_PARTY_VERIFIER`.
  ThirdPartyVerifierAssignedTargetingOptionDetails? thirdPartyVerifierDetails;

  /// URL details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_URL`.
  UrlAssignedTargetingOptionDetails? urlDetails;

  /// User rewarded content details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_USER_REWARDED_CONTENT`.
  UserRewardedContentAssignedTargetingOptionDetails? userRewardedContentDetails;

  /// Video player size details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_VIDEO_PLAYER_SIZE`.
  VideoPlayerSizeAssignedTargetingOptionDetails? videoPlayerSizeDetails;

  /// Viewability details.
  ///
  /// This field will be populated when the targeting_type is
  /// `TARGETING_TYPE_VIEWABILITY`. You can only target one viewability option
  /// per resource.
  ViewabilityAssignedTargetingOptionDetails? viewabilityDetails;

  AssignedTargetingOption();

  AssignedTargetingOption.fromJson(core.Map _json) {
    if (_json.containsKey('ageRangeDetails')) {
      ageRangeDetails = AgeRangeAssignedTargetingOptionDetails.fromJson(
          _json['ageRangeDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('appCategoryDetails')) {
      appCategoryDetails = AppCategoryAssignedTargetingOptionDetails.fromJson(
          _json['appCategoryDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('appDetails')) {
      appDetails = AppAssignedTargetingOptionDetails.fromJson(
          _json['appDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('assignedTargetingOptionId')) {
      assignedTargetingOptionId =
          _json['assignedTargetingOptionId'] as core.String;
    }
    if (_json.containsKey('audienceGroupDetails')) {
      audienceGroupDetails =
          AudienceGroupAssignedTargetingOptionDetails.fromJson(
              _json['audienceGroupDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('authorizedSellerStatusDetails')) {
      authorizedSellerStatusDetails =
          AuthorizedSellerStatusAssignedTargetingOptionDetails.fromJson(
              _json['authorizedSellerStatusDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('browserDetails')) {
      browserDetails = BrowserAssignedTargetingOptionDetails.fromJson(
          _json['browserDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('carrierAndIspDetails')) {
      carrierAndIspDetails =
          CarrierAndIspAssignedTargetingOptionDetails.fromJson(
              _json['carrierAndIspDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('categoryDetails')) {
      categoryDetails = CategoryAssignedTargetingOptionDetails.fromJson(
          _json['categoryDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('channelDetails')) {
      channelDetails = ChannelAssignedTargetingOptionDetails.fromJson(
          _json['channelDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentInstreamPositionDetails')) {
      contentInstreamPositionDetails =
          ContentInstreamPositionAssignedTargetingOptionDetails.fromJson(
              _json['contentInstreamPositionDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentOutstreamPositionDetails')) {
      contentOutstreamPositionDetails =
          ContentOutstreamPositionAssignedTargetingOptionDetails.fromJson(
              _json['contentOutstreamPositionDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dayAndTimeDetails')) {
      dayAndTimeDetails = DayAndTimeAssignedTargetingOptionDetails.fromJson(
          _json['dayAndTimeDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deviceMakeModelDetails')) {
      deviceMakeModelDetails =
          DeviceMakeModelAssignedTargetingOptionDetails.fromJson(
              _json['deviceMakeModelDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deviceTypeDetails')) {
      deviceTypeDetails = DeviceTypeAssignedTargetingOptionDetails.fromJson(
          _json['deviceTypeDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('digitalContentLabelExclusionDetails')) {
      digitalContentLabelExclusionDetails =
          DigitalContentLabelAssignedTargetingOptionDetails.fromJson(
              _json['digitalContentLabelExclusionDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('environmentDetails')) {
      environmentDetails = EnvironmentAssignedTargetingOptionDetails.fromJson(
          _json['environmentDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('exchangeDetails')) {
      exchangeDetails = ExchangeAssignedTargetingOptionDetails.fromJson(
          _json['exchangeDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('genderDetails')) {
      genderDetails = GenderAssignedTargetingOptionDetails.fromJson(
          _json['genderDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('geoRegionDetails')) {
      geoRegionDetails = GeoRegionAssignedTargetingOptionDetails.fromJson(
          _json['geoRegionDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('householdIncomeDetails')) {
      householdIncomeDetails =
          HouseholdIncomeAssignedTargetingOptionDetails.fromJson(
              _json['householdIncomeDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inheritance')) {
      inheritance = _json['inheritance'] as core.String;
    }
    if (_json.containsKey('inventorySourceDetails')) {
      inventorySourceDetails =
          InventorySourceAssignedTargetingOptionDetails.fromJson(
              _json['inventorySourceDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inventorySourceGroupDetails')) {
      inventorySourceGroupDetails =
          InventorySourceGroupAssignedTargetingOptionDetails.fromJson(
              _json['inventorySourceGroupDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('keywordDetails')) {
      keywordDetails = KeywordAssignedTargetingOptionDetails.fromJson(
          _json['keywordDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('languageDetails')) {
      languageDetails = LanguageAssignedTargetingOptionDetails.fromJson(
          _json['languageDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nativeContentPositionDetails')) {
      nativeContentPositionDetails =
          NativeContentPositionAssignedTargetingOptionDetails.fromJson(
              _json['nativeContentPositionDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('negativeKeywordListDetails')) {
      negativeKeywordListDetails =
          NegativeKeywordListAssignedTargetingOptionDetails.fromJson(
              _json['negativeKeywordListDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('onScreenPositionDetails')) {
      onScreenPositionDetails =
          OnScreenPositionAssignedTargetingOptionDetails.fromJson(
              _json['onScreenPositionDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('operatingSystemDetails')) {
      operatingSystemDetails =
          OperatingSystemAssignedTargetingOptionDetails.fromJson(
              _json['operatingSystemDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('parentalStatusDetails')) {
      parentalStatusDetails =
          ParentalStatusAssignedTargetingOptionDetails.fromJson(
              _json['parentalStatusDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('proximityLocationListDetails')) {
      proximityLocationListDetails =
          ProximityLocationListAssignedTargetingOptionDetails.fromJson(
              _json['proximityLocationListDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('regionalLocationListDetails')) {
      regionalLocationListDetails =
          RegionalLocationListAssignedTargetingOptionDetails.fromJson(
              _json['regionalLocationListDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sensitiveCategoryExclusionDetails')) {
      sensitiveCategoryExclusionDetails =
          SensitiveCategoryAssignedTargetingOptionDetails.fromJson(
              _json['sensitiveCategoryExclusionDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subExchangeDetails')) {
      subExchangeDetails = SubExchangeAssignedTargetingOptionDetails.fromJson(
          _json['subExchangeDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('targetingType')) {
      targetingType = _json['targetingType'] as core.String;
    }
    if (_json.containsKey('thirdPartyVerifierDetails')) {
      thirdPartyVerifierDetails =
          ThirdPartyVerifierAssignedTargetingOptionDetails.fromJson(
              _json['thirdPartyVerifierDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('urlDetails')) {
      urlDetails = UrlAssignedTargetingOptionDetails.fromJson(
          _json['urlDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('userRewardedContentDetails')) {
      userRewardedContentDetails =
          UserRewardedContentAssignedTargetingOptionDetails.fromJson(
              _json['userRewardedContentDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('videoPlayerSizeDetails')) {
      videoPlayerSizeDetails =
          VideoPlayerSizeAssignedTargetingOptionDetails.fromJson(
              _json['videoPlayerSizeDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('viewabilityDetails')) {
      viewabilityDetails = ViewabilityAssignedTargetingOptionDetails.fromJson(
          _json['viewabilityDetails'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ageRangeDetails != null)
          'ageRangeDetails': ageRangeDetails!.toJson(),
        if (appCategoryDetails != null)
          'appCategoryDetails': appCategoryDetails!.toJson(),
        if (appDetails != null) 'appDetails': appDetails!.toJson(),
        if (assignedTargetingOptionId != null)
          'assignedTargetingOptionId': assignedTargetingOptionId!,
        if (audienceGroupDetails != null)
          'audienceGroupDetails': audienceGroupDetails!.toJson(),
        if (authorizedSellerStatusDetails != null)
          'authorizedSellerStatusDetails':
              authorizedSellerStatusDetails!.toJson(),
        if (browserDetails != null) 'browserDetails': browserDetails!.toJson(),
        if (carrierAndIspDetails != null)
          'carrierAndIspDetails': carrierAndIspDetails!.toJson(),
        if (categoryDetails != null)
          'categoryDetails': categoryDetails!.toJson(),
        if (channelDetails != null) 'channelDetails': channelDetails!.toJson(),
        if (contentInstreamPositionDetails != null)
          'contentInstreamPositionDetails':
              contentInstreamPositionDetails!.toJson(),
        if (contentOutstreamPositionDetails != null)
          'contentOutstreamPositionDetails':
              contentOutstreamPositionDetails!.toJson(),
        if (dayAndTimeDetails != null)
          'dayAndTimeDetails': dayAndTimeDetails!.toJson(),
        if (deviceMakeModelDetails != null)
          'deviceMakeModelDetails': deviceMakeModelDetails!.toJson(),
        if (deviceTypeDetails != null)
          'deviceTypeDetails': deviceTypeDetails!.toJson(),
        if (digitalContentLabelExclusionDetails != null)
          'digitalContentLabelExclusionDetails':
              digitalContentLabelExclusionDetails!.toJson(),
        if (environmentDetails != null)
          'environmentDetails': environmentDetails!.toJson(),
        if (exchangeDetails != null)
          'exchangeDetails': exchangeDetails!.toJson(),
        if (genderDetails != null) 'genderDetails': genderDetails!.toJson(),
        if (geoRegionDetails != null)
          'geoRegionDetails': geoRegionDetails!.toJson(),
        if (householdIncomeDetails != null)
          'householdIncomeDetails': householdIncomeDetails!.toJson(),
        if (inheritance != null) 'inheritance': inheritance!,
        if (inventorySourceDetails != null)
          'inventorySourceDetails': inventorySourceDetails!.toJson(),
        if (inventorySourceGroupDetails != null)
          'inventorySourceGroupDetails': inventorySourceGroupDetails!.toJson(),
        if (keywordDetails != null) 'keywordDetails': keywordDetails!.toJson(),
        if (languageDetails != null)
          'languageDetails': languageDetails!.toJson(),
        if (name != null) 'name': name!,
        if (nativeContentPositionDetails != null)
          'nativeContentPositionDetails':
              nativeContentPositionDetails!.toJson(),
        if (negativeKeywordListDetails != null)
          'negativeKeywordListDetails': negativeKeywordListDetails!.toJson(),
        if (onScreenPositionDetails != null)
          'onScreenPositionDetails': onScreenPositionDetails!.toJson(),
        if (operatingSystemDetails != null)
          'operatingSystemDetails': operatingSystemDetails!.toJson(),
        if (parentalStatusDetails != null)
          'parentalStatusDetails': parentalStatusDetails!.toJson(),
        if (proximityLocationListDetails != null)
          'proximityLocationListDetails':
              proximityLocationListDetails!.toJson(),
        if (regionalLocationListDetails != null)
          'regionalLocationListDetails': regionalLocationListDetails!.toJson(),
        if (sensitiveCategoryExclusionDetails != null)
          'sensitiveCategoryExclusionDetails':
              sensitiveCategoryExclusionDetails!.toJson(),
        if (subExchangeDetails != null)
          'subExchangeDetails': subExchangeDetails!.toJson(),
        if (targetingType != null) 'targetingType': targetingType!,
        if (thirdPartyVerifierDetails != null)
          'thirdPartyVerifierDetails': thirdPartyVerifierDetails!.toJson(),
        if (urlDetails != null) 'urlDetails': urlDetails!.toJson(),
        if (userRewardedContentDetails != null)
          'userRewardedContentDetails': userRewardedContentDetails!.toJson(),
        if (videoPlayerSizeDetails != null)
          'videoPlayerSizeDetails': videoPlayerSizeDetails!.toJson(),
        if (viewabilityDetails != null)
          'viewabilityDetails': viewabilityDetails!.toJson(),
      };
}

/// A single assigned user role, which defines a user's authorized interaction
/// with a specified partner or advertiser.
class AssignedUserRole {
  /// The ID of the advertiser that the assigend user role applies to.
  core.String? advertiserId;

  /// The ID of the assigned user role.
  ///
  /// Output only.
  core.String? assignedUserRoleId;

  /// The ID of the partner that the assigned user role applies to.
  core.String? partnerId;

  /// The user role to assign to a user for the entity.
  ///
  /// Required.
  /// Possible string values are:
  /// - "USER_ROLE_UNSPECIFIED" : Default value when the user role is not
  /// specified or is unknown in this version.
  /// - "ADMIN" : The user can manage campaigns, creatives, insertion orders,
  /// line items, and reports for the entity. They can view and edit billing
  /// information, create or modify users, and enable or disable exchanges. This
  /// role can only be assigned for a partner entity.
  /// - "ADMIN_PARTNER_CLIENT" : The user can manage campaigns, creatives,
  /// insertion orders, line items, and reports for the entity. They can create
  /// and modify other `ADMIN_PARTNER_CLIENT` users and view billing
  /// information. They cannot view revenue models, markups, or any other
  /// reseller-sensitive fields. This role can only be assigned for a partner
  /// entity.
  /// - "STANDARD" : The user can manage campaigns, creatives, insertion orders,
  /// line items, and reports for the entity. They cannot create and modify
  /// users or view billing information.
  /// - "STANDARD_PLANNER" : The user can view all campaigns, creatives,
  /// insertion orders, line items, and reports for the entity, including all
  /// cost data. They can create and modify planning-related features, including
  /// plans and inventory.
  /// - "STANDARD_PLANNER_LIMITED" : The user can view all campaigns, creatives,
  /// insertion orders, line items, and reports for the entity. They can create
  /// or modify planning-related features, including plans and inventory. They
  /// have no access to cost data and cannot start, accept, or negotiate deals.
  /// - "STANDARD_PARTNER_CLIENT" : The user can manage campaigns, creatives,
  /// insertion orders, line items, and reports for the entity. They cannot
  /// create or modify other users or view billing information. They cannot view
  /// revenue models, markups, or any other reseller-sensitive fields. This role
  /// can only be assigned for an advertiser entity.
  /// - "READ_ONLY" : The user can only build reports and view data for the
  /// entity.
  /// - "REPORTING_ONLY" : The user can only create and manage reports.
  /// - "LIMITED_REPORTING_ONLY" : The user can only create and manage the
  /// following client-safe reports: General, Audience Performance,
  /// Cross-Partner, Keyword, Order ID, Category, and Third-Party Data Provider.
  /// - "CREATIVE" : The user can view media plan information they need to
  /// collaborate, but can't view cost-related data or Marketplace.
  /// - "CREATIVE_ADMIN" : The user can view media plan information they need to
  /// collaborate, but can't view cost-related data or Marketplace. In addition,
  /// they can add other creative admins or creative users to the entity.
  core.String? userRole;

  AssignedUserRole();

  AssignedUserRole.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('assignedUserRoleId')) {
      assignedUserRoleId = _json['assignedUserRoleId'] as core.String;
    }
    if (_json.containsKey('partnerId')) {
      partnerId = _json['partnerId'] as core.String;
    }
    if (_json.containsKey('userRole')) {
      userRole = _json['userRole'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (assignedUserRoleId != null)
          'assignedUserRoleId': assignedUserRoleId!,
        if (partnerId != null) 'partnerId': partnerId!,
        if (userRole != null) 'userRole': userRole!,
      };
}

/// Assigned audience group targeting option details.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_AUDIENCE_GROUP`. The relation between
/// each group is UNION, except for
/// excluded_first_and_third_party_audience_group and
/// excluded_google_audience_group, of which COMPLEMENT is UNION'ed with other
/// groups.
class AudienceGroupAssignedTargetingOptionDetails {
  /// The first and third party audience ids and recencies of the excluded first
  /// and third party audience group.
  ///
  /// Used for negative targeting. Its COMPLEMENT is used to UNION other
  /// audience groups.
  FirstAndThirdPartyAudienceGroup? excludedFirstAndThirdPartyAudienceGroup;

  /// The Google audience ids of the excluded Google audience group.
  ///
  /// Used for negative targeting. It's COMPLEMENT is used to UNION other
  /// audience groups. Only contains Affinity, In-market and Installed-apps type
  /// Google audiences. All items are logically ‘OR’ of each other.
  GoogleAudienceGroup? excludedGoogleAudienceGroup;

  /// The combined audience ids of the included combined audience group.
  ///
  /// Contains combined audience ids only.
  CombinedAudienceGroup? includedCombinedAudienceGroup;

  /// The custom list ids of the included custom list group.
  ///
  /// Contains custom list ids only.
  CustomListGroup? includedCustomListGroup;

  /// The first and third party audience ids and recencies of included first and
  /// third party audience groups.
  ///
  /// Each first and third party audience group contains first and third party
  /// audience ids only. The relation between each first and third party
  /// audience group is INTERSECTION, and the result is UNION'ed with other
  /// audience groups. Repeated groups with same settings will be ignored.
  core.List<FirstAndThirdPartyAudienceGroup>?
      includedFirstAndThirdPartyAudienceGroups;

  /// The Google audience ids of the included Google audience group.
  ///
  /// Contains Google audience ids only.
  GoogleAudienceGroup? includedGoogleAudienceGroup;

  AudienceGroupAssignedTargetingOptionDetails();

  AudienceGroupAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('excludedFirstAndThirdPartyAudienceGroup')) {
      excludedFirstAndThirdPartyAudienceGroup =
          FirstAndThirdPartyAudienceGroup.fromJson(
              _json['excludedFirstAndThirdPartyAudienceGroup']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('excludedGoogleAudienceGroup')) {
      excludedGoogleAudienceGroup = GoogleAudienceGroup.fromJson(
          _json['excludedGoogleAudienceGroup']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('includedCombinedAudienceGroup')) {
      includedCombinedAudienceGroup = CombinedAudienceGroup.fromJson(
          _json['includedCombinedAudienceGroup']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('includedCustomListGroup')) {
      includedCustomListGroup = CustomListGroup.fromJson(
          _json['includedCustomListGroup']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('includedFirstAndThirdPartyAudienceGroups')) {
      includedFirstAndThirdPartyAudienceGroups =
          (_json['includedFirstAndThirdPartyAudienceGroups'] as core.List)
              .map<FirstAndThirdPartyAudienceGroup>((value) =>
                  FirstAndThirdPartyAudienceGroup.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('includedGoogleAudienceGroup')) {
      includedGoogleAudienceGroup = GoogleAudienceGroup.fromJson(
          _json['includedGoogleAudienceGroup']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (excludedFirstAndThirdPartyAudienceGroup != null)
          'excludedFirstAndThirdPartyAudienceGroup':
              excludedFirstAndThirdPartyAudienceGroup!.toJson(),
        if (excludedGoogleAudienceGroup != null)
          'excludedGoogleAudienceGroup': excludedGoogleAudienceGroup!.toJson(),
        if (includedCombinedAudienceGroup != null)
          'includedCombinedAudienceGroup':
              includedCombinedAudienceGroup!.toJson(),
        if (includedCustomListGroup != null)
          'includedCustomListGroup': includedCustomListGroup!.toJson(),
        if (includedFirstAndThirdPartyAudienceGroups != null)
          'includedFirstAndThirdPartyAudienceGroups':
              includedFirstAndThirdPartyAudienceGroups!
                  .map((value) => value.toJson())
                  .toList(),
        if (includedGoogleAudienceGroup != null)
          'includedGoogleAudienceGroup': includedGoogleAudienceGroup!.toJson(),
      };
}

/// The length an audio or a video has been played.
class AudioVideoOffset {
  /// The offset in percentage of the audio or video duration.
  core.String? percentage;

  /// The offset in seconds from the start of the audio or video.
  core.String? seconds;

  AudioVideoOffset();

  AudioVideoOffset.fromJson(core.Map _json) {
    if (_json.containsKey('percentage')) {
      percentage = _json['percentage'] as core.String;
    }
    if (_json.containsKey('seconds')) {
      seconds = _json['seconds'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (percentage != null) 'percentage': percentage!,
        if (seconds != null) 'seconds': seconds!,
      };
}

/// Response message for AdvertiserService.AuditAdvertiser.
class AuditAdvertiserResponse {
  /// The number of individual targeting options from the following targeting
  /// types that are assigned to a line item under this advertiser.
  ///
  /// These individual targeting options count towards the limit of 4500000 ad
  /// group targeting options per advertiser. Qualifying Targeting types: *
  /// Channels, URLs, apps, and collections * Demographic * Google Audiences,
  /// including Affinity, Custom Affinity, and In-market audiences * Inventory
  /// source * Keyword * Mobile app category * User lists * Video targeting *
  /// Viewability
  core.String? adGroupCriteriaCount;

  /// The number of individual targeting options from the following targeting
  /// types that are assigned to a line item under this advertiser.
  ///
  /// These individual targeting options count towards the limit of 900000
  /// campaign targeting options per advertiser. Qualifying Targeting types: *
  /// Position * Browser * Connection speed * Day and time * Device and
  /// operating system * Digital content label * Sensitive categories *
  /// Environment * Geography, including business chains and proximity * ISP *
  /// Language * Third-party verification
  core.String? campaignCriteriaCount;

  /// The number of channels created under this advertiser.
  ///
  /// These channels count towards the limit of 1000 channels per advertiser.
  core.String? channelsCount;

  /// The number of negative keyword lists created under this advertiser.
  ///
  /// These negative keyword lists count towards the limit of 20 negative
  /// keyword lists per advertiser.
  core.String? negativeKeywordListsCount;

  /// The number of negatively targeted channels created under this advertiser.
  ///
  /// These negatively targeted channels count towards the limit of 5 negatively
  /// targeted channels per advertiser.
  core.String? negativelyTargetedChannelsCount;

  /// The number of ACTIVE and PAUSED campaigns under this advertiser.
  ///
  /// These campaigns count towards the limit of 9999 campaigns per advertiser.
  core.String? usedCampaignsCount;

  /// The number of ACTIVE, PAUSED and DRAFT insertion orders under this
  /// advertiser.
  ///
  /// These insertion orders count towards the limit of 9999 insertion orders
  /// per advertiser.
  core.String? usedInsertionOrdersCount;

  /// The number of ACTIVE, PAUSED, and DRAFT line items under this advertiser.
  ///
  /// These line items count towards the limit of 9999 line items per
  /// advertiser.
  core.String? usedLineItemsCount;

  AuditAdvertiserResponse();

  AuditAdvertiserResponse.fromJson(core.Map _json) {
    if (_json.containsKey('adGroupCriteriaCount')) {
      adGroupCriteriaCount = _json['adGroupCriteriaCount'] as core.String;
    }
    if (_json.containsKey('campaignCriteriaCount')) {
      campaignCriteriaCount = _json['campaignCriteriaCount'] as core.String;
    }
    if (_json.containsKey('channelsCount')) {
      channelsCount = _json['channelsCount'] as core.String;
    }
    if (_json.containsKey('negativeKeywordListsCount')) {
      negativeKeywordListsCount =
          _json['negativeKeywordListsCount'] as core.String;
    }
    if (_json.containsKey('negativelyTargetedChannelsCount')) {
      negativelyTargetedChannelsCount =
          _json['negativelyTargetedChannelsCount'] as core.String;
    }
    if (_json.containsKey('usedCampaignsCount')) {
      usedCampaignsCount = _json['usedCampaignsCount'] as core.String;
    }
    if (_json.containsKey('usedInsertionOrdersCount')) {
      usedInsertionOrdersCount =
          _json['usedInsertionOrdersCount'] as core.String;
    }
    if (_json.containsKey('usedLineItemsCount')) {
      usedLineItemsCount = _json['usedLineItemsCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adGroupCriteriaCount != null)
          'adGroupCriteriaCount': adGroupCriteriaCount!,
        if (campaignCriteriaCount != null)
          'campaignCriteriaCount': campaignCriteriaCount!,
        if (channelsCount != null) 'channelsCount': channelsCount!,
        if (negativeKeywordListsCount != null)
          'negativeKeywordListsCount': negativeKeywordListsCount!,
        if (negativelyTargetedChannelsCount != null)
          'negativelyTargetedChannelsCount': negativelyTargetedChannelsCount!,
        if (usedCampaignsCount != null)
          'usedCampaignsCount': usedCampaignsCount!,
        if (usedInsertionOrdersCount != null)
          'usedInsertionOrdersCount': usedInsertionOrdersCount!,
        if (usedLineItemsCount != null)
          'usedLineItemsCount': usedLineItemsCount!,
      };
}

/// Represents an assigned authorized seller status.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_AUTHORIZED_SELLER_STATUS`.
class AuthorizedSellerStatusAssignedTargetingOptionDetails {
  /// The authorized seller status to target.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "AUTHORIZED_SELLER_STATUS_UNSPECIFIED" : Default value when authorized
  /// seller status is not specified in this version. This enum is a placeholder
  /// for default value and does not represent a real authorized seller status
  /// option.
  /// - "AUTHORIZED_SELLER_STATUS_AUTHORIZED_DIRECT_SELLERS_ONLY" : Only
  /// authorized sellers that directly own the inventory being monetized, as
  /// indicated by a DIRECT declaration in the ads.txt file.
  /// - "AUTHORIZED_SELLER_STATUS_AUTHORIZED_AND_NON_PARTICIPATING_PUBLISHERS" :
  /// All authorized sellers, including publishers that have not posted an
  /// ads.txt file. Display & Video 360 automatically disallows unauthorized
  /// sellers.
  core.String? authorizedSellerStatus;

  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_AUTHORIZED_SELLER_STATUS`.
  ///
  /// Required.
  core.String? targetingOptionId;

  AuthorizedSellerStatusAssignedTargetingOptionDetails();

  AuthorizedSellerStatusAssignedTargetingOptionDetails.fromJson(
      core.Map _json) {
    if (_json.containsKey('authorizedSellerStatus')) {
      authorizedSellerStatus = _json['authorizedSellerStatus'] as core.String;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (authorizedSellerStatus != null)
          'authorizedSellerStatus': authorizedSellerStatus!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable authorized seller status.
///
/// This will be populated in the authorized_seller_status_details field when
/// targeting_type is `TARGETING_TYPE_AUTHORIZED_SELLER_STATUS`.
class AuthorizedSellerStatusTargetingOptionDetails {
  /// The authorized seller status.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "AUTHORIZED_SELLER_STATUS_UNSPECIFIED" : Default value when authorized
  /// seller status is not specified in this version. This enum is a placeholder
  /// for default value and does not represent a real authorized seller status
  /// option.
  /// - "AUTHORIZED_SELLER_STATUS_AUTHORIZED_DIRECT_SELLERS_ONLY" : Only
  /// authorized sellers that directly own the inventory being monetized, as
  /// indicated by a DIRECT declaration in the ads.txt file.
  /// - "AUTHORIZED_SELLER_STATUS_AUTHORIZED_AND_NON_PARTICIPATING_PUBLISHERS" :
  /// All authorized sellers, including publishers that have not posted an
  /// ads.txt file. Display & Video 360 automatically disallows unauthorized
  /// sellers.
  core.String? authorizedSellerStatus;

  AuthorizedSellerStatusTargetingOptionDetails();

  AuthorizedSellerStatusTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('authorizedSellerStatus')) {
      authorizedSellerStatus = _json['authorizedSellerStatus'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (authorizedSellerStatus != null)
          'authorizedSellerStatus': authorizedSellerStatus!,
      };
}

/// Settings that control the bid strategy.
///
/// Bid strategy determines the bid price.
class BiddingStrategy {
  /// A strategy that uses a fixed bid price.
  FixedBidStrategy? fixedBid;

  /// A strategy that automatically adjusts the bid to optimize to your
  /// performance goal while spending the full budget.
  ///
  /// At insertion order level, the markup_type of line items cannot be set to
  /// `PARTNER_REVENUE_MODEL_MARKUP_TYPE_CPM`. In addition, when
  /// performance_goal_type is one of: *
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPA` *
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPC` *
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_AV_VIEWED` , the line_item_type of
  /// the insertion order line items must be either: *
  /// `LINE_ITEM_TYPE_DISPLAY_DEFAULT` * `LINE_ITEM_TYPE_VIDEO_DEFAULT` , and
  /// when performance_goal_type is either: *
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CIVA` *
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_IVO_TEN` the line_item_type of the
  /// insertion order line items must be `LINE_ITEM_TYPE_VIDEO_DEFAULT`.
  MaximizeSpendBidStrategy? maximizeSpendAutoBid;

  /// A strategy that automatically adjusts the bid to meet or beat a specified
  /// performance goal.
  ///
  /// It is to be used only for a line item entity.
  PerformanceGoalBidStrategy? performanceGoalAutoBid;

  BiddingStrategy();

  BiddingStrategy.fromJson(core.Map _json) {
    if (_json.containsKey('fixedBid')) {
      fixedBid = FixedBidStrategy.fromJson(
          _json['fixedBid'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('maximizeSpendAutoBid')) {
      maximizeSpendAutoBid = MaximizeSpendBidStrategy.fromJson(
          _json['maximizeSpendAutoBid'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('performanceGoalAutoBid')) {
      performanceGoalAutoBid = PerformanceGoalBidStrategy.fromJson(
          _json['performanceGoalAutoBid']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fixedBid != null) 'fixedBid': fixedBid!.toJson(),
        if (maximizeSpendAutoBid != null)
          'maximizeSpendAutoBid': maximizeSpendAutoBid!.toJson(),
        if (performanceGoalAutoBid != null)
          'performanceGoalAutoBid': performanceGoalAutoBid!.toJson(),
      };
}

/// Details for assigned browser targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_BROWSER`.
class BrowserAssignedTargetingOptionDetails {
  /// The display name of the browser.
  ///
  /// Output only.
  core.String? displayName;

  /// Indicates if this option is being negatively targeted.
  ///
  /// All assigned browser targeting options on the same resource must have the
  /// same value for this field.
  core.bool? negative;

  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_BROWSER`.
  ///
  /// Required.
  core.String? targetingOptionId;

  BrowserAssignedTargetingOptionDetails();

  BrowserAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (negative != null) 'negative': negative!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable browser.
///
/// This will be populated in the browser_details field when targeting_type is
/// `TARGETING_TYPE_BROWSER`.
class BrowserTargetingOptionDetails {
  /// The display name of the browser.
  ///
  /// Output only.
  core.String? displayName;

  BrowserTargetingOptionDetails();

  BrowserTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
      };
}

/// Represents a summarized budget information associated with this invoice.
class BudgetSummary {
  /// External budget id.
  ///
  /// Output only.
  core.String? externalBudgetId;

  /// The pre-tax amount for this budget, in micros of the invoice's currency.
  ///
  /// For example if currency_code is `USD`, then 1000000 micros is one US
  /// dollar.
  ///
  /// Output only.
  core.String? preTaxAmountMicros;

  /// Codes specific to the MediaOcean Prisma tool.
  ///
  /// Output only.
  PrismaCpeCode? prismaCpeCode;

  /// The tax amount for this budget, in micros of the invoice's currency.
  ///
  /// For example if currency_code is `USD`, then 1000000 micros is one US
  /// dollar.
  ///
  /// Output only.
  core.String? taxAmountMicros;

  /// The total amount of charges for this budget, in micros of the invoice's
  /// currency.
  ///
  /// For example if currency_code is `USD`, then 1000000 micros is one US
  /// dollar.
  ///
  /// Output only.
  core.String? totalAmountMicros;

  BudgetSummary();

  BudgetSummary.fromJson(core.Map _json) {
    if (_json.containsKey('externalBudgetId')) {
      externalBudgetId = _json['externalBudgetId'] as core.String;
    }
    if (_json.containsKey('preTaxAmountMicros')) {
      preTaxAmountMicros = _json['preTaxAmountMicros'] as core.String;
    }
    if (_json.containsKey('prismaCpeCode')) {
      prismaCpeCode = PrismaCpeCode.fromJson(
          _json['prismaCpeCode'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('taxAmountMicros')) {
      taxAmountMicros = _json['taxAmountMicros'] as core.String;
    }
    if (_json.containsKey('totalAmountMicros')) {
      totalAmountMicros = _json['totalAmountMicros'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (externalBudgetId != null) 'externalBudgetId': externalBudgetId!,
        if (preTaxAmountMicros != null)
          'preTaxAmountMicros': preTaxAmountMicros!,
        if (prismaCpeCode != null) 'prismaCpeCode': prismaCpeCode!.toJson(),
        if (taxAmountMicros != null) 'taxAmountMicros': taxAmountMicros!,
        if (totalAmountMicros != null) 'totalAmountMicros': totalAmountMicros!,
      };
}

/// Request message for BulkEditAdvertiserAssignedTargetingOptions.
class BulkEditAdvertiserAssignedTargetingOptionsRequest {
  /// The assigned targeting options to create in batch, specified as a list of
  /// `CreateAssignedTargetingOptionsRequest`.
  ///
  /// Supported targeting types: * `TARGETING_TYPE_CHANNEL` *
  /// `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` *
  /// `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`
  core.List<CreateAssignedTargetingOptionsRequest>? createRequests;

  /// The assigned targeting options to delete in batch, specified as a list of
  /// `DeleteAssignedTargetingOptionsRequest`.
  ///
  /// Supported targeting types: * `TARGETING_TYPE_CHANNEL` *
  /// `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` *
  /// `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`
  core.List<DeleteAssignedTargetingOptionsRequest>? deleteRequests;

  BulkEditAdvertiserAssignedTargetingOptionsRequest();

  BulkEditAdvertiserAssignedTargetingOptionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('createRequests')) {
      createRequests = (_json['createRequests'] as core.List)
          .map<CreateAssignedTargetingOptionsRequest>((value) =>
              CreateAssignedTargetingOptionsRequest.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('deleteRequests')) {
      deleteRequests = (_json['deleteRequests'] as core.List)
          .map<DeleteAssignedTargetingOptionsRequest>((value) =>
              DeleteAssignedTargetingOptionsRequest.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createRequests != null)
          'createRequests':
              createRequests!.map((value) => value.toJson()).toList(),
        if (deleteRequests != null)
          'deleteRequests':
              deleteRequests!.map((value) => value.toJson()).toList(),
      };
}

class BulkEditAdvertiserAssignedTargetingOptionsResponse {
  /// The list of assigned targeting options that have been successfully
  /// created.
  ///
  /// This list will be absent if empty.
  core.List<AssignedTargetingOption>? createdAssignedTargetingOptions;

  BulkEditAdvertiserAssignedTargetingOptionsResponse();

  BulkEditAdvertiserAssignedTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('createdAssignedTargetingOptions')) {
      createdAssignedTargetingOptions =
          (_json['createdAssignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createdAssignedTargetingOptions != null)
          'createdAssignedTargetingOptions': createdAssignedTargetingOptions!
              .map((value) => value.toJson())
              .toList(),
      };
}

/// Request message for AssignedInventorySourceService.BulkEdit.
class BulkEditAssignedInventorySourcesRequest {
  /// The ID of the advertiser that owns the parent inventory source group.
  ///
  /// The parent partner does not have access to these assigned inventory
  /// sources.
  core.String? advertiserId;

  /// The assigned inventory sources to create in bulk, specified as a list of
  /// AssignedInventorySources.
  core.List<AssignedInventorySource>? createdAssignedInventorySources;

  /// The IDs of the assigned inventory sources to delete in bulk, specified as
  /// a list of assigned_inventory_source_ids.
  core.List<core.String>? deletedAssignedInventorySources;

  /// The ID of the partner that owns the inventory source group.
  ///
  /// Only this partner has write access to these assigned inventory sources.
  core.String? partnerId;

  BulkEditAssignedInventorySourcesRequest();

  BulkEditAssignedInventorySourcesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('createdAssignedInventorySources')) {
      createdAssignedInventorySources =
          (_json['createdAssignedInventorySources'] as core.List)
              .map<AssignedInventorySource>((value) =>
                  AssignedInventorySource.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('deletedAssignedInventorySources')) {
      deletedAssignedInventorySources =
          (_json['deletedAssignedInventorySources'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('partnerId')) {
      partnerId = _json['partnerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (createdAssignedInventorySources != null)
          'createdAssignedInventorySources': createdAssignedInventorySources!
              .map((value) => value.toJson())
              .toList(),
        if (deletedAssignedInventorySources != null)
          'deletedAssignedInventorySources': deletedAssignedInventorySources!,
        if (partnerId != null) 'partnerId': partnerId!,
      };
}

/// Response message for AssignedInventorySourceService.BulkEdit.
class BulkEditAssignedInventorySourcesResponse {
  /// The list of assigned inventory sources that have been successfully
  /// created.
  ///
  /// This list will be absent if empty.
  core.List<AssignedInventorySource>? assignedInventorySources;

  BulkEditAssignedInventorySourcesResponse();

  BulkEditAssignedInventorySourcesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignedInventorySources')) {
      assignedInventorySources =
          (_json['assignedInventorySources'] as core.List)
              .map<AssignedInventorySource>((value) =>
                  AssignedInventorySource.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedInventorySources != null)
          'assignedInventorySources':
              assignedInventorySources!.map((value) => value.toJson()).toList(),
      };
}

/// Request message for AssignedLocationService.BulkEditAssignedLocations.
class BulkEditAssignedLocationsRequest {
  /// The assigned locations to create in bulk, specified as a list of
  /// AssignedLocations.
  core.List<AssignedLocation>? createdAssignedLocations;

  /// The IDs of the assigned locations to delete in bulk, specified as a list
  /// of assigned_location_ids.
  core.List<core.String>? deletedAssignedLocations;

  BulkEditAssignedLocationsRequest();

  BulkEditAssignedLocationsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('createdAssignedLocations')) {
      createdAssignedLocations =
          (_json['createdAssignedLocations'] as core.List)
              .map<AssignedLocation>((value) => AssignedLocation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('deletedAssignedLocations')) {
      deletedAssignedLocations =
          (_json['deletedAssignedLocations'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createdAssignedLocations != null)
          'createdAssignedLocations':
              createdAssignedLocations!.map((value) => value.toJson()).toList(),
        if (deletedAssignedLocations != null)
          'deletedAssignedLocations': deletedAssignedLocations!,
      };
}

/// Response message for AssignedLocationService.BulkEditAssignedLocations.
class BulkEditAssignedLocationsResponse {
  /// The list of assigned locations that have been successfully created.
  ///
  /// This list will be absent if empty.
  core.List<AssignedLocation>? assignedLocations;

  BulkEditAssignedLocationsResponse();

  BulkEditAssignedLocationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignedLocations')) {
      assignedLocations = (_json['assignedLocations'] as core.List)
          .map<AssignedLocation>((value) => AssignedLocation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedLocations != null)
          'assignedLocations':
              assignedLocations!.map((value) => value.toJson()).toList(),
      };
}

/// Request message for BulkEditAssignedUserRoles.
class BulkEditAssignedUserRolesRequest {
  /// The assigned user roles to create in batch, specified as a list of
  /// AssignedUserRoles.
  core.List<AssignedUserRole>? createdAssignedUserRoles;

  /// The assigned user roles to delete in batch, specified as a list of
  /// assigned_user_role_ids.
  ///
  /// The format of assigned_user_role_id is `entityType-entityid`, for example
  /// `partner-123`.
  core.List<core.String>? deletedAssignedUserRoles;

  BulkEditAssignedUserRolesRequest();

  BulkEditAssignedUserRolesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('createdAssignedUserRoles')) {
      createdAssignedUserRoles =
          (_json['createdAssignedUserRoles'] as core.List)
              .map<AssignedUserRole>((value) => AssignedUserRole.fromJson(
                  value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('deletedAssignedUserRoles')) {
      deletedAssignedUserRoles =
          (_json['deletedAssignedUserRoles'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createdAssignedUserRoles != null)
          'createdAssignedUserRoles':
              createdAssignedUserRoles!.map((value) => value.toJson()).toList(),
        if (deletedAssignedUserRoles != null)
          'deletedAssignedUserRoles': deletedAssignedUserRoles!,
      };
}

class BulkEditAssignedUserRolesResponse {
  /// The list of assigned user roles that have been successfully created.
  ///
  /// This list will be absent if empty.
  core.List<AssignedUserRole>? createdAssignedUserRoles;

  BulkEditAssignedUserRolesResponse();

  BulkEditAssignedUserRolesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('createdAssignedUserRoles')) {
      createdAssignedUserRoles =
          (_json['createdAssignedUserRoles'] as core.List)
              .map<AssignedUserRole>((value) => AssignedUserRole.fromJson(
                  value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createdAssignedUserRoles != null)
          'createdAssignedUserRoles':
              createdAssignedUserRoles!.map((value) => value.toJson()).toList(),
      };
}

/// Request message for BulkEditLineItemAssignedTargetingOptions.
class BulkEditLineItemAssignedTargetingOptionsRequest {
  /// The assigned targeting options to create in batch, specified as a list of
  /// `CreateAssignedTargetingOptionsRequest`.
  core.List<CreateAssignedTargetingOptionsRequest>? createRequests;

  /// The assigned targeting options to delete in batch, specified as a list of
  /// `DeleteAssignedTargetingOptionsRequest`.
  core.List<DeleteAssignedTargetingOptionsRequest>? deleteRequests;

  BulkEditLineItemAssignedTargetingOptionsRequest();

  BulkEditLineItemAssignedTargetingOptionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('createRequests')) {
      createRequests = (_json['createRequests'] as core.List)
          .map<CreateAssignedTargetingOptionsRequest>((value) =>
              CreateAssignedTargetingOptionsRequest.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('deleteRequests')) {
      deleteRequests = (_json['deleteRequests'] as core.List)
          .map<DeleteAssignedTargetingOptionsRequest>((value) =>
              DeleteAssignedTargetingOptionsRequest.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createRequests != null)
          'createRequests':
              createRequests!.map((value) => value.toJson()).toList(),
        if (deleteRequests != null)
          'deleteRequests':
              deleteRequests!.map((value) => value.toJson()).toList(),
      };
}

class BulkEditLineItemAssignedTargetingOptionsResponse {
  /// The list of assigned targeting options that have been successfully
  /// created.
  ///
  /// This list will be absent if empty.
  core.List<AssignedTargetingOption>? createdAssignedTargetingOptions;

  BulkEditLineItemAssignedTargetingOptionsResponse();

  BulkEditLineItemAssignedTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('createdAssignedTargetingOptions')) {
      createdAssignedTargetingOptions =
          (_json['createdAssignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createdAssignedTargetingOptions != null)
          'createdAssignedTargetingOptions': createdAssignedTargetingOptions!
              .map((value) => value.toJson())
              .toList(),
      };
}

/// Request message for NegativeKeywordService.BulkEditNegativeKeywords.
class BulkEditNegativeKeywordsRequest {
  /// The negative keywords to create in batch, specified as a list of
  /// NegativeKeywords.
  core.List<NegativeKeyword>? createdNegativeKeywords;

  /// The negative keywords to delete in batch, specified as a list of
  /// keyword_values.
  core.List<core.String>? deletedNegativeKeywords;

  BulkEditNegativeKeywordsRequest();

  BulkEditNegativeKeywordsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('createdNegativeKeywords')) {
      createdNegativeKeywords = (_json['createdNegativeKeywords'] as core.List)
          .map<NegativeKeyword>((value) => NegativeKeyword.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('deletedNegativeKeywords')) {
      deletedNegativeKeywords = (_json['deletedNegativeKeywords'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createdNegativeKeywords != null)
          'createdNegativeKeywords':
              createdNegativeKeywords!.map((value) => value.toJson()).toList(),
        if (deletedNegativeKeywords != null)
          'deletedNegativeKeywords': deletedNegativeKeywords!,
      };
}

/// Response message for NegativeKeywordService.BulkEditNegativeKeywords.
class BulkEditNegativeKeywordsResponse {
  /// The list of negative keywords that have been successfully created.
  ///
  /// This list will be absent if empty.
  core.List<NegativeKeyword>? negativeKeywords;

  BulkEditNegativeKeywordsResponse();

  BulkEditNegativeKeywordsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('negativeKeywords')) {
      negativeKeywords = (_json['negativeKeywords'] as core.List)
          .map<NegativeKeyword>((value) => NegativeKeyword.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (negativeKeywords != null)
          'negativeKeywords':
              negativeKeywords!.map((value) => value.toJson()).toList(),
      };
}

/// Request message for BulkEditPartnerAssignedTargetingOptions.
class BulkEditPartnerAssignedTargetingOptionsRequest {
  /// The assigned targeting options to create in batch, specified as a list of
  /// `CreateAssignedTargetingOptionsRequest`.
  ///
  /// Supported targeting types: * `TARGETING_TYPE_CHANNEL`
  core.List<CreateAssignedTargetingOptionsRequest>? createRequests;

  /// The assigned targeting options to delete in batch, specified as a list of
  /// `DeleteAssignedTargetingOptionsRequest`.
  ///
  /// Supported targeting types: * `TARGETING_TYPE_CHANNEL`
  core.List<DeleteAssignedTargetingOptionsRequest>? deleteRequests;

  BulkEditPartnerAssignedTargetingOptionsRequest();

  BulkEditPartnerAssignedTargetingOptionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('createRequests')) {
      createRequests = (_json['createRequests'] as core.List)
          .map<CreateAssignedTargetingOptionsRequest>((value) =>
              CreateAssignedTargetingOptionsRequest.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('deleteRequests')) {
      deleteRequests = (_json['deleteRequests'] as core.List)
          .map<DeleteAssignedTargetingOptionsRequest>((value) =>
              DeleteAssignedTargetingOptionsRequest.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createRequests != null)
          'createRequests':
              createRequests!.map((value) => value.toJson()).toList(),
        if (deleteRequests != null)
          'deleteRequests':
              deleteRequests!.map((value) => value.toJson()).toList(),
      };
}

class BulkEditPartnerAssignedTargetingOptionsResponse {
  /// The list of assigned targeting options that have been successfully
  /// created.
  ///
  /// This list will be absent if empty.
  core.List<AssignedTargetingOption>? createdAssignedTargetingOptions;

  BulkEditPartnerAssignedTargetingOptionsResponse();

  BulkEditPartnerAssignedTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('createdAssignedTargetingOptions')) {
      createdAssignedTargetingOptions =
          (_json['createdAssignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createdAssignedTargetingOptions != null)
          'createdAssignedTargetingOptions': createdAssignedTargetingOptions!
              .map((value) => value.toJson())
              .toList(),
      };
}

/// Request message for SiteService.BulkEditSites.
class BulkEditSitesRequest {
  /// The ID of the advertiser that owns the parent channel.
  core.String? advertiserId;

  /// The sites to create in batch, specified as a list of Sites.
  core.List<Site>? createdSites;

  /// The sites to delete in batch, specified as a list of site url_or_app_ids.
  core.List<core.String>? deletedSites;

  /// The ID of the partner that owns the parent channel.
  core.String? partnerId;

  BulkEditSitesRequest();

  BulkEditSitesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('createdSites')) {
      createdSites = (_json['createdSites'] as core.List)
          .map<Site>((value) =>
              Site.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('deletedSites')) {
      deletedSites = (_json['deletedSites'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('partnerId')) {
      partnerId = _json['partnerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (createdSites != null)
          'createdSites': createdSites!.map((value) => value.toJson()).toList(),
        if (deletedSites != null) 'deletedSites': deletedSites!,
        if (partnerId != null) 'partnerId': partnerId!,
      };
}

/// Response message for SiteService.BulkEditSites.
class BulkEditSitesResponse {
  /// The list of sites that have been successfully created.
  ///
  /// This list will be absent if empty.
  core.List<Site>? sites;

  BulkEditSitesResponse();

  BulkEditSitesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('sites')) {
      sites = (_json['sites'] as core.List)
          .map<Site>((value) =>
              Site.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sites != null)
          'sites': sites!.map((value) => value.toJson()).toList(),
      };
}

class BulkListAdvertiserAssignedTargetingOptionsResponse {
  /// The list of assigned targeting options.
  ///
  /// This list will be absent if empty.
  core.List<AssignedTargetingOption>? assignedTargetingOptions;

  /// A token identifying the next page of results.
  ///
  /// This value should be specified as the pageToken in a subsequent
  /// BulkListAdvertiserAssignedTargetingOptionsRequest to fetch the next page
  /// of results. This token will be absent if there are no more
  /// assigned_targeting_options to return.
  core.String? nextPageToken;

  BulkListAdvertiserAssignedTargetingOptionsResponse();

  BulkListAdvertiserAssignedTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignedTargetingOptions')) {
      assignedTargetingOptions =
          (_json['assignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedTargetingOptions != null)
          'assignedTargetingOptions':
              assignedTargetingOptions!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for BulkListCampaignAssignedTargetingOptions.
class BulkListCampaignAssignedTargetingOptionsResponse {
  /// The list of assigned targeting options.
  ///
  /// This list will be absent if empty.
  core.List<AssignedTargetingOption>? assignedTargetingOptions;

  /// A token identifying the next page of results.
  ///
  /// This value should be specified as the pageToken in a subsequent
  /// BulkListCampaignAssignedTargetingOptionsRequest to fetch the next page of
  /// results. This token will be absent if there are no more
  /// assigned_targeting_options to return.
  core.String? nextPageToken;

  BulkListCampaignAssignedTargetingOptionsResponse();

  BulkListCampaignAssignedTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignedTargetingOptions')) {
      assignedTargetingOptions =
          (_json['assignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedTargetingOptions != null)
          'assignedTargetingOptions':
              assignedTargetingOptions!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for BulkListInsertionOrderAssignedTargetingOptions.
class BulkListInsertionOrderAssignedTargetingOptionsResponse {
  /// The list of assigned targeting options.
  ///
  /// This list will be absent if empty.
  core.List<AssignedTargetingOption>? assignedTargetingOptions;

  /// A token identifying the next page of results.
  ///
  /// This value should be specified as the pageToken in a subsequent
  /// BulkListInsertionOrderAssignedTargetingOptionsRequest to fetch the next
  /// page of results. This token will be absent if there are no more
  /// assigned_targeting_options to return.
  core.String? nextPageToken;

  BulkListInsertionOrderAssignedTargetingOptionsResponse();

  BulkListInsertionOrderAssignedTargetingOptionsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('assignedTargetingOptions')) {
      assignedTargetingOptions =
          (_json['assignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedTargetingOptions != null)
          'assignedTargetingOptions':
              assignedTargetingOptions!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class BulkListLineItemAssignedTargetingOptionsResponse {
  /// The list of assigned targeting options.
  ///
  /// This list will be absent if empty.
  core.List<AssignedTargetingOption>? assignedTargetingOptions;

  /// A token identifying the next page of results.
  ///
  /// This value should be specified as the pageToken in a subsequent
  /// BulkListLineItemAssignedTargetingOptionsRequest to fetch the next page of
  /// results. This token will be absent if there are no more
  /// assigned_targeting_options to return.
  core.String? nextPageToken;

  BulkListLineItemAssignedTargetingOptionsResponse();

  BulkListLineItemAssignedTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignedTargetingOptions')) {
      assignedTargetingOptions =
          (_json['assignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedTargetingOptions != null)
          'assignedTargetingOptions':
              assignedTargetingOptions!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A single campaign.
class Campaign {
  /// The unique ID of the advertiser the campaign belongs to.
  ///
  /// Output only.
  core.String? advertiserId;

  /// The list of budgets available to this campaign.
  ///
  /// Setting no budget gives an unlimited campaign budget.
  core.List<CampaignBudget>? campaignBudgets;

  /// The planned spend and duration of the campaign.
  ///
  /// Required.
  CampaignFlight? campaignFlight;

  /// The goal of the campaign.
  ///
  /// Required.
  CampaignGoal? campaignGoal;

  /// The unique ID of the campaign.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? campaignId;

  /// The display name of the campaign.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// Controls whether or not the insertion orders under this campaign can spend
  /// their budgets and bid on inventory.
  ///
  /// * Accepted values are `ENTITY_STATUS_ACTIVE`, `ENTITY_STATUS_ARCHIVED`,
  /// and `ENTITY_STATUS_PAUSED`. * For CreateCampaign method,
  /// `ENTITY_STATUS_ARCHIVED` is not allowed.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ENTITY_STATUS_UNSPECIFIED" : Default value when status is not specified
  /// or is unknown in this version.
  /// - "ENTITY_STATUS_ACTIVE" : The entity is enabled to bid and spend budget.
  /// - "ENTITY_STATUS_ARCHIVED" : The entity is archived. Bidding and budget
  /// spending are disabled. An entity can be deleted after archived. Deleted
  /// entities cannot be retrieved.
  /// - "ENTITY_STATUS_DRAFT" : The entity is under draft. Bidding and budget
  /// spending are disabled.
  /// - "ENTITY_STATUS_PAUSED" : Bidding and budget spending are paused for the
  /// entity.
  /// - "ENTITY_STATUS_SCHEDULED_FOR_DELETION" : The entity is scheduled for
  /// deletion.
  core.String? entityStatus;

  /// The frequency cap setting of the campaign.
  ///
  /// Required.
  FrequencyCap? frequencyCap;

  /// The resource name of the campaign.
  ///
  /// Output only.
  core.String? name;

  /// The timestamp when the campaign was last updated.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? updateTime;

  Campaign();

  Campaign.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('campaignBudgets')) {
      campaignBudgets = (_json['campaignBudgets'] as core.List)
          .map<CampaignBudget>((value) => CampaignBudget.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('campaignFlight')) {
      campaignFlight = CampaignFlight.fromJson(
          _json['campaignFlight'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('campaignGoal')) {
      campaignGoal = CampaignGoal.fromJson(
          _json['campaignGoal'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('campaignId')) {
      campaignId = _json['campaignId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('entityStatus')) {
      entityStatus = _json['entityStatus'] as core.String;
    }
    if (_json.containsKey('frequencyCap')) {
      frequencyCap = FrequencyCap.fromJson(
          _json['frequencyCap'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (campaignBudgets != null)
          'campaignBudgets':
              campaignBudgets!.map((value) => value.toJson()).toList(),
        if (campaignFlight != null) 'campaignFlight': campaignFlight!.toJson(),
        if (campaignGoal != null) 'campaignGoal': campaignGoal!.toJson(),
        if (campaignId != null) 'campaignId': campaignId!,
        if (displayName != null) 'displayName': displayName!,
        if (entityStatus != null) 'entityStatus': entityStatus!,
        if (frequencyCap != null) 'frequencyCap': frequencyCap!.toJson(),
        if (name != null) 'name': name!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Settings that control how the campaign budget is allocated.
class CampaignBudget {
  /// The budget amount the insertion order will spend for the given date_range.
  ///
  /// The amount is in micros. Must be greater than 0. For example, 500000000
  /// represents 500 standard units of the currency.
  ///
  /// Required.
  core.String? budgetAmountMicros;

  /// The unique ID of the campaign budget.
  ///
  /// If not included, budget is assumed to be new.
  core.String? budgetId;

  /// The budget unit specifies whether the budget is currency based or
  /// impression based.
  ///
  /// Required. Immutable.
  /// Possible string values are:
  /// - "BUDGET_UNIT_UNSPECIFIED" : Type value is not specified or is unknown in
  /// this version.
  /// - "BUDGET_UNIT_CURRENCY" : Budgeting in currency amounts.
  /// - "BUDGET_UNIT_IMPRESSIONS" : Budgeting in impression amounts.
  core.String? budgetUnit;

  /// The flight start and end time settings of the segment.
  ///
  /// Both `start_date` and `end_date` must be before the year 2037.
  ///
  /// Required.
  DateRange? dateRange;

  /// The display name of the budget.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// Must be unique under the campaign.
  ///
  /// If set, all impressions served against this budget will include this ID on
  /// the invoice if the customer has opted into budget-segment-level billing.
  ///
  /// Immutable.
  core.String? externalBudgetId;

  /// The external source of the budget segment.
  ///
  /// Required.
  /// Possible string values are:
  /// - "EXTERNAL_BUDGET_SOURCE_UNSPECIFIED" : External budget source value is
  /// not specified or unknown in this version.
  /// - "EXTERNAL_BUDGET_SOURCE_NONE" : Budget has no external source.
  /// - "EXTERNAL_BUDGET_SOURCE_MEDIA_OCEAN" : Budget source is MediaOcean.
  core.String? externalBudgetSource;

  /// If set, all external_budget_id sharing the same invoice_grouping_id will
  /// include this ID on the invoice if the customer has opted into
  /// budget-segment-level billing.
  ///
  /// Immutable.
  core.String? invoiceGroupingId;

  /// Required for MediaOcean budgets.
  ///
  /// Additional metadata set by the MediaOcean Prisma tool.
  PrismaConfig? prismaConfig;

  CampaignBudget();

  CampaignBudget.fromJson(core.Map _json) {
    if (_json.containsKey('budgetAmountMicros')) {
      budgetAmountMicros = _json['budgetAmountMicros'] as core.String;
    }
    if (_json.containsKey('budgetId')) {
      budgetId = _json['budgetId'] as core.String;
    }
    if (_json.containsKey('budgetUnit')) {
      budgetUnit = _json['budgetUnit'] as core.String;
    }
    if (_json.containsKey('dateRange')) {
      dateRange = DateRange.fromJson(
          _json['dateRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('externalBudgetId')) {
      externalBudgetId = _json['externalBudgetId'] as core.String;
    }
    if (_json.containsKey('externalBudgetSource')) {
      externalBudgetSource = _json['externalBudgetSource'] as core.String;
    }
    if (_json.containsKey('invoiceGroupingId')) {
      invoiceGroupingId = _json['invoiceGroupingId'] as core.String;
    }
    if (_json.containsKey('prismaConfig')) {
      prismaConfig = PrismaConfig.fromJson(
          _json['prismaConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (budgetAmountMicros != null)
          'budgetAmountMicros': budgetAmountMicros!,
        if (budgetId != null) 'budgetId': budgetId!,
        if (budgetUnit != null) 'budgetUnit': budgetUnit!,
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
        if (displayName != null) 'displayName': displayName!,
        if (externalBudgetId != null) 'externalBudgetId': externalBudgetId!,
        if (externalBudgetSource != null)
          'externalBudgetSource': externalBudgetSource!,
        if (invoiceGroupingId != null) 'invoiceGroupingId': invoiceGroupingId!,
        if (prismaConfig != null) 'prismaConfig': prismaConfig!.toJson(),
      };
}

/// Settings that track the planned spend and duration of a campaign.
class CampaignFlight {
  /// The dates that the campaign is expected to run.
  ///
  /// They are resolved relative to the parent advertiser's time zone. * The
  /// dates specified here will not affect serving. They are used to generate
  /// alerts and warnings. For example, if the flight date of any child
  /// insertion order is outside the range of these dates, the user interface
  /// will show a warning. * `start_date` is required and must be the current
  /// date or later. * `end_date` is optional. If specified, it must be the
  /// `start_date` or later. * Any specified date must be before the year 2037.
  ///
  /// Required.
  DateRange? plannedDates;

  /// The amount the campaign is expected to spend for its given planned_dates.
  ///
  /// This will not limit serving, but will be used for tracking spend in the
  /// DV360 UI. The amount is in micros. Must be greater than or equal to 0. For
  /// example, 500000000 represents 500 standard units of the currency.
  core.String? plannedSpendAmountMicros;

  CampaignFlight();

  CampaignFlight.fromJson(core.Map _json) {
    if (_json.containsKey('plannedDates')) {
      plannedDates = DateRange.fromJson(
          _json['plannedDates'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('plannedSpendAmountMicros')) {
      plannedSpendAmountMicros =
          _json['plannedSpendAmountMicros'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (plannedDates != null) 'plannedDates': plannedDates!.toJson(),
        if (plannedSpendAmountMicros != null)
          'plannedSpendAmountMicros': plannedSpendAmountMicros!,
      };
}

/// Settings that control the goal of a campaign.
class CampaignGoal {
  /// The type of the campaign goal.
  ///
  /// Required.
  /// Possible string values are:
  /// - "CAMPAIGN_GOAL_TYPE_UNSPECIFIED" : Goal value is not specified or
  /// unknown in this version.
  /// - "CAMPAIGN_GOAL_TYPE_APP_INSTALL" : Drive app installs or engagements.
  /// - "CAMPAIGN_GOAL_TYPE_BRAND_AWARENESS" : Raise awareness of a brand or
  /// product.
  /// - "CAMPAIGN_GOAL_TYPE_OFFLINE_ACTION" : Drive offline or in-store sales.
  /// - "CAMPAIGN_GOAL_TYPE_ONLINE_ACTION" : Drive online action or visits.
  core.String? campaignGoalType;

  /// The performance goal of the campaign.
  ///
  /// Acceptable values for performance_goal_type are: *
  /// `PERFORMANCE_GOAL_TYPE_CPM` * `PERFORMANCE_GOAL_TYPE_CPC` *
  /// `PERFORMANCE_GOAL_TYPE_CPA` * `PERFORMANCE_GOAL_TYPE_CPIAVC` *
  /// `PERFORMANCE_GOAL_TYPE_CTR` * `PERFORMANCE_GOAL_TYPE_VIEWABILITY` *
  /// `PERFORMANCE_GOAL_TYPE_OTHER`
  ///
  /// Required.
  PerformanceGoal? performanceGoal;

  CampaignGoal();

  CampaignGoal.fromJson(core.Map _json) {
    if (_json.containsKey('campaignGoalType')) {
      campaignGoalType = _json['campaignGoalType'] as core.String;
    }
    if (_json.containsKey('performanceGoal')) {
      performanceGoal = PerformanceGoal.fromJson(
          _json['performanceGoal'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (campaignGoalType != null) 'campaignGoalType': campaignGoalType!,
        if (performanceGoal != null)
          'performanceGoal': performanceGoal!.toJson(),
      };
}

/// Details for assigned carrier and ISP targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_CARRIER_AND_ISP`.
class CarrierAndIspAssignedTargetingOptionDetails {
  /// The display name of the carrier or ISP.
  ///
  /// Output only.
  core.String? displayName;

  /// Indicates if this option is being negatively targeted.
  ///
  /// All assigned carrier and ISP targeting options on the same resource must
  /// have the same value for this field.
  core.bool? negative;

  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_CARRIER_AND_ISP`.
  ///
  /// Required.
  core.String? targetingOptionId;

  CarrierAndIspAssignedTargetingOptionDetails();

  CarrierAndIspAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (negative != null) 'negative': negative!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable carrier or ISP.
///
/// This will be populated in the carrier_and_isp_details field of a
/// TargetingOption when targeting_type is `TARGETING_TYPE_CARRIER_AND_ISP`.
class CarrierAndIspTargetingOptionDetails {
  /// The display name of the carrier or ISP.
  ///
  /// Output only.
  core.String? displayName;

  /// The type indicating if it's carrier or ISP.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "CARRIER_AND_ISP_TYPE_UNSPECIFIED" : Default value when type is not
  /// specified or is unknown in this version.
  /// - "CARRIER_AND_ISP_TYPE_ISP" : Indicates this targeting resource refers to
  /// an ISP.
  /// - "CARRIER_AND_ISP_TYPE_CARRIER" : Indicates this targeting resource
  /// refers to a mobile carrier.
  core.String? type;

  CarrierAndIspTargetingOptionDetails();

  CarrierAndIspTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (type != null) 'type': type!,
      };
}

/// Assigned category targeting option details.
///
/// This will be populated in the category_details field when targeting_type is
/// `TARGETING_TYPE_CATEGORY`.
class CategoryAssignedTargetingOptionDetails {
  /// The display name of the category.
  ///
  /// Output only.
  core.String? displayName;

  /// Indicates if this option is being negatively targeted.
  core.bool? negative;

  /// The targeting_option_id field when targeting_type is
  /// `TARGETING_TYPE_CATEGORY`.
  ///
  /// Required.
  core.String? targetingOptionId;

  CategoryAssignedTargetingOptionDetails();

  CategoryAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (negative != null) 'negative': negative!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable category.
///
/// This will be populated in the category_details field of a TargetingOption
/// when targeting_type is `TARGETING_TYPE_CATEGORY`.
class CategoryTargetingOptionDetails {
  /// The display name of the category.
  ///
  /// Output only.
  core.String? displayName;

  CategoryTargetingOptionDetails();

  CategoryTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
      };
}

/// A single channel.
///
/// Channels are custom groups of related websites and apps.
class Channel {
  /// The ID of the advertiser that owns the channel.
  core.String? advertiserId;

  /// The unique ID of the channel.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? channelId;

  /// The display name of the channel.
  ///
  /// Must be UTF-8 encoded with a maximum length of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// The resource name of the channel.
  ///
  /// Output only.
  core.String? name;

  /// Number of line items that are directly targeting this channel negatively.
  ///
  /// Output only.
  core.String? negativelyTargetedLineItemCount;

  /// The ID of the partner that owns the channel.
  core.String? partnerId;

  /// Number of line items that are directly targeting this channel positively.
  ///
  /// Output only.
  core.String? positivelyTargetedLineItemCount;

  Channel();

  Channel.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('channelId')) {
      channelId = _json['channelId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('negativelyTargetedLineItemCount')) {
      negativelyTargetedLineItemCount =
          _json['negativelyTargetedLineItemCount'] as core.String;
    }
    if (_json.containsKey('partnerId')) {
      partnerId = _json['partnerId'] as core.String;
    }
    if (_json.containsKey('positivelyTargetedLineItemCount')) {
      positivelyTargetedLineItemCount =
          _json['positivelyTargetedLineItemCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (channelId != null) 'channelId': channelId!,
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
        if (negativelyTargetedLineItemCount != null)
          'negativelyTargetedLineItemCount': negativelyTargetedLineItemCount!,
        if (partnerId != null) 'partnerId': partnerId!,
        if (positivelyTargetedLineItemCount != null)
          'positivelyTargetedLineItemCount': positivelyTargetedLineItemCount!,
      };
}

/// Details for assigned channel targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_CHANNEL`.
class ChannelAssignedTargetingOptionDetails {
  /// ID of the channel.
  ///
  /// Should refer to the channel ID field on a \[Partner-owned
  /// channel\](partners.channels#Channel.FIELDS.channel_id) or
  /// \[advertiser-owned
  /// channel\](advertisers.channels#Channel.FIELDS.channel_id) resource.
  ///
  /// Required.
  core.String? channelId;

  /// Indicates if this option is being negatively targeted.
  ///
  /// For advertiser level assigned targeting option, this field must be true.
  core.bool? negative;

  ChannelAssignedTargetingOptionDetails();

  ChannelAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('channelId')) {
      channelId = _json['channelId'] as core.String;
    }
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channelId != null) 'channelId': channelId!,
        if (negative != null) 'negative': negative!,
      };
}

/// Settings for advertisers that use both Campaign Manager 360 (CM360) and
/// third-party ad servers.
class CmHybridConfig {
  /// Account ID of the CM360 Floodlight configuration linked with the DV360
  /// advertiser.
  ///
  /// Required. Immutable.
  core.String? cmAccountId;

  /// ID of the CM360 Floodlight configuration linked with the DV360 advertiser.
  ///
  /// Required. Immutable.
  core.String? cmFloodlightConfigId;

  /// By setting this field to `true`, you, on behalf of your company, authorize
  /// the sharing of information from the given Floodlight configuration to this
  /// Display & Video 360 advertiser.
  ///
  /// Required. Immutable.
  core.bool? cmFloodlightLinkingAuthorized;

  /// A list of CM360 sites whose placements will be synced to DV360 as
  /// creatives.
  ///
  /// If absent or empty in CreateAdvertiser method, the system will
  /// automatically create a CM360 site. Removing sites from this list may cause
  /// DV360 creatives synced from CM360 to be deleted. At least one site must be
  /// specified.
  core.List<core.String>? cmSyncableSiteIds;

  /// Whether or not to report DV360 cost to CM360.
  core.bool? dv360ToCmCostReportingEnabled;

  /// Whether or not to include DV360 data in CM360 data transfer reports.
  core.bool? dv360ToCmDataSharingEnabled;

  CmHybridConfig();

  CmHybridConfig.fromJson(core.Map _json) {
    if (_json.containsKey('cmAccountId')) {
      cmAccountId = _json['cmAccountId'] as core.String;
    }
    if (_json.containsKey('cmFloodlightConfigId')) {
      cmFloodlightConfigId = _json['cmFloodlightConfigId'] as core.String;
    }
    if (_json.containsKey('cmFloodlightLinkingAuthorized')) {
      cmFloodlightLinkingAuthorized =
          _json['cmFloodlightLinkingAuthorized'] as core.bool;
    }
    if (_json.containsKey('cmSyncableSiteIds')) {
      cmSyncableSiteIds = (_json['cmSyncableSiteIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('dv360ToCmCostReportingEnabled')) {
      dv360ToCmCostReportingEnabled =
          _json['dv360ToCmCostReportingEnabled'] as core.bool;
    }
    if (_json.containsKey('dv360ToCmDataSharingEnabled')) {
      dv360ToCmDataSharingEnabled =
          _json['dv360ToCmDataSharingEnabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cmAccountId != null) 'cmAccountId': cmAccountId!,
        if (cmFloodlightConfigId != null)
          'cmFloodlightConfigId': cmFloodlightConfigId!,
        if (cmFloodlightLinkingAuthorized != null)
          'cmFloodlightLinkingAuthorized': cmFloodlightLinkingAuthorized!,
        if (cmSyncableSiteIds != null) 'cmSyncableSiteIds': cmSyncableSiteIds!,
        if (dv360ToCmCostReportingEnabled != null)
          'dv360ToCmCostReportingEnabled': dv360ToCmCostReportingEnabled!,
        if (dv360ToCmDataSharingEnabled != null)
          'dv360ToCmDataSharingEnabled': dv360ToCmDataSharingEnabled!,
      };
}

/// A Campaign Manager 360 tracking ad.
class CmTrackingAd {
  /// The ad ID of the campaign manager 360 tracking Ad.
  core.String? cmAdId;

  /// The creative ID of the campaign manager 360 tracking Ad.
  core.String? cmCreativeId;

  /// The placement ID of the campaign manager 360 tracking Ad.
  core.String? cmPlacementId;

  CmTrackingAd();

  CmTrackingAd.fromJson(core.Map _json) {
    if (_json.containsKey('cmAdId')) {
      cmAdId = _json['cmAdId'] as core.String;
    }
    if (_json.containsKey('cmCreativeId')) {
      cmCreativeId = _json['cmCreativeId'] as core.String;
    }
    if (_json.containsKey('cmPlacementId')) {
      cmPlacementId = _json['cmPlacementId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cmAdId != null) 'cmAdId': cmAdId!,
        if (cmCreativeId != null) 'cmCreativeId': cmCreativeId!,
        if (cmPlacementId != null) 'cmPlacementId': cmPlacementId!,
      };
}

/// Describes a combined audience resource.
class CombinedAudience {
  /// The unique ID of the combined audience.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? combinedAudienceId;

  /// The display name of the combined audience.
  ///
  /// .
  ///
  /// Output only.
  core.String? displayName;

  /// The resource name of the combined audience.
  ///
  /// Output only.
  core.String? name;

  CombinedAudience();

  CombinedAudience.fromJson(core.Map _json) {
    if (_json.containsKey('combinedAudienceId')) {
      combinedAudienceId = _json['combinedAudienceId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (combinedAudienceId != null)
          'combinedAudienceId': combinedAudienceId!,
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
      };
}

/// Details of combined audience group.
///
/// All combined audience targeting settings are logically ‘OR’ of each other.
class CombinedAudienceGroup {
  /// All combined audience targeting settings in combined audience group.
  ///
  /// Repeated settings with same id will be ignored. The number of combined
  /// audience settings should be no more than five, error will be thrown
  /// otherwise.
  ///
  /// Required.
  core.List<CombinedAudienceTargetingSetting>? settings;

  CombinedAudienceGroup();

  CombinedAudienceGroup.fromJson(core.Map _json) {
    if (_json.containsKey('settings')) {
      settings = (_json['settings'] as core.List)
          .map<CombinedAudienceTargetingSetting>((value) =>
              CombinedAudienceTargetingSetting.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (settings != null)
          'settings': settings!.map((value) => value.toJson()).toList(),
      };
}

/// Details of combined audience targeting setting.
class CombinedAudienceTargetingSetting {
  /// Combined audience id of combined audience targeting setting.
  ///
  /// This id is combined_audience_id.
  ///
  /// Required.
  core.String? combinedAudienceId;

  CombinedAudienceTargetingSetting();

  CombinedAudienceTargetingSetting.fromJson(core.Map _json) {
    if (_json.containsKey('combinedAudienceId')) {
      combinedAudienceId = _json['combinedAudienceId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (combinedAudienceId != null)
          'combinedAudienceId': combinedAudienceId!,
      };
}

/// Assigned content instream position targeting option details.
///
/// This will be populated in the content_instream_position_details field when
/// targeting_type is `TARGETING_TYPE_CONTENT_INSTREAM_POSITION`.
class ContentInstreamPositionAssignedTargetingOptionDetails {
  /// The ad type to target.
  ///
  /// Only applicable to insertion order targeting and new line items supporting
  /// the specified ad type will inherit this targeting option by default.
  /// Possible values are: * `AD_TYPE_VIDEO`, the setting will be inherited by
  /// new line item when line_item_type is `LINE_ITEM_TYPE_VIDEO_DEFAULT`. *
  /// `AD_TYPE_AUDIO`, the setting will be inherited by new line item when
  /// line_item_type is `LINE_ITEM_TYPE_AUDIO_DEFAULT`.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "AD_TYPE_UNSPECIFIED" : Ad type is not specified or is unknown in this
  /// version.
  /// - "AD_TYPE_DISPLAY" : Display creatives, e.g. image and HTML5.
  /// - "AD_TYPE_VIDEO" : Video creatives, e.g. video ads that play during
  /// streaming content in video players.
  /// - "AD_TYPE_AUDIO" : Audio creatives, e.g. audio ads that play during audio
  /// content.
  core.String? adType;

  /// The content instream position for video or audio ads.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "CONTENT_INSTREAM_POSITION_UNSPECIFIED" : Content instream position is
  /// not specified in this version. This enum is a place holder for a default
  /// value and does not represent a real in stream ad position.
  /// - "CONTENT_INSTREAM_POSITION_PRE_ROLL" : Ads that play before streaming
  /// content.
  /// - "CONTENT_INSTREAM_POSITION_MID_ROLL" : Ads that play between the
  /// beginning and end of streaming content.
  /// - "CONTENT_INSTREAM_POSITION_POST_ROLL" : Ads that play at the end of
  /// streaming content.
  /// - "CONTENT_INSTREAM_POSITION_UNKNOWN" : Ads instream position is unknown.
  core.String? contentInstreamPosition;

  /// The targeting_option_id field when targeting_type is
  /// `TARGETING_TYPE_CONTENT_INSTREAM_POSITION`.
  ///
  /// Required.
  core.String? targetingOptionId;

  ContentInstreamPositionAssignedTargetingOptionDetails();

  ContentInstreamPositionAssignedTargetingOptionDetails.fromJson(
      core.Map _json) {
    if (_json.containsKey('adType')) {
      adType = _json['adType'] as core.String;
    }
    if (_json.containsKey('contentInstreamPosition')) {
      contentInstreamPosition = _json['contentInstreamPosition'] as core.String;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adType != null) 'adType': adType!,
        if (contentInstreamPosition != null)
          'contentInstreamPosition': contentInstreamPosition!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable content instream position, which could be used by
/// video and audio ads.
///
/// This will be populated in the content_instream_position_details field when
/// targeting_type is `TARGETING_TYPE_CONTENT_INSTREAM_POSITION`.
class ContentInstreamPositionTargetingOptionDetails {
  /// The content instream position.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "CONTENT_INSTREAM_POSITION_UNSPECIFIED" : Content instream position is
  /// not specified in this version. This enum is a place holder for a default
  /// value and does not represent a real in stream ad position.
  /// - "CONTENT_INSTREAM_POSITION_PRE_ROLL" : Ads that play before streaming
  /// content.
  /// - "CONTENT_INSTREAM_POSITION_MID_ROLL" : Ads that play between the
  /// beginning and end of streaming content.
  /// - "CONTENT_INSTREAM_POSITION_POST_ROLL" : Ads that play at the end of
  /// streaming content.
  /// - "CONTENT_INSTREAM_POSITION_UNKNOWN" : Ads instream position is unknown.
  core.String? contentInstreamPosition;

  ContentInstreamPositionTargetingOptionDetails();

  ContentInstreamPositionTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('contentInstreamPosition')) {
      contentInstreamPosition = _json['contentInstreamPosition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentInstreamPosition != null)
          'contentInstreamPosition': contentInstreamPosition!,
      };
}

/// Assigned content outstream position targeting option details.
///
/// This will be populated in the content_outstream_position_details field when
/// targeting_type is `TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION`.
class ContentOutstreamPositionAssignedTargetingOptionDetails {
  /// The ad type to target.
  ///
  /// Only applicable to insertion order targeting and new line items supporting
  /// the specified ad type will inherit this targeting option by default.
  /// Possible values are: * `AD_TYPE_DISPLAY`, the setting will be inherited by
  /// new line item when line_item_type is `LINE_ITEM_TYPE_DISPLAY_DEFAULT`. *
  /// `AD_TYPE_VIDEO`, the setting will be inherited by new line item when
  /// line_item_type is `LINE_ITEM_TYPE_VIDEO_DEFAULT`.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "AD_TYPE_UNSPECIFIED" : Ad type is not specified or is unknown in this
  /// version.
  /// - "AD_TYPE_DISPLAY" : Display creatives, e.g. image and HTML5.
  /// - "AD_TYPE_VIDEO" : Video creatives, e.g. video ads that play during
  /// streaming content in video players.
  /// - "AD_TYPE_AUDIO" : Audio creatives, e.g. audio ads that play during audio
  /// content.
  core.String? adType;

  /// The content outstream position.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "CONTENT_OUTSTREAM_POSITION_UNSPECIFIED" : Content outstream position is
  /// not specified in this version. This enum is a place holder for a default
  /// value and does not represent a real content outstream position.
  /// - "CONTENT_OUTSTREAM_POSITION_UNKNOWN" : The ad position is unknown in the
  /// content outstream.
  /// - "CONTENT_OUTSTREAM_POSITION_IN_ARTICLE" : Ads that appear between the
  /// paragraphs of your pages.
  /// - "CONTENT_OUTSTREAM_POSITION_IN_BANNER" : Ads that display on the top and
  /// the sides of a page.
  /// - "CONTENT_OUTSTREAM_POSITION_IN_FEED" : Ads that appear in a scrollable
  /// stream of content. A feed is typically editorial (e.g. a list of articles
  /// or news) or listings (e.g. a list of products or services).
  /// - "CONTENT_OUTSTREAM_POSITION_INTERSTITIAL" : Ads shown before or between
  /// content loads.
  core.String? contentOutstreamPosition;

  /// The targeting_option_id field when targeting_type is
  /// `TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION`.
  ///
  /// Required.
  core.String? targetingOptionId;

  ContentOutstreamPositionAssignedTargetingOptionDetails();

  ContentOutstreamPositionAssignedTargetingOptionDetails.fromJson(
      core.Map _json) {
    if (_json.containsKey('adType')) {
      adType = _json['adType'] as core.String;
    }
    if (_json.containsKey('contentOutstreamPosition')) {
      contentOutstreamPosition =
          _json['contentOutstreamPosition'] as core.String;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adType != null) 'adType': adType!,
        if (contentOutstreamPosition != null)
          'contentOutstreamPosition': contentOutstreamPosition!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable content outstream position, which could be used by
/// display and video ads.
///
/// This will be populated in the content_outstream_position_details field when
/// targeting_type is `TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION`.
class ContentOutstreamPositionTargetingOptionDetails {
  /// The content outstream position.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "CONTENT_OUTSTREAM_POSITION_UNSPECIFIED" : Content outstream position is
  /// not specified in this version. This enum is a place holder for a default
  /// value and does not represent a real content outstream position.
  /// - "CONTENT_OUTSTREAM_POSITION_UNKNOWN" : The ad position is unknown in the
  /// content outstream.
  /// - "CONTENT_OUTSTREAM_POSITION_IN_ARTICLE" : Ads that appear between the
  /// paragraphs of your pages.
  /// - "CONTENT_OUTSTREAM_POSITION_IN_BANNER" : Ads that display on the top and
  /// the sides of a page.
  /// - "CONTENT_OUTSTREAM_POSITION_IN_FEED" : Ads that appear in a scrollable
  /// stream of content. A feed is typically editorial (e.g. a list of articles
  /// or news) or listings (e.g. a list of products or services).
  /// - "CONTENT_OUTSTREAM_POSITION_INTERSTITIAL" : Ads shown before or between
  /// content loads.
  core.String? contentOutstreamPosition;

  ContentOutstreamPositionTargetingOptionDetails();

  ContentOutstreamPositionTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('contentOutstreamPosition')) {
      contentOutstreamPosition =
          _json['contentOutstreamPosition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentOutstreamPosition != null)
          'contentOutstreamPosition': contentOutstreamPosition!,
      };
}

/// Settings that control how conversions are counted.
///
/// All post-click conversions will be counted. A percentage value can be set
/// for post-view conversions counting.
class ConversionCountingConfig {
  /// The Floodlight activity configs used to track conversions.
  ///
  /// The number of conversions counted is the sum of all of the conversions
  /// counted by all of the Floodlight activity IDs specified in this field.
  core.List<TrackingFloodlightActivityConfig>? floodlightActivityConfigs;

  /// The percentage of post-view conversions to count, in millis (1/1000 of a
  /// percent).
  ///
  /// Must be between 0 and 100000 inclusive. For example, to track 50% of the
  /// post-click conversions, set a value of 50000.
  core.String? postViewCountPercentageMillis;

  ConversionCountingConfig();

  ConversionCountingConfig.fromJson(core.Map _json) {
    if (_json.containsKey('floodlightActivityConfigs')) {
      floodlightActivityConfigs =
          (_json['floodlightActivityConfigs'] as core.List)
              .map<TrackingFloodlightActivityConfig>((value) =>
                  TrackingFloodlightActivityConfig.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('postViewCountPercentageMillis')) {
      postViewCountPercentageMillis =
          _json['postViewCountPercentageMillis'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (floodlightActivityConfigs != null)
          'floodlightActivityConfigs': floodlightActivityConfigs!
              .map((value) => value.toJson())
              .toList(),
        if (postViewCountPercentageMillis != null)
          'postViewCountPercentageMillis': postViewCountPercentageMillis!,
      };
}

/// Counter event of the creative.
class CounterEvent {
  /// The name of the counter event.
  ///
  /// Required.
  core.String? name;

  /// The name used to identify this counter event in reports.
  ///
  /// Required.
  core.String? reportingName;

  CounterEvent();

  CounterEvent.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('reportingName')) {
      reportingName = _json['reportingName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (reportingName != null) 'reportingName': reportingName!,
      };
}

/// A request message for CreateAsset.
class CreateAssetRequest {
  /// The filename of the asset, including the file extension.
  ///
  /// The filename must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? filename;

  CreateAssetRequest();

  CreateAssetRequest.fromJson(core.Map _json) {
    if (_json.containsKey('filename')) {
      filename = _json['filename'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filename != null) 'filename': filename!,
      };
}

/// A response message for CreateAsset.
class CreateAssetResponse {
  /// The uploaded asset, if successful.
  Asset? asset;

  CreateAssetResponse();

  CreateAssetResponse.fromJson(core.Map _json) {
    if (_json.containsKey('asset')) {
      asset =
          Asset.fromJson(_json['asset'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (asset != null) 'asset': asset!.toJson(),
      };
}

/// A request listing which assigned targeting options of a given targeting type
/// should be created and added.
class CreateAssignedTargetingOptionsRequest {
  /// The assigned targeting options to create and add.
  ///
  /// Required.
  core.List<AssignedTargetingOption>? assignedTargetingOptions;

  /// Identifies the type of this assigned targeting option.
  ///
  /// Required.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  core.String? targetingType;

  CreateAssignedTargetingOptionsRequest();

  CreateAssignedTargetingOptionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('assignedTargetingOptions')) {
      assignedTargetingOptions =
          (_json['assignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('targetingType')) {
      targetingType = _json['targetingType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedTargetingOptions != null)
          'assignedTargetingOptions':
              assignedTargetingOptions!.map((value) => value.toJson()).toList(),
        if (targetingType != null) 'targetingType': targetingType!,
      };
}

/// Request message for \[SdfDownloadTaskService.CreateSdfDownloadTask\].
class CreateSdfDownloadTaskRequest {
  /// The ID of the advertiser to download SDF for.
  core.String? advertiserId;

  /// Filters on entities by their entity IDs.
  IdFilter? idFilter;

  /// Filters on Inventory Sources by their IDs.
  InventorySourceFilter? inventorySourceFilter;

  /// Filters on selected file types.
  ///
  /// The entities in each file are filtered by a chosen set of filter entities.
  /// The filter entities must be the same type as, or a parent type of, the
  /// selected file types.
  ParentEntityFilter? parentEntityFilter;

  /// The ID of the partner to download SDF for.
  core.String? partnerId;

  /// The SDF version of the downloaded file.
  ///
  /// If set to `SDF_VERSION_UNSPECIFIED`, this will default to the version
  /// specified by the advertiser or partner identified by `root_id`. An
  /// advertiser inherits its SDF version from its partner unless configured
  /// otherwise.
  ///
  /// Required.
  /// Possible string values are:
  /// - "SDF_VERSION_UNSPECIFIED" : SDF version value is not specified or is
  /// unknown in this version.
  /// - "SDF_VERSION_3_1" : SDF version 3.1
  /// - "SDF_VERSION_4" : SDF version 4
  /// - "SDF_VERSION_4_1" : SDF version 4.1
  /// - "SDF_VERSION_4_2" : SDF version 4.2
  /// - "SDF_VERSION_5" : SDF version 5.
  /// - "SDF_VERSION_5_1" : SDF version 5.1
  /// - "SDF_VERSION_5_2" : SDF version 5.2
  /// - "SDF_VERSION_5_3" : SDF version 5.3
  core.String? version;

  CreateSdfDownloadTaskRequest();

  CreateSdfDownloadTaskRequest.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('idFilter')) {
      idFilter = IdFilter.fromJson(
          _json['idFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inventorySourceFilter')) {
      inventorySourceFilter = InventorySourceFilter.fromJson(
          _json['inventorySourceFilter']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('parentEntityFilter')) {
      parentEntityFilter = ParentEntityFilter.fromJson(
          _json['parentEntityFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('partnerId')) {
      partnerId = _json['partnerId'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (idFilter != null) 'idFilter': idFilter!.toJson(),
        if (inventorySourceFilter != null)
          'inventorySourceFilter': inventorySourceFilter!.toJson(),
        if (parentEntityFilter != null)
          'parentEntityFilter': parentEntityFilter!.toJson(),
        if (partnerId != null) 'partnerId': partnerId!,
        if (version != null) 'version': version!,
      };
}

/// A single Creative.
class Creative {
  /// Additional dimensions.
  ///
  /// Applicable when creative_type is one of: * `CREATIVE_TYPE_STANDARD` *
  /// `CREATIVE_TYPE_EXPANDABLE` * `CREATIVE_TYPE_NATIVE` *
  /// `CREATIVE_TYPE_TEMPLATED_APP_INSTALL` * `CREATIVE_TYPE_NATIVE_SITE_SQUARE`
  /// * `CREATIVE_TYPE_LIGHTBOX` * `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE` *
  /// `CREATIVE_TYPE_PUBLISHER_HOSTED` If this field is specified, width_pixels
  /// and height_pixels are both required and must be greater than or equal to
  /// 0.
  core.List<Dimensions>? additionalDimensions;

  /// The unique ID of the advertiser the creative belongs to.
  ///
  /// Output only.
  core.String? advertiserId;

  /// Third-party HTML tracking tag to be appended to the creative tag.
  core.String? appendedTag;

  /// Assets associated to this creative.
  ///
  /// Assets can be associated to the creative in one of following roles: *
  /// `ASSET_ROLE_UNSPECIFIED` * `ASSET_ROLE_MAIN` * `ASSET_ROLE_BACKUP` *
  /// `ASSET_ROLE_POLITE_LOAD`
  ///
  /// Required.
  core.List<AssetAssociation>? assets;

  /// The unique ID of the Campaign Manager 360 placement associated with the
  /// creative.
  ///
  /// This field is only applicable for creatives that are synced from Campaign
  /// Manager.
  ///
  /// Output only.
  core.String? cmPlacementId;

  /// The Campaign Manager 360 tracking ad associated with the creative.
  ///
  /// Optional for the following creative_type when created by an advertiser
  /// that uses both Campaign Manager 360 and third-party ad serving: *
  /// `CREATIVE_TYPE_NATIVE` * `CREATIVE_TYPE_NATIVE_SITE_SQUARE` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE` Output only for other cases.
  CmTrackingAd? cmTrackingAd;

  /// The IDs of companion creatives for a video creative.
  ///
  /// You can assign existing display creatives (with image or HTML5 assets) to
  /// serve surrounding the publisher's video player. Companions display around
  /// the video player while the video is playing and remain after the video has
  /// completed. Creatives contain additional dimensions can not be companion
  /// creatives. This field is only supported for following creative_type: *
  /// `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_VIDEO`
  core.List<core.String>? companionCreativeIds;

  /// Counter events for a rich media creative.
  ///
  /// Counters track the number of times that a user interacts with any part of
  /// a rich media creative in a specified way (mouse-overs, mouse-outs, clicks,
  /// taps, data loading, keyboard entries, etc.). Any event that can be
  /// captured in the creative can be recorded as a counter. Leave it empty or
  /// unset for creatives containing image assets only.
  core.List<CounterEvent>? counterEvents;

  /// The timestamp when the creative was created.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? createTime;

  /// A list of attributes of the creative that is generated by the system.
  ///
  /// Output only.
  core.List<core.String>? creativeAttributes;

  /// The unique ID of the creative.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? creativeId;

  /// The type of the creative.
  ///
  /// Required. Immutable.
  /// Possible string values are:
  /// - "CREATIVE_TYPE_UNSPECIFIED" : Type value is not specified or is unknown
  /// in this version.
  /// - "CREATIVE_TYPE_STANDARD" : Standard display creative. Create and update
  /// methods are supported for this creative type if the hosting_source is one
  /// of the following: * `HOSTING_SOURCE_HOSTED` * `HOSTING_SOURCE_THIRD_PARTY`
  /// - "CREATIVE_TYPE_EXPANDABLE" : Expandable creative. Create and update
  /// methods are supported for this creative type if the hosting_source is
  /// `HOSTING_SOURCE_THIRD_PARTY`
  /// - "CREATIVE_TYPE_VIDEO" : Video creative. Create and update methods are
  /// supported for this creative type if the hosting_source is one of the
  /// following: * `HOSTING_SOURCE_HOSTED` * `HOSTING_SOURCE_THIRD_PARTY`
  /// - "CREATIVE_TYPE_NATIVE" : Native creative rendered by publishers with
  /// assets from advertiser. Create and update methods are supported for this
  /// creative type if the hosting_source is `HOSTING_SOURCE_HOSTED`
  /// - "CREATIVE_TYPE_TEMPLATED_APP_INSTALL" : Templated app install mobile
  /// creative (banner). Create and update methods are **not** supported for
  /// this creative type.
  /// - "CREATIVE_TYPE_NATIVE_SITE_SQUARE" : Square native creative. Create and
  /// update methods are supported for this creative type if the hosting_source
  /// is `HOSTING_SOURCE_HOSTED`
  /// - "CREATIVE_TYPE_TEMPLATED_APP_INSTALL_INTERSTITIAL" : Interstitial
  /// creative including both display and video. Create and update methods are
  /// **not** supported for this creative type.
  /// - "CREATIVE_TYPE_LIGHTBOX" : Responsive and expandable Lightbox creative.
  /// Create and update methods are **not** supported for this creative type.
  /// - "CREATIVE_TYPE_NATIVE_APP_INSTALL" : Native app install creative. Create
  /// and update methods are supported for this creative type if the
  /// hosting_source is `HOSTING_SOURCE_HOSTED`
  /// - "CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE" : Square native app install
  /// creative. Create and update methods are supported for this creative type
  /// if the hosting_source is `HOSTING_SOURCE_HOSTED`
  /// - "CREATIVE_TYPE_AUDIO" : Audio creative. Create and update methods are
  /// supported for this creative type if the hosting_source is
  /// `HOSTING_SOURCE_HOSTED`
  /// - "CREATIVE_TYPE_PUBLISHER_HOSTED" : Publisher hosted creative. Create and
  /// update methods are **not** supported for this creative type.
  /// - "CREATIVE_TYPE_NATIVE_VIDEO" : Native video creative. Create and update
  /// methods are supported for this creative type if the hosting_source is
  /// `HOSTING_SOURCE_HOSTED`
  /// - "CREATIVE_TYPE_TEMPLATED_APP_INSTALL_VIDEO" : Templated app install
  /// mobile video creative. Create and update methods are **not** supported for
  /// this creative type.
  core.String? creativeType;

  /// Primary dimensions of the creative.
  ///
  /// Applicable to all creative types. The value of width_pixels and
  /// height_pixels defaults to `0` when creative_type is one of: *
  /// `CREATIVE_TYPE_VIDEO` * `CREATIVE_TYPE_TEMPLATED_APP_INSTALL_INTERSTITIAL`
  /// * `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_NATIVE_VIDEO` *
  /// `CREATIVE_TYPE_TEMPLATED_APP_INSTALL_VIDEO`
  ///
  /// Required.
  Dimensions? dimensions;

  /// The display name of the creative.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// Indicates whether the creative is dynamic.
  ///
  /// Output only.
  core.bool? dynamic;

  /// Controls whether or not the creative can serve.
  ///
  /// Accepted values are: * `ENTITY_STATUS_ACTIVE` * `ENTITY_STATUS_ARCHIVED` *
  /// `ENTITY_STATUS_PAUSED`
  ///
  /// Required.
  /// Possible string values are:
  /// - "ENTITY_STATUS_UNSPECIFIED" : Default value when status is not specified
  /// or is unknown in this version.
  /// - "ENTITY_STATUS_ACTIVE" : The entity is enabled to bid and spend budget.
  /// - "ENTITY_STATUS_ARCHIVED" : The entity is archived. Bidding and budget
  /// spending are disabled. An entity can be deleted after archived. Deleted
  /// entities cannot be retrieved.
  /// - "ENTITY_STATUS_DRAFT" : The entity is under draft. Bidding and budget
  /// spending are disabled.
  /// - "ENTITY_STATUS_PAUSED" : Bidding and budget spending are paused for the
  /// entity.
  /// - "ENTITY_STATUS_SCHEDULED_FOR_DELETION" : The entity is scheduled for
  /// deletion.
  core.String? entityStatus;

  /// Exit events for this creative.
  ///
  /// An exit (also known as a click tag) is any area in your creative that
  /// someone can click or tap to open an advertiser's landing page. Every
  /// creative must include at least one exit. You can add an exit to your
  /// creative in any of the following ways: * Use Google Web Designer's tap
  /// area. * Define a JavaScript variable called "clickTag". * Use the Enabler
  /// (Enabler.exit()) to track exits in rich media formats.
  ///
  /// Required.
  core.List<ExitEvent>? exitEvents;

  /// Indicates the creative will automatically expand on hover.
  ///
  /// Optional and only valid for third-party expandable creatives. Third-party
  /// expandable creatives are creatives with following hosting source: *
  /// `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: *
  /// `CREATIVE_TYPE_EXPANDABLE`
  ///
  /// Optional.
  core.bool? expandOnHover;

  /// Specifies the expanding direction of the creative.
  ///
  /// Required and only valid for third-party expandable creatives. Third-party
  /// expandable creatives are creatives with following hosting source: *
  /// `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: *
  /// `CREATIVE_TYPE_EXPANDABLE`
  ///
  /// Optional.
  /// Possible string values are:
  /// - "EXPANDING_DIRECTION_UNSPECIFIED" : The expanding direction is not
  /// specified.
  /// - "EXPANDING_DIRECTION_NONE" : Does not expand in any direction.
  /// - "EXPANDING_DIRECTION_UP" : Expands up.
  /// - "EXPANDING_DIRECTION_DOWN" : Expands down.
  /// - "EXPANDING_DIRECTION_LEFT" : Expands left.
  /// - "EXPANDING_DIRECTION_RIGHT" : Expands right.
  /// - "EXPANDING_DIRECTION_UP_AND_LEFT" : Expands up and to the left side.
  /// - "EXPANDING_DIRECTION_UP_AND_RIGHT" : Expands up and to the right side.
  /// - "EXPANDING_DIRECTION_DOWN_AND_LEFT" : Expands down and to the left side.
  /// - "EXPANDING_DIRECTION_DOWN_AND_RIGHT" : Expands down and to the right
  /// side.
  /// - "EXPANDING_DIRECTION_UP_OR_DOWN" : Expands either up or down.
  /// - "EXPANDING_DIRECTION_LEFT_OR_RIGHT" : Expands to either the left or the
  /// right side.
  /// - "EXPANDING_DIRECTION_ANY_DIAGONAL" : Can expand in any diagonal
  /// direction.
  core.String? expandingDirection;

  /// Indicates where the creative is hosted.
  ///
  /// Required.
  /// Possible string values are:
  /// - "HOSTING_SOURCE_UNSPECIFIED" : Hosting source is not specified or is
  /// unknown in this version.
  /// - "HOSTING_SOURCE_CM" : A creative synced from Campaign Manager 360.
  /// Create and update methods are **not** supported for this hosting type.
  /// - "HOSTING_SOURCE_THIRD_PARTY" : A creative hosted by a third-party ad
  /// server (3PAS). Create and update methods are supported for this hosting
  /// type if the creative_type is one of the following: * `CREATIVE_TYPE_AUDIO`
  /// * `CREATIVE_TYPE_EXPANDABLE` * `CREATIVE_TYPE_STANDARD` *
  /// `CREATIVE_TYPE_VIDEO`
  /// - "HOSTING_SOURCE_HOSTED" : A creative created in DV360 and hosted by
  /// Campaign Manager 360. Create and update methods are supported for this
  /// hosting type if the creative_type is one of the following: *
  /// `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_NATIVE` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE` *
  /// `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO` *
  /// `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_VIDEO`
  /// - "HOSTING_SOURCE_RICH_MEDIA" : A rich media creative created in Studio
  /// and hosted by Campaign Manager 360. Create and update methods are **not**
  /// supported for this hosting type.
  core.String? hostingSource;

  /// Indicates the third-party VAST tag creative requires HTML5 Video support.
  ///
  /// Output only and only valid for third-party VAST tag creatives. Third-party
  /// VAST tag creatives are creatives with following hosting_source: *
  /// `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: *
  /// `CREATIVE_TYPE_VIDEO`
  ///
  /// Output only.
  core.bool? html5Video;

  /// Indicates whether Integral Ad Science (IAS) campaign monitoring is
  /// enabled.
  ///
  /// To enable this for the creative, make sure the
  /// Advertiser.creative_config.ias_client_id has been set to your IAS client
  /// ID.
  core.bool? iasCampaignMonitoring;

  /// ID information used to link this creative to an external system.
  ///
  /// Must be UTF-8 encoded with a length of no more than 10,000 characters.
  core.String? integrationCode;

  /// JavaScript measurement URL from supported third-party verification
  /// providers (ComScore, DoubleVerify, IAS, Moat).
  ///
  /// HTML script tags are not supported. This field is only supported in
  /// following creative_type: * `CREATIVE_TYPE_NATIVE` *
  /// `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  core.String? jsTrackerUrl;

  /// The IDs of the line items this creative is associated with.
  ///
  /// To associate a creative to a line item, use LineItem.creative_ids instead.
  ///
  /// Output only.
  core.List<core.String>? lineItemIds;

  /// Media duration of the creative.
  ///
  /// Applicable when creative_type is one of: * `CREATIVE_TYPE_VIDEO` *
  /// `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_NATIVE_VIDEO` *
  /// `CREATIVE_TYPE_PUBLISHER_HOSTED`
  ///
  /// Output only.
  core.String? mediaDuration;

  /// Indicates the third-party audio creative supports MP3.
  ///
  /// Output only and only valid for third-party audio creatives. Third-party
  /// audio creatives are creatives with following hosting_source: *
  /// `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: *
  /// `CREATIVE_TYPE_AUDIO`
  ///
  /// Output only.
  core.bool? mp3Audio;

  /// The resource name of the creative.
  ///
  /// Output only.
  core.String? name;

  /// User notes for this creative.
  ///
  /// Must be UTF-8 encoded with a length of no more than 20,000 characters.
  core.String? notes;

  /// Specifies the OBA icon for a video creative.
  ///
  /// This field is only supported in following creative_type: *
  /// `CREATIVE_TYPE_VIDEO`
  ObaIcon? obaIcon;

  /// Indicates the third-party audio creative supports OGG.
  ///
  /// Output only and only valid for third-party audio creatives. Third-party
  /// audio creatives are creatives with following hosting_source: *
  /// `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: *
  /// `CREATIVE_TYPE_AUDIO`
  ///
  /// Output only.
  core.bool? oggAudio;

  /// Amount of time to play the video before counting a view.
  ///
  /// This field is required when skippable is true. This field is only
  /// supported for the following creative_type: * `CREATIVE_TYPE_VIDEO`
  AudioVideoOffset? progressOffset;

  /// Indicates that the creative relies on HTML5 to render properly.
  ///
  /// Optional and only valid for third-party tag creatives. Third-party tag
  /// creatives are creatives with following hosting_source: *
  /// `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: *
  /// `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE`
  ///
  /// Optional.
  core.bool? requireHtml5;

  /// Indicates that the creative requires MRAID (Mobile Rich Media Ad Interface
  /// Definitions system).
  ///
  /// Set this if the creative relies on mobile gestures for interactivity, such
  /// as swiping or tapping. Optional and only valid for third-party tag
  /// creatives. Third-party tag creatives are creatives with following
  /// hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following
  /// creative_type: * `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE`
  ///
  /// Optional.
  core.bool? requireMraid;

  /// Indicates that the creative will wait for a return ping for attribution.
  ///
  /// Only valid when using a Campaign Manager 360 tracking ad with a
  /// third-party ad server parameter and the ${DC_DBM_TOKEN} macro. Optional
  /// and only valid for third-party tag creatives or third-party VAST tag
  /// creatives. Third-party tag creatives are creatives with following
  /// hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following
  /// creative_type: * `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE`
  /// Third-party VAST tag creatives are creatives with following
  /// hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following
  /// creative_type: * `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_VIDEO`
  ///
  /// Optional.
  core.bool? requirePingForAttribution;

  /// The current status of the creative review process.
  ///
  /// Output only.
  ReviewStatusInfo? reviewStatus;

  /// Amount of time to play the video before the skip button appears.
  ///
  /// This field is required when skippable is true. This field is only
  /// supported for the following creative_type: * `CREATIVE_TYPE_VIDEO`
  AudioVideoOffset? skipOffset;

  /// Whether the user can choose to skip a video creative.
  ///
  /// This field is only supported for the following creative_type: *
  /// `CREATIVE_TYPE_VIDEO`
  core.bool? skippable;

  /// The original third-party tag used for the creative.
  ///
  /// Required and only valid for third-party tag creatives. Third-party tag
  /// creatives are creatives with following hosting_source: *
  /// `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: *
  /// `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE`
  ///
  /// Optional.
  core.String? thirdPartyTag;

  /// Tracking URLs from third parties to track interactions with a video
  /// creative.
  ///
  /// This field is only supported for the following creative_type: *
  /// `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_VIDEO` *
  /// `CREATIVE_TYPE_NATIVE_VIDEO`
  core.List<ThirdPartyUrl>? thirdPartyUrls;

  /// Timer custom events for a rich media creative.
  ///
  /// Timers track the time during which a user views and interacts with a
  /// specified part of a rich media creative. A creative can have multiple
  /// timer events, each timed independently. Leave it empty or unset for
  /// creatives containing image assets only.
  core.List<TimerEvent>? timerEvents;

  /// Tracking URLs for analytics providers or third-party ad technology
  /// vendors.
  ///
  /// The URLs must start with https (except on inventory that doesn't require
  /// SSL compliance). If using macros in your URL, use only macros supported by
  /// Display & Video 360. Standard URLs only, no IMG or SCRIPT tags. This field
  /// is only supported in following creative_type: * `CREATIVE_TYPE_NATIVE` *
  /// `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_APP_INSTALL` *
  /// `CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  core.List<core.String>? trackerUrls;

  /// Audio/Video transcodes.
  ///
  /// Display & Video 360 transcodes the main asset into a number of alternative
  /// versions that use different file formats or have different properties
  /// (resolution, audio bit rate, and video bit rate), each designed for
  /// specific video players or bandwidths. These transcodes give a publisher's
  /// system more options to choose from for each impression on your video and
  /// ensures that the appropriate file serves based on the viewer’s connection
  /// and screen size. This field is only supported in following creative_type:
  /// * `CREATIVE_TYPE_VIDEO` * `CREATIVE_TYPE_NATIVE_VIDEO` *
  /// `CREATIVE_TYPE_AUDIO`
  ///
  /// Output only.
  core.List<Transcode>? transcodes;

  /// An optional creative identifier provided by a registry that is unique
  /// across all platforms.
  ///
  /// Universal Ad ID is part of the VAST 4.0 standard. It can be modified after
  /// the creative is created. This field is only supported for the following
  /// creative_type: * `CREATIVE_TYPE_VIDEO`
  ///
  /// Optional.
  UniversalAdId? universalAdId;

  /// The timestamp when the creative was last updated.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? updateTime;

  /// The URL of the VAST tag for a third-party VAST tag creative.
  ///
  /// Required and only valid for third-party VAST tag creatives. Third-party
  /// VAST tag creatives are creatives with following hosting_source: *
  /// `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: *
  /// `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_VIDEO`
  ///
  /// Optional.
  core.String? vastTagUrl;

  /// Indicates the third-party VAST tag creative requires VPAID (Digital Video
  /// Player-Ad Interface).
  ///
  /// Output only and only valid for third-party VAST tag creatives. Third-party
  /// VAST tag creatives are creatives with following hosting_source: *
  /// `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: *
  /// `CREATIVE_TYPE_VIDEO`
  ///
  /// Output only.
  core.bool? vpaid;

  Creative();

  Creative.fromJson(core.Map _json) {
    if (_json.containsKey('additionalDimensions')) {
      additionalDimensions = (_json['additionalDimensions'] as core.List)
          .map<Dimensions>((value) =>
              Dimensions.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('appendedTag')) {
      appendedTag = _json['appendedTag'] as core.String;
    }
    if (_json.containsKey('assets')) {
      assets = (_json['assets'] as core.List)
          .map<AssetAssociation>((value) => AssetAssociation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('cmPlacementId')) {
      cmPlacementId = _json['cmPlacementId'] as core.String;
    }
    if (_json.containsKey('cmTrackingAd')) {
      cmTrackingAd = CmTrackingAd.fromJson(
          _json['cmTrackingAd'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('companionCreativeIds')) {
      companionCreativeIds = (_json['companionCreativeIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('counterEvents')) {
      counterEvents = (_json['counterEvents'] as core.List)
          .map<CounterEvent>((value) => CounterEvent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('creativeAttributes')) {
      creativeAttributes = (_json['creativeAttributes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('creativeId')) {
      creativeId = _json['creativeId'] as core.String;
    }
    if (_json.containsKey('creativeType')) {
      creativeType = _json['creativeType'] as core.String;
    }
    if (_json.containsKey('dimensions')) {
      dimensions = Dimensions.fromJson(
          _json['dimensions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('dynamic')) {
      dynamic = _json['dynamic'] as core.bool;
    }
    if (_json.containsKey('entityStatus')) {
      entityStatus = _json['entityStatus'] as core.String;
    }
    if (_json.containsKey('exitEvents')) {
      exitEvents = (_json['exitEvents'] as core.List)
          .map<ExitEvent>((value) =>
              ExitEvent.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('expandOnHover')) {
      expandOnHover = _json['expandOnHover'] as core.bool;
    }
    if (_json.containsKey('expandingDirection')) {
      expandingDirection = _json['expandingDirection'] as core.String;
    }
    if (_json.containsKey('hostingSource')) {
      hostingSource = _json['hostingSource'] as core.String;
    }
    if (_json.containsKey('html5Video')) {
      html5Video = _json['html5Video'] as core.bool;
    }
    if (_json.containsKey('iasCampaignMonitoring')) {
      iasCampaignMonitoring = _json['iasCampaignMonitoring'] as core.bool;
    }
    if (_json.containsKey('integrationCode')) {
      integrationCode = _json['integrationCode'] as core.String;
    }
    if (_json.containsKey('jsTrackerUrl')) {
      jsTrackerUrl = _json['jsTrackerUrl'] as core.String;
    }
    if (_json.containsKey('lineItemIds')) {
      lineItemIds = (_json['lineItemIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('mediaDuration')) {
      mediaDuration = _json['mediaDuration'] as core.String;
    }
    if (_json.containsKey('mp3Audio')) {
      mp3Audio = _json['mp3Audio'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('notes')) {
      notes = _json['notes'] as core.String;
    }
    if (_json.containsKey('obaIcon')) {
      obaIcon = ObaIcon.fromJson(
          _json['obaIcon'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('oggAudio')) {
      oggAudio = _json['oggAudio'] as core.bool;
    }
    if (_json.containsKey('progressOffset')) {
      progressOffset = AudioVideoOffset.fromJson(
          _json['progressOffset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('requireHtml5')) {
      requireHtml5 = _json['requireHtml5'] as core.bool;
    }
    if (_json.containsKey('requireMraid')) {
      requireMraid = _json['requireMraid'] as core.bool;
    }
    if (_json.containsKey('requirePingForAttribution')) {
      requirePingForAttribution =
          _json['requirePingForAttribution'] as core.bool;
    }
    if (_json.containsKey('reviewStatus')) {
      reviewStatus = ReviewStatusInfo.fromJson(
          _json['reviewStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('skipOffset')) {
      skipOffset = AudioVideoOffset.fromJson(
          _json['skipOffset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('skippable')) {
      skippable = _json['skippable'] as core.bool;
    }
    if (_json.containsKey('thirdPartyTag')) {
      thirdPartyTag = _json['thirdPartyTag'] as core.String;
    }
    if (_json.containsKey('thirdPartyUrls')) {
      thirdPartyUrls = (_json['thirdPartyUrls'] as core.List)
          .map<ThirdPartyUrl>((value) => ThirdPartyUrl.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('timerEvents')) {
      timerEvents = (_json['timerEvents'] as core.List)
          .map<TimerEvent>((value) =>
              TimerEvent.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('trackerUrls')) {
      trackerUrls = (_json['trackerUrls'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('transcodes')) {
      transcodes = (_json['transcodes'] as core.List)
          .map<Transcode>((value) =>
              Transcode.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('universalAdId')) {
      universalAdId = UniversalAdId.fromJson(
          _json['universalAdId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('vastTagUrl')) {
      vastTagUrl = _json['vastTagUrl'] as core.String;
    }
    if (_json.containsKey('vpaid')) {
      vpaid = _json['vpaid'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalDimensions != null)
          'additionalDimensions':
              additionalDimensions!.map((value) => value.toJson()).toList(),
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (appendedTag != null) 'appendedTag': appendedTag!,
        if (assets != null)
          'assets': assets!.map((value) => value.toJson()).toList(),
        if (cmPlacementId != null) 'cmPlacementId': cmPlacementId!,
        if (cmTrackingAd != null) 'cmTrackingAd': cmTrackingAd!.toJson(),
        if (companionCreativeIds != null)
          'companionCreativeIds': companionCreativeIds!,
        if (counterEvents != null)
          'counterEvents':
              counterEvents!.map((value) => value.toJson()).toList(),
        if (createTime != null) 'createTime': createTime!,
        if (creativeAttributes != null)
          'creativeAttributes': creativeAttributes!,
        if (creativeId != null) 'creativeId': creativeId!,
        if (creativeType != null) 'creativeType': creativeType!,
        if (dimensions != null) 'dimensions': dimensions!.toJson(),
        if (displayName != null) 'displayName': displayName!,
        if (dynamic != null) 'dynamic': dynamic!,
        if (entityStatus != null) 'entityStatus': entityStatus!,
        if (exitEvents != null)
          'exitEvents': exitEvents!.map((value) => value.toJson()).toList(),
        if (expandOnHover != null) 'expandOnHover': expandOnHover!,
        if (expandingDirection != null)
          'expandingDirection': expandingDirection!,
        if (hostingSource != null) 'hostingSource': hostingSource!,
        if (html5Video != null) 'html5Video': html5Video!,
        if (iasCampaignMonitoring != null)
          'iasCampaignMonitoring': iasCampaignMonitoring!,
        if (integrationCode != null) 'integrationCode': integrationCode!,
        if (jsTrackerUrl != null) 'jsTrackerUrl': jsTrackerUrl!,
        if (lineItemIds != null) 'lineItemIds': lineItemIds!,
        if (mediaDuration != null) 'mediaDuration': mediaDuration!,
        if (mp3Audio != null) 'mp3Audio': mp3Audio!,
        if (name != null) 'name': name!,
        if (notes != null) 'notes': notes!,
        if (obaIcon != null) 'obaIcon': obaIcon!.toJson(),
        if (oggAudio != null) 'oggAudio': oggAudio!,
        if (progressOffset != null) 'progressOffset': progressOffset!.toJson(),
        if (requireHtml5 != null) 'requireHtml5': requireHtml5!,
        if (requireMraid != null) 'requireMraid': requireMraid!,
        if (requirePingForAttribution != null)
          'requirePingForAttribution': requirePingForAttribution!,
        if (reviewStatus != null) 'reviewStatus': reviewStatus!.toJson(),
        if (skipOffset != null) 'skipOffset': skipOffset!.toJson(),
        if (skippable != null) 'skippable': skippable!,
        if (thirdPartyTag != null) 'thirdPartyTag': thirdPartyTag!,
        if (thirdPartyUrls != null)
          'thirdPartyUrls':
              thirdPartyUrls!.map((value) => value.toJson()).toList(),
        if (timerEvents != null)
          'timerEvents': timerEvents!.map((value) => value.toJson()).toList(),
        if (trackerUrls != null) 'trackerUrls': trackerUrls!,
        if (transcodes != null)
          'transcodes': transcodes!.map((value) => value.toJson()).toList(),
        if (universalAdId != null) 'universalAdId': universalAdId!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
        if (vastTagUrl != null) 'vastTagUrl': vastTagUrl!,
        if (vpaid != null) 'vpaid': vpaid!,
      };
}

/// Creative requirements configuration for the inventory source.
class CreativeConfig {
  /// The type of creative that can be assigned to the inventory source.
  /// Possible string values are:
  /// - "CREATIVE_TYPE_UNSPECIFIED" : Type value is not specified or is unknown
  /// in this version.
  /// - "CREATIVE_TYPE_STANDARD" : Standard display creative. Create and update
  /// methods are supported for this creative type if the hosting_source is one
  /// of the following: * `HOSTING_SOURCE_HOSTED` * `HOSTING_SOURCE_THIRD_PARTY`
  /// - "CREATIVE_TYPE_EXPANDABLE" : Expandable creative. Create and update
  /// methods are supported for this creative type if the hosting_source is
  /// `HOSTING_SOURCE_THIRD_PARTY`
  /// - "CREATIVE_TYPE_VIDEO" : Video creative. Create and update methods are
  /// supported for this creative type if the hosting_source is one of the
  /// following: * `HOSTING_SOURCE_HOSTED` * `HOSTING_SOURCE_THIRD_PARTY`
  /// - "CREATIVE_TYPE_NATIVE" : Native creative rendered by publishers with
  /// assets from advertiser. Create and update methods are supported for this
  /// creative type if the hosting_source is `HOSTING_SOURCE_HOSTED`
  /// - "CREATIVE_TYPE_TEMPLATED_APP_INSTALL" : Templated app install mobile
  /// creative (banner). Create and update methods are **not** supported for
  /// this creative type.
  /// - "CREATIVE_TYPE_NATIVE_SITE_SQUARE" : Square native creative. Create and
  /// update methods are supported for this creative type if the hosting_source
  /// is `HOSTING_SOURCE_HOSTED`
  /// - "CREATIVE_TYPE_TEMPLATED_APP_INSTALL_INTERSTITIAL" : Interstitial
  /// creative including both display and video. Create and update methods are
  /// **not** supported for this creative type.
  /// - "CREATIVE_TYPE_LIGHTBOX" : Responsive and expandable Lightbox creative.
  /// Create and update methods are **not** supported for this creative type.
  /// - "CREATIVE_TYPE_NATIVE_APP_INSTALL" : Native app install creative. Create
  /// and update methods are supported for this creative type if the
  /// hosting_source is `HOSTING_SOURCE_HOSTED`
  /// - "CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE" : Square native app install
  /// creative. Create and update methods are supported for this creative type
  /// if the hosting_source is `HOSTING_SOURCE_HOSTED`
  /// - "CREATIVE_TYPE_AUDIO" : Audio creative. Create and update methods are
  /// supported for this creative type if the hosting_source is
  /// `HOSTING_SOURCE_HOSTED`
  /// - "CREATIVE_TYPE_PUBLISHER_HOSTED" : Publisher hosted creative. Create and
  /// update methods are **not** supported for this creative type.
  /// - "CREATIVE_TYPE_NATIVE_VIDEO" : Native video creative. Create and update
  /// methods are supported for this creative type if the hosting_source is
  /// `HOSTING_SOURCE_HOSTED`
  /// - "CREATIVE_TYPE_TEMPLATED_APP_INSTALL_VIDEO" : Templated app install
  /// mobile video creative. Create and update methods are **not** supported for
  /// this creative type.
  core.String? creativeType;

  /// The configuration for display creatives.
  ///
  /// Applicable when creative_type is `CREATIVE_TYPE_STANDARD`.
  InventorySourceDisplayCreativeConfig? displayCreativeConfig;

  /// The configuration for video creatives.
  ///
  /// Applicable when creative_type is `CREATIVE_TYPE_VIDEO`.
  InventorySourceVideoCreativeConfig? videoCreativeConfig;

  CreativeConfig();

  CreativeConfig.fromJson(core.Map _json) {
    if (_json.containsKey('creativeType')) {
      creativeType = _json['creativeType'] as core.String;
    }
    if (_json.containsKey('displayCreativeConfig')) {
      displayCreativeConfig = InventorySourceDisplayCreativeConfig.fromJson(
          _json['displayCreativeConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('videoCreativeConfig')) {
      videoCreativeConfig = InventorySourceVideoCreativeConfig.fromJson(
          _json['videoCreativeConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creativeType != null) 'creativeType': creativeType!,
        if (displayCreativeConfig != null)
          'displayCreativeConfig': displayCreativeConfig!.toJson(),
        if (videoCreativeConfig != null)
          'videoCreativeConfig': videoCreativeConfig!.toJson(),
      };
}

/// A single custom bidding algorithm.
class CustomBiddingAlgorithm {
  /// The unique ID of the advertiser that owns the custom bidding algorithm.
  ///
  /// Immutable.
  core.String? advertiserId;

  /// The unique ID of the custom bidding algorithm.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? customBiddingAlgorithmId;

  /// The type of custom bidding algorithm.
  ///
  /// Required. Immutable.
  /// Possible string values are:
  /// - "CUSTOM_BIDDING_ALGORITHM_TYPE_UNSPECIFIED" : Algorithm type is not
  /// specified or is unknown in this version.
  /// - "SCRIPT_BASED" : Algorithm generated through customer-uploaded custom
  /// bidding script files.
  /// - "ADS_DATA_HUB_BASED" : Algorithm created through Ads Data Hub product.
  core.String? customBiddingAlgorithmType;

  /// The display name of the custom bidding algorithm.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// Controls whether or not the custom bidding algorithm can be used as a
  /// bidding strategy.
  ///
  /// Accepted values are: * `ENTITY_STATUS_ACTIVE` * `ENTITY_STATUS_ARCHIVED`
  /// Possible string values are:
  /// - "ENTITY_STATUS_UNSPECIFIED" : Default value when status is not specified
  /// or is unknown in this version.
  /// - "ENTITY_STATUS_ACTIVE" : The entity is enabled to bid and spend budget.
  /// - "ENTITY_STATUS_ARCHIVED" : The entity is archived. Bidding and budget
  /// spending are disabled. An entity can be deleted after archived. Deleted
  /// entities cannot be retrieved.
  /// - "ENTITY_STATUS_DRAFT" : The entity is under draft. Bidding and budget
  /// spending are disabled.
  /// - "ENTITY_STATUS_PAUSED" : Bidding and budget spending are paused for the
  /// entity.
  /// - "ENTITY_STATUS_SCHEDULED_FOR_DELETION" : The entity is scheduled for
  /// deletion.
  core.String? entityStatus;

  /// The resource name of the custom bidding algorithm.
  ///
  /// Output only.
  core.String? name;

  /// The unique ID of the partner that owns the custom bidding algorithm.
  ///
  /// Immutable.
  core.String? partnerId;

  CustomBiddingAlgorithm();

  CustomBiddingAlgorithm.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('customBiddingAlgorithmId')) {
      customBiddingAlgorithmId =
          _json['customBiddingAlgorithmId'] as core.String;
    }
    if (_json.containsKey('customBiddingAlgorithmType')) {
      customBiddingAlgorithmType =
          _json['customBiddingAlgorithmType'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('entityStatus')) {
      entityStatus = _json['entityStatus'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('partnerId')) {
      partnerId = _json['partnerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (customBiddingAlgorithmId != null)
          'customBiddingAlgorithmId': customBiddingAlgorithmId!,
        if (customBiddingAlgorithmType != null)
          'customBiddingAlgorithmType': customBiddingAlgorithmType!,
        if (displayName != null) 'displayName': displayName!,
        if (entityStatus != null) 'entityStatus': entityStatus!,
        if (name != null) 'name': name!,
        if (partnerId != null) 'partnerId': partnerId!,
      };
}

/// Describes a custom list entity, such as a custom affinity or custom intent
/// audience list.
class CustomList {
  /// The unique ID of the custom list.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? customListId;

  /// The display name of the custom list.
  ///
  /// .
  ///
  /// Output only.
  core.String? displayName;

  /// The resource name of the custom list.
  ///
  /// Output only.
  core.String? name;

  CustomList();

  CustomList.fromJson(core.Map _json) {
    if (_json.containsKey('customListId')) {
      customListId = _json['customListId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customListId != null) 'customListId': customListId!,
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
      };
}

/// Details of custom list group.
///
/// All custom list targeting settings are logically ‘OR’ of each other.
class CustomListGroup {
  /// All custom list targeting settings in custom list group.
  ///
  /// Repeated settings with same id will be ignored.
  ///
  /// Required.
  core.List<CustomListTargetingSetting>? settings;

  CustomListGroup();

  CustomListGroup.fromJson(core.Map _json) {
    if (_json.containsKey('settings')) {
      settings = (_json['settings'] as core.List)
          .map<CustomListTargetingSetting>((value) =>
              CustomListTargetingSetting.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (settings != null)
          'settings': settings!.map((value) => value.toJson()).toList(),
      };
}

/// Details of custom list targeting setting.
class CustomListTargetingSetting {
  /// Custom id of custom list targeting setting.
  ///
  /// This id is custom_list_id.
  ///
  /// Required.
  core.String? customListId;

  CustomListTargetingSetting();

  CustomListTargetingSetting.fromJson(core.Map _json) {
    if (_json.containsKey('customListId')) {
      customListId = _json['customListId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customListId != null) 'customListId': customListId!,
      };
}

/// Represents a whole or partial calendar date, such as a birthday.
///
/// The time of day and time zone are either specified elsewhere or are
/// insignificant. The date is relative to the Gregorian Calendar. This can
/// represent one of the following: * A full date, with non-zero year, month,
/// and day values * A month and day value, with a zero year, such as an
/// anniversary * A year on its own, with zero month and day values * A year and
/// month value, with a zero day, such as a credit card expiration date Related
/// types are google.type.TimeOfDay and `google.protobuf.Timestamp`.
class Date {
  /// Day of a month.
  ///
  /// Must be from 1 to 31 and valid for the year and month, or 0 to specify a
  /// year by itself or a year and month where the day isn't significant.
  core.int? day;

  /// Month of a year.
  ///
  /// Must be from 1 to 12, or 0 to specify a year without a month and day.
  core.int? month;

  /// Year of the date.
  ///
  /// Must be from 1 to 9999, or 0 to specify a date without a year.
  core.int? year;

  Date();

  Date.fromJson(core.Map _json) {
    if (_json.containsKey('day')) {
      day = _json['day'] as core.int;
    }
    if (_json.containsKey('month')) {
      month = _json['month'] as core.int;
    }
    if (_json.containsKey('year')) {
      year = _json['year'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (day != null) 'day': day!,
        if (month != null) 'month': month!,
        if (year != null) 'year': year!,
      };
}

/// A date range.
class DateRange {
  /// The upper bound of the date range, inclusive.
  ///
  /// Must specify a positive value for `year`, `month`, and `day`.
  Date? endDate;

  /// The lower bound of the date range, inclusive.
  ///
  /// Must specify a positive value for `year`, `month`, and `day`.
  Date? startDate;

  DateRange();

  DateRange.fromJson(core.Map _json) {
    if (_json.containsKey('endDate')) {
      endDate = Date.fromJson(
          _json['endDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startDate')) {
      startDate = Date.fromJson(
          _json['startDate'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endDate != null) 'endDate': endDate!.toJson(),
        if (startDate != null) 'startDate': startDate!.toJson(),
      };
}

/// Representation of a segment of time defined on a specific day of the week
/// and with a start and end time.
///
/// The time represented by `start_hour` must be before the time represented by
/// `end_hour`.
class DayAndTimeAssignedTargetingOptionDetails {
  /// The day of the week for this day and time targeting setting.
  ///
  /// Required.
  /// Possible string values are:
  /// - "DAY_OF_WEEK_UNSPECIFIED" : The day of the week is unspecified.
  /// - "MONDAY" : Monday
  /// - "TUESDAY" : Tuesday
  /// - "WEDNESDAY" : Wednesday
  /// - "THURSDAY" : Thursday
  /// - "FRIDAY" : Friday
  /// - "SATURDAY" : Saturday
  /// - "SUNDAY" : Sunday
  core.String? dayOfWeek;

  /// The end hour for day and time targeting.
  ///
  /// Must be between 1 (1 hour after start of day) and 24 (end of day).
  ///
  /// Required.
  core.int? endHour;

  /// The start hour for day and time targeting.
  ///
  /// Must be between 0 (start of day) and 23 (1 hour before end of day).
  ///
  /// Required.
  core.int? startHour;

  /// The mechanism used to determine which timezone to use for this day and
  /// time targeting setting.
  ///
  /// Required.
  /// Possible string values are:
  /// - "TIME_ZONE_RESOLUTION_UNSPECIFIED" : Time zone resolution is either
  /// unspecific or unknown.
  /// - "TIME_ZONE_RESOLUTION_END_USER" : Times are resolved in the time zone of
  /// the user that saw the ad.
  /// - "TIME_ZONE_RESOLUTION_ADVERTISER" : Times are resolved in the time zone
  /// of the advertiser that served the ad.
  core.String? timeZoneResolution;

  DayAndTimeAssignedTargetingOptionDetails();

  DayAndTimeAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('dayOfWeek')) {
      dayOfWeek = _json['dayOfWeek'] as core.String;
    }
    if (_json.containsKey('endHour')) {
      endHour = _json['endHour'] as core.int;
    }
    if (_json.containsKey('startHour')) {
      startHour = _json['startHour'] as core.int;
    }
    if (_json.containsKey('timeZoneResolution')) {
      timeZoneResolution = _json['timeZoneResolution'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dayOfWeek != null) 'dayOfWeek': dayOfWeek!,
        if (endHour != null) 'endHour': endHour!,
        if (startHour != null) 'startHour': startHour!,
        if (timeZoneResolution != null)
          'timeZoneResolution': timeZoneResolution!,
      };
}

/// Request message for ManualTriggerService.DeactivateManualTrigger.
class DeactivateManualTriggerRequest {
  DeactivateManualTriggerRequest();

  DeactivateManualTriggerRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A request listing which assigned targeting options of a given targeting type
/// should be deleted.
class DeleteAssignedTargetingOptionsRequest {
  /// The assigned targeting option IDs to delete.
  ///
  /// Required.
  core.List<core.String>? assignedTargetingOptionIds;

  /// Identifies the type of this assigned targeting option.
  ///
  /// Required.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  core.String? targetingType;

  DeleteAssignedTargetingOptionsRequest();

  DeleteAssignedTargetingOptionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('assignedTargetingOptionIds')) {
      assignedTargetingOptionIds =
          (_json['assignedTargetingOptionIds'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('targetingType')) {
      targetingType = _json['targetingType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedTargetingOptionIds != null)
          'assignedTargetingOptionIds': assignedTargetingOptionIds!,
        if (targetingType != null) 'targetingType': targetingType!,
      };
}

/// Assigned device make and model targeting option details.
///
/// This will be populated in the device_make_model_details field when
/// targeting_type is `TARGETING_TYPE_DEVICE_MAKE_MODEL`.
class DeviceMakeModelAssignedTargetingOptionDetails {
  /// The display name of the device make and model.
  ///
  /// Output only.
  core.String? displayName;

  /// Indicates if this option is being negatively targeted.
  core.bool? negative;

  /// The targeting_option_id field when targeting_type is
  /// `TARGETING_TYPE_DEVICE_MAKE_MODEL`.
  ///
  /// Required.
  core.String? targetingOptionId;

  DeviceMakeModelAssignedTargetingOptionDetails();

  DeviceMakeModelAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (negative != null) 'negative': negative!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable device make and model.
///
/// This will be populated in the device_make_model_details field of a
/// TargetingOption when targeting_type is `TARGETING_TYPE_DEVICE_MAKE_MODEL`.
class DeviceMakeModelTargetingOptionDetails {
  /// The display name of the device make and model.
  ///
  /// Output only.
  core.String? displayName;

  DeviceMakeModelTargetingOptionDetails();

  DeviceMakeModelTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
      };
}

/// Targeting details for device type.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_DEVICE_TYPE`.
class DeviceTypeAssignedTargetingOptionDetails {
  /// The display name of the device type.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "DEVICE_TYPE_UNSPECIFIED" : Default value when device type is not
  /// specified in this version. This enum is a placeholder for default value
  /// and does not represent a real device type option.
  /// - "DEVICE_TYPE_COMPUTER" : The device type is computer.
  /// - "DEVICE_TYPE_CONNECTED_TV" : The device type is connected TV.
  /// - "DEVICE_TYPE_SMART_PHONE" : The device type is smart phone..
  /// - "DEVICE_TYPE_TABLET" : The device type is tablet.
  core.String? deviceType;

  /// ID of the device type.
  ///
  /// Required.
  core.String? targetingOptionId;

  DeviceTypeAssignedTargetingOptionDetails();

  DeviceTypeAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('deviceType')) {
      deviceType = _json['deviceType'] as core.String;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceType != null) 'deviceType': deviceType!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable device type.
///
/// This will be populated in the device_type_details field of a TargetingOption
/// when targeting_type is `TARGETING_TYPE_DEVICE_TYPE`.
class DeviceTypeTargetingOptionDetails {
  /// The device type that is used to be targeted.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "DEVICE_TYPE_UNSPECIFIED" : Default value when device type is not
  /// specified in this version. This enum is a placeholder for default value
  /// and does not represent a real device type option.
  /// - "DEVICE_TYPE_COMPUTER" : The device type is computer.
  /// - "DEVICE_TYPE_CONNECTED_TV" : The device type is connected TV.
  /// - "DEVICE_TYPE_SMART_PHONE" : The device type is smart phone..
  /// - "DEVICE_TYPE_TABLET" : The device type is tablet.
  core.String? deviceType;

  DeviceTypeTargetingOptionDetails();

  DeviceTypeTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('deviceType')) {
      deviceType = _json['deviceType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceType != null) 'deviceType': deviceType!,
      };
}

/// Targeting details for digital content label.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION`.
class DigitalContentLabelAssignedTargetingOptionDetails {
  /// The display name of the digital content label rating tier.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "CONTENT_RATING_TIER_UNSPECIFIED" : Content label is not specified in
  /// this version. This enum is a place holder for a default value and does not
  /// represent a real content rating.
  /// - "CONTENT_RATING_TIER_UNRATED" : Content that has not been labeled.
  /// - "CONTENT_RATING_TIER_GENERAL" : Content suitable for general audiences.
  /// - "CONTENT_RATING_TIER_PARENTAL_GUIDANCE" : Content suitable for most
  /// audiences with parental guidance.
  /// - "CONTENT_RATING_TIER_TEENS" : Content suitable for teen and older
  /// audiences.
  /// - "CONTENT_RATING_TIER_MATURE" : Content suitable only for mature
  /// audiences.
  core.String? contentRatingTier;

  /// ID of the digital content label to be EXCLUDED.
  ///
  /// Required.
  core.String? excludedTargetingOptionId;

  DigitalContentLabelAssignedTargetingOptionDetails();

  DigitalContentLabelAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('contentRatingTier')) {
      contentRatingTier = _json['contentRatingTier'] as core.String;
    }
    if (_json.containsKey('excludedTargetingOptionId')) {
      excludedTargetingOptionId =
          _json['excludedTargetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentRatingTier != null) 'contentRatingTier': contentRatingTier!,
        if (excludedTargetingOptionId != null)
          'excludedTargetingOptionId': excludedTargetingOptionId!,
      };
}

/// Represents a targetable digital content label rating tier.
///
/// This will be populated in the digital_content_label_details field of the
/// TargetingOption when targeting_type is
/// `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION`.
class DigitalContentLabelTargetingOptionDetails {
  /// An enum for the content label brand safety tiers.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "CONTENT_RATING_TIER_UNSPECIFIED" : Content label is not specified in
  /// this version. This enum is a place holder for a default value and does not
  /// represent a real content rating.
  /// - "CONTENT_RATING_TIER_UNRATED" : Content that has not been labeled.
  /// - "CONTENT_RATING_TIER_GENERAL" : Content suitable for general audiences.
  /// - "CONTENT_RATING_TIER_PARENTAL_GUIDANCE" : Content suitable for most
  /// audiences with parental guidance.
  /// - "CONTENT_RATING_TIER_TEENS" : Content suitable for teen and older
  /// audiences.
  /// - "CONTENT_RATING_TIER_MATURE" : Content suitable only for mature
  /// audiences.
  core.String? contentRatingTier;

  DigitalContentLabelTargetingOptionDetails();

  DigitalContentLabelTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('contentRatingTier')) {
      contentRatingTier = _json['contentRatingTier'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentRatingTier != null) 'contentRatingTier': contentRatingTier!,
      };
}

/// Dimensions.
class Dimensions {
  /// The height in pixels.
  core.int? heightPixels;

  /// The width in pixels.
  core.int? widthPixels;

  Dimensions();

  Dimensions.fromJson(core.Map _json) {
    if (_json.containsKey('heightPixels')) {
      heightPixels = _json['heightPixels'] as core.int;
    }
    if (_json.containsKey('widthPixels')) {
      widthPixels = _json['widthPixels'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (heightPixels != null) 'heightPixels': heightPixels!,
        if (widthPixels != null) 'widthPixels': widthPixels!,
      };
}

/// Details of DoubleVerify settings.
class DoubleVerify {
  /// Avoid bidding on apps with the star ratings.
  DoubleVerifyAppStarRating? appStarRating;

  /// Avoid bidding on apps with the age rating.
  core.List<core.String>? avoidedAgeRatings;

  /// DV Brand Safety Controls.
  DoubleVerifyBrandSafetyCategories? brandSafetyCategories;

  /// The custom segment ID provided by DoubleVerify.
  ///
  /// The ID must start with "51" and consist of eight digits. Custom segment ID
  /// cannot be specified along with any of the following fields: *
  /// brand_safety_categories * avoided_age_ratings * app_star_rating *
  /// fraud_invalid_traffic
  core.String? customSegmentId;

  /// Display viewability settings (applicable to display line items only).
  DoubleVerifyDisplayViewability? displayViewability;

  /// Avoid Sites and Apps with historical Fraud & IVT Rates.
  DoubleVerifyFraudInvalidTraffic? fraudInvalidTraffic;

  /// Video viewability settings (applicable to video line items only).
  DoubleVerifyVideoViewability? videoViewability;

  DoubleVerify();

  DoubleVerify.fromJson(core.Map _json) {
    if (_json.containsKey('appStarRating')) {
      appStarRating = DoubleVerifyAppStarRating.fromJson(
          _json['appStarRating'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('avoidedAgeRatings')) {
      avoidedAgeRatings = (_json['avoidedAgeRatings'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('brandSafetyCategories')) {
      brandSafetyCategories = DoubleVerifyBrandSafetyCategories.fromJson(
          _json['brandSafetyCategories']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('customSegmentId')) {
      customSegmentId = _json['customSegmentId'] as core.String;
    }
    if (_json.containsKey('displayViewability')) {
      displayViewability = DoubleVerifyDisplayViewability.fromJson(
          _json['displayViewability'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fraudInvalidTraffic')) {
      fraudInvalidTraffic = DoubleVerifyFraudInvalidTraffic.fromJson(
          _json['fraudInvalidTraffic'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('videoViewability')) {
      videoViewability = DoubleVerifyVideoViewability.fromJson(
          _json['videoViewability'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appStarRating != null) 'appStarRating': appStarRating!.toJson(),
        if (avoidedAgeRatings != null) 'avoidedAgeRatings': avoidedAgeRatings!,
        if (brandSafetyCategories != null)
          'brandSafetyCategories': brandSafetyCategories!.toJson(),
        if (customSegmentId != null) 'customSegmentId': customSegmentId!,
        if (displayViewability != null)
          'displayViewability': displayViewability!.toJson(),
        if (fraudInvalidTraffic != null)
          'fraudInvalidTraffic': fraudInvalidTraffic!.toJson(),
        if (videoViewability != null)
          'videoViewability': videoViewability!.toJson(),
      };
}

/// Details of DoubleVerify star ratings settings.
class DoubleVerifyAppStarRating {
  /// Avoid bidding on apps with insufficient star ratings.
  core.bool? avoidInsufficientStarRating;

  /// Avoid bidding on apps with the star ratings.
  /// Possible string values are:
  /// - "APP_STAR_RATE_UNSPECIFIED" : This enum is only a placeholder and it
  /// doesn't specify any app star rating options.
  /// - "APP_STAR_RATE_1_POINT_5_LESS" : Official Apps with rating < 1.5 Stars.
  /// - "APP_STAR_RATE_2_LESS" : Official Apps with rating < 2 Stars.
  /// - "APP_STAR_RATE_2_POINT_5_LESS" : Official Apps with rating < 2.5 Stars.
  /// - "APP_STAR_RATE_3_LESS" : Official Apps with rating < 3 Stars.
  /// - "APP_STAR_RATE_3_POINT_5_LESS" : Official Apps with rating < 3.5 Stars.
  /// - "APP_STAR_RATE_4_LESS" : Official Apps with rating < 4 Stars.
  /// - "APP_STAR_RATE_4_POINT_5_LESS" : Official Apps with rating < 4.5 Stars.
  core.String? avoidedStarRating;

  DoubleVerifyAppStarRating();

  DoubleVerifyAppStarRating.fromJson(core.Map _json) {
    if (_json.containsKey('avoidInsufficientStarRating')) {
      avoidInsufficientStarRating =
          _json['avoidInsufficientStarRating'] as core.bool;
    }
    if (_json.containsKey('avoidedStarRating')) {
      avoidedStarRating = _json['avoidedStarRating'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (avoidInsufficientStarRating != null)
          'avoidInsufficientStarRating': avoidInsufficientStarRating!,
        if (avoidedStarRating != null) 'avoidedStarRating': avoidedStarRating!,
      };
}

/// Settings for brand safety controls.
class DoubleVerifyBrandSafetyCategories {
  /// Unknown or unrateable.
  core.bool? avoidUnknownBrandSafetyCategory;

  /// Brand safety high severity avoidance categories.
  core.List<core.String>? avoidedHighSeverityCategories;

  /// Brand safety medium severity avoidance categories.
  core.List<core.String>? avoidedMediumSeverityCategories;

  DoubleVerifyBrandSafetyCategories();

  DoubleVerifyBrandSafetyCategories.fromJson(core.Map _json) {
    if (_json.containsKey('avoidUnknownBrandSafetyCategory')) {
      avoidUnknownBrandSafetyCategory =
          _json['avoidUnknownBrandSafetyCategory'] as core.bool;
    }
    if (_json.containsKey('avoidedHighSeverityCategories')) {
      avoidedHighSeverityCategories =
          (_json['avoidedHighSeverityCategories'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('avoidedMediumSeverityCategories')) {
      avoidedMediumSeverityCategories =
          (_json['avoidedMediumSeverityCategories'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (avoidUnknownBrandSafetyCategory != null)
          'avoidUnknownBrandSafetyCategory': avoidUnknownBrandSafetyCategory!,
        if (avoidedHighSeverityCategories != null)
          'avoidedHighSeverityCategories': avoidedHighSeverityCategories!,
        if (avoidedMediumSeverityCategories != null)
          'avoidedMediumSeverityCategories': avoidedMediumSeverityCategories!,
      };
}

/// Details of DoubleVerify display viewability settings.
class DoubleVerifyDisplayViewability {
  /// Target web and app inventory to maximize IAB viewable rate.
  /// Possible string values are:
  /// - "IAB_VIEWED_RATE_UNSPECIFIED" : This enum is only a placeholder and it
  /// doesn't specify any IAB viewed rate options.
  /// - "IAB_VIEWED_RATE_80_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 80% or higher.
  /// - "IAB_VIEWED_RATE_75_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 75% or higher.
  /// - "IAB_VIEWED_RATE_70_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 70% or higher.
  /// - "IAB_VIEWED_RATE_65_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 65% or higher.
  /// - "IAB_VIEWED_RATE_60_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 60% or higher.
  /// - "IAB_VIEWED_RATE_55_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 55% or higher.
  /// - "IAB_VIEWED_RATE_50_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 50% or higher.
  /// - "IAB_VIEWED_RATE_40_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 40% or higher.
  /// - "IAB_VIEWED_RATE_30_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 30% or higher.
  core.String? iab;

  /// Target web and app inventory to maximize 100% viewable duration.
  /// Possible string values are:
  /// - "AVERAGE_VIEW_DURATION_UNSPECIFIED" : This enum is only a placeholder
  /// and it doesn't specify any average view duration options.
  /// - "AVERAGE_VIEW_DURATION_5_SEC" : Target web and app inventory to maximize
  /// 100% viewable duration 5 seconds or more.
  /// - "AVERAGE_VIEW_DURATION_10_SEC" : Target web and app inventory to
  /// maximize 100% viewable duration 10 seconds or more.
  /// - "AVERAGE_VIEW_DURATION_15_SEC" : Target web and app inventory to
  /// maximize 100% viewable duration 15 seconds or more.
  core.String? viewableDuring;

  DoubleVerifyDisplayViewability();

  DoubleVerifyDisplayViewability.fromJson(core.Map _json) {
    if (_json.containsKey('iab')) {
      iab = _json['iab'] as core.String;
    }
    if (_json.containsKey('viewableDuring')) {
      viewableDuring = _json['viewableDuring'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (iab != null) 'iab': iab!,
        if (viewableDuring != null) 'viewableDuring': viewableDuring!,
      };
}

/// DoubleVerify Fraud & Invalid Traffic settings.
class DoubleVerifyFraudInvalidTraffic {
  /// Insufficient Historical Fraud & IVT Stats.
  core.bool? avoidInsufficientOption;

  /// Avoid Sites and Apps with historical Fraud & IVT.
  /// Possible string values are:
  /// - "FRAUD_UNSPECIFIED" : This enum is only a placeholder and it doesn't
  /// specify any fraud and invalid traffic options.
  /// - "AD_IMPRESSION_FRAUD_100" : 100% Fraud & IVT.
  /// - "AD_IMPRESSION_FRAUD_50" : 50% or Higher Fraud & IVT.
  /// - "AD_IMPRESSION_FRAUD_25" : 25% or Higher Fraud & IVT.
  /// - "AD_IMPRESSION_FRAUD_10" : 10% or Higher Fraud & IVT.
  /// - "AD_IMPRESSION_FRAUD_8" : 8% or Higher Fraud & IVT.
  /// - "AD_IMPRESSION_FRAUD_6" : 6% or Higher Fraud & IVT.
  /// - "AD_IMPRESSION_FRAUD_4" : 4% or Higher Fraud & IVT.
  /// - "AD_IMPRESSION_FRAUD_2" : 2% or Higher Fraud & IVT.
  core.String? avoidedFraudOption;

  DoubleVerifyFraudInvalidTraffic();

  DoubleVerifyFraudInvalidTraffic.fromJson(core.Map _json) {
    if (_json.containsKey('avoidInsufficientOption')) {
      avoidInsufficientOption = _json['avoidInsufficientOption'] as core.bool;
    }
    if (_json.containsKey('avoidedFraudOption')) {
      avoidedFraudOption = _json['avoidedFraudOption'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (avoidInsufficientOption != null)
          'avoidInsufficientOption': avoidInsufficientOption!,
        if (avoidedFraudOption != null)
          'avoidedFraudOption': avoidedFraudOption!,
      };
}

/// Details of DoubleVerify video viewability settings.
class DoubleVerifyVideoViewability {
  /// Target inventory to maximize impressions with 400x300 or greater player
  /// size.
  /// Possible string values are:
  /// - "PLAYER_SIZE_400X300_UNSPECIFIED" : This enum is only a placeholder and
  /// it doesn't specify any impressions options.
  /// - "PLAYER_SIZE_400X300_95" : Sites with 95%+ of impressions.
  /// - "PLAYER_SIZE_400X300_70" : Sites with 70%+ of impressions.
  /// - "PLAYER_SIZE_400X300_25" : Sites with 25%+ of impressions.
  /// - "PLAYER_SIZE_400X300_5" : Sites with 5%+ of impressions.
  core.String? playerImpressionRate;

  /// Target web inventory to maximize IAB viewable rate.
  /// Possible string values are:
  /// - "VIDEO_IAB_UNSPECIFIED" : This enum is only a placeholder and it doesn't
  /// specify any video IAB viewable rate options.
  /// - "IAB_VIEWABILITY_80_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 80% or higher.
  /// - "IAB_VIEWABILITY_75_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 75% or higher.
  /// - "IAB_VIEWABILITY_70_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 70% or higher.
  /// - "IAB_VIEWABILITY_65_PERCENT_HIHGER" : Target web and app inventory to
  /// maximize IAB viewable rate 65% or higher.
  /// - "IAB_VIEWABILITY_60_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 60% or higher.
  /// - "IAB_VIEWABILITY_55_PERCENT_HIHGER" : Target web and app inventory to
  /// maximize IAB viewable rate 55% or higher.
  /// - "IAB_VIEWABILITY_50_PERCENT_HIGHER" : Target web and app inventory to
  /// maximize IAB viewable rate 50% or higher.
  /// - "IAB_VIEWABILITY_40_PERCENT_HIHGER" : Target web and app inventory to
  /// maximize IAB viewable rate 40% or higher.
  /// - "IAB_VIEWABILITY_30_PERCENT_HIHGER" : Target web and app inventory to
  /// maximize IAB viewable rate 30% or higher.
  core.String? videoIab;

  /// Target web inventory to maximize fully viewable rate.
  /// Possible string values are:
  /// - "VIDEO_VIEWABLE_RATE_UNSPECIFIED" : This enum is only a placeholder and
  /// it doesn't specify any video viewable rate options.
  /// - "VIEWED_PERFORMANCE_40_PERCENT_HIGHER" : Target web inventory to
  /// maximize fully viewable rate 40% or higher.
  /// - "VIEWED_PERFORMANCE_35_PERCENT_HIGHER" : Target web inventory to
  /// maximize fully viewable rate 35% or higher.
  /// - "VIEWED_PERFORMANCE_30_PERCENT_HIGHER" : Target web inventory to
  /// maximize fully viewable rate 30% or higher.
  /// - "VIEWED_PERFORMANCE_25_PERCENT_HIGHER" : Target web inventory to
  /// maximize fully viewable rate 25% or higher.
  /// - "VIEWED_PERFORMANCE_20_PERCENT_HIGHER" : Target web inventory to
  /// maximize fully viewable rate 20% or higher.
  /// - "VIEWED_PERFORMANCE_10_PERCENT_HIGHER" : Target web inventory to
  /// maximize fully viewable rate 10% or higher.
  core.String? videoViewableRate;

  DoubleVerifyVideoViewability();

  DoubleVerifyVideoViewability.fromJson(core.Map _json) {
    if (_json.containsKey('playerImpressionRate')) {
      playerImpressionRate = _json['playerImpressionRate'] as core.String;
    }
    if (_json.containsKey('videoIab')) {
      videoIab = _json['videoIab'] as core.String;
    }
    if (_json.containsKey('videoViewableRate')) {
      videoViewableRate = _json['videoViewableRate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (playerImpressionRate != null)
          'playerImpressionRate': playerImpressionRate!,
        if (videoIab != null) 'videoIab': videoIab!,
        if (videoViewableRate != null) 'videoViewableRate': videoViewableRate!,
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

/// Assigned environment targeting option details.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_ENVIRONMENT`.
class EnvironmentAssignedTargetingOptionDetails {
  /// The serving environment.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ENVIRONMENT_UNSPECIFIED" : Default value when environment is not
  /// specified in this version. This enum is a placeholder for default value
  /// and does not represent a real environment option.
  /// - "ENVIRONMENT_WEB_OPTIMIZED" : Target inventory displayed in browsers.
  /// This includes inventory that was designed for the device it was viewed on,
  /// such as mobile websites viewed on a mobile device.
  /// ENVIRONMENT_WEB_NOT_OPTIMIZED, if targeted, should be deleted prior to the
  /// deletion of this targeting option.
  /// - "ENVIRONMENT_WEB_NOT_OPTIMIZED" : Target inventory displayed in
  /// browsers. This includes inventory that was not designed for the device but
  /// viewed on it, such as websites optimized for desktop but viewed on a
  /// mobile device. ENVIRONMENT_WEB_OPTIMIZED should be targeted prior to the
  /// addition of this targeting option.
  /// - "ENVIRONMENT_APP" : Target inventory displayed in apps.
  core.String? environment;

  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_ENVIRONMENT` (e.g., "508010" for targeting the
  /// `ENVIRONMENT_WEB_OPTIMIZED` option).
  ///
  /// Required.
  core.String? targetingOptionId;

  EnvironmentAssignedTargetingOptionDetails();

  EnvironmentAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('environment')) {
      environment = _json['environment'] as core.String;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (environment != null) 'environment': environment!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable environment.
///
/// This will be populated in the environment_details field of a TargetingOption
/// when targeting_type is `TARGETING_TYPE_ENVIRONMENT`.
class EnvironmentTargetingOptionDetails {
  /// The serving environment.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ENVIRONMENT_UNSPECIFIED" : Default value when environment is not
  /// specified in this version. This enum is a placeholder for default value
  /// and does not represent a real environment option.
  /// - "ENVIRONMENT_WEB_OPTIMIZED" : Target inventory displayed in browsers.
  /// This includes inventory that was designed for the device it was viewed on,
  /// such as mobile websites viewed on a mobile device.
  /// ENVIRONMENT_WEB_NOT_OPTIMIZED, if targeted, should be deleted prior to the
  /// deletion of this targeting option.
  /// - "ENVIRONMENT_WEB_NOT_OPTIMIZED" : Target inventory displayed in
  /// browsers. This includes inventory that was not designed for the device but
  /// viewed on it, such as websites optimized for desktop but viewed on a
  /// mobile device. ENVIRONMENT_WEB_OPTIMIZED should be targeted prior to the
  /// addition of this targeting option.
  /// - "ENVIRONMENT_APP" : Target inventory displayed in apps.
  core.String? environment;

  EnvironmentTargetingOptionDetails();

  EnvironmentTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('environment')) {
      environment = _json['environment'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (environment != null) 'environment': environment!,
      };
}

/// Details for assigned exchange targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_EXCHANGE`.
class ExchangeAssignedTargetingOptionDetails {
  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_EXCHANGE`.
  ///
  /// Required.
  core.String? targetingOptionId;

  ExchangeAssignedTargetingOptionDetails();

  ExchangeAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Settings that control which exchanges are enabled for a partner.
class ExchangeConfig {
  /// All enabled exchanges in the partner.
  ///
  /// Duplicate enabled exchanges will be ignored.
  core.List<ExchangeConfigEnabledExchange>? enabledExchanges;

  ExchangeConfig();

  ExchangeConfig.fromJson(core.Map _json) {
    if (_json.containsKey('enabledExchanges')) {
      enabledExchanges = (_json['enabledExchanges'] as core.List)
          .map<ExchangeConfigEnabledExchange>((value) =>
              ExchangeConfigEnabledExchange.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabledExchanges != null)
          'enabledExchanges':
              enabledExchanges!.map((value) => value.toJson()).toList(),
      };
}

/// An enabled exchange in the partner.
class ExchangeConfigEnabledExchange {
  /// The enabled exchange.
  /// Possible string values are:
  /// - "EXCHANGE_UNSPECIFIED" : Exchange is not specified or is unknown in this
  /// version.
  /// - "EXCHANGE_GOOGLE_AD_MANAGER" : Google Ad Manager.
  /// - "EXCHANGE_APPNEXUS" : AppNexus.
  /// - "EXCHANGE_BRIGHTROLL" : BrightRoll Exchange for Video from Yahoo!.
  /// - "EXCHANGE_ADFORM" : Adform.
  /// - "EXCHANGE_ADMETA" : Admeta.
  /// - "EXCHANGE_ADMIXER" : Admixer.
  /// - "EXCHANGE_ADSMOGO" : AdsMogo.
  /// - "EXCHANGE_ADSWIZZ" : AdsWizz.
  /// - "EXCHANGE_BIDSWITCH" : BidSwitch.
  /// - "EXCHANGE_BRIGHTROLL_DISPLAY" : BrightRoll Exchange for Display from
  /// Yahoo!.
  /// - "EXCHANGE_CADREON" : Cadreon.
  /// - "EXCHANGE_DAILYMOTION" : Dailymotion.
  /// - "EXCHANGE_FIVE" : Five.
  /// - "EXCHANGE_FLUCT" : Fluct.
  /// - "EXCHANGE_FREEWHEEL" : FreeWheel SSP.
  /// - "EXCHANGE_GENIEE" : Geniee.
  /// - "EXCHANGE_GUMGUM" : GumGum.
  /// - "EXCHANGE_IMOBILE" : i-mobile.
  /// - "EXCHANGE_IBILLBOARD" : iBILLBOARD.
  /// - "EXCHANGE_IMPROVE_DIGITAL" : Improve Digital.
  /// - "EXCHANGE_INDEX" : Index Exchange.
  /// - "EXCHANGE_KARGO" : Kargo.
  /// - "EXCHANGE_MICROAD" : MicroAd.
  /// - "EXCHANGE_MOPUB" : MoPub.
  /// - "EXCHANGE_NEND" : Nend.
  /// - "EXCHANGE_ONE_BY_AOL_DISPLAY" : ONE by AOL: Display Market Place.
  /// - "EXCHANGE_ONE_BY_AOL_MOBILE" : ONE by AOL: Mobile.
  /// - "EXCHANGE_ONE_BY_AOL_VIDEO" : ONE by AOL: Video.
  /// - "EXCHANGE_OOYALA" : Ooyala.
  /// - "EXCHANGE_OPENX" : OpenX.
  /// - "EXCHANGE_PERMODO" : Permodo.
  /// - "EXCHANGE_PLATFORMONE" : Platform One.
  /// - "EXCHANGE_PLATFORMID" : PlatformId.
  /// - "EXCHANGE_PUBMATIC" : PubMatic.
  /// - "EXCHANGE_PULSEPOINT" : PulsePoint.
  /// - "EXCHANGE_REVENUEMAX" : RevenueMax.
  /// - "EXCHANGE_RUBICON" : Rubicon.
  /// - "EXCHANGE_SMARTCLIP" : SmartClip.
  /// - "EXCHANGE_SMARTRTB" : SmartRTB+.
  /// - "EXCHANGE_SMARTSTREAMTV" : SmartstreamTv.
  /// - "EXCHANGE_SOVRN" : Sovrn.
  /// - "EXCHANGE_SPOTXCHANGE" : SpotXchange.
  /// - "EXCHANGE_STROER" : Ströer SSP.
  /// - "EXCHANGE_TEADSTV" : TeadsTv.
  /// - "EXCHANGE_TELARIA" : Telaria.
  /// - "EXCHANGE_TVN" : TVN.
  /// - "EXCHANGE_UNITED" : United.
  /// - "EXCHANGE_YIELDLAB" : Yieldlab.
  /// - "EXCHANGE_YIELDMO" : Yieldmo.
  /// - "EXCHANGE_UNRULYX" : UnrulyX.
  /// - "EXCHANGE_OPEN8" : Open8.
  /// - "EXCHANGE_TRITON" : Triton.
  /// - "EXCHANGE_TRIPLELIFT" : TripleLift.
  /// - "EXCHANGE_TABOOLA" : Taboola.
  /// - "EXCHANGE_INMOBI" : InMobi.
  /// - "EXCHANGE_SMAATO" : Smaato.
  /// - "EXCHANGE_AJA" : Aja.
  /// - "EXCHANGE_SUPERSHIP" : Supership.
  /// - "EXCHANGE_NEXSTAR_DIGITAL" : Nexstar Digital.
  /// - "EXCHANGE_WAZE" : Waze.
  /// - "EXCHANGE_SOUNDCAST" : SoundCast.
  /// - "EXCHANGE_SHARETHROUGH" : Sharethrough.
  /// - "EXCHANGE_MEDIANET" : Media.net.
  core.String? exchange;

  /// Agency ID of Google Ad Manager.
  ///
  /// The field is only relevant when Google Ad Manager is the enabled exchange.
  ///
  /// Output only.
  core.String? googleAdManagerAgencyId;

  /// Network ID of Google Ad Manager.
  ///
  /// The field is only relevant when Google Ad Manager is the enabled exchange.
  ///
  /// Output only.
  core.String? googleAdManagerBuyerNetworkId;

  /// Seat ID of the enabled exchange.
  ///
  /// Output only.
  core.String? seatId;

  ExchangeConfigEnabledExchange();

  ExchangeConfigEnabledExchange.fromJson(core.Map _json) {
    if (_json.containsKey('exchange')) {
      exchange = _json['exchange'] as core.String;
    }
    if (_json.containsKey('googleAdManagerAgencyId')) {
      googleAdManagerAgencyId = _json['googleAdManagerAgencyId'] as core.String;
    }
    if (_json.containsKey('googleAdManagerBuyerNetworkId')) {
      googleAdManagerBuyerNetworkId =
          _json['googleAdManagerBuyerNetworkId'] as core.String;
    }
    if (_json.containsKey('seatId')) {
      seatId = _json['seatId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exchange != null) 'exchange': exchange!,
        if (googleAdManagerAgencyId != null)
          'googleAdManagerAgencyId': googleAdManagerAgencyId!,
        if (googleAdManagerBuyerNetworkId != null)
          'googleAdManagerBuyerNetworkId': googleAdManagerBuyerNetworkId!,
        if (seatId != null) 'seatId': seatId!,
      };
}

/// Exchange review status for the creative.
class ExchangeReviewStatus {
  /// The exchange reviewing the creative.
  /// Possible string values are:
  /// - "EXCHANGE_UNSPECIFIED" : Exchange is not specified or is unknown in this
  /// version.
  /// - "EXCHANGE_GOOGLE_AD_MANAGER" : Google Ad Manager.
  /// - "EXCHANGE_APPNEXUS" : AppNexus.
  /// - "EXCHANGE_BRIGHTROLL" : BrightRoll Exchange for Video from Yahoo!.
  /// - "EXCHANGE_ADFORM" : Adform.
  /// - "EXCHANGE_ADMETA" : Admeta.
  /// - "EXCHANGE_ADMIXER" : Admixer.
  /// - "EXCHANGE_ADSMOGO" : AdsMogo.
  /// - "EXCHANGE_ADSWIZZ" : AdsWizz.
  /// - "EXCHANGE_BIDSWITCH" : BidSwitch.
  /// - "EXCHANGE_BRIGHTROLL_DISPLAY" : BrightRoll Exchange for Display from
  /// Yahoo!.
  /// - "EXCHANGE_CADREON" : Cadreon.
  /// - "EXCHANGE_DAILYMOTION" : Dailymotion.
  /// - "EXCHANGE_FIVE" : Five.
  /// - "EXCHANGE_FLUCT" : Fluct.
  /// - "EXCHANGE_FREEWHEEL" : FreeWheel SSP.
  /// - "EXCHANGE_GENIEE" : Geniee.
  /// - "EXCHANGE_GUMGUM" : GumGum.
  /// - "EXCHANGE_IMOBILE" : i-mobile.
  /// - "EXCHANGE_IBILLBOARD" : iBILLBOARD.
  /// - "EXCHANGE_IMPROVE_DIGITAL" : Improve Digital.
  /// - "EXCHANGE_INDEX" : Index Exchange.
  /// - "EXCHANGE_KARGO" : Kargo.
  /// - "EXCHANGE_MICROAD" : MicroAd.
  /// - "EXCHANGE_MOPUB" : MoPub.
  /// - "EXCHANGE_NEND" : Nend.
  /// - "EXCHANGE_ONE_BY_AOL_DISPLAY" : ONE by AOL: Display Market Place.
  /// - "EXCHANGE_ONE_BY_AOL_MOBILE" : ONE by AOL: Mobile.
  /// - "EXCHANGE_ONE_BY_AOL_VIDEO" : ONE by AOL: Video.
  /// - "EXCHANGE_OOYALA" : Ooyala.
  /// - "EXCHANGE_OPENX" : OpenX.
  /// - "EXCHANGE_PERMODO" : Permodo.
  /// - "EXCHANGE_PLATFORMONE" : Platform One.
  /// - "EXCHANGE_PLATFORMID" : PlatformId.
  /// - "EXCHANGE_PUBMATIC" : PubMatic.
  /// - "EXCHANGE_PULSEPOINT" : PulsePoint.
  /// - "EXCHANGE_REVENUEMAX" : RevenueMax.
  /// - "EXCHANGE_RUBICON" : Rubicon.
  /// - "EXCHANGE_SMARTCLIP" : SmartClip.
  /// - "EXCHANGE_SMARTRTB" : SmartRTB+.
  /// - "EXCHANGE_SMARTSTREAMTV" : SmartstreamTv.
  /// - "EXCHANGE_SOVRN" : Sovrn.
  /// - "EXCHANGE_SPOTXCHANGE" : SpotXchange.
  /// - "EXCHANGE_STROER" : Ströer SSP.
  /// - "EXCHANGE_TEADSTV" : TeadsTv.
  /// - "EXCHANGE_TELARIA" : Telaria.
  /// - "EXCHANGE_TVN" : TVN.
  /// - "EXCHANGE_UNITED" : United.
  /// - "EXCHANGE_YIELDLAB" : Yieldlab.
  /// - "EXCHANGE_YIELDMO" : Yieldmo.
  /// - "EXCHANGE_UNRULYX" : UnrulyX.
  /// - "EXCHANGE_OPEN8" : Open8.
  /// - "EXCHANGE_TRITON" : Triton.
  /// - "EXCHANGE_TRIPLELIFT" : TripleLift.
  /// - "EXCHANGE_TABOOLA" : Taboola.
  /// - "EXCHANGE_INMOBI" : InMobi.
  /// - "EXCHANGE_SMAATO" : Smaato.
  /// - "EXCHANGE_AJA" : Aja.
  /// - "EXCHANGE_SUPERSHIP" : Supership.
  /// - "EXCHANGE_NEXSTAR_DIGITAL" : Nexstar Digital.
  /// - "EXCHANGE_WAZE" : Waze.
  /// - "EXCHANGE_SOUNDCAST" : SoundCast.
  /// - "EXCHANGE_SHARETHROUGH" : Sharethrough.
  /// - "EXCHANGE_MEDIANET" : Media.net.
  core.String? exchange;

  /// Status of the exchange review.
  /// Possible string values are:
  /// - "REVIEW_STATUS_UNSPECIFIED" : Type value is not specified or is unknown
  /// in this version.
  /// - "REVIEW_STATUS_APPROVED" : The creative is approved.
  /// - "REVIEW_STATUS_REJECTED" : The creative is rejected.
  /// - "REVIEW_STATUS_PENDING" : The creative is pending review.
  core.String? status;

  ExchangeReviewStatus();

  ExchangeReviewStatus.fromJson(core.Map _json) {
    if (_json.containsKey('exchange')) {
      exchange = _json['exchange'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exchange != null) 'exchange': exchange!,
        if (status != null) 'status': status!,
      };
}

/// Represents a targetable exchange.
///
/// This will be populated in the exchange_details field of a TargetingOption
/// when targeting_type is `TARGETING_TYPE_EXCHANGE`.
class ExchangeTargetingOptionDetails {
  /// The type of exchange.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "EXCHANGE_UNSPECIFIED" : Exchange is not specified or is unknown in this
  /// version.
  /// - "EXCHANGE_GOOGLE_AD_MANAGER" : Google Ad Manager.
  /// - "EXCHANGE_APPNEXUS" : AppNexus.
  /// - "EXCHANGE_BRIGHTROLL" : BrightRoll Exchange for Video from Yahoo!.
  /// - "EXCHANGE_ADFORM" : Adform.
  /// - "EXCHANGE_ADMETA" : Admeta.
  /// - "EXCHANGE_ADMIXER" : Admixer.
  /// - "EXCHANGE_ADSMOGO" : AdsMogo.
  /// - "EXCHANGE_ADSWIZZ" : AdsWizz.
  /// - "EXCHANGE_BIDSWITCH" : BidSwitch.
  /// - "EXCHANGE_BRIGHTROLL_DISPLAY" : BrightRoll Exchange for Display from
  /// Yahoo!.
  /// - "EXCHANGE_CADREON" : Cadreon.
  /// - "EXCHANGE_DAILYMOTION" : Dailymotion.
  /// - "EXCHANGE_FIVE" : Five.
  /// - "EXCHANGE_FLUCT" : Fluct.
  /// - "EXCHANGE_FREEWHEEL" : FreeWheel SSP.
  /// - "EXCHANGE_GENIEE" : Geniee.
  /// - "EXCHANGE_GUMGUM" : GumGum.
  /// - "EXCHANGE_IMOBILE" : i-mobile.
  /// - "EXCHANGE_IBILLBOARD" : iBILLBOARD.
  /// - "EXCHANGE_IMPROVE_DIGITAL" : Improve Digital.
  /// - "EXCHANGE_INDEX" : Index Exchange.
  /// - "EXCHANGE_KARGO" : Kargo.
  /// - "EXCHANGE_MICROAD" : MicroAd.
  /// - "EXCHANGE_MOPUB" : MoPub.
  /// - "EXCHANGE_NEND" : Nend.
  /// - "EXCHANGE_ONE_BY_AOL_DISPLAY" : ONE by AOL: Display Market Place.
  /// - "EXCHANGE_ONE_BY_AOL_MOBILE" : ONE by AOL: Mobile.
  /// - "EXCHANGE_ONE_BY_AOL_VIDEO" : ONE by AOL: Video.
  /// - "EXCHANGE_OOYALA" : Ooyala.
  /// - "EXCHANGE_OPENX" : OpenX.
  /// - "EXCHANGE_PERMODO" : Permodo.
  /// - "EXCHANGE_PLATFORMONE" : Platform One.
  /// - "EXCHANGE_PLATFORMID" : PlatformId.
  /// - "EXCHANGE_PUBMATIC" : PubMatic.
  /// - "EXCHANGE_PULSEPOINT" : PulsePoint.
  /// - "EXCHANGE_REVENUEMAX" : RevenueMax.
  /// - "EXCHANGE_RUBICON" : Rubicon.
  /// - "EXCHANGE_SMARTCLIP" : SmartClip.
  /// - "EXCHANGE_SMARTRTB" : SmartRTB+.
  /// - "EXCHANGE_SMARTSTREAMTV" : SmartstreamTv.
  /// - "EXCHANGE_SOVRN" : Sovrn.
  /// - "EXCHANGE_SPOTXCHANGE" : SpotXchange.
  /// - "EXCHANGE_STROER" : Ströer SSP.
  /// - "EXCHANGE_TEADSTV" : TeadsTv.
  /// - "EXCHANGE_TELARIA" : Telaria.
  /// - "EXCHANGE_TVN" : TVN.
  /// - "EXCHANGE_UNITED" : United.
  /// - "EXCHANGE_YIELDLAB" : Yieldlab.
  /// - "EXCHANGE_YIELDMO" : Yieldmo.
  /// - "EXCHANGE_UNRULYX" : UnrulyX.
  /// - "EXCHANGE_OPEN8" : Open8.
  /// - "EXCHANGE_TRITON" : Triton.
  /// - "EXCHANGE_TRIPLELIFT" : TripleLift.
  /// - "EXCHANGE_TABOOLA" : Taboola.
  /// - "EXCHANGE_INMOBI" : InMobi.
  /// - "EXCHANGE_SMAATO" : Smaato.
  /// - "EXCHANGE_AJA" : Aja.
  /// - "EXCHANGE_SUPERSHIP" : Supership.
  /// - "EXCHANGE_NEXSTAR_DIGITAL" : Nexstar Digital.
  /// - "EXCHANGE_WAZE" : Waze.
  /// - "EXCHANGE_SOUNDCAST" : SoundCast.
  /// - "EXCHANGE_SHARETHROUGH" : Sharethrough.
  /// - "EXCHANGE_MEDIANET" : Media.net.
  core.String? exchange;

  ExchangeTargetingOptionDetails();

  ExchangeTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('exchange')) {
      exchange = _json['exchange'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exchange != null) 'exchange': exchange!,
      };
}

/// Exit event of the creative.
class ExitEvent {
  /// The name of the click tag of the exit event.
  ///
  /// The name must be unique within one creative. Leave it empty or unset for
  /// creatives containing image assets only.
  core.String? name;

  /// The name used to identify this event in reports.
  ///
  /// Leave it empty or unset for creatives containing image assets only.
  core.String? reportingName;

  /// The type of the exit event.
  ///
  /// Required.
  /// Possible string values are:
  /// - "EXIT_EVENT_TYPE_UNSPECIFIED" : Exit event type is not specified or is
  /// unknown in this version.
  /// - "EXIT_EVENT_TYPE_DEFAULT" : The exit event is the default one.
  /// - "EXIT_EVENT_TYPE_BACKUP" : The exit event is a backup exit event. There
  /// could be multiple backup exit events in a creative.
  core.String? type;

  /// The click through URL of the exit event.
  ///
  /// This is required when type is: * `EXIT_EVENT_TYPE_DEFAULT` *
  /// `EXIT_EVENT_TYPE_BACKUP`
  ///
  /// Required.
  core.String? url;

  ExitEvent();

  ExitEvent.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('reportingName')) {
      reportingName = _json['reportingName'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (reportingName != null) 'reportingName': reportingName!,
        if (type != null) 'type': type!,
        if (url != null) 'url': url!,
      };
}

/// Describes a first or third party audience list used for targeting.
///
/// First party audiences are created via usage of client data. Third party
/// audiences are provided by Third Party data providers and can only be
/// licensed to customers.
class FirstAndThirdPartyAudience {
  /// The estimated audience size for the Display network in the past month.
  ///
  /// If the size is less than 1000, the number will be hidden and 0 will be
  /// returned due to privacy reasons. Otherwise, the number will be rounded off
  /// to two significant digits. Only returned in GET request.
  ///
  /// Output only.
  core.String? activeDisplayAudienceSize;

  /// The source of the audience.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "AUDIENCE_SOURCE_UNSPECIFIED" : Default value when audience source is
  /// not specified or is unknown.
  /// - "DISPLAY_VIDEO_360" : Originated from Display & Video 360.
  /// - "CAMPAIGN_MANAGER" : Originated from Campaign Manager 360.
  /// - "AD_MANAGER" : Originated from Google Ad Manager.
  /// - "SEARCH_ADS_360" : Originated from Search Ads 360.
  /// - "YOUTUBE" : Originated from Youtube.
  /// - "ADS_DATA_HUB" : Originated from Ads Data Hub.
  core.String? audienceSource;

  /// The type of the audience.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "AUDIENCE_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown.
  /// - "CUSTOMER_MATCH_CONTACT_INFO" : Audience was generated through matching
  /// customers to known contact information.
  /// - "CUSTOMER_MATCH_DEVICE_ID" : Audience was generated through matching
  /// customers to known Mobile device IDs.
  /// - "CUSTOMER_MATCH_USER_ID" : Audience was generated through matching
  /// customers to known User IDs.
  /// - "ACTIVITY_BASED" : Audience was created based on campaign activity.
  /// - "FREQUENCY_CAP" : Audience was created based on excluding the number of
  /// impressions they were served.
  /// - "TAG_BASED" : Audience was created based on custom variables attached to
  /// pixel.
  /// - "YOUTUBE_USERS" : Audience was created based on past interactions with
  /// videos, YouTube ads, or YouTube channel.
  /// - "LICENSED" : Subtype of third party audience type.
  core.String? audienceType;

  /// The user-provided description of the audience.
  ///
  /// Only applicable to first party audiences.
  core.String? description;

  /// The estimated audience size for the Display network.
  ///
  /// If the size is less than 1000, the number will be hidden and 0 will be
  /// returned due to privacy reasons. Otherwise, the number will be rounded off
  /// to two significant digits. Only returned in GET request.
  ///
  /// Output only.
  core.String? displayAudienceSize;

  /// The estimated desktop audience size in Display network.
  ///
  /// If the size is less than 1000, the number will be hidden and 0 will be
  /// returned due to privacy reasons. Otherwise, the number will be rounded off
  /// to two significant digits. Only applicable to first party audiences. Only
  /// returned in GET request.
  ///
  /// Output only.
  core.String? displayDesktopAudienceSize;

  /// The estimated mobile app audience size in Display network.
  ///
  /// If the size is less than 1000, the number will be hidden and 0 will be
  /// returned due to privacy reasons. Otherwise, the number will be rounded off
  /// to two significant digits. Only applicable to first party audiences. Only
  /// returned in GET request.
  ///
  /// Output only.
  core.String? displayMobileAppAudienceSize;

  /// The estimated mobile web audience size in Display network.
  ///
  /// If the size is less than 1000, the number will be hidden and 0 will be
  /// returned due to privacy reasons. Otherwise, the number will be rounded off
  /// to two significant digits. Only applicable to first party audiences. Only
  /// returned in GET request.
  ///
  /// Output only.
  core.String? displayMobileWebAudienceSize;

  /// The display name of the first and third party audience.
  core.String? displayName;

  /// The unique ID of the first and third party audience.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? firstAndThirdPartyAudienceId;

  /// Whether the audience is a first or third party audience.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "FIRST_AND_THIRD_PARTY_AUDIENCE_TYPE_UNSPECIFIED" : Default value when
  /// type is not specified or is unknown.
  /// - "FIRST_AND_THIRD_PARTY_AUDIENCE_TYPE_FIRST_PARTY" : Audience that is
  /// created via usage of client data.
  /// - "FIRST_AND_THIRD_PARTY_AUDIENCE_TYPE_THIRD_PARTY" : Audience that is
  /// provided by Third Party data providers.
  core.String? firstAndThirdPartyAudienceType;

  /// The estimated audience size for Gmail network.
  ///
  /// If the size is less than 1000, the number will be hidden and 0 will be
  /// returned due to privacy reasons. Otherwise, the number will be rounded off
  /// to two significant digits. Only applicable to first party audiences. Only
  /// returned in GET request.
  ///
  /// Output only.
  core.String? gmailAudienceSize;

  /// The duration in days that an entry remains in the audience after the
  /// qualifying event.
  ///
  /// Only applicable to first party audiences.
  core.String? membershipDurationDays;

  /// The resource name of the first and third party audience.
  ///
  /// Output only.
  core.String? name;

  /// The estimated audience size for YouTube network.
  ///
  /// If the size is less than 1000, the number will be hidden and 0 will be
  /// returned due to privacy reasons. Otherwise, the number will be rounded off
  /// to two significant digits. Only applicable to first party audiences. Only
  /// returned in GET request.
  ///
  /// Output only.
  core.String? youtubeAudienceSize;

  FirstAndThirdPartyAudience();

  FirstAndThirdPartyAudience.fromJson(core.Map _json) {
    if (_json.containsKey('activeDisplayAudienceSize')) {
      activeDisplayAudienceSize =
          _json['activeDisplayAudienceSize'] as core.String;
    }
    if (_json.containsKey('audienceSource')) {
      audienceSource = _json['audienceSource'] as core.String;
    }
    if (_json.containsKey('audienceType')) {
      audienceType = _json['audienceType'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayAudienceSize')) {
      displayAudienceSize = _json['displayAudienceSize'] as core.String;
    }
    if (_json.containsKey('displayDesktopAudienceSize')) {
      displayDesktopAudienceSize =
          _json['displayDesktopAudienceSize'] as core.String;
    }
    if (_json.containsKey('displayMobileAppAudienceSize')) {
      displayMobileAppAudienceSize =
          _json['displayMobileAppAudienceSize'] as core.String;
    }
    if (_json.containsKey('displayMobileWebAudienceSize')) {
      displayMobileWebAudienceSize =
          _json['displayMobileWebAudienceSize'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('firstAndThirdPartyAudienceId')) {
      firstAndThirdPartyAudienceId =
          _json['firstAndThirdPartyAudienceId'] as core.String;
    }
    if (_json.containsKey('firstAndThirdPartyAudienceType')) {
      firstAndThirdPartyAudienceType =
          _json['firstAndThirdPartyAudienceType'] as core.String;
    }
    if (_json.containsKey('gmailAudienceSize')) {
      gmailAudienceSize = _json['gmailAudienceSize'] as core.String;
    }
    if (_json.containsKey('membershipDurationDays')) {
      membershipDurationDays = _json['membershipDurationDays'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('youtubeAudienceSize')) {
      youtubeAudienceSize = _json['youtubeAudienceSize'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activeDisplayAudienceSize != null)
          'activeDisplayAudienceSize': activeDisplayAudienceSize!,
        if (audienceSource != null) 'audienceSource': audienceSource!,
        if (audienceType != null) 'audienceType': audienceType!,
        if (description != null) 'description': description!,
        if (displayAudienceSize != null)
          'displayAudienceSize': displayAudienceSize!,
        if (displayDesktopAudienceSize != null)
          'displayDesktopAudienceSize': displayDesktopAudienceSize!,
        if (displayMobileAppAudienceSize != null)
          'displayMobileAppAudienceSize': displayMobileAppAudienceSize!,
        if (displayMobileWebAudienceSize != null)
          'displayMobileWebAudienceSize': displayMobileWebAudienceSize!,
        if (displayName != null) 'displayName': displayName!,
        if (firstAndThirdPartyAudienceId != null)
          'firstAndThirdPartyAudienceId': firstAndThirdPartyAudienceId!,
        if (firstAndThirdPartyAudienceType != null)
          'firstAndThirdPartyAudienceType': firstAndThirdPartyAudienceType!,
        if (gmailAudienceSize != null) 'gmailAudienceSize': gmailAudienceSize!,
        if (membershipDurationDays != null)
          'membershipDurationDays': membershipDurationDays!,
        if (name != null) 'name': name!,
        if (youtubeAudienceSize != null)
          'youtubeAudienceSize': youtubeAudienceSize!,
      };
}

/// Details of first and third party audience group.
///
/// All first and third party audience targeting settings are logically ‘OR’ of
/// each other.
class FirstAndThirdPartyAudienceGroup {
  /// All first and third party audience targeting settings in first and third
  /// party audience group.
  ///
  /// Repeated settings with same id are not allowed.
  ///
  /// Required.
  core.List<FirstAndThirdPartyAudienceTargetingSetting>? settings;

  FirstAndThirdPartyAudienceGroup();

  FirstAndThirdPartyAudienceGroup.fromJson(core.Map _json) {
    if (_json.containsKey('settings')) {
      settings = (_json['settings'] as core.List)
          .map<FirstAndThirdPartyAudienceTargetingSetting>((value) =>
              FirstAndThirdPartyAudienceTargetingSetting.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (settings != null)
          'settings': settings!.map((value) => value.toJson()).toList(),
      };
}

/// Details of first and third party audience targeting setting.
class FirstAndThirdPartyAudienceTargetingSetting {
  /// First and third party audience id of the first and third party audience
  /// targeting setting.
  ///
  /// This id is first_and_third_party_audience_id.
  ///
  /// Required.
  core.String? firstAndThirdPartyAudienceId;

  /// The recency of the first and third party audience targeting setting.
  ///
  /// Only applicable to first party audiences, otherwise will be ignored. For
  /// more info, refer to
  /// https://support.google.com/displayvideo/answer/2949947#recency When
  /// unspecified, no recency limit will be used.
  /// Possible string values are:
  /// - "RECENCY_NO_LIMIT" : No limit of recency.
  /// - "RECENCY_1_MINUTE" : Recency is 1 minute.
  /// - "RECENCY_5_MINUTES" : Recency is 5 minutes.
  /// - "RECENCY_10_MINUTES" : Recency is 10 minutes.
  /// - "RECENCY_15_MINUTES" : Recency is 15 minutes.
  /// - "RECENCY_30_MINUTES" : Recency is 30 minutes.
  /// - "RECENCY_1_HOUR" : Recency is 1 hour.
  /// - "RECENCY_2_HOURS" : Recency is 2 hours.
  /// - "RECENCY_3_HOURS" : Recency is 3 hours.
  /// - "RECENCY_6_HOURS" : Recency is 6 hours.
  /// - "RECENCY_12_HOURS" : Recency is 12 hours.
  /// - "RECENCY_1_DAY" : Recency is 1 day.
  /// - "RECENCY_2_DAYS" : Recency is 2 days.
  /// - "RECENCY_3_DAYS" : Recency is 3 days.
  /// - "RECENCY_5_DAYS" : Recency is 5 days.
  /// - "RECENCY_7_DAYS" : Recency is 7 days.
  /// - "RECENCY_10_DAYS" : Recency is 10 days.
  /// - "RECENCY_14_DAYS" : Recency is 14 days.
  /// - "RECENCY_15_DAYS" : Recency is 15 days.
  /// - "RECENCY_21_DAYS" : Recency is 21 days.
  /// - "RECENCY_28_DAYS" : Recency is 28 days.
  /// - "RECENCY_30_DAYS" : Recency is 30 days.
  /// - "RECENCY_45_DAYS" : Recency is 45 days.
  /// - "RECENCY_60_DAYS" : Recency is 60 days.
  /// - "RECENCY_90_DAYS" : Recency is 90 days.
  /// - "RECENCY_120_DAYS" : Recency is 120 days.
  /// - "RECENCY_180_DAYS" : Recency is 180 days.
  /// - "RECENCY_270_DAYS" : Recency is 270 days.
  /// - "RECENCY_365_DAYS" : Recency is 365 days.
  core.String? recency;

  FirstAndThirdPartyAudienceTargetingSetting();

  FirstAndThirdPartyAudienceTargetingSetting.fromJson(core.Map _json) {
    if (_json.containsKey('firstAndThirdPartyAudienceId')) {
      firstAndThirdPartyAudienceId =
          _json['firstAndThirdPartyAudienceId'] as core.String;
    }
    if (_json.containsKey('recency')) {
      recency = _json['recency'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (firstAndThirdPartyAudienceId != null)
          'firstAndThirdPartyAudienceId': firstAndThirdPartyAudienceId!,
        if (recency != null) 'recency': recency!,
      };
}

/// A strategy that uses a fixed bidding price.
class FixedBidStrategy {
  /// The fixed bid amount, in micros of the advertiser's currency.
  ///
  /// For insertion order entity, bid_amount_micros should be set as 0. For line
  /// item entity, bid_amount_micros must be greater than or equal to billable
  /// unit of the given currency and smaller than or equal to the upper limit
  /// 1000000000. For example, 1500000 represents 1.5 standard units of the
  /// currency.
  core.String? bidAmountMicros;

  FixedBidStrategy();

  FixedBidStrategy.fromJson(core.Map _json) {
    if (_json.containsKey('bidAmountMicros')) {
      bidAmountMicros = _json['bidAmountMicros'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bidAmountMicros != null) 'bidAmountMicros': bidAmountMicros!,
      };
}

/// A single Floodlight group.
class FloodlightGroup {
  /// The Active View video viewability metric configuration for the Floodlight
  /// group.
  ActiveViewVideoViewabilityMetricConfig? activeViewConfig;

  /// User-defined custom variables owned by the Floodlight group.
  ///
  /// Use custom Floodlight variables to create reporting data that is tailored
  /// to your unique business needs. Custom Floodlight variables use the keys
  /// `U1=`, `U2=`, and so on, and can take any values that you choose to pass
  /// to them. You can use them to track virtually any type of data that you
  /// collect about your customers, such as the genre of movie that a customer
  /// purchases, the country to which the item is shipped, and so on. Custom
  /// Floodlight variables may not be used to pass any data that could be used
  /// or recognized as personally identifiable information (PII). Example:
  /// `custom_variables { fields { "U1": value { number_value: 123.4 }, "U2":
  /// value { string_value: "MyVariable2" }, "U3": value { string_value:
  /// "MyVariable3" } } }` Acceptable values for keys are "U1" through "U100",
  /// inclusive. String values must be less than 64 characters long, and cannot
  /// contain the following characters: `"<>`.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? customVariables;

  /// The display name of the Floodlight group.
  ///
  /// Required.
  core.String? displayName;

  /// The unique ID of the Floodlight group.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? floodlightGroupId;

  /// The lookback window for the Floodlight group.
  ///
  /// Both click_days and impression_days are required. Acceptable values for
  /// both are `0` to `90`, inclusive.
  ///
  /// Required.
  LookbackWindow? lookbackWindow;

  /// The resource name of the Floodlight group.
  ///
  /// Output only.
  core.String? name;

  /// The web tag type enabled for the Floodlight group.
  ///
  /// Required.
  /// Possible string values are:
  /// - "WEB_TAG_TYPE_UNSPECIFIED" : Type value is not specified or is unknown
  /// in this version.
  /// - "WEB_TAG_TYPE_NONE" : No tag type.
  /// - "WEB_TAG_TYPE_IMAGE" : Image tag.
  /// - "WEB_TAG_TYPE_DYNAMIC" : Dynamic tag.
  core.String? webTagType;

  FloodlightGroup();

  FloodlightGroup.fromJson(core.Map _json) {
    if (_json.containsKey('activeViewConfig')) {
      activeViewConfig = ActiveViewVideoViewabilityMetricConfig.fromJson(
          _json['activeViewConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('customVariables')) {
      customVariables =
          (_json['customVariables'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('floodlightGroupId')) {
      floodlightGroupId = _json['floodlightGroupId'] as core.String;
    }
    if (_json.containsKey('lookbackWindow')) {
      lookbackWindow = LookbackWindow.fromJson(
          _json['lookbackWindow'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('webTagType')) {
      webTagType = _json['webTagType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activeViewConfig != null)
          'activeViewConfig': activeViewConfig!.toJson(),
        if (customVariables != null) 'customVariables': customVariables!,
        if (displayName != null) 'displayName': displayName!,
        if (floodlightGroupId != null) 'floodlightGroupId': floodlightGroupId!,
        if (lookbackWindow != null) 'lookbackWindow': lookbackWindow!.toJson(),
        if (name != null) 'name': name!,
        if (webTagType != null) 'webTagType': webTagType!,
      };
}

/// Settings that control the number of times a user may be shown with the same
/// ad during a given time period.
class FrequencyCap {
  /// The maximum number of times a user may be shown with the same ad during
  /// this period.
  ///
  /// Must be greater than 0. Required when unlimited is `false`.
  core.int? maxImpressions;

  /// The time unit in which the frequency cap will be applied.
  ///
  /// Required when unlimited is `false`.
  /// Possible string values are:
  /// - "TIME_UNIT_UNSPECIFIED" : Time unit value is not specified or is unknown
  /// in this version.
  /// - "TIME_UNIT_LIFETIME" : The frequency cap will be applied to the whole
  /// life time of the line item.
  /// - "TIME_UNIT_MONTHS" : The frequency cap will be applied to a number of
  /// months.
  /// - "TIME_UNIT_WEEKS" : The frequency cap will be applied to a number of
  /// weeks.
  /// - "TIME_UNIT_DAYS" : The frequency cap will be applied to a number of
  /// days.
  /// - "TIME_UNIT_HOURS" : The frequency cap will be applied to a number of
  /// hours.
  /// - "TIME_UNIT_MINUTES" : The frequency cap will be applied to a number of
  /// minutes.
  core.String? timeUnit;

  /// The number of time_unit the frequency cap will last.
  ///
  /// Required when unlimited is `false`. The following restrictions apply based
  /// on the value of time_unit: * `TIME_UNIT_LIFETIME` - this field is output
  /// only and will default to 1 * `TIME_UNIT_MONTHS` - must be between 1 and 2
  /// * `TIME_UNIT_WEEKS` - must be between 1 and 4 * `TIME_UNIT_DAYS` - must be
  /// between 1 and 6 * `TIME_UNIT_HOURS` - must be between 1 and 23 *
  /// `TIME_UNIT_MINUTES` - must be between 1 and 59
  core.int? timeUnitCount;

  /// Whether unlimited frequency capping is applied.
  ///
  /// When this field is set to `true`, the remaining frequency cap fields are
  /// not applicable.
  core.bool? unlimited;

  FrequencyCap();

  FrequencyCap.fromJson(core.Map _json) {
    if (_json.containsKey('maxImpressions')) {
      maxImpressions = _json['maxImpressions'] as core.int;
    }
    if (_json.containsKey('timeUnit')) {
      timeUnit = _json['timeUnit'] as core.String;
    }
    if (_json.containsKey('timeUnitCount')) {
      timeUnitCount = _json['timeUnitCount'] as core.int;
    }
    if (_json.containsKey('unlimited')) {
      unlimited = _json['unlimited'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maxImpressions != null) 'maxImpressions': maxImpressions!,
        if (timeUnit != null) 'timeUnit': timeUnit!,
        if (timeUnitCount != null) 'timeUnitCount': timeUnitCount!,
        if (unlimited != null) 'unlimited': unlimited!,
      };
}

/// Details for assigned gender targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARTGETING_TYPE_GENDER`.
class GenderAssignedTargetingOptionDetails {
  /// The gender of the audience.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "GENDER_UNSPECIFIED" : Default value when gender is not specified in
  /// this version. This enum is a place holder for default value and does not
  /// represent a real gender option.
  /// - "GENDER_MALE" : The audience gender is male.
  /// - "GENDER_FEMALE" : The audience gender is female.
  /// - "GENDER_UNKNOWN" : The audience gender is unknown.
  core.String? gender;

  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_GENDER`.
  ///
  /// Required.
  core.String? targetingOptionId;

  GenderAssignedTargetingOptionDetails();

  GenderAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('gender')) {
      gender = _json['gender'] as core.String;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gender != null) 'gender': gender!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable gender.
///
/// This will be populated in the gender_details field of a TargetingOption when
/// targeting_type is `TARGETING_TYPE_GENDER`.
class GenderTargetingOptionDetails {
  /// The gender of an audience.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "GENDER_UNSPECIFIED" : Default value when gender is not specified in
  /// this version. This enum is a place holder for default value and does not
  /// represent a real gender option.
  /// - "GENDER_MALE" : The audience gender is male.
  /// - "GENDER_FEMALE" : The audience gender is female.
  /// - "GENDER_UNKNOWN" : The audience gender is unknown.
  core.String? gender;

  GenderTargetingOptionDetails();

  GenderTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('gender')) {
      gender = _json['gender'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gender != null) 'gender': gender!,
      };
}

/// Request message for LineItemService.GenerateDefaultLineItem.
class GenerateDefaultLineItemRequest {
  /// The display name of the line item.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// The unique ID of the insertion order that the line item belongs to.
  ///
  /// Required.
  core.String? insertionOrderId;

  /// The type of the line item.
  ///
  /// Required.
  /// Possible string values are:
  /// - "LINE_ITEM_TYPE_UNSPECIFIED" : Type value is not specified or is unknown
  /// in this version.
  /// - "LINE_ITEM_TYPE_DISPLAY_DEFAULT" : Image, HTML5, native, or rich media
  /// ads.
  /// - "LINE_ITEM_TYPE_DISPLAY_MOBILE_APP_INSTALL" : Display ads that drive
  /// installs of an app.
  /// - "LINE_ITEM_TYPE_VIDEO_DEFAULT" : Video ads sold on a CPM basis for a
  /// variety of environments.
  /// - "LINE_ITEM_TYPE_VIDEO_MOBILE_APP_INSTALL" : Video ads that drive
  /// installs of an app.
  /// - "LINE_ITEM_TYPE_DISPLAY_MOBILE_APP_INVENTORY" : Display ads served on
  /// mobile app inventory.
  /// - "LINE_ITEM_TYPE_VIDEO_MOBILE_APP_INVENTORY" : Video ads served on mobile
  /// app inventory.
  /// - "LINE_ITEM_TYPE_AUDIO_DEFAULT" : RTB Audio ads sold for a variety of
  /// environments.
  /// - "LINE_ITEM_TYPE_VIDEO_OVER_THE_TOP" : Over-the-top ads present in OTT
  /// insertion orders. This type is only applicable to line items with an
  /// insertion order of insertion_order_type `OVER_THE_TOP`.
  core.String? lineItemType;

  /// The mobile app promoted by the line item.
  ///
  /// This is applicable only when line_item_type is either
  /// `LINE_ITEM_TYPE_DISPLAY_MOBILE_APP_INSTALL` or
  /// `LINE_ITEM_TYPE_VIDEO_MOBILE_APP_INSTALL`.
  MobileApp? mobileApp;

  GenerateDefaultLineItemRequest();

  GenerateDefaultLineItemRequest.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('insertionOrderId')) {
      insertionOrderId = _json['insertionOrderId'] as core.String;
    }
    if (_json.containsKey('lineItemType')) {
      lineItemType = _json['lineItemType'] as core.String;
    }
    if (_json.containsKey('mobileApp')) {
      mobileApp = MobileApp.fromJson(
          _json['mobileApp'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (insertionOrderId != null) 'insertionOrderId': insertionOrderId!,
        if (lineItemType != null) 'lineItemType': lineItemType!,
        if (mobileApp != null) 'mobileApp': mobileApp!.toJson(),
      };
}

/// Details for assigned geographic region targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_GEO_REGION`.
class GeoRegionAssignedTargetingOptionDetails {
  /// The display name of the geographic region (e.g., "Ontario, Canada").
  ///
  /// Output only.
  core.String? displayName;

  /// The type of geographic region targeting.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "GEO_REGION_TYPE_UNKNOWN" : The geographic region type is unknown.
  /// - "GEO_REGION_TYPE_OTHER" : The geographic region type is other.
  /// - "GEO_REGION_TYPE_COUNTRY" : The geographic region is a country.
  /// - "GEO_REGION_TYPE_REGION" : The geographic region type is region.
  /// - "GEO_REGION_TYPE_TERRITORY" : The geographic region is a territory.
  /// - "GEO_REGION_TYPE_PROVINCE" : The geographic region is a province.
  /// - "GEO_REGION_TYPE_STATE" : The geographic region is a state.
  /// - "GEO_REGION_TYPE_PREFECTURE" : The geographic region is a prefecture.
  /// - "GEO_REGION_TYPE_GOVERNORATE" : The geographic region is a governorate.
  /// - "GEO_REGION_TYPE_CANTON" : The geographic region is a canton.
  /// - "GEO_REGION_TYPE_UNION_TERRITORY" : The geographic region is a union
  /// territory.
  /// - "GEO_REGION_TYPE_AUTONOMOUS_COMMUNITY" : The geographic region is an
  /// autonomous community.
  /// - "GEO_REGION_TYPE_DMA_REGION" : The geographic region is a designated
  /// market area (DMA) region.
  /// - "GEO_REGION_TYPE_METRO" : The geographic region type is metro.
  /// - "GEO_REGION_TYPE_CONGRESSIONAL_DISTRICT" : The geographic region is a
  /// congressional district.
  /// - "GEO_REGION_TYPE_COUNTY" : The geographic region is a county.
  /// - "GEO_REGION_TYPE_MUNICIPALITY" : The geographic region is a
  /// municipality.
  /// - "GEO_REGION_TYPE_CITY" : The geographic region is a city.
  /// - "GEO_REGION_TYPE_POSTAL_CODE" : The geographic region targeting type is
  /// postal code.
  /// - "GEO_REGION_TYPE_DEPARTMENT" : The geographic region targeting type is
  /// department.
  /// - "GEO_REGION_TYPE_AIRPORT" : The geographic region is an airport.
  /// - "GEO_REGION_TYPE_TV_REGION" : The geographic region is a TV region.
  /// - "GEO_REGION_TYPE_OKRUG" : The geographic region is an okrug.
  /// - "GEO_REGION_TYPE_BOROUGH" : The geographic region is a borough.
  /// - "GEO_REGION_TYPE_CITY_REGION" : The geographic region is a city region.
  /// - "GEO_REGION_TYPE_ARRONDISSEMENT" : The geographic region is an
  /// arrondissement.
  /// - "GEO_REGION_TYPE_NEIGHBORHOOD" : The geographic region is a
  /// neighborhood.
  /// - "GEO_REGION_TYPE_UNIVERSITY" : The geographic region is a university.
  /// - "GEO_REGION_TYPE_DISTRICT" : The geographic region is a district.
  core.String? geoRegionType;

  /// Indicates if this option is being negatively targeted.
  core.bool? negative;

  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_GEO_REGION`.
  ///
  /// Required.
  core.String? targetingOptionId;

  GeoRegionAssignedTargetingOptionDetails();

  GeoRegionAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('geoRegionType')) {
      geoRegionType = _json['geoRegionType'] as core.String;
    }
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (geoRegionType != null) 'geoRegionType': geoRegionType!,
        if (negative != null) 'negative': negative!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Search terms for geo region targeting options.
class GeoRegionSearchTerms {
  /// The search query for the desired geo region.
  ///
  /// The query can be a prefix, e.g. "New Yor", "Seattle", "USA", etc.
  core.String? geoRegionQuery;

  GeoRegionSearchTerms();

  GeoRegionSearchTerms.fromJson(core.Map _json) {
    if (_json.containsKey('geoRegionQuery')) {
      geoRegionQuery = _json['geoRegionQuery'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (geoRegionQuery != null) 'geoRegionQuery': geoRegionQuery!,
      };
}

/// Represents a targetable geographic region.
///
/// This will be populated in the geo_region_details field when targeting_type
/// is `TARGETING_TYPE_GEO_REGION`.
class GeoRegionTargetingOptionDetails {
  /// The display name of the geographic region (e.g., "Ontario, Canada").
  ///
  /// Output only.
  core.String? displayName;

  /// The type of geographic region targeting.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "GEO_REGION_TYPE_UNKNOWN" : The geographic region type is unknown.
  /// - "GEO_REGION_TYPE_OTHER" : The geographic region type is other.
  /// - "GEO_REGION_TYPE_COUNTRY" : The geographic region is a country.
  /// - "GEO_REGION_TYPE_REGION" : The geographic region type is region.
  /// - "GEO_REGION_TYPE_TERRITORY" : The geographic region is a territory.
  /// - "GEO_REGION_TYPE_PROVINCE" : The geographic region is a province.
  /// - "GEO_REGION_TYPE_STATE" : The geographic region is a state.
  /// - "GEO_REGION_TYPE_PREFECTURE" : The geographic region is a prefecture.
  /// - "GEO_REGION_TYPE_GOVERNORATE" : The geographic region is a governorate.
  /// - "GEO_REGION_TYPE_CANTON" : The geographic region is a canton.
  /// - "GEO_REGION_TYPE_UNION_TERRITORY" : The geographic region is a union
  /// territory.
  /// - "GEO_REGION_TYPE_AUTONOMOUS_COMMUNITY" : The geographic region is an
  /// autonomous community.
  /// - "GEO_REGION_TYPE_DMA_REGION" : The geographic region is a designated
  /// market area (DMA) region.
  /// - "GEO_REGION_TYPE_METRO" : The geographic region type is metro.
  /// - "GEO_REGION_TYPE_CONGRESSIONAL_DISTRICT" : The geographic region is a
  /// congressional district.
  /// - "GEO_REGION_TYPE_COUNTY" : The geographic region is a county.
  /// - "GEO_REGION_TYPE_MUNICIPALITY" : The geographic region is a
  /// municipality.
  /// - "GEO_REGION_TYPE_CITY" : The geographic region is a city.
  /// - "GEO_REGION_TYPE_POSTAL_CODE" : The geographic region targeting type is
  /// postal code.
  /// - "GEO_REGION_TYPE_DEPARTMENT" : The geographic region targeting type is
  /// department.
  /// - "GEO_REGION_TYPE_AIRPORT" : The geographic region is an airport.
  /// - "GEO_REGION_TYPE_TV_REGION" : The geographic region is a TV region.
  /// - "GEO_REGION_TYPE_OKRUG" : The geographic region is an okrug.
  /// - "GEO_REGION_TYPE_BOROUGH" : The geographic region is a borough.
  /// - "GEO_REGION_TYPE_CITY_REGION" : The geographic region is a city region.
  /// - "GEO_REGION_TYPE_ARRONDISSEMENT" : The geographic region is an
  /// arrondissement.
  /// - "GEO_REGION_TYPE_NEIGHBORHOOD" : The geographic region is a
  /// neighborhood.
  /// - "GEO_REGION_TYPE_UNIVERSITY" : The geographic region is a university.
  /// - "GEO_REGION_TYPE_DISTRICT" : The geographic region is a district.
  core.String? geoRegionType;

  GeoRegionTargetingOptionDetails();

  GeoRegionTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('geoRegionType')) {
      geoRegionType = _json['geoRegionType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (geoRegionType != null) 'geoRegionType': geoRegionType!,
      };
}

/// Describes a Google audience resource.
///
/// Includes Google audience lists.
class GoogleAudience {
  /// The display name of the Google audience.
  ///
  /// .
  ///
  /// Output only.
  core.String? displayName;

  /// The unique ID of the Google audience.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? googleAudienceId;

  /// The type of Google audience.
  ///
  /// .
  ///
  /// Output only.
  /// Possible string values are:
  /// - "GOOGLE_AUDIENCE_TYPE_UNSPECIFIED" : Default value when type is not
  /// specified or is unknown.
  /// - "GOOGLE_AUDIENCE_TYPE_AFFINITY" : Affinity type Google audience.
  /// - "GOOGLE_AUDIENCE_TYPE_IN_MARKET" : In-Market type Google audience.
  /// - "GOOGLE_AUDIENCE_TYPE_INSTALLED_APPS" : Installed-Apps type Google
  /// audience.
  /// - "GOOGLE_AUDIENCE_TYPE_NEW_MOBILE_DEVICES" : New-Mobile-Devices type
  /// Google audience.
  /// - "GOOGLE_AUDIENCE_TYPE_LIFE_EVENT" : Life-Event type Google audience.
  /// - "GOOGLE_AUDIENCE_TYPE_EXTENDED_DEMOGRAPHIC" : Extended-Demographic type
  /// Google audience.
  core.String? googleAudienceType;

  /// The resource name of the google audience.
  ///
  /// Output only.
  core.String? name;

  GoogleAudience();

  GoogleAudience.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('googleAudienceId')) {
      googleAudienceId = _json['googleAudienceId'] as core.String;
    }
    if (_json.containsKey('googleAudienceType')) {
      googleAudienceType = _json['googleAudienceType'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (googleAudienceId != null) 'googleAudienceId': googleAudienceId!,
        if (googleAudienceType != null)
          'googleAudienceType': googleAudienceType!,
        if (name != null) 'name': name!,
      };
}

/// Details of Google audience group.
///
/// All Google audience targeting settings are logically ‘OR’ of each other.
class GoogleAudienceGroup {
  /// All Google audience targeting settings in Google audience group.
  ///
  /// Repeated settings with same id will be ignored.
  ///
  /// Required.
  core.List<GoogleAudienceTargetingSetting>? settings;

  GoogleAudienceGroup();

  GoogleAudienceGroup.fromJson(core.Map _json) {
    if (_json.containsKey('settings')) {
      settings = (_json['settings'] as core.List)
          .map<GoogleAudienceTargetingSetting>((value) =>
              GoogleAudienceTargetingSetting.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (settings != null)
          'settings': settings!.map((value) => value.toJson()).toList(),
      };
}

/// Details of Google audience targeting setting.
class GoogleAudienceTargetingSetting {
  /// Google audience id of the Google audience targeting setting.
  ///
  /// This id is google_audience_id.
  ///
  /// Required.
  core.String? googleAudienceId;

  GoogleAudienceTargetingSetting();

  GoogleAudienceTargetingSetting.fromJson(core.Map _json) {
    if (_json.containsKey('googleAudienceId')) {
      googleAudienceId = _json['googleAudienceId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (googleAudienceId != null) 'googleAudienceId': googleAudienceId!,
      };
}

/// Media resource.
class GoogleBytestreamMedia {
  /// Name of the media resource.
  core.String? resourceName;

  GoogleBytestreamMedia();

  GoogleBytestreamMedia.fromJson(core.Map _json) {
    if (_json.containsKey('resourceName')) {
      resourceName = _json['resourceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceName != null) 'resourceName': resourceName!,
      };
}

/// Details for assigned household income targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_HOUSEHOLD_INCOME`.
class HouseholdIncomeAssignedTargetingOptionDetails {
  /// The household income of the audience.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "HOUSEHOLD_INCOME_UNSPECIFIED" : Default value when household income is
  /// not specified in this version. This enum is a placeholder for default
  /// value and does not represent a real household income option.
  /// - "HOUSEHOLD_INCOME_UNKNOWN" : The household income of the audience is
  /// unknown.
  /// - "HOUSEHOLD_INCOME_LOWER_50_PERCENT" : The audience is in the lower 50%
  /// of U.S. household incomes.
  /// - "HOUSEHOLD_INCOME_TOP_41_TO_50_PERCENT" : The audience is in the top
  /// 41-50% of U.S. household incomes.
  /// - "HOUSEHOLD_INCOME_TOP_31_TO_40_PERCENT" : The audience is in the top
  /// 31-40% of U.S. household incomes.
  /// - "HOUSEHOLD_INCOME_TOP_21_TO_30_PERCENT" : The audience is in the top
  /// 21-30% of U.S. household incomes.
  /// - "HOUSEHOLD_INCOME_TOP_11_TO_20_PERCENT" : The audience is in the top
  /// 11-20% of U.S. household incomes.
  /// - "HOUSEHOLD_INCOME_TOP_10_PERCENT" : The audience is in the top 10% of
  /// U.S. household incomes.
  core.String? householdIncome;

  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_HOUSEHOLD_INCOME`.
  ///
  /// Required.
  core.String? targetingOptionId;

  HouseholdIncomeAssignedTargetingOptionDetails();

  HouseholdIncomeAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('householdIncome')) {
      householdIncome = _json['householdIncome'] as core.String;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (householdIncome != null) 'householdIncome': householdIncome!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable household income.
///
/// This will be populated in the household_income_details field of a
/// TargetingOption when targeting_type is `TARGETING_TYPE_HOUSEHOLD_INCOME`.
class HouseholdIncomeTargetingOptionDetails {
  /// The household income of an audience.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "HOUSEHOLD_INCOME_UNSPECIFIED" : Default value when household income is
  /// not specified in this version. This enum is a placeholder for default
  /// value and does not represent a real household income option.
  /// - "HOUSEHOLD_INCOME_UNKNOWN" : The household income of the audience is
  /// unknown.
  /// - "HOUSEHOLD_INCOME_LOWER_50_PERCENT" : The audience is in the lower 50%
  /// of U.S. household incomes.
  /// - "HOUSEHOLD_INCOME_TOP_41_TO_50_PERCENT" : The audience is in the top
  /// 41-50% of U.S. household incomes.
  /// - "HOUSEHOLD_INCOME_TOP_31_TO_40_PERCENT" : The audience is in the top
  /// 31-40% of U.S. household incomes.
  /// - "HOUSEHOLD_INCOME_TOP_21_TO_30_PERCENT" : The audience is in the top
  /// 21-30% of U.S. household incomes.
  /// - "HOUSEHOLD_INCOME_TOP_11_TO_20_PERCENT" : The audience is in the top
  /// 11-20% of U.S. household incomes.
  /// - "HOUSEHOLD_INCOME_TOP_10_PERCENT" : The audience is in the top 10% of
  /// U.S. household incomes.
  core.String? householdIncome;

  HouseholdIncomeTargetingOptionDetails();

  HouseholdIncomeTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('householdIncome')) {
      householdIncome = _json['householdIncome'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (householdIncome != null) 'householdIncome': householdIncome!,
      };
}

/// A filtering option that filters entities by their entity IDs.
class IdFilter {
  /// YouTube Ads to download by ID.
  ///
  /// All IDs must belong to the same Advertiser or Partner specified in
  /// CreateSdfDownloadTaskRequest.
  core.List<core.String>? adGroupAdIds;

  /// YouTube Ad Groups to download by ID.
  ///
  /// All IDs must belong to the same Advertiser or Partner specified in
  /// CreateSdfDownloadTaskRequest.
  core.List<core.String>? adGroupIds;

  /// Campaigns to download by ID.
  ///
  /// All IDs must belong to the same Advertiser or Partner specified in
  /// CreateSdfDownloadTaskRequest.
  core.List<core.String>? campaignIds;

  /// Insertion Orders to download by ID.
  ///
  /// All IDs must belong to the same Advertiser or Partner specified in
  /// CreateSdfDownloadTaskRequest.
  core.List<core.String>? insertionOrderIds;

  /// Line Items to download by ID.
  ///
  /// All IDs must belong to the same Advertiser or Partner specified in
  /// CreateSdfDownloadTaskRequest.
  core.List<core.String>? lineItemIds;

  /// Media Products to download by ID.
  ///
  /// All IDs must belong to the same Advertiser or Partner specified in
  /// CreateSdfDownloadTaskRequest.
  core.List<core.String>? mediaProductIds;

  IdFilter();

  IdFilter.fromJson(core.Map _json) {
    if (_json.containsKey('adGroupAdIds')) {
      adGroupAdIds = (_json['adGroupAdIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('adGroupIds')) {
      adGroupIds = (_json['adGroupIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('campaignIds')) {
      campaignIds = (_json['campaignIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('insertionOrderIds')) {
      insertionOrderIds = (_json['insertionOrderIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('lineItemIds')) {
      lineItemIds = (_json['lineItemIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('mediaProductIds')) {
      mediaProductIds = (_json['mediaProductIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adGroupAdIds != null) 'adGroupAdIds': adGroupAdIds!,
        if (adGroupIds != null) 'adGroupIds': adGroupIds!,
        if (campaignIds != null) 'campaignIds': campaignIds!,
        if (insertionOrderIds != null) 'insertionOrderIds': insertionOrderIds!,
        if (lineItemIds != null) 'lineItemIds': lineItemIds!,
        if (mediaProductIds != null) 'mediaProductIds': mediaProductIds!,
      };
}

/// A single insertion order.
class InsertionOrder {
  /// The unique ID of the advertiser the insertion order belongs to.
  ///
  /// Output only.
  core.String? advertiserId;

  /// The bidding strategy of the insertion order.
  ///
  /// By default, fixed_bid is set.
  BiddingStrategy? bidStrategy;

  /// The budget allocation settings of the insertion order.
  ///
  /// Required.
  InsertionOrderBudget? budget;

  /// The unique ID of the campaign that the insertion order belongs to.
  ///
  /// Required. Immutable.
  core.String? campaignId;

  /// The display name of the insertion order.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// Controls whether or not the insertion order can spend its budget and bid
  /// on inventory.
  ///
  /// * For CreateInsertionOrder method, only `ENTITY_STATUS_DRAFT` is allowed.
  /// To activate an insertion order, use UpdateInsertionOrder method and update
  /// the status to `ENTITY_STATUS_ACTIVE` after creation. * An insertion order
  /// cannot be changed back to `ENTITY_STATUS_DRAFT` status from any other
  /// status. * An insertion order cannot be set to `ENTITY_STATUS_ACTIVE` if
  /// its parent campaign is not active.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ENTITY_STATUS_UNSPECIFIED" : Default value when status is not specified
  /// or is unknown in this version.
  /// - "ENTITY_STATUS_ACTIVE" : The entity is enabled to bid and spend budget.
  /// - "ENTITY_STATUS_ARCHIVED" : The entity is archived. Bidding and budget
  /// spending are disabled. An entity can be deleted after archived. Deleted
  /// entities cannot be retrieved.
  /// - "ENTITY_STATUS_DRAFT" : The entity is under draft. Bidding and budget
  /// spending are disabled.
  /// - "ENTITY_STATUS_PAUSED" : Bidding and budget spending are paused for the
  /// entity.
  /// - "ENTITY_STATUS_SCHEDULED_FOR_DELETION" : The entity is scheduled for
  /// deletion.
  core.String? entityStatus;

  /// The frequency capping setting of the insertion order.
  ///
  /// Required.
  FrequencyCap? frequencyCap;

  /// The unique ID of the insertion order.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? insertionOrderId;

  /// The type of insertion order.
  ///
  /// If this field is unspecified in creation, the value defaults to `RTB`.
  /// Possible string values are:
  /// - "INSERTION_ORDER_TYPE_UNSPECIFIED" : Insertion order type is not
  /// specified or is unknown.
  /// - "RTB" : Real-time bidding.
  /// - "OVER_THE_TOP" : Over-the-top.
  core.String? insertionOrderType;

  /// Additional integration details of the insertion order.
  IntegrationDetails? integrationDetails;

  /// The resource name of the insertion order.
  ///
  /// Output only.
  core.String? name;

  /// The budget spending speed setting of the insertion order.
  ///
  /// Required.
  Pacing? pacing;

  /// The partner costs associated with the insertion order.
  ///
  /// If absent or empty in CreateInsertionOrder method, the newly created
  /// insertion order will inherit partner costs from the partner settings.
  core.List<PartnerCost>? partnerCosts;

  /// Performance goal of the insertion order.
  ///
  /// Required.
  PerformanceGoal? performanceGoal;

  /// The timestamp when the insertion order was last updated.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? updateTime;

  InsertionOrder();

  InsertionOrder.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('bidStrategy')) {
      bidStrategy = BiddingStrategy.fromJson(
          _json['bidStrategy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('budget')) {
      budget = InsertionOrderBudget.fromJson(
          _json['budget'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('campaignId')) {
      campaignId = _json['campaignId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('entityStatus')) {
      entityStatus = _json['entityStatus'] as core.String;
    }
    if (_json.containsKey('frequencyCap')) {
      frequencyCap = FrequencyCap.fromJson(
          _json['frequencyCap'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertionOrderId')) {
      insertionOrderId = _json['insertionOrderId'] as core.String;
    }
    if (_json.containsKey('insertionOrderType')) {
      insertionOrderType = _json['insertionOrderType'] as core.String;
    }
    if (_json.containsKey('integrationDetails')) {
      integrationDetails = IntegrationDetails.fromJson(
          _json['integrationDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('pacing')) {
      pacing = Pacing.fromJson(
          _json['pacing'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('partnerCosts')) {
      partnerCosts = (_json['partnerCosts'] as core.List)
          .map<PartnerCost>((value) => PartnerCost.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('performanceGoal')) {
      performanceGoal = PerformanceGoal.fromJson(
          _json['performanceGoal'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (bidStrategy != null) 'bidStrategy': bidStrategy!.toJson(),
        if (budget != null) 'budget': budget!.toJson(),
        if (campaignId != null) 'campaignId': campaignId!,
        if (displayName != null) 'displayName': displayName!,
        if (entityStatus != null) 'entityStatus': entityStatus!,
        if (frequencyCap != null) 'frequencyCap': frequencyCap!.toJson(),
        if (insertionOrderId != null) 'insertionOrderId': insertionOrderId!,
        if (insertionOrderType != null)
          'insertionOrderType': insertionOrderType!,
        if (integrationDetails != null)
          'integrationDetails': integrationDetails!.toJson(),
        if (name != null) 'name': name!,
        if (pacing != null) 'pacing': pacing!.toJson(),
        if (partnerCosts != null)
          'partnerCosts': partnerCosts!.map((value) => value.toJson()).toList(),
        if (performanceGoal != null)
          'performanceGoal': performanceGoal!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Settings that control how insertion order budget is allocated.
class InsertionOrderBudget {
  /// The type of automation used to manage bid and budget for the insertion
  /// order.
  ///
  /// If this field is unspecified in creation, the value defaults to
  /// `INSERTION_ORDER_AUTOMATION_TYPE_NONE`.
  /// Possible string values are:
  /// - "INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED" : Insertion order
  /// automation option is not specified or is unknown in this version.
  /// - "INSERTION_ORDER_AUTOMATION_TYPE_BUDGET" : Automatic budget allocation.
  /// Allow the system to automatically shift budget to owning line items to
  /// optimize performance defined by performance_goal. No automation on bid
  /// settings.
  /// - "INSERTION_ORDER_AUTOMATION_TYPE_NONE" : No automation of bid or budget
  /// on insertion order level. Bid and budget must be manually configured at
  /// the line item level.
  /// - "INSERTION_ORDER_AUTOMATION_TYPE_BID_BUDGET" : Allow the system to
  /// automatically adjust bids and shift budget to owning line items to
  /// optimize performance defined by performance_goal.
  core.String? automationType;

  /// The list of budget segments.
  ///
  /// Use a budget segment to specify a specific budget for a given period of
  /// time an insertion order is running.
  ///
  /// Required.
  core.List<InsertionOrderBudgetSegment>? budgetSegments;

  /// The budget unit specifies whether the budget is currency based or
  /// impression based.
  ///
  /// Required. Immutable.
  /// Possible string values are:
  /// - "BUDGET_UNIT_UNSPECIFIED" : Type value is not specified or is unknown in
  /// this version.
  /// - "BUDGET_UNIT_CURRENCY" : Budgeting in currency amounts.
  /// - "BUDGET_UNIT_IMPRESSIONS" : Budgeting in impression amounts.
  core.String? budgetUnit;

  InsertionOrderBudget();

  InsertionOrderBudget.fromJson(core.Map _json) {
    if (_json.containsKey('automationType')) {
      automationType = _json['automationType'] as core.String;
    }
    if (_json.containsKey('budgetSegments')) {
      budgetSegments = (_json['budgetSegments'] as core.List)
          .map<InsertionOrderBudgetSegment>((value) =>
              InsertionOrderBudgetSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('budgetUnit')) {
      budgetUnit = _json['budgetUnit'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (automationType != null) 'automationType': automationType!,
        if (budgetSegments != null)
          'budgetSegments':
              budgetSegments!.map((value) => value.toJson()).toList(),
        if (budgetUnit != null) 'budgetUnit': budgetUnit!,
      };
}

/// Settings that control the budget of a single budget segment.
class InsertionOrderBudgetSegment {
  /// The budget amount the insertion order will spend for the given date_range.
  ///
  /// The amount is in micros. Must be greater than 0. For example, 500000000
  /// represents 500 standard units of the currency.
  ///
  /// Required.
  core.String? budgetAmountMicros;

  /// The ID of the campaign budget linked to this insertion order budget
  /// segment.
  core.String? campaignBudgetId;

  /// The start and end date settings of the budget segment.
  ///
  /// They are resolved relative to the parent advertiser's time zone. * When
  /// creating a new budget segment, both `start_date` and `end_date` must be in
  /// the future. * An existing budget segment with a `start_date` in the past
  /// has a mutable `end_date` but an immutable `start_date`. * `end_date` must
  /// be the `start_date` or later, both before the year 2037.
  ///
  /// Required.
  DateRange? dateRange;

  /// The budget segment description.
  ///
  /// It can be used to enter Purchase Order information for each budget segment
  /// and have that information printed on the invoices. Must be UTF-8 encoded
  /// with a length of no more than 80 characters.
  core.String? description;

  InsertionOrderBudgetSegment();

  InsertionOrderBudgetSegment.fromJson(core.Map _json) {
    if (_json.containsKey('budgetAmountMicros')) {
      budgetAmountMicros = _json['budgetAmountMicros'] as core.String;
    }
    if (_json.containsKey('campaignBudgetId')) {
      campaignBudgetId = _json['campaignBudgetId'] as core.String;
    }
    if (_json.containsKey('dateRange')) {
      dateRange = DateRange.fromJson(
          _json['dateRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (budgetAmountMicros != null)
          'budgetAmountMicros': budgetAmountMicros!,
        if (campaignBudgetId != null) 'campaignBudgetId': campaignBudgetId!,
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
        if (description != null) 'description': description!,
      };
}

/// Details of Integral Ad Science settings.
class IntegralAdScience {
  /// The custom segment ID provided by Integral Ad Science.
  ///
  /// The ID must be between `1000001` and `1999999`, inclusive.
  core.List<core.String>? customSegmentId;

  /// Display Viewability section (applicable to display line items only).
  /// Possible string values are:
  /// - "PERFORMANCE_VIEWABILITY_UNSPECIFIED" : This enum is only a placeholder
  /// and it doesn't specify any display viewability options.
  /// - "PERFORMANCE_VIEWABILITY_40" : Target 40% Viewability or Higher.
  /// - "PERFORMANCE_VIEWABILITY_50" : Target 50% Viewability or Higher.
  /// - "PERFORMANCE_VIEWABILITY_60" : Target 60% Viewability or Higher.
  /// - "PERFORMANCE_VIEWABILITY_70" : Target 70% Viewability or Higher.
  core.String? displayViewability;

  /// Brand Safety - **Unrateable**.
  core.bool? excludeUnrateable;

  /// Ad Fraud settings.
  /// Possible string values are:
  /// - "SUSPICIOUS_ACTIVITY_UNSPECIFIED" : This enum is only a placeholder and
  /// it doesn't specify any ad fraud prevention options.
  /// - "SUSPICIOUS_ACTIVITY_HR" : Ad Fraud - Exclude High Risk.
  /// - "SUSPICIOUS_ACTIVITY_HMR" : Ad Fraud - Exclude High and Moderate Risk.
  core.String? excludedAdFraudRisk;

  /// Brand Safety - **Adult content**.
  /// Possible string values are:
  /// - "ADULT_UNSPECIFIED" : This enum is only a placeholder and it doesn't
  /// specify any adult options.
  /// - "ADULT_HR" : Adult - Exclude High Risk.
  /// - "ADULT_HMR" : Adult - Exclude High and Moderate Risk.
  core.String? excludedAdultRisk;

  /// Brand Safety - **Alcohol**.
  /// Possible string values are:
  /// - "ALCOHOL_UNSPECIFIED" : This enum is only a placeholder and it doesn't
  /// specify any alcohol options.
  /// - "ALCOHOL_HR" : Alcohol - Exclude High Risk.
  /// - "ALCOHOL_HMR" : Alcohol - Exclude High and Moderate Risk.
  core.String? excludedAlcoholRisk;

  /// Brand Safety - **Drugs**.
  /// Possible string values are:
  /// - "DRUGS_UNSPECIFIED" : This enum is only a placeholder and it doesn't
  /// specify any drugs options.
  /// - "DRUGS_HR" : Drugs - Exclude High Risk.
  /// - "DRUGS_HMR" : Drugs - Exclude High and Moderate Risk.
  core.String? excludedDrugsRisk;

  /// Brand Safety - **Gambling**.
  /// Possible string values are:
  /// - "GAMBLING_UNSPECIFIED" : This enum is only a placeholder and it doesn't
  /// specify any gambling options.
  /// - "GAMBLING_HR" : Gambling - Exclude High Risk.
  /// - "GAMBLING_HMR" : Gambling - Exclude High and Moderate Risk.
  core.String? excludedGamblingRisk;

  /// Brand Safety - **Hate speech**.
  /// Possible string values are:
  /// - "HATE_SPEECH_UNSPECIFIED" : This enum is only a placeholder and it
  /// doesn't specify any hate speech options.
  /// - "HATE_SPEECH_HR" : Hate Speech - Exclude High Risk.
  /// - "HATE_SPEECH_HMR" : Hate Speech - Exclude High and Moderate Risk.
  core.String? excludedHateSpeechRisk;

  /// Brand Safety - **Illegal downloads**.
  /// Possible string values are:
  /// - "ILLEGAL_DOWNLOADS_UNSPECIFIED" : This enum is only a placeholder and it
  /// doesn't specify any illegal downloads options.
  /// - "ILLEGAL_DOWNLOADS_HR" : Illegal Downloads - Exclude High Risk.
  /// - "ILLEGAL_DOWNLOADS_HMR" : Illegal Downloads - Exclude High and Moderate
  /// Risk.
  core.String? excludedIllegalDownloadsRisk;

  /// Brand Safety - **Offensive language**.
  /// Possible string values are:
  /// - "OFFENSIVE_LANGUAGE_UNSPECIFIED" : This enum is only a placeholder and
  /// it doesn't specify any language options.
  /// - "OFFENSIVE_LANGUAGE_HR" : Offensive Language - Exclude High Risk.
  /// - "OFFENSIVE_LANGUAGE_HMR" : Offensive Language - Exclude High and
  /// Moderate Risk.
  core.String? excludedOffensiveLanguageRisk;

  /// Brand Safety - **Violence**.
  /// Possible string values are:
  /// - "VIOLENCE_UNSPECIFIED" : This enum is only a placeholder and it doesn't
  /// specify any violence options.
  /// - "VIOLENCE_HR" : Violence - Exclude High Risk.
  /// - "VIOLENCE_HMR" : Violence - Exclude High and Moderate Risk.
  core.String? excludedViolenceRisk;

  /// True advertising quality (applicable to Display line items only).
  /// Possible string values are:
  /// - "TRAQ_UNSPECIFIED" : This enum is only a placeholder and it doesn't
  /// specify any true advertising quality scores.
  /// - "TRAQ_250" : TRAQ score 250-1000.
  /// - "TRAQ_500" : TRAQ score 500-1000.
  /// - "TRAQ_600" : TRAQ score 600-1000.
  /// - "TRAQ_700" : TRAQ score 700-1000.
  /// - "TRAQ_750" : TRAQ score 750-1000.
  /// - "TRAQ_875" : TRAQ score 875-1000.
  /// - "TRAQ_1000" : TRAQ score 1000.
  core.String? traqScoreOption;

  /// Video Viewability Section (applicable to video line items only).
  /// Possible string values are:
  /// - "VIDEO_VIEWABILITY_UNSPECIFIED" : This enum is only a placeholder and it
  /// doesn't specify any video viewability options.
  /// - "VIDEO_VIEWABILITY_40" : 40%+ in view (IAB video viewability standard).
  /// - "VIDEO_VIEWABILITY_50" : 50%+ in view (IAB video viewability standard).
  /// - "VIDEO_VIEWABILITY_60" : 60%+ in view (IAB video viewability standard).
  /// - "VIDEO_VIEWABILITY_70" : 70%+ in view (IAB video viewability standard).
  core.String? videoViewability;

  IntegralAdScience();

  IntegralAdScience.fromJson(core.Map _json) {
    if (_json.containsKey('customSegmentId')) {
      customSegmentId = (_json['customSegmentId'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('displayViewability')) {
      displayViewability = _json['displayViewability'] as core.String;
    }
    if (_json.containsKey('excludeUnrateable')) {
      excludeUnrateable = _json['excludeUnrateable'] as core.bool;
    }
    if (_json.containsKey('excludedAdFraudRisk')) {
      excludedAdFraudRisk = _json['excludedAdFraudRisk'] as core.String;
    }
    if (_json.containsKey('excludedAdultRisk')) {
      excludedAdultRisk = _json['excludedAdultRisk'] as core.String;
    }
    if (_json.containsKey('excludedAlcoholRisk')) {
      excludedAlcoholRisk = _json['excludedAlcoholRisk'] as core.String;
    }
    if (_json.containsKey('excludedDrugsRisk')) {
      excludedDrugsRisk = _json['excludedDrugsRisk'] as core.String;
    }
    if (_json.containsKey('excludedGamblingRisk')) {
      excludedGamblingRisk = _json['excludedGamblingRisk'] as core.String;
    }
    if (_json.containsKey('excludedHateSpeechRisk')) {
      excludedHateSpeechRisk = _json['excludedHateSpeechRisk'] as core.String;
    }
    if (_json.containsKey('excludedIllegalDownloadsRisk')) {
      excludedIllegalDownloadsRisk =
          _json['excludedIllegalDownloadsRisk'] as core.String;
    }
    if (_json.containsKey('excludedOffensiveLanguageRisk')) {
      excludedOffensiveLanguageRisk =
          _json['excludedOffensiveLanguageRisk'] as core.String;
    }
    if (_json.containsKey('excludedViolenceRisk')) {
      excludedViolenceRisk = _json['excludedViolenceRisk'] as core.String;
    }
    if (_json.containsKey('traqScoreOption')) {
      traqScoreOption = _json['traqScoreOption'] as core.String;
    }
    if (_json.containsKey('videoViewability')) {
      videoViewability = _json['videoViewability'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customSegmentId != null) 'customSegmentId': customSegmentId!,
        if (displayViewability != null)
          'displayViewability': displayViewability!,
        if (excludeUnrateable != null) 'excludeUnrateable': excludeUnrateable!,
        if (excludedAdFraudRisk != null)
          'excludedAdFraudRisk': excludedAdFraudRisk!,
        if (excludedAdultRisk != null) 'excludedAdultRisk': excludedAdultRisk!,
        if (excludedAlcoholRisk != null)
          'excludedAlcoholRisk': excludedAlcoholRisk!,
        if (excludedDrugsRisk != null) 'excludedDrugsRisk': excludedDrugsRisk!,
        if (excludedGamblingRisk != null)
          'excludedGamblingRisk': excludedGamblingRisk!,
        if (excludedHateSpeechRisk != null)
          'excludedHateSpeechRisk': excludedHateSpeechRisk!,
        if (excludedIllegalDownloadsRisk != null)
          'excludedIllegalDownloadsRisk': excludedIllegalDownloadsRisk!,
        if (excludedOffensiveLanguageRisk != null)
          'excludedOffensiveLanguageRisk': excludedOffensiveLanguageRisk!,
        if (excludedViolenceRisk != null)
          'excludedViolenceRisk': excludedViolenceRisk!,
        if (traqScoreOption != null) 'traqScoreOption': traqScoreOption!,
        if (videoViewability != null) 'videoViewability': videoViewability!,
      };
}

/// Integration details of an entry.
class IntegrationDetails {
  /// Additional details of the entry in string format.
  ///
  /// Must be UTF-8 encoded with a length of no more than 1000 characters.
  core.String? details;

  /// An external identifier to be associated with the entry.
  ///
  /// The integration code will show up together with the entry in many places
  /// in the system, for example, reporting. Must be UTF-8 encoded with a length
  /// of no more than 500 characters.
  core.String? integrationCode;

  IntegrationDetails();

  IntegrationDetails.fromJson(core.Map _json) {
    if (_json.containsKey('details')) {
      details = _json['details'] as core.String;
    }
    if (_json.containsKey('integrationCode')) {
      integrationCode = _json['integrationCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (details != null) 'details': details!,
        if (integrationCode != null) 'integrationCode': integrationCode!,
      };
}

/// An inventory source.
class InventorySource {
  /// Whether the inventory source has a guaranteed or non-guaranteed delivery.
  /// Possible string values are:
  /// - "INVENTORY_SOURCE_COMMITMENT_UNSPECIFIED" : The commitment is not
  /// specified or is unknown in this version.
  /// - "INVENTORY_SOURCE_COMMITMENT_GUARANTEED" : The commitment is guaranteed
  /// delivery.
  /// - "INVENTORY_SOURCE_COMMITMENT_NON_GUARANTEED" : The commitment is
  /// non-guaranteed delivery.
  core.String? commitment;

  /// The creative requirements of the inventory source.
  ///
  /// Not applicable for auction packages.
  core.List<CreativeConfig>? creativeConfigs;

  /// The ID in the exchange space that uniquely identifies the inventory
  /// source.
  ///
  /// Must be unique across buyers within each exchange but not necessarily
  /// unique across exchanges.
  core.String? dealId;

  /// The delivery method of the inventory source.
  ///
  /// * For non-guaranteed inventory sources, the only acceptable value is
  /// `INVENTORY_SOURCE_DELIVERY_METHOD_PROGRAMMATIC`. * For guaranteed
  /// inventory sources, acceptable values are
  /// `INVENTORY_SOURCE_DELIVERY_METHOD_TAG` and
  /// `INVENTORY_SOURCE_DELIVERY_METHOD_PROGRAMMATIC`.
  /// Possible string values are:
  /// - "INVENTORY_SOURCE_DELIVERY_METHOD_UNSPECIFIED" : The delivery method is
  /// not specified or is unknown in this version.
  /// - "INVENTORY_SOURCE_DELIVERY_METHOD_PROGRAMMATIC" : The delivery method is
  /// programmatic.
  /// - "INVENTORY_SOURCE_DELIVERY_METHOD_TAG" : The delivery method is tag.
  core.String? deliveryMethod;

  /// The display name of the inventory source.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  core.String? displayName;

  /// The exchange to which the inventory source belongs.
  /// Possible string values are:
  /// - "EXCHANGE_UNSPECIFIED" : Exchange is not specified or is unknown in this
  /// version.
  /// - "EXCHANGE_GOOGLE_AD_MANAGER" : Google Ad Manager.
  /// - "EXCHANGE_APPNEXUS" : AppNexus.
  /// - "EXCHANGE_BRIGHTROLL" : BrightRoll Exchange for Video from Yahoo!.
  /// - "EXCHANGE_ADFORM" : Adform.
  /// - "EXCHANGE_ADMETA" : Admeta.
  /// - "EXCHANGE_ADMIXER" : Admixer.
  /// - "EXCHANGE_ADSMOGO" : AdsMogo.
  /// - "EXCHANGE_ADSWIZZ" : AdsWizz.
  /// - "EXCHANGE_BIDSWITCH" : BidSwitch.
  /// - "EXCHANGE_BRIGHTROLL_DISPLAY" : BrightRoll Exchange for Display from
  /// Yahoo!.
  /// - "EXCHANGE_CADREON" : Cadreon.
  /// - "EXCHANGE_DAILYMOTION" : Dailymotion.
  /// - "EXCHANGE_FIVE" : Five.
  /// - "EXCHANGE_FLUCT" : Fluct.
  /// - "EXCHANGE_FREEWHEEL" : FreeWheel SSP.
  /// - "EXCHANGE_GENIEE" : Geniee.
  /// - "EXCHANGE_GUMGUM" : GumGum.
  /// - "EXCHANGE_IMOBILE" : i-mobile.
  /// - "EXCHANGE_IBILLBOARD" : iBILLBOARD.
  /// - "EXCHANGE_IMPROVE_DIGITAL" : Improve Digital.
  /// - "EXCHANGE_INDEX" : Index Exchange.
  /// - "EXCHANGE_KARGO" : Kargo.
  /// - "EXCHANGE_MICROAD" : MicroAd.
  /// - "EXCHANGE_MOPUB" : MoPub.
  /// - "EXCHANGE_NEND" : Nend.
  /// - "EXCHANGE_ONE_BY_AOL_DISPLAY" : ONE by AOL: Display Market Place.
  /// - "EXCHANGE_ONE_BY_AOL_MOBILE" : ONE by AOL: Mobile.
  /// - "EXCHANGE_ONE_BY_AOL_VIDEO" : ONE by AOL: Video.
  /// - "EXCHANGE_OOYALA" : Ooyala.
  /// - "EXCHANGE_OPENX" : OpenX.
  /// - "EXCHANGE_PERMODO" : Permodo.
  /// - "EXCHANGE_PLATFORMONE" : Platform One.
  /// - "EXCHANGE_PLATFORMID" : PlatformId.
  /// - "EXCHANGE_PUBMATIC" : PubMatic.
  /// - "EXCHANGE_PULSEPOINT" : PulsePoint.
  /// - "EXCHANGE_REVENUEMAX" : RevenueMax.
  /// - "EXCHANGE_RUBICON" : Rubicon.
  /// - "EXCHANGE_SMARTCLIP" : SmartClip.
  /// - "EXCHANGE_SMARTRTB" : SmartRTB+.
  /// - "EXCHANGE_SMARTSTREAMTV" : SmartstreamTv.
  /// - "EXCHANGE_SOVRN" : Sovrn.
  /// - "EXCHANGE_SPOTXCHANGE" : SpotXchange.
  /// - "EXCHANGE_STROER" : Ströer SSP.
  /// - "EXCHANGE_TEADSTV" : TeadsTv.
  /// - "EXCHANGE_TELARIA" : Telaria.
  /// - "EXCHANGE_TVN" : TVN.
  /// - "EXCHANGE_UNITED" : United.
  /// - "EXCHANGE_YIELDLAB" : Yieldlab.
  /// - "EXCHANGE_YIELDMO" : Yieldmo.
  /// - "EXCHANGE_UNRULYX" : UnrulyX.
  /// - "EXCHANGE_OPEN8" : Open8.
  /// - "EXCHANGE_TRITON" : Triton.
  /// - "EXCHANGE_TRIPLELIFT" : TripleLift.
  /// - "EXCHANGE_TABOOLA" : Taboola.
  /// - "EXCHANGE_INMOBI" : InMobi.
  /// - "EXCHANGE_SMAATO" : Smaato.
  /// - "EXCHANGE_AJA" : Aja.
  /// - "EXCHANGE_SUPERSHIP" : Supership.
  /// - "EXCHANGE_NEXSTAR_DIGITAL" : Nexstar Digital.
  /// - "EXCHANGE_WAZE" : Waze.
  /// - "EXCHANGE_SOUNDCAST" : SoundCast.
  /// - "EXCHANGE_SHARETHROUGH" : Sharethrough.
  /// - "EXCHANGE_MEDIANET" : Media.net.
  core.String? exchange;

  /// The unique ID of the inventory source.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? inventorySourceId;

  /// Denotes the type of the inventory source.
  /// Possible string values are:
  /// - "INVENTORY_SOURCE_TYPE_UNSPECIFIED" : The inventory source type is not
  /// specified or is unknown in this version.
  /// - "INVENTORY_SOURCE_TYPE_PRIVATE" : Private inventory source.
  /// - "INVENTORY_SOURCE_TYPE_AUCTION_PACKAGE" : Auction package.
  core.String? inventorySourceType;

  /// The resource name of the inventory source.
  ///
  /// Output only.
  core.String? name;

  /// The publisher/seller name of the inventory source.
  core.String? publisherName;

  /// The rate details of the inventory source.
  ///
  /// Required.
  RateDetails? rateDetails;

  /// The status settings of the inventory source.
  InventorySourceStatus? status;

  /// The time range when this inventory source starts and stops serving.
  TimeRange? timeRange;

  /// The timestamp when the inventory source was last updated.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? updateTime;

  InventorySource();

  InventorySource.fromJson(core.Map _json) {
    if (_json.containsKey('commitment')) {
      commitment = _json['commitment'] as core.String;
    }
    if (_json.containsKey('creativeConfigs')) {
      creativeConfigs = (_json['creativeConfigs'] as core.List)
          .map<CreativeConfig>((value) => CreativeConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dealId')) {
      dealId = _json['dealId'] as core.String;
    }
    if (_json.containsKey('deliveryMethod')) {
      deliveryMethod = _json['deliveryMethod'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('exchange')) {
      exchange = _json['exchange'] as core.String;
    }
    if (_json.containsKey('inventorySourceId')) {
      inventorySourceId = _json['inventorySourceId'] as core.String;
    }
    if (_json.containsKey('inventorySourceType')) {
      inventorySourceType = _json['inventorySourceType'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('publisherName')) {
      publisherName = _json['publisherName'] as core.String;
    }
    if (_json.containsKey('rateDetails')) {
      rateDetails = RateDetails.fromJson(
          _json['rateDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = InventorySourceStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeRange')) {
      timeRange = TimeRange.fromJson(
          _json['timeRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commitment != null) 'commitment': commitment!,
        if (creativeConfigs != null)
          'creativeConfigs':
              creativeConfigs!.map((value) => value.toJson()).toList(),
        if (dealId != null) 'dealId': dealId!,
        if (deliveryMethod != null) 'deliveryMethod': deliveryMethod!,
        if (displayName != null) 'displayName': displayName!,
        if (exchange != null) 'exchange': exchange!,
        if (inventorySourceId != null) 'inventorySourceId': inventorySourceId!,
        if (inventorySourceType != null)
          'inventorySourceType': inventorySourceType!,
        if (name != null) 'name': name!,
        if (publisherName != null) 'publisherName': publisherName!,
        if (rateDetails != null) 'rateDetails': rateDetails!.toJson(),
        if (status != null) 'status': status!.toJson(),
        if (timeRange != null) 'timeRange': timeRange!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Targeting details for inventory source.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_INVENTORY_SOURCE`.
class InventorySourceAssignedTargetingOptionDetails {
  /// ID of the inventory source.
  ///
  /// Should refer to the inventory_source_id field of an InventorySource
  /// resource.
  ///
  /// Required.
  core.String? inventorySourceId;

  InventorySourceAssignedTargetingOptionDetails();

  InventorySourceAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('inventorySourceId')) {
      inventorySourceId = _json['inventorySourceId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inventorySourceId != null) 'inventorySourceId': inventorySourceId!,
      };
}

/// The configuration for display creatives.
class InventorySourceDisplayCreativeConfig {
  /// The size requirements for display creatives that can be assigned to the
  /// inventory source.
  Dimensions? creativeSize;

  InventorySourceDisplayCreativeConfig();

  InventorySourceDisplayCreativeConfig.fromJson(core.Map _json) {
    if (_json.containsKey('creativeSize')) {
      creativeSize = Dimensions.fromJson(
          _json['creativeSize'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creativeSize != null) 'creativeSize': creativeSize!.toJson(),
      };
}

/// A filtering option for filtering on Inventory Source entities.
class InventorySourceFilter {
  /// Inventory Sources to download by ID.
  ///
  /// All IDs must belong to the same Advertiser or Partner specified in
  /// CreateSdfDownloadTaskRequest. Leave empty to download all Inventory
  /// Sources for the selected Advertiser or Partner.
  core.List<core.String>? inventorySourceIds;

  InventorySourceFilter();

  InventorySourceFilter.fromJson(core.Map _json) {
    if (_json.containsKey('inventorySourceIds')) {
      inventorySourceIds = (_json['inventorySourceIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inventorySourceIds != null)
          'inventorySourceIds': inventorySourceIds!,
      };
}

/// A collection of targetable inventory sources.
class InventorySourceGroup {
  /// The display name of the inventory source group.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// The unique ID of the inventory source group.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? inventorySourceGroupId;

  /// The resource name of the inventory source group.
  ///
  /// Output only.
  core.String? name;

  InventorySourceGroup();

  InventorySourceGroup.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('inventorySourceGroupId')) {
      inventorySourceGroupId = _json['inventorySourceGroupId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (inventorySourceGroupId != null)
          'inventorySourceGroupId': inventorySourceGroupId!,
        if (name != null) 'name': name!,
      };
}

/// Targeting details for inventory source group.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_INVENTORY_SOURCE_GROUP`.
class InventorySourceGroupAssignedTargetingOptionDetails {
  /// ID of the inventory source group.
  ///
  /// Should refer to the inventory_source_group_id field of an
  /// InventorySourceGroup resource.
  ///
  /// Required.
  core.String? inventorySourceGroupId;

  InventorySourceGroupAssignedTargetingOptionDetails();

  InventorySourceGroupAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('inventorySourceGroupId')) {
      inventorySourceGroupId = _json['inventorySourceGroupId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inventorySourceGroupId != null)
          'inventorySourceGroupId': inventorySourceGroupId!,
      };
}

/// The status related settings of the inventory source.
class InventorySourceStatus {
  /// The configuration status of the inventory source.
  ///
  /// Only applicable for guaranteed inventory sources. Acceptable values are
  /// `INVENTORY_SOURCE_CONFIG_STATUS_PENDING` and
  /// `INVENTORY_SOURCE_CONFIG_STATUS_COMPLETED`. An inventory source must be
  /// configured (fill in the required fields, choose creatives, and select a
  /// default campaign) before it can serve.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "INVENTORY_SOURCE_CONFIG_STATUS_UNSPECIFIED" : The approval status is
  /// not specified or is unknown in this version.
  /// - "INVENTORY_SOURCE_CONFIG_STATUS_PENDING" : The beginning state of a
  /// guaranteed inventory source. The inventory source in this state needs to
  /// be configured.
  /// - "INVENTORY_SOURCE_CONFIG_STATUS_COMPLETED" : The state after the buyer
  /// configures a guaranteed inventory source.
  core.String? configStatus;

  /// The user-provided reason for pausing this inventory source.
  ///
  /// Must not exceed 100 characters. Only applicable when entity_status is set
  /// to `ENTITY_STATUS_PAUSED`.
  core.String? entityPauseReason;

  /// Whether or not the inventory source is servable.
  ///
  /// Acceptable values are `ENTITY_STATUS_ACTIVE`, `ENTITY_STATUS_ARCHIVED`,
  /// and `ENTITY_STATUS_PAUSED`. Default value is `ENTITY_STATUS_ACTIVE`.
  /// Possible string values are:
  /// - "ENTITY_STATUS_UNSPECIFIED" : Default value when status is not specified
  /// or is unknown in this version.
  /// - "ENTITY_STATUS_ACTIVE" : The entity is enabled to bid and spend budget.
  /// - "ENTITY_STATUS_ARCHIVED" : The entity is archived. Bidding and budget
  /// spending are disabled. An entity can be deleted after archived. Deleted
  /// entities cannot be retrieved.
  /// - "ENTITY_STATUS_DRAFT" : The entity is under draft. Bidding and budget
  /// spending are disabled.
  /// - "ENTITY_STATUS_PAUSED" : Bidding and budget spending are paused for the
  /// entity.
  /// - "ENTITY_STATUS_SCHEDULED_FOR_DELETION" : The entity is scheduled for
  /// deletion.
  core.String? entityStatus;

  /// The seller-provided reason for pausing this inventory source.
  ///
  /// Only applicable for inventory sources synced directly from the publishers
  /// and when seller_status is set to `ENTITY_STATUS_PAUSED`.
  ///
  /// Output only.
  core.String? sellerPauseReason;

  /// The status set by the seller for the inventory source.
  ///
  /// Only applicable for inventory sources synced directly from the publishers.
  /// Acceptable values are `ENTITY_STATUS_ACTIVE` and `ENTITY_STATUS_PAUSED`.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ENTITY_STATUS_UNSPECIFIED" : Default value when status is not specified
  /// or is unknown in this version.
  /// - "ENTITY_STATUS_ACTIVE" : The entity is enabled to bid and spend budget.
  /// - "ENTITY_STATUS_ARCHIVED" : The entity is archived. Bidding and budget
  /// spending are disabled. An entity can be deleted after archived. Deleted
  /// entities cannot be retrieved.
  /// - "ENTITY_STATUS_DRAFT" : The entity is under draft. Bidding and budget
  /// spending are disabled.
  /// - "ENTITY_STATUS_PAUSED" : Bidding and budget spending are paused for the
  /// entity.
  /// - "ENTITY_STATUS_SCHEDULED_FOR_DELETION" : The entity is scheduled for
  /// deletion.
  core.String? sellerStatus;

  InventorySourceStatus();

  InventorySourceStatus.fromJson(core.Map _json) {
    if (_json.containsKey('configStatus')) {
      configStatus = _json['configStatus'] as core.String;
    }
    if (_json.containsKey('entityPauseReason')) {
      entityPauseReason = _json['entityPauseReason'] as core.String;
    }
    if (_json.containsKey('entityStatus')) {
      entityStatus = _json['entityStatus'] as core.String;
    }
    if (_json.containsKey('sellerPauseReason')) {
      sellerPauseReason = _json['sellerPauseReason'] as core.String;
    }
    if (_json.containsKey('sellerStatus')) {
      sellerStatus = _json['sellerStatus'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (configStatus != null) 'configStatus': configStatus!,
        if (entityPauseReason != null) 'entityPauseReason': entityPauseReason!,
        if (entityStatus != null) 'entityStatus': entityStatus!,
        if (sellerPauseReason != null) 'sellerPauseReason': sellerPauseReason!,
        if (sellerStatus != null) 'sellerStatus': sellerStatus!,
      };
}

/// The configuration for video creatives.
class InventorySourceVideoCreativeConfig {
  /// The duration requirements for the video creatives that can be assigned to
  /// the inventory source.
  core.String? duration;

  InventorySourceVideoCreativeConfig();

  InventorySourceVideoCreativeConfig.fromJson(core.Map _json) {
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (duration != null) 'duration': duration!,
      };
}

/// A single Invoice.
class Invoice {
  /// Budget invoice grouping ID associated with the budget segment in the
  /// insertion order.
  ///
  /// Output only.
  core.String? budgetInvoiceGroupingId;

  /// The list of summarized budget information associated with this invoice.
  ///
  /// Output only.
  core.List<BudgetSummary>? budgetSummaries;

  /// The originally issued invoice that is being adjusted by this invoice, if
  /// applicable.
  ///
  /// If there is a corrected invoice, the replaced_invoice_ids field will be
  /// empty. May appear on invoice PDF as `Reference invoice number`.
  ///
  /// Output only.
  core.String? correctedInvoiceId;

  /// Invoice currency code in ISO 4217 format.
  ///
  /// Output only.
  core.String? currencyCode;

  /// Display name of the invoice.
  ///
  /// Output only.
  core.String? displayName;

  /// The invoice due date.
  ///
  /// Output only.
  Date? dueDate;

  /// The unique ID of the invoice.
  ///
  /// Output only.
  core.String? invoiceId;

  /// The type of invoice document.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "INVOICE_TYPE_UNSPECIFIED" : Not specified or is unknown in this
  /// version.
  /// - "INVOICE_TYPE_CREDIT" : An Invoice with a negative amount.
  /// - "INVOICE_TYPE_INVOICE" : An Invoice with a positive amount.
  core.String? invoiceType;

  /// The date when the invoice was issued.
  ///
  /// Output only.
  Date? issueDate;

  /// The resource name of the invoice.
  ///
  /// Output only.
  core.String? name;

  /// The total amount of costs or adjustments not tied to a particular budget,
  /// in micros of the invoice's currency.
  ///
  /// For example if currency_code is `USD`, then 1000000 micros is one US
  /// dollar.
  ///
  /// Output only.
  core.String? nonBudgetMicros;

  /// The ID of the payments account the invoice belongs to.
  ///
  /// Appears on the invoice PDF as `Billing Account Number`.
  ///
  /// Output only.
  core.String? paymentsAccountId;

  /// The ID of the payments profile the invoice belongs to.
  ///
  /// Appears on the invoice PDF as `Billing ID`.
  ///
  /// Output only.
  core.String? paymentsProfileId;

  /// The URL to download a PDF copy of the invoice.
  ///
  /// Note that this URL is user specific and requires a valid OAuth 2.0 access
  /// token to access. The access token must be provided in an `Authorization:
  /// Bearer` HTTP header and be authorized for one of the following scopes: *
  /// `https://www.googleapis.com/auth/display-video-mediaplanning` *
  /// `https://www.googleapis.com/auth/display-video` The URL will only be
  /// usable for 7 days from when the api is called.
  ///
  /// Output only.
  core.String? pdfUrl;

  /// Purchase order number associated with the invoice.
  ///
  /// Output only.
  core.String? purchaseOrderNumber;

  /// The originally issued invoice(s) that is being cancelled by this invoice,
  /// if applicable.
  ///
  /// If there are any replaced invoices, the corrected_invoice_id field will be
  /// empty. May appear on invoice PDF as `Replaced invoice numbers`. Note:
  /// There may be multiple replaced invoices due to consolidation of multiple
  /// invoices into a single invoice.
  ///
  /// Output only.
  core.List<core.String>? replacedInvoiceIds;

  /// Service start and end dates which are covered by this invoice.
  ///
  /// Output only.
  DateRange? serviceDateRange;

  /// The pre-tax subtotal amount, in micros of the invoice's currency.
  ///
  /// For example if currency_code is `USD`, then 1000000 micros is one US
  /// dollar.
  ///
  /// Output only.
  core.String? subtotalAmountMicros;

  /// The invoice total amount, in micros of the invoice's currency.
  ///
  /// For example if currency_code is `USD`, then 1000000 micros is one US
  /// dollar.
  ///
  /// Output only.
  core.String? totalAmountMicros;

  /// The sum of all taxes in invoice, in micros of the invoice's currency.
  ///
  /// For example if currency_code is `USD`, then 1000000 micros is one US
  /// dollar.
  ///
  /// Output only.
  core.String? totalTaxAmountMicros;

  Invoice();

  Invoice.fromJson(core.Map _json) {
    if (_json.containsKey('budgetInvoiceGroupingId')) {
      budgetInvoiceGroupingId = _json['budgetInvoiceGroupingId'] as core.String;
    }
    if (_json.containsKey('budgetSummaries')) {
      budgetSummaries = (_json['budgetSummaries'] as core.List)
          .map<BudgetSummary>((value) => BudgetSummary.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('correctedInvoiceId')) {
      correctedInvoiceId = _json['correctedInvoiceId'] as core.String;
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('dueDate')) {
      dueDate = Date.fromJson(
          _json['dueDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('invoiceId')) {
      invoiceId = _json['invoiceId'] as core.String;
    }
    if (_json.containsKey('invoiceType')) {
      invoiceType = _json['invoiceType'] as core.String;
    }
    if (_json.containsKey('issueDate')) {
      issueDate = Date.fromJson(
          _json['issueDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nonBudgetMicros')) {
      nonBudgetMicros = _json['nonBudgetMicros'] as core.String;
    }
    if (_json.containsKey('paymentsAccountId')) {
      paymentsAccountId = _json['paymentsAccountId'] as core.String;
    }
    if (_json.containsKey('paymentsProfileId')) {
      paymentsProfileId = _json['paymentsProfileId'] as core.String;
    }
    if (_json.containsKey('pdfUrl')) {
      pdfUrl = _json['pdfUrl'] as core.String;
    }
    if (_json.containsKey('purchaseOrderNumber')) {
      purchaseOrderNumber = _json['purchaseOrderNumber'] as core.String;
    }
    if (_json.containsKey('replacedInvoiceIds')) {
      replacedInvoiceIds = (_json['replacedInvoiceIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('serviceDateRange')) {
      serviceDateRange = DateRange.fromJson(
          _json['serviceDateRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subtotalAmountMicros')) {
      subtotalAmountMicros = _json['subtotalAmountMicros'] as core.String;
    }
    if (_json.containsKey('totalAmountMicros')) {
      totalAmountMicros = _json['totalAmountMicros'] as core.String;
    }
    if (_json.containsKey('totalTaxAmountMicros')) {
      totalTaxAmountMicros = _json['totalTaxAmountMicros'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (budgetInvoiceGroupingId != null)
          'budgetInvoiceGroupingId': budgetInvoiceGroupingId!,
        if (budgetSummaries != null)
          'budgetSummaries':
              budgetSummaries!.map((value) => value.toJson()).toList(),
        if (correctedInvoiceId != null)
          'correctedInvoiceId': correctedInvoiceId!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (displayName != null) 'displayName': displayName!,
        if (dueDate != null) 'dueDate': dueDate!.toJson(),
        if (invoiceId != null) 'invoiceId': invoiceId!,
        if (invoiceType != null) 'invoiceType': invoiceType!,
        if (issueDate != null) 'issueDate': issueDate!.toJson(),
        if (name != null) 'name': name!,
        if (nonBudgetMicros != null) 'nonBudgetMicros': nonBudgetMicros!,
        if (paymentsAccountId != null) 'paymentsAccountId': paymentsAccountId!,
        if (paymentsProfileId != null) 'paymentsProfileId': paymentsProfileId!,
        if (pdfUrl != null) 'pdfUrl': pdfUrl!,
        if (purchaseOrderNumber != null)
          'purchaseOrderNumber': purchaseOrderNumber!,
        if (replacedInvoiceIds != null)
          'replacedInvoiceIds': replacedInvoiceIds!,
        if (serviceDateRange != null)
          'serviceDateRange': serviceDateRange!.toJson(),
        if (subtotalAmountMicros != null)
          'subtotalAmountMicros': subtotalAmountMicros!,
        if (totalAmountMicros != null) 'totalAmountMicros': totalAmountMicros!,
        if (totalTaxAmountMicros != null)
          'totalTaxAmountMicros': totalTaxAmountMicros!,
      };
}

/// Details for assigned keyword targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_KEYWORD`.
class KeywordAssignedTargetingOptionDetails {
  /// The keyword, for example `car insurance`.
  ///
  /// Positive keyword cannot be offensive word. Must be UTF-8 encoded with a
  /// maximum size of 255 bytes. Maximum number of characters is 80. Maximum
  /// number of words is 10.
  ///
  /// Required.
  core.String? keyword;

  /// Indicates if this option is being negatively targeted.
  core.bool? negative;

  KeywordAssignedTargetingOptionDetails();

  KeywordAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('keyword')) {
      keyword = _json['keyword'] as core.String;
    }
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (keyword != null) 'keyword': keyword!,
        if (negative != null) 'negative': negative!,
      };
}

/// Details for assigned language targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_LANGUAGE`.
class LanguageAssignedTargetingOptionDetails {
  /// The display name of the language (e.g., "French").
  ///
  /// Output only.
  core.String? displayName;

  /// Indicates if this option is being negatively targeted.
  ///
  /// All assigned language targeting options on the same resource must have the
  /// same value for this field.
  core.bool? negative;

  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_LANGUAGE`.
  ///
  /// Required.
  core.String? targetingOptionId;

  LanguageAssignedTargetingOptionDetails();

  LanguageAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (negative != null) 'negative': negative!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable language.
///
/// This will be populated in the language_details field when targeting_type is
/// `TARGETING_TYPE_LANGUAGE`.
class LanguageTargetingOptionDetails {
  /// The display name of the language (e.g., "French").
  ///
  /// Output only.
  core.String? displayName;

  LanguageTargetingOptionDetails();

  LanguageTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
      };
}

/// A single line item.
class LineItem {
  /// The unique ID of the advertiser the line item belongs to.
  ///
  /// Output only.
  core.String? advertiserId;

  /// The bidding strategy of the line item.
  ///
  /// Required.
  BiddingStrategy? bidStrategy;

  /// The budget allocation setting of the line item.
  ///
  /// Required.
  LineItemBudget? budget;

  /// The unique ID of the campaign that the line item belongs to.
  ///
  /// Output only.
  core.String? campaignId;

  /// The conversion tracking setting of the line item.
  ConversionCountingConfig? conversionCounting;

  /// The IDs of the creatives associated with the line item.
  core.List<core.String>? creativeIds;

  /// The display name of the line item.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// Controls whether or not the line item can spend its budget and bid on
  /// inventory.
  ///
  /// * For CreateLineItem method, only `ENTITY_STATUS_DRAFT` is allowed. To
  /// activate a line item, use UpdateLineItem method and update the status to
  /// `ENTITY_STATUS_ACTIVE` after creation. * A line item cannot be changed
  /// back to `ENTITY_STATUS_DRAFT` status from any other status. * If the line
  /// item's parent insertion order is not active, the line item can't spend its
  /// budget even if its own status is `ENTITY_STATUS_ACTIVE`.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ENTITY_STATUS_UNSPECIFIED" : Default value when status is not specified
  /// or is unknown in this version.
  /// - "ENTITY_STATUS_ACTIVE" : The entity is enabled to bid and spend budget.
  /// - "ENTITY_STATUS_ARCHIVED" : The entity is archived. Bidding and budget
  /// spending are disabled. An entity can be deleted after archived. Deleted
  /// entities cannot be retrieved.
  /// - "ENTITY_STATUS_DRAFT" : The entity is under draft. Bidding and budget
  /// spending are disabled.
  /// - "ENTITY_STATUS_PAUSED" : Bidding and budget spending are paused for the
  /// entity.
  /// - "ENTITY_STATUS_SCHEDULED_FOR_DELETION" : The entity is scheduled for
  /// deletion.
  core.String? entityStatus;

  /// The start and end time of the line item's flight.
  ///
  /// Required.
  LineItemFlight? flight;

  /// The frequency capping setting of the line item.
  ///
  /// Required.
  FrequencyCap? frequencyCap;

  /// The unique ID of the insertion order that the line item belongs to.
  ///
  /// Required. Immutable.
  core.String? insertionOrderId;

  /// Integration details of the line item.
  IntegrationDetails? integrationDetails;

  /// The IDs of the private inventory sources assigned to the line item.
  core.List<core.String>? inventorySourceIds;

  /// The unique ID of the line item.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? lineItemId;

  /// The type of the line item.
  ///
  /// Required. Immutable.
  /// Possible string values are:
  /// - "LINE_ITEM_TYPE_UNSPECIFIED" : Type value is not specified or is unknown
  /// in this version.
  /// - "LINE_ITEM_TYPE_DISPLAY_DEFAULT" : Image, HTML5, native, or rich media
  /// ads.
  /// - "LINE_ITEM_TYPE_DISPLAY_MOBILE_APP_INSTALL" : Display ads that drive
  /// installs of an app.
  /// - "LINE_ITEM_TYPE_VIDEO_DEFAULT" : Video ads sold on a CPM basis for a
  /// variety of environments.
  /// - "LINE_ITEM_TYPE_VIDEO_MOBILE_APP_INSTALL" : Video ads that drive
  /// installs of an app.
  /// - "LINE_ITEM_TYPE_DISPLAY_MOBILE_APP_INVENTORY" : Display ads served on
  /// mobile app inventory.
  /// - "LINE_ITEM_TYPE_VIDEO_MOBILE_APP_INVENTORY" : Video ads served on mobile
  /// app inventory.
  /// - "LINE_ITEM_TYPE_AUDIO_DEFAULT" : RTB Audio ads sold for a variety of
  /// environments.
  /// - "LINE_ITEM_TYPE_VIDEO_OVER_THE_TOP" : Over-the-top ads present in OTT
  /// insertion orders. This type is only applicable to line items with an
  /// insertion order of insertion_order_type `OVER_THE_TOP`.
  core.String? lineItemType;

  /// The mobile app promoted by the line item.
  ///
  /// This is applicable only when line_item_type is either
  /// `LINE_ITEM_TYPE_DISPLAY_MOBILE_APP_INSTALL` or
  /// `LINE_ITEM_TYPE_VIDEO_MOBILE_APP_INSTALL`.
  MobileApp? mobileApp;

  /// The resource name of the line item.
  ///
  /// Output only.
  core.String? name;

  /// The budget spending speed setting of the line item.
  ///
  /// Required.
  Pacing? pacing;

  /// The partner costs associated with the line item.
  ///
  /// If absent or empty in CreateLineItem method, the newly created line item
  /// will inherit partner costs from its parent insertion order.
  core.List<PartnerCost>? partnerCosts;

  /// The partner revenue model setting of the line item.
  ///
  /// Required.
  PartnerRevenueModel? partnerRevenueModel;

  /// The
  /// [targeting expansion](https://support.google.com/displayvideo/answer/10191558)
  /// settings of the line item.
  ///
  /// This config is only applicable when eligible audience list targeting is
  /// assigned to the line item.
  TargetingExpansionConfig? targetingExpansion;

  /// The timestamp when the line item was last updated.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? updateTime;

  /// The warning messages generated by the line item.
  ///
  /// These warnings do not block saving the line item, but some may block the
  /// line item from running.
  ///
  /// Output only.
  core.List<core.String>? warningMessages;

  LineItem();

  LineItem.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('bidStrategy')) {
      bidStrategy = BiddingStrategy.fromJson(
          _json['bidStrategy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('budget')) {
      budget = LineItemBudget.fromJson(
          _json['budget'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('campaignId')) {
      campaignId = _json['campaignId'] as core.String;
    }
    if (_json.containsKey('conversionCounting')) {
      conversionCounting = ConversionCountingConfig.fromJson(
          _json['conversionCounting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('creativeIds')) {
      creativeIds = (_json['creativeIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('entityStatus')) {
      entityStatus = _json['entityStatus'] as core.String;
    }
    if (_json.containsKey('flight')) {
      flight = LineItemFlight.fromJson(
          _json['flight'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('frequencyCap')) {
      frequencyCap = FrequencyCap.fromJson(
          _json['frequencyCap'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertionOrderId')) {
      insertionOrderId = _json['insertionOrderId'] as core.String;
    }
    if (_json.containsKey('integrationDetails')) {
      integrationDetails = IntegrationDetails.fromJson(
          _json['integrationDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inventorySourceIds')) {
      inventorySourceIds = (_json['inventorySourceIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('lineItemType')) {
      lineItemType = _json['lineItemType'] as core.String;
    }
    if (_json.containsKey('mobileApp')) {
      mobileApp = MobileApp.fromJson(
          _json['mobileApp'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('pacing')) {
      pacing = Pacing.fromJson(
          _json['pacing'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('partnerCosts')) {
      partnerCosts = (_json['partnerCosts'] as core.List)
          .map<PartnerCost>((value) => PartnerCost.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('partnerRevenueModel')) {
      partnerRevenueModel = PartnerRevenueModel.fromJson(
          _json['partnerRevenueModel'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('targetingExpansion')) {
      targetingExpansion = TargetingExpansionConfig.fromJson(
          _json['targetingExpansion'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('warningMessages')) {
      warningMessages = (_json['warningMessages'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (bidStrategy != null) 'bidStrategy': bidStrategy!.toJson(),
        if (budget != null) 'budget': budget!.toJson(),
        if (campaignId != null) 'campaignId': campaignId!,
        if (conversionCounting != null)
          'conversionCounting': conversionCounting!.toJson(),
        if (creativeIds != null) 'creativeIds': creativeIds!,
        if (displayName != null) 'displayName': displayName!,
        if (entityStatus != null) 'entityStatus': entityStatus!,
        if (flight != null) 'flight': flight!.toJson(),
        if (frequencyCap != null) 'frequencyCap': frequencyCap!.toJson(),
        if (insertionOrderId != null) 'insertionOrderId': insertionOrderId!,
        if (integrationDetails != null)
          'integrationDetails': integrationDetails!.toJson(),
        if (inventorySourceIds != null)
          'inventorySourceIds': inventorySourceIds!,
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (lineItemType != null) 'lineItemType': lineItemType!,
        if (mobileApp != null) 'mobileApp': mobileApp!.toJson(),
        if (name != null) 'name': name!,
        if (pacing != null) 'pacing': pacing!.toJson(),
        if (partnerCosts != null)
          'partnerCosts': partnerCosts!.map((value) => value.toJson()).toList(),
        if (partnerRevenueModel != null)
          'partnerRevenueModel': partnerRevenueModel!.toJson(),
        if (targetingExpansion != null)
          'targetingExpansion': targetingExpansion!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
        if (warningMessages != null) 'warningMessages': warningMessages!,
      };
}

/// Settings that control how budget is allocated.
class LineItemBudget {
  /// The type of the budget allocation.
  ///
  /// `LINE_ITEM_BUDGET_ALLOCATION_TYPE_AUTOMATIC` is only applicable when
  /// automatic budget allocation is enabled for the parent insertion order.
  ///
  /// Required.
  /// Possible string values are:
  /// - "LINE_ITEM_BUDGET_ALLOCATION_TYPE_UNSPECIFIED" : Type value is not
  /// specified or is unknown in this version.
  /// - "LINE_ITEM_BUDGET_ALLOCATION_TYPE_AUTOMATIC" : Automatic budget
  /// allocation is enabled for the line item.
  /// - "LINE_ITEM_BUDGET_ALLOCATION_TYPE_FIXED" : A fixed max budget amount is
  /// allocated for the line item.
  /// - "LINE_ITEM_BUDGET_ALLOCATION_TYPE_UNLIMITED" : No budget limit is
  /// applied to the line item.
  core.String? budgetAllocationType;

  /// The budget unit specifies whether the budget is currency based or
  /// impression based.
  ///
  /// This value is inherited from the parent insertion order.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "BUDGET_UNIT_UNSPECIFIED" : Type value is not specified or is unknown in
  /// this version.
  /// - "BUDGET_UNIT_CURRENCY" : Budgeting in currency amounts.
  /// - "BUDGET_UNIT_IMPRESSIONS" : Budgeting in impression amounts.
  core.String? budgetUnit;

  /// The maximum budget amount the line item will spend.
  ///
  /// Must be greater than 0. When budget_allocation_type is: *
  /// `LINE_ITEM_BUDGET_ALLOCATION_TYPE_AUTOMATIC`, this field is immutable and
  /// is set by the system. * `LINE_ITEM_BUDGET_ALLOCATION_TYPE_FIXED`, if
  /// budget_unit is: - `BUDGET_UNIT_CURRENCY`, this field represents maximum
  /// budget amount to spend, in micros of the advertiser's currency. For
  /// example, 1500000 represents 1.5 standard units of the currency. -
  /// `BUDGET_UNIT_IMPRESSIONS`, this field represents the maximum number of
  /// impressions to serve. * `LINE_ITEM_BUDGET_ALLOCATION_TYPE_UNLIMITED`, this
  /// field is not applicable and will be ignored by the system.
  core.String? maxAmount;

  LineItemBudget();

  LineItemBudget.fromJson(core.Map _json) {
    if (_json.containsKey('budgetAllocationType')) {
      budgetAllocationType = _json['budgetAllocationType'] as core.String;
    }
    if (_json.containsKey('budgetUnit')) {
      budgetUnit = _json['budgetUnit'] as core.String;
    }
    if (_json.containsKey('maxAmount')) {
      maxAmount = _json['maxAmount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (budgetAllocationType != null)
          'budgetAllocationType': budgetAllocationType!,
        if (budgetUnit != null) 'budgetUnit': budgetUnit!,
        if (maxAmount != null) 'maxAmount': maxAmount!,
      };
}

/// Settings that control the active duration of a line item.
class LineItemFlight {
  /// The flight start and end dates of the line item.
  ///
  /// They are resolved relative to the parent advertiser's time zone. *
  /// Required when flight_date_type is `LINE_ITEM_FLIGHT_DATE_TYPE_CUSTOM`.
  /// Output only otherwise. * When creating a new flight, both `start_date` and
  /// `end_date` must be in the future. * An existing flight with a `start_date`
  /// in the past has a mutable `end_date` but an immutable `start_date`. *
  /// `end_date` must be the `start_date` or later, both before the year 2037.
  DateRange? dateRange;

  /// The type of the line item's flight dates.
  ///
  /// Required.
  /// Possible string values are:
  /// - "LINE_ITEM_FLIGHT_DATE_TYPE_UNSPECIFIED" : Type value is not specified
  /// or is unknown in this version.
  /// - "LINE_ITEM_FLIGHT_DATE_TYPE_INHERITED" : The line item's flight dates
  /// are inherited from its parent insertion order.
  /// - "LINE_ITEM_FLIGHT_DATE_TYPE_CUSTOM" : The line item uses its own custom
  /// flight dates.
  /// - "LINE_ITEM_FLIGHT_DATE_TYPE_TRIGGER" : The line item uses a trigger.
  core.String? flightDateType;

  /// The ID of the manual trigger associated with the line item.
  ///
  /// * Required when flight_date_type is `LINE_ITEM_FLIGHT_DATE_TYPE_TRIGGER`.
  /// Must not be set otherwise. * When set, the line item's flight dates are
  /// inherited from its parent insertion order. * Active line items will spend
  /// when the selected trigger is activated within the parent insertion order's
  /// flight dates.
  core.String? triggerId;

  LineItemFlight();

  LineItemFlight.fromJson(core.Map _json) {
    if (_json.containsKey('dateRange')) {
      dateRange = DateRange.fromJson(
          _json['dateRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('flightDateType')) {
      flightDateType = _json['flightDateType'] as core.String;
    }
    if (_json.containsKey('triggerId')) {
      triggerId = _json['triggerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
        if (flightDateType != null) 'flightDateType': flightDateType!,
        if (triggerId != null) 'triggerId': triggerId!,
      };
}

/// Response message for ListAdvertiserAssignedTargetingOptions.
class ListAdvertiserAssignedTargetingOptionsResponse {
  /// The list of assigned targeting options.
  ///
  /// This list will be absent if empty.
  core.List<AssignedTargetingOption>? assignedTargetingOptions;

  /// A token identifying the next page of results.
  ///
  /// This value should be specified as the pageToken in a subsequent
  /// ListAdvertiserAssignedTargetingOptionsRequest to fetch the next page of
  /// results. This token will be absent if there are no more
  /// assigned_targeting_options to return.
  core.String? nextPageToken;

  ListAdvertiserAssignedTargetingOptionsResponse();

  ListAdvertiserAssignedTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignedTargetingOptions')) {
      assignedTargetingOptions =
          (_json['assignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedTargetingOptions != null)
          'assignedTargetingOptions':
              assignedTargetingOptions!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListAdvertisersResponse {
  /// The list of advertisers.
  ///
  /// This list will be absent if empty.
  core.List<Advertiser>? advertisers;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListAdvertisers` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListAdvertisersResponse();

  ListAdvertisersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('advertisers')) {
      advertisers = (_json['advertisers'] as core.List)
          .map<Advertiser>((value) =>
              Advertiser.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertisers != null)
          'advertisers': advertisers!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for
/// AssignedInventorySourceService.ListAssignedInventorySources.
class ListAssignedInventorySourcesResponse {
  /// The list of assigned inventory sources.
  ///
  /// This list will be absent if empty.
  core.List<AssignedInventorySource>? assignedInventorySources;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListAssignedInventorySources` method to retrieve the next page of
  /// results.
  core.String? nextPageToken;

  ListAssignedInventorySourcesResponse();

  ListAssignedInventorySourcesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignedInventorySources')) {
      assignedInventorySources =
          (_json['assignedInventorySources'] as core.List)
              .map<AssignedInventorySource>((value) =>
                  AssignedInventorySource.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedInventorySources != null)
          'assignedInventorySources':
              assignedInventorySources!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for AssignedLocationService.ListAssignedLocations.
class ListAssignedLocationsResponse {
  /// The list of assigned locations.
  ///
  /// This list will be absent if empty.
  core.List<AssignedLocation>? assignedLocations;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListAssignedLocations` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListAssignedLocationsResponse();

  ListAssignedLocationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignedLocations')) {
      assignedLocations = (_json['assignedLocations'] as core.List)
          .map<AssignedLocation>((value) => AssignedLocation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedLocations != null)
          'assignedLocations':
              assignedLocations!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for ListCampaignAssignedTargetingOptions.
class ListCampaignAssignedTargetingOptionsResponse {
  /// The list of assigned targeting options.
  ///
  /// This list will be absent if empty.
  core.List<AssignedTargetingOption>? assignedTargetingOptions;

  /// A token identifying the next page of results.
  ///
  /// This value should be specified as the pageToken in a subsequent
  /// ListCampaignAssignedTargetingOptionsRequest to fetch the next page of
  /// results. This token will be absent if there are no more
  /// assigned_targeting_options to return.
  core.String? nextPageToken;

  ListCampaignAssignedTargetingOptionsResponse();

  ListCampaignAssignedTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignedTargetingOptions')) {
      assignedTargetingOptions =
          (_json['assignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedTargetingOptions != null)
          'assignedTargetingOptions':
              assignedTargetingOptions!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListCampaignsResponse {
  /// The list of campaigns.
  ///
  /// This list will be absent if empty.
  core.List<Campaign>? campaigns;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListCampaigns` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListCampaignsResponse();

  ListCampaignsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('campaigns')) {
      campaigns = (_json['campaigns'] as core.List)
          .map<Campaign>((value) =>
              Campaign.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (campaigns != null)
          'campaigns': campaigns!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListChannelsResponse {
  /// The list of channels.
  ///
  /// This list will be absent if empty.
  core.List<Channel>? channels;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListChannels` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListChannelsResponse();

  ListChannelsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('channels')) {
      channels = (_json['channels'] as core.List)
          .map<Channel>((value) =>
              Channel.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channels != null)
          'channels': channels!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListCombinedAudiencesResponse {
  /// The list of combined audiences.
  ///
  /// This list will be absent if empty.
  core.List<CombinedAudience>? combinedAudiences;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListCombinedAudiences` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListCombinedAudiencesResponse();

  ListCombinedAudiencesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('combinedAudiences')) {
      combinedAudiences = (_json['combinedAudiences'] as core.List)
          .map<CombinedAudience>((value) => CombinedAudience.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (combinedAudiences != null)
          'combinedAudiences':
              combinedAudiences!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListCreativesResponse {
  /// The list of creatives.
  ///
  /// This list will be absent if empty.
  core.List<Creative>? creatives;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListCreativesRequest` method to retrieve the next page of results. If
  /// this field is null, it means this is the last page.
  core.String? nextPageToken;

  ListCreativesResponse();

  ListCreativesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('creatives')) {
      creatives = (_json['creatives'] as core.List)
          .map<Creative>((value) =>
              Creative.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creatives != null)
          'creatives': creatives!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListCustomBiddingAlgorithmsResponse {
  /// The list of custom bidding algorithms.
  ///
  /// This list will be absent if empty.
  core.List<CustomBiddingAlgorithm>? customBiddingAlgorithms;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListCustomBiddingAlgorithmsRequest` method to retrieve the next page of
  /// results. If this field is null, it means this is the last page.
  core.String? nextPageToken;

  ListCustomBiddingAlgorithmsResponse();

  ListCustomBiddingAlgorithmsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('customBiddingAlgorithms')) {
      customBiddingAlgorithms = (_json['customBiddingAlgorithms'] as core.List)
          .map<CustomBiddingAlgorithm>((value) =>
              CustomBiddingAlgorithm.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customBiddingAlgorithms != null)
          'customBiddingAlgorithms':
              customBiddingAlgorithms!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListCustomListsResponse {
  /// The list of custom lists.
  ///
  /// This list will be absent if empty.
  core.List<CustomList>? customLists;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListCustomLists` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListCustomListsResponse();

  ListCustomListsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('customLists')) {
      customLists = (_json['customLists'] as core.List)
          .map<CustomList>((value) =>
              CustomList.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customLists != null)
          'customLists': customLists!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListFirstAndThirdPartyAudiencesResponse {
  /// The list of first and third party audiences.
  ///
  /// Audience size properties will not be included. This list will be absent if
  /// empty.
  core.List<FirstAndThirdPartyAudience>? firstAndThirdPartyAudiences;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListFirstAndThirdPartyAudiences` method to retrieve the next page of
  /// results.
  core.String? nextPageToken;

  ListFirstAndThirdPartyAudiencesResponse();

  ListFirstAndThirdPartyAudiencesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('firstAndThirdPartyAudiences')) {
      firstAndThirdPartyAudiences =
          (_json['firstAndThirdPartyAudiences'] as core.List)
              .map<FirstAndThirdPartyAudience>((value) =>
                  FirstAndThirdPartyAudience.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (firstAndThirdPartyAudiences != null)
          'firstAndThirdPartyAudiences': firstAndThirdPartyAudiences!
              .map((value) => value.toJson())
              .toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListGoogleAudiencesResponse {
  /// The list of Google audiences.
  ///
  /// This list will be absent if empty.
  core.List<GoogleAudience>? googleAudiences;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListGoogleAudiences` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListGoogleAudiencesResponse();

  ListGoogleAudiencesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('googleAudiences')) {
      googleAudiences = (_json['googleAudiences'] as core.List)
          .map<GoogleAudience>((value) => GoogleAudience.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (googleAudiences != null)
          'googleAudiences':
              googleAudiences!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for ListInsertionOrderAssignedTargetingOptions.
class ListInsertionOrderAssignedTargetingOptionsResponse {
  /// The list of assigned targeting options.
  ///
  /// This list will be absent if empty.
  core.List<AssignedTargetingOption>? assignedTargetingOptions;

  /// A token identifying the next page of results.
  ///
  /// This value should be specified as the pageToken in a subsequent
  /// ListInsertionOrderAssignedTargetingOptionsRequest to fetch the next page
  /// of results. This token will be absent if there are no more
  /// assigned_targeting_options to return.
  core.String? nextPageToken;

  ListInsertionOrderAssignedTargetingOptionsResponse();

  ListInsertionOrderAssignedTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignedTargetingOptions')) {
      assignedTargetingOptions =
          (_json['assignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedTargetingOptions != null)
          'assignedTargetingOptions':
              assignedTargetingOptions!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListInsertionOrdersResponse {
  /// The list of insertion orders.
  ///
  /// This list will be absent if empty.
  core.List<InsertionOrder>? insertionOrders;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListInsertionOrders` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListInsertionOrdersResponse();

  ListInsertionOrdersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('insertionOrders')) {
      insertionOrders = (_json['insertionOrders'] as core.List)
          .map<InsertionOrder>((value) => InsertionOrder.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (insertionOrders != null)
          'insertionOrders':
              insertionOrders!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for InventorySourceGroupService.ListInventorySourceGroups.
class ListInventorySourceGroupsResponse {
  /// The list of inventory source groups.
  ///
  /// This list will be absent if empty.
  core.List<InventorySourceGroup>? inventorySourceGroups;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListInventorySourceGroups` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListInventorySourceGroupsResponse();

  ListInventorySourceGroupsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('inventorySourceGroups')) {
      inventorySourceGroups = (_json['inventorySourceGroups'] as core.List)
          .map<InventorySourceGroup>((value) => InventorySourceGroup.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inventorySourceGroups != null)
          'inventorySourceGroups':
              inventorySourceGroups!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListInventorySourcesResponse {
  /// The list of inventory sources.
  ///
  /// This list will be absent if empty.
  core.List<InventorySource>? inventorySources;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListInventorySources` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListInventorySourcesResponse();

  ListInventorySourcesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('inventorySources')) {
      inventorySources = (_json['inventorySources'] as core.List)
          .map<InventorySource>((value) => InventorySource.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inventorySources != null)
          'inventorySources':
              inventorySources!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for InvoiceService.ListInvoices.
class ListInvoicesResponse {
  /// The list of invoices.
  ///
  /// This list will be absent if empty.
  core.List<Invoice>? invoices;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the \[ListInvoicesRequest.page_token\] field in the
  /// subsequent call to `ListInvoices` method to retrieve the next page of
  /// results.
  core.String? nextPageToken;

  ListInvoicesResponse();

  ListInvoicesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('invoices')) {
      invoices = (_json['invoices'] as core.List)
          .map<Invoice>((value) =>
              Invoice.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (invoices != null)
          'invoices': invoices!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for ListLineItemAssignedTargetingOptions.
class ListLineItemAssignedTargetingOptionsResponse {
  /// The list of assigned targeting options.
  ///
  /// This list will be absent if empty.
  core.List<AssignedTargetingOption>? assignedTargetingOptions;

  /// A token identifying the next page of results.
  ///
  /// This value should be specified as the pageToken in a subsequent
  /// ListLineItemAssignedTargetingOptionsRequest to fetch the next page of
  /// results. This token will be absent if there are no more
  /// assigned_targeting_options to return.
  core.String? nextPageToken;

  ListLineItemAssignedTargetingOptionsResponse();

  ListLineItemAssignedTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignedTargetingOptions')) {
      assignedTargetingOptions =
          (_json['assignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedTargetingOptions != null)
          'assignedTargetingOptions':
              assignedTargetingOptions!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListLineItemsResponse {
  /// The list of line items.
  ///
  /// This list will be absent if empty.
  core.List<LineItem>? lineItems;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListLineItems` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListLineItemsResponse();

  ListLineItemsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('lineItems')) {
      lineItems = (_json['lineItems'] as core.List)
          .map<LineItem>((value) =>
              LineItem.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItems != null)
          'lineItems': lineItems!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListLocationListsResponse {
  /// The list of location lists.
  ///
  /// This list will be absent if empty.
  core.List<LocationList>? locationLists;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListLocationLists` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListLocationListsResponse();

  ListLocationListsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('locationLists')) {
      locationLists = (_json['locationLists'] as core.List)
          .map<LocationList>((value) => LocationList.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (locationLists != null)
          'locationLists':
              locationLists!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListManualTriggersResponse {
  /// The list of manual triggers.
  ///
  /// This list will be absent if empty.
  core.List<ManualTrigger>? manualTriggers;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListManualTriggers` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListManualTriggersResponse();

  ListManualTriggersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('manualTriggers')) {
      manualTriggers = (_json['manualTriggers'] as core.List)
          .map<ManualTrigger>((value) => ManualTrigger.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (manualTriggers != null)
          'manualTriggers':
              manualTriggers!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for NegativeKeywordListService.ListNegativeKeywordLists.
class ListNegativeKeywordListsResponse {
  /// The list of negative keyword lists.
  ///
  /// This list will be absent if empty.
  core.List<NegativeKeywordList>? negativeKeywordLists;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListNegativeKeywordLists` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListNegativeKeywordListsResponse();

  ListNegativeKeywordListsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('negativeKeywordLists')) {
      negativeKeywordLists = (_json['negativeKeywordLists'] as core.List)
          .map<NegativeKeywordList>((value) => NegativeKeywordList.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (negativeKeywordLists != null)
          'negativeKeywordLists':
              negativeKeywordLists!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for NegativeKeywordService.ListNegativeKeywords.
class ListNegativeKeywordsResponse {
  /// The list of negative keywords.
  ///
  /// This list will be absent if empty.
  core.List<NegativeKeyword>? negativeKeywords;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListNegativeKeywords` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListNegativeKeywordsResponse();

  ListNegativeKeywordsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('negativeKeywords')) {
      negativeKeywords = (_json['negativeKeywords'] as core.List)
          .map<NegativeKeyword>((value) => NegativeKeyword.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (negativeKeywords != null)
          'negativeKeywords':
              negativeKeywords!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListPartnerAssignedTargetingOptionsResponse {
  /// The list of assigned targeting options.
  ///
  /// This list will be absent if empty.
  core.List<AssignedTargetingOption>? assignedTargetingOptions;

  /// A token identifying the next page of results.
  ///
  /// This value should be specified as the pageToken in a subsequent
  /// ListPartnerAssignedTargetingOptionsRequest to fetch the next page of
  /// results. This token will be absent if there are no more
  /// assigned_targeting_options to return.
  core.String? nextPageToken;

  ListPartnerAssignedTargetingOptionsResponse();

  ListPartnerAssignedTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignedTargetingOptions')) {
      assignedTargetingOptions =
          (_json['assignedTargetingOptions'] as core.List)
              .map<AssignedTargetingOption>((value) =>
                  AssignedTargetingOption.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedTargetingOptions != null)
          'assignedTargetingOptions':
              assignedTargetingOptions!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListPartnersResponse {
  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListPartners` method to retrieve the next page of results.
  core.String? nextPageToken;

  /// The list of partners.
  ///
  /// This list will be absent if empty.
  core.List<Partner>? partners;

  ListPartnersResponse();

  ListPartnersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('partners')) {
      partners = (_json['partners'] as core.List)
          .map<Partner>((value) =>
              Partner.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (partners != null)
          'partners': partners!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for SiteService.ListSites.
class ListSitesResponse {
  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListSites` method to retrieve the next page of results.
  core.String? nextPageToken;

  /// The list of sites.
  ///
  /// This list will be absent if empty.
  core.List<Site>? sites;

  ListSitesResponse();

  ListSitesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('sites')) {
      sites = (_json['sites'] as core.List)
          .map<Site>((value) =>
              Site.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (sites != null)
          'sites': sites!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for ListTargetingOptions.
class ListTargetingOptionsResponse {
  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListTargetingOptions` method to retrieve the next page of results.
  core.String? nextPageToken;

  /// The list of targeting options.
  ///
  /// This list will be absent if empty.
  core.List<TargetingOption>? targetingOptions;

  ListTargetingOptionsResponse();

  ListTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('targetingOptions')) {
      targetingOptions = (_json['targetingOptions'] as core.List)
          .map<TargetingOption>((value) => TargetingOption.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (targetingOptions != null)
          'targetingOptions':
              targetingOptions!.map((value) => value.toJson()).toList(),
      };
}

class ListUsersResponse {
  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `ListUsers` method to retrieve the next page of results. This token will
  /// be absent if there are no more results to return.
  core.String? nextPageToken;

  /// The list of users.
  ///
  /// This list will be absent if empty.
  core.List<User>? users;

  ListUsersResponse();

  ListUsersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('users')) {
      users = (_json['users'] as core.List)
          .map<User>((value) =>
              User.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (users != null)
          'users': users!.map((value) => value.toJson()).toList(),
      };
}

/// A list of locations used for targeting.
class LocationList {
  /// The unique ID of the advertiser the location list belongs to.
  ///
  /// Required. Immutable.
  core.String? advertiserId;

  /// The display name of the location list.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// The unique ID of the location list.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? locationListId;

  /// The type of location.
  ///
  /// All locations in the list will share this type.
  ///
  /// Required. Immutable.
  /// Possible string values are:
  /// - "TARGETING_LOCATION_TYPE_UNSPECIFIED" : Default value when type is not
  /// specified or is unknown.
  /// - "TARGETING_LOCATION_TYPE_PROXIMITY" : The type for proximity geo
  /// location.
  /// - "TARGETING_LOCATION_TYPE_REGIONAL" : The type for regional geo location.
  core.String? locationType;

  /// The resource name of the location list.
  ///
  /// Output only.
  core.String? name;

  LocationList();

  LocationList.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('locationListId')) {
      locationListId = _json['locationListId'] as core.String;
    }
    if (_json.containsKey('locationType')) {
      locationType = _json['locationType'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (displayName != null) 'displayName': displayName!,
        if (locationListId != null) 'locationListId': locationListId!,
        if (locationType != null) 'locationType': locationType!,
        if (name != null) 'name': name!,
      };
}

/// Specifies how many days into the past to look when determining whether to
/// record a conversion.
class LookbackWindow {
  /// Lookback window, in days, from the last time a given user clicked on one
  /// of your ads.
  core.int? clickDays;

  /// Lookback window, in days, from the last time a given user viewed one of
  /// your ads.
  core.int? impressionDays;

  LookbackWindow();

  LookbackWindow.fromJson(core.Map _json) {
    if (_json.containsKey('clickDays')) {
      clickDays = _json['clickDays'] as core.int;
    }
    if (_json.containsKey('impressionDays')) {
      impressionDays = _json['impressionDays'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clickDays != null) 'clickDays': clickDays!,
        if (impressionDays != null) 'impressionDays': impressionDays!,
      };
}

/// Response message for InvoiceService.LookupInvoiceCurrency.
class LookupInvoiceCurrencyResponse {
  /// Invoice currency code in ISO 4217 format.
  ///
  /// Output only.
  core.String? currencyCode;

  LookupInvoiceCurrencyResponse();

  LookupInvoiceCurrencyResponse.fromJson(core.Map _json) {
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currencyCode != null) 'currencyCode': currencyCode!,
      };
}

/// A single manual trigger in Display & Video 360.
class ManualTrigger {
  /// The maximum duration of each activation in minutes.
  ///
  /// Must be between 1 and 360 inclusive. After this duration, the trigger will
  /// be automatically deactivated.
  ///
  /// Required.
  core.String? activationDurationMinutes;

  /// The unique ID of the advertiser that the manual trigger belongs to.
  ///
  /// Required. Immutable.
  core.String? advertiserId;

  /// The display name of the manual trigger.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// The timestamp of the trigger's latest activation.
  ///
  /// Output only.
  core.String? latestActivationTime;

  /// The resource name of the manual trigger.
  ///
  /// Output only.
  core.String? name;

  /// The state of the manual trigger.
  ///
  /// Will be set to the `INACTIVE` state upon creation.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Default value when state is not specified or is
  /// unknown in this version.
  /// - "INACTIVE" : The trigger is currently inactive and ready to be
  /// activated.
  /// - "ACTIVE" : The trigger is currently active (activated).
  core.String? state;

  /// The unique ID of the manual trigger.
  ///
  /// Output only.
  core.String? triggerId;

  ManualTrigger();

  ManualTrigger.fromJson(core.Map _json) {
    if (_json.containsKey('activationDurationMinutes')) {
      activationDurationMinutes =
          _json['activationDurationMinutes'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('latestActivationTime')) {
      latestActivationTime = _json['latestActivationTime'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('triggerId')) {
      triggerId = _json['triggerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activationDurationMinutes != null)
          'activationDurationMinutes': activationDurationMinutes!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (displayName != null) 'displayName': displayName!,
        if (latestActivationTime != null)
          'latestActivationTime': latestActivationTime!,
        if (name != null) 'name': name!,
        if (state != null) 'state': state!,
        if (triggerId != null) 'triggerId': triggerId!,
      };
}

/// A strategy that automatically adjusts the bid to optimize a specified
/// performance goal while spending the full budget.
class MaximizeSpendBidStrategy {
  /// The ID of the Custom Bidding Algorithm used by this strategy.
  ///
  /// Only applicable when performance_goal_type is set to
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CUSTOM_ALGO`.
  core.String? customBiddingAlgorithmId;

  /// The maximum average CPM that may be bid, in micros of the advertiser's
  /// currency.
  ///
  /// Must be greater than or equal to a billable unit of the given currency.
  /// For example, 1500000 represents 1.5 standard units of the currency.
  core.String? maxAverageCpmBidAmountMicros;

  /// The type of the performance goal that the bidding strategy tries to
  /// minimize while spending the full budget.
  ///
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_VIEWABLE_CPM` is not supported for
  /// this strategy.
  ///
  /// Required.
  /// Possible string values are:
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_UNSPECIFIED" : Type value is not
  /// specified or is unknown in this version.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPA" : Cost per action.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPC" : Cost per click.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_VIEWABLE_CPM" : Viewable CPM.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CUSTOM_ALGO" : Custom bidding
  /// algorithm.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CIVA" : Completed inview and
  /// audible views.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_IVO_TEN" : Inview time over 10
  /// secs views.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_AV_VIEWED" : Viewable
  /// impressions.
  core.String? performanceGoalType;

  MaximizeSpendBidStrategy();

  MaximizeSpendBidStrategy.fromJson(core.Map _json) {
    if (_json.containsKey('customBiddingAlgorithmId')) {
      customBiddingAlgorithmId =
          _json['customBiddingAlgorithmId'] as core.String;
    }
    if (_json.containsKey('maxAverageCpmBidAmountMicros')) {
      maxAverageCpmBidAmountMicros =
          _json['maxAverageCpmBidAmountMicros'] as core.String;
    }
    if (_json.containsKey('performanceGoalType')) {
      performanceGoalType = _json['performanceGoalType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customBiddingAlgorithmId != null)
          'customBiddingAlgorithmId': customBiddingAlgorithmId!,
        if (maxAverageCpmBidAmountMicros != null)
          'maxAverageCpmBidAmountMicros': maxAverageCpmBidAmountMicros!,
        if (performanceGoalType != null)
          'performanceGoalType': performanceGoalType!,
      };
}

/// Measurement settings of a partner.
class MeasurementConfig {
  /// Whether or not to report DV360 cost to CM360.
  core.bool? dv360ToCmCostReportingEnabled;

  /// Whether or not to include DV360 data in CM360 data transfer reports.
  core.bool? dv360ToCmDataSharingEnabled;

  MeasurementConfig();

  MeasurementConfig.fromJson(core.Map _json) {
    if (_json.containsKey('dv360ToCmCostReportingEnabled')) {
      dv360ToCmCostReportingEnabled =
          _json['dv360ToCmCostReportingEnabled'] as core.bool;
    }
    if (_json.containsKey('dv360ToCmDataSharingEnabled')) {
      dv360ToCmDataSharingEnabled =
          _json['dv360ToCmDataSharingEnabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dv360ToCmCostReportingEnabled != null)
          'dv360ToCmCostReportingEnabled': dv360ToCmCostReportingEnabled!,
        if (dv360ToCmDataSharingEnabled != null)
          'dv360ToCmDataSharingEnabled': dv360ToCmDataSharingEnabled!,
      };
}

/// A mobile app promoted by a mobile app install line item.
class MobileApp {
  /// The ID of the app provided by the platform store.
  ///
  /// Android apps are identified by the bundle ID used by Android's Play store,
  /// such as `com.google.android.gm`. iOS apps are identified by a nine-digit
  /// app ID used by Apple's App store, such as `422689480`.
  ///
  /// Required.
  core.String? appId;

  /// The app name.
  ///
  /// Output only.
  core.String? displayName;

  /// The app platform.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "PLATFORM_UNSPECIFIED" : Platform is not specified.
  /// - "IOS" : iOS platform.
  /// - "ANDROID" : Android platform.
  core.String? platform;

  /// The app publisher.
  ///
  /// Output only.
  core.String? publisher;

  MobileApp();

  MobileApp.fromJson(core.Map _json) {
    if (_json.containsKey('appId')) {
      appId = _json['appId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('platform')) {
      platform = _json['platform'] as core.String;
    }
    if (_json.containsKey('publisher')) {
      publisher = _json['publisher'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appId != null) 'appId': appId!,
        if (displayName != null) 'displayName': displayName!,
        if (platform != null) 'platform': platform!,
        if (publisher != null) 'publisher': publisher!,
      };
}

/// Represents an amount of money with its currency type.
class Money {
  /// The three-letter currency code defined in ISO 4217.
  core.String? currencyCode;

  /// Number of nano (10^-9) units of the amount.
  ///
  /// The value must be between -999,999,999 and +999,999,999 inclusive. If
  /// `units` is positive, `nanos` must be positive or zero. If `units` is zero,
  /// `nanos` can be positive, zero, or negative. If `units` is negative,
  /// `nanos` must be negative or zero. For example $-1.75 is represented as
  /// `units`=-1 and `nanos`=-750,000,000.
  core.int? nanos;

  /// The whole units of the amount.
  ///
  /// For example if `currencyCode` is `"USD"`, then 1 unit is one US dollar.
  core.String? units;

  Money();

  Money.fromJson(core.Map _json) {
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('nanos')) {
      nanos = _json['nanos'] as core.int;
    }
    if (_json.containsKey('units')) {
      units = _json['units'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (nanos != null) 'nanos': nanos!,
        if (units != null) 'units': units!,
      };
}

/// Details for native content position assigned targeting option.
///
/// This will be populated in the native_content_position_details field when
/// targeting_type is `TARGETING_TYPE_NATIVE_CONTENT_POSITION`. Explicitly
/// targeting all options is not supported. Remove all native content position
/// targeting options to achieve this effect.
class NativeContentPositionAssignedTargetingOptionDetails {
  /// The content position.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "NATIVE_CONTENT_POSITION_UNSPECIFIED" : Native content position is not
  /// specified in this version. This enum is a place holder for a default value
  /// and does not represent a real native content position.
  /// - "NATIVE_CONTENT_POSITION_UNKNOWN" : The native content position is
  /// unknown.
  /// - "NATIVE_CONTENT_POSITION_IN_ARTICLE" : Native content position is
  /// in-article, i.e., ads appear between the paragraphs of pages.
  /// - "NATIVE_CONTENT_POSITION_IN_FEED" : Native content position is in-feed,
  /// i.e., ads appear in a scrollable stream of content. A feed is typically
  /// editorial (e.g. a list of articles or news) or listings (e.g. a list of
  /// products or services).
  /// - "NATIVE_CONTENT_POSITION_PERIPHERAL" : Native content position is
  /// peripheral, i.e., ads appear outside of core content on pages, such as the
  /// right- or left-hand side of the page.
  /// - "NATIVE_CONTENT_POSITION_RECOMMENDATION" : Native content position is
  /// recommendation, i.e., ads appear in sections for recommended content.
  core.String? contentPosition;

  /// The targeting_option_id field when targeting_type is
  /// `TARGETING_TYPE_NATIVE_CONTENT_POSITION`.
  ///
  /// Required.
  core.String? targetingOptionId;

  NativeContentPositionAssignedTargetingOptionDetails();

  NativeContentPositionAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('contentPosition')) {
      contentPosition = _json['contentPosition'] as core.String;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentPosition != null) 'contentPosition': contentPosition!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable native content position.
///
/// This will be populated in the native_content_position_details field when
/// targeting_type is `TARGETING_TYPE_NATIVE_CONTENT_POSITION`.
class NativeContentPositionTargetingOptionDetails {
  /// The content position.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "NATIVE_CONTENT_POSITION_UNSPECIFIED" : Native content position is not
  /// specified in this version. This enum is a place holder for a default value
  /// and does not represent a real native content position.
  /// - "NATIVE_CONTENT_POSITION_UNKNOWN" : The native content position is
  /// unknown.
  /// - "NATIVE_CONTENT_POSITION_IN_ARTICLE" : Native content position is
  /// in-article, i.e., ads appear between the paragraphs of pages.
  /// - "NATIVE_CONTENT_POSITION_IN_FEED" : Native content position is in-feed,
  /// i.e., ads appear in a scrollable stream of content. A feed is typically
  /// editorial (e.g. a list of articles or news) or listings (e.g. a list of
  /// products or services).
  /// - "NATIVE_CONTENT_POSITION_PERIPHERAL" : Native content position is
  /// peripheral, i.e., ads appear outside of core content on pages, such as the
  /// right- or left-hand side of the page.
  /// - "NATIVE_CONTENT_POSITION_RECOMMENDATION" : Native content position is
  /// recommendation, i.e., ads appear in sections for recommended content.
  core.String? contentPosition;

  NativeContentPositionTargetingOptionDetails();

  NativeContentPositionTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('contentPosition')) {
      contentPosition = _json['contentPosition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentPosition != null) 'contentPosition': contentPosition!,
      };
}

/// A negatively targeted keyword that belongs to a negative keyword list.
class NegativeKeyword {
  /// The negatively targeted keyword, for example `car insurance`.
  ///
  /// Must be UTF-8 encoded with a maximum size of 255 bytes. Maximum number of
  /// characters is 80. Maximum number of words is 10. Valid characters are
  /// restricted to ASCII characters only. The only URL-escaping permitted is
  /// for representing whitespace between words. Leading or trailing whitespace
  /// is ignored.
  ///
  /// Required. Immutable.
  core.String? keywordValue;

  /// The resource name of the negative keyword.
  ///
  /// Output only.
  core.String? name;

  NegativeKeyword();

  NegativeKeyword.fromJson(core.Map _json) {
    if (_json.containsKey('keywordValue')) {
      keywordValue = _json['keywordValue'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (keywordValue != null) 'keywordValue': keywordValue!,
        if (name != null) 'name': name!,
      };
}

/// A list of negative keywords used for targeting.
class NegativeKeywordList {
  /// The unique ID of the advertiser the negative keyword list belongs to.
  ///
  /// Output only.
  core.String? advertiserId;

  /// The display name of the negative keyword list.
  ///
  /// Must be UTF-8 encoded with a maximum size of 255 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// The resource name of the negative keyword list.
  ///
  /// Output only.
  core.String? name;

  /// The unique ID of the negative keyword list.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? negativeKeywordListId;

  /// Number of line items that are directly targeting this negative keyword
  /// list.
  ///
  /// Output only.
  core.String? targetedLineItemCount;

  NegativeKeywordList();

  NegativeKeywordList.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('negativeKeywordListId')) {
      negativeKeywordListId = _json['negativeKeywordListId'] as core.String;
    }
    if (_json.containsKey('targetedLineItemCount')) {
      targetedLineItemCount = _json['targetedLineItemCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
        if (negativeKeywordListId != null)
          'negativeKeywordListId': negativeKeywordListId!,
        if (targetedLineItemCount != null)
          'targetedLineItemCount': targetedLineItemCount!,
      };
}

/// Targeting details for negative keyword list.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_NEGATIVE_KEYWORD_LIST`.
class NegativeKeywordListAssignedTargetingOptionDetails {
  /// ID of the negative keyword list.
  ///
  /// Should refer to the negative_keyword_list_id field of a
  /// NegativeKeywordList resource.
  ///
  /// Required.
  core.String? negativeKeywordListId;

  NegativeKeywordListAssignedTargetingOptionDetails();

  NegativeKeywordListAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('negativeKeywordListId')) {
      negativeKeywordListId = _json['negativeKeywordListId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (negativeKeywordListId != null)
          'negativeKeywordListId': negativeKeywordListId!,
      };
}

/// OBA Icon for a Creative
class ObaIcon {
  /// The click tracking URL of the OBA icon.
  ///
  /// Only URLs of the following domains are allowed: * https://info.evidon.com
  /// * https://l.betrad.com
  ///
  /// Required.
  core.String? clickTrackingUrl;

  /// The dimensions of the OBA icon.
  Dimensions? dimensions;

  /// The landing page URL of the OBA icon.
  ///
  /// Only URLs of the following domains are allowed: * https://info.evidon.com
  /// * https://l.betrad.com
  ///
  /// Required.
  core.String? landingPageUrl;

  /// The position of the OBA icon on the creative.
  /// Possible string values are:
  /// - "OBA_ICON_POSITION_UNSPECIFIED" : The OBA icon position is not
  /// specified.
  /// - "OBA_ICON_POSITION_UPPER_RIGHT" : At the upper right side of the
  /// creative.
  /// - "OBA_ICON_POSITION_UPPER_LEFT" : At the upper left side of the creative.
  /// - "OBA_ICON_POSITION_LOWER_RIGHT" : At the lower right side of the
  /// creative.
  /// - "OBA_ICON_POSITION_LOWER_LEFT" : At the lower left side of the creative.
  core.String? position;

  /// The program of the OBA icon.
  ///
  /// For example: “AdChoices”.
  core.String? program;

  /// The MIME type of the OBA icon resource.
  core.String? resourceMimeType;

  /// The URL of the OBA icon resource.
  core.String? resourceUrl;

  /// The view tracking URL of the OBA icon.
  ///
  /// Only URLs of the following domains are allowed: * https://info.evidon.com
  /// * https://l.betrad.com
  ///
  /// Required.
  core.String? viewTrackingUrl;

  ObaIcon();

  ObaIcon.fromJson(core.Map _json) {
    if (_json.containsKey('clickTrackingUrl')) {
      clickTrackingUrl = _json['clickTrackingUrl'] as core.String;
    }
    if (_json.containsKey('dimensions')) {
      dimensions = Dimensions.fromJson(
          _json['dimensions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('landingPageUrl')) {
      landingPageUrl = _json['landingPageUrl'] as core.String;
    }
    if (_json.containsKey('position')) {
      position = _json['position'] as core.String;
    }
    if (_json.containsKey('program')) {
      program = _json['program'] as core.String;
    }
    if (_json.containsKey('resourceMimeType')) {
      resourceMimeType = _json['resourceMimeType'] as core.String;
    }
    if (_json.containsKey('resourceUrl')) {
      resourceUrl = _json['resourceUrl'] as core.String;
    }
    if (_json.containsKey('viewTrackingUrl')) {
      viewTrackingUrl = _json['viewTrackingUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clickTrackingUrl != null) 'clickTrackingUrl': clickTrackingUrl!,
        if (dimensions != null) 'dimensions': dimensions!.toJson(),
        if (landingPageUrl != null) 'landingPageUrl': landingPageUrl!,
        if (position != null) 'position': position!,
        if (program != null) 'program': program!,
        if (resourceMimeType != null) 'resourceMimeType': resourceMimeType!,
        if (resourceUrl != null) 'resourceUrl': resourceUrl!,
        if (viewTrackingUrl != null) 'viewTrackingUrl': viewTrackingUrl!,
      };
}

/// On screen position targeting option details.
///
/// This will be populated in the on_screen_position_details field when
/// targeting_type is `TARGETING_TYPE_ON_SCREEN_POSITION`.
class OnScreenPositionAssignedTargetingOptionDetails {
  /// The ad type to target.
  ///
  /// Only applicable to insertion order targeting and new line items supporting
  /// the specified ad type will inherit this targeting option by default.
  /// Possible values are: * `AD_TYPE_DISPLAY`, the setting will be inherited by
  /// new line item when line_item_type is `LINE_ITEM_TYPE_DISPLAY_DEFAULT`. *
  /// `AD_TYPE_VIDEO`, the setting will be inherited by new line item when
  /// line_item_type is `LINE_ITEM_TYPE_VIDEO_DEFAULT`.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "AD_TYPE_UNSPECIFIED" : Ad type is not specified or is unknown in this
  /// version.
  /// - "AD_TYPE_DISPLAY" : Display creatives, e.g. image and HTML5.
  /// - "AD_TYPE_VIDEO" : Video creatives, e.g. video ads that play during
  /// streaming content in video players.
  /// - "AD_TYPE_AUDIO" : Audio creatives, e.g. audio ads that play during audio
  /// content.
  core.String? adType;

  /// The on screen position.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ON_SCREEN_POSITION_UNSPECIFIED" : On screen position is not specified
  /// in this version. This enum is a place holder for a default value and does
  /// not represent a real on screen position.
  /// - "ON_SCREEN_POSITION_UNKNOWN" : The ad position is unknown on the screen.
  /// - "ON_SCREEN_POSITION_ABOVE_THE_FOLD" : The ad is located above the fold.
  /// - "ON_SCREEN_POSITION_BELOW_THE_FOLD" : The ad is located below the fold.
  core.String? onScreenPosition;

  /// The targeting_option_id field when targeting_type is
  /// `TARGETING_TYPE_ON_SCREEN_POSITION`.
  ///
  /// Required.
  core.String? targetingOptionId;

  OnScreenPositionAssignedTargetingOptionDetails();

  OnScreenPositionAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('adType')) {
      adType = _json['adType'] as core.String;
    }
    if (_json.containsKey('onScreenPosition')) {
      onScreenPosition = _json['onScreenPosition'] as core.String;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adType != null) 'adType': adType!,
        if (onScreenPosition != null) 'onScreenPosition': onScreenPosition!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable on screen position, which could be used by display
/// and video ads.
///
/// This will be populated in the on_screen_position_details field when
/// targeting_type is `TARGETING_TYPE_ON_SCREEN_POSITION`.
class OnScreenPositionTargetingOptionDetails {
  /// The on screen position.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ON_SCREEN_POSITION_UNSPECIFIED" : On screen position is not specified
  /// in this version. This enum is a place holder for a default value and does
  /// not represent a real on screen position.
  /// - "ON_SCREEN_POSITION_UNKNOWN" : The ad position is unknown on the screen.
  /// - "ON_SCREEN_POSITION_ABOVE_THE_FOLD" : The ad is located above the fold.
  /// - "ON_SCREEN_POSITION_BELOW_THE_FOLD" : The ad is located below the fold.
  core.String? onScreenPosition;

  OnScreenPositionTargetingOptionDetails();

  OnScreenPositionTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('onScreenPosition')) {
      onScreenPosition = _json['onScreenPosition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (onScreenPosition != null) 'onScreenPosition': onScreenPosition!,
      };
}

/// Assigned operating system targeting option details.
///
/// This will be populated in the operating_system_details field when
/// targeting_type is `TARGETING_TYPE_OPERATING_SYSTEM`.
class OperatingSystemAssignedTargetingOptionDetails {
  /// The display name of the operating system.
  ///
  /// Output only.
  core.String? displayName;

  /// Indicates if this option is being negatively targeted.
  core.bool? negative;

  /// The targeting option ID populated in targeting_option_id field when
  /// targeting_type is `TARGETING_TYPE_OPERATING_SYSTEM`.
  ///
  /// Required.
  core.String? targetingOptionId;

  OperatingSystemAssignedTargetingOptionDetails();

  OperatingSystemAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (negative != null) 'negative': negative!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable operating system.
///
/// This will be populated in the operating_system_details field of a
/// TargetingOption when targeting_type is `TARGETING_TYPE_OPERATING_SYSTEM`.
class OperatingSystemTargetingOptionDetails {
  /// The display name of the operating system.
  ///
  /// Output only.
  core.String? displayName;

  OperatingSystemTargetingOptionDetails();

  OperatingSystemTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
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

/// Settings that control the rate at which a budget is spent.
class Pacing {
  /// Maximum number of impressions to serve every day.
  ///
  /// Applicable when the budget is impression based. Must be greater than 0.
  core.String? dailyMaxImpressions;

  /// Maximum currency amount to spend every day in micros of advertiser's
  /// currency.
  ///
  /// Applicable when the budget is currency based. Must be greater than 0. For
  /// example, for 1.5 standard unit of the currency, set this field to 1500000.
  /// The value assigned will be rounded to whole billable units for the
  /// relevant currency by the following rules: any positive value less than a
  /// single billable unit will be rounded up to one billable unit and any value
  /// larger than a single billable unit will be rounded down to the nearest
  /// billable value. For example, if the currency's billable unit is 0.01, and
  /// this field is set to 10257770, it will round down to 10250000, a value of
  /// 10.25. If set to 505, it will round up to 10000, a value of 0.01.
  core.String? dailyMaxMicros;

  /// The time period in which the pacing budget will be spent.
  ///
  /// When automatic budget allocation is enabled at the insertion order via
  /// auto_budget_allocation, this field is output only and defaults to
  /// `PACING_PERIOD_FLIGHT`.
  ///
  /// Required.
  /// Possible string values are:
  /// - "PACING_PERIOD_UNSPECIFIED" : Period value is not specified or is
  /// unknown in this version.
  /// - "PACING_PERIOD_DAILY" : The pacing setting will be applied on daily
  /// basis.
  /// - "PACING_PERIOD_FLIGHT" : The pacing setting will be applied to the whole
  /// flight duration.
  core.String? pacingPeriod;

  /// The type of pacing that defines how the budget amount will be spent across
  /// the pacing_period.
  ///
  /// Required.
  /// Possible string values are:
  /// - "PACING_TYPE_UNSPECIFIED" : Pacing mode value is not specified or is
  /// unknown in this version.
  /// - "PACING_TYPE_AHEAD" : Only applicable to `PACING_PERIOD_FLIGHT` pacing
  /// period. Ahead pacing attempts to spend faster than evenly, to make sure
  /// the entire budget is spent by the end of the flight.
  /// - "PACING_TYPE_ASAP" : Spend all of pacing budget amount as quick as
  /// possible.
  /// - "PACING_TYPE_EVEN" : Spend a consistent budget amount every period of
  /// time.
  core.String? pacingType;

  Pacing();

  Pacing.fromJson(core.Map _json) {
    if (_json.containsKey('dailyMaxImpressions')) {
      dailyMaxImpressions = _json['dailyMaxImpressions'] as core.String;
    }
    if (_json.containsKey('dailyMaxMicros')) {
      dailyMaxMicros = _json['dailyMaxMicros'] as core.String;
    }
    if (_json.containsKey('pacingPeriod')) {
      pacingPeriod = _json['pacingPeriod'] as core.String;
    }
    if (_json.containsKey('pacingType')) {
      pacingType = _json['pacingType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dailyMaxImpressions != null)
          'dailyMaxImpressions': dailyMaxImpressions!,
        if (dailyMaxMicros != null) 'dailyMaxMicros': dailyMaxMicros!,
        if (pacingPeriod != null) 'pacingPeriod': pacingPeriod!,
        if (pacingType != null) 'pacingType': pacingType!,
      };
}

/// A filtering option that filters on selected file types belonging to a chosen
/// set of filter entities.
class ParentEntityFilter {
  /// File types that will be returned.
  ///
  /// Required.
  core.List<core.String>? fileType;

  /// The IDs of the specified filter type.
  ///
  /// This is used to filter entities to fetch. If filter type is not
  /// `FILTER_TYPE_NONE`, at least one ID must be specified.
  core.List<core.String>? filterIds;

  /// Filter type used to filter fetched entities.
  ///
  /// Required.
  /// Possible string values are:
  /// - "FILTER_TYPE_UNSPECIFIED" : Default value when type is unspecified or is
  /// unknown in this version.
  /// - "FILTER_TYPE_NONE" : If selected, no filter will be applied to the
  /// download. Can only be used if an Advertiser is specified in
  /// CreateSdfDownloadTaskRequest.
  /// - "FILTER_TYPE_ADVERTISER_ID" : Advertiser ID. If selected, all filter IDs
  /// must be Advertiser IDs that belong to the Partner specified in
  /// CreateSdfDownloadTaskRequest.
  /// - "FILTER_TYPE_CAMPAIGN_ID" : Campaign ID. If selected, all filter IDs
  /// must be Campaign IDs that belong to the Advertiser or Partner specified in
  /// CreateSdfDownloadTaskRequest.
  /// - "FILTER_TYPE_MEDIA_PRODUCT_ID" : Media Product ID. If selected, all
  /// filter IDs must be Media Product IDs that belong to the Advertiser or
  /// Partner specified in CreateSdfDownloadTaskRequest. Can only be used for
  /// downloading `FILE_TYPE_MEDIA_PRODUCT`.
  /// - "FILTER_TYPE_INSERTION_ORDER_ID" : Insertion Order ID. If selected, all
  /// filter IDs must be Insertion Order IDs that belong to the Advertiser or
  /// Partner specified in CreateSdfDownloadTaskRequest. Can only be used for
  /// downloading `FILE_TYPE_INSERTION_ORDER`, `FILE_TYPE_LINE_ITEM`,
  /// `FILE_TYPE_AD_GROUP`, and `FILE_TYPE_AD`.
  /// - "FILTER_TYPE_LINE_ITEM_ID" : Line Item ID. If selected, all filter IDs
  /// must be Line Item IDs that belong to the Advertiser or Partner specified
  /// in CreateSdfDownloadTaskRequest. Can only be used for downloading
  /// `FILE_TYPE_LINE_ITEM`, `FILE_TYPE_AD_GROUP`, and `FILE_TYPE_AD`.
  core.String? filterType;

  ParentEntityFilter();

  ParentEntityFilter.fromJson(core.Map _json) {
    if (_json.containsKey('fileType')) {
      fileType = (_json['fileType'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('filterIds')) {
      filterIds = (_json['filterIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('filterType')) {
      filterType = _json['filterType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fileType != null) 'fileType': fileType!,
        if (filterIds != null) 'filterIds': filterIds!,
        if (filterType != null) 'filterType': filterType!,
      };
}

/// Details for assigned parental status targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARTGETING_TYPE_PARENTAL_STATUS`.
class ParentalStatusAssignedTargetingOptionDetails {
  /// The parental status of the audience.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "PARENTAL_STATUS_UNSPECIFIED" : Default value when parental status is
  /// not specified in this version. This enum is a place holder for default
  /// value and does not represent a real parental status option.
  /// - "PARENTAL_STATUS_PARENT" : The audience is a parent.
  /// - "PARENTAL_STATUS_NOT_A_PARENT" : The audience is not a parent.
  /// - "PARENTAL_STATUS_UNKNOWN" : The parental status of the audience is
  /// unknown.
  core.String? parentalStatus;

  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_PARENTAL_STATUS`.
  ///
  /// Required.
  core.String? targetingOptionId;

  ParentalStatusAssignedTargetingOptionDetails();

  ParentalStatusAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('parentalStatus')) {
      parentalStatus = _json['parentalStatus'] as core.String;
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parentalStatus != null) 'parentalStatus': parentalStatus!,
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable parental status.
///
/// This will be populated in the parental_status_details field of a
/// TargetingOption when targeting_type is `TARGETING_TYPE_PARENTAL_STATUS`.
class ParentalStatusTargetingOptionDetails {
  /// The parental status of an audience.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "PARENTAL_STATUS_UNSPECIFIED" : Default value when parental status is
  /// not specified in this version. This enum is a place holder for default
  /// value and does not represent a real parental status option.
  /// - "PARENTAL_STATUS_PARENT" : The audience is a parent.
  /// - "PARENTAL_STATUS_NOT_A_PARENT" : The audience is not a parent.
  /// - "PARENTAL_STATUS_UNKNOWN" : The parental status of the audience is
  /// unknown.
  core.String? parentalStatus;

  ParentalStatusTargetingOptionDetails();

  ParentalStatusTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('parentalStatus')) {
      parentalStatus = _json['parentalStatus'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parentalStatus != null) 'parentalStatus': parentalStatus!,
      };
}

/// A single partner in Display & Video 360 (DV360).
class Partner {
  /// Ad server related settings of the partner.
  PartnerAdServerConfig? adServerConfig;

  /// Settings that control how partner data may be accessed.
  PartnerDataAccessConfig? dataAccessConfig;

  /// The display name of the partner.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  core.String? displayName;

  /// The status of the partner.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ENTITY_STATUS_UNSPECIFIED" : Default value when status is not specified
  /// or is unknown in this version.
  /// - "ENTITY_STATUS_ACTIVE" : The entity is enabled to bid and spend budget.
  /// - "ENTITY_STATUS_ARCHIVED" : The entity is archived. Bidding and budget
  /// spending are disabled. An entity can be deleted after archived. Deleted
  /// entities cannot be retrieved.
  /// - "ENTITY_STATUS_DRAFT" : The entity is under draft. Bidding and budget
  /// spending are disabled.
  /// - "ENTITY_STATUS_PAUSED" : Bidding and budget spending are paused for the
  /// entity.
  /// - "ENTITY_STATUS_SCHEDULED_FOR_DELETION" : The entity is scheduled for
  /// deletion.
  core.String? entityStatus;

  /// Settings that control which exchanges are enabled for the partner.
  ExchangeConfig? exchangeConfig;

  /// General settings of the partner.
  PartnerGeneralConfig? generalConfig;

  /// The resource name of the partner.
  ///
  /// Output only.
  core.String? name;

  /// The unique ID of the partner.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? partnerId;

  /// The timestamp when the partner was last updated.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? updateTime;

  Partner();

  Partner.fromJson(core.Map _json) {
    if (_json.containsKey('adServerConfig')) {
      adServerConfig = PartnerAdServerConfig.fromJson(
          _json['adServerConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataAccessConfig')) {
      dataAccessConfig = PartnerDataAccessConfig.fromJson(
          _json['dataAccessConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('entityStatus')) {
      entityStatus = _json['entityStatus'] as core.String;
    }
    if (_json.containsKey('exchangeConfig')) {
      exchangeConfig = ExchangeConfig.fromJson(
          _json['exchangeConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('generalConfig')) {
      generalConfig = PartnerGeneralConfig.fromJson(
          _json['generalConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('partnerId')) {
      partnerId = _json['partnerId'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adServerConfig != null) 'adServerConfig': adServerConfig!.toJson(),
        if (dataAccessConfig != null)
          'dataAccessConfig': dataAccessConfig!.toJson(),
        if (displayName != null) 'displayName': displayName!,
        if (entityStatus != null) 'entityStatus': entityStatus!,
        if (exchangeConfig != null) 'exchangeConfig': exchangeConfig!.toJson(),
        if (generalConfig != null) 'generalConfig': generalConfig!.toJson(),
        if (name != null) 'name': name!,
        if (partnerId != null) 'partnerId': partnerId!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Ad server related settings of a partner.
class PartnerAdServerConfig {
  /// Measurement settings of a partner.
  MeasurementConfig? measurementConfig;

  PartnerAdServerConfig();

  PartnerAdServerConfig.fromJson(core.Map _json) {
    if (_json.containsKey('measurementConfig')) {
      measurementConfig = MeasurementConfig.fromJson(
          _json['measurementConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (measurementConfig != null)
          'measurementConfig': measurementConfig!.toJson(),
      };
}

/// Settings that control a partner cost.
///
/// A partner cost is any type of expense involved in running a campaign, other
/// than the costs of purchasing impressions (which is called the media cost)
/// and using third-party audience segment data (data fee). Some examples of
/// partner costs include the fees for using DV360, a third-party ad server, or
/// a third-party ad serving verification service.
class PartnerCost {
  /// The type of the partner cost.
  ///
  /// Required.
  /// Possible string values are:
  /// - "PARTNER_COST_TYPE_UNSPECIFIED" : Type value is not specified or is
  /// unknown in this version.
  /// - "PARTNER_COST_TYPE_ADLOOX" : The cost is charged for using Adloox.
  /// - "PARTNER_COST_TYPE_ADLOOX_PREBID" : The cost is charged for using Adloox
  /// Pre-Bid.
  /// - "PARTNER_COST_TYPE_ADSAFE" : The cost is charged for using AdSafe.
  /// - "PARTNER_COST_TYPE_ADXPOSE" : The cost is charged for using AdExpose.
  /// - "PARTNER_COST_TYPE_AGGREGATE_KNOWLEDGE" : The cost is charged for using
  /// Aggregate Knowledge.
  /// - "PARTNER_COST_TYPE_AGENCY_TRADING_DESK" : The cost is charged for using
  /// an Agency Trading Desk.
  /// - "PARTNER_COST_TYPE_DV360_FEE" : The cost is charged for using DV360.
  /// - "PARTNER_COST_TYPE_COMSCORE_VCE" : The cost is charged for using
  /// comScore vCE.
  /// - "PARTNER_COST_TYPE_DATA_MANAGEMENT_PLATFORM" : The cost is charged for
  /// using a Data Management Platform.
  /// - "PARTNER_COST_TYPE_DEFAULT" : The default cost type.
  /// - "PARTNER_COST_TYPE_DOUBLE_VERIFY" : The cost is charged for using
  /// DoubleVerify.
  /// - "PARTNER_COST_TYPE_DOUBLE_VERIFY_PREBID" : The cost is charged for using
  /// DoubleVerify Pre-Bid.
  /// - "PARTNER_COST_TYPE_EVIDON" : The cost is charged for using Evidon.
  /// - "PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_VIDEO" : The cost is charged for
  /// using Integral Ad Science Video.
  /// - "PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_PREBID" : The cost is charged for
  /// using Integral Ad Science Pre-Bid.
  /// - "PARTNER_COST_TYPE_MEDIA_COST_DATA" : The cost is charged for using
  /// media cost data.
  /// - "PARTNER_COST_TYPE_MOAT_VIDEO" : The cost is charged for using MOAT
  /// Video.
  /// - "PARTNER_COST_TYPE_NIELSEN_DAR" : The cost is charged for using Nielsen
  /// Digital Ad Ratings.
  /// - "PARTNER_COST_TYPE_SHOP_LOCAL" : The cost is charged for using
  /// ShopLocal.
  /// - "PARTNER_COST_TYPE_TERACENT" : The cost is charged for using Teracent.
  /// - "PARTNER_COST_TYPE_THIRD_PARTY_AD_SERVER" : The cost is charged for
  /// using a third-party ad server.
  /// - "PARTNER_COST_TYPE_TRUST_METRICS" : The cost is charged for using
  /// TrustMetrics.
  /// - "PARTNER_COST_TYPE_VIZU" : The cost is charged for using Vizu.
  /// - "PARTNER_COST_TYPE_ADLINGO_FEE" : The cost is charged for using AdLingo.
  /// - "PARTNER_COST_TYPE_CUSTOM_FEE_1" : The cost is charged as custom fee 1.
  /// - "PARTNER_COST_TYPE_CUSTOM_FEE_2" : The cost is charged as custom fee 2.
  /// - "PARTNER_COST_TYPE_CUSTOM_FEE_3" : The cost is charged as custom fee 3.
  /// - "PARTNER_COST_TYPE_CUSTOM_FEE_4" : The cost is charged as custom fee 4.
  /// - "PARTNER_COST_TYPE_CUSTOM_FEE_5" : The cost is charged as custom fee 5.
  core.String? costType;

  /// The CPM fee amount in micros of advertiser's currency.
  ///
  /// Applicable when the fee_type is `PARTNER_FEE_TYPE_CPM_FEE`. Must be
  /// greater than or equal to 0. For example, for 1.5 standard unit of the
  /// advertiser's currency, set this field to 1500000.
  core.String? feeAmount;

  /// The media fee percentage in millis (1/1000 of a percent).
  ///
  /// Applicable when the fee_type is `PARTNER_FEE_TYPE_MEDIA_FEE`. Must be
  /// greater than or equal to 0. For example: 100 represents 0.1%.
  core.String? feePercentageMillis;

  /// The fee type for this partner cost.
  ///
  /// Required.
  /// Possible string values are:
  /// - "PARTNER_COST_FEE_TYPE_UNSPECIFIED" : Value is not specified or is
  /// unknown in this version.
  /// - "PARTNER_COST_FEE_TYPE_CPM_FEE" : The partner cost is a fixed CPM fee.
  /// Not applicable when the partner cost cost_type is one of: *
  /// `PARTNER_COST_TYPE_MEDIA_COST_DATA` * `PARTNER_COST_TYPE_DV360_FEE`.
  /// - "PARTNER_COST_FEE_TYPE_MEDIA_FEE" : The partner cost is a percentage
  /// surcharge based on the media cost. Not applicable when the partner
  /// cost_type is one of: * `PARTNER_COST_TYPE_SHOP_LOCAL` *
  /// `PARTNER_COST_TYPE_TRUST_METRICS` *
  /// `PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_VIDEO` *
  /// `PARTNER_COST_TYPE_MOAT_VIDEO`.
  core.String? feeType;

  /// The invoice type for this partner cost.
  ///
  /// * Required when cost_type is one of: - `PARTNER_COST_TYPE_ADLOOX` -
  /// `PARTNER_COST_TYPE_DOUBLE_VERIFY` -
  /// `PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE`. * Output only for other types.
  /// Possible string values are:
  /// - "PARTNER_COST_INVOICE_TYPE_UNSPECIFIED" : Type value is not specified or
  /// is unknown in this version.
  /// - "PARTNER_COST_INVOICE_TYPE_DV360" : Partner cost is billed through
  /// DV360.
  /// - "PARTNER_COST_INVOICE_TYPE_PARTNER" : Partner cost is billed by the
  /// partner.
  core.String? invoiceType;

  PartnerCost();

  PartnerCost.fromJson(core.Map _json) {
    if (_json.containsKey('costType')) {
      costType = _json['costType'] as core.String;
    }
    if (_json.containsKey('feeAmount')) {
      feeAmount = _json['feeAmount'] as core.String;
    }
    if (_json.containsKey('feePercentageMillis')) {
      feePercentageMillis = _json['feePercentageMillis'] as core.String;
    }
    if (_json.containsKey('feeType')) {
      feeType = _json['feeType'] as core.String;
    }
    if (_json.containsKey('invoiceType')) {
      invoiceType = _json['invoiceType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (costType != null) 'costType': costType!,
        if (feeAmount != null) 'feeAmount': feeAmount!,
        if (feePercentageMillis != null)
          'feePercentageMillis': feePercentageMillis!,
        if (feeType != null) 'feeType': feeType!,
        if (invoiceType != null) 'invoiceType': invoiceType!,
      };
}

/// Settings that control how partner related data may be accessed.
class PartnerDataAccessConfig {
  /// Structured Data Files (SDF) settings for the partner.
  ///
  /// The SDF configuration for the partner.
  SdfConfig? sdfConfig;

  PartnerDataAccessConfig();

  PartnerDataAccessConfig.fromJson(core.Map _json) {
    if (_json.containsKey('sdfConfig')) {
      sdfConfig = SdfConfig.fromJson(
          _json['sdfConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sdfConfig != null) 'sdfConfig': sdfConfig!.toJson(),
      };
}

/// General settings of a partner.
class PartnerGeneralConfig {
  /// Partner's currency in ISO 4217 format.
  ///
  /// Immutable.
  core.String? currencyCode;

  /// The standard TZ database name of the partner's time zone.
  ///
  /// For example, `America/New_York`. See more at:
  /// https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  ///
  /// Immutable.
  core.String? timeZone;

  PartnerGeneralConfig();

  PartnerGeneralConfig.fromJson(core.Map _json) {
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('timeZone')) {
      timeZone = _json['timeZone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (timeZone != null) 'timeZone': timeZone!,
      };
}

/// Settings that control how partner revenue is calculated.
class PartnerRevenueModel {
  /// The markup amount of the partner revenue model.
  ///
  /// Must be greater than or equal to 0. * When the markup_type is set to be
  /// `PARTNER_REVENUE_MODEL_MARKUP_TYPE_CPM`, this field represents the CPM
  /// markup in micros of advertiser's currency. For example, 1500000 represents
  /// 1.5 standard units of the currency. * When the markup_type is set to be
  /// `PARTNER_REVENUE_MODEL_MARKUP_TYPE_MEDIA_COST_MARKUP`, this field
  /// represents the media cost percent markup in millis. For example, 100
  /// represents 0.1% (decimal 0.001). * When the markup_type is set to be
  /// `PARTNER_REVENUE_MODEL_MARKUP_TYPE_TOTAL_MEDIA_COST_MARKUP`, this field
  /// represents the total media cost percent markup in millis. For example, 100
  /// represents 0.1% (decimal 0.001).
  ///
  /// Required.
  core.String? markupAmount;

  /// The markup type of the partner revenue model.
  ///
  /// Required.
  /// Possible string values are:
  /// - "PARTNER_REVENUE_MODEL_MARKUP_TYPE_UNSPECIFIED" : Type value is not
  /// specified or is unknown in this version.
  /// - "PARTNER_REVENUE_MODEL_MARKUP_TYPE_CPM" : Calculate the partner revenue
  /// based on a fixed CPM.
  /// - "PARTNER_REVENUE_MODEL_MARKUP_TYPE_MEDIA_COST_MARKUP" : Calculate the
  /// partner revenue based on a percentage surcharge of its media cost.
  /// - "PARTNER_REVENUE_MODEL_MARKUP_TYPE_TOTAL_MEDIA_COST_MARKUP" : Calculate
  /// the partner revenue based on a percentage surcharge of its total media
  /// cost, which includes all partner costs and data costs.
  core.String? markupType;

  PartnerRevenueModel();

  PartnerRevenueModel.fromJson(core.Map _json) {
    if (_json.containsKey('markupAmount')) {
      markupAmount = _json['markupAmount'] as core.String;
    }
    if (_json.containsKey('markupType')) {
      markupType = _json['markupType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (markupAmount != null) 'markupAmount': markupAmount!,
        if (markupType != null) 'markupType': markupType!,
      };
}

/// Settings that control the performance goal of a campaign or insertion order.
class PerformanceGoal {
  /// The goal amount, in micros of the advertiser's currency.
  ///
  /// Applicable when performance_goal_type is one of: *
  /// `PERFORMANCE_GOAL_TYPE_CPM` * `PERFORMANCE_GOAL_TYPE_CPC` *
  /// `PERFORMANCE_GOAL_TYPE_CPA` * `PERFORMANCE_GOAL_TYPE_CPIAVC` *
  /// `PERFORMANCE_GOAL_TYPE_VCPM` For example 1500000 represents 1.5 standard
  /// units of the currency.
  core.String? performanceGoalAmountMicros;

  /// The decimal representation of the goal percentage in micros.
  ///
  /// Applicable when performance_goal_type is one of: *
  /// `PERFORMANCE_GOAL_TYPE_CTR` * `PERFORMANCE_GOAL_TYPE_VIEWABILITY` *
  /// `PERFORMANCE_GOAL_TYPE_CLICK_CVR` * `PERFORMANCE_GOAL_TYPE_IMPRESSION_CVR`
  /// * `PERFORMANCE_GOAL_TYPE_VTR` *
  /// `PERFORMANCE_GOAL_TYPE_AUDIO_COMPLETION_RATE` *
  /// `PERFORMANCE_GOAL_TYPE_VIDEO_COMPLETION_RATE` For example, 70000
  /// represents 7% (decimal 0.07).
  core.String? performanceGoalPercentageMicros;

  /// A key performance indicator (KPI) string, which can be empty.
  ///
  /// Must be UTF-8 encoded with a length of no more than 100 characters.
  /// Applicable when performance_goal_type is set to
  /// `PERFORMANCE_GOAL_TYPE_OTHER`.
  core.String? performanceGoalString;

  /// The type of the performance goal.
  ///
  /// Required.
  /// Possible string values are:
  /// - "PERFORMANCE_GOAL_TYPE_UNSPECIFIED" : Performance goal type is not
  /// specified or is unknown in this version.
  /// - "PERFORMANCE_GOAL_TYPE_CPM" : The performance goal is set in CPM (cost
  /// per mille).
  /// - "PERFORMANCE_GOAL_TYPE_CPC" : The performance goal is set in CPC (cost
  /// per click).
  /// - "PERFORMANCE_GOAL_TYPE_CPA" : The performance goal is set in CPA (cost
  /// per action).
  /// - "PERFORMANCE_GOAL_TYPE_CTR" : The performance goal is set in CTR
  /// (click-through rate) percentage.
  /// - "PERFORMANCE_GOAL_TYPE_VIEWABILITY" : The performance goal is set in
  /// Viewability percentage.
  /// - "PERFORMANCE_GOAL_TYPE_CPIAVC" : The performance goal is set as CPIAVC
  /// (cost per impression audible and visible at completion).
  /// - "PERFORMANCE_GOAL_TYPE_CPE" : The performance goal is set in CPE (cost
  /// per engagement).
  /// - "PERFORMANCE_GOAL_TYPE_CLICK_CVR" : The performance goal is set in click
  /// conversion rate (conversions per click) percentage.
  /// - "PERFORMANCE_GOAL_TYPE_IMPRESSION_CVR" : The performance goal is set in
  /// impression conversion rate (conversions per impression) percentage.
  /// - "PERFORMANCE_GOAL_TYPE_VCPM" : The performance goal is set in VCPM (cost
  /// per thousand viewable impressions).
  /// - "PERFORMANCE_GOAL_TYPE_VTR" : The performance goal is set in YouTube
  /// view rate (YouTube views per impression) percentage.
  /// - "PERFORMANCE_GOAL_TYPE_AUDIO_COMPLETION_RATE" : The performance goal is
  /// set in audio completion rate (complete audio listens per impression)
  /// percentage.
  /// - "PERFORMANCE_GOAL_TYPE_VIDEO_COMPLETION_RATE" : The performance goal is
  /// set in video completion rate (complete video views per impression)
  /// percentage.
  /// - "PERFORMANCE_GOAL_TYPE_OTHER" : The performance goal is set to Other.
  core.String? performanceGoalType;

  PerformanceGoal();

  PerformanceGoal.fromJson(core.Map _json) {
    if (_json.containsKey('performanceGoalAmountMicros')) {
      performanceGoalAmountMicros =
          _json['performanceGoalAmountMicros'] as core.String;
    }
    if (_json.containsKey('performanceGoalPercentageMicros')) {
      performanceGoalPercentageMicros =
          _json['performanceGoalPercentageMicros'] as core.String;
    }
    if (_json.containsKey('performanceGoalString')) {
      performanceGoalString = _json['performanceGoalString'] as core.String;
    }
    if (_json.containsKey('performanceGoalType')) {
      performanceGoalType = _json['performanceGoalType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (performanceGoalAmountMicros != null)
          'performanceGoalAmountMicros': performanceGoalAmountMicros!,
        if (performanceGoalPercentageMicros != null)
          'performanceGoalPercentageMicros': performanceGoalPercentageMicros!,
        if (performanceGoalString != null)
          'performanceGoalString': performanceGoalString!,
        if (performanceGoalType != null)
          'performanceGoalType': performanceGoalType!,
      };
}

/// A strategy that automatically adjusts the bid to meet or beat a specified
/// performance goal.
class PerformanceGoalBidStrategy {
  /// The ID of the Custom Bidding Algorithm used by this strategy.
  ///
  /// Only applicable when performance_goal_type is set to
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CUSTOM_ALGO`.
  core.String? customBiddingAlgorithmId;

  /// The maximum average CPM that may be bid, in micros of the advertiser's
  /// currency.
  ///
  /// Must be greater than or equal to a billable unit of the given currency.
  /// Not applicable when performance_goal_type is set to
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_VIEWABLE_CPM`. For example,
  /// 1500000 represents 1.5 standard units of the currency.
  core.String? maxAverageCpmBidAmountMicros;

  /// The performance goal the bidding strategy will attempt to meet or beat, in
  /// micros of the advertiser's currency or in micro of the ROAS (Return On
  /// Advertising Spend) value which is also based on advertiser's currency.
  ///
  /// Must be greater than or equal to a billable unit of the given currency and
  /// smaller or equal to upper bounds. Each performance_goal_type has its upper
  /// bound: * when performance_goal_type is
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPA`, upper bound is 10000.00 USD.
  /// * when performance_goal_type is
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPC`, upper bound is 1000.00 USD.
  /// * when performance_goal_type is
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_VIEWABLE_CPM`, upper bound is
  /// 1000.00 USD. * when performance_goal_type is
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CUSTOM_ALGO`, upper bound is
  /// 1000.00 and lower bound is 0.01. Example: If set to
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_VIEWABLE_CPM`, the bid price will
  /// be based on the probability that each available impression will be
  /// viewable. For example, if viewable CPM target is $2 and an impression is
  /// 40% likely to be viewable, the bid price will be $0.80 CPM (40% of $2).
  /// For example, 1500000 represents 1.5 standard units of the currency or ROAS
  /// value.
  ///
  /// Required.
  core.String? performanceGoalAmountMicros;

  /// The type of the performance goal that the bidding strategy will try to
  /// meet or beat.
  ///
  /// For line item level usage, the value must be one of: *
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPA` *
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPC` *
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_VIEWABLE_CPM` *
  /// `BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CUSTOM_ALGO`.
  ///
  /// Required.
  /// Possible string values are:
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_UNSPECIFIED" : Type value is not
  /// specified or is unknown in this version.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPA" : Cost per action.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPC" : Cost per click.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_VIEWABLE_CPM" : Viewable CPM.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CUSTOM_ALGO" : Custom bidding
  /// algorithm.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CIVA" : Completed inview and
  /// audible views.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_IVO_TEN" : Inview time over 10
  /// secs views.
  /// - "BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_AV_VIEWED" : Viewable
  /// impressions.
  core.String? performanceGoalType;

  PerformanceGoalBidStrategy();

  PerformanceGoalBidStrategy.fromJson(core.Map _json) {
    if (_json.containsKey('customBiddingAlgorithmId')) {
      customBiddingAlgorithmId =
          _json['customBiddingAlgorithmId'] as core.String;
    }
    if (_json.containsKey('maxAverageCpmBidAmountMicros')) {
      maxAverageCpmBidAmountMicros =
          _json['maxAverageCpmBidAmountMicros'] as core.String;
    }
    if (_json.containsKey('performanceGoalAmountMicros')) {
      performanceGoalAmountMicros =
          _json['performanceGoalAmountMicros'] as core.String;
    }
    if (_json.containsKey('performanceGoalType')) {
      performanceGoalType = _json['performanceGoalType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customBiddingAlgorithmId != null)
          'customBiddingAlgorithmId': customBiddingAlgorithmId!,
        if (maxAverageCpmBidAmountMicros != null)
          'maxAverageCpmBidAmountMicros': maxAverageCpmBidAmountMicros!,
        if (performanceGoalAmountMicros != null)
          'performanceGoalAmountMicros': performanceGoalAmountMicros!,
        if (performanceGoalType != null)
          'performanceGoalType': performanceGoalType!,
      };
}

/// Settings specific to the MediaOcean Prisma tool.
class PrismaConfig {
  /// Google Payments Center supports searching and filtering on this code.
  ///
  /// Required.
  PrismaCpeCode? prismaCpeCode;

  /// The Prisma type.
  ///
  /// Required.
  /// Possible string values are:
  /// - "PRISMA_TYPE_UNSPECIFIED" : Type is not specified or unknown in this
  /// version.
  /// - "PRISMA_TYPE_DISPLAY" : Display type.
  /// - "PRISMA_TYPE_SEARCH" : Search type.
  /// - "PRISMA_TYPE_VIDEO" : Video type.
  /// - "PRISMA_TYPE_AUDIO" : Audio type.
  /// - "PRISMA_TYPE_SOCIAL" : Social type.
  /// - "PRISMA_TYPE_FEE" : Fee type.
  core.String? prismaType;

  /// The entity allocated this budget (DSP, site, etc.).
  ///
  /// Required.
  core.String? supplier;

  PrismaConfig();

  PrismaConfig.fromJson(core.Map _json) {
    if (_json.containsKey('prismaCpeCode')) {
      prismaCpeCode = PrismaCpeCode.fromJson(
          _json['prismaCpeCode'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('prismaType')) {
      prismaType = _json['prismaType'] as core.String;
    }
    if (_json.containsKey('supplier')) {
      supplier = _json['supplier'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (prismaCpeCode != null) 'prismaCpeCode': prismaCpeCode!.toJson(),
        if (prismaType != null) 'prismaType': prismaType!,
        if (supplier != null) 'supplier': supplier!,
      };
}

/// Google Payments Center supports searching and filtering on the component
/// fields of this code.
class PrismaCpeCode {
  /// The Prisma client code.
  core.String? prismaClientCode;

  /// The Prisma estimate code.
  core.String? prismaEstimateCode;

  /// The Prisma product code.
  core.String? prismaProductCode;

  PrismaCpeCode();

  PrismaCpeCode.fromJson(core.Map _json) {
    if (_json.containsKey('prismaClientCode')) {
      prismaClientCode = _json['prismaClientCode'] as core.String;
    }
    if (_json.containsKey('prismaEstimateCode')) {
      prismaEstimateCode = _json['prismaEstimateCode'] as core.String;
    }
    if (_json.containsKey('prismaProductCode')) {
      prismaProductCode = _json['prismaProductCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (prismaClientCode != null) 'prismaClientCode': prismaClientCode!,
        if (prismaEstimateCode != null)
          'prismaEstimateCode': prismaEstimateCode!,
        if (prismaProductCode != null) 'prismaProductCode': prismaProductCode!,
      };
}

/// Targeting details for proximity location list.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_PROXIMITY_LOCATION_LIST`.
class ProximityLocationListAssignedTargetingOptionDetails {
  /// ID of the proximity location list.
  ///
  /// Should refer to the location_list_id field of a LocationList resource
  /// whose type is `TARGETING_LOCATION_TYPE_PROXIMITY`.
  ///
  /// Required.
  core.String? proximityLocationListId;

  /// Radius range for proximity location list.
  ///
  /// This represents the size of the area around a chosen location that will be
  /// targeted. `All` proximity location targeting under a single resource must
  /// have the same radius range value. Set this value to match any existing
  /// targeting. If updated, this field will change the radius range for all
  /// proximity targeting under the resource.
  ///
  /// Required.
  /// Possible string values are:
  /// - "PROXIMITY_RADIUS_RANGE_UNSPECIFIED" : The targeted radius range is not
  /// specified or is unknown. Default value when radius range is not specified
  /// in this version. This enum is a placeholder for default value and does not
  /// represent a real radius range option.
  /// - "PROXIMITY_RADIUS_RANGE_SMALL" : The targeted radius range is small.
  /// - "PROXIMITY_RADIUS_RANGE_MEDIUM" : The targeted radius range is medium.
  /// - "PROXIMITY_RADIUS_RANGE_LARGE" : The targeted radius range is large.
  core.String? proximityRadiusRange;

  ProximityLocationListAssignedTargetingOptionDetails();

  ProximityLocationListAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('proximityLocationListId')) {
      proximityLocationListId = _json['proximityLocationListId'] as core.String;
    }
    if (_json.containsKey('proximityRadiusRange')) {
      proximityRadiusRange = _json['proximityRadiusRange'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (proximityLocationListId != null)
          'proximityLocationListId': proximityLocationListId!,
        if (proximityRadiusRange != null)
          'proximityRadiusRange': proximityRadiusRange!,
      };
}

/// Publisher review status for the creative.
class PublisherReviewStatus {
  /// The publisher reviewing the creative.
  core.String? publisherName;

  /// Status of the publisher review.
  /// Possible string values are:
  /// - "REVIEW_STATUS_UNSPECIFIED" : Type value is not specified or is unknown
  /// in this version.
  /// - "REVIEW_STATUS_APPROVED" : The creative is approved.
  /// - "REVIEW_STATUS_REJECTED" : The creative is rejected.
  /// - "REVIEW_STATUS_PENDING" : The creative is pending review.
  core.String? status;

  PublisherReviewStatus();

  PublisherReviewStatus.fromJson(core.Map _json) {
    if (_json.containsKey('publisherName')) {
      publisherName = _json['publisherName'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (publisherName != null) 'publisherName': publisherName!,
        if (status != null) 'status': status!,
      };
}

/// The rate related settings of the inventory source.
class RateDetails {
  /// The rate type.
  ///
  /// Acceptable values are `INVENTORY_SOURCE_RATE_TYPE_CPM_FIXED`,
  /// `INVENTORY_SOURCE_RATE_TYPE_CPM_FLOOR`, and
  /// `INVENTORY_SOURCE_RATE_TYPE_CPD`.
  /// Possible string values are:
  /// - "INVENTORY_SOURCE_RATE_TYPE_UNSPECIFIED" : The rate type is not
  /// specified or is unknown in this version.
  /// - "INVENTORY_SOURCE_RATE_TYPE_CPM_FIXED" : The rate type is CPM (Fixed).
  /// - "INVENTORY_SOURCE_RATE_TYPE_CPM_FLOOR" : The rate type is CPM (Floor).
  /// - "INVENTORY_SOURCE_RATE_TYPE_CPD" : The rate type is Cost per Day.
  /// - "INVENTORY_SOURCE_RATE_TYPE_FLAT" : The rate type is Flat.
  core.String? inventorySourceRateType;

  /// The amount that the buyer has committed to spending on the inventory
  /// source up front.
  ///
  /// Only applicable for guaranteed inventory sources.
  ///
  /// Output only.
  Money? minimumSpend;

  /// The rate for the inventory source.
  Money? rate;

  /// Required for guaranteed inventory sources.
  ///
  /// The number of impressions guaranteed by the seller.
  core.String? unitsPurchased;

  RateDetails();

  RateDetails.fromJson(core.Map _json) {
    if (_json.containsKey('inventorySourceRateType')) {
      inventorySourceRateType = _json['inventorySourceRateType'] as core.String;
    }
    if (_json.containsKey('minimumSpend')) {
      minimumSpend = Money.fromJson(
          _json['minimumSpend'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rate')) {
      rate =
          Money.fromJson(_json['rate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unitsPurchased')) {
      unitsPurchased = _json['unitsPurchased'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inventorySourceRateType != null)
          'inventorySourceRateType': inventorySourceRateType!,
        if (minimumSpend != null) 'minimumSpend': minimumSpend!.toJson(),
        if (rate != null) 'rate': rate!.toJson(),
        if (unitsPurchased != null) 'unitsPurchased': unitsPurchased!,
      };
}

/// Targeting details for regional location list.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_REGIONAL_LOCATION_LIST`.
class RegionalLocationListAssignedTargetingOptionDetails {
  /// Indicates if this option is being negatively targeted.
  core.bool? negative;

  /// ID of the regional location list.
  ///
  /// Should refer to the location_list_id field of a LocationList resource
  /// whose type is `TARGETING_LOCATION_TYPE_REGIONAL`.
  ///
  /// Required.
  core.String? regionalLocationListId;

  RegionalLocationListAssignedTargetingOptionDetails();

  RegionalLocationListAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
    if (_json.containsKey('regionalLocationListId')) {
      regionalLocationListId = _json['regionalLocationListId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (negative != null) 'negative': negative!,
        if (regionalLocationListId != null)
          'regionalLocationListId': regionalLocationListId!,
      };
}

/// Request message for NegativeKeywordService.ReplaceNegativeKeywords.
class ReplaceNegativeKeywordsRequest {
  /// The negative keywords that will replace the existing keywords in the
  /// negative keyword list, specified as a list of NegativeKeywords.
  core.List<NegativeKeyword>? newNegativeKeywords;

  ReplaceNegativeKeywordsRequest();

  ReplaceNegativeKeywordsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('newNegativeKeywords')) {
      newNegativeKeywords = (_json['newNegativeKeywords'] as core.List)
          .map<NegativeKeyword>((value) => NegativeKeyword.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (newNegativeKeywords != null)
          'newNegativeKeywords':
              newNegativeKeywords!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for NegativeKeywordService.ReplaceNegativeKeywords.
class ReplaceNegativeKeywordsResponse {
  /// The full list of negative keywords now present in the negative keyword
  /// list.
  core.List<NegativeKeyword>? negativeKeywords;

  ReplaceNegativeKeywordsResponse();

  ReplaceNegativeKeywordsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('negativeKeywords')) {
      negativeKeywords = (_json['negativeKeywords'] as core.List)
          .map<NegativeKeyword>((value) => NegativeKeyword.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (negativeKeywords != null)
          'negativeKeywords':
              negativeKeywords!.map((value) => value.toJson()).toList(),
      };
}

/// Request message for SiteService.ReplaceSites.
class ReplaceSitesRequest {
  /// The ID of the advertiser that owns the parent channel.
  core.String? advertiserId;

  /// The sites that will replace the existing sites assigned to the channel,
  /// specified as a list of Sites.
  core.List<Site>? newSites;

  /// The ID of the partner that owns the parent channel.
  core.String? partnerId;

  ReplaceSitesRequest();

  ReplaceSitesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('newSites')) {
      newSites = (_json['newSites'] as core.List)
          .map<Site>((value) =>
              Site.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('partnerId')) {
      partnerId = _json['partnerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (newSites != null)
          'newSites': newSites!.map((value) => value.toJson()).toList(),
        if (partnerId != null) 'partnerId': partnerId!,
      };
}

/// Response message for SiteService.ReplaceSites.
class ReplaceSitesResponse {
  /// The list of sites in the channel after replacing.
  core.List<Site>? sites;

  ReplaceSitesResponse();

  ReplaceSitesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('sites')) {
      sites = (_json['sites'] as core.List)
          .map<Site>((value) =>
              Site.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sites != null)
          'sites': sites!.map((value) => value.toJson()).toList(),
      };
}

/// Review statuses for the creative.
class ReviewStatusInfo {
  /// Represents the basic approval needed for a creative to begin serving.
  ///
  /// Summary of creative_and_landing_page_review_status and
  /// content_and_policy_review_status.
  /// Possible string values are:
  /// - "APPROVAL_STATUS_UNSPECIFIED" : Type value is not specified or is
  /// unknown in this version.
  /// - "APPROVAL_STATUS_PENDING_NOT_SERVABLE" : The creative is still under
  /// review and not servable.
  /// - "APPROVAL_STATUS_PENDING_SERVABLE" : The creative has passed creative &
  /// landing page review and is servable, but is awaiting additional content &
  /// policy review.
  /// - "APPROVAL_STATUS_APPROVED_SERVABLE" : Both creative & landing page
  /// review and content & policy review are approved. The creative is servable.
  /// - "APPROVAL_STATUS_REJECTED_NOT_SERVABLE" : There is an issue with the
  /// creative that must be fixed before it can serve.
  core.String? approvalStatus;

  /// Content and policy review status for the creative.
  /// Possible string values are:
  /// - "REVIEW_STATUS_UNSPECIFIED" : Type value is not specified or is unknown
  /// in this version.
  /// - "REVIEW_STATUS_APPROVED" : The creative is approved.
  /// - "REVIEW_STATUS_REJECTED" : The creative is rejected.
  /// - "REVIEW_STATUS_PENDING" : The creative is pending review.
  core.String? contentAndPolicyReviewStatus;

  /// Creative and landing page review status for the creative.
  /// Possible string values are:
  /// - "REVIEW_STATUS_UNSPECIFIED" : Type value is not specified or is unknown
  /// in this version.
  /// - "REVIEW_STATUS_APPROVED" : The creative is approved.
  /// - "REVIEW_STATUS_REJECTED" : The creative is rejected.
  /// - "REVIEW_STATUS_PENDING" : The creative is pending review.
  core.String? creativeAndLandingPageReviewStatus;

  /// Exchange review statuses for the creative.
  core.List<ExchangeReviewStatus>? exchangeReviewStatuses;

  /// Publisher review statuses for the creative.
  core.List<PublisherReviewStatus>? publisherReviewStatuses;

  ReviewStatusInfo();

  ReviewStatusInfo.fromJson(core.Map _json) {
    if (_json.containsKey('approvalStatus')) {
      approvalStatus = _json['approvalStatus'] as core.String;
    }
    if (_json.containsKey('contentAndPolicyReviewStatus')) {
      contentAndPolicyReviewStatus =
          _json['contentAndPolicyReviewStatus'] as core.String;
    }
    if (_json.containsKey('creativeAndLandingPageReviewStatus')) {
      creativeAndLandingPageReviewStatus =
          _json['creativeAndLandingPageReviewStatus'] as core.String;
    }
    if (_json.containsKey('exchangeReviewStatuses')) {
      exchangeReviewStatuses = (_json['exchangeReviewStatuses'] as core.List)
          .map<ExchangeReviewStatus>((value) => ExchangeReviewStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('publisherReviewStatuses')) {
      publisherReviewStatuses = (_json['publisherReviewStatuses'] as core.List)
          .map<PublisherReviewStatus>((value) => PublisherReviewStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (approvalStatus != null) 'approvalStatus': approvalStatus!,
        if (contentAndPolicyReviewStatus != null)
          'contentAndPolicyReviewStatus': contentAndPolicyReviewStatus!,
        if (creativeAndLandingPageReviewStatus != null)
          'creativeAndLandingPageReviewStatus':
              creativeAndLandingPageReviewStatus!,
        if (exchangeReviewStatuses != null)
          'exchangeReviewStatuses':
              exchangeReviewStatuses!.map((value) => value.toJson()).toList(),
        if (publisherReviewStatuses != null)
          'publisherReviewStatuses':
              publisherReviewStatuses!.map((value) => value.toJson()).toList(),
      };
}

/// Structured Data File (SDF) related settings.
class SdfConfig {
  /// An administrator email address to which the SDF processing status reports
  /// will be sent.
  core.String? adminEmail;

  /// The version of SDF being used.
  ///
  /// Required.
  /// Possible string values are:
  /// - "SDF_VERSION_UNSPECIFIED" : SDF version value is not specified or is
  /// unknown in this version.
  /// - "SDF_VERSION_3_1" : SDF version 3.1
  /// - "SDF_VERSION_4" : SDF version 4
  /// - "SDF_VERSION_4_1" : SDF version 4.1
  /// - "SDF_VERSION_4_2" : SDF version 4.2
  /// - "SDF_VERSION_5" : SDF version 5.
  /// - "SDF_VERSION_5_1" : SDF version 5.1
  /// - "SDF_VERSION_5_2" : SDF version 5.2
  /// - "SDF_VERSION_5_3" : SDF version 5.3
  core.String? version;

  SdfConfig();

  SdfConfig.fromJson(core.Map _json) {
    if (_json.containsKey('adminEmail')) {
      adminEmail = _json['adminEmail'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adminEmail != null) 'adminEmail': adminEmail!,
        if (version != null) 'version': version!,
      };
}

/// Type for the response returned by
/// \[SdfDownloadTaskService.CreateSdfDownloadTask\].
class SdfDownloadTask {
  /// A resource name to be used in media.download to Download the prepared
  /// files.
  ///
  /// Resource names have the format
  /// `download/sdfdownloadtasks/media/{media_id}`. `media_id` will be made
  /// available by the long running operation service once the task status is
  /// done.
  core.String? resourceName;

  SdfDownloadTask();

  SdfDownloadTask.fromJson(core.Map _json) {
    if (_json.containsKey('resourceName')) {
      resourceName = _json['resourceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceName != null) 'resourceName': resourceName!,
      };
}

/// Type for the metadata returned by
/// \[SdfDownloadTaskService.CreateSdfDownloadTask\].
class SdfDownloadTaskMetadata {
  /// The time when the operation was created.
  core.String? createTime;

  /// The time when execution was completed.
  core.String? endTime;

  /// The SDF version used to execute this download task.
  /// Possible string values are:
  /// - "SDF_VERSION_UNSPECIFIED" : SDF version value is not specified or is
  /// unknown in this version.
  /// - "SDF_VERSION_3_1" : SDF version 3.1
  /// - "SDF_VERSION_4" : SDF version 4
  /// - "SDF_VERSION_4_1" : SDF version 4.1
  /// - "SDF_VERSION_4_2" : SDF version 4.2
  /// - "SDF_VERSION_5" : SDF version 5.
  /// - "SDF_VERSION_5_1" : SDF version 5.1
  /// - "SDF_VERSION_5_2" : SDF version 5.2
  /// - "SDF_VERSION_5_3" : SDF version 5.3
  core.String? version;

  SdfDownloadTaskMetadata();

  SdfDownloadTaskMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (endTime != null) 'endTime': endTime!,
        if (version != null) 'version': version!,
      };
}

/// Request message for SearchTargetingOptions.
class SearchTargetingOptionsRequest {
  /// The Advertiser this request is being made in the context of.
  ///
  /// Required.
  core.String? advertiserId;

  /// Search terms for geo region targeting options.
  ///
  /// Can only be used when targeting_type is `TARGETING_TYPE_GEO_REGION`.
  GeoRegionSearchTerms? geoRegionSearchTerms;

  /// Requested page size.
  ///
  /// Must be between `1` and `100`. If unspecified will default to `100`.
  /// Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  core.int? pageSize;

  /// A token identifying a page of results the server should return.
  ///
  /// Typically, this is the value of next_page_token returned from the previous
  /// call to `SearchTargetingOptions` method. If not specified, the first page
  /// of results will be returned.
  core.String? pageToken;

  SearchTargetingOptionsRequest();

  SearchTargetingOptionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('geoRegionSearchTerms')) {
      geoRegionSearchTerms = GeoRegionSearchTerms.fromJson(
          _json['geoRegionSearchTerms'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (geoRegionSearchTerms != null)
          'geoRegionSearchTerms': geoRegionSearchTerms!.toJson(),
        if (pageSize != null) 'pageSize': pageSize!,
        if (pageToken != null) 'pageToken': pageToken!,
      };
}

/// Response message for SearchTargetingOptionsResponse.
class SearchTargetingOptionsResponse {
  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the page_token field in the subsequent call to
  /// `SearchTargetingOptions` method to retrieve the next page of results.
  core.String? nextPageToken;

  /// The list of targeting options that match the search criteria.
  ///
  /// This list will be absent if empty.
  core.List<TargetingOption>? targetingOptions;

  SearchTargetingOptionsResponse();

  SearchTargetingOptionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('targetingOptions')) {
      targetingOptions = (_json['targetingOptions'] as core.List)
          .map<TargetingOption>((value) => TargetingOption.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (targetingOptions != null)
          'targetingOptions':
              targetingOptions!.map((value) => value.toJson()).toList(),
      };
}

/// Targeting details for sensitive category.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`.
class SensitiveCategoryAssignedTargetingOptionDetails {
  /// ID of the sensitive category to be EXCLUDED.
  ///
  /// Required.
  core.String? excludedTargetingOptionId;

  /// An enum for the DV360 Sensitive category content classifier.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "SENSITIVE_CATEGORY_UNSPECIFIED" : This enum is only a placeholder and
  /// doesn't specify a DV360 sensitive category.
  /// - "SENSITIVE_CATEGORY_ADULT" : Adult or pornographic text, image, or video
  /// content.
  /// - "SENSITIVE_CATEGORY_DEROGATORY" : Content that may be construed as
  /// biased against individuals, groups, or organizations based on criteria
  /// such as race, religion, disability, sex, age, veteran status, sexual
  /// orientation, gender identity, or political affiliation. May also indicate
  /// discussion of such content, for instance, in an academic or journalistic
  /// context.
  /// - "SENSITIVE_CATEGORY_DOWNLOADS_SHARING" : Content related to audio,
  /// video, or software downloads.
  /// - "SENSITIVE_CATEGORY_WEAPONS" : Contains content related to personal
  /// weapons, including knives, guns, small firearms, and ammunition. Selecting
  /// either "weapons" or "sensitive social issues" will result in selecting
  /// both.
  /// - "SENSITIVE_CATEGORY_GAMBLING" : Contains content related to betting or
  /// wagering in a real-world or online setting.
  /// - "SENSITIVE_CATEGORY_VIOLENCE" : Content which may be considered
  /// graphically violent, gory, gruesome, or shocking, such as street fighting
  /// videos, accident photos, descriptions of torture, etc.
  /// - "SENSITIVE_CATEGORY_SUGGESTIVE" : Adult content, as well as suggestive
  /// content that's not explicitly pornographic. This category includes all
  /// pages categorized as adult.
  /// - "SENSITIVE_CATEGORY_PROFANITY" : Prominent use of words considered
  /// indecent, such as curse words and sexual slang. Pages with only very
  /// occasional usage, such as news sites that might include such words in a
  /// quotation, are not included.
  /// - "SENSITIVE_CATEGORY_ALCOHOL" : Contains content related to alcoholic
  /// beverages, alcohol brands, recipes, etc.
  /// - "SENSITIVE_CATEGORY_DRUGS" : Contains content related to the
  /// recreational use of legal or illegal drugs, as well as to drug
  /// paraphernalia or cultivation.
  /// - "SENSITIVE_CATEGORY_TOBACCO" : Contains content related to tobacco and
  /// tobacco accessories, including lighters, humidors, ashtrays, etc.
  /// - "SENSITIVE_CATEGORY_POLITICS" : Political news and media, including
  /// discussions of social, governmental, and public policy.
  /// - "SENSITIVE_CATEGORY_RELIGION" : Content related to religious thought or
  /// beliefs.
  /// - "SENSITIVE_CATEGORY_TRAGEDY" : Content related to death, disasters,
  /// accidents, war, etc.
  /// - "SENSITIVE_CATEGORY_TRANSPORTATION_ACCIDENTS" : Content related to motor
  /// vehicle, aviation or other transportation accidents.
  /// - "SENSITIVE_CATEGORY_SENSITIVE_SOCIAL_ISSUES" : Issues that evoke strong,
  /// opposing views and spark debate. These include issues that are
  /// controversial in most countries and markets (such as abortion), as well as
  /// those that are controversial in specific countries and markets (such as
  /// immigration reform in the United States).
  /// - "SENSITIVE_CATEGORY_SHOCKING" : Content which may be considered shocking
  /// or disturbing, such as violent news stories, stunts, or toilet humor.
  core.String? sensitiveCategory;

  SensitiveCategoryAssignedTargetingOptionDetails();

  SensitiveCategoryAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('excludedTargetingOptionId')) {
      excludedTargetingOptionId =
          _json['excludedTargetingOptionId'] as core.String;
    }
    if (_json.containsKey('sensitiveCategory')) {
      sensitiveCategory = _json['sensitiveCategory'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (excludedTargetingOptionId != null)
          'excludedTargetingOptionId': excludedTargetingOptionId!,
        if (sensitiveCategory != null) 'sensitiveCategory': sensitiveCategory!,
      };
}

/// Represents a targetable sensitive category.
///
/// This will be populated in the sensitive_category_details field of the
/// TargetingOption when targeting_type is
/// `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`.
class SensitiveCategoryTargetingOptionDetails {
  /// An enum for the DV360 Sensitive category content classifier.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "SENSITIVE_CATEGORY_UNSPECIFIED" : This enum is only a placeholder and
  /// doesn't specify a DV360 sensitive category.
  /// - "SENSITIVE_CATEGORY_ADULT" : Adult or pornographic text, image, or video
  /// content.
  /// - "SENSITIVE_CATEGORY_DEROGATORY" : Content that may be construed as
  /// biased against individuals, groups, or organizations based on criteria
  /// such as race, religion, disability, sex, age, veteran status, sexual
  /// orientation, gender identity, or political affiliation. May also indicate
  /// discussion of such content, for instance, in an academic or journalistic
  /// context.
  /// - "SENSITIVE_CATEGORY_DOWNLOADS_SHARING" : Content related to audio,
  /// video, or software downloads.
  /// - "SENSITIVE_CATEGORY_WEAPONS" : Contains content related to personal
  /// weapons, including knives, guns, small firearms, and ammunition. Selecting
  /// either "weapons" or "sensitive social issues" will result in selecting
  /// both.
  /// - "SENSITIVE_CATEGORY_GAMBLING" : Contains content related to betting or
  /// wagering in a real-world or online setting.
  /// - "SENSITIVE_CATEGORY_VIOLENCE" : Content which may be considered
  /// graphically violent, gory, gruesome, or shocking, such as street fighting
  /// videos, accident photos, descriptions of torture, etc.
  /// - "SENSITIVE_CATEGORY_SUGGESTIVE" : Adult content, as well as suggestive
  /// content that's not explicitly pornographic. This category includes all
  /// pages categorized as adult.
  /// - "SENSITIVE_CATEGORY_PROFANITY" : Prominent use of words considered
  /// indecent, such as curse words and sexual slang. Pages with only very
  /// occasional usage, such as news sites that might include such words in a
  /// quotation, are not included.
  /// - "SENSITIVE_CATEGORY_ALCOHOL" : Contains content related to alcoholic
  /// beverages, alcohol brands, recipes, etc.
  /// - "SENSITIVE_CATEGORY_DRUGS" : Contains content related to the
  /// recreational use of legal or illegal drugs, as well as to drug
  /// paraphernalia or cultivation.
  /// - "SENSITIVE_CATEGORY_TOBACCO" : Contains content related to tobacco and
  /// tobacco accessories, including lighters, humidors, ashtrays, etc.
  /// - "SENSITIVE_CATEGORY_POLITICS" : Political news and media, including
  /// discussions of social, governmental, and public policy.
  /// - "SENSITIVE_CATEGORY_RELIGION" : Content related to religious thought or
  /// beliefs.
  /// - "SENSITIVE_CATEGORY_TRAGEDY" : Content related to death, disasters,
  /// accidents, war, etc.
  /// - "SENSITIVE_CATEGORY_TRANSPORTATION_ACCIDENTS" : Content related to motor
  /// vehicle, aviation or other transportation accidents.
  /// - "SENSITIVE_CATEGORY_SENSITIVE_SOCIAL_ISSUES" : Issues that evoke strong,
  /// opposing views and spark debate. These include issues that are
  /// controversial in most countries and markets (such as abortion), as well as
  /// those that are controversial in specific countries and markets (such as
  /// immigration reform in the United States).
  /// - "SENSITIVE_CATEGORY_SHOCKING" : Content which may be considered shocking
  /// or disturbing, such as violent news stories, stunts, or toilet humor.
  core.String? sensitiveCategory;

  SensitiveCategoryTargetingOptionDetails();

  SensitiveCategoryTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('sensitiveCategory')) {
      sensitiveCategory = _json['sensitiveCategory'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sensitiveCategory != null) 'sensitiveCategory': sensitiveCategory!,
      };
}

/// A single site.
///
/// Sites are apps or websites belonging to a channel.
class Site {
  /// The resource name of the site.
  ///
  /// Output only.
  core.String? name;

  /// The app ID or URL of the site.
  ///
  /// Must be UTF-8 encoded with a maximum length of 240 bytes.
  ///
  /// Required.
  core.String? urlOrAppId;

  Site();

  Site.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('urlOrAppId')) {
      urlOrAppId = _json['urlOrAppId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (urlOrAppId != null) 'urlOrAppId': urlOrAppId!,
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

/// Details for assigned sub-exchange targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_SUB_EXCHANGE`.
class SubExchangeAssignedTargetingOptionDetails {
  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_SUB_EXCHANGE`.
  ///
  /// Required.
  core.String? targetingOptionId;

  SubExchangeAssignedTargetingOptionDetails();

  SubExchangeAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
      };
}

/// Represents a targetable sub-exchange.
///
/// This will be populated in the sub_exchange_details field of a
/// TargetingOption when targeting_type is `TARGETING_TYPE_SUB_EXCHANGE`.
class SubExchangeTargetingOptionDetails {
  /// The display name of the sub-exchange.
  ///
  /// Output only.
  core.String? displayName;

  SubExchangeTargetingOptionDetails();

  SubExchangeTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
      };
}

/// Settings that control the targeting expansion of the line item.
///
/// Targeting expansion allows the line item to reach a larger audience based on
/// the original audience list and the targeting expansion level.
class TargetingExpansionConfig {
  /// Whether to exclude first party audiences from targeting.
  ///
  /// Similar audiences of the excluded first party lists will not be excluded.
  /// Only applicable when a first-party audience is positively targeted
  /// (directly or included in a combined audience), otherwise this selection
  /// will be ignored.
  ///
  /// Required.
  core.bool? excludeFirstPartyAudience;

  /// Magnitude of expansion for applicable targeting under this line item.
  ///
  /// Required.
  /// Possible string values are:
  /// - "TARGETING_EXPANSION_LEVEL_UNSPECIFIED" : Targeting expansion level is
  /// not specified or is unknown in this version.
  /// - "NO_EXPANSION" : Targeting expansion off.
  /// - "LEAST_EXPANSION" : Conservative targeting expansion, lowest reach.
  /// - "SOME_EXPANSION" : Moderately conservative targeting expansion, lower
  /// reach.
  /// - "BALANCED_EXPANSION" : Moderate targeting expansion, medium reach.
  /// - "MORE_EXPANSION" : Moderately aggressive targeting expansion, higher
  /// reach.
  /// - "MOST_EXPANSION" : Aggressive targeting expansion, highest reach.
  core.String? targetingExpansionLevel;

  TargetingExpansionConfig();

  TargetingExpansionConfig.fromJson(core.Map _json) {
    if (_json.containsKey('excludeFirstPartyAudience')) {
      excludeFirstPartyAudience =
          _json['excludeFirstPartyAudience'] as core.bool;
    }
    if (_json.containsKey('targetingExpansionLevel')) {
      targetingExpansionLevel = _json['targetingExpansionLevel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (excludeFirstPartyAudience != null)
          'excludeFirstPartyAudience': excludeFirstPartyAudience!,
        if (targetingExpansionLevel != null)
          'targetingExpansionLevel': targetingExpansionLevel!,
      };
}

/// Represents a single targeting option, which is a targetable concept in
/// DV360.
class TargetingOption {
  /// Age range details.
  AgeRangeTargetingOptionDetails? ageRangeDetails;

  /// App category details.
  AppCategoryTargetingOptionDetails? appCategoryDetails;

  /// Authorized seller status resource details.
  AuthorizedSellerStatusTargetingOptionDetails? authorizedSellerStatusDetails;

  /// Browser details.
  BrowserTargetingOptionDetails? browserDetails;

  /// Carrier and ISP details.
  CarrierAndIspTargetingOptionDetails? carrierAndIspDetails;

  /// Category resource details.
  CategoryTargetingOptionDetails? categoryDetails;

  /// Content instream position details.
  ContentInstreamPositionTargetingOptionDetails? contentInstreamPositionDetails;

  /// Content outstream position details.
  ContentOutstreamPositionTargetingOptionDetails?
      contentOutstreamPositionDetails;

  /// Device make and model resource details.
  DeviceMakeModelTargetingOptionDetails? deviceMakeModelDetails;

  /// Device type details.
  DeviceTypeTargetingOptionDetails? deviceTypeDetails;

  /// Digital content label details.
  DigitalContentLabelTargetingOptionDetails? digitalContentLabelDetails;

  /// Environment details.
  EnvironmentTargetingOptionDetails? environmentDetails;

  /// Exchange details.
  ExchangeTargetingOptionDetails? exchangeDetails;

  /// Gender details.
  GenderTargetingOptionDetails? genderDetails;

  /// Geographic region resource details.
  GeoRegionTargetingOptionDetails? geoRegionDetails;

  /// Household income details.
  HouseholdIncomeTargetingOptionDetails? householdIncomeDetails;

  /// Language resource details.
  LanguageTargetingOptionDetails? languageDetails;

  /// The resource name for this targeting option.
  ///
  /// Output only.
  core.String? name;

  /// Native content position details.
  NativeContentPositionTargetingOptionDetails? nativeContentPositionDetails;

  /// On screen position details.
  OnScreenPositionTargetingOptionDetails? onScreenPositionDetails;

  /// Operating system resources details.
  OperatingSystemTargetingOptionDetails? operatingSystemDetails;

  /// Parental status details.
  ParentalStatusTargetingOptionDetails? parentalStatusDetails;

  /// Sensitive Category details.
  SensitiveCategoryTargetingOptionDetails? sensitiveCategoryDetails;

  /// Sub-exchange details.
  SubExchangeTargetingOptionDetails? subExchangeDetails;

  /// A unique identifier for this targeting option.
  ///
  /// The tuple {`targeting_type`, `targeting_option_id`} will be unique.
  ///
  /// Output only.
  core.String? targetingOptionId;

  /// The type of this targeting option.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "TARGETING_TYPE_UNSPECIFIED" : Default value when type is not specified
  /// or is unknown in this version.
  /// - "TARGETING_TYPE_CHANNEL" : Target a channel (a custom group of related
  /// websites or apps).
  /// - "TARGETING_TYPE_APP_CATEGORY" : Target an app category (for example,
  /// education or puzzle games).
  /// - "TARGETING_TYPE_APP" : Target a specific app (for example, Angry Birds).
  /// - "TARGETING_TYPE_URL" : Target a specific url (for example, quora.com).
  /// - "TARGETING_TYPE_DAY_AND_TIME" : Target ads during a chosen time period
  /// on a specific day.
  /// - "TARGETING_TYPE_AGE_RANGE" : Target ads to a specific age range (for
  /// example, 18-24).
  /// - "TARGETING_TYPE_REGIONAL_LOCATION_LIST" : Target ads to the specified
  /// regions on a regional location list.
  /// - "TARGETING_TYPE_PROXIMITY_LOCATION_LIST" : Target ads to the specified
  /// points of interest on a proximity location list.
  /// - "TARGETING_TYPE_GENDER" : Target ads to a specific gender (for example,
  /// female or male).
  /// - "TARGETING_TYPE_VIDEO_PLAYER_SIZE" : Target a specific video player size
  /// for video ads.
  /// - "TARGETING_TYPE_USER_REWARDED_CONTENT" : Target user rewarded content
  /// for video ads.
  /// - "TARGETING_TYPE_PARENTAL_STATUS" : Target ads to a specific parental
  /// status (for example, parent or not a parent).
  /// - "TARGETING_TYPE_CONTENT_INSTREAM_POSITION" : Target video or audio ads
  /// in a specific content instream position (for example, pre-roll, mid-roll,
  /// or post-roll).
  /// - "TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION" : Target ads in a specific
  /// content outstream position.
  /// - "TARGETING_TYPE_DEVICE_TYPE" : Target ads to a specific device type (for
  /// example, tablet or connected TV).
  /// - "TARGETING_TYPE_AUDIENCE_GROUP" : Target ads to an audience or groups of
  /// audiences. Singleton field, at most one can exist on a single Lineitem at
  /// a time.
  /// - "TARGETING_TYPE_BROWSER" : Target ads to specific web browsers (for
  /// example, Chrome).
  /// - "TARGETING_TYPE_HOUSEHOLD_INCOME" : Target ads to a specific household
  /// income range (for example, top 10%).
  /// - "TARGETING_TYPE_ON_SCREEN_POSITION" : Target ads in a specific on screen
  /// position.
  /// - "TARGETING_TYPE_THIRD_PARTY_VERIFIER" : Filter web sites through third
  /// party verification (for example, IAS or DoubleVerify).
  /// - "TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION" : Filter web sites by
  /// specific digital content label ratings (for example, DL-MA: suitable only
  /// for mature audiences).
  /// - "TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION" : Filter website content
  /// by sensitive categories (for example, adult).
  /// - "TARGETING_TYPE_ENVIRONMENT" : Target ads to a specific environment (for
  /// example, web or app).
  /// - "TARGETING_TYPE_CARRIER_AND_ISP" : Target ads to a specific network
  /// carrier or internet service provider (ISP) (for example, Comcast or
  /// Orange).
  /// - "TARGETING_TYPE_OPERATING_SYSTEM" : Target ads to a specific operating
  /// system (for example, macOS).
  /// - "TARGETING_TYPE_DEVICE_MAKE_MODEL" : Target ads to a specific device
  /// make or model (for example, Roku or Samsung).
  /// - "TARGETING_TYPE_KEYWORD" : Target ads to a specific keyword (for
  /// example, dog or retriever).
  /// - "TARGETING_TYPE_NEGATIVE_KEYWORD_LIST" : Target ads to a specific
  /// negative keyword list.
  /// - "TARGETING_TYPE_VIEWABILITY" : Target ads to a specific viewability (for
  /// example, 80% viewable).
  /// - "TARGETING_TYPE_CATEGORY" : Target ads to a specific content category
  /// (for example, arts & entertainment).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE" : Purchase impressions from specific
  /// deals and auction packages.
  /// - "TARGETING_TYPE_LANGUAGE" : Target ads to a specific language (for
  /// example, English or Japanese).
  /// - "TARGETING_TYPE_AUTHORIZED_SELLER_STATUS" : Target ads to ads.txt
  /// authorized sellers.
  /// - "TARGETING_TYPE_GEO_REGION" : Target ads to a specific regional location
  /// (for example, a city or state).
  /// - "TARGETING_TYPE_INVENTORY_SOURCE_GROUP" : Purchase impressions from a
  /// group of deals and auction packages.
  /// - "TARGETING_TYPE_EXCHANGE" : Purchase impressions from specific
  /// exchanges.
  /// - "TARGETING_TYPE_SUB_EXCHANGE" : Purchase impressions from specific
  /// sub-exchanges.
  /// - "TARGETING_TYPE_NATIVE_CONTENT_POSITION" : Target ads to a specific
  /// native content position.
  core.String? targetingType;

  /// User rewarded content details.
  UserRewardedContentTargetingOptionDetails? userRewardedContentDetails;

  /// Video player size details.
  VideoPlayerSizeTargetingOptionDetails? videoPlayerSizeDetails;

  /// Viewability resource details.
  ViewabilityTargetingOptionDetails? viewabilityDetails;

  TargetingOption();

  TargetingOption.fromJson(core.Map _json) {
    if (_json.containsKey('ageRangeDetails')) {
      ageRangeDetails = AgeRangeTargetingOptionDetails.fromJson(
          _json['ageRangeDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('appCategoryDetails')) {
      appCategoryDetails = AppCategoryTargetingOptionDetails.fromJson(
          _json['appCategoryDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('authorizedSellerStatusDetails')) {
      authorizedSellerStatusDetails =
          AuthorizedSellerStatusTargetingOptionDetails.fromJson(
              _json['authorizedSellerStatusDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('browserDetails')) {
      browserDetails = BrowserTargetingOptionDetails.fromJson(
          _json['browserDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('carrierAndIspDetails')) {
      carrierAndIspDetails = CarrierAndIspTargetingOptionDetails.fromJson(
          _json['carrierAndIspDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('categoryDetails')) {
      categoryDetails = CategoryTargetingOptionDetails.fromJson(
          _json['categoryDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentInstreamPositionDetails')) {
      contentInstreamPositionDetails =
          ContentInstreamPositionTargetingOptionDetails.fromJson(
              _json['contentInstreamPositionDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentOutstreamPositionDetails')) {
      contentOutstreamPositionDetails =
          ContentOutstreamPositionTargetingOptionDetails.fromJson(
              _json['contentOutstreamPositionDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deviceMakeModelDetails')) {
      deviceMakeModelDetails = DeviceMakeModelTargetingOptionDetails.fromJson(
          _json['deviceMakeModelDetails']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deviceTypeDetails')) {
      deviceTypeDetails = DeviceTypeTargetingOptionDetails.fromJson(
          _json['deviceTypeDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('digitalContentLabelDetails')) {
      digitalContentLabelDetails =
          DigitalContentLabelTargetingOptionDetails.fromJson(
              _json['digitalContentLabelDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('environmentDetails')) {
      environmentDetails = EnvironmentTargetingOptionDetails.fromJson(
          _json['environmentDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('exchangeDetails')) {
      exchangeDetails = ExchangeTargetingOptionDetails.fromJson(
          _json['exchangeDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('genderDetails')) {
      genderDetails = GenderTargetingOptionDetails.fromJson(
          _json['genderDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('geoRegionDetails')) {
      geoRegionDetails = GeoRegionTargetingOptionDetails.fromJson(
          _json['geoRegionDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('householdIncomeDetails')) {
      householdIncomeDetails = HouseholdIncomeTargetingOptionDetails.fromJson(
          _json['householdIncomeDetails']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('languageDetails')) {
      languageDetails = LanguageTargetingOptionDetails.fromJson(
          _json['languageDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nativeContentPositionDetails')) {
      nativeContentPositionDetails =
          NativeContentPositionTargetingOptionDetails.fromJson(
              _json['nativeContentPositionDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('onScreenPositionDetails')) {
      onScreenPositionDetails = OnScreenPositionTargetingOptionDetails.fromJson(
          _json['onScreenPositionDetails']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('operatingSystemDetails')) {
      operatingSystemDetails = OperatingSystemTargetingOptionDetails.fromJson(
          _json['operatingSystemDetails']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('parentalStatusDetails')) {
      parentalStatusDetails = ParentalStatusTargetingOptionDetails.fromJson(
          _json['parentalStatusDetails']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sensitiveCategoryDetails')) {
      sensitiveCategoryDetails =
          SensitiveCategoryTargetingOptionDetails.fromJson(
              _json['sensitiveCategoryDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subExchangeDetails')) {
      subExchangeDetails = SubExchangeTargetingOptionDetails.fromJson(
          _json['subExchangeDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
    if (_json.containsKey('targetingType')) {
      targetingType = _json['targetingType'] as core.String;
    }
    if (_json.containsKey('userRewardedContentDetails')) {
      userRewardedContentDetails =
          UserRewardedContentTargetingOptionDetails.fromJson(
              _json['userRewardedContentDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('videoPlayerSizeDetails')) {
      videoPlayerSizeDetails = VideoPlayerSizeTargetingOptionDetails.fromJson(
          _json['videoPlayerSizeDetails']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('viewabilityDetails')) {
      viewabilityDetails = ViewabilityTargetingOptionDetails.fromJson(
          _json['viewabilityDetails'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ageRangeDetails != null)
          'ageRangeDetails': ageRangeDetails!.toJson(),
        if (appCategoryDetails != null)
          'appCategoryDetails': appCategoryDetails!.toJson(),
        if (authorizedSellerStatusDetails != null)
          'authorizedSellerStatusDetails':
              authorizedSellerStatusDetails!.toJson(),
        if (browserDetails != null) 'browserDetails': browserDetails!.toJson(),
        if (carrierAndIspDetails != null)
          'carrierAndIspDetails': carrierAndIspDetails!.toJson(),
        if (categoryDetails != null)
          'categoryDetails': categoryDetails!.toJson(),
        if (contentInstreamPositionDetails != null)
          'contentInstreamPositionDetails':
              contentInstreamPositionDetails!.toJson(),
        if (contentOutstreamPositionDetails != null)
          'contentOutstreamPositionDetails':
              contentOutstreamPositionDetails!.toJson(),
        if (deviceMakeModelDetails != null)
          'deviceMakeModelDetails': deviceMakeModelDetails!.toJson(),
        if (deviceTypeDetails != null)
          'deviceTypeDetails': deviceTypeDetails!.toJson(),
        if (digitalContentLabelDetails != null)
          'digitalContentLabelDetails': digitalContentLabelDetails!.toJson(),
        if (environmentDetails != null)
          'environmentDetails': environmentDetails!.toJson(),
        if (exchangeDetails != null)
          'exchangeDetails': exchangeDetails!.toJson(),
        if (genderDetails != null) 'genderDetails': genderDetails!.toJson(),
        if (geoRegionDetails != null)
          'geoRegionDetails': geoRegionDetails!.toJson(),
        if (householdIncomeDetails != null)
          'householdIncomeDetails': householdIncomeDetails!.toJson(),
        if (languageDetails != null)
          'languageDetails': languageDetails!.toJson(),
        if (name != null) 'name': name!,
        if (nativeContentPositionDetails != null)
          'nativeContentPositionDetails':
              nativeContentPositionDetails!.toJson(),
        if (onScreenPositionDetails != null)
          'onScreenPositionDetails': onScreenPositionDetails!.toJson(),
        if (operatingSystemDetails != null)
          'operatingSystemDetails': operatingSystemDetails!.toJson(),
        if (parentalStatusDetails != null)
          'parentalStatusDetails': parentalStatusDetails!.toJson(),
        if (sensitiveCategoryDetails != null)
          'sensitiveCategoryDetails': sensitiveCategoryDetails!.toJson(),
        if (subExchangeDetails != null)
          'subExchangeDetails': subExchangeDetails!.toJson(),
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
        if (targetingType != null) 'targetingType': targetingType!,
        if (userRewardedContentDetails != null)
          'userRewardedContentDetails': userRewardedContentDetails!.toJson(),
        if (videoPlayerSizeDetails != null)
          'videoPlayerSizeDetails': videoPlayerSizeDetails!.toJson(),
        if (viewabilityDetails != null)
          'viewabilityDetails': viewabilityDetails!.toJson(),
      };
}

/// Settings for advertisers that use third-party ad servers only.
class ThirdPartyOnlyConfig {
  /// Whether or not order ID reporting for pixels is enabled.
  ///
  /// This value cannot be changed once set to `true`.
  core.bool? pixelOrderIdReportingEnabled;

  ThirdPartyOnlyConfig();

  ThirdPartyOnlyConfig.fromJson(core.Map _json) {
    if (_json.containsKey('pixelOrderIdReportingEnabled')) {
      pixelOrderIdReportingEnabled =
          _json['pixelOrderIdReportingEnabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pixelOrderIdReportingEnabled != null)
          'pixelOrderIdReportingEnabled': pixelOrderIdReportingEnabled!,
      };
}

/// Tracking URLs from third parties to track interactions with an audio or a
/// video creative.
class ThirdPartyUrl {
  /// The type of interaction needs to be tracked by the tracking URL
  /// Possible string values are:
  /// - "THIRD_PARTY_URL_TYPE_UNSPECIFIED" : The type of third-party URL is
  /// unspecified or is unknown in this version.
  /// - "THIRD_PARTY_URL_TYPE_IMPRESSION" : Used to count impressions of the
  /// creative after the audio or video buffering is complete.
  /// - "THIRD_PARTY_URL_TYPE_CLICK_TRACKING" : Used to track user clicks on the
  /// audio or video.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_START" : Used to track the number of
  /// times a user starts the audio or video.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_FIRST_QUARTILE" : Used to track the
  /// number of times the audio or video plays to 25% of its length.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_MIDPOINT" : Used to track the number
  /// of times the audio or video plays to 50% of its length.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_THIRD_QUARTILE" : Used to track the
  /// number of times the audio or video plays to 75% of its length.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_COMPLETE" : Used to track the number
  /// of times the audio or video plays to the end.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_MUTE" : Used to track the number of
  /// times a user mutes the audio or video.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_PAUSE" : Used to track the number of
  /// times a user pauses the audio or video.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_REWIND" : Used to track the number of
  /// times a user replays the audio or video.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_FULLSCREEN" : Used to track the number
  /// of times a user expands the player to full-screen size.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_STOP" : Used to track the number of
  /// times a user stops the audio or video.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_CUSTOM" : Used to track the number of
  /// times a user performs a custom click, such as clicking on a video hot
  /// spot.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_SKIP" : Used to track the number of
  /// times the audio or video was skipped.
  /// - "THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_PROGRESS" : Used to track the number
  /// of times the audio or video plays to an offset determined by the
  /// progress_offset.
  core.String? type;

  /// Tracking URL used to track the interaction.
  ///
  /// Provide a URL with optional path or query string, beginning with `https:`.
  /// For example, https://www.example.com/path
  core.String? url;

  ThirdPartyUrl();

  ThirdPartyUrl.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
        if (url != null) 'url': url!,
      };
}

/// Assigned third party verifier targeting option details.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_THIRD_PARTY_VERIFIER`.
class ThirdPartyVerifierAssignedTargetingOptionDetails {
  /// Third party brand verifier -- Adloox.
  Adloox? adloox;

  /// Third party brand verifier -- DoubleVerify.
  DoubleVerify? doubleVerify;

  /// Third party brand verifier -- Integral Ad Science.
  IntegralAdScience? integralAdScience;

  ThirdPartyVerifierAssignedTargetingOptionDetails();

  ThirdPartyVerifierAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('adloox')) {
      adloox = Adloox.fromJson(
          _json['adloox'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('doubleVerify')) {
      doubleVerify = DoubleVerify.fromJson(
          _json['doubleVerify'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('integralAdScience')) {
      integralAdScience = IntegralAdScience.fromJson(
          _json['integralAdScience'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adloox != null) 'adloox': adloox!.toJson(),
        if (doubleVerify != null) 'doubleVerify': doubleVerify!.toJson(),
        if (integralAdScience != null)
          'integralAdScience': integralAdScience!.toJson(),
      };
}

/// A time range.
class TimeRange {
  /// The upper bound of a time range, inclusive.
  ///
  /// Required.
  core.String? endTime;

  /// The lower bound of a time range, inclusive.
  ///
  /// Required.
  core.String? startTime;

  TimeRange();

  TimeRange.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (startTime != null) 'startTime': startTime!,
      };
}

/// Timer event of the creative.
class TimerEvent {
  /// The name of the timer event.
  ///
  /// Required.
  core.String? name;

  /// The name used to identify this timer event in reports.
  ///
  /// Required.
  core.String? reportingName;

  TimerEvent();

  TimerEvent.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('reportingName')) {
      reportingName = _json['reportingName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (reportingName != null) 'reportingName': reportingName!,
      };
}

/// Settings that control the behavior of a single Floodlight activity config.
class TrackingFloodlightActivityConfig {
  /// The ID of the Floodlight activity.
  ///
  /// Required.
  core.String? floodlightActivityId;

  /// The number of days after an ad has been clicked in which a conversion may
  /// be counted.
  ///
  /// Must be between 0 and 90 inclusive.
  ///
  /// Required.
  core.int? postClickLookbackWindowDays;

  /// The number of days after an ad has been viewed in which a conversion may
  /// be counted.
  ///
  /// Must be between 0 and 90 inclusive.
  ///
  /// Required.
  core.int? postViewLookbackWindowDays;

  TrackingFloodlightActivityConfig();

  TrackingFloodlightActivityConfig.fromJson(core.Map _json) {
    if (_json.containsKey('floodlightActivityId')) {
      floodlightActivityId = _json['floodlightActivityId'] as core.String;
    }
    if (_json.containsKey('postClickLookbackWindowDays')) {
      postClickLookbackWindowDays =
          _json['postClickLookbackWindowDays'] as core.int;
    }
    if (_json.containsKey('postViewLookbackWindowDays')) {
      postViewLookbackWindowDays =
          _json['postViewLookbackWindowDays'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (floodlightActivityId != null)
          'floodlightActivityId': floodlightActivityId!,
        if (postClickLookbackWindowDays != null)
          'postClickLookbackWindowDays': postClickLookbackWindowDays!,
        if (postViewLookbackWindowDays != null)
          'postViewLookbackWindowDays': postViewLookbackWindowDays!,
      };
}

/// Represents information about the transcoded audio or video file.
class Transcode {
  /// The bit rate for the audio stream of the transcoded video, or the bit rate
  /// for the transcoded audio, in kilobits per second.
  core.String? audioBitRateKbps;

  /// The sample rate for the audio stream of the transcoded video, or the
  /// sample rate for the transcoded audio, in hertz.
  core.String? audioSampleRateHz;

  /// The transcoding bit rate of the transcoded video, in kilobits per second.
  core.String? bitRateKbps;

  /// The dimensions of the transcoded video.
  Dimensions? dimensions;

  /// The size of the transcoded file, in bytes.
  core.String? fileSizeBytes;

  /// The frame rate of the transcoded video, in frames per second.
  core.double? frameRate;

  /// The MIME type of the transcoded file.
  core.String? mimeType;

  /// The name of the transcoded file.
  core.String? name;

  /// Indicates if the transcoding was successful.
  core.bool? transcoded;

  Transcode();

  Transcode.fromJson(core.Map _json) {
    if (_json.containsKey('audioBitRateKbps')) {
      audioBitRateKbps = _json['audioBitRateKbps'] as core.String;
    }
    if (_json.containsKey('audioSampleRateHz')) {
      audioSampleRateHz = _json['audioSampleRateHz'] as core.String;
    }
    if (_json.containsKey('bitRateKbps')) {
      bitRateKbps = _json['bitRateKbps'] as core.String;
    }
    if (_json.containsKey('dimensions')) {
      dimensions = Dimensions.fromJson(
          _json['dimensions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fileSizeBytes')) {
      fileSizeBytes = _json['fileSizeBytes'] as core.String;
    }
    if (_json.containsKey('frameRate')) {
      frameRate = (_json['frameRate'] as core.num).toDouble();
    }
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('transcoded')) {
      transcoded = _json['transcoded'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audioBitRateKbps != null) 'audioBitRateKbps': audioBitRateKbps!,
        if (audioSampleRateHz != null) 'audioSampleRateHz': audioSampleRateHz!,
        if (bitRateKbps != null) 'bitRateKbps': bitRateKbps!,
        if (dimensions != null) 'dimensions': dimensions!.toJson(),
        if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes!,
        if (frameRate != null) 'frameRate': frameRate!,
        if (mimeType != null) 'mimeType': mimeType!,
        if (name != null) 'name': name!,
        if (transcoded != null) 'transcoded': transcoded!,
      };
}

/// A creative identifier provided by a registry that is unique across all
/// platforms.
///
/// This is part of the VAST 4.0 standard.
class UniversalAdId {
  /// The unique creative identifier.
  core.String? id;

  /// The registry provides unique creative identifiers.
  /// Possible string values are:
  /// - "UNIVERSAL_AD_REGISTRY_UNSPECIFIED" : The Universal Ad registry is
  /// unspecified or is unknown in this version.
  /// - "UNIVERSAL_AD_REGISTRY_OTHER" : Use a custom provider to provide the
  /// Universal Ad ID.
  /// - "UNIVERSAL_AD_REGISTRY_AD_ID" : Use Ad-ID to provide the Universal Ad
  /// ID.
  /// - "UNIVERSAL_AD_REGISTRY_CLEARCAST" : Use clearcast.co.uk to provide the
  /// Universal Ad ID.
  /// - "UNIVERSAL_AD_REGISTRY_DV360" : Use Display & Video 360 to provide the
  /// Universal Ad ID.
  /// - "UNIVERSAL_AD_REGISTRY_CM" : Use Campaign Manager 360 to provide the
  /// Universal Ad ID.
  core.String? registry;

  UniversalAdId();

  UniversalAdId.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('registry')) {
      registry = _json['registry'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (registry != null) 'registry': registry!,
      };
}

/// Details for assigned URL targeting option.
///
/// This will be populated in the details field of an AssignedTargetingOption
/// when targeting_type is `TARGETING_TYPE_URL`.
class UrlAssignedTargetingOptionDetails {
  /// Indicates if this option is being negatively targeted.
  core.bool? negative;

  /// The URL, for example `example.com`.
  ///
  /// DV360 supports two levels of subdirectory targeting, for example
  /// `www.example.com/one-subdirectory-level/second-level`, and five levels of
  /// subdomain targeting, for example `five.four.three.two.one.example.com`.
  ///
  /// Required.
  core.String? url;

  UrlAssignedTargetingOptionDetails();

  UrlAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('negative')) {
      negative = _json['negative'] as core.bool;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (negative != null) 'negative': negative!,
        if (url != null) 'url': url!,
      };
}

/// A single user in Display & Video 360.
class User {
  /// The assigned user roles.
  ///
  /// Required in CreateUser. Output only in UpdateUser. Can only be updated
  /// through BulkEditAssignedUserRoles.
  core.List<AssignedUserRole>? assignedUserRoles;

  /// The display name of the user.
  ///
  /// Must be UTF-8 encoded with a maximum size of 240 bytes.
  ///
  /// Required.
  core.String? displayName;

  /// The email address used to identify the user.
  ///
  /// Required. Immutable.
  core.String? email;

  /// The resource name of the user.
  ///
  /// Output only.
  core.String? name;

  /// The unique ID of the user.
  ///
  /// Assigned by the system.
  ///
  /// Output only.
  core.String? userId;

  User();

  User.fromJson(core.Map _json) {
    if (_json.containsKey('assignedUserRoles')) {
      assignedUserRoles = (_json['assignedUserRoles'] as core.List)
          .map<AssignedUserRole>((value) => AssignedUserRole.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('userId')) {
      userId = _json['userId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedUserRoles != null)
          'assignedUserRoles':
              assignedUserRoles!.map((value) => value.toJson()).toList(),
        if (displayName != null) 'displayName': displayName!,
        if (email != null) 'email': email!,
        if (name != null) 'name': name!,
        if (userId != null) 'userId': userId!,
      };
}

/// User rewarded content targeting option details.
///
/// This will be populated in the user_rewarded_content_details field when
/// targeting_type is `TARGETING_TYPE_USER_REWARDED_CONTENT`.
class UserRewardedContentAssignedTargetingOptionDetails {
  /// The targeting_option_id field when targeting_type is
  /// `TARGETING_TYPE_USER_REWARDED_CONTENT`.
  ///
  /// Required.
  core.String? targetingOptionId;

  /// User rewarded content status for video ads.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "USER_REWARDED_CONTENT_UNSPECIFIED" : User rewarded content is not
  /// specified or is unknown in this version.
  /// - "USER_REWARDED_CONTENT_USER_REWARDED" : Represents ads where the user
  /// will see a reward after viewing.
  /// - "USER_REWARDED_CONTENT_NOT_USER_REWARDED" : Represents all other ads
  /// besides user-rewarded.
  core.String? userRewardedContent;

  UserRewardedContentAssignedTargetingOptionDetails();

  UserRewardedContentAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
    if (_json.containsKey('userRewardedContent')) {
      userRewardedContent = _json['userRewardedContent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
        if (userRewardedContent != null)
          'userRewardedContent': userRewardedContent!,
      };
}

/// Represents a targetable user rewarded content status for video ads only.
///
/// This will be populated in the user_rewarded_content_details field when
/// targeting_type is `TARGETING_TYPE_USER_REWARDED_CONTENT`.
class UserRewardedContentTargetingOptionDetails {
  /// User rewarded content status for video ads.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "USER_REWARDED_CONTENT_UNSPECIFIED" : User rewarded content is not
  /// specified or is unknown in this version.
  /// - "USER_REWARDED_CONTENT_USER_REWARDED" : Represents ads where the user
  /// will see a reward after viewing.
  /// - "USER_REWARDED_CONTENT_NOT_USER_REWARDED" : Represents all other ads
  /// besides user-rewarded.
  core.String? userRewardedContent;

  UserRewardedContentTargetingOptionDetails();

  UserRewardedContentTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('userRewardedContent')) {
      userRewardedContent = _json['userRewardedContent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (userRewardedContent != null)
          'userRewardedContent': userRewardedContent!,
      };
}

/// Video player size targeting option details.
///
/// This will be populated in the video_player_size_details field when
/// targeting_type is `TARGETING_TYPE_VIDEO_PLAYER_SIZE`. Explicitly targeting
/// all options is not supported. Remove all video player size targeting options
/// to achieve this effect.
class VideoPlayerSizeAssignedTargetingOptionDetails {
  /// The targeting_option_id field when targeting_type is
  /// `TARGETING_TYPE_VIDEO_PLAYER_SIZE`.
  ///
  /// Required.
  core.String? targetingOptionId;

  /// The video player size.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "VIDEO_PLAYER_SIZE_UNSPECIFIED" : Video player size is not specified in
  /// this version. This enum is a place holder for a default value and does not
  /// represent a real video player size.
  /// - "VIDEO_PLAYER_SIZE_SMALL" : The dimensions of the video player are less
  /// than 400×300 (desktop), or up to 20% of screen covered (mobile).
  /// - "VIDEO_PLAYER_SIZE_LARGE" : The dimensions of the video player are
  /// between 400x300 and 1280x720 pixels (desktop), or 20% to 90% of the screen
  /// covered (mobile).
  /// - "VIDEO_PLAYER_SIZE_HD" : The dimensions of the video player are 1280×720
  /// or greater (desktop), or over 90% of the screen covered (mobile).
  /// - "VIDEO_PLAYER_SIZE_UNKNOWN" : The dimensions of the video player are
  /// unknown.
  core.String? videoPlayerSize;

  VideoPlayerSizeAssignedTargetingOptionDetails();

  VideoPlayerSizeAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
    if (_json.containsKey('videoPlayerSize')) {
      videoPlayerSize = _json['videoPlayerSize'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
        if (videoPlayerSize != null) 'videoPlayerSize': videoPlayerSize!,
      };
}

/// Represents a targetable video player size.
///
/// This will be populated in the video_player_size_details field when
/// targeting_type is `TARGETING_TYPE_VIDEO_PLAYER_SIZE`.
class VideoPlayerSizeTargetingOptionDetails {
  /// The video player size.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "VIDEO_PLAYER_SIZE_UNSPECIFIED" : Video player size is not specified in
  /// this version. This enum is a place holder for a default value and does not
  /// represent a real video player size.
  /// - "VIDEO_PLAYER_SIZE_SMALL" : The dimensions of the video player are less
  /// than 400×300 (desktop), or up to 20% of screen covered (mobile).
  /// - "VIDEO_PLAYER_SIZE_LARGE" : The dimensions of the video player are
  /// between 400x300 and 1280x720 pixels (desktop), or 20% to 90% of the screen
  /// covered (mobile).
  /// - "VIDEO_PLAYER_SIZE_HD" : The dimensions of the video player are 1280×720
  /// or greater (desktop), or over 90% of the screen covered (mobile).
  /// - "VIDEO_PLAYER_SIZE_UNKNOWN" : The dimensions of the video player are
  /// unknown.
  core.String? videoPlayerSize;

  VideoPlayerSizeTargetingOptionDetails();

  VideoPlayerSizeTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('videoPlayerSize')) {
      videoPlayerSize = _json['videoPlayerSize'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (videoPlayerSize != null) 'videoPlayerSize': videoPlayerSize!,
      };
}

/// Assigned viewability targeting option details.
///
/// This will be populated in the viewability_details field of an
/// AssignedTargetingOption when targeting_type is `TARGETING_TYPE_VIEWABILITY`.
class ViewabilityAssignedTargetingOptionDetails {
  /// The targeting_option_id of a TargetingOption of type
  /// `TARGETING_TYPE_VIEWABILITY` (e.g., "509010" for targeting the
  /// `VIEWABILITY_10_PERCENT_OR_MORE` option).
  ///
  /// Required.
  core.String? targetingOptionId;

  /// The predicted viewability percentage.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "VIEWABILITY_UNSPECIFIED" : Default value when viewability is not
  /// specified in this version. This enum is a placeholder for default value
  /// and does not represent a real viewability option.
  /// - "VIEWABILITY_10_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 10% likely to be viewable.
  /// - "VIEWABILITY_20_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 20% likely to be viewable.
  /// - "VIEWABILITY_30_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 30% likely to be viewable.
  /// - "VIEWABILITY_40_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 40% likely to be viewable.
  /// - "VIEWABILITY_50_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 50% likely to be viewable.
  /// - "VIEWABILITY_60_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 60% likely to be viewable.
  /// - "VIEWABILITY_70_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 70% likely to be viewable.
  /// - "VIEWABILITY_80_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 80% likely to be viewable.
  /// - "VIEWABILITY_90_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 90% likely to be viewable.
  core.String? viewability;

  ViewabilityAssignedTargetingOptionDetails();

  ViewabilityAssignedTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('targetingOptionId')) {
      targetingOptionId = _json['targetingOptionId'] as core.String;
    }
    if (_json.containsKey('viewability')) {
      viewability = _json['viewability'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (targetingOptionId != null) 'targetingOptionId': targetingOptionId!,
        if (viewability != null) 'viewability': viewability!,
      };
}

/// Represents a targetable viewability.
///
/// This will be populated in the viewability_details field of a TargetingOption
/// when targeting_type is `TARGETING_TYPE_VIEWABILITY`.
class ViewabilityTargetingOptionDetails {
  /// The predicted viewability percentage.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "VIEWABILITY_UNSPECIFIED" : Default value when viewability is not
  /// specified in this version. This enum is a placeholder for default value
  /// and does not represent a real viewability option.
  /// - "VIEWABILITY_10_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 10% likely to be viewable.
  /// - "VIEWABILITY_20_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 20% likely to be viewable.
  /// - "VIEWABILITY_30_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 30% likely to be viewable.
  /// - "VIEWABILITY_40_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 40% likely to be viewable.
  /// - "VIEWABILITY_50_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 50% likely to be viewable.
  /// - "VIEWABILITY_60_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 60% likely to be viewable.
  /// - "VIEWABILITY_70_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 70% likely to be viewable.
  /// - "VIEWABILITY_80_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 80% likely to be viewable.
  /// - "VIEWABILITY_90_PERCENT_OR_MORE" : Bid only on impressions that are at
  /// least 90% likely to be viewable.
  core.String? viewability;

  ViewabilityTargetingOptionDetails();

  ViewabilityTargetingOptionDetails.fromJson(core.Map _json) {
    if (_json.containsKey('viewability')) {
      viewability = _json['viewability'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (viewability != null) 'viewability': viewability!,
      };
}
