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

/// My Business Account Management API - v1
///
/// The My Business Account Management API provides an interface for managing
/// access to a location on Google.
///
/// For more information, see <https://developers.google.com/my-business/>
///
/// Create an instance of [MyBusinessAccountManagementApi] to access these
/// resources:
///
/// - [AccountsResource]
///   - [AccountsAdminsResource]
///   - [AccountsInvitationsResource]
/// - [LocationsResource]
///   - [LocationsAdminsResource]
library mybusinessaccountmanagement.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The My Business Account Management API provides an interface for managing
/// access to a location on Google.
class MyBusinessAccountManagementApi {
  final commons.ApiRequester _requester;

  AccountsResource get accounts => AccountsResource(_requester);
  LocationsResource get locations => LocationsResource(_requester);

  MyBusinessAccountManagementApi(http.Client client,
      {core.String rootUrl =
          'https://mybusinessaccountmanagement.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AccountsResource {
  final commons.ApiRequester _requester;

  AccountsAdminsResource get admins => AccountsAdminsResource(_requester);
  AccountsInvitationsResource get invitations =>
      AccountsInvitationsResource(_requester);

  AccountsResource(commons.ApiRequester client) : _requester = client;

  /// Creates an account with the specified name and type under the given
  /// parent.
  ///
  /// - Personal accounts and Organizations cannot be created. - User Groups
  /// cannot be created with a Personal account as primary owner. - Location
  /// Groups cannot be created with a primary owner of a Personal account if the
  /// Personal account is in an Organization. - Location Groups cannot own
  /// Location Groups.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
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
  async.Future<Account> create(
    Account request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/accounts';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the specified account.
  ///
  /// Returns `NOT_FOUND` if the account does not exist or if the caller does
  /// not have access rights to it.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the account to fetch.
  /// Value must have pattern `^accounts/\[^/\]+$`.
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
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all of the accounts for the authenticated user.
  ///
  /// This includes all accounts that the user owns, as well as any accounts for
  /// which the user has management rights.
  ///
  /// Request parameters:
  ///
  /// [filter] - Optional. A filter constraining the accounts to return. The
  /// response includes only entries that match the filter. If `filter` is
  /// empty, then no constraints are applied and all accounts (paginated) are
  /// retrieved for the requested account. For example, a request with the
  /// filter `type=USER_GROUP` will only return user groups. The `type` field is
  /// the only supported filter.
  ///
  /// [pageSize] - Optional. How many accounts to fetch per page. The minimum
  /// supported page_size is 2. The default and maximum is 20.
  ///
  /// [pageToken] - Optional. If specified, the next page of accounts is
  /// retrieved. The `pageToken` is returned when a call to `accounts.list`
  /// returns more results than can fit into the requested page size.
  ///
  /// [parentAccount] - Optional. The resource name of the account for which the
  /// list of directly accessible accounts is to be retrieved. This only makes
  /// sense for Organizations and User Groups. If empty, will return
  /// `ListAccounts` for the authenticated user. `accounts/{account_id}`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAccountsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAccountsResponse> list({
    core.String? filter,
    core.int? pageSize,
    core.String? pageToken,
    core.String? parentAccount,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (parentAccount != null) 'parentAccount': [parentAccount],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/accounts';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAccountsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified business account.
  ///
  /// Personal accounts cannot be updated using this method.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Immutable. The resource name, in the format
  /// `accounts/{account_id}`.
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [updateMask] - Required. The specific fields that should be updated. The
  /// only editable field is `accountName`.
  ///
  /// [validateOnly] - Optional. If true, the request is validated without
  /// actually updating the account.
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
    core.String name, {
    core.String? updateMask,
    core.bool? validateOnly,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if (validateOnly != null) 'validateOnly': ['${validateOnly}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsAdminsResource {
  final commons.ApiRequester _requester;

  AccountsAdminsResource(commons.ApiRequester client) : _requester = client;

  /// Invites the specified user to become an administrator for the specified
  /// account.
  ///
  /// The invitee must accept the invitation in order to be granted access to
  /// the account. See AcceptInvitation to programmatically accept an
  /// invitation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the account this admin is
  /// created for. `accounts/{account_id}`.
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Admin].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Admin> create(
    Admin request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/admins';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Admin.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Removes the specified admin from the specified account.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the admin to remove from the
  /// account. `accounts/{account_id}/admins/{admin_id}`.
  /// Value must have pattern `^accounts/\[^/\]+/admins/\[^/\]+$`.
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

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the admins for the specified account.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the account from which to retrieve a list
  /// of admins. `accounts/{account_id}/admins`.
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAccountAdminsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAccountAdminsResponse> list(
    core.String parent, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/admins';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAccountAdminsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the Admin for the specified Account Admin.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Immutable. The resource name. For account admins, this is in the
  /// form: `accounts/{account_id}/admins/{admin_id}` For location admins, this
  /// is in the form: `locations/{location_id}/admins/{admin_id}` This field
  /// will be ignored if set during admin creation.
  /// Value must have pattern `^accounts/\[^/\]+/admins/\[^/\]+$`.
  ///
  /// [updateMask] - Required. The specific fields that should be updated. The
  /// only editable field is role.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Admin].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Admin> patch(
    Admin request,
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
    return Admin.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsInvitationsResource {
  final commons.ApiRequester _requester;

  AccountsInvitationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Accepts the specified invitation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the invitation that is being accepted.
  /// `accounts/{account_id}/invitations/{invitation_id}`
  /// Value must have pattern `^accounts/\[^/\]+/invitations/\[^/\]+$`.
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
  async.Future<Empty> accept(
    AcceptInvitationRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':accept';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Declines the specified invitation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the account invitation that is being
  /// declined. `accounts/{account_id}/invitations/{invitation_id}`
  /// Value must have pattern `^accounts/\[^/\]+/invitations/\[^/\]+$`.
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
  async.Future<Empty> decline(
    DeclineInvitationRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':decline';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists pending invitations for the specified account.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the account from which the list of
  /// invitations is being retrieved. `accounts/{account_id}/invitations`
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [filter] - Optional. Filtering the response is supported via the
  /// Invitation.target_type field.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListInvitationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListInvitationsResponse> list(
    core.String parent, {
    core.String? filter,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/invitations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListInvitationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class LocationsResource {
  final commons.ApiRequester _requester;

  LocationsAdminsResource get admins => LocationsAdminsResource(_requester);

  LocationsResource(commons.ApiRequester client) : _requester = client;

  /// Moves a location from an account that the user owns to another account
  /// that the same user administers.
  ///
  /// The user must be an owner of the account the location is currently
  /// associated with and must also be at least a manager of the destination
  /// account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the location to transfer.
  /// `locations/{location_id}`.
  /// Value must have pattern `^locations/\[^/\]+$`.
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
  async.Future<Empty> transfer(
    TransferLocationRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':transfer';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class LocationsAdminsResource {
  final commons.ApiRequester _requester;

  LocationsAdminsResource(commons.ApiRequester client) : _requester = client;

  /// Invites the specified user to become an administrator for the specified
  /// location.
  ///
  /// The invitee must accept the invitation in order to be granted access to
  /// the location. See AcceptInvitation to programmatically accept an
  /// invitation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the location this admin is
  /// created for. `locations/{location_id}/admins`.
  /// Value must have pattern `^locations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Admin].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Admin> create(
    Admin request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/admins';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Admin.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Removes the specified admin as a manager of the specified location.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the admin to remove from the
  /// location.
  /// Value must have pattern `^locations/\[^/\]+/admins/\[^/\]+$`.
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

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all of the admins for the specified location.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the location to list admins of.
  /// `locations/{location_id}/admins`.
  /// Value must have pattern `^locations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLocationAdminsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLocationAdminsResponse> list(
    core.String parent, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/admins';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLocationAdminsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the Admin for the specified location.
  ///
  /// Only the AdminRole of the Admin can be updated.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Immutable. The resource name. For account admins, this is in the
  /// form: `accounts/{account_id}/admins/{admin_id}` For location admins, this
  /// is in the form: `locations/{location_id}/admins/{admin_id}` This field
  /// will be ignored if set during admin creation.
  /// Value must have pattern `^locations/\[^/\]+/admins/\[^/\]+$`.
  ///
  /// [updateMask] - Required. The specific fields that should be updated. The
  /// only editable field is role.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Admin].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Admin> patch(
    Admin request,
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
    return Admin.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// Request message for AccessControl.AcceptInvitation.
class AcceptInvitationRequest {
  AcceptInvitationRequest();

  AcceptInvitationRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// An account is a container for your location.
///
/// If you are the only user who manages locations for your business, you can
/// use your personal Google Account. To share management of locations with
/// multiple users,
/// [create a business account](https://support.google.com/business/answer/6085339?ref_topic=6085325).
class Account {
  /// The name of the account.
  ///
  /// For an account of type `PERSONAL`, this is the first and last name of the
  /// user account.
  ///
  /// Required.
  core.String? accountName;

  /// Account reference number if provisioned.
  ///
  /// Output only.
  core.String? accountNumber;

  /// The resource name, in the format `accounts/{account_id}`.
  ///
  /// Immutable.
  core.String? name;

  /// Additional info for an organization.
  ///
  /// This is populated only for an organization account.
  ///
  /// Output only.
  OrganizationInfo? organizationInfo;

  /// Specifies the permission level the user has for this account.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "PERMISSION_LEVEL_UNSPECIFIED" : Not specified.
  /// - "OWNER_LEVEL" : The user has owner level permission.
  /// - "MEMBER_LEVEL" : The user has member level permission.
  core.String? permissionLevel;

  /// Input only.
  ///
  /// The resource name of the account which will be the primary owner of the
  /// account being created. It should be of the form `accounts/{account_id}/`.
  ///
  /// Required.
  core.String? primaryOwner;

  /// Specifies the AccountRole of this account.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ACCOUNT_ROLE_UNSPECIFIED" : Not specified.
  /// - "PRIMARY_OWNER" : The user is the primary owner this account.
  /// - "OWNER" : The user owner of the account.
  /// - "MANAGER" : The user can manage this account.
  /// - "SITE_MANAGER" : The user can manage a limited set of features for the
  /// account.
  core.String? role;

  /// Contains the type of account.
  ///
  /// Accounts of type PERSONAL and ORGANIZATION cannot be created using this
  /// API.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ACCOUNT_TYPE_UNSPECIFIED" : Not specified.
  /// - "PERSONAL" : An end-user account.
  /// - "LOCATION_GROUP" : A group of Locations. For more information, see the
  /// [help center article](https://support.google.com/business/answer/6085326)
  /// - "USER_GROUP" : A User Group for segregating organization staff in
  /// groups. For more information, see the
  /// [help center article](https://support.google.com/business/answer/7655731)
  /// - "ORGANIZATION" : An organization representing a company. For more
  /// information, see the
  /// [help center article](https://support.google.com/business/answer/7663063)
  core.String? type;

  /// If verified, future locations that are created are automatically connected
  /// to Google Maps, and have Google+ pages created, without requiring
  /// moderation.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "VERIFICATION_STATE_UNSPECIFIED" : Not specified.
  /// - "VERIFIED" : Verified account.
  /// - "UNVERIFIED" : Account that is not verified, and verification has not
  /// been requested.
  /// - "VERIFICATION_REQUESTED" : Account that is not verified, but
  /// verification has been requested.
  core.String? verificationState;

  /// Indicates whether the account is vetted by Google.
  ///
  /// A vetted account is able to verify locations via the VETTED_PARTNER
  /// method.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "VETTED_STATE_UNSPECIFIED" : Not Specified
  /// - "NOT_VETTED" : The account is not vetted by Google.
  /// - "VETTED" : The account is vetted by Google and in a valid state. An
  /// account is automatically vetted if it has direct access to a vetted group
  /// account.
  /// - "INVALID" : The account is vetted but in an invalid state. The account
  /// will behave like an unvetted account.
  core.String? vettedState;

  Account();

  Account.fromJson(core.Map _json) {
    if (_json.containsKey('accountName')) {
      accountName = _json['accountName'] as core.String;
    }
    if (_json.containsKey('accountNumber')) {
      accountNumber = _json['accountNumber'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('organizationInfo')) {
      organizationInfo = OrganizationInfo.fromJson(
          _json['organizationInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('permissionLevel')) {
      permissionLevel = _json['permissionLevel'] as core.String;
    }
    if (_json.containsKey('primaryOwner')) {
      primaryOwner = _json['primaryOwner'] as core.String;
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('verificationState')) {
      verificationState = _json['verificationState'] as core.String;
    }
    if (_json.containsKey('vettedState')) {
      vettedState = _json['vettedState'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountName != null) 'accountName': accountName!,
        if (accountNumber != null) 'accountNumber': accountNumber!,
        if (name != null) 'name': name!,
        if (organizationInfo != null)
          'organizationInfo': organizationInfo!.toJson(),
        if (permissionLevel != null) 'permissionLevel': permissionLevel!,
        if (primaryOwner != null) 'primaryOwner': primaryOwner!,
        if (role != null) 'role': role!,
        if (type != null) 'type': type!,
        if (verificationState != null) 'verificationState': verificationState!,
        if (vettedState != null) 'vettedState': vettedState!,
      };
}

/// An administrator of an Account or a location.
class Admin {
  /// The name of the admin.
  ///
  /// When making the initial invitation, this is the invitee's email address.
  /// On `GET` calls, the user's email address is returned if the invitation is
  /// still pending. Otherwise, it contains the user's first and last names.
  /// This field is only needed to be set during admin creation.
  ///
  /// Optional.
  core.String? admin;

  /// The resource name.
  ///
  /// For account admins, this is in the form:
  /// `accounts/{account_id}/admins/{admin_id}` For location admins, this is in
  /// the form: `locations/{location_id}/admins/{admin_id}` This field will be
  /// ignored if set during admin creation.
  ///
  /// Immutable.
  core.String? name;

  /// Indicates whether this admin has a pending invitation for the specified
  /// resource.
  ///
  /// Output only.
  core.bool? pendingInvitation;

  /// Specifies the role that this admin uses with the specified Account or
  /// Location.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ADMIN_ROLE_UNSPECIFIED" : Not specified.
  /// - "PRIMARY_OWNER" : The admin has owner-level access and is the primary
  /// owner. (Displays as 'Primary Owner' in UI).
  /// - "OWNER" : The admin has owner-level access. (Displays as 'Owner' in UI).
  /// - "MANAGER" : The admin has managerial access.
  /// - "SITE_MANAGER" : The admin can manage social (Google+) pages. (Displays
  /// as 'Site Manager' in UI). This API doesn't allow creating an account admin
  /// with a SITE_MANAGER role.
  core.String? role;

  Admin();

  Admin.fromJson(core.Map _json) {
    if (_json.containsKey('admin')) {
      admin = _json['admin'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('pendingInvitation')) {
      pendingInvitation = _json['pendingInvitation'] as core.bool;
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (admin != null) 'admin': admin!,
        if (name != null) 'name': name!,
        if (pendingInvitation != null) 'pendingInvitation': pendingInvitation!,
        if (role != null) 'role': role!,
      };
}

/// Request message for AccessControl.DeclineInvitation.
class DeclineInvitationRequest {
  DeclineInvitationRequest();

  DeclineInvitationRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
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

/// Represents a pending invitation.
class Invitation {
  /// The resource name for the invitation.
  ///
  /// `accounts/{account_id}/invitations/{invitation_id}`.
  ///
  /// Required.
  core.String? name;

  /// The invited role on the account.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ADMIN_ROLE_UNSPECIFIED" : Not specified.
  /// - "PRIMARY_OWNER" : The admin has owner-level access and is the primary
  /// owner. (Displays as 'Primary Owner' in UI).
  /// - "OWNER" : The admin has owner-level access. (Displays as 'Owner' in UI).
  /// - "MANAGER" : The admin has managerial access.
  /// - "SITE_MANAGER" : The admin can manage social (Google+) pages. (Displays
  /// as 'Site Manager' in UI). This API doesn't allow creating an account admin
  /// with a SITE_MANAGER role.
  core.String? role;

  /// The sparsely populated account this invitation is for.
  Account? targetAccount;

  /// The target location this invitation is for.
  TargetLocation? targetLocation;

  /// Specifies which target types should appear in the response.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "TARGET_TYPE_UNSPECIFIED" : Set when target type is unspecified.
  /// - "ACCOUNTS_ONLY" : List invitations only for targets of type Account.
  /// - "LOCATIONS_ONLY" : List invitations only for targets of type Location.
  core.String? targetType;

  Invitation();

  Invitation.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
    if (_json.containsKey('targetAccount')) {
      targetAccount = Account.fromJson(
          _json['targetAccount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('targetLocation')) {
      targetLocation = TargetLocation.fromJson(
          _json['targetLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('targetType')) {
      targetType = _json['targetType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (role != null) 'role': role!,
        if (targetAccount != null) 'targetAccount': targetAccount!.toJson(),
        if (targetLocation != null) 'targetLocation': targetLocation!.toJson(),
        if (targetType != null) 'targetType': targetType!,
      };
}

/// Response message for AccessControl.ListAccountAdmins.
class ListAccountAdminsResponse {
  /// A collection of Admin instances.
  core.List<Admin>? accountAdmins;

  ListAccountAdminsResponse();

  ListAccountAdminsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accountAdmins')) {
      accountAdmins = (_json['accountAdmins'] as core.List)
          .map<Admin>((value) =>
              Admin.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountAdmins != null)
          'accountAdmins':
              accountAdmins!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for Accounts.ListAccounts.
class ListAccountsResponse {
  /// A collection of accounts to which the user has access.
  ///
  /// The personal account of the user doing the query will always be the first
  /// item of the result, unless it is filtered out.
  core.List<Account>? accounts;

  /// If the number of accounts exceeds the requested page size, this field is
  /// populated with a token to fetch the next page of accounts on a subsequent
  /// call to `accounts.list`.
  ///
  /// If there are no more accounts, this field is not present in the response.
  core.String? nextPageToken;

  ListAccountsResponse();

  ListAccountsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accounts')) {
      accounts = (_json['accounts'] as core.List)
          .map<Account>((value) =>
              Account.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accounts != null)
          'accounts': accounts!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for AccessControl.ListInvitations.
class ListInvitationsResponse {
  /// A collection of invitations that are pending for the account.
  ///
  /// The number of invitations listed here cannot exceed 1000.
  core.List<Invitation>? invitations;

  ListInvitationsResponse();

  ListInvitationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('invitations')) {
      invitations = (_json['invitations'] as core.List)
          .map<Invitation>((value) =>
              Invitation.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (invitations != null)
          'invitations': invitations!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for AccessControl.ListLocationAdmins.
class ListLocationAdminsResponse {
  /// A collection of Admins.
  core.List<Admin>? admins;

  ListLocationAdminsResponse();

  ListLocationAdminsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('admins')) {
      admins = (_json['admins'] as core.List)
          .map<Admin>((value) =>
              Admin.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (admins != null)
          'admins': admins!.map((value) => value.toJson()).toList(),
      };
}

/// Additional information stored for an organization.
class OrganizationInfo {
  /// The postal address for the account.
  ///
  /// Output only.
  PostalAddress? address;

  /// The contact number for the organization.
  ///
  /// Output only.
  core.String? phoneNumber;

  /// The registered domain for the account.
  ///
  /// Output only.
  core.String? registeredDomain;

  OrganizationInfo();

  OrganizationInfo.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = PostalAddress.fromJson(
          _json['address'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('registeredDomain')) {
      registeredDomain = _json['registeredDomain'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!.toJson(),
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (registeredDomain != null) 'registeredDomain': registeredDomain!,
      };
}

/// Represents a postal address, e.g. for postal delivery or payments addresses.
///
/// Given a postal address, a postal service can deliver items to a premise,
/// P.O. Box or similar. It is not intended to model geographical locations
/// (roads, towns, mountains). In typical usage an address would be created via
/// user input or from importing existing data, depending on the type of
/// process. Advice on address input / editing: - Use an i18n-ready address
/// widget such as https://github.com/google/libaddressinput) - Users should not
/// be presented with UI elements for input or editing of fields outside
/// countries where that field is used. For more guidance on how to use this
/// schema, please see: https://support.google.com/business/answer/6397478
class PostalAddress {
  /// Unstructured address lines describing the lower levels of an address.
  ///
  /// Because values in address_lines do not have type information and may
  /// sometimes contain multiple values in a single field (e.g. "Austin, TX"),
  /// it is important that the line order is clear. The order of address lines
  /// should be "envelope order" for the country/region of the address. In
  /// places where this can vary (e.g. Japan), address_language is used to make
  /// it explicit (e.g. "ja" for large-to-small ordering and "ja-Latn" or "en"
  /// for small-to-large). This way, the most specific line of an address can be
  /// selected based on the language. The minimum permitted structural
  /// representation of an address consists of a region_code with all remaining
  /// information placed in the address_lines. It would be possible to format
  /// such an address very approximately without geocoding, but no semantic
  /// reasoning could be made about any of the address components until it was
  /// at least partially resolved. Creating an address only containing a
  /// region_code and address_lines, and then geocoding is the recommended way
  /// to handle completely unstructured addresses (as opposed to guessing which
  /// parts of the address should be localities or administrative areas).
  core.List<core.String>? addressLines;

  /// Highest administrative subdivision which is used for postal addresses of a
  /// country or region.
  ///
  /// For example, this can be a state, a province, an oblast, or a prefecture.
  /// Specifically, for Spain this is the province and not the autonomous
  /// community (e.g. "Barcelona" and not "Catalonia"). Many countries don't use
  /// an administrative area in postal addresses. E.g. in Switzerland this
  /// should be left unpopulated.
  ///
  /// Optional.
  core.String? administrativeArea;

  /// BCP-47 language code of the contents of this address (if known).
  ///
  /// This is often the UI language of the input form or is expected to match
  /// one of the languages used in the address' country/region, or their
  /// transliterated equivalents. This can affect formatting in certain
  /// countries, but is not critical to the correctness of the data and will
  /// never affect any validation or other non-formatting related operations. If
  /// this value is not known, it should be omitted (rather than specifying a
  /// possibly incorrect default). Examples: "zh-Hant", "ja", "ja-Latn", "en".
  ///
  /// Optional.
  core.String? languageCode;

  /// Generally refers to the city/town portion of the address.
  ///
  /// Examples: US city, IT comune, UK post town. In regions of the world where
  /// localities are not well defined or do not fit into this structure well,
  /// leave locality empty and use address_lines.
  ///
  /// Optional.
  core.String? locality;

  /// The name of the organization at the address.
  ///
  /// Optional.
  core.String? organization;

  /// Postal code of the address.
  ///
  /// Not all countries use or require postal codes to be present, but where
  /// they are used, they may trigger additional validation with other parts of
  /// the address (e.g. state/zip validation in the U.S.A.).
  ///
  /// Optional.
  core.String? postalCode;

  /// The recipient at the address.
  ///
  /// This field may, under certain circumstances, contain multiline
  /// information. For example, it might contain "care of" information.
  ///
  /// Optional.
  core.List<core.String>? recipients;

  /// CLDR region code of the country/region of the address.
  ///
  /// This is never inferred and it is up to the user to ensure the value is
  /// correct. See http://cldr.unicode.org/ and
  /// http://www.unicode.org/cldr/charts/30/supplemental/territory_information.html
  /// for details. Example: "CH" for Switzerland.
  ///
  /// Required.
  core.String? regionCode;

  /// The schema revision of the `PostalAddress`.
  ///
  /// This must be set to 0, which is the latest revision. All new revisions
  /// **must** be backward compatible with old revisions.
  core.int? revision;

  /// Additional, country-specific, sorting code.
  ///
  /// This is not used in most regions. Where it is used, the value is either a
  /// string like "CEDEX", optionally followed by a number (e.g. "CEDEX 7"), or
  /// just a number alone, representing the "sector code" (Jamaica), "delivery
  /// area indicator" (Malawi) or "post office indicator" (e.g. Côte d'Ivoire).
  ///
  /// Optional.
  core.String? sortingCode;

  /// Sublocality of the address.
  ///
  /// For example, this can be neighborhoods, boroughs, districts.
  ///
  /// Optional.
  core.String? sublocality;

  PostalAddress();

  PostalAddress.fromJson(core.Map _json) {
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
    if (_json.containsKey('organization')) {
      organization = _json['organization'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
    if (_json.containsKey('recipients')) {
      recipients = (_json['recipients'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('regionCode')) {
      regionCode = _json['regionCode'] as core.String;
    }
    if (_json.containsKey('revision')) {
      revision = _json['revision'] as core.int;
    }
    if (_json.containsKey('sortingCode')) {
      sortingCode = _json['sortingCode'] as core.String;
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
        if (organization != null) 'organization': organization!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (recipients != null) 'recipients': recipients!,
        if (regionCode != null) 'regionCode': regionCode!,
        if (revision != null) 'revision': revision!,
        if (sortingCode != null) 'sortingCode': sortingCode!,
        if (sublocality != null) 'sublocality': sublocality!,
      };
}

/// Represents a target location for a pending invitation.
class TargetLocation {
  /// The address of the location to which the user is invited.
  core.String? address;

  /// The name of the location to which the user is invited.
  core.String? locationName;

  TargetLocation();

  TargetLocation.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = _json['address'] as core.String;
    }
    if (_json.containsKey('locationName')) {
      locationName = _json['locationName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!,
        if (locationName != null) 'locationName': locationName!,
      };
}

/// Request message for AccessControl.TransferLocation.
class TransferLocationRequest {
  /// Name of the account resource to transfer the location to (for example,
  /// "accounts/{account}").
  ///
  /// Required.
  core.String? destinationAccount;

  TransferLocationRequest();

  TransferLocationRequest.fromJson(core.Map _json) {
    if (_json.containsKey('destinationAccount')) {
      destinationAccount = _json['destinationAccount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationAccount != null)
          'destinationAccount': destinationAccount!,
      };
}
