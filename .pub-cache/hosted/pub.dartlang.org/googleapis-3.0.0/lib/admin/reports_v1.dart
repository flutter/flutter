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

/// Admin SDK API - reports_v1
///
/// Admin SDK lets administrators of enterprise domains to view and manage
/// resources like user, groups etc. It also provides audit and usage reports of
/// domain.
///
/// For more information, see <http://developers.google.com/admin-sdk/>
///
/// Create an instance of [ReportsApi] to access these resources:
///
/// - [ActivitiesResource]
/// - [ChannelsResource]
/// - [CustomerUsageReportsResource]
/// - [EntityUsageReportsResource]
/// - [UserUsageReportResource]
library admin.reports_v1;

import 'dart:async' as async;
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
class ReportsApi {
  /// View audit reports for your G Suite domain
  static const adminReportsAuditReadonlyScope =
      'https://www.googleapis.com/auth/admin.reports.audit.readonly';

  /// View usage reports for your G Suite domain
  static const adminReportsUsageReadonlyScope =
      'https://www.googleapis.com/auth/admin.reports.usage.readonly';

  final commons.ApiRequester _requester;

  ActivitiesResource get activities => ActivitiesResource(_requester);
  ChannelsResource get channels => ChannelsResource(_requester);
  CustomerUsageReportsResource get customerUsageReports =>
      CustomerUsageReportsResource(_requester);
  EntityUsageReportsResource get entityUsageReports =>
      EntityUsageReportsResource(_requester);
  UserUsageReportResource get userUsageReport =>
      UserUsageReportResource(_requester);

