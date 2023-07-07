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

/// Semantic Tile API - v1
///
/// Serves vector tiles containing geospatial data.
///
/// For more information, see
/// <https://developers.google.com/maps/contact-sales/>
///
/// Create an instance of [SemanticTileApi] to access these resources:
///
/// - [FeaturetilesResource]
/// - [TerraintilesResource]
library vectortile.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Serves vector tiles containing geospatial data.
class SemanticTileApi {
  final commons.ApiRequester _requester;

  FeaturetilesResource get featuretiles => FeaturetilesResource(_requester);
  TerraintilesResource get terraintiles => TerraintilesResource(_requester);

  SemanticTileApi(http.Client client,
      {core.String rootUrl = 'https://vectortile.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class FeaturetilesResource {
  final commons.ApiRequester _requester;

  FeaturetilesResource(commons.ApiRequester client) : _requester = client;

  /// Gets a feature tile by its tile resource name.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the tile. The tile resource name is
  /// prefixed by its collection ID `tiles/` followed by the resource ID, which
  /// encodes the tile's global x and y coordinates and zoom level as `@,,z`.
  /// For example, `tiles/@1,2,3z`.
  /// Value must have pattern `^featuretiles/\[^/\]+$`.
  ///
  /// [alwaysIncludeBuildingFootprints] - Flag indicating whether the returned
  /// tile will always contain 2.5D footprints for structures. If
  /// enabled_modeled_volumes is set, this will mean that structures will have
  /// both their 3D models and 2.5D footprints returned.
  ///
  /// [clientInfo_apiClient] - API client name and version. For example, the SDK
  /// calling the API. The exact format is up to the client.
  ///
  /// [clientInfo_applicationId] - Application ID, such as the package name on
  /// Android and the bundle identifier on iOS platforms.
  ///
  /// [clientInfo_applicationVersion] - Application version number, such as
  /// "1.2.3". The exact format is application-dependent.
  ///
  /// [clientInfo_deviceModel] - Device model as reported by the device. The
  /// exact format is platform-dependent.
  ///
  /// [clientInfo_operatingSystem] - Operating system name and version as
  /// reported by the OS. For example, "Mac OS X 10.10.4". The exact format is
  /// platform-dependent.
  ///
  /// [clientInfo_platform] - Platform where the application is running.
  /// Possible string values are:
  /// - "PLATFORM_UNSPECIFIED" : Unspecified or unknown OS.
  /// - "EDITOR" : Development environment.
  /// - "MAC_OS" : macOS.
  /// - "WINDOWS" : Windows.
  /// - "LINUX" : Linux
  /// - "ANDROID" : Android
  /// - "IOS" : iOS
  /// - "WEB_GL" : WebGL.
  ///
  /// [clientInfo_userId] - Required. A client-generated user ID. The ID should
  /// be generated and persisted during the first user session or whenever a
  /// pre-existing ID is not found. The exact format is up to the client. This
  /// must be non-empty in a GetFeatureTileRequest (whether via the header or
  /// GetFeatureTileRequest.client_info).
  ///
  /// [clientTileVersionId] - Optional version id identifying the tile that is
  /// already in the client's cache. This field should be populated with the
  /// most recent version_id value returned by the API for the requested tile.
  /// If the version id is empty the server always returns a newly rendered
  /// tile. If it is provided the server checks if the tile contents would be
  /// identical to one that's already on the client, and if so, returns a
  /// stripped-down response tile with STATUS_OK_DATA_UNCHANGED instead.
  ///
  /// [enableDetailedHighwayTypes] - Flag indicating whether detailed highway
  /// types should be returned. If this is set, the CONTROLLED_ACCESS_HIGHWAY
  /// type may be returned. If not, then these highways will have the generic
  /// HIGHWAY type. This exists for backwards compatibility reasons.
  ///
  /// [enableFeatureNames] - Flag indicating whether human-readable names should
  /// be returned for features. If this is set, the display_name field on the
  /// feature will be filled out.
  ///
  /// [enableModeledVolumes] - Flag indicating whether 3D building models should
  /// be enabled. If this is set structures will be returned as 3D modeled
  /// volumes rather than 2.5D extruded areas where possible.
  ///
  /// [enablePoliticalFeatures] - Flag indicating whether political features
  /// should be returned.
  ///
  /// [enablePrivateRoads] - Flag indicating whether the returned tile will
  /// contain road features that are marked private. Private roads are indicated
  /// by the Feature.segment_info.road_info.is_private field.
  ///
  /// [enableUnclippedBuildings] - Flag indicating whether unclipped buildings
  /// should be returned. If this is set, building render ops will extend beyond
  /// the tile boundary. Buildings will only be returned on the tile that
  /// contains their centroid.
  ///
  /// [languageCode] - Required. The BCP-47 language code corresponding to the
  /// language in which the name was requested, such as "en-US" or "sr-Latn".
  /// For more information, see
  /// http://www.unicode.org/reports/tr35/#Unicode_locale_identifier.
  ///
  /// [regionCode] - Required. The Unicode country/region code (CLDR) of the
  /// location from which the request is coming from, such as "US" and "419".
  /// For more information, see
  /// http://www.unicode.org/reports/tr35/#unicode_region_subtag.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [FeatureTile].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<FeatureTile> get(
    core.String name, {
    core.bool? alwaysIncludeBuildingFootprints,
    core.String? clientInfo_apiClient,
    core.String? clientInfo_applicationId,
    core.String? clientInfo_applicationVersion,
    core.String? clientInfo_deviceModel,
    core.String? clientInfo_operatingSystem,
    core.String? clientInfo_platform,
    core.String? clientInfo_userId,
    core.String? clientTileVersionId,
    core.bool? enableDetailedHighwayTypes,
    core.bool? enableFeatureNames,
    core.bool? enableModeledVolumes,
    core.bool? enablePoliticalFeatures,
    core.bool? enablePrivateRoads,
    core.bool? enableUnclippedBuildings,
    core.String? languageCode,
    core.String? regionCode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (alwaysIncludeBuildingFootprints != null)
        'alwaysIncludeBuildingFootprints': [
          '${alwaysIncludeBuildingFootprints}'
        ],
      if (clientInfo_apiClient != null)
        'clientInfo.apiClient': [clientInfo_apiClient],
      if (clientInfo_applicationId != null)
        'clientInfo.applicationId': [clientInfo_applicationId],
      if (clientInfo_applicationVersion != null)
        'clientInfo.applicationVersion': [clientInfo_applicationVersion],
      if (clientInfo_deviceModel != null)
        'clientInfo.deviceModel': [clientInfo_deviceModel],
      if (clientInfo_operatingSystem != null)
        'clientInfo.operatingSystem': [clientInfo_operatingSystem],
      if (clientInfo_platform != null)
        'clientInfo.platform': [clientInfo_platform],
      if (clientInfo_userId != null) 'clientInfo.userId': [clientInfo_userId],
      if (clientTileVersionId != null)
        'clientTileVersionId': [clientTileVersionId],
      if (enableDetailedHighwayTypes != null)
        'enableDetailedHighwayTypes': ['${enableDetailedHighwayTypes}'],
      if (enableFeatureNames != null)
        'enableFeatureNames': ['${enableFeatureNames}'],
      if (enableModeledVolumes != null)
        'enableModeledVolumes': ['${enableModeledVolumes}'],
      if (enablePoliticalFeatures != null)
        'enablePoliticalFeatures': ['${enablePoliticalFeatures}'],
      if (enablePrivateRoads != null)
        'enablePrivateRoads': ['${enablePrivateRoads}'],
      if (enableUnclippedBuildings != null)
        'enableUnclippedBuildings': ['${enableUnclippedBuildings}'],
      if (languageCode != null) 'languageCode': [languageCode],
      if (regionCode != null) 'regionCode': [regionCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return FeatureTile.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class TerraintilesResource {
  final commons.ApiRequester _requester;

  TerraintilesResource(commons.ApiRequester client) : _requester = client;

  /// Gets a terrain tile by its tile resource name.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the tile. The tile resource name is
  /// prefixed by its collection ID `terraintiles/` followed by the resource ID,
  /// which encodes the tile's global x and y coordinates and zoom level as
  /// `@,,z`. For example, `terraintiles/@1,2,3z`.
  /// Value must have pattern `^terraintiles/\[^/\]+$`.
  ///
  /// [altitudePrecisionCentimeters] - The precision of terrain altitudes in
  /// centimeters. Possible values: between 1 (cm level precision) and 1,000,000
  /// (10-kilometer level precision).
  ///
  /// [clientInfo_apiClient] - API client name and version. For example, the SDK
  /// calling the API. The exact format is up to the client.
  ///
  /// [clientInfo_applicationId] - Application ID, such as the package name on
  /// Android and the bundle identifier on iOS platforms.
  ///
  /// [clientInfo_applicationVersion] - Application version number, such as
  /// "1.2.3". The exact format is application-dependent.
  ///
  /// [clientInfo_deviceModel] - Device model as reported by the device. The
  /// exact format is platform-dependent.
  ///
  /// [clientInfo_operatingSystem] - Operating system name and version as
  /// reported by the OS. For example, "Mac OS X 10.10.4". The exact format is
  /// platform-dependent.
  ///
  /// [clientInfo_platform] - Platform where the application is running.
  /// Possible string values are:
  /// - "PLATFORM_UNSPECIFIED" : Unspecified or unknown OS.
  /// - "EDITOR" : Development environment.
  /// - "MAC_OS" : macOS.
  /// - "WINDOWS" : Windows.
  /// - "LINUX" : Linux
  /// - "ANDROID" : Android
  /// - "IOS" : iOS
  /// - "WEB_GL" : WebGL.
  ///
  /// [clientInfo_userId] - Required. A client-generated user ID. The ID should
  /// be generated and persisted during the first user session or whenever a
  /// pre-existing ID is not found. The exact format is up to the client. This
  /// must be non-empty in a GetFeatureTileRequest (whether via the header or
  /// GetFeatureTileRequest.client_info).
  ///
  /// [maxElevationResolutionCells] - The maximum allowed resolution for the
  /// returned elevation heightmap. Possible values: between 1 and 1024 (and not
  /// less than min_elevation_resolution_cells). Over-sized heightmaps will be
  /// non-uniformly down-sampled such that each edge is no longer than this
  /// value. Non-uniformity is chosen to maximise the amount of preserved data.
  /// For example: Original resolution: 100px (width) * 30px (height)
  /// max_elevation_resolution: 30 New resolution: 30px (width) * 30px (height)
  ///
  /// [minElevationResolutionCells] - The minimum allowed resolution for the
  /// returned elevation heightmap. Possible values: between 0 and 1024 (and not
  /// more than max_elevation_resolution_cells). Zero is supported for backward
  /// compatibility. Under-sized heightmaps will be non-uniformly up-sampled
  /// such that each edge is no shorter than this value. Non-uniformity is
  /// chosen to maximise the amount of preserved data. For example: Original
  /// resolution: 30px (width) * 10px (height) min_elevation_resolution: 30 New
  /// resolution: 30px (width) * 30px (height)
  ///
  /// [terrainFormats] - Terrain formats that the client understands.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TerrainTile].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TerrainTile> get(
    core.String name, {
    core.int? altitudePrecisionCentimeters,
    core.String? clientInfo_apiClient,
    core.String? clientInfo_applicationId,
    core.String? clientInfo_applicationVersion,
    core.String? clientInfo_deviceModel,
    core.String? clientInfo_operatingSystem,
    core.String? clientInfo_platform,
    core.String? clientInfo_userId,
    core.int? maxElevationResolutionCells,
    core.int? minElevationResolutionCells,
    core.List<core.String>? terrainFormats,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (altitudePrecisionCentimeters != null)
        'altitudePrecisionCentimeters': ['${altitudePrecisionCentimeters}'],
      if (clientInfo_apiClient != null)
        'clientInfo.apiClient': [clientInfo_apiClient],
      if (clientInfo_applicationId != null)
        'clientInfo.applicationId': [clientInfo_applicationId],
      if (clientInfo_applicationVersion != null)
        'clientInfo.applicationVersion': [clientInfo_applicationVersion],
      if (clientInfo_deviceModel != null)
        'clientInfo.deviceModel': [clientInfo_deviceModel],
      if (clientInfo_operatingSystem != null)
        'clientInfo.operatingSystem': [clientInfo_operatingSystem],
      if (clientInfo_platform != null)
        'clientInfo.platform': [clientInfo_platform],
      if (clientInfo_userId != null) 'clientInfo.userId': [clientInfo_userId],
      if (maxElevationResolutionCells != null)
        'maxElevationResolutionCells': ['${maxElevationResolutionCells}'],
      if (minElevationResolutionCells != null)
        'minElevationResolutionCells': ['${minElevationResolutionCells}'],
      if (terrainFormats != null) 'terrainFormats': terrainFormats,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TerrainTile.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Represents an area.
///
/// Used to represent regions such as water, parks, etc. Next ID: 10
class Area {
  /// The z-order of this geometry when rendered on a flat basemap.
  ///
  /// Geometry with a lower z-order should be rendered beneath geometry with a
  /// higher z-order. This z-ordering does not imply anything about the altitude
  /// of the area relative to the ground, but it can be used to prevent
  /// z-fighting. Unlike Area.z_order this can be used to compare with
  /// Line.basemap_z_order, and in fact may yield more accurate rendering (where
  /// a line may be rendered beneath an area).
  BasemapZOrder? basemapZOrder;

  /// True if the polygon is not entirely internal to the feature that it
  /// belongs to: that is, some of the edges are bordering another feature.
  core.bool? hasExternalEdges;

  /// When has_external_edges is true, the polygon has some edges that border
  /// another feature.
  ///
  /// This field indicates the internal edges that do not border another
  /// feature. Each value is an index into the vertices array, and denotes the
  /// start vertex of the internal edge (the next vertex in the boundary loop is
  /// the end of the edge). If the selected vertex is the last vertex in the
  /// boundary loop, then the edge between that vertex and the starting vertex
  /// of the loop is internal. This field may be used for styling. For example,
  /// building parapets could be placed only on the external edges of a building
  /// polygon, or water could be lighter colored near the external edges of a
  /// body of water. If has_external_edges is false, all edges are internal and
  /// this field will be empty.
  core.List<core.int>? internalEdges;

  /// Identifies the boundary loops of the polygon.
  ///
  /// Only set for INDEXED_TRIANGLE polygons. Each value is an index into the
  /// vertices array indicating the beginning of a loop. For instance, values of
  /// \[2, 5\] would indicate loop_data contained 3 loops with indices 0-1, 2-4,
  /// and 5-end. This may be used in conjunction with the internal_edges field
  /// for styling polygon boundaries. Note that an edge may be on a polygon
  /// boundary but still internal to the feature. For example, a feature split
  /// across multiple tiles will have an internal polygon boundary edge along
  /// the edge of the tile.
  core.List<core.int>? loopBreaks;

  /// When the polygon encoding is of type INDEXED_TRIANGLES, this contains the
  /// indices of the triangle vertices in the vertex_offsets field.
  ///
  /// There are 3 vertex indices per triangle.
  core.List<core.int>? triangleIndices;

  /// The polygon encoding type used for this area.
  /// Possible string values are:
  /// - "TRIANGLE_FAN" : The first vertex in vertex_offset is the center of a
  /// triangle fan. The other vertices are arranged around this vertex in a fan
  /// shape. The following diagram showes a triangle fan polygon with the
  /// vertices labelled with their indices in the vertex_offset list. Triangle
  /// fan polygons always have a single boundary loop. Vertices may be in either
  /// a clockwise or counterclockwise order. (1) / \ / \ / \ (0)-----(2) / \ / /
  /// \ / / \ / (4)-----(3)
  /// - "INDEXED_TRIANGLES" : The polygon is a set of triangles with three
  /// vertex indices per triangle. The vertex indices can be found in the
  /// triangle_indices field. Indexed triangle polygons also contain information
  /// about boundary loops. These identify the loops at the boundary of the
  /// polygon and may be used in conjunction with the internal_edges field for
  /// styling. Boundary loops may represent either a hole or a disconnected
  /// component of the polygon. The following diagram shows an indexed triangle
  /// polygon with two boundary loops. (0) (4) / \ / \ / \ / \ (1)----(2)
  /// (3)----(5)
  /// - "TRIANGLE_STRIP" : A strip of triangles, where each triangle uses the
  /// last edge of the previous triangle. Vertices may be in either a clockwise
  /// or counterclockwise order. Only polygons without the has_external_edges
  /// flag set will use triangle strips. (0) / \ / \ / \ (2)-----(1) / \ / / \ /
  /// / \ / (4)-----(3)
  core.String? type;

  /// The vertices present in the polygon defining the area.
  Vertex2DList? vertexOffsets;

  /// The z-ordering of this area.
  ///
  /// Areas with a lower z-order should be rendered beneath areas with a higher
  /// z-order. This z-ordering does not imply anything about the altitude of the
  /// line relative to the ground, but it can be used to prevent z-fighting
  /// during rendering on the client. This z-ordering can only be used to
  /// compare areas, and cannot be compared with the z_order field in the Line
  /// message. The z-order may be negative or zero. Prefer Area.basemap_z_order.
  core.int? zOrder;

  Area();

  Area.fromJson(core.Map _json) {
    if (_json.containsKey('basemapZOrder')) {
      basemapZOrder = BasemapZOrder.fromJson(
          _json['basemapZOrder'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hasExternalEdges')) {
      hasExternalEdges = _json['hasExternalEdges'] as core.bool;
    }
    if (_json.containsKey('internalEdges')) {
      internalEdges = (_json['internalEdges'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('loopBreaks')) {
      loopBreaks = (_json['loopBreaks'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('triangleIndices')) {
      triangleIndices = (_json['triangleIndices'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('vertexOffsets')) {
      vertexOffsets = Vertex2DList.fromJson(
          _json['vertexOffsets'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('zOrder')) {
      zOrder = _json['zOrder'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (basemapZOrder != null) 'basemapZOrder': basemapZOrder!.toJson(),
        if (hasExternalEdges != null) 'hasExternalEdges': hasExternalEdges!,
        if (internalEdges != null) 'internalEdges': internalEdges!,
        if (loopBreaks != null) 'loopBreaks': loopBreaks!,
        if (triangleIndices != null) 'triangleIndices': triangleIndices!,
        if (type != null) 'type': type!,
        if (vertexOffsets != null) 'vertexOffsets': vertexOffsets!.toJson(),
        if (zOrder != null) 'zOrder': zOrder!,
      };
}

/// Metadata necessary to determine the ordering of a particular basemap element
/// relative to others.
///
/// To render the basemap correctly, sort by z-plane, then z-grade, then
/// z-within-grade.
class BasemapZOrder {
  /// The second most significant component of the ordering of a component to be
  /// rendered onto the basemap.
  core.int? zGrade;

  /// The most significant component of the ordering of a component to be
  /// rendered onto the basemap.
  core.int? zPlane;

  /// The least significant component of the ordering of a component to be
  /// rendered onto the basemap.
  core.int? zWithinGrade;

  BasemapZOrder();

  BasemapZOrder.fromJson(core.Map _json) {
    if (_json.containsKey('zGrade')) {
      zGrade = _json['zGrade'] as core.int;
    }
    if (_json.containsKey('zPlane')) {
      zPlane = _json['zPlane'] as core.int;
    }
    if (_json.containsKey('zWithinGrade')) {
      zWithinGrade = _json['zWithinGrade'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (zGrade != null) 'zGrade': zGrade!,
        if (zPlane != null) 'zPlane': zPlane!,
        if (zWithinGrade != null) 'zWithinGrade': zWithinGrade!,
      };
}

/// Represents a height-extruded area: a 3D prism with a constant X-Y plane
/// cross section.
///
/// Used to represent extruded buildings. A single building may consist of
/// several extruded areas. The min_z and max_z fields are scaled to the size of
/// the tile. An extruded area with a max_z value of 4096 has the same height as
/// the width of the tile that it is on.
class ExtrudedArea {
  /// The area representing the footprint of the extruded area.
  Area? area;

  /// The z-value in local tile coordinates where the extruded area ends.
  core.int? maxZ;

  /// The z-value in local tile coordinates where the extruded area begins.
  ///
  /// This is non-zero for extruded areas that begin off the ground. For
  /// example, a building with a skybridge may have an extruded area component
  /// with a non-zero min_z.
  core.int? minZ;

  ExtrudedArea();

  ExtrudedArea.fromJson(core.Map _json) {
    if (_json.containsKey('area')) {
      area =
          Area.fromJson(_json['area'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('maxZ')) {
      maxZ = _json['maxZ'] as core.int;
    }
    if (_json.containsKey('minZ')) {
      minZ = _json['minZ'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (area != null) 'area': area!.toJson(),
        if (maxZ != null) 'maxZ': maxZ!,
        if (minZ != null) 'minZ': minZ!,
      };
}

/// A feature representing a single geographic entity.
class Feature {
  /// The localized name of this feature.
  ///
  /// Currently only returned for roads.
  core.String? displayName;

  /// The geometry of this feature, representing the space that it occupies in
  /// the world.
  Geometry? geometry;

  /// Place ID of this feature, suitable for use in Places API details requests.
  core.String? placeId;

  /// Relations to other features.
  core.List<Relation>? relations;

  /// Metadata for features with the SEGMENT FeatureType.
  SegmentInfo? segmentInfo;

  /// The type of this feature.
  /// Possible string values are:
  /// - "FEATURE_TYPE_UNSPECIFIED" : Unknown feature type.
  /// - "STRUCTURE" : Structures such as buildings and bridges.
  /// - "BAR" : A business serving alcoholic drinks to be consumed onsite.
  /// - "BANK" : A financial institution that offers services to the general
  /// public.
  /// - "LODGING" : A place that provides any type of lodging for travelers.
  /// - "CAFE" : A business that sells coffee, tea, and sometimes small meals.
  /// - "RESTAURANT" : A business that prepares meals on-site for service to
  /// customers.
  /// - "EVENT_VENUE" : A venue for private and public events.
  /// - "TOURIST_DESTINATION" : Place of interest to tourists, typically for
  /// natural or cultural value.
  /// - "SHOPPING" : A structure containing a business or businesses that sell
  /// goods.
  /// - "SCHOOL" : Institution where young people receive general (not vocation
  /// or professional) education.
  /// - "SEGMENT" : Segments such as roads and train lines.
  /// - "ROAD" : A way leading from one place to another intended for use by
  /// vehicles.
  /// - "LOCAL_ROAD" : A small city street, typically for travel in a
  /// residential neighborhood.
  /// - "ARTERIAL_ROAD" : Major through road that's expected to carry large
  /// volumes of traffic.
  /// - "HIGHWAY" : A major road including freeways and state highways.
  /// - "CONTROLLED_ACCESS_HIGHWAY" : A highway with grade-separated crossings
  /// that is accessed exclusively by ramps. These are usually called "freeways"
  /// or "motorways". The enable_detailed_highway_types request flag must be set
  /// in order for this type to be returned.
  /// - "FOOTPATH" : A path that's primarily intended for use by pedestrians
  /// and/or cyclists.
  /// - "RAIL" : Tracks intended for use by trains.
  /// - "FERRY" : Services which are part of the road network but are not roads.
  /// - "REGION" : Non-water areas such as parks and forest.
  /// - "PARK" : Outdoor areas such as parks and botanical gardens.
  /// - "BEACH" : A pebbly or sandy shore along the edge of a sea or lake.
  /// - "FOREST" : Area of land covered by trees.
  /// - "POLITICAL" : Political entities, such as provinces and districts.
  /// - "ADMINISTRATIVE_AREA1" : Top-level divisions within a country, such as
  /// prefectures or states.
  /// - "LOCALITY" : Cities, towns, and other municipalities.
  /// - "SUBLOCALITY" : Divisions within a locality like a borough or ward.
  /// - "WATER" : Water features such as rivers and lakes.
  core.String? type;

  Feature();

  Feature.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('geometry')) {
      geometry = Geometry.fromJson(
          _json['geometry'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('placeId')) {
      placeId = _json['placeId'] as core.String;
    }
    if (_json.containsKey('relations')) {
      relations = (_json['relations'] as core.List)
          .map<Relation>((value) =>
              Relation.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segmentInfo')) {
      segmentInfo = SegmentInfo.fromJson(
          _json['segmentInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (geometry != null) 'geometry': geometry!.toJson(),
        if (placeId != null) 'placeId': placeId!,
        if (relations != null)
          'relations': relations!.map((value) => value.toJson()).toList(),
        if (segmentInfo != null) 'segmentInfo': segmentInfo!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// A tile containing information about the map features located in the region
/// it covers.
class FeatureTile {
  /// The global tile coordinates that uniquely identify this tile.
  TileCoordinates? coordinates;

  /// Features present on this map tile.
  core.List<Feature>? features;

  /// Resource name of the tile.
  ///
  /// The tile resource name is prefixed by its collection ID `tiles/` followed
  /// by the resource ID, which encodes the tile's global x and y coordinates
  /// and zoom level as `@,,z`. For example, `tiles/@1,2,3z`.
  core.String? name;

  /// Data providers for the data contained in this tile.
  core.List<ProviderInfo>? providers;

  /// Tile response status code to support tile caching.
  /// Possible string values are:
  /// - "STATUS_OK" : Everything worked out OK. The cache-control header
  /// determines how long this Tile response may be cached by the client. See
  /// also version_id and STATUS_OK_DATA_UNCHANGED.
  /// - "STATUS_OK_DATA_UNCHANGED" : Indicates that the request was processed
  /// successfully and that the tile data that would have been returned are
  /// identical to the data already in the client's cache, as specified by the
  /// value of client_tile_version_id contained in GetFeatureTileRequest. In
  /// particular, the tile's features and providers will not be populated when
  /// the tile data is identical. However, the cache-control header and
  /// version_id can still change even when the tile contents itself does not,
  /// so clients should always use the most recent values returned by the API.
  core.String? status;

  /// An opaque value, usually less than 30 characters, that contains version
  /// info about this tile and the data that was used to generate it.
  ///
  /// The client should store this value in its tile cache and pass it back to
  /// the API in the client_tile_version_id field of subsequent tile requests in
  /// order to enable the API to detect when the new tile would be the same as
  /// the one the client already has in its cache. Also see
  /// STATUS_OK_DATA_UNCHANGED.
  core.String? versionId;

  FeatureTile();

  FeatureTile.fromJson(core.Map _json) {
    if (_json.containsKey('coordinates')) {
      coordinates = TileCoordinates.fromJson(
          _json['coordinates'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('features')) {
      features = (_json['features'] as core.List)
          .map<Feature>((value) =>
              Feature.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('providers')) {
      providers = (_json['providers'] as core.List)
          .map<ProviderInfo>((value) => ProviderInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('versionId')) {
      versionId = _json['versionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (coordinates != null) 'coordinates': coordinates!.toJson(),
        if (features != null)
          'features': features!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (providers != null)
          'providers': providers!.map((value) => value.toJson()).toList(),
        if (status != null) 'status': status!,
        if (versionId != null) 'versionId': versionId!,
      };
}

/// A packed representation of a 2D grid of uniformly spaced points containing
/// elevation data.
///
/// Each point within the grid represents the altitude in meters above average
/// sea level at that location within the tile. Elevations provided are
/// (generally) relative to the EGM96 geoid, however some areas will be relative
/// to NAVD88. EGM96 and NAVD88 are off by no more than 2 meters. The grid is
/// oriented north-west to south-east, as illustrated: rows\[0\].a\[0\]
/// rows\[0\].a\[m\] +-----------------+ | | | N | | ^ | | | | | W <-----> E | |
/// | | | v | | S | | | +-----------------+ rows\[n\].a\[0\] rows\[n\].a\[m\]
/// Rather than storing the altitudes directly, we store the diffs between them
/// as integers at some requested level of precision to take advantage of
/// integer packing. The actual altitude values a\[\] can be reconstructed using
/// the scale and each row's first_altitude and altitude_diff fields.
class FirstDerivativeElevationGrid {
  /// A multiplier applied to the altitude fields below to extract the actual
  /// altitudes in meters from the elevation grid.
  core.double? altitudeMultiplier;

  /// Rows of points containing altitude data making up the elevation grid.
  ///
  /// Each row is the same length. Rows are ordered from north to south. E.g:
  /// rows\[0\] is the north-most row, and rows\[n\] is the south-most row.
  core.List<Row>? rows;

  FirstDerivativeElevationGrid();

  FirstDerivativeElevationGrid.fromJson(core.Map _json) {
    if (_json.containsKey('altitudeMultiplier')) {
      altitudeMultiplier = (_json['altitudeMultiplier'] as core.num).toDouble();
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<Row>((value) =>
              Row.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (altitudeMultiplier != null)
          'altitudeMultiplier': altitudeMultiplier!,
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
      };
}

/// Represents the geometry of a feature, that is, the shape that it has on the
/// map.
///
/// The local tile coordinate system has the origin at the north-west
/// (upper-left) corner of the tile, and is scaled to 4096 units across each
/// edge. The height (Z) axis has the same scale factor: an extruded area with a
/// max_z value of 4096 has the same height as the width of the tile that it is
/// on. There is no clipping boundary, so it is possible that some coordinates
/// will lie outside the tile boundaries.
class Geometry {
  /// The areas present in this geometry.
  core.List<Area>? areas;

  /// The extruded areas present in this geometry.
  ///
  /// Not populated if modeled_volumes are included in this geometry unless
  /// always_include_building_footprints is set in GetFeatureTileRequest, in
  /// which case the client should decide which (extruded areas or modeled
  /// volumes) should be used (they should not be rendered together).
  core.List<ExtrudedArea>? extrudedAreas;

  /// The lines present in this geometry.
  core.List<Line>? lines;

  /// The modeled volumes present in this geometry.
  ///
  /// Not populated unless enable_modeled_volumes has been set in
  /// GetFeatureTileRequest.
  core.List<ModeledVolume>? modeledVolumes;

  Geometry();

  Geometry.fromJson(core.Map _json) {
    if (_json.containsKey('areas')) {
      areas = (_json['areas'] as core.List)
          .map<Area>((value) =>
              Area.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('extrudedAreas')) {
      extrudedAreas = (_json['extrudedAreas'] as core.List)
          .map<ExtrudedArea>((value) => ExtrudedArea.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('lines')) {
      lines = (_json['lines'] as core.List)
          .map<Line>((value) =>
              Line.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('modeledVolumes')) {
      modeledVolumes = (_json['modeledVolumes'] as core.List)
          .map<ModeledVolume>((value) => ModeledVolume.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (areas != null)
          'areas': areas!.map((value) => value.toJson()).toList(),
        if (extrudedAreas != null)
          'extrudedAreas':
              extrudedAreas!.map((value) => value.toJson()).toList(),
        if (lines != null)
          'lines': lines!.map((value) => value.toJson()).toList(),
        if (modeledVolumes != null)
          'modeledVolumes':
              modeledVolumes!.map((value) => value.toJson()).toList(),
      };
}

/// Represents a 2D polyline.
///
/// Used to represent segments such as roads, train tracks, etc.
class Line {
  /// The z-order of this geometry when rendered on a flat basemap.
  ///
  /// Geometry with a lower z-order should be rendered beneath geometry with a
  /// higher z-order. This z-ordering does not imply anything about the altitude
  /// of the area relative to the ground, but it can be used to prevent
  /// z-fighting. Unlike Line.z_order this can be used to compare with
  /// Area.basemap_z_order, and in fact may yield more accurate rendering (where
  /// a line may be rendered beneath an area).
  BasemapZOrder? basemapZOrder;

  /// The vertices present in the polyline.
  Vertex2DList? vertexOffsets;

  /// The z-order of the line.
  ///
  /// Lines with a lower z-order should be rendered beneath lines with a higher
  /// z-order. This z-ordering does not imply anything about the altitude of the
  /// area relative to the ground, but it can be used to prevent z-fighting
  /// during rendering on the client. In general, larger and more important road
  /// features will have a higher z-order line associated with them. This
  /// z-ordering can only be used to compare lines, and cannot be compared with
  /// the z_order field in the Area message. The z-order may be negative or
  /// zero. Prefer Line.basemap_z_order.
  core.int? zOrder;

  Line();

  Line.fromJson(core.Map _json) {
    if (_json.containsKey('basemapZOrder')) {
      basemapZOrder = BasemapZOrder.fromJson(
          _json['basemapZOrder'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('vertexOffsets')) {
      vertexOffsets = Vertex2DList.fromJson(
          _json['vertexOffsets'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('zOrder')) {
      zOrder = _json['zOrder'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (basemapZOrder != null) 'basemapZOrder': basemapZOrder!.toJson(),
        if (vertexOffsets != null) 'vertexOffsets': vertexOffsets!.toJson(),
        if (zOrder != null) 'zOrder': zOrder!,
      };
}

/// Represents a modeled volume in 3D space.
///
/// Used to represent 3D buildings.
class ModeledVolume {
  /// The triangle strips present in this mesh.
  core.List<TriangleStrip>? strips;

  /// The vertices present in the mesh defining the modeled volume.
  Vertex3DList? vertexOffsets;

  ModeledVolume();

  ModeledVolume.fromJson(core.Map _json) {
    if (_json.containsKey('strips')) {
      strips = (_json['strips'] as core.List)
          .map<TriangleStrip>((value) => TriangleStrip.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('vertexOffsets')) {
      vertexOffsets = Vertex3DList.fromJson(
          _json['vertexOffsets'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (strips != null)
          'strips': strips!.map((value) => value.toJson()).toList(),
        if (vertexOffsets != null) 'vertexOffsets': vertexOffsets!.toJson(),
      };
}

/// Information about the data providers that should be included in the
/// attribution string shown by the client.
class ProviderInfo {
  /// Attribution string for this provider.
  ///
  /// This string is not localized.
  core.String? description;

  ProviderInfo();

  ProviderInfo.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
      };
}

/// Represents a relation to another feature in the tile.
///
/// For example, a building might be occupied by a given POI. The related
/// feature can be retrieved using the related feature index.
class Relation {
  /// Zero-based index to look up the related feature from the list of features
  /// in the tile.
  core.int? relatedFeatureIndex;

  /// Relation type between the origin feature to the related feature.
  /// Possible string values are:
  /// - "RELATION_TYPE_UNSPECIFIED" : Unspecified relation type. Should never
  /// happen.
  /// - "OCCUPIES" : The origin feature occupies the related feature.
  /// - "PRIMARILY_OCCUPIED_BY" : The origin feature is primarily occupied by
  /// the related feature.
  core.String? relationType;

  Relation();

  Relation.fromJson(core.Map _json) {
    if (_json.containsKey('relatedFeatureIndex')) {
      relatedFeatureIndex = _json['relatedFeatureIndex'] as core.int;
    }
    if (_json.containsKey('relationType')) {
      relationType = _json['relationType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (relatedFeatureIndex != null)
          'relatedFeatureIndex': relatedFeatureIndex!,
        if (relationType != null) 'relationType': relationType!,
      };
}

/// Extra metadata relating to roads.
class RoadInfo {
  /// Road has signage discouraging or prohibiting use by the general public.
  ///
  /// E.g., roads with signs that say "Private", or "No trespassing."
  core.bool? isPrivate;

  RoadInfo();

  RoadInfo.fromJson(core.Map _json) {
    if (_json.containsKey('isPrivate')) {
      isPrivate = _json['isPrivate'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (isPrivate != null) 'isPrivate': isPrivate!,
      };
}

/// A row of altitude points in the elevation grid, ordered from west to east.
class Row {
  /// The difference between each successive pair of altitudes, from west to
  /// east.
  ///
  /// The first, westmost point, is just the altitude rather than a diff. The
  /// units are specified by the altitude_multiplier parameter above; the value
  /// in meters is given by altitude_multiplier * altitude_diffs\[n\]. The
  /// altitude row (in metres above sea level) can be reconstructed with: a\[0\]
  /// = altitude_diffs\[0\] * altitude_multiplier when n > 0, a\[n\] = a\[n-1\]
  /// + altitude_diffs\[n-1\] * altitude_multiplier.
  core.List<core.int>? altitudeDiffs;

  Row();

  Row.fromJson(core.Map _json) {
    if (_json.containsKey('altitudeDiffs')) {
      altitudeDiffs = (_json['altitudeDiffs'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (altitudeDiffs != null) 'altitudeDiffs': altitudeDiffs!,
      };
}

/// A packed representation of a 2D grid of uniformly spaced points containing
/// elevation data.
///
/// Each point within the grid represents the altitude in meters above average
/// sea level at that location within the tile. Elevations provided are
/// (generally) relative to the EGM96 geoid, however some areas will be relative
/// to NAVD88. EGM96 and NAVD88 are off by no more than 2 meters. The grid is
/// oriented north-west to south-east, as illustrated: rows\[0\].a\[0\]
/// rows\[0\].a\[m\] +-----------------+ | | | N | | ^ | | | | | W <-----> E | |
/// | | | v | | S | | | +-----------------+ rows\[n\].a\[0\] rows\[n\].a\[m\]
/// Rather than storing the altitudes directly, we store the diffs of the diffs
/// between them as integers at some requested level of precision to take
/// advantage of integer packing. Note that the data is packed in such a way
/// that is fast to decode in Unity and that further optimizes wire size.
class SecondDerivativeElevationGrid {
  /// A multiplier applied to the elements in the encoded data to extract the
  /// actual altitudes in meters.
  core.double? altitudeMultiplier;

  /// The number of columns included in the encoded elevation data (i.e. the
  /// horizontal resolution of the grid).
  core.int? columnCount;

  /// A stream of elements each representing a point on the tile running across
  /// each row from left to right, top to bottom.
  ///
  /// There will be precisely horizontal_resolution * vertical_resolution
  /// elements in the stream. The elements are not the heights, rather the
  /// second order derivative of the values one would expect in a stream of
  /// height data. Each element is a varint with the following encoding:
  /// ------------------------------------------------------------------------|
  /// | Head Nibble |
  /// ------------------------------------------------------------------------|
  /// | Bit 0 | Bit 1 | Bits 2-3 | | Terminator| Sign (1=neg) | Least
  /// significant 2 bits of absolute error |
  /// ------------------------------------------------------------------------|
  /// | Tail Nibble #1 |
  /// ------------------------------------------------------------------------|
  /// | Bit 0 | Bit 1-3 | | Terminator| Least significant 3 bits of absolute
  /// error |
  /// ------------------------------------------------------------------------|
  /// | ... | Tail Nibble #n |
  /// ------------------------------------------------------------------------|
  /// | Bit 0 | Bit 1-3 | | Terminator| Least significant 3 bits of absolute
  /// error |
  /// ------------------------------------------------------------------------|
  core.String? encodedData;
  core.List<core.int> get encodedDataAsBytes =>
      convert.base64.decode(encodedData!);

  set encodedDataAsBytes(core.List<core.int> _bytes) {
    encodedData =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The number of rows included in the encoded elevation data (i.e. the
  /// vertical resolution of the grid).
  core.int? rowCount;

  SecondDerivativeElevationGrid();

  SecondDerivativeElevationGrid.fromJson(core.Map _json) {
    if (_json.containsKey('altitudeMultiplier')) {
      altitudeMultiplier = (_json['altitudeMultiplier'] as core.num).toDouble();
    }
    if (_json.containsKey('columnCount')) {
      columnCount = _json['columnCount'] as core.int;
    }
    if (_json.containsKey('encodedData')) {
      encodedData = _json['encodedData'] as core.String;
    }
    if (_json.containsKey('rowCount')) {
      rowCount = _json['rowCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (altitudeMultiplier != null)
          'altitudeMultiplier': altitudeMultiplier!,
        if (columnCount != null) 'columnCount': columnCount!,
        if (encodedData != null) 'encodedData': encodedData!,
        if (rowCount != null) 'rowCount': rowCount!,
      };
}

/// Extra metadata relating to segments.
class SegmentInfo {
  /// Metadata for features with the ROAD FeatureType.
  RoadInfo? roadInfo;

  SegmentInfo();

  SegmentInfo.fromJson(core.Map _json) {
    if (_json.containsKey('roadInfo')) {
      roadInfo = RoadInfo.fromJson(
          _json['roadInfo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (roadInfo != null) 'roadInfo': roadInfo!.toJson(),
      };
}

/// A tile containing information about the terrain located in the region it
/// covers.
class TerrainTile {
  /// The global tile coordinates that uniquely identify this tile.
  TileCoordinates? coordinates;

  /// Terrain elevation data encoded as a FirstDerivativeElevationGrid.
  FirstDerivativeElevationGrid? firstDerivative;

  /// Resource name of the tile.
  ///
  /// The tile resource name is prefixed by its collection ID `terrain/`
  /// followed by the resource ID, which encodes the tile's global x and y
  /// coordinates and zoom level as `@,,z`. For example, `terrain/@1,2,3z`.
  core.String? name;

  /// Terrain elevation data encoded as a SecondDerivativeElevationGrid.
  ///
  /// .
  SecondDerivativeElevationGrid? secondDerivative;

  TerrainTile();

  TerrainTile.fromJson(core.Map _json) {
    if (_json.containsKey('coordinates')) {
      coordinates = TileCoordinates.fromJson(
          _json['coordinates'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('firstDerivative')) {
      firstDerivative = FirstDerivativeElevationGrid.fromJson(
          _json['firstDerivative'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('secondDerivative')) {
      secondDerivative = SecondDerivativeElevationGrid.fromJson(
          _json['secondDerivative'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (coordinates != null) 'coordinates': coordinates!.toJson(),
        if (firstDerivative != null)
          'firstDerivative': firstDerivative!.toJson(),
        if (name != null) 'name': name!,
        if (secondDerivative != null)
          'secondDerivative': secondDerivative!.toJson(),
      };
}

/// Global tile coordinates.
///
/// Global tile coordinates reference a specific tile on the map at a specific
/// zoom level. The origin of this coordinate system is always at the northwest
/// corner of the map, with x values increasing from west to east and y values
/// increasing from north to south. Tiles are indexed using x, y coordinates
/// from that origin. The zoom level containing the entire world in a tile is 0,
/// and it increases as you zoom in. Zoom level n + 1 will contain 4 times as
/// many tiles as zoom level n. The zoom level controls the level of detail of
/// the data that is returned. In particular, this affects the set of feature
/// types returned, their density, and geometry simplification. The exact tile
/// contents may change over time, but care will be taken to keep supporting the
/// most important use cases. For example, zoom level 15 shows roads for
/// orientation and planning in the local neighborhood and zoom level 17 shows
/// buildings to give users on foot a sense of situational awareness.
class TileCoordinates {
  /// The x coordinate.
  ///
  /// Required.
  core.int? x;

  /// The y coordinate.
  ///
  /// Required.
  core.int? y;

  /// The Google Maps API zoom level.
  ///
  /// Required.
  core.int? zoom;

  TileCoordinates();

  TileCoordinates.fromJson(core.Map _json) {
    if (_json.containsKey('x')) {
      x = _json['x'] as core.int;
    }
    if (_json.containsKey('y')) {
      y = _json['y'] as core.int;
    }
    if (_json.containsKey('zoom')) {
      zoom = _json['zoom'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (x != null) 'x': x!,
        if (y != null) 'y': y!,
        if (zoom != null) 'zoom': zoom!,
      };
}

/// Represents a strip of triangles.
///
/// Each triangle uses the last edge of the previous one. The following diagram
/// shows an example of a triangle strip, with each vertex labeled with its
/// index in the vertex_index array. (1)-----(3) / \ / \ / \ / \ / \ / \
/// (0)-----(2)-----(4) Vertices may be in either clockwise or counter-clockwise
/// order.
class TriangleStrip {
  /// Index into the vertex_offset array representing the next vertex in the
  /// triangle strip.
  core.List<core.int>? vertexIndices;

  TriangleStrip();

  TriangleStrip.fromJson(core.Map _json) {
    if (_json.containsKey('vertexIndices')) {
      vertexIndices = (_json['vertexIndices'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (vertexIndices != null) 'vertexIndices': vertexIndices!,
      };
}

/// 2D vertex list used for lines and areas.
///
/// Each entry represents an offset from the previous one in local tile
/// coordinates. The first entry is offset from (0, 0). For example, the list of
/// vertices \[(1,1), (2, 2), (1, 2)\] would be encoded in vertex offsets as
/// \[(1, 1), (1, 1), (-1, 0)\].
class Vertex2DList {
  /// List of x-offsets in local tile coordinates.
  core.List<core.int>? xOffsets;

  /// List of y-offsets in local tile coordinates.
  core.List<core.int>? yOffsets;

  Vertex2DList();

  Vertex2DList.fromJson(core.Map _json) {
    if (_json.containsKey('xOffsets')) {
      xOffsets = (_json['xOffsets'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('yOffsets')) {
      yOffsets = (_json['yOffsets'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (xOffsets != null) 'xOffsets': xOffsets!,
        if (yOffsets != null) 'yOffsets': yOffsets!,
      };
}

/// 3D vertex list used for modeled volumes.
///
/// Each entry represents an offset from the previous one in local tile
/// coordinates. The first coordinate is offset from (0, 0, 0).
class Vertex3DList {
  /// List of x-offsets in local tile coordinates.
  core.List<core.int>? xOffsets;

  /// List of y-offsets in local tile coordinates.
  core.List<core.int>? yOffsets;

  /// List of z-offsets in local tile coordinates.
  core.List<core.int>? zOffsets;

  Vertex3DList();

  Vertex3DList.fromJson(core.Map _json) {
    if (_json.containsKey('xOffsets')) {
      xOffsets = (_json['xOffsets'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('yOffsets')) {
      yOffsets = (_json['yOffsets'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('zOffsets')) {
      zOffsets = (_json['zOffsets'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (xOffsets != null) 'xOffsets': xOffsets!,
        if (yOffsets != null) 'yOffsets': yOffsets!,
        if (zOffsets != null) 'zOffsets': zOffsets!,
      };
}
