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

/// Admin SDK API - directory_v1
///
/// Admin SDK lets administrators of enterprise domains to view and manage
/// resources like user, groups etc. It also provides audit and usage reports of
/// domain.
///
/// For more information, see <http://developers.google.com/admin-sdk/>
///
/// Create an instance of [DirectoryApi] to access these resources:
///
/// - [AspsResource]
/// - [ChannelsResource]
/// - [ChromeosdevicesResource]
/// - [CustomerResource]
///   - [CustomerDevicesResource]
///     - [CustomerDevicesChromeosResource]
///       - [CustomerDevicesChromeosCommandsResource]
/// - [CustomersResource]
///   - [CustomersChromeResource]
///     - [CustomersChromePrintersResource]
/// - [DomainAliasesResource]
/// - [DomainsResource]
/// - [GroupsResource]
///   - [GroupsAliasesResource]
/// - [MembersResource]
/// - [MobiledevicesResource]
/// - [OrgunitsResource]
/// - [PrivilegesResource]
/// - [ResourcesResource]
///   - [ResourcesBuildingsResource]
///   - [ResourcesCalendarsResource]
///   - [ResourcesFeaturesResource]
/// - [RoleAssignmentsResource]
/// - [RolesResource]
/// - [SchemasResource]
/// - [TokensResource]
/// - [TwoStepVerificationResource]
/// - [UsersResource]
///   - [UsersAliasesResource]
///   - [UsersPhotosResource]
/// - [VerificationCodesResource]
library admin.directory_v1;

import 'dart:async' as async;
import 'dart:collection' as collection;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Admin SDK lets administrators of enterprise domains to view and manage
/// resources like user, groups etc.
///
/// It also provides audit and usage reports of domain.
class DirectoryApi {
  /// See, add, edit, and permanently delete the printers that your organization
  /// can use with Chrome
  static const adminChromePrintersScope =
      'https://www.googleapis.com/auth/admin.chrome.printers';

  /// See the printers that your organization can use with Chrome
  static const adminChromePrintersReadonlyScope =
      'https://www.googleapis.com/auth/admin.chrome.printers.readonly';

  /// View and manage customer related information
  static const adminDirectoryCustomerScope =
      'https://www.googleapis.com/auth/admin.directory.customer';

  /// View customer related information
  static const adminDirectoryCustomerReadonlyScope =
      'https://www.googleapis.com/auth/admin.directory.customer.readonly';

  /// View and manage your Chrome OS devices' metadata
  static const adminDirectoryDeviceChromeosScope =
      'https://www.googleapis.com/auth/admin.directory.device.chromeos';

  /// View your Chrome OS devices' metadata
  static const adminDirectoryDeviceChromeosReadonlyScope =
      'https://www.googleapis.com/auth/admin.directory.device.chromeos.readonly';

  /// View and manage your mobile devices' metadata
  static const adminDirectoryDeviceMobileScope =
      'https://www.googleapis.com/auth/admin.directory.device.mobile';

  /// Manage your mobile devices by performing administrative tasks
  static const adminDirectoryDeviceMobileActionScope =
      'https://www.googleapis.com/auth/admin.directory.device.mobile.action';

  /// View your mobile devices' metadata
  static const adminDirectoryDeviceMobileReadonlyScope =
      'https://www.googleapis.com/auth/admin.directory.device.mobile.readonly';

  /// View and manage the provisioning of domains for your customers
  static const adminDirectoryDomainScope =
      'https://www.googleapis.com/auth/admin.directory.domain';

  /// View domains related to your customers
  static const adminDirectoryDomainReadonlyScope =
      'https://www.googleapis.com/auth/admin.directory.domain.readonly';

  /// View and manage the provisioning of groups on your domain
  static const adminDirectoryGroupScope =
      'https://www.googleapis.com/auth/admin.directory.group';

  /// View and manage group subscriptions on your domain
  static const adminDirectoryGroupMemberScope =
      'https://www.googleapis.com/auth/admin.directory.group.member';

  /// View group subscriptions on your domain
  static const adminDirectoryGroupMemberReadonlyScope =
      'https://www.googleapis.com/auth/admin.directory.group.member.readonly';

  /// View groups on your domain
  static const adminDirectoryGroupReadonlyScope =
      'https://www.googleapis.com/auth/admin.directory.group.readonly';

  /// View and manage organization units on your domain
  static const adminDirectoryOrgunitScope =
      'https://www.googleapis.com/auth/admin.directory.orgunit';

  /// View organization units on your domain
  static const adminDirectoryOrgunitReadonlyScope =
      'https://www.googleapis.com/auth/admin.directory.orgunit.readonly';

  /// View and manage the provisioning of calendar resources on your domain
  static const adminDirectoryResourceCalendarScope =
      'https://www.googleapis.com/auth/admin.directory.resource.calendar';

  /// View calendar resources on your domain
  static const adminDirectoryResourceCalendarReadonlyScope =
      'https://www.googleapis.com/auth/admin.directory.resource.calendar.readonly';

  /// Manage delegated admin roles for your domain
  static const adminDirectoryRolemanagementScope =
      'https://www.googleapis.com/auth/admin.directory.rolemanagement';

  /// View delegated admin roles for your domain
  static const adminDirectoryRolemanagementReadonlyScope =
      'https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly';

  /// View and manage the provisioning of users on your domain
  static const adminDirectoryUserScope =
      'https://www.googleapis.com/auth/admin.directory.user';

  /// View and manage user aliases on your domain
  static const adminDirectoryUserAliasScope =
      'https://www.googleapis.com/auth/admin.directory.user.alias';

  /// View user aliases on your domain
  static const adminDirectoryUserAliasReadonlyScope =
      'https://www.googleapis.com/auth/admin.directory.user.alias.readonly';

  /// See info about users on your domain
  static const adminDirectoryUserReadonlyScope =
      'https://www.googleapis.com/auth/admin.directory.user.readonly';

  /// Manage data access permissions for users on your domain
  static const adminDirectoryUserSecurityScope =
      'https://www.googleapis.com/auth/admin.directory.user.security';

  /// View and manage the provisioning of user schemas on your domain
  static const adminDirectoryUserschemaScope =
      'https://www.googleapis.com/auth/admin.directory.userschema';

  /// View user schemas on your domain
  static const adminDirectoryUserschemaReadonlyScope =
      'https://www.googleapis.com/auth/admin.directory.userschema.readonly';

  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  AspsResource get asps => AspsResource(_requester);
  ChannelsResource get channels => ChannelsResource(_requester);
  ChromeosdevicesResource get chromeosdevices =>
      ChromeosdevicesResource(_requester);
  CustomerResource get customer => CustomerResource(_requester);
  CustomersResource get customers => CustomersResource(_requester);
  DomainAliasesResource get domainAliases => DomainAliasesResource(_requester);
  DomainsResource get domains => DomainsResource(_requester);
  GroupsResource get groups => GroupsResource(_requester);
  MembersResource get members => MembersResource(_requester);
  MobiledevicesResource get mobiledevices => MobiledevicesResource(_requester);
  OrgunitsResource get orgunits => OrgunitsResource(_requester);
  PrivilegesResource get privileges => PrivilegesResource(_requester);
  ResourcesResource get resources => ResourcesResource(_requester);
  RoleAssignmentsResource get roleAssignments =>
      RoleAssignmentsResource(_requester);
  RolesResource get roles => RolesResource(_requester);
  SchemasResource get schemas => SchemasResource(_requester);
  TokensResource get tokens => TokensResource(_requester);
  TwoStepVerificationResource get twoStepVerification =>
      TwoStepVerificationResource(_requester);
  UsersResource get users => UsersResource(_requester);
  VerificationCodesResource get verificationCodes =>
      VerificationCodesResource(_requester);