  ReportsApi(http.Client client,
      {core.String rootUrl = 'https://admin.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ActivitiesResource {
  final commons.ApiRequester _requester;

  ActivitiesResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a list of activities for a specific customer's account and
  /// application such as the Admin console application or the Google Drive
  /// application.
  ///
  /// For more information, see the guides for administrator and Google Drive
  /// activity reports. For more information about the activity report's
  /// parameters, see the activity parameters reference guides.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Represents the profile ID or the user email for which the data
  /// should be filtered. Can be `all` for all information, or `userKey` for a
  /// user's unique Google Workspace profile ID or their primary email address.
  ///
  /// [applicationName] - Application name for which the events are to be
  /// retrieved.
  /// Value must have pattern
  /// `(access_transparency)|(admin)|(calendar)|(chat)|(chrome)|(context_aware_access)|(data_studio)|(drive)|(gcp)|(gplus)|(groups)|(groups_enterprise)|(jamboard)|(keep)|(login)|(meet)|(mobile)|(rules)|(saml)|(token)|(user_accounts)`.
  /// Possible string values are:
  /// - "access_transparency" : The Google Workspace Access Transparency
  /// activity reports return information about different types of Access
  /// Transparency activity events.
  /// - "admin" : The Admin console application's activity reports return
  /// account information about different types of administrator activity
  /// events.
  /// - "calendar" : The Google Calendar application's activity reports return
  /// information about various Calendar activity events.
  /// - "chat" : The Chat activity reports return information about various Chat
  /// activity events.
  /// - "drive" : The Google Drive application's activity reports return
  /// information about various Google Drive activity events. The Drive activity
  /// report is only available for Google Workspace Business and Enterprise
  /// customers.
  /// - "gcp" : The Google Cloud Platform application's activity reports return
  /// information about various GCP activity events.
  /// - "gplus" : The Google+ application's activity reports return information
  /// about various Google+ activity events.
  /// - "groups" : The Google Groups application's activity reports return
  /// information about various Groups activity events.
  /// - "groups_enterprise" : The Enterprise Groups activity reports return
  /// information about various Enterprise group activity events.
  /// - "jamboard" : The Jamboard activity reports return information about
  /// various Jamboard activity events.
  /// - "login" : The Login application's activity reports return account
  /// information about different types of Login activity events.
  /// - "meet" : The Meet Audit activity report return information about
  /// different types of Meet Audit activity events.
  /// - "mobile" : The Mobile Audit activity report return information about
  /// different types of Mobile Audit activity events.
  /// - "rules" : The Rules activity report return information about different
  /// types of Rules activity events.
  /// - "saml" : The SAML activity report return information about different
  /// types of SAML activity events.
  /// - "token" : The Token application's activity reports return account
  /// information about different types of Token activity events.
  /// - "user_accounts" : The User Accounts application's activity reports
  /// return account information about different types of User Accounts activity
  /// events.
  /// - "context_aware_access" : The Context-aware access activity reports
  /// return information about users' access denied events due to Context-aware
  /// access rules.
  /// - "chrome" : The Chrome activity reports return information about unsafe
  /// events reported in the context of the WebProtect features of BeyondCorp.
  /// - "data_studio" : The Data Studio activity reports return information
  /// about various types of Data Studio activity events.
  /// - "keep" : The Keep application's activity reports return information
  /// about various Google Keep activity events. The Keep activity report is
  /// only available for Google Workspace Business and Enterprise customers.
  ///
  /// [actorIpAddress] - The Internet Protocol (IP) Address of host where the
  /// event was performed. This is an additional way to filter a report's
  /// summary using the IP address of the user whose activity is being reported.
  /// This IP address may or may not reflect the user's physical location. For
  /// example, the IP address can be the user's proxy server's address or a
  /// virtual private network (VPN) address. This parameter supports both IPv4
  /// and IPv6 address versions.
  ///
  /// [customerId] - The unique ID of the customer to retrieve data for.
  /// Value must have pattern `C.+|my_customer`.
  ///
  /// [endTime] - Sets the end of the range of time shown in the report. The
  /// date is in the RFC 3339 format, for example 2010-10-28T10:26:35.000Z. The
  /// default value is the approximate time of the API request. An API report
  /// has three basic time concepts: - *Date of the API's request for a report*:
  /// When the API created and retrieved the report. - *Report's start time*:
  /// The beginning of the timespan shown in the report. The `startTime` must be
  /// before the `endTime` (if specified) and the current time when the request
  /// is made, or the API returns an error. - *Report's end time*: The end of
  /// the timespan shown in the report. For example, the timespan of events
  /// summarized in a report can start in April and end in May. The report
  /// itself can be requested in August. If the `endTime` is not specified, the
  /// report returns all activities from the `startTime` until the current time
  /// or the most recent 180 days if the `startTime` is more than 180 days in
  /// the past.
  /// Value must have pattern
  /// `(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.(\d+))?(?:(Z)|(\[-+\])(\d\d):(\d\d))`.
  ///
  /// [eventName] - The name of the event being queried by the API. Each
  /// `eventName` is related to a specific Google Workspace service or feature
  /// which the API organizes into types of events. An example is the Google
  /// Calendar events in the Admin console application's reports. The Calendar
  /// Settings `type` structure has all of the Calendar `eventName` activities
  /// reported by the API. When an administrator changes a Calendar setting, the
  /// API reports this activity in the Calendar Settings `type` and `eventName`
  /// parameters. For more information about `eventName` query strings and
  /// parameters, see the list of event names for various applications above in
  /// `applicationName`.
  ///
  /// [filters] - The `filters` query string is a comma-separated list. The list
  /// is composed of event parameters that are manipulated by relational
  /// operators. Event parameters are in the form `parameter1 name[parameter1
  /// value],parameter2 name[parameter2 value],...` These event parameters are
  /// associated with a specific `eventName`. An empty report is returned if the
  /// filtered request's parameter does not belong to the `eventName`. For more
  /// information about `eventName` parameters, see the list of event names for
  /// various applications above in `applicationName`. In the following Admin
  /// Activity example, the <> operator is URL-encoded in the request's query
  /// string (%3C%3E): GET...&eventName=CHANGE_CALENDAR_SETTING
  /// &filters=NEW_VALUE%3C%3EREAD_ONLY_ACCESS In the following Drive example,
  /// the list can be a view or edit event's `doc_id` parameter with a value
  /// that is manipulated by an 'equal to' (==) or 'not equal to' (<>)
  /// relational operator. In the first example, the report returns each edited
  /// document's `doc_id`. In the second example, the report returns each viewed
  /// document's `doc_id` that equals the value 12345 and does not return any
  /// viewed document's which have a `doc_id` value of 98765. The <> operator is
  /// URL-encoded in the request's query string (%3C%3E):
  /// GET...&eventName=edit&filters=doc_id
  /// GET...&eventName=view&filters=doc_id==12345,doc_id%3C%3E98765 The
  /// relational operators include: - `==` - 'equal to'. - `<>` - 'not equal
  /// to'. It is URL-encoded (%3C%3E). - `<` - 'less than'. It is URL-encoded
  /// (%3C). - `<=` - 'less than or equal to'. It is URL-encoded (%3C=). - `>` -
  /// 'greater than'. It is URL-encoded (%3E). - `>=` - 'greater than or equal
  /// to'. It is URL-encoded (%3E=). *Note:* The API doesn't accept multiple
  /// values of a parameter. If a particular parameter is supplied more than
  /// once in the API request, the API only accepts the last value of that
  /// request parameter. In addition, if an invalid request parameter is
  /// supplied in the API request, the API ignores that request parameter and
  /// returns the response corresponding to the remaining valid request
  /// parameters. If no parameters are requested, all parameters are returned.
  /// Value must have pattern
  /// `(.+\[<,<=,==,>=,>,<>\].+,)*(.+\[<,<=,==,>=,>,<>\].+)`.
  ///
  /// [groupIdFilter] - Comma separated group ids (obfuscated) on which user
  /// activities are filtered, i.e, the response will contain activities for
  /// only those users that are a part of at least one of the group ids
  /// mentioned here. Format: "id:abc123,id:xyz456"
  /// Value must have pattern `(id:\[a-z0-9\]+(,id:\[a-z0-9\]+)*)`.
  ///
  /// [maxResults] - Determines how many activity records are shown on each
  /// response page. For example, if the request sets `maxResults=1` and the
  /// report has two activities, the report has two pages. The response's
  /// `nextPageToken` property has the token to the second page. The
  /// `maxResults` query string is optional in the request. The default value is
  /// 1000.
  /// Value must be between "1" and "1000".
  ///
  /// [orgUnitID] - ID of the organizational unit to report on. Activity records
  /// will be shown only for users who belong to the specified organizational
  /// unit. Data before Dec 17, 2018 doesn't appear in the filtered results.
  /// Value must have pattern `(id:\[a-z0-9\]+)`.
  ///
  /// [pageToken] - The token to specify next page. A report with multiple pages
  /// has a `nextPageToken` property in the response. In your follow-on request
  /// getting the next page of the report, enter the `nextPageToken` value in
  /// the `pageToken` query string.
  ///
  /// [startTime] - Sets the beginning of the range of time shown in the report.
  /// The date is in the RFC 3339 format, for example 2010-10-28T10:26:35.000Z.
  /// The report returns all activities from `startTime` until `endTime`. The
  /// `startTime` must be before the `endTime` (if specified) and the current
  /// time when the request is made, or the API returns an error.
  /// Value must have pattern
  /// `(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.(\d+))?(?:(Z)|(\[-+\])(\d\d):(\d\d))`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Activities].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Activities> list(
    core.String userKey,
    core.String applicationName, {
    core.String? actorIpAddress,
    core.String? customerId,
    core.String? endTime,
    core.String? eventName,
    core.String? filters,
    core.String? groupIdFilter,
    core.int? maxResults,
    core.String? orgUnitID,
    core.String? pageToken,
    core.String? startTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (actorIpAddress != null) 'actorIpAddress': [actorIpAddress],
      if (customerId != null) 'customerId': [customerId],
      if (endTime != null) 'endTime': [endTime],
      if (eventName != null) 'eventName': [eventName],
      if (filters != null) 'filters': [filters],
      if (groupIdFilter != null) 'groupIdFilter': [groupIdFilter],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orgUnitID != null) 'orgUnitID': [orgUnitID],
      if (pageToken != null) 'pageToken': [pageToken],
      if (startTime != null) 'startTime': [startTime],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/reports/v1/activity/users/' +
        commons.escapeVariable('$userKey') +
        '/applications/' +
        commons.escapeVariable('$applicationName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Activities.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Start receiving notifications for account activities.
  ///
  /// For more information, see Receiving Push Notifications.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Represents the profile ID or the user email for which the data
  /// should be filtered. Can be `all` for all information, or `userKey` for a
  /// user's unique Google Workspace profile ID or their primary email address.
  ///
  /// [applicationName] - Application name for which the events are to be
  /// retrieved.
  /// Value must have pattern
  /// `(access_transparency)|(admin)|(calendar)|(chat)|(chrome)|(context_aware_access)|(data_studio)|(drive)|(gcp)|(gplus)|(groups)|(groups_enterprise)|(jamboard)|(keep)|(login)|(meet)|(mobile)|(rules)|(saml)|(token)|(user_accounts)`.
  /// Possible string values are:
  /// - "access_transparency" : The Google Workspace Access Transparency
  /// activity reports return information about different types of Access
  /// Transparency activity events.
  /// - "admin" : The Admin console application's activity reports return
  /// account information about different types of administrator activity
  /// events.
  /// - "calendar" : The Google Calendar application's activity reports return
  /// information about various Calendar activity events.
  /// - "chat" : The Chat activity reports return information about various Chat
  /// activity events.
  /// - "drive" : The Google Drive application's activity reports return
  /// information about various Google Drive activity events. The Drive activity
  /// report is only available for Google Workspace Business and Google
  /// Workspace Enterprise customers.
  /// - "gcp" : The Google Cloud Platform application's activity reports return
  /// information about various GCP activity events.
  /// - "gplus" : The Google+ application's activity reports return information
  /// about various Google+ activity events.
  /// - "groups" : The Google Groups application's activity reports return
  /// information about various Groups activity events.
  /// - "groups_enterprise" : The Enterprise Groups activity reports return
  /// information about various Enterprise group activity events.
  /// - "jamboard" : The Jamboard activity reports return information about
  /// various Jamboard activity events.
  /// - "login" : The Login application's activity reports return account
  /// information about different types of Login activity events.
  /// - "meet" : The Meet Audit activity report return information about
  /// different types of Meet Audit activity events.
  /// - "mobile" : The Mobile Audit activity report return information about
  /// different types of Mobile Audit activity events.
  /// - "rules" : The Rules activity report return information about different
  /// types of Rules activity events.
  /// - "saml" : The SAML activity report return information about different
  /// types of SAML activity events.
  /// - "token" : The Token application's activity reports return account
  /// information about different types of Token activity events.
  /// - "user_accounts" : The User Accounts application's activity reports
  /// return account information about different types of User Accounts activity
  /// events.
  /// - "context_aware_access" : The Context-aware access activity reports
  /// return information about users' access denied events due to Context-aware
  /// access rules.
  /// - "chrome" : The Chrome activity reports return information about unsafe
  /// events reported in the context of the WebProtect features of BeyondCorp.
  /// - "data_studio" : The Data Studio activity reports return information
  /// about various types of Data Studio activity events.
  /// - "keep" : The Keep application's activity reports return information
  /// about various Google Keep activity events. The Keep activity report is
  /// only available for Google Workspace Business and Enterprise customers.
  ///
  /// [actorIpAddress] - The Internet Protocol (IP) Address of host where the
  /// event was performed. This is an additional way to filter a report's
  /// summary using the IP address of the user whose activity is being reported.
  /// This IP address may or may not reflect the user's physical location. For
  /// example, the IP address can be the user's proxy server's address or a
  /// virtual private network (VPN) address. This parameter supports both IPv4
  /// and IPv6 address versions.
  ///
  /// [customerId] - The unique ID of the customer to retrieve data for.
  /// Value must have pattern `C.+|my_customer`.
  ///
  /// [endTime] - Sets the end of the range of time shown in the report. The
  /// date is in the RFC 3339 format, for example 2010-10-28T10:26:35.000Z. The
  /// default value is the approximate time of the API request. An API report
  /// has three basic time concepts: - *Date of the API's request for a report*:
  /// When the API created and retrieved the report. - *Report's start time*:
  /// The beginning of the timespan shown in the report. The `startTime` must be
  /// before the `endTime` (if specified) and the current time when the request
  /// is made, or the API returns an error. - *Report's end time*: The end of
  /// the timespan shown in the report. For example, the timespan of events
  /// summarized in a report can start in April and end in May. The report
  /// itself can be requested in August. If the `endTime` is not specified, the
  /// report returns all activities from the `startTime` until the current time
  /// or the most recent 180 days if the `startTime` is more than 180 days in
  /// the past.
  /// Value must have pattern
  /// `(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.(\d+))?(?:(Z)|(\[-+\])(\d\d):(\d\d))`.
  ///
  /// [eventName] - The name of the event being queried by the API. Each
  /// `eventName` is related to a specific Google Workspace service or feature
  /// which the API organizes into types of events. An example is the Google
  /// Calendar events in the Admin console application's reports. The Calendar
  /// Settings `type` structure has all of the Calendar `eventName` activities
  /// reported by the API. When an administrator changes a Calendar setting, the
  /// API reports this activity in the Calendar Settings `type` and `eventName`
  /// parameters. For more information about `eventName` query strings and
  /// parameters, see the list of event names for various applications above in
  /// `applicationName`.
  ///
  /// [filters] - The `filters` query string is a comma-separated list. The list
  /// is composed of event parameters that are manipulated by relational
  /// operators. Event parameters are in the form `parameter1 name[parameter1
  /// value],parameter2 name[parameter2 value],...` These event parameters are
  /// associated with a specific `eventName`. An empty report is returned if the
  /// filtered request's parameter does not belong to the `eventName`. For more
  /// information about `eventName` parameters, see the list of event names for
  /// various applications above in `applicationName`. In the following Admin
  /// Activity example, the <> operator is URL-encoded in the request's query
  /// string (%3C%3E): GET...&eventName=CHANGE_CALENDAR_SETTING
  /// &filters=NEW_VALUE%3C%3EREAD_ONLY_ACCESS In the following Drive example,
  /// the list can be a view or edit event's `doc_id` parameter with a value
  /// that is manipulated by an 'equal to' (==) or 'not equal to' (<>)
  /// relational operator. In the first example, the report returns each edited
  /// document's `doc_id`. In the second example, the report returns each viewed
  /// document's `doc_id` that equals the value 12345 and does not return any
  /// viewed document's which have a `doc_id` value of 98765. The <> operator is
  /// URL-encoded in the request's query string (%3C%3E):
  /// GET...&eventName=edit&filters=doc_id
  /// GET...&eventName=view&filters=doc_id==12345,doc_id%3C%3E98765 The
  /// relational operators include: - `==` - 'equal to'. - `<>` - 'not equal
  /// to'. It is URL-encoded (%3C%3E). - `<` - 'less than'. It is URL-encoded
  /// (%3C). - `<=` - 'less than or equal to'. It is URL-encoded (%3C=). - `>` -
  /// 'greater than'. It is URL-encoded (%3E). - `>=` - 'greater than or equal
  /// to'. It is URL-encoded (%3E=). *Note:* The API doesn't accept multiple
  /// values of a parameter. If a particular parameter is supplied more than
  /// once in the API request, the API only accepts the last value of that
  /// request parameter. In addition, if an invalid request parameter is
  /// supplied in the API request, the API ignores that request parameter and
  /// returns the response corresponding to the remaining valid request
  /// parameters. If no parameters are requested, all parameters are returned.
  /// Value must have pattern
  /// `(.+\[<,<=,==,>=,>,<>\].+,)*(.+\[<,<=,==,>=,>,<>\].+)`.
  ///
  /// [groupIdFilter] - Comma separated group ids (obfuscated) on which user
  /// activities are filtered, i.e, the response will contain activities for
  /// only those users that are a part of at least one of the group ids
  /// mentioned here. Format: "id:abc123,id:xyz456"
  /// Value must have pattern `(id:\[a-z0-9\]+(,id:\[a-z0-9\]+)*)`.
  ///
  /// [maxResults] - Determines how many activity records are shown on each
  /// response page. For example, if the request sets `maxResults=1` and the
  /// report has two activities, the report has two pages. The response's
  /// `nextPageToken` property has the token to the second page. The
  /// `maxResults` query string is optional in the request. The default value is
  /// 1000.
  /// Value must be between "1" and "1000".
  ///
  /// [orgUnitID] - ID of the organizational unit to report on. Activity records
  /// will be shown only for users who belong to the specified organizational
  /// unit. Data before Dec 17, 2018 doesn't appear in the filtered results.
  /// Value must have pattern `(id:\[a-z0-9\]+)`.
  ///
  /// [pageToken] - The token to specify next page. A report with multiple pages
  /// has a `nextPageToken` property in the response. In your follow-on request
  /// getting the next page of the report, enter the `nextPageToken` value in
  /// the `pageToken` query string.
  ///
  /// [startTime] - Sets the beginning of the range of time shown in the report.
  /// The date is in the RFC 3339 format, for example 2010-10-28T10:26:35.000Z.
  /// The report returns all activities from `startTime` until `endTime`. The
  /// `startTime` must be before the `endTime` (if specified) and the current
  /// time when the request is made, or the API returns an error.
  /// Value must have pattern
  /// `(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.(\d+))?(?:(Z)|(\[-+\])(\d\d):(\d\d))`.
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
    core.String userKey,
    core.String applicationName, {
    core.String? actorIpAddress,
    core.String? customerId,
    core.String? endTime,
    core.String? eventName,
    core.String? filters,
    core.String? groupIdFilter,
    core.int? maxResults,
    core.String? orgUnitID,
    core.String? pageToken,
    core.String? startTime,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (actorIpAddress != null) 'actorIpAddress': [actorIpAddress],
      if (customerId != null) 'customerId': [customerId],
      if (endTime != null) 'endTime': [endTime],
      if (eventName != null) 'eventName': [eventName],
      if (filters != null) 'filters': [filters],
      if (groupIdFilter != null) 'groupIdFilter': [groupIdFilter],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orgUnitID != null) 'orgUnitID': [orgUnitID],
      if (pageToken != null) 'pageToken': [pageToken],
      if (startTime != null) 'startTime': [startTime],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/reports/v1/activity/users/' +
        commons.escapeVariable('$userKey') +
        '/applications/' +
        commons.escapeVariable('$applicationName') +
        '/watch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Channel.fromJson(_response as core.Map<core.String, core.dynamic>);
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

    const _url = 'admin/reports_v1/channels/stop';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }
}

class CustomerUsageReportsResource {
  final commons.ApiRequester _requester;

  CustomerUsageReportsResource(commons.ApiRequester client)
      : _requester = client;

  /// Retrieves a report which is a collection of properties and statistics for
  /// a specific customer's account.
  ///
  /// For more information, see the Customers Usage Report guide. For more
  /// information about the customer report's parameters, see the Customers
  /// Usage parameters reference guides.
  ///
  /// Request parameters:
  ///
  /// [date] - Represents the date the usage occurred. The timestamp is in the
  /// ISO 8601 format, yyyy-mm-dd. We recommend you use your account's time zone
  /// for this.
  /// Value must have pattern `(\d){4}-(\d){2}-(\d){2}`.
  ///
  /// [customerId] - The unique ID of the customer to retrieve data for.
  /// Value must have pattern `C.+|my_customer`.
  ///
  /// [pageToken] - Token to specify next page. A report with multiple pages has
  /// a `nextPageToken` property in the response. For your follow-on requests
  /// getting all of the report's pages, enter the `nextPageToken` value in the
  /// `pageToken` query string.
  ///
  /// [parameters] - The `parameters` query string is a comma-separated list of
  /// event parameters that refine a report's results. The parameter is
  /// associated with a specific application. The application values for the
  /// Customers usage report include `accounts`, `app_maker`, `apps_scripts`,
  /// `calendar`, `classroom`, `cros`, `docs`, `gmail`, `gplus`,
  /// `device_management`, `meet`, and `sites`. A `parameters` query string is
  /// in the CSV form of `app_name1:param_name1, app_name2:param_name2`. *Note:*
  /// The API doesn't accept multiple values of a parameter. If a particular
  /// parameter is supplied more than once in the API request, the API only
  /// accepts the last value of that request parameter. In addition, if an
  /// invalid request parameter is supplied in the API request, the API ignores
  /// that request parameter and returns the response corresponding to the
  /// remaining valid request parameters. An example of an invalid request
  /// parameter is one that does not belong to the application. If no parameters
  /// are requested, all parameters are returned.
  /// Value must have pattern
  /// `(((accounts)|(app_maker)|(apps_scripts)|(classroom)|(cros)|(gmail)|(calendar)|(docs)|(gplus)|(sites)|(device_management)|(drive)|(meet)):\[^,\]+,)*(((accounts)|(app_maker)|(apps_scripts)|(classroom)|(cros)|(gmail)|(calendar)|(docs)|(gplus)|(sites)|(device_management)|(drive)|(meet)):\[^,\]+)`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UsageReports].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UsageReports> get(
    core.String date, {
    core.String? customerId,
    core.String? pageToken,
    core.String? parameters,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customerId != null) 'customerId': [customerId],
      if (pageToken != null) 'pageToken': [pageToken],
      if (parameters != null) 'parameters': [parameters],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'admin/reports/v1/usage/dates/' + commons.escapeVariable('$date');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UsageReports.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class EntityUsageReportsResource {
  final commons.ApiRequester _requester;

  EntityUsageReportsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a report which is a collection of properties and statistics for
  /// entities used by users within the account.
  ///
  /// For more information, see the Entities Usage Report guide. For more
  /// information about the entities report's parameters, see the Entities Usage
  /// parameters reference guides.
  ///
  /// Request parameters:
  ///
  /// [entityType] - Represents the type of entity for the report.
  /// Value must have pattern `(gplus_communities)`.
  /// Possible string values are:
  /// - "gplus_communities" : Returns a report on Google+ communities.
  ///
  /// [entityKey] - Represents the key of the object to filter the data with.
  /// Possible string values are:
  /// - "all" : Returns activity events for all users.
  /// - "entityKey" : Represents an app-specific identifier for the entity. For
  /// details on how to obtain the `entityKey` for a particular `entityType`,
  /// see the Entities Usage parameters reference guides.
  ///
  /// [date] - Represents the date the usage occurred. The timestamp is in the
  /// ISO 8601 format, yyyy-mm-dd. We recommend you use your account's time zone
  /// for this.
  /// Value must have pattern `(\d){4}-(\d){2}-(\d){2}`.
  ///
  /// [customerId] - The unique ID of the customer to retrieve data for.
  /// Value must have pattern `C.+|my_customer`.
  ///
  /// [filters] - The `filters` query string is a comma-separated list of an
  /// application's event parameters where the parameter's value is manipulated
  /// by a relational operator. The `filters` query string includes the name of
  /// the application whose usage is returned in the report. The application
  /// values for the Entities usage report include `accounts`, `docs`, and
  /// `gmail`. Filters are in the form `[application name]:parameter
  /// name[parameter value],...`. In this example, the `<>` 'not equal to'
  /// operator is URL-encoded in the request's query string (%3C%3E): GET
  /// https://www.googleapis.com/admin/reports/v1/usage/gplus_communities/all/dates/2017-12-01
  /// ?parameters=gplus:community_name,gplus:num_total_members
  /// &filters=gplus:num_total_members%3C%3E0 The relational operators include:
  /// - `==` - 'equal to'. - `<>` - 'not equal to'. It is URL-encoded (%3C%3E).
  /// - `<` - 'less than'. It is URL-encoded (%3C). - `<=` - 'less than or equal
  /// to'. It is URL-encoded (%3C=). - `>` - 'greater than'. It is URL-encoded
  /// (%3E). - `>=` - 'greater than or equal to'. It is URL-encoded (%3E=).
  /// Filters can only be applied to numeric parameters.
  /// Value must have pattern
  /// `(((gplus)):\[a-z0-9_\]+\[<,<=,==,>=,>,!=\]\[^,\]+,)*(((gplus)):\[a-z0-9_\]+\[<,<=,==,>=,>,!=\]\[^,\]+)`.
  ///
  /// [maxResults] - Determines how many activity records are shown on each
  /// response page. For example, if the request sets `maxResults=1` and the
  /// report has two activities, the report has two pages. The response's
  /// `nextPageToken` property has the token to the second page.
  /// Value must be between "1" and "1000".
  ///
  /// [pageToken] - Token to specify next page. A report with multiple pages has
  /// a `nextPageToken` property in the response. In your follow-on request
  /// getting the next page of the report, enter the `nextPageToken` value in
  /// the `pageToken` query string.
  ///
  /// [parameters] - The `parameters` query string is a comma-separated list of
  /// event parameters that refine a report's results. The parameter is
  /// associated with a specific application. The application values for the
  /// Entities usage report are only `gplus`. A `parameter` query string is in
  /// the CSV form of `[app_name1:param_name1], [app_name2:param_name2]...`.
  /// *Note:* The API doesn't accept multiple values of a parameter. If a
  /// particular parameter is supplied more than once in the API request, the
  /// API only accepts the last value of that request parameter. In addition, if
  /// an invalid request parameter is supplied in the API request, the API
  /// ignores that request parameter and returns the response corresponding to
  /// the remaining valid request parameters. An example of an invalid request
  /// parameter is one that does not belong to the application. If no parameters
  /// are requested, all parameters are returned.
  /// Value must have pattern `(((gplus)):\[^,\]+,)*(((gplus)):\[^,\]+)`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UsageReports].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UsageReports> get(
    core.String entityType,
    core.String entityKey,
    core.String date, {
    core.String? customerId,
    core.String? filters,
    core.int? maxResults,
    core.String? pageToken,
    core.String? parameters,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customerId != null) 'customerId': [customerId],
      if (filters != null) 'filters': [filters],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (parameters != null) 'parameters': [parameters],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/reports/v1/usage/' +
        commons.escapeVariable('$entityType') +
        '/' +
        commons.escapeVariable('$entityKey') +
        '/dates/' +
        commons.escapeVariable('$date');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UsageReports.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class UserUsageReportResource {
  final commons.ApiRequester _requester;

  UserUsageReportResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a report which is a collection of properties and statistics for
  /// a set of users with the account.
  ///
  /// For more information, see the User Usage Report guide. For more
  /// information about the user report's parameters, see the Users Usage
  /// parameters reference guides.
  ///
  /// Request parameters:
  ///
  /// [userKey] - Represents the profile ID or the user email for which the data
  /// should be filtered. Can be `all` for all information, or `userKey` for a
  /// user's unique Google Workspace profile ID or their primary email address.
  ///
  /// [date] - Represents the date the usage occurred. The timestamp is in the
  /// ISO 8601 format, yyyy-mm-dd. We recommend you use your account's time zone
  /// for this.
  /// Value must have pattern `(\d){4}-(\d){2}-(\d){2}`.
  ///
  /// [customerId] - The unique ID of the customer to retrieve data for.
  /// Value must have pattern `C.+|my_customer`.
  ///
  /// [filters] - The `filters` query string is a comma-separated list of an
  /// application's event parameters where the parameter's value is manipulated
  /// by a relational operator. The `filters` query string includes the name of
  /// the application whose usage is returned in the report. The application
  /// values for the Users Usage Report include `accounts`, `docs`, and `gmail`.
  /// Filters are in the form `[application name]:parameter name[parameter
  /// value],...`. In this example, the `<>` 'not equal to' operator is
  /// URL-encoded in the request's query string (%3C%3E): GET
  /// https://www.googleapis.com/admin/reports/v1/usage/users/all/dates/2013-03-03
  /// ?parameters=accounts:last_login_time
  /// &filters=accounts:last_login_time%3C%3E2010-10-28T10:26:35.000Z The
  /// relational operators include: - `==` - 'equal to'. - `<>` - 'not equal
  /// to'. It is URL-encoded (%3C%3E). - `<` - 'less than'. It is URL-encoded
  /// (%3C). - `<=` - 'less than or equal to'. It is URL-encoded (%3C=). - `>` -
  /// 'greater than'. It is URL-encoded (%3E). - `>=` - 'greater than or equal
  /// to'. It is URL-encoded (%3E=).
  /// Value must have pattern
  /// `(((accounts)|(classroom)|(cros)|(gmail)|(calendar)|(docs)|(gplus)|(sites)|(device_management)|(drive)):\[a-z0-9_\]+\[<,<=,==,>=,>,!=\]\[^,\]+,)*(((accounts)|(classroom)|(cros)|(gmail)|(calendar)|(docs)|(gplus)|(sites)|(device_management)|(drive)):\[a-z0-9_\]+\[<,<=,==,>=,>,!=\]\[^,\]+)`.
  ///
  /// [groupIdFilter] - Comma separated group ids (obfuscated) on which user
  /// activities are filtered, i.e, the response will contain activities for
  /// only those users that are a part of at least one of the group ids
  /// mentioned here. Format: "id:abc123,id:xyz456"
  /// Value must have pattern `(id:\[a-z0-9\]+(,id:\[a-z0-9\]+)*)`.
  ///
  /// [maxResults] - Determines how many activity records are shown on each
  /// response page. For example, if the request sets `maxResults=1` and the
  /// report has two activities, the report has two pages. The response's
  /// `nextPageToken` property has the token to the second page. The
  /// `maxResults` query string is optional.
  /// Value must be between "1" and "1000".
  ///
  /// [orgUnitID] - ID of the organizational unit to report on. User activity
  /// will be shown only for users who belong to the specified organizational
  /// unit. Data before Dec 17, 2018 doesn't appear in the filtered results.
  /// Value must have pattern `(id:\[a-z0-9\]+)`.
  ///
  /// [pageToken] - Token to specify next page. A report with multiple pages has
  /// a `nextPageToken` property in the response. In your follow-on request
  /// getting the next page of the report, enter the `nextPageToken` value in
  /// the `pageToken` query string.
  ///
  /// [parameters] - The `parameters` query string is a comma-separated list of
  /// event parameters that refine a report's results. The parameter is
  /// associated with a specific application. The application values for the
  /// Customers Usage report include `accounts`, `app_maker`, `apps_scripts`,
  /// `calendar`, `classroom`, `cros`, `docs`, `gmail`, `gplus`,
  /// `device_management`, `meet`, and `sites`. A `parameters` query string is
  /// in the CSV form of `app_name1:param_name1, app_name2:param_name2`. *Note:*
  /// The API doesn't accept multiple values of a parameter. If a particular
  /// parameter is supplied more than once in the API request, the API only
  /// accepts the last value of that request parameter. In addition, if an
  /// invalid request parameter is supplied in the API request, the API ignores
  /// that request parameter and returns the response corresponding to the
  /// remaining valid request parameters. An example of an invalid request
  /// parameter is one that does not belong to the application. If no parameters
  /// are requested, all parameters are returned.
  /// Value must have pattern
  /// `(((accounts)|(classroom)|(cros)|(gmail)|(calendar)|(docs)|(gplus)|(sites)|(device_management)|(drive)):\[^,\]+,)*(((accounts)|(classroom)|(cros)|(gmail)|(calendar)|(docs)|(gplus)|(sites)|(device_management)|(drive)):\[^,\]+)`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UsageReports].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UsageReports> get(
    core.String userKey,
    core.String date, {
    core.String? customerId,
    core.String? filters,
    core.String? groupIdFilter,
    core.int? maxResults,
    core.String? orgUnitID,
    core.String? pageToken,
    core.String? parameters,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customerId != null) 'customerId': [customerId],
      if (filters != null) 'filters': [filters],
      if (groupIdFilter != null) 'groupIdFilter': [groupIdFilter],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orgUnitID != null) 'orgUnitID': [orgUnitID],
      if (pageToken != null) 'pageToken': [pageToken],
      if (parameters != null) 'parameters': [parameters],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/reports/v1/usage/users/' +
        commons.escapeVariable('$userKey') +
        '/dates/' +
        commons.escapeVariable('$date');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UsageReports.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// JSON template for a collection of activities.
class Activities {
  /// ETag of the resource.
  core.String? etag;

  /// Each activity record in the response.
  core.List<Activity>? items;

  /// The type of API resource.
  ///
  /// For an activity report, the value is `reports#activities`.
  core.String? kind;

  /// Token for retrieving the follow-on next page of the report.
  ///
  /// The `nextPageToken` value is used in the request's `pageToken` query
  /// string.
  core.String? nextPageToken;

  Activities();

  Activities.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Activity>((value) =>
              Activity.fromJson(value as core.Map<core.String, core.dynamic>))
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

/// User doing the action.
class ActivityActor {
  /// The type of actor.
  core.String? callerType;

  /// The primary email address of the actor.
  ///
  /// May be absent if there is no email address associated with the actor.
  core.String? email;

  /// Only present when `callerType` is `KEY`.
  ///
  /// Can be the `consumer_key` of the requestor for OAuth 2LO API requests or
  /// an identifier for robot accounts.
  core.String? key;

  /// The unique Google Workspace profile ID of the actor.
  ///
  /// May be absent if the actor is not a Google Workspace user.
  core.String? profileId;

  ActivityActor();

  ActivityActor.fromJson(core.Map _json) {
    if (_json.containsKey('callerType')) {
      callerType = _json['callerType'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('profileId')) {
      profileId = _json['profileId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (callerType != null) 'callerType': callerType!,
        if (email != null) 'email': email!,
        if (key != null) 'key': key!,
        if (profileId != null) 'profileId': profileId!,
      };
}

/// Nested parameter value pairs associated with this parameter.
///
/// Complex value type for a parameter are returned as a list of parameter
/// values. For example, the address parameter may have a value as `[{parameter:
/// [{name: city, value: abc}]}]`
class ActivityEventsParametersMessageValue {
  /// Parameter values
  core.List<NestedParameter>? parameter;

  ActivityEventsParametersMessageValue();

  ActivityEventsParametersMessageValue.fromJson(core.Map _json) {
    if (_json.containsKey('parameter')) {
      parameter = (_json['parameter'] as core.List)
          .map<NestedParameter>((value) => NestedParameter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameter != null)
          'parameter': parameter!.map((value) => value.toJson()).toList(),
      };
}

class ActivityEventsParametersMultiMessageValue {
  /// Parameter values
  core.List<NestedParameter>? parameter;

  ActivityEventsParametersMultiMessageValue();

  ActivityEventsParametersMultiMessageValue.fromJson(core.Map _json) {
    if (_json.containsKey('parameter')) {
      parameter = (_json['parameter'] as core.List)
          .map<NestedParameter>((value) => NestedParameter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameter != null)
          'parameter': parameter!.map((value) => value.toJson()).toList(),
      };
}

class ActivityEventsParameters {
  /// Boolean value of the parameter.
  core.bool? boolValue;

  /// Integer value of the parameter.
  core.String? intValue;

  /// Nested parameter value pairs associated with this parameter.
  ///
  /// Complex value type for a parameter are returned as a list of parameter
  /// values. For example, the address parameter may have a value as
  /// `[{parameter: [{name: city, value: abc}]}]`
  ActivityEventsParametersMessageValue? messageValue;

  /// Integer values of the parameter.
  core.List<core.String>? multiIntValue;

  /// List of `messageValue` objects.
  core.List<ActivityEventsParametersMultiMessageValue>? multiMessageValue;

  /// String values of the parameter.
  core.List<core.String>? multiValue;

  /// The name of the parameter.
  core.String? name;

  /// String value of the parameter.
  core.String? value;

  ActivityEventsParameters();

  ActivityEventsParameters.fromJson(core.Map _json) {
    if (_json.containsKey('boolValue')) {
      boolValue = _json['boolValue'] as core.bool;
    }
    if (_json.containsKey('intValue')) {
      intValue = _json['intValue'] as core.String;
    }
    if (_json.containsKey('messageValue')) {
      messageValue = ActivityEventsParametersMessageValue.fromJson(
          _json['messageValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('multiIntValue')) {
      multiIntValue = (_json['multiIntValue'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('multiMessageValue')) {
      multiMessageValue = (_json['multiMessageValue'] as core.List)
          .map<ActivityEventsParametersMultiMessageValue>((value) =>
              ActivityEventsParametersMultiMessageValue.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('multiValue')) {
      multiValue = (_json['multiValue'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (boolValue != null) 'boolValue': boolValue!,
        if (intValue != null) 'intValue': intValue!,
        if (messageValue != null) 'messageValue': messageValue!.toJson(),
        if (multiIntValue != null) 'multiIntValue': multiIntValue!,
        if (multiMessageValue != null)
          'multiMessageValue':
              multiMessageValue!.map((value) => value.toJson()).toList(),
        if (multiValue != null) 'multiValue': multiValue!,
        if (name != null) 'name': name!,
        if (value != null) 'value': value!,
      };
}

class ActivityEvents {
  /// Name of the event.
  ///
  /// This is the specific name of the activity reported by the API. And each
  /// `eventName` is related to a specific Google Workspace service or feature
  /// which the API organizes into types of events. For `eventName` request
  /// parameters in general: - If no `eventName` is given, the report returns
  /// all possible instances of an `eventName`. - When you request an
  /// `eventName`, the API's response returns all activities which contain that
  /// `eventName`. It is possible that the returned activities will have other
  /// `eventName` properties in addition to the one requested. For more
  /// information about `eventName` properties, see the list of event names for
  /// various applications above in `applicationName`.
  core.String? name;

  /// Parameter value pairs for various applications.
  ///
  /// For more information about `eventName` parameters, see the list of event
  /// names for various applications above in `applicationName`.
  core.List<ActivityEventsParameters>? parameters;

  /// Type of event.
  ///
  /// The Google Workspace service or feature that an administrator changes is
  /// identified in the `type` property which identifies an event using the
  /// `eventName` property. For a full list of the API's `type` categories, see
  /// the list of event names for various applications above in
  /// `applicationName`.
  core.String? type;

  ActivityEvents();

  ActivityEvents.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<ActivityEventsParameters>((value) =>
              ActivityEventsParameters.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
        if (type != null) 'type': type!,
      };
}

/// Unique identifier for each activity record.
class ActivityId {
  /// Application name to which the event belongs.
  ///
  /// For possible values see the list of applications above in
  /// `applicationName`.
  core.String? applicationName;

  /// The unique identifier for a Google Workspace account.
  core.String? customerId;

  /// Time of occurrence of the activity.
  ///
  /// This is in UNIX epoch time in seconds.
  core.DateTime? time;

  /// Unique qualifier if multiple events have the same time.
  core.String? uniqueQualifier;

  ActivityId();

  ActivityId.fromJson(core.Map _json) {
    if (_json.containsKey('applicationName')) {
      applicationName = _json['applicationName'] as core.String;
    }
    if (_json.containsKey('customerId')) {
      customerId = _json['customerId'] as core.String;
    }
    if (_json.containsKey('time')) {
      time = core.DateTime.parse(_json['time'] as core.String);
    }
    if (_json.containsKey('uniqueQualifier')) {
      uniqueQualifier = _json['uniqueQualifier'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applicationName != null) 'applicationName': applicationName!,
        if (customerId != null) 'customerId': customerId!,
        if (time != null) 'time': time!.toIso8601String(),
        if (uniqueQualifier != null) 'uniqueQualifier': uniqueQualifier!,
      };
}

/// JSON template for the activity resource.
class Activity {
  /// User doing the action.
  ActivityActor? actor;

  /// ETag of the entry.
  core.String? etag;

  /// Activity events in the report.
  core.List<ActivityEvents>? events;

  /// Unique identifier for each activity record.
  ActivityId? id;

  /// IP address of the user doing the action.
  ///
  /// This is the Internet Protocol (IP) address of the user when logging into
  /// Google Workspace, which may or may not reflect the user's physical
  /// location. For example, the IP address can be the user's proxy server's
  /// address or a virtual private network (VPN) address. The API supports IPv4
  /// and IPv6.
  core.String? ipAddress;

  /// The type of API resource.
  ///
  /// For an activity report, the value is `audit#activity`.
  core.String? kind;

  /// This is the domain that is affected by the report's event.
  ///
  /// For example domain of Admin console or the Drive application's document
  /// owner.
  core.String? ownerDomain;

  Activity();

  Activity.fromJson(core.Map _json) {
    if (_json.containsKey('actor')) {
      actor = ActivityActor.fromJson(
          _json['actor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('events')) {
      events = (_json['events'] as core.List)
          .map<ActivityEvents>((value) => ActivityEvents.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('id')) {
      id = ActivityId.fromJson(
          _json['id'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ipAddress')) {
      ipAddress = _json['ipAddress'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('ownerDomain')) {
      ownerDomain = _json['ownerDomain'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actor != null) 'actor': actor!.toJson(),
        if (etag != null) 'etag': etag!,
        if (events != null)
          'events': events!.map((value) => value.toJson()).toList(),
        if (id != null) 'id': id!.toJson(),
        if (ipAddress != null) 'ipAddress': ipAddress!,
        if (kind != null) 'kind': kind!,
        if (ownerDomain != null) 'ownerDomain': ownerDomain!,
      };
}

/// A notification channel used to watch for resource changes.
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
  /// resource, which is "`api#channel`".
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
  ///
  /// The value should be set to `"web_hook"`.
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

/// JSON template for a parameter used in various reports.
class NestedParameter {
  /// Boolean value of the parameter.
  core.bool? boolValue;

  /// Integer value of the parameter.
  core.String? intValue;

  /// Multiple boolean values of the parameter.
  core.List<core.bool>? multiBoolValue;

  /// Multiple integer values of the parameter.
  core.List<core.String>? multiIntValue;

  /// Multiple string values of the parameter.
  core.List<core.String>? multiValue;

  /// The name of the parameter.
  core.String? name;

  /// String value of the parameter.
  core.String? value;

  NestedParameter();

  NestedParameter.fromJson(core.Map _json) {
    if (_json.containsKey('boolValue')) {
      boolValue = _json['boolValue'] as core.bool;
    }
    if (_json.containsKey('intValue')) {
      intValue = _json['intValue'] as core.String;
    }
    if (_json.containsKey('multiBoolValue')) {
      multiBoolValue = (_json['multiBoolValue'] as core.List)
          .map<core.bool>((value) => value as core.bool)
          .toList();
    }
    if (_json.containsKey('multiIntValue')) {
      multiIntValue = (_json['multiIntValue'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('multiValue')) {
      multiValue = (_json['multiValue'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (boolValue != null) 'boolValue': boolValue!,
        if (intValue != null) 'intValue': intValue!,
        if (multiBoolValue != null) 'multiBoolValue': multiBoolValue!,
        if (multiIntValue != null) 'multiIntValue': multiIntValue!,
        if (multiValue != null) 'multiValue': multiValue!,
        if (name != null) 'name': name!,
        if (value != null) 'value': value!,
      };
}

/// Information about the type of the item.
///
/// Output only.
class UsageReportEntity {
  /// The unique identifier of the customer's account.
  ///
  /// Output only.
  core.String? customerId;

  /// Object key.
  ///
  /// Only relevant if entity.type = "OBJECT" Note: external-facing name of
  /// report is "Entities" rather than "Objects".
  ///
  /// Output only.
  core.String? entityId;

  /// The user's immutable Google Workspace profile identifier.
  ///
  /// Output only.
  core.String? profileId;

  /// The type of item.
  ///
  /// The value is `user`.
  ///
  /// Output only.
  core.String? type;

  /// The user's email address.
  ///
  /// Only relevant if entity.type = "USER"
  ///
  /// Output only.
  core.String? userEmail;

  UsageReportEntity();

  UsageReportEntity.fromJson(core.Map _json) {
    if (_json.containsKey('customerId')) {
      customerId = _json['customerId'] as core.String;
    }
    if (_json.containsKey('entityId')) {
      entityId = _json['entityId'] as core.String;
    }
    if (_json.containsKey('profileId')) {
      profileId = _json['profileId'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('userEmail')) {
      userEmail = _json['userEmail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customerId != null) 'customerId': customerId!,
        if (entityId != null) 'entityId': entityId!,
        if (profileId != null) 'profileId': profileId!,
        if (type != null) 'type': type!,
        if (userEmail != null) 'userEmail': userEmail!,
      };
}

class UsageReportParameters {
  /// Boolean value of the parameter.
  ///
  /// Output only.
  core.bool? boolValue;

  /// The RFC 3339 formatted value of the parameter, for example
  /// 2010-10-28T10:26:35.000Z.
  core.DateTime? datetimeValue;

  /// Integer value of the parameter.
  ///
  /// Output only.
  core.String? intValue;

  /// Nested message value of the parameter.
  ///
  /// Output only.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? msgValue;

  /// The name of the parameter.
  ///
  /// For the User Usage Report parameter names, see the User Usage parameters
  /// reference.
  core.String? name;

  /// String value of the parameter.
  ///
  /// Output only.
  core.String? stringValue;

  UsageReportParameters();

  UsageReportParameters.fromJson(core.Map _json) {
    if (_json.containsKey('boolValue')) {
      boolValue = _json['boolValue'] as core.bool;
    }
    if (_json.containsKey('datetimeValue')) {
      datetimeValue =
          core.DateTime.parse(_json['datetimeValue'] as core.String);
    }
    if (_json.containsKey('intValue')) {
      intValue = _json['intValue'] as core.String;
    }
    if (_json.containsKey('msgValue')) {
      msgValue = (_json['msgValue'] as core.List)
          .map<core.Map<core.String, core.Object>>(
              (value) => (value as core.Map<core.String, core.dynamic>).map(
                    (key, item) => core.MapEntry(
                      key,
                      item as core.Object,
                    ),
                  ))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('stringValue')) {
      stringValue = _json['stringValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (boolValue != null) 'boolValue': boolValue!,
        if (datetimeValue != null)
          'datetimeValue': datetimeValue!.toIso8601String(),
        if (intValue != null) 'intValue': intValue!,
        if (msgValue != null) 'msgValue': msgValue!,
        if (name != null) 'name': name!,
        if (stringValue != null) 'stringValue': stringValue!,
      };
}

/// JSON template for a usage report.
class UsageReport {
  /// The date of the report request.
  ///
  /// Output only.
  core.String? date;

  /// Information about the type of the item.
  ///
  /// Output only.
  UsageReportEntity? entity;

  /// ETag of the resource.
  core.String? etag;

  /// The type of API resource.
  ///
  /// For a usage report, the value is `admin#reports#usageReport`.
  core.String? kind;

  /// Parameter value pairs for various applications.
  ///
  /// For the Entity Usage Report parameters and values, see \[the Entity Usage
  /// parameters
  /// reference\](/admin-sdk/reports/v1/reference/usage-ref-appendix-a/entities).
  ///
  /// Output only.
  core.List<UsageReportParameters>? parameters;

  UsageReport();

  UsageReport.fromJson(core.Map _json) {
    if (_json.containsKey('date')) {
      date = _json['date'] as core.String;
    }
    if (_json.containsKey('entity')) {
      entity = UsageReportEntity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<UsageReportParameters>((value) => UsageReportParameters.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (date != null) 'date': date!,
        if (entity != null) 'entity': entity!.toJson(),
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
      };
}

class UsageReportsWarningsData {
  /// Key associated with a key-value pair to give detailed information on the
  /// warning.
  core.String? key;

  /// Value associated with a key-value pair to give detailed information on the
  /// warning.
  core.String? value;

  UsageReportsWarningsData();

  UsageReportsWarningsData.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (value != null) 'value': value!,
      };
}

class UsageReportsWarnings {
  /// Machine readable code or warning type.
  ///
  /// The warning code value is `200`.
  core.String? code;

  /// Key-value pairs to give detailed information on the warning.
  core.List<UsageReportsWarningsData>? data;

  /// The human readable messages for a warning are: - Data is not available
  /// warning - Sorry, data for date yyyy-mm-dd for application "`application
  /// name`" is not available.
  ///
  /// - Partial data is available warning - Data for date yyyy-mm-dd for
  /// application "`application name`" is not available right now, please try
  /// again after a few hours.
  core.String? message;

  UsageReportsWarnings();

  UsageReportsWarnings.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.List)
          .map<UsageReportsWarningsData>((value) =>
              UsageReportsWarningsData.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (data != null) 'data': data!.map((value) => value.toJson()).toList(),
        if (message != null) 'message': message!,
      };
}

class UsageReports {
  /// ETag of the resource.
  core.String? etag;

  /// The type of API resource.
  ///
  /// For a usage report, the value is `admin#reports#usageReports`.
  core.String? kind;

  /// Token to specify next page.
  ///
  /// A report with multiple pages has a `nextPageToken` property in the
  /// response. For your follow-on requests getting all of the report's pages,
  /// enter the `nextPageToken` value in the `pageToken` query string.
  core.String? nextPageToken;

  /// Various application parameter records.
  core.List<UsageReport>? usageReports;

  /// Warnings, if any.
  core.List<UsageReportsWarnings>? warnings;

  UsageReports();

  UsageReports.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('usageReports')) {
      usageReports = (_json['usageReports'] as core.List)
          .map<UsageReport>((value) => UsageReport.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('warnings')) {
      warnings = (_json['warnings'] as core.List)
          .map<UsageReportsWarnings>((value) => UsageReportsWarnings.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (usageReports != null)
          'usageReports': usageReports!.map((value) => value.toJson()).toList(),
        if (warnings != null)
          'warnings': warnings!.map((value) => value.toJson()).toList(),
      };
}
