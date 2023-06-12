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

/// Digital Asset Links API - v1
///
/// Discovers relationships between online assets such as websites or mobile
/// apps.
///
/// For more information, see
/// <https://developers.google.com/digital-asset-links/>
///
/// Create an instance of [DigitalassetlinksApi] to access these resources:
///
/// - [AssetlinksResource]
/// - [StatementsResource]
library digitalassetlinks.v1;

import 'dart:async' as async;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Discovers relationships between online assets such as websites or mobile
/// apps.
class DigitalassetlinksApi {
  final commons.ApiRequester _requester;

  AssetlinksResource get assetlinks => AssetlinksResource(_requester);
  StatementsResource get statements => StatementsResource(_requester);

  DigitalassetlinksApi(http.Client client,
      {core.String rootUrl = 'https://digitalassetlinks.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AssetlinksResource {
  final commons.ApiRequester _requester;

  AssetlinksResource(commons.ApiRequester client) : _requester = client;

  /// Determines whether the specified (directional) relationship exists between
  /// the specified source and target assets.
  ///
  /// The relation describes the intent of the link between the two assets as
  /// claimed by the source asset. An example for such relationships is the
  /// delegation of privileges or permissions. This command is most often used
  /// by infrastructure systems to check preconditions for an action. For
  /// example, a client may want to know if it is OK to send a web URL to a
  /// particular mobile app instead. The client can check for the relevant asset
  /// link from the website to the mobile app to decide if the operation should
  /// be allowed. A note about security: if you specify a secure asset as the
  /// source, such as an HTTPS website or an Android app, the API will ensure
  /// that any statements used to generate the response have been made in a
  /// secure way by the owner of that asset. Conversely, if the source asset is
  /// an insecure HTTP website (that is, the URL starts with `http://` instead
  /// of `https://`), the API cannot verify its statements securely, and it is
  /// not possible to ensure that the website's statements have not been altered
  /// by a third party. For more information, see the
  /// [Digital Asset Links technical design specification](https://github.com/google/digitalassetlinks/blob/master/well-known/details.md).
  ///
  /// Request parameters:
  ///
  /// [relation] - Query string for the relation. We identify relations with
  /// strings of the format `/`, where `` must be one of a set of pre-defined
  /// purpose categories, and `` is a free-form lowercase alphanumeric string
  /// that describes the specific use case of the statement. Refer to \[our API
  /// documentation\](/digital-asset-links/v1/relation-strings) for the current
  /// list of supported relations. For a query to match an asset link, both the
  /// query's and the asset link's relation strings must match exactly. Example:
  /// A query with relation `delegate_permission/common.handle_all_urls` matches
  /// an asset link with relation `delegate_permission/common.handle_all_urls`.
  ///
  /// [source_androidApp_certificate_sha256Fingerprint] - The uppercase SHA-265
  /// fingerprint of the certificate. From the PEM certificate, it can be
  /// acquired like this: $ keytool -printcert -file $CERTFILE | grep SHA256:
  /// SHA256: 14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83: \
  /// 42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5 or like this: $ openssl x509 -in
  /// $CERTFILE -noout -fingerprint -sha256 SHA256
  /// Fingerprint=14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64: \
  /// 16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5 In this example, the
  /// contents of this field would be `14:6D:E9:83:C5:73:
  /// 06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:
  /// 44:E5`. If these tools are not available to you, you can convert the PEM
  /// certificate into the DER format, compute the SHA-256 hash of that string
  /// and represent the result as a hexstring (that is, uppercase hexadecimal
  /// representations of each octet, separated by colons).
  ///
  /// [source_androidApp_packageName] - Android App assets are naturally
  /// identified by their Java package name. For example, the Google Maps app
  /// uses the package name `com.google.android.apps.maps`. REQUIRED
  ///
  /// [source_web_site] - Web assets are identified by a URL that contains only
  /// the scheme, hostname and port parts. The format is http\[s\]://\[:\]
  /// Hostnames must be fully qualified: they must end in a single period
  /// ("`.`"). Only the schemes "http" and "https" are currently allowed. Port
  /// numbers are given as a decimal number, and they must be omitted if the
  /// standard port numbers are used: 80 for http and 443 for https. We call
  /// this limited URL the "site". All URLs that share the same scheme, hostname
  /// and port are considered to be a part of the site and thus belong to the
  /// web asset. Example: the asset with the site `https://www.google.com`
  /// contains all these URLs: * `https://www.google.com/` *
  /// `https://www.google.com:443/` * `https://www.google.com/foo` *
  /// `https://www.google.com/foo?bar` * `https://www.google.com/foo#bar` *
  /// `https://user@password:www.google.com/` But it does not contain these
  /// URLs: * `http://www.google.com/` (wrong scheme) * `https://google.com/`
  /// (hostname does not match) * `https://www.google.com:444/` (port does not
  /// match) REQUIRED
  ///
  /// [target_androidApp_certificate_sha256Fingerprint] - The uppercase SHA-265
  /// fingerprint of the certificate. From the PEM certificate, it can be
  /// acquired like this: $ keytool -printcert -file $CERTFILE | grep SHA256:
  /// SHA256: 14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83: \
  /// 42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5 or like this: $ openssl x509 -in
  /// $CERTFILE -noout -fingerprint -sha256 SHA256
  /// Fingerprint=14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64: \
  /// 16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5 In this example, the
  /// contents of this field would be `14:6D:E9:83:C5:73:
  /// 06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:
  /// 44:E5`. If these tools are not available to you, you can convert the PEM
  /// certificate into the DER format, compute the SHA-256 hash of that string
  /// and represent the result as a hexstring (that is, uppercase hexadecimal
  /// representations of each octet, separated by colons).
  ///
  /// [target_androidApp_packageName] - Android App assets are naturally
  /// identified by their Java package name. For example, the Google Maps app
  /// uses the package name `com.google.android.apps.maps`. REQUIRED
  ///
  /// [target_web_site] - Web assets are identified by a URL that contains only
  /// the scheme, hostname and port parts. The format is http\[s\]://\[:\]
  /// Hostnames must be fully qualified: they must end in a single period
  /// ("`.`"). Only the schemes "http" and "https" are currently allowed. Port
  /// numbers are given as a decimal number, and they must be omitted if the
  /// standard port numbers are used: 80 for http and 443 for https. We call
  /// this limited URL the "site". All URLs that share the same scheme, hostname
  /// and port are considered to be a part of the site and thus belong to the
  /// web asset. Example: the asset with the site `https://www.google.com`
  /// contains all these URLs: * `https://www.google.com/` *
  /// `https://www.google.com:443/` * `https://www.google.com/foo` *
  /// `https://www.google.com/foo?bar` * `https://www.google.com/foo#bar` *
  /// `https://user@password:www.google.com/` But it does not contain these
  /// URLs: * `http://www.google.com/` (wrong scheme) * `https://google.com/`
  /// (hostname does not match) * `https://www.google.com:444/` (port does not
  /// match) REQUIRED
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CheckResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CheckResponse> check({
    core.String? relation,
    core.String? source_androidApp_certificate_sha256Fingerprint,
    core.String? source_androidApp_packageName,
    core.String? source_web_site,
    core.String? target_androidApp_certificate_sha256Fingerprint,
    core.String? target_androidApp_packageName,
    core.String? target_web_site,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (relation != null) 'relation': [relation],
      if (source_androidApp_certificate_sha256Fingerprint != null)
        'source.androidApp.certificate.sha256Fingerprint': [
          source_androidApp_certificate_sha256Fingerprint
        ],
      if (source_androidApp_packageName != null)
        'source.androidApp.packageName': [source_androidApp_packageName],
      if (source_web_site != null) 'source.web.site': [source_web_site],
      if (target_androidApp_certificate_sha256Fingerprint != null)
        'target.androidApp.certificate.sha256Fingerprint': [
          target_androidApp_certificate_sha256Fingerprint
        ],
      if (target_androidApp_packageName != null)
        'target.androidApp.packageName': [target_androidApp_packageName],
      if (target_web_site != null) 'target.web.site': [target_web_site],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/assetlinks:check';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CheckResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class StatementsResource {
  final commons.ApiRequester _requester;

  StatementsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a list of all statements from a given source that match the
  /// specified target and statement string.
  ///
  /// The API guarantees that all statements with secure source assets, such as
  /// HTTPS websites or Android apps, have been made in a secure way by the
  /// owner of those assets, as described in the
  /// [Digital Asset Links technical design specification](https://github.com/google/digitalassetlinks/blob/master/well-known/details.md).
  /// Specifically, you should consider that for insecure websites (that is,
  /// where the URL starts with `http://` instead of `https://`), this guarantee
  /// cannot be made. The `List` command is most useful in cases where the API
  /// client wants to know all the ways in which two assets are related, or
  /// enumerate all the relationships from a particular source asset. Example: a
  /// feature that helps users navigate to related items. When a mobile app is
  /// running on a device, the feature would make it easy to navigate to the
  /// corresponding web site or Google+ profile.
  ///
  /// Request parameters:
  ///
  /// [relation] - Use only associations that match the specified relation. See
  /// the \[`Statement`\](#Statement) message for a detailed definition of
  /// relation strings. For a query to match a statement, one of the following
  /// must be true: * both the query's and the statement's relation strings
  /// match exactly, or * the query's relation string is empty or missing.
  /// Example: A query with relation
  /// `delegate_permission/common.handle_all_urls` matches an asset link with
  /// relation `delegate_permission/common.handle_all_urls`.
  ///
  /// [source_androidApp_certificate_sha256Fingerprint] - The uppercase SHA-265
  /// fingerprint of the certificate. From the PEM certificate, it can be
  /// acquired like this: $ keytool -printcert -file $CERTFILE | grep SHA256:
  /// SHA256: 14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83: \
  /// 42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5 or like this: $ openssl x509 -in
  /// $CERTFILE -noout -fingerprint -sha256 SHA256
  /// Fingerprint=14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64: \
  /// 16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5 In this example, the
  /// contents of this field would be `14:6D:E9:83:C5:73:
  /// 06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:
  /// 44:E5`. If these tools are not available to you, you can convert the PEM
  /// certificate into the DER format, compute the SHA-256 hash of that string
  /// and represent the result as a hexstring (that is, uppercase hexadecimal
  /// representations of each octet, separated by colons).
  ///
  /// [source_androidApp_packageName] - Android App assets are naturally
  /// identified by their Java package name. For example, the Google Maps app
  /// uses the package name `com.google.android.apps.maps`. REQUIRED
  ///
  /// [source_web_site] - Web assets are identified by a URL that contains only
  /// the scheme, hostname and port parts. The format is http\[s\]://\[:\]
  /// Hostnames must be fully qualified: they must end in a single period
  /// ("`.`"). Only the schemes "http" and "https" are currently allowed. Port
  /// numbers are given as a decimal number, and they must be omitted if the
  /// standard port numbers are used: 80 for http and 443 for https. We call
  /// this limited URL the "site". All URLs that share the same scheme, hostname
  /// and port are considered to be a part of the site and thus belong to the
  /// web asset. Example: the asset with the site `https://www.google.com`
  /// contains all these URLs: * `https://www.google.com/` *
  /// `https://www.google.com:443/` * `https://www.google.com/foo` *
  /// `https://www.google.com/foo?bar` * `https://www.google.com/foo#bar` *
  /// `https://user@password:www.google.com/` But it does not contain these
  /// URLs: * `http://www.google.com/` (wrong scheme) * `https://google.com/`
  /// (hostname does not match) * `https://www.google.com:444/` (port does not
  /// match) REQUIRED
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListResponse> list({
    core.String? relation,
    core.String? source_androidApp_certificate_sha256Fingerprint,
    core.String? source_androidApp_packageName,
    core.String? source_web_site,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (relation != null) 'relation': [relation],
      if (source_androidApp_certificate_sha256Fingerprint != null)
        'source.androidApp.certificate.sha256Fingerprint': [
          source_androidApp_certificate_sha256Fingerprint
        ],
      if (source_androidApp_packageName != null)
        'source.androidApp.packageName': [source_androidApp_packageName],
      if (source_web_site != null) 'source.web.site': [source_web_site],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/statements:list';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Describes an android app asset.
class AndroidAppAsset {
  /// Because there is no global enforcement of package name uniqueness, we also
  /// require a signing certificate, which in combination with the package name
  /// uniquely identifies an app.
  ///
  /// Some apps' signing keys are rotated, so they may be signed by different
  /// keys over time. We treat these as distinct assets, since we use (package
  /// name, cert) as the unique ID. This should not normally pose any problems
  /// as both versions of the app will make the same or similar statements.
  /// Other assets making statements about the app will have to be updated when
  /// a key is rotated, however. (Note that the syntaxes for publishing and
  /// querying for statements contain syntactic sugar to easily let you specify
  /// apps that are known by multiple certificates.) REQUIRED
  CertificateInfo? certificate;

  /// Android App assets are naturally identified by their Java package name.
  ///
  /// For example, the Google Maps app uses the package name
  /// `com.google.android.apps.maps`. REQUIRED
  core.String? packageName;

  AndroidAppAsset();

  AndroidAppAsset.fromJson(core.Map _json) {
    if (_json.containsKey('certificate')) {
      certificate = CertificateInfo.fromJson(
          _json['certificate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (certificate != null) 'certificate': certificate!.toJson(),
        if (packageName != null) 'packageName': packageName!,
      };
}

/// Uniquely identifies an asset.
///
/// A digital asset is an identifiable and addressable online entity that
/// typically provides some service or content. Examples of assets are websites,
/// Android apps, Twitter feeds, and Plus Pages.
class Asset {
  /// Set if this is an Android App asset.
  AndroidAppAsset? androidApp;

  /// Set if this is a web asset.
  WebAsset? web;

  Asset();

  Asset.fromJson(core.Map _json) {
    if (_json.containsKey('androidApp')) {
      androidApp = AndroidAppAsset.fromJson(
          _json['androidApp'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('web')) {
      web = WebAsset.fromJson(
          _json['web'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidApp != null) 'androidApp': androidApp!.toJson(),
        if (web != null) 'web': web!.toJson(),
      };
}

/// Describes an X509 certificate.
class CertificateInfo {
  /// The uppercase SHA-265 fingerprint of the certificate.
  ///
  /// From the PEM certificate, it can be acquired like this: $ keytool
  /// -printcert -file $CERTFILE | grep SHA256: SHA256:
  /// 14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83: \
  /// 42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5 or like this: $ openssl x509 -in
  /// $CERTFILE -noout -fingerprint -sha256 SHA256
  /// Fingerprint=14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64: \
  /// 16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5 In this example, the
  /// contents of this field would be `14:6D:E9:83:C5:73:
  /// 06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:
  /// 44:E5`. If these tools are not available to you, you can convert the PEM
  /// certificate into the DER format, compute the SHA-256 hash of that string
  /// and represent the result as a hexstring (that is, uppercase hexadecimal
  /// representations of each octet, separated by colons).
  core.String? sha256Fingerprint;

  CertificateInfo();

  CertificateInfo.fromJson(core.Map _json) {
    if (_json.containsKey('sha256Fingerprint')) {
      sha256Fingerprint = _json['sha256Fingerprint'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sha256Fingerprint != null) 'sha256Fingerprint': sha256Fingerprint!,
      };
}

/// Response message for the CheckAssetLinks call.
class CheckResponse {
  /// Human-readable message containing information intended to help end users
  /// understand, reproduce and debug the result.
  ///
  /// The message will be in English and we are currently not planning to offer
  /// any translations. Please note that no guarantees are made about the
  /// contents or format of this string. Any aspect of it may be subject to
  /// change without notice. You should not attempt to programmatically parse
  /// this data. For programmatic access, use the error_code field below.
  core.String? debugString;

  /// Error codes that describe the result of the Check operation.
  core.List<core.String>? errorCode;

  /// Set to true if the assets specified in the request are linked by the
  /// relation specified in the request.
  core.bool? linked;

  /// From serving time, how much longer the response should be considered valid
  /// barring further updates.
  ///
  /// REQUIRED
  core.String? maxAge;

  CheckResponse();

  CheckResponse.fromJson(core.Map _json) {
    if (_json.containsKey('debugString')) {
      debugString = _json['debugString'] as core.String;
    }
    if (_json.containsKey('errorCode')) {
      errorCode = (_json['errorCode'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('linked')) {
      linked = _json['linked'] as core.bool;
    }
    if (_json.containsKey('maxAge')) {
      maxAge = _json['maxAge'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (debugString != null) 'debugString': debugString!,
        if (errorCode != null) 'errorCode': errorCode!,
        if (linked != null) 'linked': linked!,
        if (maxAge != null) 'maxAge': maxAge!,
      };
}

/// Response message for the List call.
class ListResponse {
  /// Human-readable message containing information intended to help end users
  /// understand, reproduce and debug the result.
  ///
  /// The message will be in English and we are currently not planning to offer
  /// any translations. Please note that no guarantees are made about the
  /// contents or format of this string. Any aspect of it may be subject to
  /// change without notice. You should not attempt to programmatically parse
  /// this data. For programmatic access, use the error_code field below.
  core.String? debugString;

  /// Error codes that describe the result of the List operation.
  core.List<core.String>? errorCode;

  /// From serving time, how much longer the response should be considered valid
  /// barring further updates.
  ///
  /// REQUIRED
  core.String? maxAge;

  /// A list of all the matching statements that have been found.
  core.List<Statement>? statements;

  ListResponse();

  ListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('debugString')) {
      debugString = _json['debugString'] as core.String;
    }
    if (_json.containsKey('errorCode')) {
      errorCode = (_json['errorCode'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('maxAge')) {
      maxAge = _json['maxAge'] as core.String;
    }
    if (_json.containsKey('statements')) {
      statements = (_json['statements'] as core.List)
          .map<Statement>((value) =>
              Statement.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (debugString != null) 'debugString': debugString!,
        if (errorCode != null) 'errorCode': errorCode!,
        if (maxAge != null) 'maxAge': maxAge!,
        if (statements != null)
          'statements': statements!.map((value) => value.toJson()).toList(),
      };
}

/// Describes a reliable statement that has been made about the relationship
/// between a source asset and a target asset.
///
/// Statements are always made by the source asset, either directly or by
/// delegating to a statement list that is stored elsewhere. For more detailed
/// definitions of statements and assets, please refer to our \[API
/// documentation landing page\](/digital-asset-links/v1/getting-started).
class Statement {
  /// The relation identifies the use of the statement as intended by the source
  /// asset's owner (that is, the person or entity who issued the statement).
  ///
  /// Every complete statement has a relation. We identify relations with
  /// strings of the format `/`, where `` must be one of a set of pre-defined
  /// purpose categories, and `` is a free-form lowercase alphanumeric string
  /// that describes the specific use case of the statement. Refer to \[our API
  /// documentation\](/digital-asset-links/v1/relation-strings) for the current
  /// list of supported relations. Example:
  /// `delegate_permission/common.handle_all_urls` REQUIRED
  core.String? relation;

  /// Every statement has a source asset.
  ///
  /// REQUIRED
  Asset? source;

  /// Every statement has a target asset.
  ///
  /// REQUIRED
  Asset? target;

  Statement();

  Statement.fromJson(core.Map _json) {
    if (_json.containsKey('relation')) {
      relation = _json['relation'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = Asset.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('target')) {
      target = Asset.fromJson(
          _json['target'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (relation != null) 'relation': relation!,
        if (source != null) 'source': source!.toJson(),
        if (target != null) 'target': target!.toJson(),
      };
}

/// Describes a web asset.
class WebAsset {
  /// Web assets are identified by a URL that contains only the scheme, hostname
  /// and port parts.
  ///
  /// The format is http\[s\]://\[:\] Hostnames must be fully qualified: they
  /// must end in a single period ("`.`"). Only the schemes "http" and "https"
  /// are currently allowed. Port numbers are given as a decimal number, and
  /// they must be omitted if the standard port numbers are used: 80 for http
  /// and 443 for https. We call this limited URL the "site". All URLs that
  /// share the same scheme, hostname and port are considered to be a part of
  /// the site and thus belong to the web asset. Example: the asset with the
  /// site `https://www.google.com` contains all these URLs: *
  /// `https://www.google.com/` * `https://www.google.com:443/` *
  /// `https://www.google.com/foo` * `https://www.google.com/foo?bar` *
  /// `https://www.google.com/foo#bar` * `https://user@password:www.google.com/`
  /// But it does not contain these URLs: * `http://www.google.com/` (wrong
  /// scheme) * `https://google.com/` (hostname does not match) *
  /// `https://www.google.com:444/` (port does not match) REQUIRED
  core.String? site;

  WebAsset();

  WebAsset.fromJson(core.Map _json) {
    if (_json.containsKey('site')) {
      site = _json['site'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (site != null) 'site': site!,
      };
}