  DirectoryApi(http.Client client,
      {core.String rootUrl = 'https://admin.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AspsResource {
  final commons.ApiRequester _requester;

  AspsResource(commons.ApiRequester client) : _requester = client;

  /// Delete an ASP issued by a user.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [codeId] - The unique ID of the ASP to be deleted.
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
    core.String userKey,
    core.int codeId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/asps/' +
        commons.escapeVariable('$codeId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Get information about an ASP issued by a user.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [codeId] - The unique ID of the ASP.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Asp].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Asp> get(
    core.String userKey,
    core.int codeId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/asps/' +
        commons.escapeVariable('$codeId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Asp.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List the ASPs issued by a user.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Asps].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Asps> list(
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/asps';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Asps.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ChannelsResource {
  final commons.ApiRequester _requester;

  ChannelsResource(commons.ApiRequester client) : _requester = client;

  /// Stop watching resources through this channel.
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

    const _url = 'admin/directory_v1/channels/stop';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }
}

class ChromeosdevicesResource {
  final commons.ApiRequester _requester;

  ChromeosdevicesResource(commons.ApiRequester client) : _requester = client;

  /// Takes an action that affects a Chrome OS Device.
  ///
  /// This includes deprovisioning, disabling, and re-enabling devices.
  /// *Warning:* * Deprovisioning a device will stop device policy syncing and
  /// remove device-level printers. After a device is deprovisioned, it must be
  /// wiped before it can be re-enrolled. * Lost or stolen devices should use
  /// the disable action. * Re-enabling a disabled device will consume a device
  /// license. If you do not have sufficient licenses available when completing
  /// the re-enable action, you will receive an error. For more information
  /// about deprovisioning and disabling devices, visit the
  /// [help center](https://support.google.com/chrome/a/answer/3523633).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [resourceId] - The unique ID of the device. The `resourceId`s are returned
  /// in the response from the
  /// \[chromeosdevices.list\](/admin-sdk/directory/v1/reference/chromeosdevices/list)
  /// method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> action(
    ChromeOsDeviceAction request,
    core.String customerId,
    core.String resourceId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/devices/chromeos/' +
        commons.escapeVariable('$resourceId') +
        '/action';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a Chrome OS device's properties.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [deviceId] - The unique ID of the device. The `deviceId`s are returned in
  /// the response from the
  /// \[chromeosdevices.list\](/admin-sdk/directory/v1/reference/chromeosdevices/list)
  /// method.
  ///
  /// [projection] - Determines whether the response contains the full list of
  /// properties or only a subset.
  /// Possible string values are:
  /// - "BASIC" : Includes only the basic metadata fields (e.g., deviceId,
  /// serialNumber, status, and user)
  /// - "FULL" : Includes all metadata fields
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ChromeOsDevice].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ChromeOsDevice> get(
    core.String customerId,
    core.String deviceId, {
    core.String? projection,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (projection != null) 'projection': [projection],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/devices/chromeos/' +
        commons.escapeVariable('$deviceId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ChromeOsDevice.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a paginated list of Chrome OS devices within an account.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [maxResults] - Maximum number of results to return.
  ///
  /// [orderBy] - Device property to use for sorting results.
  /// Possible string values are:
  /// - "annotatedLocation" : Chrome device location as annotated by the
  /// administrator.
  /// - "annotatedUser" : Chromebook user as annotated by administrator.
  /// - "lastSync" : The date and time the Chrome device was last synchronized
  /// with the policy settings in the Admin console.
  /// - "notes" : Chrome device notes as annotated by the administrator.
  /// - "serialNumber" : The Chrome device serial number entered when the device
  /// was enabled.
  /// - "status" : Chrome device status. For more information, see the <a
  /// \[chromeosdevices\](/admin-sdk/directory/v1/reference/chromeosdevices.html).
  /// - "supportEndDate" : Chrome device support end date. This is applicable
  /// only for devices purchased directly from Google.
  ///
  /// [orgUnitPath] - The full path of the organizational unit or its unique ID.
  ///
  /// [pageToken] - The `pageToken` query parameter is used to request the next
  /// page of query results. The follow-on request's `pageToken` query parameter
  /// is the `nextPageToken` from your previous response.
  ///
  /// [projection] - Restrict information returned to a set of selected fields.
  /// Possible string values are:
  /// - "BASIC" : Includes only the basic metadata fields (e.g., deviceId,
  /// serialNumber, status, and user)
  /// - "FULL" : Includes all metadata fields
  ///
  /// [query] - Search string in the format given at
  /// http://support.google.com/chromeos/a/bin/answer.py?answer=1698333
  ///
  /// [sortOrder] - Whether to return results in ascending or descending order.
  /// Must be used with the `orderBy` parameter.
  /// Possible string values are:
  /// - "ASCENDING" : Ascending order.
  /// - "DESCENDING" : Descending order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ChromeOsDevices].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ChromeOsDevices> list(
    core.String customerId, {
    core.int? maxResults,
    core.String? orderBy,
    core.String? orgUnitPath,
    core.String? pageToken,
    core.String? projection,
    core.String? query,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (orgUnitPath != null) 'orgUnitPath': [orgUnitPath],
      if (pageToken != null) 'pageToken': [pageToken],
      if (projection != null) 'projection': [projection],
      if (query != null) 'query': [query],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/devices/chromeos';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ChromeOsDevices.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Move or insert multiple Chrome OS devices to an organizational unit.
  ///
  /// You can move up to 50 devices at once.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Immutable ID of the Google Workspace account
  ///
  /// [orgUnitPath] - Full path of the target organizational unit or its ID
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> moveDevicesToOu(
    ChromeOsMoveDevicesToOu request,
    core.String customerId,
    core.String orgUnitPath, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'orgUnitPath': [orgUnitPath],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/devices/chromeos/moveDevicesToOu';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Updates a device's updatable properties, such as `annotatedUser`,
  /// `annotatedLocation`, `notes`, `orgUnitPath`, or `annotatedAssetId`.
  ///
  /// This method supports \[patch
  /// semantics\](/admin-sdk/directory/v1/guides/performance#patch).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [deviceId] - The unique ID of the device. The `deviceId`s are returned in
  /// the response from the
  /// \[chromeosdevices.list\](/admin-sdk/v1/reference/chromeosdevices/list)
  /// method.
  ///
  /// [projection] - Restrict information returned to a set of selected fields.
  /// Possible string values are:
  /// - "BASIC" : Includes only the basic metadata fields (e.g., deviceId,
  /// serialNumber, status, and user)
  /// - "FULL" : Includes all metadata fields
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ChromeOsDevice].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ChromeOsDevice> patch(
    ChromeOsDevice request,
    core.String customerId,
    core.String deviceId, {
    core.String? projection,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (projection != null) 'projection': [projection],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/devices/chromeos/' +
        commons.escapeVariable('$deviceId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return ChromeOsDevice.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a device's updatable properties, such as `annotatedUser`,
  /// `annotatedLocation`, `notes`, `orgUnitPath`, or `annotatedAssetId`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [deviceId] - The unique ID of the device. The `deviceId`s are returned in
  /// the response from the
  /// \[chromeosdevices.list\](/admin-sdk/v1/reference/chromeosdevices/list)
  /// method.
  ///
  /// [projection] - Restrict information returned to a set of selected fields.
  /// Possible string values are:
  /// - "BASIC" : Includes only the basic metadata fields (e.g., deviceId,
  /// serialNumber, status, and user)
  /// - "FULL" : Includes all metadata fields
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ChromeOsDevice].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ChromeOsDevice> update(
    ChromeOsDevice request,
    core.String customerId,
    core.String deviceId, {
    core.String? projection,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (projection != null) 'projection': [projection],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/devices/chromeos/' +
        commons.escapeVariable('$deviceId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return ChromeOsDevice.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CustomerResource {
  final commons.ApiRequester _requester;

  CustomerDevicesResource get devices => CustomerDevicesResource(_requester);

  CustomerResource(commons.ApiRequester client) : _requester = client;
}

class CustomerDevicesResource {
  final commons.ApiRequester _requester;

  CustomerDevicesChromeosResource get chromeos =>
      CustomerDevicesChromeosResource(_requester);

  CustomerDevicesResource(commons.ApiRequester client) : _requester = client;
}

class CustomerDevicesChromeosResource {
  final commons.ApiRequester _requester;

  CustomerDevicesChromeosCommandsResource get commands =>
      CustomerDevicesChromeosCommandsResource(_requester);

  CustomerDevicesChromeosResource(commons.ApiRequester client)
      : _requester = client;

  /// Issues a command for the device to execute.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Immutable. Immutable ID of the Google Workspace account.
  ///
  /// [deviceId] - Immutable. Immutable ID of Chrome OS Device.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DirectoryChromeosdevicesIssueCommandResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DirectoryChromeosdevicesIssueCommandResponse> issueCommand(
    DirectoryChromeosdevicesIssueCommandRequest request,
    core.String customerId,
    core.String deviceId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/devices/chromeos/' +
        commons.escapeVariable('$deviceId') +
        ':issueCommand';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DirectoryChromeosdevicesIssueCommandResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CustomerDevicesChromeosCommandsResource {
  final commons.ApiRequester _requester;

  CustomerDevicesChromeosCommandsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets command data a specific command issued to the device.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Immutable. Immutable ID of the Google Workspace account.
  ///
  /// [deviceId] - Immutable. Immutable ID of Chrome OS Device.
  ///
  /// [commandId] - Immutable. Immutable ID of Chrome OS Device Command.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DirectoryChromeosdevicesCommand].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DirectoryChromeosdevicesCommand> get(
    core.String customerId,
    core.String deviceId,
    core.String commandId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/devices/chromeos/' +
        commons.escapeVariable('$deviceId') +
        '/commands/' +
        commons.escapeVariable('$commandId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DirectoryChromeosdevicesCommand.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CustomersResource {
  final commons.ApiRequester _requester;

  CustomersChromeResource get chrome => CustomersChromeResource(_requester);

  CustomersResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a customer.
  ///
  /// Request parameters:
  ///
  /// [customerKey] - Id of the customer to be retrieved
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Customer> get(
    core.String customerKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customers/' +
        commons.escapeVariable('$customerKey');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Customer.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Patch Customers via Apiary Patch Orchestration
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerKey] - Id of the customer to be updated
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Customer> patch(
    Customer request,
    core.String customerKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customers/' +
        commons.escapeVariable('$customerKey');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Customer.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a customer.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerKey] - Id of the customer to be updated
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Customer> update(
    Customer request,
    core.String customerKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customers/' +
        commons.escapeVariable('$customerKey');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Customer.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class CustomersChromeResource {
  final commons.ApiRequester _requester;

  CustomersChromePrintersResource get printers =>
      CustomersChromePrintersResource(_requester);

  CustomersChromeResource(commons.ApiRequester client) : _requester = client;
}

class CustomersChromePrintersResource {
  final commons.ApiRequester _requester;

  CustomersChromePrintersResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates printers under given Organization Unit.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the customer. Format:
  /// customers/{customer_id}
  /// Value must have pattern `^customers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchCreatePrintersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchCreatePrintersResponse> batchCreatePrinters(
    BatchCreatePrintersRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/' +
        core.Uri.encodeFull('$parent') +
        '/chrome/printers:batchCreatePrinters';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BatchCreatePrintersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes printers in batch.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the customer. Format:
  /// customers/{customer_id}
  /// Value must have pattern `^customers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchDeletePrintersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchDeletePrintersResponse> batchDeletePrinters(
    BatchDeletePrintersRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/' +
        core.Uri.encodeFull('$parent') +
        '/chrome/printers:batchDeletePrinters';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BatchDeletePrintersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a printer under given Organization Unit.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the customer. Format:
  /// customers/{customer_id}
  /// Value must have pattern `^customers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Printer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Printer> create(
    Printer request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/' +
        core.Uri.encodeFull('$parent') +
        '/chrome/printers';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Printer.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a `Printer`.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the printer to be updated. Format:
  /// customers/{customer_id}/chrome/printers/{printer_id}
  /// Value must have pattern `^customers/\[^/\]+/chrome/printers/\[^/\]+$`.
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
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns a `Printer` resource (printer's config).
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the printer to retrieve. Format:
  /// customers/{customer_id}/chrome/printers/{printer_id}
  /// Value must have pattern `^customers/\[^/\]+/chrome/printers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Printer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Printer> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Printer.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List printers configs.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the customer who owns this collection of
  /// printers. Format: customers/{customer_id}
  /// Value must have pattern `^customers/\[^/\]+$`.
  ///
  /// [filter] - Search query. Search syntax is shared between this api and
  /// Admin Console printers pages.
  ///
  /// [orgUnitId] - Organization Unit that we want to list the printers for.
  /// When org_unit is not present in the request then all printers of the
  /// customer are returned (or filtered). When org_unit is present in the
  /// request then only printers available to this OU will be returned (owned or
  /// inherited). You may see if printer is owned or inherited for this OU by
  /// looking at Printer.org_unit_id.
  ///
  /// [pageSize] - The maximum number of objects to return. The service may
  /// return fewer than this value.
  ///
  /// [pageToken] - A page token, received from a previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListPrintersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListPrintersResponse> list(
    core.String parent, {
    core.String? filter,
    core.String? orgUnitId,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orgUnitId != null) 'orgUnitId': [orgUnitId],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/' +
        core.Uri.encodeFull('$parent') +
        '/chrome/printers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListPrintersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the supported printer models.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the customer who owns this collection of
  /// printers. Format: customers/{customer_id}
  /// Value must have pattern `^customers/\[^/\]+$`.
  ///
  /// [filter] - Filer to list only models by a given manufacturer in format:
  /// "manufacturer:Brother". Search syntax is shared between this api and Admin
  /// Console printers pages.
  ///
  /// [pageSize] - The maximum number of objects to return. The service may
  /// return fewer than this value.
  ///
  /// [pageToken] - A page token, received from a previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListPrinterModelsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListPrinterModelsResponse> listPrinterModels(
    core.String parent, {
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

    final _url = 'admin/directory/v1/' +
        core.Uri.encodeFull('$parent') +
        '/chrome/printers:listPrinterModels';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListPrinterModelsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a `Printer` resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the Printer object, in the format
  /// customers/{customer-id}/printers/{printer-id} (During printer creation
  /// leave empty)
  /// Value must have pattern `^customers/\[^/\]+/chrome/printers/\[^/\]+$`.
  ///
  /// [clearMask] - The list of fields to be cleared. Note, some of the fields
  /// are read only and cannot be updated. Values for not specified fields will
  /// be patched.
  ///
  /// [updateMask] - The list of fields to be updated. Note, some of the fields
  /// are read only and cannot be updated. Values for not specified fields will
  /// be patched.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Printer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Printer> patch(
    Printer request,
    core.String name, {
    core.String? clearMask,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (clearMask != null) 'clearMask': [clearMask],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Printer.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class DomainAliasesResource {
  final commons.ApiRequester _requester;

  DomainAliasesResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a domain Alias of the customer.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [domainAliasName] - Name of domain alias to be retrieved.
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
    core.String customer,
    core.String domainAliasName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/domainaliases/' +
        commons.escapeVariable('$domainAliasName');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a domain alias of the customer.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [domainAliasName] - Name of domain alias to be retrieved.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DomainAlias].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DomainAlias> get(
    core.String customer,
    core.String domainAliasName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/domainaliases/' +
        commons.escapeVariable('$domainAliasName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DomainAlias.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a domain alias of the customer.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DomainAlias].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DomainAlias> insert(
    DomainAlias request,
    core.String customer, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/domainaliases';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DomainAlias.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the domain aliases of the customer.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [parentDomainName] - Name of the parent domain for which domain aliases
  /// are to be fetched.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DomainAliases].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DomainAliases> list(
    core.String customer, {
    core.String? parentDomainName,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (parentDomainName != null) 'parentDomainName': [parentDomainName],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/domainaliases';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DomainAliases.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class DomainsResource {
  final commons.ApiRequester _requester;

  DomainsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a domain of the customer.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [domainName] - Name of domain to be deleted
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
    core.String customer,
    core.String domainName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/domains/' +
        commons.escapeVariable('$domainName');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a domain of the customer.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [domainName] - Name of domain to be retrieved
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Domains].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Domains> get(
    core.String customer,
    core.String domainName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/domains/' +
        commons.escapeVariable('$domainName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Domains.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a domain of the customer.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Domains].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Domains> insert(
    Domains request,
    core.String customer, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/domains';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Domains.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the domains of the customer.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Domains2].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Domains2> list(
    core.String customer, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/domains';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Domains2.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class GroupsResource {
  final commons.ApiRequester _requester;

  GroupsAliasesResource get aliases => GroupsAliasesResource(_requester);

  GroupsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a group.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
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
    core.String groupKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'admin/directory/v1/groups/' + commons.escapeVariable('$groupKey');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a group's properties.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Group].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Group> get(
    core.String groupKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'admin/directory/v1/groups/' + commons.escapeVariable('$groupKey');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Group.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Group].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Group> insert(
    Group request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'admin/directory/v1/groups';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Group.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieve all groups of a domain or of a user given a userKey (paginated)
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. In
  /// case of a multi-domain account, to fetch all groups for a customer, fill
  /// this field instead of domain. As an account administrator, you can also
  /// use the `my_customer` alias to represent your account's `customerId`. The
  /// `customerId` is also returned as part of the
  /// \[Users\](/admin-sdk/directory/v1/reference/users)
  ///
  /// [domain] - The domain name. Use this field to get fields from only one
  /// domain. To return all domains for a customer account, use the `customer`
  /// query parameter instead.
  ///
  /// [maxResults] - Maximum number of results to return. Max allowed value is
  /// 200.
  ///
  /// [orderBy] - Column to use for sorting results
  /// Possible string values are:
  /// - "email" : Email of the group.
  ///
  /// [pageToken] - Token to specify next page in the list
  ///
  /// [query] - Query string search. Should be of the form "". Complete
  /// documentation is at https:
  /// //developers.google.com/admin-sdk/directory/v1/guides/search-groups
  ///
  /// [sortOrder] - Whether to return results in ascending or descending order.
  /// Only of use when orderBy is also used
  /// Possible string values are:
  /// - "ASCENDING" : Ascending order.
  /// - "DESCENDING" : Descending order.
  ///
  /// [userKey] - Email or immutable ID of the user if only those groups are to
  /// be listed, the given user is a member of. If it's an ID, it should match
  /// with the ID of the user object.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Groups].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Groups> list({
    core.String? customer,
    core.String? domain,
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? query,
    core.String? sortOrder,
    core.String? userKey,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customer != null) 'customer': [customer],
      if (domain != null) 'domain': [domain],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if (query != null) 'query': [query],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (userKey != null) 'userKey': [userKey],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'admin/directory/v1/groups';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Groups.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a group's properties.
  ///
  /// This method supports \[patch
  /// semantics\](/admin-sdk/directory/v1/guides/performance#patch).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Group].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Group> patch(
    Group request,
    core.String groupKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'admin/directory/v1/groups/' + commons.escapeVariable('$groupKey');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Group.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a group's properties.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Group].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Group> update(
    Group request,
    core.String groupKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'admin/directory/v1/groups/' + commons.escapeVariable('$groupKey');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Group.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class GroupsAliasesResource {
  final commons.ApiRequester _requester;

  GroupsAliasesResource(commons.ApiRequester client) : _requester = client;

  /// Removes an alias.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [alias] - The alias to be removed
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
    core.String groupKey,
    core.String alias, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/groups/' +
        commons.escapeVariable('$groupKey') +
        '/aliases/' +
        commons.escapeVariable('$alias');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Adds an alias for the group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Alias].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Alias> insert(
    Alias request,
    core.String groupKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/groups/' +
        commons.escapeVariable('$groupKey') +
        '/aliases';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Alias.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all aliases for a group.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Aliases].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Aliases> list(
    core.String groupKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/groups/' +
        commons.escapeVariable('$groupKey') +
        '/aliases';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Aliases.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class MembersResource {
  final commons.ApiRequester _requester;

  MembersResource(commons.ApiRequester client) : _requester = client;

  /// Removes a member from a group.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [memberKey] - Identifies the group member in the API request. A group
  /// member can be a user or another group. The value can be the member's
  /// (group or user) primary email address, alias, or unique ID.
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
    core.String groupKey,
    core.String memberKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/groups/' +
        commons.escapeVariable('$groupKey') +
        '/members/' +
        commons.escapeVariable('$memberKey');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a group member's properties.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [memberKey] - Identifies the group member in the API request. A group
  /// member can be a user or another group. The value can be the member's
  /// (group or user) primary email address, alias, or unique ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Member].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Member> get(
    core.String groupKey,
    core.String memberKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/groups/' +
        commons.escapeVariable('$groupKey') +
        '/members/' +
        commons.escapeVariable('$memberKey');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Member.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Checks whether the given user is a member of the group.
  ///
  /// Membership can be direct or nested.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [memberKey] - Identifies the user member in the API request. The value can
  /// be the user's primary email address, alias, or unique ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [MembersHasMember].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<MembersHasMember> hasMember(
    core.String groupKey,
    core.String memberKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/groups/' +
        commons.escapeVariable('$groupKey') +
        '/hasMember/' +
        commons.escapeVariable('$memberKey');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return MembersHasMember.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Adds a user to the specified group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Member].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Member> insert(
    Member request,
    core.String groupKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/groups/' +
        commons.escapeVariable('$groupKey') +
        '/members';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Member.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a paginated list of all members in a group.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [includeDerivedMembership] - Whether to list indirect memberships.
  /// Default: false.
  ///
  /// [maxResults] - Maximum number of results to return. Max allowed value is
  /// 200.
  ///
  /// [pageToken] - Token to specify next page in the list.
  ///
  /// [roles] - The `roles` query parameter allows you to retrieve group members
  /// by role. Allowed values are `OWNER`, `MANAGER`, and `MEMBER`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Members].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Members> list(
    core.String groupKey, {
    core.bool? includeDerivedMembership,
    core.int? maxResults,
    core.String? pageToken,
    core.String? roles,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeDerivedMembership != null)
        'includeDerivedMembership': ['${includeDerivedMembership}'],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (roles != null) 'roles': [roles],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/groups/' +
        commons.escapeVariable('$groupKey') +
        '/members';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Members.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the membership properties of a user in the specified group.
  ///
  /// This method supports \[patch
  /// semantics\](/admin-sdk/directory/v1/guides/performance#patch).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [memberKey] - Identifies the group member in the API request. A group
  /// member can be a user or another group. The value can be the member's
  /// (group or user) primary email address, alias, or unique ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Member].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Member> patch(
    Member request,
    core.String groupKey,
    core.String memberKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/groups/' +
        commons.escapeVariable('$groupKey') +
        '/members/' +
        commons.escapeVariable('$memberKey');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Member.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the membership of a user in the specified group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [groupKey] - Identifies the group in the API request. The value can be the
  /// group's email address, group alias, or the unique group ID.
  ///
  /// [memberKey] - Identifies the group member in the API request. A group
  /// member can be a user or another group. The value can be the member's
  /// (group or user) primary email address, alias, or unique ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Member].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Member> update(
    Member request,
    core.String groupKey,
    core.String memberKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/groups/' +
        commons.escapeVariable('$groupKey') +
        '/members/' +
        commons.escapeVariable('$memberKey');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Member.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class MobiledevicesResource {
  final commons.ApiRequester _requester;

  MobiledevicesResource(commons.ApiRequester client) : _requester = client;

  /// Takes an action that affects a mobile device.
  ///
  /// For example, remotely wiping a device.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [resourceId] - The unique ID the API service uses to identify the mobile
  /// device.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> action(
    MobileDeviceAction request,
    core.String customerId,
    core.String resourceId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/devices/mobile/' +
        commons.escapeVariable('$resourceId') +
        '/action';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Removes a mobile device.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [resourceId] - The unique ID the API service uses to identify the mobile
  /// device.
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
    core.String customerId,
    core.String resourceId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/devices/mobile/' +
        commons.escapeVariable('$resourceId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a mobile device's properties.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [resourceId] - The unique ID the API service uses to identify the mobile
  /// device.
  ///
  /// [projection] - Restrict information returned to a set of selected fields.
  /// Possible string values are:
  /// - "BASIC" : Includes only the basic metadata fields (e.g., deviceId,
  /// model, status, type, and status)
  /// - "FULL" : Includes all metadata fields
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [MobileDevice].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<MobileDevice> get(
    core.String customerId,
    core.String resourceId, {
    core.String? projection,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (projection != null) 'projection': [projection],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/devices/mobile/' +
        commons.escapeVariable('$resourceId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return MobileDevice.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a paginated list of all mobile devices for an account.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [maxResults] - Maximum number of results to return. Max allowed value is
  /// 100.
  /// Value must be between "1" and "100".
  ///
  /// [orderBy] - Device property to use for sorting results.
  /// Possible string values are:
  /// - "deviceId" : The serial number for a Google Sync mobile device. For
  /// Android devices, this is a software generated unique identifier.
  /// - "email" : The device owner's email address.
  /// - "lastSync" : Last policy settings sync date time of the device.
  /// - "model" : The mobile device's model.
  /// - "name" : The device owner's user name.
  /// - "os" : The device's operating system.
  /// - "status" : The device status.
  /// - "type" : Type of the device.
  ///
  /// [pageToken] - Token to specify next page in the list
  ///
  /// [projection] - Restrict information returned to a set of selected fields.
  /// Possible string values are:
  /// - "BASIC" : Includes only the basic metadata fields (e.g., deviceId,
  /// model, status, type, and status)
  /// - "FULL" : Includes all metadata fields
  ///
  /// [query] - Search string in the format given at
  /// https://developers.google.com/admin-sdk/directory/v1/search-operators
  ///
  /// [sortOrder] - Whether to return results in ascending or descending order.
  /// Must be used with the `orderBy` parameter.
  /// Possible string values are:
  /// - "ASCENDING" : Ascending order.
  /// - "DESCENDING" : Descending order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [MobileDevices].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<MobileDevices> list(
    core.String customerId, {
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? projection,
    core.String? query,
    core.String? sortOrder,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if (projection != null) 'projection': [projection],
      if (query != null) 'query': [query],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/devices/mobile';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return MobileDevices.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrgunitsResource {
  final commons.ApiRequester _requester;

  OrgunitsResource(commons.ApiRequester client) : _requester = client;

  /// Removes an organizational unit.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [orgUnitPath] - The full path of the organizational unit or its unique ID.
  /// Value must have pattern `^.*$`.
  ///
  /// [allowPlus] - Parses org unit path without url decode to allow for plus in
  /// ou name
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
    core.String customerId,
    core.String orgUnitPath, {
    core.bool? allowPlus,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (allowPlus != null) 'allowPlus': ['${allowPlus}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/orgunits/' +
        core.Uri.encodeFull('$orgUnitPath');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves an organizational unit.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [orgUnitPath] - The full path of the organizational unit or its unique ID.
  /// Value must have pattern `^.*$`.
  ///
  /// [allowPlus] - Parses org unit path without url decode to allow for plus in
  /// ou name
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgUnit].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgUnit> get(
    core.String customerId,
    core.String orgUnitPath, {
    core.bool? allowPlus,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (allowPlus != null) 'allowPlus': ['${allowPlus}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/orgunits/' +
        core.Uri.encodeFull('$orgUnitPath');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OrgUnit.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Adds an organizational unit.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgUnit].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgUnit> insert(
    OrgUnit request,
    core.String customerId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/orgunits';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrgUnit.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of all organizational units for an account.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [orgUnitPath] - The full path to the organizational unit or its unique ID.
  /// Returns the children of the specified organizational unit.
  ///
  /// [type] - Whether to return all sub-organizations or just immediate
  /// children.
  /// Possible string values are:
  /// - "all" : All sub-organizational units.
  /// - "children" : Immediate children only (default).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgUnits].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgUnits> list(
    core.String customerId, {
    core.String? orgUnitPath,
    core.String? type,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (orgUnitPath != null) 'orgUnitPath': [orgUnitPath],
      if (type != null) 'type': [type],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/orgunits';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OrgUnits.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an organizational unit.
  ///
  /// This method supports \[patch
  /// semantics\](/admin-sdk/directory/v1/guides/performance#patch)
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [orgUnitPath] - The full path of the organizational unit or its unique ID.
  /// Value must have pattern `^.*$`.
  ///
  /// [allowPlus] - Parses org unit path without url decode to allow for plus in
  /// ou name
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgUnit].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgUnit> patch(
    OrgUnit request,
    core.String customerId,
    core.String orgUnitPath, {
    core.bool? allowPlus,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (allowPlus != null) 'allowPlus': ['${allowPlus}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/orgunits/' +
        core.Uri.encodeFull('$orgUnitPath');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return OrgUnit.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an organizational unit.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - The unique ID for the customer's Google Workspace account.
  /// As an account administrator, you can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users).
  ///
  /// [orgUnitPath] - The full path of the organizational unit or its unique ID.
  /// Value must have pattern `^.*$`.
  ///
  /// [allowPlus] - Parses org unit path without url decode to allow for plus in
  /// ou name
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgUnit].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgUnit> update(
    OrgUnit request,
    core.String customerId,
    core.String orgUnitPath, {
    core.bool? allowPlus,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (allowPlus != null) 'allowPlus': ['${allowPlus}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/orgunits/' +
        core.Uri.encodeFull('$orgUnitPath');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return OrgUnit.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class PrivilegesResource {
  final commons.ApiRequester _requester;

  PrivilegesResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a paginated list of all privileges for a customer.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Privileges].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Privileges> list(
    core.String customer, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/roles/ALL/privileges';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Privileges.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ResourcesResource {
  final commons.ApiRequester _requester;

  ResourcesBuildingsResource get buildings =>
      ResourcesBuildingsResource(_requester);
  ResourcesCalendarsResource get calendars =>
      ResourcesCalendarsResource(_requester);
  ResourcesFeaturesResource get features =>
      ResourcesFeaturesResource(_requester);

  ResourcesResource(commons.ApiRequester client) : _requester = client;
}

class ResourcesBuildingsResource {
  final commons.ApiRequester _requester;

  ResourcesBuildingsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a building.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [buildingId] - The id of the building to delete.
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
    core.String customer,
    core.String buildingId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/buildings/' +
        commons.escapeVariable('$buildingId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a building.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [buildingId] - The unique ID of the building to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Building].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Building> get(
    core.String customer,
    core.String buildingId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/buildings/' +
        commons.escapeVariable('$buildingId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Building.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a building.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [coordinatesSource] - Source from which Building.coordinates are derived.
  /// Possible string values are:
  /// - "CLIENT_SPECIFIED" : Building.coordinates are set to the coordinates
  /// included in the request.
  /// - "RESOLVED_FROM_ADDRESS" : Building.coordinates are automatically
  /// populated based on the postal address.
  /// - "SOURCE_UNSPECIFIED" : Defaults to `RESOLVED_FROM_ADDRESS` if postal
  /// address is provided. Otherwise, defaults to `CLIENT_SPECIFIED` if
  /// coordinates are provided.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Building].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Building> insert(
    Building request,
    core.String customer, {
    core.String? coordinatesSource,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (coordinatesSource != null) 'coordinatesSource': [coordinatesSource],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/buildings';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Building.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of buildings for an account.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "1" and "500".
  ///
  /// [pageToken] - Token to specify the next page in the list.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Buildings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Buildings> list(
    core.String customer, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/buildings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Buildings.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Patches a building via Apiary Patch Orchestration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [buildingId] - The id of the building to update.
  ///
  /// [coordinatesSource] - Source from which Building.coordinates are derived.
  /// Possible string values are:
  /// - "CLIENT_SPECIFIED" : Building.coordinates are set to the coordinates
  /// included in the request.
  /// - "RESOLVED_FROM_ADDRESS" : Building.coordinates are automatically
  /// populated based on the postal address.
  /// - "SOURCE_UNSPECIFIED" : Defaults to `RESOLVED_FROM_ADDRESS` if postal
  /// address is provided. Otherwise, defaults to `CLIENT_SPECIFIED` if
  /// coordinates are provided.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Building].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Building> patch(
    Building request,
    core.String customer,
    core.String buildingId, {
    core.String? coordinatesSource,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (coordinatesSource != null) 'coordinatesSource': [coordinatesSource],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/buildings/' +
        commons.escapeVariable('$buildingId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Building.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a building.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [buildingId] - The id of the building to update.
  ///
  /// [coordinatesSource] - Source from which Building.coordinates are derived.
  /// Possible string values are:
  /// - "CLIENT_SPECIFIED" : Building.coordinates are set to the coordinates
  /// included in the request.
  /// - "RESOLVED_FROM_ADDRESS" : Building.coordinates are automatically
  /// populated based on the postal address.
  /// - "SOURCE_UNSPECIFIED" : Defaults to `RESOLVED_FROM_ADDRESS` if postal
  /// address is provided. Otherwise, defaults to `CLIENT_SPECIFIED` if
  /// coordinates are provided.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Building].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Building> update(
    Building request,
    core.String customer,
    core.String buildingId, {
    core.String? coordinatesSource,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (coordinatesSource != null) 'coordinatesSource': [coordinatesSource],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/buildings/' +
        commons.escapeVariable('$buildingId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Building.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ResourcesCalendarsResource {
  final commons.ApiRequester _requester;

  ResourcesCalendarsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a calendar resource.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [calendarResourceId] - The unique ID of the calendar resource to delete.
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
    core.String customer,
    core.String calendarResourceId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/calendars/' +
        commons.escapeVariable('$calendarResourceId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a calendar resource.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [calendarResourceId] - The unique ID of the calendar resource to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CalendarResource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CalendarResource> get(
    core.String customer,
    core.String calendarResourceId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/calendars/' +
        commons.escapeVariable('$calendarResourceId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CalendarResource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a calendar resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CalendarResource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CalendarResource> insert(
    CalendarResource request,
    core.String customer, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/calendars';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CalendarResource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of calendar resources for an account.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "1" and "500".
  ///
  /// [orderBy] - Field(s) to sort results by in either ascending or descending
  /// order. Supported fields include `resourceId`, `resourceName`, `capacity`,
  /// `buildingId`, and `floorName`. If no order is specified, defaults to
  /// ascending. Should be of the form "field \[asc|desc\], field \[asc|desc\],
  /// ...". For example `buildingId, capacity desc` would return results sorted
  /// first by `buildingId` in ascending order then by `capacity` in descending
  /// order.
  ///
  /// [pageToken] - Token to specify the next page in the list.
  ///
  /// [query] - String query used to filter results. Should be of the form
  /// "field operator value" where field can be any of supported fields and
  /// operators can be any of supported operations. Operators include '=' for
  /// exact match, '!=' for mismatch and ':' for prefix match or HAS match where
  /// applicable. For prefix match, the value should always be followed by a *.
  /// Logical operators NOT and AND are supported (in this order of precedence).
  /// Supported fields include `generatedResourceName`, `name`, `buildingId`,
  /// `floor_name`, `capacity`, `featureInstances.feature.name`,
  /// `resourceEmail`, `resourceCategory`. For example `buildingId=US-NYC-9TH
  /// AND featureInstances.feature.name:Phone`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CalendarResources].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CalendarResources> list(
    core.String customer, {
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? query,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if (query != null) 'query': [query],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/calendars';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CalendarResources.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Patches a calendar resource via Apiary Patch Orchestration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [calendarResourceId] - The unique ID of the calendar resource to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CalendarResource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CalendarResource> patch(
    CalendarResource request,
    core.String customer,
    core.String calendarResourceId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/calendars/' +
        commons.escapeVariable('$calendarResourceId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return CalendarResource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a calendar resource.
  ///
  /// This method supports patch semantics, meaning you only need to include the
  /// fields you wish to update. Fields that are not present in the request will
  /// be preserved.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [calendarResourceId] - The unique ID of the calendar resource to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CalendarResource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CalendarResource> update(
    CalendarResource request,
    core.String customer,
    core.String calendarResourceId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/calendars/' +
        commons.escapeVariable('$calendarResourceId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return CalendarResource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ResourcesFeaturesResource {
  final commons.ApiRequester _requester;

  ResourcesFeaturesResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a feature.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [featureKey] - The unique ID of the feature to delete.
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
    core.String customer,
    core.String featureKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/features/' +
        commons.escapeVariable('$featureKey');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a feature.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [featureKey] - The unique ID of the feature to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Feature].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Feature> get(
    core.String customer,
    core.String featureKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/features/' +
        commons.escapeVariable('$featureKey');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Feature.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a feature.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Feature].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Feature> insert(
    Feature request,
    core.String customer, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/features';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Feature.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of features for an account.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "1" and "500".
  ///
  /// [pageToken] - Token to specify the next page in the list.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Features].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Features> list(
    core.String customer, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/features';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Features.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Patches a feature via Apiary Patch Orchestration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [featureKey] - The unique ID of the feature to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Feature].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Feature> patch(
    Feature request,
    core.String customer,
    core.String featureKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/features/' +
        commons.escapeVariable('$featureKey');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Feature.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Renames a feature.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [oldName] - The unique ID of the feature to rename.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> rename(
    FeatureRename request,
    core.String customer,
    core.String oldName, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/features/' +
        commons.escapeVariable('$oldName') +
        '/rename';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Updates a feature.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. As
  /// an account administrator, you can also use the `my_customer` alias to
  /// represent your account's customer ID.
  ///
  /// [featureKey] - The unique ID of the feature to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Feature].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Feature> update(
    Feature request,
    core.String customer,
    core.String featureKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/resources/features/' +
        commons.escapeVariable('$featureKey');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Feature.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class RoleAssignmentsResource {
  final commons.ApiRequester _requester;

  RoleAssignmentsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a role assignment.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [roleAssignmentId] - Immutable ID of the role assignment.
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
    core.String customer,
    core.String roleAssignmentId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/roleassignments/' +
        commons.escapeVariable('$roleAssignmentId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieve a role assignment.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [roleAssignmentId] - Immutable ID of the role assignment.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RoleAssignment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RoleAssignment> get(
    core.String customer,
    core.String roleAssignmentId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/roleassignments/' +
        commons.escapeVariable('$roleAssignmentId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return RoleAssignment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a role assignment.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RoleAssignment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RoleAssignment> insert(
    RoleAssignment request,
    core.String customer, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/roleassignments';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return RoleAssignment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a paginated list of all roleAssignments.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "1" and "200".
  ///
  /// [pageToken] - Token to specify the next page in the list.
  ///
  /// [roleId] - Immutable ID of a role. If included in the request, returns
  /// only role assignments containing this role ID.
  ///
  /// [userKey] - The user's primary email address, alias email address, or
  /// unique user ID. If included in the request, returns role assignments only
  /// for this user.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RoleAssignments].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RoleAssignments> list(
    core.String customer, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? roleId,
    core.String? userKey,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (roleId != null) 'roleId': [roleId],
      if (userKey != null) 'userKey': [userKey],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/roleassignments';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return RoleAssignments.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class RolesResource {
  final commons.ApiRequester _requester;

  RolesResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a role.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [roleId] - Immutable ID of the role.
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
    core.String customer,
    core.String roleId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/roles/' +
        commons.escapeVariable('$roleId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a role.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [roleId] - Immutable ID of the role.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Role].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Role> get(
    core.String customer,
    core.String roleId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/roles/' +
        commons.escapeVariable('$roleId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Role.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a role.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Role].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Role> insert(
    Role request,
    core.String customer, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/roles';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Role.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a paginated list of all the roles in a domain.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "1" and "100".
  ///
  /// [pageToken] - Token to specify the next page in the list.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Roles].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Roles> list(
    core.String customer, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/roles';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Roles.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Patch role via Apiary Patch Orchestration
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [roleId] - Immutable ID of the role.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Role].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Role> patch(
    Role request,
    core.String customer,
    core.String roleId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/roles/' +
        commons.escapeVariable('$roleId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Role.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a role.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - Immutable ID of the Google Workspace account.
  ///
  /// [roleId] - Immutable ID of the role.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Role].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Role> update(
    Role request,
    core.String customer,
    core.String roleId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customer') +
        '/roles/' +
        commons.escapeVariable('$roleId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Role.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SchemasResource {
  final commons.ApiRequester _requester;

  SchemasResource(commons.ApiRequester client) : _requester = client;

  /// Delete schema
  ///
  /// Request parameters:
  ///
  /// [customerId] - Immutable ID of the Google Workspace account.
  ///
  /// [schemaKey] - Name or immutable ID of the schema.
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
    core.String customerId,
    core.String schemaKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/schemas/' +
        commons.escapeVariable('$schemaKey');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieve schema
  ///
  /// Request parameters:
  ///
  /// [customerId] - Immutable ID of the Google Workspace account.
  ///
  /// [schemaKey] - Name or immutable ID of the schema.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Schema].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Schema> get(
    core.String customerId,
    core.String schemaKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/schemas/' +
        commons.escapeVariable('$schemaKey');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Schema.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Create schema.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Immutable ID of the Google Workspace account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Schema].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Schema> insert(
    Schema request,
    core.String customerId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/schemas';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Schema.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieve all schemas for a customer
  ///
  /// Request parameters:
  ///
  /// [customerId] - Immutable ID of the Google Workspace account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Schemas].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Schemas> list(
    core.String customerId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/schemas';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Schemas.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Patch Schema via Apiary Patch Orchestration
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Immutable ID of the Google Workspace account.
  ///
  /// [schemaKey] - Name or immutable ID of the schema.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Schema].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Schema> patch(
    Schema request,
    core.String customerId,
    core.String schemaKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/schemas/' +
        commons.escapeVariable('$schemaKey');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Schema.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Update schema
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Immutable ID of the Google Workspace account.
  ///
  /// [schemaKey] - Name or immutable ID of the schema.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Schema].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Schema> update(
    Schema request,
    core.String customerId,
    core.String schemaKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/customer/' +
        commons.escapeVariable('$customerId') +
        '/schemas/' +
        commons.escapeVariable('$schemaKey');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Schema.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class TokensResource {
  final commons.ApiRequester _requester;

  TokensResource(commons.ApiRequester client) : _requester = client;

  /// Delete all access tokens issued by a user for an application.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [clientId] - The Client ID of the application the token is issued to.
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
    core.String userKey,
    core.String clientId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/tokens/' +
        commons.escapeVariable('$clientId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Get information about an access token issued by a user.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [clientId] - The Client ID of the application the token is issued to.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Token].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Token> get(
    core.String userKey,
    core.String clientId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/tokens/' +
        commons.escapeVariable('$clientId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Token.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the set of tokens specified user has issued to 3rd party
  /// applications.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Tokens].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Tokens> list(
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/tokens';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Tokens.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class TwoStepVerificationResource {
  final commons.ApiRequester _requester;

  TwoStepVerificationResource(commons.ApiRequester client)
      : _requester = client;

  /// Turn off 2-Step Verification for user.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> turnOff(
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/twoStepVerification/turnOff';

    await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }
}

class UsersResource {
  final commons.ApiRequester _requester;

  UsersAliasesResource get aliases => UsersAliasesResource(_requester);
  UsersPhotosResource get photos => UsersPhotosResource(_requester);

  UsersResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a user.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
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
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'admin/directory/v1/users/' + commons.escapeVariable('$userKey');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a user.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [customFieldMask] - A comma-separated list of schema names. All fields
  /// from these schemas are fetched. This should only be set when
  /// `projection=custom`.
  ///
  /// [projection] - What subset of fields to fetch for this user.
  /// Possible string values are:
  /// - "basic" : Do not include any custom fields for the user.
  /// - "custom" : Include custom fields from schemas requested in
  /// `customFieldMask`.
  /// - "full" : Include all fields associated with this user.
  ///
  /// [viewType] - Whether to fetch the administrator-only or domain-wide public
  /// view of the user. For more information, see \[Retrieve a user as a
  /// non-administrator\](/admin-sdk/directory/v1/guides/manage-users#retrieve_users_non_admin).
  /// Possible string values are:
  /// - "admin_view" : Results include both administrator-only and domain-public
  /// fields for the user.
  /// - "domain_public" : Results only include fields for the user that are
  /// publicly visible to other users in the domain.
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
    core.String userKey, {
    core.String? customFieldMask,
    core.String? projection,
    core.String? viewType,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customFieldMask != null) 'customFieldMask': [customFieldMask],
      if (projection != null) 'projection': [projection],
      if (viewType != null) 'viewType': [viewType],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'admin/directory/v1/users/' + commons.escapeVariable('$userKey');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return User.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a user.
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
  async.Future<User> insert(
    User request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'admin/directory/v1/users';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return User.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a paginated list of either deleted users or all users in a
  /// domain.
  ///
  /// Request parameters:
  ///
  /// [customFieldMask] - A comma-separated list of schema names. All fields
  /// from these schemas are fetched. This should only be set when
  /// `projection=custom`.
  ///
  /// [customer] - The unique ID for the customer's Google Workspace account. In
  /// case of a multi-domain account, to fetch all groups for a customer, fill
  /// this field instead of domain. You can also use the `my_customer` alias to
  /// represent your account's `customerId`. The `customerId` is also returned
  /// as part of the \[Users
  /// resource\](/admin-sdk/directory/v1/reference/users). Either the `customer`
  /// or the `domain` parameter must be provided.
  ///
  /// [domain] - The domain name. Use this field to get fields from only one
  /// domain. To return all domains for a customer account, use the `customer`
  /// query parameter instead. Either the `customer` or the `domain` parameter
  /// must be provided.
  ///
  /// [event] - Event on which subscription is intended (if subscribing)
  /// Possible string values are:
  /// - "add" : User Created Event
  /// - "delete" : User Deleted Event
  /// - "makeAdmin" : User Admin Status Change Event
  /// - "undelete" : User Undeleted Event
  /// - "update" : User Updated Event
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "1" and "500".
  ///
  /// [orderBy] - Property to use for sorting results.
  /// Possible string values are:
  /// - "email" : Primary email of the user.
  /// - "familyName" : User's family name.
  /// - "givenName" : User's given name.
  ///
  /// [pageToken] - Token to specify next page in the list
  ///
  /// [projection] - What subset of fields to fetch for this user.
  /// Possible string values are:
  /// - "basic" : Do not include any custom fields for the user.
  /// - "custom" : Include custom fields from schemas requested in
  /// `customFieldMask`.
  /// - "full" : Include all fields associated with this user.
  ///
  /// [query] - Query string for searching user fields. For more information on
  /// constructing user queries, see \[Search for
  /// Users\](/admin-sdk/directory/v1/guides/search-users).
  ///
  /// [showDeleted] - If set to `true`, retrieves the list of deleted users.
  /// (Default: `false`)
  ///
  /// [sortOrder] - Whether to return results in ascending or descending order.
  /// Possible string values are:
  /// - "ASCENDING" : Ascending order.
  /// - "DESCENDING" : Descending order.
  ///
  /// [viewType] - Whether to fetch the administrator-only or domain-wide public
  /// view of the user. For more information, see \[Retrieve a user as a
  /// non-administrator\](/admin-sdk/directory/v1/guides/manage-users#retrieve_users_non_admin).
  /// Possible string values are:
  /// - "admin_view" : Results include both administrator-only and domain-public
  /// fields for the user.
  /// - "domain_public" : Results only include fields for the user that are
  /// publicly visible to other users in the domain.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Users].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Users> list({
    core.String? customFieldMask,
    core.String? customer,
    core.String? domain,
    core.String? event,
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? projection,
    core.String? query,
    core.String? showDeleted,
    core.String? sortOrder,
    core.String? viewType,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customFieldMask != null) 'customFieldMask': [customFieldMask],
      if (customer != null) 'customer': [customer],
      if (domain != null) 'domain': [domain],
      if (event != null) 'event': [event],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if (projection != null) 'projection': [projection],
      if (query != null) 'query': [query],
      if (showDeleted != null) 'showDeleted': [showDeleted],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (viewType != null) 'viewType': [viewType],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'admin/directory/v1/users';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Users.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Makes a user a super administrator.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> makeAdmin(
    UserMakeAdmin request,
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/makeAdmin';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Updates a user using patch semantics.
  ///
  /// The update method should be used instead, since it also supports patch
  /// semantics and has better performance. This method is unable to clear
  /// fields that contain repeated objects (`addresses`, `phones`, etc). Use the
  /// update method instead.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
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
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'admin/directory/v1/users/' + commons.escapeVariable('$userKey');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return User.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sign a user out of all web and device sessions and reset their sign-in
  /// cookies.
  ///
  /// User will have to sign in by authenticating again.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the target user in the API request. The value can
  /// be the user's primary email address, alias email address, or unique user
  /// ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> signOut(
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/signOut';

    await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Undeletes a deleted user.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userKey] - The immutable id of the user
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> undelete(
    UserUndelete request,
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/undelete';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Updates a user.
  ///
  /// This method supports patch semantics, meaning you only need to include the
  /// fields you wish to update. Fields that are not present in the request will
  /// be preserved, and fields set to `null` will be cleared.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
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
  async.Future<User> update(
    User request,
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'admin/directory/v1/users/' + commons.escapeVariable('$userKey');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return User.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Watch for changes in users list
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customFieldMask] - Comma-separated list of schema names. All fields from
  /// these schemas are fetched. This should only be set when projection=custom.
  ///
  /// [customer] - Immutable ID of the Google Workspace account. In case of
  /// multi-domain, to fetch all users for a customer, fill this field instead
  /// of domain.
  ///
  /// [domain] - Name of the domain. Fill this field to get users from only this
  /// domain. To return all users in a multi-domain fill customer field
  /// instead."
  ///
  /// [event] - Events to watch for.
  /// Possible string values are:
  /// - "add" : User Created Event
  /// - "delete" : User Deleted Event
  /// - "makeAdmin" : User Admin Status Change Event
  /// - "undelete" : User Undeleted Event
  /// - "update" : User Updated Event
  ///
  /// [maxResults] - Maximum number of results to return.
  /// Value must be between "1" and "500".
  ///
  /// [orderBy] - Column to use for sorting results
  /// Possible string values are:
  /// - "email" : Primary email of the user.
  /// - "familyName" : User's family name.
  /// - "givenName" : User's given name.
  ///
  /// [pageToken] - Token to specify next page in the list
  ///
  /// [projection] - What subset of fields to fetch for this user.
  /// Possible string values are:
  /// - "basic" : Do not include any custom fields for the user.
  /// - "custom" : Include custom fields from schemas mentioned in
  /// customFieldMask.
  /// - "full" : Include all fields associated with this user.
  ///
  /// [query] - Query string search. Should be of the form "". Complete
  /// documentation is at https:
  /// //developers.google.com/admin-sdk/directory/v1/guides/search-users
  ///
  /// [showDeleted] - If set to true, retrieves the list of deleted users.
  /// (Default: false)
  ///
  /// [sortOrder] - Whether to return results in ascending or descending order.
  /// Possible string values are:
  /// - "ASCENDING" : Ascending order.
  /// - "DESCENDING" : Descending order.
  ///
  /// [viewType] - Whether to fetch the administrator-only or domain-wide public
  /// view of the user. For more information, see \[Retrieve a user as a
  /// non-administrator\](/admin-sdk/directory/v1/guides/manage-users#retrieve_users_non_admin).
  /// Possible string values are:
  /// - "admin_view" : Results include both administrator-only and domain-public
  /// fields.
  /// - "domain_public" : Results only include fields for the user that are
  /// publicly visible to other users in the domain.
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
  async.Future<Channel> watch(
    Channel request, {
    core.String? customFieldMask,
    core.String? customer,
    core.String? domain,
    core.String? event,
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? projection,
    core.String? query,
    core.String? showDeleted,
    core.String? sortOrder,
    core.String? viewType,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (customFieldMask != null) 'customFieldMask': [customFieldMask],
      if (customer != null) 'customer': [customer],
      if (domain != null) 'domain': [domain],
      if (event != null) 'event': [event],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if (projection != null) 'projection': [projection],
      if (query != null) 'query': [query],
      if (showDeleted != null) 'showDeleted': [showDeleted],
      if (sortOrder != null) 'sortOrder': [sortOrder],
      if (viewType != null) 'viewType': [viewType],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'admin/directory/v1/users/watch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Channel.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class UsersAliasesResource {
  final commons.ApiRequester _requester;

  UsersAliasesResource(commons.ApiRequester client) : _requester = client;

  /// Removes an alias.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [alias] - The alias to be removed.
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
    core.String userKey,
    core.String alias, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/aliases/' +
        commons.escapeVariable('$alias');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Adds an alias.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Alias].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Alias> insert(
    Alias request,
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/aliases';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Alias.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all aliases for a user.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [event] - Events to watch for.
  /// Possible string values are:
  /// - "add" : Alias Created Event
  /// - "delete" : Alias Deleted Event
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Aliases].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Aliases> list(
    core.String userKey, {
    core.String? event,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (event != null) 'event': [event],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/aliases';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Aliases.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Watch for changes in users list.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Email or immutable ID of the user
  ///
  /// [event] - Events to watch for.
  /// Possible string values are:
  /// - "add" : Alias Created Event
  /// - "delete" : Alias Deleted Event
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
  async.Future<Channel> watch(
    Channel request,
    core.String userKey, {
    core.String? event,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (event != null) 'event': [event],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/aliases/watch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Channel.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class UsersPhotosResource {
  final commons.ApiRequester _requester;

  UsersPhotosResource(commons.ApiRequester client) : _requester = client;

  /// Removes the user's photo.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
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
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/photos/thumbnail';

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves the user's photo.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserPhoto].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserPhoto> get(
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/photos/thumbnail';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UserPhoto.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Adds a photo for the user.
  ///
  /// This method supports \[patch
  /// semantics\](/admin-sdk/directory/v1/guides/performance#patch).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserPhoto].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserPhoto> patch(
    UserPhoto request,
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/photos/thumbnail';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return UserPhoto.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Adds a photo for the user.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserPhoto].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserPhoto> update(
    UserPhoto request,
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/photos/thumbnail';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return UserPhoto.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class VerificationCodesResource {
  final commons.ApiRequester _requester;

  VerificationCodesResource(commons.ApiRequester client) : _requester = client;

  /// Generate new backup verification codes for the user.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Email or immutable ID of the user
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> generate(
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/verificationCodes/generate';

    await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Invalidate the current backup verification codes for the user.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Email or immutable ID of the user
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> invalidate(
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/verificationCodes/invalidate';

    await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Returns the current set of valid backup verification codes for the
  /// specified user.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Identifies the user in the API request. The value can be the
  /// user's primary email address, alias email address, or unique user ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [VerificationCodes].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<VerificationCodes> list(
    core.String userKey, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/directory/v1/users/' +
        commons.escapeVariable('$userKey') +
        '/verificationCodes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return VerificationCodes.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// JSON template for Alias object in Directory API.
class Alias {
  core.String? alias;
  core.String? etag;
  core.String? id;
  core.String? kind;
  core.String? primaryEmail;

  Alias();

  Alias.fromJson(core.Map _json) {
    if (_json.containsKey('alias')) {
      alias = _json['alias'] as core.String;
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
    if (_json.containsKey('primaryEmail')) {
      primaryEmail = _json['primaryEmail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alias != null) 'alias': alias!,
        if (etag != null) 'etag': etag!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (primaryEmail != null) 'primaryEmail': primaryEmail!,
      };
}

/// JSON response template to list aliases in Directory API.
class Aliases {
  ///
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Object>? aliases;
  core.String? etag;
  core.String? kind;

  Aliases();

  Aliases.fromJson(core.Map _json) {
    if (_json.containsKey('aliases')) {
      aliases = (_json['aliases'] as core.List)
          .map<core.Object>((value) => value as core.Object)
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aliases != null) 'aliases': aliases!,
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
      };
}

/// An application-specific password (ASP) is used with applications that do not
/// accept a verification code when logging into the application on certain
/// devices.
///
/// The ASP access code is used instead of the login and password you commonly
/// use when accessing an application through a browser. For more information
/// about ASPs and how to create one, see the
/// [help center](https://support.google.com/a/answer/2537800#asp).
class Asp {
  /// The unique ID of the ASP.
  core.int? codeId;

  /// The time when the ASP was created.
  ///
  /// Expressed in [Unix time](https://en.wikipedia.org/wiki/Epoch_time) format.
  core.String? creationTime;

  /// ETag of the ASP.
  core.String? etag;

  /// The type of the API resource.
  ///
  /// This is always `admin#directory#asp`.
  core.String? kind;

  /// The time when the ASP was last used.
  ///
  /// Expressed in [Unix time](https://en.wikipedia.org/wiki/Epoch_time) format.
  core.String? lastTimeUsed;

  /// The name of the application that the user, represented by their `userId`,
  /// entered when the ASP was created.
  core.String? name;

  /// The unique ID of the user who issued the ASP.
  core.String? userKey;

  Asp();

  Asp.fromJson(core.Map _json) {
    if (_json.containsKey('codeId')) {
      codeId = _json['codeId'] as core.int;
    }
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastTimeUsed')) {
      lastTimeUsed = _json['lastTimeUsed'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('userKey')) {
      userKey = _json['userKey'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (codeId != null) 'codeId': codeId!,
        if (creationTime != null) 'creationTime': creationTime!,
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (lastTimeUsed != null) 'lastTimeUsed': lastTimeUsed!,
        if (name != null) 'name': name!,
        if (userKey != null) 'userKey': userKey!,
      };
}

class Asps {
  /// ETag of the resource.
  core.String? etag;

  /// A list of ASP resources.
  core.List<Asp>? items;

  /// The type of the API resource.
  ///
  /// This is always `admin#directory#aspList`.
  core.String? kind;

  Asps();

  Asps.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Asp>((value) =>
              Asp.fromJson(value as core.Map<core.String, core.dynamic>))
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

/// Auxiliary message about issues with printers or settings.
///
/// Example: {message_type:AUXILIARY_MESSAGE_WARNING, field_mask:make_and_model,
/// message:"Given printer is invalid or no longer supported."}
class AuxiliaryMessage {
  /// Human readable message in English.
  ///
  /// Example: "Given printer is invalid or no longer supported."
  core.String? auxiliaryMessage;

  /// Field that this message concerns.
  core.String? fieldMask;

  /// Message severity
  /// Possible string values are:
  /// - "SEVERITY_UNSPECIFIED" : Message type unspecified.
  /// - "SEVERITY_INFO" : Message of severity: info.
  /// - "SEVERITY_WARNING" : Message of severity: warning.
  /// - "SEVERITY_ERROR" : Message of severity: error.
  core.String? severity;

  AuxiliaryMessage();

  AuxiliaryMessage.fromJson(core.Map _json) {
    if (_json.containsKey('auxiliaryMessage')) {
      auxiliaryMessage = _json['auxiliaryMessage'] as core.String;
    }
    if (_json.containsKey('fieldMask')) {
      fieldMask = _json['fieldMask'] as core.String;
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auxiliaryMessage != null) 'auxiliaryMessage': auxiliaryMessage!,
        if (fieldMask != null) 'fieldMask': fieldMask!,
        if (severity != null) 'severity': severity!,
      };
}

/// Request for adding new printers in batch.
class BatchCreatePrintersRequest {
  /// A list of Printers to be created.
  ///
  /// Max 50 at a time.
  core.List<CreatePrinterRequest>? requests;

  BatchCreatePrintersRequest();

  BatchCreatePrintersRequest.fromJson(core.Map _json) {
    if (_json.containsKey('requests')) {
      requests = (_json['requests'] as core.List)
          .map<CreatePrinterRequest>((value) => CreatePrinterRequest.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requests != null)
          'requests': requests!.map((value) => value.toJson()).toList(),
      };
}

/// Response for adding new printers in batch.
class BatchCreatePrintersResponse {
  /// A list of create failures.
  ///
  /// Printer IDs are not populated, as printer were not created.
  core.List<FailureInfo>? failures;

  /// A list of successfully created printers with their IDs populated.
  core.List<Printer>? printers;

  BatchCreatePrintersResponse();

  BatchCreatePrintersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('failures')) {
      failures = (_json['failures'] as core.List)
          .map<FailureInfo>((value) => FailureInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('printers')) {
      printers = (_json['printers'] as core.List)
          .map<Printer>((value) =>
              Printer.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (failures != null)
          'failures': failures!.map((value) => value.toJson()).toList(),
        if (printers != null)
          'printers': printers!.map((value) => value.toJson()).toList(),
      };
}

/// Request for deleting existing printers in batch.
class BatchDeletePrintersRequest {
  /// A list of Printer.id that should be deleted.
  ///
  /// Max 100 at a time.
  core.List<core.String>? printerIds;

  BatchDeletePrintersRequest();

  BatchDeletePrintersRequest.fromJson(core.Map _json) {
    if (_json.containsKey('printerIds')) {
      printerIds = (_json['printerIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (printerIds != null) 'printerIds': printerIds!,
      };
}

/// Response for deleting existing printers in batch.
class BatchDeletePrintersResponse {
  /// A list of update failures.
  core.List<FailureInfo>? failedPrinters;

  /// A list of Printer.id that were successfully deleted.
  core.List<core.String>? printerIds;

  BatchDeletePrintersResponse();

  BatchDeletePrintersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('failedPrinters')) {
      failedPrinters = (_json['failedPrinters'] as core.List)
          .map<FailureInfo>((value) => FailureInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('printerIds')) {
      printerIds = (_json['printerIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (failedPrinters != null)
          'failedPrinters':
              failedPrinters!.map((value) => value.toJson()).toList(),
        if (printerIds != null) 'printerIds': printerIds!,
      };
}

/// Public API: Resources.buildings
class Building {
  /// The postal address of the building.
  ///
  /// See \[`PostalAddress`\](/my-business/reference/rest/v4/PostalAddress) for
  /// details. Note that only a single address line and region code are
  /// required.
  BuildingAddress? address;

  /// Unique identifier for the building.
  ///
  /// The maximum length is 100 characters.
  core.String? buildingId;

  /// The building name as seen by users in Calendar.
  ///
  /// Must be unique for the customer. For example, "NYC-CHEL". The maximum
  /// length is 100 characters.
  core.String? buildingName;

  /// The geographic coordinates of the center of the building, expressed as
  /// latitude and longitude in decimal degrees.
  BuildingCoordinates? coordinates;

  /// A brief description of the building.
  ///
  /// For example, "Chelsea Market".
  core.String? description;

  /// ETag of the resource.
  core.String? etags;

  /// The display names for all floors in this building.
  ///
  /// The floors are expected to be sorted in ascending order, from lowest floor
  /// to highest floor. For example, \["B2", "B1", "L", "1", "2", "2M", "3",
  /// "PH"\] Must contain at least one entry.
  core.List<core.String>? floorNames;

  /// Kind of resource this is.
  core.String? kind;

  Building();

  Building.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = BuildingAddress.fromJson(
          _json['address'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('buildingId')) {
      buildingId = _json['buildingId'] as core.String;
    }
    if (_json.containsKey('buildingName')) {
      buildingName = _json['buildingName'] as core.String;
    }
    if (_json.containsKey('coordinates')) {
      coordinates = BuildingCoordinates.fromJson(
          _json['coordinates'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('etags')) {
      etags = _json['etags'] as core.String;
    }
    if (_json.containsKey('floorNames')) {
      floorNames = (_json['floorNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!.toJson(),
        if (buildingId != null) 'buildingId': buildingId!,
        if (buildingName != null) 'buildingName': buildingName!,
        if (coordinates != null) 'coordinates': coordinates!.toJson(),
        if (description != null) 'description': description!,
        if (etags != null) 'etags': etags!,
        if (floorNames != null) 'floorNames': floorNames!,
        if (kind != null) 'kind': kind!,
      };
}

/// Public API: Resources.buildings
class BuildingAddress {
  /// Unstructured address lines describing the lower levels of an address.
  core.List<core.String>? addressLines;

  /// Highest administrative subdivision which is used for postal addresses of a
  /// country or region.
  ///
  /// Optional.
  core.String? administrativeArea;

  /// BCP-47 language code of the contents of this address (if known).
  ///
  /// Optional.
  core.String? languageCode;

  /// Generally refers to the city/town portion of the address.
  ///
  /// Examples: US city, IT comune, UK post town. In regions of the world where
  /// localities are not well defined or do not fit into this structure well,
  /// leave locality empty and use addressLines.
  ///
  /// Optional.
  core.String? locality;

  /// Postal code of the address.
  ///
  /// Optional.
  core.String? postalCode;

  /// CLDR region code of the country/region of the address.
  ///
  /// Required.
  core.String? regionCode;

  /// Sublocality of the address.
  ///
  /// Optional.
  core.String? sublocality;

  BuildingAddress();

  BuildingAddress.fromJson(core.Map _json) {
    if (_json.containsKey('addressLines')) {
      addressLines = (_json['addressLines'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('administrativeArea')) {
      administrativeArea = _json['administrativeArea'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('locality')) {
      locality = _json['locality'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
    if (_json.containsKey('regionCode')) {
      regionCode = _json['regionCode'] as core.String;
    }
    if (_json.containsKey('sublocality')) {
      sublocality = _json['sublocality'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (addressLines != null) 'addressLines': addressLines!,
        if (administrativeArea != null)
          'administrativeArea': administrativeArea!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (locality != null) 'locality': locality!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (regionCode != null) 'regionCode': regionCode!,
        if (sublocality != null) 'sublocality': sublocality!,
      };
}

/// Public API: Resources.buildings
class BuildingCoordinates {
  /// Latitude in decimal degrees.
  core.double? latitude;

  /// Longitude in decimal degrees.
  core.double? longitude;

  BuildingCoordinates();

  BuildingCoordinates.fromJson(core.Map _json) {
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

/// Public API: Resources.buildings
class Buildings {
  /// The Buildings in this page of results.
  core.List<Building>? buildings;

  /// ETag of the resource.
  core.String? etag;

  /// Kind of resource this is.
  core.String? kind;

  /// The continuation token, used to page through large result sets.
  ///
  /// Provide this value in a subsequent request to return the next page of
  /// results.
  core.String? nextPageToken;

  Buildings();

  Buildings.fromJson(core.Map _json) {
    if (_json.containsKey('buildings')) {
      buildings = (_json['buildings'] as core.List)
          .map<Building>((value) =>
              Building.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buildings != null)
          'buildings': buildings!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Public API: Resources.calendars
class CalendarResource {
  /// Unique ID for the building a resource is located in.
  core.String? buildingId;

  /// Capacity of a resource, number of seats in a room.
  core.int? capacity;

  /// ETag of the resource.
  core.String? etags;

  /// Instances of features for the calendar resource.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? featureInstances;

  /// Name of the floor a resource is located on.
  core.String? floorName;

  /// Name of the section within a floor a resource is located in.
  core.String? floorSection;

  /// The read-only auto-generated name of the calendar resource which includes
  /// metadata about the resource such as building name, floor, capacity, etc.
  ///
  /// For example, "NYC-2-Training Room 1A (16)".
  core.String? generatedResourceName;

  /// The type of the resource.
  ///
  /// For calendar resources, the value is
  /// `admin#directory#resources#calendars#CalendarResource`.
  core.String? kind;

  /// The category of the calendar resource.
  ///
  /// Either CONFERENCE_ROOM or OTHER. Legacy data is set to CATEGORY_UNKNOWN.
  core.String? resourceCategory;

  /// Description of the resource, visible only to admins.
  core.String? resourceDescription;

  /// The read-only email for the calendar resource.
  ///
  /// Generated as part of creating a new calendar resource.
  core.String? resourceEmail;

  /// The unique ID for the calendar resource.
  core.String? resourceId;

  /// The name of the calendar resource.
  ///
  /// For example, "Training Room 1A".
  core.String? resourceName;

  /// The type of the calendar resource, intended for non-room resources.
  core.String? resourceType;

  /// Description of the resource, visible to users and admins.
  core.String? userVisibleDescription;

  CalendarResource();

  CalendarResource.fromJson(core.Map _json) {
    if (_json.containsKey('buildingId')) {
      buildingId = _json['buildingId'] as core.String;
    }
    if (_json.containsKey('capacity')) {
      capacity = _json['capacity'] as core.int;
    }
    if (_json.containsKey('etags')) {
      etags = _json['etags'] as core.String;
    }
    if (_json.containsKey('featureInstances')) {
      featureInstances = _json['featureInstances'] as core.Object;
    }
    if (_json.containsKey('floorName')) {
      floorName = _json['floorName'] as core.String;
    }
    if (_json.containsKey('floorSection')) {
      floorSection = _json['floorSection'] as core.String;
    }
    if (_json.containsKey('generatedResourceName')) {
      generatedResourceName = _json['generatedResourceName'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('resourceCategory')) {
      resourceCategory = _json['resourceCategory'] as core.String;
    }
    if (_json.containsKey('resourceDescription')) {
      resourceDescription = _json['resourceDescription'] as core.String;
    }
    if (_json.containsKey('resourceEmail')) {
      resourceEmail = _json['resourceEmail'] as core.String;
    }
    if (_json.containsKey('resourceId')) {
      resourceId = _json['resourceId'] as core.String;
    }
    if (_json.containsKey('resourceName')) {
      resourceName = _json['resourceName'] as core.String;
    }
    if (_json.containsKey('resourceType')) {
      resourceType = _json['resourceType'] as core.String;
    }
    if (_json.containsKey('userVisibleDescription')) {
      userVisibleDescription = _json['userVisibleDescription'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buildingId != null) 'buildingId': buildingId!,
        if (capacity != null) 'capacity': capacity!,
        if (etags != null) 'etags': etags!,
        if (featureInstances != null) 'featureInstances': featureInstances!,
        if (floorName != null) 'floorName': floorName!,
        if (floorSection != null) 'floorSection': floorSection!,
        if (generatedResourceName != null)
          'generatedResourceName': generatedResourceName!,
        if (kind != null) 'kind': kind!,
        if (resourceCategory != null) 'resourceCategory': resourceCategory!,
        if (resourceDescription != null)
          'resourceDescription': resourceDescription!,
        if (resourceEmail != null) 'resourceEmail': resourceEmail!,
        if (resourceId != null) 'resourceId': resourceId!,
        if (resourceName != null) 'resourceName': resourceName!,
        if (resourceType != null) 'resourceType': resourceType!,
        if (userVisibleDescription != null)
          'userVisibleDescription': userVisibleDescription!,
      };
}

/// Public API: Resources.calendars
class CalendarResources {
  /// ETag of the resource.
  core.String? etag;

  /// The CalendarResources in this page of results.
  core.List<CalendarResource>? items;

  /// Identifies this as a collection of CalendarResources.
  ///
  /// This is always
  /// `admin#directory#resources#calendars#calendarResourcesList`.
  core.String? kind;

  /// The continuation token, used to page through large result sets.
  ///
  /// Provide this value in a subsequent request to return the next page of
  /// results.
  core.String? nextPageToken;

  CalendarResources();

  CalendarResources.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<CalendarResource>((value) => CalendarResource.fromJson(
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
  /// resource, which is `api#channel`.
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

class ChromeOsDeviceActiveTimeRanges {
  /// Duration of usage in milliseconds.
  core.int? activeTime;

  /// Date of usage
  core.DateTime? date;

  ChromeOsDeviceActiveTimeRanges();

  ChromeOsDeviceActiveTimeRanges.fromJson(core.Map _json) {
    if (_json.containsKey('activeTime')) {
      activeTime = _json['activeTime'] as core.int;
    }
    if (_json.containsKey('date')) {
      date = core.DateTime.parse(_json['date'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activeTime != null) 'activeTime': activeTime!,
        if (date != null)
          'date':
              "${(date!).year.toString().padLeft(4, '0')}-${(date!).month.toString().padLeft(2, '0')}-${(date!).day.toString().padLeft(2, '0')}",
      };
}

class ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo {
  /// CPU label
  core.String? label;

  /// Temperature in Celsius degrees.
  core.int? temperature;

  ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo();

  ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo.fromJson(core.Map _json) {
    if (_json.containsKey('label')) {
      label = _json['label'] as core.String;
    }
    if (_json.containsKey('temperature')) {
      temperature = _json['temperature'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (label != null) 'label': label!,
        if (temperature != null) 'temperature': temperature!,
      };
}

class ChromeOsDeviceCpuStatusReports {
  /// List of CPU temperature samples.
  core.List<ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo>?
      cpuTemperatureInfo;
  core.List<core.int>? cpuUtilizationPercentageInfo;

  /// Date and time the report was received.
  core.DateTime? reportTime;

  ChromeOsDeviceCpuStatusReports();

  ChromeOsDeviceCpuStatusReports.fromJson(core.Map _json) {
    if (_json.containsKey('cpuTemperatureInfo')) {
      cpuTemperatureInfo = (_json['cpuTemperatureInfo'] as core.List)
          .map<ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo>((value) =>
              ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('cpuUtilizationPercentageInfo')) {
      cpuUtilizationPercentageInfo =
          (_json['cpuUtilizationPercentageInfo'] as core.List)
              .map<core.int>((value) => value as core.int)
              .toList();
    }
    if (_json.containsKey('reportTime')) {
      reportTime = core.DateTime.parse(_json['reportTime'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cpuTemperatureInfo != null)
          'cpuTemperatureInfo':
              cpuTemperatureInfo!.map((value) => value.toJson()).toList(),
        if (cpuUtilizationPercentageInfo != null)
          'cpuUtilizationPercentageInfo': cpuUtilizationPercentageInfo!,
        if (reportTime != null) 'reportTime': reportTime!.toIso8601String(),
      };
}

class ChromeOsDeviceDeviceFiles {
  /// Date and time the file was created
  core.DateTime? createTime;

  /// File download URL
  core.String? downloadUrl;

  /// File name
  core.String? name;

  /// File type
  core.String? type;

  ChromeOsDeviceDeviceFiles();

  ChromeOsDeviceDeviceFiles.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = core.DateTime.parse(_json['createTime'] as core.String);
    }
    if (_json.containsKey('downloadUrl')) {
      downloadUrl = _json['downloadUrl'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!.toIso8601String(),
        if (downloadUrl != null) 'downloadUrl': downloadUrl!,
        if (name != null) 'name': name!,
        if (type != null) 'type': type!,
      };
}

class ChromeOsDeviceDiskVolumeReportsVolumeInfo {
  /// Free disk space \[in bytes\]
  core.String? storageFree;

  /// Total disk space \[in bytes\]
  core.String? storageTotal;

  /// Volume id
  core.String? volumeId;

  ChromeOsDeviceDiskVolumeReportsVolumeInfo();

  ChromeOsDeviceDiskVolumeReportsVolumeInfo.fromJson(core.Map _json) {
    if (_json.containsKey('storageFree')) {
      storageFree = _json['storageFree'] as core.String;
    }
    if (_json.containsKey('storageTotal')) {
      storageTotal = _json['storageTotal'] as core.String;
    }
    if (_json.containsKey('volumeId')) {
      volumeId = _json['volumeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (storageFree != null) 'storageFree': storageFree!,
        if (storageTotal != null) 'storageTotal': storageTotal!,
        if (volumeId != null) 'volumeId': volumeId!,
      };
}

class ChromeOsDeviceDiskVolumeReports {
  /// Disk volumes
  core.List<ChromeOsDeviceDiskVolumeReportsVolumeInfo>? volumeInfo;

  ChromeOsDeviceDiskVolumeReports();

  ChromeOsDeviceDiskVolumeReports.fromJson(core.Map _json) {
    if (_json.containsKey('volumeInfo')) {
      volumeInfo = (_json['volumeInfo'] as core.List)
          .map<ChromeOsDeviceDiskVolumeReportsVolumeInfo>((value) =>
              ChromeOsDeviceDiskVolumeReportsVolumeInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (volumeInfo != null)
          'volumeInfo': volumeInfo!.map((value) => value.toJson()).toList(),
      };
}

/// Information for an ip address.
class ChromeOsDeviceLastKnownNetwork {
  /// The IP address.
  core.String? ipAddress;

  /// The WAN IP address.
  core.String? wanIpAddress;

  ChromeOsDeviceLastKnownNetwork();

  ChromeOsDeviceLastKnownNetwork.fromJson(core.Map _json) {
    if (_json.containsKey('ipAddress')) {
      ipAddress = _json['ipAddress'] as core.String;
    }
    if (_json.containsKey('wanIpAddress')) {
      wanIpAddress = _json['wanIpAddress'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ipAddress != null) 'ipAddress': ipAddress!,
        if (wanIpAddress != null) 'wanIpAddress': wanIpAddress!,
      };
}

/// List of recent device users, in descending order, by last login time.
class ChromeOsDeviceRecentUsers {
  /// The user's email address.
  ///
  /// This is only present if the user type is `USER_TYPE_MANAGED`.
  core.String? email;

  /// The type of the user.
  core.String? type;

  ChromeOsDeviceRecentUsers();

  ChromeOsDeviceRecentUsers.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (type != null) 'type': type!,
      };
}

class ChromeOsDeviceScreenshotFiles {
  /// Date and time the file was created
  core.DateTime? createTime;

  /// File download URL
  core.String? downloadUrl;

  /// File name
  core.String? name;

  /// File type
  core.String? type;

  ChromeOsDeviceScreenshotFiles();

  ChromeOsDeviceScreenshotFiles.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = core.DateTime.parse(_json['createTime'] as core.String);
    }
    if (_json.containsKey('downloadUrl')) {
      downloadUrl = _json['downloadUrl'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!.toIso8601String(),
        if (downloadUrl != null) 'downloadUrl': downloadUrl!,
        if (name != null) 'name': name!,
        if (type != null) 'type': type!,
      };
}

class ChromeOsDeviceSystemRamFreeReports {
  /// Date and time the report was received.
  core.DateTime? reportTime;
  core.List<core.String>? systemRamFreeInfo;

  ChromeOsDeviceSystemRamFreeReports();

  ChromeOsDeviceSystemRamFreeReports.fromJson(core.Map _json) {
    if (_json.containsKey('reportTime')) {
      reportTime = core.DateTime.parse(_json['reportTime'] as core.String);
    }
    if (_json.containsKey('systemRamFreeInfo')) {
      systemRamFreeInfo = (_json['systemRamFreeInfo'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (reportTime != null) 'reportTime': reportTime!.toIso8601String(),
        if (systemRamFreeInfo != null) 'systemRamFreeInfo': systemRamFreeInfo!,
      };
}

/// Trusted Platform Module (TPM) (Read-only)
class ChromeOsDeviceTpmVersionInfo {
  /// TPM family.
  ///
  /// We use the TPM 2.0 style encoding, e.g.: TPM 1.2: "1.2" -> 312e3200 TPM
  /// 2.0: "2.0" -> 322e3000
  core.String? family;

  /// TPM firmware version.
  core.String? firmwareVersion;

  /// TPM manufacturer code.
  core.String? manufacturer;

  /// TPM specification level.
  ///
  /// See Library Specification for TPM 2.0 and Main Specification for TPM 1.2.
  core.String? specLevel;

  /// TPM model number.
  core.String? tpmModel;

  /// Vendor-specific information such as Vendor ID.
  core.String? vendorSpecific;

  ChromeOsDeviceTpmVersionInfo();

  ChromeOsDeviceTpmVersionInfo.fromJson(core.Map _json) {
    if (_json.containsKey('family')) {
      family = _json['family'] as core.String;
    }
    if (_json.containsKey('firmwareVersion')) {
      firmwareVersion = _json['firmwareVersion'] as core.String;
    }
    if (_json.containsKey('manufacturer')) {
      manufacturer = _json['manufacturer'] as core.String;
    }
    if (_json.containsKey('specLevel')) {
      specLevel = _json['specLevel'] as core.String;
    }
    if (_json.containsKey('tpmModel')) {
      tpmModel = _json['tpmModel'] as core.String;
    }
    if (_json.containsKey('vendorSpecific')) {
      vendorSpecific = _json['vendorSpecific'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (family != null) 'family': family!,
        if (firmwareVersion != null) 'firmwareVersion': firmwareVersion!,
        if (manufacturer != null) 'manufacturer': manufacturer!,
        if (specLevel != null) 'specLevel': specLevel!,
        if (tpmModel != null) 'tpmModel': tpmModel!,
        if (vendorSpecific != null) 'vendorSpecific': vendorSpecific!,
      };
}

/// Google Chrome devices run on the
/// [Chrome OS](https://support.google.com/chromeos).
///
/// For more information about common API tasks, see the \[Developer's
/// Guide\](/admin-sdk/directory/v1/guides/manage-chrome-devices).
class ChromeOsDevice {
  /// List of active time ranges (Read-only).
  core.List<ChromeOsDeviceActiveTimeRanges>? activeTimeRanges;

  /// The asset identifier as noted by an administrator or specified during
  /// enrollment.
  core.String? annotatedAssetId;

  /// The address or location of the device as noted by the administrator.
  ///
  /// Maximum length is `200` characters. Empty values are allowed.
  core.String? annotatedLocation;

  /// The user of the device as noted by the administrator.
  ///
  /// Maximum length is 100 characters. Empty values are allowed.
  core.String? annotatedUser;

  /// (Read-only) The timestamp after which the device will stop receiving
  /// Chrome updates or support
  core.String? autoUpdateExpiration;

  /// The boot mode for the device.
  ///
  /// The possible values are: * `Verified`: The device is running a valid
  /// version of the Chrome OS. * `Dev`: The devices's developer hardware switch
  /// is enabled. When booted, the device has a command line shell. For an
  /// example of a developer switch, see the
  /// [Chromebook developer information](https://www.chromium.org/chromium-os/developer-information-for-chrome-os-devices/samsung-series-5-chromebook#TOC-Developer-switch).
  core.String? bootMode;

  /// Reports of CPU utilization and temperature (Read-only)
  core.List<ChromeOsDeviceCpuStatusReports>? cpuStatusReports;

  /// List of device files to download (Read-only)
  core.List<ChromeOsDeviceDeviceFiles>? deviceFiles;

  /// The unique ID of the Chrome device.
  core.String? deviceId;

  /// Reports of disk space and other info about mounted/connected volumes.
  core.List<ChromeOsDeviceDiskVolumeReports>? diskVolumeReports;

  /// (Read-only) Built-in MAC address for the docking station that the device
  /// connected to.
  ///
  /// Factory sets Media access control address (MAC address) assigned for use
  /// by a dock. It is reserved specifically for MAC pass through device policy.
  /// The format is twelve (12) hexadecimal digits without any delimiter
  /// (uppercase letters). This is only relevant for some devices.
  core.String? dockMacAddress;

  /// ETag of the resource.
  core.String? etag;

  /// The device's MAC address on the ethernet network interface.
  core.String? ethernetMacAddress;

  /// (Read-only) MAC address used by the Chromebook’s internal ethernet port,
  /// and for onboard network (ethernet) interface.
  ///
  /// The format is twelve (12) hexadecimal digits without any delimiter
  /// (uppercase letters). This is only relevant for some devices.
  core.String? ethernetMacAddress0;

  /// The Chrome device's firmware version.
  core.String? firmwareVersion;

  /// The type of resource.
  ///
  /// For the Chromeosdevices resource, the value is
  /// `admin#directory#chromeosdevice`.
  core.String? kind;

  /// Date and time the device was last enrolled (Read-only)
  core.DateTime? lastEnrollmentTime;

  /// Contains last known network (Read-only)
  core.List<ChromeOsDeviceLastKnownNetwork>? lastKnownNetwork;

  /// Date and time the device was last synchronized with the policy settings in
  /// the G Suite administrator control panel (Read-only)
  core.DateTime? lastSync;

  /// The device's wireless MAC address.
  ///
  /// If the device does not have this information, it is not included in the
  /// response.
  core.String? macAddress;

  /// (Read-only) The date the device was manufactured in yyyy-mm-dd format.
  core.String? manufactureDate;

  /// The Mobile Equipment Identifier (MEID) or the International Mobile
  /// Equipment Identity (IMEI) for the 3G mobile card in a mobile device.
  ///
  /// A MEID/IMEI is typically used when adding a device to a wireless carrier's
  /// post-pay service plan. If the device does not have this information, this
  /// property is not included in the response. For more information on how to
  /// export a MEID/IMEI list, see the \[Developer's
  /// Guide\](/admin-sdk/directory/v1/guides/manage-chrome-devices.html#export_meid).
  core.String? meid;

  /// The device's model information.
  ///
  /// If the device does not have this information, this property is not
  /// included in the response.
  core.String? model;

  /// Notes about this device added by the administrator.
  ///
  /// This property can be
  /// [searched](https://support.google.com/chrome/a/answer/1698333) with the
  /// \[list\](/admin-sdk/directory/v1/reference/chromeosdevices/list) method's
  /// `query` parameter. Maximum length is 500 characters. Empty values are
  /// allowed.
  core.String? notes;

  /// The device's order number.
  ///
  /// Only devices directly purchased from Google have an order number.
  core.String? orderNumber;

  /// The full parent path with the organizational unit's name associated with
  /// the device.
  ///
  /// Path names are case insensitive. If the parent organizational unit is the
  /// top-level organization, it is represented as a forward slash, `/`. This
  /// property can be
  /// \[updated\](/admin-sdk/directory/v1/guides/manage-chrome-devices#update_chrome_device)
  /// using the API. For more information about how to create an organizational
  /// structure for your device, see the
  /// [administration help center](https://support.google.com/a/answer/182433).
  core.String? orgUnitPath;

  /// The Chrome device's operating system version.
  core.String? osVersion;

  /// The Chrome device's platform version.
  core.String? platformVersion;

  /// List of recent device users, in descending order, by last login time.
  core.List<ChromeOsDeviceRecentUsers>? recentUsers;

  /// List of screenshot files to download.
  ///
  /// Type is always "SCREENSHOT_FILE". (Read-only)
  core.List<ChromeOsDeviceScreenshotFiles>? screenshotFiles;

  /// The Chrome device serial number entered when the device was enabled.
  ///
  /// This value is the same as the Admin console's *Serial Number* in the
  /// *Chrome OS Devices* tab.
  core.String? serialNumber;

  /// The status of the device.
  core.String? status;

  /// Final date the device will be supported (Read-only)
  core.DateTime? supportEndDate;

  /// Reports of amounts of available RAM memory (Read-only)
  core.List<ChromeOsDeviceSystemRamFreeReports>? systemRamFreeReports;

  /// Total RAM on the device \[in bytes\] (Read-only)
  core.String? systemRamTotal;

  /// Trusted Platform Module (TPM) (Read-only)
  ChromeOsDeviceTpmVersionInfo? tpmVersionInfo;

  /// Determines if the device will auto renew its support after the support end
  /// date.
  ///
  /// This is a read-only property.
  core.bool? willAutoRenew;

  ChromeOsDevice();

  ChromeOsDevice.fromJson(core.Map _json) {
    if (_json.containsKey('activeTimeRanges')) {
      activeTimeRanges = (_json['activeTimeRanges'] as core.List)
          .map<ChromeOsDeviceActiveTimeRanges>((value) =>
              ChromeOsDeviceActiveTimeRanges.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('annotatedAssetId')) {
      annotatedAssetId = _json['annotatedAssetId'] as core.String;
    }
    if (_json.containsKey('annotatedLocation')) {
      annotatedLocation = _json['annotatedLocation'] as core.String;
    }
    if (_json.containsKey('annotatedUser')) {
      annotatedUser = _json['annotatedUser'] as core.String;
    }
    if (_json.containsKey('autoUpdateExpiration')) {
      autoUpdateExpiration = _json['autoUpdateExpiration'] as core.String;
    }
    if (_json.containsKey('bootMode')) {
      bootMode = _json['bootMode'] as core.String;
    }
    if (_json.containsKey('cpuStatusReports')) {
      cpuStatusReports = (_json['cpuStatusReports'] as core.List)
          .map<ChromeOsDeviceCpuStatusReports>((value) =>
              ChromeOsDeviceCpuStatusReports.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('deviceFiles')) {
      deviceFiles = (_json['deviceFiles'] as core.List)
          .map<ChromeOsDeviceDeviceFiles>((value) =>
              ChromeOsDeviceDeviceFiles.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('deviceId')) {
      deviceId = _json['deviceId'] as core.String;
    }
    if (_json.containsKey('diskVolumeReports')) {
      diskVolumeReports = (_json['diskVolumeReports'] as core.List)
          .map<ChromeOsDeviceDiskVolumeReports>((value) =>
              ChromeOsDeviceDiskVolumeReports.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dockMacAddress')) {
      dockMacAddress = _json['dockMacAddress'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('ethernetMacAddress')) {
      ethernetMacAddress = _json['ethernetMacAddress'] as core.String;
    }
    if (_json.containsKey('ethernetMacAddress0')) {
      ethernetMacAddress0 = _json['ethernetMacAddress0'] as core.String;
    }
    if (_json.containsKey('firmwareVersion')) {
      firmwareVersion = _json['firmwareVersion'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastEnrollmentTime')) {
      lastEnrollmentTime =
          core.DateTime.parse(_json['lastEnrollmentTime'] as core.String);
    }
    if (_json.containsKey('lastKnownNetwork')) {
      lastKnownNetwork = (_json['lastKnownNetwork'] as core.List)
          .map<ChromeOsDeviceLastKnownNetwork>((value) =>
              ChromeOsDeviceLastKnownNetwork.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('lastSync')) {
      lastSync = core.DateTime.parse(_json['lastSync'] as core.String);
    }
    if (_json.containsKey('macAddress')) {
      macAddress = _json['macAddress'] as core.String;
    }
    if (_json.containsKey('manufactureDate')) {
      manufactureDate = _json['manufactureDate'] as core.String;
    }
    if (_json.containsKey('meid')) {
      meid = _json['meid'] as core.String;
    }
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
    if (_json.containsKey('notes')) {
      notes = _json['notes'] as core.String;
    }
    if (_json.containsKey('orderNumber')) {
      orderNumber = _json['orderNumber'] as core.String;
    }
    if (_json.containsKey('orgUnitPath')) {
      orgUnitPath = _json['orgUnitPath'] as core.String;
    }
    if (_json.containsKey('osVersion')) {
      osVersion = _json['osVersion'] as core.String;
    }
    if (_json.containsKey('platformVersion')) {
      platformVersion = _json['platformVersion'] as core.String;
    }
    if (_json.containsKey('recentUsers')) {
      recentUsers = (_json['recentUsers'] as core.List)
          .map<ChromeOsDeviceRecentUsers>((value) =>
              ChromeOsDeviceRecentUsers.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('screenshotFiles')) {
      screenshotFiles = (_json['screenshotFiles'] as core.List)
          .map<ChromeOsDeviceScreenshotFiles>((value) =>
              ChromeOsDeviceScreenshotFiles.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('serialNumber')) {
      serialNumber = _json['serialNumber'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('supportEndDate')) {
      supportEndDate =
          core.DateTime.parse(_json['supportEndDate'] as core.String);
    }
    if (_json.containsKey('systemRamFreeReports')) {
      systemRamFreeReports = (_json['systemRamFreeReports'] as core.List)
          .map<ChromeOsDeviceSystemRamFreeReports>((value) =>
              ChromeOsDeviceSystemRamFreeReports.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('systemRamTotal')) {
      systemRamTotal = _json['systemRamTotal'] as core.String;
    }
    if (_json.containsKey('tpmVersionInfo')) {
      tpmVersionInfo = ChromeOsDeviceTpmVersionInfo.fromJson(
          _json['tpmVersionInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('willAutoRenew')) {
      willAutoRenew = _json['willAutoRenew'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activeTimeRanges != null)
          'activeTimeRanges':
              activeTimeRanges!.map((value) => value.toJson()).toList(),
        if (annotatedAssetId != null) 'annotatedAssetId': annotatedAssetId!,
        if (annotatedLocation != null) 'annotatedLocation': annotatedLocation!,
        if (annotatedUser != null) 'annotatedUser': annotatedUser!,
        if (autoUpdateExpiration != null)
          'autoUpdateExpiration': autoUpdateExpiration!,
        if (bootMode != null) 'bootMode': bootMode!,
        if (cpuStatusReports != null)
          'cpuStatusReports':
              cpuStatusReports!.map((value) => value.toJson()).toList(),
        if (deviceFiles != null)
          'deviceFiles': deviceFiles!.map((value) => value.toJson()).toList(),
        if (deviceId != null) 'deviceId': deviceId!,
        if (diskVolumeReports != null)
          'diskVolumeReports':
              diskVolumeReports!.map((value) => value.toJson()).toList(),
        if (dockMacAddress != null) 'dockMacAddress': dockMacAddress!,
        if (etag != null) 'etag': etag!,
        if (ethernetMacAddress != null)
          'ethernetMacAddress': ethernetMacAddress!,
        if (ethernetMacAddress0 != null)
          'ethernetMacAddress0': ethernetMacAddress0!,
        if (firmwareVersion != null) 'firmwareVersion': firmwareVersion!,
        if (kind != null) 'kind': kind!,
        if (lastEnrollmentTime != null)
          'lastEnrollmentTime': lastEnrollmentTime!.toIso8601String(),
        if (lastKnownNetwork != null)
          'lastKnownNetwork':
              lastKnownNetwork!.map((value) => value.toJson()).toList(),
        if (lastSync != null) 'lastSync': lastSync!.toIso8601String(),
        if (macAddress != null) 'macAddress': macAddress!,
        if (manufactureDate != null) 'manufactureDate': manufactureDate!,
        if (meid != null) 'meid': meid!,
        if (model != null) 'model': model!,
        if (notes != null) 'notes': notes!,
        if (orderNumber != null) 'orderNumber': orderNumber!,
        if (orgUnitPath != null) 'orgUnitPath': orgUnitPath!,
        if (osVersion != null) 'osVersion': osVersion!,
        if (platformVersion != null) 'platformVersion': platformVersion!,
        if (recentUsers != null)
          'recentUsers': recentUsers!.map((value) => value.toJson()).toList(),
        if (screenshotFiles != null)
          'screenshotFiles':
              screenshotFiles!.map((value) => value.toJson()).toList(),
        if (serialNumber != null) 'serialNumber': serialNumber!,
        if (status != null) 'status': status!,
        if (supportEndDate != null)
          'supportEndDate': supportEndDate!.toIso8601String(),
        if (systemRamFreeReports != null)
          'systemRamFreeReports':
              systemRamFreeReports!.map((value) => value.toJson()).toList(),
        if (systemRamTotal != null) 'systemRamTotal': systemRamTotal!,
        if (tpmVersionInfo != null) 'tpmVersionInfo': tpmVersionInfo!.toJson(),
        if (willAutoRenew != null) 'willAutoRenew': willAutoRenew!,
      };
}

class ChromeOsDeviceAction {
  /// Action to be taken on the Chrome OS device.
  core.String? action;

  /// Only used when the action is `deprovision`.
  ///
  /// With the `deprovision` action, this field is required. *Note*: The
  /// deprovision reason is audited because it might have implications on
  /// licenses for perpetual subscription customers.
  core.String? deprovisionReason;

  ChromeOsDeviceAction();

  ChromeOsDeviceAction.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('deprovisionReason')) {
      deprovisionReason = _json['deprovisionReason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (deprovisionReason != null) 'deprovisionReason': deprovisionReason!,
      };
}

class ChromeOsDevices {
  /// List of Chrome OS Device objects.
  core.List<ChromeOsDevice>? chromeosdevices;

  /// ETag of the resource.
  core.String? etag;

  /// Kind of resource this is.
  core.String? kind;

  /// Token used to access the next page of this result.
  ///
  /// To access the next page, use this token's value in the `pageToken` query
  /// string of this request.
  core.String? nextPageToken;

  ChromeOsDevices();

  ChromeOsDevices.fromJson(core.Map _json) {
    if (_json.containsKey('chromeosdevices')) {
      chromeosdevices = (_json['chromeosdevices'] as core.List)
          .map<ChromeOsDevice>((value) => ChromeOsDevice.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chromeosdevices != null)
          'chromeosdevices':
              chromeosdevices!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ChromeOsMoveDevicesToOu {
  /// Chrome OS devices to be moved to OU
  core.List<core.String>? deviceIds;

  ChromeOsMoveDevicesToOu();

  ChromeOsMoveDevicesToOu.fromJson(core.Map _json) {
    if (_json.containsKey('deviceIds')) {
      deviceIds = (_json['deviceIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceIds != null) 'deviceIds': deviceIds!,
      };
}

/// Request for adding a new printer.
class CreatePrinterRequest {
  /// The name of the customer.
  ///
  /// Format: customers/{customer_id}
  ///
  /// Required.
  core.String? parent;

  /// A printer to create.
  ///
  /// If you want to place the printer under particular OU then populate
  /// printer.org_unit_id filed. Otherwise the printer will be placed under root
  /// OU.
  ///
  /// Required.
  Printer? printer;

  CreatePrinterRequest();

  CreatePrinterRequest.fromJson(core.Map _json) {
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('printer')) {
      printer = Printer.fromJson(
          _json['printer'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parent != null) 'parent': parent!,
        if (printer != null) 'printer': printer!.toJson(),
      };
}

class Customer {
  /// The customer's secondary contact email address.
  ///
  /// This email address cannot be on the same domain as the `customerDomain`
  core.String? alternateEmail;

  /// The customer's creation time (Readonly)
  core.DateTime? customerCreationTime;

  /// The customer's primary domain name string.
  ///
  /// Do not include the `www` prefix when creating a new customer.
  core.String? customerDomain;

  /// ETag of the resource.
  core.String? etag;

  /// The unique ID for the customer's Google Workspace account.
  ///
  /// (Readonly)
  core.String? id;

  /// Identifies the resource as a customer.
  ///
  /// Value: `admin#directory#customer`
  core.String? kind;

  /// The customer's ISO 639-2 language code.
  ///
  /// See the \[Language Codes\](/admin-sdk/directory/v1/languages) page for the
  /// list of supported codes. Valid language codes outside the supported set
  /// will be accepted by the API but may lead to unexpected behavior. The
  /// default value is `en`.
  core.String? language;

  /// The customer's contact phone number in
  /// [E.164](https://en.wikipedia.org/wiki/E.164) format.
  core.String? phoneNumber;

  /// The customer's postal address information.
  CustomerPostalAddress? postalAddress;

  Customer();

  Customer.fromJson(core.Map _json) {
    if (_json.containsKey('alternateEmail')) {
      alternateEmail = _json['alternateEmail'] as core.String;
    }
    if (_json.containsKey('customerCreationTime')) {
      customerCreationTime =
          core.DateTime.parse(_json['customerCreationTime'] as core.String);
    }
    if (_json.containsKey('customerDomain')) {
      customerDomain = _json['customerDomain'] as core.String;
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
    if (_json.containsKey('language')) {
      language = _json['language'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('postalAddress')) {
      postalAddress = CustomerPostalAddress.fromJson(
          _json['postalAddress'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alternateEmail != null) 'alternateEmail': alternateEmail!,
        if (customerCreationTime != null)
          'customerCreationTime': customerCreationTime!.toIso8601String(),
        if (customerDomain != null) 'customerDomain': customerDomain!,
        if (etag != null) 'etag': etag!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (language != null) 'language': language!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (postalAddress != null) 'postalAddress': postalAddress!.toJson(),
      };
}

class CustomerPostalAddress {
  /// A customer's physical address.
  ///
  /// The address can be composed of one to three lines.
  core.String? addressLine1;

  /// Address line 2 of the address.
  core.String? addressLine2;

  /// Address line 3 of the address.
  core.String? addressLine3;

  /// The customer contact's name.
  core.String? contactName;

  /// This is a required property.
  ///
  /// For `countryCode` information see the
  /// [ISO 3166 country code elements](https://www.iso.org/iso/country_codes.htm).
  core.String? countryCode;

  /// Name of the locality.
  ///
  /// An example of a locality value is the city of `San Francisco`.
  core.String? locality;

  /// The company or company division name.
  core.String? organizationName;

  /// The postal code.
  ///
  /// A postalCode example is a postal zip code such as `10009`. This is in
  /// accordance with - http:
  /// //portablecontacts.net/draft-spec.html#address_element.
  core.String? postalCode;

  /// Name of the region.
  ///
  /// An example of a region value is `NY` for the state of New York.
  core.String? region;

  CustomerPostalAddress();

  CustomerPostalAddress.fromJson(core.Map _json) {
    if (_json.containsKey('addressLine1')) {
      addressLine1 = _json['addressLine1'] as core.String;
    }
    if (_json.containsKey('addressLine2')) {
      addressLine2 = _json['addressLine2'] as core.String;
    }
    if (_json.containsKey('addressLine3')) {
      addressLine3 = _json['addressLine3'] as core.String;
    }
    if (_json.containsKey('contactName')) {
      contactName = _json['contactName'] as core.String;
    }
    if (_json.containsKey('countryCode')) {
      countryCode = _json['countryCode'] as core.String;
    }
    if (_json.containsKey('locality')) {
      locality = _json['locality'] as core.String;
    }
    if (_json.containsKey('organizationName')) {
      organizationName = _json['organizationName'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (addressLine1 != null) 'addressLine1': addressLine1!,
        if (addressLine2 != null) 'addressLine2': addressLine2!,
        if (addressLine3 != null) 'addressLine3': addressLine3!,
        if (contactName != null) 'contactName': contactName!,
        if (countryCode != null) 'countryCode': countryCode!,
        if (locality != null) 'locality': locality!,
        if (organizationName != null) 'organizationName': organizationName!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (region != null) 'region': region!,
      };
}

/// Information regarding a command that was issued to a device.
class DirectoryChromeosdevicesCommand {
  /// The time at which the command will expire.
  ///
  /// If the device doesn't execute the command within this time the command
  /// will become expired.
  core.String? commandExpireTime;

  /// Unique ID of a device command.
  core.String? commandId;

  /// The result of the command execution.
  DirectoryChromeosdevicesCommandResult? commandResult;

  /// The timestamp when the command was issued by the admin.
  core.String? issueTime;

  /// The payload that the command specified, if any.
  core.String? payload;

  /// Indicates the command state.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The command status was unspecified.
  /// - "PENDING" : An unexpired command not yet sent to the client.
  /// - "EXPIRED" : The command didn't get executed by the client within the
  /// expected time.
  /// - "CANCELLED" : The command is cancelled by admin while in PENDING.
  /// - "SENT_TO_CLIENT" : The command has been sent to the client.
  /// - "ACKED_BY_CLIENT" : The client has responded that it received the
  /// command.
  /// - "EXECUTED_BY_CLIENT" : The client has (un)successfully executed the
  /// command.
  core.String? state;

  /// The type of the command.
  /// Possible string values are:
  /// - "COMMAND_TYPE_UNSPECIFIED" : The command type was unspecified.
  /// - "REBOOT" : Reboot the device. Can only be issued to Kiosk and managed
  /// guest session devices.
  /// - "TAKE_A_SCREENSHOT" : Take a screenshot of the device. Only available if
  /// the device is in Kiosk Mode.
  /// - "SET_VOLUME" : Set the volume of the device. Can only be issued to Kiosk
  /// and managed guest session devices.
  /// - "WIPE_USERS" : Wipe all the users off of the device. Executing this
  /// command in the device will remove all user profile data, but it will keep
  /// device policy and enrollment.
  /// - "REMOTE_POWERWASH" : Wipes the device by performing a power wash.
  /// Executing this command in the device will remove all data including user
  /// policies, device policies and enrollment policies. Warning: This will
  /// revert the device back to a factory state with no enrollment unless the
  /// device is subject to forced or auto enrollment. Use with caution, as this
  /// is an irreversible action!
  core.String? type;

  DirectoryChromeosdevicesCommand();

  DirectoryChromeosdevicesCommand.fromJson(core.Map _json) {
    if (_json.containsKey('commandExpireTime')) {
      commandExpireTime = _json['commandExpireTime'] as core.String;
    }
    if (_json.containsKey('commandId')) {
      commandId = _json['commandId'] as core.String;
    }
    if (_json.containsKey('commandResult')) {
      commandResult = DirectoryChromeosdevicesCommandResult.fromJson(
          _json['commandResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('issueTime')) {
      issueTime = _json['issueTime'] as core.String;
    }
    if (_json.containsKey('payload')) {
      payload = _json['payload'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commandExpireTime != null) 'commandExpireTime': commandExpireTime!,
        if (commandId != null) 'commandId': commandId!,
        if (commandResult != null) 'commandResult': commandResult!.toJson(),
        if (issueTime != null) 'issueTime': issueTime!,
        if (payload != null) 'payload': payload!,
        if (state != null) 'state': state!,
        if (type != null) 'type': type!,
      };
}

/// The result of executing a command.
class DirectoryChromeosdevicesCommandResult {
  /// The error message with a short explanation as to why the command failed.
  ///
  /// Only present if the command failed.
  core.String? errorMessage;

  /// The time at which the command was executed or failed to execute.
  core.String? executeTime;

  /// The result of the command.
  /// Possible string values are:
  /// - "COMMAND_RESULT_TYPE_UNSPECIFIED" : The command result was unspecified.
  /// - "IGNORED" : The command was ignored as obsolete.
  /// - "FAILURE" : The command could not be executed successfully.
  /// - "SUCCESS" : The command was successfully executed.
  core.String? result;

  DirectoryChromeosdevicesCommandResult();

  DirectoryChromeosdevicesCommandResult.fromJson(core.Map _json) {
    if (_json.containsKey('errorMessage')) {
      errorMessage = _json['errorMessage'] as core.String;
    }
    if (_json.containsKey('executeTime')) {
      executeTime = _json['executeTime'] as core.String;
    }
    if (_json.containsKey('result')) {
      result = _json['result'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorMessage != null) 'errorMessage': errorMessage!,
        if (executeTime != null) 'executeTime': executeTime!,
        if (result != null) 'result': result!,
      };
}

/// A request for issuing a command.
class DirectoryChromeosdevicesIssueCommandRequest {
  /// The type of command.
  /// Possible string values are:
  /// - "COMMAND_TYPE_UNSPECIFIED" : The command type was unspecified.
  /// - "REBOOT" : Reboot the device. Can only be issued to Kiosk and managed
  /// guest session devices.
  /// - "TAKE_A_SCREENSHOT" : Take a screenshot of the device. Only available if
  /// the device is in Kiosk Mode.
  /// - "SET_VOLUME" : Set the volume of the device. Can only be issued to Kiosk
  /// and managed guest session devices.
  /// - "WIPE_USERS" : Wipe all the users off of the device. Executing this
  /// command in the device will remove all user profile data, but it will keep
  /// device policy and enrollment.
  /// - "REMOTE_POWERWASH" : Wipes the device by performing a power wash.
  /// Executing this command in the device will remove all data including user
  /// policies, device policies and enrollment policies. Warning: This will
  /// revert the device back to a factory state with no enrollment unless the
  /// device is subject to forced or auto enrollment. Use with caution, as this
  /// is an irreversible action!
  core.String? commandType;

  /// The payload for the command, provide it only if command supports it.
  ///
  /// The following commands support adding payload: - SET_VOLUME: Payload is a
  /// stringified JSON object in the form: { "volume": 50 }. The volume has to
  /// be an integer in the range \[0,100\].
  core.String? payload;

  DirectoryChromeosdevicesIssueCommandRequest();

  DirectoryChromeosdevicesIssueCommandRequest.fromJson(core.Map _json) {
    if (_json.containsKey('commandType')) {
      commandType = _json['commandType'] as core.String;
    }
    if (_json.containsKey('payload')) {
      payload = _json['payload'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commandType != null) 'commandType': commandType!,
        if (payload != null) 'payload': payload!,
      };
}

/// A response for issuing a command.
class DirectoryChromeosdevicesIssueCommandResponse {
  /// The unique ID of the issued command, used to retrieve the command status.
  core.String? commandId;

  DirectoryChromeosdevicesIssueCommandResponse();

  DirectoryChromeosdevicesIssueCommandResponse.fromJson(core.Map _json) {
    if (_json.containsKey('commandId')) {
      commandId = _json['commandId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commandId != null) 'commandId': commandId!,
      };
}

class DomainAlias {
  /// The creation time of the domain alias.
  ///
  /// (Read-only).
  core.String? creationTime;

  /// The domain alias name.
  core.String? domainAliasName;

  /// ETag of the resource.
  core.String? etag;

  /// Kind of resource this is.
  core.String? kind;

  /// The parent domain name that the domain alias is associated with.
  ///
  /// This can either be a primary or secondary domain name within a customer.
  core.String? parentDomainName;

  /// Indicates the verification state of a domain alias.
  ///
  /// (Read-only)
  core.bool? verified;

  DomainAlias();

  DomainAlias.fromJson(core.Map _json) {
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('domainAliasName')) {
      domainAliasName = _json['domainAliasName'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('parentDomainName')) {
      parentDomainName = _json['parentDomainName'] as core.String;
    }
    if (_json.containsKey('verified')) {
      verified = _json['verified'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creationTime != null) 'creationTime': creationTime!,
        if (domainAliasName != null) 'domainAliasName': domainAliasName!,
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (parentDomainName != null) 'parentDomainName': parentDomainName!,
        if (verified != null) 'verified': verified!,
      };
}

class DomainAliases {
  /// List of domain alias objects.
  core.List<DomainAlias>? domainAliases;

  /// ETag of the resource.
  core.String? etag;

  /// Kind of resource this is.
  core.String? kind;

  DomainAliases();

  DomainAliases.fromJson(core.Map _json) {
    if (_json.containsKey('domainAliases')) {
      domainAliases = (_json['domainAliases'] as core.List)
          .map<DomainAlias>((value) => DomainAlias.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (domainAliases != null)
          'domainAliases':
              domainAliases!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
      };
}

class Domains {
  /// Creation time of the domain.
  ///
  /// Expressed in [Unix time](https://en.wikipedia.org/wiki/Epoch_time) format.
  /// (Read-only).
  core.String? creationTime;

  /// List of domain alias objects.
  ///
  /// (Read-only)
  core.List<DomainAlias>? domainAliases;

  /// The domain name of the customer.
  core.String? domainName;

  /// ETag of the resource.
  core.String? etag;

  /// Indicates if the domain is a primary domain (Read-only).
  core.bool? isPrimary;

  /// Kind of resource this is.
  core.String? kind;

  /// Indicates the verification state of a domain.
  ///
  /// (Read-only).
  core.bool? verified;

  Domains();

  Domains.fromJson(core.Map _json) {
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('domainAliases')) {
      domainAliases = (_json['domainAliases'] as core.List)
          .map<DomainAlias>((value) => DomainAlias.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('domainName')) {
      domainName = _json['domainName'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('isPrimary')) {
      isPrimary = _json['isPrimary'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('verified')) {
      verified = _json['verified'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creationTime != null) 'creationTime': creationTime!,
        if (domainAliases != null)
          'domainAliases':
              domainAliases!.map((value) => value.toJson()).toList(),
        if (domainName != null) 'domainName': domainName!,
        if (etag != null) 'etag': etag!,
        if (isPrimary != null) 'isPrimary': isPrimary!,
        if (kind != null) 'kind': kind!,
        if (verified != null) 'verified': verified!,
      };
}

class Domains2 {
  /// List of domain objects.
  core.List<Domains>? domains;

  /// ETag of the resource.
  core.String? etag;

  /// Kind of resource this is.
  core.String? kind;

  Domains2();

  Domains2.fromJson(core.Map _json) {
    if (_json.containsKey('domains')) {
      domains = (_json['domains'] as core.List)
          .map<Domains>((value) =>
              Domains.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (domains != null)
          'domains': domains!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
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

/// Info about failures
class FailureInfo {
  /// Canonical code for why the update failed to apply.
  /// Possible string values are:
  /// - "OK" : Not an error; returned on success HTTP Mapping: 200 OK
  /// - "CANCELLED" : The operation was cancelled, typically by the caller. HTTP
  /// Mapping: 499 Client Closed Request
  /// - "UNKNOWN" : Unknown error. For example, this error may be returned when
  /// a `Status` value received from another address space belongs to an error
  /// space that is not known in this address space. Also errors raised by APIs
  /// that do not return enough error information may be converted to this
  /// error. HTTP Mapping: 500 Internal Server Error
  /// - "INVALID_ARGUMENT" : The client specified an invalid argument. Note that
  /// this differs from `FAILED_PRECONDITION`. `INVALID_ARGUMENT` indicates
  /// arguments that are problematic regardless of the state of the system
  /// (e.g., a malformed file name). HTTP Mapping: 400 Bad Request
  /// - "DEADLINE_EXCEEDED" : The deadline expired before the operation could
  /// complete. For operations that change the state of the system, this error
  /// may be returned even if the operation has completed successfully. For
  /// example, a successful response from a server could have been delayed long
  /// enough for the deadline to expire. HTTP Mapping: 504 Gateway Timeout
  /// - "NOT_FOUND" : Some requested entity (e.g., file or directory) was not
  /// found. Note to server developers: if a request is denied for an entire
  /// class of users, such as gradual feature rollout or undocumented allowlist,
  /// `NOT_FOUND` may be used. If a request is denied for some users within a
  /// class of users, such as user-based access control, `PERMISSION_DENIED`
  /// must be used. HTTP Mapping: 404 Not Found
  /// - "ALREADY_EXISTS" : The entity that a client attempted to create (e.g.,
  /// file or directory) already exists. HTTP Mapping: 409 Conflict
  /// - "PERMISSION_DENIED" : The caller does not have permission to execute the
  /// specified operation. `PERMISSION_DENIED` must not be used for rejections
  /// caused by exhausting some resource (use `RESOURCE_EXHAUSTED` instead for
  /// those errors). `PERMISSION_DENIED` must not be used if the caller can not
  /// be identified (use `UNAUTHENTICATED` instead for those errors). This error
  /// code does not imply the request is valid or the requested entity exists or
  /// satisfies other pre-conditions. HTTP Mapping: 403 Forbidden
  /// - "UNAUTHENTICATED" : The request does not have valid authentication
  /// credentials for the operation. HTTP Mapping: 401 Unauthorized
  /// - "RESOURCE_EXHAUSTED" : Some resource has been exhausted, perhaps a
  /// per-user quota, or perhaps the entire file system is out of space. HTTP
  /// Mapping: 429 Too Many Requests
  /// - "FAILED_PRECONDITION" : The operation was rejected because the system is
  /// not in a state required for the operation's execution. For example, the
  /// directory to be deleted is non-empty, an rmdir operation is applied to a
  /// non-directory, etc. Service implementors can use the following guidelines
  /// to decide between `FAILED_PRECONDITION`, `ABORTED`, and `UNAVAILABLE`: (a)
  /// Use `UNAVAILABLE` if the client can retry just the failing call. (b) Use
  /// `ABORTED` if the client should retry at a higher level. For example, when
  /// a client-specified test-and-set fails, indicating the client should
  /// restart a read-modify-write sequence. (c) Use `FAILED_PRECONDITION` if the
  /// client should not retry until the system state has been explicitly fixed.
  /// For example, if an "rmdir" fails because the directory is non-empty,
  /// `FAILED_PRECONDITION` should be returned since the client should not retry
  /// unless the files are deleted from the directory. HTTP Mapping: 400 Bad
  /// Request
  /// - "ABORTED" : The operation was aborted, typically due to a concurrency
  /// issue such as a sequencer check failure or transaction abort. See the
  /// guidelines above for deciding between `FAILED_PRECONDITION`, `ABORTED`,
  /// and `UNAVAILABLE`. HTTP Mapping: 409 Conflict
  /// - "OUT_OF_RANGE" : The operation was attempted past the valid range. E.g.,
  /// seeking or reading past end-of-file. Unlike `INVALID_ARGUMENT`, this error
  /// indicates a problem that may be fixed if the system state changes. For
  /// example, a 32-bit file system will generate `INVALID_ARGUMENT` if asked to
  /// read at an offset that is not in the range \[0,2^32-1\], but it will
  /// generate `OUT_OF_RANGE` if asked to read from an offset past the current
  /// file size. There is a fair bit of overlap between `FAILED_PRECONDITION`
  /// and `OUT_OF_RANGE`. We recommend using `OUT_OF_RANGE` (the more specific
  /// error) when it applies so that callers who are iterating through a space
  /// can easily look for an `OUT_OF_RANGE` error to detect when they are done.
  /// HTTP Mapping: 400 Bad Request
  /// - "UNIMPLEMENTED" : The operation is not implemented or is not
  /// supported/enabled in this service. HTTP Mapping: 501 Not Implemented
  /// - "INTERNAL" : Internal errors. This means that some invariants expected
  /// by the underlying system have been broken. This error code is reserved for
  /// serious errors. HTTP Mapping: 500 Internal Server Error
  /// - "UNAVAILABLE" : The service is currently unavailable. This is most
  /// likely a transient condition, which can be corrected by retrying with a
  /// backoff. Note that it is not always safe to retry non-idempotent
  /// operations. See the guidelines above for deciding between
  /// `FAILED_PRECONDITION`, `ABORTED`, and `UNAVAILABLE`. HTTP Mapping: 503
  /// Service Unavailable
  /// - "DATA_LOSS" : Unrecoverable data loss or corruption. HTTP Mapping: 500
  /// Internal Server Error
  core.String? errorCode;

  /// Failure reason message.
  core.String? errorMessage;

  /// Failed printer.
  Printer? printer;

  /// Id of a failed printer.
  core.String? printerId;

  FailureInfo();

  FailureInfo.fromJson(core.Map _json) {
    if (_json.containsKey('errorCode')) {
      errorCode = _json['errorCode'] as core.String;
    }
    if (_json.containsKey('errorMessage')) {
      errorMessage = _json['errorMessage'] as core.String;
    }
    if (_json.containsKey('printer')) {
      printer = Printer.fromJson(
          _json['printer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('printerId')) {
      printerId = _json['printerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorCode != null) 'errorCode': errorCode!,
        if (errorMessage != null) 'errorMessage': errorMessage!,
        if (printer != null) 'printer': printer!.toJson(),
        if (printerId != null) 'printerId': printerId!,
      };
}

/// JSON template for Feature object in Directory API.
class Feature {
  /// ETag of the resource.
  core.String? etags;

  /// Kind of resource this is.
  core.String? kind;

  /// The name of the feature.
  core.String? name;

  Feature();

  Feature.fromJson(core.Map _json) {
    if (_json.containsKey('etags')) {
      etags = _json['etags'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etags != null) 'etags': etags!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// JSON template for a feature instance.
class FeatureInstance {
  /// The feature that this is an instance of.
  ///
  /// A calendar resource may have multiple instances of a feature.
  Feature? feature;

  FeatureInstance();

  FeatureInstance.fromJson(core.Map _json) {
    if (_json.containsKey('feature')) {
      feature = Feature.fromJson(
          _json['feature'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (feature != null) 'feature': feature!.toJson(),
      };
}

class FeatureRename {
  /// New name of the feature.
  core.String? newName;

  FeatureRename();

  FeatureRename.fromJson(core.Map _json) {
    if (_json.containsKey('newName')) {
      newName = _json['newName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (newName != null) 'newName': newName!,
      };
}

/// Public API: Resources.features
class Features {
  /// ETag of the resource.
  core.String? etag;

  /// The Features in this page of results.
  core.List<Feature>? features;

  /// Kind of resource this is.
  core.String? kind;

  /// The continuation token, used to page through large result sets.
  ///
  /// Provide this value in a subsequent request to return the next page of
  /// results.
  core.String? nextPageToken;

  Features();

  Features.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('features')) {
      features = (_json['features'] as core.List)
          .map<Feature>((value) =>
              Feature.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (features != null)
          'features': features!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Google Groups provide your users the ability to send messages to groups of
/// people using the group's email address.
///
/// For more information about common tasks, see the \[Developer's
/// Guide\](/admin-sdk/directory/v1/guides/manage-groups).
class Group {
  /// Value is `true` if this group was created by an administrator rather than
  /// a user.
  core.bool? adminCreated;

  /// List of a group's alias email addresses.
  core.List<core.String>? aliases;

  /// An extended description to help users determine the purpose of a group.
  ///
  /// For example, you can include information about who should join the group,
  /// the types of messages to send to the group, links to FAQs about the group,
  /// or related groups. Maximum length is `4,096` characters.
  core.String? description;

  /// The number of users that are direct members of the group.
  ///
  /// If a group is a member (child) of this group (the parent), members of the
  /// child group are not counted in the `directMembersCount` property of the
  /// parent group.
  core.String? directMembersCount;

  /// The group's email address.
  ///
  /// If your account has multiple domains, select the appropriate domain for
  /// the email address. The `email` must be unique. This property is required
  /// when creating a group. Group email addresses are subject to the same
  /// character usage rules as usernames, see the
  /// [help center](https://support.google.com/a/answer/9193374) for details.
  core.String? email;

  /// ETag of the resource.
  core.String? etag;

  /// The unique ID of a group.
  ///
  /// A group `id` can be used as a group request URI's `groupKey`.
  core.String? id;

  /// The type of the API resource.
  ///
  /// For Groups resources, the value is `admin#directory#group`.
  core.String? kind;

  /// The group's display name.
  core.String? name;

  /// List of the group's non-editable alias email addresses that are outside of
  /// the account's primary domain or subdomains.
  ///
  /// These are functioning email addresses used by the group. This is a
  /// read-only property returned in the API's response for a group. If edited
  /// in a group's POST or PUT request, the edit is ignored by the API service.
  core.List<core.String>? nonEditableAliases;

  Group();

  Group.fromJson(core.Map _json) {
    if (_json.containsKey('adminCreated')) {
      adminCreated = _json['adminCreated'] as core.bool;
    }
    if (_json.containsKey('aliases')) {
      aliases = (_json['aliases'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('directMembersCount')) {
      directMembersCount = _json['directMembersCount'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
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
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nonEditableAliases')) {
      nonEditableAliases = (_json['nonEditableAliases'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adminCreated != null) 'adminCreated': adminCreated!,
        if (aliases != null) 'aliases': aliases!,
        if (description != null) 'description': description!,
        if (directMembersCount != null)
          'directMembersCount': directMembersCount!,
        if (email != null) 'email': email!,
        if (etag != null) 'etag': etag!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (nonEditableAliases != null)
          'nonEditableAliases': nonEditableAliases!,
      };
}

class Groups {
  /// ETag of the resource.
  core.String? etag;

  /// List of group objects.
  core.List<Group>? groups;

  /// Kind of resource this is.
  core.String? kind;

  /// Token used to access next page of this result.
  core.String? nextPageToken;

  Groups();

  Groups.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('groups')) {
      groups = (_json['groups'] as core.List)
          .map<Group>((value) =>
              Group.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (groups != null)
          'groups': groups!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response for listing allowed printer models.
class ListPrinterModelsResponse {
  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// Printer models that are currently allowed to be configured for ChromeOs.
  ///
  /// Some printers may be added or removed over time.
  core.List<PrinterModel>? printerModels;

  ListPrinterModelsResponse();

  ListPrinterModelsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('printerModels')) {
      printerModels = (_json['printerModels'] as core.List)
          .map<PrinterModel>((value) => PrinterModel.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (printerModels != null)
          'printerModels':
              printerModels!.map((value) => value.toJson()).toList(),
      };
}

/// Response for listing printers.
class ListPrintersResponse {
  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// List of printers.
  ///
  /// If `org_unit_id` was given in the request, then only printers visible for
  /// this OU will be returned. If `org_unit_id` was given in the request, then
  /// all printers will be returned.
  core.List<Printer>? printers;

  ListPrintersResponse();

  ListPrintersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('printers')) {
      printers = (_json['printers'] as core.List)
          .map<Printer>((value) =>
              Printer.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (printers != null)
          'printers': printers!.map((value) => value.toJson()).toList(),
      };
}

/// A Google Groups member can be a user or another group.
///
/// This member can be inside or outside of your account's domains. For more
/// information about common group member tasks, see the \[Developer's
/// Guide\](/admin-sdk/directory/v1/guides/manage-group-members).
class Member {
  /// Defines mail delivery preferences of member.
  ///
  /// This is only supported by create/update/get.
  core.String? deliverySettings;

  /// The member's email address.
  ///
  /// A member can be a user or another group. This property is required when
  /// adding a member to a group. The `email` must be unique and cannot be an
  /// alias of another group. If the email address is changed, the API
  /// automatically reflects the email address changes.
  core.String? email;

  /// ETag of the resource.
  core.String? etag;

  /// The unique ID of the group member.
  ///
  /// A member `id` can be used as a member request URI's `memberKey`.
  core.String? id;

  /// The type of the API resource.
  ///
  /// For Members resources, the value is `admin#directory#member`.
  core.String? kind;

  /// The member's role in a group.
  ///
  /// The API returns an error for cycles in group memberships. For example, if
  /// `group1` is a member of `group2`, `group2` cannot be a member of `group1`.
  /// For more information about a member's role, see the
  /// [administration help center](https://support.google.com/a/answer/167094).
  core.String? role;

  /// Status of member (Immutable)
  core.String? status;

  /// The type of group member.
  core.String? type;

  Member();

  Member.fromJson(core.Map _json) {
    if (_json.containsKey('delivery_settings')) {
      deliverySettings = _json['delivery_settings'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
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
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deliverySettings != null) 'delivery_settings': deliverySettings!,
        if (email != null) 'email': email!,
        if (etag != null) 'etag': etag!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (role != null) 'role': role!,
        if (status != null) 'status': status!,
        if (type != null) 'type': type!,
      };
}

class Members {
  /// ETag of the resource.
  core.String? etag;

  /// Kind of resource this is.
  core.String? kind;

  /// List of member objects.
  core.List<Member>? members;

  /// Token used to access next page of this result.
  core.String? nextPageToken;

  Members();

  Members.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('members')) {
      members = (_json['members'] as core.List)
          .map<Member>((value) =>
              Member.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (members != null)
          'members': members!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// JSON template for Has Member response in Directory API.
class MembersHasMember {
  /// Identifies whether the given user is a member of the group.
  ///
  /// Membership can be direct or nested.
  ///
  /// Output only.
  core.bool? isMember;

  MembersHasMember();

  MembersHasMember.fromJson(core.Map _json) {
    if (_json.containsKey('isMember')) {
      isMember = _json['isMember'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (isMember != null) 'isMember': isMember!,
      };
}

class MobileDeviceApplications {
  /// The application's display name.
  ///
  /// An example is `Browser`.
  core.String? displayName;

  /// The application's package name.
  ///
  /// An example is `com.android.browser`.
  core.String? packageName;

  /// The list of permissions of this application.
  ///
  /// These can be either a standard Android permission or one defined by the
  /// application, and are found in an application's
  /// [Android manifest](https://developer.android.com/guide/topics/manifest/uses-permission-element.html).
  /// Examples of a Calendar application's permissions are `READ_CALENDAR`, or
  /// `MANAGE_ACCOUNTS`.
  core.List<core.String>? permission;

  /// The application's version code.
  ///
  /// An example is `13`.
  core.int? versionCode;

  /// The application's version name.
  ///
  /// An example is `3.2-140714`.
  core.String? versionName;

  MobileDeviceApplications();

  MobileDeviceApplications.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
    if (_json.containsKey('permission')) {
      permission = (_json['permission'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('versionCode')) {
      versionCode = _json['versionCode'] as core.int;
    }
    if (_json.containsKey('versionName')) {
      versionName = _json['versionName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (packageName != null) 'packageName': packageName!,
        if (permission != null) 'permission': permission!,
        if (versionCode != null) 'versionCode': versionCode!,
        if (versionName != null) 'versionName': versionName!,
      };
}

/// Google Workspace Mobile Management includes Android,
/// [Google Sync](https://support.google.com/a/answer/135937), and iOS devices.
///
/// For more information about common group mobile device API tasks, see the
/// \[Developer's
/// Guide\](/admin-sdk/directory/v1/guides/manage-mobile-devices.html).
class MobileDevice {
  /// Adb (USB debugging) enabled or disabled on device (Read-only)
  core.bool? adbStatus;

  /// The list of applications installed on an Android mobile device.
  ///
  /// It is not applicable to Google Sync and iOS devices. The list includes any
  /// Android applications that access Google Workspace data. When updating an
  /// applications list, it is important to note that updates replace the
  /// existing list. If the Android device has two existing applications and the
  /// API updates the list with five applications, the is now the updated list
  /// of five applications.
  core.List<MobileDeviceApplications>? applications;

  /// The device's baseband version.
  core.String? basebandVersion;

  /// Mobile Device Bootloader version (Read-only)
  core.String? bootloaderVersion;

  /// Mobile Device Brand (Read-only)
  core.String? brand;

  /// The device's operating system build number.
  core.String? buildNumber;

  /// The default locale used on the device.
  core.String? defaultLanguage;

  /// Developer options enabled or disabled on device (Read-only)
  core.bool? developerOptionsStatus;

  /// The compromised device status.
  core.String? deviceCompromisedStatus;

  /// The serial number for a Google Sync mobile device.
  ///
  /// For Android and iOS devices, this is a software generated unique
  /// identifier.
  core.String? deviceId;

  /// DevicePasswordStatus (Read-only)
  core.String? devicePasswordStatus;

  /// List of owner's email addresses.
  ///
  /// If your application needs the current list of user emails, use the
  /// \[get\](/admin-sdk/directory/v1/reference/mobiledevices/get.html) method.
  /// For additional information, see the \[retrieve a
  /// user\](/admin-sdk/directory/v1/guides/manage-users#get_user) method.
  core.List<core.String>? email;

  /// Mobile Device Encryption Status (Read-only)
  core.String? encryptionStatus;

  /// ETag of the resource.
  core.String? etag;

  /// Date and time the device was first synchronized with the policy settings
  /// in the G Suite administrator control panel (Read-only)
  core.DateTime? firstSync;

  /// Mobile Device Hardware (Read-only)
  core.String? hardware;

  /// The IMEI/MEID unique identifier for Android hardware.
  ///
  /// It is not applicable to Google Sync devices. When adding an Android mobile
  /// device, this is an optional property. When updating one of these devices,
  /// this is a read-only property.
  core.String? hardwareId;

  /// The device's IMEI number.
  core.String? imei;

  /// The device's kernel version.
  core.String? kernelVersion;

  /// The type of the API resource.
  ///
  /// For Mobiledevices resources, the value is `admin#directory#mobiledevice`.
  core.String? kind;

  /// Date and time the device was last synchronized with the policy settings in
  /// the G Suite administrator control panel (Read-only)
  core.DateTime? lastSync;

  /// Boolean indicating if this account is on owner/primary profile or not.
  core.bool? managedAccountIsOnOwnerProfile;

  /// Mobile Device manufacturer (Read-only)
  core.String? manufacturer;

  /// The device's MEID number.
  core.String? meid;

  /// The mobile device's model name, for example Nexus S.
  ///
  /// This property can be
  /// \[updated\](/admin-sdk/directory/v1/reference/mobiledevices/update.html).
  /// For more information, see the \[Developer's
  /// Guide\](/admin-sdk/directory/v1/guides/manage-mobile=devices#update_mobile_device).
  core.String? model;

  /// List of the owner's user names.
  ///
  /// If your application needs the current list of device owner names, use the
  /// \[get\](/admin-sdk/directory/v1/reference/mobiledevices/get.html) method.
  /// For more information about retrieving mobile device user information, see
  /// the \[Developer's
  /// Guide\](/admin-sdk/directory/v1/guides/manage-users#get_user).
  core.List<core.String>? name;

  /// Mobile Device mobile or network operator (if available) (Read-only)
  core.String? networkOperator;

  /// The mobile device's operating system, for example IOS 4.3 or Android
  /// 2.3.5.
  ///
  /// This property can be
  /// \[updated\](/admin-sdk/directory/v1/reference/mobiledevices/update.html).
  /// For more information, see the \[Developer's
  /// Guide\](/admin-sdk/directory/v1/guides/manage-mobile-devices#update_mobile_device).
  core.String? os;

  /// List of accounts added on device (Read-only)
  core.List<core.String>? otherAccountsInfo;

  /// DMAgentPermission (Read-only)
  core.String? privilege;

  /// Mobile Device release version version (Read-only)
  core.String? releaseVersion;

  /// The unique ID the API service uses to identify the mobile device.
  core.String? resourceId;

  /// Mobile Device Security patch level (Read-only)
  core.String? securityPatchLevel;

  /// The device's serial number.
  core.String? serialNumber;

  /// The device's status.
  core.String? status;

  /// Work profile supported on device (Read-only)
  core.bool? supportsWorkProfile;

  /// The type of mobile device.
  core.String? type;

  /// Unknown sources enabled or disabled on device (Read-only)
  core.bool? unknownSourcesStatus;

  /// Gives information about the device such as `os` version.
  ///
  /// This property can be
  /// \[updated\](/admin-sdk/directory/v1/reference/mobiledevices/update.html).
  /// For more information, see the \[Developer's
  /// Guide\](/admin-sdk/directory/v1/guides/manage-mobile-devices#update_mobile_device).
  core.String? userAgent;

  /// The device's MAC address on Wi-Fi networks.
  core.String? wifiMacAddress;

  MobileDevice();

  MobileDevice.fromJson(core.Map _json) {
    if (_json.containsKey('adbStatus')) {
      adbStatus = _json['adbStatus'] as core.bool;
    }
    if (_json.containsKey('applications')) {
      applications = (_json['applications'] as core.List)
          .map<MobileDeviceApplications>((value) =>
              MobileDeviceApplications.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('basebandVersion')) {
      basebandVersion = _json['basebandVersion'] as core.String;
    }
    if (_json.containsKey('bootloaderVersion')) {
      bootloaderVersion = _json['bootloaderVersion'] as core.String;
    }
    if (_json.containsKey('brand')) {
      brand = _json['brand'] as core.String;
    }
    if (_json.containsKey('buildNumber')) {
      buildNumber = _json['buildNumber'] as core.String;
    }
    if (_json.containsKey('defaultLanguage')) {
      defaultLanguage = _json['defaultLanguage'] as core.String;
    }
    if (_json.containsKey('developerOptionsStatus')) {
      developerOptionsStatus = _json['developerOptionsStatus'] as core.bool;
    }
    if (_json.containsKey('deviceCompromisedStatus')) {
      deviceCompromisedStatus = _json['deviceCompromisedStatus'] as core.String;
    }
    if (_json.containsKey('deviceId')) {
      deviceId = _json['deviceId'] as core.String;
    }
    if (_json.containsKey('devicePasswordStatus')) {
      devicePasswordStatus = _json['devicePasswordStatus'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = (_json['email'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('encryptionStatus')) {
      encryptionStatus = _json['encryptionStatus'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('firstSync')) {
      firstSync = core.DateTime.parse(_json['firstSync'] as core.String);
    }
    if (_json.containsKey('hardware')) {
      hardware = _json['hardware'] as core.String;
    }
    if (_json.containsKey('hardwareId')) {
      hardwareId = _json['hardwareId'] as core.String;
    }
    if (_json.containsKey('imei')) {
      imei = _json['imei'] as core.String;
    }
    if (_json.containsKey('kernelVersion')) {
      kernelVersion = _json['kernelVersion'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastSync')) {
      lastSync = core.DateTime.parse(_json['lastSync'] as core.String);
    }
    if (_json.containsKey('managedAccountIsOnOwnerProfile')) {
      managedAccountIsOnOwnerProfile =
          _json['managedAccountIsOnOwnerProfile'] as core.bool;
    }
    if (_json.containsKey('manufacturer')) {
      manufacturer = _json['manufacturer'] as core.String;
    }
    if (_json.containsKey('meid')) {
      meid = _json['meid'] as core.String;
    }
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = (_json['name'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('networkOperator')) {
      networkOperator = _json['networkOperator'] as core.String;
    }
    if (_json.containsKey('os')) {
      os = _json['os'] as core.String;
    }
    if (_json.containsKey('otherAccountsInfo')) {
      otherAccountsInfo = (_json['otherAccountsInfo'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('privilege')) {
      privilege = _json['privilege'] as core.String;
    }
    if (_json.containsKey('releaseVersion')) {
      releaseVersion = _json['releaseVersion'] as core.String;
    }
    if (_json.containsKey('resourceId')) {
      resourceId = _json['resourceId'] as core.String;
    }
    if (_json.containsKey('securityPatchLevel')) {
      securityPatchLevel = _json['securityPatchLevel'] as core.String;
    }
    if (_json.containsKey('serialNumber')) {
      serialNumber = _json['serialNumber'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('supportsWorkProfile')) {
      supportsWorkProfile = _json['supportsWorkProfile'] as core.bool;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('unknownSourcesStatus')) {
      unknownSourcesStatus = _json['unknownSourcesStatus'] as core.bool;
    }
    if (_json.containsKey('userAgent')) {
      userAgent = _json['userAgent'] as core.String;
    }
    if (_json.containsKey('wifiMacAddress')) {
      wifiMacAddress = _json['wifiMacAddress'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adbStatus != null) 'adbStatus': adbStatus!,
        if (applications != null)
          'applications': applications!.map((value) => value.toJson()).toList(),
        if (basebandVersion != null) 'basebandVersion': basebandVersion!,
        if (bootloaderVersion != null) 'bootloaderVersion': bootloaderVersion!,
        if (brand != null) 'brand': brand!,
        if (buildNumber != null) 'buildNumber': buildNumber!,
        if (defaultLanguage != null) 'defaultLanguage': defaultLanguage!,
        if (developerOptionsStatus != null)
          'developerOptionsStatus': developerOptionsStatus!,
        if (deviceCompromisedStatus != null)
          'deviceCompromisedStatus': deviceCompromisedStatus!,
        if (deviceId != null) 'deviceId': deviceId!,
        if (devicePasswordStatus != null)
          'devicePasswordStatus': devicePasswordStatus!,
        if (email != null) 'email': email!,
        if (encryptionStatus != null) 'encryptionStatus': encryptionStatus!,
        if (etag != null) 'etag': etag!,
        if (firstSync != null) 'firstSync': firstSync!.toIso8601String(),
        if (hardware != null) 'hardware': hardware!,
        if (hardwareId != null) 'hardwareId': hardwareId!,
        if (imei != null) 'imei': imei!,
        if (kernelVersion != null) 'kernelVersion': kernelVersion!,
        if (kind != null) 'kind': kind!,
        if (lastSync != null) 'lastSync': lastSync!.toIso8601String(),
        if (managedAccountIsOnOwnerProfile != null)
          'managedAccountIsOnOwnerProfile': managedAccountIsOnOwnerProfile!,
        if (manufacturer != null) 'manufacturer': manufacturer!,
        if (meid != null) 'meid': meid!,
        if (model != null) 'model': model!,
        if (name != null) 'name': name!,
        if (networkOperator != null) 'networkOperator': networkOperator!,
        if (os != null) 'os': os!,
        if (otherAccountsInfo != null) 'otherAccountsInfo': otherAccountsInfo!,
        if (privilege != null) 'privilege': privilege!,
        if (releaseVersion != null) 'releaseVersion': releaseVersion!,
        if (resourceId != null) 'resourceId': resourceId!,
        if (securityPatchLevel != null)
          'securityPatchLevel': securityPatchLevel!,
        if (serialNumber != null) 'serialNumber': serialNumber!,
        if (status != null) 'status': status!,
        if (supportsWorkProfile != null)
          'supportsWorkProfile': supportsWorkProfile!,
        if (type != null) 'type': type!,
        if (unknownSourcesStatus != null)
          'unknownSourcesStatus': unknownSourcesStatus!,
        if (userAgent != null) 'userAgent': userAgent!,
        if (wifiMacAddress != null) 'wifiMacAddress': wifiMacAddress!,
      };
}

class MobileDeviceAction {
  /// The action to be performed on the device.
  core.String? action;

  MobileDeviceAction();

  MobileDeviceAction.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
      };
}

class MobileDevices {
  /// ETag of the resource.
  core.String? etag;

  /// Kind of resource this is.
  core.String? kind;

  /// List of Mobile Device objects.
  core.List<MobileDevice>? mobiledevices;

  /// Token used to access next page of this result.
  core.String? nextPageToken;

  MobileDevices();

  MobileDevices.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('mobiledevices')) {
      mobiledevices = (_json['mobiledevices'] as core.List)
          .map<MobileDevice>((value) => MobileDevice.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (mobiledevices != null)
          'mobiledevices':
              mobiledevices!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Managing your account's organizational units allows you to configure your
/// users' access to services and custom settings.
///
/// For more information about common organizational unit tasks, see the
/// \[Developer's Guide\](/admin-sdk/directory/v1/guides/manage-org-units.html).
class OrgUnit {
  /// Determines if a sub-organizational unit can inherit the settings of the
  /// parent organization.
  ///
  /// The default value is `false`, meaning a sub-organizational unit inherits
  /// the settings of the nearest parent organizational unit. For more
  /// information on inheritance and users in an organization structure, see the
  /// [administration help center](https://support.google.com/a/answer/4352075).
  core.bool? blockInheritance;

  /// Description of the organizational unit.
  core.String? description;

  /// ETag of the resource.
  core.String? etag;

  /// The type of the API resource.
  ///
  /// For Orgunits resources, the value is `admin#directory#orgUnit`.
  core.String? kind;

  /// The organizational unit's path name.
  ///
  /// For example, an organizational unit's name within the
  /// /corp/support/sales_support parent path is sales_support. Required.
  core.String? name;

  /// The unique ID of the organizational unit.
  core.String? orgUnitId;

  /// The full path to the organizational unit.
  ///
  /// The `orgUnitPath` is a derived property. When listed, it is derived from
  /// `parentOrgunitPath` and organizational unit's `name`. For example, for an
  /// organizational unit named 'apps' under parent organization '/engineering',
  /// the orgUnitPath is '/engineering/apps'. In order to edit an `orgUnitPath`,
  /// either update the name of the organization or the `parentOrgunitPath`. A
  /// user's organizational unit determines which Google Workspace services the
  /// user has access to. If the user is moved to a new organization, the user's
  /// access changes. For more information about organization structures, see
  /// the
  /// [administration help center](https://support.google.com/a/answer/4352075).
  /// For more information about moving a user to a different organization, see
  /// \[Update a
  /// user\](/admin-sdk/directory/v1/guides/manage-users.html#update_user).
  core.String? orgUnitPath;

  /// The unique ID of the parent organizational unit.
  ///
  /// Required, unless `parentOrgUnitPath` is set.
  core.String? parentOrgUnitId;

  /// The organizational unit's parent path.
  ///
  /// For example, /corp/sales is the parent path for /corp/sales/sales_support
  /// organizational unit. Required, unless `parentOrgUnitId` is set.
  core.String? parentOrgUnitPath;

  OrgUnit();

  OrgUnit.fromJson(core.Map _json) {
    if (_json.containsKey('blockInheritance')) {
      blockInheritance = _json['blockInheritance'] as core.bool;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('orgUnitId')) {
      orgUnitId = _json['orgUnitId'] as core.String;
    }
    if (_json.containsKey('orgUnitPath')) {
      orgUnitPath = _json['orgUnitPath'] as core.String;
    }
    if (_json.containsKey('parentOrgUnitId')) {
      parentOrgUnitId = _json['parentOrgUnitId'] as core.String;
    }
    if (_json.containsKey('parentOrgUnitPath')) {
      parentOrgUnitPath = _json['parentOrgUnitPath'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (blockInheritance != null) 'blockInheritance': blockInheritance!,
        if (description != null) 'description': description!,
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (orgUnitId != null) 'orgUnitId': orgUnitId!,
        if (orgUnitPath != null) 'orgUnitPath': orgUnitPath!,
        if (parentOrgUnitId != null) 'parentOrgUnitId': parentOrgUnitId!,
        if (parentOrgUnitPath != null) 'parentOrgUnitPath': parentOrgUnitPath!,
      };
}

class OrgUnits {
  /// ETag of the resource.
  core.String? etag;

  /// The type of the API resource.
  ///
  /// For Org Unit resources, the type is `admin#directory#orgUnits`.
  core.String? kind;

  /// List of organizational unit objects.
  core.List<OrgUnit>? organizationUnits;

  OrgUnits();

  OrgUnits.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('organizationUnits')) {
      organizationUnits = (_json['organizationUnits'] as core.List)
          .map<OrgUnit>((value) =>
              OrgUnit.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (organizationUnits != null)
          'organizationUnits':
              organizationUnits!.map((value) => value.toJson()).toList(),
      };
}

/// Printer configuration.
class Printer {
  /// Auxiliary messages about issues with the printer configuration if any.
  ///
  /// Output only.
  core.List<AuxiliaryMessage>? auxiliaryMessages;

  /// Time when printer was created.
  ///
  /// Output only.
  core.String? createTime;

  /// Editable.
  ///
  /// Description of printer.
  core.String? description;

  /// Editable.
  ///
  /// Name of printer.
  core.String? displayName;

  /// Id of the printer.
  ///
  /// (During printer creation leave empty)
  core.String? id;

  /// Editable.
  ///
  /// Make and model of printer. e.g. Lexmark MS610de Value must be in format as
  /// seen in ListPrinterModels response.
  core.String? makeAndModel;

  /// The resource name of the Printer object, in the format
  /// customers/{customer-id}/printers/{printer-id} (During printer creation
  /// leave empty)
  core.String? name;

  /// Organization Unit that owns this printer (Only can be set during Printer
  /// creation)
  core.String? orgUnitId;

  /// Editable.
  ///
  /// Printer URI.
  core.String? uri;

  /// Editable.
  ///
  /// flag to use driverless configuration or not. If it's set to be true,
  /// make_and_model can be ignored
  core.bool? useDriverlessConfig;

  Printer();

  Printer.fromJson(core.Map _json) {
    if (_json.containsKey('auxiliaryMessages')) {
      auxiliaryMessages = (_json['auxiliaryMessages'] as core.List)
          .map<AuxiliaryMessage>((value) => AuxiliaryMessage.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('makeAndModel')) {
      makeAndModel = _json['makeAndModel'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('orgUnitId')) {
      orgUnitId = _json['orgUnitId'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
    if (_json.containsKey('useDriverlessConfig')) {
      useDriverlessConfig = _json['useDriverlessConfig'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auxiliaryMessages != null)
          'auxiliaryMessages':
              auxiliaryMessages!.map((value) => value.toJson()).toList(),
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (id != null) 'id': id!,
        if (makeAndModel != null) 'makeAndModel': makeAndModel!,
        if (name != null) 'name': name!,
        if (orgUnitId != null) 'orgUnitId': orgUnitId!,
        if (uri != null) 'uri': uri!,
        if (useDriverlessConfig != null)
          'useDriverlessConfig': useDriverlessConfig!,
      };
}

/// Printer manufacturer and model
class PrinterModel {
  /// Display name.
  ///
  /// eq. "Brother MFC-8840D"
  core.String? displayName;

  /// Make and model as represented in "make_and_model" field in Printer object.
  ///
  /// eq. "brother mfc-8840d"
  core.String? makeAndModel;

  /// Manufacturer.
  ///
  /// eq. "Brother"
  core.String? manufacturer;

  PrinterModel();

  PrinterModel.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('makeAndModel')) {
      makeAndModel = _json['makeAndModel'] as core.String;
    }
    if (_json.containsKey('manufacturer')) {
      manufacturer = _json['manufacturer'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (makeAndModel != null) 'makeAndModel': makeAndModel!,
        if (manufacturer != null) 'manufacturer': manufacturer!,
      };
}

class Privilege {
  /// A list of child privileges.
  ///
  /// Privileges for a service form a tree. Each privilege can have a list of
  /// child privileges; this list is empty for a leaf privilege.
  core.List<Privilege>? childPrivileges;

  /// ETag of the resource.
  core.String? etag;

  /// If the privilege can be restricted to an organization unit.
  core.bool? isOuScopable;

  /// The type of the API resource.
  ///
  /// This is always `admin#directory#privilege`.
  core.String? kind;

  /// The name of the privilege.
  core.String? privilegeName;

  /// The obfuscated ID of the service this privilege is for.
  ///
  /// This value is returned with
  /// \[`Privileges.list()`\](/admin-sdk/directory/v1/reference/privileges/list).
  core.String? serviceId;

  /// The name of the service this privilege is for.
  core.String? serviceName;

  Privilege();

  Privilege.fromJson(core.Map _json) {
    if (_json.containsKey('childPrivileges')) {
      childPrivileges = (_json['childPrivileges'] as core.List)
          .map<Privilege>((value) =>
              Privilege.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('isOuScopable')) {
      isOuScopable = _json['isOuScopable'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('privilegeName')) {
      privilegeName = _json['privilegeName'] as core.String;
    }
    if (_json.containsKey('serviceId')) {
      serviceId = _json['serviceId'] as core.String;
    }
    if (_json.containsKey('serviceName')) {
      serviceName = _json['serviceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (childPrivileges != null)
          'childPrivileges':
              childPrivileges!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (isOuScopable != null) 'isOuScopable': isOuScopable!,
        if (kind != null) 'kind': kind!,
        if (privilegeName != null) 'privilegeName': privilegeName!,
        if (serviceId != null) 'serviceId': serviceId!,
        if (serviceName != null) 'serviceName': serviceName!,
      };
}

class Privileges {
  /// ETag of the resource.
  core.String? etag;

  /// A list of Privilege resources.
  core.List<Privilege>? items;

  /// The type of the API resource.
  ///
  /// This is always `admin#directory#privileges`.
  core.String? kind;

  Privileges();

  Privileges.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Privilege>((value) =>
              Privilege.fromJson(value as core.Map<core.String, core.dynamic>))
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

class RoleRolePrivileges {
  /// The name of the privilege.
  core.String? privilegeName;

  /// The obfuscated ID of the service this privilege is for.
  ///
  /// This value is returned with
  /// \[`Privileges.list()`\](/admin-sdk/directory/v1/reference/privileges/list).
  core.String? serviceId;

  RoleRolePrivileges();

  RoleRolePrivileges.fromJson(core.Map _json) {
    if (_json.containsKey('privilegeName')) {
      privilegeName = _json['privilegeName'] as core.String;
    }
    if (_json.containsKey('serviceId')) {
      serviceId = _json['serviceId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (privilegeName != null) 'privilegeName': privilegeName!,
        if (serviceId != null) 'serviceId': serviceId!,
      };
}

class Role {
  /// ETag of the resource.
  core.String? etag;

  /// Returns `true` if the role is a super admin role.
  core.bool? isSuperAdminRole;

  /// Returns `true` if this is a pre-defined system role.
  core.bool? isSystemRole;

  /// The type of the API resource.
  ///
  /// This is always `admin#directory#role`.
  core.String? kind;

  /// A short description of the role.
  core.String? roleDescription;

  /// ID of the role.
  core.String? roleId;

  /// Name of the role.
  core.String? roleName;

  /// The set of privileges that are granted to this role.
  core.List<RoleRolePrivileges>? rolePrivileges;

  Role();

  Role.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('isSuperAdminRole')) {
      isSuperAdminRole = _json['isSuperAdminRole'] as core.bool;
    }
    if (_json.containsKey('isSystemRole')) {
      isSystemRole = _json['isSystemRole'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('roleDescription')) {
      roleDescription = _json['roleDescription'] as core.String;
    }
    if (_json.containsKey('roleId')) {
      roleId = _json['roleId'] as core.String;
    }
    if (_json.containsKey('roleName')) {
      roleName = _json['roleName'] as core.String;
    }
    if (_json.containsKey('rolePrivileges')) {
      rolePrivileges = (_json['rolePrivileges'] as core.List)
          .map<RoleRolePrivileges>((value) => RoleRolePrivileges.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (isSuperAdminRole != null) 'isSuperAdminRole': isSuperAdminRole!,
        if (isSystemRole != null) 'isSystemRole': isSystemRole!,
        if (kind != null) 'kind': kind!,
        if (roleDescription != null) 'roleDescription': roleDescription!,
        if (roleId != null) 'roleId': roleId!,
        if (roleName != null) 'roleName': roleName!,
        if (rolePrivileges != null)
          'rolePrivileges':
              rolePrivileges!.map((value) => value.toJson()).toList(),
      };
}

/// Defines an assignment of a role.
class RoleAssignment {
  /// The unique ID of the user this role is assigned to.
  core.String? assignedTo;

  /// ETag of the resource.
  core.String? etag;

  /// The type of the API resource.
  ///
  /// This is always `admin#directory#roleAssignment`.
  core.String? kind;

  /// If the role is restricted to an organization unit, this contains the ID
  /// for the organization unit the exercise of this role is restricted to.
  core.String? orgUnitId;

  /// ID of this roleAssignment.
  core.String? roleAssignmentId;

  /// The ID of the role that is assigned.
  core.String? roleId;

  /// The scope in which this role is assigned.
  core.String? scopeType;

  RoleAssignment();

  RoleAssignment.fromJson(core.Map _json) {
    if (_json.containsKey('assignedTo')) {
      assignedTo = _json['assignedTo'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('orgUnitId')) {
      orgUnitId = _json['orgUnitId'] as core.String;
    }
    if (_json.containsKey('roleAssignmentId')) {
      roleAssignmentId = _json['roleAssignmentId'] as core.String;
    }
    if (_json.containsKey('roleId')) {
      roleId = _json['roleId'] as core.String;
    }
    if (_json.containsKey('scopeType')) {
      scopeType = _json['scopeType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedTo != null) 'assignedTo': assignedTo!,
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (orgUnitId != null) 'orgUnitId': orgUnitId!,
        if (roleAssignmentId != null) 'roleAssignmentId': roleAssignmentId!,
        if (roleId != null) 'roleId': roleId!,
        if (scopeType != null) 'scopeType': scopeType!,
      };
}

class RoleAssignments {
  /// ETag of the resource.
  core.String? etag;

  /// A list of RoleAssignment resources.
  core.List<RoleAssignment>? items;

  /// The type of the API resource.
  ///
  /// This is always `admin#directory#roleAssignments`.
  core.String? kind;
  core.String? nextPageToken;

  RoleAssignments();

  RoleAssignments.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<RoleAssignment>((value) => RoleAssignment.fromJson(
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

class Roles {
  /// ETag of the resource.
  core.String? etag;

  /// A list of Role resources.
  core.List<Role>? items;

  /// The type of the API resource.
  ///
  /// This is always `admin#directory#roles`.
  core.String? kind;
  core.String? nextPageToken;

  Roles();

  Roles.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Role>((value) =>
              Role.fromJson(value as core.Map<core.String, core.dynamic>))
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

/// The type of API resource.
///
/// For Schema resources, this is always `admin#directory#schema`.
class Schema {
  /// Display name for the schema.
  core.String? displayName;

  /// The ETag of the resource.
  core.String? etag;

  /// A list of fields in the schema.
  core.List<SchemaFieldSpec>? fields;

  /// Kind of resource this is.
  core.String? kind;

  /// The unique identifier of the schema (Read-only)
  core.String? schemaId;

  /// The schema's name.
  core.String? schemaName;

  Schema();

  Schema.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('fields')) {
      fields = (_json['fields'] as core.List)
          .map<SchemaFieldSpec>((value) => SchemaFieldSpec.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('schemaId')) {
      schemaId = _json['schemaId'] as core.String;
    }
    if (_json.containsKey('schemaName')) {
      schemaName = _json['schemaName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (etag != null) 'etag': etag!,
        if (fields != null)
          'fields': fields!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (schemaId != null) 'schemaId': schemaId!,
        if (schemaName != null) 'schemaName': schemaName!,
      };
}

/// Indexing spec for a numeric field.
///
/// By default, only exact match queries will be supported for numeric fields.
/// Setting the `numericIndexingSpec` allows range queries to be supported.
class SchemaFieldSpecNumericIndexingSpec {
  /// Maximum value of this field.
  ///
  /// This is meant to be indicative rather than enforced. Values outside this
  /// range will still be indexed, but search may not be as performant.
  core.double? maxValue;

  /// Minimum value of this field.
  ///
  /// This is meant to be indicative rather than enforced. Values outside this
  /// range will still be indexed, but search may not be as performant.
  core.double? minValue;

  SchemaFieldSpecNumericIndexingSpec();

  SchemaFieldSpecNumericIndexingSpec.fromJson(core.Map _json) {
    if (_json.containsKey('maxValue')) {
      maxValue = (_json['maxValue'] as core.num).toDouble();
    }
    if (_json.containsKey('minValue')) {
      minValue = (_json['minValue'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maxValue != null) 'maxValue': maxValue!,
        if (minValue != null) 'minValue': minValue!,
      };
}

/// You can use schemas to add custom fields to user profiles.
///
/// You can use these fields to store information such as the projects your
/// users work on, their physical locations, their hire dates, or whatever else
/// fits your business needs. For more information, see \[Custom User
/// Fields\](/admin-sdk/directory/v1/guides/manage-schemas).
class SchemaFieldSpec {
  /// Display Name of the field.
  core.String? displayName;

  /// The ETag of the field.
  core.String? etag;

  /// The unique identifier of the field (Read-only)
  core.String? fieldId;

  /// The name of the field.
  core.String? fieldName;

  /// The type of the field.
  core.String? fieldType;

  /// Boolean specifying whether the field is indexed or not.
  ///
  /// Default: `true`.
  core.bool? indexed;

  /// The kind of resource this is.
  ///
  /// For schema fields this is always `admin#directory#schema#fieldspec`.
  core.String? kind;

  /// A boolean specifying whether this is a multi-valued field or not.
  ///
  /// Default: `false`.
  core.bool? multiValued;

  /// Indexing spec for a numeric field.
  ///
  /// By default, only exact match queries will be supported for numeric fields.
  /// Setting the `numericIndexingSpec` allows range queries to be supported.
  SchemaFieldSpecNumericIndexingSpec? numericIndexingSpec;

  /// Specifies who can view values of this field.
  ///
  /// See \[Retrieve users as a
  /// non-administrator\](/admin-sdk/directory/v1/guides/manage-users#retrieve_users_non_admin)
  /// for more information. Note: It may take up to 24 hours for changes to this
  /// field to be reflected.
  core.String? readAccessType;

  SchemaFieldSpec();

  SchemaFieldSpec.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('fieldId')) {
      fieldId = _json['fieldId'] as core.String;
    }
    if (_json.containsKey('fieldName')) {
      fieldName = _json['fieldName'] as core.String;
    }
    if (_json.containsKey('fieldType')) {
      fieldType = _json['fieldType'] as core.String;
    }
    if (_json.containsKey('indexed')) {
      indexed = _json['indexed'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('multiValued')) {
      multiValued = _json['multiValued'] as core.bool;
    }
    if (_json.containsKey('numericIndexingSpec')) {
      numericIndexingSpec = SchemaFieldSpecNumericIndexingSpec.fromJson(
          _json['numericIndexingSpec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('readAccessType')) {
      readAccessType = _json['readAccessType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (etag != null) 'etag': etag!,
        if (fieldId != null) 'fieldId': fieldId!,
        if (fieldName != null) 'fieldName': fieldName!,
        if (fieldType != null) 'fieldType': fieldType!,
        if (indexed != null) 'indexed': indexed!,
        if (kind != null) 'kind': kind!,
        if (multiValued != null) 'multiValued': multiValued!,
        if (numericIndexingSpec != null)
          'numericIndexingSpec': numericIndexingSpec!.toJson(),
        if (readAccessType != null) 'readAccessType': readAccessType!,
      };
}

/// JSON response template for List Schema operation in Directory API.
class Schemas {
  /// ETag of the resource.
  core.String? etag;

  /// Kind of resource this is.
  core.String? kind;

  /// List of UserSchema objects.
  core.List<Schema>? schemas;

  Schemas();

  Schemas.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('schemas')) {
      schemas = (_json['schemas'] as core.List)
          .map<Schema>((value) =>
              Schema.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (schemas != null)
          'schemas': schemas!.map((value) => value.toJson()).toList(),
      };
}

/// JSON template for token resource in Directory API.
class Token {
  /// Whether the application is registered with Google.
  ///
  /// The value is `true` if the application has an anonymous Client ID.
  core.bool? anonymous;

  /// The Client ID of the application the token is issued to.
  core.String? clientId;

  /// The displayable name of the application the token is issued to.
  core.String? displayText;

  /// ETag of the resource.
  core.String? etag;

  /// The type of the API resource.
  ///
  /// This is always `admin#directory#token`.
  core.String? kind;

  /// Whether the token is issued to an installed application.
  ///
  /// The value is `true` if the application is installed to a desktop or mobile
  /// device.
  core.bool? nativeApp;

  /// A list of authorization scopes the application is granted.
  core.List<core.String>? scopes;

  /// The unique ID of the user that issued the token.
  core.String? userKey;

  Token();

  Token.fromJson(core.Map _json) {
    if (_json.containsKey('anonymous')) {
      anonymous = _json['anonymous'] as core.bool;
    }
    if (_json.containsKey('clientId')) {
      clientId = _json['clientId'] as core.String;
    }
    if (_json.containsKey('displayText')) {
      displayText = _json['displayText'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nativeApp')) {
      nativeApp = _json['nativeApp'] as core.bool;
    }
    if (_json.containsKey('scopes')) {
      scopes = (_json['scopes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('userKey')) {
      userKey = _json['userKey'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (anonymous != null) 'anonymous': anonymous!,
        if (clientId != null) 'clientId': clientId!,
        if (displayText != null) 'displayText': displayText!,
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (nativeApp != null) 'nativeApp': nativeApp!,
        if (scopes != null) 'scopes': scopes!,
        if (userKey != null) 'userKey': userKey!,
      };
}

/// JSON response template for List tokens operation in Directory API.
class Tokens {
  /// ETag of the resource.
  core.String? etag;

  /// A list of Token resources.
  core.List<Token>? items;

  /// The type of the API resource.
  ///
  /// This is always `admin#directory#tokenList`.
  core.String? kind;

  Tokens();

  Tokens.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Token>((value) =>
              Token.fromJson(value as core.Map<core.String, core.dynamic>))
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

/// The Directory API allows you to create and manage your account's users, user
/// aliases, and user Gmail chat profile photos.
///
/// For more information about common tasks, see the \[User Accounts Developer's
/// Guide\](/admin-sdk/directory/v1/guides/manage-users.html) and the \[User
/// Aliases Developer's
/// Guide\](/admin-sdk/directory/v1/guides/manage-user-aliases.html).
class User {
  /// A list of the user's addresses.
  ///
  /// The maximum allowed data size for this field is 10Kb.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? addresses;

  /// This property is `true` if the user has completed an initial login and
  /// accepted the Terms of Service agreement.
  ///
  /// Output only.
  core.bool? agreedToTerms;

  /// List of the user's alias email addresses.
  ///
  /// Output only.
  core.List<core.String>? aliases;

  /// Indicates if user is archived.
  core.bool? archived;

  /// Indicates if the user is forced to change their password at next login.
  ///
  /// This setting doesn't apply when \[the user signs in via a third-party
  /// identity provider\](https://support.google.com/a/answer/60224).
  core.bool? changePasswordAtNextLogin;

  /// User's G Suite account creation time.
  ///
  /// (Read-only)
  core.DateTime? creationTime;

  /// Custom fields of the user.
  core.Map<core.String, UserCustomProperties>? customSchemas;

  /// The customer ID to \[retrieve all account
  /// users\](/admin-sdk/directory/v1/guides/manage-users.html#get_all_users).
  ///
  /// You can use the alias `my_customer` to represent your account's
  /// `customerId`. As a reseller administrator, you can use the resold customer
  /// account's `customerId`. To get a `customerId`, use the account's primary
  /// domain in the `domain` parameter of a
  /// \[users.list\](/admin-sdk/directory/v1/reference/users/list) request.
  ///
  /// Output only.
  core.String? customerId;
  core.DateTime? deletionTime;

  /// A list of the user's email addresses.
  ///
  /// The maximum allowed data size for this field is 10Kb.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? emails;

  /// ETag of the resource.
  ///
  /// Output only.
  core.String? etag;

  /// A list of external IDs for the user, such as an employee or network ID.
  ///
  /// The maximum allowed data size for this field is 2Kb.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? externalIds;

  /// The user's gender.
  ///
  /// The maximum allowed data size for this field is 1Kb.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? gender;

  /// Stores the hash format of the password property.
  ///
  /// We recommend sending the `password` property value as a base 16 bit
  /// hexadecimal-encoded hash value. Set the `hashFunction` values as either
  /// the \[SHA-1\](https://wikipedia.org/wiki/SHA-1),
  /// [MD5](https://wikipedia.org/wiki/MD5), or
  /// [crypt](https://en.wikipedia.org/wiki/Crypt_\(C\)) hash format.
  core.String? hashFunction;

  /// The unique ID for the user.
  ///
  /// A user `id` can be used as a user request URI's `userKey`.
  core.String? id;

  /// The user's Instant Messenger (IM) accounts.
  ///
  /// A user account can have multiple ims properties. But, only one of these
  /// ims properties can be the primary IM contact. The maximum allowed data
  /// size for this field is 2Kb.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? ims;

  /// Indicates if the user's profile is visible in the Google Workspace global
  /// address list when the contact sharing feature is enabled for the domain.
  ///
  /// For more information about excluding user profiles, see the
  /// [administration help center](https://support.google.com/a/answer/1285988).
  core.bool? includeInGlobalAddressList;

  /// If `true`, the user's IP address is
  /// [whitelisted](https://support.google.com/a/answer/60752).
  core.bool? ipWhitelisted;

  /// Indicates a user with super admininistrator privileges.
  ///
  /// The `isAdmin` property can only be edited in the \[Make a user an
  /// administrator\](/admin-sdk/directory/v1/guides/manage-users.html#make_admin)
  /// operation (
  /// \[makeAdmin\](/admin-sdk/directory/v1/reference/users/makeAdmin.html)
  /// method). If edited in the user
  /// \[insert\](/admin-sdk/directory/v1/reference/users/insert.html) or
  /// \[update\](/admin-sdk/directory/v1/reference/users/update.html) methods,
  /// the edit is ignored by the API service.
  ///
  /// Output only.
  core.bool? isAdmin;

  /// Indicates if the user is a delegated administrator.
  ///
  /// Delegated administrators are supported by the API but cannot create or
  /// undelete users, or make users administrators. These requests are ignored
  /// by the API service. Roles and privileges for administrators are assigned
  /// using the [Admin console](https://support.google.com/a/answer/33325).
  ///
  /// Output only.
  core.bool? isDelegatedAdmin;

  /// Is 2-step verification enforced (Read-only)
  ///
  /// Output only.
  core.bool? isEnforcedIn2Sv;

  /// Is enrolled in 2-step verification (Read-only)
  ///
  /// Output only.
  core.bool? isEnrolledIn2Sv;

  /// Indicates if the user's Google mailbox is created.
  ///
  /// This property is only applicable if the user has been assigned a Gmail
  /// license.
  ///
  /// Output only.
  core.bool? isMailboxSetup;

  /// The user's keywords.
  ///
  /// The maximum allowed data size for this field is 1Kb.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? keywords;

  /// The type of the API resource.
  ///
  /// For Users resources, the value is `admin#directory#user`.
  ///
  /// Output only.
  core.String? kind;

  /// The user's languages.
  ///
  /// The maximum allowed data size for this field is 1Kb.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? languages;

  /// User's last login time.
  ///
  /// (Read-only)
  core.DateTime? lastLoginTime;

  /// The user's locations.
  ///
  /// The maximum allowed data size for this field is 10Kb.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? locations;

  /// Holds the given and family names of the user, and the read-only `fullName`
  /// value.
  ///
  /// The maximum number of characters in the `givenName` and in the
  /// `familyName` values is 60. In addition, name values support unicode/UTF-8
  /// characters, and can contain spaces, letters (a-z), numbers (0-9), dashes
  /// (-), forward slashes (/), and periods (.). For more information about
  /// character usage rules, see the
  /// [administration help center](https://support.google.com/a/answer/9193374).
  /// Maximum allowed data size for this field is 1Kb.
  UserName? name;

  /// List of the user's non-editable alias email addresses.
  ///
  /// These are typically outside the account's primary domain or sub-domain.
  ///
  /// Output only.
  core.List<core.String>? nonEditableAliases;

  /// Notes for the user.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? notes;

  /// The full path of the parent organization associated with the user.
  ///
  /// If the parent organization is the top-level, it is represented as a
  /// forward slash (`/`).
  core.String? orgUnitPath;

  /// A list of organizations the user belongs to.
  ///
  /// The maximum allowed data size for this field is 10Kb.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? organizations;

  /// User's password
  core.String? password;

  /// A list of the user's phone numbers.
  ///
  /// The maximum allowed data size for this field is 1Kb.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? phones;

  /// A list of [POSIX](https://www.opengroup.org/austin/papers/posix_faq.html)
  /// account information for the user.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? posixAccounts;

  /// The user's primary email address.
  ///
  /// This property is required in a request to create a user account. The
  /// `primaryEmail` must be unique and cannot be an alias of another user.
  core.String? primaryEmail;

  /// Recovery email of the user.
  core.String? recoveryEmail;

  /// Recovery phone of the user.
  ///
  /// The phone number must be in the E.164 format, starting with the plus sign
  /// (+). Example: *+16506661212*.
  core.String? recoveryPhone;

  /// A list of the user's relationships to other users.
  ///
  /// The maximum allowed data size for this field is 2Kb.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? relations;

  /// A list of SSH public keys.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? sshPublicKeys;

  /// Indicates if user is suspended.
  core.bool? suspended;

  /// Has the reason a user account is suspended either by the administrator or
  /// by Google at the time of suspension.
  ///
  /// The property is returned only if the `suspended` property is `true`.
  ///
  /// Output only.
  core.String? suspensionReason;

  /// ETag of the user's photo (Read-only)
  ///
  /// Output only.
  core.String? thumbnailPhotoEtag;

  /// Photo Url of the user (Read-only)
  ///
  /// Output only.
  core.String? thumbnailPhotoUrl;

  /// The user's websites.
  ///
  /// The maximum allowed data size for this field is 2Kb.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? websites;

  User();

  User.fromJson(core.Map _json) {
    if (_json.containsKey('addresses')) {
      addresses = _json['addresses'] as core.Object;
    }
    if (_json.containsKey('agreedToTerms')) {
      agreedToTerms = _json['agreedToTerms'] as core.bool;
    }
    if (_json.containsKey('aliases')) {
      aliases = (_json['aliases'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('archived')) {
      archived = _json['archived'] as core.bool;
    }
    if (_json.containsKey('changePasswordAtNextLogin')) {
      changePasswordAtNextLogin =
          _json['changePasswordAtNextLogin'] as core.bool;
    }
    if (_json.containsKey('creationTime')) {
      creationTime = core.DateTime.parse(_json['creationTime'] as core.String);
    }
    if (_json.containsKey('customSchemas')) {
      customSchemas =
          (_json['customSchemas'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          UserCustomProperties.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('customerId')) {
      customerId = _json['customerId'] as core.String;
    }
    if (_json.containsKey('deletionTime')) {
      deletionTime = core.DateTime.parse(_json['deletionTime'] as core.String);
    }
    if (_json.containsKey('emails')) {
      emails = _json['emails'] as core.Object;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('externalIds')) {
      externalIds = _json['externalIds'] as core.Object;
    }
    if (_json.containsKey('gender')) {
      gender = _json['gender'] as core.Object;
    }
    if (_json.containsKey('hashFunction')) {
      hashFunction = _json['hashFunction'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('ims')) {
      ims = _json['ims'] as core.Object;
    }
    if (_json.containsKey('includeInGlobalAddressList')) {
      includeInGlobalAddressList =
          _json['includeInGlobalAddressList'] as core.bool;
    }
    if (_json.containsKey('ipWhitelisted')) {
      ipWhitelisted = _json['ipWhitelisted'] as core.bool;
    }
    if (_json.containsKey('isAdmin')) {
      isAdmin = _json['isAdmin'] as core.bool;
    }
    if (_json.containsKey('isDelegatedAdmin')) {
      isDelegatedAdmin = _json['isDelegatedAdmin'] as core.bool;
    }
    if (_json.containsKey('isEnforcedIn2Sv')) {
      isEnforcedIn2Sv = _json['isEnforcedIn2Sv'] as core.bool;
    }
    if (_json.containsKey('isEnrolledIn2Sv')) {
      isEnrolledIn2Sv = _json['isEnrolledIn2Sv'] as core.bool;
    }
    if (_json.containsKey('isMailboxSetup')) {
      isMailboxSetup = _json['isMailboxSetup'] as core.bool;
    }
    if (_json.containsKey('keywords')) {
      keywords = _json['keywords'] as core.Object;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('languages')) {
      languages = _json['languages'] as core.Object;
    }
    if (_json.containsKey('lastLoginTime')) {
      lastLoginTime =
          core.DateTime.parse(_json['lastLoginTime'] as core.String);
    }
    if (_json.containsKey('locations')) {
      locations = _json['locations'] as core.Object;
    }
    if (_json.containsKey('name')) {
      name = UserName.fromJson(
          _json['name'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nonEditableAliases')) {
      nonEditableAliases = (_json['nonEditableAliases'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('notes')) {
      notes = _json['notes'] as core.Object;
    }
    if (_json.containsKey('orgUnitPath')) {
      orgUnitPath = _json['orgUnitPath'] as core.String;
    }
    if (_json.containsKey('organizations')) {
      organizations = _json['organizations'] as core.Object;
    }
    if (_json.containsKey('password')) {
      password = _json['password'] as core.String;
    }
    if (_json.containsKey('phones')) {
      phones = _json['phones'] as core.Object;
    }
    if (_json.containsKey('posixAccounts')) {
      posixAccounts = _json['posixAccounts'] as core.Object;
    }
    if (_json.containsKey('primaryEmail')) {
      primaryEmail = _json['primaryEmail'] as core.String;
    }
    if (_json.containsKey('recoveryEmail')) {
      recoveryEmail = _json['recoveryEmail'] as core.String;
    }
    if (_json.containsKey('recoveryPhone')) {
      recoveryPhone = _json['recoveryPhone'] as core.String;
    }
    if (_json.containsKey('relations')) {
      relations = _json['relations'] as core.Object;
    }
    if (_json.containsKey('sshPublicKeys')) {
      sshPublicKeys = _json['sshPublicKeys'] as core.Object;
    }
    if (_json.containsKey('suspended')) {
      suspended = _json['suspended'] as core.bool;
    }
    if (_json.containsKey('suspensionReason')) {
      suspensionReason = _json['suspensionReason'] as core.String;
    }
    if (_json.containsKey('thumbnailPhotoEtag')) {
      thumbnailPhotoEtag = _json['thumbnailPhotoEtag'] as core.String;
    }
    if (_json.containsKey('thumbnailPhotoUrl')) {
      thumbnailPhotoUrl = _json['thumbnailPhotoUrl'] as core.String;
    }
    if (_json.containsKey('websites')) {
      websites = _json['websites'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (addresses != null) 'addresses': addresses!,
        if (agreedToTerms != null) 'agreedToTerms': agreedToTerms!,
        if (aliases != null) 'aliases': aliases!,
        if (archived != null) 'archived': archived!,
        if (changePasswordAtNextLogin != null)
          'changePasswordAtNextLogin': changePasswordAtNextLogin!,
        if (creationTime != null)
          'creationTime': creationTime!.toIso8601String(),
        if (customSchemas != null) 'customSchemas': customSchemas!,
        if (customerId != null) 'customerId': customerId!,
        if (deletionTime != null)
          'deletionTime': deletionTime!.toIso8601String(),
        if (emails != null) 'emails': emails!,
        if (etag != null) 'etag': etag!,
        if (externalIds != null) 'externalIds': externalIds!,
        if (gender != null) 'gender': gender!,
        if (hashFunction != null) 'hashFunction': hashFunction!,
        if (id != null) 'id': id!,
        if (ims != null) 'ims': ims!,
        if (includeInGlobalAddressList != null)
          'includeInGlobalAddressList': includeInGlobalAddressList!,
        if (ipWhitelisted != null) 'ipWhitelisted': ipWhitelisted!,
        if (isAdmin != null) 'isAdmin': isAdmin!,
        if (isDelegatedAdmin != null) 'isDelegatedAdmin': isDelegatedAdmin!,
        if (isEnforcedIn2Sv != null) 'isEnforcedIn2Sv': isEnforcedIn2Sv!,
        if (isEnrolledIn2Sv != null) 'isEnrolledIn2Sv': isEnrolledIn2Sv!,
        if (isMailboxSetup != null) 'isMailboxSetup': isMailboxSetup!,
        if (keywords != null) 'keywords': keywords!,
        if (kind != null) 'kind': kind!,
        if (languages != null) 'languages': languages!,
        if (lastLoginTime != null)
          'lastLoginTime': lastLoginTime!.toIso8601String(),
        if (locations != null) 'locations': locations!,
        if (name != null) 'name': name!.toJson(),
        if (nonEditableAliases != null)
          'nonEditableAliases': nonEditableAliases!,
        if (notes != null) 'notes': notes!,
        if (orgUnitPath != null) 'orgUnitPath': orgUnitPath!,
        if (organizations != null) 'organizations': organizations!,
        if (password != null) 'password': password!,
        if (phones != null) 'phones': phones!,
        if (posixAccounts != null) 'posixAccounts': posixAccounts!,
        if (primaryEmail != null) 'primaryEmail': primaryEmail!,
        if (recoveryEmail != null) 'recoveryEmail': recoveryEmail!,
        if (recoveryPhone != null) 'recoveryPhone': recoveryPhone!,
        if (relations != null) 'relations': relations!,
        if (sshPublicKeys != null) 'sshPublicKeys': sshPublicKeys!,
        if (suspended != null) 'suspended': suspended!,
        if (suspensionReason != null) 'suspensionReason': suspensionReason!,
        if (thumbnailPhotoEtag != null)
          'thumbnailPhotoEtag': thumbnailPhotoEtag!,
        if (thumbnailPhotoUrl != null) 'thumbnailPhotoUrl': thumbnailPhotoUrl!,
        if (websites != null) 'websites': websites!,
      };
}

/// JSON template for About (notes) of a user in Directory API.
class UserAbout {
  /// About entry can have a type which indicates the content type.
  ///
  /// It can either be plain or html. By default, notes contents are assumed to
  /// contain plain text.
  core.String? contentType;

  /// Actual value of notes.
  core.String? value;

  UserAbout();

  UserAbout.fromJson(core.Map _json) {
    if (_json.containsKey('contentType')) {
      contentType = _json['contentType'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentType != null) 'contentType': contentType!,
        if (value != null) 'value': value!,
      };
}

/// JSON template for address.
class UserAddress {
  /// Country.
  core.String? country;

  /// Country code.
  core.String? countryCode;

  /// Custom type.
  core.String? customType;

  /// Extended Address.
  core.String? extendedAddress;

  /// Formatted address.
  core.String? formatted;

  /// Locality.
  core.String? locality;

  /// Other parts of address.
  core.String? poBox;

  /// Postal code.
  core.String? postalCode;

  /// If this is user's primary address.
  ///
  /// Only one entry could be marked as primary.
  core.bool? primary;

  /// Region.
  core.String? region;

  /// User supplied address was structured.
  ///
  /// Structured addresses are NOT supported at this time. You might be able to
  /// write structured addresses but any values will eventually be clobbered.
  core.bool? sourceIsStructured;

  /// Street.
  core.String? streetAddress;

  /// Each entry can have a type which indicates standard values of that entry.
  ///
  /// For example address could be of home work etc. In addition to the standard
  /// type an entry can have a custom type and can take any value. Such type
  /// should have the CUSTOM value as type and also have a customType value.
  core.String? type;

  UserAddress();

  UserAddress.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('countryCode')) {
      countryCode = _json['countryCode'] as core.String;
    }
    if (_json.containsKey('customType')) {
      customType = _json['customType'] as core.String;
    }
    if (_json.containsKey('extendedAddress')) {
      extendedAddress = _json['extendedAddress'] as core.String;
    }
    if (_json.containsKey('formatted')) {
      formatted = _json['formatted'] as core.String;
    }
    if (_json.containsKey('locality')) {
      locality = _json['locality'] as core.String;
    }
    if (_json.containsKey('poBox')) {
      poBox = _json['poBox'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
    if (_json.containsKey('primary')) {
      primary = _json['primary'] as core.bool;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('sourceIsStructured')) {
      sourceIsStructured = _json['sourceIsStructured'] as core.bool;
    }
    if (_json.containsKey('streetAddress')) {
      streetAddress = _json['streetAddress'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (countryCode != null) 'countryCode': countryCode!,
        if (customType != null) 'customType': customType!,
        if (extendedAddress != null) 'extendedAddress': extendedAddress!,
        if (formatted != null) 'formatted': formatted!,
        if (locality != null) 'locality': locality!,
        if (poBox != null) 'poBox': poBox!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (primary != null) 'primary': primary!,
        if (region != null) 'region': region!,
        if (sourceIsStructured != null)
          'sourceIsStructured': sourceIsStructured!,
        if (streetAddress != null) 'streetAddress': streetAddress!,
        if (type != null) 'type': type!,
      };
}

/// JSON template for a set of custom properties (i.e. all fields in a
/// particular schema)
class UserCustomProperties
    extends collection.MapBase<core.String, core.Object> {
  final _innerMap = <core.String, core.Object>{};

  UserCustomProperties();

  UserCustomProperties.fromJson(core.Map<core.String, core.dynamic> _json) {
    _json.forEach((core.String key, value) {
      this[key] = value as core.Object;
    });
  }

  core.Map<core.String, core.dynamic> toJson() =>
      core.Map<core.String, core.dynamic>.of(this);

  @core.override
  core.Object? operator [](core.Object? key) => _innerMap[key];

  @core.override
  void operator []=(core.String key, core.Object value) {
    _innerMap[key] = value;
  }

  @core.override
  void clear() {
    _innerMap.clear();
  }

  @core.override
  core.Iterable<core.String> get keys => _innerMap.keys;

  @core.override
  core.Object? remove(core.Object? key) => _innerMap.remove(key);
}

/// JSON template for an email.
class UserEmail {
  /// Email id of the user.
  core.String? address;

  /// Custom Type.
  core.String? customType;

  /// If this is user's primary email.
  ///
  /// Only one entry could be marked as primary.
  core.bool? primary;

  /// Each entry can have a type which indicates standard types of that entry.
  ///
  /// For example email could be of home, work etc. In addition to the standard
  /// type, an entry can have a custom type and can take any value Such types
  /// should have the CUSTOM value as type and also have a customType value.
  core.String? type;

  UserEmail();

  UserEmail.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = _json['address'] as core.String;
    }
    if (_json.containsKey('customType')) {
      customType = _json['customType'] as core.String;
    }
    if (_json.containsKey('primary')) {
      primary = _json['primary'] as core.bool;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!,
        if (customType != null) 'customType': customType!,
        if (primary != null) 'primary': primary!,
        if (type != null) 'type': type!,
      };
}

/// JSON template for an externalId entry.
class UserExternalId {
  /// Custom type.
  core.String? customType;

  /// The type of the Id.
  core.String? type;

  /// The value of the id.
  core.String? value;

  UserExternalId();

  UserExternalId.fromJson(core.Map _json) {
    if (_json.containsKey('customType')) {
      customType = _json['customType'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customType != null) 'customType': customType!,
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
      };
}

class UserGender {
  /// AddressMeAs.
  ///
  /// A human-readable string containing the proper way to refer to the profile
  /// owner by humans for example he/him/his or they/them/their.
  core.String? addressMeAs;

  /// Custom gender.
  core.String? customGender;

  /// Gender.
  core.String? type;

  UserGender();

  UserGender.fromJson(core.Map _json) {
    if (_json.containsKey('addressMeAs')) {
      addressMeAs = _json['addressMeAs'] as core.String;
    }
    if (_json.containsKey('customGender')) {
      customGender = _json['customGender'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (addressMeAs != null) 'addressMeAs': addressMeAs!,
        if (customGender != null) 'customGender': customGender!,
        if (type != null) 'type': type!,
      };
}

/// JSON template for instant messenger of an user.
class UserIm {
  /// Custom protocol.
  core.String? customProtocol;

  /// Custom type.
  core.String? customType;

  /// Instant messenger id.
  core.String? im;

  /// If this is user's primary im.
  ///
  /// Only one entry could be marked as primary.
  core.bool? primary;

  /// Protocol used in the instant messenger.
  ///
  /// It should be one of the values from ImProtocolTypes map. Similar to type
  /// it can take a CUSTOM value and specify the custom name in customProtocol
  /// field.
  core.String? protocol;

  /// Each entry can have a type which indicates standard types of that entry.
  ///
  /// For example instant messengers could be of home work etc. In addition to
  /// the standard type an entry can have a custom type and can take any value.
  /// Such types should have the CUSTOM value as type and also have a customType
  /// value.
  core.String? type;

  UserIm();

  UserIm.fromJson(core.Map _json) {
    if (_json.containsKey('customProtocol')) {
      customProtocol = _json['customProtocol'] as core.String;
    }
    if (_json.containsKey('customType')) {
      customType = _json['customType'] as core.String;
    }
    if (_json.containsKey('im')) {
      im = _json['im'] as core.String;
    }
    if (_json.containsKey('primary')) {
      primary = _json['primary'] as core.bool;
    }
    if (_json.containsKey('protocol')) {
      protocol = _json['protocol'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customProtocol != null) 'customProtocol': customProtocol!,
        if (customType != null) 'customType': customType!,
        if (im != null) 'im': im!,
        if (primary != null) 'primary': primary!,
        if (protocol != null) 'protocol': protocol!,
        if (type != null) 'type': type!,
      };
}

/// JSON template for a keyword entry.
class UserKeyword {
  /// Custom Type.
  core.String? customType;

  /// Each entry can have a type which indicates standard type of that entry.
  ///
  /// For example keyword could be of type occupation or outlook. In addition to
  /// the standard type an entry can have a custom type and can give it any
  /// name. Such types should have the CUSTOM value as type and also have a
  /// customType value.
  core.String? type;

  /// Keyword.
  core.String? value;

  UserKeyword();

  UserKeyword.fromJson(core.Map _json) {
    if (_json.containsKey('customType')) {
      customType = _json['customType'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customType != null) 'customType': customType!,
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
      };
}

/// JSON template for a language entry.
class UserLanguage {
  /// Other language.
  ///
  /// User can provide own language name if there is no corresponding Google III
  /// language code. If this is set LanguageCode can't be set
  core.String? customLanguage;

  /// Language Code.
  ///
  /// Should be used for storing Google III LanguageCode string representation
  /// for language. Illegal values cause SchemaException.
  core.String? languageCode;

  UserLanguage();

  UserLanguage.fromJson(core.Map _json) {
    if (_json.containsKey('customLanguage')) {
      customLanguage = _json['customLanguage'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customLanguage != null) 'customLanguage': customLanguage!,
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// JSON template for a location entry.
class UserLocation {
  /// Textual location.
  ///
  /// This is most useful for display purposes to concisely describe the
  /// location. For example 'Mountain View, CA', 'Near Seattle', 'US-NYC-9TH
  /// 9A209A.''
  core.String? area;

  /// Building Identifier.
  core.String? buildingId;

  /// Custom Type.
  core.String? customType;

  /// Most specific textual code of individual desk location.
  core.String? deskCode;

  /// Floor name/number.
  core.String? floorName;

  /// Floor section.
  ///
  /// More specific location within the floor. For example if a floor is divided
  /// into sections 'A', 'B' and 'C' this field would identify one of those
  /// values.
  core.String? floorSection;

  /// Each entry can have a type which indicates standard types of that entry.
  ///
  /// For example location could be of types default and desk. In addition to
  /// standard type an entry can have a custom type and can give it any name.
  /// Such types should have 'custom' as type and also have a customType value.
  core.String? type;

  UserLocation();

  UserLocation.fromJson(core.Map _json) {
    if (_json.containsKey('area')) {
      area = _json['area'] as core.String;
    }
    if (_json.containsKey('buildingId')) {
      buildingId = _json['buildingId'] as core.String;
    }
    if (_json.containsKey('customType')) {
      customType = _json['customType'] as core.String;
    }
    if (_json.containsKey('deskCode')) {
      deskCode = _json['deskCode'] as core.String;
    }
    if (_json.containsKey('floorName')) {
      floorName = _json['floorName'] as core.String;
    }
    if (_json.containsKey('floorSection')) {
      floorSection = _json['floorSection'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (area != null) 'area': area!,
        if (buildingId != null) 'buildingId': buildingId!,
        if (customType != null) 'customType': customType!,
        if (deskCode != null) 'deskCode': deskCode!,
        if (floorName != null) 'floorName': floorName!,
        if (floorSection != null) 'floorSection': floorSection!,
        if (type != null) 'type': type!,
      };
}

class UserMakeAdmin {
  /// Indicates the administrator status of the user.
  core.bool? status;

  UserMakeAdmin();

  UserMakeAdmin.fromJson(core.Map _json) {
    if (_json.containsKey('status')) {
      status = _json['status'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (status != null) 'status': status!,
      };
}

class UserName {
  /// The user's last name.
  ///
  /// Required when creating a user account.
  core.String? familyName;

  /// The user's full name formed by concatenating the first and last name
  /// values.
  core.String? fullName;

  /// The user's first name.
  ///
  /// Required when creating a user account.
  core.String? givenName;

  UserName();

  UserName.fromJson(core.Map _json) {
    if (_json.containsKey('familyName')) {
      familyName = _json['familyName'] as core.String;
    }
    if (_json.containsKey('fullName')) {
      fullName = _json['fullName'] as core.String;
    }
    if (_json.containsKey('givenName')) {
      givenName = _json['givenName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (familyName != null) 'familyName': familyName!,
        if (fullName != null) 'fullName': fullName!,
        if (givenName != null) 'givenName': givenName!,
      };
}

/// JSON template for an organization entry.
class UserOrganization {
  /// The cost center of the users department.
  core.String? costCenter;

  /// Custom type.
  core.String? customType;

  /// Department within the organization.
  core.String? department;

  /// Description of the organization.
  core.String? description;

  /// The domain to which the organization belongs to.
  core.String? domain;

  /// The full-time equivalent millipercent within the organization (100000 =
  /// 100%).
  core.int? fullTimeEquivalent;

  /// Location of the organization.
  ///
  /// This need not be fully qualified address.
  core.String? location;

  /// Name of the organization
  core.String? name;

  /// If it user's primary organization.
  core.bool? primary;

  /// Symbol of the organization.
  core.String? symbol;

  /// Title (designation) of the user in the organization.
  core.String? title;

  /// Each entry can have a type which indicates standard types of that entry.
  ///
  /// For example organization could be of school work etc. In addition to the
  /// standard type an entry can have a custom type and can give it any name.
  /// Such types should have the CUSTOM value as type and also have a CustomType
  /// value.
  core.String? type;

  UserOrganization();

  UserOrganization.fromJson(core.Map _json) {
    if (_json.containsKey('costCenter')) {
      costCenter = _json['costCenter'] as core.String;
    }
    if (_json.containsKey('customType')) {
      customType = _json['customType'] as core.String;
    }
    if (_json.containsKey('department')) {
      department = _json['department'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('domain')) {
      domain = _json['domain'] as core.String;
    }
    if (_json.containsKey('fullTimeEquivalent')) {
      fullTimeEquivalent = _json['fullTimeEquivalent'] as core.int;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('primary')) {
      primary = _json['primary'] as core.bool;
    }
    if (_json.containsKey('symbol')) {
      symbol = _json['symbol'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (costCenter != null) 'costCenter': costCenter!,
        if (customType != null) 'customType': customType!,
        if (department != null) 'department': department!,
        if (description != null) 'description': description!,
        if (domain != null) 'domain': domain!,
        if (fullTimeEquivalent != null)
          'fullTimeEquivalent': fullTimeEquivalent!,
        if (location != null) 'location': location!,
        if (name != null) 'name': name!,
        if (primary != null) 'primary': primary!,
        if (symbol != null) 'symbol': symbol!,
        if (title != null) 'title': title!,
        if (type != null) 'type': type!,
      };
}

/// JSON template for a phone entry.
class UserPhone {
  /// Custom Type.
  core.String? customType;

  /// If this is user's primary phone or not.
  core.bool? primary;

  /// Each entry can have a type which indicates standard types of that entry.
  ///
  /// For example phone could be of home_fax work mobile etc. In addition to the
  /// standard type an entry can have a custom type and can give it any name.
  /// Such types should have the CUSTOM value as type and also have a customType
  /// value.
  core.String? type;

  /// Phone number.
  core.String? value;

  UserPhone();

  UserPhone.fromJson(core.Map _json) {
    if (_json.containsKey('customType')) {
      customType = _json['customType'] as core.String;
    }
    if (_json.containsKey('primary')) {
      primary = _json['primary'] as core.bool;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customType != null) 'customType': customType!,
        if (primary != null) 'primary': primary!,
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
      };
}

class UserPhoto {
  /// ETag of the resource.
  core.String? etag;

  /// Height of the photo in pixels.
  core.int? height;

  /// The ID the API uses to uniquely identify the user.
  core.String? id;

  /// The type of the API resource.
  ///
  /// For Photo resources, this is `admin#directory#user#photo`.
  core.String? kind;

  /// The MIME type of the photo.
  ///
  /// Allowed values are `JPEG`, `PNG`, `GIF`, `BMP`, `TIFF`, and web-safe
  /// base64 encoding.
  core.String? mimeType;

  /// The user photo's upload data in \[web-safe
  /// Base64\](https://en.wikipedia.org/wiki/Base64#URL_applications) format in
  /// bytes.
  ///
  /// This means: * The slash (/) character is replaced with the underscore (_)
  /// character. * The plus sign (+) character is replaced with the hyphen (-)
  /// character. * The equals sign (=) character is replaced with the asterisk
  /// (*). * For padding, the period (.) character is used instead of the
  /// RFC-4648 baseURL definition which uses the equals sign (=) for padding.
  /// This is done to simplify URL-parsing. * Whatever the size of the photo
  /// being uploaded, the API downsizes it to 96x96 pixels.
  core.String? photoData;
  core.List<core.int> get photoDataAsBytes => convert.base64.decode(photoData!);

  set photoDataAsBytes(core.List<core.int> _bytes) {
    photoData =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The user's primary email address.
  core.String? primaryEmail;

  /// Width of the photo in pixels.
  core.int? width;

  UserPhoto();

  UserPhoto.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
    if (_json.containsKey('photoData')) {
      photoData = _json['photoData'] as core.String;
    }
    if (_json.containsKey('primaryEmail')) {
      primaryEmail = _json['primaryEmail'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (height != null) 'height': height!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (mimeType != null) 'mimeType': mimeType!,
        if (photoData != null) 'photoData': photoData!,
        if (primaryEmail != null) 'primaryEmail': primaryEmail!,
        if (width != null) 'width': width!,
      };
}

/// JSON template for a POSIX account entry.
class UserPosixAccount {
  /// A POSIX account field identifier.
  core.String? accountId;

  /// The GECOS (user information) for this account.
  core.String? gecos;

  /// The default group ID.
  core.String? gid;

  /// The path to the home directory for this account.
  core.String? homeDirectory;

  /// The operating system type for this account.
  core.String? operatingSystemType;

  /// If this is user's primary account within the SystemId.
  core.bool? primary;

  /// The path to the login shell for this account.
  core.String? shell;

  /// System identifier for which account Username or Uid apply to.
  core.String? systemId;

  /// The POSIX compliant user ID.
  core.String? uid;

  /// The username of the account.
  core.String? username;

  UserPosixAccount();

  UserPosixAccount.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('gecos')) {
      gecos = _json['gecos'] as core.String;
    }
    if (_json.containsKey('gid')) {
      gid = _json['gid'] as core.String;
    }
    if (_json.containsKey('homeDirectory')) {
      homeDirectory = _json['homeDirectory'] as core.String;
    }
    if (_json.containsKey('operatingSystemType')) {
      operatingSystemType = _json['operatingSystemType'] as core.String;
    }
    if (_json.containsKey('primary')) {
      primary = _json['primary'] as core.bool;
    }
    if (_json.containsKey('shell')) {
      shell = _json['shell'] as core.String;
    }
    if (_json.containsKey('systemId')) {
      systemId = _json['systemId'] as core.String;
    }
    if (_json.containsKey('uid')) {
      uid = _json['uid'] as core.String;
    }
    if (_json.containsKey('username')) {
      username = _json['username'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (gecos != null) 'gecos': gecos!,
        if (gid != null) 'gid': gid!,
        if (homeDirectory != null) 'homeDirectory': homeDirectory!,
        if (operatingSystemType != null)
          'operatingSystemType': operatingSystemType!,
        if (primary != null) 'primary': primary!,
        if (shell != null) 'shell': shell!,
        if (systemId != null) 'systemId': systemId!,
        if (uid != null) 'uid': uid!,
        if (username != null) 'username': username!,
      };
}

/// JSON template for a relation entry.
class UserRelation {
  /// Custom Type.
  core.String? customType;

  /// The relation of the user.
  ///
  /// Some of the possible values are mother father sister brother manager
  /// assistant partner.
  core.String? type;

  /// The name of the relation.
  core.String? value;

  UserRelation();

  UserRelation.fromJson(core.Map _json) {
    if (_json.containsKey('customType')) {
      customType = _json['customType'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customType != null) 'customType': customType!,
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
      };
}

/// JSON template for a POSIX account entry.
class UserSshPublicKey {
  /// An expiration time in microseconds since epoch.
  core.String? expirationTimeUsec;

  /// A SHA-256 fingerprint of the SSH public key.
  ///
  /// (Read-only)
  core.String? fingerprint;

  /// An SSH public key.
  core.String? key;

  UserSshPublicKey();

  UserSshPublicKey.fromJson(core.Map _json) {
    if (_json.containsKey('expirationTimeUsec')) {
      expirationTimeUsec = _json['expirationTimeUsec'] as core.String;
    }
    if (_json.containsKey('fingerprint')) {
      fingerprint = _json['fingerprint'] as core.String;
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expirationTimeUsec != null)
          'expirationTimeUsec': expirationTimeUsec!,
        if (fingerprint != null) 'fingerprint': fingerprint!,
        if (key != null) 'key': key!,
      };
}

class UserUndelete {
  /// OrgUnit of User
  core.String? orgUnitPath;

  UserUndelete();

  UserUndelete.fromJson(core.Map _json) {
    if (_json.containsKey('orgUnitPath')) {
      orgUnitPath = _json['orgUnitPath'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (orgUnitPath != null) 'orgUnitPath': orgUnitPath!,
      };
}

/// JSON template for a website entry.
class UserWebsite {
  /// Custom Type.
  core.String? customType;

  /// If this is user's primary website or not.
  core.bool? primary;

  /// Each entry can have a type which indicates standard types of that entry.
  ///
  /// For example website could be of home work blog etc. In addition to the
  /// standard type an entry can have a custom type and can give it any name.
  /// Such types should have the CUSTOM value as type and also have a customType
  /// value.
  core.String? type;

  /// Website.
  core.String? value;

  UserWebsite();

  UserWebsite.fromJson(core.Map _json) {
    if (_json.containsKey('customType')) {
      customType = _json['customType'] as core.String;
    }
    if (_json.containsKey('primary')) {
      primary = _json['primary'] as core.bool;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customType != null) 'customType': customType!,
        if (primary != null) 'primary': primary!,
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
      };
}

class Users {
  /// ETag of the resource.
  core.String? etag;

  /// Kind of resource this is.
  core.String? kind;

  /// Token used to access next page of this result.
  core.String? nextPageToken;

  /// Event that triggered this response (only used in case of Push Response)
  core.String? triggerEvent;

  /// List of user objects.
  core.List<User>? users;

  Users();

  Users.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('trigger_event')) {
      triggerEvent = _json['trigger_event'] as core.String;
    }
    if (_json.containsKey('users')) {
      users = (_json['users'] as core.List)
          .map<User>((value) =>
              User.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (triggerEvent != null) 'trigger_event': triggerEvent!,
        if (users != null)
          'users': users!.map((value) => value.toJson()).toList(),
      };
}

/// The Directory API allows you to view, generate, and invalidate backup
/// verification codes for a user.
class VerificationCode {
  /// ETag of the resource.
  core.String? etag;

  /// The type of the resource.
  ///
  /// This is always `admin#directory#verificationCode`.
  core.String? kind;

  /// The obfuscated unique ID of the user.
  core.String? userId;

  /// A current verification code for the user.
  ///
  /// Invalidated or used verification codes are not returned as part of the
  /// result.
  core.String? verificationCode;

  VerificationCode();

  VerificationCode.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('userId')) {
      userId = _json['userId'] as core.String;
    }
    if (_json.containsKey('verificationCode')) {
      verificationCode = _json['verificationCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (userId != null) 'userId': userId!,
        if (verificationCode != null) 'verificationCode': verificationCode!,
      };
}

/// JSON response template for List verification codes operation in Directory
/// API.
class VerificationCodes {
  /// ETag of the resource.
  core.String? etag;

  /// A list of verification code resources.
  core.List<VerificationCode>? items;

  /// The type of the resource.
  ///
  /// This is always `admin#directory#verificationCodesList`.
  core.String? kind;

  VerificationCodes();

  VerificationCodes.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<VerificationCode>((value) => VerificationCode.fromJson(
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
