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

/// Google Slides API - v1
///
/// Reads and writes Google Slides presentations.
///
/// For more information, see <https://developers.google.com/slides/>
///
/// Create an instance of [SlidesApi] to access these resources:
///
/// - [PresentationsResource]
///   - [PresentationsPagesResource]
library slides.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Reads and writes Google Slides presentations.
class SlidesApi {
  /// See, edit, create, and delete all of your Google Drive files
  static const driveScope = 'https://www.googleapis.com/auth/drive';

  /// See, edit, create, and delete only the specific Google Drive files you use
  /// with this app
  static const driveFileScope = 'https://www.googleapis.com/auth/drive.file';

  /// See and download all your Google Drive files
  static const driveReadonlyScope =
      'https://www.googleapis.com/auth/drive.readonly';

  /// View and manage your Google Slides presentations
  static const presentationsScope =
      'https://www.googleapis.com/auth/presentations';

  /// View your Google Slides presentations
  static const presentationsReadonlyScope =
      'https://www.googleapis.com/auth/presentations.readonly';

  /// See, edit, create, and delete your spreadsheets in Google Drive
  static const spreadsheetsScope =
      'https://www.googleapis.com/auth/spreadsheets';

  /// View your Google Spreadsheets
  static const spreadsheetsReadonlyScope =
      'https://www.googleapis.com/auth/spreadsheets.readonly';

  final commons.ApiRequester _requester;

  PresentationsResource get presentations => PresentationsResource(_requester);

