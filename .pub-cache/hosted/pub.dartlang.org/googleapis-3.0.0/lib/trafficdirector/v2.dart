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

/// Traffic Director API - v2
///
/// For more information, see <https://cloud.google.com/traffic-director>
///
/// Create an instance of [TrafficDirectorServiceApi] to access these resources:
///
/// - [DiscoveryResource]
library trafficdirector.v2;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

class TrafficDirectorServiceApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  DiscoveryResource get discovery => DiscoveryResource(_requester);

  TrafficDirectorServiceApi(http.Client client,
      {core.String rootUrl = 'https://trafficdirector.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class DiscoveryResource {
  final commons.ApiRequester _requester;

  DiscoveryResource(commons.ApiRequester client) : _requester = client;

  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ClientStatusResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ClientStatusResponse> clientStatus(
    ClientStatusRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v2/discovery:client_status';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ClientStatusResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Addresses specify either a logical or physical address and port, which are
/// used to tell Envoy where to bind/listen, connect to upstream and find
/// management servers.
class Address {
  Pipe? pipe;
  SocketAddress? socketAddress;

  Address();

  Address.fromJson(core.Map _json) {
    if (_json.containsKey('pipe')) {
      pipe =
          Pipe.fromJson(_json['pipe'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('socketAddress')) {
      socketAddress = SocketAddress.fromJson(
          _json['socketAddress'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pipe != null) 'pipe': pipe!.toJson(),
        if (socketAddress != null) 'socketAddress': socketAddress!.toJson(),
      };
}

/// BuildVersion combines SemVer version of extension with free-form build
/// information (i.e. 'alpha', 'private-build') as a set of strings.
class BuildVersion {
  /// Free-form build information.
  ///
  /// Envoy defines several well known keys in the
  /// source/common/version/version.h file
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  /// SemVer version of extension.
  SemanticVersion? version;

  BuildVersion();

  BuildVersion.fromJson(core.Map _json) {
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('version')) {
      version = SemanticVersion.fromJson(
          _json['version'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metadata != null) 'metadata': metadata!,
        if (version != null) 'version': version!.toJson(),
      };
}

/// All xds configs for a particular client.
class ClientConfig {
  /// Node for a particular client.
  Node? node;
  core.List<PerXdsConfig>? xdsConfig;

  ClientConfig();

  ClientConfig.fromJson(core.Map _json) {
    if (_json.containsKey('node')) {
      node =
          Node.fromJson(_json['node'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('xdsConfig')) {
      xdsConfig = (_json['xdsConfig'] as core.List)
          .map<PerXdsConfig>((value) => PerXdsConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (node != null) 'node': node!.toJson(),
        if (xdsConfig != null)
          'xdsConfig': xdsConfig!.map((value) => value.toJson()).toList(),
      };
}

/// Request for client status of clients identified by a list of NodeMatchers.
class ClientStatusRequest {
  /// Management server can use these match criteria to identify clients.
  ///
  /// The match follows OR semantics.
  core.List<NodeMatcher>? nodeMatchers;

  ClientStatusRequest();

  ClientStatusRequest.fromJson(core.Map _json) {
    if (_json.containsKey('nodeMatchers')) {
      nodeMatchers = (_json['nodeMatchers'] as core.List)
          .map<NodeMatcher>((value) => NodeMatcher.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nodeMatchers != null)
          'nodeMatchers': nodeMatchers!.map((value) => value.toJson()).toList(),
      };
}

class ClientStatusResponse {
  /// Client configs for the clients specified in the ClientStatusRequest.
  core.List<ClientConfig>? config;

  ClientStatusResponse();

  ClientStatusResponse.fromJson(core.Map _json) {
    if (_json.containsKey('config')) {
      config = (_json['config'] as core.List)
          .map<ClientConfig>((value) => ClientConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (config != null)
          'config': config!.map((value) => value.toJson()).toList(),
      };
}

/// Envoy's cluster manager fills this message with all currently known
/// clusters.
///
/// Cluster configuration information can be used to recreate an Envoy
/// configuration by populating all clusters as static clusters or by returning
/// them in a CDS response.
class ClustersConfigDump {
  /// The dynamically loaded active clusters.
  ///
  /// These are clusters that are available to service data plane traffic.
  core.List<DynamicCluster>? dynamicActiveClusters;

  /// The dynamically loaded warming clusters.
  ///
  /// These are clusters that are currently undergoing warming in preparation to
  /// service data plane traffic. Note that if attempting to recreate an Envoy
  /// configuration from a configuration dump, the warming clusters should
  /// generally be discarded.
  core.List<DynamicCluster>? dynamicWarmingClusters;

  /// The statically loaded cluster configs.
  core.List<StaticCluster>? staticClusters;

  /// This is the :ref:`version_info ` in the last processed CDS discovery
  /// response.
  ///
  /// If there are only static bootstrap clusters, this field will be "".
  core.String? versionInfo;

  ClustersConfigDump();

  ClustersConfigDump.fromJson(core.Map _json) {
    if (_json.containsKey('dynamicActiveClusters')) {
      dynamicActiveClusters = (_json['dynamicActiveClusters'] as core.List)
          .map<DynamicCluster>((value) => DynamicCluster.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dynamicWarmingClusters')) {
      dynamicWarmingClusters = (_json['dynamicWarmingClusters'] as core.List)
          .map<DynamicCluster>((value) => DynamicCluster.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('staticClusters')) {
      staticClusters = (_json['staticClusters'] as core.List)
          .map<StaticCluster>((value) => StaticCluster.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('versionInfo')) {
      versionInfo = _json['versionInfo'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dynamicActiveClusters != null)
          'dynamicActiveClusters':
              dynamicActiveClusters!.map((value) => value.toJson()).toList(),
        if (dynamicWarmingClusters != null)
          'dynamicWarmingClusters':
              dynamicWarmingClusters!.map((value) => value.toJson()).toList(),
        if (staticClusters != null)
          'staticClusters':
              staticClusters!.map((value) => value.toJson()).toList(),
        if (versionInfo != null) 'versionInfo': versionInfo!,
      };
}

/// Specifies the way to match a double value.
class DoubleMatcher {
  /// If specified, the input double value must be equal to the value specified
  /// here.
  core.double? exact;

  /// If specified, the input double value must be in the range specified here.
  ///
  /// Note: The range is using half-open interval semantics \[start, end).
  DoubleRange? range;

  DoubleMatcher();

  DoubleMatcher.fromJson(core.Map _json) {
    if (_json.containsKey('exact')) {
      exact = (_json['exact'] as core.num).toDouble();
    }
    if (_json.containsKey('range')) {
      range = DoubleRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exact != null) 'exact': exact!,
        if (range != null) 'range': range!.toJson(),
      };
}

/// Specifies the double start and end of the range using half-open interval
/// semantics \[start, end).
class DoubleRange {
  /// end of the range (exclusive)
  core.double? end;

  /// start of the range (inclusive)
  core.double? start;

  DoubleRange();

  DoubleRange.fromJson(core.Map _json) {
    if (_json.containsKey('end')) {
      end = (_json['end'] as core.num).toDouble();
    }
    if (_json.containsKey('start')) {
      start = (_json['start'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (end != null) 'end': end!,
        if (start != null) 'start': start!,
      };
}

/// Describes a dynamically loaded cluster via the CDS API.
class DynamicCluster {
  /// The cluster config.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? cluster;

  /// The timestamp when the Cluster was last updated.
  core.String? lastUpdated;

  /// This is the per-resource version information.
  ///
  /// This version is currently taken from the :ref:`version_info ` field at the
  /// time that the cluster was loaded. In the future, discrete per-cluster
  /// versions may be supported by the API.
  core.String? versionInfo;

  DynamicCluster();

  DynamicCluster.fromJson(core.Map _json) {
    if (_json.containsKey('cluster')) {
      cluster = (_json['cluster'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('lastUpdated')) {
      lastUpdated = _json['lastUpdated'] as core.String;
    }
    if (_json.containsKey('versionInfo')) {
      versionInfo = _json['versionInfo'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cluster != null) 'cluster': cluster!,
        if (lastUpdated != null) 'lastUpdated': lastUpdated!,
        if (versionInfo != null) 'versionInfo': versionInfo!,
      };
}

/// Describes a dynamically loaded listener via the LDS API.
///
/// \[#next-free-field: 6\]
class DynamicListener {
  /// The listener state for any active listener by this name.
  ///
  /// These are listeners that are available to service data plane traffic.
  DynamicListenerState? activeState;

  /// The listener state for any draining listener by this name.
  ///
  /// These are listeners that are currently undergoing draining in preparation
  /// to stop servicing data plane traffic. Note that if attempting to recreate
  /// an Envoy configuration from a configuration dump, the draining listeners
  /// should generally be discarded.
  DynamicListenerState? drainingState;

  /// Set if the last update failed, cleared after the next successful update.
  UpdateFailureState? errorState;

  /// The name or unique id of this listener, pulled from the
  /// DynamicListenerState config.
  core.String? name;

  /// The listener state for any warming listener by this name.
  ///
  /// These are listeners that are currently undergoing warming in preparation
  /// to service data plane traffic. Note that if attempting to recreate an
  /// Envoy configuration from a configuration dump, the warming listeners
  /// should generally be discarded.
  DynamicListenerState? warmingState;

  DynamicListener();

  DynamicListener.fromJson(core.Map _json) {
    if (_json.containsKey('activeState')) {
      activeState = DynamicListenerState.fromJson(
          _json['activeState'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('drainingState')) {
      drainingState = DynamicListenerState.fromJson(
          _json['drainingState'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('errorState')) {
      errorState = UpdateFailureState.fromJson(
          _json['errorState'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('warmingState')) {
      warmingState = DynamicListenerState.fromJson(
          _json['warmingState'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activeState != null) 'activeState': activeState!.toJson(),
        if (drainingState != null) 'drainingState': drainingState!.toJson(),
        if (errorState != null) 'errorState': errorState!.toJson(),
        if (name != null) 'name': name!,
        if (warmingState != null) 'warmingState': warmingState!.toJson(),
      };
}

class DynamicListenerState {
  /// The timestamp when the Listener was last successfully updated.
  core.String? lastUpdated;

  /// The listener config.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? listener;

  /// This is the per-resource version information.
  ///
  /// This version is currently taken from the :ref:`version_info ` field at the
  /// time that the listener was loaded. In the future, discrete per-listener
  /// versions may be supported by the API.
  core.String? versionInfo;

  DynamicListenerState();

  DynamicListenerState.fromJson(core.Map _json) {
    if (_json.containsKey('lastUpdated')) {
      lastUpdated = _json['lastUpdated'] as core.String;
    }
    if (_json.containsKey('listener')) {
      listener = (_json['listener'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('versionInfo')) {
      versionInfo = _json['versionInfo'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lastUpdated != null) 'lastUpdated': lastUpdated!,
        if (listener != null) 'listener': listener!,
        if (versionInfo != null) 'versionInfo': versionInfo!,
      };
}

class DynamicRouteConfig {
  /// The timestamp when the Route was last updated.
  core.String? lastUpdated;

  /// The route config.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? routeConfig;

  /// This is the per-resource version information.
  ///
  /// This version is currently taken from the :ref:`version_info ` field at the
  /// time that the route configuration was loaded.
  core.String? versionInfo;

  DynamicRouteConfig();

  DynamicRouteConfig.fromJson(core.Map _json) {
    if (_json.containsKey('lastUpdated')) {
      lastUpdated = _json['lastUpdated'] as core.String;
    }
    if (_json.containsKey('routeConfig')) {
      routeConfig =
          (_json['routeConfig'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('versionInfo')) {
      versionInfo = _json['versionInfo'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lastUpdated != null) 'lastUpdated': lastUpdated!,
        if (routeConfig != null) 'routeConfig': routeConfig!,
        if (versionInfo != null) 'versionInfo': versionInfo!,
      };
}

class DynamicScopedRouteConfigs {
  /// The timestamp when the scoped route config set was last updated.
  core.String? lastUpdated;

  /// The name assigned to the scoped route configurations.
  core.String? name;

  /// The scoped route configurations.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? scopedRouteConfigs;

  /// This is the per-resource version information.
  ///
  /// This version is currently taken from the :ref:`version_info ` field at the
  /// time that the scoped routes configuration was loaded.
  core.String? versionInfo;

  DynamicScopedRouteConfigs();

  DynamicScopedRouteConfigs.fromJson(core.Map _json) {
    if (_json.containsKey('lastUpdated')) {
      lastUpdated = _json['lastUpdated'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('scopedRouteConfigs')) {
      scopedRouteConfigs = (_json['scopedRouteConfigs'] as core.List)
          .map<core.Map<core.String, core.Object>>(
              (value) => (value as core.Map<core.String, core.dynamic>).map(
                    (key, item) => core.MapEntry(
                      key,
                      item as core.Object,
                    ),
                  ))
          .toList();
    }
    if (_json.containsKey('versionInfo')) {
      versionInfo = _json['versionInfo'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lastUpdated != null) 'lastUpdated': lastUpdated!,
        if (name != null) 'name': name!,
        if (scopedRouteConfigs != null)
          'scopedRouteConfigs': scopedRouteConfigs!,
        if (versionInfo != null) 'versionInfo': versionInfo!,
      };
}

/// Version and identification for an Envoy extension.
///
/// \[#next-free-field: 6\]
class Extension {
  /// Category of the extension.
  ///
  /// Extension category names use reverse DNS notation. For instance
  /// "envoy.filters.listener" for Envoy's built-in listener filters or
  /// "com.acme.filters.http" for HTTP filters from acme.com vendor. \[#comment:
  core.String? category;

  /// Indicates that the extension is present but was disabled via dynamic
  /// configuration.
  core.bool? disabled;

  /// This is the name of the Envoy filter as specified in the Envoy
  /// configuration, e.g. envoy.filters.http.router, com.acme.widget.
  core.String? name;

  /// \[#not-implemented-hide:\] Type descriptor of extension configuration
  /// proto.
  ///
  /// \[#comment:
  core.String? typeDescriptor;

  /// The version is a property of the extension and maintained independently of
  /// other extensions and the Envoy API.
  ///
  /// This field is not set when extension did not provide version information.
  BuildVersion? version;

  Extension();

  Extension.fromJson(core.Map _json) {
    if (_json.containsKey('category')) {
      category = _json['category'] as core.String;
    }
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('typeDescriptor')) {
      typeDescriptor = _json['typeDescriptor'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = BuildVersion.fromJson(
          _json['version'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (category != null) 'category': category!,
        if (disabled != null) 'disabled': disabled!,
        if (name != null) 'name': name!,
        if (typeDescriptor != null) 'typeDescriptor': typeDescriptor!,
        if (version != null) 'version': version!.toJson(),
      };
}

/// Google's `RE2 `_ regex engine.
///
/// The regex string must adhere to the documented `syntax `_. The engine is
/// designed to complete execution in linear time as well as limit the amount of
/// memory used. Envoy supports program size checking via runtime. The runtime
/// keys `re2.max_program_size.error_level` and
/// `re2.max_program_size.warn_level` can be set to integers as the maximum
/// program size or complexity that a compiled regex can have before an
/// exception is thrown or a warning is logged, respectively.
/// `re2.max_program_size.error_level` defaults to 100, and
/// `re2.max_program_size.warn_level` has no default if unset (will not
/// check/log a warning). Envoy emits two stats for tracking the program size of
/// regexes: the histogram `re2.program_size`, which records the program size,
/// and the counter `re2.exceeded_warn_level`, which is incremented each time
/// the program size exceeds the warn level threshold.
class GoogleRE2 {
  /// This field controls the RE2 "program size" which is a rough estimate of
  /// how complex a compiled regex is to evaluate.
  ///
  /// A regex that has a program size greater than the configured value will
  /// fail to compile. In this case, the configured max program size can be
  /// increased or the regex can be simplified. If not specified, the default is
  /// 100. This field is deprecated; regexp validation should be performed on
  /// the management server instead of being done by each individual client.
  core.int? maxProgramSize;

  GoogleRE2();

  GoogleRE2.fromJson(core.Map _json) {
    if (_json.containsKey('maxProgramSize')) {
      maxProgramSize = _json['maxProgramSize'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maxProgramSize != null) 'maxProgramSize': maxProgramSize!,
      };
}

class InlineScopedRouteConfigs {
  /// The timestamp when the scoped route config set was last updated.
  core.String? lastUpdated;

  /// The name assigned to the scoped route configurations.
  core.String? name;

  /// The scoped route configurations.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? scopedRouteConfigs;

  InlineScopedRouteConfigs();

  InlineScopedRouteConfigs.fromJson(core.Map _json) {
    if (_json.containsKey('lastUpdated')) {
      lastUpdated = _json['lastUpdated'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('scopedRouteConfigs')) {
      scopedRouteConfigs = (_json['scopedRouteConfigs'] as core.List)
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
        if (lastUpdated != null) 'lastUpdated': lastUpdated!,
        if (name != null) 'name': name!,
        if (scopedRouteConfigs != null)
          'scopedRouteConfigs': scopedRouteConfigs!,
      };
}

/// Specifies the way to match a list value.
class ListMatcher {
  /// If specified, at least one of the values in the list must match the value
  /// specified.
  ValueMatcher? oneOf;

  ListMatcher();

  ListMatcher.fromJson(core.Map _json) {
    if (_json.containsKey('oneOf')) {
      oneOf = ValueMatcher.fromJson(
          _json['oneOf'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (oneOf != null) 'oneOf': oneOf!.toJson(),
      };
}

/// Envoy's listener manager fills this message with all currently known
/// listeners.
///
/// Listener configuration information can be used to recreate an Envoy
/// configuration by populating all listeners as static listeners or by
/// returning them in a LDS response.
class ListenersConfigDump {
  /// State for any warming, active, or draining listeners.
  core.List<DynamicListener>? dynamicListeners;

  /// The statically loaded listener configs.
  core.List<StaticListener>? staticListeners;

  /// This is the :ref:`version_info ` in the last processed LDS discovery
  /// response.
  ///
  /// If there are only static bootstrap listeners, this field will be "".
  core.String? versionInfo;

  ListenersConfigDump();

  ListenersConfigDump.fromJson(core.Map _json) {
    if (_json.containsKey('dynamicListeners')) {
      dynamicListeners = (_json['dynamicListeners'] as core.List)
          .map<DynamicListener>((value) => DynamicListener.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('staticListeners')) {
      staticListeners = (_json['staticListeners'] as core.List)
          .map<StaticListener>((value) => StaticListener.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('versionInfo')) {
      versionInfo = _json['versionInfo'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dynamicListeners != null)
          'dynamicListeners':
              dynamicListeners!.map((value) => value.toJson()).toList(),
        if (staticListeners != null)
          'staticListeners':
              staticListeners!.map((value) => value.toJson()).toList(),
        if (versionInfo != null) 'versionInfo': versionInfo!,
      };
}

/// Identifies location of where either Envoy runs or where upstream hosts run.
class Locality {
  /// Region this :ref:`zone ` belongs to.
  core.String? region;

  /// When used for locality of upstream hosts, this field further splits zone
  /// into smaller chunks of sub-zones so they can be load balanced
  /// independently.
  core.String? subZone;

  /// Defines the local service zone where Envoy is running.
  ///
  /// Though optional, it should be set if discovery service routing is used and
  /// the discovery service exposes :ref:`zone data `, either in this message or
  /// via :option:`--service-zone`. The meaning of zone is context dependent,
  /// e.g. `Availability Zone (AZ) `_ on AWS, `Zone `_ on GCP, etc.
  core.String? zone;

  Locality();

  Locality.fromJson(core.Map _json) {
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('subZone')) {
      subZone = _json['subZone'] as core.String;
    }
    if (_json.containsKey('zone')) {
      zone = _json['zone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (region != null) 'region': region!,
        if (subZone != null) 'subZone': subZone!,
        if (zone != null) 'zone': zone!,
      };
}

/// Identifies a specific Envoy instance.
///
/// The node identifier is presented to the management server, which may use
/// this identifier to distinguish per Envoy configuration for serving.
/// \[#next-free-field: 12\]
class Node {
  /// This is motivated by informing a management server during canary which
  /// version of Envoy is being tested in a heterogeneous fleet.
  ///
  /// This will be set by Envoy in management server RPCs. This field is
  /// deprecated in favor of the user_agent_name and user_agent_version values.
  core.String? buildVersion;

  /// Client feature support list.
  ///
  /// These are well known features described in the Envoy API repository for a
  /// given major version of an API. Client features use reverse DNS naming
  /// scheme, for example `com.acme.feature`. See :ref:`the list of features `
  /// that xDS client may support.
  core.List<core.String>? clientFeatures;

  /// Defines the local service cluster name where Envoy is running.
  ///
  /// Though optional, it should be set if any of the following features are
  /// used: :ref:`statsd `, :ref:`health check cluster verification `,
  /// :ref:`runtime override directory `, :ref:`user agent addition `,
  /// :ref:`HTTP global rate limiting `, :ref:`CDS `, and :ref:`HTTP tracing `,
  /// either in this message or via :option:`--service-cluster`.
  core.String? cluster;

  /// List of extensions and their versions supported by the node.
  core.List<Extension>? extensions;

  /// An opaque node identifier for the Envoy node.
  ///
  /// This also provides the local service node name. It should be set if any of
  /// the following features are used: :ref:`statsd `, :ref:`CDS `, and
  /// :ref:`HTTP tracing `, either in this message or via
  /// :option:`--service-node`.
  core.String? id;

  /// Known listening ports on the node as a generic hint to the management
  /// server for filtering :ref:`listeners ` to be returned.
  ///
  /// For example, if there is a listener bound to port 80, the list can
  /// optionally contain the SocketAddress `(0.0.0.0,80)`. The field is optional
  /// and just a hint.
  core.List<Address>? listeningAddresses;

  /// Locality specifying where the Envoy instance is running.
  Locality? locality;

  /// Opaque metadata extending the node identifier.
  ///
  /// Envoy will pass this directly to the management server.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  /// Structured version of the entity requesting config.
  BuildVersion? userAgentBuildVersion;

  /// Free-form string that identifies the entity requesting config.
  ///
  /// E.g. "envoy" or "grpc"
  core.String? userAgentName;

  /// Free-form string that identifies the version of the entity requesting
  /// config.
  ///
  /// E.g. "1.12.2" or "abcd1234", or "SpecialEnvoyBuild"
  core.String? userAgentVersion;

  Node();

  Node.fromJson(core.Map _json) {
    if (_json.containsKey('buildVersion')) {
      buildVersion = _json['buildVersion'] as core.String;
    }
    if (_json.containsKey('clientFeatures')) {
      clientFeatures = (_json['clientFeatures'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('cluster')) {
      cluster = _json['cluster'] as core.String;
    }
    if (_json.containsKey('extensions')) {
      extensions = (_json['extensions'] as core.List)
          .map<Extension>((value) =>
              Extension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('listeningAddresses')) {
      listeningAddresses = (_json['listeningAddresses'] as core.List)
          .map<Address>((value) =>
              Address.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('locality')) {
      locality = Locality.fromJson(
          _json['locality'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('userAgentBuildVersion')) {
      userAgentBuildVersion = BuildVersion.fromJson(
          _json['userAgentBuildVersion']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('userAgentName')) {
      userAgentName = _json['userAgentName'] as core.String;
    }
    if (_json.containsKey('userAgentVersion')) {
      userAgentVersion = _json['userAgentVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buildVersion != null) 'buildVersion': buildVersion!,
        if (clientFeatures != null) 'clientFeatures': clientFeatures!,
        if (cluster != null) 'cluster': cluster!,
        if (extensions != null)
          'extensions': extensions!.map((value) => value.toJson()).toList(),
        if (id != null) 'id': id!,
        if (listeningAddresses != null)
          'listeningAddresses':
              listeningAddresses!.map((value) => value.toJson()).toList(),
        if (locality != null) 'locality': locality!.toJson(),
        if (metadata != null) 'metadata': metadata!,
        if (userAgentBuildVersion != null)
          'userAgentBuildVersion': userAgentBuildVersion!.toJson(),
        if (userAgentName != null) 'userAgentName': userAgentName!,
        if (userAgentVersion != null) 'userAgentVersion': userAgentVersion!,
      };
}

/// Specifies the way to match a Node.
///
/// The match follows AND semantics.
class NodeMatcher {
  /// Specifies match criteria on the node id.
  StringMatcher? nodeId;

  /// Specifies match criteria on the node metadata.
  core.List<StructMatcher>? nodeMetadatas;

  NodeMatcher();

  NodeMatcher.fromJson(core.Map _json) {
    if (_json.containsKey('nodeId')) {
      nodeId = StringMatcher.fromJson(
          _json['nodeId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nodeMetadatas')) {
      nodeMetadatas = (_json['nodeMetadatas'] as core.List)
          .map<StructMatcher>((value) => StructMatcher.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nodeId != null) 'nodeId': nodeId!.toJson(),
        if (nodeMetadatas != null)
          'nodeMetadatas':
              nodeMetadatas!.map((value) => value.toJson()).toList(),
      };
}

/// NullMatch is an empty message to specify a null value.
class NullMatch {
  NullMatch();

  NullMatch.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Specifies the segment in a path to retrieve value from Struct.
class PathSegment {
  /// If specified, use the key to retrieve the value in a Struct.
  core.String? key;

  PathSegment();

  PathSegment.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
      };
}

/// Detailed config (per xDS) with status.
///
/// \[#next-free-field: 6\]
class PerXdsConfig {
  ClustersConfigDump? clusterConfig;
  ListenersConfigDump? listenerConfig;
  RoutesConfigDump? routeConfig;
  ScopedRoutesConfigDump? scopedRouteConfig;

  ///
  /// Possible string values are:
  /// - "UNKNOWN" : Status info is not available/unknown.
  /// - "SYNCED" : Management server has sent the config to client and received
  /// ACK.
  /// - "NOT_SENT" : Config is not sent.
  /// - "STALE" : Management server has sent the config to client but hasn’t
  /// received ACK/NACK.
  /// - "ERROR" : Management server has sent the config to client but received
  /// NACK.
  core.String? status;

  PerXdsConfig();

  PerXdsConfig.fromJson(core.Map _json) {
    if (_json.containsKey('clusterConfig')) {
      clusterConfig = ClustersConfigDump.fromJson(
          _json['clusterConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('listenerConfig')) {
      listenerConfig = ListenersConfigDump.fromJson(
          _json['listenerConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('routeConfig')) {
      routeConfig = RoutesConfigDump.fromJson(
          _json['routeConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('scopedRouteConfig')) {
      scopedRouteConfig = ScopedRoutesConfigDump.fromJson(
          _json['scopedRouteConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusterConfig != null) 'clusterConfig': clusterConfig!.toJson(),
        if (listenerConfig != null) 'listenerConfig': listenerConfig!.toJson(),
        if (routeConfig != null) 'routeConfig': routeConfig!.toJson(),
        if (scopedRouteConfig != null)
          'scopedRouteConfig': scopedRouteConfig!.toJson(),
        if (status != null) 'status': status!,
      };
}

class Pipe {
  /// The mode for the Pipe.
  ///
  /// Not applicable for abstract sockets.
  core.int? mode;

  /// Unix Domain Socket path.
  ///
  /// On Linux, paths starting with '@' will use the abstract namespace. The
  /// starting '@' is replaced by a null byte by Envoy. Paths starting with '@'
  /// will result in an error in environments other than Linux.
  core.String? path;

  Pipe();

  Pipe.fromJson(core.Map _json) {
    if (_json.containsKey('mode')) {
      mode = _json['mode'] as core.int;
    }
    if (_json.containsKey('path')) {
      path = _json['path'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mode != null) 'mode': mode!,
        if (path != null) 'path': path!,
      };
}

/// A regex matcher designed for safety when used with untrusted input.
class RegexMatcher {
  /// Google's RE2 regex engine.
  GoogleRE2? googleRe2;

  /// The regex match string.
  ///
  /// The string must be supported by the configured engine.
  core.String? regex;

  RegexMatcher();

  RegexMatcher.fromJson(core.Map _json) {
    if (_json.containsKey('googleRe2')) {
      googleRe2 = GoogleRE2.fromJson(
          _json['googleRe2'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('regex')) {
      regex = _json['regex'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (googleRe2 != null) 'googleRe2': googleRe2!.toJson(),
        if (regex != null) 'regex': regex!,
      };
}

/// Envoy's RDS implementation fills this message with all currently loaded
/// routes, as described by their RouteConfiguration objects.
///
/// Static routes that are either defined in the bootstrap configuration or
/// defined inline while configuring listeners are separated from those
/// configured dynamically via RDS. Route configuration information can be used
/// to recreate an Envoy configuration by populating all routes as static routes
/// or by returning them in RDS responses.
class RoutesConfigDump {
  /// The dynamically loaded route configs.
  core.List<DynamicRouteConfig>? dynamicRouteConfigs;

  /// The statically loaded route configs.
  core.List<StaticRouteConfig>? staticRouteConfigs;

  RoutesConfigDump();

  RoutesConfigDump.fromJson(core.Map _json) {
    if (_json.containsKey('dynamicRouteConfigs')) {
      dynamicRouteConfigs = (_json['dynamicRouteConfigs'] as core.List)
          .map<DynamicRouteConfig>((value) => DynamicRouteConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('staticRouteConfigs')) {
      staticRouteConfigs = (_json['staticRouteConfigs'] as core.List)
          .map<StaticRouteConfig>((value) => StaticRouteConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dynamicRouteConfigs != null)
          'dynamicRouteConfigs':
              dynamicRouteConfigs!.map((value) => value.toJson()).toList(),
        if (staticRouteConfigs != null)
          'staticRouteConfigs':
              staticRouteConfigs!.map((value) => value.toJson()).toList(),
      };
}

/// Envoy's scoped RDS implementation fills this message with all currently
/// loaded route configuration scopes (defined via ScopedRouteConfigurationsSet
/// protos).
///
/// This message lists both the scopes defined inline with the higher order
/// object (i.e., the HttpConnectionManager) and the dynamically obtained scopes
/// via the SRDS API.
class ScopedRoutesConfigDump {
  /// The dynamically loaded scoped route configs.
  core.List<DynamicScopedRouteConfigs>? dynamicScopedRouteConfigs;

  /// The statically loaded scoped route configs.
  core.List<InlineScopedRouteConfigs>? inlineScopedRouteConfigs;

  ScopedRoutesConfigDump();

  ScopedRoutesConfigDump.fromJson(core.Map _json) {
    if (_json.containsKey('dynamicScopedRouteConfigs')) {
      dynamicScopedRouteConfigs =
          (_json['dynamicScopedRouteConfigs'] as core.List)
              .map<DynamicScopedRouteConfigs>((value) =>
                  DynamicScopedRouteConfigs.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('inlineScopedRouteConfigs')) {
      inlineScopedRouteConfigs =
          (_json['inlineScopedRouteConfigs'] as core.List)
              .map<InlineScopedRouteConfigs>((value) =>
                  InlineScopedRouteConfigs.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dynamicScopedRouteConfigs != null)
          'dynamicScopedRouteConfigs': dynamicScopedRouteConfigs!
              .map((value) => value.toJson())
              .toList(),
        if (inlineScopedRouteConfigs != null)
          'inlineScopedRouteConfigs':
              inlineScopedRouteConfigs!.map((value) => value.toJson()).toList(),
      };
}

/// Envoy uses SemVer (https://semver.org/).
///
/// Major/minor versions indicate expected behaviors and APIs, the patch version
/// field is used only for security fixes and can be generally ignored.
class SemanticVersion {
  core.int? majorNumber;
  core.int? minorNumber;
  core.int? patch;

  SemanticVersion();

  SemanticVersion.fromJson(core.Map _json) {
    if (_json.containsKey('majorNumber')) {
      majorNumber = _json['majorNumber'] as core.int;
    }
    if (_json.containsKey('minorNumber')) {
      minorNumber = _json['minorNumber'] as core.int;
    }
    if (_json.containsKey('patch')) {
      patch = _json['patch'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (majorNumber != null) 'majorNumber': majorNumber!,
        if (minorNumber != null) 'minorNumber': minorNumber!,
        if (patch != null) 'patch': patch!,
      };
}

/// \[#next-free-field: 7\]
class SocketAddress {
  /// The address for this socket.
  ///
  /// :ref:`Listeners ` will bind to the address. An empty address is not
  /// allowed. Specify ``0.0.0.0`` or ``::`` to bind to any address.
  /// \[#comment:TODO(zuercher) reinstate when implemented: It is possible to
  /// distinguish a Listener address via the prefix/suffix matching in
  /// :ref:`FilterChainMatch `.\] When used within an upstream :ref:`BindConfig
  /// `, the address controls the source address of outbound connections. For
  /// :ref:`clusters `, the cluster type determines whether the address must be
  /// an IP (*STATIC* or *EDS* clusters) or a hostname resolved by DNS
  /// (*STRICT_DNS* or *LOGICAL_DNS* clusters). Address resolution can be
  /// customized via :ref:`resolver_name `.
  core.String? address;

  /// When binding to an IPv6 address above, this enables `IPv4 compatibility
  /// `_.
  ///
  /// Binding to ``::`` will allow both IPv4 and IPv6 connections, with peer
  /// IPv4 addresses mapped into IPv6 space as ``::FFFF:``.
  core.bool? ipv4Compat;

  /// This is only valid if :ref:`resolver_name ` is specified below and the
  /// named resolver is capable of named port resolution.
  core.String? namedPort;
  core.int? portValue;

  ///
  /// Possible string values are:
  /// - "TCP"
  /// - "UDP"
  core.String? protocol;

  /// The name of the custom resolver.
  ///
  /// This must have been registered with Envoy. If this is empty, a context
  /// dependent default applies. If the address is a concrete IP address, no
  /// resolution will occur. If address is a hostname this should be set for
  /// resolution other than DNS. Specifying a custom resolver with *STRICT_DNS*
  /// or *LOGICAL_DNS* will generate an error at runtime.
  core.String? resolverName;

  SocketAddress();

  SocketAddress.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = _json['address'] as core.String;
    }
    if (_json.containsKey('ipv4Compat')) {
      ipv4Compat = _json['ipv4Compat'] as core.bool;
    }
    if (_json.containsKey('namedPort')) {
      namedPort = _json['namedPort'] as core.String;
    }
    if (_json.containsKey('portValue')) {
      portValue = _json['portValue'] as core.int;
    }
    if (_json.containsKey('protocol')) {
      protocol = _json['protocol'] as core.String;
    }
    if (_json.containsKey('resolverName')) {
      resolverName = _json['resolverName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!,
        if (ipv4Compat != null) 'ipv4Compat': ipv4Compat!,
        if (namedPort != null) 'namedPort': namedPort!,
        if (portValue != null) 'portValue': portValue!,
        if (protocol != null) 'protocol': protocol!,
        if (resolverName != null) 'resolverName': resolverName!,
      };
}

/// Describes a statically loaded cluster.
class StaticCluster {
  /// The cluster config.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? cluster;

  /// The timestamp when the Cluster was last updated.
  core.String? lastUpdated;

  StaticCluster();

  StaticCluster.fromJson(core.Map _json) {
    if (_json.containsKey('cluster')) {
      cluster = (_json['cluster'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('lastUpdated')) {
      lastUpdated = _json['lastUpdated'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cluster != null) 'cluster': cluster!,
        if (lastUpdated != null) 'lastUpdated': lastUpdated!,
      };
}

/// Describes a statically loaded listener.
class StaticListener {
  /// The timestamp when the Listener was last successfully updated.
  core.String? lastUpdated;

  /// The listener config.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? listener;

  StaticListener();

  StaticListener.fromJson(core.Map _json) {
    if (_json.containsKey('lastUpdated')) {
      lastUpdated = _json['lastUpdated'] as core.String;
    }
    if (_json.containsKey('listener')) {
      listener = (_json['listener'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lastUpdated != null) 'lastUpdated': lastUpdated!,
        if (listener != null) 'listener': listener!,
      };
}

class StaticRouteConfig {
  /// The timestamp when the Route was last updated.
  core.String? lastUpdated;

  /// The route config.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? routeConfig;

  StaticRouteConfig();

  StaticRouteConfig.fromJson(core.Map _json) {
    if (_json.containsKey('lastUpdated')) {
      lastUpdated = _json['lastUpdated'] as core.String;
    }
    if (_json.containsKey('routeConfig')) {
      routeConfig =
          (_json['routeConfig'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lastUpdated != null) 'lastUpdated': lastUpdated!,
        if (routeConfig != null) 'routeConfig': routeConfig!,
      };
}

/// Specifies the way to match a string.
///
/// \[#next-free-field: 7\]
class StringMatcher {
  /// The input string must match exactly the string specified here.
  ///
  /// Examples: * *abc* only matches the value *abc*.
  core.String? exact;

  /// If true, indicates the exact/prefix/suffix matching should be case
  /// insensitive.
  ///
  /// This has no effect for the safe_regex match. For example, the matcher
  /// *data* will match both input string *Data* and *data* if set to true.
  core.bool? ignoreCase;

  /// The input string must have the prefix specified here.
  ///
  /// Note: empty prefix is not allowed, please use regex instead. Examples: *
  /// *abc* matches the value *abc.xyz*
  core.String? prefix;

  /// The input string must match the regular expression specified here.
  ///
  /// The regex grammar is defined `here `_. Examples: * The regex ``\d{3}``
  /// matches the value *123* * The regex ``\d{3}`` does not match the value
  /// *1234* * The regex ``\d{3}`` does not match the value *123.456* ..
  /// attention:: This field has been deprecated in favor of `safe_regex` as it
  /// is not safe for use with untrusted input in all cases.
  core.String? regex;

  /// The input string must match the regular expression specified here.
  RegexMatcher? safeRegex;

  /// The input string must have the suffix specified here.
  ///
  /// Note: empty prefix is not allowed, please use regex instead. Examples: *
  /// *abc* matches the value *xyz.abc*
  core.String? suffix;

  StringMatcher();

  StringMatcher.fromJson(core.Map _json) {
    if (_json.containsKey('exact')) {
      exact = _json['exact'] as core.String;
    }
    if (_json.containsKey('ignoreCase')) {
      ignoreCase = _json['ignoreCase'] as core.bool;
    }
    if (_json.containsKey('prefix')) {
      prefix = _json['prefix'] as core.String;
    }
    if (_json.containsKey('regex')) {
      regex = _json['regex'] as core.String;
    }
    if (_json.containsKey('safeRegex')) {
      safeRegex = RegexMatcher.fromJson(
          _json['safeRegex'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suffix')) {
      suffix = _json['suffix'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exact != null) 'exact': exact!,
        if (ignoreCase != null) 'ignoreCase': ignoreCase!,
        if (prefix != null) 'prefix': prefix!,
        if (regex != null) 'regex': regex!,
        if (safeRegex != null) 'safeRegex': safeRegex!.toJson(),
        if (suffix != null) 'suffix': suffix!,
      };
}

/// StructMatcher provides a general interface to check if a given value is
/// matched in google.protobuf.Struct.
///
/// It uses `path` to retrieve the value from the struct and then check if it's
/// matched to the specified value. For example, for the following Struct: ..
/// code-block:: yaml fields: a: struct_value: fields: b: struct_value: fields:
/// c: string_value: pro t: list_value: values: - string_value: m -
/// string_value: n The following MetadataMatcher is matched as the path \[a, b,
/// c\] will retrieve a string value "pro" from the Metadata which is matched to
/// the specified prefix match. .. code-block:: yaml path: - key: a - key: b -
/// key: c value: string_match: prefix: pr The following StructMatcher is
/// matched as the code will match one of the string values in the list at the
/// path \[a, t\]. .. code-block:: yaml path: - key: a - key: t value:
/// list_match: one_of: string_match: exact: m An example use of StructMatcher
/// is to match metadata in envoy.v*.core.Node.
class StructMatcher {
  /// The path to retrieve the Value from the Struct.
  core.List<PathSegment>? path;

  /// The StructMatcher is matched if the value retrieved by path is matched to
  /// this value.
  ValueMatcher? value;

  StructMatcher();

  StructMatcher.fromJson(core.Map _json) {
    if (_json.containsKey('path')) {
      path = (_json['path'] as core.List)
          .map<PathSegment>((value) => PathSegment.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('value')) {
      value = ValueMatcher.fromJson(
          _json['value'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (path != null) 'path': path!.map((value) => value.toJson()).toList(),
        if (value != null) 'value': value!.toJson(),
      };
}

class UpdateFailureState {
  /// Details about the last failed update attempt.
  core.String? details;

  /// What the component configuration would have been if the update had
  /// succeeded.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? failedConfiguration;

  /// Time of the latest failed update attempt.
  core.String? lastUpdateAttempt;

  UpdateFailureState();

  UpdateFailureState.fromJson(core.Map _json) {
    if (_json.containsKey('details')) {
      details = _json['details'] as core.String;
    }
    if (_json.containsKey('failedConfiguration')) {
      failedConfiguration =
          (_json['failedConfiguration'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('lastUpdateAttempt')) {
      lastUpdateAttempt = _json['lastUpdateAttempt'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (details != null) 'details': details!,
        if (failedConfiguration != null)
          'failedConfiguration': failedConfiguration!,
        if (lastUpdateAttempt != null) 'lastUpdateAttempt': lastUpdateAttempt!,
      };
}

/// Specifies the way to match a ProtobufWkt::Value.
///
/// Primitive values and ListValue are supported. StructValue is not supported
/// and is always not matched. \[#next-free-field: 7\]
class ValueMatcher {
  /// If specified, a match occurs if and only if the target value is a bool
  /// value and is equal to this field.
  core.bool? boolMatch;

  /// If specified, a match occurs if and only if the target value is a double
  /// value and is matched to this field.
  DoubleMatcher? doubleMatch;

  /// If specified, a match occurs if and only if the target value is a list
  /// value and is matched to this field.
  ListMatcher? listMatch;

  /// If specified, a match occurs if and only if the target value is a
  /// NullValue.
  NullMatch? nullMatch;

  /// If specified, value match will be performed based on whether the path is
  /// referring to a valid primitive value in the metadata.
  ///
  /// If the path is referring to a non-primitive value, the result is always
  /// not matched.
  core.bool? presentMatch;

  /// If specified, a match occurs if and only if the target value is a string
  /// value and is matched to this field.
  StringMatcher? stringMatch;

  ValueMatcher();

  ValueMatcher.fromJson(core.Map _json) {
    if (_json.containsKey('boolMatch')) {
      boolMatch = _json['boolMatch'] as core.bool;
    }
    if (_json.containsKey('doubleMatch')) {
      doubleMatch = DoubleMatcher.fromJson(
          _json['doubleMatch'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('listMatch')) {
      listMatch = ListMatcher.fromJson(
          _json['listMatch'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nullMatch')) {
      nullMatch = NullMatch.fromJson(
          _json['nullMatch'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('presentMatch')) {
      presentMatch = _json['presentMatch'] as core.bool;
    }
    if (_json.containsKey('stringMatch')) {
      stringMatch = StringMatcher.fromJson(
          _json['stringMatch'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (boolMatch != null) 'boolMatch': boolMatch!,
        if (doubleMatch != null) 'doubleMatch': doubleMatch!.toJson(),
        if (listMatch != null) 'listMatch': listMatch!.toJson(),
        if (nullMatch != null) 'nullMatch': nullMatch!.toJson(),
        if (presentMatch != null) 'presentMatch': presentMatch!,
        if (stringMatch != null) 'stringMatch': stringMatch!.toJson(),
      };
}
