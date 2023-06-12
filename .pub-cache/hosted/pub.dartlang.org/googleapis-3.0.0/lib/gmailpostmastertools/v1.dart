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

/// Gmail Postmaster Tools API - v1
///
/// The Postmaster Tools API is a RESTful API that provides programmatic access
/// to email traffic metrics (like spam reports, delivery errors etc) otherwise
/// available through the Gmail Postmaster Tools UI currently.
///
/// For more information, see <https://developers.google.com/gmail/postmaster>
///
/// Create an instance of [PostmasterToolsApi] to access these resources:
///
/// - [DomainsResource]
///   - [DomainsTrafficStatsResource]
library gmailpostmastertools.v1;

import 'dart:async' as async;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The Postmaster Tools API is a RESTful API that provides programmatic access
/// to email traffic metrics (like spam reports, delivery errors etc) otherwise
/// available through the Gmail Postmaster Tools UI currently.
class PostmasterToolsApi {
  /// See email traffic metrics for the domains you have registered in Gmail
  /// Postmaster Tools
  static const postmasterReadonlyScope =
      'https://www.googleapis.com/auth/postmaster.readonly';

  final commons.ApiRequester _requester;

  DomainsResource get domains => DomainsResource(_requester);

  PostmasterToolsApi(http.Client client,
      {core.String rootUrl = 'https://gmailpostmastertools.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class DomainsResource {
  final commons.ApiRequester _requester;

  DomainsTrafficStatsResource get trafficStats =>
      DomainsTrafficStatsResource(_requester);

  DomainsResource(commons.ApiRequester client) : _requester = client;

  /// Gets a specific domain registered by the client.
  ///
  /// Returns NOT_FOUND if the domain does not exist.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the domain. It should have the form
  /// `domains/{domain_name}`, where domain_name is the fully qualified domain
  /// name.
  /// Value must have pattern `^domains/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Domain].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Domain> get(
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
    return Domain.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the domains that have been registered by the client.
  ///
  /// The order of domains in the response is unspecified and non-deterministic.
  /// Newly created domains will not necessarily be added to the end of this
  /// list.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Requested page size. Server may return fewer domains than
  /// requested. If unspecified, server will pick an appropriate default.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any. This is the value of ListDomainsResponse.next_page_token
  /// returned from the previous call to `ListDomains` method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDomainsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDomainsResponse> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/domains';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDomainsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class DomainsTrafficStatsResource {
  final commons.ApiRequester _requester;

  DomainsTrafficStatsResource(commons.ApiRequester client)
      : _requester = client;

  /// Get traffic statistics for a domain on a specific date.
  ///
  /// Returns PERMISSION_DENIED if user does not have permission to access
  /// TrafficStats for the domain.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the traffic statistics to get. E.g.,
  /// domains/mymail.mydomain.com/trafficStats/20160807.
  /// Value must have pattern `^domains/\[^/\]+/trafficStats/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TrafficStats].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TrafficStats> get(
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
    return TrafficStats.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List traffic statistics for all available days.
  ///
  /// Returns PERMISSION_DENIED if user does not have permission to access
  /// TrafficStats for the domain.
  ///
  /// Request parameters:
  ///
  /// [parent] - The resource name of the domain whose traffic statistics we'd
  /// like to list. It should have the form `domains/{domain_name}`, where
  /// domain_name is the fully qualified domain name.
  /// Value must have pattern `^domains/\[^/\]+$`.
  ///
  /// [endDate_day] - Day of a month. Must be from 1 to 31 and valid for the
  /// year and month, or 0 to specify a year by itself or a year and month where
  /// the day isn't significant.
  ///
  /// [endDate_month] - Month of a year. Must be from 1 to 12, or 0 to specify a
  /// year without a month and day.
  ///
  /// [endDate_year] - Year of the date. Must be from 1 to 9999, or 0 to specify
  /// a date without a year.
  ///
  /// [pageSize] - Requested page size. Server may return fewer TrafficStats
  /// than requested. If unspecified, server will pick an appropriate default.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any. This is the value of
  /// ListTrafficStatsResponse.next_page_token returned from the previous call
  /// to `ListTrafficStats` method.
  ///
  /// [startDate_day] - Day of a month. Must be from 1 to 31 and valid for the
  /// year and month, or 0 to specify a year by itself or a year and month where
  /// the day isn't significant.
  ///
  /// [startDate_month] - Month of a year. Must be from 1 to 12, or 0 to specify
  /// a year without a month and day.
  ///
  /// [startDate_year] - Year of the date. Must be from 1 to 9999, or 0 to
  /// specify a date without a year.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTrafficStatsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTrafficStatsResponse> list(
    core.String parent, {
    core.int? endDate_day,
    core.int? endDate_month,
    core.int? endDate_year,
    core.int? pageSize,
    core.String? pageToken,
    core.int? startDate_day,
    core.int? startDate_month,
    core.int? startDate_year,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (endDate_day != null) 'endDate.day': ['${endDate_day}'],
      if (endDate_month != null) 'endDate.month': ['${endDate_month}'],
      if (endDate_year != null) 'endDate.year': ['${endDate_year}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (startDate_day != null) 'startDate.day': ['${startDate_day}'],
      if (startDate_month != null) 'startDate.month': ['${startDate_month}'],
      if (startDate_year != null) 'startDate.year': ['${startDate_year}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/trafficStats';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTrafficStatsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Metric on a particular delivery error type.
class DeliveryError {
  /// The class of delivery error.
  /// Possible string values are:
  /// - "DELIVERY_ERROR_CLASS_UNSPECIFIED" : The default value which should
  /// never be used explicitly.
  /// - "PERMANENT_ERROR" : Delivery of message has been rejected.
  /// - "TEMPORARY_ERROR" : Temporary failure of message delivery to the
  /// recipient.
  core.String? errorClass;

  /// The ratio of messages where the error occurred vs all authenticated
  /// traffic.
  core.double? errorRatio;

  /// The type of delivery error.
  /// Possible string values are:
  /// - "DELIVERY_ERROR_TYPE_UNSPECIFIED" : The default value which should never
  /// be used explicitly.
  /// - "RATE_LIMIT_EXCEEDED" : The Domain or IP is sending traffic at a
  /// suspiciously high rate, due to which temporary rate limits have been
  /// imposed. The limit will be lifted when Gmail is confident enough of the
  /// nature of the traffic.
  /// - "SUSPECTED_SPAM" : The traffic is suspected to be spam, by Gmail, for
  /// various reasons.
  /// - "CONTENT_SPAMMY" : The traffic is suspected to be spammy, specific to
  /// the content.
  /// - "BAD_ATTACHMENT" : Traffic contains attachments not supported by Gmail.
  /// - "BAD_DMARC_POLICY" : The sender domain has set up a DMARC rejection
  /// policy.
  /// - "LOW_IP_REPUTATION" : The IP reputation of the sending IP is very low.
  /// - "LOW_DOMAIN_REPUTATION" : The Domain reputation of the sending domain is
  /// very low.
  /// - "IP_IN_RBL" : The IP is listed in one or more public \[Real-time
  /// Blackhole Lists\](http://en.wikipedia.org/wiki/DNSBL). Work with the RBL
  /// to get your IP delisted.
  /// - "DOMAIN_IN_RBL" : The Domain is listed in one or more public \[Real-time
  /// Blackhole Lists\](http://en.wikipedia.org/wiki/DNSBL). Work with the RBL
  /// to get your domain delisted.
  /// - "BAD_PTR_RECORD" : The sending IP is missing a
  /// [PTR record](https://support.google.com/domains/answer/3251147#ptr).
  core.String? errorType;

  DeliveryError();

  DeliveryError.fromJson(core.Map _json) {
    if (_json.containsKey('errorClass')) {
      errorClass = _json['errorClass'] as core.String;
    }
    if (_json.containsKey('errorRatio')) {
      errorRatio = (_json['errorRatio'] as core.num).toDouble();
    }
    if (_json.containsKey('errorType')) {
      errorType = _json['errorType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorClass != null) 'errorClass': errorClass!,
        if (errorRatio != null) 'errorRatio': errorRatio!,
        if (errorType != null) 'errorType': errorType!,
      };
}

/// A registered domain resource in the Postmaster API.
class Domain {
  /// Timestamp when the user registered this domain.
  ///
  /// Assigned by the server.
  core.String? createTime;

  /// The resource name of the Domain.
  ///
  /// Domain names have the form `domains/{domain_name}`, where domain_name is
  /// the fully qualified domain name (i.e., mymail.mydomain.com).
  core.String? name;

  /// User’s permission for this domain.
  ///
  /// Assigned by the server.
  /// Possible string values are:
  /// - "PERMISSION_UNSPECIFIED" : The default value and should never be used
  /// explicitly.
  /// - "OWNER" : User has read access to the domain and can share access with
  /// others.
  /// - "READER" : User has read access to the domain.
  /// - "NONE" : User doesn't have permission to access information about the
  /// domain. User did not verify ownership of domain nor was access granted by
  /// other domain owners.
  core.String? permission;

  Domain();

  Domain.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('permission')) {
      permission = _json['permission'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (name != null) 'name': name!,
        if (permission != null) 'permission': permission!,
      };
}

/// [Feedback loop](https://support.google.com/mail/answer/6254652) identifier
/// information.
class FeedbackLoop {
  /// Feedback loop identifier that uniquely identifies individual campaigns.
  core.String? id;

  /// The ratio of user marked spam messages with the identifier vs the total
  /// number of inboxed messages with that identifier.
  core.double? spamRatio;

  FeedbackLoop();

  FeedbackLoop.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('spamRatio')) {
      spamRatio = (_json['spamRatio'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (spamRatio != null) 'spamRatio': spamRatio!,
      };
}

/// IP Reputation information for a set of IPs in a specific reputation
/// category.
class IpReputation {
  /// Total number of unique IPs in this reputation category.
  ///
  /// This metric only pertains to traffic that passed
  /// [SPF](http://www.openspf.org/) or [DKIM](http://www.dkim.org/).
  core.String? ipCount;

  /// The reputation category this IP reputation represents.
  /// Possible string values are:
  /// - "REPUTATION_CATEGORY_UNSPECIFIED" : The default value which should never
  /// be used explicitly. This represents the state where no reputation
  /// information is available.
  /// - "HIGH" : Has a good track record of a very low spam rate, and complies
  /// with Gmail's sender guidelines. Mail will rarely be marked by the spam
  /// filter.
  /// - "MEDIUM" : Known to send good mail, but is prone to sending a low volume
  /// of spam intermittently. Most of the email from this entity will have a
  /// fair deliverability rate, except when there is a notable increase in spam
  /// levels.
  /// - "LOW" : Known to send a considerable volume of spam regularly, and mail
  /// from this sender will likely be marked as spam.
  /// - "BAD" : History of sending an enormously high volume of spam. Mail
  /// coming from this entity will almost always be rejected at SMTP level or
  /// marked as spam.
  core.String? reputation;

  /// A sample of IPs in this reputation category.
  core.List<core.String>? sampleIps;

  IpReputation();

  IpReputation.fromJson(core.Map _json) {
    if (_json.containsKey('ipCount')) {
      ipCount = _json['ipCount'] as core.String;
    }
    if (_json.containsKey('reputation')) {
      reputation = _json['reputation'] as core.String;
    }
    if (_json.containsKey('sampleIps')) {
      sampleIps = (_json['sampleIps'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ipCount != null) 'ipCount': ipCount!,
        if (reputation != null) 'reputation': reputation!,
        if (sampleIps != null) 'sampleIps': sampleIps!,
      };
}

/// Response message for ListDomains.
class ListDomainsResponse {
  /// The list of domains.
  core.List<Domain>? domains;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  ListDomainsResponse();

  ListDomainsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('domains')) {
      domains = (_json['domains'] as core.List)
          .map<Domain>((value) =>
              Domain.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (domains != null)
          'domains': domains!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for ListTrafficStats.
class ListTrafficStatsResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// The list of TrafficStats.
  core.List<TrafficStats>? trafficStats;

  ListTrafficStatsResponse();

  ListTrafficStatsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('trafficStats')) {
      trafficStats = (_json['trafficStats'] as core.List)
          .map<TrafficStats>((value) => TrafficStats.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (trafficStats != null)
          'trafficStats': trafficStats!.map((value) => value.toJson()).toList(),
      };
}

/// Email traffic statistics pertaining to a specific date.
class TrafficStats {
  /// Delivery errors for the domain.
  ///
  /// This metric only pertains to traffic that passed
  /// [SPF](http://www.openspf.org/) or [DKIM](http://www.dkim.org/).
  core.List<DeliveryError>? deliveryErrors;

  /// The ratio of mail that successfully authenticated with DKIM vs.
  ///
  /// all mail that attempted to authenticate with [DKIM](http://www.dkim.org/).
  /// Spoofed mail is excluded.
  core.double? dkimSuccessRatio;

  /// The ratio of mail that passed [DMARC](https://dmarc.org/) alignment checks
  /// vs all mail received from the domain that successfully authenticated with
  /// either of [SPF](http://www.openspf.org/) or [DKIM](http://www.dkim.org/).
  core.double? dmarcSuccessRatio;

  /// Reputation of the domain.
  /// Possible string values are:
  /// - "REPUTATION_CATEGORY_UNSPECIFIED" : The default value which should never
  /// be used explicitly. This represents the state where no reputation
  /// information is available.
  /// - "HIGH" : Has a good track record of a very low spam rate, and complies
  /// with Gmail's sender guidelines. Mail will rarely be marked by the spam
  /// filter.
  /// - "MEDIUM" : Known to send good mail, but is prone to sending a low volume
  /// of spam intermittently. Most of the email from this entity will have a
  /// fair deliverability rate, except when there is a notable increase in spam
  /// levels.
  /// - "LOW" : Known to send a considerable volume of spam regularly, and mail
  /// from this sender will likely be marked as spam.
  /// - "BAD" : History of sending an enormously high volume of spam. Mail
  /// coming from this entity will almost always be rejected at SMTP level or
  /// marked as spam.
  core.String? domainReputation;

  /// The ratio of incoming mail (to Gmail), that passed secure transport (TLS)
  /// vs all mail received from that domain.
  ///
  /// This metric only pertains to traffic that passed
  /// [SPF](http://www.openspf.org/) or [DKIM](http://www.dkim.org/).
  core.double? inboundEncryptionRatio;

  /// Reputation information pertaining to the IP addresses of the email servers
  /// for the domain.
  ///
  /// There is exactly one entry for each reputation category except
  /// REPUTATION_CATEGORY_UNSPECIFIED.
  core.List<IpReputation>? ipReputations;

  /// The resource name of the traffic statistics.
  ///
  /// Traffic statistic names have the form
  /// `domains/{domain}/trafficStats/{date}`, where domain_name is the fully
  /// qualified domain name (i.e., mymail.mydomain.com) of the domain this
  /// traffic statistics pertains to and date is the date in yyyymmdd format
  /// that these statistics corresponds to. For example:
  /// domains/mymail.mydomain.com/trafficStats/20160807
  core.String? name;

  /// The ratio of outgoing mail (from Gmail) that was accepted over secure
  /// transport (TLS).
  core.double? outboundEncryptionRatio;

  /// Spammy
  /// [Feedback loop identifiers](https://support.google.com/mail/answer/6254652)
  /// with their individual spam rates.
  ///
  /// This metric only pertains to traffic that is authenticated by
  /// [DKIM](http://www.dkim.org/).
  core.List<FeedbackLoop>? spammyFeedbackLoops;

  /// The ratio of mail that successfully authenticated with SPF vs.
  ///
  /// all mail that attempted to authenticate with
  /// [SPF](http://www.openspf.org/). Spoofed mail is excluded.
  core.double? spfSuccessRatio;

  /// The ratio of user-report spam vs.
  ///
  /// email that was sent to the inbox. This metric only pertains to emails
  /// authenticated by [DKIM](http://www.dkim.org/).
  core.double? userReportedSpamRatio;

  TrafficStats();

  TrafficStats.fromJson(core.Map _json) {
    if (_json.containsKey('deliveryErrors')) {
      deliveryErrors = (_json['deliveryErrors'] as core.List)
          .map<DeliveryError>((value) => DeliveryError.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dkimSuccessRatio')) {
      dkimSuccessRatio = (_json['dkimSuccessRatio'] as core.num).toDouble();
    }
    if (_json.containsKey('dmarcSuccessRatio')) {
      dmarcSuccessRatio = (_json['dmarcSuccessRatio'] as core.num).toDouble();
    }
    if (_json.containsKey('domainReputation')) {
      domainReputation = _json['domainReputation'] as core.String;
    }
    if (_json.containsKey('inboundEncryptionRatio')) {
      inboundEncryptionRatio =
          (_json['inboundEncryptionRatio'] as core.num).toDouble();
    }
    if (_json.containsKey('ipReputations')) {
      ipReputations = (_json['ipReputations'] as core.List)
          .map<IpReputation>((value) => IpReputation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('outboundEncryptionRatio')) {
      outboundEncryptionRatio =
          (_json['outboundEncryptionRatio'] as core.num).toDouble();
    }
    if (_json.containsKey('spammyFeedbackLoops')) {
      spammyFeedbackLoops = (_json['spammyFeedbackLoops'] as core.List)
          .map<FeedbackLoop>((value) => FeedbackLoop.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('spfSuccessRatio')) {
      spfSuccessRatio = (_json['spfSuccessRatio'] as core.num).toDouble();
    }
    if (_json.containsKey('userReportedSpamRatio')) {
      userReportedSpamRatio =
          (_json['userReportedSpamRatio'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deliveryErrors != null)
          'deliveryErrors':
              deliveryErrors!.map((value) => value.toJson()).toList(),
        if (dkimSuccessRatio != null) 'dkimSuccessRatio': dkimSuccessRatio!,
        if (dmarcSuccessRatio != null) 'dmarcSuccessRatio': dmarcSuccessRatio!,
        if (domainReputation != null) 'domainReputation': domainReputation!,
        if (inboundEncryptionRatio != null)
          'inboundEncryptionRatio': inboundEncryptionRatio!,
        if (ipReputations != null)
          'ipReputations':
              ipReputations!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (outboundEncryptionRatio != null)
          'outboundEncryptionRatio': outboundEncryptionRatio!,
        if (spammyFeedbackLoops != null)
          'spammyFeedbackLoops':
              spammyFeedbackLoops!.map((value) => value.toJson()).toList(),
        if (spfSuccessRatio != null) 'spfSuccessRatio': spfSuccessRatio!,
        if (userReportedSpamRatio != null)
          'userReportedSpamRatio': userReportedSpamRatio!,
      };
}