  SlidesApi(http.Client client,
      {core.String rootUrl = 'https://slides.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class PresentationsResource {
  final commons.ApiRequester _requester;

  PresentationsPagesResource get pages =>
      PresentationsPagesResource(_requester);

  PresentationsResource(commons.ApiRequester client) : _requester = client;

  /// Applies one or more updates to the presentation.
  ///
  /// Each request is validated before being applied. If any request is not
  /// valid, then the entire request will fail and nothing will be applied. Some
  /// requests have replies to give you some information about how they are
  /// applied. Other requests do not need to return information; these each
  /// return an empty reply. The order of replies matches that of the requests.
  /// For example, suppose you call batchUpdate with four updates, and only the
  /// third one returns information. The response would have two empty replies:
  /// the reply to the third request, and another empty reply, in that order.
  /// Because other users may be editing the presentation, the presentation
  /// might not exactly reflect your changes: your changes may be altered with
  /// respect to collaborator changes. If there are no collaborators, the
  /// presentation should reflect your changes. In any case, the updates in your
  /// request are guaranteed to be applied together atomically.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [presentationId] - The presentation to apply the updates to.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchUpdatePresentationResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchUpdatePresentationResponse> batchUpdate(
    BatchUpdatePresentationRequest request,
    core.String presentationId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/presentations/' +
        commons.escapeVariable('$presentationId') +
        ':batchUpdate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BatchUpdatePresentationResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a blank presentation using the title given in the request.
  ///
  /// If a `presentationId` is provided, it is used as the ID of the new
  /// presentation. Otherwise, a new ID is generated. Other fields in the
  /// request, including any provided content, are ignored. Returns the created
  /// presentation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Presentation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Presentation> create(
    Presentation request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/presentations';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Presentation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the latest version of the specified presentation.
  ///
  /// Request parameters:
  ///
  /// [presentationId] - The ID of the presentation to retrieve.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Presentation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Presentation> get(
    core.String presentationId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/presentations/' + core.Uri.encodeFull('$presentationId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Presentation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PresentationsPagesResource {
  final commons.ApiRequester _requester;

  PresentationsPagesResource(commons.ApiRequester client) : _requester = client;

  /// Gets the latest version of the specified page in the presentation.
  ///
  /// Request parameters:
  ///
  /// [presentationId] - The ID of the presentation to retrieve.
  ///
  /// [pageObjectId] - The object ID of the page to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Page].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Page> get(
    core.String presentationId,
    core.String pageObjectId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/presentations/' +
        commons.escapeVariable('$presentationId') +
        '/pages/' +
        commons.escapeVariable('$pageObjectId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Page.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Generates a thumbnail of the latest version of the specified page in the
  /// presentation and returns a URL to the thumbnail image.
  ///
  /// This request counts as an \[expensive read request\](/slides/limits) for
  /// quota purposes.
  ///
  /// Request parameters:
  ///
  /// [presentationId] - The ID of the presentation to retrieve.
  ///
  /// [pageObjectId] - The object ID of the page whose thumbnail to retrieve.
  ///
  /// [thumbnailProperties_mimeType] - The optional mime type of the thumbnail
  /// image. If you don't specify the mime type, the mime type defaults to PNG.
  /// Possible string values are:
  /// - "PNG" : The default mime type.
  ///
  /// [thumbnailProperties_thumbnailSize] - The optional thumbnail image size.
  /// If you don't specify the size, the server chooses a default size of the
  /// image.
  /// Possible string values are:
  /// - "THUMBNAIL_SIZE_UNSPECIFIED" : The default thumbnail image size. The
  /// unspecified thumbnail size implies that the server chooses the size of the
  /// image in a way that might vary in the future.
  /// - "LARGE" : The thumbnail image width of 1600px.
  /// - "MEDIUM" : The thumbnail image width of 800px.
  /// - "SMALL" : The thumbnail image width of 200px.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Thumbnail].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Thumbnail> getThumbnail(
    core.String presentationId,
    core.String pageObjectId, {
    core.String? thumbnailProperties_mimeType,
    core.String? thumbnailProperties_thumbnailSize,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (thumbnailProperties_mimeType != null)
        'thumbnailProperties.mimeType': [thumbnailProperties_mimeType],
      if (thumbnailProperties_thumbnailSize != null)
        'thumbnailProperties.thumbnailSize': [
          thumbnailProperties_thumbnailSize
        ],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/presentations/' +
        commons.escapeVariable('$presentationId') +
        '/pages/' +
        commons.escapeVariable('$pageObjectId') +
        '/thumbnail';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Thumbnail.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// AffineTransform uses a 3x3 matrix with an implied last row of \[ 0 0 1 \] to
/// transform source coordinates (x,y) into destination coordinates (x', y')
/// according to: x' x = shear_y scale_y translate_y 1 \[ 1 \] After
/// transformation, x' = scale_x * x + shear_x * y + translate_x; y' = scale_y *
/// y + shear_y * x + translate_y; This message is therefore composed of these
/// six matrix elements.
class AffineTransform {
  /// The X coordinate scaling element.
  core.double? scaleX;

  /// The Y coordinate scaling element.
  core.double? scaleY;

  /// The X coordinate shearing element.
  core.double? shearX;

  /// The Y coordinate shearing element.
  core.double? shearY;

  /// The X coordinate translation element.
  core.double? translateX;

  /// The Y coordinate translation element.
  core.double? translateY;

  /// The units for translate elements.
  /// Possible string values are:
  /// - "UNIT_UNSPECIFIED" : The units are unknown.
  /// - "EMU" : An English Metric Unit (EMU) is defined as 1/360,000 of a
  /// centimeter and thus there are 914,400 EMUs per inch, and 12,700 EMUs per
  /// point.
  /// - "PT" : A point, 1/72 of an inch.
  core.String? unit;

  AffineTransform();

  AffineTransform.fromJson(core.Map _json) {
    if (_json.containsKey('scaleX')) {
      scaleX = (_json['scaleX'] as core.num).toDouble();
    }
    if (_json.containsKey('scaleY')) {
      scaleY = (_json['scaleY'] as core.num).toDouble();
    }
    if (_json.containsKey('shearX')) {
      shearX = (_json['shearX'] as core.num).toDouble();
    }
    if (_json.containsKey('shearY')) {
      shearY = (_json['shearY'] as core.num).toDouble();
    }
    if (_json.containsKey('translateX')) {
      translateX = (_json['translateX'] as core.num).toDouble();
    }
    if (_json.containsKey('translateY')) {
      translateY = (_json['translateY'] as core.num).toDouble();
    }
    if (_json.containsKey('unit')) {
      unit = _json['unit'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (scaleX != null) 'scaleX': scaleX!,
        if (scaleY != null) 'scaleY': scaleY!,
        if (shearX != null) 'shearX': shearX!,
        if (shearY != null) 'shearY': shearY!,
        if (translateX != null) 'translateX': translateX!,
        if (translateY != null) 'translateY': translateY!,
        if (unit != null) 'unit': unit!,
      };
}

/// A TextElement kind that represents auto text.
class AutoText {
  /// The rendered content of this auto text, if available.
  core.String? content;

  /// The styling applied to this auto text.
  TextStyle? style;

  /// The type of this auto text.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : An unspecified autotext type.
  /// - "SLIDE_NUMBER" : Type for autotext that represents the current slide
  /// number.
  core.String? type;

  AutoText();

  AutoText.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('style')) {
      style = TextStyle.fromJson(
          _json['style'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (style != null) 'style': style!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// The autofit properties of a Shape.
class Autofit {
  /// The autofit type of the shape.
  ///
  /// If the autofit type is AUTOFIT_TYPE_UNSPECIFIED, the autofit type is
  /// inherited from a parent placeholder if it exists. The field is
  /// automatically set to NONE if a request is made that might affect text
  /// fitting within its bounding text box. In this case the font_scale is
  /// applied to the font_size and the line_spacing_reduction is applied to the
  /// line_spacing. Both properties are also reset to default values.
  /// Possible string values are:
  /// - "AUTOFIT_TYPE_UNSPECIFIED" : The autofit type is unspecified.
  /// - "NONE" : Do not autofit.
  /// - "TEXT_AUTOFIT" : Shrink text on overflow to fit the shape.
  /// - "SHAPE_AUTOFIT" : Resize the shape to fit the text.
  core.String? autofitType;

  /// The font scale applied to the shape.
  ///
  /// For shapes with autofit_type NONE or SHAPE_AUTOFIT, this value is the
  /// default value of 1. For TEXT_AUTOFIT, this value multiplied by the
  /// font_size gives the font size that is rendered in the editor. This
  /// property is read-only.
  core.double? fontScale;

  /// The line spacing reduction applied to the shape.
  ///
  /// For shapes with autofit_type NONE or SHAPE_AUTOFIT, this value is the
  /// default value of 0. For TEXT_AUTOFIT, this value subtracted from the
  /// line_spacing gives the line spacing that is rendered in the editor. This
  /// property is read-only.
  core.double? lineSpacingReduction;

  Autofit();

  Autofit.fromJson(core.Map _json) {
    if (_json.containsKey('autofitType')) {
      autofitType = _json['autofitType'] as core.String;
    }
    if (_json.containsKey('fontScale')) {
      fontScale = (_json['fontScale'] as core.num).toDouble();
    }
    if (_json.containsKey('lineSpacingReduction')) {
      lineSpacingReduction =
          (_json['lineSpacingReduction'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autofitType != null) 'autofitType': autofitType!,
        if (fontScale != null) 'fontScale': fontScale!,
        if (lineSpacingReduction != null)
          'lineSpacingReduction': lineSpacingReduction!,
      };
}

/// Request message for PresentationsService.BatchUpdatePresentation.
class BatchUpdatePresentationRequest {
  /// A list of updates to apply to the presentation.
  core.List<Request>? requests;

  /// Provides control over how write requests are executed.
  WriteControl? writeControl;

  BatchUpdatePresentationRequest();

  BatchUpdatePresentationRequest.fromJson(core.Map _json) {
    if (_json.containsKey('requests')) {
      requests = (_json['requests'] as core.List)
          .map<Request>((value) =>
              Request.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('writeControl')) {
      writeControl = WriteControl.fromJson(
          _json['writeControl'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requests != null)
          'requests': requests!.map((value) => value.toJson()).toList(),
        if (writeControl != null) 'writeControl': writeControl!.toJson(),
      };
}

/// Response message from a batch update.
class BatchUpdatePresentationResponse {
  /// The presentation the updates were applied to.
  core.String? presentationId;

  /// The reply of the updates.
  ///
  /// This maps 1:1 with the updates, although replies to some requests may be
  /// empty.
  core.List<Response>? replies;

  /// The updated write control after applying the request.
  WriteControl? writeControl;

  BatchUpdatePresentationResponse();

  BatchUpdatePresentationResponse.fromJson(core.Map _json) {
    if (_json.containsKey('presentationId')) {
      presentationId = _json['presentationId'] as core.String;
    }
    if (_json.containsKey('replies')) {
      replies = (_json['replies'] as core.List)
          .map<Response>((value) =>
              Response.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('writeControl')) {
      writeControl = WriteControl.fromJson(
          _json['writeControl'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (presentationId != null) 'presentationId': presentationId!,
        if (replies != null)
          'replies': replies!.map((value) => value.toJson()).toList(),
        if (writeControl != null) 'writeControl': writeControl!.toJson(),
      };
}

/// Describes the bullet of a paragraph.
class Bullet {
  /// The paragraph specific text style applied to this bullet.
  TextStyle? bulletStyle;

  /// The rendered bullet glyph for this paragraph.
  core.String? glyph;

  /// The ID of the list this paragraph belongs to.
  core.String? listId;

  /// The nesting level of this paragraph in the list.
  core.int? nestingLevel;

  Bullet();

  Bullet.fromJson(core.Map _json) {
    if (_json.containsKey('bulletStyle')) {
      bulletStyle = TextStyle.fromJson(
          _json['bulletStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('glyph')) {
      glyph = _json['glyph'] as core.String;
    }
    if (_json.containsKey('listId')) {
      listId = _json['listId'] as core.String;
    }
    if (_json.containsKey('nestingLevel')) {
      nestingLevel = _json['nestingLevel'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bulletStyle != null) 'bulletStyle': bulletStyle!.toJson(),
        if (glyph != null) 'glyph': glyph!,
        if (listId != null) 'listId': listId!,
        if (nestingLevel != null) 'nestingLevel': nestingLevel!,
      };
}

/// The palette of predefined colors for a page.
class ColorScheme {
  /// The ThemeColorType and corresponding concrete color pairs.
  core.List<ThemeColorPair>? colors;

  ColorScheme();

  ColorScheme.fromJson(core.Map _json) {
    if (_json.containsKey('colors')) {
      colors = (_json['colors'] as core.List)
          .map<ThemeColorPair>((value) => ThemeColorPair.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (colors != null)
          'colors': colors!.map((value) => value.toJson()).toList(),
      };
}

/// A color and position in a gradient band.
class ColorStop {
  /// The alpha value of this color in the gradient band.
  ///
  /// Defaults to 1.0, fully opaque.
  core.double? alpha;

  /// The color of the gradient stop.
  OpaqueColor? color;

  /// The relative position of the color stop in the gradient band measured in
  /// percentage.
  ///
  /// The value should be in the interval \[0.0, 1.0\].
  core.double? position;

  ColorStop();

  ColorStop.fromJson(core.Map _json) {
    if (_json.containsKey('alpha')) {
      alpha = (_json['alpha'] as core.num).toDouble();
    }
    if (_json.containsKey('color')) {
      color = OpaqueColor.fromJson(
          _json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('position')) {
      position = (_json['position'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alpha != null) 'alpha': alpha!,
        if (color != null) 'color': color!.toJson(),
        if (position != null) 'position': position!,
      };
}

/// Creates an image.
class CreateImageRequest {
  /// The element properties for the image.
  ///
  /// When the aspect ratio of the provided size does not match the image aspect
  /// ratio, the image is scaled and centered with respect to the size in order
  /// to maintain aspect ratio. The provided transform is applied after this
  /// operation. The PageElementProperties.size property is optional. If you
  /// don't specify the size, the default size of the image is used. The
  /// PageElementProperties.transform property is optional. If you don't specify
  /// a transform, the image will be placed at the top left corner of the page.
  PageElementProperties? elementProperties;

  /// A user-supplied object ID.
  ///
  /// If you specify an ID, it must be unique among all pages and page elements
  /// in the presentation. The ID must start with an alphanumeric character or
  /// an underscore (matches regex `[a-zA-Z0-9_]`); remaining characters may
  /// include those as well as a hyphen or colon (matches regex
  /// `[a-zA-Z0-9_-:]`). The length of the ID must not be less than 5 or greater
  /// than 50. If you don't specify an ID, a unique one is generated.
  core.String? objectId;

  /// The image URL.
  ///
  /// The image is fetched once at insertion time and a copy is stored for
  /// display inside the presentation. Images must be less than 50MB in size,
  /// cannot exceed 25 megapixels, and must be in one of PNG, JPEG, or GIF
  /// format. The provided URL can be at most 2 kB in length. The URL itself is
  /// saved with the image, and exposed via the Image.source_url field.
  core.String? url;

  CreateImageRequest();

  CreateImageRequest.fromJson(core.Map _json) {
    if (_json.containsKey('elementProperties')) {
      elementProperties = PageElementProperties.fromJson(
          _json['elementProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (elementProperties != null)
          'elementProperties': elementProperties!.toJson(),
        if (objectId != null) 'objectId': objectId!,
        if (url != null) 'url': url!,
      };
}

/// The result of creating an image.
class CreateImageResponse {
  /// The object ID of the created image.
  core.String? objectId;

  CreateImageResponse();

  CreateImageResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Creates a line.
class CreateLineRequest {
  /// The category of the line to be created.
  ///
  /// The exact line type created is determined based on the category and how
  /// it's routed to connect to other page elements. If you specify both a
  /// `category` and a `line_category`, the `category` takes precedence. If you
  /// do not specify a value for `category`, but specify a value for
  /// `line_category`, then the specified `line_category` value is used. If you
  /// do not specify either, then STRAIGHT is used.
  /// Possible string values are:
  /// - "LINE_CATEGORY_UNSPECIFIED" : Unspecified line category.
  /// - "STRAIGHT" : Straight connectors, including straight connector 1.
  /// - "BENT" : Bent connectors, including bent connector 2 to 5.
  /// - "CURVED" : Curved connectors, including curved connector 2 to 5.
  core.String? category;

  /// The element properties for the line.
  PageElementProperties? elementProperties;

  /// The category of the line to be created.
  ///
  /// *Deprecated*: use `category` instead. The exact line type created is
  /// determined based on the category and how it's routed to connect to other
  /// page elements. If you specify both a `category` and a `line_category`, the
  /// `category` takes precedence.
  /// Possible string values are:
  /// - "STRAIGHT" : Straight connectors, including straight connector 1. The is
  /// the default category when one is not specified.
  /// - "BENT" : Bent connectors, including bent connector 2 to 5.
  /// - "CURVED" : Curved connectors, including curved connector 2 to 5.
  core.String? lineCategory;

  /// A user-supplied object ID.
  ///
  /// If you specify an ID, it must be unique among all pages and page elements
  /// in the presentation. The ID must start with an alphanumeric character or
  /// an underscore (matches regex `[a-zA-Z0-9_]`); remaining characters may
  /// include those as well as a hyphen or colon (matches regex
  /// `[a-zA-Z0-9_-:]`). The length of the ID must not be less than 5 or greater
  /// than 50. If you don't specify an ID, a unique one is generated.
  core.String? objectId;

  CreateLineRequest();

  CreateLineRequest.fromJson(core.Map _json) {
    if (_json.containsKey('category')) {
      category = _json['category'] as core.String;
    }
    if (_json.containsKey('elementProperties')) {
      elementProperties = PageElementProperties.fromJson(
          _json['elementProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lineCategory')) {
      lineCategory = _json['lineCategory'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (category != null) 'category': category!,
        if (elementProperties != null)
          'elementProperties': elementProperties!.toJson(),
        if (lineCategory != null) 'lineCategory': lineCategory!,
        if (objectId != null) 'objectId': objectId!,
      };
}

/// The result of creating a line.
class CreateLineResponse {
  /// The object ID of the created line.
  core.String? objectId;

  CreateLineResponse();

  CreateLineResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Creates bullets for all of the paragraphs that overlap with the given text
/// index range.
///
/// The nesting level of each paragraph will be determined by counting leading
/// tabs in front of each paragraph. To avoid excess space between the bullet
/// and the corresponding paragraph, these leading tabs are removed by this
/// request. This may change the indices of parts of the text. If the paragraph
/// immediately before paragraphs being updated is in a list with a matching
/// preset, the paragraphs being updated are added to that preceding list.
class CreateParagraphBulletsRequest {
  /// The kinds of bullet glyphs to be used.
  ///
  /// Defaults to the `BULLET_DISC_CIRCLE_SQUARE` preset.
  /// Possible string values are:
  /// - "BULLET_DISC_CIRCLE_SQUARE" : A bulleted list with a `DISC`, `CIRCLE`
  /// and `SQUARE` bullet glyph for the first 3 list nesting levels.
  /// - "BULLET_DIAMONDX_ARROW3D_SQUARE" : A bulleted list with a `DIAMONDX`,
  /// `ARROW3D` and `SQUARE` bullet glyph for the first 3 list nesting levels.
  /// - "BULLET_CHECKBOX" : A bulleted list with `CHECKBOX` bullet glyphs for
  /// all list nesting levels.
  /// - "BULLET_ARROW_DIAMOND_DISC" : A bulleted list with a `ARROW`, `DIAMOND`
  /// and `DISC` bullet glyph for the first 3 list nesting levels.
  /// - "BULLET_STAR_CIRCLE_SQUARE" : A bulleted list with a `STAR`, `CIRCLE`
  /// and `SQUARE` bullet glyph for the first 3 list nesting levels.
  /// - "BULLET_ARROW3D_CIRCLE_SQUARE" : A bulleted list with a `ARROW3D`,
  /// `CIRCLE` and `SQUARE` bullet glyph for the first 3 list nesting levels.
  /// - "BULLET_LEFTTRIANGLE_DIAMOND_DISC" : A bulleted list with a
  /// `LEFTTRIANGLE`, `DIAMOND` and `DISC` bullet glyph for the first 3 list
  /// nesting levels.
  /// - "BULLET_DIAMONDX_HOLLOWDIAMOND_SQUARE" : A bulleted list with a
  /// `DIAMONDX`, `HOLLOWDIAMOND` and `SQUARE` bullet glyph for the first 3 list
  /// nesting levels.
  /// - "BULLET_DIAMOND_CIRCLE_SQUARE" : A bulleted list with a `DIAMOND`,
  /// `CIRCLE` and `SQUARE` bullet glyph for the first 3 list nesting levels.
  /// - "NUMBERED_DIGIT_ALPHA_ROMAN" : A numbered list with `DIGIT`, `ALPHA` and
  /// `ROMAN` numeric glyphs for the first 3 list nesting levels, followed by
  /// periods.
  /// - "NUMBERED_DIGIT_ALPHA_ROMAN_PARENS" : A numbered list with `DIGIT`,
  /// `ALPHA` and `ROMAN` numeric glyphs for the first 3 list nesting levels,
  /// followed by parenthesis.
  /// - "NUMBERED_DIGIT_NESTED" : A numbered list with `DIGIT` numeric glyphs
  /// separated by periods, where each nesting level uses the previous nesting
  /// level's glyph as a prefix. For example: '1.', '1.1.', '2.', '2.2.'.
  /// - "NUMBERED_UPPERALPHA_ALPHA_ROMAN" : A numbered list with `UPPERALPHA`,
  /// `ALPHA` and `ROMAN` numeric glyphs for the first 3 list nesting levels,
  /// followed by periods.
  /// - "NUMBERED_UPPERROMAN_UPPERALPHA_DIGIT" : A numbered list with
  /// `UPPERROMAN`, `UPPERALPHA` and `DIGIT` numeric glyphs for the first 3 list
  /// nesting levels, followed by periods.
  /// - "NUMBERED_ZERODIGIT_ALPHA_ROMAN" : A numbered list with `ZERODIGIT`,
  /// `ALPHA` and `ROMAN` numeric glyphs for the first 3 list nesting levels,
  /// followed by periods.
  core.String? bulletPreset;

  /// The optional table cell location if the text to be modified is in a table
  /// cell.
  ///
  /// If present, the object_id must refer to a table.
  TableCellLocation? cellLocation;

  /// The object ID of the shape or table containing the text to add bullets to.
  core.String? objectId;

  /// The range of text to apply the bullet presets to, based on TextElement
  /// indexes.
  Range? textRange;

  CreateParagraphBulletsRequest();

  CreateParagraphBulletsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('bulletPreset')) {
      bulletPreset = _json['bulletPreset'] as core.String;
    }
    if (_json.containsKey('cellLocation')) {
      cellLocation = TableCellLocation.fromJson(
          _json['cellLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('textRange')) {
      textRange = Range.fromJson(
          _json['textRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bulletPreset != null) 'bulletPreset': bulletPreset!,
        if (cellLocation != null) 'cellLocation': cellLocation!.toJson(),
        if (objectId != null) 'objectId': objectId!,
        if (textRange != null) 'textRange': textRange!.toJson(),
      };
}

/// Creates a new shape.
class CreateShapeRequest {
  /// The element properties for the shape.
  PageElementProperties? elementProperties;

  /// A user-supplied object ID.
  ///
  /// If you specify an ID, it must be unique among all pages and page elements
  /// in the presentation. The ID must start with an alphanumeric character or
  /// an underscore (matches regex `[a-zA-Z0-9_]`); remaining characters may
  /// include those as well as a hyphen or colon (matches regex
  /// `[a-zA-Z0-9_-:]`). The length of the ID must not be less than 5 or greater
  /// than 50. If empty, a unique identifier will be generated.
  core.String? objectId;

  /// The shape type.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : The shape type that is not predefined.
  /// - "TEXT_BOX" : Text box shape.
  /// - "RECTANGLE" : Rectangle shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'rect'.
  /// - "ROUND_RECTANGLE" : Round corner rectangle shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'roundRect'
  /// - "ELLIPSE" : Ellipse shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'ellipse'
  /// - "ARC" : Curved arc shape. Corresponds to ECMA-376 ST_ShapeType 'arc'
  /// - "BENT_ARROW" : Bent arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'bentArrow'
  /// - "BENT_UP_ARROW" : Bent up arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'bentUpArrow'
  /// - "BEVEL" : Bevel shape. Corresponds to ECMA-376 ST_ShapeType 'bevel'
  /// - "BLOCK_ARC" : Block arc shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'blockArc'
  /// - "BRACE_PAIR" : Brace pair shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'bracePair'
  /// - "BRACKET_PAIR" : Bracket pair shape. Corresponds to ECMA-376
  /// ST_ShapeType 'bracketPair'
  /// - "CAN" : Can shape. Corresponds to ECMA-376 ST_ShapeType 'can'
  /// - "CHEVRON" : Chevron shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'chevron'
  /// - "CHORD" : Chord shape. Corresponds to ECMA-376 ST_ShapeType 'chord'
  /// - "CLOUD" : Cloud shape. Corresponds to ECMA-376 ST_ShapeType 'cloud'
  /// - "CORNER" : Corner shape. Corresponds to ECMA-376 ST_ShapeType 'corner'
  /// - "CUBE" : Cube shape. Corresponds to ECMA-376 ST_ShapeType 'cube'
  /// - "CURVED_DOWN_ARROW" : Curved down arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'curvedDownArrow'
  /// - "CURVED_LEFT_ARROW" : Curved left arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'curvedLeftArrow'
  /// - "CURVED_RIGHT_ARROW" : Curved right arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'curvedRightArrow'
  /// - "CURVED_UP_ARROW" : Curved up arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'curvedUpArrow'
  /// - "DECAGON" : Decagon shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'decagon'
  /// - "DIAGONAL_STRIPE" : Diagonal stripe shape. Corresponds to ECMA-376
  /// ST_ShapeType 'diagStripe'
  /// - "DIAMOND" : Diamond shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'diamond'
  /// - "DODECAGON" : Dodecagon shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'dodecagon'
  /// - "DONUT" : Donut shape. Corresponds to ECMA-376 ST_ShapeType 'donut'
  /// - "DOUBLE_WAVE" : Double wave shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'doubleWave'
  /// - "DOWN_ARROW" : Down arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'downArrow'
  /// - "DOWN_ARROW_CALLOUT" : Callout down arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'downArrowCallout'
  /// - "FOLDED_CORNER" : Folded corner shape. Corresponds to ECMA-376
  /// ST_ShapeType 'foldedCorner'
  /// - "FRAME" : Frame shape. Corresponds to ECMA-376 ST_ShapeType 'frame'
  /// - "HALF_FRAME" : Half frame shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'halfFrame'
  /// - "HEART" : Heart shape. Corresponds to ECMA-376 ST_ShapeType 'heart'
  /// - "HEPTAGON" : Heptagon shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'heptagon'
  /// - "HEXAGON" : Hexagon shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'hexagon'
  /// - "HOME_PLATE" : Home plate shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'homePlate'
  /// - "HORIZONTAL_SCROLL" : Horizontal scroll shape. Corresponds to ECMA-376
  /// ST_ShapeType 'horizontalScroll'
  /// - "IRREGULAR_SEAL_1" : Irregular seal 1 shape. Corresponds to ECMA-376
  /// ST_ShapeType 'irregularSeal1'
  /// - "IRREGULAR_SEAL_2" : Irregular seal 2 shape. Corresponds to ECMA-376
  /// ST_ShapeType 'irregularSeal2'
  /// - "LEFT_ARROW" : Left arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'leftArrow'
  /// - "LEFT_ARROW_CALLOUT" : Callout left arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'leftArrowCallout'
  /// - "LEFT_BRACE" : Left brace shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'leftBrace'
  /// - "LEFT_BRACKET" : Left bracket shape. Corresponds to ECMA-376
  /// ST_ShapeType 'leftBracket'
  /// - "LEFT_RIGHT_ARROW" : Left right arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'leftRightArrow'
  /// - "LEFT_RIGHT_ARROW_CALLOUT" : Callout left right arrow shape. Corresponds
  /// to ECMA-376 ST_ShapeType 'leftRightArrowCallout'
  /// - "LEFT_RIGHT_UP_ARROW" : Left right up arrow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'leftRightUpArrow'
  /// - "LEFT_UP_ARROW" : Left up arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'leftUpArrow'
  /// - "LIGHTNING_BOLT" : Lightning bolt shape. Corresponds to ECMA-376
  /// ST_ShapeType 'lightningBolt'
  /// - "MATH_DIVIDE" : Divide math shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'mathDivide'
  /// - "MATH_EQUAL" : Equal math shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'mathEqual'
  /// - "MATH_MINUS" : Minus math shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'mathMinus'
  /// - "MATH_MULTIPLY" : Multiply math shape. Corresponds to ECMA-376
  /// ST_ShapeType 'mathMultiply'
  /// - "MATH_NOT_EQUAL" : Not equal math shape. Corresponds to ECMA-376
  /// ST_ShapeType 'mathNotEqual'
  /// - "MATH_PLUS" : Plus math shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'mathPlus'
  /// - "MOON" : Moon shape. Corresponds to ECMA-376 ST_ShapeType 'moon'
  /// - "NO_SMOKING" : No smoking shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'noSmoking'
  /// - "NOTCHED_RIGHT_ARROW" : Notched right arrow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'notchedRightArrow'
  /// - "OCTAGON" : Octagon shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'octagon'
  /// - "PARALLELOGRAM" : Parallelogram shape. Corresponds to ECMA-376
  /// ST_ShapeType 'parallelogram'
  /// - "PENTAGON" : Pentagon shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'pentagon'
  /// - "PIE" : Pie shape. Corresponds to ECMA-376 ST_ShapeType 'pie'
  /// - "PLAQUE" : Plaque shape. Corresponds to ECMA-376 ST_ShapeType 'plaque'
  /// - "PLUS" : Plus shape. Corresponds to ECMA-376 ST_ShapeType 'plus'
  /// - "QUAD_ARROW" : Quad-arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'quadArrow'
  /// - "QUAD_ARROW_CALLOUT" : Callout quad-arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'quadArrowCallout'
  /// - "RIBBON" : Ribbon shape. Corresponds to ECMA-376 ST_ShapeType 'ribbon'
  /// - "RIBBON_2" : Ribbon 2 shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'ribbon2'
  /// - "RIGHT_ARROW" : Right arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'rightArrow'
  /// - "RIGHT_ARROW_CALLOUT" : Callout right arrow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'rightArrowCallout'
  /// - "RIGHT_BRACE" : Right brace shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'rightBrace'
  /// - "RIGHT_BRACKET" : Right bracket shape. Corresponds to ECMA-376
  /// ST_ShapeType 'rightBracket'
  /// - "ROUND_1_RECTANGLE" : One round corner rectangle shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'round1Rect'
  /// - "ROUND_2_DIAGONAL_RECTANGLE" : Two diagonal round corner rectangle
  /// shape. Corresponds to ECMA-376 ST_ShapeType 'round2DiagRect'
  /// - "ROUND_2_SAME_RECTANGLE" : Two same-side round corner rectangle shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'round2SameRect'
  /// - "RIGHT_TRIANGLE" : Right triangle shape. Corresponds to ECMA-376
  /// ST_ShapeType 'rtTriangle'
  /// - "SMILEY_FACE" : Smiley face shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'smileyFace'
  /// - "SNIP_1_RECTANGLE" : One snip corner rectangle shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'snip1Rect'
  /// - "SNIP_2_DIAGONAL_RECTANGLE" : Two diagonal snip corner rectangle shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'snip2DiagRect'
  /// - "SNIP_2_SAME_RECTANGLE" : Two same-side snip corner rectangle shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'snip2SameRect'
  /// - "SNIP_ROUND_RECTANGLE" : One snip one round corner rectangle shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'snipRoundRect'
  /// - "STAR_10" : Ten pointed star shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'star10'
  /// - "STAR_12" : Twelve pointed star shape. Corresponds to ECMA-376
  /// ST_ShapeType 'star12'
  /// - "STAR_16" : Sixteen pointed star shape. Corresponds to ECMA-376
  /// ST_ShapeType 'star16'
  /// - "STAR_24" : Twenty four pointed star shape. Corresponds to ECMA-376
  /// ST_ShapeType 'star24'
  /// - "STAR_32" : Thirty two pointed star shape. Corresponds to ECMA-376
  /// ST_ShapeType 'star32'
  /// - "STAR_4" : Four pointed star shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'star4'
  /// - "STAR_5" : Five pointed star shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'star5'
  /// - "STAR_6" : Six pointed star shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'star6'
  /// - "STAR_7" : Seven pointed star shape. Corresponds to ECMA-376
  /// ST_ShapeType 'star7'
  /// - "STAR_8" : Eight pointed star shape. Corresponds to ECMA-376
  /// ST_ShapeType 'star8'
  /// - "STRIPED_RIGHT_ARROW" : Striped right arrow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'stripedRightArrow'
  /// - "SUN" : Sun shape. Corresponds to ECMA-376 ST_ShapeType 'sun'
  /// - "TRAPEZOID" : Trapezoid shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'trapezoid'
  /// - "TRIANGLE" : Triangle shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'triangle'
  /// - "UP_ARROW" : Up arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'upArrow'
  /// - "UP_ARROW_CALLOUT" : Callout up arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'upArrowCallout'
  /// - "UP_DOWN_ARROW" : Up down arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'upDownArrow'
  /// - "UTURN_ARROW" : U-turn arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'uturnArrow'
  /// - "VERTICAL_SCROLL" : Vertical scroll shape. Corresponds to ECMA-376
  /// ST_ShapeType 'verticalScroll'
  /// - "WAVE" : Wave shape. Corresponds to ECMA-376 ST_ShapeType 'wave'
  /// - "WEDGE_ELLIPSE_CALLOUT" : Callout wedge ellipse shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'wedgeEllipseCallout'
  /// - "WEDGE_RECTANGLE_CALLOUT" : Callout wedge rectangle shape. Corresponds
  /// to ECMA-376 ST_ShapeType 'wedgeRectCallout'
  /// - "WEDGE_ROUND_RECTANGLE_CALLOUT" : Callout wedge round rectangle shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'wedgeRoundRectCallout'
  /// - "FLOW_CHART_ALTERNATE_PROCESS" : Alternate process flow shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'flowChartAlternateProcess'
  /// - "FLOW_CHART_COLLATE" : Collate flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartCollate'
  /// - "FLOW_CHART_CONNECTOR" : Connector flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartConnector'
  /// - "FLOW_CHART_DECISION" : Decision flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartDecision'
  /// - "FLOW_CHART_DELAY" : Delay flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartDelay'
  /// - "FLOW_CHART_DISPLAY" : Display flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartDisplay'
  /// - "FLOW_CHART_DOCUMENT" : Document flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartDocument'
  /// - "FLOW_CHART_EXTRACT" : Extract flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartExtract'
  /// - "FLOW_CHART_INPUT_OUTPUT" : Input output flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartInputOutput'
  /// - "FLOW_CHART_INTERNAL_STORAGE" : Internal storage flow shape. Corresponds
  /// to ECMA-376 ST_ShapeType 'flowChartInternalStorage'
  /// - "FLOW_CHART_MAGNETIC_DISK" : Magnetic disk flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartMagneticDisk'
  /// - "FLOW_CHART_MAGNETIC_DRUM" : Magnetic drum flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartMagneticDrum'
  /// - "FLOW_CHART_MAGNETIC_TAPE" : Magnetic tape flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartMagneticTape'
  /// - "FLOW_CHART_MANUAL_INPUT" : Manual input flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartManualInput'
  /// - "FLOW_CHART_MANUAL_OPERATION" : Manual operation flow shape. Corresponds
  /// to ECMA-376 ST_ShapeType 'flowChartManualOperation'
  /// - "FLOW_CHART_MERGE" : Merge flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartMerge'
  /// - "FLOW_CHART_MULTIDOCUMENT" : Multi-document flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartMultidocument'
  /// - "FLOW_CHART_OFFLINE_STORAGE" : Offline storage flow shape. Corresponds
  /// to ECMA-376 ST_ShapeType 'flowChartOfflineStorage'
  /// - "FLOW_CHART_OFFPAGE_CONNECTOR" : Off-page connector flow shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'flowChartOffpageConnector'
  /// - "FLOW_CHART_ONLINE_STORAGE" : Online storage flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartOnlineStorage'
  /// - "FLOW_CHART_OR" : Or flow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'flowChartOr'
  /// - "FLOW_CHART_PREDEFINED_PROCESS" : Predefined process flow shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'flowChartPredefinedProcess'
  /// - "FLOW_CHART_PREPARATION" : Preparation flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartPreparation'
  /// - "FLOW_CHART_PROCESS" : Process flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartProcess'
  /// - "FLOW_CHART_PUNCHED_CARD" : Punched card flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartPunchedCard'
  /// - "FLOW_CHART_PUNCHED_TAPE" : Punched tape flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartPunchedTape'
  /// - "FLOW_CHART_SORT" : Sort flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartSort'
  /// - "FLOW_CHART_SUMMING_JUNCTION" : Summing junction flow shape. Corresponds
  /// to ECMA-376 ST_ShapeType 'flowChartSummingJunction'
  /// - "FLOW_CHART_TERMINATOR" : Terminator flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartTerminator'
  /// - "ARROW_EAST" : East arrow shape.
  /// - "ARROW_NORTH_EAST" : Northeast arrow shape.
  /// - "ARROW_NORTH" : North arrow shape.
  /// - "SPEECH" : Speech shape.
  /// - "STARBURST" : Star burst shape.
  /// - "TEARDROP" : Teardrop shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'teardrop'
  /// - "ELLIPSE_RIBBON" : Ellipse ribbon shape. Corresponds to ECMA-376
  /// ST_ShapeType 'ellipseRibbon'
  /// - "ELLIPSE_RIBBON_2" : Ellipse ribbon 2 shape. Corresponds to ECMA-376
  /// ST_ShapeType 'ellipseRibbon2'
  /// - "CLOUD_CALLOUT" : Callout cloud shape. Corresponds to ECMA-376
  /// ST_ShapeType 'cloudCallout'
  /// - "CUSTOM" : Custom shape.
  core.String? shapeType;

  CreateShapeRequest();

  CreateShapeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('elementProperties')) {
      elementProperties = PageElementProperties.fromJson(
          _json['elementProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('shapeType')) {
      shapeType = _json['shapeType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (elementProperties != null)
          'elementProperties': elementProperties!.toJson(),
        if (objectId != null) 'objectId': objectId!,
        if (shapeType != null) 'shapeType': shapeType!,
      };
}

/// The result of creating a shape.
class CreateShapeResponse {
  /// The object ID of the created shape.
  core.String? objectId;

  CreateShapeResponse();

  CreateShapeResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Creates an embedded Google Sheets chart.
///
/// NOTE: Chart creation requires at least one of the spreadsheets.readonly,
/// spreadsheets, drive.readonly, drive.file, or drive OAuth scopes.
class CreateSheetsChartRequest {
  /// The ID of the specific chart in the Google Sheets spreadsheet.
  core.int? chartId;

  /// The element properties for the chart.
  ///
  /// When the aspect ratio of the provided size does not match the chart aspect
  /// ratio, the chart is scaled and centered with respect to the size in order
  /// to maintain aspect ratio. The provided transform is applied after this
  /// operation.
  PageElementProperties? elementProperties;

  /// The mode with which the chart is linked to the source spreadsheet.
  ///
  /// When not specified, the chart will be an image that is not linked.
  /// Possible string values are:
  /// - "NOT_LINKED_IMAGE" : The chart is not associated with the source
  /// spreadsheet and cannot be updated. A chart that is not linked will be
  /// inserted as an image.
  /// - "LINKED" : Linking the chart allows it to be updated, and other
  /// collaborators will see a link to the spreadsheet.
  core.String? linkingMode;

  /// A user-supplied object ID.
  ///
  /// If specified, the ID must be unique among all pages and page elements in
  /// the presentation. The ID should start with a word character \[a-zA-Z0-9_\]
  /// and then followed by any number of the following characters
  /// \[a-zA-Z0-9_-:\]. The length of the ID should not be less than 5 or
  /// greater than 50. If empty, a unique identifier will be generated.
  core.String? objectId;

  /// The ID of the Google Sheets spreadsheet that contains the chart.
  core.String? spreadsheetId;

  CreateSheetsChartRequest();

  CreateSheetsChartRequest.fromJson(core.Map _json) {
    if (_json.containsKey('chartId')) {
      chartId = _json['chartId'] as core.int;
    }
    if (_json.containsKey('elementProperties')) {
      elementProperties = PageElementProperties.fromJson(
          _json['elementProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('linkingMode')) {
      linkingMode = _json['linkingMode'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chartId != null) 'chartId': chartId!,
        if (elementProperties != null)
          'elementProperties': elementProperties!.toJson(),
        if (linkingMode != null) 'linkingMode': linkingMode!,
        if (objectId != null) 'objectId': objectId!,
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
      };
}

/// The result of creating an embedded Google Sheets chart.
class CreateSheetsChartResponse {
  /// The object ID of the created chart.
  core.String? objectId;

  CreateSheetsChartResponse();

  CreateSheetsChartResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Creates a new slide.
class CreateSlideRequest {
  /// The optional zero-based index indicating where to insert the slides.
  ///
  /// If you don't specify an index, the new slide is created at the end.
  core.int? insertionIndex;

  /// A user-supplied object ID.
  ///
  /// If you specify an ID, it must be unique among all pages and page elements
  /// in the presentation. The ID must start with an alphanumeric character or
  /// an underscore (matches regex `[a-zA-Z0-9_]`); remaining characters may
  /// include those as well as a hyphen or colon (matches regex
  /// `[a-zA-Z0-9_-:]`). The length of the ID must not be less than 5 or greater
  /// than 50. If you don't specify an ID, a unique one is generated.
  core.String? objectId;

  /// An optional list of object ID mappings from the placeholder(s) on the
  /// layout to the placeholder(s) that will be created on the new slide from
  /// that specified layout.
  ///
  /// Can only be used when `slide_layout_reference` is specified.
  core.List<LayoutPlaceholderIdMapping>? placeholderIdMappings;

  /// Layout reference of the slide to be inserted, based on the *current
  /// master*, which is one of the following: - The master of the previous slide
  /// index.
  ///
  /// - The master of the first slide, if the insertion_index is zero. - The
  /// first master in the presentation, if there are no slides. If the
  /// LayoutReference is not found in the current master, a 400 bad request
  /// error is returned. If you don't specify a layout reference, then the new
  /// slide will use the predefined layout `BLANK`.
  LayoutReference? slideLayoutReference;

  CreateSlideRequest();

  CreateSlideRequest.fromJson(core.Map _json) {
    if (_json.containsKey('insertionIndex')) {
      insertionIndex = _json['insertionIndex'] as core.int;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('placeholderIdMappings')) {
      placeholderIdMappings = (_json['placeholderIdMappings'] as core.List)
          .map<LayoutPlaceholderIdMapping>((value) =>
              LayoutPlaceholderIdMapping.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('slideLayoutReference')) {
      slideLayoutReference = LayoutReference.fromJson(
          _json['slideLayoutReference'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (insertionIndex != null) 'insertionIndex': insertionIndex!,
        if (objectId != null) 'objectId': objectId!,
        if (placeholderIdMappings != null)
          'placeholderIdMappings':
              placeholderIdMappings!.map((value) => value.toJson()).toList(),
        if (slideLayoutReference != null)
          'slideLayoutReference': slideLayoutReference!.toJson(),
      };
}

/// The result of creating a slide.
class CreateSlideResponse {
  /// The object ID of the created slide.
  core.String? objectId;

  CreateSlideResponse();

  CreateSlideResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Creates a new table.
class CreateTableRequest {
  /// Number of columns in the table.
  core.int? columns;

  /// The element properties for the table.
  ///
  /// The table will be created at the provided size, subject to a minimum size.
  /// If no size is provided, the table will be automatically sized. Table
  /// transforms must have a scale of 1 and no shear components. If no transform
  /// is provided, the table will be centered on the page.
  PageElementProperties? elementProperties;

  /// A user-supplied object ID.
  ///
  /// If you specify an ID, it must be unique among all pages and page elements
  /// in the presentation. The ID must start with an alphanumeric character or
  /// an underscore (matches regex `[a-zA-Z0-9_]`); remaining characters may
  /// include those as well as a hyphen or colon (matches regex
  /// `[a-zA-Z0-9_-:]`). The length of the ID must not be less than 5 or greater
  /// than 50. If you don't specify an ID, a unique one is generated.
  core.String? objectId;

  /// Number of rows in the table.
  core.int? rows;

  CreateTableRequest();

  CreateTableRequest.fromJson(core.Map _json) {
    if (_json.containsKey('columns')) {
      columns = _json['columns'] as core.int;
    }
    if (_json.containsKey('elementProperties')) {
      elementProperties = PageElementProperties.fromJson(
          _json['elementProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('rows')) {
      rows = _json['rows'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columns != null) 'columns': columns!,
        if (elementProperties != null)
          'elementProperties': elementProperties!.toJson(),
        if (objectId != null) 'objectId': objectId!,
        if (rows != null) 'rows': rows!,
      };
}

/// The result of creating a table.
class CreateTableResponse {
  /// The object ID of the created table.
  core.String? objectId;

  CreateTableResponse();

  CreateTableResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Creates a video.
///
/// NOTE: Creating a video from Google Drive requires that the requesting app
/// have at least one of the drive, drive.readonly, or drive.file OAuth scopes.
class CreateVideoRequest {
  /// The element properties for the video.
  ///
  /// The PageElementProperties.size property is optional. If you don't specify
  /// a size, a default size is chosen by the server. The
  /// PageElementProperties.transform property is optional. The transform must
  /// not have shear components. If you don't specify a transform, the video
  /// will be placed at the top left corner of the page.
  PageElementProperties? elementProperties;

  /// The video source's unique identifier for this video.
  ///
  /// e.g. For YouTube video https://www.youtube.com/watch?v=7U3axjORYZ0, the ID
  /// is 7U3axjORYZ0. For a Google Drive video
  /// https://drive.google.com/file/d/1xCgQLFTJi5_Xl8DgW_lcUYq5e-q6Hi5Q the ID
  /// is 1xCgQLFTJi5_Xl8DgW_lcUYq5e-q6Hi5Q.
  core.String? id;

  /// A user-supplied object ID.
  ///
  /// If you specify an ID, it must be unique among all pages and page elements
  /// in the presentation. The ID must start with an alphanumeric character or
  /// an underscore (matches regex `[a-zA-Z0-9_]`); remaining characters may
  /// include those as well as a hyphen or colon (matches regex
  /// `[a-zA-Z0-9_-:]`). The length of the ID must not be less than 5 or greater
  /// than 50. If you don't specify an ID, a unique one is generated.
  core.String? objectId;

  /// The video source.
  /// Possible string values are:
  /// - "SOURCE_UNSPECIFIED" : The video source is unspecified.
  /// - "YOUTUBE" : The video source is YouTube.
  /// - "DRIVE" : The video source is Google Drive.
  core.String? source;

  CreateVideoRequest();

  CreateVideoRequest.fromJson(core.Map _json) {
    if (_json.containsKey('elementProperties')) {
      elementProperties = PageElementProperties.fromJson(
          _json['elementProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (elementProperties != null)
          'elementProperties': elementProperties!.toJson(),
        if (id != null) 'id': id!,
        if (objectId != null) 'objectId': objectId!,
        if (source != null) 'source': source!,
      };
}

/// The result of creating a video.
class CreateVideoResponse {
  /// The object ID of the created video.
  core.String? objectId;

  CreateVideoResponse();

  CreateVideoResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// The crop properties of an object enclosed in a container.
///
/// For example, an Image. The crop properties is represented by the offsets of
/// four edges which define a crop rectangle. The offsets are measured in
/// percentage from the corresponding edges of the object's original bounding
/// rectangle towards inside, relative to the object's original dimensions. - If
/// the offset is in the interval (0, 1), the corresponding edge of crop
/// rectangle is positioned inside of the object's original bounding rectangle.
/// - If the offset is negative or greater than 1, the corresponding edge of
/// crop rectangle is positioned outside of the object's original bounding
/// rectangle. - If the left edge of the crop rectangle is on the right side of
/// its right edge, the object will be flipped horizontally. - If the top edge
/// of the crop rectangle is below its bottom edge, the object will be flipped
/// vertically. - If all offsets and rotation angle is 0, the object is not
/// cropped. After cropping, the content in the crop rectangle will be stretched
/// to fit its container.
class CropProperties {
  /// The rotation angle of the crop window around its center, in radians.
  ///
  /// Rotation angle is applied after the offset.
  core.double? angle;

  /// The offset specifies the bottom edge of the crop rectangle that is located
  /// above the original bounding rectangle bottom edge, relative to the
  /// object's original height.
  core.double? bottomOffset;

  /// The offset specifies the left edge of the crop rectangle that is located
  /// to the right of the original bounding rectangle left edge, relative to the
  /// object's original width.
  core.double? leftOffset;

  /// The offset specifies the right edge of the crop rectangle that is located
  /// to the left of the original bounding rectangle right edge, relative to the
  /// object's original width.
  core.double? rightOffset;

  /// The offset specifies the top edge of the crop rectangle that is located
  /// below the original bounding rectangle top edge, relative to the object's
  /// original height.
  core.double? topOffset;

  CropProperties();

  CropProperties.fromJson(core.Map _json) {
    if (_json.containsKey('angle')) {
      angle = (_json['angle'] as core.num).toDouble();
    }
    if (_json.containsKey('bottomOffset')) {
      bottomOffset = (_json['bottomOffset'] as core.num).toDouble();
    }
    if (_json.containsKey('leftOffset')) {
      leftOffset = (_json['leftOffset'] as core.num).toDouble();
    }
    if (_json.containsKey('rightOffset')) {
      rightOffset = (_json['rightOffset'] as core.num).toDouble();
    }
    if (_json.containsKey('topOffset')) {
      topOffset = (_json['topOffset'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (angle != null) 'angle': angle!,
        if (bottomOffset != null) 'bottomOffset': bottomOffset!,
        if (leftOffset != null) 'leftOffset': leftOffset!,
        if (rightOffset != null) 'rightOffset': rightOffset!,
        if (topOffset != null) 'topOffset': topOffset!,
      };
}

/// Deletes an object, either pages or page elements, from the presentation.
class DeleteObjectRequest {
  /// The object ID of the page or page element to delete.
  ///
  /// If after a delete operation a group contains only 1 or no page elements,
  /// the group is also deleted. If a placeholder is deleted on a layout, any
  /// empty inheriting shapes are also deleted.
  core.String? objectId;

  DeleteObjectRequest();

  DeleteObjectRequest.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Deletes bullets from all of the paragraphs that overlap with the given text
/// index range.
///
/// The nesting level of each paragraph will be visually preserved by adding
/// indent to the start of the corresponding paragraph.
class DeleteParagraphBulletsRequest {
  /// The optional table cell location if the text to be modified is in a table
  /// cell.
  ///
  /// If present, the object_id must refer to a table.
  TableCellLocation? cellLocation;

  /// The object ID of the shape or table containing the text to delete bullets
  /// from.
  core.String? objectId;

  /// The range of text to delete bullets from, based on TextElement indexes.
  Range? textRange;

  DeleteParagraphBulletsRequest();

  DeleteParagraphBulletsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cellLocation')) {
      cellLocation = TableCellLocation.fromJson(
          _json['cellLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('textRange')) {
      textRange = Range.fromJson(
          _json['textRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cellLocation != null) 'cellLocation': cellLocation!.toJson(),
        if (objectId != null) 'objectId': objectId!,
        if (textRange != null) 'textRange': textRange!.toJson(),
      };
}

/// Deletes a column from a table.
class DeleteTableColumnRequest {
  /// The reference table cell location from which a column will be deleted.
  ///
  /// The column this cell spans will be deleted. If this is a merged cell,
  /// multiple columns will be deleted. If no columns remain in the table after
  /// this deletion, the whole table is deleted.
  TableCellLocation? cellLocation;

  /// The table to delete columns from.
  core.String? tableObjectId;

  DeleteTableColumnRequest();

  DeleteTableColumnRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cellLocation')) {
      cellLocation = TableCellLocation.fromJson(
          _json['cellLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableObjectId')) {
      tableObjectId = _json['tableObjectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cellLocation != null) 'cellLocation': cellLocation!.toJson(),
        if (tableObjectId != null) 'tableObjectId': tableObjectId!,
      };
}

/// Deletes a row from a table.
class DeleteTableRowRequest {
  /// The reference table cell location from which a row will be deleted.
  ///
  /// The row this cell spans will be deleted. If this is a merged cell,
  /// multiple rows will be deleted. If no rows remain in the table after this
  /// deletion, the whole table is deleted.
  TableCellLocation? cellLocation;

  /// The table to delete rows from.
  core.String? tableObjectId;

  DeleteTableRowRequest();

  DeleteTableRowRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cellLocation')) {
      cellLocation = TableCellLocation.fromJson(
          _json['cellLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableObjectId')) {
      tableObjectId = _json['tableObjectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cellLocation != null) 'cellLocation': cellLocation!.toJson(),
        if (tableObjectId != null) 'tableObjectId': tableObjectId!,
      };
}

/// Deletes text from a shape or a table cell.
class DeleteTextRequest {
  /// The optional table cell location if the text is to be deleted from a table
  /// cell.
  ///
  /// If present, the object_id must refer to a table.
  TableCellLocation? cellLocation;

  /// The object ID of the shape or table from which the text will be deleted.
  core.String? objectId;

  /// The range of text to delete, based on TextElement indexes.
  ///
  /// There is always an implicit newline character at the end of a shape's or
  /// table cell's text that cannot be deleted. `Range.Type.ALL` will use the
  /// correct bounds, but care must be taken when specifying explicit bounds for
  /// range types `FROM_START_INDEX` and `FIXED_RANGE`. For example, if the text
  /// is "ABC", followed by an implicit newline, then the maximum value is 2 for
  /// `text_range.start_index` and 3 for `text_range.end_index`. Deleting text
  /// that crosses a paragraph boundary may result in changes to paragraph
  /// styles and lists as the two paragraphs are merged. Ranges that include
  /// only one code unit of a surrogate pair are expanded to include both code
  /// units.
  Range? textRange;

  DeleteTextRequest();

  DeleteTextRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cellLocation')) {
      cellLocation = TableCellLocation.fromJson(
          _json['cellLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('textRange')) {
      textRange = Range.fromJson(
          _json['textRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cellLocation != null) 'cellLocation': cellLocation!.toJson(),
        if (objectId != null) 'objectId': objectId!,
        if (textRange != null) 'textRange': textRange!.toJson(),
      };
}

/// A magnitude in a single direction in the specified units.
class Dimension {
  /// The magnitude.
  core.double? magnitude;

  /// The units for magnitude.
  /// Possible string values are:
  /// - "UNIT_UNSPECIFIED" : The units are unknown.
  /// - "EMU" : An English Metric Unit (EMU) is defined as 1/360,000 of a
  /// centimeter and thus there are 914,400 EMUs per inch, and 12,700 EMUs per
  /// point.
  /// - "PT" : A point, 1/72 of an inch.
  core.String? unit;

  Dimension();

  Dimension.fromJson(core.Map _json) {
    if (_json.containsKey('magnitude')) {
      magnitude = (_json['magnitude'] as core.num).toDouble();
    }
    if (_json.containsKey('unit')) {
      unit = _json['unit'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (magnitude != null) 'magnitude': magnitude!,
        if (unit != null) 'unit': unit!,
      };
}

/// Duplicates a slide or page element.
///
/// When duplicating a slide, the duplicate slide will be created immediately
/// following the specified slide. When duplicating a page element, the
/// duplicate will be placed on the same page at the same position as the
/// original.
class DuplicateObjectRequest {
  /// The ID of the object to duplicate.
  core.String? objectId;

  /// The object being duplicated may contain other objects, for example when
  /// duplicating a slide or a group page element.
  ///
  /// This map defines how the IDs of duplicated objects are generated: the keys
  /// are the IDs of the original objects and its values are the IDs that will
  /// be assigned to the corresponding duplicate object. The ID of the source
  /// object's duplicate may be specified in this map as well, using the same
  /// value of the `object_id` field as a key and the newly desired ID as the
  /// value. All keys must correspond to existing IDs in the presentation. All
  /// values must be unique in the presentation and must start with an
  /// alphanumeric character or an underscore (matches regex `[a-zA-Z0-9_]`);
  /// remaining characters may include those as well as a hyphen or colon
  /// (matches regex `[a-zA-Z0-9_-:]`). The length of the new ID must not be
  /// less than 5 or greater than 50. If any IDs of source objects are omitted
  /// from the map, a new random ID will be assigned. If the map is empty or
  /// unset, all duplicate objects will receive a new random ID.
  core.Map<core.String, core.String>? objectIds;

  DuplicateObjectRequest();

  DuplicateObjectRequest.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('objectIds')) {
      objectIds =
          (_json['objectIds'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
        if (objectIds != null) 'objectIds': objectIds!,
      };
}

/// The response of duplicating an object.
class DuplicateObjectResponse {
  /// The ID of the new duplicate object.
  core.String? objectId;

  DuplicateObjectResponse();

  DuplicateObjectResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// A PageElement kind representing a joined collection of PageElements.
class Group {
  /// The collection of elements in the group.
  ///
  /// The minimum size of a group is 2.
  core.List<PageElement>? children;

  Group();

  Group.fromJson(core.Map _json) {
    if (_json.containsKey('children')) {
      children = (_json['children'] as core.List)
          .map<PageElement>((value) => PageElement.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (children != null)
          'children': children!.map((value) => value.toJson()).toList(),
      };
}

/// Groups objects to create an object group.
///
/// For example, groups PageElements to create a Group on the same page as all
/// the children.
class GroupObjectsRequest {
  /// The object IDs of the objects to group.
  ///
  /// Only page elements can be grouped. There should be at least two page
  /// elements on the same page that are not already in another group. Some page
  /// elements, such as videos, tables and placeholder shapes cannot be grouped.
  core.List<core.String>? childrenObjectIds;

  /// A user-supplied object ID for the group to be created.
  ///
  /// If you specify an ID, it must be unique among all pages and page elements
  /// in the presentation. The ID must start with an alphanumeric character or
  /// an underscore (matches regex `[a-zA-Z0-9_]`); remaining characters may
  /// include those as well as a hyphen or colon (matches regex
  /// `[a-zA-Z0-9_-:]`). The length of the ID must not be less than 5 or greater
  /// than 50. If you don't specify an ID, a unique one is generated.
  core.String? groupObjectId;

  GroupObjectsRequest();

  GroupObjectsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('childrenObjectIds')) {
      childrenObjectIds = (_json['childrenObjectIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('groupObjectId')) {
      groupObjectId = _json['groupObjectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (childrenObjectIds != null) 'childrenObjectIds': childrenObjectIds!,
        if (groupObjectId != null) 'groupObjectId': groupObjectId!,
      };
}

/// The result of grouping objects.
class GroupObjectsResponse {
  /// The object ID of the created group.
  core.String? objectId;

  GroupObjectsResponse();

  GroupObjectsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// A PageElement kind representing an image.
class Image {
  /// An URL to an image with a default lifetime of 30 minutes.
  ///
  /// This URL is tagged with the account of the requester. Anyone with the URL
  /// effectively accesses the image as the original requester. Access to the
  /// image may be lost if the presentation's sharing settings change.
  core.String? contentUrl;

  /// The properties of the image.
  ImageProperties? imageProperties;

  /// The source URL is the URL used to insert the image.
  ///
  /// The source URL can be empty.
  core.String? sourceUrl;

  Image();

  Image.fromJson(core.Map _json) {
    if (_json.containsKey('contentUrl')) {
      contentUrl = _json['contentUrl'] as core.String;
    }
    if (_json.containsKey('imageProperties')) {
      imageProperties = ImageProperties.fromJson(
          _json['imageProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sourceUrl')) {
      sourceUrl = _json['sourceUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentUrl != null) 'contentUrl': contentUrl!,
        if (imageProperties != null)
          'imageProperties': imageProperties!.toJson(),
        if (sourceUrl != null) 'sourceUrl': sourceUrl!,
      };
}

/// The properties of the Image.
class ImageProperties {
  /// The brightness effect of the image.
  ///
  /// The value should be in the interval \[-1.0, 1.0\], where 0 means no
  /// effect. This property is read-only.
  core.double? brightness;

  /// The contrast effect of the image.
  ///
  /// The value should be in the interval \[-1.0, 1.0\], where 0 means no
  /// effect. This property is read-only.
  core.double? contrast;

  /// The crop properties of the image.
  ///
  /// If not set, the image is not cropped. This property is read-only.
  CropProperties? cropProperties;

  /// The hyperlink destination of the image.
  ///
  /// If unset, there is no link.
  Link? link;

  /// The outline of the image.
  ///
  /// If not set, the image has no outline.
  Outline? outline;

  /// The recolor effect of the image.
  ///
  /// If not set, the image is not recolored. This property is read-only.
  Recolor? recolor;

  /// The shadow of the image.
  ///
  /// If not set, the image has no shadow. This property is read-only.
  Shadow? shadow;

  /// The transparency effect of the image.
  ///
  /// The value should be in the interval \[0.0, 1.0\], where 0 means no effect
  /// and 1 means completely transparent. This property is read-only.
  core.double? transparency;

  ImageProperties();

  ImageProperties.fromJson(core.Map _json) {
    if (_json.containsKey('brightness')) {
      brightness = (_json['brightness'] as core.num).toDouble();
    }
    if (_json.containsKey('contrast')) {
      contrast = (_json['contrast'] as core.num).toDouble();
    }
    if (_json.containsKey('cropProperties')) {
      cropProperties = CropProperties.fromJson(
          _json['cropProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('link')) {
      link =
          Link.fromJson(_json['link'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('outline')) {
      outline = Outline.fromJson(
          _json['outline'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('recolor')) {
      recolor = Recolor.fromJson(
          _json['recolor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shadow')) {
      shadow = Shadow.fromJson(
          _json['shadow'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transparency')) {
      transparency = (_json['transparency'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (brightness != null) 'brightness': brightness!,
        if (contrast != null) 'contrast': contrast!,
        if (cropProperties != null) 'cropProperties': cropProperties!.toJson(),
        if (link != null) 'link': link!.toJson(),
        if (outline != null) 'outline': outline!.toJson(),
        if (recolor != null) 'recolor': recolor!.toJson(),
        if (shadow != null) 'shadow': shadow!.toJson(),
        if (transparency != null) 'transparency': transparency!,
      };
}

/// Inserts columns into a table.
///
/// Other columns in the table will be resized to fit the new column.
class InsertTableColumnsRequest {
  /// The reference table cell location from which columns will be inserted.
  ///
  /// A new column will be inserted to the left (or right) of the column where
  /// the reference cell is. If the reference cell is a merged cell, a new
  /// column will be inserted to the left (or right) of the merged cell.
  TableCellLocation? cellLocation;

  /// Whether to insert new columns to the right of the reference cell location.
  ///
  /// - `True`: insert to the right. - `False`: insert to the left.
  core.bool? insertRight;

  /// The number of columns to be inserted.
  ///
  /// Maximum 20 per request.
  core.int? number;

  /// The table to insert columns into.
  core.String? tableObjectId;

  InsertTableColumnsRequest();

  InsertTableColumnsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cellLocation')) {
      cellLocation = TableCellLocation.fromJson(
          _json['cellLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertRight')) {
      insertRight = _json['insertRight'] as core.bool;
    }
    if (_json.containsKey('number')) {
      number = _json['number'] as core.int;
    }
    if (_json.containsKey('tableObjectId')) {
      tableObjectId = _json['tableObjectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cellLocation != null) 'cellLocation': cellLocation!.toJson(),
        if (insertRight != null) 'insertRight': insertRight!,
        if (number != null) 'number': number!,
        if (tableObjectId != null) 'tableObjectId': tableObjectId!,
      };
}

/// Inserts rows into a table.
class InsertTableRowsRequest {
  /// The reference table cell location from which rows will be inserted.
  ///
  /// A new row will be inserted above (or below) the row where the reference
  /// cell is. If the reference cell is a merged cell, a new row will be
  /// inserted above (or below) the merged cell.
  TableCellLocation? cellLocation;

  /// Whether to insert new rows below the reference cell location.
  ///
  /// - `True`: insert below the cell. - `False`: insert above the cell.
  core.bool? insertBelow;

  /// The number of rows to be inserted.
  ///
  /// Maximum 20 per request.
  core.int? number;

  /// The table to insert rows into.
  core.String? tableObjectId;

  InsertTableRowsRequest();

  InsertTableRowsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cellLocation')) {
      cellLocation = TableCellLocation.fromJson(
          _json['cellLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertBelow')) {
      insertBelow = _json['insertBelow'] as core.bool;
    }
    if (_json.containsKey('number')) {
      number = _json['number'] as core.int;
    }
    if (_json.containsKey('tableObjectId')) {
      tableObjectId = _json['tableObjectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cellLocation != null) 'cellLocation': cellLocation!.toJson(),
        if (insertBelow != null) 'insertBelow': insertBelow!,
        if (number != null) 'number': number!,
        if (tableObjectId != null) 'tableObjectId': tableObjectId!,
      };
}

/// Inserts text into a shape or a table cell.
class InsertTextRequest {
  /// The optional table cell location if the text is to be inserted into a
  /// table cell.
  ///
  /// If present, the object_id must refer to a table.
  TableCellLocation? cellLocation;

  /// The index where the text will be inserted, in Unicode code units, based on
  /// TextElement indexes.
  ///
  /// The index is zero-based and is computed from the start of the string. The
  /// index may be adjusted to prevent insertions inside Unicode grapheme
  /// clusters. In these cases, the text will be inserted immediately after the
  /// grapheme cluster.
  core.int? insertionIndex;

  /// The object ID of the shape or table where the text will be inserted.
  core.String? objectId;

  /// The text to be inserted.
  ///
  /// Inserting a newline character will implicitly create a new ParagraphMarker
  /// at that index. The paragraph style of the new paragraph will be copied
  /// from the paragraph at the current insertion index, including lists and
  /// bullets. Text styles for inserted text will be determined automatically,
  /// generally preserving the styling of neighboring text. In most cases, the
  /// text will be added to the TextRun that exists at the insertion index. Some
  /// control characters (U+0000-U+0008, U+000C-U+001F) and characters from the
  /// Unicode Basic Multilingual Plane Private Use Area (U+E000-U+F8FF) will be
  /// stripped out of the inserted text.
  core.String? text;

  InsertTextRequest();

  InsertTextRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cellLocation')) {
      cellLocation = TableCellLocation.fromJson(
          _json['cellLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertionIndex')) {
      insertionIndex = _json['insertionIndex'] as core.int;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cellLocation != null) 'cellLocation': cellLocation!.toJson(),
        if (insertionIndex != null) 'insertionIndex': insertionIndex!,
        if (objectId != null) 'objectId': objectId!,
        if (text != null) 'text': text!,
      };
}

/// The user-specified ID mapping for a placeholder that will be created on a
/// slide from a specified layout.
class LayoutPlaceholderIdMapping {
  /// The placeholder on a layout that will be applied to a slide.
  ///
  /// Only type and index are needed. For example, a predefined `TITLE_AND_BODY`
  /// layout may usually have a TITLE placeholder with index 0 and a BODY
  /// placeholder with index 0.
  Placeholder? layoutPlaceholder;

  /// The object ID of the placeholder on a layout that will be applied to a
  /// slide.
  core.String? layoutPlaceholderObjectId;

  /// A user-supplied object ID for the placeholder identified above that to be
  /// created onto a slide.
  ///
  /// If you specify an ID, it must be unique among all pages and page elements
  /// in the presentation. The ID must start with an alphanumeric character or
  /// an underscore (matches regex `[a-zA-Z0-9_]`); remaining characters may
  /// include those as well as a hyphen or colon (matches regex
  /// `[a-zA-Z0-9_-:]`). The length of the ID must not be less than 5 or greater
  /// than 50. If you don't specify an ID, a unique one is generated.
  core.String? objectId;

  LayoutPlaceholderIdMapping();

  LayoutPlaceholderIdMapping.fromJson(core.Map _json) {
    if (_json.containsKey('layoutPlaceholder')) {
      layoutPlaceholder = Placeholder.fromJson(
          _json['layoutPlaceholder'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('layoutPlaceholderObjectId')) {
      layoutPlaceholderObjectId =
          _json['layoutPlaceholderObjectId'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (layoutPlaceholder != null)
          'layoutPlaceholder': layoutPlaceholder!.toJson(),
        if (layoutPlaceholderObjectId != null)
          'layoutPlaceholderObjectId': layoutPlaceholderObjectId!,
        if (objectId != null) 'objectId': objectId!,
      };
}

/// The properties of Page are only relevant for pages with page_type LAYOUT.
class LayoutProperties {
  /// The human-readable name of the layout.
  core.String? displayName;

  /// The object ID of the master that this layout is based on.
  core.String? masterObjectId;

  /// The name of the layout.
  core.String? name;

  LayoutProperties();

  LayoutProperties.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('masterObjectId')) {
      masterObjectId = _json['masterObjectId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (masterObjectId != null) 'masterObjectId': masterObjectId!,
        if (name != null) 'name': name!,
      };
}

/// Slide layout reference.
///
/// This may reference either: - A predefined layout - One of the layouts in the
/// presentation.
class LayoutReference {
  /// Layout ID: the object ID of one of the layouts in the presentation.
  core.String? layoutId;

  /// Predefined layout.
  /// Possible string values are:
  /// - "PREDEFINED_LAYOUT_UNSPECIFIED" : Unspecified layout.
  /// - "BLANK" : Blank layout, with no placeholders.
  /// - "CAPTION_ONLY" : Layout with a caption at the bottom.
  /// - "TITLE" : Layout with a title and a subtitle.
  /// - "TITLE_AND_BODY" : Layout with a title and body.
  /// - "TITLE_AND_TWO_COLUMNS" : Layout with a title and two columns.
  /// - "TITLE_ONLY" : Layout with only a title.
  /// - "SECTION_HEADER" : Layout with a section title.
  /// - "SECTION_TITLE_AND_DESCRIPTION" : Layout with a title and subtitle on
  /// one side and description on the other.
  /// - "ONE_COLUMN_TEXT" : Layout with one title and one body, arranged in a
  /// single column.
  /// - "MAIN_POINT" : Layout with a main point.
  /// - "BIG_NUMBER" : Layout with a big number heading.
  core.String? predefinedLayout;

  LayoutReference();

  LayoutReference.fromJson(core.Map _json) {
    if (_json.containsKey('layoutId')) {
      layoutId = _json['layoutId'] as core.String;
    }
    if (_json.containsKey('predefinedLayout')) {
      predefinedLayout = _json['predefinedLayout'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (layoutId != null) 'layoutId': layoutId!,
        if (predefinedLayout != null) 'predefinedLayout': predefinedLayout!,
      };
}

/// A PageElement kind representing a non-connector line, straight connector,
/// curved connector, or bent connector.
class Line {
  /// The category of the line.
  ///
  /// It matches the `category` specified in CreateLineRequest, and can be
  /// updated with UpdateLineCategoryRequest.
  /// Possible string values are:
  /// - "LINE_CATEGORY_UNSPECIFIED" : Unspecified line category.
  /// - "STRAIGHT" : Straight connectors, including straight connector 1.
  /// - "BENT" : Bent connectors, including bent connector 2 to 5.
  /// - "CURVED" : Curved connectors, including curved connector 2 to 5.
  core.String? lineCategory;

  /// The properties of the line.
  LineProperties? lineProperties;

  /// The type of the line.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : An unspecified line type.
  /// - "STRAIGHT_CONNECTOR_1" : Straight connector 1 form. Corresponds to
  /// ECMA-376 ST_ShapeType 'straightConnector1'.
  /// - "BENT_CONNECTOR_2" : Bent connector 2 form. Corresponds to ECMA-376
  /// ST_ShapeType 'bentConnector2'.
  /// - "BENT_CONNECTOR_3" : Bent connector 3 form. Corresponds to ECMA-376
  /// ST_ShapeType 'bentConnector3'.
  /// - "BENT_CONNECTOR_4" : Bent connector 4 form. Corresponds to ECMA-376
  /// ST_ShapeType 'bentConnector4'.
  /// - "BENT_CONNECTOR_5" : Bent connector 5 form. Corresponds to ECMA-376
  /// ST_ShapeType 'bentConnector5'.
  /// - "CURVED_CONNECTOR_2" : Curved connector 2 form. Corresponds to ECMA-376
  /// ST_ShapeType 'curvedConnector2'.
  /// - "CURVED_CONNECTOR_3" : Curved connector 3 form. Corresponds to ECMA-376
  /// ST_ShapeType 'curvedConnector3'.
  /// - "CURVED_CONNECTOR_4" : Curved connector 4 form. Corresponds to ECMA-376
  /// ST_ShapeType 'curvedConnector4'.
  /// - "CURVED_CONNECTOR_5" : Curved connector 5 form. Corresponds to ECMA-376
  /// ST_ShapeType 'curvedConnector5'.
  /// - "STRAIGHT_LINE" : Straight line. Corresponds to ECMA-376 ST_ShapeType
  /// 'line'. This line type is not a connector.
  core.String? lineType;

  Line();

  Line.fromJson(core.Map _json) {
    if (_json.containsKey('lineCategory')) {
      lineCategory = _json['lineCategory'] as core.String;
    }
    if (_json.containsKey('lineProperties')) {
      lineProperties = LineProperties.fromJson(
          _json['lineProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lineType')) {
      lineType = _json['lineType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineCategory != null) 'lineCategory': lineCategory!,
        if (lineProperties != null) 'lineProperties': lineProperties!.toJson(),
        if (lineType != null) 'lineType': lineType!,
      };
}

/// The properties for one end of a Line connection.
class LineConnection {
  /// The object ID of the connected page element.
  ///
  /// Some page elements, such as groups, tables, and lines do not have
  /// connection sites and therefore cannot be connected to a connector line.
  core.String? connectedObjectId;

  /// The index of the connection site on the connected page element.
  ///
  /// In most cases, it corresponds to the predefined connection site index from
  /// the ECMA-376 standard. More information on those connection sites can be
  /// found in the description of the "cnx" attribute in section 20.1.9.9 and
  /// Annex H. "Predefined DrawingML Shape and Text Geometries" of "Office Open
  /// XML File Formats-Fundamentals and Markup Language Reference", part 1 of
  /// \[ECMA-376 5th
  /// edition\](http://www.ecma-international.org/publications/standards/Ecma-376.htm).
  /// The position of each connection site can also be viewed from Slides
  /// editor.
  core.int? connectionSiteIndex;

  LineConnection();

  LineConnection.fromJson(core.Map _json) {
    if (_json.containsKey('connectedObjectId')) {
      connectedObjectId = _json['connectedObjectId'] as core.String;
    }
    if (_json.containsKey('connectionSiteIndex')) {
      connectionSiteIndex = _json['connectionSiteIndex'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (connectedObjectId != null) 'connectedObjectId': connectedObjectId!,
        if (connectionSiteIndex != null)
          'connectionSiteIndex': connectionSiteIndex!,
      };
}

/// The fill of the line.
class LineFill {
  /// Solid color fill.
  SolidFill? solidFill;

  LineFill();

  LineFill.fromJson(core.Map _json) {
    if (_json.containsKey('solidFill')) {
      solidFill = SolidFill.fromJson(
          _json['solidFill'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (solidFill != null) 'solidFill': solidFill!.toJson(),
      };
}

/// The properties of the Line.
///
/// When unset, these fields default to values that match the appearance of new
/// lines created in the Slides editor.
class LineProperties {
  /// The dash style of the line.
  /// Possible string values are:
  /// - "DASH_STYLE_UNSPECIFIED" : Unspecified dash style.
  /// - "SOLID" : Solid line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'solid'. This is the default dash style.
  /// - "DOT" : Dotted line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'dot'.
  /// - "DASH" : Dashed line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'dash'.
  /// - "DASH_DOT" : Alternating dashes and dots. Corresponds to ECMA-376
  /// ST_PresetLineDashVal value 'dashDot'.
  /// - "LONG_DASH" : Line with large dashes. Corresponds to ECMA-376
  /// ST_PresetLineDashVal value 'lgDash'.
  /// - "LONG_DASH_DOT" : Alternating large dashes and dots. Corresponds to
  /// ECMA-376 ST_PresetLineDashVal value 'lgDashDot'.
  core.String? dashStyle;

  /// The style of the arrow at the end of the line.
  /// Possible string values are:
  /// - "ARROW_STYLE_UNSPECIFIED" : An unspecified arrow style.
  /// - "NONE" : No arrow.
  /// - "STEALTH_ARROW" : Arrow with notched back. Corresponds to ECMA-376
  /// ST_LineEndType value 'stealth'.
  /// - "FILL_ARROW" : Filled arrow. Corresponds to ECMA-376 ST_LineEndType
  /// value 'triangle'.
  /// - "FILL_CIRCLE" : Filled circle. Corresponds to ECMA-376 ST_LineEndType
  /// value 'oval'.
  /// - "FILL_SQUARE" : Filled square.
  /// - "FILL_DIAMOND" : Filled diamond. Corresponds to ECMA-376 ST_LineEndType
  /// value 'diamond'.
  /// - "OPEN_ARROW" : Hollow arrow.
  /// - "OPEN_CIRCLE" : Hollow circle.
  /// - "OPEN_SQUARE" : Hollow square.
  /// - "OPEN_DIAMOND" : Hollow diamond.
  core.String? endArrow;

  /// The connection at the end of the line.
  ///
  /// If unset, there is no connection. Only lines with a Type indicating it is
  /// a "connector" can have an `end_connection`.
  LineConnection? endConnection;

  /// The fill of the line.
  ///
  /// The default line fill matches the defaults for new lines created in the
  /// Slides editor.
  LineFill? lineFill;

  /// The hyperlink destination of the line.
  ///
  /// If unset, there is no link.
  Link? link;

  /// The style of the arrow at the beginning of the line.
  /// Possible string values are:
  /// - "ARROW_STYLE_UNSPECIFIED" : An unspecified arrow style.
  /// - "NONE" : No arrow.
  /// - "STEALTH_ARROW" : Arrow with notched back. Corresponds to ECMA-376
  /// ST_LineEndType value 'stealth'.
  /// - "FILL_ARROW" : Filled arrow. Corresponds to ECMA-376 ST_LineEndType
  /// value 'triangle'.
  /// - "FILL_CIRCLE" : Filled circle. Corresponds to ECMA-376 ST_LineEndType
  /// value 'oval'.
  /// - "FILL_SQUARE" : Filled square.
  /// - "FILL_DIAMOND" : Filled diamond. Corresponds to ECMA-376 ST_LineEndType
  /// value 'diamond'.
  /// - "OPEN_ARROW" : Hollow arrow.
  /// - "OPEN_CIRCLE" : Hollow circle.
  /// - "OPEN_SQUARE" : Hollow square.
  /// - "OPEN_DIAMOND" : Hollow diamond.
  core.String? startArrow;

  /// The connection at the beginning of the line.
  ///
  /// If unset, there is no connection. Only lines with a Type indicating it is
  /// a "connector" can have a `start_connection`.
  LineConnection? startConnection;

  /// The thickness of the line.
  Dimension? weight;

  LineProperties();

  LineProperties.fromJson(core.Map _json) {
    if (_json.containsKey('dashStyle')) {
      dashStyle = _json['dashStyle'] as core.String;
    }
    if (_json.containsKey('endArrow')) {
      endArrow = _json['endArrow'] as core.String;
    }
    if (_json.containsKey('endConnection')) {
      endConnection = LineConnection.fromJson(
          _json['endConnection'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lineFill')) {
      lineFill = LineFill.fromJson(
          _json['lineFill'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('link')) {
      link =
          Link.fromJson(_json['link'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startArrow')) {
      startArrow = _json['startArrow'] as core.String;
    }
    if (_json.containsKey('startConnection')) {
      startConnection = LineConnection.fromJson(
          _json['startConnection'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('weight')) {
      weight = Dimension.fromJson(
          _json['weight'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dashStyle != null) 'dashStyle': dashStyle!,
        if (endArrow != null) 'endArrow': endArrow!,
        if (endConnection != null) 'endConnection': endConnection!.toJson(),
        if (lineFill != null) 'lineFill': lineFill!.toJson(),
        if (link != null) 'link': link!.toJson(),
        if (startArrow != null) 'startArrow': startArrow!,
        if (startConnection != null)
          'startConnection': startConnection!.toJson(),
        if (weight != null) 'weight': weight!.toJson(),
      };
}

/// A hypertext link.
class Link {
  /// If set, indicates this is a link to the specific page in this presentation
  /// with this ID.
  ///
  /// A page with this ID may not exist.
  core.String? pageObjectId;

  /// If set, indicates this is a link to a slide in this presentation,
  /// addressed by its position.
  /// Possible string values are:
  /// - "RELATIVE_SLIDE_LINK_UNSPECIFIED" : An unspecified relative slide link.
  /// - "NEXT_SLIDE" : A link to the next slide.
  /// - "PREVIOUS_SLIDE" : A link to the previous slide.
  /// - "FIRST_SLIDE" : A link to the first slide in the presentation.
  /// - "LAST_SLIDE" : A link to the last slide in the presentation.
  core.String? relativeLink;

  /// If set, indicates this is a link to the slide at this zero-based index in
  /// the presentation.
  ///
  /// There may not be a slide at this index.
  core.int? slideIndex;

  /// If set, indicates this is a link to the external web page at this URL.
  core.String? url;

  Link();

  Link.fromJson(core.Map _json) {
    if (_json.containsKey('pageObjectId')) {
      pageObjectId = _json['pageObjectId'] as core.String;
    }
    if (_json.containsKey('relativeLink')) {
      relativeLink = _json['relativeLink'] as core.String;
    }
    if (_json.containsKey('slideIndex')) {
      slideIndex = _json['slideIndex'] as core.int;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pageObjectId != null) 'pageObjectId': pageObjectId!,
        if (relativeLink != null) 'relativeLink': relativeLink!,
        if (slideIndex != null) 'slideIndex': slideIndex!,
        if (url != null) 'url': url!,
      };
}

/// A List describes the look and feel of bullets belonging to paragraphs
/// associated with a list.
///
/// A paragraph that is part of a list has an implicit reference to that list's
/// ID.
class List {
  /// The ID of the list.
  core.String? listId;

  /// A map of nesting levels to the properties of bullets at the associated
  /// level.
  ///
  /// A list has at most nine levels of nesting, so the possible values for the
  /// keys of this map are 0 through 8, inclusive.
  core.Map<core.String, NestingLevel>? nestingLevel;

  List();

  List.fromJson(core.Map _json) {
    if (_json.containsKey('listId')) {
      listId = _json['listId'] as core.String;
    }
    if (_json.containsKey('nestingLevel')) {
      nestingLevel =
          (_json['nestingLevel'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          NestingLevel.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (listId != null) 'listId': listId!,
        if (nestingLevel != null)
          'nestingLevel': nestingLevel!
              .map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// The properties of Page that are only relevant for pages with page_type
/// MASTER.
class MasterProperties {
  /// The human-readable name of the master.
  core.String? displayName;

  MasterProperties();

  MasterProperties.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
      };
}

/// Merges cells in a Table.
class MergeTableCellsRequest {
  /// The object ID of the table.
  core.String? objectId;

  /// The table range specifying which cells of the table to merge.
  ///
  /// Any text in the cells being merged will be concatenated and stored in the
  /// upper-left ("head") cell of the range. If the range is non-rectangular
  /// (which can occur in some cases where the range covers cells that are
  /// already merged), a 400 bad request error is returned.
  TableRange? tableRange;

  MergeTableCellsRequest();

  MergeTableCellsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('tableRange')) {
      tableRange = TableRange.fromJson(
          _json['tableRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
        if (tableRange != null) 'tableRange': tableRange!.toJson(),
      };
}

/// Contains properties describing the look and feel of a list bullet at a given
/// level of nesting.
class NestingLevel {
  /// The style of a bullet at this level of nesting.
  TextStyle? bulletStyle;

  NestingLevel();

  NestingLevel.fromJson(core.Map _json) {
    if (_json.containsKey('bulletStyle')) {
      bulletStyle = TextStyle.fromJson(
          _json['bulletStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bulletStyle != null) 'bulletStyle': bulletStyle!.toJson(),
      };
}

/// The properties of Page that are only relevant for pages with page_type
/// NOTES.
class NotesProperties {
  /// The object ID of the shape on this notes page that contains the speaker
  /// notes for the corresponding slide.
  ///
  /// The actual shape may not always exist on the notes page. Inserting text
  /// using this object ID will automatically create the shape. In this case,
  /// the actual shape may have different object ID. The `GetPresentation` or
  /// `GetPage` action will always return the latest object ID.
  core.String? speakerNotesObjectId;

  NotesProperties();

  NotesProperties.fromJson(core.Map _json) {
    if (_json.containsKey('speakerNotesObjectId')) {
      speakerNotesObjectId = _json['speakerNotesObjectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (speakerNotesObjectId != null)
          'speakerNotesObjectId': speakerNotesObjectId!,
      };
}

/// A themeable solid color value.
class OpaqueColor {
  /// An opaque RGB color.
  RgbColor? rgbColor;

  /// An opaque theme color.
  /// Possible string values are:
  /// - "THEME_COLOR_TYPE_UNSPECIFIED" : Unspecified theme color. This value
  /// should not be used.
  /// - "DARK1" : Represents the first dark color.
  /// - "LIGHT1" : Represents the first light color.
  /// - "DARK2" : Represents the second dark color.
  /// - "LIGHT2" : Represents the second light color.
  /// - "ACCENT1" : Represents the first accent color.
  /// - "ACCENT2" : Represents the second accent color.
  /// - "ACCENT3" : Represents the third accent color.
  /// - "ACCENT4" : Represents the fourth accent color.
  /// - "ACCENT5" : Represents the fifth accent color.
  /// - "ACCENT6" : Represents the sixth accent color.
  /// - "HYPERLINK" : Represents the color to use for hyperlinks.
  /// - "FOLLOWED_HYPERLINK" : Represents the color to use for visited
  /// hyperlinks.
  /// - "TEXT1" : Represents the first text color.
  /// - "BACKGROUND1" : Represents the first background color.
  /// - "TEXT2" : Represents the second text color.
  /// - "BACKGROUND2" : Represents the second background color.
  core.String? themeColor;

  OpaqueColor();

  OpaqueColor.fromJson(core.Map _json) {
    if (_json.containsKey('rgbColor')) {
      rgbColor = RgbColor.fromJson(
          _json['rgbColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('themeColor')) {
      themeColor = _json['themeColor'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rgbColor != null) 'rgbColor': rgbColor!.toJson(),
        if (themeColor != null) 'themeColor': themeColor!,
      };
}

/// A color that can either be fully opaque or fully transparent.
class OptionalColor {
  /// If set, this will be used as an opaque color.
  ///
  /// If unset, this represents a transparent color.
  OpaqueColor? opaqueColor;

  OptionalColor();

  OptionalColor.fromJson(core.Map _json) {
    if (_json.containsKey('opaqueColor')) {
      opaqueColor = OpaqueColor.fromJson(
          _json['opaqueColor'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (opaqueColor != null) 'opaqueColor': opaqueColor!.toJson(),
      };
}

/// The outline of a PageElement.
///
/// If these fields are unset, they may be inherited from a parent placeholder
/// if it exists. If there is no parent, the fields will default to the value
/// used for new page elements created in the Slides editor, which may depend on
/// the page element kind.
class Outline {
  /// The dash style of the outline.
  /// Possible string values are:
  /// - "DASH_STYLE_UNSPECIFIED" : Unspecified dash style.
  /// - "SOLID" : Solid line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'solid'. This is the default dash style.
  /// - "DOT" : Dotted line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'dot'.
  /// - "DASH" : Dashed line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'dash'.
  /// - "DASH_DOT" : Alternating dashes and dots. Corresponds to ECMA-376
  /// ST_PresetLineDashVal value 'dashDot'.
  /// - "LONG_DASH" : Line with large dashes. Corresponds to ECMA-376
  /// ST_PresetLineDashVal value 'lgDash'.
  /// - "LONG_DASH_DOT" : Alternating large dashes and dots. Corresponds to
  /// ECMA-376 ST_PresetLineDashVal value 'lgDashDot'.
  core.String? dashStyle;

  /// The fill of the outline.
  OutlineFill? outlineFill;

  /// The outline property state.
  ///
  /// Updating the outline on a page element will implicitly update this field
  /// to `RENDERED`, unless another value is specified in the same request. To
  /// have no outline on a page element, set this field to `NOT_RENDERED`. In
  /// this case, any other outline fields set in the same request will be
  /// ignored.
  /// Possible string values are:
  /// - "RENDERED" : If a property's state is RENDERED, then the element has the
  /// corresponding property when rendered on a page. If the element is a
  /// placeholder shape as determined by the placeholder field, and it inherits
  /// from a placeholder shape, the corresponding field may be unset, meaning
  /// that the property value is inherited from a parent placeholder. If the
  /// element does not inherit, then the field will contain the rendered value.
  /// This is the default value.
  /// - "NOT_RENDERED" : If a property's state is NOT_RENDERED, then the element
  /// does not have the corresponding property when rendered on a page. However,
  /// the field may still be set so it can be inherited by child shapes. To
  /// remove a property from a rendered element, set its property_state to
  /// NOT_RENDERED.
  /// - "INHERIT" : If a property's state is INHERIT, then the property state
  /// uses the value of corresponding `property_state` field on the parent
  /// shape. Elements that do not inherit will never have an INHERIT property
  /// state.
  core.String? propertyState;

  /// The thickness of the outline.
  Dimension? weight;

  Outline();

  Outline.fromJson(core.Map _json) {
    if (_json.containsKey('dashStyle')) {
      dashStyle = _json['dashStyle'] as core.String;
    }
    if (_json.containsKey('outlineFill')) {
      outlineFill = OutlineFill.fromJson(
          _json['outlineFill'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('propertyState')) {
      propertyState = _json['propertyState'] as core.String;
    }
    if (_json.containsKey('weight')) {
      weight = Dimension.fromJson(
          _json['weight'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dashStyle != null) 'dashStyle': dashStyle!,
        if (outlineFill != null) 'outlineFill': outlineFill!.toJson(),
        if (propertyState != null) 'propertyState': propertyState!,
        if (weight != null) 'weight': weight!.toJson(),
      };
}

/// The fill of the outline.
class OutlineFill {
  /// Solid color fill.
  SolidFill? solidFill;

  OutlineFill();

  OutlineFill.fromJson(core.Map _json) {
    if (_json.containsKey('solidFill')) {
      solidFill = SolidFill.fromJson(
          _json['solidFill'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (solidFill != null) 'solidFill': solidFill!.toJson(),
      };
}

/// A page in a presentation.
class Page {
  /// Layout specific properties.
  ///
  /// Only set if page_type = LAYOUT.
  LayoutProperties? layoutProperties;

  /// Master specific properties.
  ///
  /// Only set if page_type = MASTER.
  MasterProperties? masterProperties;

  /// Notes specific properties.
  ///
  /// Only set if page_type = NOTES.
  NotesProperties? notesProperties;

  /// The object ID for this page.
  ///
  /// Object IDs used by Page and PageElement share the same namespace.
  core.String? objectId;

  /// The page elements rendered on the page.
  core.List<PageElement>? pageElements;

  /// The properties of the page.
  PageProperties? pageProperties;

  /// The type of the page.
  /// Possible string values are:
  /// - "SLIDE" : A slide page.
  /// - "MASTER" : A master slide page.
  /// - "LAYOUT" : A layout page.
  /// - "NOTES" : A notes page.
  /// - "NOTES_MASTER" : A notes master page.
  core.String? pageType;

  /// The revision ID of the presentation containing this page.
  ///
  /// Can be used in update requests to assert that the presentation revision
  /// hasn't changed since the last read operation. Only populated if the user
  /// has edit access to the presentation. The format of the revision ID may
  /// change over time, so it should be treated opaquely. A returned revision ID
  /// is only guaranteed to be valid for 24 hours after it has been returned and
  /// cannot be shared across users. If the revision ID is unchanged between
  /// calls, then the presentation has not changed. Conversely, a changed ID
  /// (for the same presentation and user) usually means the presentation has
  /// been updated; however, a changed ID can also be due to internal factors
  /// such as ID format changes.
  core.String? revisionId;

  /// Slide specific properties.
  ///
  /// Only set if page_type = SLIDE.
  SlideProperties? slideProperties;

  Page();

  Page.fromJson(core.Map _json) {
    if (_json.containsKey('layoutProperties')) {
      layoutProperties = LayoutProperties.fromJson(
          _json['layoutProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('masterProperties')) {
      masterProperties = MasterProperties.fromJson(
          _json['masterProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('notesProperties')) {
      notesProperties = NotesProperties.fromJson(
          _json['notesProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('pageElements')) {
      pageElements = (_json['pageElements'] as core.List)
          .map<PageElement>((value) => PageElement.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('pageProperties')) {
      pageProperties = PageProperties.fromJson(
          _json['pageProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pageType')) {
      pageType = _json['pageType'] as core.String;
    }
    if (_json.containsKey('revisionId')) {
      revisionId = _json['revisionId'] as core.String;
    }
    if (_json.containsKey('slideProperties')) {
      slideProperties = SlideProperties.fromJson(
          _json['slideProperties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (layoutProperties != null)
          'layoutProperties': layoutProperties!.toJson(),
        if (masterProperties != null)
          'masterProperties': masterProperties!.toJson(),
        if (notesProperties != null)
          'notesProperties': notesProperties!.toJson(),
        if (objectId != null) 'objectId': objectId!,
        if (pageElements != null)
          'pageElements': pageElements!.map((value) => value.toJson()).toList(),
        if (pageProperties != null) 'pageProperties': pageProperties!.toJson(),
        if (pageType != null) 'pageType': pageType!,
        if (revisionId != null) 'revisionId': revisionId!,
        if (slideProperties != null)
          'slideProperties': slideProperties!.toJson(),
      };
}

/// The page background fill.
class PageBackgroundFill {
  /// The background fill property state.
  ///
  /// Updating the fill on a page will implicitly update this field to
  /// `RENDERED`, unless another value is specified in the same request. To have
  /// no fill on a page, set this field to `NOT_RENDERED`. In this case, any
  /// other fill fields set in the same request will be ignored.
  /// Possible string values are:
  /// - "RENDERED" : If a property's state is RENDERED, then the element has the
  /// corresponding property when rendered on a page. If the element is a
  /// placeholder shape as determined by the placeholder field, and it inherits
  /// from a placeholder shape, the corresponding field may be unset, meaning
  /// that the property value is inherited from a parent placeholder. If the
  /// element does not inherit, then the field will contain the rendered value.
  /// This is the default value.
  /// - "NOT_RENDERED" : If a property's state is NOT_RENDERED, then the element
  /// does not have the corresponding property when rendered on a page. However,
  /// the field may still be set so it can be inherited by child shapes. To
  /// remove a property from a rendered element, set its property_state to
  /// NOT_RENDERED.
  /// - "INHERIT" : If a property's state is INHERIT, then the property state
  /// uses the value of corresponding `property_state` field on the parent
  /// shape. Elements that do not inherit will never have an INHERIT property
  /// state.
  core.String? propertyState;

  /// Solid color fill.
  SolidFill? solidFill;

  /// Stretched picture fill.
  StretchedPictureFill? stretchedPictureFill;

  PageBackgroundFill();

  PageBackgroundFill.fromJson(core.Map _json) {
    if (_json.containsKey('propertyState')) {
      propertyState = _json['propertyState'] as core.String;
    }
    if (_json.containsKey('solidFill')) {
      solidFill = SolidFill.fromJson(
          _json['solidFill'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('stretchedPictureFill')) {
      stretchedPictureFill = StretchedPictureFill.fromJson(
          _json['stretchedPictureFill'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (propertyState != null) 'propertyState': propertyState!,
        if (solidFill != null) 'solidFill': solidFill!.toJson(),
        if (stretchedPictureFill != null)
          'stretchedPictureFill': stretchedPictureFill!.toJson(),
      };
}

/// A visual element rendered on a page.
class PageElement {
  /// The description of the page element.
  ///
  /// Combined with title to display alt text. The field is not supported for
  /// Group elements.
  core.String? description;

  /// A collection of page elements joined as a single unit.
  Group? elementGroup;

  /// An image page element.
  Image? image;

  /// A line page element.
  Line? line;

  /// The object ID for this page element.
  ///
  /// Object IDs used by google.apps.slides.v1.Page and
  /// google.apps.slides.v1.PageElement share the same namespace.
  core.String? objectId;

  /// A generic shape.
  Shape? shape;

  /// A linked chart embedded from Google Sheets.
  ///
  /// Unlinked charts are represented as images.
  SheetsChart? sheetsChart;

  /// The size of the page element.
  Size? size;

  /// A table page element.
  Table? table;

  /// The title of the page element.
  ///
  /// Combined with description to display alt text. The field is not supported
  /// for Group elements.
  core.String? title;

  /// The transform of the page element.
  ///
  /// The visual appearance of the page element is determined by its absolute
  /// transform. To compute the absolute transform, preconcatenate a page
  /// element's transform with the transforms of all of its parent groups. If
  /// the page element is not in a group, its absolute transform is the same as
  /// the value in this field. The initial transform for the newly created Group
  /// is always the identity transform.
  AffineTransform? transform;

  /// A video page element.
  Video? video;

  /// A word art page element.
  WordArt? wordArt;

  PageElement();

  PageElement.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('elementGroup')) {
      elementGroup = Group.fromJson(
          _json['elementGroup'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('image')) {
      image =
          Image.fromJson(_json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('line')) {
      line =
          Line.fromJson(_json['line'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('shape')) {
      shape =
          Shape.fromJson(_json['shape'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sheetsChart')) {
      sheetsChart = SheetsChart.fromJson(
          _json['sheetsChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('size')) {
      size =
          Size.fromJson(_json['size'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('table')) {
      table =
          Table.fromJson(_json['table'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('transform')) {
      transform = AffineTransform.fromJson(
          _json['transform'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('video')) {
      video =
          Video.fromJson(_json['video'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('wordArt')) {
      wordArt = WordArt.fromJson(
          _json['wordArt'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (elementGroup != null) 'elementGroup': elementGroup!.toJson(),
        if (image != null) 'image': image!.toJson(),
        if (line != null) 'line': line!.toJson(),
        if (objectId != null) 'objectId': objectId!,
        if (shape != null) 'shape': shape!.toJson(),
        if (sheetsChart != null) 'sheetsChart': sheetsChart!.toJson(),
        if (size != null) 'size': size!.toJson(),
        if (table != null) 'table': table!.toJson(),
        if (title != null) 'title': title!,
        if (transform != null) 'transform': transform!.toJson(),
        if (video != null) 'video': video!.toJson(),
        if (wordArt != null) 'wordArt': wordArt!.toJson(),
      };
}

/// Common properties for a page element.
///
/// Note: When you initially create a PageElement, the API may modify the values
/// of both `size` and `transform`, but the visual size will be unchanged.
class PageElementProperties {
  /// The object ID of the page where the element is located.
  core.String? pageObjectId;

  /// The size of the element.
  Size? size;

  /// The transform for the element.
  AffineTransform? transform;

  PageElementProperties();

  PageElementProperties.fromJson(core.Map _json) {
    if (_json.containsKey('pageObjectId')) {
      pageObjectId = _json['pageObjectId'] as core.String;
    }
    if (_json.containsKey('size')) {
      size =
          Size.fromJson(_json['size'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transform')) {
      transform = AffineTransform.fromJson(
          _json['transform'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pageObjectId != null) 'pageObjectId': pageObjectId!,
        if (size != null) 'size': size!.toJson(),
        if (transform != null) 'transform': transform!.toJson(),
      };
}

/// The properties of the Page.
///
/// The page will inherit properties from the parent page. Depending on the page
/// type the hierarchy is defined in either SlideProperties or LayoutProperties.
class PageProperties {
  /// The color scheme of the page.
  ///
  /// If unset, the color scheme is inherited from a parent page. If the page
  /// has no parent, the color scheme uses a default Slides color scheme,
  /// matching the defaults in the Slides editor. Only the concrete colors of
  /// the first 12 ThemeColorTypes are editable. In addition, only the color
  /// scheme on `Master` pages can be updated. To update the field, a color
  /// scheme containing mappings from all the first 12 ThemeColorTypes to their
  /// concrete colors must be provided. Colors for the remaining ThemeColorTypes
  /// will be ignored.
  ColorScheme? colorScheme;

  /// The background fill of the page.
  ///
  /// If unset, the background fill is inherited from a parent page if it
  /// exists. If the page has no parent, then the background fill defaults to
  /// the corresponding fill in the Slides editor.
  PageBackgroundFill? pageBackgroundFill;

  PageProperties();

  PageProperties.fromJson(core.Map _json) {
    if (_json.containsKey('colorScheme')) {
      colorScheme = ColorScheme.fromJson(
          _json['colorScheme'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pageBackgroundFill')) {
      pageBackgroundFill = PageBackgroundFill.fromJson(
          _json['pageBackgroundFill'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (colorScheme != null) 'colorScheme': colorScheme!.toJson(),
        if (pageBackgroundFill != null)
          'pageBackgroundFill': pageBackgroundFill!.toJson(),
      };
}

/// A TextElement kind that represents the beginning of a new paragraph.
class ParagraphMarker {
  /// The bullet for this paragraph.
  ///
  /// If not present, the paragraph does not belong to a list.
  Bullet? bullet;

  /// The paragraph's style
  ParagraphStyle? style;

  ParagraphMarker();

  ParagraphMarker.fromJson(core.Map _json) {
    if (_json.containsKey('bullet')) {
      bullet = Bullet.fromJson(
          _json['bullet'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('style')) {
      style = ParagraphStyle.fromJson(
          _json['style'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bullet != null) 'bullet': bullet!.toJson(),
        if (style != null) 'style': style!.toJson(),
      };
}

/// Styles that apply to a whole paragraph.
///
/// If this text is contained in a shape with a parent placeholder, then these
/// paragraph styles may be inherited from the parent. Which paragraph styles
/// are inherited depend on the nesting level of lists: * A paragraph not in a
/// list will inherit its paragraph style from the paragraph at the 0 nesting
/// level of the list inside the parent placeholder. * A paragraph in a list
/// will inherit its paragraph style from the paragraph at its corresponding
/// nesting level of the list inside the parent placeholder. Inherited paragraph
/// styles are represented as unset fields in this message.
class ParagraphStyle {
  /// The text alignment for this paragraph.
  /// Possible string values are:
  /// - "ALIGNMENT_UNSPECIFIED" : The paragraph alignment is inherited from the
  /// parent.
  /// - "START" : The paragraph is aligned to the start of the line.
  /// Left-aligned for LTR text, right-aligned otherwise.
  /// - "CENTER" : The paragraph is centered.
  /// - "END" : The paragraph is aligned to the end of the line. Right-aligned
  /// for LTR text, left-aligned otherwise.
  /// - "JUSTIFIED" : The paragraph is justified.
  core.String? alignment;

  /// The text direction of this paragraph.
  ///
  /// If unset, the value defaults to LEFT_TO_RIGHT since text direction is not
  /// inherited.
  /// Possible string values are:
  /// - "TEXT_DIRECTION_UNSPECIFIED" : The text direction is inherited from the
  /// parent.
  /// - "LEFT_TO_RIGHT" : The text goes from left to right.
  /// - "RIGHT_TO_LEFT" : The text goes from right to left.
  core.String? direction;

  /// The amount indentation for the paragraph on the side that corresponds to
  /// the end of the text, based on the current text direction.
  ///
  /// If unset, the value is inherited from the parent.
  Dimension? indentEnd;

  /// The amount of indentation for the start of the first line of the
  /// paragraph.
  ///
  /// If unset, the value is inherited from the parent.
  Dimension? indentFirstLine;

  /// The amount indentation for the paragraph on the side that corresponds to
  /// the start of the text, based on the current text direction.
  ///
  /// If unset, the value is inherited from the parent.
  Dimension? indentStart;

  /// The amount of space between lines, as a percentage of normal, where normal
  /// is represented as 100.0.
  ///
  /// If unset, the value is inherited from the parent.
  core.double? lineSpacing;

  /// The amount of extra space above the paragraph.
  ///
  /// If unset, the value is inherited from the parent.
  Dimension? spaceAbove;

  /// The amount of extra space below the paragraph.
  ///
  /// If unset, the value is inherited from the parent.
  Dimension? spaceBelow;

  /// The spacing mode for the paragraph.
  /// Possible string values are:
  /// - "SPACING_MODE_UNSPECIFIED" : The spacing mode is inherited from the
  /// parent.
  /// - "NEVER_COLLAPSE" : Paragraph spacing is always rendered.
  /// - "COLLAPSE_LISTS" : Paragraph spacing is skipped between list elements.
  core.String? spacingMode;

  ParagraphStyle();

  ParagraphStyle.fromJson(core.Map _json) {
    if (_json.containsKey('alignment')) {
      alignment = _json['alignment'] as core.String;
    }
    if (_json.containsKey('direction')) {
      direction = _json['direction'] as core.String;
    }
    if (_json.containsKey('indentEnd')) {
      indentEnd = Dimension.fromJson(
          _json['indentEnd'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('indentFirstLine')) {
      indentFirstLine = Dimension.fromJson(
          _json['indentFirstLine'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('indentStart')) {
      indentStart = Dimension.fromJson(
          _json['indentStart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lineSpacing')) {
      lineSpacing = (_json['lineSpacing'] as core.num).toDouble();
    }
    if (_json.containsKey('spaceAbove')) {
      spaceAbove = Dimension.fromJson(
          _json['spaceAbove'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spaceBelow')) {
      spaceBelow = Dimension.fromJson(
          _json['spaceBelow'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spacingMode')) {
      spacingMode = _json['spacingMode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alignment != null) 'alignment': alignment!,
        if (direction != null) 'direction': direction!,
        if (indentEnd != null) 'indentEnd': indentEnd!.toJson(),
        if (indentFirstLine != null)
          'indentFirstLine': indentFirstLine!.toJson(),
        if (indentStart != null) 'indentStart': indentStart!.toJson(),
        if (lineSpacing != null) 'lineSpacing': lineSpacing!,
        if (spaceAbove != null) 'spaceAbove': spaceAbove!.toJson(),
        if (spaceBelow != null) 'spaceBelow': spaceBelow!.toJson(),
        if (spacingMode != null) 'spacingMode': spacingMode!,
      };
}

/// The placeholder information that uniquely identifies a placeholder shape.
class Placeholder {
  /// The index of the placeholder.
  ///
  /// If the same placeholder types are present in the same page, they would
  /// have different index values.
  core.int? index;

  /// The object ID of this shape's parent placeholder.
  ///
  /// If unset, the parent placeholder shape does not exist, so the shape does
  /// not inherit properties from any other shape.
  core.String? parentObjectId;

  /// The type of the placeholder.
  /// Possible string values are:
  /// - "NONE" : Default value, signifies it is not a placeholder.
  /// - "BODY" : Body text.
  /// - "CHART" : Chart or graph.
  /// - "CLIP_ART" : Clip art image.
  /// - "CENTERED_TITLE" : Title centered.
  /// - "DIAGRAM" : Diagram.
  /// - "DATE_AND_TIME" : Date and time.
  /// - "FOOTER" : Footer text.
  /// - "HEADER" : Header text.
  /// - "MEDIA" : Multimedia.
  /// - "OBJECT" : Any content type.
  /// - "PICTURE" : Picture.
  /// - "SLIDE_NUMBER" : Number of a slide.
  /// - "SUBTITLE" : Subtitle.
  /// - "TABLE" : Table.
  /// - "TITLE" : Slide title.
  /// - "SLIDE_IMAGE" : Slide image.
  core.String? type;

  Placeholder();

  Placeholder.fromJson(core.Map _json) {
    if (_json.containsKey('index')) {
      index = _json['index'] as core.int;
    }
    if (_json.containsKey('parentObjectId')) {
      parentObjectId = _json['parentObjectId'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (index != null) 'index': index!,
        if (parentObjectId != null) 'parentObjectId': parentObjectId!,
        if (type != null) 'type': type!,
      };
}

/// A Google Slides presentation.
class Presentation {
  /// The layouts in the presentation.
  ///
  /// A layout is a template that determines how content is arranged and styled
  /// on the slides that inherit from that layout.
  core.List<Page>? layouts;

  /// The locale of the presentation, as an IETF BCP 47 language tag.
  core.String? locale;

  /// The slide masters in the presentation.
  ///
  /// A slide master contains all common page elements and the common properties
  /// for a set of layouts. They serve three purposes: - Placeholder shapes on a
  /// master contain the default text styles and shape properties of all
  /// placeholder shapes on pages that use that master. - The master page
  /// properties define the common page properties inherited by its layouts. -
  /// Any other shapes on the master slide appear on all slides using that
  /// master, regardless of their layout.
  core.List<Page>? masters;

  /// The notes master in the presentation.
  ///
  /// It serves three purposes: - Placeholder shapes on a notes master contain
  /// the default text styles and shape properties of all placeholder shapes on
  /// notes pages. Specifically, a `SLIDE_IMAGE` placeholder shape contains the
  /// slide thumbnail, and a `BODY` placeholder shape contains the speaker
  /// notes. - The notes master page properties define the common page
  /// properties inherited by all notes pages. - Any other shapes on the notes
  /// master appear on all notes pages. The notes master is read-only.
  Page? notesMaster;

  /// The size of pages in the presentation.
  Size? pageSize;

  /// The ID of the presentation.
  core.String? presentationId;

  /// The revision ID of the presentation.
  ///
  /// Can be used in update requests to assert that the presentation revision
  /// hasn't changed since the last read operation. Only populated if the user
  /// has edit access to the presentation. The format of the revision ID may
  /// change over time, so it should be treated opaquely. A returned revision ID
  /// is only guaranteed to be valid for 24 hours after it has been returned and
  /// cannot be shared across users. If the revision ID is unchanged between
  /// calls, then the presentation has not changed. Conversely, a changed ID
  /// (for the same presentation and user) usually means the presentation has
  /// been updated; however, a changed ID can also be due to internal factors
  /// such as ID format changes.
  core.String? revisionId;

  /// The slides in the presentation.
  ///
  /// A slide inherits properties from a slide layout.
  core.List<Page>? slides;

  /// The title of the presentation.
  core.String? title;

  Presentation();

  Presentation.fromJson(core.Map _json) {
    if (_json.containsKey('layouts')) {
      layouts = (_json['layouts'] as core.List)
          .map<Page>((value) =>
              Page.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('locale')) {
      locale = _json['locale'] as core.String;
    }
    if (_json.containsKey('masters')) {
      masters = (_json['masters'] as core.List)
          .map<Page>((value) =>
              Page.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('notesMaster')) {
      notesMaster = Page.fromJson(
          _json['notesMaster'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pageSize')) {
      pageSize = Size.fromJson(
          _json['pageSize'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('presentationId')) {
      presentationId = _json['presentationId'] as core.String;
    }
    if (_json.containsKey('revisionId')) {
      revisionId = _json['revisionId'] as core.String;
    }
    if (_json.containsKey('slides')) {
      slides = (_json['slides'] as core.List)
          .map<Page>((value) =>
              Page.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (layouts != null)
          'layouts': layouts!.map((value) => value.toJson()).toList(),
        if (locale != null) 'locale': locale!,
        if (masters != null)
          'masters': masters!.map((value) => value.toJson()).toList(),
        if (notesMaster != null) 'notesMaster': notesMaster!.toJson(),
        if (pageSize != null) 'pageSize': pageSize!.toJson(),
        if (presentationId != null) 'presentationId': presentationId!,
        if (revisionId != null) 'revisionId': revisionId!,
        if (slides != null)
          'slides': slides!.map((value) => value.toJson()).toList(),
        if (title != null) 'title': title!,
      };
}

/// Specifies a contiguous range of an indexed collection, such as characters in
/// text.
class Range {
  /// The optional zero-based index of the end of the collection.
  ///
  /// Required for `FIXED_RANGE` ranges.
  core.int? endIndex;

  /// The optional zero-based index of the beginning of the collection.
  ///
  /// Required for `FIXED_RANGE` and `FROM_START_INDEX` ranges.
  core.int? startIndex;

  /// The type of range.
  /// Possible string values are:
  /// - "RANGE_TYPE_UNSPECIFIED" : Unspecified range type. This value must not
  /// be used.
  /// - "FIXED_RANGE" : A fixed range. Both the `start_index` and `end_index`
  /// must be specified.
  /// - "FROM_START_INDEX" : Starts the range at `start_index` and continues
  /// until the end of the collection. The `end_index` must not be specified.
  /// - "ALL" : Sets the range to be the whole length of the collection. Both
  /// the `start_index` and the `end_index` must not be specified.
  core.String? type;

  Range();

  Range.fromJson(core.Map _json) {
    if (_json.containsKey('endIndex')) {
      endIndex = _json['endIndex'] as core.int;
    }
    if (_json.containsKey('startIndex')) {
      startIndex = _json['startIndex'] as core.int;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endIndex != null) 'endIndex': endIndex!,
        if (startIndex != null) 'startIndex': startIndex!,
        if (type != null) 'type': type!,
      };
}

/// A recolor effect applied on an image.
class Recolor {
  /// The name of the recolor effect.
  ///
  /// The name is determined from the `recolor_stops` by matching the gradient
  /// against the colors in the page's current color scheme. This property is
  /// read-only.
  /// Possible string values are:
  /// - "NONE" : No recolor effect. The default value.
  /// - "LIGHT1" : A recolor effect that lightens the image using the page's
  /// first available color from its color scheme.
  /// - "LIGHT2" : A recolor effect that lightens the image using the page's
  /// second available color from its color scheme.
  /// - "LIGHT3" : A recolor effect that lightens the image using the page's
  /// third available color from its color scheme.
  /// - "LIGHT4" : A recolor effect that lightens the image using the page's
  /// forth available color from its color scheme.
  /// - "LIGHT5" : A recolor effect that lightens the image using the page's
  /// fifth available color from its color scheme.
  /// - "LIGHT6" : A recolor effect that lightens the image using the page's
  /// sixth available color from its color scheme.
  /// - "LIGHT7" : A recolor effect that lightens the image using the page's
  /// seventh available color from its color scheme.
  /// - "LIGHT8" : A recolor effect that lightens the image using the page's
  /// eighth available color from its color scheme.
  /// - "LIGHT9" : A recolor effect that lightens the image using the page's
  /// ninth available color from its color scheme.
  /// - "LIGHT10" : A recolor effect that lightens the image using the page's
  /// tenth available color from its color scheme.
  /// - "DARK1" : A recolor effect that darkens the image using the page's first
  /// available color from its color scheme.
  /// - "DARK2" : A recolor effect that darkens the image using the page's
  /// second available color from its color scheme.
  /// - "DARK3" : A recolor effect that darkens the image using the page's third
  /// available color from its color scheme.
  /// - "DARK4" : A recolor effect that darkens the image using the page's
  /// fourth available color from its color scheme.
  /// - "DARK5" : A recolor effect that darkens the image using the page's fifth
  /// available color from its color scheme.
  /// - "DARK6" : A recolor effect that darkens the image using the page's sixth
  /// available color from its color scheme.
  /// - "DARK7" : A recolor effect that darkens the image using the page's
  /// seventh available color from its color scheme.
  /// - "DARK8" : A recolor effect that darkens the image using the page's
  /// eighth available color from its color scheme.
  /// - "DARK9" : A recolor effect that darkens the image using the page's ninth
  /// available color from its color scheme.
  /// - "DARK10" : A recolor effect that darkens the image using the page's
  /// tenth available color from its color scheme.
  /// - "GRAYSCALE" : A recolor effect that recolors the image to grayscale.
  /// - "NEGATIVE" : A recolor effect that recolors the image to negative
  /// grayscale.
  /// - "SEPIA" : A recolor effect that recolors the image using the sepia
  /// color.
  /// - "CUSTOM" : Custom recolor effect. Refer to `recolor_stops` for the
  /// concrete gradient.
  core.String? name;

  /// The recolor effect is represented by a gradient, which is a list of color
  /// stops.
  ///
  /// The colors in the gradient will replace the corresponding colors at the
  /// same position in the color palette and apply to the image. This property
  /// is read-only.
  core.List<ColorStop>? recolorStops;

  Recolor();

  Recolor.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('recolorStops')) {
      recolorStops = (_json['recolorStops'] as core.List)
          .map<ColorStop>((value) =>
              ColorStop.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (recolorStops != null)
          'recolorStops': recolorStops!.map((value) => value.toJson()).toList(),
      };
}

/// Refreshes an embedded Google Sheets chart by replacing it with the latest
/// version of the chart from Google Sheets.
///
/// NOTE: Refreshing charts requires at least one of the spreadsheets.readonly,
/// spreadsheets, drive.readonly, or drive OAuth scopes.
class RefreshSheetsChartRequest {
  /// The object ID of the chart to refresh.
  core.String? objectId;

  RefreshSheetsChartRequest();

  RefreshSheetsChartRequest.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Replaces all shapes that match the given criteria with the provided image.
///
/// The images replacing the shapes are rectangular after being inserted into
/// the presentation and do not take on the forms of the shapes.
class ReplaceAllShapesWithImageRequest {
  /// If set, this request will replace all of the shapes that contain the given
  /// text.
  SubstringMatchCriteria? containsText;

  /// The image replace method.
  ///
  /// If you specify both a `replace_method` and an `image_replace_method`, the
  /// `image_replace_method` takes precedence. If you do not specify a value for
  /// `image_replace_method`, but specify a value for `replace_method`, then the
  /// specified `replace_method` value is used. If you do not specify either,
  /// then CENTER_INSIDE is used.
  /// Possible string values are:
  /// - "IMAGE_REPLACE_METHOD_UNSPECIFIED" : Unspecified image replace method.
  /// This value must not be used.
  /// - "CENTER_INSIDE" : Scales and centers the image to fit within the bounds
  /// of the original shape and maintains the image's aspect ratio. The rendered
  /// size of the image may be smaller than the size of the shape. This is the
  /// default method when one is not specified.
  /// - "CENTER_CROP" : Scales and centers the image to fill the bounds of the
  /// original shape. The image may be cropped in order to fill the shape. The
  /// rendered size of the image will be the same as that of the original shape.
  core.String? imageReplaceMethod;

  /// The image URL.
  ///
  /// The image is fetched once at insertion time and a copy is stored for
  /// display inside the presentation. Images must be less than 50MB in size,
  /// cannot exceed 25 megapixels, and must be in one of PNG, JPEG, or GIF
  /// format. The provided URL can be at most 2 kB in length. The URL itself is
  /// saved with the image, and exposed via the Image.source_url field.
  core.String? imageUrl;

  /// If non-empty, limits the matches to page elements only on the given pages.
  ///
  /// Returns a 400 bad request error if given the page object ID of a notes
  /// page or a notes master, or if a page with that object ID doesn't exist in
  /// the presentation.
  core.List<core.String>? pageObjectIds;

  /// The replace method.
  ///
  /// *Deprecated*: use `image_replace_method` instead. If you specify both a
  /// `replace_method` and an `image_replace_method`, the `image_replace_method`
  /// takes precedence.
  /// Possible string values are:
  /// - "CENTER_INSIDE" : Scales and centers the image to fit within the bounds
  /// of the original shape and maintains the image's aspect ratio. The rendered
  /// size of the image may be smaller than the size of the shape. This is the
  /// default method when one is not specified.
  /// - "CENTER_CROP" : Scales and centers the image to fill the bounds of the
  /// original shape. The image may be cropped in order to fill the shape. The
  /// rendered size of the image will be the same as that of the original shape.
  core.String? replaceMethod;

  ReplaceAllShapesWithImageRequest();

  ReplaceAllShapesWithImageRequest.fromJson(core.Map _json) {
    if (_json.containsKey('containsText')) {
      containsText = SubstringMatchCriteria.fromJson(
          _json['containsText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('imageReplaceMethod')) {
      imageReplaceMethod = _json['imageReplaceMethod'] as core.String;
    }
    if (_json.containsKey('imageUrl')) {
      imageUrl = _json['imageUrl'] as core.String;
    }
    if (_json.containsKey('pageObjectIds')) {
      pageObjectIds = (_json['pageObjectIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('replaceMethod')) {
      replaceMethod = _json['replaceMethod'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (containsText != null) 'containsText': containsText!.toJson(),
        if (imageReplaceMethod != null)
          'imageReplaceMethod': imageReplaceMethod!,
        if (imageUrl != null) 'imageUrl': imageUrl!,
        if (pageObjectIds != null) 'pageObjectIds': pageObjectIds!,
        if (replaceMethod != null) 'replaceMethod': replaceMethod!,
      };
}

/// The result of replacing shapes with an image.
class ReplaceAllShapesWithImageResponse {
  /// The number of shapes replaced with images.
  core.int? occurrencesChanged;

  ReplaceAllShapesWithImageResponse();

  ReplaceAllShapesWithImageResponse.fromJson(core.Map _json) {
    if (_json.containsKey('occurrencesChanged')) {
      occurrencesChanged = _json['occurrencesChanged'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (occurrencesChanged != null)
          'occurrencesChanged': occurrencesChanged!,
      };
}

/// Replaces all shapes that match the given criteria with the provided Google
/// Sheets chart.
///
/// The chart will be scaled and centered to fit within the bounds of the
/// original shape. NOTE: Replacing shapes with a chart requires at least one of
/// the spreadsheets.readonly, spreadsheets, drive.readonly, or drive OAuth
/// scopes.
class ReplaceAllShapesWithSheetsChartRequest {
  /// The ID of the specific chart in the Google Sheets spreadsheet.
  core.int? chartId;

  /// The criteria that the shapes must match in order to be replaced.
  ///
  /// The request will replace all of the shapes that contain the given text.
  SubstringMatchCriteria? containsText;

  /// The mode with which the chart is linked to the source spreadsheet.
  ///
  /// When not specified, the chart will be an image that is not linked.
  /// Possible string values are:
  /// - "NOT_LINKED_IMAGE" : The chart is not associated with the source
  /// spreadsheet and cannot be updated. A chart that is not linked will be
  /// inserted as an image.
  /// - "LINKED" : Linking the chart allows it to be updated, and other
  /// collaborators will see a link to the spreadsheet.
  core.String? linkingMode;

  /// If non-empty, limits the matches to page elements only on the given pages.
  ///
  /// Returns a 400 bad request error if given the page object ID of a notes
  /// page or a notes master, or if a page with that object ID doesn't exist in
  /// the presentation.
  core.List<core.String>? pageObjectIds;

  /// The ID of the Google Sheets spreadsheet that contains the chart.
  core.String? spreadsheetId;

  ReplaceAllShapesWithSheetsChartRequest();

  ReplaceAllShapesWithSheetsChartRequest.fromJson(core.Map _json) {
    if (_json.containsKey('chartId')) {
      chartId = _json['chartId'] as core.int;
    }
    if (_json.containsKey('containsText')) {
      containsText = SubstringMatchCriteria.fromJson(
          _json['containsText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('linkingMode')) {
      linkingMode = _json['linkingMode'] as core.String;
    }
    if (_json.containsKey('pageObjectIds')) {
      pageObjectIds = (_json['pageObjectIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chartId != null) 'chartId': chartId!,
        if (containsText != null) 'containsText': containsText!.toJson(),
        if (linkingMode != null) 'linkingMode': linkingMode!,
        if (pageObjectIds != null) 'pageObjectIds': pageObjectIds!,
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
      };
}

/// The result of replacing shapes with a Google Sheets chart.
class ReplaceAllShapesWithSheetsChartResponse {
  /// The number of shapes replaced with charts.
  core.int? occurrencesChanged;

  ReplaceAllShapesWithSheetsChartResponse();

  ReplaceAllShapesWithSheetsChartResponse.fromJson(core.Map _json) {
    if (_json.containsKey('occurrencesChanged')) {
      occurrencesChanged = _json['occurrencesChanged'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (occurrencesChanged != null)
          'occurrencesChanged': occurrencesChanged!,
      };
}

/// Replaces all instances of text matching a criteria with replace text.
class ReplaceAllTextRequest {
  /// Finds text in a shape matching this substring.
  SubstringMatchCriteria? containsText;

  /// If non-empty, limits the matches to page elements only on the given pages.
  ///
  /// Returns a 400 bad request error if given the page object ID of a notes
  /// master, or if a page with that object ID doesn't exist in the
  /// presentation.
  core.List<core.String>? pageObjectIds;

  /// The text that will replace the matched text.
  core.String? replaceText;

  ReplaceAllTextRequest();

  ReplaceAllTextRequest.fromJson(core.Map _json) {
    if (_json.containsKey('containsText')) {
      containsText = SubstringMatchCriteria.fromJson(
          _json['containsText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pageObjectIds')) {
      pageObjectIds = (_json['pageObjectIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('replaceText')) {
      replaceText = _json['replaceText'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (containsText != null) 'containsText': containsText!.toJson(),
        if (pageObjectIds != null) 'pageObjectIds': pageObjectIds!,
        if (replaceText != null) 'replaceText': replaceText!,
      };
}

/// The result of replacing text.
class ReplaceAllTextResponse {
  /// The number of occurrences changed by replacing all text.
  core.int? occurrencesChanged;

  ReplaceAllTextResponse();

  ReplaceAllTextResponse.fromJson(core.Map _json) {
    if (_json.containsKey('occurrencesChanged')) {
      occurrencesChanged = _json['occurrencesChanged'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (occurrencesChanged != null)
          'occurrencesChanged': occurrencesChanged!,
      };
}

/// Replaces an existing image with a new image.
///
/// Replacing an image removes some image effects from the existing image.
class ReplaceImageRequest {
  /// The ID of the existing image that will be replaced.
  core.String? imageObjectId;

  /// The replacement method.
  /// Possible string values are:
  /// - "IMAGE_REPLACE_METHOD_UNSPECIFIED" : Unspecified image replace method.
  /// This value must not be used.
  /// - "CENTER_INSIDE" : Scales and centers the image to fit within the bounds
  /// of the original shape and maintains the image's aspect ratio. The rendered
  /// size of the image may be smaller than the size of the shape. This is the
  /// default method when one is not specified.
  /// - "CENTER_CROP" : Scales and centers the image to fill the bounds of the
  /// original shape. The image may be cropped in order to fill the shape. The
  /// rendered size of the image will be the same as that of the original shape.
  core.String? imageReplaceMethod;

  /// The image URL.
  ///
  /// The image is fetched once at insertion time and a copy is stored for
  /// display inside the presentation. Images must be less than 50MB in size,
  /// cannot exceed 25 megapixels, and must be in one of PNG, JPEG, or GIF
  /// format. The provided URL can be at most 2 kB in length. The URL itself is
  /// saved with the image, and exposed via the Image.source_url field.
  core.String? url;

  ReplaceImageRequest();

  ReplaceImageRequest.fromJson(core.Map _json) {
    if (_json.containsKey('imageObjectId')) {
      imageObjectId = _json['imageObjectId'] as core.String;
    }
    if (_json.containsKey('imageReplaceMethod')) {
      imageReplaceMethod = _json['imageReplaceMethod'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (imageObjectId != null) 'imageObjectId': imageObjectId!,
        if (imageReplaceMethod != null)
          'imageReplaceMethod': imageReplaceMethod!,
        if (url != null) 'url': url!,
      };
}

/// A single kind of update to apply to a presentation.
class Request {
  /// Creates an image.
  CreateImageRequest? createImage;

  /// Creates a line.
  CreateLineRequest? createLine;

  /// Creates bullets for paragraphs.
  CreateParagraphBulletsRequest? createParagraphBullets;

  /// Creates a new shape.
  CreateShapeRequest? createShape;

  /// Creates an embedded Google Sheets chart.
  CreateSheetsChartRequest? createSheetsChart;

  /// Creates a new slide.
  CreateSlideRequest? createSlide;

  /// Creates a new table.
  CreateTableRequest? createTable;

  /// Creates a video.
  CreateVideoRequest? createVideo;

  /// Deletes a page or page element from the presentation.
  DeleteObjectRequest? deleteObject;

  /// Deletes bullets from paragraphs.
  DeleteParagraphBulletsRequest? deleteParagraphBullets;

  /// Deletes a column from a table.
  DeleteTableColumnRequest? deleteTableColumn;

  /// Deletes a row from a table.
  DeleteTableRowRequest? deleteTableRow;

  /// Deletes text from a shape or a table cell.
  DeleteTextRequest? deleteText;

  /// Duplicates a slide or page element.
  DuplicateObjectRequest? duplicateObject;

  /// Groups objects, such as page elements.
  GroupObjectsRequest? groupObjects;

  /// Inserts columns into a table.
  InsertTableColumnsRequest? insertTableColumns;

  /// Inserts rows into a table.
  InsertTableRowsRequest? insertTableRows;

  /// Inserts text into a shape or table cell.
  InsertTextRequest? insertText;

  /// Merges cells in a Table.
  MergeTableCellsRequest? mergeTableCells;

  /// Refreshes a Google Sheets chart.
  RefreshSheetsChartRequest? refreshSheetsChart;

  /// Replaces all shapes matching some criteria with an image.
  ReplaceAllShapesWithImageRequest? replaceAllShapesWithImage;

  /// Replaces all shapes matching some criteria with a Google Sheets chart.
  ReplaceAllShapesWithSheetsChartRequest? replaceAllShapesWithSheetsChart;

  /// Replaces all instances of specified text.
  ReplaceAllTextRequest? replaceAllText;

  /// Replaces an existing image with a new image.
  ReplaceImageRequest? replaceImage;

  /// Reroutes a line such that it's connected at the two closest connection
  /// sites on the connected page elements.
  RerouteLineRequest? rerouteLine;

  /// Ungroups objects, such as groups.
  UngroupObjectsRequest? ungroupObjects;

  /// Unmerges cells in a Table.
  UnmergeTableCellsRequest? unmergeTableCells;

  /// Updates the properties of an Image.
  UpdateImagePropertiesRequest? updateImageProperties;

  /// Updates the category of a line.
  UpdateLineCategoryRequest? updateLineCategory;

  /// Updates the properties of a Line.
  UpdateLinePropertiesRequest? updateLineProperties;

  /// Updates the alt text title and/or description of a page element.
  UpdatePageElementAltTextRequest? updatePageElementAltText;

  /// Updates the transform of a page element.
  UpdatePageElementTransformRequest? updatePageElementTransform;

  /// Updates the Z-order of page elements.
  UpdatePageElementsZOrderRequest? updatePageElementsZOrder;

  /// Updates the properties of a Page.
  UpdatePagePropertiesRequest? updatePageProperties;

  /// Updates the styling of paragraphs within a Shape or Table.
  UpdateParagraphStyleRequest? updateParagraphStyle;

  /// Updates the properties of a Shape.
  UpdateShapePropertiesRequest? updateShapeProperties;

  /// Updates the position of a set of slides in the presentation.
  UpdateSlidesPositionRequest? updateSlidesPosition;

  /// Updates the properties of the table borders in a Table.
  UpdateTableBorderPropertiesRequest? updateTableBorderProperties;

  /// Updates the properties of a TableCell.
  UpdateTableCellPropertiesRequest? updateTableCellProperties;

  /// Updates the properties of a Table column.
  UpdateTableColumnPropertiesRequest? updateTableColumnProperties;

  /// Updates the properties of a Table row.
  UpdateTableRowPropertiesRequest? updateTableRowProperties;

  /// Updates the styling of text within a Shape or Table.
  UpdateTextStyleRequest? updateTextStyle;

  /// Updates the properties of a Video.
  UpdateVideoPropertiesRequest? updateVideoProperties;

  Request();

  Request.fromJson(core.Map _json) {
    if (_json.containsKey('createImage')) {
      createImage = CreateImageRequest.fromJson(
          _json['createImage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createLine')) {
      createLine = CreateLineRequest.fromJson(
          _json['createLine'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createParagraphBullets')) {
      createParagraphBullets = CreateParagraphBulletsRequest.fromJson(
          _json['createParagraphBullets']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createShape')) {
      createShape = CreateShapeRequest.fromJson(
          _json['createShape'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createSheetsChart')) {
      createSheetsChart = CreateSheetsChartRequest.fromJson(
          _json['createSheetsChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createSlide')) {
      createSlide = CreateSlideRequest.fromJson(
          _json['createSlide'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTable')) {
      createTable = CreateTableRequest.fromJson(
          _json['createTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createVideo')) {
      createVideo = CreateVideoRequest.fromJson(
          _json['createVideo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteObject')) {
      deleteObject = DeleteObjectRequest.fromJson(
          _json['deleteObject'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteParagraphBullets')) {
      deleteParagraphBullets = DeleteParagraphBulletsRequest.fromJson(
          _json['deleteParagraphBullets']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteTableColumn')) {
      deleteTableColumn = DeleteTableColumnRequest.fromJson(
          _json['deleteTableColumn'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteTableRow')) {
      deleteTableRow = DeleteTableRowRequest.fromJson(
          _json['deleteTableRow'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteText')) {
      deleteText = DeleteTextRequest.fromJson(
          _json['deleteText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('duplicateObject')) {
      duplicateObject = DuplicateObjectRequest.fromJson(
          _json['duplicateObject'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('groupObjects')) {
      groupObjects = GroupObjectsRequest.fromJson(
          _json['groupObjects'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertTableColumns')) {
      insertTableColumns = InsertTableColumnsRequest.fromJson(
          _json['insertTableColumns'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertTableRows')) {
      insertTableRows = InsertTableRowsRequest.fromJson(
          _json['insertTableRows'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertText')) {
      insertText = InsertTextRequest.fromJson(
          _json['insertText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mergeTableCells')) {
      mergeTableCells = MergeTableCellsRequest.fromJson(
          _json['mergeTableCells'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('refreshSheetsChart')) {
      refreshSheetsChart = RefreshSheetsChartRequest.fromJson(
          _json['refreshSheetsChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replaceAllShapesWithImage')) {
      replaceAllShapesWithImage = ReplaceAllShapesWithImageRequest.fromJson(
          _json['replaceAllShapesWithImage']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replaceAllShapesWithSheetsChart')) {
      replaceAllShapesWithSheetsChart =
          ReplaceAllShapesWithSheetsChartRequest.fromJson(
              _json['replaceAllShapesWithSheetsChart']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replaceAllText')) {
      replaceAllText = ReplaceAllTextRequest.fromJson(
          _json['replaceAllText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replaceImage')) {
      replaceImage = ReplaceImageRequest.fromJson(
          _json['replaceImage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rerouteLine')) {
      rerouteLine = RerouteLineRequest.fromJson(
          _json['rerouteLine'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ungroupObjects')) {
      ungroupObjects = UngroupObjectsRequest.fromJson(
          _json['ungroupObjects'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unmergeTableCells')) {
      unmergeTableCells = UnmergeTableCellsRequest.fromJson(
          _json['unmergeTableCells'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateImageProperties')) {
      updateImageProperties = UpdateImagePropertiesRequest.fromJson(
          _json['updateImageProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateLineCategory')) {
      updateLineCategory = UpdateLineCategoryRequest.fromJson(
          _json['updateLineCategory'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateLineProperties')) {
      updateLineProperties = UpdateLinePropertiesRequest.fromJson(
          _json['updateLineProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updatePageElementAltText')) {
      updatePageElementAltText = UpdatePageElementAltTextRequest.fromJson(
          _json['updatePageElementAltText']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updatePageElementTransform')) {
      updatePageElementTransform = UpdatePageElementTransformRequest.fromJson(
          _json['updatePageElementTransform']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updatePageElementsZOrder')) {
      updatePageElementsZOrder = UpdatePageElementsZOrderRequest.fromJson(
          _json['updatePageElementsZOrder']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updatePageProperties')) {
      updatePageProperties = UpdatePagePropertiesRequest.fromJson(
          _json['updatePageProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateParagraphStyle')) {
      updateParagraphStyle = UpdateParagraphStyleRequest.fromJson(
          _json['updateParagraphStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateShapeProperties')) {
      updateShapeProperties = UpdateShapePropertiesRequest.fromJson(
          _json['updateShapeProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateSlidesPosition')) {
      updateSlidesPosition = UpdateSlidesPositionRequest.fromJson(
          _json['updateSlidesPosition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTableBorderProperties')) {
      updateTableBorderProperties = UpdateTableBorderPropertiesRequest.fromJson(
          _json['updateTableBorderProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTableCellProperties')) {
      updateTableCellProperties = UpdateTableCellPropertiesRequest.fromJson(
          _json['updateTableCellProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTableColumnProperties')) {
      updateTableColumnProperties = UpdateTableColumnPropertiesRequest.fromJson(
          _json['updateTableColumnProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTableRowProperties')) {
      updateTableRowProperties = UpdateTableRowPropertiesRequest.fromJson(
          _json['updateTableRowProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTextStyle')) {
      updateTextStyle = UpdateTextStyleRequest.fromJson(
          _json['updateTextStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateVideoProperties')) {
      updateVideoProperties = UpdateVideoPropertiesRequest.fromJson(
          _json['updateVideoProperties']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createImage != null) 'createImage': createImage!.toJson(),
        if (createLine != null) 'createLine': createLine!.toJson(),
        if (createParagraphBullets != null)
          'createParagraphBullets': createParagraphBullets!.toJson(),
        if (createShape != null) 'createShape': createShape!.toJson(),
        if (createSheetsChart != null)
          'createSheetsChart': createSheetsChart!.toJson(),
        if (createSlide != null) 'createSlide': createSlide!.toJson(),
        if (createTable != null) 'createTable': createTable!.toJson(),
        if (createVideo != null) 'createVideo': createVideo!.toJson(),
        if (deleteObject != null) 'deleteObject': deleteObject!.toJson(),
        if (deleteParagraphBullets != null)
          'deleteParagraphBullets': deleteParagraphBullets!.toJson(),
        if (deleteTableColumn != null)
          'deleteTableColumn': deleteTableColumn!.toJson(),
        if (deleteTableRow != null) 'deleteTableRow': deleteTableRow!.toJson(),
        if (deleteText != null) 'deleteText': deleteText!.toJson(),
        if (duplicateObject != null)
          'duplicateObject': duplicateObject!.toJson(),
        if (groupObjects != null) 'groupObjects': groupObjects!.toJson(),
        if (insertTableColumns != null)
          'insertTableColumns': insertTableColumns!.toJson(),
        if (insertTableRows != null)
          'insertTableRows': insertTableRows!.toJson(),
        if (insertText != null) 'insertText': insertText!.toJson(),
        if (mergeTableCells != null)
          'mergeTableCells': mergeTableCells!.toJson(),
        if (refreshSheetsChart != null)
          'refreshSheetsChart': refreshSheetsChart!.toJson(),
        if (replaceAllShapesWithImage != null)
          'replaceAllShapesWithImage': replaceAllShapesWithImage!.toJson(),
        if (replaceAllShapesWithSheetsChart != null)
          'replaceAllShapesWithSheetsChart':
              replaceAllShapesWithSheetsChart!.toJson(),
        if (replaceAllText != null) 'replaceAllText': replaceAllText!.toJson(),
        if (replaceImage != null) 'replaceImage': replaceImage!.toJson(),
        if (rerouteLine != null) 'rerouteLine': rerouteLine!.toJson(),
        if (ungroupObjects != null) 'ungroupObjects': ungroupObjects!.toJson(),
        if (unmergeTableCells != null)
          'unmergeTableCells': unmergeTableCells!.toJson(),
        if (updateImageProperties != null)
          'updateImageProperties': updateImageProperties!.toJson(),
        if (updateLineCategory != null)
          'updateLineCategory': updateLineCategory!.toJson(),
        if (updateLineProperties != null)
          'updateLineProperties': updateLineProperties!.toJson(),
        if (updatePageElementAltText != null)
          'updatePageElementAltText': updatePageElementAltText!.toJson(),
        if (updatePageElementTransform != null)
          'updatePageElementTransform': updatePageElementTransform!.toJson(),
        if (updatePageElementsZOrder != null)
          'updatePageElementsZOrder': updatePageElementsZOrder!.toJson(),
        if (updatePageProperties != null)
          'updatePageProperties': updatePageProperties!.toJson(),
        if (updateParagraphStyle != null)
          'updateParagraphStyle': updateParagraphStyle!.toJson(),
        if (updateShapeProperties != null)
          'updateShapeProperties': updateShapeProperties!.toJson(),
        if (updateSlidesPosition != null)
          'updateSlidesPosition': updateSlidesPosition!.toJson(),
        if (updateTableBorderProperties != null)
          'updateTableBorderProperties': updateTableBorderProperties!.toJson(),
        if (updateTableCellProperties != null)
          'updateTableCellProperties': updateTableCellProperties!.toJson(),
        if (updateTableColumnProperties != null)
          'updateTableColumnProperties': updateTableColumnProperties!.toJson(),
        if (updateTableRowProperties != null)
          'updateTableRowProperties': updateTableRowProperties!.toJson(),
        if (updateTextStyle != null)
          'updateTextStyle': updateTextStyle!.toJson(),
        if (updateVideoProperties != null)
          'updateVideoProperties': updateVideoProperties!.toJson(),
      };
}

/// Reroutes a line such that it's connected at the two closest connection sites
/// on the connected page elements.
class RerouteLineRequest {
  /// The object ID of the line to reroute.
  ///
  /// Only a line with a category indicating it is a "connector" can be
  /// rerouted. The start and end connections of the line must be on different
  /// page elements.
  core.String? objectId;

  RerouteLineRequest();

  RerouteLineRequest.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// A single response from an update.
class Response {
  /// The result of creating an image.
  CreateImageResponse? createImage;

  /// The result of creating a line.
  CreateLineResponse? createLine;

  /// The result of creating a shape.
  CreateShapeResponse? createShape;

  /// The result of creating a Google Sheets chart.
  CreateSheetsChartResponse? createSheetsChart;

  /// The result of creating a slide.
  CreateSlideResponse? createSlide;

  /// The result of creating a table.
  CreateTableResponse? createTable;

  /// The result of creating a video.
  CreateVideoResponse? createVideo;

  /// The result of duplicating an object.
  DuplicateObjectResponse? duplicateObject;

  /// The result of grouping objects.
  GroupObjectsResponse? groupObjects;

  /// The result of replacing all shapes matching some criteria with an image.
  ReplaceAllShapesWithImageResponse? replaceAllShapesWithImage;

  /// The result of replacing all shapes matching some criteria with a Google
  /// Sheets chart.
  ReplaceAllShapesWithSheetsChartResponse? replaceAllShapesWithSheetsChart;

  /// The result of replacing text.
  ReplaceAllTextResponse? replaceAllText;

  Response();

  Response.fromJson(core.Map _json) {
    if (_json.containsKey('createImage')) {
      createImage = CreateImageResponse.fromJson(
          _json['createImage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createLine')) {
      createLine = CreateLineResponse.fromJson(
          _json['createLine'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createShape')) {
      createShape = CreateShapeResponse.fromJson(
          _json['createShape'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createSheetsChart')) {
      createSheetsChart = CreateSheetsChartResponse.fromJson(
          _json['createSheetsChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createSlide')) {
      createSlide = CreateSlideResponse.fromJson(
          _json['createSlide'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTable')) {
      createTable = CreateTableResponse.fromJson(
          _json['createTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createVideo')) {
      createVideo = CreateVideoResponse.fromJson(
          _json['createVideo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('duplicateObject')) {
      duplicateObject = DuplicateObjectResponse.fromJson(
          _json['duplicateObject'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('groupObjects')) {
      groupObjects = GroupObjectsResponse.fromJson(
          _json['groupObjects'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replaceAllShapesWithImage')) {
      replaceAllShapesWithImage = ReplaceAllShapesWithImageResponse.fromJson(
          _json['replaceAllShapesWithImage']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replaceAllShapesWithSheetsChart')) {
      replaceAllShapesWithSheetsChart =
          ReplaceAllShapesWithSheetsChartResponse.fromJson(
              _json['replaceAllShapesWithSheetsChart']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replaceAllText')) {
      replaceAllText = ReplaceAllTextResponse.fromJson(
          _json['replaceAllText'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createImage != null) 'createImage': createImage!.toJson(),
        if (createLine != null) 'createLine': createLine!.toJson(),
        if (createShape != null) 'createShape': createShape!.toJson(),
        if (createSheetsChart != null)
          'createSheetsChart': createSheetsChart!.toJson(),
        if (createSlide != null) 'createSlide': createSlide!.toJson(),
        if (createTable != null) 'createTable': createTable!.toJson(),
        if (createVideo != null) 'createVideo': createVideo!.toJson(),
        if (duplicateObject != null)
          'duplicateObject': duplicateObject!.toJson(),
        if (groupObjects != null) 'groupObjects': groupObjects!.toJson(),
        if (replaceAllShapesWithImage != null)
          'replaceAllShapesWithImage': replaceAllShapesWithImage!.toJson(),
        if (replaceAllShapesWithSheetsChart != null)
          'replaceAllShapesWithSheetsChart':
              replaceAllShapesWithSheetsChart!.toJson(),
        if (replaceAllText != null) 'replaceAllText': replaceAllText!.toJson(),
      };
}

/// An RGB color.
class RgbColor {
  /// The blue component of the color, from 0.0 to 1.0.
  core.double? blue;

  /// The green component of the color, from 0.0 to 1.0.
  core.double? green;

  /// The red component of the color, from 0.0 to 1.0.
  core.double? red;

  RgbColor();

  RgbColor.fromJson(core.Map _json) {
    if (_json.containsKey('blue')) {
      blue = (_json['blue'] as core.num).toDouble();
    }
    if (_json.containsKey('green')) {
      green = (_json['green'] as core.num).toDouble();
    }
    if (_json.containsKey('red')) {
      red = (_json['red'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (blue != null) 'blue': blue!,
        if (green != null) 'green': green!,
        if (red != null) 'red': red!,
      };
}

/// The shadow properties of a page element.
///
/// If these fields are unset, they may be inherited from a parent placeholder
/// if it exists. If there is no parent, the fields will default to the value
/// used for new page elements created in the Slides editor, which may depend on
/// the page element kind.
class Shadow {
  /// The alignment point of the shadow, that sets the origin for translate,
  /// scale and skew of the shadow.
  ///
  /// This property is read-only.
  /// Possible string values are:
  /// - "RECTANGLE_POSITION_UNSPECIFIED" : Unspecified.
  /// - "TOP_LEFT" : Top left.
  /// - "TOP_CENTER" : Top center.
  /// - "TOP_RIGHT" : Top right.
  /// - "LEFT_CENTER" : Left center.
  /// - "CENTER" : Center.
  /// - "RIGHT_CENTER" : Right center.
  /// - "BOTTOM_LEFT" : Bottom left.
  /// - "BOTTOM_CENTER" : Bottom center.
  /// - "BOTTOM_RIGHT" : Bottom right.
  core.String? alignment;

  /// The alpha of the shadow's color, from 0.0 to 1.0.
  core.double? alpha;

  /// The radius of the shadow blur.
  ///
  /// The larger the radius, the more diffuse the shadow becomes.
  Dimension? blurRadius;

  /// The shadow color value.
  OpaqueColor? color;

  /// The shadow property state.
  ///
  /// Updating the shadow on a page element will implicitly update this field to
  /// `RENDERED`, unless another value is specified in the same request. To have
  /// no shadow on a page element, set this field to `NOT_RENDERED`. In this
  /// case, any other shadow fields set in the same request will be ignored.
  /// Possible string values are:
  /// - "RENDERED" : If a property's state is RENDERED, then the element has the
  /// corresponding property when rendered on a page. If the element is a
  /// placeholder shape as determined by the placeholder field, and it inherits
  /// from a placeholder shape, the corresponding field may be unset, meaning
  /// that the property value is inherited from a parent placeholder. If the
  /// element does not inherit, then the field will contain the rendered value.
  /// This is the default value.
  /// - "NOT_RENDERED" : If a property's state is NOT_RENDERED, then the element
  /// does not have the corresponding property when rendered on a page. However,
  /// the field may still be set so it can be inherited by child shapes. To
  /// remove a property from a rendered element, set its property_state to
  /// NOT_RENDERED.
  /// - "INHERIT" : If a property's state is INHERIT, then the property state
  /// uses the value of corresponding `property_state` field on the parent
  /// shape. Elements that do not inherit will never have an INHERIT property
  /// state.
  core.String? propertyState;

  /// Whether the shadow should rotate with the shape.
  ///
  /// This property is read-only.
  core.bool? rotateWithShape;

  /// Transform that encodes the translate, scale, and skew of the shadow,
  /// relative to the alignment position.
  AffineTransform? transform;

  /// The type of the shadow.
  ///
  /// This property is read-only.
  /// Possible string values are:
  /// - "SHADOW_TYPE_UNSPECIFIED" : Unspecified shadow type.
  /// - "OUTER" : Outer shadow.
  core.String? type;

  Shadow();

  Shadow.fromJson(core.Map _json) {
    if (_json.containsKey('alignment')) {
      alignment = _json['alignment'] as core.String;
    }
    if (_json.containsKey('alpha')) {
      alpha = (_json['alpha'] as core.num).toDouble();
    }
    if (_json.containsKey('blurRadius')) {
      blurRadius = Dimension.fromJson(
          _json['blurRadius'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('color')) {
      color = OpaqueColor.fromJson(
          _json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('propertyState')) {
      propertyState = _json['propertyState'] as core.String;
    }
    if (_json.containsKey('rotateWithShape')) {
      rotateWithShape = _json['rotateWithShape'] as core.bool;
    }
    if (_json.containsKey('transform')) {
      transform = AffineTransform.fromJson(
          _json['transform'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alignment != null) 'alignment': alignment!,
        if (alpha != null) 'alpha': alpha!,
        if (blurRadius != null) 'blurRadius': blurRadius!.toJson(),
        if (color != null) 'color': color!.toJson(),
        if (propertyState != null) 'propertyState': propertyState!,
        if (rotateWithShape != null) 'rotateWithShape': rotateWithShape!,
        if (transform != null) 'transform': transform!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// A PageElement kind representing a generic shape that does not have a more
/// specific classification.
class Shape {
  /// Placeholders are shapes that are inherit from corresponding placeholders
  /// on layouts and masters.
  ///
  /// If set, the shape is a placeholder shape and any inherited properties can
  /// be resolved by looking at the parent placeholder identified by the
  /// Placeholder.parent_object_id field.
  Placeholder? placeholder;

  /// The properties of the shape.
  ShapeProperties? shapeProperties;

  /// The type of the shape.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : The shape type that is not predefined.
  /// - "TEXT_BOX" : Text box shape.
  /// - "RECTANGLE" : Rectangle shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'rect'.
  /// - "ROUND_RECTANGLE" : Round corner rectangle shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'roundRect'
  /// - "ELLIPSE" : Ellipse shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'ellipse'
  /// - "ARC" : Curved arc shape. Corresponds to ECMA-376 ST_ShapeType 'arc'
  /// - "BENT_ARROW" : Bent arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'bentArrow'
  /// - "BENT_UP_ARROW" : Bent up arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'bentUpArrow'
  /// - "BEVEL" : Bevel shape. Corresponds to ECMA-376 ST_ShapeType 'bevel'
  /// - "BLOCK_ARC" : Block arc shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'blockArc'
  /// - "BRACE_PAIR" : Brace pair shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'bracePair'
  /// - "BRACKET_PAIR" : Bracket pair shape. Corresponds to ECMA-376
  /// ST_ShapeType 'bracketPair'
  /// - "CAN" : Can shape. Corresponds to ECMA-376 ST_ShapeType 'can'
  /// - "CHEVRON" : Chevron shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'chevron'
  /// - "CHORD" : Chord shape. Corresponds to ECMA-376 ST_ShapeType 'chord'
  /// - "CLOUD" : Cloud shape. Corresponds to ECMA-376 ST_ShapeType 'cloud'
  /// - "CORNER" : Corner shape. Corresponds to ECMA-376 ST_ShapeType 'corner'
  /// - "CUBE" : Cube shape. Corresponds to ECMA-376 ST_ShapeType 'cube'
  /// - "CURVED_DOWN_ARROW" : Curved down arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'curvedDownArrow'
  /// - "CURVED_LEFT_ARROW" : Curved left arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'curvedLeftArrow'
  /// - "CURVED_RIGHT_ARROW" : Curved right arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'curvedRightArrow'
  /// - "CURVED_UP_ARROW" : Curved up arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'curvedUpArrow'
  /// - "DECAGON" : Decagon shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'decagon'
  /// - "DIAGONAL_STRIPE" : Diagonal stripe shape. Corresponds to ECMA-376
  /// ST_ShapeType 'diagStripe'
  /// - "DIAMOND" : Diamond shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'diamond'
  /// - "DODECAGON" : Dodecagon shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'dodecagon'
  /// - "DONUT" : Donut shape. Corresponds to ECMA-376 ST_ShapeType 'donut'
  /// - "DOUBLE_WAVE" : Double wave shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'doubleWave'
  /// - "DOWN_ARROW" : Down arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'downArrow'
  /// - "DOWN_ARROW_CALLOUT" : Callout down arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'downArrowCallout'
  /// - "FOLDED_CORNER" : Folded corner shape. Corresponds to ECMA-376
  /// ST_ShapeType 'foldedCorner'
  /// - "FRAME" : Frame shape. Corresponds to ECMA-376 ST_ShapeType 'frame'
  /// - "HALF_FRAME" : Half frame shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'halfFrame'
  /// - "HEART" : Heart shape. Corresponds to ECMA-376 ST_ShapeType 'heart'
  /// - "HEPTAGON" : Heptagon shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'heptagon'
  /// - "HEXAGON" : Hexagon shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'hexagon'
  /// - "HOME_PLATE" : Home plate shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'homePlate'
  /// - "HORIZONTAL_SCROLL" : Horizontal scroll shape. Corresponds to ECMA-376
  /// ST_ShapeType 'horizontalScroll'
  /// - "IRREGULAR_SEAL_1" : Irregular seal 1 shape. Corresponds to ECMA-376
  /// ST_ShapeType 'irregularSeal1'
  /// - "IRREGULAR_SEAL_2" : Irregular seal 2 shape. Corresponds to ECMA-376
  /// ST_ShapeType 'irregularSeal2'
  /// - "LEFT_ARROW" : Left arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'leftArrow'
  /// - "LEFT_ARROW_CALLOUT" : Callout left arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'leftArrowCallout'
  /// - "LEFT_BRACE" : Left brace shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'leftBrace'
  /// - "LEFT_BRACKET" : Left bracket shape. Corresponds to ECMA-376
  /// ST_ShapeType 'leftBracket'
  /// - "LEFT_RIGHT_ARROW" : Left right arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'leftRightArrow'
  /// - "LEFT_RIGHT_ARROW_CALLOUT" : Callout left right arrow shape. Corresponds
  /// to ECMA-376 ST_ShapeType 'leftRightArrowCallout'
  /// - "LEFT_RIGHT_UP_ARROW" : Left right up arrow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'leftRightUpArrow'
  /// - "LEFT_UP_ARROW" : Left up arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'leftUpArrow'
  /// - "LIGHTNING_BOLT" : Lightning bolt shape. Corresponds to ECMA-376
  /// ST_ShapeType 'lightningBolt'
  /// - "MATH_DIVIDE" : Divide math shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'mathDivide'
  /// - "MATH_EQUAL" : Equal math shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'mathEqual'
  /// - "MATH_MINUS" : Minus math shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'mathMinus'
  /// - "MATH_MULTIPLY" : Multiply math shape. Corresponds to ECMA-376
  /// ST_ShapeType 'mathMultiply'
  /// - "MATH_NOT_EQUAL" : Not equal math shape. Corresponds to ECMA-376
  /// ST_ShapeType 'mathNotEqual'
  /// - "MATH_PLUS" : Plus math shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'mathPlus'
  /// - "MOON" : Moon shape. Corresponds to ECMA-376 ST_ShapeType 'moon'
  /// - "NO_SMOKING" : No smoking shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'noSmoking'
  /// - "NOTCHED_RIGHT_ARROW" : Notched right arrow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'notchedRightArrow'
  /// - "OCTAGON" : Octagon shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'octagon'
  /// - "PARALLELOGRAM" : Parallelogram shape. Corresponds to ECMA-376
  /// ST_ShapeType 'parallelogram'
  /// - "PENTAGON" : Pentagon shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'pentagon'
  /// - "PIE" : Pie shape. Corresponds to ECMA-376 ST_ShapeType 'pie'
  /// - "PLAQUE" : Plaque shape. Corresponds to ECMA-376 ST_ShapeType 'plaque'
  /// - "PLUS" : Plus shape. Corresponds to ECMA-376 ST_ShapeType 'plus'
  /// - "QUAD_ARROW" : Quad-arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'quadArrow'
  /// - "QUAD_ARROW_CALLOUT" : Callout quad-arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'quadArrowCallout'
  /// - "RIBBON" : Ribbon shape. Corresponds to ECMA-376 ST_ShapeType 'ribbon'
  /// - "RIBBON_2" : Ribbon 2 shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'ribbon2'
  /// - "RIGHT_ARROW" : Right arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'rightArrow'
  /// - "RIGHT_ARROW_CALLOUT" : Callout right arrow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'rightArrowCallout'
  /// - "RIGHT_BRACE" : Right brace shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'rightBrace'
  /// - "RIGHT_BRACKET" : Right bracket shape. Corresponds to ECMA-376
  /// ST_ShapeType 'rightBracket'
  /// - "ROUND_1_RECTANGLE" : One round corner rectangle shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'round1Rect'
  /// - "ROUND_2_DIAGONAL_RECTANGLE" : Two diagonal round corner rectangle
  /// shape. Corresponds to ECMA-376 ST_ShapeType 'round2DiagRect'
  /// - "ROUND_2_SAME_RECTANGLE" : Two same-side round corner rectangle shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'round2SameRect'
  /// - "RIGHT_TRIANGLE" : Right triangle shape. Corresponds to ECMA-376
  /// ST_ShapeType 'rtTriangle'
  /// - "SMILEY_FACE" : Smiley face shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'smileyFace'
  /// - "SNIP_1_RECTANGLE" : One snip corner rectangle shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'snip1Rect'
  /// - "SNIP_2_DIAGONAL_RECTANGLE" : Two diagonal snip corner rectangle shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'snip2DiagRect'
  /// - "SNIP_2_SAME_RECTANGLE" : Two same-side snip corner rectangle shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'snip2SameRect'
  /// - "SNIP_ROUND_RECTANGLE" : One snip one round corner rectangle shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'snipRoundRect'
  /// - "STAR_10" : Ten pointed star shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'star10'
  /// - "STAR_12" : Twelve pointed star shape. Corresponds to ECMA-376
  /// ST_ShapeType 'star12'
  /// - "STAR_16" : Sixteen pointed star shape. Corresponds to ECMA-376
  /// ST_ShapeType 'star16'
  /// - "STAR_24" : Twenty four pointed star shape. Corresponds to ECMA-376
  /// ST_ShapeType 'star24'
  /// - "STAR_32" : Thirty two pointed star shape. Corresponds to ECMA-376
  /// ST_ShapeType 'star32'
  /// - "STAR_4" : Four pointed star shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'star4'
  /// - "STAR_5" : Five pointed star shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'star5'
  /// - "STAR_6" : Six pointed star shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'star6'
  /// - "STAR_7" : Seven pointed star shape. Corresponds to ECMA-376
  /// ST_ShapeType 'star7'
  /// - "STAR_8" : Eight pointed star shape. Corresponds to ECMA-376
  /// ST_ShapeType 'star8'
  /// - "STRIPED_RIGHT_ARROW" : Striped right arrow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'stripedRightArrow'
  /// - "SUN" : Sun shape. Corresponds to ECMA-376 ST_ShapeType 'sun'
  /// - "TRAPEZOID" : Trapezoid shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'trapezoid'
  /// - "TRIANGLE" : Triangle shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'triangle'
  /// - "UP_ARROW" : Up arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'upArrow'
  /// - "UP_ARROW_CALLOUT" : Callout up arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'upArrowCallout'
  /// - "UP_DOWN_ARROW" : Up down arrow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'upDownArrow'
  /// - "UTURN_ARROW" : U-turn arrow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'uturnArrow'
  /// - "VERTICAL_SCROLL" : Vertical scroll shape. Corresponds to ECMA-376
  /// ST_ShapeType 'verticalScroll'
  /// - "WAVE" : Wave shape. Corresponds to ECMA-376 ST_ShapeType 'wave'
  /// - "WEDGE_ELLIPSE_CALLOUT" : Callout wedge ellipse shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'wedgeEllipseCallout'
  /// - "WEDGE_RECTANGLE_CALLOUT" : Callout wedge rectangle shape. Corresponds
  /// to ECMA-376 ST_ShapeType 'wedgeRectCallout'
  /// - "WEDGE_ROUND_RECTANGLE_CALLOUT" : Callout wedge round rectangle shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'wedgeRoundRectCallout'
  /// - "FLOW_CHART_ALTERNATE_PROCESS" : Alternate process flow shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'flowChartAlternateProcess'
  /// - "FLOW_CHART_COLLATE" : Collate flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartCollate'
  /// - "FLOW_CHART_CONNECTOR" : Connector flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartConnector'
  /// - "FLOW_CHART_DECISION" : Decision flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartDecision'
  /// - "FLOW_CHART_DELAY" : Delay flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartDelay'
  /// - "FLOW_CHART_DISPLAY" : Display flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartDisplay'
  /// - "FLOW_CHART_DOCUMENT" : Document flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartDocument'
  /// - "FLOW_CHART_EXTRACT" : Extract flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartExtract'
  /// - "FLOW_CHART_INPUT_OUTPUT" : Input output flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartInputOutput'
  /// - "FLOW_CHART_INTERNAL_STORAGE" : Internal storage flow shape. Corresponds
  /// to ECMA-376 ST_ShapeType 'flowChartInternalStorage'
  /// - "FLOW_CHART_MAGNETIC_DISK" : Magnetic disk flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartMagneticDisk'
  /// - "FLOW_CHART_MAGNETIC_DRUM" : Magnetic drum flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartMagneticDrum'
  /// - "FLOW_CHART_MAGNETIC_TAPE" : Magnetic tape flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartMagneticTape'
  /// - "FLOW_CHART_MANUAL_INPUT" : Manual input flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartManualInput'
  /// - "FLOW_CHART_MANUAL_OPERATION" : Manual operation flow shape. Corresponds
  /// to ECMA-376 ST_ShapeType 'flowChartManualOperation'
  /// - "FLOW_CHART_MERGE" : Merge flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartMerge'
  /// - "FLOW_CHART_MULTIDOCUMENT" : Multi-document flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartMultidocument'
  /// - "FLOW_CHART_OFFLINE_STORAGE" : Offline storage flow shape. Corresponds
  /// to ECMA-376 ST_ShapeType 'flowChartOfflineStorage'
  /// - "FLOW_CHART_OFFPAGE_CONNECTOR" : Off-page connector flow shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'flowChartOffpageConnector'
  /// - "FLOW_CHART_ONLINE_STORAGE" : Online storage flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartOnlineStorage'
  /// - "FLOW_CHART_OR" : Or flow shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'flowChartOr'
  /// - "FLOW_CHART_PREDEFINED_PROCESS" : Predefined process flow shape.
  /// Corresponds to ECMA-376 ST_ShapeType 'flowChartPredefinedProcess'
  /// - "FLOW_CHART_PREPARATION" : Preparation flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartPreparation'
  /// - "FLOW_CHART_PROCESS" : Process flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartProcess'
  /// - "FLOW_CHART_PUNCHED_CARD" : Punched card flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartPunchedCard'
  /// - "FLOW_CHART_PUNCHED_TAPE" : Punched tape flow shape. Corresponds to
  /// ECMA-376 ST_ShapeType 'flowChartPunchedTape'
  /// - "FLOW_CHART_SORT" : Sort flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartSort'
  /// - "FLOW_CHART_SUMMING_JUNCTION" : Summing junction flow shape. Corresponds
  /// to ECMA-376 ST_ShapeType 'flowChartSummingJunction'
  /// - "FLOW_CHART_TERMINATOR" : Terminator flow shape. Corresponds to ECMA-376
  /// ST_ShapeType 'flowChartTerminator'
  /// - "ARROW_EAST" : East arrow shape.
  /// - "ARROW_NORTH_EAST" : Northeast arrow shape.
  /// - "ARROW_NORTH" : North arrow shape.
  /// - "SPEECH" : Speech shape.
  /// - "STARBURST" : Star burst shape.
  /// - "TEARDROP" : Teardrop shape. Corresponds to ECMA-376 ST_ShapeType
  /// 'teardrop'
  /// - "ELLIPSE_RIBBON" : Ellipse ribbon shape. Corresponds to ECMA-376
  /// ST_ShapeType 'ellipseRibbon'
  /// - "ELLIPSE_RIBBON_2" : Ellipse ribbon 2 shape. Corresponds to ECMA-376
  /// ST_ShapeType 'ellipseRibbon2'
  /// - "CLOUD_CALLOUT" : Callout cloud shape. Corresponds to ECMA-376
  /// ST_ShapeType 'cloudCallout'
  /// - "CUSTOM" : Custom shape.
  core.String? shapeType;

  /// The text content of the shape.
  TextContent? text;

  Shape();

  Shape.fromJson(core.Map _json) {
    if (_json.containsKey('placeholder')) {
      placeholder = Placeholder.fromJson(
          _json['placeholder'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shapeProperties')) {
      shapeProperties = ShapeProperties.fromJson(
          _json['shapeProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shapeType')) {
      shapeType = _json['shapeType'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = TextContent.fromJson(
          _json['text'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (placeholder != null) 'placeholder': placeholder!.toJson(),
        if (shapeProperties != null)
          'shapeProperties': shapeProperties!.toJson(),
        if (shapeType != null) 'shapeType': shapeType!,
        if (text != null) 'text': text!.toJson(),
      };
}

/// The shape background fill.
class ShapeBackgroundFill {
  /// The background fill property state.
  ///
  /// Updating the fill on a shape will implicitly update this field to
  /// `RENDERED`, unless another value is specified in the same request. To have
  /// no fill on a shape, set this field to `NOT_RENDERED`. In this case, any
  /// other fill fields set in the same request will be ignored.
  /// Possible string values are:
  /// - "RENDERED" : If a property's state is RENDERED, then the element has the
  /// corresponding property when rendered on a page. If the element is a
  /// placeholder shape as determined by the placeholder field, and it inherits
  /// from a placeholder shape, the corresponding field may be unset, meaning
  /// that the property value is inherited from a parent placeholder. If the
  /// element does not inherit, then the field will contain the rendered value.
  /// This is the default value.
  /// - "NOT_RENDERED" : If a property's state is NOT_RENDERED, then the element
  /// does not have the corresponding property when rendered on a page. However,
  /// the field may still be set so it can be inherited by child shapes. To
  /// remove a property from a rendered element, set its property_state to
  /// NOT_RENDERED.
  /// - "INHERIT" : If a property's state is INHERIT, then the property state
  /// uses the value of corresponding `property_state` field on the parent
  /// shape. Elements that do not inherit will never have an INHERIT property
  /// state.
  core.String? propertyState;

  /// Solid color fill.
  SolidFill? solidFill;

  ShapeBackgroundFill();

  ShapeBackgroundFill.fromJson(core.Map _json) {
    if (_json.containsKey('propertyState')) {
      propertyState = _json['propertyState'] as core.String;
    }
    if (_json.containsKey('solidFill')) {
      solidFill = SolidFill.fromJson(
          _json['solidFill'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (propertyState != null) 'propertyState': propertyState!,
        if (solidFill != null) 'solidFill': solidFill!.toJson(),
      };
}

/// The properties of a Shape.
///
/// If the shape is a placeholder shape as determined by the placeholder field,
/// then these properties may be inherited from a parent placeholder shape.
/// Determining the rendered value of the property depends on the corresponding
/// property_state field value. Any text autofit settings on the shape are
/// automatically deactivated by requests that can impact how text fits in the
/// shape.
class ShapeProperties {
  /// The autofit properties of the shape.
  ///
  /// This property is only set for shapes that allow text.
  Autofit? autofit;

  /// The alignment of the content in the shape.
  ///
  /// If unspecified, the alignment is inherited from a parent placeholder if it
  /// exists. If the shape has no parent, the default alignment matches the
  /// alignment for new shapes created in the Slides editor.
  /// Possible string values are:
  /// - "CONTENT_ALIGNMENT_UNSPECIFIED" : An unspecified content alignment. The
  /// content alignment is inherited from the parent if it exists.
  /// - "CONTENT_ALIGNMENT_UNSUPPORTED" : An unsupported content alignment.
  /// - "TOP" : An alignment that aligns the content to the top of the content
  /// holder. Corresponds to ECMA-376 ST_TextAnchoringType 't'.
  /// - "MIDDLE" : An alignment that aligns the content to the middle of the
  /// content holder. Corresponds to ECMA-376 ST_TextAnchoringType 'ctr'.
  /// - "BOTTOM" : An alignment that aligns the content to the bottom of the
  /// content holder. Corresponds to ECMA-376 ST_TextAnchoringType 'b'.
  core.String? contentAlignment;

  /// The hyperlink destination of the shape.
  ///
  /// If unset, there is no link. Links are not inherited from parent
  /// placeholders.
  Link? link;

  /// The outline of the shape.
  ///
  /// If unset, the outline is inherited from a parent placeholder if it exists.
  /// If the shape has no parent, then the default outline depends on the shape
  /// type, matching the defaults for new shapes created in the Slides editor.
  Outline? outline;

  /// The shadow properties of the shape.
  ///
  /// If unset, the shadow is inherited from a parent placeholder if it exists.
  /// If the shape has no parent, then the default shadow matches the defaults
  /// for new shapes created in the Slides editor. This property is read-only.
  Shadow? shadow;

  /// The background fill of the shape.
  ///
  /// If unset, the background fill is inherited from a parent placeholder if it
  /// exists. If the shape has no parent, then the default background fill
  /// depends on the shape type, matching the defaults for new shapes created in
  /// the Slides editor.
  ShapeBackgroundFill? shapeBackgroundFill;

  ShapeProperties();

  ShapeProperties.fromJson(core.Map _json) {
    if (_json.containsKey('autofit')) {
      autofit = Autofit.fromJson(
          _json['autofit'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentAlignment')) {
      contentAlignment = _json['contentAlignment'] as core.String;
    }
    if (_json.containsKey('link')) {
      link =
          Link.fromJson(_json['link'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('outline')) {
      outline = Outline.fromJson(
          _json['outline'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shadow')) {
      shadow = Shadow.fromJson(
          _json['shadow'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shapeBackgroundFill')) {
      shapeBackgroundFill = ShapeBackgroundFill.fromJson(
          _json['shapeBackgroundFill'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autofit != null) 'autofit': autofit!.toJson(),
        if (contentAlignment != null) 'contentAlignment': contentAlignment!,
        if (link != null) 'link': link!.toJson(),
        if (outline != null) 'outline': outline!.toJson(),
        if (shadow != null) 'shadow': shadow!.toJson(),
        if (shapeBackgroundFill != null)
          'shapeBackgroundFill': shapeBackgroundFill!.toJson(),
      };
}

/// A PageElement kind representing a linked chart embedded from Google Sheets.
class SheetsChart {
  /// The ID of the specific chart in the Google Sheets spreadsheet that is
  /// embedded.
  core.int? chartId;

  /// The URL of an image of the embedded chart, with a default lifetime of 30
  /// minutes.
  ///
  /// This URL is tagged with the account of the requester. Anyone with the URL
  /// effectively accesses the image as the original requester. Access to the
  /// image may be lost if the presentation's sharing settings change.
  core.String? contentUrl;

  /// The properties of the Sheets chart.
  SheetsChartProperties? sheetsChartProperties;

  /// The ID of the Google Sheets spreadsheet that contains the source chart.
  core.String? spreadsheetId;

  SheetsChart();

  SheetsChart.fromJson(core.Map _json) {
    if (_json.containsKey('chartId')) {
      chartId = _json['chartId'] as core.int;
    }
    if (_json.containsKey('contentUrl')) {
      contentUrl = _json['contentUrl'] as core.String;
    }
    if (_json.containsKey('sheetsChartProperties')) {
      sheetsChartProperties = SheetsChartProperties.fromJson(
          _json['sheetsChartProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chartId != null) 'chartId': chartId!,
        if (contentUrl != null) 'contentUrl': contentUrl!,
        if (sheetsChartProperties != null)
          'sheetsChartProperties': sheetsChartProperties!.toJson(),
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
      };
}

/// The properties of the SheetsChart.
class SheetsChartProperties {
  /// The properties of the embedded chart image.
  ImageProperties? chartImageProperties;

  SheetsChartProperties();

  SheetsChartProperties.fromJson(core.Map _json) {
    if (_json.containsKey('chartImageProperties')) {
      chartImageProperties = ImageProperties.fromJson(
          _json['chartImageProperties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chartImageProperties != null)
          'chartImageProperties': chartImageProperties!.toJson(),
      };
}

/// A width and height.
class Size {
  /// The height of the object.
  Dimension? height;

  /// The width of the object.
  Dimension? width;

  Size();

  Size.fromJson(core.Map _json) {
    if (_json.containsKey('height')) {
      height = Dimension.fromJson(
          _json['height'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('width')) {
      width = Dimension.fromJson(
          _json['width'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (height != null) 'height': height!.toJson(),
        if (width != null) 'width': width!.toJson(),
      };
}

/// The properties of Page that are only relevant for pages with page_type
/// SLIDE.
class SlideProperties {
  /// The object ID of the layout that this slide is based on.
  ///
  /// This property is read-only.
  core.String? layoutObjectId;

  /// The object ID of the master that this slide is based on.
  ///
  /// This property is read-only.
  core.String? masterObjectId;

  /// The notes page that this slide is associated with.
  ///
  /// It defines the visual appearance of a notes page when printing or
  /// exporting slides with speaker notes. A notes page inherits properties from
  /// the notes master. The placeholder shape with type BODY on the notes page
  /// contains the speaker notes for this slide. The ID of this shape is
  /// identified by the speakerNotesObjectId field. The notes page is read-only
  /// except for the text content and styles of the speaker notes shape. This
  /// property is read-only.
  Page? notesPage;

  SlideProperties();

  SlideProperties.fromJson(core.Map _json) {
    if (_json.containsKey('layoutObjectId')) {
      layoutObjectId = _json['layoutObjectId'] as core.String;
    }
    if (_json.containsKey('masterObjectId')) {
      masterObjectId = _json['masterObjectId'] as core.String;
    }
    if (_json.containsKey('notesPage')) {
      notesPage = Page.fromJson(
          _json['notesPage'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (layoutObjectId != null) 'layoutObjectId': layoutObjectId!,
        if (masterObjectId != null) 'masterObjectId': masterObjectId!,
        if (notesPage != null) 'notesPage': notesPage!.toJson(),
      };
}

/// A solid color fill.
///
/// The page or page element is filled entirely with the specified color value.
/// If any field is unset, its value may be inherited from a parent placeholder
/// if it exists.
class SolidFill {
  /// The fraction of this `color` that should be applied to the pixel.
  ///
  /// That is, the final pixel color is defined by the equation: pixel color =
  /// alpha * (color) + (1.0 - alpha) * (background color) This means that a
  /// value of 1.0 corresponds to a solid color, whereas a value of 0.0
  /// corresponds to a completely transparent color.
  core.double? alpha;

  /// The color value of the solid fill.
  OpaqueColor? color;

  SolidFill();

  SolidFill.fromJson(core.Map _json) {
    if (_json.containsKey('alpha')) {
      alpha = (_json['alpha'] as core.num).toDouble();
    }
    if (_json.containsKey('color')) {
      color = OpaqueColor.fromJson(
          _json['color'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alpha != null) 'alpha': alpha!,
        if (color != null) 'color': color!.toJson(),
      };
}

/// The stretched picture fill.
///
/// The page or page element is filled entirely with the specified picture. The
/// picture is stretched to fit its container.
class StretchedPictureFill {
  /// Reading the content_url: An URL to a picture with a default lifetime of 30
  /// minutes.
  ///
  /// This URL is tagged with the account of the requester. Anyone with the URL
  /// effectively accesses the picture as the original requester. Access to the
  /// picture may be lost if the presentation's sharing settings change. Writing
  /// the content_url: The picture is fetched once at insertion time and a copy
  /// is stored for display inside the presentation. Pictures must be less than
  /// 50MB in size, cannot exceed 25 megapixels, and must be in one of PNG,
  /// JPEG, or GIF format. The provided URL can be at most 2 kB in length.
  core.String? contentUrl;

  /// The original size of the picture fill.
  ///
  /// This field is read-only.
  Size? size;

  StretchedPictureFill();

  StretchedPictureFill.fromJson(core.Map _json) {
    if (_json.containsKey('contentUrl')) {
      contentUrl = _json['contentUrl'] as core.String;
    }
    if (_json.containsKey('size')) {
      size =
          Size.fromJson(_json['size'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentUrl != null) 'contentUrl': contentUrl!,
        if (size != null) 'size': size!.toJson(),
      };
}

/// A criteria that matches a specific string of text in a shape or table.
class SubstringMatchCriteria {
  /// Indicates whether the search should respect case: - `True`: the search is
  /// case sensitive.
  ///
  /// - `False`: the search is case insensitive.
  core.bool? matchCase;

  /// The text to search for in the shape or table.
  core.String? text;

  SubstringMatchCriteria();

  SubstringMatchCriteria.fromJson(core.Map _json) {
    if (_json.containsKey('matchCase')) {
      matchCase = _json['matchCase'] as core.bool;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (matchCase != null) 'matchCase': matchCase!,
        if (text != null) 'text': text!,
      };
}

/// A PageElement kind representing a table.
class Table {
  /// Number of columns in the table.
  core.int? columns;

  /// Properties of horizontal cell borders.
  ///
  /// A table's horizontal cell borders are represented as a grid. The grid has
  /// one more row than the number of rows in the table and the same number of
  /// columns as the table. For example, if the table is 3 x 3, its horizontal
  /// borders will be represented as a grid with 4 rows and 3 columns.
  core.List<TableBorderRow>? horizontalBorderRows;

  /// Number of rows in the table.
  core.int? rows;

  /// Properties of each column.
  core.List<TableColumnProperties>? tableColumns;

  /// Properties and contents of each row.
  ///
  /// Cells that span multiple rows are contained in only one of these rows and
  /// have a row_span greater than 1.
  core.List<TableRow>? tableRows;

  /// Properties of vertical cell borders.
  ///
  /// A table's vertical cell borders are represented as a grid. The grid has
  /// the same number of rows as the table and one more column than the number
  /// of columns in the table. For example, if the table is 3 x 3, its vertical
  /// borders will be represented as a grid with 3 rows and 4 columns.
  core.List<TableBorderRow>? verticalBorderRows;

  Table();

  Table.fromJson(core.Map _json) {
    if (_json.containsKey('columns')) {
      columns = _json['columns'] as core.int;
    }
    if (_json.containsKey('horizontalBorderRows')) {
      horizontalBorderRows = (_json['horizontalBorderRows'] as core.List)
          .map<TableBorderRow>((value) => TableBorderRow.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('rows')) {
      rows = _json['rows'] as core.int;
    }
    if (_json.containsKey('tableColumns')) {
      tableColumns = (_json['tableColumns'] as core.List)
          .map<TableColumnProperties>((value) => TableColumnProperties.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('tableRows')) {
      tableRows = (_json['tableRows'] as core.List)
          .map<TableRow>((value) =>
              TableRow.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('verticalBorderRows')) {
      verticalBorderRows = (_json['verticalBorderRows'] as core.List)
          .map<TableBorderRow>((value) => TableBorderRow.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columns != null) 'columns': columns!,
        if (horizontalBorderRows != null)
          'horizontalBorderRows':
              horizontalBorderRows!.map((value) => value.toJson()).toList(),
        if (rows != null) 'rows': rows!,
        if (tableColumns != null)
          'tableColumns': tableColumns!.map((value) => value.toJson()).toList(),
        if (tableRows != null)
          'tableRows': tableRows!.map((value) => value.toJson()).toList(),
        if (verticalBorderRows != null)
          'verticalBorderRows':
              verticalBorderRows!.map((value) => value.toJson()).toList(),
      };
}

/// The properties of each border cell.
class TableBorderCell {
  /// The location of the border within the border table.
  TableCellLocation? location;

  /// The border properties.
  TableBorderProperties? tableBorderProperties;

  TableBorderCell();

  TableBorderCell.fromJson(core.Map _json) {
    if (_json.containsKey('location')) {
      location = TableCellLocation.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableBorderProperties')) {
      tableBorderProperties = TableBorderProperties.fromJson(
          _json['tableBorderProperties']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (location != null) 'location': location!.toJson(),
        if (tableBorderProperties != null)
          'tableBorderProperties': tableBorderProperties!.toJson(),
      };
}

/// The fill of the border.
class TableBorderFill {
  /// Solid fill.
  SolidFill? solidFill;

  TableBorderFill();

  TableBorderFill.fromJson(core.Map _json) {
    if (_json.containsKey('solidFill')) {
      solidFill = SolidFill.fromJson(
          _json['solidFill'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (solidFill != null) 'solidFill': solidFill!.toJson(),
      };
}

/// The border styling properties of the TableBorderCell.
class TableBorderProperties {
  /// The dash style of the border.
  /// Possible string values are:
  /// - "DASH_STYLE_UNSPECIFIED" : Unspecified dash style.
  /// - "SOLID" : Solid line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'solid'. This is the default dash style.
  /// - "DOT" : Dotted line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'dot'.
  /// - "DASH" : Dashed line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'dash'.
  /// - "DASH_DOT" : Alternating dashes and dots. Corresponds to ECMA-376
  /// ST_PresetLineDashVal value 'dashDot'.
  /// - "LONG_DASH" : Line with large dashes. Corresponds to ECMA-376
  /// ST_PresetLineDashVal value 'lgDash'.
  /// - "LONG_DASH_DOT" : Alternating large dashes and dots. Corresponds to
  /// ECMA-376 ST_PresetLineDashVal value 'lgDashDot'.
  core.String? dashStyle;

  /// The fill of the table border.
  TableBorderFill? tableBorderFill;

  /// The thickness of the border.
  Dimension? weight;

  TableBorderProperties();

  TableBorderProperties.fromJson(core.Map _json) {
    if (_json.containsKey('dashStyle')) {
      dashStyle = _json['dashStyle'] as core.String;
    }
    if (_json.containsKey('tableBorderFill')) {
      tableBorderFill = TableBorderFill.fromJson(
          _json['tableBorderFill'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('weight')) {
      weight = Dimension.fromJson(
          _json['weight'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dashStyle != null) 'dashStyle': dashStyle!,
        if (tableBorderFill != null)
          'tableBorderFill': tableBorderFill!.toJson(),
        if (weight != null) 'weight': weight!.toJson(),
      };
}

/// Contents of each border row in a table.
class TableBorderRow {
  /// Properties of each border cell.
  ///
  /// When a border's adjacent table cells are merged, it is not included in the
  /// response.
  core.List<TableBorderCell>? tableBorderCells;

  TableBorderRow();

  TableBorderRow.fromJson(core.Map _json) {
    if (_json.containsKey('tableBorderCells')) {
      tableBorderCells = (_json['tableBorderCells'] as core.List)
          .map<TableBorderCell>((value) => TableBorderCell.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tableBorderCells != null)
          'tableBorderCells':
              tableBorderCells!.map((value) => value.toJson()).toList(),
      };
}

/// Properties and contents of each table cell.
class TableCell {
  /// Column span of the cell.
  core.int? columnSpan;

  /// The location of the cell within the table.
  TableCellLocation? location;

  /// Row span of the cell.
  core.int? rowSpan;

  /// The properties of the table cell.
  TableCellProperties? tableCellProperties;

  /// The text content of the cell.
  TextContent? text;

  TableCell();

  TableCell.fromJson(core.Map _json) {
    if (_json.containsKey('columnSpan')) {
      columnSpan = _json['columnSpan'] as core.int;
    }
    if (_json.containsKey('location')) {
      location = TableCellLocation.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rowSpan')) {
      rowSpan = _json['rowSpan'] as core.int;
    }
    if (_json.containsKey('tableCellProperties')) {
      tableCellProperties = TableCellProperties.fromJson(
          _json['tableCellProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = TextContent.fromJson(
          _json['text'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnSpan != null) 'columnSpan': columnSpan!,
        if (location != null) 'location': location!.toJson(),
        if (rowSpan != null) 'rowSpan': rowSpan!,
        if (tableCellProperties != null)
          'tableCellProperties': tableCellProperties!.toJson(),
        if (text != null) 'text': text!.toJson(),
      };
}

/// The table cell background fill.
class TableCellBackgroundFill {
  /// The background fill property state.
  ///
  /// Updating the fill on a table cell will implicitly update this field to
  /// `RENDERED`, unless another value is specified in the same request. To have
  /// no fill on a table cell, set this field to `NOT_RENDERED`. In this case,
  /// any other fill fields set in the same request will be ignored.
  /// Possible string values are:
  /// - "RENDERED" : If a property's state is RENDERED, then the element has the
  /// corresponding property when rendered on a page. If the element is a
  /// placeholder shape as determined by the placeholder field, and it inherits
  /// from a placeholder shape, the corresponding field may be unset, meaning
  /// that the property value is inherited from a parent placeholder. If the
  /// element does not inherit, then the field will contain the rendered value.
  /// This is the default value.
  /// - "NOT_RENDERED" : If a property's state is NOT_RENDERED, then the element
  /// does not have the corresponding property when rendered on a page. However,
  /// the field may still be set so it can be inherited by child shapes. To
  /// remove a property from a rendered element, set its property_state to
  /// NOT_RENDERED.
  /// - "INHERIT" : If a property's state is INHERIT, then the property state
  /// uses the value of corresponding `property_state` field on the parent
  /// shape. Elements that do not inherit will never have an INHERIT property
  /// state.
  core.String? propertyState;

  /// Solid color fill.
  SolidFill? solidFill;

  TableCellBackgroundFill();

  TableCellBackgroundFill.fromJson(core.Map _json) {
    if (_json.containsKey('propertyState')) {
      propertyState = _json['propertyState'] as core.String;
    }
    if (_json.containsKey('solidFill')) {
      solidFill = SolidFill.fromJson(
          _json['solidFill'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (propertyState != null) 'propertyState': propertyState!,
        if (solidFill != null) 'solidFill': solidFill!.toJson(),
      };
}

/// A location of a single table cell within a table.
class TableCellLocation {
  /// The 0-based column index.
  core.int? columnIndex;

  /// The 0-based row index.
  core.int? rowIndex;

  TableCellLocation();

  TableCellLocation.fromJson(core.Map _json) {
    if (_json.containsKey('columnIndex')) {
      columnIndex = _json['columnIndex'] as core.int;
    }
    if (_json.containsKey('rowIndex')) {
      rowIndex = _json['rowIndex'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnIndex != null) 'columnIndex': columnIndex!,
        if (rowIndex != null) 'rowIndex': rowIndex!,
      };
}

/// The properties of the TableCell.
class TableCellProperties {
  /// The alignment of the content in the table cell.
  ///
  /// The default alignment matches the alignment for newly created table cells
  /// in the Slides editor.
  /// Possible string values are:
  /// - "CONTENT_ALIGNMENT_UNSPECIFIED" : An unspecified content alignment. The
  /// content alignment is inherited from the parent if it exists.
  /// - "CONTENT_ALIGNMENT_UNSUPPORTED" : An unsupported content alignment.
  /// - "TOP" : An alignment that aligns the content to the top of the content
  /// holder. Corresponds to ECMA-376 ST_TextAnchoringType 't'.
  /// - "MIDDLE" : An alignment that aligns the content to the middle of the
  /// content holder. Corresponds to ECMA-376 ST_TextAnchoringType 'ctr'.
  /// - "BOTTOM" : An alignment that aligns the content to the bottom of the
  /// content holder. Corresponds to ECMA-376 ST_TextAnchoringType 'b'.
  core.String? contentAlignment;

  /// The background fill of the table cell.
  ///
  /// The default fill matches the fill for newly created table cells in the
  /// Slides editor.
  TableCellBackgroundFill? tableCellBackgroundFill;

  TableCellProperties();

  TableCellProperties.fromJson(core.Map _json) {
    if (_json.containsKey('contentAlignment')) {
      contentAlignment = _json['contentAlignment'] as core.String;
    }
    if (_json.containsKey('tableCellBackgroundFill')) {
      tableCellBackgroundFill = TableCellBackgroundFill.fromJson(
          _json['tableCellBackgroundFill']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentAlignment != null) 'contentAlignment': contentAlignment!,
        if (tableCellBackgroundFill != null)
          'tableCellBackgroundFill': tableCellBackgroundFill!.toJson(),
      };
}

/// Properties of each column in a table.
class TableColumnProperties {
  /// Width of a column.
  Dimension? columnWidth;

  TableColumnProperties();

  TableColumnProperties.fromJson(core.Map _json) {
    if (_json.containsKey('columnWidth')) {
      columnWidth = Dimension.fromJson(
          _json['columnWidth'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnWidth != null) 'columnWidth': columnWidth!.toJson(),
      };
}

/// A table range represents a reference to a subset of a table.
///
/// It's important to note that the cells specified by a table range do not
/// necessarily form a rectangle. For example, let's say we have a 3 x 3 table
/// where all the cells of the last row are merged together. The table looks
/// like this: \[ \] A table range with location = (0, 0), row span = 3 and
/// column span = 2 specifies the following cells: x x \[ x x x \]
class TableRange {
  /// The column span of the table range.
  core.int? columnSpan;

  /// The starting location of the table range.
  TableCellLocation? location;

  /// The row span of the table range.
  core.int? rowSpan;

  TableRange();

  TableRange.fromJson(core.Map _json) {
    if (_json.containsKey('columnSpan')) {
      columnSpan = _json['columnSpan'] as core.int;
    }
    if (_json.containsKey('location')) {
      location = TableCellLocation.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rowSpan')) {
      rowSpan = _json['rowSpan'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnSpan != null) 'columnSpan': columnSpan!,
        if (location != null) 'location': location!.toJson(),
        if (rowSpan != null) 'rowSpan': rowSpan!,
      };
}

/// Properties and contents of each row in a table.
class TableRow {
  /// Height of a row.
  Dimension? rowHeight;

  /// Properties and contents of each cell.
  ///
  /// Cells that span multiple columns are represented only once with a
  /// column_span greater than 1. As a result, the length of this collection
  /// does not always match the number of columns of the entire table.
  core.List<TableCell>? tableCells;

  /// Properties of the row.
  TableRowProperties? tableRowProperties;

  TableRow();

  TableRow.fromJson(core.Map _json) {
    if (_json.containsKey('rowHeight')) {
      rowHeight = Dimension.fromJson(
          _json['rowHeight'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableCells')) {
      tableCells = (_json['tableCells'] as core.List)
          .map<TableCell>((value) =>
              TableCell.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('tableRowProperties')) {
      tableRowProperties = TableRowProperties.fromJson(
          _json['tableRowProperties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rowHeight != null) 'rowHeight': rowHeight!.toJson(),
        if (tableCells != null)
          'tableCells': tableCells!.map((value) => value.toJson()).toList(),
        if (tableRowProperties != null)
          'tableRowProperties': tableRowProperties!.toJson(),
      };
}

/// Properties of each row in a table.
class TableRowProperties {
  /// Minimum height of the row.
  ///
  /// The row will be rendered in the Slides editor at a height equal to or
  /// greater than this value in order to show all the text in the row's
  /// cell(s).
  Dimension? minRowHeight;

  TableRowProperties();

  TableRowProperties.fromJson(core.Map _json) {
    if (_json.containsKey('minRowHeight')) {
      minRowHeight = Dimension.fromJson(
          _json['minRowHeight'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (minRowHeight != null) 'minRowHeight': minRowHeight!.toJson(),
      };
}

/// The general text content.
///
/// The text must reside in a compatible shape (e.g. text box or rectangle) or a
/// table cell in a page.
class TextContent {
  /// The bulleted lists contained in this text, keyed by list ID.
  core.Map<core.String, List>? lists;

  /// The text contents broken down into its component parts, including styling
  /// information.
  ///
  /// This property is read-only.
  core.List<TextElement>? textElements;

  TextContent();

  TextContent.fromJson(core.Map _json) {
    if (_json.containsKey('lists')) {
      lists = (_json['lists'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          List.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('textElements')) {
      textElements = (_json['textElements'] as core.List)
          .map<TextElement>((value) => TextElement.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lists != null)
          'lists': lists!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (textElements != null)
          'textElements': textElements!.map((value) => value.toJson()).toList(),
      };
}

/// A TextElement describes the content of a range of indices in the text
/// content of a Shape or TableCell.
class TextElement {
  /// A TextElement representing a spot in the text that is dynamically replaced
  /// with content that can change over time.
  AutoText? autoText;

  /// The zero-based end index of this text element, exclusive, in Unicode code
  /// units.
  core.int? endIndex;

  /// A marker representing the beginning of a new paragraph.
  ///
  /// The `start_index` and `end_index` of this TextElement represent the range
  /// of the paragraph. Other TextElements with an index range contained inside
  /// this paragraph's range are considered to be part of this paragraph. The
  /// range of indices of two separate paragraphs will never overlap.
  ParagraphMarker? paragraphMarker;

  /// The zero-based start index of this text element, in Unicode code units.
  core.int? startIndex;

  /// A TextElement representing a run of text where all of the characters in
  /// the run have the same TextStyle.
  ///
  /// The `start_index` and `end_index` of TextRuns will always be fully
  /// contained in the index range of a single `paragraph_marker` TextElement.
  /// In other words, a TextRun will never span multiple paragraphs.
  TextRun? textRun;

  TextElement();

  TextElement.fromJson(core.Map _json) {
    if (_json.containsKey('autoText')) {
      autoText = AutoText.fromJson(
          _json['autoText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('endIndex')) {
      endIndex = _json['endIndex'] as core.int;
    }
    if (_json.containsKey('paragraphMarker')) {
      paragraphMarker = ParagraphMarker.fromJson(
          _json['paragraphMarker'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startIndex')) {
      startIndex = _json['startIndex'] as core.int;
    }
    if (_json.containsKey('textRun')) {
      textRun = TextRun.fromJson(
          _json['textRun'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoText != null) 'autoText': autoText!.toJson(),
        if (endIndex != null) 'endIndex': endIndex!,
        if (paragraphMarker != null)
          'paragraphMarker': paragraphMarker!.toJson(),
        if (startIndex != null) 'startIndex': startIndex!,
        if (textRun != null) 'textRun': textRun!.toJson(),
      };
}

/// A TextElement kind that represents a run of text that all has the same
/// styling.
class TextRun {
  /// The text of this run.
  core.String? content;

  /// The styling applied to this run.
  TextStyle? style;

  TextRun();

  TextRun.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('style')) {
      style = TextStyle.fromJson(
          _json['style'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (style != null) 'style': style!.toJson(),
      };
}

/// Represents the styling that can be applied to a TextRun.
///
/// If this text is contained in a shape with a parent placeholder, then these
/// text styles may be inherited from the parent. Which text styles are
/// inherited depend on the nesting level of lists: * A text run in a paragraph
/// that is not in a list will inherit its text style from the the newline
/// character in the paragraph at the 0 nesting level of the list inside the
/// parent placeholder. * A text run in a paragraph that is in a list will
/// inherit its text style from the newline character in the paragraph at its
/// corresponding nesting level of the list inside the parent placeholder.
/// Inherited text styles are represented as unset fields in this message. If
/// text is contained in a shape without a parent placeholder, unsetting these
/// fields will revert the style to a value matching the defaults in the Slides
/// editor.
class TextStyle {
  /// The background color of the text.
  ///
  /// If set, the color is either opaque or transparent, depending on if the
  /// `opaque_color` field in it is set.
  OptionalColor? backgroundColor;

  /// The text's vertical offset from its normal position.
  ///
  /// Text with `SUPERSCRIPT` or `SUBSCRIPT` baseline offsets is automatically
  /// rendered in a smaller font size, computed based on the `font_size` field.
  /// The `font_size` itself is not affected by changes in this field.
  /// Possible string values are:
  /// - "BASELINE_OFFSET_UNSPECIFIED" : The text's baseline offset is inherited
  /// from the parent.
  /// - "NONE" : The text is not vertically offset.
  /// - "SUPERSCRIPT" : The text is vertically offset upwards (superscript).
  /// - "SUBSCRIPT" : The text is vertically offset downwards (subscript).
  core.String? baselineOffset;

  /// Whether or not the text is rendered as bold.
  core.bool? bold;

  /// The font family of the text.
  ///
  /// The font family can be any font from the Font menu in Slides or from
  /// [Google Fonts](https://fonts.google.com/). If the font name is
  /// unrecognized, the text is rendered in `Arial`. Some fonts can affect the
  /// weight of the text. If an update request specifies values for both
  /// `font_family` and `bold`, the explicitly-set `bold` value is used.
  core.String? fontFamily;

  /// The size of the text's font.
  ///
  /// When read, the `font_size` will specified in points.
  Dimension? fontSize;

  /// The color of the text itself.
  ///
  /// If set, the color is either opaque or transparent, depending on if the
  /// `opaque_color` field in it is set.
  OptionalColor? foregroundColor;

  /// Whether or not the text is italicized.
  core.bool? italic;

  /// The hyperlink destination of the text.
  ///
  /// If unset, there is no link. Links are not inherited from parent text.
  /// Changing the link in an update request causes some other changes to the
  /// text style of the range: * When setting a link, the text foreground color
  /// will be set to ThemeColorType.HYPERLINK and the text will be underlined.
  /// If these fields are modified in the same request, those values will be
  /// used instead of the link defaults. * Setting a link on a text range that
  /// overlaps with an existing link will also update the existing link to point
  /// to the new URL. * Links are not settable on newline characters. As a
  /// result, setting a link on a text range that crosses a paragraph boundary,
  /// such as `"ABC\n123"`, will separate the newline character(s) into their
  /// own text runs. The link will be applied separately to the runs before and
  /// after the newline. * Removing a link will update the text style of the
  /// range to match the style of the preceding text (or the default text styles
  /// if the preceding text is another link) unless different styles are being
  /// set in the same request.
  Link? link;

  /// Whether or not the text is in small capital letters.
  core.bool? smallCaps;

  /// Whether or not the text is struck through.
  core.bool? strikethrough;

  /// Whether or not the text is underlined.
  core.bool? underline;

  /// The font family and rendered weight of the text.
  ///
  /// This field is an extension of `font_family` meant to support explicit font
  /// weights without breaking backwards compatibility. As such, when reading
  /// the style of a range of text, the value of
  /// `weighted_font_family#font_family` will always be equal to that of
  /// `font_family`. However, when writing, if both fields are included in the
  /// field mask (either explicitly or through the wildcard `"*"`), their values
  /// are reconciled as follows: * If `font_family` is set and
  /// `weighted_font_family` is not, the value of `font_family` is applied with
  /// weight `400` ("normal"). * If both fields are set, the value of
  /// `font_family` must match that of `weighted_font_family#font_family`. If
  /// so, the font family and weight of `weighted_font_family` is applied.
  /// Otherwise, a 400 bad request error is returned. * If
  /// `weighted_font_family` is set and `font_family` is not, the font family
  /// and weight of `weighted_font_family` is applied. * If neither field is
  /// set, the font family and weight of the text inherit from the parent. Note
  /// that these properties cannot inherit separately from each other. If an
  /// update request specifies values for both `weighted_font_family` and
  /// `bold`, the `weighted_font_family` is applied first, then `bold`. If
  /// `weighted_font_family#weight` is not set, it defaults to `400`. If
  /// `weighted_font_family` is set, then `weighted_font_family#font_family`
  /// must also be set with a non-empty value. Otherwise, a 400 bad request
  /// error is returned.
  WeightedFontFamily? weightedFontFamily;

  TextStyle();

  TextStyle.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundColor')) {
      backgroundColor = OptionalColor.fromJson(
          _json['backgroundColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('baselineOffset')) {
      baselineOffset = _json['baselineOffset'] as core.String;
    }
    if (_json.containsKey('bold')) {
      bold = _json['bold'] as core.bool;
    }
    if (_json.containsKey('fontFamily')) {
      fontFamily = _json['fontFamily'] as core.String;
    }
    if (_json.containsKey('fontSize')) {
      fontSize = Dimension.fromJson(
          _json['fontSize'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('foregroundColor')) {
      foregroundColor = OptionalColor.fromJson(
          _json['foregroundColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('italic')) {
      italic = _json['italic'] as core.bool;
    }
    if (_json.containsKey('link')) {
      link =
          Link.fromJson(_json['link'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('smallCaps')) {
      smallCaps = _json['smallCaps'] as core.bool;
    }
    if (_json.containsKey('strikethrough')) {
      strikethrough = _json['strikethrough'] as core.bool;
    }
    if (_json.containsKey('underline')) {
      underline = _json['underline'] as core.bool;
    }
    if (_json.containsKey('weightedFontFamily')) {
      weightedFontFamily = WeightedFontFamily.fromJson(
          _json['weightedFontFamily'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundColor != null)
          'backgroundColor': backgroundColor!.toJson(),
        if (baselineOffset != null) 'baselineOffset': baselineOffset!,
        if (bold != null) 'bold': bold!,
        if (fontFamily != null) 'fontFamily': fontFamily!,
        if (fontSize != null) 'fontSize': fontSize!.toJson(),
        if (foregroundColor != null)
          'foregroundColor': foregroundColor!.toJson(),
        if (italic != null) 'italic': italic!,
        if (link != null) 'link': link!.toJson(),
        if (smallCaps != null) 'smallCaps': smallCaps!,
        if (strikethrough != null) 'strikethrough': strikethrough!,
        if (underline != null) 'underline': underline!,
        if (weightedFontFamily != null)
          'weightedFontFamily': weightedFontFamily!.toJson(),
      };
}

/// A pair mapping a theme color type to the concrete color it represents.
class ThemeColorPair {
  /// The concrete color corresponding to the theme color type above.
  RgbColor? color;

  /// The type of the theme color.
  /// Possible string values are:
  /// - "THEME_COLOR_TYPE_UNSPECIFIED" : Unspecified theme color. This value
  /// should not be used.
  /// - "DARK1" : Represents the first dark color.
  /// - "LIGHT1" : Represents the first light color.
  /// - "DARK2" : Represents the second dark color.
  /// - "LIGHT2" : Represents the second light color.
  /// - "ACCENT1" : Represents the first accent color.
  /// - "ACCENT2" : Represents the second accent color.
  /// - "ACCENT3" : Represents the third accent color.
  /// - "ACCENT4" : Represents the fourth accent color.
  /// - "ACCENT5" : Represents the fifth accent color.
  /// - "ACCENT6" : Represents the sixth accent color.
  /// - "HYPERLINK" : Represents the color to use for hyperlinks.
  /// - "FOLLOWED_HYPERLINK" : Represents the color to use for visited
  /// hyperlinks.
  /// - "TEXT1" : Represents the first text color.
  /// - "BACKGROUND1" : Represents the first background color.
  /// - "TEXT2" : Represents the second text color.
  /// - "BACKGROUND2" : Represents the second background color.
  core.String? type;

  ThemeColorPair();

  ThemeColorPair.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color = RgbColor.fromJson(
          _json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// The thumbnail of a page.
class Thumbnail {
  /// The content URL of the thumbnail image.
  ///
  /// The URL to the image has a default lifetime of 30 minutes. This URL is
  /// tagged with the account of the requester. Anyone with the URL effectively
  /// accesses the image as the original requester. Access to the image may be
  /// lost if the presentation's sharing settings change. The mime type of the
  /// thumbnail image is the same as specified in the `GetPageThumbnailRequest`.
  core.String? contentUrl;

  /// The positive height in pixels of the thumbnail image.
  core.int? height;

  /// The positive width in pixels of the thumbnail image.
  core.int? width;

  Thumbnail();

  Thumbnail.fromJson(core.Map _json) {
    if (_json.containsKey('contentUrl')) {
      contentUrl = _json['contentUrl'] as core.String;
    }
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentUrl != null) 'contentUrl': contentUrl!,
        if (height != null) 'height': height!,
        if (width != null) 'width': width!,
      };
}

/// Ungroups objects, such as groups.
class UngroupObjectsRequest {
  /// The object IDs of the objects to ungroup.
  ///
  /// Only groups that are not inside other groups can be ungrouped. All the
  /// groups should be on the same page. The group itself is deleted. The visual
  /// sizes and positions of all the children are preserved.
  core.List<core.String>? objectIds;

  UngroupObjectsRequest();

  UngroupObjectsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('objectIds')) {
      objectIds = (_json['objectIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectIds != null) 'objectIds': objectIds!,
      };
}

/// Unmerges cells in a Table.
class UnmergeTableCellsRequest {
  /// The object ID of the table.
  core.String? objectId;

  /// The table range specifying which cells of the table to unmerge.
  ///
  /// All merged cells in this range will be unmerged, and cells that are
  /// already unmerged will not be affected. If the range has no merged cells,
  /// the request will do nothing. If there is text in any of the merged cells,
  /// the text will remain in the upper-left ("head") cell of the resulting
  /// block of unmerged cells.
  TableRange? tableRange;

  UnmergeTableCellsRequest();

  UnmergeTableCellsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('tableRange')) {
      tableRange = TableRange.fromJson(
          _json['tableRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
        if (tableRange != null) 'tableRange': tableRange!.toJson(),
      };
}

/// Update the properties of an Image.
class UpdateImagePropertiesRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `imageProperties` is
  /// implied and should not be specified. A single `"*"` can be used as
  /// short-hand for listing every field. For example to update the image
  /// outline color, set `fields` to `"outline.outlineFill.solidFill.color"`. To
  /// reset a property to its default value, include its field name in the field
  /// mask but leave the field itself unset.
  core.String? fields;

  /// The image properties to update.
  ImageProperties? imageProperties;

  /// The object ID of the image the updates are applied to.
  core.String? objectId;

  UpdateImagePropertiesRequest();

  UpdateImagePropertiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('imageProperties')) {
      imageProperties = ImageProperties.fromJson(
          _json['imageProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (imageProperties != null)
          'imageProperties': imageProperties!.toJson(),
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Updates the category of a line.
class UpdateLineCategoryRequest {
  /// The line category to update to.
  ///
  /// The exact line type is determined based on the category to update to and
  /// how it's routed to connect to other page elements.
  /// Possible string values are:
  /// - "LINE_CATEGORY_UNSPECIFIED" : Unspecified line category.
  /// - "STRAIGHT" : Straight connectors, including straight connector 1.
  /// - "BENT" : Bent connectors, including bent connector 2 to 5.
  /// - "CURVED" : Curved connectors, including curved connector 2 to 5.
  core.String? lineCategory;

  /// The object ID of the line the update is applied to.
  ///
  /// Only a line with a category indicating it is a "connector" can be updated.
  /// The line may be rerouted after updating its category.
  core.String? objectId;

  UpdateLineCategoryRequest();

  UpdateLineCategoryRequest.fromJson(core.Map _json) {
    if (_json.containsKey('lineCategory')) {
      lineCategory = _json['lineCategory'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineCategory != null) 'lineCategory': lineCategory!,
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Updates the properties of a Line.
class UpdateLinePropertiesRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `lineProperties` is implied
  /// and should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field. For example to update the line solid fill color, set
  /// `fields` to `"lineFill.solidFill.color"`. To reset a property to its
  /// default value, include its field name in the field mask but leave the
  /// field itself unset.
  core.String? fields;

  /// The line properties to update.
  LineProperties? lineProperties;

  /// The object ID of the line the update is applied to.
  core.String? objectId;

  UpdateLinePropertiesRequest();

  UpdateLinePropertiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('lineProperties')) {
      lineProperties = LineProperties.fromJson(
          _json['lineProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (lineProperties != null) 'lineProperties': lineProperties!.toJson(),
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Updates the alt text title and/or description of a page element.
class UpdatePageElementAltTextRequest {
  /// The updated alt text description of the page element.
  ///
  /// If unset the existing value will be maintained. The description is exposed
  /// to screen readers and other accessibility interfaces. Only use human
  /// readable values related to the content of the page element.
  core.String? description;

  /// The object ID of the page element the updates are applied to.
  core.String? objectId;

  /// The updated alt text title of the page element.
  ///
  /// If unset the existing value will be maintained. The title is exposed to
  /// screen readers and other accessibility interfaces. Only use human readable
  /// values related to the content of the page element.
  core.String? title;

  UpdatePageElementAltTextRequest();

  UpdatePageElementAltTextRequest.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (objectId != null) 'objectId': objectId!,
        if (title != null) 'title': title!,
      };
}

/// Updates the transform of a page element.
///
/// Updating the transform of a group will change the absolute transform of the
/// page elements in that group, which can change their visual appearance. See
/// the documentation for PageElement.transform for more details.
class UpdatePageElementTransformRequest {
  /// The apply mode of the transform update.
  /// Possible string values are:
  /// - "APPLY_MODE_UNSPECIFIED" : Unspecified mode.
  /// - "RELATIVE" : Applies the new AffineTransform matrix to the existing one,
  /// and replaces the existing one with the resulting concatenation.
  /// - "ABSOLUTE" : Replaces the existing AffineTransform matrix with the new
  /// one.
  core.String? applyMode;

  /// The object ID of the page element to update.
  core.String? objectId;

  /// The input transform matrix used to update the page element.
  AffineTransform? transform;

  UpdatePageElementTransformRequest();

  UpdatePageElementTransformRequest.fromJson(core.Map _json) {
    if (_json.containsKey('applyMode')) {
      applyMode = _json['applyMode'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('transform')) {
      transform = AffineTransform.fromJson(
          _json['transform'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applyMode != null) 'applyMode': applyMode!,
        if (objectId != null) 'objectId': objectId!,
        if (transform != null) 'transform': transform!.toJson(),
      };
}

/// Updates the Z-order of page elements.
///
/// Z-order is an ordering of the elements on the page from back to front. The
/// page element in the front may cover the elements that are behind it.
class UpdatePageElementsZOrderRequest {
  /// The Z-order operation to apply on the page elements.
  ///
  /// When applying the operation on multiple page elements, the relative
  /// Z-orders within these page elements before the operation is maintained.
  /// Possible string values are:
  /// - "Z_ORDER_OPERATION_UNSPECIFIED" : Unspecified operation.
  /// - "BRING_TO_FRONT" : Brings the page elements to the front of the page.
  /// - "BRING_FORWARD" : Brings the page elements forward on the page by one
  /// element relative to the forwardmost one in the specified page elements.
  /// - "SEND_BACKWARD" : Sends the page elements backward on the page by one
  /// element relative to the furthest behind one in the specified page
  /// elements.
  /// - "SEND_TO_BACK" : Sends the page elements to the back of the page.
  core.String? operation;

  /// The object IDs of the page elements to update.
  ///
  /// All the page elements must be on the same page and must not be grouped.
  core.List<core.String>? pageElementObjectIds;

  UpdatePageElementsZOrderRequest();

  UpdatePageElementsZOrderRequest.fromJson(core.Map _json) {
    if (_json.containsKey('operation')) {
      operation = _json['operation'] as core.String;
    }
    if (_json.containsKey('pageElementObjectIds')) {
      pageElementObjectIds = (_json['pageElementObjectIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operation != null) 'operation': operation!,
        if (pageElementObjectIds != null)
          'pageElementObjectIds': pageElementObjectIds!,
      };
}

/// Updates the properties of a Page.
class UpdatePagePropertiesRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `pageProperties` is implied
  /// and should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field. For example to update the page background solid fill
  /// color, set `fields` to `"pageBackgroundFill.solidFill.color"`. To reset a
  /// property to its default value, include its field name in the field mask
  /// but leave the field itself unset.
  core.String? fields;

  /// The object ID of the page the update is applied to.
  core.String? objectId;

  /// The page properties to update.
  PageProperties? pageProperties;

  UpdatePagePropertiesRequest();

  UpdatePagePropertiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('pageProperties')) {
      pageProperties = PageProperties.fromJson(
          _json['pageProperties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (objectId != null) 'objectId': objectId!,
        if (pageProperties != null) 'pageProperties': pageProperties!.toJson(),
      };
}

/// Updates the styling for all of the paragraphs within a Shape or Table that
/// overlap with the given text index range.
class UpdateParagraphStyleRequest {
  /// The location of the cell in the table containing the paragraph(s) to
  /// style.
  ///
  /// If `object_id` refers to a table, `cell_location` must have a value.
  /// Otherwise, it must not.
  TableCellLocation? cellLocation;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `style` is implied and
  /// should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field. For example, to update the paragraph alignment, set
  /// `fields` to `"alignment"`. To reset a property to its default value,
  /// include its field name in the field mask but leave the field itself unset.
  core.String? fields;

  /// The object ID of the shape or table with the text to be styled.
  core.String? objectId;

  /// The paragraph's style.
  ParagraphStyle? style;

  /// The range of text containing the paragraph(s) to style.
  Range? textRange;

  UpdateParagraphStyleRequest();

  UpdateParagraphStyleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cellLocation')) {
      cellLocation = TableCellLocation.fromJson(
          _json['cellLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('style')) {
      style = ParagraphStyle.fromJson(
          _json['style'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textRange')) {
      textRange = Range.fromJson(
          _json['textRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cellLocation != null) 'cellLocation': cellLocation!.toJson(),
        if (fields != null) 'fields': fields!,
        if (objectId != null) 'objectId': objectId!,
        if (style != null) 'style': style!.toJson(),
        if (textRange != null) 'textRange': textRange!.toJson(),
      };
}

/// Update the properties of a Shape.
class UpdateShapePropertiesRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `shapeProperties` is
  /// implied and should not be specified. A single `"*"` can be used as
  /// short-hand for listing every field. For example to update the shape
  /// background solid fill color, set `fields` to
  /// `"shapeBackgroundFill.solidFill.color"`. To reset a property to its
  /// default value, include its field name in the field mask but leave the
  /// field itself unset.
  core.String? fields;

  /// The object ID of the shape the updates are applied to.
  core.String? objectId;

  /// The shape properties to update.
  ShapeProperties? shapeProperties;

  UpdateShapePropertiesRequest();

  UpdateShapePropertiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('shapeProperties')) {
      shapeProperties = ShapeProperties.fromJson(
          _json['shapeProperties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (objectId != null) 'objectId': objectId!,
        if (shapeProperties != null)
          'shapeProperties': shapeProperties!.toJson(),
      };
}

/// Updates the position of slides in the presentation.
class UpdateSlidesPositionRequest {
  /// The index where the slides should be inserted, based on the slide
  /// arrangement before the move takes place.
  ///
  /// Must be between zero and the number of slides in the presentation,
  /// inclusive.
  core.int? insertionIndex;

  /// The IDs of the slides in the presentation that should be moved.
  ///
  /// The slides in this list must be in existing presentation order, without
  /// duplicates.
  core.List<core.String>? slideObjectIds;

  UpdateSlidesPositionRequest();

  UpdateSlidesPositionRequest.fromJson(core.Map _json) {
    if (_json.containsKey('insertionIndex')) {
      insertionIndex = _json['insertionIndex'] as core.int;
    }
    if (_json.containsKey('slideObjectIds')) {
      slideObjectIds = (_json['slideObjectIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (insertionIndex != null) 'insertionIndex': insertionIndex!,
        if (slideObjectIds != null) 'slideObjectIds': slideObjectIds!,
      };
}

/// Updates the properties of the table borders in a Table.
class UpdateTableBorderPropertiesRequest {
  /// The border position in the table range the updates should apply to.
  ///
  /// If a border position is not specified, the updates will apply to all
  /// borders in the table range.
  /// Possible string values are:
  /// - "ALL" : All borders in the range.
  /// - "BOTTOM" : Borders at the bottom of the range.
  /// - "INNER" : Borders on the inside of the range.
  /// - "INNER_HORIZONTAL" : Horizontal borders on the inside of the range.
  /// - "INNER_VERTICAL" : Vertical borders on the inside of the range.
  /// - "LEFT" : Borders at the left of the range.
  /// - "OUTER" : Borders along the outside of the range.
  /// - "RIGHT" : Borders at the right of the range.
  /// - "TOP" : Borders at the top of the range.
  core.String? borderPosition;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `tableBorderProperties` is
  /// implied and should not be specified. A single `"*"` can be used as
  /// short-hand for listing every field. For example to update the table border
  /// solid fill color, set `fields` to `"tableBorderFill.solidFill.color"`. To
  /// reset a property to its default value, include its field name in the field
  /// mask but leave the field itself unset.
  core.String? fields;

  /// The object ID of the table.
  core.String? objectId;

  /// The table border properties to update.
  TableBorderProperties? tableBorderProperties;

  /// The table range representing the subset of the table to which the updates
  /// are applied.
  ///
  /// If a table range is not specified, the updates will apply to the entire
  /// table.
  TableRange? tableRange;

  UpdateTableBorderPropertiesRequest();

  UpdateTableBorderPropertiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('borderPosition')) {
      borderPosition = _json['borderPosition'] as core.String;
    }
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('tableBorderProperties')) {
      tableBorderProperties = TableBorderProperties.fromJson(
          _json['tableBorderProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableRange')) {
      tableRange = TableRange.fromJson(
          _json['tableRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (borderPosition != null) 'borderPosition': borderPosition!,
        if (fields != null) 'fields': fields!,
        if (objectId != null) 'objectId': objectId!,
        if (tableBorderProperties != null)
          'tableBorderProperties': tableBorderProperties!.toJson(),
        if (tableRange != null) 'tableRange': tableRange!.toJson(),
      };
}

/// Update the properties of a TableCell.
class UpdateTableCellPropertiesRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `tableCellProperties` is
  /// implied and should not be specified. A single `"*"` can be used as
  /// short-hand for listing every field. For example to update the table cell
  /// background solid fill color, set `fields` to
  /// `"tableCellBackgroundFill.solidFill.color"`. To reset a property to its
  /// default value, include its field name in the field mask but leave the
  /// field itself unset.
  core.String? fields;

  /// The object ID of the table.
  core.String? objectId;

  /// The table cell properties to update.
  TableCellProperties? tableCellProperties;

  /// The table range representing the subset of the table to which the updates
  /// are applied.
  ///
  /// If a table range is not specified, the updates will apply to the entire
  /// table.
  TableRange? tableRange;

  UpdateTableCellPropertiesRequest();

  UpdateTableCellPropertiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('tableCellProperties')) {
      tableCellProperties = TableCellProperties.fromJson(
          _json['tableCellProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableRange')) {
      tableRange = TableRange.fromJson(
          _json['tableRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (objectId != null) 'objectId': objectId!,
        if (tableCellProperties != null)
          'tableCellProperties': tableCellProperties!.toJson(),
        if (tableRange != null) 'tableRange': tableRange!.toJson(),
      };
}

/// Updates the properties of a Table column.
class UpdateTableColumnPropertiesRequest {
  /// The list of zero-based indices specifying which columns to update.
  ///
  /// If no indices are provided, all columns in the table will be updated.
  core.List<core.int>? columnIndices;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `tableColumnProperties` is
  /// implied and should not be specified. A single `"*"` can be used as
  /// short-hand for listing every field. For example to update the column
  /// width, set `fields` to `"column_width"`. If '"column_width"' is included
  /// in the field mask but the property is left unset, the column width will
  /// default to 406,400 EMU (32 points).
  core.String? fields;

  /// The object ID of the table.
  core.String? objectId;

  /// The table column properties to update.
  ///
  /// If the value of `table_column_properties#column_width` in the request is
  /// less than 406,400 EMU (32 points), a 400 bad request error is returned.
  TableColumnProperties? tableColumnProperties;

  UpdateTableColumnPropertiesRequest();

  UpdateTableColumnPropertiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('columnIndices')) {
      columnIndices = (_json['columnIndices'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('tableColumnProperties')) {
      tableColumnProperties = TableColumnProperties.fromJson(
          _json['tableColumnProperties']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnIndices != null) 'columnIndices': columnIndices!,
        if (fields != null) 'fields': fields!,
        if (objectId != null) 'objectId': objectId!,
        if (tableColumnProperties != null)
          'tableColumnProperties': tableColumnProperties!.toJson(),
      };
}

/// Updates the properties of a Table row.
class UpdateTableRowPropertiesRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `tableRowProperties` is
  /// implied and should not be specified. A single `"*"` can be used as
  /// short-hand for listing every field. For example to update the minimum row
  /// height, set `fields` to `"min_row_height"`. If '"min_row_height"' is
  /// included in the field mask but the property is left unset, the minimum row
  /// height will default to 0.
  core.String? fields;

  /// The object ID of the table.
  core.String? objectId;

  /// The list of zero-based indices specifying which rows to update.
  ///
  /// If no indices are provided, all rows in the table will be updated.
  core.List<core.int>? rowIndices;

  /// The table row properties to update.
  TableRowProperties? tableRowProperties;

  UpdateTableRowPropertiesRequest();

  UpdateTableRowPropertiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('rowIndices')) {
      rowIndices = (_json['rowIndices'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('tableRowProperties')) {
      tableRowProperties = TableRowProperties.fromJson(
          _json['tableRowProperties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (objectId != null) 'objectId': objectId!,
        if (rowIndices != null) 'rowIndices': rowIndices!,
        if (tableRowProperties != null)
          'tableRowProperties': tableRowProperties!.toJson(),
      };
}

/// Update the styling of text in a Shape or Table.
class UpdateTextStyleRequest {
  /// The location of the cell in the table containing the text to style.
  ///
  /// If `object_id` refers to a table, `cell_location` must have a value.
  /// Otherwise, it must not.
  TableCellLocation? cellLocation;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `style` is implied and
  /// should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field. For example, to update the text style to bold, set
  /// `fields` to `"bold"`. To reset a property to its default value, include
  /// its field name in the field mask but leave the field itself unset.
  core.String? fields;

  /// The object ID of the shape or table with the text to be styled.
  core.String? objectId;

  /// The style(s) to set on the text.
  ///
  /// If the value for a particular style matches that of the parent, that style
  /// will be set to inherit. Certain text style changes may cause other changes
  /// meant to mirror the behavior of the Slides editor. See the documentation
  /// of TextStyle for more information.
  TextStyle? style;

  /// The range of text to style.
  ///
  /// The range may be extended to include adjacent newlines. If the range fully
  /// contains a paragraph belonging to a list, the paragraph's bullet is also
  /// updated with the matching text style.
  Range? textRange;

  UpdateTextStyleRequest();

  UpdateTextStyleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cellLocation')) {
      cellLocation = TableCellLocation.fromJson(
          _json['cellLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('style')) {
      style = TextStyle.fromJson(
          _json['style'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textRange')) {
      textRange = Range.fromJson(
          _json['textRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cellLocation != null) 'cellLocation': cellLocation!.toJson(),
        if (fields != null) 'fields': fields!,
        if (objectId != null) 'objectId': objectId!,
        if (style != null) 'style': style!.toJson(),
        if (textRange != null) 'textRange': textRange!.toJson(),
      };
}

/// Update the properties of a Video.
class UpdateVideoPropertiesRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `videoProperties` is
  /// implied and should not be specified. A single `"*"` can be used as
  /// short-hand for listing every field. For example to update the video
  /// outline color, set `fields` to `"outline.outlineFill.solidFill.color"`. To
  /// reset a property to its default value, include its field name in the field
  /// mask but leave the field itself unset.
  core.String? fields;

  /// The object ID of the video the updates are applied to.
  core.String? objectId;

  /// The video properties to update.
  VideoProperties? videoProperties;

  UpdateVideoPropertiesRequest();

  UpdateVideoPropertiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('videoProperties')) {
      videoProperties = VideoProperties.fromJson(
          _json['videoProperties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (objectId != null) 'objectId': objectId!,
        if (videoProperties != null)
          'videoProperties': videoProperties!.toJson(),
      };
}

/// A PageElement kind representing a video.
class Video {
  /// The video source's unique identifier for this video.
  core.String? id;

  /// The video source.
  /// Possible string values are:
  /// - "SOURCE_UNSPECIFIED" : The video source is unspecified.
  /// - "YOUTUBE" : The video source is YouTube.
  /// - "DRIVE" : The video source is Google Drive.
  core.String? source;

  /// An URL to a video.
  ///
  /// The URL is valid as long as the source video exists and sharing settings
  /// do not change.
  core.String? url;

  /// The properties of the video.
  VideoProperties? videoProperties;

  Video();

  Video.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
    if (_json.containsKey('videoProperties')) {
      videoProperties = VideoProperties.fromJson(
          _json['videoProperties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (source != null) 'source': source!,
        if (url != null) 'url': url!,
        if (videoProperties != null)
          'videoProperties': videoProperties!.toJson(),
      };
}

/// The properties of the Video.
class VideoProperties {
  /// Whether to enable video autoplay when the page is displayed in present
  /// mode.
  ///
  /// Defaults to false.
  core.bool? autoPlay;

  /// The time at which to end playback, measured in seconds from the beginning
  /// of the video.
  ///
  /// If set, the end time should be after the start time. If not set or if you
  /// set this to a value that exceeds the video's length, the video will be
  /// played until its end.
  core.int? end;

  /// Whether to mute the audio during video playback.
  ///
  /// Defaults to false.
  core.bool? mute;

  /// The outline of the video.
  ///
  /// The default outline matches the defaults for new videos created in the
  /// Slides editor.
  Outline? outline;

  /// The time at which to start playback, measured in seconds from the
  /// beginning of the video.
  ///
  /// If set, the start time should be before the end time. If you set this to a
  /// value that exceeds the video's length in seconds, the video will be played
  /// from the last second. If not set, the video will be played from the
  /// beginning.
  core.int? start;

  VideoProperties();

  VideoProperties.fromJson(core.Map _json) {
    if (_json.containsKey('autoPlay')) {
      autoPlay = _json['autoPlay'] as core.bool;
    }
    if (_json.containsKey('end')) {
      end = _json['end'] as core.int;
    }
    if (_json.containsKey('mute')) {
      mute = _json['mute'] as core.bool;
    }
    if (_json.containsKey('outline')) {
      outline = Outline.fromJson(
          _json['outline'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('start')) {
      start = _json['start'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoPlay != null) 'autoPlay': autoPlay!,
        if (end != null) 'end': end!,
        if (mute != null) 'mute': mute!,
        if (outline != null) 'outline': outline!.toJson(),
        if (start != null) 'start': start!,
      };
}

/// Represents a font family and weight used to style a TextRun.
class WeightedFontFamily {
  /// The font family of the text.
  ///
  /// The font family can be any font from the Font menu in Slides or from
  /// [Google Fonts](https://fonts.google.com/). If the font name is
  /// unrecognized, the text is rendered in `Arial`.
  core.String? fontFamily;

  /// The rendered weight of the text.
  ///
  /// This field can have any value that is a multiple of `100` between `100`
  /// and `900`, inclusive. This range corresponds to the numerical values
  /// described in the CSS 2.1 Specification,
  /// [section 15.6](https://www.w3.org/TR/CSS21/fonts.html#font-boldness), with
  /// non-numerical values disallowed. Weights greater than or equal to `700`
  /// are considered bold, and weights less than `700`are not bold. The default
  /// value is `400` ("normal").
  core.int? weight;

  WeightedFontFamily();

  WeightedFontFamily.fromJson(core.Map _json) {
    if (_json.containsKey('fontFamily')) {
      fontFamily = _json['fontFamily'] as core.String;
    }
    if (_json.containsKey('weight')) {
      weight = _json['weight'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fontFamily != null) 'fontFamily': fontFamily!,
        if (weight != null) 'weight': weight!,
      };
}

/// A PageElement kind representing word art.
class WordArt {
  /// The text rendered as word art.
  core.String? renderedText;

  WordArt();

  WordArt.fromJson(core.Map _json) {
    if (_json.containsKey('renderedText')) {
      renderedText = _json['renderedText'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (renderedText != null) 'renderedText': renderedText!,
      };
}

/// Provides control over how write requests are executed.
class WriteControl {
  /// The revision ID of the presentation required for the write request.
  ///
  /// If specified and the `required_revision_id` doesn't exactly match the
  /// presentation's current `revision_id`, the request will not be processed
  /// and will return a 400 bad request error.
  core.String? requiredRevisionId;

  WriteControl();

  WriteControl.fromJson(core.Map _json) {
    if (_json.containsKey('requiredRevisionId')) {
      requiredRevisionId = _json['requiredRevisionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requiredRevisionId != null)
          'requiredRevisionId': requiredRevisionId!,
      };
}
