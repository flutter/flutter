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

/// Campaign Manager 360 API - v3.4
///
/// Build applications to efficiently manage large or complex trafficking,
/// reporting, and attribution workflows for Campaign Manager 360.
///
/// For more information, see
/// <https://developers.google.com/doubleclick-advertisers/>
///
/// Create an instance of [DfareportingApi] to access these resources:
///
/// - [AccountActiveAdSummariesResource]
/// - [AccountPermissionGroupsResource]
/// - [AccountPermissionsResource]
/// - [AccountUserProfilesResource]
/// - [AccountsResource]
/// - [AdsResource]
/// - [AdvertiserGroupsResource]
/// - [AdvertiserLandingPagesResource]
/// - [AdvertisersResource]
/// - [BrowsersResource]
/// - [CampaignCreativeAssociationsResource]
/// - [CampaignsResource]
/// - [ChangeLogsResource]
/// - [CitiesResource]
/// - [ConnectionTypesResource]
/// - [ContentCategoriesResource]
/// - [ConversionsResource]
/// - [CountriesResource]
/// - [CreativeAssetsResource]
/// - [CreativeFieldValuesResource]
/// - [CreativeFieldsResource]
/// - [CreativeGroupsResource]
/// - [CreativesResource]
/// - [CustomEventsResource]
/// - [DimensionValuesResource]
/// - [DirectorySitesResource]
/// - [DynamicTargetingKeysResource]
/// - [EventTagsResource]
/// - [FilesResource]
/// - [FloodlightActivitiesResource]
/// - [FloodlightActivityGroupsResource]
/// - [FloodlightConfigurationsResource]
/// - [InventoryItemsResource]
/// - [LanguagesResource]
/// - [MetrosResource]
/// - [MobileAppsResource]
/// - [MobileCarriersResource]
/// - [OperatingSystemVersionsResource]
/// - [OperatingSystemsResource]
/// - [OrderDocumentsResource]
/// - [OrdersResource]
/// - [PlacementGroupsResource]
/// - [PlacementStrategiesResource]
/// - [PlacementsResource]
/// - [PlatformTypesResource]
/// - [PostalCodesResource]
/// - [ProjectsResource]
/// - [RegionsResource]
/// - [RemarketingListSharesResource]
/// - [RemarketingListsResource]
/// - [ReportsResource]
///   - [ReportsCompatibleFieldsResource]
///   - [ReportsFilesResource]
/// - [SitesResource]
/// - [SizesResource]
/// - [SubaccountsResource]
/// - [TargetableRemarketingListsResource]
/// - [TargetingTemplatesResource]
/// - [UserProfilesResource]
/// - [UserRolePermissionGroupsResource]
/// - [UserRolePermissionsResource]
/// - [UserRolesResource]
/// - [VideoFormatsResource]
library dfareporting.v3_4;

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

/// Build applications to efficiently manage large or complex trafficking,
/// reporting, and attribution workflows for Campaign Manager 360.
class DfareportingApi {
  /// Manage DoubleClick Digital Marketing conversions
  static const ddmconversionsScope =
      'https://www.googleapis.com/auth/ddmconversions';

  /// View and manage DoubleClick for Advertisers reports
  static const dfareportingScope =
      'https://www.googleapis.com/auth/dfareporting';

  /// View and manage your DoubleClick Campaign Manager's (DCM) display ad
  /// campaigns
  static const dfatraffickingScope =
      'https://www.googleapis.com/auth/dfatrafficking';

  final commons.ApiRequester _requester;

  AccountActiveAdSummariesResource get accountActiveAdSummaries =>
      AccountActiveAdSummariesResource(_requester);
  AccountPermissionGroupsResource get accountPermissionGroups =>
      AccountPermissionGroupsResource(_requester);
  AccountPermissionsResource get accountPermissions =>
      AccountPermissionsResource(_requester);
  AccountUserProfilesResource get accountUserProfiles =>
      AccountUserProfilesResource(_requester);
  AccountsResource get accounts => AccountsResource(_requester);
  AdsResource get ads => AdsResource(_requester);
  AdvertiserGroupsResource get advertiserGroups =>
      AdvertiserGroupsResource(_requester);
  AdvertiserLandingPagesResource get advertiserLandingPages =>
      AdvertiserLandingPagesResource(_requester);
  AdvertisersResource get advertisers => AdvertisersResource(_requester);
  BrowsersResource get browsers => BrowsersResource(_requester);
  CampaignCreativeAssociationsResource get campaignCreativeAssociations =>
      CampaignCreativeAssociationsResource(_requester);
  CampaignsResource get campaigns => CampaignsResource(_requester);
  ChangeLogsResource get changeLogs => ChangeLogsResource(_requester);
  CitiesResource get cities => CitiesResource(_requester);
  ConnectionTypesResource get connectionTypes =>
      ConnectionTypesResource(_requester);
  ContentCategoriesResource get contentCategories =>
      ContentCategoriesResource(_requester);
  ConversionsResource get conversions => ConversionsResource(_requester);
  CountriesResource get countries => CountriesResource(_requester);
  CreativeAssetsResource get creativeAssets =>
      CreativeAssetsResource(_requester);
  CreativeFieldValuesResource get creativeFieldValues =>
      CreativeFieldValuesResource(_requester);
  CreativeFieldsResource get creativeFields =>
      CreativeFieldsResource(_requester);
  CreativeGroupsResource get creativeGroups =>
      CreativeGroupsResource(_requester);
  CreativesResource get creatives => CreativesResource(_requester);
  CustomEventsResource get customEvents => CustomEventsResource(_requester);
  DimensionValuesResource get dimensionValues =>
      DimensionValuesResource(_requester);
  DirectorySitesResource get directorySites =>
      DirectorySitesResource(_requester);
  DynamicTargetingKeysResource get dynamicTargetingKeys =>
      DynamicTargetingKeysResource(_requester);
  EventTagsResource get eventTags => EventTagsResource(_requester);
  FilesResource get files => FilesResource(_requester);
  FloodlightActivitiesResource get floodlightActivities =>
      FloodlightActivitiesResource(_requester);
  FloodlightActivityGroupsResource get floodlightActivityGroups =>
      FloodlightActivityGroupsResource(_requester);
  FloodlightConfigurationsResource get floodlightConfigurations =>
      FloodlightConfigurationsResource(_requester);
  InventoryItemsResource get inventoryItems =>
      InventoryItemsResource(_requester);
  LanguagesResource get languages => LanguagesResource(_requester);
  MetrosResource get metros => MetrosResource(_requester);
  MobileAppsResource get mobileApps => MobileAppsResource(_requester);
  MobileCarriersResource get mobileCarriers =>
      MobileCarriersResource(_requester);
  OperatingSystemVersionsResource get operatingSystemVersions =>
      OperatingSystemVersionsResource(_requester);
  OperatingSystemsResource get operatingSystems =>
      OperatingSystemsResource(_requester);
  OrderDocumentsResource get orderDocuments =>
      OrderDocumentsResource(_requester);
  OrdersResource get orders => OrdersResource(_requester);
  PlacementGroupsResource get placementGroups =>
      PlacementGroupsResource(_requester);
  PlacementStrategiesResource get placementStrategies =>
      PlacementStrategiesResource(_requester);
  PlacementsResource get placements => PlacementsResource(_requester);
  PlatformTypesResource get platformTypes => PlatformTypesResource(_requester);
  PostalCodesResource get postalCodes => PostalCodesResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);
  RegionsResource get regions => RegionsResource(_requester);
  RemarketingListSharesResource get remarketingListShares =>
      RemarketingListSharesResource(_requester);
  RemarketingListsResource get remarketingLists =>
      RemarketingListsResource(_requester);
  ReportsResource get reports => ReportsResource(_requester);
  SitesResource get sites => SitesResource(_requester);
  SizesResource get sizes => SizesResource(_requester);
  SubaccountsResource get subaccounts => SubaccountsResource(_requester);
  TargetableRemarketingListsResource get targetableRemarketingLists =>
      TargetableRemarketingListsResource(_requester);
  TargetingTemplatesResource get targetingTemplates =>
      TargetingTemplatesResource(_requester);
  UserProfilesResource get userProfiles => UserProfilesResource(_requester);
  UserRolePermissionGroupsResource get userRolePermissionGroups =>
      UserRolePermissionGroupsResource(_requester);
  UserRolePermissionsResource get userRolePermissions =>
      UserRolePermissionsResource(_requester);
  UserRolesResource get userRoles => UserRolesResource(_requester);
  VideoFormatsResource get videoFormats => VideoFormatsResource(_requester);

  DfareportingApi(http.Client client,
      {core.String rootUrl = 'https://dfareporting.googleapis.com/',
      core.String servicePath = 'dfareporting/v3.4/'})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AccountActiveAdSummariesResource {
  final commons.ApiRequester _requester;

  AccountActiveAdSummariesResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the account's active ad summary by account ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [summaryAccountId] - Account ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountActiveAdSummary].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountActiveAdSummary> get(
    core.String profileId,
    core.String summaryAccountId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/accountActiveAdSummaries/' +
        commons.escapeVariable('$summaryAccountId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountActiveAdSummary.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountPermissionGroupsResource {
  final commons.ApiRequester _requester;

  AccountPermissionGroupsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets one account permission group by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Account permission group ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountPermissionGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountPermissionGroup> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/accountPermissionGroups/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountPermissionGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the list of account permission groups.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountPermissionGroupsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountPermissionGroupsListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/accountPermissionGroups';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountPermissionGroupsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountPermissionsResource {
  final commons.ApiRequester _requester;

  AccountPermissionsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one account permission by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Account permission ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountPermission].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountPermission> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/accountPermissions/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountPermission.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the list of account permissions.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountPermissionsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountPermissionsListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/accountPermissions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountPermissionsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountUserProfilesResource {
  final commons.ApiRequester _requester;

  AccountUserProfilesResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets one account user profile by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - User profile ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountUserProfile].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountUserProfile> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/accountUserProfiles/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountUserProfile.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new account user profile.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountUserProfile].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountUserProfile> insert(
    AccountUserProfile request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/accountUserProfiles';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountUserProfile.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of account user profiles, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [active] - Select only active user profiles.
  ///
  /// [ids] - Select only user profiles with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name, ID or email.
  /// Wildcards (*) are allowed. For example, "user profile*2015" will return
  /// objects with names like "user profile June 2015", "user profile April
  /// 2015", or simply "user profile 2015". Most of the searches also add
  /// wildcards implicitly at the start and the end of the search string. For
  /// example, a search string of "user profile" will match objects with name
  /// "my user profile", "user profile 2015", or simply "user profile".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [subaccountId] - Select only user profiles with the specified subaccount
  /// ID.
  ///
  /// [userRoleId] - Select only user profiles with the specified user role ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountUserProfilesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountUserProfilesListResponse> list(
    core.String profileId, {
    core.bool? active,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? subaccountId,
    core.String? userRoleId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (active != null) 'active': ['${active}'],
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (subaccountId != null) 'subaccountId': [subaccountId],
      if (userRoleId != null) 'userRoleId': [userRoleId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/accountUserProfiles';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountUserProfilesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing account user profile.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - AccountUserProfile ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountUserProfile].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountUserProfile> patch(
    AccountUserProfile request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/accountUserProfiles';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountUserProfile.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing account user profile.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountUserProfile].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountUserProfile> update(
    AccountUserProfile request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/accountUserProfiles';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountUserProfile.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsResource {
  final commons.ApiRequester _requester;

  AccountsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one account by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Account ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Account].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Account> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/accounts/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the list of accounts, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [active] - Select only active accounts. Don't set this field to select
  /// both active and non-active accounts.
  ///
  /// [ids] - Select only accounts with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "account*2015" will return objects with names
  /// like "account June 2015", "account April 2015", or simply "account 2015".
  /// Most of the searches also add wildcards implicitly at the start and the
  /// end of the search string. For example, a search string of "account" will
  /// match objects with name "my account", "account 2015", or simply "account".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountsListResponse> list(
    core.String profileId, {
    core.bool? active,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (active != null) 'active': ['${active}'],
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/accounts';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing account.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Account ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Account].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Account> patch(
    Account request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/accounts';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Account].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Account> update(
    Account request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/accounts';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AdsResource {
  final commons.ApiRequester _requester;

  AdsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one ad by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Ad ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Ad].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Ad> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/ads/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Ad.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new ad.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Ad].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Ad> insert(
    Ad request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/ads';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Ad.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of ads, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [active] - Select only active ads.
  ///
  /// [advertiserId] - Select only ads with this advertiser ID.
  ///
  /// [archived] - Select only archived ads.
  ///
  /// [audienceSegmentIds] - Select only ads with these audience segment IDs.
  ///
  /// [campaignIds] - Select only ads with these campaign IDs.
  ///
  /// [compatibility] - Select default ads with the specified compatibility.
  /// Applicable when type is AD_SERVING_DEFAULT_AD. DISPLAY and
  /// DISPLAY_INTERSTITIAL refer to rendering either on desktop or on mobile
  /// devices for regular or interstitial ads, respectively. APP and
  /// APP_INTERSTITIAL are for rendering in mobile apps. IN_STREAM_VIDEO refers
  /// to rendering an in-stream video ads developed with the VAST standard.
  /// Possible string values are:
  /// - "DISPLAY"
  /// - "DISPLAY_INTERSTITIAL"
  /// - "APP"
  /// - "APP_INTERSTITIAL"
  /// - "IN_STREAM_VIDEO"
  /// - "IN_STREAM_AUDIO"
  ///
  /// [creativeIds] - Select only ads with these creative IDs assigned.
  ///
  /// [creativeOptimizationConfigurationIds] - Select only ads with these
  /// creative optimization configuration IDs.
  ///
  /// [dynamicClickTracker] - Select only dynamic click trackers. Applicable
  /// when type is AD_SERVING_CLICK_TRACKER. If true, select dynamic click
  /// trackers. If false, select static click trackers. Leave unset to select
  /// both.
  ///
  /// [ids] - Select only ads with these IDs.
  ///
  /// [landingPageIds] - Select only ads with these landing page IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [overriddenEventTagId] - Select only ads with this event tag override ID.
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [placementIds] - Select only ads with these placement IDs assigned.
  ///
  /// [remarketingListIds] - Select only ads whose list targeting expression use
  /// these remarketing list IDs.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "ad*2015" will return objects with names like
  /// "ad June 2015", "ad April 2015", or simply "ad 2015". Most of the searches
  /// also add wildcards implicitly at the start and the end of the search
  /// string. For example, a search string of "ad" will match objects with name
  /// "my ad", "ad 2015", or simply "ad".
  ///
  /// [sizeIds] - Select only ads with these size IDs.
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [sslCompliant] - Select only ads that are SSL-compliant.
  ///
  /// [sslRequired] - Select only ads that require SSL.
  ///
  /// [type] - Select only ads with these types.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdsListResponse> list(
    core.String profileId, {
    core.bool? active,
    core.String? advertiserId,
    core.bool? archived,
    core.List<core.String>? audienceSegmentIds,
    core.List<core.String>? campaignIds,
    core.String? compatibility,
    core.List<core.String>? creativeIds,
    core.List<core.String>? creativeOptimizationConfigurationIds,
    core.bool? dynamicClickTracker,
    core.List<core.String>? ids,
    core.List<core.String>? landingPageIds,
    core.int? maxResults,
    core.String? overriddenEventTagId,
    core.String? pageToken,
    core.List<core.String>? placementIds,
    core.List<core.String>? remarketingListIds,
    core.String? searchString,
    core.List<core.String>? sizeIds,
    core.String? sortField,
    core.String? sortOrder,
    core.bool? sslCompliant,
    core.bool? sslRequired,
    core.List<core.String>? type,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (active != null) 'active': ['${active}'],
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (archived != null) 'archived': ['${archived}'],
      if (audienceSegmentIds != null) 'audienceSegmentIds': audienceSegmentIds,
      if (campaignIds != null) 'campaignIds': campaignIds,
      if (compatibility != null) 'compatibility': [compatibility],
      if (creativeIds != null) 'creativeIds': creativeIds,
      if (creativeOptimizationConfigurationIds != null)
        'creativeOptimizationConfigurationIds':
            creativeOptimizationConfigurationIds,
      if (dynamicClickTracker != null)
        'dynamicClickTracker': ['${dynamicClickTracker}'],
      if (ids != null) 'ids': ids,
      if (landingPageIds != null) 'landingPageIds': landingPageIds,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (overriddenEventTagId != null)
        'overriddenEventTagId': [overriddenEventTagId],
      if (pageToken != null) 'pageToken': [pageToken],
      if (placementIds != null) 'placementIds': placementIds,
      if (remarketingListIds != null) 'remarketingListIds': remarketingListIds,
      if (searchString != null) 'searchString': [searchString],
      if (sizeIds != null) 'sizeIds': sizeIds,
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (sslCompliant != null) 'sslCompliant': ['${sslCompliant}'],
      if (sslRequired != null) 'sslRequired': ['${sslRequired}'],
      if (type != null) 'type': type,
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/ads';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AdsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing ad.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Ad ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Ad].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Ad> patch(
    Ad request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/ads';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Ad.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing ad.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Ad].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Ad> update(
    Ad request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/ads';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Ad.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertiserGroupsResource {
  final commons.ApiRequester _requester;

  AdvertiserGroupsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes an existing advertiser group.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Advertiser group ID.
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/advertiserGroups/' +
        commons.escapeVariable('$id');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets one advertiser group by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Advertiser group ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdvertiserGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdvertiserGroup> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/advertiserGroups/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AdvertiserGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new advertiser group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdvertiserGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdvertiserGroup> insert(
    AdvertiserGroup request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/advertiserGroups';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AdvertiserGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of advertiser groups, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [ids] - Select only advertiser groups with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "advertiser*2015" will return objects with names
  /// like "advertiser group June 2015", "advertiser group April 2015", or
  /// simply "advertiser group 2015". Most of the searches also add wildcards
  /// implicitly at the start and the end of the search string. For example, a
  /// search string of "advertisergroup" will match objects with name "my
  /// advertisergroup", "advertisergroup 2015", or simply "advertisergroup".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdvertiserGroupsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdvertiserGroupsListResponse> list(
    core.String profileId, {
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/advertiserGroups';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AdvertiserGroupsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing advertiser group.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - AdvertiserGroup ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdvertiserGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdvertiserGroup> patch(
    AdvertiserGroup request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/advertiserGroups';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return AdvertiserGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing advertiser group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdvertiserGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdvertiserGroup> update(
    AdvertiserGroup request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/advertiserGroups';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return AdvertiserGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertiserLandingPagesResource {
  final commons.ApiRequester _requester;

  AdvertiserLandingPagesResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets one landing page by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Landing page ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LandingPage].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LandingPage> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/advertiserLandingPages/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LandingPage.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new landing page.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LandingPage].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LandingPage> insert(
    LandingPage request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/advertiserLandingPages';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LandingPage.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of landing pages.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserIds] - Select only landing pages that belong to these
  /// advertisers.
  ///
  /// [archived] - Select only archived landing pages. Don't set this field to
  /// select both archived and non-archived landing pages.
  ///
  /// [campaignIds] - Select only landing pages that are associated with these
  /// campaigns.
  ///
  /// [ids] - Select only landing pages with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for landing pages by name or ID.
  /// Wildcards (*) are allowed. For example, "landingpage*2017" will return
  /// landing pages with names like "landingpage July 2017", "landingpage March
  /// 2017", or simply "landingpage 2017". Most of the searches also add
  /// wildcards implicitly at the start and the end of the search string. For
  /// example, a search string of "landingpage" will match campaigns with name
  /// "my landingpage", "landingpage 2015", or simply "landingpage".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [subaccountId] - Select only landing pages that belong to this subaccount.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdvertiserLandingPagesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdvertiserLandingPagesListResponse> list(
    core.String profileId, {
    core.List<core.String>? advertiserIds,
    core.bool? archived,
    core.List<core.String>? campaignIds,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? subaccountId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserIds != null) 'advertiserIds': advertiserIds,
      if (archived != null) 'archived': ['${archived}'],
      if (campaignIds != null) 'campaignIds': campaignIds,
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (subaccountId != null) 'subaccountId': [subaccountId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/advertiserLandingPages';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AdvertiserLandingPagesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing advertiser landing page.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - LandingPage ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LandingPage].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LandingPage> patch(
    LandingPage request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/advertiserLandingPages';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return LandingPage.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing landing page.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LandingPage].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LandingPage> update(
    LandingPage request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/advertiserLandingPages';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return LandingPage.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AdvertisersResource {
  final commons.ApiRequester _requester;

  AdvertisersResource(commons.ApiRequester client) : _requester = client;

  /// Gets one advertiser by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Advertiser ID.
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/advertisers/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Advertiser.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new advertiser.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
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
  async.Future<Advertiser> insert(
    Advertiser request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/advertisers';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Advertiser.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of advertisers, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserGroupIds] - Select only advertisers with these advertiser group
  /// IDs.
  ///
  /// [floodlightConfigurationIds] - Select only advertisers with these
  /// floodlight configuration IDs.
  ///
  /// [ids] - Select only advertisers with these IDs.
  ///
  /// [includeAdvertisersWithoutGroupsOnly] - Select only advertisers which do
  /// not belong to any advertiser group.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [onlyParent] - Select only advertisers which use another advertiser's
  /// floodlight configuration.
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "advertiser*2015" will return objects with names
  /// like "advertiser June 2015", "advertiser April 2015", or simply
  /// "advertiser 2015". Most of the searches also add wildcards implicitly at
  /// the start and the end of the search string. For example, a search string
  /// of "advertiser" will match objects with name "my advertiser", "advertiser
  /// 2015", or simply "advertiser" .
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [status] - Select only advertisers with the specified status.
  /// Possible string values are:
  /// - "APPROVED"
  /// - "ON_HOLD"
  ///
  /// [subaccountId] - Select only advertisers with these subaccount IDs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdvertisersListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdvertisersListResponse> list(
    core.String profileId, {
    core.List<core.String>? advertiserGroupIds,
    core.List<core.String>? floodlightConfigurationIds,
    core.List<core.String>? ids,
    core.bool? includeAdvertisersWithoutGroupsOnly,
    core.int? maxResults,
    core.bool? onlyParent,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? status,
    core.String? subaccountId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserGroupIds != null) 'advertiserGroupIds': advertiserGroupIds,
      if (floodlightConfigurationIds != null)
        'floodlightConfigurationIds': floodlightConfigurationIds,
      if (ids != null) 'ids': ids,
      if (includeAdvertisersWithoutGroupsOnly != null)
        'includeAdvertisersWithoutGroupsOnly': [
          '${includeAdvertisersWithoutGroupsOnly}'
        ],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (onlyParent != null) 'onlyParent': ['${onlyParent}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (status != null) 'status': [status],
      if (subaccountId != null) 'subaccountId': [subaccountId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/advertisers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AdvertisersListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing advertiser.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Advertiser ID.
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/advertisers';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Advertiser.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing advertiser.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
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
  async.Future<Advertiser> update(
    Advertiser request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/advertisers';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Advertiser.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BrowsersResource {
  final commons.ApiRequester _requester;

  BrowsersResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a list of browsers.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BrowsersListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BrowsersListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/browsers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BrowsersListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CampaignCreativeAssociationsResource {
  final commons.ApiRequester _requester;

  CampaignCreativeAssociationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Associates a creative with the specified campaign.
  ///
  /// This method creates a default ad with dimensions matching the creative in
  /// the campaign if such a default ad does not exist already.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [campaignId] - Campaign ID in this association.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CampaignCreativeAssociation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CampaignCreativeAssociation> insert(
    CampaignCreativeAssociation request,
    core.String profileId,
    core.String campaignId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/campaigns/' +
        commons.escapeVariable('$campaignId') +
        '/campaignCreativeAssociations';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CampaignCreativeAssociation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the list of creative IDs associated with the specified campaign.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [campaignId] - Campaign ID in this association.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CampaignCreativeAssociationsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CampaignCreativeAssociationsListResponse> list(
    core.String profileId,
    core.String campaignId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/campaigns/' +
        commons.escapeVariable('$campaignId') +
        '/campaignCreativeAssociations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CampaignCreativeAssociationsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CampaignsResource {
  final commons.ApiRequester _requester;

  CampaignsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one campaign by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Campaign ID.
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/campaigns/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Campaign.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new campaign.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
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
  async.Future<Campaign> insert(
    Campaign request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/campaigns';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Campaign.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of campaigns, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserGroupIds] - Select only campaigns whose advertisers belong to
  /// these advertiser groups.
  ///
  /// [advertiserIds] - Select only campaigns that belong to these advertisers.
  ///
  /// [archived] - Select only archived campaigns. Don't set this field to
  /// select both archived and non-archived campaigns.
  ///
  /// [atLeastOneOptimizationActivity] - Select only campaigns that have at
  /// least one optimization activity.
  ///
  /// [excludedIds] - Exclude campaigns with these IDs.
  ///
  /// [ids] - Select only campaigns with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [overriddenEventTagId] - Select only campaigns that have overridden this
  /// event tag ID.
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for campaigns by name or ID. Wildcards
  /// (*) are allowed. For example, "campaign*2015" will return campaigns with
  /// names like "campaign June 2015", "campaign April 2015", or simply
  /// "campaign 2015". Most of the searches also add wildcards implicitly at the
  /// start and the end of the search string. For example, a search string of
  /// "campaign" will match campaigns with name "my campaign", "campaign 2015",
  /// or simply "campaign".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [subaccountId] - Select only campaigns that belong to this subaccount.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CampaignsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CampaignsListResponse> list(
    core.String profileId, {
    core.List<core.String>? advertiserGroupIds,
    core.List<core.String>? advertiserIds,
    core.bool? archived,
    core.bool? atLeastOneOptimizationActivity,
    core.List<core.String>? excludedIds,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? overriddenEventTagId,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? subaccountId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserGroupIds != null) 'advertiserGroupIds': advertiserGroupIds,
      if (advertiserIds != null) 'advertiserIds': advertiserIds,
      if (archived != null) 'archived': ['${archived}'],
      if (atLeastOneOptimizationActivity != null)
        'atLeastOneOptimizationActivity': ['${atLeastOneOptimizationActivity}'],
      if (excludedIds != null) 'excludedIds': excludedIds,
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (overriddenEventTagId != null)
        'overriddenEventTagId': [overriddenEventTagId],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (subaccountId != null) 'subaccountId': [subaccountId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/campaigns';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CampaignsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing campaign.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Campaign ID.
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/campaigns';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Campaign.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing campaign.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
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
  async.Future<Campaign> update(
    Campaign request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/campaigns';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Campaign.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ChangeLogsResource {
  final commons.ApiRequester _requester;

  ChangeLogsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one change log by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Change log ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ChangeLog].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ChangeLog> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/changeLogs/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ChangeLog.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of change logs.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [action] - Select only change logs with the specified action.
  /// Possible string values are:
  /// - "ACTION_CREATE"
  /// - "ACTION_UPDATE"
  /// - "ACTION_DELETE"
  /// - "ACTION_ENABLE"
  /// - "ACTION_DISABLE"
  /// - "ACTION_ADD"
  /// - "ACTION_REMOVE"
  /// - "ACTION_MARK_AS_DEFAULT"
  /// - "ACTION_ASSOCIATE"
  /// - "ACTION_ASSIGN"
  /// - "ACTION_UNASSIGN"
  /// - "ACTION_SEND"
  /// - "ACTION_LINK"
  /// - "ACTION_UNLINK"
  /// - "ACTION_PUSH"
  /// - "ACTION_EMAIL_TAGS"
  /// - "ACTION_SHARE"
  ///
  /// [ids] - Select only change logs with these IDs.
  ///
  /// [maxChangeTime] - Select only change logs whose change time is before the
  /// specified maxChangeTime.The time should be formatted as an RFC3339
  /// date/time string. For example, for 10:54 PM on July 18th, 2015, in the
  /// America/New York time zone, the format is "2015-07-18T22:54:00-04:00". In
  /// other words, the year, month, day, the letter T, the hour (24-hour clock
  /// system), minute, second, and then the time zone offset.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [minChangeTime] - Select only change logs whose change time is after the
  /// specified minChangeTime.The time should be formatted as an RFC3339
  /// date/time string. For example, for 10:54 PM on July 18th, 2015, in the
  /// America/New York time zone, the format is "2015-07-18T22:54:00-04:00". In
  /// other words, the year, month, day, the letter T, the hour (24-hour clock
  /// system), minute, second, and then the time zone offset.
  ///
  /// [objectIds] - Select only change logs with these object IDs.
  ///
  /// [objectType] - Select only change logs with the specified object type.
  /// Possible string values are:
  /// - "OBJECT_ADVERTISER"
  /// - "OBJECT_FLOODLIGHT_CONFIGURATION"
  /// - "OBJECT_AD"
  /// - "OBJECT_FLOODLIGHT_ACTVITY"
  /// - "OBJECT_CAMPAIGN"
  /// - "OBJECT_FLOODLIGHT_ACTIVITY_GROUP"
  /// - "OBJECT_CREATIVE"
  /// - "OBJECT_PLACEMENT"
  /// - "OBJECT_DFA_SITE"
  /// - "OBJECT_USER_ROLE"
  /// - "OBJECT_USER_PROFILE"
  /// - "OBJECT_ADVERTISER_GROUP"
  /// - "OBJECT_ACCOUNT"
  /// - "OBJECT_SUBACCOUNT"
  /// - "OBJECT_RICHMEDIA_CREATIVE"
  /// - "OBJECT_INSTREAM_CREATIVE"
  /// - "OBJECT_MEDIA_ORDER"
  /// - "OBJECT_CONTENT_CATEGORY"
  /// - "OBJECT_PLACEMENT_STRATEGY"
  /// - "OBJECT_SD_SITE"
  /// - "OBJECT_SIZE"
  /// - "OBJECT_CREATIVE_GROUP"
  /// - "OBJECT_CREATIVE_ASSET"
  /// - "OBJECT_USER_PROFILE_FILTER"
  /// - "OBJECT_LANDING_PAGE"
  /// - "OBJECT_CREATIVE_FIELD"
  /// - "OBJECT_REMARKETING_LIST"
  /// - "OBJECT_PROVIDED_LIST_CLIENT"
  /// - "OBJECT_EVENT_TAG"
  /// - "OBJECT_CREATIVE_BUNDLE"
  /// - "OBJECT_BILLING_ACCOUNT_GROUP"
  /// - "OBJECT_BILLING_FEATURE"
  /// - "OBJECT_RATE_CARD"
  /// - "OBJECT_ACCOUNT_BILLING_FEATURE"
  /// - "OBJECT_BILLING_MINIMUM_FEE"
  /// - "OBJECT_BILLING_PROFILE"
  /// - "OBJECT_PLAYSTORE_LINK"
  /// - "OBJECT_TARGETING_TEMPLATE"
  /// - "OBJECT_SEARCH_LIFT_STUDY"
  /// - "OBJECT_FLOODLIGHT_DV360_LINK"
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Select only change logs whose object ID, user name, old
  /// or new values match the search string.
  ///
  /// [userProfileIds] - Select only change logs with these user profile IDs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ChangeLogsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ChangeLogsListResponse> list(
    core.String profileId, {
    core.String? action,
    core.List<core.String>? ids,
    core.String? maxChangeTime,
    core.int? maxResults,
    core.String? minChangeTime,
    core.List<core.String>? objectIds,
    core.String? objectType,
    core.String? pageToken,
    core.String? searchString,
    core.List<core.String>? userProfileIds,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (action != null) 'action': [action],
      if (ids != null) 'ids': ids,
      if (maxChangeTime != null) 'maxChangeTime': [maxChangeTime],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (minChangeTime != null) 'minChangeTime': [minChangeTime],
      if (objectIds != null) 'objectIds': objectIds,
      if (objectType != null) 'objectType': [objectType],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (userProfileIds != null) 'userProfileIds': userProfileIds,
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/changeLogs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ChangeLogsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CitiesResource {
  final commons.ApiRequester _requester;

  CitiesResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a list of cities, possibly filtered.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [countryDartIds] - Select only cities from these countries.
  ///
  /// [dartIds] - Select only cities with these DART IDs.
  ///
  /// [namePrefix] - Select only cities with names starting with this prefix.
  ///
  /// [regionDartIds] - Select only cities from these regions.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CitiesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CitiesListResponse> list(
    core.String profileId, {
    core.List<core.String>? countryDartIds,
    core.List<core.String>? dartIds,
    core.String? namePrefix,
    core.List<core.String>? regionDartIds,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (countryDartIds != null) 'countryDartIds': countryDartIds,
      if (dartIds != null) 'dartIds': dartIds,
      if (namePrefix != null) 'namePrefix': [namePrefix],
      if (regionDartIds != null) 'regionDartIds': regionDartIds,
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/cities';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CitiesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ConnectionTypesResource {
  final commons.ApiRequester _requester;

  ConnectionTypesResource(commons.ApiRequester client) : _requester = client;

  /// Gets one connection type by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Connection type ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ConnectionType].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ConnectionType> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/connectionTypes/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ConnectionType.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of connection types.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ConnectionTypesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ConnectionTypesListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/connectionTypes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ConnectionTypesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ContentCategoriesResource {
  final commons.ApiRequester _requester;

  ContentCategoriesResource(commons.ApiRequester client) : _requester = client;

  /// Deletes an existing content category.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Content category ID.
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/contentCategories/' +
        commons.escapeVariable('$id');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets one content category by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Content category ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ContentCategory].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ContentCategory> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/contentCategories/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ContentCategory.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new content category.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ContentCategory].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ContentCategory> insert(
    ContentCategory request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/contentCategories';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ContentCategory.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of content categories, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [ids] - Select only content categories with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "contentcategory*2015" will return objects with
  /// names like "contentcategory June 2015", "contentcategory April 2015", or
  /// simply "contentcategory 2015". Most of the searches also add wildcards
  /// implicitly at the start and the end of the search string. For example, a
  /// search string of "contentcategory" will match objects with name "my
  /// contentcategory", "contentcategory 2015", or simply "contentcategory".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ContentCategoriesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ContentCategoriesListResponse> list(
    core.String profileId, {
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/contentCategories';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ContentCategoriesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing content category.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - ContentCategory ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ContentCategory].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ContentCategory> patch(
    ContentCategory request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/contentCategories';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return ContentCategory.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing content category.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ContentCategory].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ContentCategory> update(
    ContentCategory request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/contentCategories';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return ContentCategory.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ConversionsResource {
  final commons.ApiRequester _requester;

  ConversionsResource(commons.ApiRequester client) : _requester = client;

  /// Inserts conversions.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ConversionsBatchInsertResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ConversionsBatchInsertResponse> batchinsert(
    ConversionsBatchInsertRequest request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/conversions/batchinsert';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ConversionsBatchInsertResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates existing conversions.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ConversionsBatchUpdateResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ConversionsBatchUpdateResponse> batchupdate(
    ConversionsBatchUpdateRequest request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/conversions/batchupdate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ConversionsBatchUpdateResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CountriesResource {
  final commons.ApiRequester _requester;

  CountriesResource(commons.ApiRequester client) : _requester = client;

  /// Gets one country by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [dartId] - Country DART ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Country].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Country> get(
    core.String profileId,
    core.String dartId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/countries/' +
        commons.escapeVariable('$dartId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Country.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of countries.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CountriesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CountriesListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/countries';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CountriesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CreativeAssetsResource {
  final commons.ApiRequester _requester;

  CreativeAssetsResource(commons.ApiRequester client) : _requester = client;

  /// Inserts a new creative asset.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserId] - Advertiser ID of this creative. This is a required field.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [uploadMedia] - The media to upload.
  ///
  /// Completes with a [CreativeAssetMetadata].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeAssetMetadata> insert(
    CreativeAssetMetadata request,
    core.String profileId,
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
      _url = 'userprofiles/' +
          commons.escapeVariable('$profileId') +
          '/creativeAssets/' +
          commons.escapeVariable('$advertiserId') +
          '/creativeAssets';
    } else {
      _url = '/upload/dfareporting/v3.4/userprofiles/' +
          commons.escapeVariable('$profileId') +
          '/creativeAssets/' +
          commons.escapeVariable('$advertiserId') +
          '/creativeAssets';
    }

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      uploadMedia: uploadMedia,
      uploadOptions: commons.UploadOptions.defaultOptions,
    );
    return CreativeAssetMetadata.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CreativeFieldValuesResource {
  final commons.ApiRequester _requester;

  CreativeFieldValuesResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes an existing creative field value.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [creativeFieldId] - Creative field ID for this creative field value.
  ///
  /// [id] - Creative Field Value ID
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
    core.String profileId,
    core.String creativeFieldId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeFields/' +
        commons.escapeVariable('$creativeFieldId') +
        '/creativeFieldValues/' +
        commons.escapeVariable('$id');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets one creative field value by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [creativeFieldId] - Creative field ID for this creative field value.
  ///
  /// [id] - Creative Field Value ID
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeFieldValue].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeFieldValue> get(
    core.String profileId,
    core.String creativeFieldId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeFields/' +
        commons.escapeVariable('$creativeFieldId') +
        '/creativeFieldValues/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CreativeFieldValue.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new creative field value.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [creativeFieldId] - Creative field ID for this creative field value.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeFieldValue].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeFieldValue> insert(
    CreativeFieldValue request,
    core.String profileId,
    core.String creativeFieldId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeFields/' +
        commons.escapeVariable('$creativeFieldId') +
        '/creativeFieldValues';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CreativeFieldValue.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of creative field values, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [creativeFieldId] - Creative field ID for this creative field value.
  ///
  /// [ids] - Select only creative field values with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for creative field values by their
  /// values. Wildcards (e.g. *) are not allowed.
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "VALUE"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeFieldValuesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeFieldValuesListResponse> list(
    core.String profileId,
    core.String creativeFieldId, {
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeFields/' +
        commons.escapeVariable('$creativeFieldId') +
        '/creativeFieldValues';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CreativeFieldValuesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing creative field value.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [creativeFieldId] - CreativeField ID.
  ///
  /// [id] - CreativeFieldValue ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeFieldValue].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeFieldValue> patch(
    CreativeFieldValue request,
    core.String profileId,
    core.String creativeFieldId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeFields/' +
        commons.escapeVariable('$creativeFieldId') +
        '/creativeFieldValues';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return CreativeFieldValue.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing creative field value.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [creativeFieldId] - Creative field ID for this creative field value.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeFieldValue].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeFieldValue> update(
    CreativeFieldValue request,
    core.String profileId,
    core.String creativeFieldId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeFields/' +
        commons.escapeVariable('$creativeFieldId') +
        '/creativeFieldValues';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return CreativeFieldValue.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CreativeFieldsResource {
  final commons.ApiRequester _requester;

  CreativeFieldsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes an existing creative field.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Creative Field ID
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeFields/' +
        commons.escapeVariable('$id');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets one creative field by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Creative Field ID
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeField].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeField> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeFields/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CreativeField.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new creative field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeField].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeField> insert(
    CreativeField request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeFields';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CreativeField.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of creative fields, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserIds] - Select only creative fields that belong to these
  /// advertisers.
  ///
  /// [ids] - Select only creative fields with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for creative fields by name or ID.
  /// Wildcards (*) are allowed. For example, "creativefield*2015" will return
  /// creative fields with names like "creativefield June 2015", "creativefield
  /// April 2015", or simply "creativefield 2015". Most of the searches also add
  /// wild-cards implicitly at the start and the end of the search string. For
  /// example, a search string of "creativefield" will match creative fields
  /// with the name "my creativefield", "creativefield 2015", or simply
  /// "creativefield".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeFieldsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeFieldsListResponse> list(
    core.String profileId, {
    core.List<core.String>? advertiserIds,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserIds != null) 'advertiserIds': advertiserIds,
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeFields';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CreativeFieldsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing creative field.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - CreativeField ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeField].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeField> patch(
    CreativeField request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeFields';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return CreativeField.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing creative field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeField].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeField> update(
    CreativeField request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeFields';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return CreativeField.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CreativeGroupsResource {
  final commons.ApiRequester _requester;

  CreativeGroupsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one creative group by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Creative group ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeGroup> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeGroups/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CreativeGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new creative group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeGroup> insert(
    CreativeGroup request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeGroups';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CreativeGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of creative groups, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserIds] - Select only creative groups that belong to these
  /// advertisers.
  ///
  /// [groupNumber] - Select only creative groups that belong to this subgroup.
  /// Value must be between "1" and "2".
  ///
  /// [ids] - Select only creative groups with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for creative groups by name or ID.
  /// Wildcards (*) are allowed. For example, "creativegroup*2015" will return
  /// creative groups with names like "creativegroup June 2015", "creativegroup
  /// April 2015", or simply "creativegroup 2015". Most of the searches also add
  /// wild-cards implicitly at the start and the end of the search string. For
  /// example, a search string of "creativegroup" will match creative groups
  /// with the name "my creativegroup", "creativegroup 2015", or simply
  /// "creativegroup".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeGroupsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeGroupsListResponse> list(
    core.String profileId, {
    core.List<core.String>? advertiserIds,
    core.int? groupNumber,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserIds != null) 'advertiserIds': advertiserIds,
      if (groupNumber != null) 'groupNumber': ['${groupNumber}'],
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeGroups';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CreativeGroupsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing creative group.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - CreativeGroup ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeGroup> patch(
    CreativeGroup request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeGroups';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return CreativeGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing creative group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeGroup> update(
    CreativeGroup request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creativeGroups';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return CreativeGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CreativesResource {
  final commons.ApiRequester _requester;

  CreativesResource(commons.ApiRequester client) : _requester = client;

  /// Gets one creative by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Creative ID.
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/creatives/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Creative.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new creative.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
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
  async.Future<Creative> insert(
    Creative request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/creatives';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Creative.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of creatives, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [active] - Select only active creatives. Leave blank to select active and
  /// inactive creatives.
  ///
  /// [advertiserId] - Select only creatives with this advertiser ID.
  ///
  /// [archived] - Select only archived creatives. Leave blank to select
  /// archived and unarchived creatives.
  ///
  /// [campaignId] - Select only creatives with this campaign ID.
  ///
  /// [companionCreativeIds] - Select only in-stream video creatives with these
  /// companion IDs.
  ///
  /// [creativeFieldIds] - Select only creatives with these creative field IDs.
  ///
  /// [ids] - Select only creatives with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [renderingIds] - Select only creatives with these rendering IDs.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "creative*2015" will return objects with names
  /// like "creative June 2015", "creative April 2015", or simply "creative
  /// 2015". Most of the searches also add wildcards implicitly at the start and
  /// the end of the search string. For example, a search string of "creative"
  /// will match objects with name "my creative", "creative 2015", or simply
  /// "creative".
  ///
  /// [sizeIds] - Select only creatives with these size IDs.
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [studioCreativeId] - Select only creatives corresponding to this Studio
  /// creative ID.
  ///
  /// [types] - Select only creatives with these creative types.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativesListResponse> list(
    core.String profileId, {
    core.bool? active,
    core.String? advertiserId,
    core.bool? archived,
    core.String? campaignId,
    core.List<core.String>? companionCreativeIds,
    core.List<core.String>? creativeFieldIds,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.List<core.String>? renderingIds,
    core.String? searchString,
    core.List<core.String>? sizeIds,
    core.String? sortField,
    core.String? sortOrder,
    core.String? studioCreativeId,
    core.List<core.String>? types,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (active != null) 'active': ['${active}'],
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (archived != null) 'archived': ['${archived}'],
      if (campaignId != null) 'campaignId': [campaignId],
      if (companionCreativeIds != null)
        'companionCreativeIds': companionCreativeIds,
      if (creativeFieldIds != null) 'creativeFieldIds': creativeFieldIds,
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (renderingIds != null) 'renderingIds': renderingIds,
      if (searchString != null) 'searchString': [searchString],
      if (sizeIds != null) 'sizeIds': sizeIds,
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (studioCreativeId != null) 'studioCreativeId': [studioCreativeId],
      if (types != null) 'types': types,
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/creatives';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CreativesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing creative.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Creative ID.
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/creatives';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Creative.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing creative.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
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
  async.Future<Creative> update(
    Creative request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/creatives';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Creative.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class CustomEventsResource {
  final commons.ApiRequester _requester;

  CustomEventsResource(commons.ApiRequester client) : _requester = client;

  /// Inserts custom events.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CustomEventsBatchInsertResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CustomEventsBatchInsertResponse> batchinsert(
    CustomEventsBatchInsertRequest request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/customEvents/batchinsert';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CustomEventsBatchInsertResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class DimensionValuesResource {
  final commons.ApiRequester _requester;

  DimensionValuesResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves list of report dimension values for a list of filters.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The Campaign Manager 360 user profile ID.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "100".
  ///
  /// [pageToken] - The value of the nextToken from the previous result page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DimensionValueList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DimensionValueList> query(
    DimensionValueRequest request,
    core.String profileId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/dimensionvalues/query';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DimensionValueList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class DirectorySitesResource {
  final commons.ApiRequester _requester;

  DirectorySitesResource(commons.ApiRequester client) : _requester = client;

  /// Gets one directory site by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Directory site ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DirectorySite].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DirectorySite> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/directorySites/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DirectorySite.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new directory site.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DirectorySite].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DirectorySite> insert(
    DirectorySite request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/directorySites';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DirectorySite.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of directory sites, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [acceptsInStreamVideoPlacements] - This search filter is no longer
  /// supported and will have no effect on the results returned.
  ///
  /// [acceptsInterstitialPlacements] - This search filter is no longer
  /// supported and will have no effect on the results returned.
  ///
  /// [acceptsPublisherPaidPlacements] - Select only directory sites that accept
  /// publisher paid placements. This field can be left blank.
  ///
  /// [active] - Select only active directory sites. Leave blank to retrieve
  /// both active and inactive directory sites.
  ///
  /// [dfpNetworkCode] - Select only directory sites with this Ad Manager
  /// network code.
  ///
  /// [ids] - Select only directory sites with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name, ID or URL.
  /// Wildcards (*) are allowed. For example, "directory site*2015" will return
  /// objects with names like "directory site June 2015", "directory site April
  /// 2015", or simply "directory site 2015". Most of the searches also add
  /// wildcards implicitly at the start and the end of the search string. For
  /// example, a search string of "directory site" will match objects with name
  /// "my directory site", "directory site 2015" or simply, "directory site".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DirectorySitesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DirectorySitesListResponse> list(
    core.String profileId, {
    core.bool? acceptsInStreamVideoPlacements,
    core.bool? acceptsInterstitialPlacements,
    core.bool? acceptsPublisherPaidPlacements,
    core.bool? active,
    core.String? dfpNetworkCode,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (acceptsInStreamVideoPlacements != null)
        'acceptsInStreamVideoPlacements': ['${acceptsInStreamVideoPlacements}'],
      if (acceptsInterstitialPlacements != null)
        'acceptsInterstitialPlacements': ['${acceptsInterstitialPlacements}'],
      if (acceptsPublisherPaidPlacements != null)
        'acceptsPublisherPaidPlacements': ['${acceptsPublisherPaidPlacements}'],
      if (active != null) 'active': ['${active}'],
      if (dfpNetworkCode != null) 'dfpNetworkCode': [dfpNetworkCode],
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/directorySites';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DirectorySitesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class DynamicTargetingKeysResource {
  final commons.ApiRequester _requester;

  DynamicTargetingKeysResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes an existing dynamic targeting key.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [objectId] - ID of the object of this dynamic targeting key. This is a
  /// required field.
  ///
  /// [name] - Name of this dynamic targeting key. This is a required field.
  /// Must be less than 256 characters long and cannot contain commas. All
  /// characters are converted to lowercase.
  ///
  /// [objectType] - Type of the object of this dynamic targeting key. This is a
  /// required field.
  /// Possible string values are:
  /// - "OBJECT_ADVERTISER"
  /// - "OBJECT_AD"
  /// - "OBJECT_CREATIVE"
  /// - "OBJECT_PLACEMENT"
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
    core.String profileId,
    core.String objectId,
    core.String name,
    core.String objectType, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'name': [name],
      'objectType': [objectType],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/dynamicTargetingKeys/' +
        commons.escapeVariable('$objectId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Inserts a new dynamic targeting key.
  ///
  /// Keys must be created at the advertiser level before being assigned to the
  /// advertiser's ads, creatives, or placements. There is a maximum of 1000
  /// keys per advertiser, out of which a maximum of 20 keys can be assigned per
  /// ad, creative, or placement.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DynamicTargetingKey].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DynamicTargetingKey> insert(
    DynamicTargetingKey request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/dynamicTargetingKeys';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DynamicTargetingKey.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of dynamic targeting keys.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserId] - Select only dynamic targeting keys whose object has this
  /// advertiser ID.
  ///
  /// [names] - Select only dynamic targeting keys exactly matching these names.
  ///
  /// [objectId] - Select only dynamic targeting keys with this object ID.
  ///
  /// [objectType] - Select only dynamic targeting keys with this object type.
  /// Possible string values are:
  /// - "OBJECT_ADVERTISER"
  /// - "OBJECT_AD"
  /// - "OBJECT_CREATIVE"
  /// - "OBJECT_PLACEMENT"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DynamicTargetingKeysListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DynamicTargetingKeysListResponse> list(
    core.String profileId, {
    core.String? advertiserId,
    core.List<core.String>? names,
    core.String? objectId,
    core.String? objectType,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (names != null) 'names': names,
      if (objectId != null) 'objectId': [objectId],
      if (objectType != null) 'objectType': [objectType],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/dynamicTargetingKeys';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DynamicTargetingKeysListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class EventTagsResource {
  final commons.ApiRequester _requester;

  EventTagsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes an existing event tag.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Event tag ID.
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/eventTags/' +
        commons.escapeVariable('$id');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets one event tag by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Event tag ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EventTag].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EventTag> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/eventTags/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return EventTag.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new event tag.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EventTag].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EventTag> insert(
    EventTag request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/eventTags';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return EventTag.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of event tags, possibly filtered.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [adId] - Select only event tags that belong to this ad.
  ///
  /// [advertiserId] - Select only event tags that belong to this advertiser.
  ///
  /// [campaignId] - Select only event tags that belong to this campaign.
  ///
  /// [definitionsOnly] - Examine only the specified campaign or advertiser's
  /// event tags for matching selector criteria. When set to false, the parent
  /// advertiser and parent campaign of the specified ad or campaign is examined
  /// as well. In addition, when set to false, the status field is examined as
  /// well, along with the enabledByDefault field. This parameter can not be set
  /// to true when adId is specified as ads do not define their own even tags.
  ///
  /// [enabled] - Select only enabled event tags. What is considered enabled or
  /// disabled depends on the definitionsOnly parameter. When definitionsOnly is
  /// set to true, only the specified advertiser or campaign's event tags'
  /// enabledByDefault field is examined. When definitionsOnly is set to false,
  /// the specified ad or specified campaign's parent advertiser's or parent
  /// campaign's event tags' enabledByDefault and status fields are examined as
  /// well.
  ///
  /// [eventTagTypes] - Select only event tags with the specified event tag
  /// types. Event tag types can be used to specify whether to use a third-party
  /// pixel, a third-party JavaScript URL, or a third-party click-through URL
  /// for either impression or click tracking.
  ///
  /// [ids] - Select only event tags with these IDs.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "eventtag*2015" will return objects with names
  /// like "eventtag June 2015", "eventtag April 2015", or simply "eventtag
  /// 2015". Most of the searches also add wildcards implicitly at the start and
  /// the end of the search string. For example, a search string of "eventtag"
  /// will match objects with name "my eventtag", "eventtag 2015", or simply
  /// "eventtag".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EventTagsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EventTagsListResponse> list(
    core.String profileId, {
    core.String? adId,
    core.String? advertiserId,
    core.String? campaignId,
    core.bool? definitionsOnly,
    core.bool? enabled,
    core.List<core.String>? eventTagTypes,
    core.List<core.String>? ids,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (adId != null) 'adId': [adId],
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (campaignId != null) 'campaignId': [campaignId],
      if (definitionsOnly != null) 'definitionsOnly': ['${definitionsOnly}'],
      if (enabled != null) 'enabled': ['${enabled}'],
      if (eventTagTypes != null) 'eventTagTypes': eventTagTypes,
      if (ids != null) 'ids': ids,
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/eventTags';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return EventTagsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing event tag.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - EventTag ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EventTag].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EventTag> patch(
    EventTag request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/eventTags';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return EventTag.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing event tag.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EventTag].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EventTag> update(
    EventTag request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/eventTags';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return EventTag.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class FilesResource {
  final commons.ApiRequester _requester;

  FilesResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a report file by its report ID and file ID.
  ///
  /// This method supports media download.
  ///
  /// Request parameters:
  ///
  /// [reportId] - The ID of the report.
  ///
  /// [fileId] - The ID of the report file.
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
  /// - [File] for Metadata downloads (see [downloadOptions]).
  ///
  /// - [commons.Media] for Media downloads (see [downloadOptions]).
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<core.Object> get(
    core.String reportId,
    core.String fileId, {
    core.String? $fields,
    commons.DownloadOptions downloadOptions = commons.DownloadOptions.metadata,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'reports/' +
        commons.escapeVariable('$reportId') +
        '/files/' +
        commons.escapeVariable('$fileId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
      downloadOptions: downloadOptions,
    );
    if (downloadOptions.isMetadataDownload) {
      return File.fromJson(_response as core.Map<core.String, core.dynamic>);
    } else {
      return _response as commons.Media;
    }
  }

  /// Lists files for a user profile.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The Campaign Manager 360 user profile ID.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "10".
  ///
  /// [pageToken] - The value of the nextToken from the previous result page.
  ///
  /// [scope] - The scope that defines which results are returned.
  /// Possible string values are:
  /// - "ALL" : All files in account.
  /// - "MINE" : My files.
  /// - "SHARED_WITH_ME" : Files shared with me.
  ///
  /// [sortField] - The field by which to sort the list.
  /// Possible string values are:
  /// - "ID" : Sort by file ID.
  /// - "LAST_MODIFIED_TIME" : Sort by 'lastmodifiedAt' field.
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING" : Ascending order.
  /// - "DESCENDING" : Descending order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FileList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FileList> list(
    core.String profileId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? scope,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (scope != null) 'scope': [scope],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/files';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FileList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class FloodlightActivitiesResource {
  final commons.ApiRequester _requester;

  FloodlightActivitiesResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes an existing floodlight activity.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Floodlight activity ID.
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightActivities/' +
        commons.escapeVariable('$id');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Generates a tag for a floodlight activity.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [floodlightActivityId] - Floodlight activity ID for which we want to
  /// generate a tag.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightActivitiesGenerateTagResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightActivitiesGenerateTagResponse> generatetag(
    core.String profileId, {
    core.String? floodlightActivityId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (floodlightActivityId != null)
        'floodlightActivityId': [floodlightActivityId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightActivities/generatetag';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return FloodlightActivitiesGenerateTagResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets one floodlight activity by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Floodlight activity ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightActivity].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightActivity> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightActivities/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FloodlightActivity.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new floodlight activity.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightActivity].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightActivity> insert(
    FloodlightActivity request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightActivities';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return FloodlightActivity.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of floodlight activities, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserId] - Select only floodlight activities for the specified
  /// advertiser ID. Must specify either ids, advertiserId, or
  /// floodlightConfigurationId for a non-empty result.
  ///
  /// [floodlightActivityGroupIds] - Select only floodlight activities with the
  /// specified floodlight activity group IDs.
  ///
  /// [floodlightActivityGroupName] - Select only floodlight activities with the
  /// specified floodlight activity group name.
  ///
  /// [floodlightActivityGroupTagString] - Select only floodlight activities
  /// with the specified floodlight activity group tag string.
  ///
  /// [floodlightActivityGroupType] - Select only floodlight activities with the
  /// specified floodlight activity group type.
  /// Possible string values are:
  /// - "COUNTER"
  /// - "SALE"
  ///
  /// [floodlightConfigurationId] - Select only floodlight activities for the
  /// specified floodlight configuration ID. Must specify either ids,
  /// advertiserId, or floodlightConfigurationId for a non-empty result.
  ///
  /// [ids] - Select only floodlight activities with the specified IDs. Must
  /// specify either ids, advertiserId, or floodlightConfigurationId for a
  /// non-empty result.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "floodlightactivity*2015" will return objects
  /// with names like "floodlightactivity June 2015", "floodlightactivity April
  /// 2015", or simply "floodlightactivity 2015". Most of the searches also add
  /// wildcards implicitly at the start and the end of the search string. For
  /// example, a search string of "floodlightactivity" will match objects with
  /// name "my floodlightactivity activity", "floodlightactivity 2015", or
  /// simply "floodlightactivity".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [tagString] - Select only floodlight activities with the specified tag
  /// string.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightActivitiesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightActivitiesListResponse> list(
    core.String profileId, {
    core.String? advertiserId,
    core.List<core.String>? floodlightActivityGroupIds,
    core.String? floodlightActivityGroupName,
    core.String? floodlightActivityGroupTagString,
    core.String? floodlightActivityGroupType,
    core.String? floodlightConfigurationId,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? tagString,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (floodlightActivityGroupIds != null)
        'floodlightActivityGroupIds': floodlightActivityGroupIds,
      if (floodlightActivityGroupName != null)
        'floodlightActivityGroupName': [floodlightActivityGroupName],
      if (floodlightActivityGroupTagString != null)
        'floodlightActivityGroupTagString': [floodlightActivityGroupTagString],
      if (floodlightActivityGroupType != null)
        'floodlightActivityGroupType': [floodlightActivityGroupType],
      if (floodlightConfigurationId != null)
        'floodlightConfigurationId': [floodlightConfigurationId],
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (tagString != null) 'tagString': [tagString],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightActivities';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FloodlightActivitiesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing floodlight activity.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - FloodlightActivity ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightActivity].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightActivity> patch(
    FloodlightActivity request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightActivities';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return FloodlightActivity.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing floodlight activity.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightActivity].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightActivity> update(
    FloodlightActivity request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightActivities';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return FloodlightActivity.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FloodlightActivityGroupsResource {
  final commons.ApiRequester _requester;

  FloodlightActivityGroupsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets one floodlight activity group by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Floodlight activity Group ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightActivityGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightActivityGroup> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightActivityGroups/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FloodlightActivityGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new floodlight activity group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightActivityGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightActivityGroup> insert(
    FloodlightActivityGroup request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightActivityGroups';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return FloodlightActivityGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of floodlight activity groups, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserId] - Select only floodlight activity groups with the specified
  /// advertiser ID. Must specify either advertiserId or
  /// floodlightConfigurationId for a non-empty result.
  ///
  /// [floodlightConfigurationId] - Select only floodlight activity groups with
  /// the specified floodlight configuration ID. Must specify either
  /// advertiserId, or floodlightConfigurationId for a non-empty result.
  ///
  /// [ids] - Select only floodlight activity groups with the specified IDs.
  /// Must specify either advertiserId or floodlightConfigurationId for a
  /// non-empty result.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "floodlightactivitygroup*2015" will return
  /// objects with names like "floodlightactivitygroup June 2015",
  /// "floodlightactivitygroup April 2015", or simply "floodlightactivitygroup
  /// 2015". Most of the searches also add wildcards implicitly at the start and
  /// the end of the search string. For example, a search string of
  /// "floodlightactivitygroup" will match objects with name "my
  /// floodlightactivitygroup activity", "floodlightactivitygroup 2015", or
  /// simply "floodlightactivitygroup".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [type] - Select only floodlight activity groups with the specified
  /// floodlight activity group type.
  /// Possible string values are:
  /// - "COUNTER"
  /// - "SALE"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightActivityGroupsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightActivityGroupsListResponse> list(
    core.String profileId, {
    core.String? advertiserId,
    core.String? floodlightConfigurationId,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? type,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (floodlightConfigurationId != null)
        'floodlightConfigurationId': [floodlightConfigurationId],
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (type != null) 'type': [type],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightActivityGroups';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FloodlightActivityGroupsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing floodlight activity group.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - FloodlightActivityGroup ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightActivityGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightActivityGroup> patch(
    FloodlightActivityGroup request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightActivityGroups';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return FloodlightActivityGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing floodlight activity group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightActivityGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightActivityGroup> update(
    FloodlightActivityGroup request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightActivityGroups';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return FloodlightActivityGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FloodlightConfigurationsResource {
  final commons.ApiRequester _requester;

  FloodlightConfigurationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets one floodlight configuration by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Floodlight configuration ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightConfiguration> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightConfigurations/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FloodlightConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of floodlight configurations, possibly filtered.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [ids] - Set of IDs of floodlight configurations to retrieve. Required
  /// field; otherwise an empty list will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightConfigurationsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightConfigurationsListResponse> list(
    core.String profileId, {
    core.List<core.String>? ids,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ids != null) 'ids': ids,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightConfigurations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FloodlightConfigurationsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing floodlight configuration.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - FloodlightConfiguration ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightConfiguration> patch(
    FloodlightConfiguration request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightConfigurations';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return FloodlightConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing floodlight configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FloodlightConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FloodlightConfiguration> update(
    FloodlightConfiguration request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/floodlightConfigurations';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return FloodlightConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class InventoryItemsResource {
  final commons.ApiRequester _requester;

  InventoryItemsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one inventory item by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [projectId] - Project ID for order documents.
  ///
  /// [id] - Inventory item ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [InventoryItem].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<InventoryItem> get(
    core.String profileId,
    core.String projectId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/projects/' +
        commons.escapeVariable('$projectId') +
        '/inventoryItems/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return InventoryItem.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of inventory items, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [projectId] - Project ID for order documents.
  ///
  /// [ids] - Select only inventory items with these IDs.
  ///
  /// [inPlan] - Select only inventory items that are in plan.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [orderId] - Select only inventory items that belong to specified orders.
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [siteId] - Select only inventory items that are associated with these
  /// sites.
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [type] - Select only inventory items with this type.
  /// Possible string values are:
  /// - "PLANNING_PLACEMENT_TYPE_REGULAR"
  /// - "PLANNING_PLACEMENT_TYPE_CREDIT"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [InventoryItemsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<InventoryItemsListResponse> list(
    core.String profileId,
    core.String projectId, {
    core.List<core.String>? ids,
    core.bool? inPlan,
    core.int? maxResults,
    core.List<core.String>? orderId,
    core.String? pageToken,
    core.List<core.String>? siteId,
    core.String? sortField,
    core.String? sortOrder,
    core.String? type,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ids != null) 'ids': ids,
      if (inPlan != null) 'inPlan': ['${inPlan}'],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderId != null) 'orderId': orderId,
      if (pageToken != null) 'pageToken': [pageToken],
      if (siteId != null) 'siteId': siteId,
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (type != null) 'type': [type],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/projects/' +
        commons.escapeVariable('$projectId') +
        '/inventoryItems';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return InventoryItemsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class LanguagesResource {
  final commons.ApiRequester _requester;

  LanguagesResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a list of languages.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LanguagesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LanguagesListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/languages';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LanguagesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MetrosResource {
  final commons.ApiRequester _requester;

  MetrosResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a list of metros.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [MetrosListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<MetrosListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/metros';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return MetrosListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MobileAppsResource {
  final commons.ApiRequester _requester;

  MobileAppsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one mobile app by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Mobile app ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [MobileApp].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<MobileApp> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/mobileApps/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return MobileApp.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves list of available mobile apps.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [directories] - Select only apps from these directories.
  ///
  /// [ids] - Select only apps with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "app*2015" will return objects with names like
  /// "app Jan 2018", "app Jan 2018", or simply "app 2018". Most of the searches
  /// also add wildcards implicitly at the start and the end of the search
  /// string. For example, a search string of "app" will match objects with name
  /// "my app", "app 2018", or simply "app".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [MobileAppsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<MobileAppsListResponse> list(
    core.String profileId, {
    core.List<core.String>? directories,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (directories != null) 'directories': directories,
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/mobileApps';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return MobileAppsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MobileCarriersResource {
  final commons.ApiRequester _requester;

  MobileCarriersResource(commons.ApiRequester client) : _requester = client;

  /// Gets one mobile carrier by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Mobile carrier ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [MobileCarrier].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<MobileCarrier> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/mobileCarriers/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return MobileCarrier.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of mobile carriers.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [MobileCarriersListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<MobileCarriersListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/mobileCarriers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return MobileCarriersListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OperatingSystemVersionsResource {
  final commons.ApiRequester _requester;

  OperatingSystemVersionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets one operating system version by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Operating system version ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OperatingSystemVersion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OperatingSystemVersion> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/operatingSystemVersions/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OperatingSystemVersion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of operating system versions.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OperatingSystemVersionsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OperatingSystemVersionsListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/operatingSystemVersions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OperatingSystemVersionsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OperatingSystemsResource {
  final commons.ApiRequester _requester;

  OperatingSystemsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one operating system by DART ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [dartId] - Operating system DART ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OperatingSystem].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OperatingSystem> get(
    core.String profileId,
    core.String dartId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/operatingSystems/' +
        commons.escapeVariable('$dartId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OperatingSystem.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of operating systems.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OperatingSystemsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OperatingSystemsListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/operatingSystems';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OperatingSystemsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrderDocumentsResource {
  final commons.ApiRequester _requester;

  OrderDocumentsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one order document by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [projectId] - Project ID for order documents.
  ///
  /// [id] - Order document ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrderDocument].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrderDocument> get(
    core.String profileId,
    core.String projectId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/projects/' +
        commons.escapeVariable('$projectId') +
        '/orderDocuments/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OrderDocument.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of order documents, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [projectId] - Project ID for order documents.
  ///
  /// [approved] - Select only order documents that have been approved by at
  /// least one user.
  ///
  /// [ids] - Select only order documents with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [orderId] - Select only order documents for specified orders.
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for order documents by name or ID.
  /// Wildcards (*) are allowed. For example, "orderdocument*2015" will return
  /// order documents with names like "orderdocument June 2015", "orderdocument
  /// April 2015", or simply "orderdocument 2015". Most of the searches also add
  /// wildcards implicitly at the start and the end of the search string. For
  /// example, a search string of "orderdocument" will match order documents
  /// with name "my orderdocument", "orderdocument 2015", or simply
  /// "orderdocument".
  ///
  /// [siteId] - Select only order documents that are associated with these
  /// sites.
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrderDocumentsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrderDocumentsListResponse> list(
    core.String profileId,
    core.String projectId, {
    core.bool? approved,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.List<core.String>? orderId,
    core.String? pageToken,
    core.String? searchString,
    core.List<core.String>? siteId,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (approved != null) 'approved': ['${approved}'],
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderId != null) 'orderId': orderId,
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (siteId != null) 'siteId': siteId,
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/projects/' +
        commons.escapeVariable('$projectId') +
        '/orderDocuments';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OrderDocumentsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrdersResource {
  final commons.ApiRequester _requester;

  OrdersResource(commons.ApiRequester client) : _requester = client;

  /// Gets one order by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [projectId] - Project ID for orders.
  ///
  /// [id] - Order ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Order].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Order> get(
    core.String profileId,
    core.String projectId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/projects/' +
        commons.escapeVariable('$projectId') +
        '/orders/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Order.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of orders, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [projectId] - Project ID for orders.
  ///
  /// [ids] - Select only orders with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for orders by name or ID. Wildcards (*)
  /// are allowed. For example, "order*2015" will return orders with names like
  /// "order June 2015", "order April 2015", or simply "order 2015". Most of the
  /// searches also add wildcards implicitly at the start and the end of the
  /// search string. For example, a search string of "order" will match orders
  /// with name "my order", "order 2015", or simply "order".
  ///
  /// [siteId] - Select only orders that are associated with these site IDs.
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersListResponse> list(
    core.String profileId,
    core.String projectId, {
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.List<core.String>? siteId,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (siteId != null) 'siteId': siteId,
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/projects/' +
        commons.escapeVariable('$projectId') +
        '/orders';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OrdersListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PlacementGroupsResource {
  final commons.ApiRequester _requester;

  PlacementGroupsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one placement group by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Placement group ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlacementGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlacementGroup> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placementGroups/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PlacementGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new placement group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlacementGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlacementGroup> insert(
    PlacementGroup request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placementGroups';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PlacementGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of placement groups, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserIds] - Select only placement groups that belong to these
  /// advertisers.
  ///
  /// [archived] - Select only archived placements. Don't set this field to
  /// select both archived and non-archived placements.
  ///
  /// [campaignIds] - Select only placement groups that belong to these
  /// campaigns.
  ///
  /// [contentCategoryIds] - Select only placement groups that are associated
  /// with these content categories.
  ///
  /// [directorySiteIds] - Select only placement groups that are associated with
  /// these directory sites.
  ///
  /// [ids] - Select only placement groups with these IDs.
  ///
  /// [maxEndDate] - Select only placements or placement groups whose end date
  /// is on or before the specified maxEndDate. The date should be formatted as
  /// "yyyy-MM-dd".
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "800".
  ///
  /// [maxStartDate] - Select only placements or placement groups whose start
  /// date is on or before the specified maxStartDate. The date should be
  /// formatted as "yyyy-MM-dd".
  ///
  /// [minEndDate] - Select only placements or placement groups whose end date
  /// is on or after the specified minEndDate. The date should be formatted as
  /// "yyyy-MM-dd".
  ///
  /// [minStartDate] - Select only placements or placement groups whose start
  /// date is on or after the specified minStartDate. The date should be
  /// formatted as "yyyy-MM-dd".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [placementGroupType] - Select only placement groups belonging with this
  /// group type. A package is a simple group of placements that acts as a
  /// single pricing point for a group of tags. A roadblock is a group of
  /// placements that not only acts as a single pricing point but also assumes
  /// that all the tags in it will be served at the same time. A roadblock
  /// requires one of its assigned placements to be marked as primary for
  /// reporting.
  /// Possible string values are:
  /// - "PLACEMENT_PACKAGE"
  /// - "PLACEMENT_ROADBLOCK"
  ///
  /// [placementStrategyIds] - Select only placement groups that are associated
  /// with these placement strategies.
  ///
  /// [pricingTypes] - Select only placement groups with these pricing types.
  ///
  /// [searchString] - Allows searching for placement groups by name or ID.
  /// Wildcards (*) are allowed. For example, "placement*2015" will return
  /// placement groups with names like "placement group June 2015", "placement
  /// group May 2015", or simply "placements 2015". Most of the searches also
  /// add wildcards implicitly at the start and the end of the search string.
  /// For example, a search string of "placementgroup" will match placement
  /// groups with name "my placementgroup", "placementgroup 2015", or simply
  /// "placementgroup".
  ///
  /// [siteIds] - Select only placement groups that are associated with these
  /// sites.
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlacementGroupsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlacementGroupsListResponse> list(
    core.String profileId, {
    core.List<core.String>? advertiserIds,
    core.bool? archived,
    core.List<core.String>? campaignIds,
    core.List<core.String>? contentCategoryIds,
    core.List<core.String>? directorySiteIds,
    core.List<core.String>? ids,
    core.String? maxEndDate,
    core.int? maxResults,
    core.String? maxStartDate,
    core.String? minEndDate,
    core.String? minStartDate,
    core.String? pageToken,
    core.String? placementGroupType,
    core.List<core.String>? placementStrategyIds,
    core.List<core.String>? pricingTypes,
    core.String? searchString,
    core.List<core.String>? siteIds,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserIds != null) 'advertiserIds': advertiserIds,
      if (archived != null) 'archived': ['${archived}'],
      if (campaignIds != null) 'campaignIds': campaignIds,
      if (contentCategoryIds != null) 'contentCategoryIds': contentCategoryIds,
      if (directorySiteIds != null) 'directorySiteIds': directorySiteIds,
      if (ids != null) 'ids': ids,
      if (maxEndDate != null) 'maxEndDate': [maxEndDate],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (maxStartDate != null) 'maxStartDate': [maxStartDate],
      if (minEndDate != null) 'minEndDate': [minEndDate],
      if (minStartDate != null) 'minStartDate': [minStartDate],
      if (pageToken != null) 'pageToken': [pageToken],
      if (placementGroupType != null)
        'placementGroupType': [placementGroupType],
      if (placementStrategyIds != null)
        'placementStrategyIds': placementStrategyIds,
      if (pricingTypes != null) 'pricingTypes': pricingTypes,
      if (searchString != null) 'searchString': [searchString],
      if (siteIds != null) 'siteIds': siteIds,
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placementGroups';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PlacementGroupsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing placement group.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - PlacementGroup ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlacementGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlacementGroup> patch(
    PlacementGroup request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placementGroups';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return PlacementGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing placement group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlacementGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlacementGroup> update(
    PlacementGroup request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placementGroups';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return PlacementGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PlacementStrategiesResource {
  final commons.ApiRequester _requester;

  PlacementStrategiesResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes an existing placement strategy.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Placement strategy ID.
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placementStrategies/' +
        commons.escapeVariable('$id');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets one placement strategy by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Placement strategy ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlacementStrategy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlacementStrategy> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placementStrategies/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PlacementStrategy.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new placement strategy.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlacementStrategy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlacementStrategy> insert(
    PlacementStrategy request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placementStrategies';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PlacementStrategy.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of placement strategies, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [ids] - Select only placement strategies with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "placementstrategy*2015" will return objects
  /// with names like "placementstrategy June 2015", "placementstrategy April
  /// 2015", or simply "placementstrategy 2015". Most of the searches also add
  /// wildcards implicitly at the start and the end of the search string. For
  /// example, a search string of "placementstrategy" will match objects with
  /// name "my placementstrategy", "placementstrategy 2015", or simply
  /// "placementstrategy".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlacementStrategiesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlacementStrategiesListResponse> list(
    core.String profileId, {
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placementStrategies';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PlacementStrategiesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing placement strategy.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - PlacementStrategy ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlacementStrategy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlacementStrategy> patch(
    PlacementStrategy request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placementStrategies';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return PlacementStrategy.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing placement strategy.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlacementStrategy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlacementStrategy> update(
    PlacementStrategy request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placementStrategies';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return PlacementStrategy.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PlacementsResource {
  final commons.ApiRequester _requester;

  PlacementsResource(commons.ApiRequester client) : _requester = client;

  /// Generates tags for a placement.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [campaignId] - Generate placements belonging to this campaign. This is a
  /// required field.
  ///
  /// [placementIds] - Generate tags for these placements.
  ///
  /// [tagFormats] - Tag formats to generate for these placements. *Note:*
  /// PLACEMENT_TAG_STANDARD can only be generated for 1x1 placements.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlacementsGenerateTagsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlacementsGenerateTagsResponse> generatetags(
    core.String profileId, {
    core.String? campaignId,
    core.List<core.String>? placementIds,
    core.List<core.String>? tagFormats,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (campaignId != null) 'campaignId': [campaignId],
      if (placementIds != null) 'placementIds': placementIds,
      if (tagFormats != null) 'tagFormats': tagFormats,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placements/generatetags';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return PlacementsGenerateTagsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets one placement by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Placement ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Placement].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Placement> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/placements/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Placement.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new placement.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Placement].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Placement> insert(
    Placement request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/placements';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Placement.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of placements, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserIds] - Select only placements that belong to these advertisers.
  ///
  /// [archived] - Select only archived placements. Don't set this field to
  /// select both archived and non-archived placements.
  ///
  /// [campaignIds] - Select only placements that belong to these campaigns.
  ///
  /// [compatibilities] - Select only placements that are associated with these
  /// compatibilities. DISPLAY and DISPLAY_INTERSTITIAL refer to rendering
  /// either on desktop or on mobile devices for regular or interstitial ads
  /// respectively. APP and APP_INTERSTITIAL are for rendering in mobile apps.
  /// IN_STREAM_VIDEO refers to rendering in in-stream video ads developed with
  /// the VAST standard.
  ///
  /// [contentCategoryIds] - Select only placements that are associated with
  /// these content categories.
  ///
  /// [directorySiteIds] - Select only placements that are associated with these
  /// directory sites.
  ///
  /// [groupIds] - Select only placements that belong to these placement groups.
  ///
  /// [ids] - Select only placements with these IDs.
  ///
  /// [maxEndDate] - Select only placements or placement groups whose end date
  /// is on or before the specified maxEndDate. The date should be formatted as
  /// "yyyy-MM-dd".
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [maxStartDate] - Select only placements or placement groups whose start
  /// date is on or before the specified maxStartDate. The date should be
  /// formatted as "yyyy-MM-dd".
  ///
  /// [minEndDate] - Select only placements or placement groups whose end date
  /// is on or after the specified minEndDate. The date should be formatted as
  /// "yyyy-MM-dd".
  ///
  /// [minStartDate] - Select only placements or placement groups whose start
  /// date is on or after the specified minStartDate. The date should be
  /// formatted as "yyyy-MM-dd".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [paymentSource] - Select only placements with this payment source.
  /// Possible string values are:
  /// - "PLACEMENT_AGENCY_PAID"
  /// - "PLACEMENT_PUBLISHER_PAID"
  ///
  /// [placementStrategyIds] - Select only placements that are associated with
  /// these placement strategies.
  ///
  /// [pricingTypes] - Select only placements with these pricing types.
  ///
  /// [searchString] - Allows searching for placements by name or ID. Wildcards
  /// (*) are allowed. For example, "placement*2015" will return placements with
  /// names like "placement June 2015", "placement May 2015", or simply
  /// "placements 2015". Most of the searches also add wildcards implicitly at
  /// the start and the end of the search string. For example, a search string
  /// of "placement" will match placements with name "my placement", "placement
  /// 2015", or simply "placement" .
  ///
  /// [siteIds] - Select only placements that are associated with these sites.
  ///
  /// [sizeIds] - Select only placements that are associated with these sizes.
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlacementsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlacementsListResponse> list(
    core.String profileId, {
    core.List<core.String>? advertiserIds,
    core.bool? archived,
    core.List<core.String>? campaignIds,
    core.List<core.String>? compatibilities,
    core.List<core.String>? contentCategoryIds,
    core.List<core.String>? directorySiteIds,
    core.List<core.String>? groupIds,
    core.List<core.String>? ids,
    core.String? maxEndDate,
    core.int? maxResults,
    core.String? maxStartDate,
    core.String? minEndDate,
    core.String? minStartDate,
    core.String? pageToken,
    core.String? paymentSource,
    core.List<core.String>? placementStrategyIds,
    core.List<core.String>? pricingTypes,
    core.String? searchString,
    core.List<core.String>? siteIds,
    core.List<core.String>? sizeIds,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserIds != null) 'advertiserIds': advertiserIds,
      if (archived != null) 'archived': ['${archived}'],
      if (campaignIds != null) 'campaignIds': campaignIds,
      if (compatibilities != null) 'compatibilities': compatibilities,
      if (contentCategoryIds != null) 'contentCategoryIds': contentCategoryIds,
      if (directorySiteIds != null) 'directorySiteIds': directorySiteIds,
      if (groupIds != null) 'groupIds': groupIds,
      if (ids != null) 'ids': ids,
      if (maxEndDate != null) 'maxEndDate': [maxEndDate],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (maxStartDate != null) 'maxStartDate': [maxStartDate],
      if (minEndDate != null) 'minEndDate': [minEndDate],
      if (minStartDate != null) 'minStartDate': [minStartDate],
      if (pageToken != null) 'pageToken': [pageToken],
      if (paymentSource != null) 'paymentSource': [paymentSource],
      if (placementStrategyIds != null)
        'placementStrategyIds': placementStrategyIds,
      if (pricingTypes != null) 'pricingTypes': pricingTypes,
      if (searchString != null) 'searchString': [searchString],
      if (siteIds != null) 'siteIds': siteIds,
      if (sizeIds != null) 'sizeIds': sizeIds,
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/placements';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PlacementsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing placement.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Placement ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Placement].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Placement> patch(
    Placement request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/placements';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Placement.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing placement.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Placement].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Placement> update(
    Placement request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/placements';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Placement.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class PlatformTypesResource {
  final commons.ApiRequester _requester;

  PlatformTypesResource(commons.ApiRequester client) : _requester = client;

  /// Gets one platform type by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Platform type ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlatformType].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlatformType> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/platformTypes/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PlatformType.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of platform types.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlatformTypesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlatformTypesListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/platformTypes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PlatformTypesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PostalCodesResource {
  final commons.ApiRequester _requester;

  PostalCodesResource(commons.ApiRequester client) : _requester = client;

  /// Gets one postal code by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [code] - Postal code ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PostalCode].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PostalCode> get(
    core.String profileId,
    core.String code, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/postalCodes/' +
        commons.escapeVariable('$code');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PostalCode.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of postal codes.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PostalCodesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PostalCodesListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/postalCodes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PostalCodesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one project by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Project ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Project].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Project> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/projects/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Project.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of projects, possibly filtered.
  ///
  /// This method supports paging .
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserIds] - Select only projects with these advertiser IDs.
  ///
  /// [ids] - Select only projects with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for projects by name or ID. Wildcards
  /// (*) are allowed. For example, "project*2015" will return projects with
  /// names like "project June 2015", "project April 2015", or simply "project
  /// 2015". Most of the searches also add wildcards implicitly at the start and
  /// the end of the search string. For example, a search string of "project"
  /// will match projects with name "my project", "project 2015", or simply
  /// "project".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProjectsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProjectsListResponse> list(
    core.String profileId, {
    core.List<core.String>? advertiserIds,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserIds != null) 'advertiserIds': advertiserIds,
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/projects';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ProjectsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class RegionsResource {
  final commons.ApiRequester _requester;

  RegionsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a list of regions.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RegionsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RegionsListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/regions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return RegionsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class RemarketingListSharesResource {
  final commons.ApiRequester _requester;

  RemarketingListSharesResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets one remarketing list share by remarketing list ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [remarketingListId] - Remarketing list ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RemarketingListShare].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RemarketingListShare> get(
    core.String profileId,
    core.String remarketingListId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/remarketingListShares/' +
        commons.escapeVariable('$remarketingListId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return RemarketingListShare.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing remarketing list share.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - RemarketingList ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RemarketingListShare].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RemarketingListShare> patch(
    RemarketingListShare request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/remarketingListShares';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return RemarketingListShare.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing remarketing list share.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RemarketingListShare].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RemarketingListShare> update(
    RemarketingListShare request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/remarketingListShares';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return RemarketingListShare.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class RemarketingListsResource {
  final commons.ApiRequester _requester;

  RemarketingListsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one remarketing list by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Remarketing list ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RemarketingList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RemarketingList> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/remarketingLists/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return RemarketingList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new remarketing list.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RemarketingList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RemarketingList> insert(
    RemarketingList request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/remarketingLists';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return RemarketingList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of remarketing lists, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserId] - Select only remarketing lists owned by this advertiser.
  ///
  /// [active] - Select only active or only inactive remarketing lists.
  ///
  /// [floodlightActivityId] - Select only remarketing lists that have this
  /// floodlight activity ID.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [name] - Allows searching for objects by name or ID. Wildcards (*) are
  /// allowed. For example, "remarketing list*2015" will return objects with
  /// names like "remarketing list June 2015", "remarketing list April 2015", or
  /// simply "remarketing list 2015". Most of the searches also add wildcards
  /// implicitly at the start and the end of the search string. For example, a
  /// search string of "remarketing list" will match objects with name "my
  /// remarketing list", "remarketing list 2015", or simply "remarketing list".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RemarketingListsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RemarketingListsListResponse> list(
    core.String profileId,
    core.String advertiserId, {
    core.bool? active,
    core.String? floodlightActivityId,
    core.int? maxResults,
    core.String? name,
    core.String? pageToken,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'advertiserId': [advertiserId],
      if (active != null) 'active': ['${active}'],
      if (floodlightActivityId != null)
        'floodlightActivityId': [floodlightActivityId],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (name != null) 'name': [name],
      if (pageToken != null) 'pageToken': [pageToken],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/remarketingLists';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return RemarketingListsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing remarketing list.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - RemarketingList ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RemarketingList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RemarketingList> patch(
    RemarketingList request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/remarketingLists';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return RemarketingList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing remarketing list.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RemarketingList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RemarketingList> update(
    RemarketingList request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/remarketingLists';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return RemarketingList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ReportsResource {
  final commons.ApiRequester _requester;

  ReportsCompatibleFieldsResource get compatibleFields =>
      ReportsCompatibleFieldsResource(_requester);
  ReportsFilesResource get files => ReportsFilesResource(_requester);

  ReportsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a report by its ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The Campaign Manager 360 user profile ID.
  ///
  /// [reportId] - The ID of the report.
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
    core.String profileId,
    core.String reportId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/reports/' +
        commons.escapeVariable('$reportId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a report by its ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The Campaign Manager 360 user profile ID.
  ///
  /// [reportId] - The ID of the report.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Report].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Report> get(
    core.String profileId,
    core.String reportId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/reports/' +
        commons.escapeVariable('$reportId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Report.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a report.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The Campaign Manager 360 user profile ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Report].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Report> insert(
    Report request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/reports';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Report.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves list of reports.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The Campaign Manager 360 user profile ID.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "10".
  ///
  /// [pageToken] - The value of the nextToken from the previous result page.
  ///
  /// [scope] - The scope that defines which results are returned.
  /// Possible string values are:
  /// - "ALL" : All reports in account.
  /// - "MINE" : My reports.
  ///
  /// [sortField] - The field by which to sort the list.
  /// Possible string values are:
  /// - "ID" : Sort by report ID.
  /// - "LAST_MODIFIED_TIME" : Sort by 'lastModifiedTime' field.
  /// - "NAME" : Sort by name of reports.
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING" : Ascending order.
  /// - "DESCENDING" : Descending order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReportList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReportList> list(
    core.String profileId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? scope,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (scope != null) 'scope': [scope],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/reports';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ReportList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing report.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The DFA user profile ID.
  ///
  /// [reportId] - The ID of the report.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Report].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Report> patch(
    Report request,
    core.String profileId,
    core.String reportId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/reports/' +
        commons.escapeVariable('$reportId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Report.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Runs a report.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The Campaign Manager 360 user profile ID.
  ///
  /// [reportId] - The ID of the report.
  ///
  /// [synchronous] - If set and true, tries to run the report synchronously.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [File].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<File> run(
    core.String profileId,
    core.String reportId, {
    core.bool? synchronous,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (synchronous != null) 'synchronous': ['${synchronous}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/reports/' +
        commons.escapeVariable('$reportId') +
        '/run';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return File.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a report.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The Campaign Manager 360 user profile ID.
  ///
  /// [reportId] - The ID of the report.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Report].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Report> update(
    Report request,
    core.String profileId,
    core.String reportId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/reports/' +
        commons.escapeVariable('$reportId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Report.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ReportsCompatibleFieldsResource {
  final commons.ApiRequester _requester;

  ReportsCompatibleFieldsResource(commons.ApiRequester client)
      : _requester = client;

  /// Returns the fields that are compatible to be selected in the respective
  /// sections of a report criteria, given the fields already selected in the
  /// input report and user permissions.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The Campaign Manager 360 user profile ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CompatibleFields].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CompatibleFields> query(
    Report request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/reports/compatiblefields/query';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CompatibleFields.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ReportsFilesResource {
  final commons.ApiRequester _requester;

  ReportsFilesResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a report file by its report ID and file ID.
  ///
  /// This method supports media download.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The Campaign Manager 360 user profile ID.
  ///
  /// [reportId] - The ID of the report.
  ///
  /// [fileId] - The ID of the report file.
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
  /// - [File] for Metadata downloads (see [downloadOptions]).
  ///
  /// - [commons.Media] for Media downloads (see [downloadOptions]).
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<core.Object> get(
    core.String profileId,
    core.String reportId,
    core.String fileId, {
    core.String? $fields,
    commons.DownloadOptions downloadOptions = commons.DownloadOptions.metadata,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/reports/' +
        commons.escapeVariable('$reportId') +
        '/files/' +
        commons.escapeVariable('$fileId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
      downloadOptions: downloadOptions,
    );
    if (downloadOptions.isMetadataDownload) {
      return File.fromJson(_response as core.Map<core.String, core.dynamic>);
    } else {
      return _response as commons.Media;
    }
  }

  /// Lists files for a report.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The Campaign Manager 360 user profile ID.
  ///
  /// [reportId] - The ID of the parent report.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "10".
  ///
  /// [pageToken] - The value of the nextToken from the previous result page.
  ///
  /// [sortField] - The field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "LAST_MODIFIED_TIME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FileList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FileList> list(
    core.String profileId,
    core.String reportId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/reports/' +
        commons.escapeVariable('$reportId') +
        '/files';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FileList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SitesResource {
  final commons.ApiRequester _requester;

  SitesResource(commons.ApiRequester client) : _requester = client;

  /// Gets one site by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Site ID.
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
  async.Future<Site> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/sites/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Site.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new site.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
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
  async.Future<Site> insert(
    Site request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/sites';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Site.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of sites, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [acceptsInStreamVideoPlacements] - This search filter is no longer
  /// supported and will have no effect on the results returned.
  ///
  /// [acceptsInterstitialPlacements] - This search filter is no longer
  /// supported and will have no effect on the results returned.
  ///
  /// [acceptsPublisherPaidPlacements] - Select only sites that accept publisher
  /// paid placements.
  ///
  /// [adWordsSite] - Select only AdWords sites.
  ///
  /// [approved] - Select only approved sites.
  ///
  /// [campaignIds] - Select only sites with these campaign IDs.
  ///
  /// [directorySiteIds] - Select only sites with these directory site IDs.
  ///
  /// [ids] - Select only sites with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name, ID or keyName.
  /// Wildcards (*) are allowed. For example, "site*2015" will return objects
  /// with names like "site June 2015", "site April 2015", or simply "site
  /// 2015". Most of the searches also add wildcards implicitly at the start and
  /// the end of the search string. For example, a search string of "site" will
  /// match objects with name "my site", "site 2015", or simply "site".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [subaccountId] - Select only sites with this subaccount ID.
  ///
  /// [unmappedSite] - Select only sites that have not been mapped to a
  /// directory site.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SitesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SitesListResponse> list(
    core.String profileId, {
    core.bool? acceptsInStreamVideoPlacements,
    core.bool? acceptsInterstitialPlacements,
    core.bool? acceptsPublisherPaidPlacements,
    core.bool? adWordsSite,
    core.bool? approved,
    core.List<core.String>? campaignIds,
    core.List<core.String>? directorySiteIds,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? subaccountId,
    core.bool? unmappedSite,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (acceptsInStreamVideoPlacements != null)
        'acceptsInStreamVideoPlacements': ['${acceptsInStreamVideoPlacements}'],
      if (acceptsInterstitialPlacements != null)
        'acceptsInterstitialPlacements': ['${acceptsInterstitialPlacements}'],
      if (acceptsPublisherPaidPlacements != null)
        'acceptsPublisherPaidPlacements': ['${acceptsPublisherPaidPlacements}'],
      if (adWordsSite != null) 'adWordsSite': ['${adWordsSite}'],
      if (approved != null) 'approved': ['${approved}'],
      if (campaignIds != null) 'campaignIds': campaignIds,
      if (directorySiteIds != null) 'directorySiteIds': directorySiteIds,
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (subaccountId != null) 'subaccountId': [subaccountId],
      if (unmappedSite != null) 'unmappedSite': ['${unmappedSite}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/sites';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SitesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing site.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Site ID.
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
  async.Future<Site> patch(
    Site request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/sites';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Site.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing site.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
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
  async.Future<Site> update(
    Site request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/sites';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Site.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SizesResource {
  final commons.ApiRequester _requester;

  SizesResource(commons.ApiRequester client) : _requester = client;

  /// Gets one size by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Size ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Size].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Size> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/sizes/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Size.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new size.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Size].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Size> insert(
    Size request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/sizes';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Size.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of sizes, possibly filtered.
  ///
  /// Retrieved sizes are globally unique and may include values not currently
  /// in use by your account. Due to this, the list of sizes returned by this
  /// method may differ from the list seen in the Trafficking UI.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [height] - Select only sizes with this height.
  /// Value must be between "0" and "32767".
  ///
  /// [iabStandard] - Select only IAB standard sizes.
  ///
  /// [ids] - Select only sizes with these IDs.
  ///
  /// [width] - Select only sizes with this width.
  /// Value must be between "0" and "32767".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SizesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SizesListResponse> list(
    core.String profileId, {
    core.int? height,
    core.bool? iabStandard,
    core.List<core.String>? ids,
    core.int? width,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (height != null) 'height': ['${height}'],
      if (iabStandard != null) 'iabStandard': ['${iabStandard}'],
      if (ids != null) 'ids': ids,
      if (width != null) 'width': ['${width}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/sizes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SizesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class SubaccountsResource {
  final commons.ApiRequester _requester;

  SubaccountsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one subaccount by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Subaccount ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subaccount].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subaccount> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/subaccounts/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Subaccount.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new subaccount.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subaccount].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subaccount> insert(
    Subaccount request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/subaccounts';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Subaccount.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a list of subaccounts, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [ids] - Select only subaccounts with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "subaccount*2015" will return objects with names
  /// like "subaccount June 2015", "subaccount April 2015", or simply
  /// "subaccount 2015". Most of the searches also add wildcards implicitly at
  /// the start and the end of the search string. For example, a search string
  /// of "subaccount" will match objects with name "my subaccount", "subaccount
  /// 2015", or simply "subaccount" .
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SubaccountsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SubaccountsListResponse> list(
    core.String profileId, {
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/subaccounts';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SubaccountsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing subaccount.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Subaccount ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subaccount].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subaccount> patch(
    Subaccount request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/subaccounts';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Subaccount.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing subaccount.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subaccount].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subaccount> update(
    Subaccount request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/subaccounts';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Subaccount.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class TargetableRemarketingListsResource {
  final commons.ApiRequester _requester;

  TargetableRemarketingListsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets one remarketing list by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Remarketing list ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TargetableRemarketingList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TargetableRemarketingList> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/targetableRemarketingLists/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TargetableRemarketingList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of targetable remarketing lists, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserId] - Select only targetable remarketing lists targetable by
  /// these advertisers.
  ///
  /// [active] - Select only active or only inactive targetable remarketing
  /// lists.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [name] - Allows searching for objects by name or ID. Wildcards (*) are
  /// allowed. For example, "remarketing list*2015" will return objects with
  /// names like "remarketing list June 2015", "remarketing list April 2015", or
  /// simply "remarketing list 2015". Most of the searches also add wildcards
  /// implicitly at the start and the end of the search string. For example, a
  /// search string of "remarketing list" will match objects with name "my
  /// remarketing list", "remarketing list 2015", or simply "remarketing list".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TargetableRemarketingListsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TargetableRemarketingListsListResponse> list(
    core.String profileId,
    core.String advertiserId, {
    core.bool? active,
    core.int? maxResults,
    core.String? name,
    core.String? pageToken,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'advertiserId': [advertiserId],
      if (active != null) 'active': ['${active}'],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (name != null) 'name': [name],
      if (pageToken != null) 'pageToken': [pageToken],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/targetableRemarketingLists';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TargetableRemarketingListsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class TargetingTemplatesResource {
  final commons.ApiRequester _requester;

  TargetingTemplatesResource(commons.ApiRequester client) : _requester = client;

  /// Gets one targeting template by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Targeting template ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TargetingTemplate].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TargetingTemplate> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/targetingTemplates/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TargetingTemplate.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new targeting template.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TargetingTemplate].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TargetingTemplate> insert(
    TargetingTemplate request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/targetingTemplates';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TargetingTemplate.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of targeting templates, optionally filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [advertiserId] - Select only targeting templates with this advertiser ID.
  ///
  /// [ids] - Select only targeting templates with these IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "template*2015" will return objects with names
  /// like "template June 2015", "template April 2015", or simply "template
  /// 2015". Most of the searches also add wildcards implicitly at the start and
  /// the end of the search string. For example, a search string of "template"
  /// will match objects with name "my template", "template 2015", or simply
  /// "template".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TargetingTemplatesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TargetingTemplatesListResponse> list(
    core.String profileId, {
    core.String? advertiserId,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (advertiserId != null) 'advertiserId': [advertiserId],
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/targetingTemplates';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TargetingTemplatesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing targeting template.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - TargetingTemplate ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TargetingTemplate].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TargetingTemplate> patch(
    TargetingTemplate request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/targetingTemplates';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return TargetingTemplate.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing targeting template.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TargetingTemplate].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TargetingTemplate> update(
    TargetingTemplate request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/targetingTemplates';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return TargetingTemplate.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class UserProfilesResource {
  final commons.ApiRequester _requester;

  UserProfilesResource(commons.ApiRequester client) : _requester = client;

  /// Gets one user profile by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - The user profile ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserProfile].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserProfile> get(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' + commons.escapeVariable('$profileId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UserProfile.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves list of user profiles for a user.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserProfileList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserProfileList> list({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'userprofiles';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UserProfileList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class UserRolePermissionGroupsResource {
  final commons.ApiRequester _requester;

  UserRolePermissionGroupsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets one user role permission group by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - User role permission group ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserRolePermissionGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserRolePermissionGroup> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/userRolePermissionGroups/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UserRolePermissionGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a list of all supported user role permission groups.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserRolePermissionGroupsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserRolePermissionGroupsListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/userRolePermissionGroups';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UserRolePermissionGroupsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class UserRolePermissionsResource {
  final commons.ApiRequester _requester;

  UserRolePermissionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets one user role permission by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - User role permission ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserRolePermission].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserRolePermission> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/userRolePermissions/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UserRolePermission.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a list of user role permissions, possibly filtered.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [ids] - Select only user role permissions with these IDs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserRolePermissionsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserRolePermissionsListResponse> list(
    core.String profileId, {
    core.List<core.String>? ids,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (ids != null) 'ids': ids,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/userRolePermissions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UserRolePermissionsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class UserRolesResource {
  final commons.ApiRequester _requester;

  UserRolesResource(commons.ApiRequester client) : _requester = client;

  /// Deletes an existing user role.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - User role ID.
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
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/userRoles/' +
        commons.escapeVariable('$id');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets one user role by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - User role ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserRole].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserRole> get(
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/userRoles/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UserRole.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new user role.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserRole].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserRole> insert(
    UserRole request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/userRoles';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return UserRole.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of user roles, possibly filtered.
  ///
  /// This method supports paging.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [accountUserRoleOnly] - Select only account level user roles not
  /// associated with any specific subaccount.
  ///
  /// [ids] - Select only user roles with the specified IDs.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "0" and "1000".
  ///
  /// [pageToken] - Value of the nextPageToken from the previous result page.
  ///
  /// [searchString] - Allows searching for objects by name or ID. Wildcards (*)
  /// are allowed. For example, "userrole*2015" will return objects with names
  /// like "userrole June 2015", "userrole April 2015", or simply "userrole
  /// 2015". Most of the searches also add wildcards implicitly at the start and
  /// the end of the search string. For example, a search string of "userrole"
  /// will match objects with name "my userrole", "userrole 2015", or simply
  /// "userrole".
  ///
  /// [sortField] - Field by which to sort the list.
  /// Possible string values are:
  /// - "ID"
  /// - "NAME"
  ///
  /// [sortOrder] - Order of sorted results.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  ///
  /// [subaccountId] - Select only user roles that belong to this subaccount.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserRolesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserRolesListResponse> list(
    core.String profileId, {
    core.bool? accountUserRoleOnly,
    core.List<core.String>? ids,
    core.int? maxResults,
    core.String? pageToken,
    core.String? searchString,
    core.String? sortField,
    core.String? sortOrder,
    core.String? subaccountId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (accountUserRoleOnly != null)
        'accountUserRoleOnly': ['${accountUserRoleOnly}'],
      if (ids != null) 'ids': ids,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (searchString != null) 'searchString': [searchString],
      if (sortField != null) 'sortField': [sortField],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (subaccountId != null) 'subaccountId': [subaccountId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/userRoles';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UserRolesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing user role.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - UserRole ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserRole].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserRole> patch(
    UserRole request,
    core.String profileId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'id': [id],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/userRoles';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return UserRole.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing user role.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserRole].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserRole> update(
    UserRole request,
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'userprofiles/' + commons.escapeVariable('$profileId') + '/userRoles';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return UserRole.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class VideoFormatsResource {
  final commons.ApiRequester _requester;

  VideoFormatsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one video format by ID.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [id] - Video format ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [VideoFormat].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<VideoFormat> get(
    core.String profileId,
    core.int id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/videoFormats/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return VideoFormat.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists available video formats.
  ///
  /// Request parameters:
  ///
  /// [profileId] - User profile ID associated with this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [VideoFormatsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<VideoFormatsListResponse> list(
    core.String profileId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'userprofiles/' +
        commons.escapeVariable('$profileId') +
        '/videoFormats';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return VideoFormatsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Contains properties of a Campaign Manager account.
class Account {
  /// Account permissions assigned to this account.
  core.List<core.String>? accountPermissionIds;

  /// Profile for this account.
  ///
  /// This is a read-only field that can be left blank.
  /// Possible string values are:
  /// - "ACCOUNT_PROFILE_BASIC"
  /// - "ACCOUNT_PROFILE_STANDARD"
  core.String? accountProfile;

  /// Whether this account is active.
  core.bool? active;

  /// Maximum number of active ads allowed for this account.
  /// Possible string values are:
  /// - "ACTIVE_ADS_TIER_40K"
  /// - "ACTIVE_ADS_TIER_75K"
  /// - "ACTIVE_ADS_TIER_100K"
  /// - "ACTIVE_ADS_TIER_200K"
  /// - "ACTIVE_ADS_TIER_300K"
  /// - "ACTIVE_ADS_TIER_500K"
  /// - "ACTIVE_ADS_TIER_750K"
  /// - "ACTIVE_ADS_TIER_1M"
  core.String? activeAdsLimitTier;

  /// Whether to serve creatives with Active View tags.
  ///
  /// If disabled, viewability data will not be available for any impressions.
  core.bool? activeViewOptOut;

  /// User role permissions available to the user roles of this account.
  core.List<core.String>? availablePermissionIds;

  /// ID of the country associated with this account.
  core.String? countryId;

  /// ID of currency associated with this account.
  ///
  /// This is a required field. Acceptable values are: - "1" for USD - "2" for
  /// GBP - "3" for ESP - "4" for SEK - "5" for CAD - "6" for JPY - "7" for DEM
  /// - "8" for AUD - "9" for FRF - "10" for ITL - "11" for DKK - "12" for NOK -
  /// "13" for FIM - "14" for ZAR - "15" for IEP - "16" for NLG - "17" for EUR -
  /// "18" for KRW - "19" for TWD - "20" for SGD - "21" for CNY - "22" for HKD -
  /// "23" for NZD - "24" for MYR - "25" for BRL - "26" for PTE - "28" for CLP -
  /// "29" for TRY - "30" for ARS - "31" for PEN - "32" for ILS - "33" for CHF -
  /// "34" for VEF - "35" for COP - "36" for GTQ - "37" for PLN - "39" for INR -
  /// "40" for THB - "41" for IDR - "42" for CZK - "43" for RON - "44" for HUF -
  /// "45" for RUB - "46" for AED - "47" for BGN - "48" for HRK - "49" for MXN -
  /// "50" for NGN - "51" for EGP
  core.String? currencyId;

  /// Default placement dimensions for this account.
  core.String? defaultCreativeSizeId;

  /// Description of this account.
  core.String? description;

  /// ID of this account.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#account".
  core.String? kind;

  /// Locale of this account.
  ///
  /// Acceptable values are: - "cs" (Czech) - "de" (German) - "en" (English) -
  /// "en-GB" (English United Kingdom) - "es" (Spanish) - "fr" (French) - "it"
  /// (Italian) - "ja" (Japanese) - "ko" (Korean) - "pl" (Polish) - "pt-BR"
  /// (Portuguese Brazil) - "ru" (Russian) - "sv" (Swedish) - "tr" (Turkish) -
  /// "zh-CN" (Chinese Simplified) - "zh-TW" (Chinese Traditional)
  core.String? locale;

  /// Maximum image size allowed for this account, in kilobytes.
  ///
  /// Value must be greater than or equal to 1.
  core.String? maximumImageSize;

  /// Name of this account.
  ///
  /// This is a required field, and must be less than 128 characters long and be
  /// globally unique.
  core.String? name;

  /// Whether campaigns created in this account will be enabled for Nielsen OCR
  /// reach ratings by default.
  core.bool? nielsenOcrEnabled;

  /// Reporting configuration of this account.
  ReportsConfiguration? reportsConfiguration;

  /// Share Path to Conversion reports with Twitter.
  core.bool? shareReportsWithTwitter;

  /// File size limit in kilobytes of Rich Media teaser creatives.
  ///
  /// Acceptable values are 1 to 10240, inclusive.
  core.String? teaserSizeLimit;

  Account();

  Account.fromJson(core.Map _json) {
    if (_json.containsKey('accountPermissionIds')) {
      accountPermissionIds = (_json['accountPermissionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('accountProfile')) {
      accountProfile = _json['accountProfile'] as core.String;
    }
    if (_json.containsKey('active')) {
      active = _json['active'] as core.bool;
    }
    if (_json.containsKey('activeAdsLimitTier')) {
      activeAdsLimitTier = _json['activeAdsLimitTier'] as core.String;
    }
    if (_json.containsKey('activeViewOptOut')) {
      activeViewOptOut = _json['activeViewOptOut'] as core.bool;
    }
    if (_json.containsKey('availablePermissionIds')) {
      availablePermissionIds = (_json['availablePermissionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('countryId')) {
      countryId = _json['countryId'] as core.String;
    }
    if (_json.containsKey('currencyId')) {
      currencyId = _json['currencyId'] as core.String;
    }
    if (_json.containsKey('defaultCreativeSizeId')) {
      defaultCreativeSizeId = _json['defaultCreativeSizeId'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('locale')) {
      locale = _json['locale'] as core.String;
    }
    if (_json.containsKey('maximumImageSize')) {
      maximumImageSize = _json['maximumImageSize'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nielsenOcrEnabled')) {
      nielsenOcrEnabled = _json['nielsenOcrEnabled'] as core.bool;
    }
    if (_json.containsKey('reportsConfiguration')) {
      reportsConfiguration = ReportsConfiguration.fromJson(
          _json['reportsConfiguration'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shareReportsWithTwitter')) {
      shareReportsWithTwitter = _json['shareReportsWithTwitter'] as core.bool;
    }
    if (_json.containsKey('teaserSizeLimit')) {
      teaserSizeLimit = _json['teaserSizeLimit'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountPermissionIds != null)
          'accountPermissionIds': accountPermissionIds!,
        if (accountProfile != null) 'accountProfile': accountProfile!,
        if (active != null) 'active': active!,
        if (activeAdsLimitTier != null)
          'activeAdsLimitTier': activeAdsLimitTier!,
        if (activeViewOptOut != null) 'activeViewOptOut': activeViewOptOut!,
        if (availablePermissionIds != null)
          'availablePermissionIds': availablePermissionIds!,
        if (countryId != null) 'countryId': countryId!,
        if (currencyId != null) 'currencyId': currencyId!,
        if (defaultCreativeSizeId != null)
          'defaultCreativeSizeId': defaultCreativeSizeId!,
        if (description != null) 'description': description!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (locale != null) 'locale': locale!,
        if (maximumImageSize != null) 'maximumImageSize': maximumImageSize!,
        if (name != null) 'name': name!,
        if (nielsenOcrEnabled != null) 'nielsenOcrEnabled': nielsenOcrEnabled!,
        if (reportsConfiguration != null)
          'reportsConfiguration': reportsConfiguration!.toJson(),
        if (shareReportsWithTwitter != null)
          'shareReportsWithTwitter': shareReportsWithTwitter!,
        if (teaserSizeLimit != null) 'teaserSizeLimit': teaserSizeLimit!,
      };
}

/// Gets a summary of active ads in an account.
class AccountActiveAdSummary {
  /// ID of the account.
  core.String? accountId;

  /// Ads that have been activated for the account
  core.String? activeAds;

  /// Maximum number of active ads allowed for the account.
  /// Possible string values are:
  /// - "ACTIVE_ADS_TIER_40K"
  /// - "ACTIVE_ADS_TIER_75K"
  /// - "ACTIVE_ADS_TIER_100K"
  /// - "ACTIVE_ADS_TIER_200K"
  /// - "ACTIVE_ADS_TIER_300K"
  /// - "ACTIVE_ADS_TIER_500K"
  /// - "ACTIVE_ADS_TIER_750K"
  /// - "ACTIVE_ADS_TIER_1M"
  core.String? activeAdsLimitTier;

  /// Ads that can be activated for the account.
  core.String? availableAds;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#accountActiveAdSummary".
  core.String? kind;

  AccountActiveAdSummary();

  AccountActiveAdSummary.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('activeAds')) {
      activeAds = _json['activeAds'] as core.String;
    }
    if (_json.containsKey('activeAdsLimitTier')) {
      activeAdsLimitTier = _json['activeAdsLimitTier'] as core.String;
    }
    if (_json.containsKey('availableAds')) {
      availableAds = _json['availableAds'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (activeAds != null) 'activeAds': activeAds!,
        if (activeAdsLimitTier != null)
          'activeAdsLimitTier': activeAdsLimitTier!,
        if (availableAds != null) 'availableAds': availableAds!,
        if (kind != null) 'kind': kind!,
      };
}

/// AccountPermissions contains information about a particular account
/// permission.
///
/// Some features of Campaign Manager require an account permission to be
/// present in the account.
class AccountPermission {
  /// Account profiles associated with this account permission.
  ///
  /// Possible values are: - "ACCOUNT_PROFILE_BASIC" -
  /// "ACCOUNT_PROFILE_STANDARD"
  core.List<core.String>? accountProfiles;

  /// ID of this account permission.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#accountPermission".
  core.String? kind;

  /// Administrative level required to enable this account permission.
  /// Possible string values are:
  /// - "USER"
  /// - "ADMINISTRATOR"
  core.String? level;

  /// Name of this account permission.
  core.String? name;

  /// Permission group of this account permission.
  core.String? permissionGroupId;

  AccountPermission();

  AccountPermission.fromJson(core.Map _json) {
    if (_json.containsKey('accountProfiles')) {
      accountProfiles = (_json['accountProfiles'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('level')) {
      level = _json['level'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('permissionGroupId')) {
      permissionGroupId = _json['permissionGroupId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountProfiles != null) 'accountProfiles': accountProfiles!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (level != null) 'level': level!,
        if (name != null) 'name': name!,
        if (permissionGroupId != null) 'permissionGroupId': permissionGroupId!,
      };
}

/// AccountPermissionGroups contains a mapping of permission group IDs to names.
///
/// A permission group is a grouping of account permissions.
class AccountPermissionGroup {
  /// ID of this account permission group.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#accountPermissionGroup".
  core.String? kind;

  /// Name of this account permission group.
  core.String? name;

  AccountPermissionGroup();

  AccountPermissionGroup.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// Account Permission Group List Response
class AccountPermissionGroupsListResponse {
  /// Account permission group collection.
  core.List<AccountPermissionGroup>? accountPermissionGroups;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "dfareporting#accountPermissionGroupsListResponse".
  core.String? kind;

  AccountPermissionGroupsListResponse();

  AccountPermissionGroupsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accountPermissionGroups')) {
      accountPermissionGroups = (_json['accountPermissionGroups'] as core.List)
          .map<AccountPermissionGroup>((value) =>
              AccountPermissionGroup.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountPermissionGroups != null)
          'accountPermissionGroups':
              accountPermissionGroups!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Account Permission List Response
class AccountPermissionsListResponse {
  /// Account permission collection.
  core.List<AccountPermission>? accountPermissions;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#accountPermissionsListResponse".
  core.String? kind;

  AccountPermissionsListResponse();

  AccountPermissionsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accountPermissions')) {
      accountPermissions = (_json['accountPermissions'] as core.List)
          .map<AccountPermission>((value) => AccountPermission.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountPermissions != null)
          'accountPermissions':
              accountPermissions!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// AccountUserProfiles contains properties of a Campaign Manager user profile.
///
/// This resource is specifically for managing user profiles, whereas
/// UserProfiles is for accessing the API.
class AccountUserProfile {
  /// Account ID of the user profile.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// Whether this user profile is active.
  ///
  /// This defaults to false, and must be set true on insert for the user
  /// profile to be usable.
  core.bool? active;

  /// Filter that describes which advertisers are visible to the user profile.
  ObjectFilter? advertiserFilter;

  /// Filter that describes which campaigns are visible to the user profile.
  ObjectFilter? campaignFilter;

  /// Comments for this user profile.
  core.String? comments;

  /// Email of the user profile.
  ///
  /// The email addresss must be linked to a Google Account. This field is
  /// required on insertion and is read-only after insertion.
  core.String? email;

  /// ID of the user profile.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#accountUserProfile".
  core.String? kind;

  /// Locale of the user profile.
  ///
  /// This is a required field. Acceptable values are: - "cs" (Czech) - "de"
  /// (German) - "en" (English) - "en-GB" (English United Kingdom) - "es"
  /// (Spanish) - "fr" (French) - "it" (Italian) - "ja" (Japanese) - "ko"
  /// (Korean) - "pl" (Polish) - "pt-BR" (Portuguese Brazil) - "ru" (Russian) -
  /// "sv" (Swedish) - "tr" (Turkish) - "zh-CN" (Chinese Simplified) - "zh-TW"
  /// (Chinese Traditional)
  core.String? locale;

  /// Name of the user profile.
  ///
  /// This is a required field. Must be less than 64 characters long, must be
  /// globally unique, and cannot contain whitespace or any of the following
  /// characters: "&;<>"#%,".
  core.String? name;

  /// Filter that describes which sites are visible to the user profile.
  ObjectFilter? siteFilter;

  /// Subaccount ID of the user profile.
  ///
  /// This is a read-only field that can be left blank.
  core.String? subaccountId;

  /// Trafficker type of this user profile.
  ///
  /// This is a read-only field.
  /// Possible string values are:
  /// - "INTERNAL_NON_TRAFFICKER"
  /// - "INTERNAL_TRAFFICKER"
  /// - "EXTERNAL_TRAFFICKER"
  core.String? traffickerType;

  /// User type of the user profile.
  ///
  /// This is a read-only field that can be left blank.
  /// Possible string values are:
  /// - "NORMAL_USER"
  /// - "SUPER_USER"
  /// - "INTERNAL_ADMINISTRATOR"
  /// - "READ_ONLY_SUPER_USER"
  core.String? userAccessType;

  /// Filter that describes which user roles are visible to the user profile.
  ObjectFilter? userRoleFilter;

  /// User role ID of the user profile.
  ///
  /// This is a required field.
  core.String? userRoleId;

  AccountUserProfile();

  AccountUserProfile.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('active')) {
      active = _json['active'] as core.bool;
    }
    if (_json.containsKey('advertiserFilter')) {
      advertiserFilter = ObjectFilter.fromJson(
          _json['advertiserFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('campaignFilter')) {
      campaignFilter = ObjectFilter.fromJson(
          _json['campaignFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('comments')) {
      comments = _json['comments'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('locale')) {
      locale = _json['locale'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('siteFilter')) {
      siteFilter = ObjectFilter.fromJson(
          _json['siteFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('traffickerType')) {
      traffickerType = _json['traffickerType'] as core.String;
    }
    if (_json.containsKey('userAccessType')) {
      userAccessType = _json['userAccessType'] as core.String;
    }
    if (_json.containsKey('userRoleFilter')) {
      userRoleFilter = ObjectFilter.fromJson(
          _json['userRoleFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('userRoleId')) {
      userRoleId = _json['userRoleId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (active != null) 'active': active!,
        if (advertiserFilter != null)
          'advertiserFilter': advertiserFilter!.toJson(),
        if (campaignFilter != null) 'campaignFilter': campaignFilter!.toJson(),
        if (comments != null) 'comments': comments!,
        if (email != null) 'email': email!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (locale != null) 'locale': locale!,
        if (name != null) 'name': name!,
        if (siteFilter != null) 'siteFilter': siteFilter!.toJson(),
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (traffickerType != null) 'traffickerType': traffickerType!,
        if (userAccessType != null) 'userAccessType': userAccessType!,
        if (userRoleFilter != null) 'userRoleFilter': userRoleFilter!.toJson(),
        if (userRoleId != null) 'userRoleId': userRoleId!,
      };
}

/// Account User Profile List Response
class AccountUserProfilesListResponse {
  /// Account user profile collection.
  core.List<AccountUserProfile>? accountUserProfiles;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#accountUserProfilesListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  AccountUserProfilesListResponse();

  AccountUserProfilesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accountUserProfiles')) {
      accountUserProfiles = (_json['accountUserProfiles'] as core.List)
          .map<AccountUserProfile>((value) => AccountUserProfile.fromJson(
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
        if (accountUserProfiles != null)
          'accountUserProfiles':
              accountUserProfiles!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Account List Response
class AccountsListResponse {
  /// Account collection.
  core.List<Account>? accounts;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#accountsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  AccountsListResponse();

  AccountsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accounts')) {
      accounts = (_json['accounts'] as core.List)
          .map<Account>((value) =>
              Account.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (accounts != null)
          'accounts': accounts!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Represents an activity group.
class Activities {
  /// List of activity filters.
  ///
  /// The dimension values need to be all either of type "dfa:activity" or
  /// "dfa:activityGroup".
  core.List<DimensionValue>? filters;

  /// The kind of resource this is, in this case dfareporting#activities.
  core.String? kind;

  /// List of names of floodlight activity metrics.
  core.List<core.String>? metricNames;

  Activities();

  Activities.fromJson(core.Map _json) {
    if (_json.containsKey('filters')) {
      filters = (_json['filters'] as core.List)
          .map<DimensionValue>((value) => DimensionValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metricNames')) {
      metricNames = (_json['metricNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filters != null)
          'filters': filters!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (metricNames != null) 'metricNames': metricNames!,
      };
}

/// Contains properties of a Campaign Manager ad.
class Ad {
  /// Account ID of this ad.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// Whether this ad is active.
  ///
  /// When true, archived must be false.
  core.bool? active;

  /// Advertiser ID of this ad.
  ///
  /// This is a required field on insertion.
  core.String? advertiserId;

  /// Dimension value for the ID of the advertiser.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? advertiserIdDimensionValue;

  /// Whether this ad is archived.
  ///
  /// When true, active must be false.
  core.bool? archived;

  /// Audience segment ID that is being targeted for this ad.
  ///
  /// Applicable when type is AD_SERVING_STANDARD_AD.
  core.String? audienceSegmentId;

  /// Campaign ID of this ad.
  ///
  /// This is a required field on insertion.
  core.String? campaignId;

  /// Dimension value for the ID of the campaign.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? campaignIdDimensionValue;

  /// Click-through URL for this ad.
  ///
  /// This is a required field on insertion. Applicable when type is
  /// AD_SERVING_CLICK_TRACKER.
  ClickThroughUrl? clickThroughUrl;

  /// Click-through URL suffix properties for this ad.
  ///
  /// Applies to the URL in the ad or (if overriding ad properties) the URL in
  /// the creative.
  ClickThroughUrlSuffixProperties? clickThroughUrlSuffixProperties;

  /// Comments for this ad.
  core.String? comments;

  /// Compatibility of this ad.
  ///
  /// Applicable when type is AD_SERVING_DEFAULT_AD. DISPLAY and
  /// DISPLAY_INTERSTITIAL refer to either rendering on desktop or on mobile
  /// devices or in mobile apps for regular or interstitial ads, respectively.
  /// APP and APP_INTERSTITIAL are only used for existing default ads. New
  /// mobile placements must be assigned DISPLAY or DISPLAY_INTERSTITIAL and
  /// default ads created for those placements will be limited to those
  /// compatibility types. IN_STREAM_VIDEO refers to rendering in-stream video
  /// ads developed with the VAST standard.
  /// Possible string values are:
  /// - "DISPLAY"
  /// - "DISPLAY_INTERSTITIAL"
  /// - "APP"
  /// - "APP_INTERSTITIAL"
  /// - "IN_STREAM_VIDEO"
  /// - "IN_STREAM_AUDIO"
  core.String? compatibility;

  /// Information about the creation of this ad.
  ///
  /// This is a read-only field.
  LastModifiedInfo? createInfo;

  /// Creative group assignments for this ad.
  ///
  /// Applicable when type is AD_SERVING_CLICK_TRACKER. Only one assignment per
  /// creative group number is allowed for a maximum of two assignments.
  core.List<CreativeGroupAssignment>? creativeGroupAssignments;

  /// Creative rotation for this ad.
  ///
  /// Applicable when type is AD_SERVING_DEFAULT_AD, AD_SERVING_STANDARD_AD, or
  /// AD_SERVING_TRACKING. When type is AD_SERVING_DEFAULT_AD, this field should
  /// have exactly one creativeAssignment .
  CreativeRotation? creativeRotation;

  /// Time and day targeting information for this ad.
  ///
  /// This field must be left blank if the ad is using a targeting template.
  /// Applicable when type is AD_SERVING_STANDARD_AD.
  DayPartTargeting? dayPartTargeting;

  /// Default click-through event tag properties for this ad.
  DefaultClickThroughEventTagProperties? defaultClickThroughEventTagProperties;

  /// Delivery schedule information for this ad.
  ///
  /// Applicable when type is AD_SERVING_STANDARD_AD or AD_SERVING_TRACKING.
  /// This field along with subfields priority and impressionRatio are required
  /// on insertion when type is AD_SERVING_STANDARD_AD.
  DeliverySchedule? deliverySchedule;

  /// Whether this ad is a dynamic click tracker.
  ///
  /// Applicable when type is AD_SERVING_CLICK_TRACKER. This is a required field
  /// on insert, and is read-only after insert.
  core.bool? dynamicClickTracker;
  core.DateTime? endTime;

  /// Event tag overrides for this ad.
  core.List<EventTagOverride>? eventTagOverrides;

  /// Geographical targeting information for this ad.
  ///
  /// This field must be left blank if the ad is using a targeting template.
  /// Applicable when type is AD_SERVING_STANDARD_AD.
  GeoTargeting? geoTargeting;

  /// ID of this ad.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Dimension value for the ID of this ad.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? idDimensionValue;

  /// Key-value targeting information for this ad.
  ///
  /// This field must be left blank if the ad is using a targeting template.
  /// Applicable when type is AD_SERVING_STANDARD_AD.
  KeyValueTargetingExpression? keyValueTargetingExpression;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#ad".
  core.String? kind;

  /// Language targeting information for this ad.
  ///
  /// This field must be left blank if the ad is using a targeting template.
  /// Applicable when type is AD_SERVING_STANDARD_AD.
  LanguageTargeting? languageTargeting;

  /// Information about the most recent modification of this ad.
  ///
  /// This is a read-only field.
  LastModifiedInfo? lastModifiedInfo;

  /// Name of this ad.
  ///
  /// This is a required field and must be less than 256 characters long.
  core.String? name;

  /// Placement assignments for this ad.
  core.List<PlacementAssignment>? placementAssignments;

  /// Remarketing list targeting expression for this ad.
  ///
  /// This field must be left blank if the ad is using a targeting template.
  /// Applicable when type is AD_SERVING_STANDARD_AD.
  ListTargetingExpression? remarketingListExpression;

  /// Size of this ad.
  ///
  /// Applicable when type is AD_SERVING_DEFAULT_AD.
  Size? size;

  /// Whether this ad is ssl compliant.
  ///
  /// This is a read-only field that is auto-generated when the ad is inserted
  /// or updated.
  core.bool? sslCompliant;

  /// Whether this ad requires ssl.
  ///
  /// This is a read-only field that is auto-generated when the ad is inserted
  /// or updated.
  core.bool? sslRequired;
  core.DateTime? startTime;

  /// Subaccount ID of this ad.
  ///
  /// This is a read-only field that can be left blank.
  core.String? subaccountId;

  /// Targeting template ID, used to apply preconfigured targeting information
  /// to this ad.
  ///
  /// This cannot be set while any of dayPartTargeting, geoTargeting,
  /// keyValueTargetingExpression, languageTargeting, remarketingListExpression,
  /// or technologyTargeting are set. Applicable when type is
  /// AD_SERVING_STANDARD_AD.
  core.String? targetingTemplateId;

  /// Technology platform targeting information for this ad.
  ///
  /// This field must be left blank if the ad is using a targeting template.
  /// Applicable when type is AD_SERVING_STANDARD_AD.
  TechnologyTargeting? technologyTargeting;

  /// Type of ad.
  ///
  /// This is a required field on insertion. Note that default ads (
  /// AD_SERVING_DEFAULT_AD) cannot be created directly (see Creative resource).
  /// Possible string values are:
  /// - "AD_SERVING_STANDARD_AD"
  /// - "AD_SERVING_DEFAULT_AD"
  /// - "AD_SERVING_CLICK_TRACKER"
  /// - "AD_SERVING_TRACKING"
  /// - "AD_SERVING_BRAND_SAFE_AD"
  core.String? type;

  Ad();

  Ad.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('active')) {
      active = _json['active'] as core.bool;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('archived')) {
      archived = _json['archived'] as core.bool;
    }
    if (_json.containsKey('audienceSegmentId')) {
      audienceSegmentId = _json['audienceSegmentId'] as core.String;
    }
    if (_json.containsKey('campaignId')) {
      campaignId = _json['campaignId'] as core.String;
    }
    if (_json.containsKey('campaignIdDimensionValue')) {
      campaignIdDimensionValue = DimensionValue.fromJson(
          _json['campaignIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('clickThroughUrl')) {
      clickThroughUrl = ClickThroughUrl.fromJson(
          _json['clickThroughUrl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('clickThroughUrlSuffixProperties')) {
      clickThroughUrlSuffixProperties =
          ClickThroughUrlSuffixProperties.fromJson(
              _json['clickThroughUrlSuffixProperties']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('comments')) {
      comments = _json['comments'] as core.String;
    }
    if (_json.containsKey('compatibility')) {
      compatibility = _json['compatibility'] as core.String;
    }
    if (_json.containsKey('createInfo')) {
      createInfo = LastModifiedInfo.fromJson(
          _json['createInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('creativeGroupAssignments')) {
      creativeGroupAssignments =
          (_json['creativeGroupAssignments'] as core.List)
              .map<CreativeGroupAssignment>((value) =>
                  CreativeGroupAssignment.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('creativeRotation')) {
      creativeRotation = CreativeRotation.fromJson(
          _json['creativeRotation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dayPartTargeting')) {
      dayPartTargeting = DayPartTargeting.fromJson(
          _json['dayPartTargeting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('defaultClickThroughEventTagProperties')) {
      defaultClickThroughEventTagProperties =
          DefaultClickThroughEventTagProperties.fromJson(
              _json['defaultClickThroughEventTagProperties']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deliverySchedule')) {
      deliverySchedule = DeliverySchedule.fromJson(
          _json['deliverySchedule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dynamicClickTracker')) {
      dynamicClickTracker = _json['dynamicClickTracker'] as core.bool;
    }
    if (_json.containsKey('endTime')) {
      endTime = core.DateTime.parse(_json['endTime'] as core.String);
    }
    if (_json.containsKey('eventTagOverrides')) {
      eventTagOverrides = (_json['eventTagOverrides'] as core.List)
          .map<EventTagOverride>((value) => EventTagOverride.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('geoTargeting')) {
      geoTargeting = GeoTargeting.fromJson(
          _json['geoTargeting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('keyValueTargetingExpression')) {
      keyValueTargetingExpression = KeyValueTargetingExpression.fromJson(
          _json['keyValueTargetingExpression']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('languageTargeting')) {
      languageTargeting = LanguageTargeting.fromJson(
          _json['languageTargeting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lastModifiedInfo')) {
      lastModifiedInfo = LastModifiedInfo.fromJson(
          _json['lastModifiedInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('placementAssignments')) {
      placementAssignments = (_json['placementAssignments'] as core.List)
          .map<PlacementAssignment>((value) => PlacementAssignment.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('remarketingListExpression')) {
      remarketingListExpression = ListTargetingExpression.fromJson(
          _json['remarketingListExpression']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('size')) {
      size =
          Size.fromJson(_json['size'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sslCompliant')) {
      sslCompliant = _json['sslCompliant'] as core.bool;
    }
    if (_json.containsKey('sslRequired')) {
      sslRequired = _json['sslRequired'] as core.bool;
    }
    if (_json.containsKey('startTime')) {
      startTime = core.DateTime.parse(_json['startTime'] as core.String);
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('targetingTemplateId')) {
      targetingTemplateId = _json['targetingTemplateId'] as core.String;
    }
    if (_json.containsKey('technologyTargeting')) {
      technologyTargeting = TechnologyTargeting.fromJson(
          _json['technologyTargeting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (active != null) 'active': active!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (archived != null) 'archived': archived!,
        if (audienceSegmentId != null) 'audienceSegmentId': audienceSegmentId!,
        if (campaignId != null) 'campaignId': campaignId!,
        if (campaignIdDimensionValue != null)
          'campaignIdDimensionValue': campaignIdDimensionValue!.toJson(),
        if (clickThroughUrl != null)
          'clickThroughUrl': clickThroughUrl!.toJson(),
        if (clickThroughUrlSuffixProperties != null)
          'clickThroughUrlSuffixProperties':
              clickThroughUrlSuffixProperties!.toJson(),
        if (comments != null) 'comments': comments!,
        if (compatibility != null) 'compatibility': compatibility!,
        if (createInfo != null) 'createInfo': createInfo!.toJson(),
        if (creativeGroupAssignments != null)
          'creativeGroupAssignments':
              creativeGroupAssignments!.map((value) => value.toJson()).toList(),
        if (creativeRotation != null)
          'creativeRotation': creativeRotation!.toJson(),
        if (dayPartTargeting != null)
          'dayPartTargeting': dayPartTargeting!.toJson(),
        if (defaultClickThroughEventTagProperties != null)
          'defaultClickThroughEventTagProperties':
              defaultClickThroughEventTagProperties!.toJson(),
        if (deliverySchedule != null)
          'deliverySchedule': deliverySchedule!.toJson(),
        if (dynamicClickTracker != null)
          'dynamicClickTracker': dynamicClickTracker!,
        if (endTime != null) 'endTime': endTime!.toIso8601String(),
        if (eventTagOverrides != null)
          'eventTagOverrides':
              eventTagOverrides!.map((value) => value.toJson()).toList(),
        if (geoTargeting != null) 'geoTargeting': geoTargeting!.toJson(),
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (keyValueTargetingExpression != null)
          'keyValueTargetingExpression': keyValueTargetingExpression!.toJson(),
        if (kind != null) 'kind': kind!,
        if (languageTargeting != null)
          'languageTargeting': languageTargeting!.toJson(),
        if (lastModifiedInfo != null)
          'lastModifiedInfo': lastModifiedInfo!.toJson(),
        if (name != null) 'name': name!,
        if (placementAssignments != null)
          'placementAssignments':
              placementAssignments!.map((value) => value.toJson()).toList(),
        if (remarketingListExpression != null)
          'remarketingListExpression': remarketingListExpression!.toJson(),
        if (size != null) 'size': size!.toJson(),
        if (sslCompliant != null) 'sslCompliant': sslCompliant!,
        if (sslRequired != null) 'sslRequired': sslRequired!,
        if (startTime != null) 'startTime': startTime!.toIso8601String(),
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (targetingTemplateId != null)
          'targetingTemplateId': targetingTemplateId!,
        if (technologyTargeting != null)
          'technologyTargeting': technologyTargeting!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// Campaign ad blocking settings.
class AdBlockingConfiguration {
  /// Click-through URL used by brand-neutral ads.
  ///
  /// This is a required field when overrideClickThroughUrl is set to true.
  core.String? clickThroughUrl;

  /// ID of a creative bundle to use for this campaign.
  ///
  /// If set, brand-neutral ads will select creatives from this bundle.
  /// Otherwise, a default transparent pixel will be used.
  core.String? creativeBundleId;

  /// Whether this campaign has enabled ad blocking.
  ///
  /// When true, ad blocking is enabled for placements in the campaign, but this
  /// may be overridden by site and placement settings. When false, ad blocking
  /// is disabled for all placements under the campaign, regardless of site and
  /// placement settings.
  core.bool? enabled;

  /// Whether the brand-neutral ad's click-through URL comes from the campaign's
  /// creative bundle or the override URL.
  ///
  /// Must be set to true if ad blocking is enabled and no creative bundle is
  /// configured.
  core.bool? overrideClickThroughUrl;

  AdBlockingConfiguration();

  AdBlockingConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('clickThroughUrl')) {
      clickThroughUrl = _json['clickThroughUrl'] as core.String;
    }
    if (_json.containsKey('creativeBundleId')) {
      creativeBundleId = _json['creativeBundleId'] as core.String;
    }
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
    if (_json.containsKey('overrideClickThroughUrl')) {
      overrideClickThroughUrl = _json['overrideClickThroughUrl'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clickThroughUrl != null) 'clickThroughUrl': clickThroughUrl!,
        if (creativeBundleId != null) 'creativeBundleId': creativeBundleId!,
        if (enabled != null) 'enabled': enabled!,
        if (overrideClickThroughUrl != null)
          'overrideClickThroughUrl': overrideClickThroughUrl!,
      };
}

/// Ad Slot
class AdSlot {
  /// Comment for this ad slot.
  core.String? comment;

  /// Ad slot compatibility.
  ///
  /// DISPLAY and DISPLAY_INTERSTITIAL refer to rendering either on desktop,
  /// mobile devices or in mobile apps for regular or interstitial ads
  /// respectively. APP and APP_INTERSTITIAL are for rendering in mobile apps.
  /// IN_STREAM_VIDEO refers to rendering in in-stream video ads developed with
  /// the VAST standard.
  /// Possible string values are:
  /// - "DISPLAY"
  /// - "DISPLAY_INTERSTITIAL"
  /// - "APP"
  /// - "APP_INTERSTITIAL"
  /// - "IN_STREAM_VIDEO"
  /// - "IN_STREAM_AUDIO"
  core.String? compatibility;

  /// Height of this ad slot.
  core.String? height;

  /// ID of the placement from an external platform that is linked to this ad
  /// slot.
  core.String? linkedPlacementId;

  /// Name of this ad slot.
  core.String? name;

  /// Payment source type of this ad slot.
  /// Possible string values are:
  /// - "PLANNING_PAYMENT_SOURCE_TYPE_AGENCY_PAID"
  /// - "PLANNING_PAYMENT_SOURCE_TYPE_PUBLISHER_PAID"
  core.String? paymentSourceType;

  /// Primary ad slot of a roadblock inventory item.
  core.bool? primary;

  /// Width of this ad slot.
  core.String? width;

  AdSlot();

  AdSlot.fromJson(core.Map _json) {
    if (_json.containsKey('comment')) {
      comment = _json['comment'] as core.String;
    }
    if (_json.containsKey('compatibility')) {
      compatibility = _json['compatibility'] as core.String;
    }
    if (_json.containsKey('height')) {
      height = _json['height'] as core.String;
    }
    if (_json.containsKey('linkedPlacementId')) {
      linkedPlacementId = _json['linkedPlacementId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('paymentSourceType')) {
      paymentSourceType = _json['paymentSourceType'] as core.String;
    }
    if (_json.containsKey('primary')) {
      primary = _json['primary'] as core.bool;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (comment != null) 'comment': comment!,
        if (compatibility != null) 'compatibility': compatibility!,
        if (height != null) 'height': height!,
        if (linkedPlacementId != null) 'linkedPlacementId': linkedPlacementId!,
        if (name != null) 'name': name!,
        if (paymentSourceType != null) 'paymentSourceType': paymentSourceType!,
        if (primary != null) 'primary': primary!,
        if (width != null) 'width': width!,
      };
}

/// Ad List Response
class AdsListResponse {
  /// Ad collection.
  core.List<Ad>? ads;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#adsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  AdsListResponse();

  AdsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('ads')) {
      ads = (_json['ads'] as core.List)
          .map<Ad>((value) =>
              Ad.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (ads != null) 'ads': ads!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Contains properties of a Campaign Manager advertiser.
class Advertiser {
  /// Account ID of this advertiser.This is a read-only field that can be left
  /// blank.
  core.String? accountId;

  /// ID of the advertiser group this advertiser belongs to.
  ///
  /// You can group advertisers for reporting purposes, allowing you to see
  /// aggregated information for all advertisers in each group.
  core.String? advertiserGroupId;

  /// Suffix added to click-through URL of ad creative associations under this
  /// advertiser.
  ///
  /// Must be less than 129 characters long.
  core.String? clickThroughUrlSuffix;

  /// ID of the click-through event tag to apply by default to the landing pages
  /// of this advertiser's campaigns.
  core.String? defaultClickThroughEventTagId;

  /// Default email address used in sender field for tag emails.
  core.String? defaultEmail;

  /// Floodlight configuration ID of this advertiser.
  ///
  /// The floodlight configuration ID will be created automatically, so on
  /// insert this field should be left blank. This field can be set to another
  /// advertiser's floodlight configuration ID in order to share that
  /// advertiser's floodlight configuration with this advertiser, so long as: -
  /// This advertiser's original floodlight configuration is not already
  /// associated with floodlight activities or floodlight activity groups. -
  /// This advertiser's original floodlight configuration is not already shared
  /// with another advertiser.
  core.String? floodlightConfigurationId;

  /// Dimension value for the ID of the floodlight configuration.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? floodlightConfigurationIdDimensionValue;

  /// ID of this advertiser.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Dimension value for the ID of this advertiser.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? idDimensionValue;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#advertiser".
  core.String? kind;

  /// Name of this advertiser.
  ///
  /// This is a required field and must be less than 256 characters long and
  /// unique among advertisers of the same account.
  core.String? name;

  /// Original floodlight configuration before any sharing occurred.
  ///
  /// Set the floodlightConfigurationId of this advertiser to
  /// originalFloodlightConfigurationId to unshare the advertiser's current
  /// floodlight configuration. You cannot unshare an advertiser's floodlight
  /// configuration if the shared configuration has activities associated with
  /// any campaign or placement.
  core.String? originalFloodlightConfigurationId;

  /// Status of this advertiser.
  /// Possible string values are:
  /// - "APPROVED"
  /// - "ON_HOLD"
  core.String? status;

  /// Subaccount ID of this advertiser.This is a read-only field that can be
  /// left blank.
  core.String? subaccountId;

  /// Suspension status of this advertiser.
  core.bool? suspended;

  Advertiser();

  Advertiser.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('advertiserGroupId')) {
      advertiserGroupId = _json['advertiserGroupId'] as core.String;
    }
    if (_json.containsKey('clickThroughUrlSuffix')) {
      clickThroughUrlSuffix = _json['clickThroughUrlSuffix'] as core.String;
    }
    if (_json.containsKey('defaultClickThroughEventTagId')) {
      defaultClickThroughEventTagId =
          _json['defaultClickThroughEventTagId'] as core.String;
    }
    if (_json.containsKey('defaultEmail')) {
      defaultEmail = _json['defaultEmail'] as core.String;
    }
    if (_json.containsKey('floodlightConfigurationId')) {
      floodlightConfigurationId =
          _json['floodlightConfigurationId'] as core.String;
    }
    if (_json.containsKey('floodlightConfigurationIdDimensionValue')) {
      floodlightConfigurationIdDimensionValue = DimensionValue.fromJson(
          _json['floodlightConfigurationIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('originalFloodlightConfigurationId')) {
      originalFloodlightConfigurationId =
          _json['originalFloodlightConfigurationId'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('suspended')) {
      suspended = _json['suspended'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiserGroupId != null) 'advertiserGroupId': advertiserGroupId!,
        if (clickThroughUrlSuffix != null)
          'clickThroughUrlSuffix': clickThroughUrlSuffix!,
        if (defaultClickThroughEventTagId != null)
          'defaultClickThroughEventTagId': defaultClickThroughEventTagId!,
        if (defaultEmail != null) 'defaultEmail': defaultEmail!,
        if (floodlightConfigurationId != null)
          'floodlightConfigurationId': floodlightConfigurationId!,
        if (floodlightConfigurationIdDimensionValue != null)
          'floodlightConfigurationIdDimensionValue':
              floodlightConfigurationIdDimensionValue!.toJson(),
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (originalFloodlightConfigurationId != null)
          'originalFloodlightConfigurationId':
              originalFloodlightConfigurationId!,
        if (status != null) 'status': status!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (suspended != null) 'suspended': suspended!,
      };
}

/// Groups advertisers together so that reports can be generated for the entire
/// group at once.
class AdvertiserGroup {
  /// Account ID of this advertiser group.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// ID of this advertiser group.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#advertiserGroup".
  core.String? kind;

  /// Name of this advertiser group.
  ///
  /// This is a required field and must be less than 256 characters long and
  /// unique among advertiser groups of the same account.
  core.String? name;

  AdvertiserGroup();

  AdvertiserGroup.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// Advertiser Group List Response
class AdvertiserGroupsListResponse {
  /// Advertiser group collection.
  core.List<AdvertiserGroup>? advertiserGroups;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#advertiserGroupsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  AdvertiserGroupsListResponse();

  AdvertiserGroupsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserGroups')) {
      advertiserGroups = (_json['advertiserGroups'] as core.List)
          .map<AdvertiserGroup>((value) => AdvertiserGroup.fromJson(
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
        if (advertiserGroups != null)
          'advertiserGroups':
              advertiserGroups!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Landing Page List Response
class AdvertiserLandingPagesListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#advertiserLandingPagesListResponse".
  core.String? kind;

  /// Landing page collection
  core.List<LandingPage>? landingPages;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  AdvertiserLandingPagesListResponse();

  AdvertiserLandingPagesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('landingPages')) {
      landingPages = (_json['landingPages'] as core.List)
          .map<LandingPage>((value) => LandingPage.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (landingPages != null)
          'landingPages': landingPages!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Advertiser List Response
class AdvertisersListResponse {
  /// Advertiser collection.
  core.List<Advertiser>? advertisers;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#advertisersListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  AdvertisersListResponse();

  AdvertisersListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('advertisers')) {
      advertisers = (_json['advertisers'] as core.List)
          .map<Advertiser>((value) =>
              Advertiser.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (advertisers != null)
          'advertisers': advertisers!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Audience Segment.
class AudienceSegment {
  /// Weight allocated to this segment.
  ///
  /// The weight assigned will be understood in proportion to the weights
  /// assigned to other segments in the same segment group. Acceptable values
  /// are 1 to 1000, inclusive.
  core.int? allocation;

  /// ID of this audience segment.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Name of this audience segment.
  ///
  /// This is a required field and must be less than 65 characters long.
  core.String? name;

  AudienceSegment();

  AudienceSegment.fromJson(core.Map _json) {
    if (_json.containsKey('allocation')) {
      allocation = _json['allocation'] as core.int;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allocation != null) 'allocation': allocation!,
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
      };
}

/// Audience Segment Group.
class AudienceSegmentGroup {
  /// Audience segments assigned to this group.
  ///
  /// The number of segments must be between 2 and 100.
  core.List<AudienceSegment>? audienceSegments;

  /// ID of this audience segment group.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Name of this audience segment group.
  ///
  /// This is a required field and must be less than 65 characters long.
  core.String? name;

  AudienceSegmentGroup();

  AudienceSegmentGroup.fromJson(core.Map _json) {
    if (_json.containsKey('audienceSegments')) {
      audienceSegments = (_json['audienceSegments'] as core.List)
          .map<AudienceSegment>((value) => AudienceSegment.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audienceSegments != null)
          'audienceSegments':
              audienceSegments!.map((value) => value.toJson()).toList(),
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
      };
}

/// Contains information about a browser that can be targeted by ads.
class Browser {
  /// ID referring to this grouping of browser and version numbers.
  ///
  /// This is the ID used for targeting.
  core.String? browserVersionId;

  /// DART ID of this browser.
  ///
  /// This is the ID used when generating reports.
  core.String? dartId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#browser".
  core.String? kind;

  /// Major version number (leftmost number) of this browser.
  ///
  /// For example, for Chrome 5.0.376.86 beta, this field should be set to 5. An
  /// asterisk (*) may be used to target any version number, and a question mark
  /// (?) may be used to target cases where the version number cannot be
  /// identified. For example, Chrome *.* targets any version of Chrome: 1.2,
  /// 2.5, 3.5, and so on. Chrome 3.* targets Chrome 3.1, 3.5, but not 4.0.
  /// Firefox ?.? targets cases where the ad server knows the browser is Firefox
  /// but can't tell which version it is.
  core.String? majorVersion;

  /// Minor version number (number after first dot on left) of this browser.
  ///
  /// For example, for Chrome 5.0.375.86 beta, this field should be set to 0. An
  /// asterisk (*) may be used to target any version number, and a question mark
  /// (?) may be used to target cases where the version number cannot be
  /// identified. For example, Chrome *.* targets any version of Chrome: 1.2,
  /// 2.5, 3.5, and so on. Chrome 3.* targets Chrome 3.1, 3.5, but not 4.0.
  /// Firefox ?.? targets cases where the ad server knows the browser is Firefox
  /// but can't tell which version it is.
  core.String? minorVersion;

  /// Name of this browser.
  core.String? name;

  Browser();

  Browser.fromJson(core.Map _json) {
    if (_json.containsKey('browserVersionId')) {
      browserVersionId = _json['browserVersionId'] as core.String;
    }
    if (_json.containsKey('dartId')) {
      dartId = _json['dartId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('majorVersion')) {
      majorVersion = _json['majorVersion'] as core.String;
    }
    if (_json.containsKey('minorVersion')) {
      minorVersion = _json['minorVersion'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (browserVersionId != null) 'browserVersionId': browserVersionId!,
        if (dartId != null) 'dartId': dartId!,
        if (kind != null) 'kind': kind!,
        if (majorVersion != null) 'majorVersion': majorVersion!,
        if (minorVersion != null) 'minorVersion': minorVersion!,
        if (name != null) 'name': name!,
      };
}

/// Browser List Response
class BrowsersListResponse {
  /// Browser collection.
  core.List<Browser>? browsers;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#browsersListResponse".
  core.String? kind;

  BrowsersListResponse();

  BrowsersListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('browsers')) {
      browsers = (_json['browsers'] as core.List)
          .map<Browser>((value) =>
              Browser.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (browsers != null)
          'browsers': browsers!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Contains properties of a Campaign Manager campaign.
class Campaign {
  /// Account ID of this campaign.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// Ad blocking settings for this campaign.
  AdBlockingConfiguration? adBlockingConfiguration;

  /// Additional creative optimization configurations for the campaign.
  core.List<CreativeOptimizationConfiguration>?
      additionalCreativeOptimizationConfigurations;

  /// Advertiser group ID of the associated advertiser.
  core.String? advertiserGroupId;

  /// Advertiser ID of this campaign.
  ///
  /// This is a required field.
  core.String? advertiserId;

  /// Dimension value for the advertiser ID of this campaign.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? advertiserIdDimensionValue;

  /// Whether this campaign has been archived.
  core.bool? archived;

  /// Audience segment groups assigned to this campaign.
  ///
  /// Cannot have more than 300 segment groups.
  core.List<AudienceSegmentGroup>? audienceSegmentGroups;

  /// Billing invoice code included in the Campaign Manager client billing
  /// invoices associated with the campaign.
  core.String? billingInvoiceCode;

  /// Click-through URL suffix override properties for this campaign.
  ClickThroughUrlSuffixProperties? clickThroughUrlSuffixProperties;

  /// Arbitrary comments about this campaign.
  ///
  /// Must be less than 256 characters long.
  core.String? comment;

  /// Information about the creation of this campaign.
  ///
  /// This is a read-only field.
  LastModifiedInfo? createInfo;

  /// List of creative group IDs that are assigned to the campaign.
  core.List<core.String>? creativeGroupIds;

  /// Creative optimization configuration for the campaign.
  CreativeOptimizationConfiguration? creativeOptimizationConfiguration;

  /// Click-through event tag ID override properties for this campaign.
  DefaultClickThroughEventTagProperties? defaultClickThroughEventTagProperties;

  /// The default landing page ID for this campaign.
  core.String? defaultLandingPageId;
  core.DateTime? endDate;

  /// Overrides that can be used to activate or deactivate advertiser event
  /// tags.
  core.List<EventTagOverride>? eventTagOverrides;

  /// External ID for this campaign.
  core.String? externalId;

  /// ID of this campaign.
  ///
  /// This is a read-only auto-generated field.
  core.String? id;

  /// Dimension value for the ID of this campaign.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? idDimensionValue;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#campaign".
  core.String? kind;

  /// Information about the most recent modification of this campaign.
  ///
  /// This is a read-only field.
  LastModifiedInfo? lastModifiedInfo;

  /// Name of this campaign.
  ///
  /// This is a required field and must be less than 256 characters long and
  /// unique among campaigns of the same advertiser.
  core.String? name;

  /// Whether Nielsen reports are enabled for this campaign.
  core.bool? nielsenOcrEnabled;
  core.DateTime? startDate;

  /// Subaccount ID of this campaign.
  ///
  /// This is a read-only field that can be left blank.
  core.String? subaccountId;

  /// Campaign trafficker contact emails.
  core.List<core.String>? traffickerEmails;

  Campaign();

  Campaign.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('adBlockingConfiguration')) {
      adBlockingConfiguration = AdBlockingConfiguration.fromJson(
          _json['adBlockingConfiguration']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('additionalCreativeOptimizationConfigurations')) {
      additionalCreativeOptimizationConfigurations =
          (_json['additionalCreativeOptimizationConfigurations'] as core.List)
              .map<CreativeOptimizationConfiguration>((value) =>
                  CreativeOptimizationConfiguration.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('advertiserGroupId')) {
      advertiserGroupId = _json['advertiserGroupId'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('archived')) {
      archived = _json['archived'] as core.bool;
    }
    if (_json.containsKey('audienceSegmentGroups')) {
      audienceSegmentGroups = (_json['audienceSegmentGroups'] as core.List)
          .map<AudienceSegmentGroup>((value) => AudienceSegmentGroup.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('billingInvoiceCode')) {
      billingInvoiceCode = _json['billingInvoiceCode'] as core.String;
    }
    if (_json.containsKey('clickThroughUrlSuffixProperties')) {
      clickThroughUrlSuffixProperties =
          ClickThroughUrlSuffixProperties.fromJson(
              _json['clickThroughUrlSuffixProperties']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('comment')) {
      comment = _json['comment'] as core.String;
    }
    if (_json.containsKey('createInfo')) {
      createInfo = LastModifiedInfo.fromJson(
          _json['createInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('creativeGroupIds')) {
      creativeGroupIds = (_json['creativeGroupIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('creativeOptimizationConfiguration')) {
      creativeOptimizationConfiguration =
          CreativeOptimizationConfiguration.fromJson(
              _json['creativeOptimizationConfiguration']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('defaultClickThroughEventTagProperties')) {
      defaultClickThroughEventTagProperties =
          DefaultClickThroughEventTagProperties.fromJson(
              _json['defaultClickThroughEventTagProperties']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('defaultLandingPageId')) {
      defaultLandingPageId = _json['defaultLandingPageId'] as core.String;
    }
    if (_json.containsKey('endDate')) {
      endDate = core.DateTime.parse(_json['endDate'] as core.String);
    }
    if (_json.containsKey('eventTagOverrides')) {
      eventTagOverrides = (_json['eventTagOverrides'] as core.List)
          .map<EventTagOverride>((value) => EventTagOverride.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('externalId')) {
      externalId = _json['externalId'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifiedInfo')) {
      lastModifiedInfo = LastModifiedInfo.fromJson(
          _json['lastModifiedInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nielsenOcrEnabled')) {
      nielsenOcrEnabled = _json['nielsenOcrEnabled'] as core.bool;
    }
    if (_json.containsKey('startDate')) {
      startDate = core.DateTime.parse(_json['startDate'] as core.String);
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('traffickerEmails')) {
      traffickerEmails = (_json['traffickerEmails'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (adBlockingConfiguration != null)
          'adBlockingConfiguration': adBlockingConfiguration!.toJson(),
        if (additionalCreativeOptimizationConfigurations != null)
          'additionalCreativeOptimizationConfigurations':
              additionalCreativeOptimizationConfigurations!
                  .map((value) => value.toJson())
                  .toList(),
        if (advertiserGroupId != null) 'advertiserGroupId': advertiserGroupId!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (archived != null) 'archived': archived!,
        if (audienceSegmentGroups != null)
          'audienceSegmentGroups':
              audienceSegmentGroups!.map((value) => value.toJson()).toList(),
        if (billingInvoiceCode != null)
          'billingInvoiceCode': billingInvoiceCode!,
        if (clickThroughUrlSuffixProperties != null)
          'clickThroughUrlSuffixProperties':
              clickThroughUrlSuffixProperties!.toJson(),
        if (comment != null) 'comment': comment!,
        if (createInfo != null) 'createInfo': createInfo!.toJson(),
        if (creativeGroupIds != null) 'creativeGroupIds': creativeGroupIds!,
        if (creativeOptimizationConfiguration != null)
          'creativeOptimizationConfiguration':
              creativeOptimizationConfiguration!.toJson(),
        if (defaultClickThroughEventTagProperties != null)
          'defaultClickThroughEventTagProperties':
              defaultClickThroughEventTagProperties!.toJson(),
        if (defaultLandingPageId != null)
          'defaultLandingPageId': defaultLandingPageId!,
        if (endDate != null)
          'endDate':
              "${(endDate!).year.toString().padLeft(4, '0')}-${(endDate!).month.toString().padLeft(2, '0')}-${(endDate!).day.toString().padLeft(2, '0')}",
        if (eventTagOverrides != null)
          'eventTagOverrides':
              eventTagOverrides!.map((value) => value.toJson()).toList(),
        if (externalId != null) 'externalId': externalId!,
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (kind != null) 'kind': kind!,
        if (lastModifiedInfo != null)
          'lastModifiedInfo': lastModifiedInfo!.toJson(),
        if (name != null) 'name': name!,
        if (nielsenOcrEnabled != null) 'nielsenOcrEnabled': nielsenOcrEnabled!,
        if (startDate != null)
          'startDate':
              "${(startDate!).year.toString().padLeft(4, '0')}-${(startDate!).month.toString().padLeft(2, '0')}-${(startDate!).day.toString().padLeft(2, '0')}",
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (traffickerEmails != null) 'traffickerEmails': traffickerEmails!,
      };
}

/// Identifies a creative which has been associated with a given campaign.
class CampaignCreativeAssociation {
  /// ID of the creative associated with the campaign.
  ///
  /// This is a required field.
  core.String? creativeId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#campaignCreativeAssociation".
  core.String? kind;

  CampaignCreativeAssociation();

  CampaignCreativeAssociation.fromJson(core.Map _json) {
    if (_json.containsKey('creativeId')) {
      creativeId = _json['creativeId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creativeId != null) 'creativeId': creativeId!,
        if (kind != null) 'kind': kind!,
      };
}

/// Campaign Creative Association List Response
class CampaignCreativeAssociationsListResponse {
  /// Campaign creative association collection
  core.List<CampaignCreativeAssociation>? campaignCreativeAssociations;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "dfareporting#campaignCreativeAssociationsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  CampaignCreativeAssociationsListResponse();

  CampaignCreativeAssociationsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('campaignCreativeAssociations')) {
      campaignCreativeAssociations =
          (_json['campaignCreativeAssociations'] as core.List)
              .map<CampaignCreativeAssociation>((value) =>
                  CampaignCreativeAssociation.fromJson(
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
        if (campaignCreativeAssociations != null)
          'campaignCreativeAssociations': campaignCreativeAssociations!
              .map((value) => value.toJson())
              .toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Campaign Manager IDs related to the custom event.
class CampaignManagerIds {
  /// Ad ID for Campaign Manager.
  core.String? adId;

  /// Campaign ID for Campaign Manager.
  core.String? campaignId;

  /// Creative ID for Campaign Manager.
  core.String? creativeId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#campaignManagerIds".
  core.String? kind;

  /// Placement ID for Campaign Manager.
  core.String? placementId;

  /// Site ID for Campaign Manager.
  core.String? siteId;

  CampaignManagerIds();

  CampaignManagerIds.fromJson(core.Map _json) {
    if (_json.containsKey('adId')) {
      adId = _json['adId'] as core.String;
    }
    if (_json.containsKey('campaignId')) {
      campaignId = _json['campaignId'] as core.String;
    }
    if (_json.containsKey('creativeId')) {
      creativeId = _json['creativeId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('placementId')) {
      placementId = _json['placementId'] as core.String;
    }
    if (_json.containsKey('siteId')) {
      siteId = _json['siteId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adId != null) 'adId': adId!,
        if (campaignId != null) 'campaignId': campaignId!,
        if (creativeId != null) 'creativeId': creativeId!,
        if (kind != null) 'kind': kind!,
        if (placementId != null) 'placementId': placementId!,
        if (siteId != null) 'siteId': siteId!,
      };
}

/// Campaign List Response
class CampaignsListResponse {
  /// Campaign collection.
  core.List<Campaign>? campaigns;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#campaignsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  CampaignsListResponse();

  CampaignsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('campaigns')) {
      campaigns = (_json['campaigns'] as core.List)
          .map<Campaign>((value) =>
              Campaign.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (campaigns != null)
          'campaigns': campaigns!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Describes a change that a user has made to a resource.
class ChangeLog {
  /// Account ID of the modified object.
  core.String? accountId;

  /// Action which caused the change.
  core.String? action;
  core.DateTime? changeTime;

  /// Field name of the object which changed.
  core.String? fieldName;

  /// ID of this change log.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#changeLog".
  core.String? kind;

  /// New value of the object field.
  core.String? newValue;

  /// ID of the object of this change log.
  ///
  /// The object could be a campaign, placement, ad, or other type.
  core.String? objectId;

  /// Object type of the change log.
  core.String? objectType;

  /// Old value of the object field.
  core.String? oldValue;

  /// Subaccount ID of the modified object.
  core.String? subaccountId;

  /// Transaction ID of this change log.
  ///
  /// When a single API call results in many changes, each change will have a
  /// separate ID in the change log but will share the same transactionId.
  core.String? transactionId;

  /// ID of the user who modified the object.
  core.String? userProfileId;

  /// User profile name of the user who modified the object.
  core.String? userProfileName;

  ChangeLog();

  ChangeLog.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('changeTime')) {
      changeTime = core.DateTime.parse(_json['changeTime'] as core.String);
    }
    if (_json.containsKey('fieldName')) {
      fieldName = _json['fieldName'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('newValue')) {
      newValue = _json['newValue'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('objectType')) {
      objectType = _json['objectType'] as core.String;
    }
    if (_json.containsKey('oldValue')) {
      oldValue = _json['oldValue'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('transactionId')) {
      transactionId = _json['transactionId'] as core.String;
    }
    if (_json.containsKey('userProfileId')) {
      userProfileId = _json['userProfileId'] as core.String;
    }
    if (_json.containsKey('userProfileName')) {
      userProfileName = _json['userProfileName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (action != null) 'action': action!,
        if (changeTime != null) 'changeTime': changeTime!.toIso8601String(),
        if (fieldName != null) 'fieldName': fieldName!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (newValue != null) 'newValue': newValue!,
        if (objectId != null) 'objectId': objectId!,
        if (objectType != null) 'objectType': objectType!,
        if (oldValue != null) 'oldValue': oldValue!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (transactionId != null) 'transactionId': transactionId!,
        if (userProfileId != null) 'userProfileId': userProfileId!,
        if (userProfileName != null) 'userProfileName': userProfileName!,
      };
}

/// Change Log List Response
class ChangeLogsListResponse {
  /// Change log collection.
  core.List<ChangeLog>? changeLogs;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#changeLogsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  ChangeLogsListResponse();

  ChangeLogsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('changeLogs')) {
      changeLogs = (_json['changeLogs'] as core.List)
          .map<ChangeLog>((value) =>
              ChangeLog.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (changeLogs != null)
          'changeLogs': changeLogs!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Represents a DfaReporting channel grouping.
class ChannelGrouping {
  /// ChannelGrouping fallback name.
  core.String? fallbackName;

  /// The kind of resource this is, in this case dfareporting#channelGrouping.
  core.String? kind;

  /// ChannelGrouping name.
  core.String? name;

  /// The rules contained within this channel grouping.
  core.List<ChannelGroupingRule>? rules;

  ChannelGrouping();

  ChannelGrouping.fromJson(core.Map _json) {
    if (_json.containsKey('fallbackName')) {
      fallbackName = _json['fallbackName'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('rules')) {
      rules = (_json['rules'] as core.List)
          .map<ChannelGroupingRule>((value) => ChannelGroupingRule.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fallbackName != null) 'fallbackName': fallbackName!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (rules != null)
          'rules': rules!.map((value) => value.toJson()).toList(),
      };
}

/// Represents a DfaReporting channel grouping rule.
class ChannelGroupingRule {
  /// The disjunctive match statements contained within this rule.
  core.List<DisjunctiveMatchStatement>? disjunctiveMatchStatements;

  /// The kind of resource this is, in this case
  /// dfareporting#channelGroupingRule.
  core.String? kind;

  /// Rule name.
  core.String? name;

  ChannelGroupingRule();

  ChannelGroupingRule.fromJson(core.Map _json) {
    if (_json.containsKey('disjunctiveMatchStatements')) {
      disjunctiveMatchStatements =
          (_json['disjunctiveMatchStatements'] as core.List)
              .map<DisjunctiveMatchStatement>((value) =>
                  DisjunctiveMatchStatement.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disjunctiveMatchStatements != null)
          'disjunctiveMatchStatements': disjunctiveMatchStatements!
              .map((value) => value.toJson())
              .toList(),
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// City List Response
class CitiesListResponse {
  /// City collection.
  core.List<City>? cities;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#citiesListResponse".
  core.String? kind;

  CitiesListResponse();

  CitiesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('cities')) {
      cities = (_json['cities'] as core.List)
          .map<City>((value) =>
              City.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cities != null)
          'cities': cities!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Contains information about a city that can be targeted by ads.
class City {
  /// Country code of the country to which this city belongs.
  core.String? countryCode;

  /// DART ID of the country to which this city belongs.
  core.String? countryDartId;

  /// DART ID of this city.
  ///
  /// This is the ID used for targeting and generating reports.
  core.String? dartId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#city".
  core.String? kind;

  /// Metro region code of the metro region (DMA) to which this city belongs.
  core.String? metroCode;

  /// ID of the metro region (DMA) to which this city belongs.
  core.String? metroDmaId;

  /// Name of this city.
  core.String? name;

  /// Region code of the region to which this city belongs.
  core.String? regionCode;

  /// DART ID of the region to which this city belongs.
  core.String? regionDartId;

  City();

  City.fromJson(core.Map _json) {
    if (_json.containsKey('countryCode')) {
      countryCode = _json['countryCode'] as core.String;
    }
    if (_json.containsKey('countryDartId')) {
      countryDartId = _json['countryDartId'] as core.String;
    }
    if (_json.containsKey('dartId')) {
      dartId = _json['dartId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metroCode')) {
      metroCode = _json['metroCode'] as core.String;
    }
    if (_json.containsKey('metroDmaId')) {
      metroDmaId = _json['metroDmaId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('regionCode')) {
      regionCode = _json['regionCode'] as core.String;
    }
    if (_json.containsKey('regionDartId')) {
      regionDartId = _json['regionDartId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (countryCode != null) 'countryCode': countryCode!,
        if (countryDartId != null) 'countryDartId': countryDartId!,
        if (dartId != null) 'dartId': dartId!,
        if (kind != null) 'kind': kind!,
        if (metroCode != null) 'metroCode': metroCode!,
        if (metroDmaId != null) 'metroDmaId': metroDmaId!,
        if (name != null) 'name': name!,
        if (regionCode != null) 'regionCode': regionCode!,
        if (regionDartId != null) 'regionDartId': regionDartId!,
      };
}

/// Creative Click Tag.
class ClickTag {
  /// Parameter value for the specified click tag.
  ///
  /// This field contains a click-through url.
  CreativeClickThroughUrl? clickThroughUrl;

  /// Advertiser event name associated with the click tag.
  ///
  /// This field is used by DISPLAY_IMAGE_GALLERY and HTML5_BANNER creatives.
  /// Applicable to DISPLAY when the primary asset type is not HTML_IMAGE.
  core.String? eventName;

  /// Parameter name for the specified click tag.
  ///
  /// For DISPLAY_IMAGE_GALLERY creative assets, this field must match the value
  /// of the creative asset's creativeAssetId.name field.
  core.String? name;

  ClickTag();

  ClickTag.fromJson(core.Map _json) {
    if (_json.containsKey('clickThroughUrl')) {
      clickThroughUrl = CreativeClickThroughUrl.fromJson(
          _json['clickThroughUrl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('eventName')) {
      eventName = _json['eventName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clickThroughUrl != null)
          'clickThroughUrl': clickThroughUrl!.toJson(),
        if (eventName != null) 'eventName': eventName!,
        if (name != null) 'name': name!,
      };
}

/// Click-through URL
class ClickThroughUrl {
  /// Read-only convenience field representing the actual URL that will be used
  /// for this click-through.
  ///
  /// The URL is computed as follows: - If defaultLandingPage is enabled then
  /// the campaign's default landing page URL is assigned to this field. - If
  /// defaultLandingPage is not enabled and a landingPageId is specified then
  /// that landing page's URL is assigned to this field. - If neither of the
  /// above cases apply, then the customClickThroughUrl is assigned to this
  /// field.
  core.String? computedClickThroughUrl;

  /// Custom click-through URL.
  ///
  /// Applicable if the defaultLandingPage field is set to false and the
  /// landingPageId field is left unset.
  core.String? customClickThroughUrl;

  /// Whether the campaign default landing page is used.
  core.bool? defaultLandingPage;

  /// ID of the landing page for the click-through URL.
  ///
  /// Applicable if the defaultLandingPage field is set to false.
  core.String? landingPageId;

  ClickThroughUrl();

  ClickThroughUrl.fromJson(core.Map _json) {
    if (_json.containsKey('computedClickThroughUrl')) {
      computedClickThroughUrl = _json['computedClickThroughUrl'] as core.String;
    }
    if (_json.containsKey('customClickThroughUrl')) {
      customClickThroughUrl = _json['customClickThroughUrl'] as core.String;
    }
    if (_json.containsKey('defaultLandingPage')) {
      defaultLandingPage = _json['defaultLandingPage'] as core.bool;
    }
    if (_json.containsKey('landingPageId')) {
      landingPageId = _json['landingPageId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (computedClickThroughUrl != null)
          'computedClickThroughUrl': computedClickThroughUrl!,
        if (customClickThroughUrl != null)
          'customClickThroughUrl': customClickThroughUrl!,
        if (defaultLandingPage != null)
          'defaultLandingPage': defaultLandingPage!,
        if (landingPageId != null) 'landingPageId': landingPageId!,
      };
}

/// Click Through URL Suffix settings.
class ClickThroughUrlSuffixProperties {
  /// Click-through URL suffix to apply to all ads in this entity's scope.
  ///
  /// Must be less than 128 characters long.
  core.String? clickThroughUrlSuffix;

  /// Whether this entity should override the inherited click-through URL suffix
  /// with its own defined value.
  core.bool? overrideInheritedSuffix;

  ClickThroughUrlSuffixProperties();

  ClickThroughUrlSuffixProperties.fromJson(core.Map _json) {
    if (_json.containsKey('clickThroughUrlSuffix')) {
      clickThroughUrlSuffix = _json['clickThroughUrlSuffix'] as core.String;
    }
    if (_json.containsKey('overrideInheritedSuffix')) {
      overrideInheritedSuffix = _json['overrideInheritedSuffix'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clickThroughUrlSuffix != null)
          'clickThroughUrlSuffix': clickThroughUrlSuffix!,
        if (overrideInheritedSuffix != null)
          'overrideInheritedSuffix': overrideInheritedSuffix!,
      };
}

/// Companion Click-through override.
class CompanionClickThroughOverride {
  /// Click-through URL of this companion click-through override.
  ClickThroughUrl? clickThroughUrl;

  /// ID of the creative for this companion click-through override.
  core.String? creativeId;

  CompanionClickThroughOverride();

  CompanionClickThroughOverride.fromJson(core.Map _json) {
    if (_json.containsKey('clickThroughUrl')) {
      clickThroughUrl = ClickThroughUrl.fromJson(
          _json['clickThroughUrl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('creativeId')) {
      creativeId = _json['creativeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clickThroughUrl != null)
          'clickThroughUrl': clickThroughUrl!.toJson(),
        if (creativeId != null) 'creativeId': creativeId!,
      };
}

/// Companion Settings
class CompanionSetting {
  /// Whether companions are disabled for this placement.
  core.bool? companionsDisabled;

  /// Allowlist of companion sizes to be served to this placement.
  ///
  /// Set this list to null or empty to serve all companion sizes.
  core.List<Size>? enabledSizes;

  /// Whether to serve only static images as companions.
  core.bool? imageOnly;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#companionSetting".
  core.String? kind;

  CompanionSetting();

  CompanionSetting.fromJson(core.Map _json) {
    if (_json.containsKey('companionsDisabled')) {
      companionsDisabled = _json['companionsDisabled'] as core.bool;
    }
    if (_json.containsKey('enabledSizes')) {
      enabledSizes = (_json['enabledSizes'] as core.List)
          .map<Size>((value) =>
              Size.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('imageOnly')) {
      imageOnly = _json['imageOnly'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (companionsDisabled != null)
          'companionsDisabled': companionsDisabled!,
        if (enabledSizes != null)
          'enabledSizes': enabledSizes!.map((value) => value.toJson()).toList(),
        if (imageOnly != null) 'imageOnly': imageOnly!,
        if (kind != null) 'kind': kind!,
      };
}

/// Represents a response to the queryCompatibleFields method.
class CompatibleFields {
  /// Contains items that are compatible to be selected for a report of type
  /// "CROSS_DIMENSION_REACH".
  CrossDimensionReachReportCompatibleFields?
      crossDimensionReachReportCompatibleFields;

  /// Contains items that are compatible to be selected for a report of type
  /// "FLOODLIGHT".
  FloodlightReportCompatibleFields? floodlightReportCompatibleFields;

  /// The kind of resource this is, in this case dfareporting#compatibleFields.
  core.String? kind;

  /// Contains items that are compatible to be selected for a report of type
  /// "PATH_ATTRIBUTION".
  PathReportCompatibleFields? pathAttributionReportCompatibleFields;

  /// Contains items that are compatible to be selected for a report of type
  /// "PATH".
  PathReportCompatibleFields? pathReportCompatibleFields;

  /// Contains items that are compatible to be selected for a report of type
  /// "PATH_TO_CONVERSION".
  PathToConversionReportCompatibleFields?
      pathToConversionReportCompatibleFields;

  /// Contains items that are compatible to be selected for a report of type
  /// "REACH".
  ReachReportCompatibleFields? reachReportCompatibleFields;

  /// Contains items that are compatible to be selected for a report of type
  /// "STANDARD".
  ReportCompatibleFields? reportCompatibleFields;

  CompatibleFields();

  CompatibleFields.fromJson(core.Map _json) {
    if (_json.containsKey('crossDimensionReachReportCompatibleFields')) {
      crossDimensionReachReportCompatibleFields =
          CrossDimensionReachReportCompatibleFields.fromJson(
              _json['crossDimensionReachReportCompatibleFields']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('floodlightReportCompatibleFields')) {
      floodlightReportCompatibleFields =
          FloodlightReportCompatibleFields.fromJson(
              _json['floodlightReportCompatibleFields']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('pathAttributionReportCompatibleFields')) {
      pathAttributionReportCompatibleFields =
          PathReportCompatibleFields.fromJson(
              _json['pathAttributionReportCompatibleFields']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pathReportCompatibleFields')) {
      pathReportCompatibleFields = PathReportCompatibleFields.fromJson(
          _json['pathReportCompatibleFields']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pathToConversionReportCompatibleFields')) {
      pathToConversionReportCompatibleFields =
          PathToConversionReportCompatibleFields.fromJson(
              _json['pathToConversionReportCompatibleFields']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reachReportCompatibleFields')) {
      reachReportCompatibleFields = ReachReportCompatibleFields.fromJson(
          _json['reachReportCompatibleFields']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reportCompatibleFields')) {
      reportCompatibleFields = ReportCompatibleFields.fromJson(
          _json['reportCompatibleFields']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (crossDimensionReachReportCompatibleFields != null)
          'crossDimensionReachReportCompatibleFields':
              crossDimensionReachReportCompatibleFields!.toJson(),
        if (floodlightReportCompatibleFields != null)
          'floodlightReportCompatibleFields':
              floodlightReportCompatibleFields!.toJson(),
        if (kind != null) 'kind': kind!,
        if (pathAttributionReportCompatibleFields != null)
          'pathAttributionReportCompatibleFields':
              pathAttributionReportCompatibleFields!.toJson(),
        if (pathReportCompatibleFields != null)
          'pathReportCompatibleFields': pathReportCompatibleFields!.toJson(),
        if (pathToConversionReportCompatibleFields != null)
          'pathToConversionReportCompatibleFields':
              pathToConversionReportCompatibleFields!.toJson(),
        if (reachReportCompatibleFields != null)
          'reachReportCompatibleFields': reachReportCompatibleFields!.toJson(),
        if (reportCompatibleFields != null)
          'reportCompatibleFields': reportCompatibleFields!.toJson(),
      };
}

/// Contains information about an internet connection type that can be targeted
/// by ads.
///
/// Clients can use the connection type to target mobile vs. broadband users.
class ConnectionType {
  /// ID of this connection type.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#connectionType".
  core.String? kind;

  /// Name of this connection type.
  core.String? name;

  ConnectionType();

  ConnectionType.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// Connection Type List Response
class ConnectionTypesListResponse {
  /// Collection of connection types such as broadband and mobile.
  core.List<ConnectionType>? connectionTypes;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#connectionTypesListResponse".
  core.String? kind;

  ConnectionTypesListResponse();

  ConnectionTypesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('connectionTypes')) {
      connectionTypes = (_json['connectionTypes'] as core.List)
          .map<ConnectionType>((value) => ConnectionType.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (connectionTypes != null)
          'connectionTypes':
              connectionTypes!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Content Category List Response
class ContentCategoriesListResponse {
  /// Content category collection.
  core.List<ContentCategory>? contentCategories;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#contentCategoriesListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  ContentCategoriesListResponse();

  ContentCategoriesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('contentCategories')) {
      contentCategories = (_json['contentCategories'] as core.List)
          .map<ContentCategory>((value) => ContentCategory.fromJson(
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
        if (contentCategories != null)
          'contentCategories':
              contentCategories!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Organizes placements according to the contents of their associated webpages.
class ContentCategory {
  /// Account ID of this content category.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// ID of this content category.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#contentCategory".
  core.String? kind;

  /// Name of this content category.
  ///
  /// This is a required field and must be less than 256 characters long and
  /// unique among content categories of the same account.
  core.String? name;

  ContentCategory();

  ContentCategory.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// A Conversion represents when a user successfully performs a desired action
/// after seeing an ad.
class Conversion {
  /// Whether this particular request may come from a user under the age of 13,
  /// under COPPA compliance.
  core.bool? childDirectedTreatment;

  /// Custom floodlight variables.
  core.List<CustomFloodlightVariable>? customVariables;

  /// The display click ID.
  ///
  /// This field is mutually exclusive with encryptedUserId,
  /// encryptedUserIdCandidates\[\], matchId, mobileDeviceId and gclid. This or
  /// encryptedUserId or encryptedUserIdCandidates\[\] or matchId or
  /// mobileDeviceId or gclid is a required field.
  core.String? dclid;

  /// The alphanumeric encrypted user ID.
  ///
  /// When set, encryptionInfo should also be specified. This field is mutually
  /// exclusive with encryptedUserIdCandidates\[\], matchId, mobileDeviceId,
  /// gclid and dclid. This or encryptedUserIdCandidates\[\] or matchId or
  /// mobileDeviceId or gclid or dclid is a required field.
  core.String? encryptedUserId;

  /// A list of the alphanumeric encrypted user IDs.
  ///
  /// Any user ID with exposure prior to the conversion timestamp will be used
  /// in the inserted conversion. If no such user ID is found then the
  /// conversion will be rejected with INVALID_ARGUMENT error. When set,
  /// encryptionInfo should also be specified. This field may only be used when
  /// calling batchinsert; it is not supported by batchupdate. This field is
  /// mutually exclusive with encryptedUserId, matchId, mobileDeviceId, gclid
  /// and dclid. This or encryptedUserId or matchId or mobileDeviceId or gclid
  /// or dclid is a required field.
  core.List<core.String>? encryptedUserIdCandidates;

  /// Floodlight Activity ID of this conversion.
  ///
  /// This is a required field.
  core.String? floodlightActivityId;

  /// Floodlight Configuration ID of this conversion.
  ///
  /// This is a required field.
  core.String? floodlightConfigurationId;

  /// The Google click ID.
  ///
  /// This field is mutually exclusive with encryptedUserId,
  /// encryptedUserIdCandidates\[\], matchId, mobileDeviceId and dclid. This or
  /// encryptedUserId or encryptedUserIdCandidates\[\] or matchId or
  /// mobileDeviceId or dclid is a required field.
  core.String? gclid;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#conversion".
  core.String? kind;

  /// Whether Limit Ad Tracking is enabled.
  ///
  /// When set to true, the conversion will be used for reporting but not
  /// targeting. This will prevent remarketing.
  core.bool? limitAdTracking;

  /// The match ID field.
  ///
  /// A match ID is your own first-party identifier that has been synced with
  /// Google using the match ID feature in Floodlight. This field is mutually
  /// exclusive with encryptedUserId,
  /// encryptedUserIdCandidates\[\],mobileDeviceId, gclid and dclid. This or
  /// encryptedUserId or encryptedUserIdCandidates\[\] or mobileDeviceId or
  /// gclid or dclid is a required field.
  core.String? matchId;

  /// The mobile device ID.
  ///
  /// This field is mutually exclusive with encryptedUserId,
  /// encryptedUserIdCandidates\[\], matchId, gclid and dclid. This or
  /// encryptedUserId or encryptedUserIdCandidates\[\] or matchId or gclid or
  /// dclid is a required field.
  core.String? mobileDeviceId;

  /// Whether the conversion was for a non personalized ad.
  core.bool? nonPersonalizedAd;

  /// The ordinal of the conversion.
  ///
  /// Use this field to control how conversions of the same user and day are
  /// de-duplicated. This is a required field.
  core.String? ordinal;

  /// The quantity of the conversion.
  core.String? quantity;

  /// The timestamp of conversion, in Unix epoch micros.
  ///
  /// This is a required field.
  core.String? timestampMicros;

  /// Whether this particular request may come from a user under the age of 16
  /// (may differ by country), under compliance with the European Union's
  /// General Data Protection Regulation (GDPR).
  core.bool? treatmentForUnderage;

  /// The value of the conversion.
  core.double? value;

  Conversion();

  Conversion.fromJson(core.Map _json) {
    if (_json.containsKey('childDirectedTreatment')) {
      childDirectedTreatment = _json['childDirectedTreatment'] as core.bool;
    }
    if (_json.containsKey('customVariables')) {
      customVariables = (_json['customVariables'] as core.List)
          .map<CustomFloodlightVariable>((value) =>
              CustomFloodlightVariable.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dclid')) {
      dclid = _json['dclid'] as core.String;
    }
    if (_json.containsKey('encryptedUserId')) {
      encryptedUserId = _json['encryptedUserId'] as core.String;
    }
    if (_json.containsKey('encryptedUserIdCandidates')) {
      encryptedUserIdCandidates =
          (_json['encryptedUserIdCandidates'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('floodlightActivityId')) {
      floodlightActivityId = _json['floodlightActivityId'] as core.String;
    }
    if (_json.containsKey('floodlightConfigurationId')) {
      floodlightConfigurationId =
          _json['floodlightConfigurationId'] as core.String;
    }
    if (_json.containsKey('gclid')) {
      gclid = _json['gclid'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('limitAdTracking')) {
      limitAdTracking = _json['limitAdTracking'] as core.bool;
    }
    if (_json.containsKey('matchId')) {
      matchId = _json['matchId'] as core.String;
    }
    if (_json.containsKey('mobileDeviceId')) {
      mobileDeviceId = _json['mobileDeviceId'] as core.String;
    }
    if (_json.containsKey('nonPersonalizedAd')) {
      nonPersonalizedAd = _json['nonPersonalizedAd'] as core.bool;
    }
    if (_json.containsKey('ordinal')) {
      ordinal = _json['ordinal'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.String;
    }
    if (_json.containsKey('timestampMicros')) {
      timestampMicros = _json['timestampMicros'] as core.String;
    }
    if (_json.containsKey('treatmentForUnderage')) {
      treatmentForUnderage = _json['treatmentForUnderage'] as core.bool;
    }
    if (_json.containsKey('value')) {
      value = (_json['value'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (childDirectedTreatment != null)
          'childDirectedTreatment': childDirectedTreatment!,
        if (customVariables != null)
          'customVariables':
              customVariables!.map((value) => value.toJson()).toList(),
        if (dclid != null) 'dclid': dclid!,
        if (encryptedUserId != null) 'encryptedUserId': encryptedUserId!,
        if (encryptedUserIdCandidates != null)
          'encryptedUserIdCandidates': encryptedUserIdCandidates!,
        if (floodlightActivityId != null)
          'floodlightActivityId': floodlightActivityId!,
        if (floodlightConfigurationId != null)
          'floodlightConfigurationId': floodlightConfigurationId!,
        if (gclid != null) 'gclid': gclid!,
        if (kind != null) 'kind': kind!,
        if (limitAdTracking != null) 'limitAdTracking': limitAdTracking!,
        if (matchId != null) 'matchId': matchId!,
        if (mobileDeviceId != null) 'mobileDeviceId': mobileDeviceId!,
        if (nonPersonalizedAd != null) 'nonPersonalizedAd': nonPersonalizedAd!,
        if (ordinal != null) 'ordinal': ordinal!,
        if (quantity != null) 'quantity': quantity!,
        if (timestampMicros != null) 'timestampMicros': timestampMicros!,
        if (treatmentForUnderage != null)
          'treatmentForUnderage': treatmentForUnderage!,
        if (value != null) 'value': value!,
      };
}

/// The error code and description for a conversion that failed to insert or
/// update.
class ConversionError {
  /// The error code.
  /// Possible string values are:
  /// - "INVALID_ARGUMENT"
  /// - "INTERNAL"
  /// - "PERMISSION_DENIED"
  /// - "NOT_FOUND"
  core.String? code;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#conversionError".
  core.String? kind;

  /// A description of the error.
  core.String? message;

  ConversionError();

  ConversionError.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (kind != null) 'kind': kind!,
        if (message != null) 'message': message!,
      };
}

/// The original conversion that was inserted or updated and whether there were
/// any errors.
class ConversionStatus {
  /// The original conversion that was inserted or updated.
  Conversion? conversion;

  /// A list of errors related to this conversion.
  core.List<ConversionError>? errors;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#conversionStatus".
  core.String? kind;

  ConversionStatus();

  ConversionStatus.fromJson(core.Map _json) {
    if (_json.containsKey('conversion')) {
      conversion = Conversion.fromJson(
          _json['conversion'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<ConversionError>((value) => ConversionError.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conversion != null) 'conversion': conversion!.toJson(),
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Insert Conversions Request.
class ConversionsBatchInsertRequest {
  /// The set of conversions to insert.
  core.List<Conversion>? conversions;

  /// Describes how encryptedUserId or encryptedUserIdCandidates\[\] is
  /// encrypted.
  ///
  /// This is a required field if encryptedUserId or
  /// encryptedUserIdCandidates\[\] is used.
  EncryptionInfo? encryptionInfo;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#conversionsBatchInsertRequest".
  core.String? kind;

  ConversionsBatchInsertRequest();

  ConversionsBatchInsertRequest.fromJson(core.Map _json) {
    if (_json.containsKey('conversions')) {
      conversions = (_json['conversions'] as core.List)
          .map<Conversion>((value) =>
              Conversion.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('encryptionInfo')) {
      encryptionInfo = EncryptionInfo.fromJson(
          _json['encryptionInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conversions != null)
          'conversions': conversions!.map((value) => value.toJson()).toList(),
        if (encryptionInfo != null) 'encryptionInfo': encryptionInfo!.toJson(),
        if (kind != null) 'kind': kind!,
      };
}

/// Insert Conversions Response.
class ConversionsBatchInsertResponse {
  /// Indicates that some or all conversions failed to insert.
  core.bool? hasFailures;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#conversionsBatchInsertResponse".
  core.String? kind;

  /// The insert status of each conversion.
  ///
  /// Statuses are returned in the same order that conversions are inserted.
  core.List<ConversionStatus>? status;

  ConversionsBatchInsertResponse();

  ConversionsBatchInsertResponse.fromJson(core.Map _json) {
    if (_json.containsKey('hasFailures')) {
      hasFailures = _json['hasFailures'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = (_json['status'] as core.List)
          .map<ConversionStatus>((value) => ConversionStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hasFailures != null) 'hasFailures': hasFailures!,
        if (kind != null) 'kind': kind!,
        if (status != null)
          'status': status!.map((value) => value.toJson()).toList(),
      };
}

/// Update Conversions Request.
class ConversionsBatchUpdateRequest {
  /// The set of conversions to update.
  core.List<Conversion>? conversions;

  /// Describes how encryptedUserId is encrypted.
  ///
  /// This is a required field if encryptedUserId is used.
  EncryptionInfo? encryptionInfo;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#conversionsBatchUpdateRequest".
  core.String? kind;

  ConversionsBatchUpdateRequest();

  ConversionsBatchUpdateRequest.fromJson(core.Map _json) {
    if (_json.containsKey('conversions')) {
      conversions = (_json['conversions'] as core.List)
          .map<Conversion>((value) =>
              Conversion.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('encryptionInfo')) {
      encryptionInfo = EncryptionInfo.fromJson(
          _json['encryptionInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conversions != null)
          'conversions': conversions!.map((value) => value.toJson()).toList(),
        if (encryptionInfo != null) 'encryptionInfo': encryptionInfo!.toJson(),
        if (kind != null) 'kind': kind!,
      };
}

/// Update Conversions Response.
class ConversionsBatchUpdateResponse {
  /// Indicates that some or all conversions failed to update.
  core.bool? hasFailures;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#conversionsBatchUpdateResponse".
  core.String? kind;

  /// The update status of each conversion.
  ///
  /// Statuses are returned in the same order that conversions are updated.
  core.List<ConversionStatus>? status;

  ConversionsBatchUpdateResponse();

  ConversionsBatchUpdateResponse.fromJson(core.Map _json) {
    if (_json.containsKey('hasFailures')) {
      hasFailures = _json['hasFailures'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = (_json['status'] as core.List)
          .map<ConversionStatus>((value) => ConversionStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hasFailures != null) 'hasFailures': hasFailures!,
        if (kind != null) 'kind': kind!,
        if (status != null)
          'status': status!.map((value) => value.toJson()).toList(),
      };
}

/// Country List Response
class CountriesListResponse {
  /// Country collection.
  core.List<Country>? countries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#countriesListResponse".
  core.String? kind;

  CountriesListResponse();

  CountriesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('countries')) {
      countries = (_json['countries'] as core.List)
          .map<Country>((value) =>
              Country.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (countries != null)
          'countries': countries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Contains information about a country that can be targeted by ads.
class Country {
  /// Country code.
  core.String? countryCode;

  /// DART ID of this country.
  ///
  /// This is the ID used for targeting and generating reports.
  core.String? dartId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#country".
  core.String? kind;

  /// Name of this country.
  core.String? name;

  /// Whether ad serving supports secure servers in this country.
  core.bool? sslEnabled;

  Country();

  Country.fromJson(core.Map _json) {
    if (_json.containsKey('countryCode')) {
      countryCode = _json['countryCode'] as core.String;
    }
    if (_json.containsKey('dartId')) {
      dartId = _json['dartId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('sslEnabled')) {
      sslEnabled = _json['sslEnabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (countryCode != null) 'countryCode': countryCode!,
        if (dartId != null) 'dartId': dartId!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (sslEnabled != null) 'sslEnabled': sslEnabled!,
      };
}

/// Contains properties of a Creative.
class Creative {
  /// Account ID of this creative.
  ///
  /// This field, if left unset, will be auto-generated for both insert and
  /// update operations. Applicable to all creative types.
  core.String? accountId;

  /// Whether the creative is active.
  ///
  /// Applicable to all creative types.
  core.bool? active;

  /// Ad parameters user for VPAID creative.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// VPAID.
  core.String? adParameters;

  /// Keywords for a Rich Media creative.
  ///
  /// Keywords let you customize the creative settings of a Rich Media ad
  /// running on your site without having to contact the advertiser. You can use
  /// keywords to dynamically change the look or functionality of a creative.
  /// Applicable to the following creative types: all RICH_MEDIA, and all VPAID.
  core.List<core.String>? adTagKeys;

  /// Additional sizes associated with a responsive creative.
  ///
  /// When inserting or updating a creative either the size ID field or size
  /// width and height fields can be used. Applicable to DISPLAY creatives when
  /// the primary asset type is HTML_IMAGE.
  core.List<Size>? additionalSizes;

  /// Advertiser ID of this creative.
  ///
  /// This is a required field. Applicable to all creative types.
  core.String? advertiserId;

  /// Whether script access is allowed for this creative.
  ///
  /// This is a read-only and deprecated field which will automatically be set
  /// to true on update. Applicable to the following creative types:
  /// FLASH_INPAGE.
  core.bool? allowScriptAccess;

  /// Whether the creative is archived.
  ///
  /// Applicable to all creative types.
  core.bool? archived;

  /// Type of artwork used for the creative.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA, and all VPAID.
  /// Possible string values are:
  /// - "ARTWORK_TYPE_FLASH"
  /// - "ARTWORK_TYPE_HTML5"
  /// - "ARTWORK_TYPE_MIXED"
  /// - "ARTWORK_TYPE_IMAGE"
  core.String? artworkType;

  /// Source application where creative was authored.
  ///
  /// Presently, only DBM authored creatives will have this field set.
  /// Applicable to all creative types.
  /// Possible string values are:
  /// - "CREATIVE_AUTHORING_SOURCE_DCM"
  /// - "CREATIVE_AUTHORING_SOURCE_DBM"
  /// - "CREATIVE_AUTHORING_SOURCE_STUDIO"
  /// - "CREATIVE_AUTHORING_SOURCE_GWD"
  core.String? authoringSource;

  /// Authoring tool for HTML5 banner creatives.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// HTML5_BANNER.
  /// Possible string values are:
  /// - "NINJA"
  /// - "SWIFFY"
  core.String? authoringTool;

  /// Whether images are automatically advanced for image gallery creatives.
  ///
  /// Applicable to the following creative types: DISPLAY_IMAGE_GALLERY.
  core.bool? autoAdvanceImages;

  /// The 6-character HTML color code, beginning with #, for the background of
  /// the window area where the Flash file is displayed.
  ///
  /// Default is white. Applicable to the following creative types:
  /// FLASH_INPAGE.
  core.String? backgroundColor;

  /// Click-through URL for backup image.
  ///
  /// Applicable to ENHANCED_BANNER when the primary asset type is not
  /// HTML_IMAGE.
  CreativeClickThroughUrl? backupImageClickThroughUrl;

  /// List of feature dependencies that will cause a backup image to be served
  /// if the browser that serves the ad does not support them.
  ///
  /// Feature dependencies are features that a browser must be able to support
  /// in order to render your HTML5 creative asset correctly. This field is
  /// initially auto-generated to contain all features detected by Campaign
  /// Manager for all the assets of this creative and can then be modified by
  /// the client. To reset this field, copy over all the creativeAssets'
  /// detected features. Applicable to the following creative types:
  /// HTML5_BANNER. Applicable to DISPLAY when the primary asset type is not
  /// HTML_IMAGE.
  core.List<core.String>? backupImageFeatures;

  /// Reporting label used for HTML5 banner backup image.
  ///
  /// Applicable to the following creative types: DISPLAY when the primary asset
  /// type is not HTML_IMAGE.
  core.String? backupImageReportingLabel;

  /// Target window for backup image.
  ///
  /// Applicable to the following creative types: FLASH_INPAGE and HTML5_BANNER.
  /// Applicable to DISPLAY when the primary asset type is not HTML_IMAGE.
  TargetWindow? backupImageTargetWindow;

  /// Click tags of the creative.
  ///
  /// For DISPLAY, FLASH_INPAGE, and HTML5_BANNER creatives, this is a subset of
  /// detected click tags for the assets associated with this creative. After
  /// creating a flash asset, detected click tags will be returned in the
  /// creativeAssetMetadata. When inserting the creative, populate the creative
  /// clickTags field using the creativeAssetMetadata.clickTags field. For
  /// DISPLAY_IMAGE_GALLERY creatives, there should be exactly one entry in this
  /// list for each image creative asset. A click tag is matched with a
  /// corresponding creative asset by matching the clickTag.name field with the
  /// creativeAsset.assetIdentifier.name field. Applicable to the following
  /// creative types: DISPLAY_IMAGE_GALLERY, FLASH_INPAGE, HTML5_BANNER.
  /// Applicable to DISPLAY when the primary asset type is not HTML_IMAGE.
  core.List<ClickTag>? clickTags;

  /// Industry standard ID assigned to creative for reach and frequency.
  ///
  /// Applicable to INSTREAM_VIDEO_REDIRECT creatives.
  core.String? commercialId;

  /// List of companion creatives assigned to an in-Stream video creative.
  ///
  /// Acceptable values include IDs of existing flash and image creatives.
  /// Applicable to the following creative types: all VPAID, all INSTREAM_AUDIO
  /// and all INSTREAM_VIDEO with dynamicAssetSelection set to false.
  core.List<core.String>? companionCreatives;

  /// Compatibilities associated with this creative.
  ///
  /// This is a read-only field. DISPLAY and DISPLAY_INTERSTITIAL refer to
  /// rendering either on desktop or on mobile devices or in mobile apps for
  /// regular or interstitial ads, respectively. APP and APP_INTERSTITIAL are
  /// for rendering in mobile apps. Only pre-existing creatives may have these
  /// compatibilities since new creatives will either be assigned DISPLAY or
  /// DISPLAY_INTERSTITIAL instead. IN_STREAM_VIDEO refers to rendering in
  /// in-stream video ads developed with the VAST standard. IN_STREAM_AUDIO
  /// refers to rendering in in-stream audio ads developed with the VAST
  /// standard. Applicable to all creative types. Acceptable values are: - "APP"
  /// - "APP_INTERSTITIAL" - "IN_STREAM_VIDEO" - "IN_STREAM_AUDIO" - "DISPLAY" -
  /// "DISPLAY_INTERSTITIAL"
  core.List<core.String>? compatibility;

  /// Whether Flash assets associated with the creative need to be automatically
  /// converted to HTML5.
  ///
  /// This flag is enabled by default and users can choose to disable it if they
  /// don't want the system to generate and use HTML5 asset for this creative.
  /// Applicable to the following creative type: FLASH_INPAGE. Applicable to
  /// DISPLAY when the primary asset type is not HTML_IMAGE.
  core.bool? convertFlashToHtml5;

  /// List of counter events configured for the creative.
  ///
  /// For DISPLAY_IMAGE_GALLERY creatives, these are read-only and
  /// auto-generated from clickTags. Applicable to the following creative types:
  /// DISPLAY_IMAGE_GALLERY, all RICH_MEDIA, and all VPAID.
  core.List<CreativeCustomEvent>? counterCustomEvents;

  /// Required if dynamicAssetSelection is true.
  CreativeAssetSelection? creativeAssetSelection;

  /// Assets associated with a creative.
  ///
  /// Applicable to all but the following creative types: INTERNAL_REDIRECT,
  /// INTERSTITIAL_INTERNAL_REDIRECT, and REDIRECT
  core.List<CreativeAsset>? creativeAssets;

  /// Creative field assignments for this creative.
  ///
  /// Applicable to all creative types.
  core.List<CreativeFieldAssignment>? creativeFieldAssignments;

  /// Custom key-values for a Rich Media creative.
  ///
  /// Key-values let you customize the creative settings of a Rich Media ad
  /// running on your site without having to contact the advertiser. You can use
  /// key-values to dynamically change the look or functionality of a creative.
  /// Applicable to the following creative types: all RICH_MEDIA, and all VPAID.
  core.List<core.String>? customKeyValues;

  /// Set this to true to enable the use of rules to target individual assets in
  /// this creative.
  ///
  /// When set to true creativeAssetSelection must be set. This also controls
  /// asset-level companions. When this is true, companion creatives should be
  /// assigned to creative assets. Learn more. Applicable to INSTREAM_VIDEO
  /// creatives.
  core.bool? dynamicAssetSelection;

  /// List of exit events configured for the creative.
  ///
  /// For DISPLAY and DISPLAY_IMAGE_GALLERY creatives, these are read-only and
  /// auto-generated from clickTags, For DISPLAY, an event is also created from
  /// the backupImageReportingLabel. Applicable to the following creative types:
  /// DISPLAY_IMAGE_GALLERY, all RICH_MEDIA, and all VPAID. Applicable to
  /// DISPLAY when the primary asset type is not HTML_IMAGE.
  core.List<CreativeCustomEvent>? exitCustomEvents;

  /// OpenWindow FSCommand of this creative.
  ///
  /// This lets the SWF file communicate with either Flash Player or the program
  /// hosting Flash Player, such as a web browser. This is only triggered if
  /// allowScriptAccess field is true. Applicable to the following creative
  /// types: FLASH_INPAGE.
  FsCommand? fsCommand;

  /// HTML code for the creative.
  ///
  /// This is a required field when applicable. This field is ignored if
  /// htmlCodeLocked is true. Applicable to the following creative types: all
  /// CUSTOM, FLASH_INPAGE, and HTML5_BANNER, and all RICH_MEDIA.
  core.String? htmlCode;

  /// Whether HTML code is generated by Campaign Manager or manually entered.
  ///
  /// Set to true to ignore changes to htmlCode. Applicable to the following
  /// creative types: FLASH_INPAGE and HTML5_BANNER.
  core.bool? htmlCodeLocked;

  /// ID of this creative.
  ///
  /// This is a read-only, auto-generated field. Applicable to all creative
  /// types.
  core.String? id;

  /// Dimension value for the ID of this creative.
  ///
  /// This is a read-only field. Applicable to all creative types.
  DimensionValue? idDimensionValue;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#creative".
  core.String? kind;

  /// Creative last modification information.
  ///
  /// This is a read-only field. Applicable to all creative types.
  LastModifiedInfo? lastModifiedInfo;

  /// Latest Studio trafficked creative ID associated with rich media and VPAID
  /// creatives.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA, and all VPAID.
  core.String? latestTraffickedCreativeId;

  /// Description of the audio or video ad.
  ///
  /// Applicable to the following creative types: all INSTREAM_VIDEO,
  /// INSTREAM_AUDIO, and all VPAID.
  core.String? mediaDescription;

  /// Creative audio or video duration in seconds.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// INSTREAM_VIDEO, INSTREAM_AUDIO, all RICH_MEDIA, and all VPAID.
  core.double? mediaDuration;

  /// Name of the creative.
  ///
  /// This is a required field and must be less than 256 characters long.
  /// Applicable to all creative types.
  core.String? name;

  /// Online behavioral advertising icon to be added to the creative.
  ///
  /// Applicable to the following creative types: all INSTREAM_VIDEO.
  ObaIcon? obaIcon;

  /// Override CSS value for rich media creatives.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA.
  core.String? overrideCss;

  /// Amount of time to play the video before counting a view.
  ///
  /// Applicable to the following creative types: all INSTREAM_VIDEO.
  VideoOffset? progressOffset;

  /// URL of hosted image or hosted video or another ad tag.
  ///
  /// For INSTREAM_VIDEO_REDIRECT creatives this is the in-stream video redirect
  /// URL. The standard for a VAST (Video Ad Serving Template) ad response
  /// allows for a redirect link to another VAST 2.0 or 3.0 call. This is a
  /// required field when applicable. Applicable to the following creative
  /// types: DISPLAY_REDIRECT, INTERNAL_REDIRECT,
  /// INTERSTITIAL_INTERNAL_REDIRECT, and INSTREAM_VIDEO_REDIRECT
  core.String? redirectUrl;

  /// ID of current rendering version.
  ///
  /// This is a read-only field. Applicable to all creative types.
  core.String? renderingId;

  /// Dimension value for the rendering ID of this creative.
  ///
  /// This is a read-only field. Applicable to all creative types.
  DimensionValue? renderingIdDimensionValue;

  /// The minimum required Flash plugin version for this creative.
  ///
  /// For example, 11.2.202.235. This is a read-only field. Applicable to the
  /// following creative types: all RICH_MEDIA, and all VPAID.
  core.String? requiredFlashPluginVersion;

  /// The internal Flash version for this creative as calculated by Studio.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// FLASH_INPAGE all RICH_MEDIA, and all VPAID. Applicable to DISPLAY when the
  /// primary asset type is not HTML_IMAGE.
  core.int? requiredFlashVersion;

  /// Size associated with this creative.
  ///
  /// When inserting or updating a creative either the size ID field or size
  /// width and height fields can be used. This is a required field when
  /// applicable; however for IMAGE, FLASH_INPAGE creatives, and for DISPLAY
  /// creatives with a primary asset of type HTML_IMAGE, if left blank, this
  /// field will be automatically set using the actual size of the associated
  /// image assets. Applicable to the following creative types: DISPLAY,
  /// DISPLAY_IMAGE_GALLERY, FLASH_INPAGE, HTML5_BANNER, IMAGE, and all
  /// RICH_MEDIA.
  Size? size;

  /// Amount of time to play the video before the skip button appears.
  ///
  /// Applicable to the following creative types: all INSTREAM_VIDEO.
  VideoOffset? skipOffset;

  /// Whether the user can choose to skip the creative.
  ///
  /// Applicable to the following creative types: all INSTREAM_VIDEO and all
  /// VPAID.
  core.bool? skippable;

  /// Whether the creative is SSL-compliant.
  ///
  /// This is a read-only field. Applicable to all creative types.
  core.bool? sslCompliant;

  /// Whether creative should be treated as SSL compliant even if the system
  /// scan shows it's not.
  ///
  /// Applicable to all creative types.
  core.bool? sslOverride;

  /// Studio advertiser ID associated with rich media and VPAID creatives.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA, and all VPAID.
  core.String? studioAdvertiserId;

  /// Studio creative ID associated with rich media and VPAID creatives.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA, and all VPAID.
  core.String? studioCreativeId;

  /// Studio trafficked creative ID associated with rich media and VPAID
  /// creatives.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA, and all VPAID.
  core.String? studioTraffickedCreativeId;

  /// Subaccount ID of this creative.
  ///
  /// This field, if left unset, will be auto-generated for both insert and
  /// update operations. Applicable to all creative types.
  core.String? subaccountId;

  /// Third-party URL used to record backup image impressions.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA.
  core.String? thirdPartyBackupImageImpressionsUrl;

  /// Third-party URL used to record rich media impressions.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA.
  core.String? thirdPartyRichMediaImpressionsUrl;

  /// Third-party URLs for tracking in-stream creative events.
  ///
  /// Applicable to the following creative types: all INSTREAM_VIDEO, all
  /// INSTREAM_AUDIO, and all VPAID.
  core.List<ThirdPartyTrackingUrl>? thirdPartyUrls;

  /// List of timer events configured for the creative.
  ///
  /// For DISPLAY_IMAGE_GALLERY creatives, these are read-only and
  /// auto-generated from clickTags. Applicable to the following creative types:
  /// DISPLAY_IMAGE_GALLERY, all RICH_MEDIA, and all VPAID. Applicable to
  /// DISPLAY when the primary asset is not HTML_IMAGE.
  core.List<CreativeCustomEvent>? timerCustomEvents;

  /// Combined size of all creative assets.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA, and all VPAID.
  core.String? totalFileSize;

  /// Type of this creative.
  ///
  /// This is a required field. Applicable to all creative types. *Note:*
  /// FLASH_INPAGE, HTML5_BANNER, and IMAGE are only used for existing
  /// creatives. New creatives should use DISPLAY as a replacement for these
  /// types.
  /// Possible string values are:
  /// - "IMAGE"
  /// - "DISPLAY_REDIRECT"
  /// - "CUSTOM_DISPLAY"
  /// - "INTERNAL_REDIRECT"
  /// - "CUSTOM_DISPLAY_INTERSTITIAL"
  /// - "INTERSTITIAL_INTERNAL_REDIRECT"
  /// - "TRACKING_TEXT"
  /// - "RICH_MEDIA_DISPLAY_BANNER"
  /// - "RICH_MEDIA_INPAGE_FLOATING"
  /// - "RICH_MEDIA_IM_EXPAND"
  /// - "RICH_MEDIA_DISPLAY_EXPANDING"
  /// - "RICH_MEDIA_DISPLAY_INTERSTITIAL"
  /// - "RICH_MEDIA_DISPLAY_MULTI_FLOATING_INTERSTITIAL"
  /// - "RICH_MEDIA_MOBILE_IN_APP"
  /// - "FLASH_INPAGE"
  /// - "INSTREAM_VIDEO"
  /// - "VPAID_LINEAR_VIDEO"
  /// - "VPAID_NON_LINEAR_VIDEO"
  /// - "INSTREAM_VIDEO_REDIRECT"
  /// - "RICH_MEDIA_PEEL_DOWN"
  /// - "HTML5_BANNER"
  /// - "DISPLAY"
  /// - "DISPLAY_IMAGE_GALLERY"
  /// - "BRAND_SAFE_DEFAULT_INSTREAM_VIDEO"
  /// - "INSTREAM_AUDIO"
  core.String? type;

  /// A Universal Ad ID as per the VAST 4.0 spec.
  ///
  /// Applicable to the following creative types: INSTREAM_AUDIO and
  /// INSTREAM_VIDEO and VPAID.
  UniversalAdId? universalAdId;

  /// The version number helps you keep track of multiple versions of your
  /// creative in your reports.
  ///
  /// The version number will always be auto-generated during insert operations
  /// to start at 1. For tracking creatives the version cannot be incremented
  /// and will always remain at 1. For all other creative types the version can
  /// be incremented only by 1 during update operations. In addition, the
  /// version will be automatically incremented by 1 when undergoing Rich Media
  /// creative merging. Applicable to all creative types.
  core.int? version;

  Creative();

  Creative.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('active')) {
      active = _json['active'] as core.bool;
    }
    if (_json.containsKey('adParameters')) {
      adParameters = _json['adParameters'] as core.String;
    }
    if (_json.containsKey('adTagKeys')) {
      adTagKeys = (_json['adTagKeys'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('additionalSizes')) {
      additionalSizes = (_json['additionalSizes'] as core.List)
          .map<Size>((value) =>
              Size.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('allowScriptAccess')) {
      allowScriptAccess = _json['allowScriptAccess'] as core.bool;
    }
    if (_json.containsKey('archived')) {
      archived = _json['archived'] as core.bool;
    }
    if (_json.containsKey('artworkType')) {
      artworkType = _json['artworkType'] as core.String;
    }
    if (_json.containsKey('authoringSource')) {
      authoringSource = _json['authoringSource'] as core.String;
    }
    if (_json.containsKey('authoringTool')) {
      authoringTool = _json['authoringTool'] as core.String;
    }
    if (_json.containsKey('autoAdvanceImages')) {
      autoAdvanceImages = _json['autoAdvanceImages'] as core.bool;
    }
    if (_json.containsKey('backgroundColor')) {
      backgroundColor = _json['backgroundColor'] as core.String;
    }
    if (_json.containsKey('backupImageClickThroughUrl')) {
      backupImageClickThroughUrl = CreativeClickThroughUrl.fromJson(
          _json['backupImageClickThroughUrl']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('backupImageFeatures')) {
      backupImageFeatures = (_json['backupImageFeatures'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('backupImageReportingLabel')) {
      backupImageReportingLabel =
          _json['backupImageReportingLabel'] as core.String;
    }
    if (_json.containsKey('backupImageTargetWindow')) {
      backupImageTargetWindow = TargetWindow.fromJson(
          _json['backupImageTargetWindow']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('clickTags')) {
      clickTags = (_json['clickTags'] as core.List)
          .map<ClickTag>((value) =>
              ClickTag.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('commercialId')) {
      commercialId = _json['commercialId'] as core.String;
    }
    if (_json.containsKey('companionCreatives')) {
      companionCreatives = (_json['companionCreatives'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('compatibility')) {
      compatibility = (_json['compatibility'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('convertFlashToHtml5')) {
      convertFlashToHtml5 = _json['convertFlashToHtml5'] as core.bool;
    }
    if (_json.containsKey('counterCustomEvents')) {
      counterCustomEvents = (_json['counterCustomEvents'] as core.List)
          .map<CreativeCustomEvent>((value) => CreativeCustomEvent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('creativeAssetSelection')) {
      creativeAssetSelection = CreativeAssetSelection.fromJson(
          _json['creativeAssetSelection']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('creativeAssets')) {
      creativeAssets = (_json['creativeAssets'] as core.List)
          .map<CreativeAsset>((value) => CreativeAsset.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('creativeFieldAssignments')) {
      creativeFieldAssignments =
          (_json['creativeFieldAssignments'] as core.List)
              .map<CreativeFieldAssignment>((value) =>
                  CreativeFieldAssignment.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('customKeyValues')) {
      customKeyValues = (_json['customKeyValues'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('dynamicAssetSelection')) {
      dynamicAssetSelection = _json['dynamicAssetSelection'] as core.bool;
    }
    if (_json.containsKey('exitCustomEvents')) {
      exitCustomEvents = (_json['exitCustomEvents'] as core.List)
          .map<CreativeCustomEvent>((value) => CreativeCustomEvent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('fsCommand')) {
      fsCommand = FsCommand.fromJson(
          _json['fsCommand'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('htmlCode')) {
      htmlCode = _json['htmlCode'] as core.String;
    }
    if (_json.containsKey('htmlCodeLocked')) {
      htmlCodeLocked = _json['htmlCodeLocked'] as core.bool;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifiedInfo')) {
      lastModifiedInfo = LastModifiedInfo.fromJson(
          _json['lastModifiedInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('latestTraffickedCreativeId')) {
      latestTraffickedCreativeId =
          _json['latestTraffickedCreativeId'] as core.String;
    }
    if (_json.containsKey('mediaDescription')) {
      mediaDescription = _json['mediaDescription'] as core.String;
    }
    if (_json.containsKey('mediaDuration')) {
      mediaDuration = (_json['mediaDuration'] as core.num).toDouble();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('obaIcon')) {
      obaIcon = ObaIcon.fromJson(
          _json['obaIcon'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('overrideCss')) {
      overrideCss = _json['overrideCss'] as core.String;
    }
    if (_json.containsKey('progressOffset')) {
      progressOffset = VideoOffset.fromJson(
          _json['progressOffset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('redirectUrl')) {
      redirectUrl = _json['redirectUrl'] as core.String;
    }
    if (_json.containsKey('renderingId')) {
      renderingId = _json['renderingId'] as core.String;
    }
    if (_json.containsKey('renderingIdDimensionValue')) {
      renderingIdDimensionValue = DimensionValue.fromJson(
          _json['renderingIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('requiredFlashPluginVersion')) {
      requiredFlashPluginVersion =
          _json['requiredFlashPluginVersion'] as core.String;
    }
    if (_json.containsKey('requiredFlashVersion')) {
      requiredFlashVersion = _json['requiredFlashVersion'] as core.int;
    }
    if (_json.containsKey('size')) {
      size =
          Size.fromJson(_json['size'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('skipOffset')) {
      skipOffset = VideoOffset.fromJson(
          _json['skipOffset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('skippable')) {
      skippable = _json['skippable'] as core.bool;
    }
    if (_json.containsKey('sslCompliant')) {
      sslCompliant = _json['sslCompliant'] as core.bool;
    }
    if (_json.containsKey('sslOverride')) {
      sslOverride = _json['sslOverride'] as core.bool;
    }
    if (_json.containsKey('studioAdvertiserId')) {
      studioAdvertiserId = _json['studioAdvertiserId'] as core.String;
    }
    if (_json.containsKey('studioCreativeId')) {
      studioCreativeId = _json['studioCreativeId'] as core.String;
    }
    if (_json.containsKey('studioTraffickedCreativeId')) {
      studioTraffickedCreativeId =
          _json['studioTraffickedCreativeId'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('thirdPartyBackupImageImpressionsUrl')) {
      thirdPartyBackupImageImpressionsUrl =
          _json['thirdPartyBackupImageImpressionsUrl'] as core.String;
    }
    if (_json.containsKey('thirdPartyRichMediaImpressionsUrl')) {
      thirdPartyRichMediaImpressionsUrl =
          _json['thirdPartyRichMediaImpressionsUrl'] as core.String;
    }
    if (_json.containsKey('thirdPartyUrls')) {
      thirdPartyUrls = (_json['thirdPartyUrls'] as core.List)
          .map<ThirdPartyTrackingUrl>((value) => ThirdPartyTrackingUrl.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('timerCustomEvents')) {
      timerCustomEvents = (_json['timerCustomEvents'] as core.List)
          .map<CreativeCustomEvent>((value) => CreativeCustomEvent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('totalFileSize')) {
      totalFileSize = _json['totalFileSize'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('universalAdId')) {
      universalAdId = UniversalAdId.fromJson(
          _json['universalAdId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (active != null) 'active': active!,
        if (adParameters != null) 'adParameters': adParameters!,
        if (adTagKeys != null) 'adTagKeys': adTagKeys!,
        if (additionalSizes != null)
          'additionalSizes':
              additionalSizes!.map((value) => value.toJson()).toList(),
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (allowScriptAccess != null) 'allowScriptAccess': allowScriptAccess!,
        if (archived != null) 'archived': archived!,
        if (artworkType != null) 'artworkType': artworkType!,
        if (authoringSource != null) 'authoringSource': authoringSource!,
        if (authoringTool != null) 'authoringTool': authoringTool!,
        if (autoAdvanceImages != null) 'autoAdvanceImages': autoAdvanceImages!,
        if (backgroundColor != null) 'backgroundColor': backgroundColor!,
        if (backupImageClickThroughUrl != null)
          'backupImageClickThroughUrl': backupImageClickThroughUrl!.toJson(),
        if (backupImageFeatures != null)
          'backupImageFeatures': backupImageFeatures!,
        if (backupImageReportingLabel != null)
          'backupImageReportingLabel': backupImageReportingLabel!,
        if (backupImageTargetWindow != null)
          'backupImageTargetWindow': backupImageTargetWindow!.toJson(),
        if (clickTags != null)
          'clickTags': clickTags!.map((value) => value.toJson()).toList(),
        if (commercialId != null) 'commercialId': commercialId!,
        if (companionCreatives != null)
          'companionCreatives': companionCreatives!,
        if (compatibility != null) 'compatibility': compatibility!,
        if (convertFlashToHtml5 != null)
          'convertFlashToHtml5': convertFlashToHtml5!,
        if (counterCustomEvents != null)
          'counterCustomEvents':
              counterCustomEvents!.map((value) => value.toJson()).toList(),
        if (creativeAssetSelection != null)
          'creativeAssetSelection': creativeAssetSelection!.toJson(),
        if (creativeAssets != null)
          'creativeAssets':
              creativeAssets!.map((value) => value.toJson()).toList(),
        if (creativeFieldAssignments != null)
          'creativeFieldAssignments':
              creativeFieldAssignments!.map((value) => value.toJson()).toList(),
        if (customKeyValues != null) 'customKeyValues': customKeyValues!,
        if (dynamicAssetSelection != null)
          'dynamicAssetSelection': dynamicAssetSelection!,
        if (exitCustomEvents != null)
          'exitCustomEvents':
              exitCustomEvents!.map((value) => value.toJson()).toList(),
        if (fsCommand != null) 'fsCommand': fsCommand!.toJson(),
        if (htmlCode != null) 'htmlCode': htmlCode!,
        if (htmlCodeLocked != null) 'htmlCodeLocked': htmlCodeLocked!,
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (kind != null) 'kind': kind!,
        if (lastModifiedInfo != null)
          'lastModifiedInfo': lastModifiedInfo!.toJson(),
        if (latestTraffickedCreativeId != null)
          'latestTraffickedCreativeId': latestTraffickedCreativeId!,
        if (mediaDescription != null) 'mediaDescription': mediaDescription!,
        if (mediaDuration != null) 'mediaDuration': mediaDuration!,
        if (name != null) 'name': name!,
        if (obaIcon != null) 'obaIcon': obaIcon!.toJson(),
        if (overrideCss != null) 'overrideCss': overrideCss!,
        if (progressOffset != null) 'progressOffset': progressOffset!.toJson(),
        if (redirectUrl != null) 'redirectUrl': redirectUrl!,
        if (renderingId != null) 'renderingId': renderingId!,
        if (renderingIdDimensionValue != null)
          'renderingIdDimensionValue': renderingIdDimensionValue!.toJson(),
        if (requiredFlashPluginVersion != null)
          'requiredFlashPluginVersion': requiredFlashPluginVersion!,
        if (requiredFlashVersion != null)
          'requiredFlashVersion': requiredFlashVersion!,
        if (size != null) 'size': size!.toJson(),
        if (skipOffset != null) 'skipOffset': skipOffset!.toJson(),
        if (skippable != null) 'skippable': skippable!,
        if (sslCompliant != null) 'sslCompliant': sslCompliant!,
        if (sslOverride != null) 'sslOverride': sslOverride!,
        if (studioAdvertiserId != null)
          'studioAdvertiserId': studioAdvertiserId!,
        if (studioCreativeId != null) 'studioCreativeId': studioCreativeId!,
        if (studioTraffickedCreativeId != null)
          'studioTraffickedCreativeId': studioTraffickedCreativeId!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (thirdPartyBackupImageImpressionsUrl != null)
          'thirdPartyBackupImageImpressionsUrl':
              thirdPartyBackupImageImpressionsUrl!,
        if (thirdPartyRichMediaImpressionsUrl != null)
          'thirdPartyRichMediaImpressionsUrl':
              thirdPartyRichMediaImpressionsUrl!,
        if (thirdPartyUrls != null)
          'thirdPartyUrls':
              thirdPartyUrls!.map((value) => value.toJson()).toList(),
        if (timerCustomEvents != null)
          'timerCustomEvents':
              timerCustomEvents!.map((value) => value.toJson()).toList(),
        if (totalFileSize != null) 'totalFileSize': totalFileSize!,
        if (type != null) 'type': type!,
        if (universalAdId != null) 'universalAdId': universalAdId!.toJson(),
        if (version != null) 'version': version!,
      };
}

/// Creative Asset.
class CreativeAsset {
  /// Whether ActionScript3 is enabled for the flash asset.
  ///
  /// This is a read-only field. Applicable to the following creative type:
  /// FLASH_INPAGE. Applicable to DISPLAY when the primary asset type is not
  /// HTML_IMAGE.
  core.bool? actionScript3;

  /// Whether the video or audio asset is active.
  ///
  /// This is a read-only field for VPAID_NON_LINEAR_VIDEO assets. Applicable to
  /// the following creative types: INSTREAM_AUDIO, INSTREAM_VIDEO and all
  /// VPAID.
  core.bool? active;

  /// Additional sizes associated with this creative asset.
  ///
  /// HTML5 asset generated by compatible software such as GWD will be able to
  /// support more sizes this creative asset can render.
  core.List<Size>? additionalSizes;

  /// Possible alignments for an asset.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// RICH_MEDIA_DISPLAY_MULTI_FLOATING_INTERSTITIAL .
  /// Possible string values are:
  /// - "ALIGNMENT_TOP"
  /// - "ALIGNMENT_RIGHT"
  /// - "ALIGNMENT_BOTTOM"
  /// - "ALIGNMENT_LEFT"
  core.String? alignment;

  /// Artwork type of rich media creative.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA.
  /// Possible string values are:
  /// - "ARTWORK_TYPE_FLASH"
  /// - "ARTWORK_TYPE_HTML5"
  /// - "ARTWORK_TYPE_MIXED"
  /// - "ARTWORK_TYPE_IMAGE"
  core.String? artworkType;

  /// Identifier of this asset.
  ///
  /// This is the same identifier returned during creative asset insert
  /// operation. This is a required field. Applicable to all but the following
  /// creative types: all REDIRECT and TRACKING_TEXT.
  CreativeAssetId? assetIdentifier;

  /// Audio stream bit rate in kbps.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// INSTREAM_AUDIO, INSTREAM_VIDEO and all VPAID.
  core.int? audioBitRate;

  /// Audio sample bit rate in hertz.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// INSTREAM_AUDIO, INSTREAM_VIDEO and all VPAID.
  core.int? audioSampleRate;

  /// Exit event configured for the backup image.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA.
  CreativeCustomEvent? backupImageExit;

  /// Detected bit-rate for audio or video asset.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// INSTREAM_AUDIO, INSTREAM_VIDEO and all VPAID.
  core.int? bitRate;

  /// Rich media child asset type.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// VPAID.
  /// Possible string values are:
  /// - "CHILD_ASSET_TYPE_FLASH"
  /// - "CHILD_ASSET_TYPE_VIDEO"
  /// - "CHILD_ASSET_TYPE_IMAGE"
  /// - "CHILD_ASSET_TYPE_DATA"
  core.String? childAssetType;

  /// Size of an asset when collapsed.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA and all VPAID. Additionally, applicable to assets whose
  /// displayType is ASSET_DISPLAY_TYPE_EXPANDING or
  /// ASSET_DISPLAY_TYPE_PEEL_DOWN.
  Size? collapsedSize;

  /// List of companion creatives assigned to an in-stream video creative asset.
  ///
  /// Acceptable values include IDs of existing flash and image creatives.
  /// Applicable to INSTREAM_VIDEO creative type with dynamicAssetSelection set
  /// to true.
  core.List<core.String>? companionCreativeIds;

  /// Custom start time in seconds for making the asset visible.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA. Value must be
  /// greater than or equal to 0.
  core.int? customStartTimeValue;

  /// List of feature dependencies for the creative asset that are detected by
  /// Campaign Manager.
  ///
  /// Feature dependencies are features that a browser must be able to support
  /// in order to render your HTML5 creative correctly. This is a read-only,
  /// auto-generated field. Applicable to the following creative types:
  /// HTML5_BANNER. Applicable to DISPLAY when the primary asset type is not
  /// HTML_IMAGE.
  core.List<core.String>? detectedFeatures;

  /// Type of rich media asset.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA.
  /// Possible string values are:
  /// - "ASSET_DISPLAY_TYPE_INPAGE"
  /// - "ASSET_DISPLAY_TYPE_FLOATING"
  /// - "ASSET_DISPLAY_TYPE_OVERLAY"
  /// - "ASSET_DISPLAY_TYPE_EXPANDING"
  /// - "ASSET_DISPLAY_TYPE_FLASH_IN_FLASH"
  /// - "ASSET_DISPLAY_TYPE_FLASH_IN_FLASH_EXPANDING"
  /// - "ASSET_DISPLAY_TYPE_PEEL_DOWN"
  /// - "ASSET_DISPLAY_TYPE_VPAID_LINEAR"
  /// - "ASSET_DISPLAY_TYPE_VPAID_NON_LINEAR"
  /// - "ASSET_DISPLAY_TYPE_BACKDROP"
  core.String? displayType;

  /// Duration in seconds for which an asset will be displayed.
  ///
  /// Applicable to the following creative types: INSTREAM_AUDIO, INSTREAM_VIDEO
  /// and VPAID_LINEAR_VIDEO. Value must be greater than or equal to 1.
  core.int? duration;

  /// Duration type for which an asset will be displayed.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA.
  /// Possible string values are:
  /// - "ASSET_DURATION_TYPE_AUTO"
  /// - "ASSET_DURATION_TYPE_NONE"
  /// - "ASSET_DURATION_TYPE_CUSTOM"
  core.String? durationType;

  /// Detected expanded dimension for video asset.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// INSTREAM_VIDEO and all VPAID.
  Size? expandedDimension;

  /// File size associated with this creative asset.
  ///
  /// This is a read-only field. Applicable to all but the following creative
  /// types: all REDIRECT and TRACKING_TEXT.
  core.String? fileSize;

  /// Flash version of the asset.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// FLASH_INPAGE, all RICH_MEDIA, and all VPAID. Applicable to DISPLAY when
  /// the primary asset type is not HTML_IMAGE.
  core.int? flashVersion;

  /// Video frame rate for video asset in frames per second.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// INSTREAM_VIDEO and all VPAID.
  core.double? frameRate;

  /// Whether to hide Flash objects flag for an asset.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA.
  core.bool? hideFlashObjects;

  /// Whether to hide selection boxes flag for an asset.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA.
  core.bool? hideSelectionBoxes;

  /// Whether the asset is horizontally locked.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA.
  core.bool? horizontallyLocked;

  /// Numeric ID of this creative asset.
  ///
  /// This is a required field and should not be modified. Applicable to all but
  /// the following creative types: all REDIRECT and TRACKING_TEXT.
  core.String? id;

  /// Dimension value for the ID of the asset.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? idDimensionValue;

  /// Detected duration for audio or video asset.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// INSTREAM_AUDIO, INSTREAM_VIDEO and all VPAID.
  core.double? mediaDuration;

  /// Detected MIME type for audio or video asset.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// INSTREAM_AUDIO, INSTREAM_VIDEO and all VPAID.
  core.String? mimeType;

  /// Offset position for an asset in collapsed mode.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA and all VPAID. Additionally, only applicable to assets whose
  /// displayType is ASSET_DISPLAY_TYPE_EXPANDING or
  /// ASSET_DISPLAY_TYPE_PEEL_DOWN.
  OffsetPosition? offset;

  /// Orientation of video asset.
  ///
  /// This is a read-only, auto-generated field.
  /// Possible string values are:
  /// - "LANDSCAPE"
  /// - "PORTRAIT"
  /// - "SQUARE"
  core.String? orientation;

  /// Whether the backup asset is original or changed by the user in Campaign
  /// Manager.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA.
  core.bool? originalBackup;

  /// Whether this asset is used as a polite load asset.
  core.bool? politeLoad;

  /// Offset position for an asset.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA.
  OffsetPosition? position;

  /// Offset left unit for an asset.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA.
  /// Possible string values are:
  /// - "OFFSET_UNIT_PIXEL"
  /// - "OFFSET_UNIT_PERCENT"
  /// - "OFFSET_UNIT_PIXEL_FROM_CENTER"
  core.String? positionLeftUnit;

  /// Offset top unit for an asset.
  ///
  /// This is a read-only field if the asset displayType is
  /// ASSET_DISPLAY_TYPE_OVERLAY. Applicable to the following creative types:
  /// all RICH_MEDIA.
  /// Possible string values are:
  /// - "OFFSET_UNIT_PIXEL"
  /// - "OFFSET_UNIT_PERCENT"
  /// - "OFFSET_UNIT_PIXEL_FROM_CENTER"
  core.String? positionTopUnit;

  /// Progressive URL for video asset.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// INSTREAM_VIDEO and all VPAID.
  core.String? progressiveServingUrl;

  /// Whether the asset pushes down other content.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA. Additionally,
  /// only applicable when the asset offsets are 0, the collapsedSize.width
  /// matches size.width, and the collapsedSize.height is less than size.height.
  core.bool? pushdown;

  /// Pushdown duration in seconds for an asset.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA.Additionally,
  /// only applicable when the asset pushdown field is true, the offsets are 0,
  /// the collapsedSize.width matches size.width, and the collapsedSize.height
  /// is less than size.height. Acceptable values are 0 to 9.99, inclusive.
  core.double? pushdownDuration;

  /// Role of the asset in relation to creative.
  ///
  /// Applicable to all but the following creative types: all REDIRECT and
  /// TRACKING_TEXT. This is a required field. PRIMARY applies to DISPLAY,
  /// FLASH_INPAGE, HTML5_BANNER, IMAGE, DISPLAY_IMAGE_GALLERY, all RICH_MEDIA
  /// (which may contain multiple primary assets), and all VPAID creatives.
  /// BACKUP_IMAGE applies to FLASH_INPAGE, HTML5_BANNER, all RICH_MEDIA, and
  /// all VPAID creatives. Applicable to DISPLAY when the primary asset type is
  /// not HTML_IMAGE. ADDITIONAL_IMAGE and ADDITIONAL_FLASH apply to
  /// FLASH_INPAGE creatives. OTHER refers to assets from sources other than
  /// Campaign Manager, such as Studio uploaded assets, applicable to all
  /// RICH_MEDIA and all VPAID creatives. PARENT_VIDEO refers to videos uploaded
  /// by the user in Campaign Manager and is applicable to INSTREAM_VIDEO and
  /// VPAID_LINEAR_VIDEO creatives. TRANSCODED_VIDEO refers to videos transcoded
  /// by Campaign Manager from PARENT_VIDEO assets and is applicable to
  /// INSTREAM_VIDEO and VPAID_LINEAR_VIDEO creatives. ALTERNATE_VIDEO refers to
  /// the Campaign Manager representation of child asset videos from Studio, and
  /// is applicable to VPAID_LINEAR_VIDEO creatives. These cannot be added or
  /// removed within Campaign Manager. For VPAID_LINEAR_VIDEO creatives,
  /// PARENT_VIDEO, TRANSCODED_VIDEO and ALTERNATE_VIDEO assets that are marked
  /// active serve as backup in case the VPAID creative cannot be served. Only
  /// PARENT_VIDEO assets can be added or removed for an INSTREAM_VIDEO or
  /// VPAID_LINEAR_VIDEO creative. PARENT_AUDIO refers to audios uploaded by the
  /// user in Campaign Manager and is applicable to INSTREAM_AUDIO creatives.
  /// TRANSCODED_AUDIO refers to audios transcoded by Campaign Manager from
  /// PARENT_AUDIO assets and is applicable to INSTREAM_AUDIO creatives.
  /// Possible string values are:
  /// - "PRIMARY"
  /// - "BACKUP_IMAGE"
  /// - "ADDITIONAL_IMAGE"
  /// - "ADDITIONAL_FLASH"
  /// - "PARENT_VIDEO"
  /// - "TRANSCODED_VIDEO"
  /// - "OTHER"
  /// - "ALTERNATE_VIDEO"
  /// - "PARENT_AUDIO"
  /// - "TRANSCODED_AUDIO"
  core.String? role;

  /// Size associated with this creative asset.
  ///
  /// This is a required field when applicable; however for IMAGE and
  /// FLASH_INPAGE, creatives if left blank, this field will be automatically
  /// set using the actual size of the associated image asset. Applicable to the
  /// following creative types: DISPLAY_IMAGE_GALLERY, FLASH_INPAGE,
  /// HTML5_BANNER, IMAGE, and all RICH_MEDIA. Applicable to DISPLAY when the
  /// primary asset type is not HTML_IMAGE.
  Size? size;

  /// Whether the asset is SSL-compliant.
  ///
  /// This is a read-only field. Applicable to all but the following creative
  /// types: all REDIRECT and TRACKING_TEXT.
  core.bool? sslCompliant;

  /// Initial wait time type before making the asset visible.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA.
  /// Possible string values are:
  /// - "ASSET_START_TIME_TYPE_NONE"
  /// - "ASSET_START_TIME_TYPE_CUSTOM"
  core.String? startTimeType;

  /// Streaming URL for video asset.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// INSTREAM_VIDEO and all VPAID.
  core.String? streamingServingUrl;

  /// Whether the asset is transparent.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA. Additionally,
  /// only applicable to HTML5 assets.
  core.bool? transparency;

  /// Whether the asset is vertically locked.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA.
  core.bool? verticallyLocked;

  /// Window mode options for flash assets.
  ///
  /// Applicable to the following creative types: FLASH_INPAGE,
  /// RICH_MEDIA_DISPLAY_EXPANDING, RICH_MEDIA_IM_EXPAND,
  /// RICH_MEDIA_DISPLAY_BANNER, and RICH_MEDIA_INPAGE_FLOATING.
  /// Possible string values are:
  /// - "OPAQUE"
  /// - "WINDOW"
  /// - "TRANSPARENT"
  core.String? windowMode;

  /// zIndex value of an asset.
  ///
  /// Applicable to the following creative types: all RICH_MEDIA.Additionally,
  /// only applicable to assets whose displayType is NOT one of the following
  /// types: ASSET_DISPLAY_TYPE_INPAGE or ASSET_DISPLAY_TYPE_OVERLAY. Acceptable
  /// values are -999999999 to 999999999, inclusive.
  core.int? zIndex;

  /// File name of zip file.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// HTML5_BANNER.
  core.String? zipFilename;

  /// Size of zip file.
  ///
  /// This is a read-only field. Applicable to the following creative types:
  /// HTML5_BANNER.
  core.String? zipFilesize;

  CreativeAsset();

  CreativeAsset.fromJson(core.Map _json) {
    if (_json.containsKey('actionScript3')) {
      actionScript3 = _json['actionScript3'] as core.bool;
    }
    if (_json.containsKey('active')) {
      active = _json['active'] as core.bool;
    }
    if (_json.containsKey('additionalSizes')) {
      additionalSizes = (_json['additionalSizes'] as core.List)
          .map<Size>((value) =>
              Size.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('alignment')) {
      alignment = _json['alignment'] as core.String;
    }
    if (_json.containsKey('artworkType')) {
      artworkType = _json['artworkType'] as core.String;
    }
    if (_json.containsKey('assetIdentifier')) {
      assetIdentifier = CreativeAssetId.fromJson(
          _json['assetIdentifier'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('audioBitRate')) {
      audioBitRate = _json['audioBitRate'] as core.int;
    }
    if (_json.containsKey('audioSampleRate')) {
      audioSampleRate = _json['audioSampleRate'] as core.int;
    }
    if (_json.containsKey('backupImageExit')) {
      backupImageExit = CreativeCustomEvent.fromJson(
          _json['backupImageExit'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('bitRate')) {
      bitRate = _json['bitRate'] as core.int;
    }
    if (_json.containsKey('childAssetType')) {
      childAssetType = _json['childAssetType'] as core.String;
    }
    if (_json.containsKey('collapsedSize')) {
      collapsedSize = Size.fromJson(
          _json['collapsedSize'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('companionCreativeIds')) {
      companionCreativeIds = (_json['companionCreativeIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('customStartTimeValue')) {
      customStartTimeValue = _json['customStartTimeValue'] as core.int;
    }
    if (_json.containsKey('detectedFeatures')) {
      detectedFeatures = (_json['detectedFeatures'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('displayType')) {
      displayType = _json['displayType'] as core.String;
    }
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.int;
    }
    if (_json.containsKey('durationType')) {
      durationType = _json['durationType'] as core.String;
    }
    if (_json.containsKey('expandedDimension')) {
      expandedDimension = Size.fromJson(
          _json['expandedDimension'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fileSize')) {
      fileSize = _json['fileSize'] as core.String;
    }
    if (_json.containsKey('flashVersion')) {
      flashVersion = _json['flashVersion'] as core.int;
    }
    if (_json.containsKey('frameRate')) {
      frameRate = (_json['frameRate'] as core.num).toDouble();
    }
    if (_json.containsKey('hideFlashObjects')) {
      hideFlashObjects = _json['hideFlashObjects'] as core.bool;
    }
    if (_json.containsKey('hideSelectionBoxes')) {
      hideSelectionBoxes = _json['hideSelectionBoxes'] as core.bool;
    }
    if (_json.containsKey('horizontallyLocked')) {
      horizontallyLocked = _json['horizontallyLocked'] as core.bool;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mediaDuration')) {
      mediaDuration = (_json['mediaDuration'] as core.num).toDouble();
    }
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
    if (_json.containsKey('offset')) {
      offset = OffsetPosition.fromJson(
          _json['offset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('orientation')) {
      orientation = _json['orientation'] as core.String;
    }
    if (_json.containsKey('originalBackup')) {
      originalBackup = _json['originalBackup'] as core.bool;
    }
    if (_json.containsKey('politeLoad')) {
      politeLoad = _json['politeLoad'] as core.bool;
    }
    if (_json.containsKey('position')) {
      position = OffsetPosition.fromJson(
          _json['position'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('positionLeftUnit')) {
      positionLeftUnit = _json['positionLeftUnit'] as core.String;
    }
    if (_json.containsKey('positionTopUnit')) {
      positionTopUnit = _json['positionTopUnit'] as core.String;
    }
    if (_json.containsKey('progressiveServingUrl')) {
      progressiveServingUrl = _json['progressiveServingUrl'] as core.String;
    }
    if (_json.containsKey('pushdown')) {
      pushdown = _json['pushdown'] as core.bool;
    }
    if (_json.containsKey('pushdownDuration')) {
      pushdownDuration = (_json['pushdownDuration'] as core.num).toDouble();
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
    if (_json.containsKey('size')) {
      size =
          Size.fromJson(_json['size'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sslCompliant')) {
      sslCompliant = _json['sslCompliant'] as core.bool;
    }
    if (_json.containsKey('startTimeType')) {
      startTimeType = _json['startTimeType'] as core.String;
    }
    if (_json.containsKey('streamingServingUrl')) {
      streamingServingUrl = _json['streamingServingUrl'] as core.String;
    }
    if (_json.containsKey('transparency')) {
      transparency = _json['transparency'] as core.bool;
    }
    if (_json.containsKey('verticallyLocked')) {
      verticallyLocked = _json['verticallyLocked'] as core.bool;
    }
    if (_json.containsKey('windowMode')) {
      windowMode = _json['windowMode'] as core.String;
    }
    if (_json.containsKey('zIndex')) {
      zIndex = _json['zIndex'] as core.int;
    }
    if (_json.containsKey('zipFilename')) {
      zipFilename = _json['zipFilename'] as core.String;
    }
    if (_json.containsKey('zipFilesize')) {
      zipFilesize = _json['zipFilesize'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actionScript3 != null) 'actionScript3': actionScript3!,
        if (active != null) 'active': active!,
        if (additionalSizes != null)
          'additionalSizes':
              additionalSizes!.map((value) => value.toJson()).toList(),
        if (alignment != null) 'alignment': alignment!,
        if (artworkType != null) 'artworkType': artworkType!,
        if (assetIdentifier != null)
          'assetIdentifier': assetIdentifier!.toJson(),
        if (audioBitRate != null) 'audioBitRate': audioBitRate!,
        if (audioSampleRate != null) 'audioSampleRate': audioSampleRate!,
        if (backupImageExit != null)
          'backupImageExit': backupImageExit!.toJson(),
        if (bitRate != null) 'bitRate': bitRate!,
        if (childAssetType != null) 'childAssetType': childAssetType!,
        if (collapsedSize != null) 'collapsedSize': collapsedSize!.toJson(),
        if (companionCreativeIds != null)
          'companionCreativeIds': companionCreativeIds!,
        if (customStartTimeValue != null)
          'customStartTimeValue': customStartTimeValue!,
        if (detectedFeatures != null) 'detectedFeatures': detectedFeatures!,
        if (displayType != null) 'displayType': displayType!,
        if (duration != null) 'duration': duration!,
        if (durationType != null) 'durationType': durationType!,
        if (expandedDimension != null)
          'expandedDimension': expandedDimension!.toJson(),
        if (fileSize != null) 'fileSize': fileSize!,
        if (flashVersion != null) 'flashVersion': flashVersion!,
        if (frameRate != null) 'frameRate': frameRate!,
        if (hideFlashObjects != null) 'hideFlashObjects': hideFlashObjects!,
        if (hideSelectionBoxes != null)
          'hideSelectionBoxes': hideSelectionBoxes!,
        if (horizontallyLocked != null)
          'horizontallyLocked': horizontallyLocked!,
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (mediaDuration != null) 'mediaDuration': mediaDuration!,
        if (mimeType != null) 'mimeType': mimeType!,
        if (offset != null) 'offset': offset!.toJson(),
        if (orientation != null) 'orientation': orientation!,
        if (originalBackup != null) 'originalBackup': originalBackup!,
        if (politeLoad != null) 'politeLoad': politeLoad!,
        if (position != null) 'position': position!.toJson(),
        if (positionLeftUnit != null) 'positionLeftUnit': positionLeftUnit!,
        if (positionTopUnit != null) 'positionTopUnit': positionTopUnit!,
        if (progressiveServingUrl != null)
          'progressiveServingUrl': progressiveServingUrl!,
        if (pushdown != null) 'pushdown': pushdown!,
        if (pushdownDuration != null) 'pushdownDuration': pushdownDuration!,
        if (role != null) 'role': role!,
        if (size != null) 'size': size!.toJson(),
        if (sslCompliant != null) 'sslCompliant': sslCompliant!,
        if (startTimeType != null) 'startTimeType': startTimeType!,
        if (streamingServingUrl != null)
          'streamingServingUrl': streamingServingUrl!,
        if (transparency != null) 'transparency': transparency!,
        if (verticallyLocked != null) 'verticallyLocked': verticallyLocked!,
        if (windowMode != null) 'windowMode': windowMode!,
        if (zIndex != null) 'zIndex': zIndex!,
        if (zipFilename != null) 'zipFilename': zipFilename!,
        if (zipFilesize != null) 'zipFilesize': zipFilesize!,
      };
}

/// Creative Asset ID.
class CreativeAssetId {
  /// Name of the creative asset.
  ///
  /// This is a required field while inserting an asset. After insertion, this
  /// assetIdentifier is used to identify the uploaded asset. Characters in the
  /// name must be alphanumeric or one of the following: ".-_ ". Spaces are
  /// allowed.
  core.String? name;

  /// Type of asset to upload.
  ///
  /// This is a required field. FLASH and IMAGE are no longer supported for new
  /// uploads. All image assets should use HTML_IMAGE.
  /// Possible string values are:
  /// - "IMAGE"
  /// - "FLASH"
  /// - "VIDEO"
  /// - "HTML"
  /// - "HTML_IMAGE"
  /// - "AUDIO"
  core.String? type;

  CreativeAssetId();

  CreativeAssetId.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (type != null) 'type': type!,
      };
}

/// CreativeAssets contains properties of a creative asset file which will be
/// uploaded or has already been uploaded.
///
/// Refer to the creative sample code for how to upload assets and insert a
/// creative.
class CreativeAssetMetadata {
  /// ID of the creative asset.
  ///
  /// This is a required field.
  CreativeAssetId? assetIdentifier;

  /// List of detected click tags for assets.
  ///
  /// This is a read-only, auto-generated field. This field is empty for a rich
  /// media asset.
  core.List<ClickTag>? clickTags;

  /// List of counter events configured for the asset.
  ///
  /// This is a read-only, auto-generated field and only applicable to a rich
  /// media asset.
  core.List<CreativeCustomEvent>? counterCustomEvents;

  /// List of feature dependencies for the creative asset that are detected by
  /// Campaign Manager.
  ///
  /// Feature dependencies are features that a browser must be able to support
  /// in order to render your HTML5 creative correctly. This is a read-only,
  /// auto-generated field.
  core.List<core.String>? detectedFeatures;

  /// List of exit events configured for the asset.
  ///
  /// This is a read-only, auto-generated field and only applicable to a rich
  /// media asset.
  core.List<CreativeCustomEvent>? exitCustomEvents;

  /// Numeric ID of the asset.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Dimension value for the numeric ID of the asset.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? idDimensionValue;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#creativeAssetMetadata".
  core.String? kind;

  /// True if the uploaded asset is a rich media asset.
  ///
  /// This is a read-only, auto-generated field.
  core.bool? richMedia;

  /// List of timer events configured for the asset.
  ///
  /// This is a read-only, auto-generated field and only applicable to a rich
  /// media asset.
  core.List<CreativeCustomEvent>? timerCustomEvents;

  /// Rules validated during code generation that generated a warning.
  ///
  /// This is a read-only, auto-generated field. Possible values are: -
  /// "ADMOB_REFERENCED" - "ASSET_FORMAT_UNSUPPORTED_DCM" - "ASSET_INVALID" -
  /// "CLICK_TAG_HARD_CODED" - "CLICK_TAG_INVALID" - "CLICK_TAG_IN_GWD" -
  /// "CLICK_TAG_MISSING" - "CLICK_TAG_MORE_THAN_ONE" -
  /// "CLICK_TAG_NON_TOP_LEVEL" - "COMPONENT_UNSUPPORTED_DCM" -
  /// "ENABLER_UNSUPPORTED_METHOD_DCM" - "EXTERNAL_FILE_REFERENCED" -
  /// "FILE_DETAIL_EMPTY" - "FILE_TYPE_INVALID" - "GWD_PROPERTIES_INVALID" -
  /// "HTML5_FEATURE_UNSUPPORTED" - "LINKED_FILE_NOT_FOUND" -
  /// "MAX_FLASH_VERSION_11" - "MRAID_REFERENCED" - "NOT_SSL_COMPLIANT" -
  /// "ORPHANED_ASSET" - "PRIMARY_HTML_MISSING" - "SVG_INVALID" - "ZIP_INVALID"
  core.List<core.String>? warnedValidationRules;

  CreativeAssetMetadata();

  CreativeAssetMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('assetIdentifier')) {
      assetIdentifier = CreativeAssetId.fromJson(
          _json['assetIdentifier'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('clickTags')) {
      clickTags = (_json['clickTags'] as core.List)
          .map<ClickTag>((value) =>
              ClickTag.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('counterCustomEvents')) {
      counterCustomEvents = (_json['counterCustomEvents'] as core.List)
          .map<CreativeCustomEvent>((value) => CreativeCustomEvent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('detectedFeatures')) {
      detectedFeatures = (_json['detectedFeatures'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('exitCustomEvents')) {
      exitCustomEvents = (_json['exitCustomEvents'] as core.List)
          .map<CreativeCustomEvent>((value) => CreativeCustomEvent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('richMedia')) {
      richMedia = _json['richMedia'] as core.bool;
    }
    if (_json.containsKey('timerCustomEvents')) {
      timerCustomEvents = (_json['timerCustomEvents'] as core.List)
          .map<CreativeCustomEvent>((value) => CreativeCustomEvent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('warnedValidationRules')) {
      warnedValidationRules = (_json['warnedValidationRules'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assetIdentifier != null)
          'assetIdentifier': assetIdentifier!.toJson(),
        if (clickTags != null)
          'clickTags': clickTags!.map((value) => value.toJson()).toList(),
        if (counterCustomEvents != null)
          'counterCustomEvents':
              counterCustomEvents!.map((value) => value.toJson()).toList(),
        if (detectedFeatures != null) 'detectedFeatures': detectedFeatures!,
        if (exitCustomEvents != null)
          'exitCustomEvents':
              exitCustomEvents!.map((value) => value.toJson()).toList(),
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (kind != null) 'kind': kind!,
        if (richMedia != null) 'richMedia': richMedia!,
        if (timerCustomEvents != null)
          'timerCustomEvents':
              timerCustomEvents!.map((value) => value.toJson()).toList(),
        if (warnedValidationRules != null)
          'warnedValidationRules': warnedValidationRules!,
      };
}

/// Encapsulates the list of rules for asset selection and a default asset in
/// case none of the rules match.
///
/// Applicable to INSTREAM_VIDEO creatives.
class CreativeAssetSelection {
  /// A creativeAssets\[\].id.
  ///
  /// This should refer to one of the parent assets in this creative, and will
  /// be served if none of the rules match. This is a required field.
  core.String? defaultAssetId;

  /// Rules determine which asset will be served to a viewer.
  ///
  /// Rules will be evaluated in the order in which they are stored in this
  /// list. This list must contain at least one rule. Applicable to
  /// INSTREAM_VIDEO creatives.
  core.List<Rule>? rules;

  CreativeAssetSelection();

  CreativeAssetSelection.fromJson(core.Map _json) {
    if (_json.containsKey('defaultAssetId')) {
      defaultAssetId = _json['defaultAssetId'] as core.String;
    }
    if (_json.containsKey('rules')) {
      rules = (_json['rules'] as core.List)
          .map<Rule>((value) =>
              Rule.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultAssetId != null) 'defaultAssetId': defaultAssetId!,
        if (rules != null)
          'rules': rules!.map((value) => value.toJson()).toList(),
      };
}

/// Creative Assignment.
class CreativeAssignment {
  /// Whether this creative assignment is active.
  ///
  /// When true, the creative will be included in the ad's rotation.
  core.bool? active;

  /// Whether applicable event tags should fire when this creative assignment is
  /// rendered.
  ///
  /// If this value is unset when the ad is inserted or updated, it will default
  /// to true for all creative types EXCEPT for INTERNAL_REDIRECT,
  /// INTERSTITIAL_INTERNAL_REDIRECT, and INSTREAM_VIDEO.
  core.bool? applyEventTags;

  /// Click-through URL of the creative assignment.
  ClickThroughUrl? clickThroughUrl;

  /// Companion creative overrides for this creative assignment.
  ///
  /// Applicable to video ads.
  core.List<CompanionClickThroughOverride>? companionCreativeOverrides;

  /// Creative group assignments for this creative assignment.
  ///
  /// Only one assignment per creative group number is allowed for a maximum of
  /// two assignments.
  core.List<CreativeGroupAssignment>? creativeGroupAssignments;

  /// ID of the creative to be assigned.
  ///
  /// This is a required field.
  core.String? creativeId;

  /// Dimension value for the ID of the creative.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? creativeIdDimensionValue;
  core.DateTime? endTime;

  /// Rich media exit overrides for this creative assignment.
  ///
  /// Applicable when the creative type is any of the following: - DISPLAY -
  /// RICH_MEDIA_INPAGE - RICH_MEDIA_INPAGE_FLOATING - RICH_MEDIA_IM_EXPAND -
  /// RICH_MEDIA_EXPANDING - RICH_MEDIA_INTERSTITIAL_FLOAT -
  /// RICH_MEDIA_MOBILE_IN_APP - RICH_MEDIA_MULTI_FLOATING -
  /// RICH_MEDIA_PEEL_DOWN - VPAID_LINEAR - VPAID_NON_LINEAR
  core.List<RichMediaExitOverride>? richMediaExitOverrides;

  /// Sequence number of the creative assignment, applicable when the rotation
  /// type is CREATIVE_ROTATION_TYPE_SEQUENTIAL.
  ///
  /// Acceptable values are 1 to 65535, inclusive.
  core.int? sequence;

  /// Whether the creative to be assigned is SSL-compliant.
  ///
  /// This is a read-only field that is auto-generated when the ad is inserted
  /// or updated.
  core.bool? sslCompliant;
  core.DateTime? startTime;

  /// Weight of the creative assignment, applicable when the rotation type is
  /// CREATIVE_ROTATION_TYPE_RANDOM.
  ///
  /// Value must be greater than or equal to 1.
  core.int? weight;

  CreativeAssignment();

  CreativeAssignment.fromJson(core.Map _json) {
    if (_json.containsKey('active')) {
      active = _json['active'] as core.bool;
    }
    if (_json.containsKey('applyEventTags')) {
      applyEventTags = _json['applyEventTags'] as core.bool;
    }
    if (_json.containsKey('clickThroughUrl')) {
      clickThroughUrl = ClickThroughUrl.fromJson(
          _json['clickThroughUrl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('companionCreativeOverrides')) {
      companionCreativeOverrides =
          (_json['companionCreativeOverrides'] as core.List)
              .map<CompanionClickThroughOverride>((value) =>
                  CompanionClickThroughOverride.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('creativeGroupAssignments')) {
      creativeGroupAssignments =
          (_json['creativeGroupAssignments'] as core.List)
              .map<CreativeGroupAssignment>((value) =>
                  CreativeGroupAssignment.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('creativeId')) {
      creativeId = _json['creativeId'] as core.String;
    }
    if (_json.containsKey('creativeIdDimensionValue')) {
      creativeIdDimensionValue = DimensionValue.fromJson(
          _json['creativeIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('endTime')) {
      endTime = core.DateTime.parse(_json['endTime'] as core.String);
    }
    if (_json.containsKey('richMediaExitOverrides')) {
      richMediaExitOverrides = (_json['richMediaExitOverrides'] as core.List)
          .map<RichMediaExitOverride>((value) => RichMediaExitOverride.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('sequence')) {
      sequence = _json['sequence'] as core.int;
    }
    if (_json.containsKey('sslCompliant')) {
      sslCompliant = _json['sslCompliant'] as core.bool;
    }
    if (_json.containsKey('startTime')) {
      startTime = core.DateTime.parse(_json['startTime'] as core.String);
    }
    if (_json.containsKey('weight')) {
      weight = _json['weight'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (active != null) 'active': active!,
        if (applyEventTags != null) 'applyEventTags': applyEventTags!,
        if (clickThroughUrl != null)
          'clickThroughUrl': clickThroughUrl!.toJson(),
        if (companionCreativeOverrides != null)
          'companionCreativeOverrides': companionCreativeOverrides!
              .map((value) => value.toJson())
              .toList(),
        if (creativeGroupAssignments != null)
          'creativeGroupAssignments':
              creativeGroupAssignments!.map((value) => value.toJson()).toList(),
        if (creativeId != null) 'creativeId': creativeId!,
        if (creativeIdDimensionValue != null)
          'creativeIdDimensionValue': creativeIdDimensionValue!.toJson(),
        if (endTime != null) 'endTime': endTime!.toIso8601String(),
        if (richMediaExitOverrides != null)
          'richMediaExitOverrides':
              richMediaExitOverrides!.map((value) => value.toJson()).toList(),
        if (sequence != null) 'sequence': sequence!,
        if (sslCompliant != null) 'sslCompliant': sslCompliant!,
        if (startTime != null) 'startTime': startTime!.toIso8601String(),
        if (weight != null) 'weight': weight!,
      };
}

/// Click-through URL
class CreativeClickThroughUrl {
  /// Read-only convenience field representing the actual URL that will be used
  /// for this click-through.
  ///
  /// The URL is computed as follows: - If landingPageId is specified then that
  /// landing page's URL is assigned to this field. - Otherwise, the
  /// customClickThroughUrl is assigned to this field.
  core.String? computedClickThroughUrl;

  /// Custom click-through URL.
  ///
  /// Applicable if the landingPageId field is left unset.
  core.String? customClickThroughUrl;

  /// ID of the landing page for the click-through URL.
  core.String? landingPageId;

  CreativeClickThroughUrl();

  CreativeClickThroughUrl.fromJson(core.Map _json) {
    if (_json.containsKey('computedClickThroughUrl')) {
      computedClickThroughUrl = _json['computedClickThroughUrl'] as core.String;
    }
    if (_json.containsKey('customClickThroughUrl')) {
      customClickThroughUrl = _json['customClickThroughUrl'] as core.String;
    }
    if (_json.containsKey('landingPageId')) {
      landingPageId = _json['landingPageId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (computedClickThroughUrl != null)
          'computedClickThroughUrl': computedClickThroughUrl!,
        if (customClickThroughUrl != null)
          'customClickThroughUrl': customClickThroughUrl!,
        if (landingPageId != null) 'landingPageId': landingPageId!,
      };
}

/// Creative Custom Event.
class CreativeCustomEvent {
  /// Unique ID of this event used by Reporting and Data Transfer.
  ///
  /// This is a read-only field.
  core.String? advertiserCustomEventId;

  /// User-entered name for the event.
  core.String? advertiserCustomEventName;

  /// Type of the event.
  ///
  /// This is a read-only field.
  /// Possible string values are:
  /// - "ADVERTISER_EVENT_TIMER"
  /// - "ADVERTISER_EVENT_EXIT"
  /// - "ADVERTISER_EVENT_COUNTER"
  core.String? advertiserCustomEventType;

  /// Artwork label column, used to link events in Campaign Manager back to
  /// events in Studio.
  ///
  /// This is a required field and should not be modified after insertion.
  core.String? artworkLabel;

  /// Artwork type used by the creative.This is a read-only field.
  /// Possible string values are:
  /// - "ARTWORK_TYPE_FLASH"
  /// - "ARTWORK_TYPE_HTML5"
  /// - "ARTWORK_TYPE_MIXED"
  /// - "ARTWORK_TYPE_IMAGE"
  core.String? artworkType;

  /// Exit click-through URL for the event.
  ///
  /// This field is used only for exit events.
  CreativeClickThroughUrl? exitClickThroughUrl;

  /// ID of this event.
  ///
  /// This is a required field and should not be modified after insertion.
  core.String? id;

  /// Properties for rich media popup windows.
  ///
  /// This field is used only for exit events.
  PopupWindowProperties? popupWindowProperties;

  /// Target type used by the event.
  /// Possible string values are:
  /// - "TARGET_BLANK"
  /// - "TARGET_TOP"
  /// - "TARGET_SELF"
  /// - "TARGET_PARENT"
  /// - "TARGET_POPUP"
  core.String? targetType;

  /// Video reporting ID, used to differentiate multiple videos in a single
  /// creative.
  ///
  /// This is a read-only field.
  core.String? videoReportingId;

  CreativeCustomEvent();

  CreativeCustomEvent.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserCustomEventId')) {
      advertiserCustomEventId = _json['advertiserCustomEventId'] as core.String;
    }
    if (_json.containsKey('advertiserCustomEventName')) {
      advertiserCustomEventName =
          _json['advertiserCustomEventName'] as core.String;
    }
    if (_json.containsKey('advertiserCustomEventType')) {
      advertiserCustomEventType =
          _json['advertiserCustomEventType'] as core.String;
    }
    if (_json.containsKey('artworkLabel')) {
      artworkLabel = _json['artworkLabel'] as core.String;
    }
    if (_json.containsKey('artworkType')) {
      artworkType = _json['artworkType'] as core.String;
    }
    if (_json.containsKey('exitClickThroughUrl')) {
      exitClickThroughUrl = CreativeClickThroughUrl.fromJson(
          _json['exitClickThroughUrl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('popupWindowProperties')) {
      popupWindowProperties = PopupWindowProperties.fromJson(
          _json['popupWindowProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('targetType')) {
      targetType = _json['targetType'] as core.String;
    }
    if (_json.containsKey('videoReportingId')) {
      videoReportingId = _json['videoReportingId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserCustomEventId != null)
          'advertiserCustomEventId': advertiserCustomEventId!,
        if (advertiserCustomEventName != null)
          'advertiserCustomEventName': advertiserCustomEventName!,
        if (advertiserCustomEventType != null)
          'advertiserCustomEventType': advertiserCustomEventType!,
        if (artworkLabel != null) 'artworkLabel': artworkLabel!,
        if (artworkType != null) 'artworkType': artworkType!,
        if (exitClickThroughUrl != null)
          'exitClickThroughUrl': exitClickThroughUrl!.toJson(),
        if (id != null) 'id': id!,
        if (popupWindowProperties != null)
          'popupWindowProperties': popupWindowProperties!.toJson(),
        if (targetType != null) 'targetType': targetType!,
        if (videoReportingId != null) 'videoReportingId': videoReportingId!,
      };
}

/// Contains properties of a creative field.
class CreativeField {
  /// Account ID of this creative field.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// Advertiser ID of this creative field.
  ///
  /// This is a required field on insertion.
  core.String? advertiserId;

  /// Dimension value for the ID of the advertiser.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? advertiserIdDimensionValue;

  /// ID of this creative field.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#creativeField".
  core.String? kind;

  /// Name of this creative field.
  ///
  /// This is a required field and must be less than 256 characters long and
  /// unique among creative fields of the same advertiser.
  core.String? name;

  /// Subaccount ID of this creative field.
  ///
  /// This is a read-only field that can be left blank.
  core.String? subaccountId;

  CreativeField();

  CreativeField.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
      };
}

/// Creative Field Assignment.
class CreativeFieldAssignment {
  /// ID of the creative field.
  core.String? creativeFieldId;

  /// ID of the creative field value.
  core.String? creativeFieldValueId;

  CreativeFieldAssignment();

  CreativeFieldAssignment.fromJson(core.Map _json) {
    if (_json.containsKey('creativeFieldId')) {
      creativeFieldId = _json['creativeFieldId'] as core.String;
    }
    if (_json.containsKey('creativeFieldValueId')) {
      creativeFieldValueId = _json['creativeFieldValueId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creativeFieldId != null) 'creativeFieldId': creativeFieldId!,
        if (creativeFieldValueId != null)
          'creativeFieldValueId': creativeFieldValueId!,
      };
}

/// Contains properties of a creative field value.
class CreativeFieldValue {
  /// ID of this creative field value.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#creativeFieldValue".
  core.String? kind;

  /// Value of this creative field value.
  ///
  /// It needs to be less than 256 characters in length and unique per creative
  /// field.
  core.String? value;

  CreativeFieldValue();

  CreativeFieldValue.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (value != null) 'value': value!,
      };
}

/// Creative Field Value List Response
class CreativeFieldValuesListResponse {
  /// Creative field value collection.
  core.List<CreativeFieldValue>? creativeFieldValues;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#creativeFieldValuesListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  CreativeFieldValuesListResponse();

  CreativeFieldValuesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('creativeFieldValues')) {
      creativeFieldValues = (_json['creativeFieldValues'] as core.List)
          .map<CreativeFieldValue>((value) => CreativeFieldValue.fromJson(
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
        if (creativeFieldValues != null)
          'creativeFieldValues':
              creativeFieldValues!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Creative Field List Response
class CreativeFieldsListResponse {
  /// Creative field collection.
  core.List<CreativeField>? creativeFields;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#creativeFieldsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  CreativeFieldsListResponse();

  CreativeFieldsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('creativeFields')) {
      creativeFields = (_json['creativeFields'] as core.List)
          .map<CreativeField>((value) => CreativeField.fromJson(
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
        if (creativeFields != null)
          'creativeFields':
              creativeFields!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Contains properties of a creative group.
class CreativeGroup {
  /// Account ID of this creative group.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// Advertiser ID of this creative group.
  ///
  /// This is a required field on insertion.
  core.String? advertiserId;

  /// Dimension value for the ID of the advertiser.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? advertiserIdDimensionValue;

  /// Subgroup of the creative group.
  ///
  /// Assign your creative groups to a subgroup in order to filter or manage
  /// them more easily. This field is required on insertion and is read-only
  /// after insertion. Acceptable values are 1 to 2, inclusive.
  core.int? groupNumber;

  /// ID of this creative group.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#creativeGroup".
  core.String? kind;

  /// Name of this creative group.
  ///
  /// This is a required field and must be less than 256 characters long and
  /// unique among creative groups of the same advertiser.
  core.String? name;

  /// Subaccount ID of this creative group.
  ///
  /// This is a read-only field that can be left blank.
  core.String? subaccountId;

  CreativeGroup();

  CreativeGroup.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('groupNumber')) {
      groupNumber = _json['groupNumber'] as core.int;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (groupNumber != null) 'groupNumber': groupNumber!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
      };
}

/// Creative Group Assignment.
class CreativeGroupAssignment {
  /// ID of the creative group to be assigned.
  core.String? creativeGroupId;

  /// Creative group number of the creative group assignment.
  /// Possible string values are:
  /// - "CREATIVE_GROUP_ONE"
  /// - "CREATIVE_GROUP_TWO"
  core.String? creativeGroupNumber;

  CreativeGroupAssignment();

  CreativeGroupAssignment.fromJson(core.Map _json) {
    if (_json.containsKey('creativeGroupId')) {
      creativeGroupId = _json['creativeGroupId'] as core.String;
    }
    if (_json.containsKey('creativeGroupNumber')) {
      creativeGroupNumber = _json['creativeGroupNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creativeGroupId != null) 'creativeGroupId': creativeGroupId!,
        if (creativeGroupNumber != null)
          'creativeGroupNumber': creativeGroupNumber!,
      };
}

/// Creative Group List Response
class CreativeGroupsListResponse {
  /// Creative group collection.
  core.List<CreativeGroup>? creativeGroups;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#creativeGroupsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  CreativeGroupsListResponse();

  CreativeGroupsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('creativeGroups')) {
      creativeGroups = (_json['creativeGroups'] as core.List)
          .map<CreativeGroup>((value) => CreativeGroup.fromJson(
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
        if (creativeGroups != null)
          'creativeGroups':
              creativeGroups!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Creative optimization settings.
class CreativeOptimizationConfiguration {
  /// ID of this creative optimization config.
  ///
  /// This field is auto-generated when the campaign is inserted or updated. It
  /// can be null for existing campaigns.
  core.String? id;

  /// Name of this creative optimization config.
  ///
  /// This is a required field and must be less than 129 characters long.
  core.String? name;

  /// List of optimization activities associated with this configuration.
  core.List<OptimizationActivity>? optimizationActivitys;

  /// Optimization model for this configuration.
  /// Possible string values are:
  /// - "CLICK"
  /// - "POST_CLICK"
  /// - "POST_IMPRESSION"
  /// - "POST_CLICK_AND_IMPRESSION"
  /// - "VIDEO_COMPLETION"
  core.String? optimizationModel;

  CreativeOptimizationConfiguration();

  CreativeOptimizationConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('optimizationActivitys')) {
      optimizationActivitys = (_json['optimizationActivitys'] as core.List)
          .map<OptimizationActivity>((value) => OptimizationActivity.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('optimizationModel')) {
      optimizationModel = _json['optimizationModel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
        if (optimizationActivitys != null)
          'optimizationActivitys':
              optimizationActivitys!.map((value) => value.toJson()).toList(),
        if (optimizationModel != null) 'optimizationModel': optimizationModel!,
      };
}

/// Creative Rotation.
class CreativeRotation {
  /// Creative assignments in this creative rotation.
  core.List<CreativeAssignment>? creativeAssignments;

  /// Creative optimization configuration that is used by this ad.
  ///
  /// It should refer to one of the existing optimization configurations in the
  /// ad's campaign. If it is unset or set to 0, then the campaign's default
  /// optimization configuration will be used for this ad.
  core.String? creativeOptimizationConfigurationId;

  /// Type of creative rotation.
  ///
  /// Can be used to specify whether to use sequential or random rotation.
  /// Possible string values are:
  /// - "CREATIVE_ROTATION_TYPE_SEQUENTIAL"
  /// - "CREATIVE_ROTATION_TYPE_RANDOM"
  core.String? type;

  /// Strategy for calculating weights.
  ///
  /// Used with CREATIVE_ROTATION_TYPE_RANDOM.
  /// Possible string values are:
  /// - "WEIGHT_STRATEGY_EQUAL"
  /// - "WEIGHT_STRATEGY_CUSTOM"
  /// - "WEIGHT_STRATEGY_HIGHEST_CTR"
  /// - "WEIGHT_STRATEGY_OPTIMIZED"
  core.String? weightCalculationStrategy;

  CreativeRotation();

  CreativeRotation.fromJson(core.Map _json) {
    if (_json.containsKey('creativeAssignments')) {
      creativeAssignments = (_json['creativeAssignments'] as core.List)
          .map<CreativeAssignment>((value) => CreativeAssignment.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('creativeOptimizationConfigurationId')) {
      creativeOptimizationConfigurationId =
          _json['creativeOptimizationConfigurationId'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('weightCalculationStrategy')) {
      weightCalculationStrategy =
          _json['weightCalculationStrategy'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creativeAssignments != null)
          'creativeAssignments':
              creativeAssignments!.map((value) => value.toJson()).toList(),
        if (creativeOptimizationConfigurationId != null)
          'creativeOptimizationConfigurationId':
              creativeOptimizationConfigurationId!,
        if (type != null) 'type': type!,
        if (weightCalculationStrategy != null)
          'weightCalculationStrategy': weightCalculationStrategy!,
      };
}

/// Creative List Response
class CreativesListResponse {
  /// Creative collection.
  core.List<Creative>? creatives;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#creativesListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  CreativesListResponse();

  CreativesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('creatives')) {
      creatives = (_json['creatives'] as core.List)
          .map<Creative>((value) =>
              Creative.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (creatives != null)
          'creatives': creatives!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Represents fields that are compatible to be selected for a report of type
/// "CROSS_DIMENSION_REACH".
class CrossDimensionReachReportCompatibleFields {
  /// Dimensions which are compatible to be selected in the "breakdown" section
  /// of the report.
  core.List<Dimension>? breakdown;

  /// Dimensions which are compatible to be selected in the "dimensionFilters"
  /// section of the report.
  core.List<Dimension>? dimensionFilters;

  /// The kind of resource this is, in this case
  /// dfareporting#crossDimensionReachReportCompatibleFields.
  core.String? kind;

  /// Metrics which are compatible to be selected in the "metricNames" section
  /// of the report.
  core.List<Metric>? metrics;

  /// Metrics which are compatible to be selected in the "overlapMetricNames"
  /// section of the report.
  core.List<Metric>? overlapMetrics;

  CrossDimensionReachReportCompatibleFields();

  CrossDimensionReachReportCompatibleFields.fromJson(core.Map _json) {
    if (_json.containsKey('breakdown')) {
      breakdown = (_json['breakdown'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dimensionFilters')) {
      dimensionFilters = (_json['dimensionFilters'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.List)
          .map<Metric>((value) =>
              Metric.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('overlapMetrics')) {
      overlapMetrics = (_json['overlapMetrics'] as core.List)
          .map<Metric>((value) =>
              Metric.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (breakdown != null)
          'breakdown': breakdown!.map((value) => value.toJson()).toList(),
        if (dimensionFilters != null)
          'dimensionFilters':
              dimensionFilters!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (metrics != null)
          'metrics': metrics!.map((value) => value.toJson()).toList(),
        if (overlapMetrics != null)
          'overlapMetrics':
              overlapMetrics!.map((value) => value.toJson()).toList(),
      };
}

/// Experimental feature (no support provided) A custom event represents a third
/// party impression, a third party click, an annotation on a first party
/// impression, or an annotation on a first party click.
class CustomEvent {
  /// Annotate a click event.
  ///
  /// This field is mutually exclusive with insertEvent and
  /// annotateImpressionEvent. This or insertEvent and annotateImpressionEvent
  /// is a required field.
  CustomEventClickAnnotation? annotateClickEvent;

  /// Annotate an impression.
  ///
  /// This field is mutually exclusive with insertEvent and annotateClickEvent.
  /// This or insertEvent and annotateClickEvent is a required field.
  CustomEventImpressionAnnotation? annotateImpressionEvent;

  /// Custom variables associated with the event.
  core.List<CustomVariable>? customVariables;

  /// The type of event.
  ///
  /// If INSERT, the fields in insertEvent need to be populated. If ANNOTATE,
  /// the fields in either annotateClickEvent or annotateImpressionEvent need to
  /// be populated.
  /// Possible string values are:
  /// - "UNKNOWN"
  /// - "INSERT"
  /// - "ANNOTATE"
  core.String? eventType;

  /// Floodlight configuration ID of the advertiser the event is linked to.
  ///
  /// This is a required field.
  core.String? floodlightConfigurationId;

  /// Insert custom event.
  ///
  /// This field is mutually exclusive with annotateClickEvent and
  /// annotateImpressionEvent. This or annotateClickEvent and
  /// annotateImpressionEvent is a required field.
  CustomEventInsert? insertEvent;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#customEvent".
  core.String? kind;

  /// The ordinal of this custom event.
  ///
  /// This is a required field.
  core.String? ordinal;

  /// The timestamp of this custom event, in Unix epoch micros.
  ///
  /// This is a required field.
  core.String? timestampMicros;

  CustomEvent();

  CustomEvent.fromJson(core.Map _json) {
    if (_json.containsKey('annotateClickEvent')) {
      annotateClickEvent = CustomEventClickAnnotation.fromJson(
          _json['annotateClickEvent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('annotateImpressionEvent')) {
      annotateImpressionEvent = CustomEventImpressionAnnotation.fromJson(
          _json['annotateImpressionEvent']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('customVariables')) {
      customVariables = (_json['customVariables'] as core.List)
          .map<CustomVariable>((value) => CustomVariable.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('eventType')) {
      eventType = _json['eventType'] as core.String;
    }
    if (_json.containsKey('floodlightConfigurationId')) {
      floodlightConfigurationId =
          _json['floodlightConfigurationId'] as core.String;
    }
    if (_json.containsKey('insertEvent')) {
      insertEvent = CustomEventInsert.fromJson(
          _json['insertEvent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('ordinal')) {
      ordinal = _json['ordinal'] as core.String;
    }
    if (_json.containsKey('timestampMicros')) {
      timestampMicros = _json['timestampMicros'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotateClickEvent != null)
          'annotateClickEvent': annotateClickEvent!.toJson(),
        if (annotateImpressionEvent != null)
          'annotateImpressionEvent': annotateImpressionEvent!.toJson(),
        if (customVariables != null)
          'customVariables':
              customVariables!.map((value) => value.toJson()).toList(),
        if (eventType != null) 'eventType': eventType!,
        if (floodlightConfigurationId != null)
          'floodlightConfigurationId': floodlightConfigurationId!,
        if (insertEvent != null) 'insertEvent': insertEvent!.toJson(),
        if (kind != null) 'kind': kind!,
        if (ordinal != null) 'ordinal': ordinal!,
        if (timestampMicros != null) 'timestampMicros': timestampMicros!,
      };
}

/// Annotate a click event.
class CustomEventClickAnnotation {
  /// The Google click ID.
  ///
  /// Use this field to annotate the click associated with the gclid.
  core.String? gclid;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#customEventClickAnnotation".
  core.String? kind;

  CustomEventClickAnnotation();

  CustomEventClickAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('gclid')) {
      gclid = _json['gclid'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gclid != null) 'gclid': gclid!,
        if (kind != null) 'kind': kind!,
      };
}

/// The error code and description for a custom event that failed to insert.
class CustomEventError {
  /// The error code.
  /// Possible string values are:
  /// - "UNKNOWN"
  /// - "INVALID_ARGUMENT"
  /// - "INTERNAL"
  /// - "PERMISSION_DENIED"
  /// - "NOT_FOUND"
  core.String? code;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#customEventError".
  core.String? kind;

  /// A description of the error.
  core.String? message;

  CustomEventError();

  CustomEventError.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (kind != null) 'kind': kind!,
        if (message != null) 'message': message!,
      };
}

/// Annotate an impression.
class CustomEventImpressionAnnotation {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#customEventImpressionAnnotation".
  core.String? kind;

  /// The path impression ID.
  ///
  /// Use this field to annotate the impression associated with the
  /// pathImpressionId.
  core.String? pathImpressionId;

  CustomEventImpressionAnnotation();

  CustomEventImpressionAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('pathImpressionId')) {
      pathImpressionId = _json['pathImpressionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (pathImpressionId != null) 'pathImpressionId': pathImpressionId!,
      };
}

/// Custom event to be inserted.
class CustomEventInsert {
  /// Campaign Manager dimensions associated with the event.
  CampaignManagerIds? cmDimensions;

  /// DV360 dimensions associated with the event.
  DV3Ids? dv3Dimensions;

  /// The type of event to insert.
  /// Possible string values are:
  /// - "UNKNOWN"
  /// - "IMPRESSION"
  /// - "CLICK"
  core.String? insertEventType;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#customEventInsert".
  core.String? kind;

  /// The match ID field.
  ///
  /// A match ID is your own first-party identifier that has been synced with
  /// Google using the match ID feature in Floodlight. This field is mutually
  /// exclusive with mobileDeviceId, and at least one of the two fields is
  /// required.
  core.String? matchId;

  /// The mobile device ID.
  ///
  /// This field is mutually exclusive with matchId, and at least one of the two
  /// fields is required.
  core.String? mobileDeviceId;

  CustomEventInsert();

  CustomEventInsert.fromJson(core.Map _json) {
    if (_json.containsKey('cmDimensions')) {
      cmDimensions = CampaignManagerIds.fromJson(
          _json['cmDimensions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dv3Dimensions')) {
      dv3Dimensions = DV3Ids.fromJson(
          _json['dv3Dimensions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertEventType')) {
      insertEventType = _json['insertEventType'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('matchId')) {
      matchId = _json['matchId'] as core.String;
    }
    if (_json.containsKey('mobileDeviceId')) {
      mobileDeviceId = _json['mobileDeviceId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cmDimensions != null) 'cmDimensions': cmDimensions!.toJson(),
        if (dv3Dimensions != null) 'dv3Dimensions': dv3Dimensions!.toJson(),
        if (insertEventType != null) 'insertEventType': insertEventType!,
        if (kind != null) 'kind': kind!,
        if (matchId != null) 'matchId': matchId!,
        if (mobileDeviceId != null) 'mobileDeviceId': mobileDeviceId!,
      };
}

/// The original custom event that was inserted and whether there were any
/// errors.
class CustomEventStatus {
  /// The original custom event that was inserted.
  CustomEvent? customEvent;

  /// A list of errors related to this custom event.
  core.List<CustomEventError>? errors;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#customEventStatus".
  core.String? kind;

  CustomEventStatus();

  CustomEventStatus.fromJson(core.Map _json) {
    if (_json.containsKey('customEvent')) {
      customEvent = CustomEvent.fromJson(
          _json['customEvent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<CustomEventError>((value) => CustomEventError.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customEvent != null) 'customEvent': customEvent!.toJson(),
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Insert Custom Events Request.
class CustomEventsBatchInsertRequest {
  /// The set of custom events to insert.
  core.List<CustomEvent>? customEvents;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#customEventsBatchInsertRequest".
  core.String? kind;

  CustomEventsBatchInsertRequest();

  CustomEventsBatchInsertRequest.fromJson(core.Map _json) {
    if (_json.containsKey('customEvents')) {
      customEvents = (_json['customEvents'] as core.List)
          .map<CustomEvent>((value) => CustomEvent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customEvents != null)
          'customEvents': customEvents!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Insert Custom Events Response.
class CustomEventsBatchInsertResponse {
  /// Indicates that some or all custom events failed to insert.
  core.bool? hasFailures;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#customEventsBatchInsertResponse".
  core.String? kind;

  /// The insert status of each custom event.
  ///
  /// Statuses are returned in the same order that conversions are inserted.
  core.List<CustomEventStatus>? status;

  CustomEventsBatchInsertResponse();

  CustomEventsBatchInsertResponse.fromJson(core.Map _json) {
    if (_json.containsKey('hasFailures')) {
      hasFailures = _json['hasFailures'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = (_json['status'] as core.List)
          .map<CustomEventStatus>((value) => CustomEventStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hasFailures != null) 'hasFailures': hasFailures!,
        if (kind != null) 'kind': kind!,
        if (status != null)
          'status': status!.map((value) => value.toJson()).toList(),
      };
}

/// A custom floodlight variable.
class CustomFloodlightVariable {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#customFloodlightVariable".
  core.String? kind;

  /// The type of custom floodlight variable to supply a value for.
  ///
  /// These map to the "u\[1-20\]=" in the tags.
  /// Possible string values are:
  /// - "U1"
  /// - "U2"
  /// - "U3"
  /// - "U4"
  /// - "U5"
  /// - "U6"
  /// - "U7"
  /// - "U8"
  /// - "U9"
  /// - "U10"
  /// - "U11"
  /// - "U12"
  /// - "U13"
  /// - "U14"
  /// - "U15"
  /// - "U16"
  /// - "U17"
  /// - "U18"
  /// - "U19"
  /// - "U20"
  /// - "U21"
  /// - "U22"
  /// - "U23"
  /// - "U24"
  /// - "U25"
  /// - "U26"
  /// - "U27"
  /// - "U28"
  /// - "U29"
  /// - "U30"
  /// - "U31"
  /// - "U32"
  /// - "U33"
  /// - "U34"
  /// - "U35"
  /// - "U36"
  /// - "U37"
  /// - "U38"
  /// - "U39"
  /// - "U40"
  /// - "U41"
  /// - "U42"
  /// - "U43"
  /// - "U44"
  /// - "U45"
  /// - "U46"
  /// - "U47"
  /// - "U48"
  /// - "U49"
  /// - "U50"
  /// - "U51"
  /// - "U52"
  /// - "U53"
  /// - "U54"
  /// - "U55"
  /// - "U56"
  /// - "U57"
  /// - "U58"
  /// - "U59"
  /// - "U60"
  /// - "U61"
  /// - "U62"
  /// - "U63"
  /// - "U64"
  /// - "U65"
  /// - "U66"
  /// - "U67"
  /// - "U68"
  /// - "U69"
  /// - "U70"
  /// - "U71"
  /// - "U72"
  /// - "U73"
  /// - "U74"
  /// - "U75"
  /// - "U76"
  /// - "U77"
  /// - "U78"
  /// - "U79"
  /// - "U80"
  /// - "U81"
  /// - "U82"
  /// - "U83"
  /// - "U84"
  /// - "U85"
  /// - "U86"
  /// - "U87"
  /// - "U88"
  /// - "U89"
  /// - "U90"
  /// - "U91"
  /// - "U92"
  /// - "U93"
  /// - "U94"
  /// - "U95"
  /// - "U96"
  /// - "U97"
  /// - "U98"
  /// - "U99"
  /// - "U100"
  core.String? type;

  /// The value of the custom floodlight variable.
  ///
  /// The length of string must not exceed 100 characters.
  core.String? value;

  CustomFloodlightVariable();

  CustomFloodlightVariable.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
      };
}

/// Represents a Custom Rich Media Events group.
class CustomRichMediaEvents {
  /// List of custom rich media event IDs.
  ///
  /// Dimension values must be all of type dfa:richMediaEventTypeIdAndName.
  core.List<DimensionValue>? filteredEventIds;

  /// The kind of resource this is, in this case
  /// dfareporting#customRichMediaEvents.
  core.String? kind;

  CustomRichMediaEvents();

  CustomRichMediaEvents.fromJson(core.Map _json) {
    if (_json.containsKey('filteredEventIds')) {
      filteredEventIds = (_json['filteredEventIds'] as core.List)
          .map<DimensionValue>((value) => DimensionValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filteredEventIds != null)
          'filteredEventIds':
              filteredEventIds!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Custom variable.
class CustomVariable {
  /// The index of the custom variable.
  core.String? index;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#customVariable".
  core.String? kind;

  /// The value of the custom variable.
  ///
  /// The length of string must not exceed 50 characters.
  core.String? value;

  CustomVariable();

  CustomVariable.fromJson(core.Map _json) {
    if (_json.containsKey('index')) {
      index = _json['index'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (index != null) 'index': index!,
        if (kind != null) 'kind': kind!,
        if (value != null) 'value': value!,
      };
}

/// Custom Viewability Metric
class CustomViewabilityMetric {
  /// Configuration of the custom viewability metric.
  CustomViewabilityMetricConfiguration? configuration;

  /// ID of the custom viewability metric.
  core.String? id;

  /// Name of the custom viewability metric.
  core.String? name;

  CustomViewabilityMetric();

  CustomViewabilityMetric.fromJson(core.Map _json) {
    if (_json.containsKey('configuration')) {
      configuration = CustomViewabilityMetricConfiguration.fromJson(
          _json['configuration'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (configuration != null) 'configuration': configuration!.toJson(),
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
      };
}

/// The attributes, like playtime and percent onscreen, that define the Custom
/// Viewability Metric.
class CustomViewabilityMetricConfiguration {
  /// Whether the video must be audible to count an impression.
  core.bool? audible;

  /// The time in milliseconds the video must play for the Custom Viewability
  /// Metric to count an impression.
  ///
  /// If both this and timePercent are specified, the earlier of the two will be
  /// used.
  core.int? timeMillis;

  /// The percentage of video that must play for the Custom Viewability Metric
  /// to count an impression.
  ///
  /// If both this and timeMillis are specified, the earlier of the two will be
  /// used.
  core.int? timePercent;

  /// The percentage of video that must be on screen for the Custom Viewability
  /// Metric to count an impression.
  core.int? viewabilityPercent;

  CustomViewabilityMetricConfiguration();

  CustomViewabilityMetricConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('audible')) {
      audible = _json['audible'] as core.bool;
    }
    if (_json.containsKey('timeMillis')) {
      timeMillis = _json['timeMillis'] as core.int;
    }
    if (_json.containsKey('timePercent')) {
      timePercent = _json['timePercent'] as core.int;
    }
    if (_json.containsKey('viewabilityPercent')) {
      viewabilityPercent = _json['viewabilityPercent'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audible != null) 'audible': audible!,
        if (timeMillis != null) 'timeMillis': timeMillis!,
        if (timePercent != null) 'timePercent': timePercent!,
        if (viewabilityPercent != null)
          'viewabilityPercent': viewabilityPercent!,
      };
}

/// DV360 IDs related to the custom event.
class DV3Ids {
  /// Campaign ID for DV360.
  core.String? dvCampaignId;

  /// Creative ID for DV360.
  core.String? dvCreativeId;

  /// Insertion Order ID for DV360.
  core.String? dvInsertionOrderId;

  /// Line Item ID for DV360.
  core.String? dvLineItemId;

  /// Site ID for DV360.
  core.String? dvSiteId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#dV3Ids".
  core.String? kind;

  DV3Ids();

  DV3Ids.fromJson(core.Map _json) {
    if (_json.containsKey('dvCampaignId')) {
      dvCampaignId = _json['dvCampaignId'] as core.String;
    }
    if (_json.containsKey('dvCreativeId')) {
      dvCreativeId = _json['dvCreativeId'] as core.String;
    }
    if (_json.containsKey('dvInsertionOrderId')) {
      dvInsertionOrderId = _json['dvInsertionOrderId'] as core.String;
    }
    if (_json.containsKey('dvLineItemId')) {
      dvLineItemId = _json['dvLineItemId'] as core.String;
    }
    if (_json.containsKey('dvSiteId')) {
      dvSiteId = _json['dvSiteId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dvCampaignId != null) 'dvCampaignId': dvCampaignId!,
        if (dvCreativeId != null) 'dvCreativeId': dvCreativeId!,
        if (dvInsertionOrderId != null)
          'dvInsertionOrderId': dvInsertionOrderId!,
        if (dvLineItemId != null) 'dvLineItemId': dvLineItemId!,
        if (dvSiteId != null) 'dvSiteId': dvSiteId!,
        if (kind != null) 'kind': kind!,
      };
}

/// Represents a date range.
class DateRange {
  core.DateTime? endDate;

  /// The kind of resource this is, in this case dfareporting#dateRange.
  core.String? kind;

  /// The date range relative to the date of when the report is run.
  /// Possible string values are:
  /// - "TODAY"
  /// - "YESTERDAY"
  /// - "WEEK_TO_DATE"
  /// - "MONTH_TO_DATE"
  /// - "QUARTER_TO_DATE"
  /// - "YEAR_TO_DATE"
  /// - "PREVIOUS_WEEK"
  /// - "PREVIOUS_MONTH"
  /// - "PREVIOUS_QUARTER"
  /// - "PREVIOUS_YEAR"
  /// - "LAST_7_DAYS"
  /// - "LAST_30_DAYS"
  /// - "LAST_90_DAYS"
  /// - "LAST_365_DAYS"
  /// - "LAST_24_MONTHS"
  /// - "LAST_14_DAYS"
  /// - "LAST_60_DAYS"
  core.String? relativeDateRange;
  core.DateTime? startDate;

  DateRange();

  DateRange.fromJson(core.Map _json) {
    if (_json.containsKey('endDate')) {
      endDate = core.DateTime.parse(_json['endDate'] as core.String);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('relativeDateRange')) {
      relativeDateRange = _json['relativeDateRange'] as core.String;
    }
    if (_json.containsKey('startDate')) {
      startDate = core.DateTime.parse(_json['startDate'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endDate != null)
          'endDate':
              "${(endDate!).year.toString().padLeft(4, '0')}-${(endDate!).month.toString().padLeft(2, '0')}-${(endDate!).day.toString().padLeft(2, '0')}",
        if (kind != null) 'kind': kind!,
        if (relativeDateRange != null) 'relativeDateRange': relativeDateRange!,
        if (startDate != null)
          'startDate':
              "${(startDate!).year.toString().padLeft(4, '0')}-${(startDate!).month.toString().padLeft(2, '0')}-${(startDate!).day.toString().padLeft(2, '0')}",
      };
}

/// Day Part Targeting.
class DayPartTargeting {
  /// Days of the week when the ad will serve.
  ///
  /// Acceptable values are: - "SUNDAY" - "MONDAY" - "TUESDAY" - "WEDNESDAY" -
  /// "THURSDAY" - "FRIDAY" - "SATURDAY"
  core.List<core.String>? daysOfWeek;

  /// Hours of the day when the ad will serve, where 0 is midnight to 1 AM and
  /// 23 is 11 PM to midnight.
  ///
  /// Can be specified with days of week, in which case the ad would serve
  /// during these hours on the specified days. For example if Monday,
  /// Wednesday, Friday are the days of week specified and 9-10am, 3-5pm (hours
  /// 9, 15, and 16) is specified, the ad would serve Monday, Wednesdays, and
  /// Fridays at 9-10am and 3-5pm. Acceptable values are 0 to 23, inclusive.
  core.List<core.int>? hoursOfDay;

  /// Whether or not to use the user's local time.
  ///
  /// If false, the America/New York time zone applies.
  core.bool? userLocalTime;

  DayPartTargeting();

  DayPartTargeting.fromJson(core.Map _json) {
    if (_json.containsKey('daysOfWeek')) {
      daysOfWeek = (_json['daysOfWeek'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('hoursOfDay')) {
      hoursOfDay = (_json['hoursOfDay'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('userLocalTime')) {
      userLocalTime = _json['userLocalTime'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek!,
        if (hoursOfDay != null) 'hoursOfDay': hoursOfDay!,
        if (userLocalTime != null) 'userLocalTime': userLocalTime!,
      };
}

/// Contains information about a landing page deep link.
class DeepLink {
  /// The URL of the mobile app being linked to.
  core.String? appUrl;

  /// The fallback URL.
  ///
  /// This URL will be served to users who do not have the mobile app installed.
  core.String? fallbackUrl;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#deepLink".
  core.String? kind;

  /// The mobile app targeted by this deep link.
  MobileApp? mobileApp;

  /// Ads served to users on these remarketing lists will use this deep link.
  ///
  /// Applicable when mobileApp.directory is APPLE_APP_STORE.
  core.List<core.String>? remarketingListIds;

  DeepLink();

  DeepLink.fromJson(core.Map _json) {
    if (_json.containsKey('appUrl')) {
      appUrl = _json['appUrl'] as core.String;
    }
    if (_json.containsKey('fallbackUrl')) {
      fallbackUrl = _json['fallbackUrl'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('mobileApp')) {
      mobileApp = MobileApp.fromJson(
          _json['mobileApp'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('remarketingListIds')) {
      remarketingListIds = (_json['remarketingListIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appUrl != null) 'appUrl': appUrl!,
        if (fallbackUrl != null) 'fallbackUrl': fallbackUrl!,
        if (kind != null) 'kind': kind!,
        if (mobileApp != null) 'mobileApp': mobileApp!.toJson(),
        if (remarketingListIds != null)
          'remarketingListIds': remarketingListIds!,
      };
}

/// Properties of inheriting and overriding the default click-through event tag.
///
/// A campaign may override the event tag defined at the advertiser level, and
/// an ad may also override the campaign's setting further.
class DefaultClickThroughEventTagProperties {
  /// ID of the click-through event tag to apply to all ads in this entity's
  /// scope.
  core.String? defaultClickThroughEventTagId;

  /// Whether this entity should override the inherited default click-through
  /// event tag with its own defined value.
  core.bool? overrideInheritedEventTag;

  DefaultClickThroughEventTagProperties();

  DefaultClickThroughEventTagProperties.fromJson(core.Map _json) {
    if (_json.containsKey('defaultClickThroughEventTagId')) {
      defaultClickThroughEventTagId =
          _json['defaultClickThroughEventTagId'] as core.String;
    }
    if (_json.containsKey('overrideInheritedEventTag')) {
      overrideInheritedEventTag =
          _json['overrideInheritedEventTag'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultClickThroughEventTagId != null)
          'defaultClickThroughEventTagId': defaultClickThroughEventTagId!,
        if (overrideInheritedEventTag != null)
          'overrideInheritedEventTag': overrideInheritedEventTag!,
      };
}

/// Delivery Schedule.
class DeliverySchedule {
  /// Limit on the number of times an individual user can be served the ad
  /// within a specified period of time.
  FrequencyCap? frequencyCap;

  /// Whether or not hard cutoff is enabled.
  ///
  /// If true, the ad will not serve after the end date and time. Otherwise the
  /// ad will continue to be served until it has reached its delivery goals.
  core.bool? hardCutoff;

  /// Impression ratio for this ad.
  ///
  /// This ratio determines how often each ad is served relative to the others.
  /// For example, if ad A has an impression ratio of 1 and ad B has an
  /// impression ratio of 3, then Campaign Manager will serve ad B three times
  /// as often as ad A. Acceptable values are 1 to 10, inclusive.
  core.String? impressionRatio;

  /// Serving priority of an ad, with respect to other ads.
  ///
  /// The lower the priority number, the greater the priority with which it is
  /// served.
  /// Possible string values are:
  /// - "AD_PRIORITY_01"
  /// - "AD_PRIORITY_02"
  /// - "AD_PRIORITY_03"
  /// - "AD_PRIORITY_04"
  /// - "AD_PRIORITY_05"
  /// - "AD_PRIORITY_06"
  /// - "AD_PRIORITY_07"
  /// - "AD_PRIORITY_08"
  /// - "AD_PRIORITY_09"
  /// - "AD_PRIORITY_10"
  /// - "AD_PRIORITY_11"
  /// - "AD_PRIORITY_12"
  /// - "AD_PRIORITY_13"
  /// - "AD_PRIORITY_14"
  /// - "AD_PRIORITY_15"
  /// - "AD_PRIORITY_16"
  core.String? priority;

  DeliverySchedule();

  DeliverySchedule.fromJson(core.Map _json) {
    if (_json.containsKey('frequencyCap')) {
      frequencyCap = FrequencyCap.fromJson(
          _json['frequencyCap'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hardCutoff')) {
      hardCutoff = _json['hardCutoff'] as core.bool;
    }
    if (_json.containsKey('impressionRatio')) {
      impressionRatio = _json['impressionRatio'] as core.String;
    }
    if (_json.containsKey('priority')) {
      priority = _json['priority'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (frequencyCap != null) 'frequencyCap': frequencyCap!.toJson(),
        if (hardCutoff != null) 'hardCutoff': hardCutoff!,
        if (impressionRatio != null) 'impressionRatio': impressionRatio!,
        if (priority != null) 'priority': priority!,
      };
}

/// Google Ad Manager Settings
class DfpSettings {
  /// Ad Manager network code for this directory site.
  core.String? dfpNetworkCode;

  /// Ad Manager network name for this directory site.
  core.String? dfpNetworkName;

  /// Whether this directory site accepts programmatic placements.
  core.bool? programmaticPlacementAccepted;

  /// Whether this directory site accepts publisher-paid tags.
  core.bool? pubPaidPlacementAccepted;

  /// Whether this directory site is available only via Publisher Portal.
  core.bool? publisherPortalOnly;

  DfpSettings();

  DfpSettings.fromJson(core.Map _json) {
    if (_json.containsKey('dfpNetworkCode')) {
      dfpNetworkCode = _json['dfpNetworkCode'] as core.String;
    }
    if (_json.containsKey('dfpNetworkName')) {
      dfpNetworkName = _json['dfpNetworkName'] as core.String;
    }
    if (_json.containsKey('programmaticPlacementAccepted')) {
      programmaticPlacementAccepted =
          _json['programmaticPlacementAccepted'] as core.bool;
    }
    if (_json.containsKey('pubPaidPlacementAccepted')) {
      pubPaidPlacementAccepted = _json['pubPaidPlacementAccepted'] as core.bool;
    }
    if (_json.containsKey('publisherPortalOnly')) {
      publisherPortalOnly = _json['publisherPortalOnly'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dfpNetworkCode != null) 'dfpNetworkCode': dfpNetworkCode!,
        if (dfpNetworkName != null) 'dfpNetworkName': dfpNetworkName!,
        if (programmaticPlacementAccepted != null)
          'programmaticPlacementAccepted': programmaticPlacementAccepted!,
        if (pubPaidPlacementAccepted != null)
          'pubPaidPlacementAccepted': pubPaidPlacementAccepted!,
        if (publisherPortalOnly != null)
          'publisherPortalOnly': publisherPortalOnly!,
      };
}

/// Represents a dimension.
class Dimension {
  /// The kind of resource this is, in this case dfareporting#dimension.
  core.String? kind;

  /// The dimension name, e.g. dfa:advertiser
  core.String? name;

  Dimension();

  Dimension.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// Represents a dimension filter.
class DimensionFilter {
  /// The name of the dimension to filter.
  core.String? dimensionName;

  /// The kind of resource this is, in this case dfareporting#dimensionFilter.
  core.String? kind;

  /// The value of the dimension to filter.
  core.String? value;

  DimensionFilter();

  DimensionFilter.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionName')) {
      dimensionName = _json['dimensionName'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionName != null) 'dimensionName': dimensionName!,
        if (kind != null) 'kind': kind!,
        if (value != null) 'value': value!,
      };
}

/// Represents a DimensionValue resource.
class DimensionValue {
  /// The name of the dimension.
  core.String? dimensionName;

  /// The eTag of this response for caching purposes.
  core.String? etag;

  /// The ID associated with the value if available.
  core.String? id;

  /// The kind of resource this is, in this case dfareporting#dimensionValue.
  core.String? kind;

  /// Determines how the 'value' field is matched when filtering.
  ///
  /// If not specified, defaults to EXACT. If set to WILDCARD_EXPRESSION, '*' is
  /// allowed as a placeholder for variable length character sequences, and it
  /// can be escaped with a backslash. Note, only paid search dimensions
  /// ('dfa:paidSearch*') allow a matchType other than EXACT.
  /// Possible string values are:
  /// - "EXACT"
  /// - "BEGINS_WITH"
  /// - "CONTAINS"
  /// - "WILDCARD_EXPRESSION"
  core.String? matchType;

  /// The value of the dimension.
  core.String? value;

  DimensionValue();

  DimensionValue.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionName')) {
      dimensionName = _json['dimensionName'] as core.String;
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
    if (_json.containsKey('matchType')) {
      matchType = _json['matchType'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionName != null) 'dimensionName': dimensionName!,
        if (etag != null) 'etag': etag!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (matchType != null) 'matchType': matchType!,
        if (value != null) 'value': value!,
      };
}

/// Represents the list of DimensionValue resources.
class DimensionValueList {
  /// The eTag of this response for caching purposes.
  core.String? etag;

  /// The dimension values returned in this response.
  core.List<DimensionValue>? items;

  /// The kind of list this is, in this case dfareporting#dimensionValueList.
  core.String? kind;

  /// Continuation token used to page through dimension values.
  ///
  /// To retrieve the next page of results, set the next request's "pageToken"
  /// to the value of this field. The page token is only valid for a limited
  /// amount of time and should not be persisted.
  core.String? nextPageToken;

  DimensionValueList();

  DimensionValueList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<DimensionValue>((value) => DimensionValue.fromJson(
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
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Represents a DimensionValuesRequest.
class DimensionValueRequest {
  /// The name of the dimension for which values should be requested.
  core.String? dimensionName;
  core.DateTime? endDate;

  /// The list of filters by which to filter values.
  ///
  /// The filters are ANDed.
  core.List<DimensionFilter>? filters;

  /// The kind of request this is, in this case
  /// dfareporting#dimensionValueRequest .
  core.String? kind;
  core.DateTime? startDate;

  DimensionValueRequest();

  DimensionValueRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionName')) {
      dimensionName = _json['dimensionName'] as core.String;
    }
    if (_json.containsKey('endDate')) {
      endDate = core.DateTime.parse(_json['endDate'] as core.String);
    }
    if (_json.containsKey('filters')) {
      filters = (_json['filters'] as core.List)
          .map<DimensionFilter>((value) => DimensionFilter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('startDate')) {
      startDate = core.DateTime.parse(_json['startDate'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionName != null) 'dimensionName': dimensionName!,
        if (endDate != null)
          'endDate':
              "${(endDate!).year.toString().padLeft(4, '0')}-${(endDate!).month.toString().padLeft(2, '0')}-${(endDate!).day.toString().padLeft(2, '0')}",
        if (filters != null)
          'filters': filters!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (startDate != null)
          'startDate':
              "${(startDate!).year.toString().padLeft(4, '0')}-${(startDate!).month.toString().padLeft(2, '0')}-${(startDate!).day.toString().padLeft(2, '0')}",
      };
}

/// DirectorySites contains properties of a website from the Site Directory.
///
/// Sites need to be added to an account via the Sites resource before they can
/// be assigned to a placement.
class DirectorySite {
  /// ID of this directory site.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Dimension value for the ID of this directory site.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? idDimensionValue;

  /// Tag types for regular placements.
  ///
  /// Acceptable values are: - "STANDARD" - "IFRAME_JAVASCRIPT_INPAGE" -
  /// "INTERNAL_REDIRECT_INPAGE" - "JAVASCRIPT_INPAGE"
  core.List<core.String>? inpageTagFormats;

  /// Tag types for interstitial placements.
  ///
  /// Acceptable values are: - "IFRAME_JAVASCRIPT_INTERSTITIAL" -
  /// "INTERNAL_REDIRECT_INTERSTITIAL" - "JAVASCRIPT_INTERSTITIAL"
  core.List<core.String>? interstitialTagFormats;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#directorySite".
  core.String? kind;

  /// Name of this directory site.
  core.String? name;

  /// Directory site settings.
  DirectorySiteSettings? settings;

  /// URL of this directory site.
  core.String? url;

  DirectorySite();

  DirectorySite.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inpageTagFormats')) {
      inpageTagFormats = (_json['inpageTagFormats'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('interstitialTagFormats')) {
      interstitialTagFormats = (_json['interstitialTagFormats'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('settings')) {
      settings = DirectorySiteSettings.fromJson(
          _json['settings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (inpageTagFormats != null) 'inpageTagFormats': inpageTagFormats!,
        if (interstitialTagFormats != null)
          'interstitialTagFormats': interstitialTagFormats!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (settings != null) 'settings': settings!.toJson(),
        if (url != null) 'url': url!,
      };
}

/// Directory Site Settings
class DirectorySiteSettings {
  /// Whether this directory site has disabled active view creatives.
  core.bool? activeViewOptOut;

  /// Directory site Ad Manager settings.
  DfpSettings? dfpSettings;

  /// Whether this site accepts in-stream video ads.
  core.bool? instreamVideoPlacementAccepted;

  /// Whether this site accepts interstitial ads.
  core.bool? interstitialPlacementAccepted;

  DirectorySiteSettings();

  DirectorySiteSettings.fromJson(core.Map _json) {
    if (_json.containsKey('activeViewOptOut')) {
      activeViewOptOut = _json['activeViewOptOut'] as core.bool;
    }
    if (_json.containsKey('dfpSettings')) {
      dfpSettings = DfpSettings.fromJson(
          _json['dfpSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('instreamVideoPlacementAccepted')) {
      instreamVideoPlacementAccepted =
          _json['instreamVideoPlacementAccepted'] as core.bool;
    }
    if (_json.containsKey('interstitialPlacementAccepted')) {
      interstitialPlacementAccepted =
          _json['interstitialPlacementAccepted'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activeViewOptOut != null) 'activeViewOptOut': activeViewOptOut!,
        if (dfpSettings != null) 'dfpSettings': dfpSettings!.toJson(),
        if (instreamVideoPlacementAccepted != null)
          'instreamVideoPlacementAccepted': instreamVideoPlacementAccepted!,
        if (interstitialPlacementAccepted != null)
          'interstitialPlacementAccepted': interstitialPlacementAccepted!,
      };
}

/// Directory Site List Response
class DirectorySitesListResponse {
  /// Directory site collection.
  core.List<DirectorySite>? directorySites;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#directorySitesListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  DirectorySitesListResponse();

  DirectorySitesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('directorySites')) {
      directorySites = (_json['directorySites'] as core.List)
          .map<DirectorySite>((value) => DirectorySite.fromJson(
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
        if (directorySites != null)
          'directorySites':
              directorySites!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Represents a Disjunctive Match Statement resource, which is a conjunction
/// (and) of disjunctive (or) boolean statements.
class DisjunctiveMatchStatement {
  /// The event filters contained within this disjunctive match statement.
  core.List<EventFilter>? eventFilters;

  /// The kind of resource this is, in this case
  /// dfareporting#disjunctiveMatchStatement.
  core.String? kind;

  DisjunctiveMatchStatement();

  DisjunctiveMatchStatement.fromJson(core.Map _json) {
    if (_json.containsKey('eventFilters')) {
      eventFilters = (_json['eventFilters'] as core.List)
          .map<EventFilter>((value) => EventFilter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (eventFilters != null)
          'eventFilters': eventFilters!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Contains properties of a dynamic targeting key.
///
/// Dynamic targeting keys are unique, user-friendly labels, created at the
/// advertiser level in DCM, that can be assigned to ads, creatives, and
/// placements and used for targeting with Studio dynamic creatives. Use these
/// labels instead of numeric Campaign Manager IDs (such as placement IDs) to
/// save time and avoid errors in your dynamic feeds.
class DynamicTargetingKey {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#dynamicTargetingKey".
  core.String? kind;

  /// Name of this dynamic targeting key.
  ///
  /// This is a required field. Must be less than 256 characters long and cannot
  /// contain commas. All characters are converted to lowercase.
  core.String? name;

  /// ID of the object of this dynamic targeting key.
  ///
  /// This is a required field.
  core.String? objectId;

  /// Type of the object of this dynamic targeting key.
  ///
  /// This is a required field.
  /// Possible string values are:
  /// - "OBJECT_ADVERTISER"
  /// - "OBJECT_AD"
  /// - "OBJECT_CREATIVE"
  /// - "OBJECT_PLACEMENT"
  core.String? objectType;

  DynamicTargetingKey();

  DynamicTargetingKey.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('objectType')) {
      objectType = _json['objectType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (objectId != null) 'objectId': objectId!,
        if (objectType != null) 'objectType': objectType!,
      };
}

/// Dynamic Targeting Key List Response
class DynamicTargetingKeysListResponse {
  /// Dynamic targeting key collection.
  core.List<DynamicTargetingKey>? dynamicTargetingKeys;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#dynamicTargetingKeysListResponse".
  core.String? kind;

  DynamicTargetingKeysListResponse();

  DynamicTargetingKeysListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('dynamicTargetingKeys')) {
      dynamicTargetingKeys = (_json['dynamicTargetingKeys'] as core.List)
          .map<DynamicTargetingKey>((value) => DynamicTargetingKey.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dynamicTargetingKeys != null)
          'dynamicTargetingKeys':
              dynamicTargetingKeys!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// A description of how user IDs are encrypted.
class EncryptionInfo {
  /// The encryption entity ID.
  ///
  /// This should match the encryption configuration for ad serving or Data
  /// Transfer.
  core.String? encryptionEntityId;

  /// The encryption entity type.
  ///
  /// This should match the encryption configuration for ad serving or Data
  /// Transfer.
  /// Possible string values are:
  /// - "ENCRYPTION_ENTITY_TYPE_UNKNOWN"
  /// - "DCM_ACCOUNT"
  /// - "DCM_ADVERTISER"
  /// - "DBM_PARTNER"
  /// - "DBM_ADVERTISER"
  /// - "ADWORDS_CUSTOMER"
  /// - "DFP_NETWORK_CODE"
  core.String? encryptionEntityType;

  /// Describes whether the encrypted cookie was received from ad serving (the
  /// %m macro) or from Data Transfer.
  /// Possible string values are:
  /// - "ENCRYPTION_SCOPE_UNKNOWN"
  /// - "AD_SERVING"
  /// - "DATA_TRANSFER"
  core.String? encryptionSource;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#encryptionInfo".
  core.String? kind;

  EncryptionInfo();

  EncryptionInfo.fromJson(core.Map _json) {
    if (_json.containsKey('encryptionEntityId')) {
      encryptionEntityId = _json['encryptionEntityId'] as core.String;
    }
    if (_json.containsKey('encryptionEntityType')) {
      encryptionEntityType = _json['encryptionEntityType'] as core.String;
    }
    if (_json.containsKey('encryptionSource')) {
      encryptionSource = _json['encryptionSource'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (encryptionEntityId != null)
          'encryptionEntityId': encryptionEntityId!,
        if (encryptionEntityType != null)
          'encryptionEntityType': encryptionEntityType!,
        if (encryptionSource != null) 'encryptionSource': encryptionSource!,
        if (kind != null) 'kind': kind!,
      };
}

/// Represents a DfaReporting event filter.
class EventFilter {
  /// The dimension filter contained within this EventFilter.
  PathReportDimensionValue? dimensionFilter;

  /// The kind of resource this is, in this case dfareporting#eventFilter.
  core.String? kind;

  EventFilter();

  EventFilter.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionFilter')) {
      dimensionFilter = PathReportDimensionValue.fromJson(
          _json['dimensionFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionFilter != null)
          'dimensionFilter': dimensionFilter!.toJson(),
        if (kind != null) 'kind': kind!,
      };
}

/// Contains properties of an event tag.
class EventTag {
  /// Account ID of this event tag.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// Advertiser ID of this event tag.
  ///
  /// This field or the campaignId field is required on insertion.
  core.String? advertiserId;

  /// Dimension value for the ID of the advertiser.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? advertiserIdDimensionValue;

  /// Campaign ID of this event tag.
  ///
  /// This field or the advertiserId field is required on insertion.
  core.String? campaignId;

  /// Dimension value for the ID of the campaign.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? campaignIdDimensionValue;

  /// Whether this event tag should be automatically enabled for all of the
  /// advertiser's campaigns and ads.
  core.bool? enabledByDefault;

  /// Whether to remove this event tag from ads that are trafficked through
  /// Display & Video 360 to Ad Exchange.
  ///
  /// This may be useful if the event tag uses a pixel that is unapproved for Ad
  /// Exchange bids on one or more networks, such as the Google Display Network.
  core.bool? excludeFromAdxRequests;

  /// ID of this event tag.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#eventTag".
  core.String? kind;

  /// Name of this event tag.
  ///
  /// This is a required field and must be less than 256 characters long.
  core.String? name;

  /// Site filter type for this event tag.
  ///
  /// If no type is specified then the event tag will be applied to all sites.
  /// Possible string values are:
  /// - "WHITELIST"
  /// - "BLACKLIST"
  core.String? siteFilterType;

  /// Filter list of site IDs associated with this event tag.
  ///
  /// The siteFilterType determines whether this is a allowlist or blocklist
  /// filter.
  core.List<core.String>? siteIds;

  /// Whether this tag is SSL-compliant or not.
  ///
  /// This is a read-only field.
  core.bool? sslCompliant;

  /// Status of this event tag.
  ///
  /// Must be ENABLED for this event tag to fire. This is a required field.
  /// Possible string values are:
  /// - "ENABLED"
  /// - "DISABLED"
  core.String? status;

  /// Subaccount ID of this event tag.
  ///
  /// This is a read-only field that can be left blank.
  core.String? subaccountId;

  /// Event tag type.
  ///
  /// Can be used to specify whether to use a third-party pixel, a third-party
  /// JavaScript URL, or a third-party click-through URL for either impression
  /// or click tracking. This is a required field.
  /// Possible string values are:
  /// - "IMPRESSION_IMAGE_EVENT_TAG"
  /// - "IMPRESSION_JAVASCRIPT_EVENT_TAG"
  /// - "CLICK_THROUGH_EVENT_TAG"
  core.String? type;

  /// Payload URL for this event tag.
  ///
  /// The URL on a click-through event tag should have a landing page URL
  /// appended to the end of it. This field is required on insertion.
  core.String? url;

  /// Number of times the landing page URL should be URL-escaped before being
  /// appended to the click-through event tag URL.
  ///
  /// Only applies to click-through event tags as specified by the event tag
  /// type.
  core.int? urlEscapeLevels;

  EventTag();

  EventTag.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('campaignId')) {
      campaignId = _json['campaignId'] as core.String;
    }
    if (_json.containsKey('campaignIdDimensionValue')) {
      campaignIdDimensionValue = DimensionValue.fromJson(
          _json['campaignIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enabledByDefault')) {
      enabledByDefault = _json['enabledByDefault'] as core.bool;
    }
    if (_json.containsKey('excludeFromAdxRequests')) {
      excludeFromAdxRequests = _json['excludeFromAdxRequests'] as core.bool;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('siteFilterType')) {
      siteFilterType = _json['siteFilterType'] as core.String;
    }
    if (_json.containsKey('siteIds')) {
      siteIds = (_json['siteIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('sslCompliant')) {
      sslCompliant = _json['sslCompliant'] as core.bool;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
    if (_json.containsKey('urlEscapeLevels')) {
      urlEscapeLevels = _json['urlEscapeLevels'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (campaignId != null) 'campaignId': campaignId!,
        if (campaignIdDimensionValue != null)
          'campaignIdDimensionValue': campaignIdDimensionValue!.toJson(),
        if (enabledByDefault != null) 'enabledByDefault': enabledByDefault!,
        if (excludeFromAdxRequests != null)
          'excludeFromAdxRequests': excludeFromAdxRequests!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (siteFilterType != null) 'siteFilterType': siteFilterType!,
        if (siteIds != null) 'siteIds': siteIds!,
        if (sslCompliant != null) 'sslCompliant': sslCompliant!,
        if (status != null) 'status': status!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (type != null) 'type': type!,
        if (url != null) 'url': url!,
        if (urlEscapeLevels != null) 'urlEscapeLevels': urlEscapeLevels!,
      };
}

/// Event tag override information.
class EventTagOverride {
  /// Whether this override is enabled.
  core.bool? enabled;

  /// ID of this event tag override.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  EventTagOverride();

  EventTagOverride.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
        if (id != null) 'id': id!,
      };
}

/// Event Tag List Response
class EventTagsListResponse {
  /// Event tag collection.
  core.List<EventTag>? eventTags;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#eventTagsListResponse".
  core.String? kind;

  EventTagsListResponse();

  EventTagsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('eventTags')) {
      eventTags = (_json['eventTags'] as core.List)
          .map<EventTag>((value) =>
              EventTag.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (eventTags != null)
          'eventTags': eventTags!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// The URLs where the completed report file can be downloaded.
class FileUrls {
  /// The URL for downloading the report data through the API.
  core.String? apiUrl;

  /// The URL for downloading the report data through a browser.
  core.String? browserUrl;

  FileUrls();

  FileUrls.fromJson(core.Map _json) {
    if (_json.containsKey('apiUrl')) {
      apiUrl = _json['apiUrl'] as core.String;
    }
    if (_json.containsKey('browserUrl')) {
      browserUrl = _json['browserUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiUrl != null) 'apiUrl': apiUrl!,
        if (browserUrl != null) 'browserUrl': browserUrl!,
      };
}

/// Represents a File resource.
///
/// A file contains the metadata for a report run. It shows the status of the
/// run and holds the URLs to the generated report data if the run is finished
/// and the status is "REPORT_AVAILABLE".
class File {
  /// The date range for which the file has report data.
  ///
  /// The date range will always be the absolute date range for which the report
  /// is run.
  DateRange? dateRange;

  /// Etag of this resource.
  core.String? etag;

  /// The filename of the file.
  core.String? fileName;

  /// The output format of the report.
  ///
  /// Only available once the file is available.
  /// Possible string values are:
  /// - "CSV"
  /// - "EXCEL"
  core.String? format;

  /// The unique ID of this report file.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#file".
  core.String? kind;

  /// The timestamp in milliseconds since epoch when this file was last
  /// modified.
  core.String? lastModifiedTime;

  /// The ID of the report this file was generated from.
  core.String? reportId;

  /// The status of the report file.
  /// Possible string values are:
  /// - "PROCESSING"
  /// - "REPORT_AVAILABLE"
  /// - "FAILED"
  /// - "CANCELLED"
  core.String? status;

  /// The URLs where the completed report file can be downloaded.
  FileUrls? urls;

  File();

  File.fromJson(core.Map _json) {
    if (_json.containsKey('dateRange')) {
      dateRange = DateRange.fromJson(
          _json['dateRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('fileName')) {
      fileName = _json['fileName'] as core.String;
    }
    if (_json.containsKey('format')) {
      format = _json['format'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifiedTime')) {
      lastModifiedTime = _json['lastModifiedTime'] as core.String;
    }
    if (_json.containsKey('reportId')) {
      reportId = _json['reportId'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('urls')) {
      urls = FileUrls.fromJson(
          _json['urls'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
        if (etag != null) 'etag': etag!,
        if (fileName != null) 'fileName': fileName!,
        if (format != null) 'format': format!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (lastModifiedTime != null) 'lastModifiedTime': lastModifiedTime!,
        if (reportId != null) 'reportId': reportId!,
        if (status != null) 'status': status!,
        if (urls != null) 'urls': urls!.toJson(),
      };
}

/// List of files for a report.
class FileList {
  /// Etag of this resource.
  core.String? etag;

  /// The files returned in this response.
  core.List<File>? items;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#fileList".
  core.String? kind;

  /// Continuation token used to page through files.
  ///
  /// To retrieve the next page of results, set the next request's "pageToken"
  /// to the value of this field. The page token is only valid for a limited
  /// amount of time and should not be persisted.
  core.String? nextPageToken;

  FileList();

  FileList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<File>((value) =>
              File.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Flight
class Flight {
  core.DateTime? endDate;

  /// Rate or cost of this flight.
  core.String? rateOrCost;
  core.DateTime? startDate;

  /// Units of this flight.
  core.String? units;

  Flight();

  Flight.fromJson(core.Map _json) {
    if (_json.containsKey('endDate')) {
      endDate = core.DateTime.parse(_json['endDate'] as core.String);
    }
    if (_json.containsKey('rateOrCost')) {
      rateOrCost = _json['rateOrCost'] as core.String;
    }
    if (_json.containsKey('startDate')) {
      startDate = core.DateTime.parse(_json['startDate'] as core.String);
    }
    if (_json.containsKey('units')) {
      units = _json['units'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endDate != null)
          'endDate':
              "${(endDate!).year.toString().padLeft(4, '0')}-${(endDate!).month.toString().padLeft(2, '0')}-${(endDate!).day.toString().padLeft(2, '0')}",
        if (rateOrCost != null) 'rateOrCost': rateOrCost!,
        if (startDate != null)
          'startDate':
              "${(startDate!).year.toString().padLeft(4, '0')}-${(startDate!).month.toString().padLeft(2, '0')}-${(startDate!).day.toString().padLeft(2, '0')}",
        if (units != null) 'units': units!,
      };
}

/// Floodlight Activity GenerateTag Response
class FloodlightActivitiesGenerateTagResponse {
  /// Generated tag for this Floodlight activity.
  ///
  /// For global site tags, this is the event snippet.
  core.String? floodlightActivityTag;

  /// The global snippet section of a global site tag.
  ///
  /// The global site tag sets new cookies on your domain, which will store a
  /// unique identifier for a user or the ad click that brought the user to your
  /// site. Learn more.
  core.String? globalSiteTagGlobalSnippet;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "dfareporting#floodlightActivitiesGenerateTagResponse".
  core.String? kind;

  FloodlightActivitiesGenerateTagResponse();

  FloodlightActivitiesGenerateTagResponse.fromJson(core.Map _json) {
    if (_json.containsKey('floodlightActivityTag')) {
      floodlightActivityTag = _json['floodlightActivityTag'] as core.String;
    }
    if (_json.containsKey('globalSiteTagGlobalSnippet')) {
      globalSiteTagGlobalSnippet =
          _json['globalSiteTagGlobalSnippet'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (floodlightActivityTag != null)
          'floodlightActivityTag': floodlightActivityTag!,
        if (globalSiteTagGlobalSnippet != null)
          'globalSiteTagGlobalSnippet': globalSiteTagGlobalSnippet!,
        if (kind != null) 'kind': kind!,
      };
}

/// Floodlight Activity List Response
class FloodlightActivitiesListResponse {
  /// Floodlight activity collection.
  core.List<FloodlightActivity>? floodlightActivities;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#floodlightActivitiesListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  FloodlightActivitiesListResponse();

  FloodlightActivitiesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('floodlightActivities')) {
      floodlightActivities = (_json['floodlightActivities'] as core.List)
          .map<FloodlightActivity>((value) => FloodlightActivity.fromJson(
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
        if (floodlightActivities != null)
          'floodlightActivities':
              floodlightActivities!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Contains properties of a Floodlight activity.
class FloodlightActivity {
  /// Account ID of this floodlight activity.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// Advertiser ID of this floodlight activity.
  ///
  /// If this field is left blank, the value will be copied over either from the
  /// activity group's advertiser or the existing activity's advertiser.
  core.String? advertiserId;

  /// Dimension value for the ID of the advertiser.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? advertiserIdDimensionValue;

  /// Whether the activity is enabled for attribution.
  core.bool? attributionEnabled;

  /// Code type used for cache busting in the generated tag.
  ///
  /// Applicable only when floodlightActivityGroupType is COUNTER and
  /// countingMethod is STANDARD_COUNTING or UNIQUE_COUNTING.
  /// Possible string values are:
  /// - "JAVASCRIPT"
  /// - "ACTIVE_SERVER_PAGE"
  /// - "JSP"
  /// - "PHP"
  /// - "COLD_FUSION"
  core.String? cacheBustingType;

  /// Counting method for conversions for this floodlight activity.
  ///
  /// This is a required field.
  /// Possible string values are:
  /// - "STANDARD_COUNTING"
  /// - "UNIQUE_COUNTING"
  /// - "SESSION_COUNTING"
  /// - "TRANSACTIONS_COUNTING"
  /// - "ITEMS_SOLD_COUNTING"
  core.String? countingMethod;

  /// Dynamic floodlight tags.
  core.List<FloodlightActivityDynamicTag>? defaultTags;

  /// URL where this tag will be deployed.
  ///
  /// If specified, must be less than 256 characters long.
  core.String? expectedUrl;

  /// Floodlight activity group ID of this floodlight activity.
  ///
  /// This is a required field.
  core.String? floodlightActivityGroupId;

  /// Name of the associated floodlight activity group.
  ///
  /// This is a read-only field.
  core.String? floodlightActivityGroupName;

  /// Tag string of the associated floodlight activity group.
  ///
  /// This is a read-only field.
  core.String? floodlightActivityGroupTagString;

  /// Type of the associated floodlight activity group.
  ///
  /// This is a read-only field.
  /// Possible string values are:
  /// - "COUNTER"
  /// - "SALE"
  core.String? floodlightActivityGroupType;

  /// Floodlight configuration ID of this floodlight activity.
  ///
  /// If this field is left blank, the value will be copied over either from the
  /// activity group's floodlight configuration or from the existing activity's
  /// floodlight configuration.
  core.String? floodlightConfigurationId;

  /// Dimension value for the ID of the floodlight configuration.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? floodlightConfigurationIdDimensionValue;

  /// The type of Floodlight tag this activity will generate.
  ///
  /// This is a required field.
  /// Possible string values are:
  /// - "IFRAME"
  /// - "IMAGE"
  /// - "GLOBAL_SITE_TAG"
  core.String? floodlightTagType;

  /// ID of this floodlight activity.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Dimension value for the ID of this floodlight activity.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? idDimensionValue;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#floodlightActivity".
  core.String? kind;

  /// Name of this floodlight activity.
  ///
  /// This is a required field. Must be less than 129 characters long and cannot
  /// contain quotes.
  core.String? name;

  /// General notes or implementation instructions for the tag.
  core.String? notes;

  /// Publisher dynamic floodlight tags.
  core.List<FloodlightActivityPublisherDynamicTag>? publisherTags;

  /// Whether this tag should use SSL.
  core.bool? secure;

  /// Whether the floodlight activity is SSL-compliant.
  ///
  /// This is a read-only field, its value detected by the system from the
  /// floodlight tags.
  core.bool? sslCompliant;

  /// Whether this floodlight activity must be SSL-compliant.
  core.bool? sslRequired;

  /// The status of the activity.
  ///
  /// This can only be set to ACTIVE or ARCHIVED_AND_DISABLED. The ARCHIVED
  /// status is no longer supported and cannot be set for Floodlight activities.
  /// The DISABLED_POLICY status indicates that a Floodlight activity is
  /// violating Google policy. Contact your account manager for more
  /// information.
  /// Possible string values are:
  /// - "ACTIVE"
  /// - "ARCHIVED_AND_DISABLED"
  /// - "ARCHIVED"
  /// - "DISABLED_POLICY"
  core.String? status;

  /// Subaccount ID of this floodlight activity.
  ///
  /// This is a read-only field that can be left blank.
  core.String? subaccountId;

  /// Tag format type for the floodlight activity.
  ///
  /// If left blank, the tag format will default to HTML.
  /// Possible string values are:
  /// - "HTML"
  /// - "XHTML"
  core.String? tagFormat;

  /// Value of the cat= parameter in the floodlight tag, which the ad servers
  /// use to identify the activity.
  ///
  /// This is optional: if empty, a new tag string will be generated for you.
  /// This string must be 1 to 8 characters long, with valid characters being
  /// a-z0-9\[ _ \]. This tag string must also be unique among activities of the
  /// same activity group. This field is read-only after insertion.
  core.String? tagString;

  /// List of the user-defined variables used by this conversion tag.
  ///
  /// These map to the "u\[1-100\]=" in the tags. Each of these can have a user
  /// defined type. Acceptable values are U1 to U100, inclusive.
  core.List<core.String>? userDefinedVariableTypes;

  FloodlightActivity();

  FloodlightActivity.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('attributionEnabled')) {
      attributionEnabled = _json['attributionEnabled'] as core.bool;
    }
    if (_json.containsKey('cacheBustingType')) {
      cacheBustingType = _json['cacheBustingType'] as core.String;
    }
    if (_json.containsKey('countingMethod')) {
      countingMethod = _json['countingMethod'] as core.String;
    }
    if (_json.containsKey('defaultTags')) {
      defaultTags = (_json['defaultTags'] as core.List)
          .map<FloodlightActivityDynamicTag>((value) =>
              FloodlightActivityDynamicTag.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('expectedUrl')) {
      expectedUrl = _json['expectedUrl'] as core.String;
    }
    if (_json.containsKey('floodlightActivityGroupId')) {
      floodlightActivityGroupId =
          _json['floodlightActivityGroupId'] as core.String;
    }
    if (_json.containsKey('floodlightActivityGroupName')) {
      floodlightActivityGroupName =
          _json['floodlightActivityGroupName'] as core.String;
    }
    if (_json.containsKey('floodlightActivityGroupTagString')) {
      floodlightActivityGroupTagString =
          _json['floodlightActivityGroupTagString'] as core.String;
    }
    if (_json.containsKey('floodlightActivityGroupType')) {
      floodlightActivityGroupType =
          _json['floodlightActivityGroupType'] as core.String;
    }
    if (_json.containsKey('floodlightConfigurationId')) {
      floodlightConfigurationId =
          _json['floodlightConfigurationId'] as core.String;
    }
    if (_json.containsKey('floodlightConfigurationIdDimensionValue')) {
      floodlightConfigurationIdDimensionValue = DimensionValue.fromJson(
          _json['floodlightConfigurationIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('floodlightTagType')) {
      floodlightTagType = _json['floodlightTagType'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('notes')) {
      notes = _json['notes'] as core.String;
    }
    if (_json.containsKey('publisherTags')) {
      publisherTags = (_json['publisherTags'] as core.List)
          .map<FloodlightActivityPublisherDynamicTag>((value) =>
              FloodlightActivityPublisherDynamicTag.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('secure')) {
      secure = _json['secure'] as core.bool;
    }
    if (_json.containsKey('sslCompliant')) {
      sslCompliant = _json['sslCompliant'] as core.bool;
    }
    if (_json.containsKey('sslRequired')) {
      sslRequired = _json['sslRequired'] as core.bool;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('tagFormat')) {
      tagFormat = _json['tagFormat'] as core.String;
    }
    if (_json.containsKey('tagString')) {
      tagString = _json['tagString'] as core.String;
    }
    if (_json.containsKey('userDefinedVariableTypes')) {
      userDefinedVariableTypes =
          (_json['userDefinedVariableTypes'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (attributionEnabled != null)
          'attributionEnabled': attributionEnabled!,
        if (cacheBustingType != null) 'cacheBustingType': cacheBustingType!,
        if (countingMethod != null) 'countingMethod': countingMethod!,
        if (defaultTags != null)
          'defaultTags': defaultTags!.map((value) => value.toJson()).toList(),
        if (expectedUrl != null) 'expectedUrl': expectedUrl!,
        if (floodlightActivityGroupId != null)
          'floodlightActivityGroupId': floodlightActivityGroupId!,
        if (floodlightActivityGroupName != null)
          'floodlightActivityGroupName': floodlightActivityGroupName!,
        if (floodlightActivityGroupTagString != null)
          'floodlightActivityGroupTagString': floodlightActivityGroupTagString!,
        if (floodlightActivityGroupType != null)
          'floodlightActivityGroupType': floodlightActivityGroupType!,
        if (floodlightConfigurationId != null)
          'floodlightConfigurationId': floodlightConfigurationId!,
        if (floodlightConfigurationIdDimensionValue != null)
          'floodlightConfigurationIdDimensionValue':
              floodlightConfigurationIdDimensionValue!.toJson(),
        if (floodlightTagType != null) 'floodlightTagType': floodlightTagType!,
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (notes != null) 'notes': notes!,
        if (publisherTags != null)
          'publisherTags':
              publisherTags!.map((value) => value.toJson()).toList(),
        if (secure != null) 'secure': secure!,
        if (sslCompliant != null) 'sslCompliant': sslCompliant!,
        if (sslRequired != null) 'sslRequired': sslRequired!,
        if (status != null) 'status': status!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (tagFormat != null) 'tagFormat': tagFormat!,
        if (tagString != null) 'tagString': tagString!,
        if (userDefinedVariableTypes != null)
          'userDefinedVariableTypes': userDefinedVariableTypes!,
      };
}

/// Dynamic Tag
class FloodlightActivityDynamicTag {
  /// ID of this dynamic tag.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Name of this tag.
  core.String? name;

  /// Tag code.
  core.String? tag;

  FloodlightActivityDynamicTag();

  FloodlightActivityDynamicTag.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('tag')) {
      tag = _json['tag'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
        if (tag != null) 'tag': tag!,
      };
}

/// Contains properties of a Floodlight activity group.
class FloodlightActivityGroup {
  /// Account ID of this floodlight activity group.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// Advertiser ID of this floodlight activity group.
  ///
  /// If this field is left blank, the value will be copied over either from the
  /// floodlight configuration's advertiser or from the existing activity
  /// group's advertiser.
  core.String? advertiserId;

  /// Dimension value for the ID of the advertiser.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? advertiserIdDimensionValue;

  /// Floodlight configuration ID of this floodlight activity group.
  ///
  /// This is a required field.
  core.String? floodlightConfigurationId;

  /// Dimension value for the ID of the floodlight configuration.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? floodlightConfigurationIdDimensionValue;

  /// ID of this floodlight activity group.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Dimension value for the ID of this floodlight activity group.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? idDimensionValue;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#floodlightActivityGroup".
  core.String? kind;

  /// Name of this floodlight activity group.
  ///
  /// This is a required field. Must be less than 65 characters long and cannot
  /// contain quotes.
  core.String? name;

  /// Subaccount ID of this floodlight activity group.
  ///
  /// This is a read-only field that can be left blank.
  core.String? subaccountId;

  /// Value of the type= parameter in the floodlight tag, which the ad servers
  /// use to identify the activity group that the activity belongs to.
  ///
  /// This is optional: if empty, a new tag string will be generated for you.
  /// This string must be 1 to 8 characters long, with valid characters being
  /// a-z0-9\[ _ \]. This tag string must also be unique among activity groups
  /// of the same floodlight configuration. This field is read-only after
  /// insertion.
  core.String? tagString;

  /// Type of the floodlight activity group.
  ///
  /// This is a required field that is read-only after insertion.
  /// Possible string values are:
  /// - "COUNTER"
  /// - "SALE"
  core.String? type;

  FloodlightActivityGroup();

  FloodlightActivityGroup.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('floodlightConfigurationId')) {
      floodlightConfigurationId =
          _json['floodlightConfigurationId'] as core.String;
    }
    if (_json.containsKey('floodlightConfigurationIdDimensionValue')) {
      floodlightConfigurationIdDimensionValue = DimensionValue.fromJson(
          _json['floodlightConfigurationIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('tagString')) {
      tagString = _json['tagString'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (floodlightConfigurationId != null)
          'floodlightConfigurationId': floodlightConfigurationId!,
        if (floodlightConfigurationIdDimensionValue != null)
          'floodlightConfigurationIdDimensionValue':
              floodlightConfigurationIdDimensionValue!.toJson(),
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (tagString != null) 'tagString': tagString!,
        if (type != null) 'type': type!,
      };
}

/// Floodlight Activity Group List Response
class FloodlightActivityGroupsListResponse {
  /// Floodlight activity group collection.
  core.List<FloodlightActivityGroup>? floodlightActivityGroups;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "dfareporting#floodlightActivityGroupsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  FloodlightActivityGroupsListResponse();

  FloodlightActivityGroupsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('floodlightActivityGroups')) {
      floodlightActivityGroups =
          (_json['floodlightActivityGroups'] as core.List)
              .map<FloodlightActivityGroup>((value) =>
                  FloodlightActivityGroup.fromJson(
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
        if (floodlightActivityGroups != null)
          'floodlightActivityGroups':
              floodlightActivityGroups!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Publisher Dynamic Tag
class FloodlightActivityPublisherDynamicTag {
  /// Whether this tag is applicable only for click-throughs.
  core.bool? clickThrough;

  /// Directory site ID of this dynamic tag.
  ///
  /// This is a write-only field that can be used as an alternative to the
  /// siteId field. When this resource is retrieved, only the siteId field will
  /// be populated.
  core.String? directorySiteId;

  /// Dynamic floodlight tag.
  FloodlightActivityDynamicTag? dynamicTag;

  /// Site ID of this dynamic tag.
  core.String? siteId;

  /// Dimension value for the ID of the site.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? siteIdDimensionValue;

  /// Whether this tag is applicable only for view-throughs.
  core.bool? viewThrough;

  FloodlightActivityPublisherDynamicTag();

  FloodlightActivityPublisherDynamicTag.fromJson(core.Map _json) {
    if (_json.containsKey('clickThrough')) {
      clickThrough = _json['clickThrough'] as core.bool;
    }
    if (_json.containsKey('directorySiteId')) {
      directorySiteId = _json['directorySiteId'] as core.String;
    }
    if (_json.containsKey('dynamicTag')) {
      dynamicTag = FloodlightActivityDynamicTag.fromJson(
          _json['dynamicTag'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('siteId')) {
      siteId = _json['siteId'] as core.String;
    }
    if (_json.containsKey('siteIdDimensionValue')) {
      siteIdDimensionValue = DimensionValue.fromJson(
          _json['siteIdDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('viewThrough')) {
      viewThrough = _json['viewThrough'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clickThrough != null) 'clickThrough': clickThrough!,
        if (directorySiteId != null) 'directorySiteId': directorySiteId!,
        if (dynamicTag != null) 'dynamicTag': dynamicTag!.toJson(),
        if (siteId != null) 'siteId': siteId!,
        if (siteIdDimensionValue != null)
          'siteIdDimensionValue': siteIdDimensionValue!.toJson(),
        if (viewThrough != null) 'viewThrough': viewThrough!,
      };
}

/// Contains properties of a Floodlight configuration.
class FloodlightConfiguration {
  /// Account ID of this floodlight configuration.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// Advertiser ID of the parent advertiser of this floodlight configuration.
  core.String? advertiserId;

  /// Dimension value for the ID of the advertiser.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? advertiserIdDimensionValue;

  /// Whether advertiser data is shared with Google Analytics.
  core.bool? analyticsDataSharingEnabled;

  /// Custom Viewability metric for the floodlight configuration.
  CustomViewabilityMetric? customViewabilityMetric;

  /// Whether the exposure-to-conversion report is enabled.
  ///
  /// This report shows detailed pathway information on up to 10 of the most
  /// recent ad exposures seen by a user before converting.
  core.bool? exposureToConversionEnabled;

  /// Day that will be counted as the first day of the week in reports.
  ///
  /// This is a required field.
  /// Possible string values are:
  /// - "MONDAY"
  /// - "SUNDAY"
  core.String? firstDayOfWeek;

  /// ID of this floodlight configuration.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Dimension value for the ID of this floodlight configuration.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? idDimensionValue;

  /// Whether in-app attribution tracking is enabled.
  core.bool? inAppAttributionTrackingEnabled;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#floodlightConfiguration".
  core.String? kind;

  /// Lookback window settings for this floodlight configuration.
  LookbackConfiguration? lookbackConfiguration;

  /// Types of attribution options for natural search conversions.
  /// Possible string values are:
  /// - "EXCLUDE_NATURAL_SEARCH_CONVERSION_ATTRIBUTION"
  /// - "INCLUDE_NATURAL_SEARCH_CONVERSION_ATTRIBUTION"
  /// - "INCLUDE_NATURAL_SEARCH_TIERED_CONVERSION_ATTRIBUTION"
  core.String? naturalSearchConversionAttributionOption;

  /// Settings for Campaign Manager Omniture integration.
  OmnitureSettings? omnitureSettings;

  /// Subaccount ID of this floodlight configuration.
  ///
  /// This is a read-only field that can be left blank.
  core.String? subaccountId;

  /// Configuration settings for dynamic and image floodlight tags.
  TagSettings? tagSettings;

  /// List of third-party authentication tokens enabled for this configuration.
  core.List<ThirdPartyAuthenticationToken>? thirdPartyAuthenticationTokens;

  /// List of user defined variables enabled for this configuration.
  core.List<UserDefinedVariableConfiguration>?
      userDefinedVariableConfigurations;

  FloodlightConfiguration();

  FloodlightConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('analyticsDataSharingEnabled')) {
      analyticsDataSharingEnabled =
          _json['analyticsDataSharingEnabled'] as core.bool;
    }
    if (_json.containsKey('customViewabilityMetric')) {
      customViewabilityMetric = CustomViewabilityMetric.fromJson(
          _json['customViewabilityMetric']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('exposureToConversionEnabled')) {
      exposureToConversionEnabled =
          _json['exposureToConversionEnabled'] as core.bool;
    }
    if (_json.containsKey('firstDayOfWeek')) {
      firstDayOfWeek = _json['firstDayOfWeek'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inAppAttributionTrackingEnabled')) {
      inAppAttributionTrackingEnabled =
          _json['inAppAttributionTrackingEnabled'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lookbackConfiguration')) {
      lookbackConfiguration = LookbackConfiguration.fromJson(
          _json['lookbackConfiguration']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('naturalSearchConversionAttributionOption')) {
      naturalSearchConversionAttributionOption =
          _json['naturalSearchConversionAttributionOption'] as core.String;
    }
    if (_json.containsKey('omnitureSettings')) {
      omnitureSettings = OmnitureSettings.fromJson(
          _json['omnitureSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('tagSettings')) {
      tagSettings = TagSettings.fromJson(
          _json['tagSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('thirdPartyAuthenticationTokens')) {
      thirdPartyAuthenticationTokens =
          (_json['thirdPartyAuthenticationTokens'] as core.List)
              .map<ThirdPartyAuthenticationToken>((value) =>
                  ThirdPartyAuthenticationToken.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('userDefinedVariableConfigurations')) {
      userDefinedVariableConfigurations =
          (_json['userDefinedVariableConfigurations'] as core.List)
              .map<UserDefinedVariableConfiguration>((value) =>
                  UserDefinedVariableConfiguration.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (analyticsDataSharingEnabled != null)
          'analyticsDataSharingEnabled': analyticsDataSharingEnabled!,
        if (customViewabilityMetric != null)
          'customViewabilityMetric': customViewabilityMetric!.toJson(),
        if (exposureToConversionEnabled != null)
          'exposureToConversionEnabled': exposureToConversionEnabled!,
        if (firstDayOfWeek != null) 'firstDayOfWeek': firstDayOfWeek!,
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (inAppAttributionTrackingEnabled != null)
          'inAppAttributionTrackingEnabled': inAppAttributionTrackingEnabled!,
        if (kind != null) 'kind': kind!,
        if (lookbackConfiguration != null)
          'lookbackConfiguration': lookbackConfiguration!.toJson(),
        if (naturalSearchConversionAttributionOption != null)
          'naturalSearchConversionAttributionOption':
              naturalSearchConversionAttributionOption!,
        if (omnitureSettings != null)
          'omnitureSettings': omnitureSettings!.toJson(),
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (tagSettings != null) 'tagSettings': tagSettings!.toJson(),
        if (thirdPartyAuthenticationTokens != null)
          'thirdPartyAuthenticationTokens': thirdPartyAuthenticationTokens!
              .map((value) => value.toJson())
              .toList(),
        if (userDefinedVariableConfigurations != null)
          'userDefinedVariableConfigurations':
              userDefinedVariableConfigurations!
                  .map((value) => value.toJson())
                  .toList(),
      };
}

/// Floodlight Configuration List Response
class FloodlightConfigurationsListResponse {
  /// Floodlight configuration collection.
  core.List<FloodlightConfiguration>? floodlightConfigurations;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "dfareporting#floodlightConfigurationsListResponse".
  core.String? kind;

  FloodlightConfigurationsListResponse();

  FloodlightConfigurationsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('floodlightConfigurations')) {
      floodlightConfigurations =
          (_json['floodlightConfigurations'] as core.List)
              .map<FloodlightConfiguration>((value) =>
                  FloodlightConfiguration.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (floodlightConfigurations != null)
          'floodlightConfigurations':
              floodlightConfigurations!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Represents fields that are compatible to be selected for a report of type
/// "FlOODLIGHT".
class FloodlightReportCompatibleFields {
  /// Dimensions which are compatible to be selected in the "dimensionFilters"
  /// section of the report.
  core.List<Dimension>? dimensionFilters;

  /// Dimensions which are compatible to be selected in the "dimensions" section
  /// of the report.
  core.List<Dimension>? dimensions;

  /// The kind of resource this is, in this case
  /// dfareporting#floodlightReportCompatibleFields.
  core.String? kind;

  /// Metrics which are compatible to be selected in the "metricNames" section
  /// of the report.
  core.List<Metric>? metrics;

  FloodlightReportCompatibleFields();

  FloodlightReportCompatibleFields.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionFilters')) {
      dimensionFilters = (_json['dimensionFilters'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dimensions')) {
      dimensions = (_json['dimensions'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.List)
          .map<Metric>((value) =>
              Metric.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionFilters != null)
          'dimensionFilters':
              dimensionFilters!.map((value) => value.toJson()).toList(),
        if (dimensions != null)
          'dimensions': dimensions!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (metrics != null)
          'metrics': metrics!.map((value) => value.toJson()).toList(),
      };
}

/// Frequency Cap.
class FrequencyCap {
  /// Duration of time, in seconds, for this frequency cap.
  ///
  /// The maximum duration is 90 days. Acceptable values are 1 to 7776000,
  /// inclusive.
  core.String? duration;

  /// Number of times an individual user can be served the ad within the
  /// specified duration.
  ///
  /// Acceptable values are 1 to 15, inclusive.
  core.String? impressions;

  FrequencyCap();

  FrequencyCap.fromJson(core.Map _json) {
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.String;
    }
    if (_json.containsKey('impressions')) {
      impressions = _json['impressions'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (duration != null) 'duration': duration!,
        if (impressions != null) 'impressions': impressions!,
      };
}

/// FsCommand.
class FsCommand {
  /// Distance from the left of the browser.Applicable when positionOption is
  /// DISTANCE_FROM_TOP_LEFT_CORNER.
  core.int? left;

  /// Position in the browser where the window will open.
  /// Possible string values are:
  /// - "CENTERED"
  /// - "DISTANCE_FROM_TOP_LEFT_CORNER"
  core.String? positionOption;

  /// Distance from the top of the browser.
  ///
  /// Applicable when positionOption is DISTANCE_FROM_TOP_LEFT_CORNER.
  core.int? top;

  /// Height of the window.
  core.int? windowHeight;

  /// Width of the window.
  core.int? windowWidth;

  FsCommand();

  FsCommand.fromJson(core.Map _json) {
    if (_json.containsKey('left')) {
      left = _json['left'] as core.int;
    }
    if (_json.containsKey('positionOption')) {
      positionOption = _json['positionOption'] as core.String;
    }
    if (_json.containsKey('top')) {
      top = _json['top'] as core.int;
    }
    if (_json.containsKey('windowHeight')) {
      windowHeight = _json['windowHeight'] as core.int;
    }
    if (_json.containsKey('windowWidth')) {
      windowWidth = _json['windowWidth'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (left != null) 'left': left!,
        if (positionOption != null) 'positionOption': positionOption!,
        if (top != null) 'top': top!,
        if (windowHeight != null) 'windowHeight': windowHeight!,
        if (windowWidth != null) 'windowWidth': windowWidth!,
      };
}

/// Geographical Targeting.
class GeoTargeting {
  /// Cities to be targeted.
  ///
  /// For each city only dartId is required. The other fields are populated
  /// automatically when the ad is inserted or updated. If targeting a city, do
  /// not target or exclude the country of the city, and do not target the metro
  /// or region of the city.
  core.List<City>? cities;

  /// Countries to be targeted or excluded from targeting, depending on the
  /// setting of the excludeCountries field.
  ///
  /// For each country only dartId is required. The other fields are populated
  /// automatically when the ad is inserted or updated. If targeting or
  /// excluding a country, do not target regions, cities, metros, or postal
  /// codes in the same country.
  core.List<Country>? countries;

  /// Whether or not to exclude the countries in the countries field from
  /// targeting.
  ///
  /// If false, the countries field refers to countries which will be targeted
  /// by the ad.
  core.bool? excludeCountries;

  /// Metros to be targeted.
  ///
  /// For each metro only dmaId is required. The other fields are populated
  /// automatically when the ad is inserted or updated. If targeting a metro, do
  /// not target or exclude the country of the metro.
  core.List<Metro>? metros;

  /// Postal codes to be targeted.
  ///
  /// For each postal code only id is required. The other fields are populated
  /// automatically when the ad is inserted or updated. If targeting a postal
  /// code, do not target or exclude the country of the postal code.
  core.List<PostalCode>? postalCodes;

  /// Regions to be targeted.
  ///
  /// For each region only dartId is required. The other fields are populated
  /// automatically when the ad is inserted or updated. If targeting a region,
  /// do not target or exclude the country of the region.
  core.List<Region>? regions;

  GeoTargeting();

  GeoTargeting.fromJson(core.Map _json) {
    if (_json.containsKey('cities')) {
      cities = (_json['cities'] as core.List)
          .map<City>((value) =>
              City.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('countries')) {
      countries = (_json['countries'] as core.List)
          .map<Country>((value) =>
              Country.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('excludeCountries')) {
      excludeCountries = _json['excludeCountries'] as core.bool;
    }
    if (_json.containsKey('metros')) {
      metros = (_json['metros'] as core.List)
          .map<Metro>((value) =>
              Metro.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('postalCodes')) {
      postalCodes = (_json['postalCodes'] as core.List)
          .map<PostalCode>((value) =>
              PostalCode.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('regions')) {
      regions = (_json['regions'] as core.List)
          .map<Region>((value) =>
              Region.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cities != null)
          'cities': cities!.map((value) => value.toJson()).toList(),
        if (countries != null)
          'countries': countries!.map((value) => value.toJson()).toList(),
        if (excludeCountries != null) 'excludeCountries': excludeCountries!,
        if (metros != null)
          'metros': metros!.map((value) => value.toJson()).toList(),
        if (postalCodes != null)
          'postalCodes': postalCodes!.map((value) => value.toJson()).toList(),
        if (regions != null)
          'regions': regions!.map((value) => value.toJson()).toList(),
      };
}

/// Represents a buy from the Planning inventory store.
class InventoryItem {
  /// Account ID of this inventory item.
  core.String? accountId;

  /// Ad slots of this inventory item.
  ///
  /// If this inventory item represents a standalone placement, there will be
  /// exactly one ad slot. If this inventory item represents a placement group,
  /// there will be more than one ad slot, each representing one child placement
  /// in that placement group.
  core.List<AdSlot>? adSlots;

  /// Advertiser ID of this inventory item.
  core.String? advertiserId;

  /// Content category ID of this inventory item.
  core.String? contentCategoryId;

  /// Estimated click-through rate of this inventory item.
  core.String? estimatedClickThroughRate;

  /// Estimated conversion rate of this inventory item.
  core.String? estimatedConversionRate;

  /// ID of this inventory item.
  core.String? id;

  /// Whether this inventory item is in plan.
  core.bool? inPlan;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#inventoryItem".
  core.String? kind;

  /// Information about the most recent modification of this inventory item.
  LastModifiedInfo? lastModifiedInfo;

  /// Name of this inventory item.
  ///
  /// For standalone inventory items, this is the same name as that of its only
  /// ad slot. For group inventory items, this can differ from the name of any
  /// of its ad slots.
  core.String? name;

  /// Negotiation channel ID of this inventory item.
  core.String? negotiationChannelId;

  /// Order ID of this inventory item.
  core.String? orderId;

  /// Placement strategy ID of this inventory item.
  core.String? placementStrategyId;

  /// Pricing of this inventory item.
  Pricing? pricing;

  /// Project ID of this inventory item.
  core.String? projectId;

  /// RFP ID of this inventory item.
  core.String? rfpId;

  /// ID of the site this inventory item is associated with.
  core.String? siteId;

  /// Subaccount ID of this inventory item.
  core.String? subaccountId;

  /// Type of inventory item.
  /// Possible string values are:
  /// - "PLANNING_PLACEMENT_TYPE_REGULAR"
  /// - "PLANNING_PLACEMENT_TYPE_CREDIT"
  core.String? type;

  InventoryItem();

  InventoryItem.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('adSlots')) {
      adSlots = (_json['adSlots'] as core.List)
          .map<AdSlot>((value) =>
              AdSlot.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('contentCategoryId')) {
      contentCategoryId = _json['contentCategoryId'] as core.String;
    }
    if (_json.containsKey('estimatedClickThroughRate')) {
      estimatedClickThroughRate =
          _json['estimatedClickThroughRate'] as core.String;
    }
    if (_json.containsKey('estimatedConversionRate')) {
      estimatedConversionRate = _json['estimatedConversionRate'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('inPlan')) {
      inPlan = _json['inPlan'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifiedInfo')) {
      lastModifiedInfo = LastModifiedInfo.fromJson(
          _json['lastModifiedInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('negotiationChannelId')) {
      negotiationChannelId = _json['negotiationChannelId'] as core.String;
    }
    if (_json.containsKey('orderId')) {
      orderId = _json['orderId'] as core.String;
    }
    if (_json.containsKey('placementStrategyId')) {
      placementStrategyId = _json['placementStrategyId'] as core.String;
    }
    if (_json.containsKey('pricing')) {
      pricing = Pricing.fromJson(
          _json['pricing'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('rfpId')) {
      rfpId = _json['rfpId'] as core.String;
    }
    if (_json.containsKey('siteId')) {
      siteId = _json['siteId'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (adSlots != null)
          'adSlots': adSlots!.map((value) => value.toJson()).toList(),
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (contentCategoryId != null) 'contentCategoryId': contentCategoryId!,
        if (estimatedClickThroughRate != null)
          'estimatedClickThroughRate': estimatedClickThroughRate!,
        if (estimatedConversionRate != null)
          'estimatedConversionRate': estimatedConversionRate!,
        if (id != null) 'id': id!,
        if (inPlan != null) 'inPlan': inPlan!,
        if (kind != null) 'kind': kind!,
        if (lastModifiedInfo != null)
          'lastModifiedInfo': lastModifiedInfo!.toJson(),
        if (name != null) 'name': name!,
        if (negotiationChannelId != null)
          'negotiationChannelId': negotiationChannelId!,
        if (orderId != null) 'orderId': orderId!,
        if (placementStrategyId != null)
          'placementStrategyId': placementStrategyId!,
        if (pricing != null) 'pricing': pricing!.toJson(),
        if (projectId != null) 'projectId': projectId!,
        if (rfpId != null) 'rfpId': rfpId!,
        if (siteId != null) 'siteId': siteId!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (type != null) 'type': type!,
      };
}

/// Inventory item List Response
class InventoryItemsListResponse {
  /// Inventory item collection
  core.List<InventoryItem>? inventoryItems;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#inventoryItemsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  InventoryItemsListResponse();

  InventoryItemsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('inventoryItems')) {
      inventoryItems = (_json['inventoryItems'] as core.List)
          .map<InventoryItem>((value) => InventoryItem.fromJson(
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
        if (inventoryItems != null)
          'inventoryItems':
              inventoryItems!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Key Value Targeting Expression.
class KeyValueTargetingExpression {
  /// Keyword expression being targeted by the ad.
  core.String? expression;

  KeyValueTargetingExpression();

  KeyValueTargetingExpression.fromJson(core.Map _json) {
    if (_json.containsKey('expression')) {
      expression = _json['expression'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expression != null) 'expression': expression!,
      };
}

/// Contains information about where a user's browser is taken after the user
/// clicks an ad.
class LandingPage {
  /// Advertiser ID of this landing page.
  ///
  /// This is a required field.
  core.String? advertiserId;

  /// Whether this landing page has been archived.
  core.bool? archived;

  /// Links that will direct the user to a mobile app, if installed.
  core.List<DeepLink>? deepLinks;

  /// ID of this landing page.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#landingPage".
  core.String? kind;

  /// Name of this landing page.
  ///
  /// This is a required field. It must be less than 256 characters long.
  core.String? name;

  /// URL of this landing page.
  ///
  /// This is a required field.
  core.String? url;

  LandingPage();

  LandingPage.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('archived')) {
      archived = _json['archived'] as core.bool;
    }
    if (_json.containsKey('deepLinks')) {
      deepLinks = (_json['deepLinks'] as core.List)
          .map<DeepLink>((value) =>
              DeepLink.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (archived != null) 'archived': archived!,
        if (deepLinks != null)
          'deepLinks': deepLinks!.map((value) => value.toJson()).toList(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (url != null) 'url': url!,
      };
}

/// Contains information about a language that can be targeted by ads.
class Language {
  /// Language ID of this language.
  ///
  /// This is the ID used for targeting and generating reports.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#language".
  core.String? kind;

  /// Format of language code is an ISO 639 two-letter language code optionally
  /// followed by an underscore followed by an ISO 3166 code.
  ///
  /// Examples are "en" for English or "zh_CN" for Simplified Chinese.
  core.String? languageCode;

  /// Name of this language.
  core.String? name;

  Language();

  Language.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (name != null) 'name': name!,
      };
}

/// Language Targeting.
class LanguageTargeting {
  /// Languages that this ad targets.
  ///
  /// For each language only languageId is required. The other fields are
  /// populated automatically when the ad is inserted or updated.
  core.List<Language>? languages;

  LanguageTargeting();

  LanguageTargeting.fromJson(core.Map _json) {
    if (_json.containsKey('languages')) {
      languages = (_json['languages'] as core.List)
          .map<Language>((value) =>
              Language.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (languages != null)
          'languages': languages!.map((value) => value.toJson()).toList(),
      };
}

/// Language List Response
class LanguagesListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#languagesListResponse".
  core.String? kind;

  /// Language collection.
  core.List<Language>? languages;

  LanguagesListResponse();

  LanguagesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('languages')) {
      languages = (_json['languages'] as core.List)
          .map<Language>((value) =>
              Language.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (languages != null)
          'languages': languages!.map((value) => value.toJson()).toList(),
      };
}

/// Modification timestamp.
class LastModifiedInfo {
  /// Timestamp of the last change in milliseconds since epoch.
  core.String? time;

  LastModifiedInfo();

  LastModifiedInfo.fromJson(core.Map _json) {
    if (_json.containsKey('time')) {
      time = _json['time'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (time != null) 'time': time!,
      };
}

/// A group clause made up of list population terms representing constraints
/// joined by ORs.
class ListPopulationClause {
  /// Terms of this list population clause.
  ///
  /// Each clause is made up of list population terms representing constraints
  /// and are joined by ORs.
  core.List<ListPopulationTerm>? terms;

  ListPopulationClause();

  ListPopulationClause.fromJson(core.Map _json) {
    if (_json.containsKey('terms')) {
      terms = (_json['terms'] as core.List)
          .map<ListPopulationTerm>((value) => ListPopulationTerm.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (terms != null)
          'terms': terms!.map((value) => value.toJson()).toList(),
      };
}

/// Remarketing List Population Rule.
class ListPopulationRule {
  /// Floodlight activity ID associated with this rule.
  ///
  /// This field can be left blank.
  core.String? floodlightActivityId;

  /// Name of floodlight activity associated with this rule.
  ///
  /// This is a read-only, auto-generated field.
  core.String? floodlightActivityName;

  /// Clauses that make up this list population rule.
  ///
  /// Clauses are joined by ANDs, and the clauses themselves are made up of list
  /// population terms which are joined by ORs.
  core.List<ListPopulationClause>? listPopulationClauses;

  ListPopulationRule();

  ListPopulationRule.fromJson(core.Map _json) {
    if (_json.containsKey('floodlightActivityId')) {
      floodlightActivityId = _json['floodlightActivityId'] as core.String;
    }
    if (_json.containsKey('floodlightActivityName')) {
      floodlightActivityName = _json['floodlightActivityName'] as core.String;
    }
    if (_json.containsKey('listPopulationClauses')) {
      listPopulationClauses = (_json['listPopulationClauses'] as core.List)
          .map<ListPopulationClause>((value) => ListPopulationClause.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (floodlightActivityId != null)
          'floodlightActivityId': floodlightActivityId!,
        if (floodlightActivityName != null)
          'floodlightActivityName': floodlightActivityName!,
        if (listPopulationClauses != null)
          'listPopulationClauses':
              listPopulationClauses!.map((value) => value.toJson()).toList(),
      };
}

/// Remarketing List Population Rule Term.
class ListPopulationTerm {
  /// Will be true if the term should check if the user is in the list and false
  /// if the term should check if the user is not in the list.
  ///
  /// This field is only relevant when type is set to LIST_MEMBERSHIP_TERM.
  /// False by default.
  core.bool? contains;

  /// Whether to negate the comparison result of this term during rule
  /// evaluation.
  ///
  /// This field is only relevant when type is left unset or set to
  /// CUSTOM_VARIABLE_TERM or REFERRER_TERM.
  core.bool? negation;

  /// Comparison operator of this term.
  ///
  /// This field is only relevant when type is left unset or set to
  /// CUSTOM_VARIABLE_TERM or REFERRER_TERM.
  /// Possible string values are:
  /// - "NUM_EQUALS"
  /// - "NUM_LESS_THAN"
  /// - "NUM_LESS_THAN_EQUAL"
  /// - "NUM_GREATER_THAN"
  /// - "NUM_GREATER_THAN_EQUAL"
  /// - "STRING_EQUALS"
  /// - "STRING_CONTAINS"
  core.String? operator;

  /// ID of the list in question.
  ///
  /// This field is only relevant when type is set to LIST_MEMBERSHIP_TERM.
  core.String? remarketingListId;

  /// List population term type determines the applicable fields in this object.
  ///
  /// If left unset or set to CUSTOM_VARIABLE_TERM, then variableName,
  /// variableFriendlyName, operator, value, and negation are applicable. If set
  /// to LIST_MEMBERSHIP_TERM then remarketingListId and contains are
  /// applicable. If set to REFERRER_TERM then operator, value, and negation are
  /// applicable.
  /// Possible string values are:
  /// - "CUSTOM_VARIABLE_TERM"
  /// - "LIST_MEMBERSHIP_TERM"
  /// - "REFERRER_TERM"
  core.String? type;

  /// Literal to compare the variable to.
  ///
  /// This field is only relevant when type is left unset or set to
  /// CUSTOM_VARIABLE_TERM or REFERRER_TERM.
  core.String? value;

  /// Friendly name of this term's variable.
  ///
  /// This is a read-only, auto-generated field. This field is only relevant
  /// when type is left unset or set to CUSTOM_VARIABLE_TERM.
  core.String? variableFriendlyName;

  /// Name of the variable (U1, U2, etc.) being compared in this term.
  ///
  /// This field is only relevant when type is set to null, CUSTOM_VARIABLE_TERM
  /// or REFERRER_TERM.
  core.String? variableName;

  ListPopulationTerm();

  ListPopulationTerm.fromJson(core.Map _json) {
    if (_json.containsKey('contains')) {
      contains = _json['contains'] as core.bool;
    }
    if (_json.containsKey('negation')) {
      negation = _json['negation'] as core.bool;
    }
    if (_json.containsKey('operator')) {
      operator = _json['operator'] as core.String;
    }
    if (_json.containsKey('remarketingListId')) {
      remarketingListId = _json['remarketingListId'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
    if (_json.containsKey('variableFriendlyName')) {
      variableFriendlyName = _json['variableFriendlyName'] as core.String;
    }
    if (_json.containsKey('variableName')) {
      variableName = _json['variableName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contains != null) 'contains': contains!,
        if (negation != null) 'negation': negation!,
        if (operator != null) 'operator': operator!,
        if (remarketingListId != null) 'remarketingListId': remarketingListId!,
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
        if (variableFriendlyName != null)
          'variableFriendlyName': variableFriendlyName!,
        if (variableName != null) 'variableName': variableName!,
      };
}

/// Remarketing List Targeting Expression.
class ListTargetingExpression {
  /// Expression describing which lists are being targeted by the ad.
  core.String? expression;

  ListTargetingExpression();

  ListTargetingExpression.fromJson(core.Map _json) {
    if (_json.containsKey('expression')) {
      expression = _json['expression'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expression != null) 'expression': expression!,
      };
}

/// Lookback configuration settings.
class LookbackConfiguration {
  /// Lookback window, in days, from the last time a given user clicked on one
  /// of your ads.
  ///
  /// If you enter 0, clicks will not be considered as triggering events for
  /// floodlight tracking. If you leave this field blank, the default value for
  /// your account will be used. Acceptable values are 0 to 90, inclusive.
  core.int? clickDuration;

  /// Lookback window, in days, from the last time a given user viewed one of
  /// your ads.
  ///
  /// If you enter 0, impressions will not be considered as triggering events
  /// for floodlight tracking. If you leave this field blank, the default value
  /// for your account will be used. Acceptable values are 0 to 90, inclusive.
  core.int? postImpressionActivitiesDuration;

  LookbackConfiguration();

  LookbackConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('clickDuration')) {
      clickDuration = _json['clickDuration'] as core.int;
    }
    if (_json.containsKey('postImpressionActivitiesDuration')) {
      postImpressionActivitiesDuration =
          _json['postImpressionActivitiesDuration'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clickDuration != null) 'clickDuration': clickDuration!,
        if (postImpressionActivitiesDuration != null)
          'postImpressionActivitiesDuration': postImpressionActivitiesDuration!,
      };
}

/// Represents a metric.
class Metric {
  /// The kind of resource this is, in this case dfareporting#metric.
  core.String? kind;

  /// The metric name, e.g. dfa:impressions
  core.String? name;

  Metric();

  Metric.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// Contains information about a metro region that can be targeted by ads.
class Metro {
  /// Country code of the country to which this metro region belongs.
  core.String? countryCode;

  /// DART ID of the country to which this metro region belongs.
  core.String? countryDartId;

  /// DART ID of this metro region.
  core.String? dartId;

  /// DMA ID of this metro region.
  ///
  /// This is the ID used for targeting and generating reports, and is
  /// equivalent to metro_code.
  core.String? dmaId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#metro".
  core.String? kind;

  /// Metro code of this metro region.
  ///
  /// This is equivalent to dma_id.
  core.String? metroCode;

  /// Name of this metro region.
  core.String? name;

  Metro();

  Metro.fromJson(core.Map _json) {
    if (_json.containsKey('countryCode')) {
      countryCode = _json['countryCode'] as core.String;
    }
    if (_json.containsKey('countryDartId')) {
      countryDartId = _json['countryDartId'] as core.String;
    }
    if (_json.containsKey('dartId')) {
      dartId = _json['dartId'] as core.String;
    }
    if (_json.containsKey('dmaId')) {
      dmaId = _json['dmaId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metroCode')) {
      metroCode = _json['metroCode'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (countryCode != null) 'countryCode': countryCode!,
        if (countryDartId != null) 'countryDartId': countryDartId!,
        if (dartId != null) 'dartId': dartId!,
        if (dmaId != null) 'dmaId': dmaId!,
        if (kind != null) 'kind': kind!,
        if (metroCode != null) 'metroCode': metroCode!,
        if (name != null) 'name': name!,
      };
}

/// Metro List Response
class MetrosListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#metrosListResponse".
  core.String? kind;

  /// Metro collection.
  core.List<Metro>? metros;

  MetrosListResponse();

  MetrosListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metros')) {
      metros = (_json['metros'] as core.List)
          .map<Metro>((value) =>
              Metro.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (metros != null)
          'metros': metros!.map((value) => value.toJson()).toList(),
      };
}

/// Contains information about a mobile app.
///
/// Used as a landing page deep link.
class MobileApp {
  /// Mobile app directory.
  /// Possible string values are:
  /// - "UNKNOWN"
  /// - "APPLE_APP_STORE"
  /// - "GOOGLE_PLAY_STORE"
  core.String? directory;

  /// ID of this mobile app.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#mobileApp".
  core.String? kind;

  /// Publisher name.
  core.String? publisherName;

  /// Title of this mobile app.
  core.String? title;

  MobileApp();

  MobileApp.fromJson(core.Map _json) {
    if (_json.containsKey('directory')) {
      directory = _json['directory'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('publisherName')) {
      publisherName = _json['publisherName'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (directory != null) 'directory': directory!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (publisherName != null) 'publisherName': publisherName!,
        if (title != null) 'title': title!,
      };
}

/// Mobile app List Response
class MobileAppsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#mobileAppsListResponse".
  core.String? kind;

  /// Mobile apps collection.
  core.List<MobileApp>? mobileApps;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  MobileAppsListResponse();

  MobileAppsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('mobileApps')) {
      mobileApps = (_json['mobileApps'] as core.List)
          .map<MobileApp>((value) =>
              MobileApp.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (mobileApps != null)
          'mobileApps': mobileApps!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Contains information about a mobile carrier that can be targeted by ads.
class MobileCarrier {
  /// Country code of the country to which this mobile carrier belongs.
  core.String? countryCode;

  /// DART ID of the country to which this mobile carrier belongs.
  core.String? countryDartId;

  /// ID of this mobile carrier.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#mobileCarrier".
  core.String? kind;

  /// Name of this mobile carrier.
  core.String? name;

  MobileCarrier();

  MobileCarrier.fromJson(core.Map _json) {
    if (_json.containsKey('countryCode')) {
      countryCode = _json['countryCode'] as core.String;
    }
    if (_json.containsKey('countryDartId')) {
      countryDartId = _json['countryDartId'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (countryCode != null) 'countryCode': countryCode!,
        if (countryDartId != null) 'countryDartId': countryDartId!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// Mobile Carrier List Response
class MobileCarriersListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#mobileCarriersListResponse".
  core.String? kind;

  /// Mobile carrier collection.
  core.List<MobileCarrier>? mobileCarriers;

  MobileCarriersListResponse();

  MobileCarriersListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('mobileCarriers')) {
      mobileCarriers = (_json['mobileCarriers'] as core.List)
          .map<MobileCarrier>((value) => MobileCarrier.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (mobileCarriers != null)
          'mobileCarriers':
              mobileCarriers!.map((value) => value.toJson()).toList(),
      };
}

/// Online Behavioral Advertiser icon.
class ObaIcon {
  /// URL to redirect to when an OBA icon is clicked.
  core.String? iconClickThroughUrl;

  /// URL to track click when an OBA icon is clicked.
  core.String? iconClickTrackingUrl;

  /// URL to track view when an OBA icon is clicked.
  core.String? iconViewTrackingUrl;

  /// Identifies the industry initiative that the icon supports.
  ///
  /// For example, AdChoices.
  core.String? program;

  /// OBA icon resource URL.
  ///
  /// Campaign Manager only supports image and JavaScript icons. Learn more
  core.String? resourceUrl;

  /// OBA icon size.
  Size? size;

  /// OBA icon x coordinate position.
  ///
  /// Accepted values are left or right.
  core.String? xPosition;

  /// OBA icon y coordinate position.
  ///
  /// Accepted values are top or bottom.
  core.String? yPosition;

  ObaIcon();

  ObaIcon.fromJson(core.Map _json) {
    if (_json.containsKey('iconClickThroughUrl')) {
      iconClickThroughUrl = _json['iconClickThroughUrl'] as core.String;
    }
    if (_json.containsKey('iconClickTrackingUrl')) {
      iconClickTrackingUrl = _json['iconClickTrackingUrl'] as core.String;
    }
    if (_json.containsKey('iconViewTrackingUrl')) {
      iconViewTrackingUrl = _json['iconViewTrackingUrl'] as core.String;
    }
    if (_json.containsKey('program')) {
      program = _json['program'] as core.String;
    }
    if (_json.containsKey('resourceUrl')) {
      resourceUrl = _json['resourceUrl'] as core.String;
    }
    if (_json.containsKey('size')) {
      size =
          Size.fromJson(_json['size'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('xPosition')) {
      xPosition = _json['xPosition'] as core.String;
    }
    if (_json.containsKey('yPosition')) {
      yPosition = _json['yPosition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (iconClickThroughUrl != null)
          'iconClickThroughUrl': iconClickThroughUrl!,
        if (iconClickTrackingUrl != null)
          'iconClickTrackingUrl': iconClickTrackingUrl!,
        if (iconViewTrackingUrl != null)
          'iconViewTrackingUrl': iconViewTrackingUrl!,
        if (program != null) 'program': program!,
        if (resourceUrl != null) 'resourceUrl': resourceUrl!,
        if (size != null) 'size': size!.toJson(),
        if (xPosition != null) 'xPosition': xPosition!,
        if (yPosition != null) 'yPosition': yPosition!,
      };
}

/// Object Filter.
class ObjectFilter {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#objectFilter".
  core.String? kind;

  /// Applicable when status is ASSIGNED.
  ///
  /// The user has access to objects with these object IDs.
  core.List<core.String>? objectIds;

  /// Status of the filter.
  ///
  /// NONE means the user has access to none of the objects. ALL means the user
  /// has access to all objects. ASSIGNED means the user has access to the
  /// objects with IDs in the objectIds list.
  /// Possible string values are:
  /// - "NONE"
  /// - "ASSIGNED"
  /// - "ALL"
  core.String? status;

  ObjectFilter();

  ObjectFilter.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('objectIds')) {
      objectIds = (_json['objectIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (objectIds != null) 'objectIds': objectIds!,
        if (status != null) 'status': status!,
      };
}

/// Offset Position.
class OffsetPosition {
  /// Offset distance from left side of an asset or a window.
  core.int? left;

  /// Offset distance from top side of an asset or a window.
  core.int? top;

  OffsetPosition();

  OffsetPosition.fromJson(core.Map _json) {
    if (_json.containsKey('left')) {
      left = _json['left'] as core.int;
    }
    if (_json.containsKey('top')) {
      top = _json['top'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (left != null) 'left': left!,
        if (top != null) 'top': top!,
      };
}

/// Omniture Integration Settings.
class OmnitureSettings {
  /// Whether placement cost data will be sent to Omniture.
  ///
  /// This property can be enabled only if omnitureIntegrationEnabled is true.
  core.bool? omnitureCostDataEnabled;

  /// Whether Omniture integration is enabled.
  ///
  /// This property can be enabled only when the "Advanced Ad Serving" account
  /// setting is enabled.
  core.bool? omnitureIntegrationEnabled;

  OmnitureSettings();

  OmnitureSettings.fromJson(core.Map _json) {
    if (_json.containsKey('omnitureCostDataEnabled')) {
      omnitureCostDataEnabled = _json['omnitureCostDataEnabled'] as core.bool;
    }
    if (_json.containsKey('omnitureIntegrationEnabled')) {
      omnitureIntegrationEnabled =
          _json['omnitureIntegrationEnabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (omnitureCostDataEnabled != null)
          'omnitureCostDataEnabled': omnitureCostDataEnabled!,
        if (omnitureIntegrationEnabled != null)
          'omnitureIntegrationEnabled': omnitureIntegrationEnabled!,
      };
}

/// Contains information about an operating system that can be targeted by ads.
class OperatingSystem {
  /// DART ID of this operating system.
  ///
  /// This is the ID used for targeting.
  core.String? dartId;

  /// Whether this operating system is for desktop.
  core.bool? desktop;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#operatingSystem".
  core.String? kind;

  /// Whether this operating system is for mobile.
  core.bool? mobile;

  /// Name of this operating system.
  core.String? name;

  OperatingSystem();

  OperatingSystem.fromJson(core.Map _json) {
    if (_json.containsKey('dartId')) {
      dartId = _json['dartId'] as core.String;
    }
    if (_json.containsKey('desktop')) {
      desktop = _json['desktop'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('mobile')) {
      mobile = _json['mobile'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dartId != null) 'dartId': dartId!,
        if (desktop != null) 'desktop': desktop!,
        if (kind != null) 'kind': kind!,
        if (mobile != null) 'mobile': mobile!,
        if (name != null) 'name': name!,
      };
}

/// Contains information about a particular version of an operating system that
/// can be targeted by ads.
class OperatingSystemVersion {
  /// ID of this operating system version.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#operatingSystemVersion".
  core.String? kind;

  /// Major version (leftmost number) of this operating system version.
  core.String? majorVersion;

  /// Minor version (number after the first dot) of this operating system
  /// version.
  core.String? minorVersion;

  /// Name of this operating system version.
  core.String? name;

  /// Operating system of this operating system version.
  OperatingSystem? operatingSystem;

  OperatingSystemVersion();

  OperatingSystemVersion.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('majorVersion')) {
      majorVersion = _json['majorVersion'] as core.String;
    }
    if (_json.containsKey('minorVersion')) {
      minorVersion = _json['minorVersion'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('operatingSystem')) {
      operatingSystem = OperatingSystem.fromJson(
          _json['operatingSystem'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (majorVersion != null) 'majorVersion': majorVersion!,
        if (minorVersion != null) 'minorVersion': minorVersion!,
        if (name != null) 'name': name!,
        if (operatingSystem != null)
          'operatingSystem': operatingSystem!.toJson(),
      };
}

/// Operating System Version List Response
class OperatingSystemVersionsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "dfareporting#operatingSystemVersionsListResponse".
  core.String? kind;

  /// Operating system version collection.
  core.List<OperatingSystemVersion>? operatingSystemVersions;

  OperatingSystemVersionsListResponse();

  OperatingSystemVersionsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('operatingSystemVersions')) {
      operatingSystemVersions = (_json['operatingSystemVersions'] as core.List)
          .map<OperatingSystemVersion>((value) =>
              OperatingSystemVersion.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (operatingSystemVersions != null)
          'operatingSystemVersions':
              operatingSystemVersions!.map((value) => value.toJson()).toList(),
      };
}

/// Operating System List Response
class OperatingSystemsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#operatingSystemsListResponse".
  core.String? kind;

  /// Operating system collection.
  core.List<OperatingSystem>? operatingSystems;

  OperatingSystemsListResponse();

  OperatingSystemsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('operatingSystems')) {
      operatingSystems = (_json['operatingSystems'] as core.List)
          .map<OperatingSystem>((value) => OperatingSystem.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (operatingSystems != null)
          'operatingSystems':
              operatingSystems!.map((value) => value.toJson()).toList(),
      };
}

/// Creative optimization activity.
class OptimizationActivity {
  /// Floodlight activity ID of this optimization activity.
  ///
  /// This is a required field.
  core.String? floodlightActivityId;

  /// Dimension value for the ID of the floodlight activity.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? floodlightActivityIdDimensionValue;

  /// Weight associated with this optimization.
  ///
  /// The weight assigned will be understood in proportion to the weights
  /// assigned to the other optimization activities. Value must be greater than
  /// or equal to 1.
  core.int? weight;

  OptimizationActivity();

  OptimizationActivity.fromJson(core.Map _json) {
    if (_json.containsKey('floodlightActivityId')) {
      floodlightActivityId = _json['floodlightActivityId'] as core.String;
    }
    if (_json.containsKey('floodlightActivityIdDimensionValue')) {
      floodlightActivityIdDimensionValue = DimensionValue.fromJson(
          _json['floodlightActivityIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('weight')) {
      weight = _json['weight'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (floodlightActivityId != null)
          'floodlightActivityId': floodlightActivityId!,
        if (floodlightActivityIdDimensionValue != null)
          'floodlightActivityIdDimensionValue':
              floodlightActivityIdDimensionValue!.toJson(),
        if (weight != null) 'weight': weight!,
      };
}

/// Describes properties of a Planning order.
class Order {
  /// Account ID of this order.
  core.String? accountId;

  /// Advertiser ID of this order.
  core.String? advertiserId;

  /// IDs for users that have to approve documents created for this order.
  core.List<core.String>? approverUserProfileIds;

  /// Buyer invoice ID associated with this order.
  core.String? buyerInvoiceId;

  /// Name of the buyer organization.
  core.String? buyerOrganizationName;

  /// Comments in this order.
  core.String? comments;

  /// Contacts for this order.
  core.List<OrderContact>? contacts;

  /// ID of this order.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#order".
  core.String? kind;

  /// Information about the most recent modification of this order.
  LastModifiedInfo? lastModifiedInfo;

  /// Name of this order.
  core.String? name;

  /// Notes of this order.
  core.String? notes;

  /// ID of the terms and conditions template used in this order.
  core.String? planningTermId;

  /// Project ID of this order.
  core.String? projectId;

  /// Seller order ID associated with this order.
  core.String? sellerOrderId;

  /// Name of the seller organization.
  core.String? sellerOrganizationName;

  /// Site IDs this order is associated with.
  core.List<core.String>? siteId;

  /// Free-form site names this order is associated with.
  core.List<core.String>? siteNames;

  /// Subaccount ID of this order.
  core.String? subaccountId;

  /// Terms and conditions of this order.
  core.String? termsAndConditions;

  Order();

  Order.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('approverUserProfileIds')) {
      approverUserProfileIds = (_json['approverUserProfileIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('buyerInvoiceId')) {
      buyerInvoiceId = _json['buyerInvoiceId'] as core.String;
    }
    if (_json.containsKey('buyerOrganizationName')) {
      buyerOrganizationName = _json['buyerOrganizationName'] as core.String;
    }
    if (_json.containsKey('comments')) {
      comments = _json['comments'] as core.String;
    }
    if (_json.containsKey('contacts')) {
      contacts = (_json['contacts'] as core.List)
          .map<OrderContact>((value) => OrderContact.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifiedInfo')) {
      lastModifiedInfo = LastModifiedInfo.fromJson(
          _json['lastModifiedInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('notes')) {
      notes = _json['notes'] as core.String;
    }
    if (_json.containsKey('planningTermId')) {
      planningTermId = _json['planningTermId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('sellerOrderId')) {
      sellerOrderId = _json['sellerOrderId'] as core.String;
    }
    if (_json.containsKey('sellerOrganizationName')) {
      sellerOrganizationName = _json['sellerOrganizationName'] as core.String;
    }
    if (_json.containsKey('siteId')) {
      siteId = (_json['siteId'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('siteNames')) {
      siteNames = (_json['siteNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('termsAndConditions')) {
      termsAndConditions = _json['termsAndConditions'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (approverUserProfileIds != null)
          'approverUserProfileIds': approverUserProfileIds!,
        if (buyerInvoiceId != null) 'buyerInvoiceId': buyerInvoiceId!,
        if (buyerOrganizationName != null)
          'buyerOrganizationName': buyerOrganizationName!,
        if (comments != null) 'comments': comments!,
        if (contacts != null)
          'contacts': contacts!.map((value) => value.toJson()).toList(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (lastModifiedInfo != null)
          'lastModifiedInfo': lastModifiedInfo!.toJson(),
        if (name != null) 'name': name!,
        if (notes != null) 'notes': notes!,
        if (planningTermId != null) 'planningTermId': planningTermId!,
        if (projectId != null) 'projectId': projectId!,
        if (sellerOrderId != null) 'sellerOrderId': sellerOrderId!,
        if (sellerOrganizationName != null)
          'sellerOrganizationName': sellerOrganizationName!,
        if (siteId != null) 'siteId': siteId!,
        if (siteNames != null) 'siteNames': siteNames!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (termsAndConditions != null)
          'termsAndConditions': termsAndConditions!,
      };
}

/// Contact of an order.
class OrderContact {
  /// Free-form information about this contact.
  ///
  /// It could be any information related to this contact in addition to type,
  /// title, name, and signature user profile ID.
  core.String? contactInfo;

  /// Name of this contact.
  core.String? contactName;

  /// Title of this contact.
  core.String? contactTitle;

  /// Type of this contact.
  /// Possible string values are:
  /// - "PLANNING_ORDER_CONTACT_BUYER_CONTACT"
  /// - "PLANNING_ORDER_CONTACT_BUYER_BILLING_CONTACT"
  /// - "PLANNING_ORDER_CONTACT_SELLER_CONTACT"
  core.String? contactType;

  /// ID of the user profile containing the signature that will be embedded into
  /// order documents.
  core.String? signatureUserProfileId;

  OrderContact();

  OrderContact.fromJson(core.Map _json) {
    if (_json.containsKey('contactInfo')) {
      contactInfo = _json['contactInfo'] as core.String;
    }
    if (_json.containsKey('contactName')) {
      contactName = _json['contactName'] as core.String;
    }
    if (_json.containsKey('contactTitle')) {
      contactTitle = _json['contactTitle'] as core.String;
    }
    if (_json.containsKey('contactType')) {
      contactType = _json['contactType'] as core.String;
    }
    if (_json.containsKey('signatureUserProfileId')) {
      signatureUserProfileId = _json['signatureUserProfileId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contactInfo != null) 'contactInfo': contactInfo!,
        if (contactName != null) 'contactName': contactName!,
        if (contactTitle != null) 'contactTitle': contactTitle!,
        if (contactType != null) 'contactType': contactType!,
        if (signatureUserProfileId != null)
          'signatureUserProfileId': signatureUserProfileId!,
      };
}

/// Contains properties of a Planning order document.
class OrderDocument {
  /// Account ID of this order document.
  core.String? accountId;

  /// Advertiser ID of this order document.
  core.String? advertiserId;

  /// The amended order document ID of this order document.
  ///
  /// An order document can be created by optionally amending another order
  /// document so that the change history can be preserved.
  core.String? amendedOrderDocumentId;

  /// IDs of users who have approved this order document.
  core.List<core.String>? approvedByUserProfileIds;

  /// Whether this order document is cancelled.
  core.bool? cancelled;

  /// Information about the creation of this order document.
  LastModifiedInfo? createdInfo;
  core.DateTime? effectiveDate;

  /// ID of this order document.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#orderDocument".
  core.String? kind;

  /// List of email addresses that received the last sent document.
  core.List<core.String>? lastSentRecipients;
  core.DateTime? lastSentTime;

  /// ID of the order from which this order document is created.
  core.String? orderId;

  /// Project ID of this order document.
  core.String? projectId;

  /// Whether this order document has been signed.
  core.bool? signed;

  /// Subaccount ID of this order document.
  core.String? subaccountId;

  /// Title of this order document.
  core.String? title;

  /// Type of this order document
  /// Possible string values are:
  /// - "PLANNING_ORDER_TYPE_INSERTION_ORDER"
  /// - "PLANNING_ORDER_TYPE_CHANGE_ORDER"
  core.String? type;

  OrderDocument();

  OrderDocument.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('amendedOrderDocumentId')) {
      amendedOrderDocumentId = _json['amendedOrderDocumentId'] as core.String;
    }
    if (_json.containsKey('approvedByUserProfileIds')) {
      approvedByUserProfileIds =
          (_json['approvedByUserProfileIds'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('cancelled')) {
      cancelled = _json['cancelled'] as core.bool;
    }
    if (_json.containsKey('createdInfo')) {
      createdInfo = LastModifiedInfo.fromJson(
          _json['createdInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('effectiveDate')) {
      effectiveDate =
          core.DateTime.parse(_json['effectiveDate'] as core.String);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastSentRecipients')) {
      lastSentRecipients = (_json['lastSentRecipients'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('lastSentTime')) {
      lastSentTime = core.DateTime.parse(_json['lastSentTime'] as core.String);
    }
    if (_json.containsKey('orderId')) {
      orderId = _json['orderId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('signed')) {
      signed = _json['signed'] as core.bool;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (amendedOrderDocumentId != null)
          'amendedOrderDocumentId': amendedOrderDocumentId!,
        if (approvedByUserProfileIds != null)
          'approvedByUserProfileIds': approvedByUserProfileIds!,
        if (cancelled != null) 'cancelled': cancelled!,
        if (createdInfo != null) 'createdInfo': createdInfo!.toJson(),
        if (effectiveDate != null)
          'effectiveDate':
              "${(effectiveDate!).year.toString().padLeft(4, '0')}-${(effectiveDate!).month.toString().padLeft(2, '0')}-${(effectiveDate!).day.toString().padLeft(2, '0')}",
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (lastSentRecipients != null)
          'lastSentRecipients': lastSentRecipients!,
        if (lastSentTime != null)
          'lastSentTime': lastSentTime!.toIso8601String(),
        if (orderId != null) 'orderId': orderId!,
        if (projectId != null) 'projectId': projectId!,
        if (signed != null) 'signed': signed!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (title != null) 'title': title!,
        if (type != null) 'type': type!,
      };
}

/// Order document List Response
class OrderDocumentsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#orderDocumentsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  /// Order document collection
  core.List<OrderDocument>? orderDocuments;

  OrderDocumentsListResponse();

  OrderDocumentsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('orderDocuments')) {
      orderDocuments = (_json['orderDocuments'] as core.List)
          .map<OrderDocument>((value) => OrderDocument.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (orderDocuments != null)
          'orderDocuments':
              orderDocuments!.map((value) => value.toJson()).toList(),
      };
}

/// Order List Response
class OrdersListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#ordersListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  /// Order collection.
  core.List<Order>? orders;

  OrdersListResponse();

  OrdersListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('orders')) {
      orders = (_json['orders'] as core.List)
          .map<Order>((value) =>
              Order.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (orders != null)
          'orders': orders!.map((value) => value.toJson()).toList(),
      };
}

/// Represents a DfaReporting path filter.
class PathFilter {
  /// Event filters in path report.
  core.List<EventFilter>? eventFilters;

  /// The kind of resource this is, in this case dfareporting#pathFilter.
  core.String? kind;

  /// Determines how the 'value' field is matched when filtering.
  ///
  /// If not specified, defaults to EXACT. If set to WILDCARD_EXPRESSION, '*' is
  /// allowed as a placeholder for variable length character sequences, and it
  /// can be escaped with a backslash. Note, only paid search dimensions
  /// ('dfa:paidSearch*') allow a matchType other than EXACT.
  /// Possible string values are:
  /// - "PATH_MATCH_POSITION_UNSPECIFIED"
  /// - "ANY"
  /// - "FIRST"
  /// - "LAST"
  core.String? pathMatchPosition;

  PathFilter();

  PathFilter.fromJson(core.Map _json) {
    if (_json.containsKey('eventFilters')) {
      eventFilters = (_json['eventFilters'] as core.List)
          .map<EventFilter>((value) => EventFilter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('pathMatchPosition')) {
      pathMatchPosition = _json['pathMatchPosition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (eventFilters != null)
          'eventFilters': eventFilters!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (pathMatchPosition != null) 'pathMatchPosition': pathMatchPosition!,
      };
}

/// Represents fields that are compatible to be selected for a report of type
/// "PATH".
class PathReportCompatibleFields {
  /// Dimensions which are compatible to be selected in the "channelGroupings"
  /// section of the report.
  core.List<Dimension>? channelGroupings;

  /// Dimensions which are compatible to be selected in the "dimensions" section
  /// of the report.
  core.List<Dimension>? dimensions;

  /// The kind of resource this is, in this case
  /// dfareporting#pathReportCompatibleFields.
  core.String? kind;

  /// Metrics which are compatible to be selected in the "metricNames" section
  /// of the report.
  core.List<Metric>? metrics;

  /// Dimensions which are compatible to be selected in the "pathFilters"
  /// section of the report.
  core.List<Dimension>? pathFilters;

  PathReportCompatibleFields();

  PathReportCompatibleFields.fromJson(core.Map _json) {
    if (_json.containsKey('channelGroupings')) {
      channelGroupings = (_json['channelGroupings'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dimensions')) {
      dimensions = (_json['dimensions'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.List)
          .map<Metric>((value) =>
              Metric.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('pathFilters')) {
      pathFilters = (_json['pathFilters'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channelGroupings != null)
          'channelGroupings':
              channelGroupings!.map((value) => value.toJson()).toList(),
        if (dimensions != null)
          'dimensions': dimensions!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (metrics != null)
          'metrics': metrics!.map((value) => value.toJson()).toList(),
        if (pathFilters != null)
          'pathFilters': pathFilters!.map((value) => value.toJson()).toList(),
      };
}

/// Represents a PathReportDimensionValue resource.
class PathReportDimensionValue {
  /// The name of the dimension.
  core.String? dimensionName;

  /// The possible ID's associated with the value if available.
  core.List<core.String>? ids;

  /// The kind of resource this is, in this case
  /// dfareporting#pathReportDimensionValue.
  core.String? kind;

  /// Determines how the 'value' field is matched when filtering.
  ///
  /// If not specified, defaults to EXACT. If set to WILDCARD_EXPRESSION, '*' is
  /// allowed as a placeholder for variable length character sequences, and it
  /// can be escaped with a backslash. Note, only paid search dimensions
  /// ('dfa:paidSearch*') allow a matchType other than EXACT.
  /// Possible string values are:
  /// - "EXACT"
  /// - "BEGINS_WITH"
  /// - "CONTAINS"
  /// - "WILDCARD_EXPRESSION"
  core.String? matchType;

  /// The possible values of the dimension.
  core.List<core.String>? values;

  PathReportDimensionValue();

  PathReportDimensionValue.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionName')) {
      dimensionName = _json['dimensionName'] as core.String;
    }
    if (_json.containsKey('ids')) {
      ids = (_json['ids'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('matchType')) {
      matchType = _json['matchType'] as core.String;
    }
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionName != null) 'dimensionName': dimensionName!,
        if (ids != null) 'ids': ids!,
        if (kind != null) 'kind': kind!,
        if (matchType != null) 'matchType': matchType!,
        if (values != null) 'values': values!,
      };
}

/// Represents fields that are compatible to be selected for a report of type
/// "PATH_TO_CONVERSION".
class PathToConversionReportCompatibleFields {
  /// Conversion dimensions which are compatible to be selected in the
  /// "conversionDimensions" section of the report.
  core.List<Dimension>? conversionDimensions;

  /// Custom floodlight variables which are compatible to be selected in the
  /// "customFloodlightVariables" section of the report.
  core.List<Dimension>? customFloodlightVariables;

  /// The kind of resource this is, in this case
  /// dfareporting#pathToConversionReportCompatibleFields.
  core.String? kind;

  /// Metrics which are compatible to be selected in the "metricNames" section
  /// of the report.
  core.List<Metric>? metrics;

  /// Per-interaction dimensions which are compatible to be selected in the
  /// "perInteractionDimensions" section of the report.
  core.List<Dimension>? perInteractionDimensions;

  PathToConversionReportCompatibleFields();

  PathToConversionReportCompatibleFields.fromJson(core.Map _json) {
    if (_json.containsKey('conversionDimensions')) {
      conversionDimensions = (_json['conversionDimensions'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('customFloodlightVariables')) {
      customFloodlightVariables = (_json['customFloodlightVariables']
              as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.List)
          .map<Metric>((value) =>
              Metric.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('perInteractionDimensions')) {
      perInteractionDimensions = (_json['perInteractionDimensions']
              as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conversionDimensions != null)
          'conversionDimensions':
              conversionDimensions!.map((value) => value.toJson()).toList(),
        if (customFloodlightVariables != null)
          'customFloodlightVariables': customFloodlightVariables!
              .map((value) => value.toJson())
              .toList(),
        if (kind != null) 'kind': kind!,
        if (metrics != null)
          'metrics': metrics!.map((value) => value.toJson()).toList(),
        if (perInteractionDimensions != null)
          'perInteractionDimensions':
              perInteractionDimensions!.map((value) => value.toJson()).toList(),
      };
}

/// Contains properties of a placement.
class Placement {
  /// Account ID of this placement.
  ///
  /// This field can be left blank.
  core.String? accountId;

  /// Whether this placement opts out of ad blocking.
  ///
  /// When true, ad blocking is disabled for this placement. When false, the
  /// campaign and site settings take effect.
  core.bool? adBlockingOptOut;

  /// Additional sizes associated with this placement.
  ///
  /// When inserting or updating a placement, only the size ID field is used.
  core.List<Size>? additionalSizes;

  /// Advertiser ID of this placement.
  ///
  /// This field can be left blank.
  core.String? advertiserId;

  /// Dimension value for the ID of the advertiser.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? advertiserIdDimensionValue;

  /// Whether this placement is archived.
  core.bool? archived;

  /// Campaign ID of this placement.
  ///
  /// This field is a required field on insertion.
  core.String? campaignId;

  /// Dimension value for the ID of the campaign.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? campaignIdDimensionValue;

  /// Comments for this placement.
  core.String? comment;

  /// Placement compatibility.
  ///
  /// DISPLAY and DISPLAY_INTERSTITIAL refer to rendering on desktop, on mobile
  /// devices or in mobile apps for regular or interstitial ads respectively.
  /// APP and APP_INTERSTITIAL are no longer allowed for new placement
  /// insertions. Instead, use DISPLAY or DISPLAY_INTERSTITIAL. IN_STREAM_VIDEO
  /// refers to rendering in in-stream video ads developed with the VAST
  /// standard. This field is required on insertion.
  /// Possible string values are:
  /// - "DISPLAY"
  /// - "DISPLAY_INTERSTITIAL"
  /// - "APP"
  /// - "APP_INTERSTITIAL"
  /// - "IN_STREAM_VIDEO"
  /// - "IN_STREAM_AUDIO"
  core.String? compatibility;

  /// ID of the content category assigned to this placement.
  core.String? contentCategoryId;

  /// Information about the creation of this placement.
  ///
  /// This is a read-only field.
  LastModifiedInfo? createInfo;

  /// Directory site ID of this placement.
  ///
  /// On insert, you must set either this field or the siteId field to specify
  /// the site associated with this placement. This is a required field that is
  /// read-only after insertion.
  core.String? directorySiteId;

  /// Dimension value for the ID of the directory site.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? directorySiteIdDimensionValue;

  /// External ID for this placement.
  core.String? externalId;

  /// ID of this placement.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Dimension value for the ID of this placement.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? idDimensionValue;

  /// Key name of this placement.
  ///
  /// This is a read-only, auto-generated field.
  core.String? keyName;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#placement".
  core.String? kind;

  /// Information about the most recent modification of this placement.
  ///
  /// This is a read-only field.
  LastModifiedInfo? lastModifiedInfo;

  /// Lookback window settings for this placement.
  LookbackConfiguration? lookbackConfiguration;

  /// Name of this placement.This is a required field and must be less than or
  /// equal to 256 characters long.
  core.String? name;

  /// Whether payment was approved for this placement.
  ///
  /// This is a read-only field relevant only to publisher-paid placements.
  core.bool? paymentApproved;

  /// Payment source for this placement.
  ///
  /// This is a required field that is read-only after insertion.
  /// Possible string values are:
  /// - "PLACEMENT_AGENCY_PAID"
  /// - "PLACEMENT_PUBLISHER_PAID"
  core.String? paymentSource;

  /// ID of this placement's group, if applicable.
  core.String? placementGroupId;

  /// Dimension value for the ID of the placement group.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? placementGroupIdDimensionValue;

  /// ID of the placement strategy assigned to this placement.
  core.String? placementStrategyId;

  /// Pricing schedule of this placement.
  ///
  /// This field is required on insertion, specifically subfields startDate,
  /// endDate and pricingType.
  PricingSchedule? pricingSchedule;

  /// Whether this placement is the primary placement of a roadblock (placement
  /// group).
  ///
  /// You cannot change this field from true to false. Setting this field to
  /// true will automatically set the primary field on the original primary
  /// placement of the roadblock to false, and it will automatically set the
  /// roadblock's primaryPlacementId field to the ID of this placement.
  core.bool? primary;

  /// Information about the last publisher update.
  ///
  /// This is a read-only field.
  LastModifiedInfo? publisherUpdateInfo;

  /// Site ID associated with this placement.
  ///
  /// On insert, you must set either this field or the directorySiteId field to
  /// specify the site associated with this placement. This is a required field
  /// that is read-only after insertion.
  core.String? siteId;

  /// Dimension value for the ID of the site.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? siteIdDimensionValue;

  /// Size associated with this placement.
  ///
  /// When inserting or updating a placement, only the size ID field is used.
  /// This field is required on insertion.
  Size? size;

  /// Whether creatives assigned to this placement must be SSL-compliant.
  core.bool? sslRequired;

  /// Third-party placement status.
  /// Possible string values are:
  /// - "PENDING_REVIEW"
  /// - "PAYMENT_ACCEPTED"
  /// - "PAYMENT_REJECTED"
  /// - "ACKNOWLEDGE_REJECTION"
  /// - "ACKNOWLEDGE_ACCEPTANCE"
  /// - "DRAFT"
  core.String? status;

  /// Subaccount ID of this placement.
  ///
  /// This field can be left blank.
  core.String? subaccountId;

  /// Tag formats to generate for this placement.
  ///
  /// This field is required on insertion. Acceptable values are: -
  /// "PLACEMENT_TAG_STANDARD" - "PLACEMENT_TAG_IFRAME_JAVASCRIPT" -
  /// "PLACEMENT_TAG_IFRAME_ILAYER" - "PLACEMENT_TAG_INTERNAL_REDIRECT" -
  /// "PLACEMENT_TAG_JAVASCRIPT" -
  /// "PLACEMENT_TAG_INTERSTITIAL_IFRAME_JAVASCRIPT" -
  /// "PLACEMENT_TAG_INTERSTITIAL_INTERNAL_REDIRECT" -
  /// "PLACEMENT_TAG_INTERSTITIAL_JAVASCRIPT" - "PLACEMENT_TAG_CLICK_COMMANDS" -
  /// "PLACEMENT_TAG_INSTREAM_VIDEO_PREFETCH" -
  /// "PLACEMENT_TAG_INSTREAM_VIDEO_PREFETCH_VAST_3" -
  /// "PLACEMENT_TAG_INSTREAM_VIDEO_PREFETCH_VAST_4" - "PLACEMENT_TAG_TRACKING"
  /// - "PLACEMENT_TAG_TRACKING_IFRAME" - "PLACEMENT_TAG_TRACKING_JAVASCRIPT"
  core.List<core.String>? tagFormats;

  /// Tag settings for this placement.
  TagSetting? tagSetting;

  /// Whether Verification and ActiveView are disabled for in-stream video
  /// creatives for this placement.
  ///
  /// The same setting videoActiveViewOptOut exists on the site level -- the opt
  /// out occurs if either of these settings are true. These settings are
  /// distinct from DirectorySites.settings.activeViewOptOut or
  /// Sites.siteSettings.activeViewOptOut which only apply to display ads.
  /// However, Accounts.activeViewOptOut opts out both video traffic, as well as
  /// display ads, from Verification and ActiveView.
  core.bool? videoActiveViewOptOut;

  /// A collection of settings which affect video creatives served through this
  /// placement.
  ///
  /// Applicable to placements with IN_STREAM_VIDEO compatibility.
  VideoSettings? videoSettings;

  /// VPAID adapter setting for this placement.
  ///
  /// Controls which VPAID format the measurement adapter will use for in-stream
  /// video creatives assigned to this placement. *Note:* Flash is no longer
  /// supported. This field now defaults to HTML5 when the following values are
  /// provided: FLASH, BOTH.
  /// Possible string values are:
  /// - "DEFAULT"
  /// - "FLASH"
  /// - "HTML5"
  /// - "BOTH"
  core.String? vpaidAdapterChoice;

  Placement();

  Placement.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('adBlockingOptOut')) {
      adBlockingOptOut = _json['adBlockingOptOut'] as core.bool;
    }
    if (_json.containsKey('additionalSizes')) {
      additionalSizes = (_json['additionalSizes'] as core.List)
          .map<Size>((value) =>
              Size.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('archived')) {
      archived = _json['archived'] as core.bool;
    }
    if (_json.containsKey('campaignId')) {
      campaignId = _json['campaignId'] as core.String;
    }
    if (_json.containsKey('campaignIdDimensionValue')) {
      campaignIdDimensionValue = DimensionValue.fromJson(
          _json['campaignIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('comment')) {
      comment = _json['comment'] as core.String;
    }
    if (_json.containsKey('compatibility')) {
      compatibility = _json['compatibility'] as core.String;
    }
    if (_json.containsKey('contentCategoryId')) {
      contentCategoryId = _json['contentCategoryId'] as core.String;
    }
    if (_json.containsKey('createInfo')) {
      createInfo = LastModifiedInfo.fromJson(
          _json['createInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('directorySiteId')) {
      directorySiteId = _json['directorySiteId'] as core.String;
    }
    if (_json.containsKey('directorySiteIdDimensionValue')) {
      directorySiteIdDimensionValue = DimensionValue.fromJson(
          _json['directorySiteIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('externalId')) {
      externalId = _json['externalId'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('keyName')) {
      keyName = _json['keyName'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifiedInfo')) {
      lastModifiedInfo = LastModifiedInfo.fromJson(
          _json['lastModifiedInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lookbackConfiguration')) {
      lookbackConfiguration = LookbackConfiguration.fromJson(
          _json['lookbackConfiguration']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('paymentApproved')) {
      paymentApproved = _json['paymentApproved'] as core.bool;
    }
    if (_json.containsKey('paymentSource')) {
      paymentSource = _json['paymentSource'] as core.String;
    }
    if (_json.containsKey('placementGroupId')) {
      placementGroupId = _json['placementGroupId'] as core.String;
    }
    if (_json.containsKey('placementGroupIdDimensionValue')) {
      placementGroupIdDimensionValue = DimensionValue.fromJson(
          _json['placementGroupIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('placementStrategyId')) {
      placementStrategyId = _json['placementStrategyId'] as core.String;
    }
    if (_json.containsKey('pricingSchedule')) {
      pricingSchedule = PricingSchedule.fromJson(
          _json['pricingSchedule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('primary')) {
      primary = _json['primary'] as core.bool;
    }
    if (_json.containsKey('publisherUpdateInfo')) {
      publisherUpdateInfo = LastModifiedInfo.fromJson(
          _json['publisherUpdateInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('siteId')) {
      siteId = _json['siteId'] as core.String;
    }
    if (_json.containsKey('siteIdDimensionValue')) {
      siteIdDimensionValue = DimensionValue.fromJson(
          _json['siteIdDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('size')) {
      size =
          Size.fromJson(_json['size'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sslRequired')) {
      sslRequired = _json['sslRequired'] as core.bool;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('tagFormats')) {
      tagFormats = (_json['tagFormats'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('tagSetting')) {
      tagSetting = TagSetting.fromJson(
          _json['tagSetting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('videoActiveViewOptOut')) {
      videoActiveViewOptOut = _json['videoActiveViewOptOut'] as core.bool;
    }
    if (_json.containsKey('videoSettings')) {
      videoSettings = VideoSettings.fromJson(
          _json['videoSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('vpaidAdapterChoice')) {
      vpaidAdapterChoice = _json['vpaidAdapterChoice'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (adBlockingOptOut != null) 'adBlockingOptOut': adBlockingOptOut!,
        if (additionalSizes != null)
          'additionalSizes':
              additionalSizes!.map((value) => value.toJson()).toList(),
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (archived != null) 'archived': archived!,
        if (campaignId != null) 'campaignId': campaignId!,
        if (campaignIdDimensionValue != null)
          'campaignIdDimensionValue': campaignIdDimensionValue!.toJson(),
        if (comment != null) 'comment': comment!,
        if (compatibility != null) 'compatibility': compatibility!,
        if (contentCategoryId != null) 'contentCategoryId': contentCategoryId!,
        if (createInfo != null) 'createInfo': createInfo!.toJson(),
        if (directorySiteId != null) 'directorySiteId': directorySiteId!,
        if (directorySiteIdDimensionValue != null)
          'directorySiteIdDimensionValue':
              directorySiteIdDimensionValue!.toJson(),
        if (externalId != null) 'externalId': externalId!,
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (keyName != null) 'keyName': keyName!,
        if (kind != null) 'kind': kind!,
        if (lastModifiedInfo != null)
          'lastModifiedInfo': lastModifiedInfo!.toJson(),
        if (lookbackConfiguration != null)
          'lookbackConfiguration': lookbackConfiguration!.toJson(),
        if (name != null) 'name': name!,
        if (paymentApproved != null) 'paymentApproved': paymentApproved!,
        if (paymentSource != null) 'paymentSource': paymentSource!,
        if (placementGroupId != null) 'placementGroupId': placementGroupId!,
        if (placementGroupIdDimensionValue != null)
          'placementGroupIdDimensionValue':
              placementGroupIdDimensionValue!.toJson(),
        if (placementStrategyId != null)
          'placementStrategyId': placementStrategyId!,
        if (pricingSchedule != null)
          'pricingSchedule': pricingSchedule!.toJson(),
        if (primary != null) 'primary': primary!,
        if (publisherUpdateInfo != null)
          'publisherUpdateInfo': publisherUpdateInfo!.toJson(),
        if (siteId != null) 'siteId': siteId!,
        if (siteIdDimensionValue != null)
          'siteIdDimensionValue': siteIdDimensionValue!.toJson(),
        if (size != null) 'size': size!.toJson(),
        if (sslRequired != null) 'sslRequired': sslRequired!,
        if (status != null) 'status': status!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (tagFormats != null) 'tagFormats': tagFormats!,
        if (tagSetting != null) 'tagSetting': tagSetting!.toJson(),
        if (videoActiveViewOptOut != null)
          'videoActiveViewOptOut': videoActiveViewOptOut!,
        if (videoSettings != null) 'videoSettings': videoSettings!.toJson(),
        if (vpaidAdapterChoice != null)
          'vpaidAdapterChoice': vpaidAdapterChoice!,
      };
}

/// Placement Assignment.
class PlacementAssignment {
  /// Whether this placement assignment is active.
  ///
  /// When true, the placement will be included in the ad's rotation.
  core.bool? active;

  /// ID of the placement to be assigned.
  ///
  /// This is a required field.
  core.String? placementId;

  /// Dimension value for the ID of the placement.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? placementIdDimensionValue;

  /// Whether the placement to be assigned requires SSL.
  ///
  /// This is a read-only field that is auto-generated when the ad is inserted
  /// or updated.
  core.bool? sslRequired;

  PlacementAssignment();

  PlacementAssignment.fromJson(core.Map _json) {
    if (_json.containsKey('active')) {
      active = _json['active'] as core.bool;
    }
    if (_json.containsKey('placementId')) {
      placementId = _json['placementId'] as core.String;
    }
    if (_json.containsKey('placementIdDimensionValue')) {
      placementIdDimensionValue = DimensionValue.fromJson(
          _json['placementIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sslRequired')) {
      sslRequired = _json['sslRequired'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (active != null) 'active': active!,
        if (placementId != null) 'placementId': placementId!,
        if (placementIdDimensionValue != null)
          'placementIdDimensionValue': placementIdDimensionValue!.toJson(),
        if (sslRequired != null) 'sslRequired': sslRequired!,
      };
}

/// Contains properties of a package or roadblock.
class PlacementGroup {
  /// Account ID of this placement group.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// Advertiser ID of this placement group.
  ///
  /// This is a required field on insertion.
  core.String? advertiserId;

  /// Dimension value for the ID of the advertiser.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? advertiserIdDimensionValue;

  /// Whether this placement group is archived.
  core.bool? archived;

  /// Campaign ID of this placement group.
  ///
  /// This field is required on insertion.
  core.String? campaignId;

  /// Dimension value for the ID of the campaign.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? campaignIdDimensionValue;

  /// IDs of placements which are assigned to this placement group.
  ///
  /// This is a read-only, auto-generated field.
  core.List<core.String>? childPlacementIds;

  /// Comments for this placement group.
  core.String? comment;

  /// ID of the content category assigned to this placement group.
  core.String? contentCategoryId;

  /// Information about the creation of this placement group.
  ///
  /// This is a read-only field.
  LastModifiedInfo? createInfo;

  /// Directory site ID associated with this placement group.
  ///
  /// On insert, you must set either this field or the site_id field to specify
  /// the site associated with this placement group. This is a required field
  /// that is read-only after insertion.
  core.String? directorySiteId;

  /// Dimension value for the ID of the directory site.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? directorySiteIdDimensionValue;

  /// External ID for this placement.
  core.String? externalId;

  /// ID of this placement group.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Dimension value for the ID of this placement group.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? idDimensionValue;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#placementGroup".
  core.String? kind;

  /// Information about the most recent modification of this placement group.
  ///
  /// This is a read-only field.
  LastModifiedInfo? lastModifiedInfo;

  /// Name of this placement group.
  ///
  /// This is a required field and must be less than 256 characters long.
  core.String? name;

  /// Type of this placement group.
  ///
  /// A package is a simple group of placements that acts as a single pricing
  /// point for a group of tags. A roadblock is a group of placements that not
  /// only acts as a single pricing point, but also assumes that all the tags in
  /// it will be served at the same time. A roadblock requires one of its
  /// assigned placements to be marked as primary for reporting. This field is
  /// required on insertion.
  /// Possible string values are:
  /// - "PLACEMENT_PACKAGE"
  /// - "PLACEMENT_ROADBLOCK"
  core.String? placementGroupType;

  /// ID of the placement strategy assigned to this placement group.
  core.String? placementStrategyId;

  /// Pricing schedule of this placement group.
  ///
  /// This field is required on insertion.
  PricingSchedule? pricingSchedule;

  /// ID of the primary placement, used to calculate the media cost of a
  /// roadblock (placement group).
  ///
  /// Modifying this field will automatically modify the primary field on all
  /// affected roadblock child placements.
  core.String? primaryPlacementId;

  /// Dimension value for the ID of the primary placement.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? primaryPlacementIdDimensionValue;

  /// Site ID associated with this placement group.
  ///
  /// On insert, you must set either this field or the directorySiteId field to
  /// specify the site associated with this placement group. This is a required
  /// field that is read-only after insertion.
  core.String? siteId;

  /// Dimension value for the ID of the site.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? siteIdDimensionValue;

  /// Subaccount ID of this placement group.
  ///
  /// This is a read-only field that can be left blank.
  core.String? subaccountId;

  PlacementGroup();

  PlacementGroup.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('archived')) {
      archived = _json['archived'] as core.bool;
    }
    if (_json.containsKey('campaignId')) {
      campaignId = _json['campaignId'] as core.String;
    }
    if (_json.containsKey('campaignIdDimensionValue')) {
      campaignIdDimensionValue = DimensionValue.fromJson(
          _json['campaignIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('childPlacementIds')) {
      childPlacementIds = (_json['childPlacementIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('comment')) {
      comment = _json['comment'] as core.String;
    }
    if (_json.containsKey('contentCategoryId')) {
      contentCategoryId = _json['contentCategoryId'] as core.String;
    }
    if (_json.containsKey('createInfo')) {
      createInfo = LastModifiedInfo.fromJson(
          _json['createInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('directorySiteId')) {
      directorySiteId = _json['directorySiteId'] as core.String;
    }
    if (_json.containsKey('directorySiteIdDimensionValue')) {
      directorySiteIdDimensionValue = DimensionValue.fromJson(
          _json['directorySiteIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('externalId')) {
      externalId = _json['externalId'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifiedInfo')) {
      lastModifiedInfo = LastModifiedInfo.fromJson(
          _json['lastModifiedInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('placementGroupType')) {
      placementGroupType = _json['placementGroupType'] as core.String;
    }
    if (_json.containsKey('placementStrategyId')) {
      placementStrategyId = _json['placementStrategyId'] as core.String;
    }
    if (_json.containsKey('pricingSchedule')) {
      pricingSchedule = PricingSchedule.fromJson(
          _json['pricingSchedule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('primaryPlacementId')) {
      primaryPlacementId = _json['primaryPlacementId'] as core.String;
    }
    if (_json.containsKey('primaryPlacementIdDimensionValue')) {
      primaryPlacementIdDimensionValue = DimensionValue.fromJson(
          _json['primaryPlacementIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('siteId')) {
      siteId = _json['siteId'] as core.String;
    }
    if (_json.containsKey('siteIdDimensionValue')) {
      siteIdDimensionValue = DimensionValue.fromJson(
          _json['siteIdDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (archived != null) 'archived': archived!,
        if (campaignId != null) 'campaignId': campaignId!,
        if (campaignIdDimensionValue != null)
          'campaignIdDimensionValue': campaignIdDimensionValue!.toJson(),
        if (childPlacementIds != null) 'childPlacementIds': childPlacementIds!,
        if (comment != null) 'comment': comment!,
        if (contentCategoryId != null) 'contentCategoryId': contentCategoryId!,
        if (createInfo != null) 'createInfo': createInfo!.toJson(),
        if (directorySiteId != null) 'directorySiteId': directorySiteId!,
        if (directorySiteIdDimensionValue != null)
          'directorySiteIdDimensionValue':
              directorySiteIdDimensionValue!.toJson(),
        if (externalId != null) 'externalId': externalId!,
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (kind != null) 'kind': kind!,
        if (lastModifiedInfo != null)
          'lastModifiedInfo': lastModifiedInfo!.toJson(),
        if (name != null) 'name': name!,
        if (placementGroupType != null)
          'placementGroupType': placementGroupType!,
        if (placementStrategyId != null)
          'placementStrategyId': placementStrategyId!,
        if (pricingSchedule != null)
          'pricingSchedule': pricingSchedule!.toJson(),
        if (primaryPlacementId != null)
          'primaryPlacementId': primaryPlacementId!,
        if (primaryPlacementIdDimensionValue != null)
          'primaryPlacementIdDimensionValue':
              primaryPlacementIdDimensionValue!.toJson(),
        if (siteId != null) 'siteId': siteId!,
        if (siteIdDimensionValue != null)
          'siteIdDimensionValue': siteIdDimensionValue!.toJson(),
        if (subaccountId != null) 'subaccountId': subaccountId!,
      };
}

/// Placement Group List Response
class PlacementGroupsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#placementGroupsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  /// Placement group collection.
  core.List<PlacementGroup>? placementGroups;

  PlacementGroupsListResponse();

  PlacementGroupsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('placementGroups')) {
      placementGroups = (_json['placementGroups'] as core.List)
          .map<PlacementGroup>((value) => PlacementGroup.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (placementGroups != null)
          'placementGroups':
              placementGroups!.map((value) => value.toJson()).toList(),
      };
}

/// Placement Strategy List Response
class PlacementStrategiesListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#placementStrategiesListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  /// Placement strategy collection.
  core.List<PlacementStrategy>? placementStrategies;

  PlacementStrategiesListResponse();

  PlacementStrategiesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('placementStrategies')) {
      placementStrategies = (_json['placementStrategies'] as core.List)
          .map<PlacementStrategy>((value) => PlacementStrategy.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (placementStrategies != null)
          'placementStrategies':
              placementStrategies!.map((value) => value.toJson()).toList(),
      };
}

/// Contains properties of a placement strategy.
class PlacementStrategy {
  /// Account ID of this placement strategy.This is a read-only field that can
  /// be left blank.
  core.String? accountId;

  /// ID of this placement strategy.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#placementStrategy".
  core.String? kind;

  /// Name of this placement strategy.
  ///
  /// This is a required field. It must be less than 256 characters long and
  /// unique among placement strategies of the same account.
  core.String? name;

  PlacementStrategy();

  PlacementStrategy.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// Placement Tag
class PlacementTag {
  /// Placement ID
  core.String? placementId;

  /// Tags generated for this placement.
  core.List<TagData>? tagDatas;

  PlacementTag();

  PlacementTag.fromJson(core.Map _json) {
    if (_json.containsKey('placementId')) {
      placementId = _json['placementId'] as core.String;
    }
    if (_json.containsKey('tagDatas')) {
      tagDatas = (_json['tagDatas'] as core.List)
          .map<TagData>((value) =>
              TagData.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (placementId != null) 'placementId': placementId!,
        if (tagDatas != null)
          'tagDatas': tagDatas!.map((value) => value.toJson()).toList(),
      };
}

/// Placement GenerateTags Response
class PlacementsGenerateTagsResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#placementsGenerateTagsResponse".
  core.String? kind;

  /// Set of generated tags for the specified placements.
  core.List<PlacementTag>? placementTags;

  PlacementsGenerateTagsResponse();

  PlacementsGenerateTagsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('placementTags')) {
      placementTags = (_json['placementTags'] as core.List)
          .map<PlacementTag>((value) => PlacementTag.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (placementTags != null)
          'placementTags':
              placementTags!.map((value) => value.toJson()).toList(),
      };
}

/// Placement List Response
class PlacementsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#placementsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  /// Placement collection.
  core.List<Placement>? placements;

  PlacementsListResponse();

  PlacementsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('placements')) {
      placements = (_json['placements'] as core.List)
          .map<Placement>((value) =>
              Placement.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (placements != null)
          'placements': placements!.map((value) => value.toJson()).toList(),
      };
}

/// Contains information about a platform type that can be targeted by ads.
class PlatformType {
  /// ID of this platform type.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#platformType".
  core.String? kind;

  /// Name of this platform type.
  core.String? name;

  PlatformType();

  PlatformType.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// Platform Type List Response
class PlatformTypesListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#platformTypesListResponse".
  core.String? kind;

  /// Platform type collection.
  core.List<PlatformType>? platformTypes;

  PlatformTypesListResponse();

  PlatformTypesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('platformTypes')) {
      platformTypes = (_json['platformTypes'] as core.List)
          .map<PlatformType>((value) => PlatformType.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (platformTypes != null)
          'platformTypes':
              platformTypes!.map((value) => value.toJson()).toList(),
      };
}

/// Popup Window Properties.
class PopupWindowProperties {
  /// Popup dimension for a creative.
  ///
  /// This is a read-only field. Applicable to the following creative types: all
  /// RICH_MEDIA and all VPAID
  Size? dimension;

  /// Upper-left corner coordinates of the popup window.
  ///
  /// Applicable if positionType is COORDINATES.
  OffsetPosition? offset;

  /// Popup window position either centered or at specific coordinate.
  /// Possible string values are:
  /// - "CENTER"
  /// - "COORDINATES"
  core.String? positionType;

  /// Whether to display the browser address bar.
  core.bool? showAddressBar;

  /// Whether to display the browser menu bar.
  core.bool? showMenuBar;

  /// Whether to display the browser scroll bar.
  core.bool? showScrollBar;

  /// Whether to display the browser status bar.
  core.bool? showStatusBar;

  /// Whether to display the browser tool bar.
  core.bool? showToolBar;

  /// Title of popup window.
  core.String? title;

  PopupWindowProperties();

  PopupWindowProperties.fromJson(core.Map _json) {
    if (_json.containsKey('dimension')) {
      dimension = Size.fromJson(
          _json['dimension'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('offset')) {
      offset = OffsetPosition.fromJson(
          _json['offset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('positionType')) {
      positionType = _json['positionType'] as core.String;
    }
    if (_json.containsKey('showAddressBar')) {
      showAddressBar = _json['showAddressBar'] as core.bool;
    }
    if (_json.containsKey('showMenuBar')) {
      showMenuBar = _json['showMenuBar'] as core.bool;
    }
    if (_json.containsKey('showScrollBar')) {
      showScrollBar = _json['showScrollBar'] as core.bool;
    }
    if (_json.containsKey('showStatusBar')) {
      showStatusBar = _json['showStatusBar'] as core.bool;
    }
    if (_json.containsKey('showToolBar')) {
      showToolBar = _json['showToolBar'] as core.bool;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimension != null) 'dimension': dimension!.toJson(),
        if (offset != null) 'offset': offset!.toJson(),
        if (positionType != null) 'positionType': positionType!,
        if (showAddressBar != null) 'showAddressBar': showAddressBar!,
        if (showMenuBar != null) 'showMenuBar': showMenuBar!,
        if (showScrollBar != null) 'showScrollBar': showScrollBar!,
        if (showStatusBar != null) 'showStatusBar': showStatusBar!,
        if (showToolBar != null) 'showToolBar': showToolBar!,
        if (title != null) 'title': title!,
      };
}

/// Contains information about a postal code that can be targeted by ads.
class PostalCode {
  /// Postal code.
  ///
  /// This is equivalent to the id field.
  core.String? code;

  /// Country code of the country to which this postal code belongs.
  core.String? countryCode;

  /// DART ID of the country to which this postal code belongs.
  core.String? countryDartId;

  /// ID of this postal code.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#postalCode".
  core.String? kind;

  PostalCode();

  PostalCode.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('countryCode')) {
      countryCode = _json['countryCode'] as core.String;
    }
    if (_json.containsKey('countryDartId')) {
      countryDartId = _json['countryDartId'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (countryCode != null) 'countryCode': countryCode!,
        if (countryDartId != null) 'countryDartId': countryDartId!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
      };
}

/// Postal Code List Response
class PostalCodesListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#postalCodesListResponse".
  core.String? kind;

  /// Postal code collection.
  core.List<PostalCode>? postalCodes;

  PostalCodesListResponse();

  PostalCodesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('postalCodes')) {
      postalCodes = (_json['postalCodes'] as core.List)
          .map<PostalCode>((value) =>
              PostalCode.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (postalCodes != null)
          'postalCodes': postalCodes!.map((value) => value.toJson()).toList(),
      };
}

/// Pricing Information
class Pricing {
  /// Cap cost type of this inventory item.
  /// Possible string values are:
  /// - "PLANNING_PLACEMENT_CAP_COST_TYPE_NONE"
  /// - "PLANNING_PLACEMENT_CAP_COST_TYPE_MONTHLY"
  /// - "PLANNING_PLACEMENT_CAP_COST_TYPE_CUMULATIVE"
  core.String? capCostType;
  core.DateTime? endDate;

  /// Flights of this inventory item.
  ///
  /// A flight (a.k.a. pricing period) represents the inventory item pricing
  /// information for a specific period of time.
  core.List<Flight>? flights;

  /// Group type of this inventory item if it represents a placement group.
  ///
  /// Is null otherwise. There are two type of placement groups:
  /// PLANNING_PLACEMENT_GROUP_TYPE_PACKAGE is a simple group of inventory items
  /// that acts as a single pricing point for a group of tags.
  /// PLANNING_PLACEMENT_GROUP_TYPE_ROADBLOCK is a group of inventory items that
  /// not only acts as a single pricing point, but also assumes that all the
  /// tags in it will be served at the same time. A roadblock requires one of
  /// its assigned inventory items to be marked as primary.
  /// Possible string values are:
  /// - "PLANNING_PLACEMENT_GROUP_TYPE_PACKAGE"
  /// - "PLANNING_PLACEMENT_GROUP_TYPE_ROADBLOCK"
  core.String? groupType;

  /// Pricing type of this inventory item.
  /// Possible string values are:
  /// - "PLANNING_PLACEMENT_PRICING_TYPE_IMPRESSIONS"
  /// - "PLANNING_PLACEMENT_PRICING_TYPE_CPM"
  /// - "PLANNING_PLACEMENT_PRICING_TYPE_CLICKS"
  /// - "PLANNING_PLACEMENT_PRICING_TYPE_CPC"
  /// - "PLANNING_PLACEMENT_PRICING_TYPE_CPA"
  /// - "PLANNING_PLACEMENT_PRICING_TYPE_FLAT_RATE_IMPRESSIONS"
  /// - "PLANNING_PLACEMENT_PRICING_TYPE_FLAT_RATE_CLICKS"
  /// - "PLANNING_PLACEMENT_PRICING_TYPE_CPM_ACTIVEVIEW"
  core.String? pricingType;
  core.DateTime? startDate;

  Pricing();

  Pricing.fromJson(core.Map _json) {
    if (_json.containsKey('capCostType')) {
      capCostType = _json['capCostType'] as core.String;
    }
    if (_json.containsKey('endDate')) {
      endDate = core.DateTime.parse(_json['endDate'] as core.String);
    }
    if (_json.containsKey('flights')) {
      flights = (_json['flights'] as core.List)
          .map<Flight>((value) =>
              Flight.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('groupType')) {
      groupType = _json['groupType'] as core.String;
    }
    if (_json.containsKey('pricingType')) {
      pricingType = _json['pricingType'] as core.String;
    }
    if (_json.containsKey('startDate')) {
      startDate = core.DateTime.parse(_json['startDate'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (capCostType != null) 'capCostType': capCostType!,
        if (endDate != null)
          'endDate':
              "${(endDate!).year.toString().padLeft(4, '0')}-${(endDate!).month.toString().padLeft(2, '0')}-${(endDate!).day.toString().padLeft(2, '0')}",
        if (flights != null)
          'flights': flights!.map((value) => value.toJson()).toList(),
        if (groupType != null) 'groupType': groupType!,
        if (pricingType != null) 'pricingType': pricingType!,
        if (startDate != null)
          'startDate':
              "${(startDate!).year.toString().padLeft(4, '0')}-${(startDate!).month.toString().padLeft(2, '0')}-${(startDate!).day.toString().padLeft(2, '0')}",
      };
}

/// Pricing Schedule
class PricingSchedule {
  /// Placement cap cost option.
  /// Possible string values are:
  /// - "CAP_COST_NONE"
  /// - "CAP_COST_MONTHLY"
  /// - "CAP_COST_CUMULATIVE"
  core.String? capCostOption;
  core.DateTime? endDate;

  /// Whether this placement is flighted.
  ///
  /// If true, pricing periods will be computed automatically.
  core.bool? flighted;

  /// Floodlight activity ID associated with this placement.
  ///
  /// This field should be set when placement pricing type is set to
  /// PRICING_TYPE_CPA.
  core.String? floodlightActivityId;

  /// Pricing periods for this placement.
  core.List<PricingSchedulePricingPeriod>? pricingPeriods;

  /// Placement pricing type.
  ///
  /// This field is required on insertion.
  /// Possible string values are:
  /// - "PRICING_TYPE_CPM"
  /// - "PRICING_TYPE_CPC"
  /// - "PRICING_TYPE_CPA"
  /// - "PRICING_TYPE_FLAT_RATE_IMPRESSIONS"
  /// - "PRICING_TYPE_FLAT_RATE_CLICKS"
  /// - "PRICING_TYPE_CPM_ACTIVEVIEW"
  core.String? pricingType;
  core.DateTime? startDate;
  core.DateTime? testingStartDate;

  PricingSchedule();

  PricingSchedule.fromJson(core.Map _json) {
    if (_json.containsKey('capCostOption')) {
      capCostOption = _json['capCostOption'] as core.String;
    }
    if (_json.containsKey('endDate')) {
      endDate = core.DateTime.parse(_json['endDate'] as core.String);
    }
    if (_json.containsKey('flighted')) {
      flighted = _json['flighted'] as core.bool;
    }
    if (_json.containsKey('floodlightActivityId')) {
      floodlightActivityId = _json['floodlightActivityId'] as core.String;
    }
    if (_json.containsKey('pricingPeriods')) {
      pricingPeriods = (_json['pricingPeriods'] as core.List)
          .map<PricingSchedulePricingPeriod>((value) =>
              PricingSchedulePricingPeriod.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('pricingType')) {
      pricingType = _json['pricingType'] as core.String;
    }
    if (_json.containsKey('startDate')) {
      startDate = core.DateTime.parse(_json['startDate'] as core.String);
    }
    if (_json.containsKey('testingStartDate')) {
      testingStartDate =
          core.DateTime.parse(_json['testingStartDate'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (capCostOption != null) 'capCostOption': capCostOption!,
        if (endDate != null)
          'endDate':
              "${(endDate!).year.toString().padLeft(4, '0')}-${(endDate!).month.toString().padLeft(2, '0')}-${(endDate!).day.toString().padLeft(2, '0')}",
        if (flighted != null) 'flighted': flighted!,
        if (floodlightActivityId != null)
          'floodlightActivityId': floodlightActivityId!,
        if (pricingPeriods != null)
          'pricingPeriods':
              pricingPeriods!.map((value) => value.toJson()).toList(),
        if (pricingType != null) 'pricingType': pricingType!,
        if (startDate != null)
          'startDate':
              "${(startDate!).year.toString().padLeft(4, '0')}-${(startDate!).month.toString().padLeft(2, '0')}-${(startDate!).day.toString().padLeft(2, '0')}",
        if (testingStartDate != null)
          'testingStartDate':
              "${(testingStartDate!).year.toString().padLeft(4, '0')}-${(testingStartDate!).month.toString().padLeft(2, '0')}-${(testingStartDate!).day.toString().padLeft(2, '0')}",
      };
}

/// Pricing Period
class PricingSchedulePricingPeriod {
  core.DateTime? endDate;

  /// Comments for this pricing period.
  core.String? pricingComment;

  /// Rate or cost of this pricing period in nanos (i.e., multipled by
  /// 1000000000).
  ///
  /// Acceptable values are 0 to 1000000000000000000, inclusive.
  core.String? rateOrCostNanos;
  core.DateTime? startDate;

  /// Units of this pricing period.
  ///
  /// Acceptable values are 0 to 10000000000, inclusive.
  core.String? units;

  PricingSchedulePricingPeriod();

  PricingSchedulePricingPeriod.fromJson(core.Map _json) {
    if (_json.containsKey('endDate')) {
      endDate = core.DateTime.parse(_json['endDate'] as core.String);
    }
    if (_json.containsKey('pricingComment')) {
      pricingComment = _json['pricingComment'] as core.String;
    }
    if (_json.containsKey('rateOrCostNanos')) {
      rateOrCostNanos = _json['rateOrCostNanos'] as core.String;
    }
    if (_json.containsKey('startDate')) {
      startDate = core.DateTime.parse(_json['startDate'] as core.String);
    }
    if (_json.containsKey('units')) {
      units = _json['units'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endDate != null)
          'endDate':
              "${(endDate!).year.toString().padLeft(4, '0')}-${(endDate!).month.toString().padLeft(2, '0')}-${(endDate!).day.toString().padLeft(2, '0')}",
        if (pricingComment != null) 'pricingComment': pricingComment!,
        if (rateOrCostNanos != null) 'rateOrCostNanos': rateOrCostNanos!,
        if (startDate != null)
          'startDate':
              "${(startDate!).year.toString().padLeft(4, '0')}-${(startDate!).month.toString().padLeft(2, '0')}-${(startDate!).day.toString().padLeft(2, '0')}",
        if (units != null) 'units': units!,
      };
}

/// Contains properties of a Planning project.
class Project {
  /// Account ID of this project.
  core.String? accountId;

  /// Advertiser ID of this project.
  core.String? advertiserId;

  /// Audience age group of this project.
  /// Possible string values are:
  /// - "PLANNING_AUDIENCE_AGE_18_24"
  /// - "PLANNING_AUDIENCE_AGE_25_34"
  /// - "PLANNING_AUDIENCE_AGE_35_44"
  /// - "PLANNING_AUDIENCE_AGE_45_54"
  /// - "PLANNING_AUDIENCE_AGE_55_64"
  /// - "PLANNING_AUDIENCE_AGE_65_OR_MORE"
  /// - "PLANNING_AUDIENCE_AGE_UNKNOWN"
  core.String? audienceAgeGroup;

  /// Audience gender of this project.
  /// Possible string values are:
  /// - "PLANNING_AUDIENCE_GENDER_MALE"
  /// - "PLANNING_AUDIENCE_GENDER_FEMALE"
  core.String? audienceGender;

  /// Budget of this project in the currency specified by the current account.
  ///
  /// The value stored in this field represents only the non-fractional amount.
  /// For example, for USD, the smallest value that can be represented by this
  /// field is 1 US dollar.
  core.String? budget;

  /// Client billing code of this project.
  core.String? clientBillingCode;

  /// Name of the project client.
  core.String? clientName;
  core.DateTime? endDate;

  /// ID of this project.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#project".
  core.String? kind;

  /// Information about the most recent modification of this project.
  LastModifiedInfo? lastModifiedInfo;

  /// Name of this project.
  core.String? name;

  /// Overview of this project.
  core.String? overview;
  core.DateTime? startDate;

  /// Subaccount ID of this project.
  core.String? subaccountId;

  /// Number of clicks that the advertiser is targeting.
  core.String? targetClicks;

  /// Number of conversions that the advertiser is targeting.
  core.String? targetConversions;

  /// CPA that the advertiser is targeting.
  core.String? targetCpaNanos;

  /// CPC that the advertiser is targeting.
  core.String? targetCpcNanos;

  /// vCPM from Active View that the advertiser is targeting.
  core.String? targetCpmActiveViewNanos;

  /// CPM that the advertiser is targeting.
  core.String? targetCpmNanos;

  /// Number of impressions that the advertiser is targeting.
  core.String? targetImpressions;

  Project();

  Project.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('audienceAgeGroup')) {
      audienceAgeGroup = _json['audienceAgeGroup'] as core.String;
    }
    if (_json.containsKey('audienceGender')) {
      audienceGender = _json['audienceGender'] as core.String;
    }
    if (_json.containsKey('budget')) {
      budget = _json['budget'] as core.String;
    }
    if (_json.containsKey('clientBillingCode')) {
      clientBillingCode = _json['clientBillingCode'] as core.String;
    }
    if (_json.containsKey('clientName')) {
      clientName = _json['clientName'] as core.String;
    }
    if (_json.containsKey('endDate')) {
      endDate = core.DateTime.parse(_json['endDate'] as core.String);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifiedInfo')) {
      lastModifiedInfo = LastModifiedInfo.fromJson(
          _json['lastModifiedInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('overview')) {
      overview = _json['overview'] as core.String;
    }
    if (_json.containsKey('startDate')) {
      startDate = core.DateTime.parse(_json['startDate'] as core.String);
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('targetClicks')) {
      targetClicks = _json['targetClicks'] as core.String;
    }
    if (_json.containsKey('targetConversions')) {
      targetConversions = _json['targetConversions'] as core.String;
    }
    if (_json.containsKey('targetCpaNanos')) {
      targetCpaNanos = _json['targetCpaNanos'] as core.String;
    }
    if (_json.containsKey('targetCpcNanos')) {
      targetCpcNanos = _json['targetCpcNanos'] as core.String;
    }
    if (_json.containsKey('targetCpmActiveViewNanos')) {
      targetCpmActiveViewNanos =
          _json['targetCpmActiveViewNanos'] as core.String;
    }
    if (_json.containsKey('targetCpmNanos')) {
      targetCpmNanos = _json['targetCpmNanos'] as core.String;
    }
    if (_json.containsKey('targetImpressions')) {
      targetImpressions = _json['targetImpressions'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (audienceAgeGroup != null) 'audienceAgeGroup': audienceAgeGroup!,
        if (audienceGender != null) 'audienceGender': audienceGender!,
        if (budget != null) 'budget': budget!,
        if (clientBillingCode != null) 'clientBillingCode': clientBillingCode!,
        if (clientName != null) 'clientName': clientName!,
        if (endDate != null)
          'endDate':
              "${(endDate!).year.toString().padLeft(4, '0')}-${(endDate!).month.toString().padLeft(2, '0')}-${(endDate!).day.toString().padLeft(2, '0')}",
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (lastModifiedInfo != null)
          'lastModifiedInfo': lastModifiedInfo!.toJson(),
        if (name != null) 'name': name!,
        if (overview != null) 'overview': overview!,
        if (startDate != null)
          'startDate':
              "${(startDate!).year.toString().padLeft(4, '0')}-${(startDate!).month.toString().padLeft(2, '0')}-${(startDate!).day.toString().padLeft(2, '0')}",
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (targetClicks != null) 'targetClicks': targetClicks!,
        if (targetConversions != null) 'targetConversions': targetConversions!,
        if (targetCpaNanos != null) 'targetCpaNanos': targetCpaNanos!,
        if (targetCpcNanos != null) 'targetCpcNanos': targetCpcNanos!,
        if (targetCpmActiveViewNanos != null)
          'targetCpmActiveViewNanos': targetCpmActiveViewNanos!,
        if (targetCpmNanos != null) 'targetCpmNanos': targetCpmNanos!,
        if (targetImpressions != null) 'targetImpressions': targetImpressions!,
      };
}

/// Project List Response
class ProjectsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#projectsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  /// Project collection.
  core.List<Project>? projects;

  ProjectsListResponse();

  ProjectsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('projects')) {
      projects = (_json['projects'] as core.List)
          .map<Project>((value) =>
              Project.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (projects != null)
          'projects': projects!.map((value) => value.toJson()).toList(),
      };
}

/// Represents fields that are compatible to be selected for a report of type
/// "REACH".
class ReachReportCompatibleFields {
  /// Dimensions which are compatible to be selected in the "dimensionFilters"
  /// section of the report.
  core.List<Dimension>? dimensionFilters;

  /// Dimensions which are compatible to be selected in the "dimensions" section
  /// of the report.
  core.List<Dimension>? dimensions;

  /// The kind of resource this is, in this case
  /// dfareporting#reachReportCompatibleFields.
  core.String? kind;

  /// Metrics which are compatible to be selected in the "metricNames" section
  /// of the report.
  core.List<Metric>? metrics;

  /// Metrics which are compatible to be selected as activity metrics to pivot
  /// on in the "activities" section of the report.
  core.List<Metric>? pivotedActivityMetrics;

  /// Metrics which are compatible to be selected in the
  /// "reachByFrequencyMetricNames" section of the report.
  core.List<Metric>? reachByFrequencyMetrics;

  ReachReportCompatibleFields();

  ReachReportCompatibleFields.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionFilters')) {
      dimensionFilters = (_json['dimensionFilters'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dimensions')) {
      dimensions = (_json['dimensions'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.List)
          .map<Metric>((value) =>
              Metric.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('pivotedActivityMetrics')) {
      pivotedActivityMetrics = (_json['pivotedActivityMetrics'] as core.List)
          .map<Metric>((value) =>
              Metric.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('reachByFrequencyMetrics')) {
      reachByFrequencyMetrics = (_json['reachByFrequencyMetrics'] as core.List)
          .map<Metric>((value) =>
              Metric.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionFilters != null)
          'dimensionFilters':
              dimensionFilters!.map((value) => value.toJson()).toList(),
        if (dimensions != null)
          'dimensions': dimensions!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (metrics != null)
          'metrics': metrics!.map((value) => value.toJson()).toList(),
        if (pivotedActivityMetrics != null)
          'pivotedActivityMetrics':
              pivotedActivityMetrics!.map((value) => value.toJson()).toList(),
        if (reachByFrequencyMetrics != null)
          'reachByFrequencyMetrics':
              reachByFrequencyMetrics!.map((value) => value.toJson()).toList(),
      };
}

/// Represents a recipient.
class Recipient {
  /// The delivery type for the recipient.
  /// Possible string values are:
  /// - "LINK"
  /// - "ATTACHMENT"
  core.String? deliveryType;

  /// The email address of the recipient.
  core.String? email;

  /// The kind of resource this is, in this case dfareporting#recipient.
  core.String? kind;

  Recipient();

  Recipient.fromJson(core.Map _json) {
    if (_json.containsKey('deliveryType')) {
      deliveryType = _json['deliveryType'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deliveryType != null) 'deliveryType': deliveryType!,
        if (email != null) 'email': email!,
        if (kind != null) 'kind': kind!,
      };
}

/// Contains information about a region that can be targeted by ads.
class Region {
  /// Country code of the country to which this region belongs.
  core.String? countryCode;

  /// DART ID of the country to which this region belongs.
  core.String? countryDartId;

  /// DART ID of this region.
  core.String? dartId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#region".
  core.String? kind;

  /// Name of this region.
  core.String? name;

  /// Region code.
  core.String? regionCode;

  Region();

  Region.fromJson(core.Map _json) {
    if (_json.containsKey('countryCode')) {
      countryCode = _json['countryCode'] as core.String;
    }
    if (_json.containsKey('countryDartId')) {
      countryDartId = _json['countryDartId'] as core.String;
    }
    if (_json.containsKey('dartId')) {
      dartId = _json['dartId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('regionCode')) {
      regionCode = _json['regionCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (countryCode != null) 'countryCode': countryCode!,
        if (countryDartId != null) 'countryDartId': countryDartId!,
        if (dartId != null) 'dartId': dartId!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (regionCode != null) 'regionCode': regionCode!,
      };
}

/// Region List Response
class RegionsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#regionsListResponse".
  core.String? kind;

  /// Region collection.
  core.List<Region>? regions;

  RegionsListResponse();

  RegionsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('regions')) {
      regions = (_json['regions'] as core.List)
          .map<Region>((value) =>
              Region.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (regions != null)
          'regions': regions!.map((value) => value.toJson()).toList(),
      };
}

/// Contains properties of a remarketing list.
///
/// Remarketing enables you to create lists of users who have performed specific
/// actions on a site, then target ads to members of those lists. This resource
/// can be used to manage remarketing lists that are owned by your advertisers.
/// To see all remarketing lists that are visible to your advertisers, including
/// those that are shared to your advertiser or account, use the
/// TargetableRemarketingLists resource.
class RemarketingList {
  /// Account ID of this remarketing list.
  ///
  /// This is a read-only, auto-generated field that is only returned in GET
  /// requests.
  core.String? accountId;

  /// Whether this remarketing list is active.
  core.bool? active;

  /// Dimension value for the advertiser ID that owns this remarketing list.
  ///
  /// This is a required field.
  core.String? advertiserId;

  /// Dimension value for the ID of the advertiser.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? advertiserIdDimensionValue;

  /// Remarketing list description.
  core.String? description;

  /// Remarketing list ID.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#remarketingList".
  core.String? kind;

  /// Number of days that a user should remain in the remarketing list without
  /// an impression.
  ///
  /// Acceptable values are 1 to 540, inclusive.
  core.String? lifeSpan;

  /// Rule used to populate the remarketing list with users.
  ListPopulationRule? listPopulationRule;

  /// Number of users currently in the list.
  ///
  /// This is a read-only field.
  core.String? listSize;

  /// Product from which this remarketing list was originated.
  /// Possible string values are:
  /// - "REMARKETING_LIST_SOURCE_OTHER"
  /// - "REMARKETING_LIST_SOURCE_ADX"
  /// - "REMARKETING_LIST_SOURCE_DFP"
  /// - "REMARKETING_LIST_SOURCE_XFP"
  /// - "REMARKETING_LIST_SOURCE_DFA"
  /// - "REMARKETING_LIST_SOURCE_GA"
  /// - "REMARKETING_LIST_SOURCE_YOUTUBE"
  /// - "REMARKETING_LIST_SOURCE_DBM"
  /// - "REMARKETING_LIST_SOURCE_GPLUS"
  /// - "REMARKETING_LIST_SOURCE_DMP"
  /// - "REMARKETING_LIST_SOURCE_PLAY_STORE"
  core.String? listSource;

  /// Name of the remarketing list.
  ///
  /// This is a required field. Must be no greater than 128 characters long.
  core.String? name;

  /// Subaccount ID of this remarketing list.
  ///
  /// This is a read-only, auto-generated field that is only returned in GET
  /// requests.
  core.String? subaccountId;

  RemarketingList();

  RemarketingList.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('active')) {
      active = _json['active'] as core.bool;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lifeSpan')) {
      lifeSpan = _json['lifeSpan'] as core.String;
    }
    if (_json.containsKey('listPopulationRule')) {
      listPopulationRule = ListPopulationRule.fromJson(
          _json['listPopulationRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('listSize')) {
      listSize = _json['listSize'] as core.String;
    }
    if (_json.containsKey('listSource')) {
      listSource = _json['listSource'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (active != null) 'active': active!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (description != null) 'description': description!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (lifeSpan != null) 'lifeSpan': lifeSpan!,
        if (listPopulationRule != null)
          'listPopulationRule': listPopulationRule!.toJson(),
        if (listSize != null) 'listSize': listSize!,
        if (listSource != null) 'listSource': listSource!,
        if (name != null) 'name': name!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
      };
}

/// Contains properties of a remarketing list's sharing information.
///
/// Sharing allows other accounts or advertisers to target to your remarketing
/// lists. This resource can be used to manage remarketing list sharing to other
/// accounts and advertisers.
class RemarketingListShare {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#remarketingListShare".
  core.String? kind;

  /// Remarketing list ID.
  ///
  /// This is a read-only, auto-generated field.
  core.String? remarketingListId;

  /// Accounts that the remarketing list is shared with.
  core.List<core.String>? sharedAccountIds;

  /// Advertisers that the remarketing list is shared with.
  core.List<core.String>? sharedAdvertiserIds;

  RemarketingListShare();

  RemarketingListShare.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('remarketingListId')) {
      remarketingListId = _json['remarketingListId'] as core.String;
    }
    if (_json.containsKey('sharedAccountIds')) {
      sharedAccountIds = (_json['sharedAccountIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('sharedAdvertiserIds')) {
      sharedAdvertiserIds = (_json['sharedAdvertiserIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (remarketingListId != null) 'remarketingListId': remarketingListId!,
        if (sharedAccountIds != null) 'sharedAccountIds': sharedAccountIds!,
        if (sharedAdvertiserIds != null)
          'sharedAdvertiserIds': sharedAdvertiserIds!,
      };
}

/// Remarketing list response
class RemarketingListsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#remarketingListsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  /// Remarketing list collection.
  core.List<RemarketingList>? remarketingLists;

  RemarketingListsListResponse();

  RemarketingListsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('remarketingLists')) {
      remarketingLists = (_json['remarketingLists'] as core.List)
          .map<RemarketingList>((value) => RemarketingList.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (remarketingLists != null)
          'remarketingLists':
              remarketingLists!.map((value) => value.toJson()).toList(),
      };
}

/// The report criteria for a report of type "STANDARD".
class ReportCriteria {
  /// Activity group.
  Activities? activities;

  /// Custom Rich Media Events group.
  CustomRichMediaEvents? customRichMediaEvents;

  /// The date range for which this report should be run.
  DateRange? dateRange;

  /// The list of filters on which dimensions are filtered.
  ///
  /// Filters for different dimensions are ANDed, filters for the same dimension
  /// are grouped together and ORed.
  core.List<DimensionValue>? dimensionFilters;

  /// The list of standard dimensions the report should include.
  core.List<SortedDimension>? dimensions;

  /// The list of names of metrics the report should include.
  core.List<core.String>? metricNames;

  ReportCriteria();

  ReportCriteria.fromJson(core.Map _json) {
    if (_json.containsKey('activities')) {
      activities = Activities.fromJson(
          _json['activities'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('customRichMediaEvents')) {
      customRichMediaEvents = CustomRichMediaEvents.fromJson(
          _json['customRichMediaEvents']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dateRange')) {
      dateRange = DateRange.fromJson(
          _json['dateRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dimensionFilters')) {
      dimensionFilters = (_json['dimensionFilters'] as core.List)
          .map<DimensionValue>((value) => DimensionValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dimensions')) {
      dimensions = (_json['dimensions'] as core.List)
          .map<SortedDimension>((value) => SortedDimension.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('metricNames')) {
      metricNames = (_json['metricNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activities != null) 'activities': activities!.toJson(),
        if (customRichMediaEvents != null)
          'customRichMediaEvents': customRichMediaEvents!.toJson(),
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
        if (dimensionFilters != null)
          'dimensionFilters':
              dimensionFilters!.map((value) => value.toJson()).toList(),
        if (dimensions != null)
          'dimensions': dimensions!.map((value) => value.toJson()).toList(),
        if (metricNames != null) 'metricNames': metricNames!,
      };
}

/// The report criteria for a report of type "CROSS_DIMENSION_REACH".
class ReportCrossDimensionReachCriteria {
  /// The list of dimensions the report should include.
  core.List<SortedDimension>? breakdown;

  /// The date range this report should be run for.
  DateRange? dateRange;

  /// The dimension option.
  /// Possible string values are:
  /// - "ADVERTISER"
  /// - "CAMPAIGN"
  /// - "SITE_BY_ADVERTISER"
  /// - "SITE_BY_CAMPAIGN"
  core.String? dimension;

  /// The list of filters on which dimensions are filtered.
  core.List<DimensionValue>? dimensionFilters;

  /// The list of names of metrics the report should include.
  core.List<core.String>? metricNames;

  /// The list of names of overlap metrics the report should include.
  core.List<core.String>? overlapMetricNames;

  /// Whether the report is pivoted or not.
  ///
  /// Defaults to true.
  core.bool? pivoted;

  ReportCrossDimensionReachCriteria();

  ReportCrossDimensionReachCriteria.fromJson(core.Map _json) {
    if (_json.containsKey('breakdown')) {
      breakdown = (_json['breakdown'] as core.List)
          .map<SortedDimension>((value) => SortedDimension.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dateRange')) {
      dateRange = DateRange.fromJson(
          _json['dateRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dimension')) {
      dimension = _json['dimension'] as core.String;
    }
    if (_json.containsKey('dimensionFilters')) {
      dimensionFilters = (_json['dimensionFilters'] as core.List)
          .map<DimensionValue>((value) => DimensionValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('metricNames')) {
      metricNames = (_json['metricNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('overlapMetricNames')) {
      overlapMetricNames = (_json['overlapMetricNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('pivoted')) {
      pivoted = _json['pivoted'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (breakdown != null)
          'breakdown': breakdown!.map((value) => value.toJson()).toList(),
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
        if (dimension != null) 'dimension': dimension!,
        if (dimensionFilters != null)
          'dimensionFilters':
              dimensionFilters!.map((value) => value.toJson()).toList(),
        if (metricNames != null) 'metricNames': metricNames!,
        if (overlapMetricNames != null)
          'overlapMetricNames': overlapMetricNames!,
        if (pivoted != null) 'pivoted': pivoted!,
      };
}

/// The report's email delivery settings.
class ReportDelivery {
  /// Whether the report should be emailed to the report owner.
  core.bool? emailOwner;

  /// The type of delivery for the owner to receive, if enabled.
  /// Possible string values are:
  /// - "LINK"
  /// - "ATTACHMENT"
  core.String? emailOwnerDeliveryType;

  /// The message to be sent with each email.
  core.String? message;

  /// The list of recipients to which to email the report.
  core.List<Recipient>? recipients;

  ReportDelivery();

  ReportDelivery.fromJson(core.Map _json) {
    if (_json.containsKey('emailOwner')) {
      emailOwner = _json['emailOwner'] as core.bool;
    }
    if (_json.containsKey('emailOwnerDeliveryType')) {
      emailOwnerDeliveryType = _json['emailOwnerDeliveryType'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('recipients')) {
      recipients = (_json['recipients'] as core.List)
          .map<Recipient>((value) =>
              Recipient.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (emailOwner != null) 'emailOwner': emailOwner!,
        if (emailOwnerDeliveryType != null)
          'emailOwnerDeliveryType': emailOwnerDeliveryType!,
        if (message != null) 'message': message!,
        if (recipients != null)
          'recipients': recipients!.map((value) => value.toJson()).toList(),
      };
}

/// The properties of the report.
class ReportFloodlightCriteriaReportProperties {
  /// Include conversions that have no cookie, but do have an exposure path.
  core.bool? includeAttributedIPConversions;

  /// Include conversions of users with a DoubleClick cookie but without an
  /// exposure.
  ///
  /// That means the user did not click or see an ad from the advertiser within
  /// the Floodlight group, or that the interaction happened outside the
  /// lookback window.
  core.bool? includeUnattributedCookieConversions;

  /// Include conversions that have no associated cookies and no exposures.
  ///
  /// It’s therefore impossible to know how the user was exposed to your ads
  /// during the lookback window prior to a conversion.
  core.bool? includeUnattributedIPConversions;

  ReportFloodlightCriteriaReportProperties();

  ReportFloodlightCriteriaReportProperties.fromJson(core.Map _json) {
    if (_json.containsKey('includeAttributedIPConversions')) {
      includeAttributedIPConversions =
          _json['includeAttributedIPConversions'] as core.bool;
    }
    if (_json.containsKey('includeUnattributedCookieConversions')) {
      includeUnattributedCookieConversions =
          _json['includeUnattributedCookieConversions'] as core.bool;
    }
    if (_json.containsKey('includeUnattributedIPConversions')) {
      includeUnattributedIPConversions =
          _json['includeUnattributedIPConversions'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (includeAttributedIPConversions != null)
          'includeAttributedIPConversions': includeAttributedIPConversions!,
        if (includeUnattributedCookieConversions != null)
          'includeUnattributedCookieConversions':
              includeUnattributedCookieConversions!,
        if (includeUnattributedIPConversions != null)
          'includeUnattributedIPConversions': includeUnattributedIPConversions!,
      };
}

/// The report criteria for a report of type "FLOODLIGHT".
class ReportFloodlightCriteria {
  /// The list of custom rich media events to include.
  core.List<DimensionValue>? customRichMediaEvents;

  /// The date range this report should be run for.
  DateRange? dateRange;

  /// The list of filters on which dimensions are filtered.
  ///
  /// Filters for different dimensions are ANDed, filters for the same dimension
  /// are grouped together and ORed.
  core.List<DimensionValue>? dimensionFilters;

  /// The list of dimensions the report should include.
  core.List<SortedDimension>? dimensions;

  /// The floodlight ID for which to show data in this report.
  ///
  /// All advertisers associated with that ID will automatically be added. The
  /// dimension of the value needs to be 'dfa:floodlightConfigId'.
  DimensionValue? floodlightConfigId;

  /// The list of names of metrics the report should include.
  core.List<core.String>? metricNames;

  /// The properties of the report.
  ReportFloodlightCriteriaReportProperties? reportProperties;

  ReportFloodlightCriteria();

  ReportFloodlightCriteria.fromJson(core.Map _json) {
    if (_json.containsKey('customRichMediaEvents')) {
      customRichMediaEvents = (_json['customRichMediaEvents'] as core.List)
          .map<DimensionValue>((value) => DimensionValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dateRange')) {
      dateRange = DateRange.fromJson(
          _json['dateRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dimensionFilters')) {
      dimensionFilters = (_json['dimensionFilters'] as core.List)
          .map<DimensionValue>((value) => DimensionValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dimensions')) {
      dimensions = (_json['dimensions'] as core.List)
          .map<SortedDimension>((value) => SortedDimension.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('floodlightConfigId')) {
      floodlightConfigId = DimensionValue.fromJson(
          _json['floodlightConfigId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metricNames')) {
      metricNames = (_json['metricNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('reportProperties')) {
      reportProperties = ReportFloodlightCriteriaReportProperties.fromJson(
          _json['reportProperties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customRichMediaEvents != null)
          'customRichMediaEvents':
              customRichMediaEvents!.map((value) => value.toJson()).toList(),
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
        if (dimensionFilters != null)
          'dimensionFilters':
              dimensionFilters!.map((value) => value.toJson()).toList(),
        if (dimensions != null)
          'dimensions': dimensions!.map((value) => value.toJson()).toList(),
        if (floodlightConfigId != null)
          'floodlightConfigId': floodlightConfigId!.toJson(),
        if (metricNames != null) 'metricNames': metricNames!,
        if (reportProperties != null)
          'reportProperties': reportProperties!.toJson(),
      };
}

/// The report criteria for a report of type "PATH_ATTRIBUTION".
class ReportPathAttributionCriteria {
  /// The list of 'dfa:activity' values to filter on.
  core.List<DimensionValue>? activityFilters;

  /// Channel Grouping.
  ChannelGrouping? customChannelGrouping;

  /// The date range this report should be run for.
  DateRange? dateRange;

  /// The list of dimensions the report should include.
  core.List<SortedDimension>? dimensions;

  /// The floodlight ID for which to show data in this report.
  ///
  /// All advertisers associated with that ID will automatically be added. The
  /// dimension of the value needs to be 'dfa:floodlightConfigId'.
  DimensionValue? floodlightConfigId;

  /// The list of names of metrics the report should include.
  core.List<core.String>? metricNames;

  /// Path Filters.
  core.List<PathFilter>? pathFilters;

  ReportPathAttributionCriteria();

  ReportPathAttributionCriteria.fromJson(core.Map _json) {
    if (_json.containsKey('activityFilters')) {
      activityFilters = (_json['activityFilters'] as core.List)
          .map<DimensionValue>((value) => DimensionValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('customChannelGrouping')) {
      customChannelGrouping = ChannelGrouping.fromJson(
          _json['customChannelGrouping']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dateRange')) {
      dateRange = DateRange.fromJson(
          _json['dateRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dimensions')) {
      dimensions = (_json['dimensions'] as core.List)
          .map<SortedDimension>((value) => SortedDimension.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('floodlightConfigId')) {
      floodlightConfigId = DimensionValue.fromJson(
          _json['floodlightConfigId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metricNames')) {
      metricNames = (_json['metricNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('pathFilters')) {
      pathFilters = (_json['pathFilters'] as core.List)
          .map<PathFilter>((value) =>
              PathFilter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activityFilters != null)
          'activityFilters':
              activityFilters!.map((value) => value.toJson()).toList(),
        if (customChannelGrouping != null)
          'customChannelGrouping': customChannelGrouping!.toJson(),
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
        if (dimensions != null)
          'dimensions': dimensions!.map((value) => value.toJson()).toList(),
        if (floodlightConfigId != null)
          'floodlightConfigId': floodlightConfigId!.toJson(),
        if (metricNames != null) 'metricNames': metricNames!,
        if (pathFilters != null)
          'pathFilters': pathFilters!.map((value) => value.toJson()).toList(),
      };
}

/// The report criteria for a report of type "PATH".
class ReportPathCriteria {
  /// The list of 'dfa:activity' values to filter on.
  core.List<DimensionValue>? activityFilters;

  /// Channel Grouping.
  ChannelGrouping? customChannelGrouping;

  /// The date range this report should be run for.
  DateRange? dateRange;

  /// The list of dimensions the report should include.
  core.List<SortedDimension>? dimensions;

  /// The floodlight ID for which to show data in this report.
  ///
  /// All advertisers associated with that ID will automatically be added. The
  /// dimension of the value needs to be 'dfa:floodlightConfigId'.
  DimensionValue? floodlightConfigId;

  /// The list of names of metrics the report should include.
  core.List<core.String>? metricNames;

  /// Path Filters.
  core.List<PathFilter>? pathFilters;

  ReportPathCriteria();

  ReportPathCriteria.fromJson(core.Map _json) {
    if (_json.containsKey('activityFilters')) {
      activityFilters = (_json['activityFilters'] as core.List)
          .map<DimensionValue>((value) => DimensionValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('customChannelGrouping')) {
      customChannelGrouping = ChannelGrouping.fromJson(
          _json['customChannelGrouping']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dateRange')) {
      dateRange = DateRange.fromJson(
          _json['dateRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dimensions')) {
      dimensions = (_json['dimensions'] as core.List)
          .map<SortedDimension>((value) => SortedDimension.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('floodlightConfigId')) {
      floodlightConfigId = DimensionValue.fromJson(
          _json['floodlightConfigId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metricNames')) {
      metricNames = (_json['metricNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('pathFilters')) {
      pathFilters = (_json['pathFilters'] as core.List)
          .map<PathFilter>((value) =>
              PathFilter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activityFilters != null)
          'activityFilters':
              activityFilters!.map((value) => value.toJson()).toList(),
        if (customChannelGrouping != null)
          'customChannelGrouping': customChannelGrouping!.toJson(),
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
        if (dimensions != null)
          'dimensions': dimensions!.map((value) => value.toJson()).toList(),
        if (floodlightConfigId != null)
          'floodlightConfigId': floodlightConfigId!.toJson(),
        if (metricNames != null) 'metricNames': metricNames!,
        if (pathFilters != null)
          'pathFilters': pathFilters!.map((value) => value.toJson()).toList(),
      };
}

/// The properties of the report.
class ReportPathToConversionCriteriaReportProperties {
  /// CM360 checks to see if a click interaction occurred within the specified
  /// period of time before a conversion.
  ///
  /// By default the value is pulled from Floodlight or you can manually enter a
  /// custom value. Valid values: 1-90.
  core.int? clicksLookbackWindow;

  /// CM360 checks to see if an impression interaction occurred within the
  /// specified period of time before a conversion.
  ///
  /// By default the value is pulled from Floodlight or you can manually enter a
  /// custom value. Valid values: 1-90.
  core.int? impressionsLookbackWindow;

  /// Deprecated: has no effect.
  core.bool? includeAttributedIPConversions;

  /// Include conversions of users with a DoubleClick cookie but without an
  /// exposure.
  ///
  /// That means the user did not click or see an ad from the advertiser within
  /// the Floodlight group, or that the interaction happened outside the
  /// lookback window.
  core.bool? includeUnattributedCookieConversions;

  /// Include conversions that have no associated cookies and no exposures.
  ///
  /// It’s therefore impossible to know how the user was exposed to your ads
  /// during the lookback window prior to a conversion.
  core.bool? includeUnattributedIPConversions;

  /// The maximum number of click interactions to include in the report.
  ///
  /// Advertisers currently paying for E2C reports get up to 200 (100 clicks,
  /// 100 impressions). If another advertiser in your network is paying for E2C,
  /// you can have up to 5 total exposures per report.
  core.int? maximumClickInteractions;

  /// The maximum number of click interactions to include in the report.
  ///
  /// Advertisers currently paying for E2C reports get up to 200 (100 clicks,
  /// 100 impressions). If another advertiser in your network is paying for E2C,
  /// you can have up to 5 total exposures per report.
  core.int? maximumImpressionInteractions;

  /// The maximum amount of time that can take place between interactions
  /// (clicks or impressions) by the same user.
  ///
  /// Valid values: 1-90.
  core.int? maximumInteractionGap;

  /// Enable pivoting on interaction path.
  core.bool? pivotOnInteractionPath;

  ReportPathToConversionCriteriaReportProperties();

  ReportPathToConversionCriteriaReportProperties.fromJson(core.Map _json) {
    if (_json.containsKey('clicksLookbackWindow')) {
      clicksLookbackWindow = _json['clicksLookbackWindow'] as core.int;
    }
    if (_json.containsKey('impressionsLookbackWindow')) {
      impressionsLookbackWindow =
          _json['impressionsLookbackWindow'] as core.int;
    }
    if (_json.containsKey('includeAttributedIPConversions')) {
      includeAttributedIPConversions =
          _json['includeAttributedIPConversions'] as core.bool;
    }
    if (_json.containsKey('includeUnattributedCookieConversions')) {
      includeUnattributedCookieConversions =
          _json['includeUnattributedCookieConversions'] as core.bool;
    }
    if (_json.containsKey('includeUnattributedIPConversions')) {
      includeUnattributedIPConversions =
          _json['includeUnattributedIPConversions'] as core.bool;
    }
    if (_json.containsKey('maximumClickInteractions')) {
      maximumClickInteractions = _json['maximumClickInteractions'] as core.int;
    }
    if (_json.containsKey('maximumImpressionInteractions')) {
      maximumImpressionInteractions =
          _json['maximumImpressionInteractions'] as core.int;
    }
    if (_json.containsKey('maximumInteractionGap')) {
      maximumInteractionGap = _json['maximumInteractionGap'] as core.int;
    }
    if (_json.containsKey('pivotOnInteractionPath')) {
      pivotOnInteractionPath = _json['pivotOnInteractionPath'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clicksLookbackWindow != null)
          'clicksLookbackWindow': clicksLookbackWindow!,
        if (impressionsLookbackWindow != null)
          'impressionsLookbackWindow': impressionsLookbackWindow!,
        if (includeAttributedIPConversions != null)
          'includeAttributedIPConversions': includeAttributedIPConversions!,
        if (includeUnattributedCookieConversions != null)
          'includeUnattributedCookieConversions':
              includeUnattributedCookieConversions!,
        if (includeUnattributedIPConversions != null)
          'includeUnattributedIPConversions': includeUnattributedIPConversions!,
        if (maximumClickInteractions != null)
          'maximumClickInteractions': maximumClickInteractions!,
        if (maximumImpressionInteractions != null)
          'maximumImpressionInteractions': maximumImpressionInteractions!,
        if (maximumInteractionGap != null)
          'maximumInteractionGap': maximumInteractionGap!,
        if (pivotOnInteractionPath != null)
          'pivotOnInteractionPath': pivotOnInteractionPath!,
      };
}

/// The report criteria for a report of type "PATH_TO_CONVERSION".
class ReportPathToConversionCriteria {
  /// The list of 'dfa:activity' values to filter on.
  core.List<DimensionValue>? activityFilters;

  /// The list of conversion dimensions the report should include.
  core.List<SortedDimension>? conversionDimensions;

  /// The list of custom floodlight variables the report should include.
  core.List<SortedDimension>? customFloodlightVariables;

  /// The list of custom rich media events to include.
  core.List<DimensionValue>? customRichMediaEvents;

  /// The date range this report should be run for.
  DateRange? dateRange;

  /// The floodlight ID for which to show data in this report.
  ///
  /// All advertisers associated with that ID will automatically be added. The
  /// dimension of the value needs to be 'dfa:floodlightConfigId'.
  DimensionValue? floodlightConfigId;

  /// The list of names of metrics the report should include.
  core.List<core.String>? metricNames;

  /// The list of per interaction dimensions the report should include.
  core.List<SortedDimension>? perInteractionDimensions;

  /// The properties of the report.
  ReportPathToConversionCriteriaReportProperties? reportProperties;

  ReportPathToConversionCriteria();

  ReportPathToConversionCriteria.fromJson(core.Map _json) {
    if (_json.containsKey('activityFilters')) {
      activityFilters = (_json['activityFilters'] as core.List)
          .map<DimensionValue>((value) => DimensionValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('conversionDimensions')) {
      conversionDimensions = (_json['conversionDimensions'] as core.List)
          .map<SortedDimension>((value) => SortedDimension.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('customFloodlightVariables')) {
      customFloodlightVariables =
          (_json['customFloodlightVariables'] as core.List)
              .map<SortedDimension>((value) => SortedDimension.fromJson(
                  value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('customRichMediaEvents')) {
      customRichMediaEvents = (_json['customRichMediaEvents'] as core.List)
          .map<DimensionValue>((value) => DimensionValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dateRange')) {
      dateRange = DateRange.fromJson(
          _json['dateRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('floodlightConfigId')) {
      floodlightConfigId = DimensionValue.fromJson(
          _json['floodlightConfigId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metricNames')) {
      metricNames = (_json['metricNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('perInteractionDimensions')) {
      perInteractionDimensions =
          (_json['perInteractionDimensions'] as core.List)
              .map<SortedDimension>((value) => SortedDimension.fromJson(
                  value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('reportProperties')) {
      reportProperties =
          ReportPathToConversionCriteriaReportProperties.fromJson(
              _json['reportProperties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activityFilters != null)
          'activityFilters':
              activityFilters!.map((value) => value.toJson()).toList(),
        if (conversionDimensions != null)
          'conversionDimensions':
              conversionDimensions!.map((value) => value.toJson()).toList(),
        if (customFloodlightVariables != null)
          'customFloodlightVariables': customFloodlightVariables!
              .map((value) => value.toJson())
              .toList(),
        if (customRichMediaEvents != null)
          'customRichMediaEvents':
              customRichMediaEvents!.map((value) => value.toJson()).toList(),
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
        if (floodlightConfigId != null)
          'floodlightConfigId': floodlightConfigId!.toJson(),
        if (metricNames != null) 'metricNames': metricNames!,
        if (perInteractionDimensions != null)
          'perInteractionDimensions':
              perInteractionDimensions!.map((value) => value.toJson()).toList(),
        if (reportProperties != null)
          'reportProperties': reportProperties!.toJson(),
      };
}

/// The report criteria for a report of type "REACH".
class ReportReachCriteria {
  /// Activity group.
  Activities? activities;

  /// Custom Rich Media Events group.
  CustomRichMediaEvents? customRichMediaEvents;

  /// The date range this report should be run for.
  DateRange? dateRange;

  /// The list of filters on which dimensions are filtered.
  ///
  /// Filters for different dimensions are ANDed, filters for the same dimension
  /// are grouped together and ORed.
  core.List<DimensionValue>? dimensionFilters;

  /// The list of dimensions the report should include.
  core.List<SortedDimension>? dimensions;

  /// Whether to enable all reach dimension combinations in the report.
  ///
  /// Defaults to false. If enabled, the date range of the report should be
  /// within the last 42 days.
  core.bool? enableAllDimensionCombinations;

  /// The list of names of metrics the report should include.
  core.List<core.String>? metricNames;

  /// The list of names of Reach By Frequency metrics the report should include.
  core.List<core.String>? reachByFrequencyMetricNames;

  ReportReachCriteria();

  ReportReachCriteria.fromJson(core.Map _json) {
    if (_json.containsKey('activities')) {
      activities = Activities.fromJson(
          _json['activities'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('customRichMediaEvents')) {
      customRichMediaEvents = CustomRichMediaEvents.fromJson(
          _json['customRichMediaEvents']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dateRange')) {
      dateRange = DateRange.fromJson(
          _json['dateRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dimensionFilters')) {
      dimensionFilters = (_json['dimensionFilters'] as core.List)
          .map<DimensionValue>((value) => DimensionValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dimensions')) {
      dimensions = (_json['dimensions'] as core.List)
          .map<SortedDimension>((value) => SortedDimension.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('enableAllDimensionCombinations')) {
      enableAllDimensionCombinations =
          _json['enableAllDimensionCombinations'] as core.bool;
    }
    if (_json.containsKey('metricNames')) {
      metricNames = (_json['metricNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('reachByFrequencyMetricNames')) {
      reachByFrequencyMetricNames =
          (_json['reachByFrequencyMetricNames'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activities != null) 'activities': activities!.toJson(),
        if (customRichMediaEvents != null)
          'customRichMediaEvents': customRichMediaEvents!.toJson(),
        if (dateRange != null) 'dateRange': dateRange!.toJson(),
        if (dimensionFilters != null)
          'dimensionFilters':
              dimensionFilters!.map((value) => value.toJson()).toList(),
        if (dimensions != null)
          'dimensions': dimensions!.map((value) => value.toJson()).toList(),
        if (enableAllDimensionCombinations != null)
          'enableAllDimensionCombinations': enableAllDimensionCombinations!,
        if (metricNames != null) 'metricNames': metricNames!,
        if (reachByFrequencyMetricNames != null)
          'reachByFrequencyMetricNames': reachByFrequencyMetricNames!,
      };
}

/// The report's schedule.
///
/// Can only be set if the report's 'dateRange' is a relative date range and the
/// relative date range is not "TODAY".
class ReportSchedule {
  /// Whether the schedule is active or not.
  ///
  /// Must be set to either true or false.
  core.bool? active;

  /// Defines every how many days, weeks or months the report should be run.
  ///
  /// Needs to be set when "repeats" is either "DAILY", "WEEKLY" or "MONTHLY".
  core.int? every;
  core.DateTime? expirationDate;

  /// The interval for which the report is repeated.
  ///
  /// Note: - "DAILY" also requires field "every" to be set. - "WEEKLY" also
  /// requires fields "every" and "repeatsOnWeekDays" to be set. - "MONTHLY"
  /// also requires fields "every" and "runsOnDayOfMonth" to be set.
  core.String? repeats;

  /// List of week days "WEEKLY" on which scheduled reports should run.
  core.List<core.String>? repeatsOnWeekDays;

  /// Enum to define for "MONTHLY" scheduled reports whether reports should be
  /// repeated on the same day of the month as "startDate" or the same day of
  /// the week of the month.
  ///
  /// Example: If 'startDate' is Monday, April 2nd 2012 (2012-04-02),
  /// "DAY_OF_MONTH" would run subsequent reports on the 2nd of every Month, and
  /// "WEEK_OF_MONTH" would run subsequent reports on the first Monday of the
  /// month.
  /// Possible string values are:
  /// - "DAY_OF_MONTH"
  /// - "WEEK_OF_MONTH"
  core.String? runsOnDayOfMonth;
  core.DateTime? startDate;

  ReportSchedule();

  ReportSchedule.fromJson(core.Map _json) {
    if (_json.containsKey('active')) {
      active = _json['active'] as core.bool;
    }
    if (_json.containsKey('every')) {
      every = _json['every'] as core.int;
    }
    if (_json.containsKey('expirationDate')) {
      expirationDate =
          core.DateTime.parse(_json['expirationDate'] as core.String);
    }
    if (_json.containsKey('repeats')) {
      repeats = _json['repeats'] as core.String;
    }
    if (_json.containsKey('repeatsOnWeekDays')) {
      repeatsOnWeekDays = (_json['repeatsOnWeekDays'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('runsOnDayOfMonth')) {
      runsOnDayOfMonth = _json['runsOnDayOfMonth'] as core.String;
    }
    if (_json.containsKey('startDate')) {
      startDate = core.DateTime.parse(_json['startDate'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (active != null) 'active': active!,
        if (every != null) 'every': every!,
        if (expirationDate != null)
          'expirationDate':
              "${(expirationDate!).year.toString().padLeft(4, '0')}-${(expirationDate!).month.toString().padLeft(2, '0')}-${(expirationDate!).day.toString().padLeft(2, '0')}",
        if (repeats != null) 'repeats': repeats!,
        if (repeatsOnWeekDays != null) 'repeatsOnWeekDays': repeatsOnWeekDays!,
        if (runsOnDayOfMonth != null) 'runsOnDayOfMonth': runsOnDayOfMonth!,
        if (startDate != null)
          'startDate':
              "${(startDate!).year.toString().padLeft(4, '0')}-${(startDate!).month.toString().padLeft(2, '0')}-${(startDate!).day.toString().padLeft(2, '0')}",
      };
}

/// Represents a Report resource.
class Report {
  /// The account ID to which this report belongs.
  core.String? accountId;

  /// The report criteria for a report of type "STANDARD".
  ReportCriteria? criteria;

  /// The report criteria for a report of type "CROSS_DIMENSION_REACH".
  ReportCrossDimensionReachCriteria? crossDimensionReachCriteria;

  /// The report's email delivery settings.
  ReportDelivery? delivery;

  /// The eTag of this response for caching purposes.
  core.String? etag;

  /// The filename used when generating report files for this report.
  core.String? fileName;

  /// The report criteria for a report of type "FLOODLIGHT".
  ReportFloodlightCriteria? floodlightCriteria;

  /// The output format of the report.
  ///
  /// If not specified, default format is "CSV". Note that the actual format in
  /// the completed report file might differ if for instance the report's size
  /// exceeds the format's capabilities. "CSV" will then be the fallback format.
  /// Possible string values are:
  /// - "CSV"
  /// - "EXCEL"
  core.String? format;

  /// The unique ID identifying this report resource.
  core.String? id;

  /// The kind of resource this is, in this case dfareporting#report.
  core.String? kind;

  /// The timestamp (in milliseconds since epoch) of when this report was last
  /// modified.
  core.String? lastModifiedTime;

  /// The name of the report.
  core.String? name;

  /// The user profile id of the owner of this report.
  core.String? ownerProfileId;

  /// The report criteria for a report of type "PATH_ATTRIBUTION".
  ReportPathAttributionCriteria? pathAttributionCriteria;

  /// The report criteria for a report of type "PATH".
  ReportPathCriteria? pathCriteria;

  /// The report criteria for a report of type "PATH_TO_CONVERSION".
  ReportPathToConversionCriteria? pathToConversionCriteria;

  /// The report criteria for a report of type "REACH".
  ReportReachCriteria? reachCriteria;

  /// The report's schedule.
  ///
  /// Can only be set if the report's 'dateRange' is a relative date range and
  /// the relative date range is not "TODAY".
  ReportSchedule? schedule;

  /// The subaccount ID to which this report belongs if applicable.
  core.String? subAccountId;

  /// The type of the report.
  /// Possible string values are:
  /// - "STANDARD"
  /// - "REACH"
  /// - "PATH_TO_CONVERSION"
  /// - "CROSS_DIMENSION_REACH"
  /// - "FLOODLIGHT"
  /// - "PATH"
  /// - "PATH_ATTRIBUTION"
  core.String? type;

  Report();

  Report.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('criteria')) {
      criteria = ReportCriteria.fromJson(
          _json['criteria'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('crossDimensionReachCriteria')) {
      crossDimensionReachCriteria = ReportCrossDimensionReachCriteria.fromJson(
          _json['crossDimensionReachCriteria']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('delivery')) {
      delivery = ReportDelivery.fromJson(
          _json['delivery'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('fileName')) {
      fileName = _json['fileName'] as core.String;
    }
    if (_json.containsKey('floodlightCriteria')) {
      floodlightCriteria = ReportFloodlightCriteria.fromJson(
          _json['floodlightCriteria'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('format')) {
      format = _json['format'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifiedTime')) {
      lastModifiedTime = _json['lastModifiedTime'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('ownerProfileId')) {
      ownerProfileId = _json['ownerProfileId'] as core.String;
    }
    if (_json.containsKey('pathAttributionCriteria')) {
      pathAttributionCriteria = ReportPathAttributionCriteria.fromJson(
          _json['pathAttributionCriteria']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pathCriteria')) {
      pathCriteria = ReportPathCriteria.fromJson(
          _json['pathCriteria'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pathToConversionCriteria')) {
      pathToConversionCriteria = ReportPathToConversionCriteria.fromJson(
          _json['pathToConversionCriteria']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reachCriteria')) {
      reachCriteria = ReportReachCriteria.fromJson(
          _json['reachCriteria'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('schedule')) {
      schedule = ReportSchedule.fromJson(
          _json['schedule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subAccountId')) {
      subAccountId = _json['subAccountId'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (criteria != null) 'criteria': criteria!.toJson(),
        if (crossDimensionReachCriteria != null)
          'crossDimensionReachCriteria': crossDimensionReachCriteria!.toJson(),
        if (delivery != null) 'delivery': delivery!.toJson(),
        if (etag != null) 'etag': etag!,
        if (fileName != null) 'fileName': fileName!,
        if (floodlightCriteria != null)
          'floodlightCriteria': floodlightCriteria!.toJson(),
        if (format != null) 'format': format!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (lastModifiedTime != null) 'lastModifiedTime': lastModifiedTime!,
        if (name != null) 'name': name!,
        if (ownerProfileId != null) 'ownerProfileId': ownerProfileId!,
        if (pathAttributionCriteria != null)
          'pathAttributionCriteria': pathAttributionCriteria!.toJson(),
        if (pathCriteria != null) 'pathCriteria': pathCriteria!.toJson(),
        if (pathToConversionCriteria != null)
          'pathToConversionCriteria': pathToConversionCriteria!.toJson(),
        if (reachCriteria != null) 'reachCriteria': reachCriteria!.toJson(),
        if (schedule != null) 'schedule': schedule!.toJson(),
        if (subAccountId != null) 'subAccountId': subAccountId!,
        if (type != null) 'type': type!,
      };
}

/// Represents fields that are compatible to be selected for a report of type
/// "STANDARD".
class ReportCompatibleFields {
  /// Dimensions which are compatible to be selected in the "dimensionFilters"
  /// section of the report.
  core.List<Dimension>? dimensionFilters;

  /// Dimensions which are compatible to be selected in the "dimensions" section
  /// of the report.
  core.List<Dimension>? dimensions;

  /// The kind of resource this is, in this case
  /// dfareporting#reportCompatibleFields.
  core.String? kind;

  /// Metrics which are compatible to be selected in the "metricNames" section
  /// of the report.
  core.List<Metric>? metrics;

  /// Metrics which are compatible to be selected as activity metrics to pivot
  /// on in the "activities" section of the report.
  core.List<Metric>? pivotedActivityMetrics;

  ReportCompatibleFields();

  ReportCompatibleFields.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionFilters')) {
      dimensionFilters = (_json['dimensionFilters'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dimensions')) {
      dimensions = (_json['dimensions'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.List)
          .map<Metric>((value) =>
              Metric.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('pivotedActivityMetrics')) {
      pivotedActivityMetrics = (_json['pivotedActivityMetrics'] as core.List)
          .map<Metric>((value) =>
              Metric.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionFilters != null)
          'dimensionFilters':
              dimensionFilters!.map((value) => value.toJson()).toList(),
        if (dimensions != null)
          'dimensions': dimensions!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (metrics != null)
          'metrics': metrics!.map((value) => value.toJson()).toList(),
        if (pivotedActivityMetrics != null)
          'pivotedActivityMetrics':
              pivotedActivityMetrics!.map((value) => value.toJson()).toList(),
      };
}

/// Represents the list of reports.
class ReportList {
  /// The eTag of this response for caching purposes.
  core.String? etag;

  /// The reports returned in this response.
  core.List<Report>? items;

  /// The kind of list this is, in this case dfareporting#reportList.
  core.String? kind;

  /// Continuation token used to page through reports.
  ///
  /// To retrieve the next page of results, set the next request's "pageToken"
  /// to the value of this field. The page token is only valid for a limited
  /// amount of time and should not be persisted.
  core.String? nextPageToken;

  ReportList();

  ReportList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Report>((value) =>
              Report.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Reporting Configuration
class ReportsConfiguration {
  /// Whether the exposure to conversion report is enabled.
  ///
  /// This report shows detailed pathway information on up to 10 of the most
  /// recent ad exposures seen by a user before converting.
  core.bool? exposureToConversionEnabled;

  /// Default lookback windows for new advertisers in this account.
  LookbackConfiguration? lookbackConfiguration;

  /// Report generation time zone ID of this account.
  ///
  /// This is a required field that can only be changed by a superuser.
  /// Acceptable values are: - "1" for "America/New_York" - "2" for
  /// "Europe/London" - "3" for "Europe/Paris" - "4" for "Africa/Johannesburg" -
  /// "5" for "Asia/Jerusalem" - "6" for "Asia/Shanghai" - "7" for
  /// "Asia/Hong_Kong" - "8" for "Asia/Tokyo" - "9" for "Australia/Sydney" -
  /// "10" for "Asia/Dubai" - "11" for "America/Los_Angeles" - "12" for
  /// "Pacific/Auckland" - "13" for "America/Sao_Paulo" - "16" for
  /// "America/Asuncion" - "17" for "America/Chicago" - "18" for
  /// "America/Denver" - "19" for "America/St_Johns" - "20" for "Asia/Dhaka" -
  /// "21" for "Asia/Jakarta" - "22" for "Asia/Kabul" - "23" for "Asia/Karachi"
  /// - "24" for "Asia/Calcutta" - "25" for "Asia/Pyongyang" - "26" for
  /// "Asia/Rangoon" - "27" for "Atlantic/Cape_Verde" - "28" for
  /// "Atlantic/South_Georgia" - "29" for "Australia/Adelaide" - "30" for
  /// "Australia/Lord_Howe" - "31" for "Europe/Moscow" - "32" for
  /// "Pacific/Kiritimati" - "35" for "Pacific/Norfolk" - "36" for
  /// "Pacific/Tongatapu"
  core.String? reportGenerationTimeZoneId;

  ReportsConfiguration();

  ReportsConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('exposureToConversionEnabled')) {
      exposureToConversionEnabled =
          _json['exposureToConversionEnabled'] as core.bool;
    }
    if (_json.containsKey('lookbackConfiguration')) {
      lookbackConfiguration = LookbackConfiguration.fromJson(
          _json['lookbackConfiguration']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reportGenerationTimeZoneId')) {
      reportGenerationTimeZoneId =
          _json['reportGenerationTimeZoneId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exposureToConversionEnabled != null)
          'exposureToConversionEnabled': exposureToConversionEnabled!,
        if (lookbackConfiguration != null)
          'lookbackConfiguration': lookbackConfiguration!.toJson(),
        if (reportGenerationTimeZoneId != null)
          'reportGenerationTimeZoneId': reportGenerationTimeZoneId!,
      };
}

/// Rich Media Exit Override.
class RichMediaExitOverride {
  /// Click-through URL of this rich media exit override.
  ///
  /// Applicable if the enabled field is set to true.
  ClickThroughUrl? clickThroughUrl;

  /// Whether to use the clickThroughUrl.
  ///
  /// If false, the creative-level exit will be used.
  core.bool? enabled;

  /// ID for the override to refer to a specific exit in the creative.
  core.String? exitId;

  RichMediaExitOverride();

  RichMediaExitOverride.fromJson(core.Map _json) {
    if (_json.containsKey('clickThroughUrl')) {
      clickThroughUrl = ClickThroughUrl.fromJson(
          _json['clickThroughUrl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
    if (_json.containsKey('exitId')) {
      exitId = _json['exitId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clickThroughUrl != null)
          'clickThroughUrl': clickThroughUrl!.toJson(),
        if (enabled != null) 'enabled': enabled!,
        if (exitId != null) 'exitId': exitId!,
      };
}

/// A rule associates an asset with a targeting template for asset-level
/// targeting.
///
/// Applicable to INSTREAM_VIDEO creatives.
class Rule {
  /// A creativeAssets\[\].id.
  ///
  /// This should refer to one of the parent assets in this creative. This is a
  /// required field.
  core.String? assetId;

  /// A user-friendly name for this rule.
  ///
  /// This is a required field.
  core.String? name;

  /// A targeting template ID.
  ///
  /// The targeting from the targeting template will be used to determine
  /// whether this asset should be served. This is a required field.
  core.String? targetingTemplateId;

  Rule();

  Rule.fromJson(core.Map _json) {
    if (_json.containsKey('assetId')) {
      assetId = _json['assetId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('targetingTemplateId')) {
      targetingTemplateId = _json['targetingTemplateId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assetId != null) 'assetId': assetId!,
        if (name != null) 'name': name!,
        if (targetingTemplateId != null)
          'targetingTemplateId': targetingTemplateId!,
      };
}

/// Contains properties of a site.
class Site {
  /// Account ID of this site.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// Whether this site is approved.
  core.bool? approved;

  /// Directory site associated with this site.
  ///
  /// This is a required field that is read-only after insertion.
  core.String? directorySiteId;

  /// Dimension value for the ID of the directory site.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? directorySiteIdDimensionValue;

  /// ID of this site.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Dimension value for the ID of this site.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? idDimensionValue;

  /// Key name of this site.
  ///
  /// This is a read-only, auto-generated field.
  core.String? keyName;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#site".
  core.String? kind;

  /// Name of this site.This is a required field.
  ///
  /// Must be less than 128 characters long. If this site is under a subaccount,
  /// the name must be unique among sites of the same subaccount. Otherwise,
  /// this site is a top-level site, and the name must be unique among top-level
  /// sites of the same account.
  core.String? name;

  /// Site contacts.
  core.List<SiteContact>? siteContacts;

  /// Site-wide settings.
  SiteSettings? siteSettings;

  /// Subaccount ID of this site.
  ///
  /// This is a read-only field that can be left blank.
  core.String? subaccountId;

  /// Default video settings for new placements created under this site.
  ///
  /// This value will be used to populate the placements.videoSettings field,
  /// when no value is specified for the new placement.
  SiteVideoSettings? videoSettings;

  Site();

  Site.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('approved')) {
      approved = _json['approved'] as core.bool;
    }
    if (_json.containsKey('directorySiteId')) {
      directorySiteId = _json['directorySiteId'] as core.String;
    }
    if (_json.containsKey('directorySiteIdDimensionValue')) {
      directorySiteIdDimensionValue = DimensionValue.fromJson(
          _json['directorySiteIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('idDimensionValue')) {
      idDimensionValue = DimensionValue.fromJson(
          _json['idDimensionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('keyName')) {
      keyName = _json['keyName'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('siteContacts')) {
      siteContacts = (_json['siteContacts'] as core.List)
          .map<SiteContact>((value) => SiteContact.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('siteSettings')) {
      siteSettings = SiteSettings.fromJson(
          _json['siteSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('videoSettings')) {
      videoSettings = SiteVideoSettings.fromJson(
          _json['videoSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (approved != null) 'approved': approved!,
        if (directorySiteId != null) 'directorySiteId': directorySiteId!,
        if (directorySiteIdDimensionValue != null)
          'directorySiteIdDimensionValue':
              directorySiteIdDimensionValue!.toJson(),
        if (id != null) 'id': id!,
        if (idDimensionValue != null)
          'idDimensionValue': idDimensionValue!.toJson(),
        if (keyName != null) 'keyName': keyName!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (siteContacts != null)
          'siteContacts': siteContacts!.map((value) => value.toJson()).toList(),
        if (siteSettings != null) 'siteSettings': siteSettings!.toJson(),
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (videoSettings != null) 'videoSettings': videoSettings!.toJson(),
      };
}

/// Companion Settings
class SiteCompanionSetting {
  /// Whether companions are disabled for this site template.
  core.bool? companionsDisabled;

  /// Allowlist of companion sizes to be served via this site template.
  ///
  /// Set this list to null or empty to serve all companion sizes.
  core.List<Size>? enabledSizes;

  /// Whether to serve only static images as companions.
  core.bool? imageOnly;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#siteCompanionSetting".
  core.String? kind;

  SiteCompanionSetting();

  SiteCompanionSetting.fromJson(core.Map _json) {
    if (_json.containsKey('companionsDisabled')) {
      companionsDisabled = _json['companionsDisabled'] as core.bool;
    }
    if (_json.containsKey('enabledSizes')) {
      enabledSizes = (_json['enabledSizes'] as core.List)
          .map<Size>((value) =>
              Size.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('imageOnly')) {
      imageOnly = _json['imageOnly'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (companionsDisabled != null)
          'companionsDisabled': companionsDisabled!,
        if (enabledSizes != null)
          'enabledSizes': enabledSizes!.map((value) => value.toJson()).toList(),
        if (imageOnly != null) 'imageOnly': imageOnly!,
        if (kind != null) 'kind': kind!,
      };
}

/// Site Contact
class SiteContact {
  /// Address of this site contact.
  core.String? address;

  /// Site contact type.
  /// Possible string values are:
  /// - "SALES_PERSON"
  /// - "TRAFFICKER"
  core.String? contactType;

  /// Email address of this site contact.
  ///
  /// This is a required field.
  core.String? email;

  /// First name of this site contact.
  core.String? firstName;

  /// ID of this site contact.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Last name of this site contact.
  core.String? lastName;

  /// Primary phone number of this site contact.
  core.String? phone;

  /// Title or designation of this site contact.
  core.String? title;

  SiteContact();

  SiteContact.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = _json['address'] as core.String;
    }
    if (_json.containsKey('contactType')) {
      contactType = _json['contactType'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('firstName')) {
      firstName = _json['firstName'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('lastName')) {
      lastName = _json['lastName'] as core.String;
    }
    if (_json.containsKey('phone')) {
      phone = _json['phone'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!,
        if (contactType != null) 'contactType': contactType!,
        if (email != null) 'email': email!,
        if (firstName != null) 'firstName': firstName!,
        if (id != null) 'id': id!,
        if (lastName != null) 'lastName': lastName!,
        if (phone != null) 'phone': phone!,
        if (title != null) 'title': title!,
      };
}

/// Site Settings
class SiteSettings {
  /// Whether active view creatives are disabled for this site.
  core.bool? activeViewOptOut;

  /// Whether this site opts out of ad blocking.
  ///
  /// When true, ad blocking is disabled for all placements under the site,
  /// regardless of the individual placement settings. When false, the campaign
  /// and placement settings take effect.
  core.bool? adBlockingOptOut;

  /// Whether new cookies are disabled for this site.
  core.bool? disableNewCookie;

  /// Configuration settings for dynamic and image floodlight tags.
  TagSetting? tagSetting;

  /// Whether Verification and ActiveView for in-stream video creatives are
  /// disabled by default for new placements created under this site.
  ///
  /// This value will be used to populate the placement.videoActiveViewOptOut
  /// field, when no value is specified for the new placement.
  core.bool? videoActiveViewOptOutTemplate;

  /// Default VPAID adapter setting for new placements created under this site.
  ///
  /// This value will be used to populate the placements.vpaidAdapterChoice
  /// field, when no value is specified for the new placement. Controls which
  /// VPAID format the measurement adapter will use for in-stream video
  /// creatives assigned to the placement. The publisher's specifications will
  /// typically determine this setting. For VPAID creatives, the adapter format
  /// will match the VPAID format (HTML5 VPAID creatives use the HTML5 adapter).
  /// *Note:* Flash is no longer supported. This field now defaults to HTML5
  /// when the following values are provided: FLASH, BOTH.
  /// Possible string values are:
  /// - "DEFAULT"
  /// - "FLASH"
  /// - "HTML5"
  /// - "BOTH"
  core.String? vpaidAdapterChoiceTemplate;

  SiteSettings();

  SiteSettings.fromJson(core.Map _json) {
    if (_json.containsKey('activeViewOptOut')) {
      activeViewOptOut = _json['activeViewOptOut'] as core.bool;
    }
    if (_json.containsKey('adBlockingOptOut')) {
      adBlockingOptOut = _json['adBlockingOptOut'] as core.bool;
    }
    if (_json.containsKey('disableNewCookie')) {
      disableNewCookie = _json['disableNewCookie'] as core.bool;
    }
    if (_json.containsKey('tagSetting')) {
      tagSetting = TagSetting.fromJson(
          _json['tagSetting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('videoActiveViewOptOutTemplate')) {
      videoActiveViewOptOutTemplate =
          _json['videoActiveViewOptOutTemplate'] as core.bool;
    }
    if (_json.containsKey('vpaidAdapterChoiceTemplate')) {
      vpaidAdapterChoiceTemplate =
          _json['vpaidAdapterChoiceTemplate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activeViewOptOut != null) 'activeViewOptOut': activeViewOptOut!,
        if (adBlockingOptOut != null) 'adBlockingOptOut': adBlockingOptOut!,
        if (disableNewCookie != null) 'disableNewCookie': disableNewCookie!,
        if (tagSetting != null) 'tagSetting': tagSetting!.toJson(),
        if (videoActiveViewOptOutTemplate != null)
          'videoActiveViewOptOutTemplate': videoActiveViewOptOutTemplate!,
        if (vpaidAdapterChoiceTemplate != null)
          'vpaidAdapterChoiceTemplate': vpaidAdapterChoiceTemplate!,
      };
}

/// Skippable Settings
class SiteSkippableSetting {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#siteSkippableSetting".
  core.String? kind;

  /// Amount of time to play videos served to this site template before counting
  /// a view.
  ///
  /// Applicable when skippable is true.
  VideoOffset? progressOffset;

  /// Amount of time to play videos served to this site before the skip button
  /// should appear.
  ///
  /// Applicable when skippable is true.
  VideoOffset? skipOffset;

  /// Whether the user can skip creatives served to this site.
  ///
  /// This will act as default for new placements created under this site.
  core.bool? skippable;

  SiteSkippableSetting();

  SiteSkippableSetting.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('progressOffset')) {
      progressOffset = VideoOffset.fromJson(
          _json['progressOffset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('skipOffset')) {
      skipOffset = VideoOffset.fromJson(
          _json['skipOffset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('skippable')) {
      skippable = _json['skippable'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (progressOffset != null) 'progressOffset': progressOffset!.toJson(),
        if (skipOffset != null) 'skipOffset': skipOffset!.toJson(),
        if (skippable != null) 'skippable': skippable!,
      };
}

/// Transcode Settings
class SiteTranscodeSetting {
  /// Allowlist of video formats to be served to this site template.
  ///
  /// Set this list to null or empty to serve all video formats.
  core.List<core.int>? enabledVideoFormats;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#siteTranscodeSetting".
  core.String? kind;

  SiteTranscodeSetting();

  SiteTranscodeSetting.fromJson(core.Map _json) {
    if (_json.containsKey('enabledVideoFormats')) {
      enabledVideoFormats = (_json['enabledVideoFormats'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabledVideoFormats != null)
          'enabledVideoFormats': enabledVideoFormats!,
        if (kind != null) 'kind': kind!,
      };
}

/// Video Settings
class SiteVideoSettings {
  /// Settings for the companion creatives of video creatives served to this
  /// site.
  SiteCompanionSetting? companionSettings;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#siteVideoSettings".
  core.String? kind;

  /// Whether OBA icons are enabled for this placement.
  core.bool? obaEnabled;

  /// Settings for the OBA icon of video creatives served to this site.
  ///
  /// This will act as default for new placements created under this site.
  ObaIcon? obaSettings;

  /// Orientation of a site template used for video.
  ///
  /// This will act as default for new placements created under this site.
  /// Possible string values are:
  /// - "ANY"
  /// - "LANDSCAPE"
  /// - "PORTRAIT"
  core.String? orientation;

  /// Settings for the skippability of video creatives served to this site.
  ///
  /// This will act as default for new placements created under this site.
  SiteSkippableSetting? skippableSettings;

  /// Settings for the transcodes of video creatives served to this site.
  ///
  /// This will act as default for new placements created under this site.
  SiteTranscodeSetting? transcodeSettings;

  SiteVideoSettings();

  SiteVideoSettings.fromJson(core.Map _json) {
    if (_json.containsKey('companionSettings')) {
      companionSettings = SiteCompanionSetting.fromJson(
          _json['companionSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('obaEnabled')) {
      obaEnabled = _json['obaEnabled'] as core.bool;
    }
    if (_json.containsKey('obaSettings')) {
      obaSettings = ObaIcon.fromJson(
          _json['obaSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('orientation')) {
      orientation = _json['orientation'] as core.String;
    }
    if (_json.containsKey('skippableSettings')) {
      skippableSettings = SiteSkippableSetting.fromJson(
          _json['skippableSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transcodeSettings')) {
      transcodeSettings = SiteTranscodeSetting.fromJson(
          _json['transcodeSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (companionSettings != null)
          'companionSettings': companionSettings!.toJson(),
        if (kind != null) 'kind': kind!,
        if (obaEnabled != null) 'obaEnabled': obaEnabled!,
        if (obaSettings != null) 'obaSettings': obaSettings!.toJson(),
        if (orientation != null) 'orientation': orientation!,
        if (skippableSettings != null)
          'skippableSettings': skippableSettings!.toJson(),
        if (transcodeSettings != null)
          'transcodeSettings': transcodeSettings!.toJson(),
      };
}

/// Site List Response
class SitesListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#sitesListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  /// Site collection.
  core.List<Site>? sites;

  SitesListResponse();

  SitesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
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
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (sites != null)
          'sites': sites!.map((value) => value.toJson()).toList(),
      };
}

/// Represents the dimensions of ads, placements, creatives, or creative assets.
class Size {
  /// Height of this size.
  ///
  /// Acceptable values are 0 to 32767, inclusive.
  core.int? height;

  /// IAB standard size.
  ///
  /// This is a read-only, auto-generated field.
  core.bool? iab;

  /// ID of this size.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#size".
  core.String? kind;

  /// Width of this size.
  ///
  /// Acceptable values are 0 to 32767, inclusive.
  core.int? width;

  Size();

  Size.fromJson(core.Map _json) {
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('iab')) {
      iab = _json['iab'] as core.bool;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (height != null) 'height': height!,
        if (iab != null) 'iab': iab!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (width != null) 'width': width!,
      };
}

/// Size List Response
class SizesListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#sizesListResponse".
  core.String? kind;

  /// Size collection.
  core.List<Size>? sizes;

  SizesListResponse();

  SizesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('sizes')) {
      sizes = (_json['sizes'] as core.List)
          .map<Size>((value) =>
              Size.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (sizes != null)
          'sizes': sizes!.map((value) => value.toJson()).toList(),
      };
}

/// Skippable Settings
class SkippableSetting {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#skippableSetting".
  core.String? kind;

  /// Amount of time to play videos served to this placement before counting a
  /// view.
  ///
  /// Applicable when skippable is true.
  VideoOffset? progressOffset;

  /// Amount of time to play videos served to this placement before the skip
  /// button should appear.
  ///
  /// Applicable when skippable is true.
  VideoOffset? skipOffset;

  /// Whether the user can skip creatives served to this placement.
  core.bool? skippable;

  SkippableSetting();

  SkippableSetting.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('progressOffset')) {
      progressOffset = VideoOffset.fromJson(
          _json['progressOffset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('skipOffset')) {
      skipOffset = VideoOffset.fromJson(
          _json['skipOffset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('skippable')) {
      skippable = _json['skippable'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (progressOffset != null) 'progressOffset': progressOffset!.toJson(),
        if (skipOffset != null) 'skipOffset': skipOffset!.toJson(),
        if (skippable != null) 'skippable': skippable!,
      };
}

/// Represents a sorted dimension.
class SortedDimension {
  /// The kind of resource this is, in this case dfareporting#sortedDimension.
  core.String? kind;

  /// The name of the dimension.
  core.String? name;

  /// An optional sort order for the dimension column.
  /// Possible string values are:
  /// - "ASCENDING"
  /// - "DESCENDING"
  core.String? sortOrder;

  SortedDimension();

  SortedDimension.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('sortOrder')) {
      sortOrder = _json['sortOrder'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (sortOrder != null) 'sortOrder': sortOrder!,
      };
}

/// Contains properties of a Campaign Manager subaccount.
class Subaccount {
  /// ID of the account that contains this subaccount.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// IDs of the available user role permissions for this subaccount.
  core.List<core.String>? availablePermissionIds;

  /// ID of this subaccount.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#subaccount".
  core.String? kind;

  /// Name of this subaccount.
  ///
  /// This is a required field. Must be less than 128 characters long and be
  /// unique among subaccounts of the same account.
  core.String? name;

  Subaccount();

  Subaccount.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('availablePermissionIds')) {
      availablePermissionIds = (_json['availablePermissionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (availablePermissionIds != null)
          'availablePermissionIds': availablePermissionIds!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// Subaccount List Response
class SubaccountsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#subaccountsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  /// Subaccount collection.
  core.List<Subaccount>? subaccounts;

  SubaccountsListResponse();

  SubaccountsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('subaccounts')) {
      subaccounts = (_json['subaccounts'] as core.List)
          .map<Subaccount>((value) =>
              Subaccount.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (subaccounts != null)
          'subaccounts': subaccounts!.map((value) => value.toJson()).toList(),
      };
}

/// Placement Tag Data
class TagData {
  /// Ad associated with this placement tag.
  ///
  /// Applicable only when format is PLACEMENT_TAG_TRACKING.
  core.String? adId;

  /// Tag string to record a click.
  core.String? clickTag;

  /// Creative associated with this placement tag.
  ///
  /// Applicable only when format is PLACEMENT_TAG_TRACKING.
  core.String? creativeId;

  /// TagData tag format of this tag.
  /// Possible string values are:
  /// - "PLACEMENT_TAG_STANDARD"
  /// - "PLACEMENT_TAG_IFRAME_JAVASCRIPT"
  /// - "PLACEMENT_TAG_IFRAME_ILAYER"
  /// - "PLACEMENT_TAG_INTERNAL_REDIRECT"
  /// - "PLACEMENT_TAG_JAVASCRIPT"
  /// - "PLACEMENT_TAG_INTERSTITIAL_IFRAME_JAVASCRIPT"
  /// - "PLACEMENT_TAG_INTERSTITIAL_INTERNAL_REDIRECT"
  /// - "PLACEMENT_TAG_INTERSTITIAL_JAVASCRIPT"
  /// - "PLACEMENT_TAG_CLICK_COMMANDS"
  /// - "PLACEMENT_TAG_INSTREAM_VIDEO_PREFETCH"
  /// - "PLACEMENT_TAG_TRACKING"
  /// - "PLACEMENT_TAG_TRACKING_IFRAME"
  /// - "PLACEMENT_TAG_TRACKING_JAVASCRIPT"
  /// - "PLACEMENT_TAG_INSTREAM_VIDEO_PREFETCH_VAST_3"
  /// - "PLACEMENT_TAG_IFRAME_JAVASCRIPT_LEGACY"
  /// - "PLACEMENT_TAG_JAVASCRIPT_LEGACY"
  /// - "PLACEMENT_TAG_INTERSTITIAL_IFRAME_JAVASCRIPT_LEGACY"
  /// - "PLACEMENT_TAG_INTERSTITIAL_JAVASCRIPT_LEGACY"
  /// - "PLACEMENT_TAG_INSTREAM_VIDEO_PREFETCH_VAST_4"
  core.String? format;

  /// Tag string for serving an ad.
  core.String? impressionTag;

  TagData();

  TagData.fromJson(core.Map _json) {
    if (_json.containsKey('adId')) {
      adId = _json['adId'] as core.String;
    }
    if (_json.containsKey('clickTag')) {
      clickTag = _json['clickTag'] as core.String;
    }
    if (_json.containsKey('creativeId')) {
      creativeId = _json['creativeId'] as core.String;
    }
    if (_json.containsKey('format')) {
      format = _json['format'] as core.String;
    }
    if (_json.containsKey('impressionTag')) {
      impressionTag = _json['impressionTag'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adId != null) 'adId': adId!,
        if (clickTag != null) 'clickTag': clickTag!,
        if (creativeId != null) 'creativeId': creativeId!,
        if (format != null) 'format': format!,
        if (impressionTag != null) 'impressionTag': impressionTag!,
      };
}

/// Tag Settings
class TagSetting {
  /// Additional key-values to be included in tags.
  ///
  /// Each key-value pair must be of the form key=value, and pairs must be
  /// separated by a semicolon (;). Keys and values must not contain commas. For
  /// example, id=2;color=red is a valid value for this field.
  core.String? additionalKeyValues;

  /// Whether static landing page URLs should be included in the tags.
  ///
  /// This setting applies only to placements.
  core.bool? includeClickThroughUrls;

  /// Whether click-tracking string should be included in the tags.
  core.bool? includeClickTracking;

  /// Option specifying how keywords are embedded in ad tags.
  ///
  /// This setting can be used to specify whether keyword placeholders are
  /// inserted in placement tags for this site. Publishers can then add keywords
  /// to those placeholders.
  /// Possible string values are:
  /// - "PLACEHOLDER_WITH_LIST_OF_KEYWORDS"
  /// - "IGNORE"
  /// - "GENERATE_SEPARATE_TAG_FOR_EACH_KEYWORD"
  core.String? keywordOption;

  TagSetting();

  TagSetting.fromJson(core.Map _json) {
    if (_json.containsKey('additionalKeyValues')) {
      additionalKeyValues = _json['additionalKeyValues'] as core.String;
    }
    if (_json.containsKey('includeClickThroughUrls')) {
      includeClickThroughUrls = _json['includeClickThroughUrls'] as core.bool;
    }
    if (_json.containsKey('includeClickTracking')) {
      includeClickTracking = _json['includeClickTracking'] as core.bool;
    }
    if (_json.containsKey('keywordOption')) {
      keywordOption = _json['keywordOption'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalKeyValues != null)
          'additionalKeyValues': additionalKeyValues!,
        if (includeClickThroughUrls != null)
          'includeClickThroughUrls': includeClickThroughUrls!,
        if (includeClickTracking != null)
          'includeClickTracking': includeClickTracking!,
        if (keywordOption != null) 'keywordOption': keywordOption!,
      };
}

/// Dynamic and Image Tag Settings.
class TagSettings {
  /// Whether dynamic floodlight tags are enabled.
  core.bool? dynamicTagEnabled;

  /// Whether image tags are enabled.
  core.bool? imageTagEnabled;

  TagSettings();

  TagSettings.fromJson(core.Map _json) {
    if (_json.containsKey('dynamicTagEnabled')) {
      dynamicTagEnabled = _json['dynamicTagEnabled'] as core.bool;
    }
    if (_json.containsKey('imageTagEnabled')) {
      imageTagEnabled = _json['imageTagEnabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dynamicTagEnabled != null) 'dynamicTagEnabled': dynamicTagEnabled!,
        if (imageTagEnabled != null) 'imageTagEnabled': imageTagEnabled!,
      };
}

/// Target Window.
class TargetWindow {
  /// User-entered value.
  core.String? customHtml;

  /// Type of browser window for which the backup image of the flash creative
  /// can be displayed.
  /// Possible string values are:
  /// - "NEW_WINDOW"
  /// - "CURRENT_WINDOW"
  /// - "CUSTOM"
  core.String? targetWindowOption;

  TargetWindow();

  TargetWindow.fromJson(core.Map _json) {
    if (_json.containsKey('customHtml')) {
      customHtml = _json['customHtml'] as core.String;
    }
    if (_json.containsKey('targetWindowOption')) {
      targetWindowOption = _json['targetWindowOption'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customHtml != null) 'customHtml': customHtml!,
        if (targetWindowOption != null)
          'targetWindowOption': targetWindowOption!,
      };
}

/// Contains properties of a targetable remarketing list.
///
/// Remarketing enables you to create lists of users who have performed specific
/// actions on a site, then target ads to members of those lists. This resource
/// is a read-only view of a remarketing list to be used to faciliate targeting
/// ads to specific lists. Remarketing lists that are owned by your advertisers
/// and those that are shared to your advertisers or account are accessible via
/// this resource. To manage remarketing lists that are owned by your
/// advertisers, use the RemarketingLists resource.
class TargetableRemarketingList {
  /// Account ID of this remarketing list.
  ///
  /// This is a read-only, auto-generated field that is only returned in GET
  /// requests.
  core.String? accountId;

  /// Whether this targetable remarketing list is active.
  core.bool? active;

  /// Dimension value for the advertiser ID that owns this targetable
  /// remarketing list.
  core.String? advertiserId;

  /// Dimension value for the ID of the advertiser.
  DimensionValue? advertiserIdDimensionValue;

  /// Targetable remarketing list description.
  core.String? description;

  /// Targetable remarketing list ID.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#targetableRemarketingList".
  core.String? kind;

  /// Number of days that a user should remain in the targetable remarketing
  /// list without an impression.
  core.String? lifeSpan;

  /// Number of users currently in the list.
  ///
  /// This is a read-only field.
  core.String? listSize;

  /// Product from which this targetable remarketing list was originated.
  /// Possible string values are:
  /// - "REMARKETING_LIST_SOURCE_OTHER"
  /// - "REMARKETING_LIST_SOURCE_ADX"
  /// - "REMARKETING_LIST_SOURCE_DFP"
  /// - "REMARKETING_LIST_SOURCE_XFP"
  /// - "REMARKETING_LIST_SOURCE_DFA"
  /// - "REMARKETING_LIST_SOURCE_GA"
  /// - "REMARKETING_LIST_SOURCE_YOUTUBE"
  /// - "REMARKETING_LIST_SOURCE_DBM"
  /// - "REMARKETING_LIST_SOURCE_GPLUS"
  /// - "REMARKETING_LIST_SOURCE_DMP"
  /// - "REMARKETING_LIST_SOURCE_PLAY_STORE"
  core.String? listSource;

  /// Name of the targetable remarketing list.
  ///
  /// Is no greater than 128 characters long.
  core.String? name;

  /// Subaccount ID of this remarketing list.
  ///
  /// This is a read-only, auto-generated field that is only returned in GET
  /// requests.
  core.String? subaccountId;

  TargetableRemarketingList();

  TargetableRemarketingList.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('active')) {
      active = _json['active'] as core.bool;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lifeSpan')) {
      lifeSpan = _json['lifeSpan'] as core.String;
    }
    if (_json.containsKey('listSize')) {
      listSize = _json['listSize'] as core.String;
    }
    if (_json.containsKey('listSource')) {
      listSource = _json['listSource'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (active != null) 'active': active!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (description != null) 'description': description!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (lifeSpan != null) 'lifeSpan': lifeSpan!,
        if (listSize != null) 'listSize': listSize!,
        if (listSource != null) 'listSource': listSource!,
        if (name != null) 'name': name!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
      };
}

/// Targetable remarketing list response
class TargetableRemarketingListsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "dfareporting#targetableRemarketingListsListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  /// Targetable remarketing list collection.
  core.List<TargetableRemarketingList>? targetableRemarketingLists;

  TargetableRemarketingListsListResponse();

  TargetableRemarketingListsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('targetableRemarketingLists')) {
      targetableRemarketingLists =
          (_json['targetableRemarketingLists'] as core.List)
              .map<TargetableRemarketingList>((value) =>
                  TargetableRemarketingList.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (targetableRemarketingLists != null)
          'targetableRemarketingLists': targetableRemarketingLists!
              .map((value) => value.toJson())
              .toList(),
      };
}

/// Contains properties of a targeting template.
///
/// A targeting template encapsulates targeting information which can be reused
/// across multiple ads.
class TargetingTemplate {
  /// Account ID of this targeting template.
  ///
  /// This field, if left unset, will be auto-generated on insert and is
  /// read-only after insert.
  core.String? accountId;

  /// Advertiser ID of this targeting template.
  ///
  /// This is a required field on insert and is read-only after insert.
  core.String? advertiserId;

  /// Dimension value for the ID of the advertiser.
  ///
  /// This is a read-only, auto-generated field.
  DimensionValue? advertiserIdDimensionValue;

  /// Time and day targeting criteria.
  DayPartTargeting? dayPartTargeting;

  /// Geographical targeting criteria.
  GeoTargeting? geoTargeting;

  /// ID of this targeting template.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Key-value targeting criteria.
  KeyValueTargetingExpression? keyValueTargetingExpression;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#targetingTemplate".
  core.String? kind;

  /// Language targeting criteria.
  LanguageTargeting? languageTargeting;

  /// Remarketing list targeting criteria.
  ListTargetingExpression? listTargetingExpression;

  /// Name of this targeting template.
  ///
  /// This field is required. It must be less than 256 characters long and
  /// unique within an advertiser.
  core.String? name;

  /// Subaccount ID of this targeting template.
  ///
  /// This field, if left unset, will be auto-generated on insert and is
  /// read-only after insert.
  core.String? subaccountId;

  /// Technology platform targeting criteria.
  TechnologyTargeting? technologyTargeting;

  TargetingTemplate();

  TargetingTemplate.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserIdDimensionValue')) {
      advertiserIdDimensionValue = DimensionValue.fromJson(
          _json['advertiserIdDimensionValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dayPartTargeting')) {
      dayPartTargeting = DayPartTargeting.fromJson(
          _json['dayPartTargeting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('geoTargeting')) {
      geoTargeting = GeoTargeting.fromJson(
          _json['geoTargeting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('keyValueTargetingExpression')) {
      keyValueTargetingExpression = KeyValueTargetingExpression.fromJson(
          _json['keyValueTargetingExpression']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('languageTargeting')) {
      languageTargeting = LanguageTargeting.fromJson(
          _json['languageTargeting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('listTargetingExpression')) {
      listTargetingExpression = ListTargetingExpression.fromJson(
          _json['listTargetingExpression']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
    if (_json.containsKey('technologyTargeting')) {
      technologyTargeting = TechnologyTargeting.fromJson(
          _json['technologyTargeting'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserIdDimensionValue != null)
          'advertiserIdDimensionValue': advertiserIdDimensionValue!.toJson(),
        if (dayPartTargeting != null)
          'dayPartTargeting': dayPartTargeting!.toJson(),
        if (geoTargeting != null) 'geoTargeting': geoTargeting!.toJson(),
        if (id != null) 'id': id!,
        if (keyValueTargetingExpression != null)
          'keyValueTargetingExpression': keyValueTargetingExpression!.toJson(),
        if (kind != null) 'kind': kind!,
        if (languageTargeting != null)
          'languageTargeting': languageTargeting!.toJson(),
        if (listTargetingExpression != null)
          'listTargetingExpression': listTargetingExpression!.toJson(),
        if (name != null) 'name': name!,
        if (subaccountId != null) 'subaccountId': subaccountId!,
        if (technologyTargeting != null)
          'technologyTargeting': technologyTargeting!.toJson(),
      };
}

/// Targeting Template List Response
class TargetingTemplatesListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#targetingTemplatesListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  /// Targeting template collection.
  core.List<TargetingTemplate>? targetingTemplates;

  TargetingTemplatesListResponse();

  TargetingTemplatesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('targetingTemplates')) {
      targetingTemplates = (_json['targetingTemplates'] as core.List)
          .map<TargetingTemplate>((value) => TargetingTemplate.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (targetingTemplates != null)
          'targetingTemplates':
              targetingTemplates!.map((value) => value.toJson()).toList(),
      };
}

/// Technology Targeting.
class TechnologyTargeting {
  /// Browsers that this ad targets.
  ///
  /// For each browser either set browserVersionId or dartId along with the
  /// version numbers. If both are specified, only browserVersionId will be
  /// used. The other fields are populated automatically when the ad is inserted
  /// or updated.
  core.List<Browser>? browsers;

  /// Connection types that this ad targets.
  ///
  /// For each connection type only id is required. The other fields are
  /// populated automatically when the ad is inserted or updated.
  core.List<ConnectionType>? connectionTypes;

  /// Mobile carriers that this ad targets.
  ///
  /// For each mobile carrier only id is required, and the other fields are
  /// populated automatically when the ad is inserted or updated. If targeting a
  /// mobile carrier, do not set targeting for any zip codes.
  core.List<MobileCarrier>? mobileCarriers;

  /// Operating system versions that this ad targets.
  ///
  /// To target all versions, use operatingSystems. For each operating system
  /// version, only id is required. The other fields are populated automatically
  /// when the ad is inserted or updated. If targeting an operating system
  /// version, do not set targeting for the corresponding operating system in
  /// operatingSystems.
  core.List<OperatingSystemVersion>? operatingSystemVersions;

  /// Operating systems that this ad targets.
  ///
  /// To target specific versions, use operatingSystemVersions. For each
  /// operating system only dartId is required. The other fields are populated
  /// automatically when the ad is inserted or updated. If targeting an
  /// operating system, do not set targeting for operating system versions for
  /// the same operating system.
  core.List<OperatingSystem>? operatingSystems;

  /// Platform types that this ad targets.
  ///
  /// For example, desktop, mobile, or tablet. For each platform type, only id
  /// is required, and the other fields are populated automatically when the ad
  /// is inserted or updated.
  core.List<PlatformType>? platformTypes;

  TechnologyTargeting();

  TechnologyTargeting.fromJson(core.Map _json) {
    if (_json.containsKey('browsers')) {
      browsers = (_json['browsers'] as core.List)
          .map<Browser>((value) =>
              Browser.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('connectionTypes')) {
      connectionTypes = (_json['connectionTypes'] as core.List)
          .map<ConnectionType>((value) => ConnectionType.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('mobileCarriers')) {
      mobileCarriers = (_json['mobileCarriers'] as core.List)
          .map<MobileCarrier>((value) => MobileCarrier.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('operatingSystemVersions')) {
      operatingSystemVersions = (_json['operatingSystemVersions'] as core.List)
          .map<OperatingSystemVersion>((value) =>
              OperatingSystemVersion.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('operatingSystems')) {
      operatingSystems = (_json['operatingSystems'] as core.List)
          .map<OperatingSystem>((value) => OperatingSystem.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('platformTypes')) {
      platformTypes = (_json['platformTypes'] as core.List)
          .map<PlatformType>((value) => PlatformType.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (browsers != null)
          'browsers': browsers!.map((value) => value.toJson()).toList(),
        if (connectionTypes != null)
          'connectionTypes':
              connectionTypes!.map((value) => value.toJson()).toList(),
        if (mobileCarriers != null)
          'mobileCarriers':
              mobileCarriers!.map((value) => value.toJson()).toList(),
        if (operatingSystemVersions != null)
          'operatingSystemVersions':
              operatingSystemVersions!.map((value) => value.toJson()).toList(),
        if (operatingSystems != null)
          'operatingSystems':
              operatingSystems!.map((value) => value.toJson()).toList(),
        if (platformTypes != null)
          'platformTypes':
              platformTypes!.map((value) => value.toJson()).toList(),
      };
}

/// Third Party Authentication Token
class ThirdPartyAuthenticationToken {
  /// Name of the third-party authentication token.
  core.String? name;

  /// Value of the third-party authentication token.
  ///
  /// This is a read-only, auto-generated field.
  core.String? value;

  ThirdPartyAuthenticationToken();

  ThirdPartyAuthenticationToken.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (value != null) 'value': value!,
      };
}

/// Third-party Tracking URL.
class ThirdPartyTrackingUrl {
  /// Third-party URL type for in-stream video and in-stream audio creatives.
  /// Possible string values are:
  /// - "IMPRESSION"
  /// - "CLICK_TRACKING"
  /// - "VIDEO_START"
  /// - "VIDEO_FIRST_QUARTILE"
  /// - "VIDEO_MIDPOINT"
  /// - "VIDEO_THIRD_QUARTILE"
  /// - "VIDEO_COMPLETE"
  /// - "VIDEO_MUTE"
  /// - "VIDEO_PAUSE"
  /// - "VIDEO_REWIND"
  /// - "VIDEO_FULLSCREEN"
  /// - "VIDEO_STOP"
  /// - "VIDEO_CUSTOM"
  /// - "SURVEY"
  /// - "RICH_MEDIA_IMPRESSION"
  /// - "RICH_MEDIA_RM_IMPRESSION"
  /// - "RICH_MEDIA_BACKUP_IMPRESSION"
  /// - "VIDEO_SKIP"
  /// - "VIDEO_PROGRESS"
  core.String? thirdPartyUrlType;

  /// URL for the specified third-party URL type.
  core.String? url;

  ThirdPartyTrackingUrl();

  ThirdPartyTrackingUrl.fromJson(core.Map _json) {
    if (_json.containsKey('thirdPartyUrlType')) {
      thirdPartyUrlType = _json['thirdPartyUrlType'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (thirdPartyUrlType != null) 'thirdPartyUrlType': thirdPartyUrlType!,
        if (url != null) 'url': url!,
      };
}

/// Transcode Settings
class TranscodeSetting {
  /// Allowlist of video formats to be served to this placement.
  ///
  /// Set this list to null or empty to serve all video formats.
  core.List<core.int>? enabledVideoFormats;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#transcodeSetting".
  core.String? kind;

  TranscodeSetting();

  TranscodeSetting.fromJson(core.Map _json) {
    if (_json.containsKey('enabledVideoFormats')) {
      enabledVideoFormats = (_json['enabledVideoFormats'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabledVideoFormats != null)
          'enabledVideoFormats': enabledVideoFormats!,
        if (kind != null) 'kind': kind!,
      };
}

/// A Universal Ad ID as per the VAST 4.0 spec.
///
/// Applicable to the following creative types: INSTREAM_AUDIO, INSTREAM_VIDEO
/// and VPAID.
class UniversalAdId {
  /// Registry used for the Ad ID value.
  /// Possible string values are:
  /// - "OTHER"
  /// - "AD_ID_OFFICIAL"
  /// - "CLEARCAST"
  /// - "DCM"
  core.String? registry;

  /// ID value for this creative.
  ///
  /// Only alphanumeric characters and the following symbols are valid: "_/\-".
  /// Maximum length is 64 characters. Read only when registry is DCM.
  core.String? value;

  UniversalAdId();

  UniversalAdId.fromJson(core.Map _json) {
    if (_json.containsKey('registry')) {
      registry = _json['registry'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (registry != null) 'registry': registry!,
        if (value != null) 'value': value!,
      };
}

/// User Defined Variable configuration.
class UserDefinedVariableConfiguration {
  /// Data type for the variable.
  ///
  /// This is a required field.
  /// Possible string values are:
  /// - "STRING"
  /// - "NUMBER"
  core.String? dataType;

  /// User-friendly name for the variable which will appear in reports.
  ///
  /// This is a required field, must be less than 64 characters long, and cannot
  /// contain the following characters: ""<>".
  core.String? reportName;

  /// Variable name in the tag.
  ///
  /// This is a required field.
  /// Possible string values are:
  /// - "U1"
  /// - "U2"
  /// - "U3"
  /// - "U4"
  /// - "U5"
  /// - "U6"
  /// - "U7"
  /// - "U8"
  /// - "U9"
  /// - "U10"
  /// - "U11"
  /// - "U12"
  /// - "U13"
  /// - "U14"
  /// - "U15"
  /// - "U16"
  /// - "U17"
  /// - "U18"
  /// - "U19"
  /// - "U20"
  /// - "U21"
  /// - "U22"
  /// - "U23"
  /// - "U24"
  /// - "U25"
  /// - "U26"
  /// - "U27"
  /// - "U28"
  /// - "U29"
  /// - "U30"
  /// - "U31"
  /// - "U32"
  /// - "U33"
  /// - "U34"
  /// - "U35"
  /// - "U36"
  /// - "U37"
  /// - "U38"
  /// - "U39"
  /// - "U40"
  /// - "U41"
  /// - "U42"
  /// - "U43"
  /// - "U44"
  /// - "U45"
  /// - "U46"
  /// - "U47"
  /// - "U48"
  /// - "U49"
  /// - "U50"
  /// - "U51"
  /// - "U52"
  /// - "U53"
  /// - "U54"
  /// - "U55"
  /// - "U56"
  /// - "U57"
  /// - "U58"
  /// - "U59"
  /// - "U60"
  /// - "U61"
  /// - "U62"
  /// - "U63"
  /// - "U64"
  /// - "U65"
  /// - "U66"
  /// - "U67"
  /// - "U68"
  /// - "U69"
  /// - "U70"
  /// - "U71"
  /// - "U72"
  /// - "U73"
  /// - "U74"
  /// - "U75"
  /// - "U76"
  /// - "U77"
  /// - "U78"
  /// - "U79"
  /// - "U80"
  /// - "U81"
  /// - "U82"
  /// - "U83"
  /// - "U84"
  /// - "U85"
  /// - "U86"
  /// - "U87"
  /// - "U88"
  /// - "U89"
  /// - "U90"
  /// - "U91"
  /// - "U92"
  /// - "U93"
  /// - "U94"
  /// - "U95"
  /// - "U96"
  /// - "U97"
  /// - "U98"
  /// - "U99"
  /// - "U100"
  core.String? variableType;

  UserDefinedVariableConfiguration();

  UserDefinedVariableConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('dataType')) {
      dataType = _json['dataType'] as core.String;
    }
    if (_json.containsKey('reportName')) {
      reportName = _json['reportName'] as core.String;
    }
    if (_json.containsKey('variableType')) {
      variableType = _json['variableType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataType != null) 'dataType': dataType!,
        if (reportName != null) 'reportName': reportName!,
        if (variableType != null) 'variableType': variableType!,
      };
}

/// A UserProfile resource lets you list all DFA user profiles that are
/// associated with a Google user account.
///
/// The profile_id needs to be specified in other API requests.
class UserProfile {
  /// The account ID to which this profile belongs.
  core.String? accountId;

  /// The account name this profile belongs to.
  core.String? accountName;

  /// Etag of this resource.
  core.String? etag;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#userProfile".
  core.String? kind;

  /// The unique ID of the user profile.
  core.String? profileId;

  /// The sub account ID this profile belongs to if applicable.
  core.String? subAccountId;

  /// The sub account name this profile belongs to if applicable.
  core.String? subAccountName;

  /// The user name.
  core.String? userName;

  UserProfile();

  UserProfile.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('accountName')) {
      accountName = _json['accountName'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('profileId')) {
      profileId = _json['profileId'] as core.String;
    }
    if (_json.containsKey('subAccountId')) {
      subAccountId = _json['subAccountId'] as core.String;
    }
    if (_json.containsKey('subAccountName')) {
      subAccountName = _json['subAccountName'] as core.String;
    }
    if (_json.containsKey('userName')) {
      userName = _json['userName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (accountName != null) 'accountName': accountName!,
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (profileId != null) 'profileId': profileId!,
        if (subAccountId != null) 'subAccountId': subAccountId!,
        if (subAccountName != null) 'subAccountName': subAccountName!,
        if (userName != null) 'userName': userName!,
      };
}

/// Represents the list of user profiles.
class UserProfileList {
  /// Etag of this resource.
  core.String? etag;

  /// The user profiles returned in this response.
  core.List<UserProfile>? items;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#userProfileList".
  core.String? kind;

  UserProfileList();

  UserProfileList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<UserProfile>((value) => UserProfile.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Contains properties of auser role, which is used to manage user access.
class UserRole {
  /// Account ID of this user role.
  ///
  /// This is a read-only field that can be left blank.
  core.String? accountId;

  /// Whether this is a default user role.
  ///
  /// Default user roles are created by the system for the account/subaccount
  /// and cannot be modified or deleted. Each default user role comes with a
  /// basic set of preassigned permissions.
  core.bool? defaultUserRole;

  /// ID of this user role.
  ///
  /// This is a read-only, auto-generated field.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#userRole".
  core.String? kind;

  /// Name of this user role.
  ///
  /// This is a required field. Must be less than 256 characters long. If this
  /// user role is under a subaccount, the name must be unique among sites of
  /// the same subaccount. Otherwise, this user role is a top-level user role,
  /// and the name must be unique among top-level user roles of the same
  /// account.
  core.String? name;

  /// ID of the user role that this user role is based on or copied from.
  ///
  /// This is a required field.
  core.String? parentUserRoleId;

  /// List of permissions associated with this user role.
  core.List<UserRolePermission>? permissions;

  /// Subaccount ID of this user role.
  ///
  /// This is a read-only field that can be left blank.
  core.String? subaccountId;

  UserRole();

  UserRole.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('defaultUserRole')) {
      defaultUserRole = _json['defaultUserRole'] as core.bool;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parentUserRoleId')) {
      parentUserRoleId = _json['parentUserRoleId'] as core.String;
    }
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<UserRolePermission>((value) => UserRolePermission.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('subaccountId')) {
      subaccountId = _json['subaccountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (defaultUserRole != null) 'defaultUserRole': defaultUserRole!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (parentUserRoleId != null) 'parentUserRoleId': parentUserRoleId!,
        if (permissions != null)
          'permissions': permissions!.map((value) => value.toJson()).toList(),
        if (subaccountId != null) 'subaccountId': subaccountId!,
      };
}

/// Contains properties of a user role permission.
class UserRolePermission {
  /// Levels of availability for a user role permission.
  /// Possible string values are:
  /// - "NOT_AVAILABLE_BY_DEFAULT"
  /// - "ACCOUNT_BY_DEFAULT"
  /// - "SUBACCOUNT_AND_ACCOUNT_BY_DEFAULT"
  /// - "ACCOUNT_ALWAYS"
  /// - "SUBACCOUNT_AND_ACCOUNT_ALWAYS"
  /// - "USER_PROFILE_ONLY"
  core.String? availability;

  /// ID of this user role permission.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#userRolePermission".
  core.String? kind;

  /// Name of this user role permission.
  core.String? name;

  /// ID of the permission group that this user role permission belongs to.
  core.String? permissionGroupId;

  UserRolePermission();

  UserRolePermission.fromJson(core.Map _json) {
    if (_json.containsKey('availability')) {
      availability = _json['availability'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('permissionGroupId')) {
      permissionGroupId = _json['permissionGroupId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (availability != null) 'availability': availability!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (permissionGroupId != null) 'permissionGroupId': permissionGroupId!,
      };
}

/// Represents a grouping of related user role permissions.
class UserRolePermissionGroup {
  /// ID of this user role permission.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#userRolePermissionGroup".
  core.String? kind;

  /// Name of this user role permission group.
  core.String? name;

  UserRolePermissionGroup();

  UserRolePermissionGroup.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// User Role Permission Group List Response
class UserRolePermissionGroupsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "dfareporting#userRolePermissionGroupsListResponse".
  core.String? kind;

  /// User role permission group collection.
  core.List<UserRolePermissionGroup>? userRolePermissionGroups;

  UserRolePermissionGroupsListResponse();

  UserRolePermissionGroupsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('userRolePermissionGroups')) {
      userRolePermissionGroups =
          (_json['userRolePermissionGroups'] as core.List)
              .map<UserRolePermissionGroup>((value) =>
                  UserRolePermissionGroup.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (userRolePermissionGroups != null)
          'userRolePermissionGroups':
              userRolePermissionGroups!.map((value) => value.toJson()).toList(),
      };
}

/// User Role Permission List Response
class UserRolePermissionsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#userRolePermissionsListResponse".
  core.String? kind;

  /// User role permission collection.
  core.List<UserRolePermission>? userRolePermissions;

  UserRolePermissionsListResponse();

  UserRolePermissionsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('userRolePermissions')) {
      userRolePermissions = (_json['userRolePermissions'] as core.List)
          .map<UserRolePermission>((value) => UserRolePermission.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (userRolePermissions != null)
          'userRolePermissions':
              userRolePermissions!.map((value) => value.toJson()).toList(),
      };
}

/// User Role List Response
class UserRolesListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#userRolesListResponse".
  core.String? kind;

  /// Pagination token to be used for the next list operation.
  core.String? nextPageToken;

  /// User role collection.
  core.List<UserRole>? userRoles;

  UserRolesListResponse();

  UserRolesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('userRoles')) {
      userRoles = (_json['userRoles'] as core.List)
          .map<UserRole>((value) =>
              UserRole.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (userRoles != null)
          'userRoles': userRoles!.map((value) => value.toJson()).toList(),
      };
}

/// Contains information about supported video formats.
class VideoFormat {
  /// File type of the video format.
  /// Possible string values are:
  /// - "FLV"
  /// - "THREEGPP"
  /// - "MP4"
  /// - "WEBM"
  /// - "M3U8"
  core.String? fileType;

  /// ID of the video format.
  core.int? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#videoFormat".
  core.String? kind;

  /// The resolution of this video format.
  Size? resolution;

  /// The target bit rate of this video format.
  core.int? targetBitRate;

  VideoFormat();

  VideoFormat.fromJson(core.Map _json) {
    if (_json.containsKey('fileType')) {
      fileType = _json['fileType'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.int;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('resolution')) {
      resolution = Size.fromJson(
          _json['resolution'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('targetBitRate')) {
      targetBitRate = _json['targetBitRate'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fileType != null) 'fileType': fileType!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (resolution != null) 'resolution': resolution!.toJson(),
        if (targetBitRate != null) 'targetBitRate': targetBitRate!,
      };
}

/// Video Format List Response
class VideoFormatsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#videoFormatsListResponse".
  core.String? kind;

  /// Video format collection.
  core.List<VideoFormat>? videoFormats;

  VideoFormatsListResponse();

  VideoFormatsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('videoFormats')) {
      videoFormats = (_json['videoFormats'] as core.List)
          .map<VideoFormat>((value) => VideoFormat.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (videoFormats != null)
          'videoFormats': videoFormats!.map((value) => value.toJson()).toList(),
      };
}

/// Video Offset
class VideoOffset {
  /// Duration, as a percentage of video duration.
  ///
  /// Do not set when offsetSeconds is set. Acceptable values are 0 to 100,
  /// inclusive.
  core.int? offsetPercentage;

  /// Duration, in seconds.
  ///
  /// Do not set when offsetPercentage is set. Acceptable values are 0 to 86399,
  /// inclusive.
  core.int? offsetSeconds;

  VideoOffset();

  VideoOffset.fromJson(core.Map _json) {
    if (_json.containsKey('offsetPercentage')) {
      offsetPercentage = _json['offsetPercentage'] as core.int;
    }
    if (_json.containsKey('offsetSeconds')) {
      offsetSeconds = _json['offsetSeconds'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (offsetPercentage != null) 'offsetPercentage': offsetPercentage!,
        if (offsetSeconds != null) 'offsetSeconds': offsetSeconds!,
      };
}

/// Video Settings
class VideoSettings {
  /// Settings for the companion creatives of video creatives served to this
  /// placement.
  CompanionSetting? companionSettings;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "dfareporting#videoSettings".
  core.String? kind;

  /// Whether OBA icons are enabled for this placement.
  core.bool? obaEnabled;

  /// Settings for the OBA icon of video creatives served to this placement.
  ///
  /// If this object is provided, the creative-level OBA settings will be
  /// overridden.
  ObaIcon? obaSettings;

  /// Orientation of a video placement.
  ///
  /// If this value is set, placement will return assets matching the specified
  /// orientation.
  /// Possible string values are:
  /// - "ANY"
  /// - "LANDSCAPE"
  /// - "PORTRAIT"
  core.String? orientation;

  /// Settings for the skippability of video creatives served to this placement.
  ///
  /// If this object is provided, the creative-level skippable settings will be
  /// overridden.
  SkippableSetting? skippableSettings;

  /// Settings for the transcodes of video creatives served to this placement.
  ///
  /// If this object is provided, the creative-level transcode settings will be
  /// overridden.
  TranscodeSetting? transcodeSettings;

  VideoSettings();

  VideoSettings.fromJson(core.Map _json) {
    if (_json.containsKey('companionSettings')) {
      companionSettings = CompanionSetting.fromJson(
          _json['companionSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('obaEnabled')) {
      obaEnabled = _json['obaEnabled'] as core.bool;
    }
    if (_json.containsKey('obaSettings')) {
      obaSettings = ObaIcon.fromJson(
          _json['obaSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('orientation')) {
      orientation = _json['orientation'] as core.String;
    }
    if (_json.containsKey('skippableSettings')) {
      skippableSettings = SkippableSetting.fromJson(
          _json['skippableSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transcodeSettings')) {
      transcodeSettings = TranscodeSetting.fromJson(
          _json['transcodeSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (companionSettings != null)
          'companionSettings': companionSettings!.toJson(),
        if (kind != null) 'kind': kind!,
        if (obaEnabled != null) 'obaEnabled': obaEnabled!,
        if (obaSettings != null) 'obaSettings': obaSettings!.toJson(),
        if (orientation != null) 'orientation': orientation!,
        if (skippableSettings != null)
          'skippableSettings': skippableSettings!.toJson(),
        if (transcodeSettings != null)
          'transcodeSettings': transcodeSettings!.toJson(),
      };
}
