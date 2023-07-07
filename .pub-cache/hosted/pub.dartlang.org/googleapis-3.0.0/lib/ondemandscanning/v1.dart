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

/// On-Demand Scanning API - v1
///
/// A service to scan container images for vulnerabilities.
///
/// For more information, see
/// <https://cloud.google.com/container-analysis/docs/on-demand-scanning/>
///
/// Create an instance of [OnDemandScanningApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsOperationsResource]
///     - [ProjectsLocationsScansResource]
///       - [ProjectsLocationsScansVulnerabilitiesResource]
library ondemandscanning.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// A service to scan container images for vulnerabilities.
class OnDemandScanningApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  OnDemandScanningApi(http.Client client,
      {core.String rootUrl = 'https://ondemandscanning.googleapis.com/',
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

  ProjectsLocationsOperationsResource get operations =>
      ProjectsLocationsOperationsResource(_requester);
  ProjectsLocationsScansResource get scans =>
      ProjectsLocationsScansResource(_requester);

  ProjectsLocationsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsOperationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Starts asynchronous cancellation on a long-running operation.
  ///
  /// The server makes a best effort to cancel the operation, but success is not
  /// guaranteed. If the server doesn't support this method, it returns
  /// `google.rpc.Code.UNIMPLEMENTED`. Clients can use Operations.GetOperation
  /// or other methods to check whether the cancellation succeeded or whether
  /// the operation completed despite cancellation. On successful cancellation,
  /// the operation is not deleted; instead, it becomes an operation with an
  /// Operation.error value with a google.rpc.Status.code of 1, corresponding to
  /// `Code.CANCELLED`.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be cancelled.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
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
  async.Future<Empty> cancel(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':cancel';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a long-running operation.
  ///
  /// This method indicates that the client is no longer interested in the
  /// operation result. It does not cancel the operation. If the server doesn't
  /// support this method, it returns `google.rpc.Code.UNIMPLEMENTED`.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be deleted.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
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
  /// Completes with a [ListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListOperationsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Waits until the specified long-running operation is done or reaches at
  /// most a specified timeout, returning the latest state.
  ///
  /// If the operation is already done, the latest state is immediately
  /// returned. If the timeout specified is greater than the default HTTP/RPC
  /// timeout, the HTTP/RPC timeout is used. If the server does not support this
  /// method, it returns `google.rpc.Code.UNIMPLEMENTED`. Note that this method
  /// is on a best-effort basis. It may return the latest state before the
  /// specified timeout (including immediately), meaning even an immediate
  /// response is no guarantee that the operation is done.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to wait on.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [timeout] - The maximum duration to wait before timing out. If left blank,
  /// the wait will be at most the time permitted by the underlying HTTP/RPC
  /// protocol. If RPC context deadline is also specified, the shorter one will
  /// be used.
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
  async.Future<Operation> wait(
    core.String name, {
    core.String? timeout,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (timeout != null) 'timeout': [timeout],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':wait';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsScansResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsScansVulnerabilitiesResource get vulnerabilities =>
      ProjectsLocationsScansVulnerabilitiesResource(_requester);

  ProjectsLocationsScansResource(commons.ApiRequester client)
      : _requester = client;

  /// Initiates an analysis of the provided packages.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent of the resource for which analysis is
  /// requested. Format: projects/\[project_name\]/locations/\[location\]
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
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
  async.Future<Operation> analyzePackages(
    AnalyzePackagesRequestV1 request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/scans:analyzePackages';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsScansVulnerabilitiesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsScansVulnerabilitiesResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists vulnerabilities resulting from a successfully completed scan.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent of the collection of Vulnerabilities being
  /// requested. Format:
  /// projects/\[project_name\]/locations/\[location\]/scans/\[scan_id\]
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/scans/\[^/\]+$`.
  ///
  /// [pageSize] - The number of vulnerabilities to retrieve.
  ///
  /// [pageToken] - The page token, resulting from a previous call to
  /// ListVulnerabilities.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListVulnerabilitiesResponseV1].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListVulnerabilitiesResponseV1> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/vulnerabilities';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListVulnerabilitiesResponseV1.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// An alias to a repo revision.
class AliasContext {
  /// The alias kind.
  /// Possible string values are:
  /// - "KIND_UNSPECIFIED" : Unknown.
  /// - "FIXED" : Git tag.
  /// - "MOVABLE" : Git branch.
  /// - "OTHER" : Used to specify non-standard aliases. For example, if a Git
  /// repo has a ref named "refs/foo/bar".
  core.String? kind;

  /// The alias name.
  core.String? name;

  AliasContext();

  AliasContext.fromJson(core.Map _json) {
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

/// AnalyzePackagesMetadata contains metadata for an active scan of a container
/// image.
class AnalyzePackagesMetadata {
  /// When the scan was created.
  core.String? createTime;

  /// The resource URI of the container image being scanned.
  core.String? resourceUri;

  AnalyzePackagesMetadata();

  AnalyzePackagesMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('resourceUri')) {
      resourceUri = _json['resourceUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (resourceUri != null) 'resourceUri': resourceUri!,
      };
}

/// AnalyzePackagesMetadata contains metadata for an active scan of a container
/// image.
class AnalyzePackagesMetadataV1 {
  /// When the scan was created.
  core.String? createTime;

  /// The resource URI of the container image being scanned.
  core.String? resourceUri;

  AnalyzePackagesMetadataV1();

  AnalyzePackagesMetadataV1.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('resourceUri')) {
      resourceUri = _json['resourceUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (resourceUri != null) 'resourceUri': resourceUri!,
      };
}

/// AnalyzePackagesRequest is the request to analyze a list of packages and
/// create Vulnerability Occurrences for it.
class AnalyzePackagesRequestV1 {
  /// The packages to analyze.
  core.List<PackageData>? packages;

  /// The resource URI of the container image being scanned.
  ///
  /// Required.
  core.String? resourceUri;

  AnalyzePackagesRequestV1();

  AnalyzePackagesRequestV1.fromJson(core.Map _json) {
    if (_json.containsKey('packages')) {
      packages = (_json['packages'] as core.List)
          .map<PackageData>((value) => PackageData.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resourceUri')) {
      resourceUri = _json['resourceUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (packages != null)
          'packages': packages!.map((value) => value.toJson()).toList(),
        if (resourceUri != null) 'resourceUri': resourceUri!,
      };
}

/// AnalyzePackagesResponse contains the information necessary to find results
/// for the given scan.
class AnalyzePackagesResponse {
  /// The name of the scan resource created by this successful scan.
  core.String? scan;

  AnalyzePackagesResponse();

  AnalyzePackagesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('scan')) {
      scan = _json['scan'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (scan != null) 'scan': scan!,
      };
}

/// AnalyzePackagesResponse contains the information necessary to find results
/// for the given scan.
class AnalyzePackagesResponseV1 {
  /// The name of the scan resource created by this successful scan.
  core.String? scan;

  AnalyzePackagesResponseV1();

  AnalyzePackagesResponseV1.fromJson(core.Map _json) {
    if (_json.containsKey('scan')) {
      scan = _json['scan'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (scan != null) 'scan': scan!,
      };
}

/// Artifact describes a build product.
class Artifact {
  /// Hash or checksum value of a binary, or Docker Registry 2.0 digest of a
  /// container.
  core.String? checksum;

  /// Artifact ID, if any; for container images, this will be a URL by digest
  /// like `gcr.io/projectID/imagename@sha256:123456`.
  core.String? id;

  /// Related artifact names.
  ///
  /// This may be the path to a binary or jar file, or in the case of a
  /// container build, the name used to push the container image to Google
  /// Container Registry, as presented to `docker push`. Note that a single
  /// Artifact ID can have multiple names, for example if two tags are applied
  /// to one image.
  core.List<core.String>? names;

  Artifact();

  Artifact.fromJson(core.Map _json) {
    if (_json.containsKey('checksum')) {
      checksum = _json['checksum'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('names')) {
      names = (_json['names'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (checksum != null) 'checksum': checksum!,
        if (id != null) 'id': id!,
        if (names != null) 'names': names!,
      };
}

/// Occurrence that represents a single "attestation".
///
/// The authenticity of an attestation can be verified using the attached
/// signature. If the verifier trusts the public key of the signer, then
/// verifying the signature is sufficient to establish trust. In this
/// circumstance, the authority to which this attestation is attached is
/// primarily useful for lookup (how to find this attestation if you already
/// know the authority and artifact to be verified) and intent (for which
/// authority this attestation was intended to sign.
class AttestationOccurrence {
  /// One or more JWTs encoding a self-contained attestation.
  ///
  /// Each JWT encodes the payload that it verifies within the JWT itself.
  /// Verifier implementation SHOULD ignore the `serialized_payload` field when
  /// verifying these JWTs. If only JWTs are present on this
  /// AttestationOccurrence, then the `serialized_payload` SHOULD be left empty.
  /// Each JWT SHOULD encode a claim specific to the `resource_uri` of this
  /// Occurrence, but this is not validated by Grafeas metadata API
  /// implementations. The JWT itself is opaque to Grafeas.
  core.List<Jwt>? jwts;

  /// The serialized payload that is verified by one or more `signatures`.
  ///
  /// Required.
  core.String? serializedPayload;
  core.List<core.int> get serializedPayloadAsBytes =>
      convert.base64.decode(serializedPayload!);

  set serializedPayloadAsBytes(core.List<core.int> _bytes) {
    serializedPayload =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// One or more signatures over `serialized_payload`.
  ///
  /// Verifier implementations should consider this attestation message verified
  /// if at least one `signature` verifies `serialized_payload`. See `Signature`
  /// in common.proto for more details on signature structure and verification.
  core.List<Signature>? signatures;

  AttestationOccurrence();

  AttestationOccurrence.fromJson(core.Map _json) {
    if (_json.containsKey('jwts')) {
      jwts = (_json['jwts'] as core.List)
          .map<Jwt>((value) =>
              Jwt.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('serializedPayload')) {
      serializedPayload = _json['serializedPayload'] as core.String;
    }
    if (_json.containsKey('signatures')) {
      signatures = (_json['signatures'] as core.List)
          .map<Signature>((value) =>
              Signature.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (jwts != null) 'jwts': jwts!.map((value) => value.toJson()).toList(),
        if (serializedPayload != null) 'serializedPayload': serializedPayload!,
        if (signatures != null)
          'signatures': signatures!.map((value) => value.toJson()).toList(),
      };
}

/// Details of a build occurrence.
class BuildOccurrence {
  /// The actual provenance for the build.
  ///
  /// Required.
  BuildProvenance? provenance;

  /// Serialized JSON representation of the provenance, used in generating the
  /// build signature in the corresponding build note.
  ///
  /// After verifying the signature, `provenance_bytes` can be unmarshalled and
  /// compared to the provenance to confirm that it is unchanged. A
  /// base64-encoded string representation of the provenance bytes is used for
  /// the signature in order to interoperate with openssl which expects this
  /// format for signature verification. The serialized form is captured both to
  /// avoid ambiguity in how the provenance is marshalled to json as well to
  /// prevent incompatibilities with future changes.
  core.String? provenanceBytes;

  BuildOccurrence();

  BuildOccurrence.fromJson(core.Map _json) {
    if (_json.containsKey('provenance')) {
      provenance = BuildProvenance.fromJson(
          _json['provenance'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('provenanceBytes')) {
      provenanceBytes = _json['provenanceBytes'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (provenance != null) 'provenance': provenance!.toJson(),
        if (provenanceBytes != null) 'provenanceBytes': provenanceBytes!,
      };
}

/// Provenance of a build.
///
/// Contains all information needed to verify the full details about the build
/// from source to completion.
class BuildProvenance {
  /// Special options applied to this build.
  ///
  /// This is a catch-all field where build providers can enter any desired
  /// additional details.
  core.Map<core.String, core.String>? buildOptions;

  /// Version string of the builder at the time this build was executed.
  core.String? builderVersion;

  /// Output of the build.
  core.List<Artifact>? builtArtifacts;

  /// Commands requested by the build.
  core.List<Command>? commands;

  /// Time at which the build was created.
  core.String? createTime;

  /// E-mail address of the user who initiated this build.
  ///
  /// Note that this was the user's e-mail address at the time the build was
  /// initiated; this address may not represent the same end-user for all time.
  core.String? creator;

  /// Time at which execution of the build was finished.
  core.String? endTime;

  /// Unique identifier of the build.
  ///
  /// Required.
  core.String? id;

  /// URI where any logs for this provenance were written.
  core.String? logsUri;

  /// ID of the project.
  core.String? projectId;

  /// Details of the Source input to the build.
  Source? sourceProvenance;

  /// Time at which execution of the build was started.
  core.String? startTime;

  /// Trigger identifier if the build was triggered automatically; empty if not.
  core.String? triggerId;

  BuildProvenance();

  BuildProvenance.fromJson(core.Map _json) {
    if (_json.containsKey('buildOptions')) {
      buildOptions =
          (_json['buildOptions'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('builderVersion')) {
      builderVersion = _json['builderVersion'] as core.String;
    }
    if (_json.containsKey('builtArtifacts')) {
      builtArtifacts = (_json['builtArtifacts'] as core.List)
          .map<Artifact>((value) =>
              Artifact.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('commands')) {
      commands = (_json['commands'] as core.List)
          .map<Command>((value) =>
              Command.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('creator')) {
      creator = _json['creator'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('logsUri')) {
      logsUri = _json['logsUri'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('sourceProvenance')) {
      sourceProvenance = Source.fromJson(
          _json['sourceProvenance'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('triggerId')) {
      triggerId = _json['triggerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buildOptions != null) 'buildOptions': buildOptions!,
        if (builderVersion != null) 'builderVersion': builderVersion!,
        if (builtArtifacts != null)
          'builtArtifacts':
              builtArtifacts!.map((value) => value.toJson()).toList(),
        if (commands != null)
          'commands': commands!.map((value) => value.toJson()).toList(),
        if (createTime != null) 'createTime': createTime!,
        if (creator != null) 'creator': creator!,
        if (endTime != null) 'endTime': endTime!,
        if (id != null) 'id': id!,
        if (logsUri != null) 'logsUri': logsUri!,
        if (projectId != null) 'projectId': projectId!,
        if (sourceProvenance != null)
          'sourceProvenance': sourceProvenance!.toJson(),
        if (startTime != null) 'startTime': startTime!,
        if (triggerId != null) 'triggerId': triggerId!,
      };
}

/// The category to which the update belongs.
class Category {
  /// The identifier of the category.
  core.String? categoryId;

  /// The localized name of the category.
  core.String? name;

  Category();

  Category.fromJson(core.Map _json) {
    if (_json.containsKey('categoryId')) {
      categoryId = _json['categoryId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (categoryId != null) 'categoryId': categoryId!,
        if (name != null) 'name': name!,
      };
}

/// A CloudRepoSourceContext denotes a particular revision in a Google Cloud
/// Source Repo.
class CloudRepoSourceContext {
  /// An alias, which may be a branch or tag.
  AliasContext? aliasContext;

  /// The ID of the repo.
  RepoId? repoId;

  /// A revision ID.
  core.String? revisionId;

  CloudRepoSourceContext();

  CloudRepoSourceContext.fromJson(core.Map _json) {
    if (_json.containsKey('aliasContext')) {
      aliasContext = AliasContext.fromJson(
          _json['aliasContext'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('repoId')) {
      repoId = RepoId.fromJson(
          _json['repoId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('revisionId')) {
      revisionId = _json['revisionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aliasContext != null) 'aliasContext': aliasContext!.toJson(),
        if (repoId != null) 'repoId': repoId!.toJson(),
        if (revisionId != null) 'revisionId': revisionId!,
      };
}

/// Command describes a step performed as part of the build pipeline.
class Command {
  /// Command-line arguments used when executing this command.
  core.List<core.String>? args;

  /// Working directory (relative to project source root) used when running this
  /// command.
  core.String? dir;

  /// Environment variables set before running this command.
  core.List<core.String>? env;

  /// Optional unique identifier for this command, used in wait_for to reference
  /// this command as a dependency.
  core.String? id;

  /// Name of the command, as presented on the command line, or if the command
  /// is packaged as a Docker container, as presented to `docker pull`.
  ///
  /// Required.
  core.String? name;

  /// The ID(s) of the command(s) that this command depends on.
  core.List<core.String>? waitFor;

  Command();

  Command.fromJson(core.Map _json) {
    if (_json.containsKey('args')) {
      args = (_json['args'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('dir')) {
      dir = _json['dir'] as core.String;
    }
    if (_json.containsKey('env')) {
      env = (_json['env'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('waitFor')) {
      waitFor = (_json['waitFor'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (args != null) 'args': args!,
        if (dir != null) 'dir': dir!,
        if (env != null) 'env': env!,
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
        if (waitFor != null) 'waitFor': waitFor!,
      };
}

/// The period during which some deployable was active in a runtime.
class DeploymentOccurrence {
  /// Address of the runtime element hosting this deployment.
  core.String? address;

  /// Configuration used to create this deployment.
  core.String? config;

  /// Beginning of the lifetime of this deployment.
  ///
  /// Required.
  core.String? deployTime;

  /// Platform hosting this deployment.
  /// Possible string values are:
  /// - "PLATFORM_UNSPECIFIED" : Unknown.
  /// - "GKE" : Google Container Engine.
  /// - "FLEX" : Google App Engine: Flexible Environment.
  /// - "CUSTOM" : Custom user-defined platform.
  core.String? platform;

  /// Resource URI for the artifact being deployed taken from the deployable
  /// field with the same name.
  ///
  /// Output only.
  core.List<core.String>? resourceUri;

  /// End of the lifetime of this deployment.
  core.String? undeployTime;

  /// Identity of the user that triggered this deployment.
  core.String? userEmail;

  DeploymentOccurrence();

  DeploymentOccurrence.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = _json['address'] as core.String;
    }
    if (_json.containsKey('config')) {
      config = _json['config'] as core.String;
    }
    if (_json.containsKey('deployTime')) {
      deployTime = _json['deployTime'] as core.String;
    }
    if (_json.containsKey('platform')) {
      platform = _json['platform'] as core.String;
    }
    if (_json.containsKey('resourceUri')) {
      resourceUri = (_json['resourceUri'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('undeployTime')) {
      undeployTime = _json['undeployTime'] as core.String;
    }
    if (_json.containsKey('userEmail')) {
      userEmail = _json['userEmail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!,
        if (config != null) 'config': config!,
        if (deployTime != null) 'deployTime': deployTime!,
        if (platform != null) 'platform': platform!,
        if (resourceUri != null) 'resourceUri': resourceUri!,
        if (undeployTime != null) 'undeployTime': undeployTime!,
        if (userEmail != null) 'userEmail': userEmail!,
      };
}

/// Provides information about the analysis status of a discovered resource.
class DiscoveryOccurrence {
  /// The status of discovery for the resource.
  /// Possible string values are:
  /// - "ANALYSIS_STATUS_UNSPECIFIED" : Unknown.
  /// - "PENDING" : Resource is known but no action has been taken yet.
  /// - "SCANNING" : Resource is being analyzed.
  /// - "FINISHED_SUCCESS" : Analysis has finished successfully.
  /// - "FINISHED_FAILED" : Analysis has finished unsuccessfully, the analysis
  /// itself is in a bad state.
  /// - "FINISHED_UNSUPPORTED" : The resource is known not to be supported
  core.String? analysisStatus;

  /// When an error is encountered this will contain a LocalizedMessage under
  /// details to show to the user.
  ///
  /// The LocalizedMessage is output only and populated by the API.
  Status? analysisStatusError;

  /// Whether the resource is continuously analyzed.
  /// Possible string values are:
  /// - "CONTINUOUS_ANALYSIS_UNSPECIFIED" : Unknown.
  /// - "ACTIVE" : The resource is continuously analyzed.
  /// - "INACTIVE" : The resource is ignored for continuous analysis.
  core.String? continuousAnalysis;

  /// The CPE of the resource being scanned.
  core.String? cpe;

  /// The last time this resource was scanned.
  core.String? lastScanTime;

  DiscoveryOccurrence();

  DiscoveryOccurrence.fromJson(core.Map _json) {
    if (_json.containsKey('analysisStatus')) {
      analysisStatus = _json['analysisStatus'] as core.String;
    }
    if (_json.containsKey('analysisStatusError')) {
      analysisStatusError = Status.fromJson(
          _json['analysisStatusError'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('continuousAnalysis')) {
      continuousAnalysis = _json['continuousAnalysis'] as core.String;
    }
    if (_json.containsKey('cpe')) {
      cpe = _json['cpe'] as core.String;
    }
    if (_json.containsKey('lastScanTime')) {
      lastScanTime = _json['lastScanTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analysisStatus != null) 'analysisStatus': analysisStatus!,
        if (analysisStatusError != null)
          'analysisStatusError': analysisStatusError!.toJson(),
        if (continuousAnalysis != null)
          'continuousAnalysis': continuousAnalysis!,
        if (cpe != null) 'cpe': cpe!,
        if (lastScanTime != null) 'lastScanTime': lastScanTime!,
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

/// Container message for hashes of byte content of files, used in source
/// messages to verify integrity of source input to the build.
class FileHashes {
  /// Collection of file hashes.
  ///
  /// Required.
  core.List<Hash>? fileHash;

  FileHashes();

  FileHashes.fromJson(core.Map _json) {
    if (_json.containsKey('fileHash')) {
      fileHash = (_json['fileHash'] as core.List)
          .map<Hash>((value) =>
              Hash.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fileHash != null)
          'fileHash': fileHash!.map((value) => value.toJson()).toList(),
      };
}

/// A set of properties that uniquely identify a given Docker image.
class Fingerprint {
  /// The layer ID of the final layer in the Docker image's v1 representation.
  ///
  /// Required.
  core.String? v1Name;

  /// The ordered list of v2 blobs that represent a given image.
  ///
  /// Required.
  core.List<core.String>? v2Blob;

  /// The name of the image's v2 blobs computed via: \[bottom\] := v2_blobbottom
  /// := sha256(v2_blob\[N\] + " " + v2_name\[N+1\]) Only the name of the final
  /// blob is kept.
  ///
  /// Output only.
  core.String? v2Name;

  Fingerprint();

  Fingerprint.fromJson(core.Map _json) {
    if (_json.containsKey('v1Name')) {
      v1Name = _json['v1Name'] as core.String;
    }
    if (_json.containsKey('v2Blob')) {
      v2Blob = (_json['v2Blob'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('v2Name')) {
      v2Name = _json['v2Name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (v1Name != null) 'v1Name': v1Name!,
        if (v2Blob != null) 'v2Blob': v2Blob!,
        if (v2Name != null) 'v2Name': v2Name!,
      };
}

/// A SourceContext referring to a Gerrit project.
class GerritSourceContext {
  /// An alias, which may be a branch or tag.
  AliasContext? aliasContext;

  /// The full project name within the host.
  ///
  /// Projects may be nested, so "project/subproject" is a valid project name.
  /// The "repo name" is the hostURI/project.
  core.String? gerritProject;

  /// The URI of a running Gerrit instance.
  core.String? hostUri;

  /// A revision (commit) ID.
  core.String? revisionId;

  GerritSourceContext();

  GerritSourceContext.fromJson(core.Map _json) {
    if (_json.containsKey('aliasContext')) {
      aliasContext = AliasContext.fromJson(
          _json['aliasContext'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gerritProject')) {
      gerritProject = _json['gerritProject'] as core.String;
    }
    if (_json.containsKey('hostUri')) {
      hostUri = _json['hostUri'] as core.String;
    }
    if (_json.containsKey('revisionId')) {
      revisionId = _json['revisionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aliasContext != null) 'aliasContext': aliasContext!.toJson(),
        if (gerritProject != null) 'gerritProject': gerritProject!,
        if (hostUri != null) 'hostUri': hostUri!,
        if (revisionId != null) 'revisionId': revisionId!,
      };
}

/// A GitSourceContext denotes a particular revision in a third party Git
/// repository (e.g., GitHub).
class GitSourceContext {
  /// Git commit hash.
  core.String? revisionId;

  /// Git repository URL.
  core.String? url;

  GitSourceContext();

  GitSourceContext.fromJson(core.Map _json) {
    if (_json.containsKey('revisionId')) {
      revisionId = _json['revisionId'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (revisionId != null) 'revisionId': revisionId!,
        if (url != null) 'url': url!,
      };
}

/// Container message for hash values.
class Hash {
  /// The type of hash that was performed, e.g. "SHA-256".
  ///
  /// Required.
  core.String? type;

  /// The hash value.
  ///
  /// Required.
  core.String? value;
  core.List<core.int> get valueAsBytes => convert.base64.decode(value!);

  set valueAsBytes(core.List<core.int> _bytes) {
    value =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  Hash();

  Hash.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
      };
}

/// The unique identifier of the update.
class Identity {
  /// The revision number of the update.
  core.int? revision;

  /// The revision independent identifier of the update.
  core.String? updateId;

  Identity();

  Identity.fromJson(core.Map _json) {
    if (_json.containsKey('revision')) {
      revision = _json['revision'] as core.int;
    }
    if (_json.containsKey('updateId')) {
      updateId = _json['updateId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (revision != null) 'revision': revision!,
        if (updateId != null) 'updateId': updateId!,
      };
}

/// Details of the derived image portion of the DockerImage relationship.
///
/// This image would be produced from a Dockerfile with FROM .
class ImageOccurrence {
  /// This contains the base image URL for the derived image occurrence.
  ///
  /// Output only.
  core.String? baseResourceUrl;

  /// The number of layers by which this image differs from the associated image
  /// basis.
  ///
  /// Output only.
  core.int? distance;

  /// The fingerprint of the derived image.
  ///
  /// Required.
  Fingerprint? fingerprint;

  /// This contains layer-specific metadata, if populated it has length
  /// "distance" and is ordered with \[distance\] being the layer immediately
  /// following the base image and \[1\] being the final layer.
  core.List<Layer>? layerInfo;

  ImageOccurrence();

  ImageOccurrence.fromJson(core.Map _json) {
    if (_json.containsKey('baseResourceUrl')) {
      baseResourceUrl = _json['baseResourceUrl'] as core.String;
    }
    if (_json.containsKey('distance')) {
      distance = _json['distance'] as core.int;
    }
    if (_json.containsKey('fingerprint')) {
      fingerprint = Fingerprint.fromJson(
          _json['fingerprint'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('layerInfo')) {
      layerInfo = (_json['layerInfo'] as core.List)
          .map<Layer>((value) =>
              Layer.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (baseResourceUrl != null) 'baseResourceUrl': baseResourceUrl!,
        if (distance != null) 'distance': distance!,
        if (fingerprint != null) 'fingerprint': fingerprint!.toJson(),
        if (layerInfo != null)
          'layerInfo': layerInfo!.map((value) => value.toJson()).toList(),
      };
}

class Jwt {
  /// The compact encoding of a JWS, which is always three base64 encoded
  /// strings joined by periods.
  ///
  /// For details, see: https://tools.ietf.org/html/rfc7515.html#section-3.1
  core.String? compactJwt;

  Jwt();

  Jwt.fromJson(core.Map _json) {
    if (_json.containsKey('compactJwt')) {
      compactJwt = _json['compactJwt'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (compactJwt != null) 'compactJwt': compactJwt!,
      };
}

/// Layer holds metadata specific to a layer of a Docker image.
class Layer {
  /// The recovered arguments to the Dockerfile directive.
  core.String? arguments;

  /// The recovered Dockerfile directive used to construct this layer.
  ///
  /// See https://docs.docker.com/engine/reference/builder/ for more
  /// information.
  ///
  /// Required.
  core.String? directive;

  Layer();

  Layer.fromJson(core.Map _json) {
    if (_json.containsKey('arguments')) {
      arguments = _json['arguments'] as core.String;
    }
    if (_json.containsKey('directive')) {
      directive = _json['directive'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arguments != null) 'arguments': arguments!,
        if (directive != null) 'directive': directive!,
      };
}

/// The response message for Operations.ListOperations.
class ListOperationsResponse {
  /// The standard List next-page token.
  core.String? nextPageToken;

  /// A list of operations that matches the specified filter in the request.
  core.List<Operation>? operations;

  ListOperationsResponse();

  ListOperationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<Operation>((value) =>
              Operation.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
      };
}

/// ListVulnerabilitiesResponse contains a single page of vulnerabilities
/// resulting from a scan.
class ListVulnerabilitiesResponseV1 {
  /// A page token that can be used in a subsequent call to ListVulnerabilities
  /// to continue retrieving results.
  core.String? nextPageToken;

  /// The list of Vulnerability Occurrences resulting from a scan.
  core.List<Occurrence>? occurrences;

  ListVulnerabilitiesResponseV1();

  ListVulnerabilitiesResponseV1.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('occurrences')) {
      occurrences = (_json['occurrences'] as core.List)
          .map<Occurrence>((value) =>
              Occurrence.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (occurrences != null)
          'occurrences': occurrences!.map((value) => value.toJson()).toList(),
      };
}

/// An occurrence of a particular package installation found within a system's
/// filesystem.
///
/// E.g., glibc was found in `/var/lib/dpkg/status`.
class Location {
  /// The CPE URI in [CPE format](https://cpe.mitre.org/specification/) denoting
  /// the package manager version distributing a package.
  ///
  /// Required.
  core.String? cpeUri;

  /// The path from which we gathered that this package/version is installed.
  core.String? path;

  /// The version installed at this location.
  Version? version;

  Location();

  Location.fromJson(core.Map _json) {
    if (_json.containsKey('cpeUri')) {
      cpeUri = _json['cpeUri'] as core.String;
    }
    if (_json.containsKey('path')) {
      path = _json['path'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = Version.fromJson(
          _json['version'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cpeUri != null) 'cpeUri': cpeUri!,
        if (path != null) 'path': path!,
        if (version != null) 'version': version!.toJson(),
      };
}

/// An instance of an analysis type that has been found on a resource.
class Occurrence {
  /// Describes an attestation of an artifact.
  AttestationOccurrence? attestation;

  /// Describes a verifiable build.
  BuildOccurrence? build;

  /// The time this occurrence was created.
  ///
  /// Output only.
  core.String? createTime;

  /// Describes the deployment of an artifact on a runtime.
  DeploymentOccurrence? deployment;

  /// Describes when a resource was discovered.
  DiscoveryOccurrence? discovery;

  /// Describes how this resource derives from the basis in the associated note.
  ImageOccurrence? image;

  /// This explicitly denotes which of the occurrence details are specified.
  ///
  /// This field can be used as a filter in list requests.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "NOTE_KIND_UNSPECIFIED" : Default value. This value is unused.
  /// - "VULNERABILITY" : The note and occurrence represent a package
  /// vulnerability.
  /// - "BUILD" : The note and occurrence assert build provenance.
  /// - "IMAGE" : This represents an image basis relationship.
  /// - "PACKAGE" : This represents a package installed via a package manager.
  /// - "DEPLOYMENT" : The note and occurrence track deployment events.
  /// - "DISCOVERY" : The note and occurrence track the initial discovery status
  /// of a resource.
  /// - "ATTESTATION" : This represents a logical "role" that can attest to
  /// artifacts.
  /// - "UPGRADE" : This represents an available package upgrade.
  core.String? kind;

  /// The name of the occurrence in the form of
  /// `projects/[PROJECT_ID]/occurrences/[OCCURRENCE_ID]`.
  ///
  /// Output only.
  core.String? name;

  /// The analysis note associated with this occurrence, in the form of
  /// `projects/[PROVIDER_ID]/notes/[NOTE_ID]`.
  ///
  /// This field can be used as a filter in list requests.
  ///
  /// Required. Immutable.
  core.String? noteName;

  /// Describes the installation of a package on the linked resource.
  PackageOccurrence? package;

  /// A description of actions that can be taken to remedy the note.
  core.String? remediation;

  /// A URI that represents the resource for which the occurrence applies.
  ///
  /// For example, `https://gcr.io/project/image@sha256:123abc` for a Docker
  /// image.
  ///
  /// Required. Immutable.
  core.String? resourceUri;

  /// The time this occurrence was last updated.
  ///
  /// Output only.
  core.String? updateTime;

  /// Describes an available package upgrade on the linked resource.
  UpgradeOccurrence? upgrade;

  /// Describes a security vulnerability.
  VulnerabilityOccurrence? vulnerability;

  Occurrence();

  Occurrence.fromJson(core.Map _json) {
    if (_json.containsKey('attestation')) {
      attestation = AttestationOccurrence.fromJson(
          _json['attestation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('build')) {
      build = BuildOccurrence.fromJson(
          _json['build'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('deployment')) {
      deployment = DeploymentOccurrence.fromJson(
          _json['deployment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('discovery')) {
      discovery = DiscoveryOccurrence.fromJson(
          _json['discovery'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('image')) {
      image = ImageOccurrence.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('noteName')) {
      noteName = _json['noteName'] as core.String;
    }
    if (_json.containsKey('package')) {
      package = PackageOccurrence.fromJson(
          _json['package'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('remediation')) {
      remediation = _json['remediation'] as core.String;
    }
    if (_json.containsKey('resourceUri')) {
      resourceUri = _json['resourceUri'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('upgrade')) {
      upgrade = UpgradeOccurrence.fromJson(
          _json['upgrade'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('vulnerability')) {
      vulnerability = VulnerabilityOccurrence.fromJson(
          _json['vulnerability'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attestation != null) 'attestation': attestation!.toJson(),
        if (build != null) 'build': build!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (deployment != null) 'deployment': deployment!.toJson(),
        if (discovery != null) 'discovery': discovery!.toJson(),
        if (image != null) 'image': image!.toJson(),
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (noteName != null) 'noteName': noteName!,
        if (package != null) 'package': package!.toJson(),
        if (remediation != null) 'remediation': remediation!,
        if (resourceUri != null) 'resourceUri': resourceUri!,
        if (updateTime != null) 'updateTime': updateTime!,
        if (upgrade != null) 'upgrade': upgrade!.toJson(),
        if (vulnerability != null) 'vulnerability': vulnerability!.toJson(),
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

class PackageData {
  /// The cpe_uri in [cpe format](https://cpe.mitre.org/specification/) in which
  /// the vulnerability may manifest.
  ///
  /// Examples include distro or storage location for vulnerable jar.
  core.String? cpeUri;

  /// The OS affected by a vulnerability This field is deprecated and the
  /// information is in cpe_uri
  core.String? os;

  /// The version of the OS This field is deprecated and the information is in
  /// cpe_uri
  core.String? osVersion;

  /// The package being analysed for vulnerabilities
  core.String? package;
  core.String? unused;

  /// The version of the package being analysed
  core.String? version;

  PackageData();

  PackageData.fromJson(core.Map _json) {
    if (_json.containsKey('cpeUri')) {
      cpeUri = _json['cpeUri'] as core.String;
    }
    if (_json.containsKey('os')) {
      os = _json['os'] as core.String;
    }
    if (_json.containsKey('osVersion')) {
      osVersion = _json['osVersion'] as core.String;
    }
    if (_json.containsKey('package')) {
      package = _json['package'] as core.String;
    }
    if (_json.containsKey('unused')) {
      unused = _json['unused'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cpeUri != null) 'cpeUri': cpeUri!,
        if (os != null) 'os': os!,
        if (osVersion != null) 'osVersion': osVersion!,
        if (package != null) 'package': package!,
        if (unused != null) 'unused': unused!,
        if (version != null) 'version': version!,
      };
}

/// A detail for a distro and package this vulnerability occurrence was found in
/// and its associated fix (if one is available).
class PackageIssue {
  /// The [CPE URI](https://cpe.mitre.org/specification/) this vulnerability was
  /// found in.
  ///
  /// Required.
  core.String? affectedCpeUri;

  /// The package this vulnerability was found in.
  ///
  /// Required.
  core.String? affectedPackage;

  /// The version of the package that is installed on the resource affected by
  /// this vulnerability.
  ///
  /// Required.
  Version? affectedVersion;

  /// Whether a fix is available for this package.
  ///
  /// Output only.
  core.bool? fixAvailable;

  /// The [CPE URI](https://cpe.mitre.org/specification/) this vulnerability was
  /// fixed in.
  ///
  /// It is possible for this to be different from the affected_cpe_uri.
  core.String? fixedCpeUri;

  /// The package this vulnerability was fixed in.
  ///
  /// It is possible for this to be different from the affected_package.
  core.String? fixedPackage;

  /// The version of the package this vulnerability was fixed in.
  ///
  /// Setting this to VersionKind.MAXIMUM means no fix is yet available.
  ///
  /// Required.
  Version? fixedVersion;

  PackageIssue();

  PackageIssue.fromJson(core.Map _json) {
    if (_json.containsKey('affectedCpeUri')) {
      affectedCpeUri = _json['affectedCpeUri'] as core.String;
    }
    if (_json.containsKey('affectedPackage')) {
      affectedPackage = _json['affectedPackage'] as core.String;
    }
    if (_json.containsKey('affectedVersion')) {
      affectedVersion = Version.fromJson(
          _json['affectedVersion'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fixAvailable')) {
      fixAvailable = _json['fixAvailable'] as core.bool;
    }
    if (_json.containsKey('fixedCpeUri')) {
      fixedCpeUri = _json['fixedCpeUri'] as core.String;
    }
    if (_json.containsKey('fixedPackage')) {
      fixedPackage = _json['fixedPackage'] as core.String;
    }
    if (_json.containsKey('fixedVersion')) {
      fixedVersion = Version.fromJson(
          _json['fixedVersion'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (affectedCpeUri != null) 'affectedCpeUri': affectedCpeUri!,
        if (affectedPackage != null) 'affectedPackage': affectedPackage!,
        if (affectedVersion != null)
          'affectedVersion': affectedVersion!.toJson(),
        if (fixAvailable != null) 'fixAvailable': fixAvailable!,
        if (fixedCpeUri != null) 'fixedCpeUri': fixedCpeUri!,
        if (fixedPackage != null) 'fixedPackage': fixedPackage!,
        if (fixedVersion != null) 'fixedVersion': fixedVersion!.toJson(),
      };
}

/// Details on how a particular software package was installed on a system.
class PackageOccurrence {
  /// All of the places within the filesystem versions of this package have been
  /// found.
  ///
  /// Required.
  core.List<Location>? location;

  /// The name of the installed package.
  ///
  /// Output only.
  core.String? name;

  PackageOccurrence();

  PackageOccurrence.fromJson(core.Map _json) {
    if (_json.containsKey('location')) {
      location = (_json['location'] as core.List)
          .map<Location>((value) =>
              Location.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (location != null)
          'location': location!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
      };
}

/// Selects a repo using a Google Cloud Platform project ID (e.g.,
/// winged-cargo-31) and a repo name within that project.
class ProjectRepoId {
  /// The ID of the project.
  core.String? projectId;

  /// The name of the repo.
  ///
  /// Leave empty for the default repo.
  core.String? repoName;

  ProjectRepoId();

  ProjectRepoId.fromJson(core.Map _json) {
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('repoName')) {
      repoName = _json['repoName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (projectId != null) 'projectId': projectId!,
        if (repoName != null) 'repoName': repoName!,
      };
}

/// Metadata for any related URL information.
class RelatedUrl {
  /// Label to describe usage of the URL.
  core.String? label;

  /// Specific URL associated with the resource.
  core.String? url;

  RelatedUrl();

  RelatedUrl.fromJson(core.Map _json) {
    if (_json.containsKey('label')) {
      label = _json['label'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (label != null) 'label': label!,
        if (url != null) 'url': url!,
      };
}

/// A unique identifier for a Cloud Repo.
class RepoId {
  /// A combination of a project ID and a repo name.
  ProjectRepoId? projectRepoId;

  /// A server-assigned, globally unique identifier.
  core.String? uid;

  RepoId();

  RepoId.fromJson(core.Map _json) {
    if (_json.containsKey('projectRepoId')) {
      projectRepoId = ProjectRepoId.fromJson(
          _json['projectRepoId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('uid')) {
      uid = _json['uid'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (projectRepoId != null) 'projectRepoId': projectRepoId!.toJson(),
        if (uid != null) 'uid': uid!,
      };
}

/// Verifiers (e.g. Kritis implementations) MUST verify signatures with respect
/// to the trust anchors defined in policy (e.g. a Kritis policy).
///
/// Typically this means that the verifier has been configured with a map from
/// `public_key_id` to public key material (and any required parameters, e.g.
/// signing algorithm). In particular, verification implementations MUST NOT
/// treat the signature `public_key_id` as anything more than a key lookup hint.
/// The `public_key_id` DOES NOT validate or authenticate a public key; it only
/// provides a mechanism for quickly selecting a public key ALREADY CONFIGURED
/// on the verifier through a trusted channel. Verification implementations MUST
/// reject signatures in any of the following circumstances: * The
/// `public_key_id` is not recognized by the verifier. * The public key that
/// `public_key_id` refers to does not verify the signature with respect to the
/// payload. The `signature` contents SHOULD NOT be "attached" (where the
/// payload is included with the serialized `signature` bytes). Verifiers MUST
/// ignore any "attached" payload and only verify signatures with respect to
/// explicitly provided payload (e.g. a `payload` field on the proto message
/// that holds this Signature, or the canonical serialization of the proto
/// message that holds this signature).
class Signature {
  /// The identifier for the public key that verifies this signature.
  ///
  /// * The `public_key_id` is required. * The `public_key_id` SHOULD be an
  /// RFC3986 conformant URI. * When possible, the `public_key_id` SHOULD be an
  /// immutable reference, such as a cryptographic digest. Examples of valid
  /// `public_key_id`s: OpenPGP V4 public key fingerprint: *
  /// "openpgp4fpr:74FAF3B861BDA0870C7B6DEF607E48D2A663AEEA" See
  /// https://www.iana.org/assignments/uri-schemes/prov/openpgp4fpr for more
  /// details on this scheme. RFC6920 digest-named SubjectPublicKeyInfo (digest
  /// of the DER serialization): *
  /// "ni:///sha-256;cD9o9Cq6LG3jD0iKXqEi_vdjJGecm_iXkbqVoScViaU" *
  /// "nih:///sha-256;703f68f42aba2c6de30f488a5ea122fef76324679c9bf89791ba95a1271589a5"
  core.String? publicKeyId;

  /// The content of the signature, an opaque bytestring.
  ///
  /// The payload that this signature verifies MUST be unambiguously provided
  /// with the Signature during verification. A wrapper message might provide
  /// the payload explicitly. Alternatively, a message might have a canonical
  /// serialization that can always be unambiguously computed to derive the
  /// payload.
  core.String? signature;
  core.List<core.int> get signatureAsBytes => convert.base64.decode(signature!);

  set signatureAsBytes(core.List<core.int> _bytes) {
    signature =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  Signature();

  Signature.fromJson(core.Map _json) {
    if (_json.containsKey('publicKeyId')) {
      publicKeyId = _json['publicKeyId'] as core.String;
    }
    if (_json.containsKey('signature')) {
      signature = _json['signature'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (publicKeyId != null) 'publicKeyId': publicKeyId!,
        if (signature != null) 'signature': signature!,
      };
}

/// Source describes the location of the source used for the build.
class Source {
  /// If provided, some of the source code used for the build may be found in
  /// these locations, in the case where the source repository had multiple
  /// remotes or submodules.
  ///
  /// This list will not include the context specified in the context field.
  core.List<SourceContext>? additionalContexts;

  /// If provided, the input binary artifacts for the build came from this
  /// location.
  core.String? artifactStorageSourceUri;

  /// If provided, the source code used for the build came from this location.
  SourceContext? context;

  /// Hash(es) of the build source, which can be used to verify that the
  /// original source integrity was maintained in the build.
  ///
  /// The keys to this map are file paths used as build source and the values
  /// contain the hash values for those files. If the build source came in a
  /// single package such as a gzipped tarfile (.tar.gz), the FileHash will be
  /// for the single path to that file.
  core.Map<core.String, FileHashes>? fileHashes;

  Source();

  Source.fromJson(core.Map _json) {
    if (_json.containsKey('additionalContexts')) {
      additionalContexts = (_json['additionalContexts'] as core.List)
          .map<SourceContext>((value) => SourceContext.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('artifactStorageSourceUri')) {
      artifactStorageSourceUri =
          _json['artifactStorageSourceUri'] as core.String;
    }
    if (_json.containsKey('context')) {
      context = SourceContext.fromJson(
          _json['context'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fileHashes')) {
      fileHashes =
          (_json['fileHashes'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          FileHashes.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalContexts != null)
          'additionalContexts':
              additionalContexts!.map((value) => value.toJson()).toList(),
        if (artifactStorageSourceUri != null)
          'artifactStorageSourceUri': artifactStorageSourceUri!,
        if (context != null) 'context': context!.toJson(),
        if (fileHashes != null)
          'fileHashes':
              fileHashes!.map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// A SourceContext is a reference to a tree of files.
///
/// A SourceContext together with a path point to a unique revision of a single
/// file or directory.
class SourceContext {
  /// A SourceContext referring to a revision in a Google Cloud Source Repo.
  CloudRepoSourceContext? cloudRepo;

  /// A SourceContext referring to a Gerrit project.
  GerritSourceContext? gerrit;

  /// A SourceContext referring to any third party Git repo (e.g., GitHub).
  GitSourceContext? git;

  /// Labels with user defined metadata.
  core.Map<core.String, core.String>? labels;

  SourceContext();

  SourceContext.fromJson(core.Map _json) {
    if (_json.containsKey('cloudRepo')) {
      cloudRepo = CloudRepoSourceContext.fromJson(
          _json['cloudRepo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gerrit')) {
      gerrit = GerritSourceContext.fromJson(
          _json['gerrit'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('git')) {
      git = GitSourceContext.fromJson(
          _json['git'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudRepo != null) 'cloudRepo': cloudRepo!.toJson(),
        if (gerrit != null) 'gerrit': gerrit!.toJson(),
        if (git != null) 'git': git!.toJson(),
        if (labels != null) 'labels': labels!,
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

/// The Upgrade Distribution represents metadata about the Upgrade for each
/// operating system (CPE).
///
/// Some distributions have additional metadata around updates, classifying them
/// into various categories and severities.
class UpgradeDistribution {
  /// The operating system classification of this Upgrade, as specified by the
  /// upstream operating system upgrade feed.
  ///
  /// For Windows the classification is one of the category_ids listed at
  /// https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ff357803(v=vs.85)
  core.String? classification;

  /// Required - The specific operating system this metadata applies to.
  ///
  /// See https://cpe.mitre.org/specification/.
  core.String? cpeUri;

  /// The cve tied to this Upgrade.
  core.List<core.String>? cve;

  /// The severity as specified by the upstream operating system.
  core.String? severity;

  UpgradeDistribution();

  UpgradeDistribution.fromJson(core.Map _json) {
    if (_json.containsKey('classification')) {
      classification = _json['classification'] as core.String;
    }
    if (_json.containsKey('cpeUri')) {
      cpeUri = _json['cpeUri'] as core.String;
    }
    if (_json.containsKey('cve')) {
      cve = (_json['cve'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (classification != null) 'classification': classification!,
        if (cpeUri != null) 'cpeUri': cpeUri!,
        if (cve != null) 'cve': cve!,
        if (severity != null) 'severity': severity!,
      };
}

/// An Upgrade Occurrence represents that a specific resource_url could install
/// a specific upgrade.
///
/// This presence is supplied via local sources (i.e. it is present in the
/// mirror and the running system has noticed its availability). For Windows,
/// both distribution and windows_update contain information for the Windows
/// update.
class UpgradeOccurrence {
  /// Metadata about the upgrade for available for the specific operating system
  /// for the resource_url.
  ///
  /// This allows efficient filtering, as well as making it easier to use the
  /// occurrence.
  UpgradeDistribution? distribution;

  /// Required for non-Windows OS.
  ///
  /// The package this Upgrade is for.
  core.String? package;

  /// Required for non-Windows OS.
  ///
  /// The version of the package in a machine + human readable form.
  Version? parsedVersion;

  /// Required for Windows OS.
  ///
  /// Represents the metadata about the Windows update.
  WindowsUpdate? windowsUpdate;

  UpgradeOccurrence();

  UpgradeOccurrence.fromJson(core.Map _json) {
    if (_json.containsKey('distribution')) {
      distribution = UpgradeDistribution.fromJson(
          _json['distribution'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('package')) {
      package = _json['package'] as core.String;
    }
    if (_json.containsKey('parsedVersion')) {
      parsedVersion = Version.fromJson(
          _json['parsedVersion'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('windowsUpdate')) {
      windowsUpdate = WindowsUpdate.fromJson(
          _json['windowsUpdate'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (distribution != null) 'distribution': distribution!.toJson(),
        if (package != null) 'package': package!,
        if (parsedVersion != null) 'parsedVersion': parsedVersion!.toJson(),
        if (windowsUpdate != null) 'windowsUpdate': windowsUpdate!.toJson(),
      };
}

/// Version contains structured information about the version of a package.
class Version {
  /// Used to correct mistakes in the version numbering scheme.
  core.int? epoch;

  /// Human readable version string.
  ///
  /// This string is of the form :- and is only set when kind is NORMAL.
  core.String? fullName;

  /// Whether this version is specifying part of an inclusive range.
  ///
  /// Grafeas does not have the capability to specify version ranges; instead we
  /// have fields that specify start version and end versions. At times this is
  /// insufficient - we also need to specify whether the version is included in
  /// the range or is excluded from the range. This boolean is expected to be
  /// set to true when the version is included in a range.
  core.bool? inclusive;

  /// Distinguishes between sentinel MIN/MAX versions and normal versions.
  ///
  /// Required.
  /// Possible string values are:
  /// - "VERSION_KIND_UNSPECIFIED" : Unknown.
  /// - "NORMAL" : A standard package version.
  /// - "MINIMUM" : A special version representing negative infinity.
  /// - "MAXIMUM" : A special version representing positive infinity.
  core.String? kind;

  /// Required only when version kind is NORMAL.
  ///
  /// The main part of the version name.
  core.String? name;

  /// The iteration of the package build from the above version.
  core.String? revision;

  Version();

  Version.fromJson(core.Map _json) {
    if (_json.containsKey('epoch')) {
      epoch = _json['epoch'] as core.int;
    }
    if (_json.containsKey('fullName')) {
      fullName = _json['fullName'] as core.String;
    }
    if (_json.containsKey('inclusive')) {
      inclusive = _json['inclusive'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('revision')) {
      revision = _json['revision'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (epoch != null) 'epoch': epoch!,
        if (fullName != null) 'fullName': fullName!,
        if (inclusive != null) 'inclusive': inclusive!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (revision != null) 'revision': revision!,
      };
}

/// An occurrence of a severity vulnerability on a resource.
class VulnerabilityOccurrence {
  /// The CVSS score of this vulnerability.
  ///
  /// CVSS score is on a scale of 0 - 10 where 0 indicates low severity and 10
  /// indicates high severity.
  ///
  /// Output only.
  core.double? cvssScore;

  /// The distro assigned severity for this vulnerability when it is available,
  /// otherwise this is the note provider assigned severity.
  /// Possible string values are:
  /// - "SEVERITY_UNSPECIFIED" : Unknown.
  /// - "MINIMAL" : Minimal severity.
  /// - "LOW" : Low severity.
  /// - "MEDIUM" : Medium severity.
  /// - "HIGH" : High severity.
  /// - "CRITICAL" : Critical severity.
  core.String? effectiveSeverity;

  /// Whether at least one of the affected packages has a fix available.
  ///
  /// Output only.
  core.bool? fixAvailable;

  /// A detailed description of this vulnerability.
  ///
  /// Output only.
  core.String? longDescription;

  /// The set of affected locations and their fixes (if available) within the
  /// associated resource.
  ///
  /// Required.
  core.List<PackageIssue>? packageIssue;

  /// URLs related to this vulnerability.
  ///
  /// Output only.
  core.List<RelatedUrl>? relatedUrls;

  /// The note provider assigned severity of this vulnerability.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "SEVERITY_UNSPECIFIED" : Unknown.
  /// - "MINIMAL" : Minimal severity.
  /// - "LOW" : Low severity.
  /// - "MEDIUM" : Medium severity.
  /// - "HIGH" : High severity.
  /// - "CRITICAL" : Critical severity.
  core.String? severity;

  /// A one sentence description of this vulnerability.
  ///
  /// Output only.
  core.String? shortDescription;

  /// The type of package; whether native or non native (e.g., ruby gems,
  /// node.js packages, etc.).
  core.String? type;

  VulnerabilityOccurrence();

  VulnerabilityOccurrence.fromJson(core.Map _json) {
    if (_json.containsKey('cvssScore')) {
      cvssScore = (_json['cvssScore'] as core.num).toDouble();
    }
    if (_json.containsKey('effectiveSeverity')) {
      effectiveSeverity = _json['effectiveSeverity'] as core.String;
    }
    if (_json.containsKey('fixAvailable')) {
      fixAvailable = _json['fixAvailable'] as core.bool;
    }
    if (_json.containsKey('longDescription')) {
      longDescription = _json['longDescription'] as core.String;
    }
    if (_json.containsKey('packageIssue')) {
      packageIssue = (_json['packageIssue'] as core.List)
          .map<PackageIssue>((value) => PackageIssue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('relatedUrls')) {
      relatedUrls = (_json['relatedUrls'] as core.List)
          .map<RelatedUrl>((value) =>
              RelatedUrl.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
    if (_json.containsKey('shortDescription')) {
      shortDescription = _json['shortDescription'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cvssScore != null) 'cvssScore': cvssScore!,
        if (effectiveSeverity != null) 'effectiveSeverity': effectiveSeverity!,
        if (fixAvailable != null) 'fixAvailable': fixAvailable!,
        if (longDescription != null) 'longDescription': longDescription!,
        if (packageIssue != null)
          'packageIssue': packageIssue!.map((value) => value.toJson()).toList(),
        if (relatedUrls != null)
          'relatedUrls': relatedUrls!.map((value) => value.toJson()).toList(),
        if (severity != null) 'severity': severity!,
        if (shortDescription != null) 'shortDescription': shortDescription!,
        if (type != null) 'type': type!,
      };
}

/// Windows Update represents the metadata about the update for the Windows
/// operating system.
///
/// The fields in this message come from the Windows Update API documented at
/// https://docs.microsoft.com/en-us/windows/win32/api/wuapi/nn-wuapi-iupdate.
class WindowsUpdate {
  /// The list of categories to which the update belongs.
  core.List<Category>? categories;

  /// The localized description of the update.
  core.String? description;

  /// Required - The unique identifier for the update.
  Identity? identity;

  /// The Microsoft Knowledge Base article IDs that are associated with the
  /// update.
  core.List<core.String>? kbArticleIds;

  /// The last published timestamp of the update.
  core.String? lastPublishedTimestamp;

  /// The hyperlink to the support information for the update.
  core.String? supportUrl;

  /// The localized title of the update.
  core.String? title;

  WindowsUpdate();

  WindowsUpdate.fromJson(core.Map _json) {
    if (_json.containsKey('categories')) {
      categories = (_json['categories'] as core.List)
          .map<Category>((value) =>
              Category.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('identity')) {
      identity = Identity.fromJson(
          _json['identity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kbArticleIds')) {
      kbArticleIds = (_json['kbArticleIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('lastPublishedTimestamp')) {
      lastPublishedTimestamp = _json['lastPublishedTimestamp'] as core.String;
    }
    if (_json.containsKey('supportUrl')) {
      supportUrl = _json['supportUrl'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (categories != null)
          'categories': categories!.map((value) => value.toJson()).toList(),
        if (description != null) 'description': description!,
        if (identity != null) 'identity': identity!.toJson(),
        if (kbArticleIds != null) 'kbArticleIds': kbArticleIds!,
        if (lastPublishedTimestamp != null)
          'lastPublishedTimestamp': lastPublishedTimestamp!,
        if (supportUrl != null) 'supportUrl': supportUrl!,
        if (title != null) 'title': title!,
      };
}
