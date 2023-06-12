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

/// Google Docs API - v1
///
/// Reads and writes Google Docs documents.
///
/// For more information, see <https://developers.google.com/docs/>
///
/// Create an instance of [DocsApi] to access these resources:
///
/// - [DocumentsResource]
library docs.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Reads and writes Google Docs documents.
class DocsApi {
  /// See, create, and edit all Google Docs documents you have access to
  static const documentsScope = 'https://www.googleapis.com/auth/documents';

  /// View your Google Docs documents
  static const documentsReadonlyScope =
      'https://www.googleapis.com/auth/documents.readonly';

  /// See, edit, create, and delete all of your Google Drive files
  static const driveScope = 'https://www.googleapis.com/auth/drive';

  /// See, edit, create, and delete only the specific Google Drive files you use
  /// with this app
  static const driveFileScope = 'https://www.googleapis.com/auth/drive.file';

  /// See and download all your Google Drive files
  static const driveReadonlyScope =
      'https://www.googleapis.com/auth/drive.readonly';

  final commons.ApiRequester _requester;

  DocumentsResource get documents => DocumentsResource(_requester);

  DocsApi(http.Client client,
      {core.String rootUrl = 'https://docs.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class DocumentsResource {
  final commons.ApiRequester _requester;

  DocumentsResource(commons.ApiRequester client) : _requester = client;

  /// Applies one or more updates to the document.
  ///
  /// Each request is validated before being applied. If any request is not
  /// valid, then the entire request will fail and nothing will be applied. Some
  /// requests have replies to give you some information about how they are
  /// applied. Other requests do not need to return information; these each
  /// return an empty reply. The order of replies matches that of the requests.
  /// For example, suppose you call batchUpdate with four updates, and only the
  /// third one returns information. The response would have two empty replies,
  /// the reply to the third request, and another empty reply, in that order.
  /// Because other users may be editing the document, the document might not
  /// exactly reflect your changes: your changes may be altered with respect to
  /// collaborator changes. If there are no collaborators, the document should
  /// reflect your changes. In any case, the updates in your request are
  /// guaranteed to be applied together atomically.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [documentId] - The ID of the document to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchUpdateDocumentResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchUpdateDocumentResponse> batchUpdate(
    BatchUpdateDocumentRequest request,
    core.String documentId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/documents/' +
        commons.escapeVariable('$documentId') +
        ':batchUpdate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BatchUpdateDocumentResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a blank document using the title given in the request.
  ///
  /// Other fields in the request, including any provided content, are ignored.
  /// Returns the created document.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Document].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Document> create(
    Document request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/documents';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Document.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the latest version of the specified document.
  ///
  /// Request parameters:
  ///
  /// [documentId] - The ID of the document to retrieve.
  ///
  /// [suggestionsViewMode] - The suggestions view mode to apply to the
  /// document. This allows viewing the document with all suggestions inline,
  /// accepted or rejected. If one is not specified, DEFAULT_FOR_CURRENT_ACCESS
  /// is used.
  /// Possible string values are:
  /// - "DEFAULT_FOR_CURRENT_ACCESS" : The SuggestionsViewMode applied to the
  /// returned document depends on the user's current access level. If the user
  /// only has view access, PREVIEW_WITHOUT_SUGGESTIONS is applied. Otherwise,
  /// SUGGESTIONS_INLINE is applied. This is the default suggestions view mode.
  /// - "SUGGESTIONS_INLINE" : The returned document has suggestions inline.
  /// Suggested changes will be differentiated from base content within the
  /// document. Requests to retrieve a document using this mode will return a
  /// 403 error if the user does not have permission to view suggested changes.
  /// - "PREVIEW_SUGGESTIONS_ACCEPTED" : The returned document is a preview with
  /// all suggested changes accepted. Requests to retrieve a document using this
  /// mode will return a 403 error if the user does not have permission to view
  /// suggested changes.
  /// - "PREVIEW_WITHOUT_SUGGESTIONS" : The returned document is a preview with
  /// all suggested changes rejected if there are any suggestions in the
  /// document.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Document].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Document> get(
    core.String documentId, {
    core.String? suggestionsViewMode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (suggestionsViewMode != null)
        'suggestionsViewMode': [suggestionsViewMode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/documents/' + commons.escapeVariable('$documentId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Document.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// A ParagraphElement representing a spot in the text that is dynamically
/// replaced with content that can change over time, like a page number.
class AutoText {
  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// An AutoText may have multiple insertion IDs if it is a nested suggested
  /// change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  /// The suggested text style changes to this AutoText, keyed by suggestion ID.
  core.Map<core.String, SuggestedTextStyle>? suggestedTextStyleChanges;

  /// The text style of this AutoText.
  TextStyle? textStyle;

  /// The type of this auto text.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : An unspecified auto text type.
  /// - "PAGE_NUMBER" : Type for auto text that represents the current page
  /// number.
  /// - "PAGE_COUNT" : Type for auto text that represents the total number of
  /// pages in the document.
  core.String? type;

  AutoText();

  AutoText.fromJson(core.Map _json) {
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedTextStyleChanges')) {
      suggestedTextStyleChanges = (_json['suggestedTextStyleChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedTextStyle.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
        if (suggestedTextStyleChanges != null)
          'suggestedTextStyleChanges': suggestedTextStyleChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// Represents the background of a document.
class Background {
  /// The background color.
  OptionalColor? color;

  Background();

  Background.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color = OptionalColor.fromJson(
          _json['color'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
      };
}

/// A mask that indicates which of the fields on the base Background have been
/// changed in this suggestion.
///
/// For any field set to true, the Backgound has a new suggested value.
class BackgroundSuggestionState {
  /// Indicates whether the current background color has been modified in this
  /// suggestion.
  core.bool? backgroundColorSuggested;

  BackgroundSuggestionState();

  BackgroundSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundColorSuggested')) {
      backgroundColorSuggested = _json['backgroundColorSuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundColorSuggested != null)
          'backgroundColorSuggested': backgroundColorSuggested!,
      };
}

/// Request message for BatchUpdateDocument.
class BatchUpdateDocumentRequest {
  /// A list of updates to apply to the document.
  core.List<Request>? requests;

  /// Provides control over how write requests are executed.
  WriteControl? writeControl;

  BatchUpdateDocumentRequest();

  BatchUpdateDocumentRequest.fromJson(core.Map _json) {
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

/// Response message from a BatchUpdateDocument request.
class BatchUpdateDocumentResponse {
  /// The ID of the document to which the updates were applied to.
  core.String? documentId;

  /// The reply of the updates.
  ///
  /// This maps 1:1 with the updates, although replies to some requests may be
  /// empty.
  core.List<Response>? replies;

  /// The updated write control after applying the request.
  WriteControl? writeControl;

  BatchUpdateDocumentResponse();

  BatchUpdateDocumentResponse.fromJson(core.Map _json) {
    if (_json.containsKey('documentId')) {
      documentId = _json['documentId'] as core.String;
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
        if (documentId != null) 'documentId': documentId!,
        if (replies != null)
          'replies': replies!.map((value) => value.toJson()).toList(),
        if (writeControl != null) 'writeControl': writeControl!.toJson(),
      };
}

/// The document body.
///
/// The body typically contains the full document contents except for headers,
/// footers and footnotes.
class Body {
  /// The contents of the body.
  ///
  /// The indexes for the body's content begin at zero.
  core.List<StructuralElement>? content;

  Body();

  Body.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = (_json['content'] as core.List)
          .map<StructuralElement>((value) => StructuralElement.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null)
          'content': content!.map((value) => value.toJson()).toList(),
      };
}

/// Describes the bullet of a paragraph.
class Bullet {
  /// The ID of the list this paragraph belongs to.
  core.String? listId;

  /// The nesting level of this paragraph in the list.
  core.int? nestingLevel;

  /// The paragraph specific text style applied to this bullet.
  TextStyle? textStyle;

  Bullet();

  Bullet.fromJson(core.Map _json) {
    if (_json.containsKey('listId')) {
      listId = _json['listId'] as core.String;
    }
    if (_json.containsKey('nestingLevel')) {
      nestingLevel = _json['nestingLevel'] as core.int;
    }
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (listId != null) 'listId': listId!,
        if (nestingLevel != null) 'nestingLevel': nestingLevel!,
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
      };
}

/// A mask that indicates which of the fields on the base Bullet have been
/// changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class BulletSuggestionState {
  /// Indicates if there was a suggested change to the list_id.
  core.bool? listIdSuggested;

  /// Indicates if there was a suggested change to the nesting_level.
  core.bool? nestingLevelSuggested;

  /// A mask that indicates which of the fields in text style have been changed
  /// in this suggestion.
  TextStyleSuggestionState? textStyleSuggestionState;

  BulletSuggestionState();

  BulletSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('listIdSuggested')) {
      listIdSuggested = _json['listIdSuggested'] as core.bool;
    }
    if (_json.containsKey('nestingLevelSuggested')) {
      nestingLevelSuggested = _json['nestingLevelSuggested'] as core.bool;
    }
    if (_json.containsKey('textStyleSuggestionState')) {
      textStyleSuggestionState = TextStyleSuggestionState.fromJson(
          _json['textStyleSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (listIdSuggested != null) 'listIdSuggested': listIdSuggested!,
        if (nestingLevelSuggested != null)
          'nestingLevelSuggested': nestingLevelSuggested!,
        if (textStyleSuggestionState != null)
          'textStyleSuggestionState': textStyleSuggestionState!.toJson(),
      };
}

/// A solid color.
class Color {
  /// The RGB color value.
  RgbColor? rgbColor;

  Color();

  Color.fromJson(core.Map _json) {
    if (_json.containsKey('rgbColor')) {
      rgbColor = RgbColor.fromJson(
          _json['rgbColor'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rgbColor != null) 'rgbColor': rgbColor!.toJson(),
      };
}

/// A ParagraphElement representing a column break.
///
/// A column break makes the subsequent text start at the top of the next
/// column.
class ColumnBreak {
  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// A ColumnBreak may have multiple insertion IDs if it is a nested suggested
  /// change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  /// The suggested text style changes to this ColumnBreak, keyed by suggestion
  /// ID.
  core.Map<core.String, SuggestedTextStyle>? suggestedTextStyleChanges;

  /// The text style of this ColumnBreak.
  ///
  /// Similar to text content, like text runs and footnote references, the text
  /// style of a column break can affect content layout as well as the styling
  /// of text inserted adjacent to it.
  TextStyle? textStyle;

  ColumnBreak();

  ColumnBreak.fromJson(core.Map _json) {
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedTextStyleChanges')) {
      suggestedTextStyleChanges = (_json['suggestedTextStyleChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedTextStyle.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
        if (suggestedTextStyleChanges != null)
          'suggestedTextStyleChanges': suggestedTextStyleChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
      };
}

/// Creates a Footer.
///
/// The new footer is applied to the SectionStyle at the location of the
/// SectionBreak if specificed, otherwise it is applied to the DocumentStyle. If
/// a footer of the specified type already exists, a 400 bad request error is
/// returned.
class CreateFooterRequest {
  /// The location of the SectionBreak immediately preceding the section whose
  /// SectionStyle this footer should belong to.
  ///
  /// If this is unset or refers to the first section break in the document, the
  /// footer applies to the document style.
  Location? sectionBreakLocation;

  /// The type of footer to create.
  /// Possible string values are:
  /// - "HEADER_FOOTER_TYPE_UNSPECIFIED" : The header/footer type is
  /// unspecified.
  /// - "DEFAULT" : A default header/footer.
  core.String? type;

  CreateFooterRequest();

  CreateFooterRequest.fromJson(core.Map _json) {
    if (_json.containsKey('sectionBreakLocation')) {
      sectionBreakLocation = Location.fromJson(
          _json['sectionBreakLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sectionBreakLocation != null)
          'sectionBreakLocation': sectionBreakLocation!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// The result of creating a footer.
class CreateFooterResponse {
  /// The ID of the created footer.
  core.String? footerId;

  CreateFooterResponse();

  CreateFooterResponse.fromJson(core.Map _json) {
    if (_json.containsKey('footerId')) {
      footerId = _json['footerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (footerId != null) 'footerId': footerId!,
      };
}

/// Creates a Footnote segment and inserts a new FootnoteReference to it at the
/// given location.
///
/// The new Footnote segment will contain a space followed by a newline
/// character.
class CreateFootnoteRequest {
  /// Inserts the footnote reference at the end of the document body.
  ///
  /// Footnote references cannot be inserted inside a header, footer or
  /// footnote. Since footnote references can only be inserted in the body, the
  /// segment ID field must be empty.
  EndOfSegmentLocation? endOfSegmentLocation;

  /// Inserts the footnote reference at a specific index in the document.
  ///
  /// The footnote reference must be inserted inside the bounds of an existing
  /// Paragraph. For instance, it cannot be inserted at a table's start index
  /// (i.e. between the table and its preceding paragraph). Footnote references
  /// cannot be inserted inside an equation, header, footer or footnote. Since
  /// footnote references can only be inserted in the body, the segment ID field
  /// must be empty.
  Location? location;

  CreateFootnoteRequest();

  CreateFootnoteRequest.fromJson(core.Map _json) {
    if (_json.containsKey('endOfSegmentLocation')) {
      endOfSegmentLocation = EndOfSegmentLocation.fromJson(
          _json['endOfSegmentLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('location')) {
      location = Location.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endOfSegmentLocation != null)
          'endOfSegmentLocation': endOfSegmentLocation!.toJson(),
        if (location != null) 'location': location!.toJson(),
      };
}

/// The result of creating a footnote.
class CreateFootnoteResponse {
  /// The ID of the created footnote.
  core.String? footnoteId;

  CreateFootnoteResponse();

  CreateFootnoteResponse.fromJson(core.Map _json) {
    if (_json.containsKey('footnoteId')) {
      footnoteId = _json['footnoteId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (footnoteId != null) 'footnoteId': footnoteId!,
      };
}

/// Creates a Header.
///
/// The new header is applied to the SectionStyle at the location of the
/// SectionBreak if specificed, otherwise it is applied to the DocumentStyle. If
/// a header of the specified type already exists, a 400 bad request error is
/// returned.
class CreateHeaderRequest {
  /// The location of the SectionBreak which begins the section this header
  /// should belong to.
  ///
  /// If \`section_break_location' is unset or if it refers to the first section
  /// break in the document body, the header applies to the DocumentStyle
  Location? sectionBreakLocation;

  /// The type of header to create.
  /// Possible string values are:
  /// - "HEADER_FOOTER_TYPE_UNSPECIFIED" : The header/footer type is
  /// unspecified.
  /// - "DEFAULT" : A default header/footer.
  core.String? type;

  CreateHeaderRequest();

  CreateHeaderRequest.fromJson(core.Map _json) {
    if (_json.containsKey('sectionBreakLocation')) {
      sectionBreakLocation = Location.fromJson(
          _json['sectionBreakLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sectionBreakLocation != null)
          'sectionBreakLocation': sectionBreakLocation!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// The result of creating a header.
class CreateHeaderResponse {
  /// The ID of the created header.
  core.String? headerId;

  CreateHeaderResponse();

  CreateHeaderResponse.fromJson(core.Map _json) {
    if (_json.containsKey('headerId')) {
      headerId = _json['headerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (headerId != null) 'headerId': headerId!,
      };
}

/// Creates a NamedRange referencing the given range.
class CreateNamedRangeRequest {
  /// The name of the NamedRange.
  ///
  /// Names do not need to be unique. Names must be at least 1 character and no
  /// more than 256 characters, measured in UTF-16 code units.
  core.String? name;

  /// The range to apply the name to.
  Range? range;

  CreateNamedRangeRequest();

  CreateNamedRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('range')) {
      range =
          Range.fromJson(_json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (range != null) 'range': range!.toJson(),
      };
}

/// The result of creating a named range.
class CreateNamedRangeResponse {
  /// The ID of the created named range.
  core.String? namedRangeId;

  CreateNamedRangeResponse();

  CreateNamedRangeResponse.fromJson(core.Map _json) {
    if (_json.containsKey('namedRangeId')) {
      namedRangeId = _json['namedRangeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (namedRangeId != null) 'namedRangeId': namedRangeId!,
      };
}

/// Creates bullets for all of the paragraphs that overlap with the given range.
///
/// The nesting level of each paragraph will be determined by counting leading
/// tabs in front of each paragraph. To avoid excess space between the bullet
/// and the corresponding paragraph, these leading tabs are removed by this
/// request. This may change the indices of parts of the text. If the paragraph
/// immediately before paragraphs being updated is in a list with a matching
/// preset, the paragraphs being updated are added to that preceding list.
class CreateParagraphBulletsRequest {
  /// The kinds of bullet glyphs to be used.
  /// Possible string values are:
  /// - "BULLET_GLYPH_PRESET_UNSPECIFIED" : The bullet glyph preset is
  /// unspecified.
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
  /// - "NUMBERED_DECIMAL_ALPHA_ROMAN" : A numbered list with `DECIMAL`, `ALPHA`
  /// and `ROMAN` numeric glyphs for the first 3 list nesting levels, followed
  /// by periods.
  /// - "NUMBERED_DECIMAL_ALPHA_ROMAN_PARENS" : A numbered list with `DECIMAL`,
  /// `ALPHA` and `ROMAN` numeric glyphs for the first 3 list nesting levels,
  /// followed by parenthesis.
  /// - "NUMBERED_DECIMAL_NESTED" : A numbered list with `DECIMAL` numeric
  /// glyphs separated by periods, where each nesting level uses the previous
  /// nesting level's glyph as a prefix. For example: '1.', '1.1.', '2.',
  /// '2.2.'.
  /// - "NUMBERED_UPPERALPHA_ALPHA_ROMAN" : A numbered list with `UPPERALPHA`,
  /// `ALPHA` and `ROMAN` numeric glyphs for the first 3 list nesting levels,
  /// followed by periods.
  /// - "NUMBERED_UPPERROMAN_UPPERALPHA_DECIMAL" : A numbered list with
  /// `UPPERROMAN`, `UPPERALPHA` and `DECIMAL` numeric glyphs for the first 3
  /// list nesting levels, followed by periods.
  /// - "NUMBERED_ZERODECIMAL_ALPHA_ROMAN" : A numbered list with `ZERODECIMAL`,
  /// `ALPHA` and `ROMAN` numeric glyphs for the first 3 list nesting levels,
  /// followed by periods.
  core.String? bulletPreset;

  /// The range to apply the bullet preset to.
  Range? range;

  CreateParagraphBulletsRequest();

  CreateParagraphBulletsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('bulletPreset')) {
      bulletPreset = _json['bulletPreset'] as core.String;
    }
    if (_json.containsKey('range')) {
      range =
          Range.fromJson(_json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bulletPreset != null) 'bulletPreset': bulletPreset!,
        if (range != null) 'range': range!.toJson(),
      };
}

/// The crop properties of an image.
///
/// The crop rectangle is represented using fractional offsets from the original
/// content's four edges. - If the offset is in the interval (0, 1), the
/// corresponding edge of crop rectangle is positioned inside of the image's
/// original bounding rectangle. - If the offset is negative or greater than 1,
/// the corresponding edge of crop rectangle is positioned outside of the
/// image's original bounding rectangle. - If all offsets and rotation angle are
/// 0, the image is not cropped.
class CropProperties {
  /// The clockwise rotation angle of the crop rectangle around its center, in
  /// radians.
  ///
  /// Rotation is applied after the offsets.
  core.double? angle;

  /// The offset specifies how far inwards the bottom edge of the crop rectangle
  /// is from the bottom edge of the original content as a fraction of the
  /// original content's height.
  core.double? offsetBottom;

  /// The offset specifies how far inwards the left edge of the crop rectangle
  /// is from the left edge of the original content as a fraction of the
  /// original content's width.
  core.double? offsetLeft;

  /// The offset specifies how far inwards the right edge of the crop rectangle
  /// is from the right edge of the original content as a fraction of the
  /// original content's width.
  core.double? offsetRight;

  /// The offset specifies how far inwards the top edge of the crop rectangle is
  /// from the top edge of the original content as a fraction of the original
  /// content's height.
  core.double? offsetTop;

  CropProperties();

  CropProperties.fromJson(core.Map _json) {
    if (_json.containsKey('angle')) {
      angle = (_json['angle'] as core.num).toDouble();
    }
    if (_json.containsKey('offsetBottom')) {
      offsetBottom = (_json['offsetBottom'] as core.num).toDouble();
    }
    if (_json.containsKey('offsetLeft')) {
      offsetLeft = (_json['offsetLeft'] as core.num).toDouble();
    }
    if (_json.containsKey('offsetRight')) {
      offsetRight = (_json['offsetRight'] as core.num).toDouble();
    }
    if (_json.containsKey('offsetTop')) {
      offsetTop = (_json['offsetTop'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (angle != null) 'angle': angle!,
        if (offsetBottom != null) 'offsetBottom': offsetBottom!,
        if (offsetLeft != null) 'offsetLeft': offsetLeft!,
        if (offsetRight != null) 'offsetRight': offsetRight!,
        if (offsetTop != null) 'offsetTop': offsetTop!,
      };
}

/// A mask that indicates which of the fields on the base CropProperties have
/// been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class CropPropertiesSuggestionState {
  /// Indicates if there was a suggested change to angle.
  core.bool? angleSuggested;

  /// Indicates if there was a suggested change to offset_bottom.
  core.bool? offsetBottomSuggested;

  /// Indicates if there was a suggested change to offset_left.
  core.bool? offsetLeftSuggested;

  /// Indicates if there was a suggested change to offset_right.
  core.bool? offsetRightSuggested;

  /// Indicates if there was a suggested change to offset_top.
  core.bool? offsetTopSuggested;

  CropPropertiesSuggestionState();

  CropPropertiesSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('angleSuggested')) {
      angleSuggested = _json['angleSuggested'] as core.bool;
    }
    if (_json.containsKey('offsetBottomSuggested')) {
      offsetBottomSuggested = _json['offsetBottomSuggested'] as core.bool;
    }
    if (_json.containsKey('offsetLeftSuggested')) {
      offsetLeftSuggested = _json['offsetLeftSuggested'] as core.bool;
    }
    if (_json.containsKey('offsetRightSuggested')) {
      offsetRightSuggested = _json['offsetRightSuggested'] as core.bool;
    }
    if (_json.containsKey('offsetTopSuggested')) {
      offsetTopSuggested = _json['offsetTopSuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (angleSuggested != null) 'angleSuggested': angleSuggested!,
        if (offsetBottomSuggested != null)
          'offsetBottomSuggested': offsetBottomSuggested!,
        if (offsetLeftSuggested != null)
          'offsetLeftSuggested': offsetLeftSuggested!,
        if (offsetRightSuggested != null)
          'offsetRightSuggested': offsetRightSuggested!,
        if (offsetTopSuggested != null)
          'offsetTopSuggested': offsetTopSuggested!,
      };
}

/// Deletes content from the document.
class DeleteContentRangeRequest {
  /// The range of content to delete.
  ///
  /// Deleting text that crosses a paragraph boundary may result in changes to
  /// paragraph styles, lists, positioned objects and bookmarks as the two
  /// paragraphs are merged. Attempting to delete certain ranges can result in
  /// an invalid document structure in which case a 400 bad request error is
  /// returned. Some examples of invalid delete requests include: * Deleting one
  /// code unit of a surrogate pair. * Deleting the last newline character of a
  /// Body, Header, Footer, Footnote, TableCell or TableOfContents. * Deleting
  /// the start or end of a Table, TableOfContents or Equation without deleting
  /// the entire element. * Deleting the newline character before a Table,
  /// TableOfContents or SectionBreak without deleting the element. * Deleting
  /// individual rows or cells of a table. Deleting the content within a table
  /// cell is allowed.
  Range? range;

  DeleteContentRangeRequest();

  DeleteContentRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range =
          Range.fromJson(_json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
      };
}

/// Deletes a Footer from the document.
class DeleteFooterRequest {
  /// The id of the footer to delete.
  ///
  /// If this footer is defined on DocumentStyle, the reference to this footer
  /// is removed, resulting in no footer of that type for the first section of
  /// the document. If this footer is defined on a SectionStyle, the reference
  /// to this footer is removed and the footer of that type is now continued
  /// from the previous section.
  core.String? footerId;

  DeleteFooterRequest();

  DeleteFooterRequest.fromJson(core.Map _json) {
    if (_json.containsKey('footerId')) {
      footerId = _json['footerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (footerId != null) 'footerId': footerId!,
      };
}

/// Deletes a Header from the document.
class DeleteHeaderRequest {
  /// The id of the header to delete.
  ///
  /// If this header is defined on DocumentStyle, the reference to this header
  /// is removed, resulting in no header of that type for the first section of
  /// the document. If this header is defined on a SectionStyle, the reference
  /// to this header is removed and the header of that type is now continued
  /// from the previous section.
  core.String? headerId;

  DeleteHeaderRequest();

  DeleteHeaderRequest.fromJson(core.Map _json) {
    if (_json.containsKey('headerId')) {
      headerId = _json['headerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (headerId != null) 'headerId': headerId!,
      };
}

/// Deletes a NamedRange.
class DeleteNamedRangeRequest {
  /// The name of the range(s) to delete.
  ///
  /// All named ranges with the given name will be deleted.
  core.String? name;

  /// The ID of the named range to delete.
  core.String? namedRangeId;

  DeleteNamedRangeRequest();

  DeleteNamedRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('namedRangeId')) {
      namedRangeId = _json['namedRangeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (namedRangeId != null) 'namedRangeId': namedRangeId!,
      };
}

/// Deletes bullets from all of the paragraphs that overlap with the given
/// range.
///
/// The nesting level of each paragraph will be visually preserved by adding
/// indent to the start of the corresponding paragraph.
class DeleteParagraphBulletsRequest {
  /// The range to delete bullets from.
  Range? range;

  DeleteParagraphBulletsRequest();

  DeleteParagraphBulletsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range =
          Range.fromJson(_json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
      };
}

/// Deletes a PositionedObject from the document.
class DeletePositionedObjectRequest {
  /// The ID of the positioned object to delete.
  core.String? objectId;

  DeletePositionedObjectRequest();

  DeletePositionedObjectRequest.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Deletes a column from a table.
class DeleteTableColumnRequest {
  /// The reference table cell location from which the column will be deleted.
  ///
  /// The column this cell spans will be deleted. If this is a merged cell that
  /// spans multiple columns, all columns that the cell spans will be deleted.
  /// If no columns remain in the table after this deletion, the whole table is
  /// deleted.
  TableCellLocation? tableCellLocation;

  DeleteTableColumnRequest();

  DeleteTableColumnRequest.fromJson(core.Map _json) {
    if (_json.containsKey('tableCellLocation')) {
      tableCellLocation = TableCellLocation.fromJson(
          _json['tableCellLocation'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tableCellLocation != null)
          'tableCellLocation': tableCellLocation!.toJson(),
      };
}

/// Deletes a row from a table.
class DeleteTableRowRequest {
  /// The reference table cell location from which the row will be deleted.
  ///
  /// The row this cell spans will be deleted. If this is a merged cell that
  /// spans multiple rows, all rows that the cell spans will be deleted. If no
  /// rows remain in the table after this deletion, the whole table is deleted.
  TableCellLocation? tableCellLocation;

  DeleteTableRowRequest();

  DeleteTableRowRequest.fromJson(core.Map _json) {
    if (_json.containsKey('tableCellLocation')) {
      tableCellLocation = TableCellLocation.fromJson(
          _json['tableCellLocation'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tableCellLocation != null)
          'tableCellLocation': tableCellLocation!.toJson(),
      };
}

/// A magnitude in a single direction in the specified units.
class Dimension {
  /// The magnitude.
  core.double? magnitude;

  /// The units for magnitude.
  /// Possible string values are:
  /// - "UNIT_UNSPECIFIED" : The units are unknown.
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

/// A Google Docs document.
class Document {
  /// The main body of the document.
  ///
  /// Output only.
  Body? body;

  /// The ID of the document.
  ///
  /// Output only.
  core.String? documentId;

  /// The style of the document.
  ///
  /// Output only.
  DocumentStyle? documentStyle;

  /// The footers in the document, keyed by footer ID.
  ///
  /// Output only.
  core.Map<core.String, Footer>? footers;

  /// The footnotes in the document, keyed by footnote ID.
  ///
  /// Output only.
  core.Map<core.String, Footnote>? footnotes;

  /// The headers in the document, keyed by header ID.
  ///
  /// Output only.
  core.Map<core.String, Header>? headers;

  /// The inline objects in the document, keyed by object ID.
  ///
  /// Output only.
  core.Map<core.String, InlineObject>? inlineObjects;

  /// The lists in the document, keyed by list ID.
  ///
  /// Output only.
  core.Map<core.String, List>? lists;

  /// The named ranges in the document, keyed by name.
  ///
  /// Output only.
  core.Map<core.String, NamedRanges>? namedRanges;

  /// The named styles of the document.
  ///
  /// Output only.
  NamedStyles? namedStyles;

  /// The positioned objects in the document, keyed by object ID.
  ///
  /// Output only.
  core.Map<core.String, PositionedObject>? positionedObjects;

  /// The revision ID of the document.
  ///
  /// Can be used in update requests to specify which revision of a document to
  /// apply updates to and how the request should behave if the document has
  /// been edited since that revision. Only populated if the user has edit
  /// access to the document. The format of the revision ID may change over
  /// time, so it should be treated opaquely. A returned revision ID is only
  /// guaranteed to be valid for 24 hours after it has been returned and cannot
  /// be shared across users. If the revision ID is unchanged between calls,
  /// then the document has not changed. Conversely, a changed ID (for the same
  /// document and user) usually means the document has been updated; however, a
  /// changed ID can also be due to internal factors such as ID format changes.
  ///
  /// Output only.
  core.String? revisionId;

  /// The suggested changes to the style of the document, keyed by suggestion
  /// ID.
  ///
  /// Output only.
  core.Map<core.String, SuggestedDocumentStyle>? suggestedDocumentStyleChanges;

  /// The suggested changes to the named styles of the document, keyed by
  /// suggestion ID.
  ///
  /// Output only.
  core.Map<core.String, SuggestedNamedStyles>? suggestedNamedStylesChanges;

  /// The suggestions view mode applied to the document.
  ///
  /// Note: When editing a document, changes must be based on a document with
  /// SUGGESTIONS_INLINE.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "DEFAULT_FOR_CURRENT_ACCESS" : The SuggestionsViewMode applied to the
  /// returned document depends on the user's current access level. If the user
  /// only has view access, PREVIEW_WITHOUT_SUGGESTIONS is applied. Otherwise,
  /// SUGGESTIONS_INLINE is applied. This is the default suggestions view mode.
  /// - "SUGGESTIONS_INLINE" : The returned document has suggestions inline.
  /// Suggested changes will be differentiated from base content within the
  /// document. Requests to retrieve a document using this mode will return a
  /// 403 error if the user does not have permission to view suggested changes.
  /// - "PREVIEW_SUGGESTIONS_ACCEPTED" : The returned document is a preview with
  /// all suggested changes accepted. Requests to retrieve a document using this
  /// mode will return a 403 error if the user does not have permission to view
  /// suggested changes.
  /// - "PREVIEW_WITHOUT_SUGGESTIONS" : The returned document is a preview with
  /// all suggested changes rejected if there are any suggestions in the
  /// document.
  core.String? suggestionsViewMode;

  /// The title of the document.
  core.String? title;

  Document();

  Document.fromJson(core.Map _json) {
    if (_json.containsKey('body')) {
      body =
          Body.fromJson(_json['body'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('documentId')) {
      documentId = _json['documentId'] as core.String;
    }
    if (_json.containsKey('documentStyle')) {
      documentStyle = DocumentStyle.fromJson(
          _json['documentStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('footers')) {
      footers = (_json['footers'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          Footer.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('footnotes')) {
      footnotes =
          (_json['footnotes'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          Footnote.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('headers')) {
      headers = (_json['headers'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          Header.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('inlineObjects')) {
      inlineObjects =
          (_json['inlineObjects'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          InlineObject.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('lists')) {
      lists = (_json['lists'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          List.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('namedRanges')) {
      namedRanges =
          (_json['namedRanges'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          NamedRanges.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('namedStyles')) {
      namedStyles = NamedStyles.fromJson(
          _json['namedStyles'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('positionedObjects')) {
      positionedObjects =
          (_json['positionedObjects'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          PositionedObject.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('revisionId')) {
      revisionId = _json['revisionId'] as core.String;
    }
    if (_json.containsKey('suggestedDocumentStyleChanges')) {
      suggestedDocumentStyleChanges = (_json['suggestedDocumentStyleChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedDocumentStyle.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('suggestedNamedStylesChanges')) {
      suggestedNamedStylesChanges = (_json['suggestedNamedStylesChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedNamedStyles.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('suggestionsViewMode')) {
      suggestionsViewMode = _json['suggestionsViewMode'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (body != null) 'body': body!.toJson(),
        if (documentId != null) 'documentId': documentId!,
        if (documentStyle != null) 'documentStyle': documentStyle!.toJson(),
        if (footers != null)
          'footers':
              footers!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (footnotes != null)
          'footnotes':
              footnotes!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (headers != null)
          'headers':
              headers!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (inlineObjects != null)
          'inlineObjects': inlineObjects!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (lists != null)
          'lists': lists!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (namedRanges != null)
          'namedRanges': namedRanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (namedStyles != null) 'namedStyles': namedStyles!.toJson(),
        if (positionedObjects != null)
          'positionedObjects': positionedObjects!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (revisionId != null) 'revisionId': revisionId!,
        if (suggestedDocumentStyleChanges != null)
          'suggestedDocumentStyleChanges': suggestedDocumentStyleChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (suggestedNamedStylesChanges != null)
          'suggestedNamedStylesChanges': suggestedNamedStylesChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (suggestionsViewMode != null)
          'suggestionsViewMode': suggestionsViewMode!,
        if (title != null) 'title': title!,
      };
}

/// The style of the document.
class DocumentStyle {
  /// The background of the document.
  ///
  /// Documents cannot have a transparent background color.
  Background? background;

  /// The ID of the default footer.
  ///
  /// If not set, there is no default footer. This property is read-only.
  core.String? defaultFooterId;

  /// The ID of the default header.
  ///
  /// If not set, there is no default header. This property is read-only.
  core.String? defaultHeaderId;

  /// The ID of the footer used only for even pages.
  ///
  /// The value of use_even_page_header_footer determines whether to use the
  /// default_footer_id or this value for the footer on even pages. If not set,
  /// there is no even page footer. This property is read-only.
  core.String? evenPageFooterId;

  /// The ID of the header used only for even pages.
  ///
  /// The value of use_even_page_header_footer determines whether to use the
  /// default_header_id or this value for the header on even pages. If not set,
  /// there is no even page header. This property is read-only.
  core.String? evenPageHeaderId;

  /// The ID of the footer used only for the first page.
  ///
  /// If not set then a unique footer for the first page does not exist. The
  /// value of use_first_page_header_footer determines whether to use the
  /// default_footer_id or this value for the footer on the first page. If not
  /// set, there is no first page footer. This property is read-only.
  core.String? firstPageFooterId;

  /// The ID of the header used only for the first page.
  ///
  /// If not set then a unique header for the first page does not exist. The
  /// value of use_first_page_header_footer determines whether to use the
  /// default_header_id or this value for the header on the first page. If not
  /// set, there is no first page header. This property is read-only.
  core.String? firstPageHeaderId;

  /// The bottom page margin.
  ///
  /// Updating the bottom page margin on the document style clears the bottom
  /// page margin on all section styles.
  Dimension? marginBottom;

  /// The amount of space between the bottom of the page and the contents of the
  /// footer.
  Dimension? marginFooter;

  /// The amount of space between the top of the page and the contents of the
  /// header.
  Dimension? marginHeader;

  /// The left page margin.
  ///
  /// Updating the left page margin on the document style clears the left page
  /// margin on all section styles. It may also cause columns to resize in all
  /// sections.
  Dimension? marginLeft;

  /// The right page margin.
  ///
  /// Updating the right page margin on the document style clears the right page
  /// margin on all section styles. It may also cause columns to resize in all
  /// sections.
  Dimension? marginRight;

  /// The top page margin.
  ///
  /// Updating the top page margin on the document style clears the top page
  /// margin on all section styles.
  Dimension? marginTop;

  /// The page number from which to start counting the number of pages.
  core.int? pageNumberStart;

  /// The size of a page in the document.
  Size? pageSize;

  /// Indicates whether DocumentStyle margin_header, SectionStyle margin_header
  /// and DocumentStyle margin_footer, SectionStyle margin_footer are respected.
  ///
  /// When false, the default values in the Docs editor for header and footer
  /// margin are used. This property is read-only.
  core.bool? useCustomHeaderFooterMargins;

  /// Indicates whether to use the even page header / footer IDs for the even
  /// pages.
  core.bool? useEvenPageHeaderFooter;

  /// Indicates whether to use the first page header / footer IDs for the first
  /// page.
  core.bool? useFirstPageHeaderFooter;

  DocumentStyle();

  DocumentStyle.fromJson(core.Map _json) {
    if (_json.containsKey('background')) {
      background = Background.fromJson(
          _json['background'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('defaultFooterId')) {
      defaultFooterId = _json['defaultFooterId'] as core.String;
    }
    if (_json.containsKey('defaultHeaderId')) {
      defaultHeaderId = _json['defaultHeaderId'] as core.String;
    }
    if (_json.containsKey('evenPageFooterId')) {
      evenPageFooterId = _json['evenPageFooterId'] as core.String;
    }
    if (_json.containsKey('evenPageHeaderId')) {
      evenPageHeaderId = _json['evenPageHeaderId'] as core.String;
    }
    if (_json.containsKey('firstPageFooterId')) {
      firstPageFooterId = _json['firstPageFooterId'] as core.String;
    }
    if (_json.containsKey('firstPageHeaderId')) {
      firstPageHeaderId = _json['firstPageHeaderId'] as core.String;
    }
    if (_json.containsKey('marginBottom')) {
      marginBottom = Dimension.fromJson(
          _json['marginBottom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginFooter')) {
      marginFooter = Dimension.fromJson(
          _json['marginFooter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginHeader')) {
      marginHeader = Dimension.fromJson(
          _json['marginHeader'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginLeft')) {
      marginLeft = Dimension.fromJson(
          _json['marginLeft'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginRight')) {
      marginRight = Dimension.fromJson(
          _json['marginRight'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginTop')) {
      marginTop = Dimension.fromJson(
          _json['marginTop'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pageNumberStart')) {
      pageNumberStart = _json['pageNumberStart'] as core.int;
    }
    if (_json.containsKey('pageSize')) {
      pageSize = Size.fromJson(
          _json['pageSize'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('useCustomHeaderFooterMargins')) {
      useCustomHeaderFooterMargins =
          _json['useCustomHeaderFooterMargins'] as core.bool;
    }
    if (_json.containsKey('useEvenPageHeaderFooter')) {
      useEvenPageHeaderFooter = _json['useEvenPageHeaderFooter'] as core.bool;
    }
    if (_json.containsKey('useFirstPageHeaderFooter')) {
      useFirstPageHeaderFooter = _json['useFirstPageHeaderFooter'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (background != null) 'background': background!.toJson(),
        if (defaultFooterId != null) 'defaultFooterId': defaultFooterId!,
        if (defaultHeaderId != null) 'defaultHeaderId': defaultHeaderId!,
        if (evenPageFooterId != null) 'evenPageFooterId': evenPageFooterId!,
        if (evenPageHeaderId != null) 'evenPageHeaderId': evenPageHeaderId!,
        if (firstPageFooterId != null) 'firstPageFooterId': firstPageFooterId!,
        if (firstPageHeaderId != null) 'firstPageHeaderId': firstPageHeaderId!,
        if (marginBottom != null) 'marginBottom': marginBottom!.toJson(),
        if (marginFooter != null) 'marginFooter': marginFooter!.toJson(),
        if (marginHeader != null) 'marginHeader': marginHeader!.toJson(),
        if (marginLeft != null) 'marginLeft': marginLeft!.toJson(),
        if (marginRight != null) 'marginRight': marginRight!.toJson(),
        if (marginTop != null) 'marginTop': marginTop!.toJson(),
        if (pageNumberStart != null) 'pageNumberStart': pageNumberStart!,
        if (pageSize != null) 'pageSize': pageSize!.toJson(),
        if (useCustomHeaderFooterMargins != null)
          'useCustomHeaderFooterMargins': useCustomHeaderFooterMargins!,
        if (useEvenPageHeaderFooter != null)
          'useEvenPageHeaderFooter': useEvenPageHeaderFooter!,
        if (useFirstPageHeaderFooter != null)
          'useFirstPageHeaderFooter': useFirstPageHeaderFooter!,
      };
}

/// A mask that indicates which of the fields on the base DocumentStyle have
/// been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class DocumentStyleSuggestionState {
  /// A mask that indicates which of the fields in background have been changed
  /// in this suggestion.
  BackgroundSuggestionState? backgroundSuggestionState;

  /// Indicates if there was a suggested change to default_footer_id.
  core.bool? defaultFooterIdSuggested;

  /// Indicates if there was a suggested change to default_header_id.
  core.bool? defaultHeaderIdSuggested;

  /// Indicates if there was a suggested change to even_page_footer_id.
  core.bool? evenPageFooterIdSuggested;

  /// Indicates if there was a suggested change to even_page_header_id.
  core.bool? evenPageHeaderIdSuggested;

  /// Indicates if there was a suggested change to first_page_footer_id.
  core.bool? firstPageFooterIdSuggested;

  /// Indicates if there was a suggested change to first_page_header_id.
  core.bool? firstPageHeaderIdSuggested;

  /// Indicates if there was a suggested change to margin_bottom.
  core.bool? marginBottomSuggested;

  /// Indicates if there was a suggested change to margin_footer.
  core.bool? marginFooterSuggested;

  /// Indicates if there was a suggested change to margin_header.
  core.bool? marginHeaderSuggested;

  /// Indicates if there was a suggested change to margin_left.
  core.bool? marginLeftSuggested;

  /// Indicates if there was a suggested change to margin_right.
  core.bool? marginRightSuggested;

  /// Indicates if there was a suggested change to margin_top.
  core.bool? marginTopSuggested;

  /// Indicates if there was a suggested change to page_number_start.
  core.bool? pageNumberStartSuggested;

  /// A mask that indicates which of the fields in size have been changed in
  /// this suggestion.
  SizeSuggestionState? pageSizeSuggestionState;

  /// Indicates if there was a suggested change to
  /// use_custom_header_footer_margins.
  core.bool? useCustomHeaderFooterMarginsSuggested;

  /// Indicates if there was a suggested change to use_even_page_header_footer.
  core.bool? useEvenPageHeaderFooterSuggested;

  /// Indicates if there was a suggested change to use_first_page_header_footer.
  core.bool? useFirstPageHeaderFooterSuggested;

  DocumentStyleSuggestionState();

  DocumentStyleSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundSuggestionState')) {
      backgroundSuggestionState = BackgroundSuggestionState.fromJson(
          _json['backgroundSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('defaultFooterIdSuggested')) {
      defaultFooterIdSuggested = _json['defaultFooterIdSuggested'] as core.bool;
    }
    if (_json.containsKey('defaultHeaderIdSuggested')) {
      defaultHeaderIdSuggested = _json['defaultHeaderIdSuggested'] as core.bool;
    }
    if (_json.containsKey('evenPageFooterIdSuggested')) {
      evenPageFooterIdSuggested =
          _json['evenPageFooterIdSuggested'] as core.bool;
    }
    if (_json.containsKey('evenPageHeaderIdSuggested')) {
      evenPageHeaderIdSuggested =
          _json['evenPageHeaderIdSuggested'] as core.bool;
    }
    if (_json.containsKey('firstPageFooterIdSuggested')) {
      firstPageFooterIdSuggested =
          _json['firstPageFooterIdSuggested'] as core.bool;
    }
    if (_json.containsKey('firstPageHeaderIdSuggested')) {
      firstPageHeaderIdSuggested =
          _json['firstPageHeaderIdSuggested'] as core.bool;
    }
    if (_json.containsKey('marginBottomSuggested')) {
      marginBottomSuggested = _json['marginBottomSuggested'] as core.bool;
    }
    if (_json.containsKey('marginFooterSuggested')) {
      marginFooterSuggested = _json['marginFooterSuggested'] as core.bool;
    }
    if (_json.containsKey('marginHeaderSuggested')) {
      marginHeaderSuggested = _json['marginHeaderSuggested'] as core.bool;
    }
    if (_json.containsKey('marginLeftSuggested')) {
      marginLeftSuggested = _json['marginLeftSuggested'] as core.bool;
    }
    if (_json.containsKey('marginRightSuggested')) {
      marginRightSuggested = _json['marginRightSuggested'] as core.bool;
    }
    if (_json.containsKey('marginTopSuggested')) {
      marginTopSuggested = _json['marginTopSuggested'] as core.bool;
    }
    if (_json.containsKey('pageNumberStartSuggested')) {
      pageNumberStartSuggested = _json['pageNumberStartSuggested'] as core.bool;
    }
    if (_json.containsKey('pageSizeSuggestionState')) {
      pageSizeSuggestionState = SizeSuggestionState.fromJson(
          _json['pageSizeSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('useCustomHeaderFooterMarginsSuggested')) {
      useCustomHeaderFooterMarginsSuggested =
          _json['useCustomHeaderFooterMarginsSuggested'] as core.bool;
    }
    if (_json.containsKey('useEvenPageHeaderFooterSuggested')) {
      useEvenPageHeaderFooterSuggested =
          _json['useEvenPageHeaderFooterSuggested'] as core.bool;
    }
    if (_json.containsKey('useFirstPageHeaderFooterSuggested')) {
      useFirstPageHeaderFooterSuggested =
          _json['useFirstPageHeaderFooterSuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundSuggestionState != null)
          'backgroundSuggestionState': backgroundSuggestionState!.toJson(),
        if (defaultFooterIdSuggested != null)
          'defaultFooterIdSuggested': defaultFooterIdSuggested!,
        if (defaultHeaderIdSuggested != null)
          'defaultHeaderIdSuggested': defaultHeaderIdSuggested!,
        if (evenPageFooterIdSuggested != null)
          'evenPageFooterIdSuggested': evenPageFooterIdSuggested!,
        if (evenPageHeaderIdSuggested != null)
          'evenPageHeaderIdSuggested': evenPageHeaderIdSuggested!,
        if (firstPageFooterIdSuggested != null)
          'firstPageFooterIdSuggested': firstPageFooterIdSuggested!,
        if (firstPageHeaderIdSuggested != null)
          'firstPageHeaderIdSuggested': firstPageHeaderIdSuggested!,
        if (marginBottomSuggested != null)
          'marginBottomSuggested': marginBottomSuggested!,
        if (marginFooterSuggested != null)
          'marginFooterSuggested': marginFooterSuggested!,
        if (marginHeaderSuggested != null)
          'marginHeaderSuggested': marginHeaderSuggested!,
        if (marginLeftSuggested != null)
          'marginLeftSuggested': marginLeftSuggested!,
        if (marginRightSuggested != null)
          'marginRightSuggested': marginRightSuggested!,
        if (marginTopSuggested != null)
          'marginTopSuggested': marginTopSuggested!,
        if (pageNumberStartSuggested != null)
          'pageNumberStartSuggested': pageNumberStartSuggested!,
        if (pageSizeSuggestionState != null)
          'pageSizeSuggestionState': pageSizeSuggestionState!.toJson(),
        if (useCustomHeaderFooterMarginsSuggested != null)
          'useCustomHeaderFooterMarginsSuggested':
              useCustomHeaderFooterMarginsSuggested!,
        if (useEvenPageHeaderFooterSuggested != null)
          'useEvenPageHeaderFooterSuggested': useEvenPageHeaderFooterSuggested!,
        if (useFirstPageHeaderFooterSuggested != null)
          'useFirstPageHeaderFooterSuggested':
              useFirstPageHeaderFooterSuggested!,
      };
}

/// The properties of an embedded drawing.
class EmbeddedDrawingProperties {
  EmbeddedDrawingProperties();

  EmbeddedDrawingProperties.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A mask that indicates which of the fields on the base
/// EmbeddedDrawingProperties have been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class EmbeddedDrawingPropertiesSuggestionState {
  EmbeddedDrawingPropertiesSuggestionState();

  EmbeddedDrawingPropertiesSuggestionState.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// An embedded object in the document.
class EmbeddedObject {
  /// The description of the embedded object.
  ///
  /// The `title` and `description` are both combined to display alt text.
  core.String? description;

  /// The properties of an embedded drawing.
  EmbeddedDrawingProperties? embeddedDrawingProperties;

  /// The border of the embedded object.
  EmbeddedObjectBorder? embeddedObjectBorder;

  /// The properties of an image.
  ImageProperties? imageProperties;

  /// A reference to the external linked source content.
  ///
  /// For example, it contains a reference to the source Sheets chart when the
  /// embedded object is a linked chart. If unset, then the embedded object is
  /// not linked.
  LinkedContentReference? linkedContentReference;

  /// The bottom margin of the embedded object.
  Dimension? marginBottom;

  /// The left margin of the embedded object.
  Dimension? marginLeft;

  /// The right margin of the embedded object.
  Dimension? marginRight;

  /// The top margin of the embedded object.
  Dimension? marginTop;

  /// The visible size of the image after cropping.
  Size? size;

  /// The title of the embedded object.
  ///
  /// The `title` and `description` are both combined to display alt text.
  core.String? title;

  EmbeddedObject();

  EmbeddedObject.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('embeddedDrawingProperties')) {
      embeddedDrawingProperties = EmbeddedDrawingProperties.fromJson(
          _json['embeddedDrawingProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('embeddedObjectBorder')) {
      embeddedObjectBorder = EmbeddedObjectBorder.fromJson(
          _json['embeddedObjectBorder'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('imageProperties')) {
      imageProperties = ImageProperties.fromJson(
          _json['imageProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('linkedContentReference')) {
      linkedContentReference = LinkedContentReference.fromJson(
          _json['linkedContentReference']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginBottom')) {
      marginBottom = Dimension.fromJson(
          _json['marginBottom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginLeft')) {
      marginLeft = Dimension.fromJson(
          _json['marginLeft'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginRight')) {
      marginRight = Dimension.fromJson(
          _json['marginRight'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginTop')) {
      marginTop = Dimension.fromJson(
          _json['marginTop'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('size')) {
      size =
          Size.fromJson(_json['size'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (embeddedDrawingProperties != null)
          'embeddedDrawingProperties': embeddedDrawingProperties!.toJson(),
        if (embeddedObjectBorder != null)
          'embeddedObjectBorder': embeddedObjectBorder!.toJson(),
        if (imageProperties != null)
          'imageProperties': imageProperties!.toJson(),
        if (linkedContentReference != null)
          'linkedContentReference': linkedContentReference!.toJson(),
        if (marginBottom != null) 'marginBottom': marginBottom!.toJson(),
        if (marginLeft != null) 'marginLeft': marginLeft!.toJson(),
        if (marginRight != null) 'marginRight': marginRight!.toJson(),
        if (marginTop != null) 'marginTop': marginTop!.toJson(),
        if (size != null) 'size': size!.toJson(),
        if (title != null) 'title': title!,
      };
}

/// A border around an EmbeddedObject.
class EmbeddedObjectBorder {
  /// The color of the border.
  OptionalColor? color;

  /// The dash style of the border.
  /// Possible string values are:
  /// - "DASH_STYLE_UNSPECIFIED" : Unspecified dash style.
  /// - "SOLID" : Solid line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'solid'. This is the default dash style.
  /// - "DOT" : Dotted line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'dot'.
  /// - "DASH" : Dashed line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'dash'.
  core.String? dashStyle;

  /// The property state of the border property.
  /// Possible string values are:
  /// - "RENDERED" : If a property's state is RENDERED, then the element has the
  /// corresponding property when rendered in the document. This is the default
  /// value.
  /// - "NOT_RENDERED" : If a property's state is NOT_RENDERED, then the element
  /// does not have the corresponding property when rendered in the document.
  core.String? propertyState;

  /// The width of the border.
  Dimension? width;

  EmbeddedObjectBorder();

  EmbeddedObjectBorder.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color = OptionalColor.fromJson(
          _json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dashStyle')) {
      dashStyle = _json['dashStyle'] as core.String;
    }
    if (_json.containsKey('propertyState')) {
      propertyState = _json['propertyState'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = Dimension.fromJson(
          _json['width'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
        if (dashStyle != null) 'dashStyle': dashStyle!,
        if (propertyState != null) 'propertyState': propertyState!,
        if (width != null) 'width': width!.toJson(),
      };
}

/// A mask that indicates which of the fields on the base EmbeddedObjectBorder
/// have been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class EmbeddedObjectBorderSuggestionState {
  /// Indicates if there was a suggested change to color.
  core.bool? colorSuggested;

  /// Indicates if there was a suggested change to dash_style.
  core.bool? dashStyleSuggested;

  /// Indicates if there was a suggested change to property_state.
  core.bool? propertyStateSuggested;

  /// Indicates if there was a suggested change to width.
  core.bool? widthSuggested;

  EmbeddedObjectBorderSuggestionState();

  EmbeddedObjectBorderSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('colorSuggested')) {
      colorSuggested = _json['colorSuggested'] as core.bool;
    }
    if (_json.containsKey('dashStyleSuggested')) {
      dashStyleSuggested = _json['dashStyleSuggested'] as core.bool;
    }
    if (_json.containsKey('propertyStateSuggested')) {
      propertyStateSuggested = _json['propertyStateSuggested'] as core.bool;
    }
    if (_json.containsKey('widthSuggested')) {
      widthSuggested = _json['widthSuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (colorSuggested != null) 'colorSuggested': colorSuggested!,
        if (dashStyleSuggested != null)
          'dashStyleSuggested': dashStyleSuggested!,
        if (propertyStateSuggested != null)
          'propertyStateSuggested': propertyStateSuggested!,
        if (widthSuggested != null) 'widthSuggested': widthSuggested!,
      };
}

/// A mask that indicates which of the fields on the base EmbeddedObject have
/// been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class EmbeddedObjectSuggestionState {
  /// Indicates if there was a suggested change to description.
  core.bool? descriptionSuggested;

  /// A mask that indicates which of the fields in embedded_drawing_properties
  /// have been changed in this suggestion.
  EmbeddedDrawingPropertiesSuggestionState?
      embeddedDrawingPropertiesSuggestionState;

  /// A mask that indicates which of the fields in embedded_object_border have
  /// been changed in this suggestion.
  EmbeddedObjectBorderSuggestionState? embeddedObjectBorderSuggestionState;

  /// A mask that indicates which of the fields in image_properties have been
  /// changed in this suggestion.
  ImagePropertiesSuggestionState? imagePropertiesSuggestionState;

  /// A mask that indicates which of the fields in linked_content_reference have
  /// been changed in this suggestion.
  LinkedContentReferenceSuggestionState? linkedContentReferenceSuggestionState;

  /// Indicates if there was a suggested change to margin_bottom.
  core.bool? marginBottomSuggested;

  /// Indicates if there was a suggested change to margin_left.
  core.bool? marginLeftSuggested;

  /// Indicates if there was a suggested change to margin_right.
  core.bool? marginRightSuggested;

  /// Indicates if there was a suggested change to margin_top.
  core.bool? marginTopSuggested;

  /// A mask that indicates which of the fields in size have been changed in
  /// this suggestion.
  SizeSuggestionState? sizeSuggestionState;

  /// Indicates if there was a suggested change to title.
  core.bool? titleSuggested;

  EmbeddedObjectSuggestionState();

  EmbeddedObjectSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('descriptionSuggested')) {
      descriptionSuggested = _json['descriptionSuggested'] as core.bool;
    }
    if (_json.containsKey('embeddedDrawingPropertiesSuggestionState')) {
      embeddedDrawingPropertiesSuggestionState =
          EmbeddedDrawingPropertiesSuggestionState.fromJson(
              _json['embeddedDrawingPropertiesSuggestionState']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('embeddedObjectBorderSuggestionState')) {
      embeddedObjectBorderSuggestionState =
          EmbeddedObjectBorderSuggestionState.fromJson(
              _json['embeddedObjectBorderSuggestionState']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('imagePropertiesSuggestionState')) {
      imagePropertiesSuggestionState = ImagePropertiesSuggestionState.fromJson(
          _json['imagePropertiesSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('linkedContentReferenceSuggestionState')) {
      linkedContentReferenceSuggestionState =
          LinkedContentReferenceSuggestionState.fromJson(
              _json['linkedContentReferenceSuggestionState']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginBottomSuggested')) {
      marginBottomSuggested = _json['marginBottomSuggested'] as core.bool;
    }
    if (_json.containsKey('marginLeftSuggested')) {
      marginLeftSuggested = _json['marginLeftSuggested'] as core.bool;
    }
    if (_json.containsKey('marginRightSuggested')) {
      marginRightSuggested = _json['marginRightSuggested'] as core.bool;
    }
    if (_json.containsKey('marginTopSuggested')) {
      marginTopSuggested = _json['marginTopSuggested'] as core.bool;
    }
    if (_json.containsKey('sizeSuggestionState')) {
      sizeSuggestionState = SizeSuggestionState.fromJson(
          _json['sizeSuggestionState'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('titleSuggested')) {
      titleSuggested = _json['titleSuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (descriptionSuggested != null)
          'descriptionSuggested': descriptionSuggested!,
        if (embeddedDrawingPropertiesSuggestionState != null)
          'embeddedDrawingPropertiesSuggestionState':
              embeddedDrawingPropertiesSuggestionState!.toJson(),
        if (embeddedObjectBorderSuggestionState != null)
          'embeddedObjectBorderSuggestionState':
              embeddedObjectBorderSuggestionState!.toJson(),
        if (imagePropertiesSuggestionState != null)
          'imagePropertiesSuggestionState':
              imagePropertiesSuggestionState!.toJson(),
        if (linkedContentReferenceSuggestionState != null)
          'linkedContentReferenceSuggestionState':
              linkedContentReferenceSuggestionState!.toJson(),
        if (marginBottomSuggested != null)
          'marginBottomSuggested': marginBottomSuggested!,
        if (marginLeftSuggested != null)
          'marginLeftSuggested': marginLeftSuggested!,
        if (marginRightSuggested != null)
          'marginRightSuggested': marginRightSuggested!,
        if (marginTopSuggested != null)
          'marginTopSuggested': marginTopSuggested!,
        if (sizeSuggestionState != null)
          'sizeSuggestionState': sizeSuggestionState!.toJson(),
        if (titleSuggested != null) 'titleSuggested': titleSuggested!,
      };
}

/// Location at the end of a body, header, footer or footnote.
///
/// The location is immediately before the last newline in the document segment.
class EndOfSegmentLocation {
  /// The ID of the header, footer or footnote the location is in.
  ///
  /// An empty segment ID signifies the document's body.
  core.String? segmentId;

  EndOfSegmentLocation();

  EndOfSegmentLocation.fromJson(core.Map _json) {
    if (_json.containsKey('segmentId')) {
      segmentId = _json['segmentId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segmentId != null) 'segmentId': segmentId!,
      };
}

/// A ParagraphElement representing an equation.
class Equation {
  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// A Equation may have multiple insertion IDs if it is a nested suggested
  /// change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  Equation();

  Equation.fromJson(core.Map _json) {
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
      };
}

/// A document footer.
class Footer {
  /// The contents of the footer.
  ///
  /// The indexes for a footer's content begin at zero.
  core.List<StructuralElement>? content;

  /// The ID of the footer.
  core.String? footerId;

  Footer();

  Footer.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = (_json['content'] as core.List)
          .map<StructuralElement>((value) => StructuralElement.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('footerId')) {
      footerId = _json['footerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null)
          'content': content!.map((value) => value.toJson()).toList(),
        if (footerId != null) 'footerId': footerId!,
      };
}

/// A document footnote.
class Footnote {
  /// The contents of the footnote.
  ///
  /// The indexes for a footnote's content begin at zero.
  core.List<StructuralElement>? content;

  /// The ID of the footnote.
  core.String? footnoteId;

  Footnote();

  Footnote.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = (_json['content'] as core.List)
          .map<StructuralElement>((value) => StructuralElement.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('footnoteId')) {
      footnoteId = _json['footnoteId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null)
          'content': content!.map((value) => value.toJson()).toList(),
        if (footnoteId != null) 'footnoteId': footnoteId!,
      };
}

/// A ParagraphElement representing a footnote reference.
///
/// A footnote reference is the inline content rendered with a number and is
/// used to identify the footnote.
class FootnoteReference {
  /// The ID of the footnote that contains the content of this footnote
  /// reference.
  core.String? footnoteId;

  /// The rendered number of this footnote.
  core.String? footnoteNumber;

  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// A FootnoteReference may have multiple insertion IDs if it is a nested
  /// suggested change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  /// The suggested text style changes to this FootnoteReference, keyed by
  /// suggestion ID.
  core.Map<core.String, SuggestedTextStyle>? suggestedTextStyleChanges;

  /// The text style of this FootnoteReference.
  TextStyle? textStyle;

  FootnoteReference();

  FootnoteReference.fromJson(core.Map _json) {
    if (_json.containsKey('footnoteId')) {
      footnoteId = _json['footnoteId'] as core.String;
    }
    if (_json.containsKey('footnoteNumber')) {
      footnoteNumber = _json['footnoteNumber'] as core.String;
    }
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedTextStyleChanges')) {
      suggestedTextStyleChanges = (_json['suggestedTextStyleChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedTextStyle.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (footnoteId != null) 'footnoteId': footnoteId!,
        if (footnoteNumber != null) 'footnoteNumber': footnoteNumber!,
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
        if (suggestedTextStyleChanges != null)
          'suggestedTextStyleChanges': suggestedTextStyleChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
      };
}

/// A document header.
class Header {
  /// The contents of the header.
  ///
  /// The indexes for a header's content begin at zero.
  core.List<StructuralElement>? content;

  /// The ID of the header.
  core.String? headerId;

  Header();

  Header.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = (_json['content'] as core.List)
          .map<StructuralElement>((value) => StructuralElement.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('headerId')) {
      headerId = _json['headerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null)
          'content': content!.map((value) => value.toJson()).toList(),
        if (headerId != null) 'headerId': headerId!,
      };
}

/// A ParagraphElement representing a horizontal line.
class HorizontalRule {
  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// A HorizontalRule may have multiple insertion IDs if it is a nested
  /// suggested change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  /// The suggested text style changes to this HorizontalRule, keyed by
  /// suggestion ID.
  core.Map<core.String, SuggestedTextStyle>? suggestedTextStyleChanges;

  /// The text style of this HorizontalRule.
  ///
  /// Similar to text content, like text runs and footnote references, the text
  /// style of a horizontal rule can affect content layout as well as the
  /// styling of text inserted adjacent to it.
  TextStyle? textStyle;

  HorizontalRule();

  HorizontalRule.fromJson(core.Map _json) {
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedTextStyleChanges')) {
      suggestedTextStyleChanges = (_json['suggestedTextStyleChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedTextStyle.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
        if (suggestedTextStyleChanges != null)
          'suggestedTextStyleChanges': suggestedTextStyleChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
      };
}

/// The properties of an image.
class ImageProperties {
  /// The clockwise rotation angle of the image, in radians.
  core.double? angle;

  /// The brightness effect of the image.
  ///
  /// The value should be in the interval \[-1.0, 1.0\], where 0 means no
  /// effect.
  core.double? brightness;

  /// A URI to the image with a default lifetime of 30 minutes.
  ///
  /// This URI is tagged with the account of the requester. Anyone with the URI
  /// effectively accesses the image as the original requester. Access to the
  /// image may be lost if the document's sharing settings change.
  core.String? contentUri;

  /// The contrast effect of the image.
  ///
  /// The value should be in the interval \[-1.0, 1.0\], where 0 means no
  /// effect.
  core.double? contrast;

  /// The crop properties of the image.
  CropProperties? cropProperties;

  /// The source URI is the URI used to insert the image.
  ///
  /// The source URI can be empty.
  core.String? sourceUri;

  /// The transparency effect of the image.
  ///
  /// The value should be in the interval \[0.0, 1.0\], where 0 means no effect
  /// and 1 means completely transparent.
  core.double? transparency;

  ImageProperties();

  ImageProperties.fromJson(core.Map _json) {
    if (_json.containsKey('angle')) {
      angle = (_json['angle'] as core.num).toDouble();
    }
    if (_json.containsKey('brightness')) {
      brightness = (_json['brightness'] as core.num).toDouble();
    }
    if (_json.containsKey('contentUri')) {
      contentUri = _json['contentUri'] as core.String;
    }
    if (_json.containsKey('contrast')) {
      contrast = (_json['contrast'] as core.num).toDouble();
    }
    if (_json.containsKey('cropProperties')) {
      cropProperties = CropProperties.fromJson(
          _json['cropProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sourceUri')) {
      sourceUri = _json['sourceUri'] as core.String;
    }
    if (_json.containsKey('transparency')) {
      transparency = (_json['transparency'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (angle != null) 'angle': angle!,
        if (brightness != null) 'brightness': brightness!,
        if (contentUri != null) 'contentUri': contentUri!,
        if (contrast != null) 'contrast': contrast!,
        if (cropProperties != null) 'cropProperties': cropProperties!.toJson(),
        if (sourceUri != null) 'sourceUri': sourceUri!,
        if (transparency != null) 'transparency': transparency!,
      };
}

/// A mask that indicates which of the fields on the base ImageProperties have
/// been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class ImagePropertiesSuggestionState {
  /// Indicates if there was a suggested change to angle.
  core.bool? angleSuggested;

  /// Indicates if there was a suggested change to brightness.
  core.bool? brightnessSuggested;

  /// Indicates if there was a suggested change to content_uri.
  core.bool? contentUriSuggested;

  /// Indicates if there was a suggested change to contrast.
  core.bool? contrastSuggested;

  /// A mask that indicates which of the fields in crop_properties have been
  /// changed in this suggestion.
  CropPropertiesSuggestionState? cropPropertiesSuggestionState;

  /// Indicates if there was a suggested change to source_uri.
  core.bool? sourceUriSuggested;

  /// Indicates if there was a suggested change to transparency.
  core.bool? transparencySuggested;

  ImagePropertiesSuggestionState();

  ImagePropertiesSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('angleSuggested')) {
      angleSuggested = _json['angleSuggested'] as core.bool;
    }
    if (_json.containsKey('brightnessSuggested')) {
      brightnessSuggested = _json['brightnessSuggested'] as core.bool;
    }
    if (_json.containsKey('contentUriSuggested')) {
      contentUriSuggested = _json['contentUriSuggested'] as core.bool;
    }
    if (_json.containsKey('contrastSuggested')) {
      contrastSuggested = _json['contrastSuggested'] as core.bool;
    }
    if (_json.containsKey('cropPropertiesSuggestionState')) {
      cropPropertiesSuggestionState = CropPropertiesSuggestionState.fromJson(
          _json['cropPropertiesSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sourceUriSuggested')) {
      sourceUriSuggested = _json['sourceUriSuggested'] as core.bool;
    }
    if (_json.containsKey('transparencySuggested')) {
      transparencySuggested = _json['transparencySuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (angleSuggested != null) 'angleSuggested': angleSuggested!,
        if (brightnessSuggested != null)
          'brightnessSuggested': brightnessSuggested!,
        if (contentUriSuggested != null)
          'contentUriSuggested': contentUriSuggested!,
        if (contrastSuggested != null) 'contrastSuggested': contrastSuggested!,
        if (cropPropertiesSuggestionState != null)
          'cropPropertiesSuggestionState':
              cropPropertiesSuggestionState!.toJson(),
        if (sourceUriSuggested != null)
          'sourceUriSuggested': sourceUriSuggested!,
        if (transparencySuggested != null)
          'transparencySuggested': transparencySuggested!,
      };
}

/// An object that appears inline with text.
///
/// An InlineObject contains an EmbeddedObject such as an image.
class InlineObject {
  /// The properties of this inline object.
  InlineObjectProperties? inlineObjectProperties;

  /// The ID of this inline object.
  core.String? objectId;

  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested changes to the inline object properties, keyed by suggestion
  /// ID.
  core.Map<core.String, SuggestedInlineObjectProperties>?
      suggestedInlineObjectPropertiesChanges;

  /// The suggested insertion ID.
  ///
  /// If empty, then this is not a suggested insertion.
  core.String? suggestedInsertionId;

  InlineObject();

  InlineObject.fromJson(core.Map _json) {
    if (_json.containsKey('inlineObjectProperties')) {
      inlineObjectProperties = InlineObjectProperties.fromJson(
          _json['inlineObjectProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInlineObjectPropertiesChanges')) {
      suggestedInlineObjectPropertiesChanges =
          (_json['suggestedInlineObjectPropertiesChanges']
                  as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedInlineObjectProperties.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('suggestedInsertionId')) {
      suggestedInsertionId = _json['suggestedInsertionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inlineObjectProperties != null)
          'inlineObjectProperties': inlineObjectProperties!.toJson(),
        if (objectId != null) 'objectId': objectId!,
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInlineObjectPropertiesChanges != null)
          'suggestedInlineObjectPropertiesChanges':
              suggestedInlineObjectPropertiesChanges!
                  .map((key, item) => core.MapEntry(key, item.toJson())),
        if (suggestedInsertionId != null)
          'suggestedInsertionId': suggestedInsertionId!,
      };
}

/// A ParagraphElement that contains an InlineObject.
class InlineObjectElement {
  /// The ID of the InlineObject this element contains.
  core.String? inlineObjectId;

  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// An InlineObjectElement may have multiple insertion IDs if it is a nested
  /// suggested change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  /// The suggested text style changes to this InlineObject, keyed by suggestion
  /// ID.
  core.Map<core.String, SuggestedTextStyle>? suggestedTextStyleChanges;

  /// The text style of this InlineObjectElement.
  ///
  /// Similar to text content, like text runs and footnote references, the text
  /// style of an inline object element can affect content layout as well as the
  /// styling of text inserted adjacent to it.
  TextStyle? textStyle;

  InlineObjectElement();

  InlineObjectElement.fromJson(core.Map _json) {
    if (_json.containsKey('inlineObjectId')) {
      inlineObjectId = _json['inlineObjectId'] as core.String;
    }
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedTextStyleChanges')) {
      suggestedTextStyleChanges = (_json['suggestedTextStyleChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedTextStyle.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inlineObjectId != null) 'inlineObjectId': inlineObjectId!,
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
        if (suggestedTextStyleChanges != null)
          'suggestedTextStyleChanges': suggestedTextStyleChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
      };
}

/// Properties of an InlineObject.
class InlineObjectProperties {
  /// The embedded object of this inline object.
  EmbeddedObject? embeddedObject;

  InlineObjectProperties();

  InlineObjectProperties.fromJson(core.Map _json) {
    if (_json.containsKey('embeddedObject')) {
      embeddedObject = EmbeddedObject.fromJson(
          _json['embeddedObject'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (embeddedObject != null) 'embeddedObject': embeddedObject!.toJson(),
      };
}

/// A mask that indicates which of the fields on the base InlineObjectProperties
/// have been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class InlineObjectPropertiesSuggestionState {
  /// A mask that indicates which of the fields in embedded_object have been
  /// changed in this suggestion.
  EmbeddedObjectSuggestionState? embeddedObjectSuggestionState;

  InlineObjectPropertiesSuggestionState();

  InlineObjectPropertiesSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('embeddedObjectSuggestionState')) {
      embeddedObjectSuggestionState = EmbeddedObjectSuggestionState.fromJson(
          _json['embeddedObjectSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (embeddedObjectSuggestionState != null)
          'embeddedObjectSuggestionState':
              embeddedObjectSuggestionState!.toJson(),
      };
}

/// Inserts an InlineObject containing an image at the given location.
class InsertInlineImageRequest {
  /// Inserts the text at the end of a header, footer or the document body.
  ///
  /// Inline images cannot be inserted inside a footnote.
  EndOfSegmentLocation? endOfSegmentLocation;

  /// Inserts the image at a specific index in the document.
  ///
  /// The image must be inserted inside the bounds of an existing Paragraph. For
  /// instance, it cannot be inserted at a table's start index (i.e. between the
  /// table and its preceding paragraph). Inline images cannot be inserted
  /// inside a footnote or equation.
  Location? location;

  /// The size that the image should appear as in the document.
  ///
  /// This property is optional and the final size of the image in the document
  /// is determined by the following rules: * If neither width nor height is
  /// specified, then a default size of the image is calculated based on its
  /// resolution. * If one dimension is specified then the other dimension is
  /// calculated to preserve the aspect ratio of the image. * If both width and
  /// height are specified, the image is scaled to fit within the provided
  /// dimensions while maintaining its aspect ratio.
  Size? objectSize;

  /// The image URI.
  ///
  /// The image is fetched once at insertion time and a copy is stored for
  /// display inside the document. Images must be less than 50MB in size, cannot
  /// exceed 25 megapixels, and must be in one of PNG, JPEG, or GIF format. The
  /// provided URI can be at most 2 kB in length. The URI itself is saved with
  /// the image, and exposed via the ImageProperties.content_uri field.
  core.String? uri;

  InsertInlineImageRequest();

  InsertInlineImageRequest.fromJson(core.Map _json) {
    if (_json.containsKey('endOfSegmentLocation')) {
      endOfSegmentLocation = EndOfSegmentLocation.fromJson(
          _json['endOfSegmentLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('location')) {
      location = Location.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectSize')) {
      objectSize = Size.fromJson(
          _json['objectSize'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endOfSegmentLocation != null)
          'endOfSegmentLocation': endOfSegmentLocation!.toJson(),
        if (location != null) 'location': location!.toJson(),
        if (objectSize != null) 'objectSize': objectSize!.toJson(),
        if (uri != null) 'uri': uri!,
      };
}

/// The result of inserting an inline image.
class InsertInlineImageResponse {
  /// The ID of the created InlineObject.
  core.String? objectId;

  InsertInlineImageResponse();

  InsertInlineImageResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// The result of inserting an embedded Google Sheets chart.
class InsertInlineSheetsChartResponse {
  /// The object ID of the inserted chart.
  core.String? objectId;

  InsertInlineSheetsChartResponse();

  InsertInlineSheetsChartResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Inserts a page break followed by a newline at the specified location.
class InsertPageBreakRequest {
  /// Inserts the page break at the end of the document body.
  ///
  /// Page breaks cannot be inserted inside a footnote, header or footer. Since
  /// page breaks can only be inserted inside the body, the segment ID field
  /// must be empty.
  EndOfSegmentLocation? endOfSegmentLocation;

  /// Inserts the page break at a specific index in the document.
  ///
  /// The page break must be inserted inside the bounds of an existing
  /// Paragraph. For instance, it cannot be inserted at a table's start index
  /// (i.e. between the table and its preceding paragraph). Page breaks cannot
  /// be inserted inside a table, equation, footnote, header or footer. Since
  /// page breaks can only be inserted inside the body, the segment ID field
  /// must be empty.
  Location? location;

  InsertPageBreakRequest();

  InsertPageBreakRequest.fromJson(core.Map _json) {
    if (_json.containsKey('endOfSegmentLocation')) {
      endOfSegmentLocation = EndOfSegmentLocation.fromJson(
          _json['endOfSegmentLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('location')) {
      location = Location.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endOfSegmentLocation != null)
          'endOfSegmentLocation': endOfSegmentLocation!.toJson(),
        if (location != null) 'location': location!.toJson(),
      };
}

/// Inserts a section break at the given location.
///
/// A newline character will be inserted before the section break.
class InsertSectionBreakRequest {
  /// Inserts a newline and a section break at the end of the document body.
  ///
  /// Section breaks cannot be inserted inside a footnote, header or footer.
  /// Because section breaks can only be inserted inside the body, the segment
  /// ID field must be empty.
  EndOfSegmentLocation? endOfSegmentLocation;

  /// Inserts a newline and a section break at a specific index in the document.
  ///
  /// The section break must be inserted inside the bounds of an existing
  /// Paragraph. For instance, it cannot be inserted at a table's start index
  /// (i.e. between the table and its preceding paragraph). Section breaks
  /// cannot be inserted inside a table, equation, footnote, header, or footer.
  /// Since section breaks can only be inserted inside the body, the segment ID
  /// field must be empty.
  Location? location;

  /// The type of section to insert.
  /// Possible string values are:
  /// - "SECTION_TYPE_UNSPECIFIED" : The section type is unspecified.
  /// - "CONTINUOUS" : The section starts immediately after the last paragraph
  /// of the previous section.
  /// - "NEXT_PAGE" : The section starts on the next page.
  core.String? sectionType;

  InsertSectionBreakRequest();

  InsertSectionBreakRequest.fromJson(core.Map _json) {
    if (_json.containsKey('endOfSegmentLocation')) {
      endOfSegmentLocation = EndOfSegmentLocation.fromJson(
          _json['endOfSegmentLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('location')) {
      location = Location.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sectionType')) {
      sectionType = _json['sectionType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endOfSegmentLocation != null)
          'endOfSegmentLocation': endOfSegmentLocation!.toJson(),
        if (location != null) 'location': location!.toJson(),
        if (sectionType != null) 'sectionType': sectionType!,
      };
}

/// Inserts an empty column into a table.
class InsertTableColumnRequest {
  /// Whether to insert new column to the right of the reference cell location.
  ///
  /// - `True`: insert to the right. - `False`: insert to the left.
  core.bool? insertRight;

  /// The reference table cell location from which columns will be inserted.
  ///
  /// A new column will be inserted to the left (or right) of the column where
  /// the reference cell is. If the reference cell is a merged cell, a new
  /// column will be inserted to the left (or right) of the merged cell.
  TableCellLocation? tableCellLocation;

  InsertTableColumnRequest();

  InsertTableColumnRequest.fromJson(core.Map _json) {
    if (_json.containsKey('insertRight')) {
      insertRight = _json['insertRight'] as core.bool;
    }
    if (_json.containsKey('tableCellLocation')) {
      tableCellLocation = TableCellLocation.fromJson(
          _json['tableCellLocation'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (insertRight != null) 'insertRight': insertRight!,
        if (tableCellLocation != null)
          'tableCellLocation': tableCellLocation!.toJson(),
      };
}

/// Inserts a table at the specified location.
///
/// A newline character will be inserted before the inserted table.
class InsertTableRequest {
  /// The number of columns in the table.
  core.int? columns;

  /// Inserts the table at the end of the given header, footer or document body.
  ///
  /// A newline character will be inserted before the inserted table. Tables
  /// cannot be inserted inside a footnote.
  EndOfSegmentLocation? endOfSegmentLocation;

  /// Inserts the table at a specific model index.
  ///
  /// A newline character will be inserted before the inserted table, therefore
  /// the table start index will be at the specified location index + 1. The
  /// table must be inserted inside the bounds of an existing Paragraph. For
  /// instance, it cannot be inserted at a table's start index (i.e. between an
  /// existing table and its preceding paragraph). Tables cannot be inserted
  /// inside a footnote or equation.
  Location? location;

  /// The number of rows in the table.
  core.int? rows;

  InsertTableRequest();

  InsertTableRequest.fromJson(core.Map _json) {
    if (_json.containsKey('columns')) {
      columns = _json['columns'] as core.int;
    }
    if (_json.containsKey('endOfSegmentLocation')) {
      endOfSegmentLocation = EndOfSegmentLocation.fromJson(
          _json['endOfSegmentLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('location')) {
      location = Location.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rows')) {
      rows = _json['rows'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columns != null) 'columns': columns!,
        if (endOfSegmentLocation != null)
          'endOfSegmentLocation': endOfSegmentLocation!.toJson(),
        if (location != null) 'location': location!.toJson(),
        if (rows != null) 'rows': rows!,
      };
}

/// Inserts an empty row into a table.
class InsertTableRowRequest {
  /// Whether to insert new row below the reference cell location.
  ///
  /// - `True`: insert below the cell. - `False`: insert above the cell.
  core.bool? insertBelow;

  /// The reference table cell location from which rows will be inserted.
  ///
  /// A new row will be inserted above (or below) the row where the reference
  /// cell is. If the reference cell is a merged cell, a new row will be
  /// inserted above (or below) the merged cell.
  TableCellLocation? tableCellLocation;

  InsertTableRowRequest();

  InsertTableRowRequest.fromJson(core.Map _json) {
    if (_json.containsKey('insertBelow')) {
      insertBelow = _json['insertBelow'] as core.bool;
    }
    if (_json.containsKey('tableCellLocation')) {
      tableCellLocation = TableCellLocation.fromJson(
          _json['tableCellLocation'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (insertBelow != null) 'insertBelow': insertBelow!,
        if (tableCellLocation != null)
          'tableCellLocation': tableCellLocation!.toJson(),
      };
}

/// Inserts text at the specified location.
class InsertTextRequest {
  /// Inserts the text at the end of a header, footer, footnote or the document
  /// body.
  EndOfSegmentLocation? endOfSegmentLocation;

  /// Inserts the text at a specific index in the document.
  ///
  /// Text must be inserted inside the bounds of an existing Paragraph. For
  /// instance, text cannot be inserted at a table's start index (i.e. between
  /// the table and its preceding paragraph). The text must be inserted in the
  /// preceding paragraph.
  Location? location;

  /// The text to be inserted.
  ///
  /// Inserting a newline character will implicitly create a new Paragraph at
  /// that index. The paragraph style of the new paragraph will be copied from
  /// the paragraph at the current insertion index, including lists and bullets.
  /// Text styles for inserted text will be determined automatically, generally
  /// preserving the styling of neighboring text. In most cases, the text style
  /// for the inserted text will match the text immediately before the insertion
  /// index. Some control characters (U+0000-U+0008, U+000C-U+001F) and
  /// characters from the Unicode Basic Multilingual Plane Private Use Area
  /// (U+E000-U+F8FF) will be stripped out of the inserted text.
  core.String? text;

  InsertTextRequest();

  InsertTextRequest.fromJson(core.Map _json) {
    if (_json.containsKey('endOfSegmentLocation')) {
      endOfSegmentLocation = EndOfSegmentLocation.fromJson(
          _json['endOfSegmentLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('location')) {
      location = Location.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endOfSegmentLocation != null)
          'endOfSegmentLocation': endOfSegmentLocation!.toJson(),
        if (location != null) 'location': location!.toJson(),
        if (text != null) 'text': text!,
      };
}

/// A reference to another portion of a document or an external URL resource.
class Link {
  /// The ID of a bookmark in this document.
  core.String? bookmarkId;

  /// The ID of a heading in this document.
  core.String? headingId;

  /// An external URL.
  core.String? url;

  Link();

  Link.fromJson(core.Map _json) {
    if (_json.containsKey('bookmarkId')) {
      bookmarkId = _json['bookmarkId'] as core.String;
    }
    if (_json.containsKey('headingId')) {
      headingId = _json['headingId'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bookmarkId != null) 'bookmarkId': bookmarkId!,
        if (headingId != null) 'headingId': headingId!,
        if (url != null) 'url': url!,
      };
}

/// A reference to the external linked source content.
class LinkedContentReference {
  /// A reference to the linked chart.
  SheetsChartReference? sheetsChartReference;

  LinkedContentReference();

  LinkedContentReference.fromJson(core.Map _json) {
    if (_json.containsKey('sheetsChartReference')) {
      sheetsChartReference = SheetsChartReference.fromJson(
          _json['sheetsChartReference'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sheetsChartReference != null)
          'sheetsChartReference': sheetsChartReference!.toJson(),
      };
}

/// A mask that indicates which of the fields on the base LinkedContentReference
/// have been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class LinkedContentReferenceSuggestionState {
  /// A mask that indicates which of the fields in sheets_chart_reference have
  /// been changed in this suggestion.
  SheetsChartReferenceSuggestionState? sheetsChartReferenceSuggestionState;

  LinkedContentReferenceSuggestionState();

  LinkedContentReferenceSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('sheetsChartReferenceSuggestionState')) {
      sheetsChartReferenceSuggestionState =
          SheetsChartReferenceSuggestionState.fromJson(
              _json['sheetsChartReferenceSuggestionState']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sheetsChartReferenceSuggestionState != null)
          'sheetsChartReferenceSuggestionState':
              sheetsChartReferenceSuggestionState!.toJson(),
      };
}

/// A List represents the list attributes for a group of paragraphs that all
/// belong to the same list.
///
/// A paragraph that is part of a list has a reference to the list's ID in its
/// bullet.
class List {
  /// The properties of the list.
  ListProperties? listProperties;

  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this list.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion ID.
  ///
  /// If empty, then this is not a suggested insertion.
  core.String? suggestedInsertionId;

  /// The suggested changes to the list properties, keyed by suggestion ID.
  core.Map<core.String, SuggestedListProperties>?
      suggestedListPropertiesChanges;

  List();

  List.fromJson(core.Map _json) {
    if (_json.containsKey('listProperties')) {
      listProperties = ListProperties.fromJson(
          _json['listProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionId')) {
      suggestedInsertionId = _json['suggestedInsertionId'] as core.String;
    }
    if (_json.containsKey('suggestedListPropertiesChanges')) {
      suggestedListPropertiesChanges = (_json['suggestedListPropertiesChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedListProperties.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (listProperties != null) 'listProperties': listProperties!.toJson(),
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionId != null)
          'suggestedInsertionId': suggestedInsertionId!,
        if (suggestedListPropertiesChanges != null)
          'suggestedListPropertiesChanges': suggestedListPropertiesChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// The properties of a list which describe the look and feel of bullets
/// belonging to paragraphs associated with a list.
class ListProperties {
  /// Describes the properties of the bullets at the associated level.
  ///
  /// A list has at most nine levels of nesting with nesting level 0
  /// corresponding to the top-most level and nesting level 8 corresponding to
  /// the most nested level. The nesting levels are returned in ascending order
  /// with the least nested returned first.
  core.List<NestingLevel>? nestingLevels;

  ListProperties();

  ListProperties.fromJson(core.Map _json) {
    if (_json.containsKey('nestingLevels')) {
      nestingLevels = (_json['nestingLevels'] as core.List)
          .map<NestingLevel>((value) => NestingLevel.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nestingLevels != null)
          'nestingLevels':
              nestingLevels!.map((value) => value.toJson()).toList(),
      };
}

/// A mask that indicates which of the fields on the base ListProperties have
/// been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class ListPropertiesSuggestionState {
  /// A mask that indicates which of the fields on the corresponding
  /// NestingLevel in nesting_levels have been changed in this suggestion.
  ///
  /// The nesting level suggestion states are returned in ascending order of the
  /// nesting level with the least nested returned first.
  core.List<NestingLevelSuggestionState>? nestingLevelsSuggestionStates;

  ListPropertiesSuggestionState();

  ListPropertiesSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('nestingLevelsSuggestionStates')) {
      nestingLevelsSuggestionStates =
          (_json['nestingLevelsSuggestionStates'] as core.List)
              .map<NestingLevelSuggestionState>((value) =>
                  NestingLevelSuggestionState.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nestingLevelsSuggestionStates != null)
          'nestingLevelsSuggestionStates': nestingLevelsSuggestionStates!
              .map((value) => value.toJson())
              .toList(),
      };
}

/// A particular location in the document.
class Location {
  /// The zero-based index, in UTF-16 code units.
  ///
  /// The index is relative to the beginning of the segment specified by
  /// segment_id.
  core.int? index;

  /// The ID of the header, footer or footnote the location is in.
  ///
  /// An empty segment ID signifies the document's body.
  core.String? segmentId;

  Location();

  Location.fromJson(core.Map _json) {
    if (_json.containsKey('index')) {
      index = _json['index'] as core.int;
    }
    if (_json.containsKey('segmentId')) {
      segmentId = _json['segmentId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (index != null) 'index': index!,
        if (segmentId != null) 'segmentId': segmentId!,
      };
}

/// Merges cells in a Table.
class MergeTableCellsRequest {
  /// The table range specifying which cells of the table to merge.
  ///
  /// Any text in the cells being merged will be concatenated and stored in the
  /// "head" cell of the range. This is the upper-left cell of the range when
  /// the content direction is left to right, and the upper-right cell of the
  /// range otherwise. If the range is non-rectangular (which can occur in some
  /// cases where the range covers cells that are already merged or where the
  /// table is non-rectangular), a 400 bad request error is returned.
  TableRange? tableRange;

  MergeTableCellsRequest();

  MergeTableCellsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('tableRange')) {
      tableRange = TableRange.fromJson(
          _json['tableRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tableRange != null) 'tableRange': tableRange!.toJson(),
      };
}

/// A collection of Ranges with the same named range ID.
///
/// Named ranges allow developers to associate parts of a document with an
/// arbitrary user-defined label so their contents can be programmatically read
/// or edited at a later time. A document can contain multiple named ranges with
/// the same name, but every named range has a unique ID. A named range is
/// created with a single Range, and content inserted inside a named range
/// generally expands that range. However, certain document changes can cause
/// the range to be split into multiple ranges. Named ranges are not private.
/// All applications and collaborators that have access to the document can see
/// its named ranges.
class NamedRange {
  /// The name of the named range.
  core.String? name;

  /// The ID of the named range.
  core.String? namedRangeId;

  /// The ranges that belong to this named range.
  core.List<Range>? ranges;

  NamedRange();

  NamedRange.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('namedRangeId')) {
      namedRangeId = _json['namedRangeId'] as core.String;
    }
    if (_json.containsKey('ranges')) {
      ranges = (_json['ranges'] as core.List)
          .map<Range>((value) =>
              Range.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (namedRangeId != null) 'namedRangeId': namedRangeId!,
        if (ranges != null)
          'ranges': ranges!.map((value) => value.toJson()).toList(),
      };
}

/// A collection of all the NamedRanges in the document that share a given name.
class NamedRanges {
  /// The name that all the named ranges share.
  core.String? name;

  /// The NamedRanges that share the same name.
  core.List<NamedRange>? namedRanges;

  NamedRanges();

  NamedRanges.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('namedRanges')) {
      namedRanges = (_json['namedRanges'] as core.List)
          .map<NamedRange>((value) =>
              NamedRange.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (namedRanges != null)
          'namedRanges': namedRanges!.map((value) => value.toJson()).toList(),
      };
}

/// A named style.
///
/// Paragraphs in the document can inherit their TextStyle and ParagraphStyle
/// from this named style when they have the same named style type.
class NamedStyle {
  /// The type of this named style.
  /// Possible string values are:
  /// - "NAMED_STYLE_TYPE_UNSPECIFIED" : The type of named style is unspecified.
  /// - "NORMAL_TEXT" : Normal text.
  /// - "TITLE" : Title.
  /// - "SUBTITLE" : Subtitle.
  /// - "HEADING_1" : Heading 1.
  /// - "HEADING_2" : Heading 2.
  /// - "HEADING_3" : Heading 3.
  /// - "HEADING_4" : Heading 4.
  /// - "HEADING_5" : Heading 5.
  /// - "HEADING_6" : Heading 6.
  core.String? namedStyleType;

  /// The paragraph style of this named style.
  ParagraphStyle? paragraphStyle;

  /// The text style of this named style.
  TextStyle? textStyle;

  NamedStyle();

  NamedStyle.fromJson(core.Map _json) {
    if (_json.containsKey('namedStyleType')) {
      namedStyleType = _json['namedStyleType'] as core.String;
    }
    if (_json.containsKey('paragraphStyle')) {
      paragraphStyle = ParagraphStyle.fromJson(
          _json['paragraphStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (namedStyleType != null) 'namedStyleType': namedStyleType!,
        if (paragraphStyle != null) 'paragraphStyle': paragraphStyle!.toJson(),
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
      };
}

/// A suggestion state of a NamedStyle message.
class NamedStyleSuggestionState {
  /// The named style type that this suggestion state corresponds to.
  ///
  /// This field is provided as a convenience for matching the
  /// NamedStyleSuggestionState with its corresponding NamedStyle.
  /// Possible string values are:
  /// - "NAMED_STYLE_TYPE_UNSPECIFIED" : The type of named style is unspecified.
  /// - "NORMAL_TEXT" : Normal text.
  /// - "TITLE" : Title.
  /// - "SUBTITLE" : Subtitle.
  /// - "HEADING_1" : Heading 1.
  /// - "HEADING_2" : Heading 2.
  /// - "HEADING_3" : Heading 3.
  /// - "HEADING_4" : Heading 4.
  /// - "HEADING_5" : Heading 5.
  /// - "HEADING_6" : Heading 6.
  core.String? namedStyleType;

  /// A mask that indicates which of the fields in paragraph style have been
  /// changed in this suggestion.
  ParagraphStyleSuggestionState? paragraphStyleSuggestionState;

  /// A mask that indicates which of the fields in text style have been changed
  /// in this suggestion.
  TextStyleSuggestionState? textStyleSuggestionState;

  NamedStyleSuggestionState();

  NamedStyleSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('namedStyleType')) {
      namedStyleType = _json['namedStyleType'] as core.String;
    }
    if (_json.containsKey('paragraphStyleSuggestionState')) {
      paragraphStyleSuggestionState = ParagraphStyleSuggestionState.fromJson(
          _json['paragraphStyleSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textStyleSuggestionState')) {
      textStyleSuggestionState = TextStyleSuggestionState.fromJson(
          _json['textStyleSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (namedStyleType != null) 'namedStyleType': namedStyleType!,
        if (paragraphStyleSuggestionState != null)
          'paragraphStyleSuggestionState':
              paragraphStyleSuggestionState!.toJson(),
        if (textStyleSuggestionState != null)
          'textStyleSuggestionState': textStyleSuggestionState!.toJson(),
      };
}

/// The named styles.
///
/// Paragraphs in the document can inherit their TextStyle and ParagraphStyle
/// from these named styles.
class NamedStyles {
  /// The named styles.
  ///
  /// There is an entry for each of the possible named style types.
  core.List<NamedStyle>? styles;

  NamedStyles();

  NamedStyles.fromJson(core.Map _json) {
    if (_json.containsKey('styles')) {
      styles = (_json['styles'] as core.List)
          .map<NamedStyle>((value) =>
              NamedStyle.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (styles != null)
          'styles': styles!.map((value) => value.toJson()).toList(),
      };
}

/// The suggestion state of a NamedStyles message.
class NamedStylesSuggestionState {
  /// A mask that indicates which of the fields on the corresponding NamedStyle
  /// in styles have been changed in this suggestion.
  ///
  /// The order of these named style suggestion states match the order of the
  /// corresponding named style within the named styles suggestion.
  core.List<NamedStyleSuggestionState>? stylesSuggestionStates;

  NamedStylesSuggestionState();

  NamedStylesSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('stylesSuggestionStates')) {
      stylesSuggestionStates = (_json['stylesSuggestionStates'] as core.List)
          .map<NamedStyleSuggestionState>((value) =>
              NamedStyleSuggestionState.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (stylesSuggestionStates != null)
          'stylesSuggestionStates':
              stylesSuggestionStates!.map((value) => value.toJson()).toList(),
      };
}

/// Contains properties describing the look and feel of a list bullet at a given
/// level of nesting.
class NestingLevel {
  /// The alignment of the bullet within the space allotted for rendering the
  /// bullet.
  /// Possible string values are:
  /// - "BULLET_ALIGNMENT_UNSPECIFIED" : The bullet alignment is unspecified.
  /// - "START" : The bullet is aligned to the start of the space allotted for
  /// rendering the bullet. Left-aligned for LTR text, right-aligned otherwise.
  /// - "CENTER" : The bullet is aligned to the center of the space allotted for
  /// rendering the bullet.
  /// - "END" : The bullet is aligned to the end of the space allotted for
  /// rendering the bullet. Right-aligned for LTR text, left-aligned otherwise.
  core.String? bulletAlignment;

  /// The format string used by bullets at this level of nesting.
  ///
  /// The glyph format contains one or more placeholders, and these placeholder
  /// are replaced with the appropriate values depending on the glyph_type or
  /// glyph_symbol. The placeholders follow the pattern `%[nesting_level]`.
  /// Furthermore, placeholders can have prefixes and suffixes. Thus, the glyph
  /// format follows the pattern `%[nesting_level]`. Note that the prefix and
  /// suffix are optional and can be arbitrary strings. For example, the glyph
  /// format `%0.` indicates that the rendered glyph will replace the
  /// placeholder with the corresponding glyph for nesting level 0 followed by a
  /// period as the suffix. So a list with a glyph type of UPPER_ALPHA and glyph
  /// format `%0.` at nesting level 0 will result in a list with rendered glyphs
  /// `A.` `B.` `C.` The glyph format can contain placeholders for the current
  /// nesting level as well as placeholders for parent nesting levels. For
  /// example, a list can have a glyph format of `%0.` at nesting level 0 and a
  /// glyph format of `%0.%1.` at nesting level 1. Assuming both nesting levels
  /// have DECIMAL glyph types, this would result in a list with rendered glyphs
  /// `1.` `2.` ` 2.1.` ` 2.2.` `3.` For nesting levels that are ordered, the
  /// string that replaces a placeholder in the glyph format for a particular
  /// paragraph depends on the paragraph's order within the list.
  core.String? glyphFormat;

  /// A custom glyph symbol used by bullets when paragraphs at this level of
  /// nesting are unordered.
  ///
  /// The glyph symbol replaces placeholders within the glyph_format. For
  /// example, if the glyph_symbol is the solid circle corresponding to Unicode
  /// U+25cf code point and the glyph_format is `%0`, the rendered glyph would
  /// be the solid circle.
  core.String? glyphSymbol;

  /// The type of glyph used by bullets when paragraphs at this level of nesting
  /// are ordered.
  ///
  /// The glyph type determines the type of glyph used to replace placeholders
  /// within the glyph_format when paragraphs at this level of nesting are
  /// ordered. For example, if the nesting level is 0, the glyph_format is `%0.`
  /// and the glyph type is DECIMAL, then the rendered glyph would replace the
  /// placeholder `%0` in the glyph format with a number corresponding to list
  /// item's order within the list.
  /// Possible string values are:
  /// - "GLYPH_TYPE_UNSPECIFIED" : The glyph type is unspecified or unsupported.
  /// - "NONE" : An empty string.
  /// - "DECIMAL" : A number, like `1`, `2`, or `3`.
  /// - "ZERO_DECIMAL" : A number where single digit numbers are prefixed with a
  /// zero, like `01`, `02`, or `03`. Numbers with more than one digit are not
  /// prefixed with a zero.
  /// - "UPPER_ALPHA" : An uppercase letter, like `A`, `B`, or `C`.
  /// - "ALPHA" : A lowercase letter, like `a`, `b`, or `c`.
  /// - "UPPER_ROMAN" : An uppercase Roman numeral, like `I`, `II`, or `III`.
  /// - "ROMAN" : A lowercase Roman numeral, like `i`, `ii`, or `iii`.
  core.String? glyphType;

  /// The amount of indentation for the first line of paragraphs at this level
  /// of nesting.
  Dimension? indentFirstLine;

  /// The amount of indentation for paragraphs at this level of nesting.
  ///
  /// Applied to the side that corresponds to the start of the text, based on
  /// the paragraph's content direction.
  Dimension? indentStart;

  /// The number of the first list item at this nesting level.
  ///
  /// A value of 0 is treated as a value of 1 for lettered lists and roman
  /// numeraled lists, i.e. for values of both 0 and 1, lettered and roman
  /// numeraled lists will begin at `a` and `i` respectively. This value is
  /// ignored for nesting levels with unordered glyphs.
  core.int? startNumber;

  /// The text style of bullets at this level of nesting.
  TextStyle? textStyle;

  NestingLevel();

  NestingLevel.fromJson(core.Map _json) {
    if (_json.containsKey('bulletAlignment')) {
      bulletAlignment = _json['bulletAlignment'] as core.String;
    }
    if (_json.containsKey('glyphFormat')) {
      glyphFormat = _json['glyphFormat'] as core.String;
    }
    if (_json.containsKey('glyphSymbol')) {
      glyphSymbol = _json['glyphSymbol'] as core.String;
    }
    if (_json.containsKey('glyphType')) {
      glyphType = _json['glyphType'] as core.String;
    }
    if (_json.containsKey('indentFirstLine')) {
      indentFirstLine = Dimension.fromJson(
          _json['indentFirstLine'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('indentStart')) {
      indentStart = Dimension.fromJson(
          _json['indentStart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startNumber')) {
      startNumber = _json['startNumber'] as core.int;
    }
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bulletAlignment != null) 'bulletAlignment': bulletAlignment!,
        if (glyphFormat != null) 'glyphFormat': glyphFormat!,
        if (glyphSymbol != null) 'glyphSymbol': glyphSymbol!,
        if (glyphType != null) 'glyphType': glyphType!,
        if (indentFirstLine != null)
          'indentFirstLine': indentFirstLine!.toJson(),
        if (indentStart != null) 'indentStart': indentStart!.toJson(),
        if (startNumber != null) 'startNumber': startNumber!,
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
      };
}

/// A mask that indicates which of the fields on the base NestingLevel have been
/// changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class NestingLevelSuggestionState {
  /// Indicates if there was a suggested change to bullet_alignment.
  core.bool? bulletAlignmentSuggested;

  /// Indicates if there was a suggested change to glyph_format.
  core.bool? glyphFormatSuggested;

  /// Indicates if there was a suggested change to glyph_symbol.
  core.bool? glyphSymbolSuggested;

  /// Indicates if there was a suggested change to glyph_type.
  core.bool? glyphTypeSuggested;

  /// Indicates if there was a suggested change to indent_first_line.
  core.bool? indentFirstLineSuggested;

  /// Indicates if there was a suggested change to indent_start.
  core.bool? indentStartSuggested;

  /// Indicates if there was a suggested change to start_number.
  core.bool? startNumberSuggested;

  /// A mask that indicates which of the fields in text style have been changed
  /// in this suggestion.
  TextStyleSuggestionState? textStyleSuggestionState;

  NestingLevelSuggestionState();

  NestingLevelSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('bulletAlignmentSuggested')) {
      bulletAlignmentSuggested = _json['bulletAlignmentSuggested'] as core.bool;
    }
    if (_json.containsKey('glyphFormatSuggested')) {
      glyphFormatSuggested = _json['glyphFormatSuggested'] as core.bool;
    }
    if (_json.containsKey('glyphSymbolSuggested')) {
      glyphSymbolSuggested = _json['glyphSymbolSuggested'] as core.bool;
    }
    if (_json.containsKey('glyphTypeSuggested')) {
      glyphTypeSuggested = _json['glyphTypeSuggested'] as core.bool;
    }
    if (_json.containsKey('indentFirstLineSuggested')) {
      indentFirstLineSuggested = _json['indentFirstLineSuggested'] as core.bool;
    }
    if (_json.containsKey('indentStartSuggested')) {
      indentStartSuggested = _json['indentStartSuggested'] as core.bool;
    }
    if (_json.containsKey('startNumberSuggested')) {
      startNumberSuggested = _json['startNumberSuggested'] as core.bool;
    }
    if (_json.containsKey('textStyleSuggestionState')) {
      textStyleSuggestionState = TextStyleSuggestionState.fromJson(
          _json['textStyleSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bulletAlignmentSuggested != null)
          'bulletAlignmentSuggested': bulletAlignmentSuggested!,
        if (glyphFormatSuggested != null)
          'glyphFormatSuggested': glyphFormatSuggested!,
        if (glyphSymbolSuggested != null)
          'glyphSymbolSuggested': glyphSymbolSuggested!,
        if (glyphTypeSuggested != null)
          'glyphTypeSuggested': glyphTypeSuggested!,
        if (indentFirstLineSuggested != null)
          'indentFirstLineSuggested': indentFirstLineSuggested!,
        if (indentStartSuggested != null)
          'indentStartSuggested': indentStartSuggested!,
        if (startNumberSuggested != null)
          'startNumberSuggested': startNumberSuggested!,
        if (textStyleSuggestionState != null)
          'textStyleSuggestionState': textStyleSuggestionState!.toJson(),
      };
}

/// A collection of object IDs.
class ObjectReferences {
  /// The object IDs.
  core.List<core.String>? objectIds;

  ObjectReferences();

  ObjectReferences.fromJson(core.Map _json) {
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

/// A color that can either be fully opaque or fully transparent.
class OptionalColor {
  /// If set, this will be used as an opaque color.
  ///
  /// If unset, this represents a transparent color.
  Color? color;

  OptionalColor();

  OptionalColor.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color =
          Color.fromJson(_json['color'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
      };
}

/// A ParagraphElement representing a page break.
///
/// A page break makes the subsequent text start at the top of the next page.
class PageBreak {
  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// A PageBreak may have multiple insertion IDs if it is a nested suggested
  /// change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  /// The suggested text style changes to this PageBreak, keyed by suggestion
  /// ID.
  core.Map<core.String, SuggestedTextStyle>? suggestedTextStyleChanges;

  /// The text style of this PageBreak.
  ///
  /// Similar to text content, like text runs and footnote references, the text
  /// style of a page break can affect content layout as well as the styling of
  /// text inserted adjacent to it.
  TextStyle? textStyle;

  PageBreak();

  PageBreak.fromJson(core.Map _json) {
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedTextStyleChanges')) {
      suggestedTextStyleChanges = (_json['suggestedTextStyleChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedTextStyle.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
        if (suggestedTextStyleChanges != null)
          'suggestedTextStyleChanges': suggestedTextStyleChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
      };
}

/// A StructuralElement representing a paragraph.
///
/// A paragraph is a range of content that is terminated with a newline
/// character.
class Paragraph {
  /// The bullet for this paragraph.
  ///
  /// If not present, the paragraph does not belong to a list.
  Bullet? bullet;

  /// The content of the paragraph broken down into its component parts.
  core.List<ParagraphElement>? elements;

  /// The style of this paragraph.
  ParagraphStyle? paragraphStyle;

  /// The IDs of the positioned objects tethered to this paragraph.
  core.List<core.String>? positionedObjectIds;

  /// The suggested changes to this paragraph's bullet.
  core.Map<core.String, SuggestedBullet>? suggestedBulletChanges;

  /// The suggested paragraph style changes to this paragraph, keyed by
  /// suggestion ID.
  core.Map<core.String, SuggestedParagraphStyle>?
      suggestedParagraphStyleChanges;

  /// The IDs of the positioned objects that are suggested to be attached to
  /// this paragraph, keyed by suggestion ID.
  core.Map<core.String, ObjectReferences>? suggestedPositionedObjectIds;

  Paragraph();

  Paragraph.fromJson(core.Map _json) {
    if (_json.containsKey('bullet')) {
      bullet = Bullet.fromJson(
          _json['bullet'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('elements')) {
      elements = (_json['elements'] as core.List)
          .map<ParagraphElement>((value) => ParagraphElement.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('paragraphStyle')) {
      paragraphStyle = ParagraphStyle.fromJson(
          _json['paragraphStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('positionedObjectIds')) {
      positionedObjectIds = (_json['positionedObjectIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedBulletChanges')) {
      suggestedBulletChanges = (_json['suggestedBulletChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedBullet.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('suggestedParagraphStyleChanges')) {
      suggestedParagraphStyleChanges = (_json['suggestedParagraphStyleChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedParagraphStyle.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('suggestedPositionedObjectIds')) {
      suggestedPositionedObjectIds = (_json['suggestedPositionedObjectIds']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          ObjectReferences.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bullet != null) 'bullet': bullet!.toJson(),
        if (elements != null)
          'elements': elements!.map((value) => value.toJson()).toList(),
        if (paragraphStyle != null) 'paragraphStyle': paragraphStyle!.toJson(),
        if (positionedObjectIds != null)
          'positionedObjectIds': positionedObjectIds!,
        if (suggestedBulletChanges != null)
          'suggestedBulletChanges': suggestedBulletChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (suggestedParagraphStyleChanges != null)
          'suggestedParagraphStyleChanges': suggestedParagraphStyleChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (suggestedPositionedObjectIds != null)
          'suggestedPositionedObjectIds': suggestedPositionedObjectIds!
              .map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// A border around a paragraph.
class ParagraphBorder {
  /// The color of the border.
  OptionalColor? color;

  /// The dash style of the border.
  /// Possible string values are:
  /// - "DASH_STYLE_UNSPECIFIED" : Unspecified dash style.
  /// - "SOLID" : Solid line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'solid'. This is the default dash style.
  /// - "DOT" : Dotted line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'dot'.
  /// - "DASH" : Dashed line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'dash'.
  core.String? dashStyle;

  /// The padding of the border.
  Dimension? padding;

  /// The width of the border.
  Dimension? width;

  ParagraphBorder();

  ParagraphBorder.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color = OptionalColor.fromJson(
          _json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dashStyle')) {
      dashStyle = _json['dashStyle'] as core.String;
    }
    if (_json.containsKey('padding')) {
      padding = Dimension.fromJson(
          _json['padding'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('width')) {
      width = Dimension.fromJson(
          _json['width'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
        if (dashStyle != null) 'dashStyle': dashStyle!,
        if (padding != null) 'padding': padding!.toJson(),
        if (width != null) 'width': width!.toJson(),
      };
}

/// A ParagraphElement describes content within a Paragraph.
class ParagraphElement {
  /// An auto text paragraph element.
  AutoText? autoText;

  /// A column break paragraph element.
  ColumnBreak? columnBreak;

  /// The zero-base end index of this paragraph element, exclusive, in UTF-16
  /// code units.
  core.int? endIndex;

  /// An equation paragraph element.
  Equation? equation;

  /// A footnote reference paragraph element.
  FootnoteReference? footnoteReference;

  /// A horizontal rule paragraph element.
  HorizontalRule? horizontalRule;

  /// An inline object paragraph element.
  InlineObjectElement? inlineObjectElement;

  /// A page break paragraph element.
  PageBreak? pageBreak;

  /// A paragraph element that links to a person or email address.
  Person? person;

  /// The zero-based start index of this paragraph element, in UTF-16 code
  /// units.
  core.int? startIndex;

  /// A text run paragraph element.
  TextRun? textRun;

  ParagraphElement();

  ParagraphElement.fromJson(core.Map _json) {
    if (_json.containsKey('autoText')) {
      autoText = AutoText.fromJson(
          _json['autoText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('columnBreak')) {
      columnBreak = ColumnBreak.fromJson(
          _json['columnBreak'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('endIndex')) {
      endIndex = _json['endIndex'] as core.int;
    }
    if (_json.containsKey('equation')) {
      equation = Equation.fromJson(
          _json['equation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('footnoteReference')) {
      footnoteReference = FootnoteReference.fromJson(
          _json['footnoteReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('horizontalRule')) {
      horizontalRule = HorizontalRule.fromJson(
          _json['horizontalRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inlineObjectElement')) {
      inlineObjectElement = InlineObjectElement.fromJson(
          _json['inlineObjectElement'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pageBreak')) {
      pageBreak = PageBreak.fromJson(
          _json['pageBreak'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('person')) {
      person = Person.fromJson(
          _json['person'] as core.Map<core.String, core.dynamic>);
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
        if (columnBreak != null) 'columnBreak': columnBreak!.toJson(),
        if (endIndex != null) 'endIndex': endIndex!,
        if (equation != null) 'equation': equation!.toJson(),
        if (footnoteReference != null)
          'footnoteReference': footnoteReference!.toJson(),
        if (horizontalRule != null) 'horizontalRule': horizontalRule!.toJson(),
        if (inlineObjectElement != null)
          'inlineObjectElement': inlineObjectElement!.toJson(),
        if (pageBreak != null) 'pageBreak': pageBreak!.toJson(),
        if (person != null) 'person': person!.toJson(),
        if (startIndex != null) 'startIndex': startIndex!,
        if (textRun != null) 'textRun': textRun!.toJson(),
      };
}

/// Styles that apply to a whole paragraph.
///
/// Inherited paragraph styles are represented as unset fields in this message.
/// A paragraph style's parent depends on where the paragraph style is defined:
/// * The ParagraphStyle on a Paragraph inherits from the paragraph's
/// corresponding named style type. * The ParagraphStyle on a named style
/// inherits from the normal text named style. * The ParagraphStyle of the
/// normal text named style inherits from the default paragraph style in the
/// Docs editor. * The ParagraphStyle on a Paragraph element that is contained
/// in a table may inherit its paragraph style from the table style. If the
/// paragraph style does not inherit from a parent, unsetting fields will revert
/// the style to a value matching the defaults in the Docs editor.
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

  /// Whether to avoid widows and orphans for the paragraph.
  ///
  /// If unset, the value is inherited from the parent.
  core.bool? avoidWidowAndOrphan;

  /// The border between this paragraph and the next and previous paragraphs.
  ///
  /// If unset, the value is inherited from the parent. The between border is
  /// rendered when the adjacent paragraph has the same border and indent
  /// properties. Paragraph borders cannot be partially updated. When making
  /// changes to a paragraph border the new border must be specified in its
  /// entirety.
  ParagraphBorder? borderBetween;

  /// The border at the bottom of this paragraph.
  ///
  /// If unset, the value is inherited from the parent. The bottom border is
  /// rendered when the paragraph below has different border and indent
  /// properties. Paragraph borders cannot be partially updated. When making
  /// changes to a paragraph border the new border must be specified in its
  /// entirety.
  ParagraphBorder? borderBottom;

  /// The border to the left of this paragraph.
  ///
  /// If unset, the value is inherited from the parent. Paragraph borders cannot
  /// be partially updated. When making changes to a paragraph border the new
  /// border must be specified in its entirety.
  ParagraphBorder? borderLeft;

  /// The border to the right of this paragraph.
  ///
  /// If unset, the value is inherited from the parent. Paragraph borders cannot
  /// be partially updated. When making changes to a paragraph border the new
  /// border must be specified in its entirety.
  ParagraphBorder? borderRight;

  /// The border at the top of this paragraph.
  ///
  /// If unset, the value is inherited from the parent. The top border is
  /// rendered when the paragraph above has different border and indent
  /// properties. Paragraph borders cannot be partially updated. When making
  /// changes to a paragraph border the new border must be specified in its
  /// entirety.
  ParagraphBorder? borderTop;

  /// The text direction of this paragraph.
  ///
  /// If unset, the value defaults to LEFT_TO_RIGHT since paragraph direction is
  /// not inherited.
  /// Possible string values are:
  /// - "CONTENT_DIRECTION_UNSPECIFIED" : The content direction is unspecified.
  /// - "LEFT_TO_RIGHT" : The content goes from left to right.
  /// - "RIGHT_TO_LEFT" : The content goes from right to left.
  core.String? direction;

  /// The heading ID of the paragraph.
  ///
  /// If empty, then this paragraph is not a heading. This property is
  /// read-only.
  core.String? headingId;

  /// The amount of indentation for the paragraph on the side that corresponds
  /// to the end of the text, based on the current paragraph direction.
  ///
  /// If unset, the value is inherited from the parent.
  Dimension? indentEnd;

  /// The amount of indentation for the first line of the paragraph.
  ///
  /// If unset, the value is inherited from the parent.
  Dimension? indentFirstLine;

  /// The amount of indentation for the paragraph on the side that corresponds
  /// to the start of the text, based on the current paragraph direction.
  ///
  /// If unset, the value is inherited from the parent.
  Dimension? indentStart;

  /// Whether all lines of the paragraph should be laid out on the same page or
  /// column if possible.
  ///
  /// If unset, the value is inherited from the parent.
  core.bool? keepLinesTogether;

  /// Whether at least a part of this paragraph should be laid out on the same
  /// page or column as the next paragraph if possible.
  ///
  /// If unset, the value is inherited from the parent.
  core.bool? keepWithNext;

  /// The amount of space between lines, as a percentage of normal, where normal
  /// is represented as 100.0.
  ///
  /// If unset, the value is inherited from the parent.
  core.double? lineSpacing;

  /// The named style type of the paragraph.
  ///
  /// Since updating the named style type affects other properties within
  /// ParagraphStyle, the named style type is applied before the other
  /// properties are updated.
  /// Possible string values are:
  /// - "NAMED_STYLE_TYPE_UNSPECIFIED" : The type of named style is unspecified.
  /// - "NORMAL_TEXT" : Normal text.
  /// - "TITLE" : Title.
  /// - "SUBTITLE" : Subtitle.
  /// - "HEADING_1" : Heading 1.
  /// - "HEADING_2" : Heading 2.
  /// - "HEADING_3" : Heading 3.
  /// - "HEADING_4" : Heading 4.
  /// - "HEADING_5" : Heading 5.
  /// - "HEADING_6" : Heading 6.
  core.String? namedStyleType;

  /// The shading of the paragraph.
  ///
  /// If unset, the value is inherited from the parent.
  Shading? shading;

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

  /// A list of the tab stops for this paragraph.
  ///
  /// The list of tab stops is not inherited. This property is read-only.
  core.List<TabStop>? tabStops;

  ParagraphStyle();

  ParagraphStyle.fromJson(core.Map _json) {
    if (_json.containsKey('alignment')) {
      alignment = _json['alignment'] as core.String;
    }
    if (_json.containsKey('avoidWidowAndOrphan')) {
      avoidWidowAndOrphan = _json['avoidWidowAndOrphan'] as core.bool;
    }
    if (_json.containsKey('borderBetween')) {
      borderBetween = ParagraphBorder.fromJson(
          _json['borderBetween'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('borderBottom')) {
      borderBottom = ParagraphBorder.fromJson(
          _json['borderBottom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('borderLeft')) {
      borderLeft = ParagraphBorder.fromJson(
          _json['borderLeft'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('borderRight')) {
      borderRight = ParagraphBorder.fromJson(
          _json['borderRight'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('borderTop')) {
      borderTop = ParagraphBorder.fromJson(
          _json['borderTop'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('direction')) {
      direction = _json['direction'] as core.String;
    }
    if (_json.containsKey('headingId')) {
      headingId = _json['headingId'] as core.String;
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
    if (_json.containsKey('keepLinesTogether')) {
      keepLinesTogether = _json['keepLinesTogether'] as core.bool;
    }
    if (_json.containsKey('keepWithNext')) {
      keepWithNext = _json['keepWithNext'] as core.bool;
    }
    if (_json.containsKey('lineSpacing')) {
      lineSpacing = (_json['lineSpacing'] as core.num).toDouble();
    }
    if (_json.containsKey('namedStyleType')) {
      namedStyleType = _json['namedStyleType'] as core.String;
    }
    if (_json.containsKey('shading')) {
      shading = Shading.fromJson(
          _json['shading'] as core.Map<core.String, core.dynamic>);
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
    if (_json.containsKey('tabStops')) {
      tabStops = (_json['tabStops'] as core.List)
          .map<TabStop>((value) =>
              TabStop.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alignment != null) 'alignment': alignment!,
        if (avoidWidowAndOrphan != null)
          'avoidWidowAndOrphan': avoidWidowAndOrphan!,
        if (borderBetween != null) 'borderBetween': borderBetween!.toJson(),
        if (borderBottom != null) 'borderBottom': borderBottom!.toJson(),
        if (borderLeft != null) 'borderLeft': borderLeft!.toJson(),
        if (borderRight != null) 'borderRight': borderRight!.toJson(),
        if (borderTop != null) 'borderTop': borderTop!.toJson(),
        if (direction != null) 'direction': direction!,
        if (headingId != null) 'headingId': headingId!,
        if (indentEnd != null) 'indentEnd': indentEnd!.toJson(),
        if (indentFirstLine != null)
          'indentFirstLine': indentFirstLine!.toJson(),
        if (indentStart != null) 'indentStart': indentStart!.toJson(),
        if (keepLinesTogether != null) 'keepLinesTogether': keepLinesTogether!,
        if (keepWithNext != null) 'keepWithNext': keepWithNext!,
        if (lineSpacing != null) 'lineSpacing': lineSpacing!,
        if (namedStyleType != null) 'namedStyleType': namedStyleType!,
        if (shading != null) 'shading': shading!.toJson(),
        if (spaceAbove != null) 'spaceAbove': spaceAbove!.toJson(),
        if (spaceBelow != null) 'spaceBelow': spaceBelow!.toJson(),
        if (spacingMode != null) 'spacingMode': spacingMode!,
        if (tabStops != null)
          'tabStops': tabStops!.map((value) => value.toJson()).toList(),
      };
}

/// A mask that indicates which of the fields on the base ParagraphStyle have
/// been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class ParagraphStyleSuggestionState {
  /// Indicates if there was a suggested change to alignment.
  core.bool? alignmentSuggested;

  /// Indicates if there was a suggested change to avoid_widow_and_orphan.
  core.bool? avoidWidowAndOrphanSuggested;

  /// Indicates if there was a suggested change to border_between.
  core.bool? borderBetweenSuggested;

  /// Indicates if there was a suggested change to border_bottom.
  core.bool? borderBottomSuggested;

  /// Indicates if there was a suggested change to border_left.
  core.bool? borderLeftSuggested;

  /// Indicates if there was a suggested change to border_right.
  core.bool? borderRightSuggested;

  /// Indicates if there was a suggested change to border_top.
  core.bool? borderTopSuggested;

  /// Indicates if there was a suggested change to direction.
  core.bool? directionSuggested;

  /// Indicates if there was a suggested change to heading_id.
  core.bool? headingIdSuggested;

  /// Indicates if there was a suggested change to indent_end.
  core.bool? indentEndSuggested;

  /// Indicates if there was a suggested change to indent_first_line.
  core.bool? indentFirstLineSuggested;

  /// Indicates if there was a suggested change to indent_start.
  core.bool? indentStartSuggested;

  /// Indicates if there was a suggested change to keep_lines_together.
  core.bool? keepLinesTogetherSuggested;

  /// Indicates if there was a suggested change to keep_with_next.
  core.bool? keepWithNextSuggested;

  /// Indicates if there was a suggested change to line_spacing.
  core.bool? lineSpacingSuggested;

  /// Indicates if there was a suggested change to named_style_type.
  core.bool? namedStyleTypeSuggested;

  /// A mask that indicates which of the fields in shading have been changed in
  /// this suggestion.
  ShadingSuggestionState? shadingSuggestionState;

  /// Indicates if there was a suggested change to space_above.
  core.bool? spaceAboveSuggested;

  /// Indicates if there was a suggested change to space_below.
  core.bool? spaceBelowSuggested;

  /// Indicates if there was a suggested change to spacing_mode.
  core.bool? spacingModeSuggested;

  ParagraphStyleSuggestionState();

  ParagraphStyleSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('alignmentSuggested')) {
      alignmentSuggested = _json['alignmentSuggested'] as core.bool;
    }
    if (_json.containsKey('avoidWidowAndOrphanSuggested')) {
      avoidWidowAndOrphanSuggested =
          _json['avoidWidowAndOrphanSuggested'] as core.bool;
    }
    if (_json.containsKey('borderBetweenSuggested')) {
      borderBetweenSuggested = _json['borderBetweenSuggested'] as core.bool;
    }
    if (_json.containsKey('borderBottomSuggested')) {
      borderBottomSuggested = _json['borderBottomSuggested'] as core.bool;
    }
    if (_json.containsKey('borderLeftSuggested')) {
      borderLeftSuggested = _json['borderLeftSuggested'] as core.bool;
    }
    if (_json.containsKey('borderRightSuggested')) {
      borderRightSuggested = _json['borderRightSuggested'] as core.bool;
    }
    if (_json.containsKey('borderTopSuggested')) {
      borderTopSuggested = _json['borderTopSuggested'] as core.bool;
    }
    if (_json.containsKey('directionSuggested')) {
      directionSuggested = _json['directionSuggested'] as core.bool;
    }
    if (_json.containsKey('headingIdSuggested')) {
      headingIdSuggested = _json['headingIdSuggested'] as core.bool;
    }
    if (_json.containsKey('indentEndSuggested')) {
      indentEndSuggested = _json['indentEndSuggested'] as core.bool;
    }
    if (_json.containsKey('indentFirstLineSuggested')) {
      indentFirstLineSuggested = _json['indentFirstLineSuggested'] as core.bool;
    }
    if (_json.containsKey('indentStartSuggested')) {
      indentStartSuggested = _json['indentStartSuggested'] as core.bool;
    }
    if (_json.containsKey('keepLinesTogetherSuggested')) {
      keepLinesTogetherSuggested =
          _json['keepLinesTogetherSuggested'] as core.bool;
    }
    if (_json.containsKey('keepWithNextSuggested')) {
      keepWithNextSuggested = _json['keepWithNextSuggested'] as core.bool;
    }
    if (_json.containsKey('lineSpacingSuggested')) {
      lineSpacingSuggested = _json['lineSpacingSuggested'] as core.bool;
    }
    if (_json.containsKey('namedStyleTypeSuggested')) {
      namedStyleTypeSuggested = _json['namedStyleTypeSuggested'] as core.bool;
    }
    if (_json.containsKey('shadingSuggestionState')) {
      shadingSuggestionState = ShadingSuggestionState.fromJson(
          _json['shadingSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spaceAboveSuggested')) {
      spaceAboveSuggested = _json['spaceAboveSuggested'] as core.bool;
    }
    if (_json.containsKey('spaceBelowSuggested')) {
      spaceBelowSuggested = _json['spaceBelowSuggested'] as core.bool;
    }
    if (_json.containsKey('spacingModeSuggested')) {
      spacingModeSuggested = _json['spacingModeSuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alignmentSuggested != null)
          'alignmentSuggested': alignmentSuggested!,
        if (avoidWidowAndOrphanSuggested != null)
          'avoidWidowAndOrphanSuggested': avoidWidowAndOrphanSuggested!,
        if (borderBetweenSuggested != null)
          'borderBetweenSuggested': borderBetweenSuggested!,
        if (borderBottomSuggested != null)
          'borderBottomSuggested': borderBottomSuggested!,
        if (borderLeftSuggested != null)
          'borderLeftSuggested': borderLeftSuggested!,
        if (borderRightSuggested != null)
          'borderRightSuggested': borderRightSuggested!,
        if (borderTopSuggested != null)
          'borderTopSuggested': borderTopSuggested!,
        if (directionSuggested != null)
          'directionSuggested': directionSuggested!,
        if (headingIdSuggested != null)
          'headingIdSuggested': headingIdSuggested!,
        if (indentEndSuggested != null)
          'indentEndSuggested': indentEndSuggested!,
        if (indentFirstLineSuggested != null)
          'indentFirstLineSuggested': indentFirstLineSuggested!,
        if (indentStartSuggested != null)
          'indentStartSuggested': indentStartSuggested!,
        if (keepLinesTogetherSuggested != null)
          'keepLinesTogetherSuggested': keepLinesTogetherSuggested!,
        if (keepWithNextSuggested != null)
          'keepWithNextSuggested': keepWithNextSuggested!,
        if (lineSpacingSuggested != null)
          'lineSpacingSuggested': lineSpacingSuggested!,
        if (namedStyleTypeSuggested != null)
          'namedStyleTypeSuggested': namedStyleTypeSuggested!,
        if (shadingSuggestionState != null)
          'shadingSuggestionState': shadingSuggestionState!.toJson(),
        if (spaceAboveSuggested != null)
          'spaceAboveSuggested': spaceAboveSuggested!,
        if (spaceBelowSuggested != null)
          'spaceBelowSuggested': spaceBelowSuggested!,
        if (spacingModeSuggested != null)
          'spacingModeSuggested': spacingModeSuggested!,
      };
}

/// A person or email address mentioned in a document.
///
/// These mentions behave as a single, immutable element containing the person's
/// name or email address.
class Person {
  /// The unique ID of this link.
  ///
  /// Output only.
  core.String? personId;

  /// The properties of this Person.
  ///
  /// This field is always present.
  ///
  /// Output only.
  PersonProperties? personProperties;

  /// IDs for suggestions that remove this person link from the document.
  ///
  /// A Person might have multiple deletion IDs if, for example, multiple users
  /// suggest to delete it. If empty, then this person link isn't suggested for
  /// deletion.
  core.List<core.String>? suggestedDeletionIds;

  /// IDs for suggestions that insert this person link into the document.
  ///
  /// A Person might have multiple insertion IDs if it is a nested suggested
  /// change (a suggestion within a suggestion made by a different user, for
  /// example). If empty, then this person link isn't a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  /// The suggested text style changes to this Person, keyed by suggestion ID.
  core.Map<core.String, SuggestedTextStyle>? suggestedTextStyleChanges;

  /// The text style of this Person.
  TextStyle? textStyle;

  Person();

  Person.fromJson(core.Map _json) {
    if (_json.containsKey('personId')) {
      personId = _json['personId'] as core.String;
    }
    if (_json.containsKey('personProperties')) {
      personProperties = PersonProperties.fromJson(
          _json['personProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedTextStyleChanges')) {
      suggestedTextStyleChanges = (_json['suggestedTextStyleChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedTextStyle.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (personId != null) 'personId': personId!,
        if (personProperties != null)
          'personProperties': personProperties!.toJson(),
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
        if (suggestedTextStyleChanges != null)
          'suggestedTextStyleChanges': suggestedTextStyleChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
      };
}

/// Properties specific to a linked Person.
class PersonProperties {
  /// The email address linked to this Person.
  ///
  /// This field is always present.
  ///
  /// Output only.
  core.String? email;

  /// The name of the person if it is displayed in the link text instead of the
  /// person's email address.
  ///
  /// Output only.
  core.String? name;

  PersonProperties();

  PersonProperties.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (name != null) 'name': name!,
      };
}

/// An object that is tethered to a Paragraph and positioned relative to the
/// beginning of the paragraph.
///
/// A PositionedObject contains an EmbeddedObject such as an image.
class PositionedObject {
  /// The ID of this positioned object.
  core.String? objectId;

  /// The properties of this positioned object.
  PositionedObjectProperties? positionedObjectProperties;

  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion ID.
  ///
  /// If empty, then this is not a suggested insertion.
  core.String? suggestedInsertionId;

  /// The suggested changes to the positioned object properties, keyed by
  /// suggestion ID.
  core.Map<core.String, SuggestedPositionedObjectProperties>?
      suggestedPositionedObjectPropertiesChanges;

  PositionedObject();

  PositionedObject.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.String;
    }
    if (_json.containsKey('positionedObjectProperties')) {
      positionedObjectProperties = PositionedObjectProperties.fromJson(
          _json['positionedObjectProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionId')) {
      suggestedInsertionId = _json['suggestedInsertionId'] as core.String;
    }
    if (_json.containsKey('suggestedPositionedObjectPropertiesChanges')) {
      suggestedPositionedObjectPropertiesChanges =
          (_json['suggestedPositionedObjectPropertiesChanges']
                  as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedPositionedObjectProperties.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
        if (positionedObjectProperties != null)
          'positionedObjectProperties': positionedObjectProperties!.toJson(),
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionId != null)
          'suggestedInsertionId': suggestedInsertionId!,
        if (suggestedPositionedObjectPropertiesChanges != null)
          'suggestedPositionedObjectPropertiesChanges':
              suggestedPositionedObjectPropertiesChanges!
                  .map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// The positioning of a PositionedObject.
///
/// The positioned object is positioned relative to the beginning of the
/// Paragraph it is tethered to.
class PositionedObjectPositioning {
  /// The layout of this positioned object.
  /// Possible string values are:
  /// - "POSITIONED_OBJECT_LAYOUT_UNSPECIFIED" : The layout is unspecified.
  /// - "WRAP_TEXT" : The text wraps around the positioned object.
  /// - "BREAK_LEFT" : Breaks text such that the positioned object is on the
  /// left and text is on the right.
  /// - "BREAK_RIGHT" : Breaks text such that the positioned object is on the
  /// right and text is on the left.
  /// - "BREAK_LEFT_RIGHT" : Breaks text such that there is no text on the left
  /// or right of the positioned object.
  /// - "IN_FRONT_OF_TEXT" : The positioned object is in front of the text.
  core.String? layout;

  /// The offset of the left edge of the positioned object relative to the
  /// beginning of the Paragraph it is tethered to.
  ///
  /// The exact positioning of the object can depend on other content in the
  /// document and the document's styling.
  Dimension? leftOffset;

  /// The offset of the top edge of the positioned object relative to the
  /// beginning of the Paragraph it is tethered to.
  ///
  /// The exact positioning of the object can depend on other content in the
  /// document and the document's styling.
  Dimension? topOffset;

  PositionedObjectPositioning();

  PositionedObjectPositioning.fromJson(core.Map _json) {
    if (_json.containsKey('layout')) {
      layout = _json['layout'] as core.String;
    }
    if (_json.containsKey('leftOffset')) {
      leftOffset = Dimension.fromJson(
          _json['leftOffset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('topOffset')) {
      topOffset = Dimension.fromJson(
          _json['topOffset'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (layout != null) 'layout': layout!,
        if (leftOffset != null) 'leftOffset': leftOffset!.toJson(),
        if (topOffset != null) 'topOffset': topOffset!.toJson(),
      };
}

/// A mask that indicates which of the fields on the base
/// PositionedObjectPositioning have been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class PositionedObjectPositioningSuggestionState {
  /// Indicates if there was a suggested change to layout.
  core.bool? layoutSuggested;

  /// Indicates if there was a suggested change to left_offset.
  core.bool? leftOffsetSuggested;

  /// Indicates if there was a suggested change to top_offset.
  core.bool? topOffsetSuggested;

  PositionedObjectPositioningSuggestionState();

  PositionedObjectPositioningSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('layoutSuggested')) {
      layoutSuggested = _json['layoutSuggested'] as core.bool;
    }
    if (_json.containsKey('leftOffsetSuggested')) {
      leftOffsetSuggested = _json['leftOffsetSuggested'] as core.bool;
    }
    if (_json.containsKey('topOffsetSuggested')) {
      topOffsetSuggested = _json['topOffsetSuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (layoutSuggested != null) 'layoutSuggested': layoutSuggested!,
        if (leftOffsetSuggested != null)
          'leftOffsetSuggested': leftOffsetSuggested!,
        if (topOffsetSuggested != null)
          'topOffsetSuggested': topOffsetSuggested!,
      };
}

/// Properties of a PositionedObject.
class PositionedObjectProperties {
  /// The embedded object of this positioned object.
  EmbeddedObject? embeddedObject;

  /// The positioning of this positioned object relative to the newline of the
  /// Paragraph that references this positioned object.
  PositionedObjectPositioning? positioning;

  PositionedObjectProperties();

  PositionedObjectProperties.fromJson(core.Map _json) {
    if (_json.containsKey('embeddedObject')) {
      embeddedObject = EmbeddedObject.fromJson(
          _json['embeddedObject'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('positioning')) {
      positioning = PositionedObjectPositioning.fromJson(
          _json['positioning'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (embeddedObject != null) 'embeddedObject': embeddedObject!.toJson(),
        if (positioning != null) 'positioning': positioning!.toJson(),
      };
}

/// A mask that indicates which of the fields on the base
/// PositionedObjectProperties have been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class PositionedObjectPropertiesSuggestionState {
  /// A mask that indicates which of the fields in embedded_object have been
  /// changed in this suggestion.
  EmbeddedObjectSuggestionState? embeddedObjectSuggestionState;

  /// A mask that indicates which of the fields in positioning have been changed
  /// in this suggestion.
  PositionedObjectPositioningSuggestionState? positioningSuggestionState;

  PositionedObjectPropertiesSuggestionState();

  PositionedObjectPropertiesSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('embeddedObjectSuggestionState')) {
      embeddedObjectSuggestionState = EmbeddedObjectSuggestionState.fromJson(
          _json['embeddedObjectSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('positioningSuggestionState')) {
      positioningSuggestionState =
          PositionedObjectPositioningSuggestionState.fromJson(
              _json['positioningSuggestionState']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (embeddedObjectSuggestionState != null)
          'embeddedObjectSuggestionState':
              embeddedObjectSuggestionState!.toJson(),
        if (positioningSuggestionState != null)
          'positioningSuggestionState': positioningSuggestionState!.toJson(),
      };
}

/// Specifies a contiguous range of text.
class Range {
  /// The zero-based end index of this range, exclusive, in UTF-16 code units.
  ///
  /// In all current uses, an end index must be provided. This field is an
  /// Int32Value in order to accommodate future use cases with open-ended
  /// ranges.
  core.int? endIndex;

  /// The ID of the header, footer or footnote that this range is contained in.
  ///
  /// An empty segment ID signifies the document's body.
  core.String? segmentId;

  /// The zero-based start index of this range, in UTF-16 code units.
  ///
  /// In all current uses, a start index must be provided. This field is an
  /// Int32Value in order to accommodate future use cases with open-ended
  /// ranges.
  core.int? startIndex;

  Range();

  Range.fromJson(core.Map _json) {
    if (_json.containsKey('endIndex')) {
      endIndex = _json['endIndex'] as core.int;
    }
    if (_json.containsKey('segmentId')) {
      segmentId = _json['segmentId'] as core.String;
    }
    if (_json.containsKey('startIndex')) {
      startIndex = _json['startIndex'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endIndex != null) 'endIndex': endIndex!,
        if (segmentId != null) 'segmentId': segmentId!,
        if (startIndex != null) 'startIndex': startIndex!,
      };
}

/// Replaces all instances of text matching a criteria with replace text.
class ReplaceAllTextRequest {
  /// Finds text in the document matching this substring.
  SubstringMatchCriteria? containsText;

  /// The text that will replace the matched text.
  core.String? replaceText;

  ReplaceAllTextRequest();

  ReplaceAllTextRequest.fromJson(core.Map _json) {
    if (_json.containsKey('containsText')) {
      containsText = SubstringMatchCriteria.fromJson(
          _json['containsText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replaceText')) {
      replaceText = _json['replaceText'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (containsText != null) 'containsText': containsText!.toJson(),
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
/// Replacing an image removes some image effects from the existing image in
/// order to mirror the behavior of the Docs editor.
class ReplaceImageRequest {
  /// The ID of the existing image that will be replaced.
  core.String? imageObjectId;

  /// The replacement method.
  /// Possible string values are:
  /// - "IMAGE_REPLACE_METHOD_UNSPECIFIED" : Unspecified image replace method.
  /// This value must not be used.
  /// - "CENTER_CROP" : Scales and centers the image to fill the bounds of the
  /// original image. The image may be cropped in order to fill the original
  /// image's bounds. The rendered size of the image will be the same as that of
  /// the original image.
  core.String? imageReplaceMethod;

  /// The URI of the new image.
  ///
  /// The image is fetched once at insertion time and a copy is stored for
  /// display inside the document. Images must be less than 50MB in size, cannot
  /// exceed 25 megapixels, and must be in one of PNG, JPEG, or GIF format. The
  /// provided URI can be at most 2 kB in length. The URI itself is saved with
  /// the image, and exposed via the ImageProperties.source_uri field.
  core.String? uri;

  ReplaceImageRequest();

  ReplaceImageRequest.fromJson(core.Map _json) {
    if (_json.containsKey('imageObjectId')) {
      imageObjectId = _json['imageObjectId'] as core.String;
    }
    if (_json.containsKey('imageReplaceMethod')) {
      imageReplaceMethod = _json['imageReplaceMethod'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (imageObjectId != null) 'imageObjectId': imageObjectId!,
        if (imageReplaceMethod != null)
          'imageReplaceMethod': imageReplaceMethod!,
        if (uri != null) 'uri': uri!,
      };
}

/// Replaces the contents of the specified NamedRange or NamedRanges with the
/// given replacement content.
///
/// Note that an individual NamedRange may consist of multiple discontinuous
/// ranges. In this case, only the content in the first range will be replaced.
/// The other ranges and their content will be deleted. In cases where replacing
/// or deleting any ranges would result in an invalid document structure, a 400
/// bad request error is returned.
class ReplaceNamedRangeContentRequest {
  /// The ID of the named range whose content will be replaced.
  ///
  /// If there is no named range with the given ID a 400 bad request error is
  /// returned.
  core.String? namedRangeId;

  /// The name of the NamedRanges whose content will be replaced.
  ///
  /// If there are multiple named ranges with the given name, then the content
  /// of each one will be replaced. If there are no named ranges with the given
  /// name, then the request will be a no-op.
  core.String? namedRangeName;

  /// Replaces the content of the specified named range(s) with the given text.
  core.String? text;

  ReplaceNamedRangeContentRequest();

  ReplaceNamedRangeContentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('namedRangeId')) {
      namedRangeId = _json['namedRangeId'] as core.String;
    }
    if (_json.containsKey('namedRangeName')) {
      namedRangeName = _json['namedRangeName'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (namedRangeId != null) 'namedRangeId': namedRangeId!,
        if (namedRangeName != null) 'namedRangeName': namedRangeName!,
        if (text != null) 'text': text!,
      };
}

/// A single update to apply to a document.
class Request {
  /// Creates a footer.
  CreateFooterRequest? createFooter;

  /// Creates a footnote.
  CreateFootnoteRequest? createFootnote;

  /// Creates a header.
  CreateHeaderRequest? createHeader;

  /// Creates a named range.
  CreateNamedRangeRequest? createNamedRange;

  /// Creates bullets for paragraphs.
  CreateParagraphBulletsRequest? createParagraphBullets;

  /// Deletes content from the document.
  DeleteContentRangeRequest? deleteContentRange;

  /// Deletes a footer from the document.
  DeleteFooterRequest? deleteFooter;

  /// Deletes a header from the document.
  DeleteHeaderRequest? deleteHeader;

  /// Deletes a named range.
  DeleteNamedRangeRequest? deleteNamedRange;

  /// Deletes bullets from paragraphs.
  DeleteParagraphBulletsRequest? deleteParagraphBullets;

  /// Deletes a positioned object from the document.
  DeletePositionedObjectRequest? deletePositionedObject;

  /// Deletes a column from a table.
  DeleteTableColumnRequest? deleteTableColumn;

  /// Deletes a row from a table.
  DeleteTableRowRequest? deleteTableRow;

  /// Inserts an inline image at the specified location.
  InsertInlineImageRequest? insertInlineImage;

  /// Inserts a page break at the specified location.
  InsertPageBreakRequest? insertPageBreak;

  /// Inserts a section break at the specified location.
  InsertSectionBreakRequest? insertSectionBreak;

  /// Inserts a table at the specified location.
  InsertTableRequest? insertTable;

  /// Inserts an empty column into a table.
  InsertTableColumnRequest? insertTableColumn;

  /// Inserts an empty row into a table.
  InsertTableRowRequest? insertTableRow;

  /// Inserts text at the specified location.
  InsertTextRequest? insertText;

  /// Merges cells in a table.
  MergeTableCellsRequest? mergeTableCells;

  /// Replaces all instances of the specified text.
  ReplaceAllTextRequest? replaceAllText;

  /// Replaces an image in the document.
  ReplaceImageRequest? replaceImage;

  /// Replaces the content in a named range.
  ReplaceNamedRangeContentRequest? replaceNamedRangeContent;

  /// Unmerges cells in a table.
  UnmergeTableCellsRequest? unmergeTableCells;

  /// Updates the style of the document.
  UpdateDocumentStyleRequest? updateDocumentStyle;

  /// Updates the paragraph style at the specified range.
  UpdateParagraphStyleRequest? updateParagraphStyle;

  /// Updates the section style of the specified range.
  UpdateSectionStyleRequest? updateSectionStyle;

  /// Updates the style of table cells.
  UpdateTableCellStyleRequest? updateTableCellStyle;

  /// Updates the properties of columns in a table.
  UpdateTableColumnPropertiesRequest? updateTableColumnProperties;

  /// Updates the row style in a table.
  UpdateTableRowStyleRequest? updateTableRowStyle;

  /// Updates the text style at the specified range.
  UpdateTextStyleRequest? updateTextStyle;

  Request();

  Request.fromJson(core.Map _json) {
    if (_json.containsKey('createFooter')) {
      createFooter = CreateFooterRequest.fromJson(
          _json['createFooter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createFootnote')) {
      createFootnote = CreateFootnoteRequest.fromJson(
          _json['createFootnote'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createHeader')) {
      createHeader = CreateHeaderRequest.fromJson(
          _json['createHeader'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createNamedRange')) {
      createNamedRange = CreateNamedRangeRequest.fromJson(
          _json['createNamedRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createParagraphBullets')) {
      createParagraphBullets = CreateParagraphBulletsRequest.fromJson(
          _json['createParagraphBullets']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteContentRange')) {
      deleteContentRange = DeleteContentRangeRequest.fromJson(
          _json['deleteContentRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteFooter')) {
      deleteFooter = DeleteFooterRequest.fromJson(
          _json['deleteFooter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteHeader')) {
      deleteHeader = DeleteHeaderRequest.fromJson(
          _json['deleteHeader'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteNamedRange')) {
      deleteNamedRange = DeleteNamedRangeRequest.fromJson(
          _json['deleteNamedRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteParagraphBullets')) {
      deleteParagraphBullets = DeleteParagraphBulletsRequest.fromJson(
          _json['deleteParagraphBullets']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deletePositionedObject')) {
      deletePositionedObject = DeletePositionedObjectRequest.fromJson(
          _json['deletePositionedObject']
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
    if (_json.containsKey('insertInlineImage')) {
      insertInlineImage = InsertInlineImageRequest.fromJson(
          _json['insertInlineImage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertPageBreak')) {
      insertPageBreak = InsertPageBreakRequest.fromJson(
          _json['insertPageBreak'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertSectionBreak')) {
      insertSectionBreak = InsertSectionBreakRequest.fromJson(
          _json['insertSectionBreak'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertTable')) {
      insertTable = InsertTableRequest.fromJson(
          _json['insertTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertTableColumn')) {
      insertTableColumn = InsertTableColumnRequest.fromJson(
          _json['insertTableColumn'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertTableRow')) {
      insertTableRow = InsertTableRowRequest.fromJson(
          _json['insertTableRow'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertText')) {
      insertText = InsertTextRequest.fromJson(
          _json['insertText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mergeTableCells')) {
      mergeTableCells = MergeTableCellsRequest.fromJson(
          _json['mergeTableCells'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replaceAllText')) {
      replaceAllText = ReplaceAllTextRequest.fromJson(
          _json['replaceAllText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replaceImage')) {
      replaceImage = ReplaceImageRequest.fromJson(
          _json['replaceImage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replaceNamedRangeContent')) {
      replaceNamedRangeContent = ReplaceNamedRangeContentRequest.fromJson(
          _json['replaceNamedRangeContent']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unmergeTableCells')) {
      unmergeTableCells = UnmergeTableCellsRequest.fromJson(
          _json['unmergeTableCells'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateDocumentStyle')) {
      updateDocumentStyle = UpdateDocumentStyleRequest.fromJson(
          _json['updateDocumentStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateParagraphStyle')) {
      updateParagraphStyle = UpdateParagraphStyleRequest.fromJson(
          _json['updateParagraphStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateSectionStyle')) {
      updateSectionStyle = UpdateSectionStyleRequest.fromJson(
          _json['updateSectionStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTableCellStyle')) {
      updateTableCellStyle = UpdateTableCellStyleRequest.fromJson(
          _json['updateTableCellStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTableColumnProperties')) {
      updateTableColumnProperties = UpdateTableColumnPropertiesRequest.fromJson(
          _json['updateTableColumnProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTableRowStyle')) {
      updateTableRowStyle = UpdateTableRowStyleRequest.fromJson(
          _json['updateTableRowStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTextStyle')) {
      updateTextStyle = UpdateTextStyleRequest.fromJson(
          _json['updateTextStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createFooter != null) 'createFooter': createFooter!.toJson(),
        if (createFootnote != null) 'createFootnote': createFootnote!.toJson(),
        if (createHeader != null) 'createHeader': createHeader!.toJson(),
        if (createNamedRange != null)
          'createNamedRange': createNamedRange!.toJson(),
        if (createParagraphBullets != null)
          'createParagraphBullets': createParagraphBullets!.toJson(),
        if (deleteContentRange != null)
          'deleteContentRange': deleteContentRange!.toJson(),
        if (deleteFooter != null) 'deleteFooter': deleteFooter!.toJson(),
        if (deleteHeader != null) 'deleteHeader': deleteHeader!.toJson(),
        if (deleteNamedRange != null)
          'deleteNamedRange': deleteNamedRange!.toJson(),
        if (deleteParagraphBullets != null)
          'deleteParagraphBullets': deleteParagraphBullets!.toJson(),
        if (deletePositionedObject != null)
          'deletePositionedObject': deletePositionedObject!.toJson(),
        if (deleteTableColumn != null)
          'deleteTableColumn': deleteTableColumn!.toJson(),
        if (deleteTableRow != null) 'deleteTableRow': deleteTableRow!.toJson(),
        if (insertInlineImage != null)
          'insertInlineImage': insertInlineImage!.toJson(),
        if (insertPageBreak != null)
          'insertPageBreak': insertPageBreak!.toJson(),
        if (insertSectionBreak != null)
          'insertSectionBreak': insertSectionBreak!.toJson(),
        if (insertTable != null) 'insertTable': insertTable!.toJson(),
        if (insertTableColumn != null)
          'insertTableColumn': insertTableColumn!.toJson(),
        if (insertTableRow != null) 'insertTableRow': insertTableRow!.toJson(),
        if (insertText != null) 'insertText': insertText!.toJson(),
        if (mergeTableCells != null)
          'mergeTableCells': mergeTableCells!.toJson(),
        if (replaceAllText != null) 'replaceAllText': replaceAllText!.toJson(),
        if (replaceImage != null) 'replaceImage': replaceImage!.toJson(),
        if (replaceNamedRangeContent != null)
          'replaceNamedRangeContent': replaceNamedRangeContent!.toJson(),
        if (unmergeTableCells != null)
          'unmergeTableCells': unmergeTableCells!.toJson(),
        if (updateDocumentStyle != null)
          'updateDocumentStyle': updateDocumentStyle!.toJson(),
        if (updateParagraphStyle != null)
          'updateParagraphStyle': updateParagraphStyle!.toJson(),
        if (updateSectionStyle != null)
          'updateSectionStyle': updateSectionStyle!.toJson(),
        if (updateTableCellStyle != null)
          'updateTableCellStyle': updateTableCellStyle!.toJson(),
        if (updateTableColumnProperties != null)
          'updateTableColumnProperties': updateTableColumnProperties!.toJson(),
        if (updateTableRowStyle != null)
          'updateTableRowStyle': updateTableRowStyle!.toJson(),
        if (updateTextStyle != null)
          'updateTextStyle': updateTextStyle!.toJson(),
      };
}

/// A single response from an update.
class Response {
  /// The result of creating a footer.
  CreateFooterResponse? createFooter;

  /// The result of creating a footnote.
  CreateFootnoteResponse? createFootnote;

  /// The result of creating a header.
  CreateHeaderResponse? createHeader;

  /// The result of creating a named range.
  CreateNamedRangeResponse? createNamedRange;

  /// The result of inserting an inline image.
  InsertInlineImageResponse? insertInlineImage;

  /// The result of inserting an inline Google Sheets chart.
  InsertInlineSheetsChartResponse? insertInlineSheetsChart;

  /// The result of replacing text.
  ReplaceAllTextResponse? replaceAllText;

  Response();

  Response.fromJson(core.Map _json) {
    if (_json.containsKey('createFooter')) {
      createFooter = CreateFooterResponse.fromJson(
          _json['createFooter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createFootnote')) {
      createFootnote = CreateFootnoteResponse.fromJson(
          _json['createFootnote'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createHeader')) {
      createHeader = CreateHeaderResponse.fromJson(
          _json['createHeader'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createNamedRange')) {
      createNamedRange = CreateNamedRangeResponse.fromJson(
          _json['createNamedRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertInlineImage')) {
      insertInlineImage = InsertInlineImageResponse.fromJson(
          _json['insertInlineImage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertInlineSheetsChart')) {
      insertInlineSheetsChart = InsertInlineSheetsChartResponse.fromJson(
          _json['insertInlineSheetsChart']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replaceAllText')) {
      replaceAllText = ReplaceAllTextResponse.fromJson(
          _json['replaceAllText'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createFooter != null) 'createFooter': createFooter!.toJson(),
        if (createFootnote != null) 'createFootnote': createFootnote!.toJson(),
        if (createHeader != null) 'createHeader': createHeader!.toJson(),
        if (createNamedRange != null)
          'createNamedRange': createNamedRange!.toJson(),
        if (insertInlineImage != null)
          'insertInlineImage': insertInlineImage!.toJson(),
        if (insertInlineSheetsChart != null)
          'insertInlineSheetsChart': insertInlineSheetsChart!.toJson(),
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

/// A StructuralElement representing a section break.
///
/// A section is a range of content which has the same SectionStyle. A section
/// break represents the start of a new section, and the section style applies
/// to the section after the section break. The document body always begins with
/// a section break.
class SectionBreak {
  /// The style of the section after this section break.
  SectionStyle? sectionStyle;

  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// A SectionBreak may have multiple insertion IDs if it is a nested suggested
  /// change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  SectionBreak();

  SectionBreak.fromJson(core.Map _json) {
    if (_json.containsKey('sectionStyle')) {
      sectionStyle = SectionStyle.fromJson(
          _json['sectionStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sectionStyle != null) 'sectionStyle': sectionStyle!.toJson(),
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
      };
}

/// Properties that apply to a section's column.
class SectionColumnProperties {
  /// The padding at the end of the column.
  Dimension? paddingEnd;

  /// The width of the column.
  ///
  /// Output only.
  Dimension? width;

  SectionColumnProperties();

  SectionColumnProperties.fromJson(core.Map _json) {
    if (_json.containsKey('paddingEnd')) {
      paddingEnd = Dimension.fromJson(
          _json['paddingEnd'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('width')) {
      width = Dimension.fromJson(
          _json['width'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (paddingEnd != null) 'paddingEnd': paddingEnd!.toJson(),
        if (width != null) 'width': width!.toJson(),
      };
}

/// The styling that applies to a section.
class SectionStyle {
  /// The section's columns properties.
  ///
  /// If empty, the section contains one column with the default properties in
  /// the Docs editor. A section can be updated to have no more than three
  /// columns. When updating this property, setting a concrete value is
  /// required. Unsetting this property will result in a 400 bad request error.
  core.List<SectionColumnProperties>? columnProperties;

  /// The style of column separators.
  ///
  /// This style can be set even when there is one column in the section. When
  /// updating this property, setting a concrete value is required. Unsetting
  /// this property results in a 400 bad request error.
  /// Possible string values are:
  /// - "COLUMN_SEPARATOR_STYLE_UNSPECIFIED" : An unspecified column separator
  /// style.
  /// - "NONE" : No column separator lines between columns.
  /// - "BETWEEN_EACH_COLUMN" : Renders a column separator line between each
  /// column.
  core.String? columnSeparatorStyle;

  /// The content direction of this section.
  ///
  /// If unset, the value defaults to LEFT_TO_RIGHT. When updating this
  /// property, setting a concrete value is required. Unsetting this property
  /// results in a 400 bad request error.
  /// Possible string values are:
  /// - "CONTENT_DIRECTION_UNSPECIFIED" : The content direction is unspecified.
  /// - "LEFT_TO_RIGHT" : The content goes from left to right.
  /// - "RIGHT_TO_LEFT" : The content goes from right to left.
  core.String? contentDirection;

  /// The ID of the default footer.
  ///
  /// If unset, the value inherits from the previous SectionBreak's
  /// SectionStyle. If the value is unset in the first SectionBreak, it inherits
  /// from DocumentStyle's default_footer_id. This property is read-only.
  core.String? defaultFooterId;

  /// The ID of the default header.
  ///
  /// If unset, the value inherits from the previous SectionBreak's
  /// SectionStyle. If the value is unset in the first SectionBreak, it inherits
  /// from DocumentStyle's default_header_id. This property is read-only.
  core.String? defaultHeaderId;

  /// The ID of the footer used only for even pages.
  ///
  /// If the value of DocumentStyle's use_even_page_header_footer is true, this
  /// value is used for the footers on even pages in the section. If it is
  /// false, the footers on even pages uses the default_footer_id. If unset, the
  /// value inherits from the previous SectionBreak's SectionStyle. If the value
  /// is unset in the first SectionBreak, it inherits from DocumentStyle's
  /// even_page_footer_id. This property is read-only.
  core.String? evenPageFooterId;

  /// The ID of the header used only for even pages.
  ///
  /// If the value of DocumentStyle's use_even_page_header_footer is true, this
  /// value is used for the headers on even pages in the section. If it is
  /// false, the headers on even pages uses the default_header_id. If unset, the
  /// value inherits from the previous SectionBreak's SectionStyle. If the value
  /// is unset in the first SectionBreak, it inherits from DocumentStyle's
  /// even_page_header_id. This property is read-only.
  core.String? evenPageHeaderId;

  /// The ID of the footer used only for the first page of the section.
  ///
  /// If use_first_page_header_footer is true, this value is used for the footer
  /// on the first page of the section. If it is false, the footer on the first
  /// page of the section uses the default_footer_id. If unset, the value
  /// inherits from the previous SectionBreak's SectionStyle. If the value is
  /// unset in the first SectionBreak, it inherits from DocumentStyle's
  /// first_page_footer_id. This property is read-only.
  core.String? firstPageFooterId;

  /// The ID of the header used only for the first page of the section.
  ///
  /// If use_first_page_header_footer is true, this value is used for the header
  /// on the first page of the section. If it is false, the header on the first
  /// page of the section uses the default_header_id. If unset, the value
  /// inherits from the previous SectionBreak's SectionStyle. If the value is
  /// unset in the first SectionBreak, it inherits from DocumentStyle's
  /// first_page_header_id. This property is read-only.
  core.String? firstPageHeaderId;

  /// The bottom page margin of the section.
  ///
  /// If unset, uses margin_bottom from DocumentStyle. When updating this
  /// property, setting a concrete value is required. Unsetting this property
  /// results in a 400 bad request error.
  Dimension? marginBottom;

  /// The footer margin of the section.
  ///
  /// If unset, uses margin_footer from DocumentStyle. If updated,
  /// use_custom_header_footer_margins is set to true on DocumentStyle. The
  /// value of use_custom_header_footer_margins on DocumentStyle indicates if a
  /// footer margin is being respected for this section When updating this
  /// property, setting a concrete value is required. Unsetting this property
  /// results in a 400 bad request error.
  Dimension? marginFooter;

  /// The header margin of the section.
  ///
  /// If unset, uses margin_header from DocumentStyle. If updated,
  /// use_custom_header_footer_margins is set to true on DocumentStyle. The
  /// value of use_custom_header_footer_margins on DocumentStyle indicates if a
  /// header margin is being respected for this section. When updating this
  /// property, setting a concrete value is required. Unsetting this property
  /// results in a 400 bad request error.
  Dimension? marginHeader;

  /// The left page margin of the section.
  ///
  /// If unset, uses margin_left from DocumentStyle. Updating left margin causes
  /// columns in this section to resize. Since the margin affects column width,
  /// it is applied before column properties. When updating this property,
  /// setting a concrete value is required. Unsetting this property results in a
  /// 400 bad request error.
  Dimension? marginLeft;

  /// The right page margin of the section.
  ///
  /// If unset, uses margin_right from DocumentStyle. Updating right margin
  /// causes columns in this section to resize. Since the margin affects column
  /// width, it is applied before column properties. When updating this
  /// property, setting a concrete value is required. Unsetting this property
  /// results in a 400 bad request error.
  Dimension? marginRight;

  /// The top page margin of the section.
  ///
  /// If unset, uses margin_top from DocumentStyle. When updating this property,
  /// setting a concrete value is required. Unsetting this property results in a
  /// 400 bad request error.
  Dimension? marginTop;

  /// The page number from which to start counting the number of pages for this
  /// section.
  ///
  /// If unset, page numbering continues from the previous section. If the value
  /// is unset in the first SectionBreak, refer to DocumentStyle's
  /// page_number_start. When updating this property, setting a concrete value
  /// is required. Unsetting this property results in a 400 bad request error.
  core.int? pageNumberStart;

  /// The type of section.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "SECTION_TYPE_UNSPECIFIED" : The section type is unspecified.
  /// - "CONTINUOUS" : The section starts immediately after the last paragraph
  /// of the previous section.
  /// - "NEXT_PAGE" : The section starts on the next page.
  core.String? sectionType;

  /// Indicates whether to use the first page header / footer IDs for the first
  /// page of the section.
  ///
  /// If unset, it inherits from DocumentStyle's use_first_page_header_footer
  /// for the first section. If the value is unset for subsequent sectors, it
  /// should be interpreted as false. When updating this property, setting a
  /// concrete value is required. Unsetting this property results in a 400 bad
  /// request error.
  core.bool? useFirstPageHeaderFooter;

  SectionStyle();

  SectionStyle.fromJson(core.Map _json) {
    if (_json.containsKey('columnProperties')) {
      columnProperties = (_json['columnProperties'] as core.List)
          .map<SectionColumnProperties>((value) =>
              SectionColumnProperties.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('columnSeparatorStyle')) {
      columnSeparatorStyle = _json['columnSeparatorStyle'] as core.String;
    }
    if (_json.containsKey('contentDirection')) {
      contentDirection = _json['contentDirection'] as core.String;
    }
    if (_json.containsKey('defaultFooterId')) {
      defaultFooterId = _json['defaultFooterId'] as core.String;
    }
    if (_json.containsKey('defaultHeaderId')) {
      defaultHeaderId = _json['defaultHeaderId'] as core.String;
    }
    if (_json.containsKey('evenPageFooterId')) {
      evenPageFooterId = _json['evenPageFooterId'] as core.String;
    }
    if (_json.containsKey('evenPageHeaderId')) {
      evenPageHeaderId = _json['evenPageHeaderId'] as core.String;
    }
    if (_json.containsKey('firstPageFooterId')) {
      firstPageFooterId = _json['firstPageFooterId'] as core.String;
    }
    if (_json.containsKey('firstPageHeaderId')) {
      firstPageHeaderId = _json['firstPageHeaderId'] as core.String;
    }
    if (_json.containsKey('marginBottom')) {
      marginBottom = Dimension.fromJson(
          _json['marginBottom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginFooter')) {
      marginFooter = Dimension.fromJson(
          _json['marginFooter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginHeader')) {
      marginHeader = Dimension.fromJson(
          _json['marginHeader'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginLeft')) {
      marginLeft = Dimension.fromJson(
          _json['marginLeft'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginRight')) {
      marginRight = Dimension.fromJson(
          _json['marginRight'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marginTop')) {
      marginTop = Dimension.fromJson(
          _json['marginTop'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pageNumberStart')) {
      pageNumberStart = _json['pageNumberStart'] as core.int;
    }
    if (_json.containsKey('sectionType')) {
      sectionType = _json['sectionType'] as core.String;
    }
    if (_json.containsKey('useFirstPageHeaderFooter')) {
      useFirstPageHeaderFooter = _json['useFirstPageHeaderFooter'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnProperties != null)
          'columnProperties':
              columnProperties!.map((value) => value.toJson()).toList(),
        if (columnSeparatorStyle != null)
          'columnSeparatorStyle': columnSeparatorStyle!,
        if (contentDirection != null) 'contentDirection': contentDirection!,
        if (defaultFooterId != null) 'defaultFooterId': defaultFooterId!,
        if (defaultHeaderId != null) 'defaultHeaderId': defaultHeaderId!,
        if (evenPageFooterId != null) 'evenPageFooterId': evenPageFooterId!,
        if (evenPageHeaderId != null) 'evenPageHeaderId': evenPageHeaderId!,
        if (firstPageFooterId != null) 'firstPageFooterId': firstPageFooterId!,
        if (firstPageHeaderId != null) 'firstPageHeaderId': firstPageHeaderId!,
        if (marginBottom != null) 'marginBottom': marginBottom!.toJson(),
        if (marginFooter != null) 'marginFooter': marginFooter!.toJson(),
        if (marginHeader != null) 'marginHeader': marginHeader!.toJson(),
        if (marginLeft != null) 'marginLeft': marginLeft!.toJson(),
        if (marginRight != null) 'marginRight': marginRight!.toJson(),
        if (marginTop != null) 'marginTop': marginTop!.toJson(),
        if (pageNumberStart != null) 'pageNumberStart': pageNumberStart!,
        if (sectionType != null) 'sectionType': sectionType!,
        if (useFirstPageHeaderFooter != null)
          'useFirstPageHeaderFooter': useFirstPageHeaderFooter!,
      };
}

/// The shading of a paragraph.
class Shading {
  /// The background color of this paragraph shading.
  OptionalColor? backgroundColor;

  Shading();

  Shading.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundColor')) {
      backgroundColor = OptionalColor.fromJson(
          _json['backgroundColor'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundColor != null)
          'backgroundColor': backgroundColor!.toJson(),
      };
}

/// A mask that indicates which of the fields on the base Shading have been
/// changed in this suggested change.
///
/// For any field set to true, there is a new suggested value.
class ShadingSuggestionState {
  /// Indicates if there was a suggested change to the Shading.
  core.bool? backgroundColorSuggested;

  ShadingSuggestionState();

  ShadingSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundColorSuggested')) {
      backgroundColorSuggested = _json['backgroundColorSuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundColorSuggested != null)
          'backgroundColorSuggested': backgroundColorSuggested!,
      };
}

/// A reference to a linked chart embedded from Google Sheets.
class SheetsChartReference {
  /// The ID of the specific chart in the Google Sheets spreadsheet that is
  /// embedded.
  core.int? chartId;

  /// The ID of the Google Sheets spreadsheet that contains the source chart.
  core.String? spreadsheetId;

  SheetsChartReference();

  SheetsChartReference.fromJson(core.Map _json) {
    if (_json.containsKey('chartId')) {
      chartId = _json['chartId'] as core.int;
    }
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chartId != null) 'chartId': chartId!,
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
      };
}

/// A mask that indicates which of the fields on the base SheetsChartReference
/// have been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class SheetsChartReferenceSuggestionState {
  /// Indicates if there was a suggested change to chart_id.
  core.bool? chartIdSuggested;

  /// Indicates if there was a suggested change to spreadsheet_id.
  core.bool? spreadsheetIdSuggested;

  SheetsChartReferenceSuggestionState();

  SheetsChartReferenceSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('chartIdSuggested')) {
      chartIdSuggested = _json['chartIdSuggested'] as core.bool;
    }
    if (_json.containsKey('spreadsheetIdSuggested')) {
      spreadsheetIdSuggested = _json['spreadsheetIdSuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chartIdSuggested != null) 'chartIdSuggested': chartIdSuggested!,
        if (spreadsheetIdSuggested != null)
          'spreadsheetIdSuggested': spreadsheetIdSuggested!,
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

/// A mask that indicates which of the fields on the base Size have been changed
/// in this suggestion.
///
/// For any field set to true, the Size has a new suggested value.
class SizeSuggestionState {
  /// Indicates if there was a suggested change to height.
  core.bool? heightSuggested;

  /// Indicates if there was a suggested change to width.
  core.bool? widthSuggested;

  SizeSuggestionState();

  SizeSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('heightSuggested')) {
      heightSuggested = _json['heightSuggested'] as core.bool;
    }
    if (_json.containsKey('widthSuggested')) {
      widthSuggested = _json['widthSuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (heightSuggested != null) 'heightSuggested': heightSuggested!,
        if (widthSuggested != null) 'widthSuggested': widthSuggested!,
      };
}

/// A StructuralElement describes content that provides structure to the
/// document.
class StructuralElement {
  /// The zero-based end index of this structural element, exclusive, in UTF-16
  /// code units.
  core.int? endIndex;

  /// A paragraph type of structural element.
  Paragraph? paragraph;

  /// A section break type of structural element.
  SectionBreak? sectionBreak;

  /// The zero-based start index of this structural element, in UTF-16 code
  /// units.
  core.int? startIndex;

  /// A table type of structural element.
  Table? table;

  /// A table of contents type of structural element.
  TableOfContents? tableOfContents;

  StructuralElement();

  StructuralElement.fromJson(core.Map _json) {
    if (_json.containsKey('endIndex')) {
      endIndex = _json['endIndex'] as core.int;
    }
    if (_json.containsKey('paragraph')) {
      paragraph = Paragraph.fromJson(
          _json['paragraph'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sectionBreak')) {
      sectionBreak = SectionBreak.fromJson(
          _json['sectionBreak'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startIndex')) {
      startIndex = _json['startIndex'] as core.int;
    }
    if (_json.containsKey('table')) {
      table =
          Table.fromJson(_json['table'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableOfContents')) {
      tableOfContents = TableOfContents.fromJson(
          _json['tableOfContents'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endIndex != null) 'endIndex': endIndex!,
        if (paragraph != null) 'paragraph': paragraph!.toJson(),
        if (sectionBreak != null) 'sectionBreak': sectionBreak!.toJson(),
        if (startIndex != null) 'startIndex': startIndex!,
        if (table != null) 'table': table!.toJson(),
        if (tableOfContents != null)
          'tableOfContents': tableOfContents!.toJson(),
      };
}

/// A criteria that matches a specific string of text in the document.
class SubstringMatchCriteria {
  /// Indicates whether the search should respect case: - `True`: the search is
  /// case sensitive.
  ///
  /// - `False`: the search is case insensitive.
  core.bool? matchCase;

  /// The text to search for in the document.
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

/// A suggested change to a Bullet.
class SuggestedBullet {
  /// A Bullet that only includes the changes made in this suggestion.
  ///
  /// This can be used along with the bullet_suggestion_state to see which
  /// fields have changed and their new values.
  Bullet? bullet;

  /// A mask that indicates which of the fields on the base Bullet have been
  /// changed in this suggestion.
  BulletSuggestionState? bulletSuggestionState;

  SuggestedBullet();

  SuggestedBullet.fromJson(core.Map _json) {
    if (_json.containsKey('bullet')) {
      bullet = Bullet.fromJson(
          _json['bullet'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('bulletSuggestionState')) {
      bulletSuggestionState = BulletSuggestionState.fromJson(
          _json['bulletSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bullet != null) 'bullet': bullet!.toJson(),
        if (bulletSuggestionState != null)
          'bulletSuggestionState': bulletSuggestionState!.toJson(),
      };
}

/// A suggested change to the DocumentStyle.
class SuggestedDocumentStyle {
  /// A DocumentStyle that only includes the changes made in this suggestion.
  ///
  /// This can be used along with the document_style_suggestion_state to see
  /// which fields have changed and their new values.
  DocumentStyle? documentStyle;

  /// A mask that indicates which of the fields on the base DocumentStyle have
  /// been changed in this suggestion.
  DocumentStyleSuggestionState? documentStyleSuggestionState;

  SuggestedDocumentStyle();

  SuggestedDocumentStyle.fromJson(core.Map _json) {
    if (_json.containsKey('documentStyle')) {
      documentStyle = DocumentStyle.fromJson(
          _json['documentStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('documentStyleSuggestionState')) {
      documentStyleSuggestionState = DocumentStyleSuggestionState.fromJson(
          _json['documentStyleSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (documentStyle != null) 'documentStyle': documentStyle!.toJson(),
        if (documentStyleSuggestionState != null)
          'documentStyleSuggestionState':
              documentStyleSuggestionState!.toJson(),
      };
}

/// A suggested change to InlineObjectProperties.
class SuggestedInlineObjectProperties {
  /// An InlineObjectProperties that only includes the changes made in this
  /// suggestion.
  ///
  /// This can be used along with the inline_object_properties_suggestion_state
  /// to see which fields have changed and their new values.
  InlineObjectProperties? inlineObjectProperties;

  /// A mask that indicates which of the fields on the base
  /// InlineObjectProperties have been changed in this suggestion.
  InlineObjectPropertiesSuggestionState? inlineObjectPropertiesSuggestionState;

  SuggestedInlineObjectProperties();

  SuggestedInlineObjectProperties.fromJson(core.Map _json) {
    if (_json.containsKey('inlineObjectProperties')) {
      inlineObjectProperties = InlineObjectProperties.fromJson(
          _json['inlineObjectProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inlineObjectPropertiesSuggestionState')) {
      inlineObjectPropertiesSuggestionState =
          InlineObjectPropertiesSuggestionState.fromJson(
              _json['inlineObjectPropertiesSuggestionState']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inlineObjectProperties != null)
          'inlineObjectProperties': inlineObjectProperties!.toJson(),
        if (inlineObjectPropertiesSuggestionState != null)
          'inlineObjectPropertiesSuggestionState':
              inlineObjectPropertiesSuggestionState!.toJson(),
      };
}

/// A suggested change to ListProperties.
class SuggestedListProperties {
  /// A ListProperties that only includes the changes made in this suggestion.
  ///
  /// This can be used along with the list_properties_suggestion_state to see
  /// which fields have changed and their new values.
  ListProperties? listProperties;

  /// A mask that indicates which of the fields on the base ListProperties have
  /// been changed in this suggestion.
  ListPropertiesSuggestionState? listPropertiesSuggestionState;

  SuggestedListProperties();

  SuggestedListProperties.fromJson(core.Map _json) {
    if (_json.containsKey('listProperties')) {
      listProperties = ListProperties.fromJson(
          _json['listProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('listPropertiesSuggestionState')) {
      listPropertiesSuggestionState = ListPropertiesSuggestionState.fromJson(
          _json['listPropertiesSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (listProperties != null) 'listProperties': listProperties!.toJson(),
        if (listPropertiesSuggestionState != null)
          'listPropertiesSuggestionState':
              listPropertiesSuggestionState!.toJson(),
      };
}

/// A suggested change to the NamedStyles.
class SuggestedNamedStyles {
  /// A NamedStyles that only includes the changes made in this suggestion.
  ///
  /// This can be used along with the named_styles_suggestion_state to see which
  /// fields have changed and their new values.
  NamedStyles? namedStyles;

  /// A mask that indicates which of the fields on the base NamedStyles have
  /// been changed in this suggestion.
  NamedStylesSuggestionState? namedStylesSuggestionState;

  SuggestedNamedStyles();

  SuggestedNamedStyles.fromJson(core.Map _json) {
    if (_json.containsKey('namedStyles')) {
      namedStyles = NamedStyles.fromJson(
          _json['namedStyles'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('namedStylesSuggestionState')) {
      namedStylesSuggestionState = NamedStylesSuggestionState.fromJson(
          _json['namedStylesSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (namedStyles != null) 'namedStyles': namedStyles!.toJson(),
        if (namedStylesSuggestionState != null)
          'namedStylesSuggestionState': namedStylesSuggestionState!.toJson(),
      };
}

/// A suggested change to a ParagraphStyle.
class SuggestedParagraphStyle {
  /// A ParagraphStyle that only includes the changes made in this suggestion.
  ///
  /// This can be used along with the paragraph_suggestion_state to see which
  /// fields have changed and their new values.
  ParagraphStyle? paragraphStyle;

  /// A mask that indicates which of the fields on the base ParagraphStyle have
  /// been changed in this suggestion.
  ParagraphStyleSuggestionState? paragraphStyleSuggestionState;

  SuggestedParagraphStyle();

  SuggestedParagraphStyle.fromJson(core.Map _json) {
    if (_json.containsKey('paragraphStyle')) {
      paragraphStyle = ParagraphStyle.fromJson(
          _json['paragraphStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('paragraphStyleSuggestionState')) {
      paragraphStyleSuggestionState = ParagraphStyleSuggestionState.fromJson(
          _json['paragraphStyleSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (paragraphStyle != null) 'paragraphStyle': paragraphStyle!.toJson(),
        if (paragraphStyleSuggestionState != null)
          'paragraphStyleSuggestionState':
              paragraphStyleSuggestionState!.toJson(),
      };
}

/// A suggested change to PositionedObjectProperties.
class SuggestedPositionedObjectProperties {
  /// A PositionedObjectProperties that only includes the changes made in this
  /// suggestion.
  ///
  /// This can be used along with the
  /// positioned_object_properties_suggestion_state to see which fields have
  /// changed and their new values.
  PositionedObjectProperties? positionedObjectProperties;

  /// A mask that indicates which of the fields on the base
  /// PositionedObjectProperties have been changed in this suggestion.
  PositionedObjectPropertiesSuggestionState?
      positionedObjectPropertiesSuggestionState;

  SuggestedPositionedObjectProperties();

  SuggestedPositionedObjectProperties.fromJson(core.Map _json) {
    if (_json.containsKey('positionedObjectProperties')) {
      positionedObjectProperties = PositionedObjectProperties.fromJson(
          _json['positionedObjectProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('positionedObjectPropertiesSuggestionState')) {
      positionedObjectPropertiesSuggestionState =
          PositionedObjectPropertiesSuggestionState.fromJson(
              _json['positionedObjectPropertiesSuggestionState']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (positionedObjectProperties != null)
          'positionedObjectProperties': positionedObjectProperties!.toJson(),
        if (positionedObjectPropertiesSuggestionState != null)
          'positionedObjectPropertiesSuggestionState':
              positionedObjectPropertiesSuggestionState!.toJson(),
      };
}

/// A suggested change to a TableCellStyle.
class SuggestedTableCellStyle {
  /// A TableCellStyle that only includes the changes made in this suggestion.
  ///
  /// This can be used along with the table_cell_style_suggestion_state to see
  /// which fields have changed and their new values.
  TableCellStyle? tableCellStyle;

  /// A mask that indicates which of the fields on the base TableCellStyle have
  /// been changed in this suggestion.
  TableCellStyleSuggestionState? tableCellStyleSuggestionState;

  SuggestedTableCellStyle();

  SuggestedTableCellStyle.fromJson(core.Map _json) {
    if (_json.containsKey('tableCellStyle')) {
      tableCellStyle = TableCellStyle.fromJson(
          _json['tableCellStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableCellStyleSuggestionState')) {
      tableCellStyleSuggestionState = TableCellStyleSuggestionState.fromJson(
          _json['tableCellStyleSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tableCellStyle != null) 'tableCellStyle': tableCellStyle!.toJson(),
        if (tableCellStyleSuggestionState != null)
          'tableCellStyleSuggestionState':
              tableCellStyleSuggestionState!.toJson(),
      };
}

/// A suggested change to a TableRowStyle.
class SuggestedTableRowStyle {
  /// A TableRowStyle that only includes the changes made in this suggestion.
  ///
  /// This can be used along with the table_row_style_suggestion_state to see
  /// which fields have changed and their new values.
  TableRowStyle? tableRowStyle;

  /// A mask that indicates which of the fields on the base TableRowStyle have
  /// been changed in this suggestion.
  TableRowStyleSuggestionState? tableRowStyleSuggestionState;

  SuggestedTableRowStyle();

  SuggestedTableRowStyle.fromJson(core.Map _json) {
    if (_json.containsKey('tableRowStyle')) {
      tableRowStyle = TableRowStyle.fromJson(
          _json['tableRowStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableRowStyleSuggestionState')) {
      tableRowStyleSuggestionState = TableRowStyleSuggestionState.fromJson(
          _json['tableRowStyleSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tableRowStyle != null) 'tableRowStyle': tableRowStyle!.toJson(),
        if (tableRowStyleSuggestionState != null)
          'tableRowStyleSuggestionState':
              tableRowStyleSuggestionState!.toJson(),
      };
}

/// A suggested change to a TextStyle.
class SuggestedTextStyle {
  /// A TextStyle that only includes the changes made in this suggestion.
  ///
  /// This can be used along with the text_style_suggestion_state to see which
  /// fields have changed and their new values.
  TextStyle? textStyle;

  /// A mask that indicates which of the fields on the base TextStyle have been
  /// changed in this suggestion.
  TextStyleSuggestionState? textStyleSuggestionState;

  SuggestedTextStyle();

  SuggestedTextStyle.fromJson(core.Map _json) {
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textStyleSuggestionState')) {
      textStyleSuggestionState = TextStyleSuggestionState.fromJson(
          _json['textStyleSuggestionState']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
        if (textStyleSuggestionState != null)
          'textStyleSuggestionState': textStyleSuggestionState!.toJson(),
      };
}

/// A tab stop within a paragraph.
class TabStop {
  /// The alignment of this tab stop.
  ///
  /// If unset, the value defaults to START.
  /// Possible string values are:
  /// - "TAB_STOP_ALIGNMENT_UNSPECIFIED" : The tab stop alignment is
  /// unspecified.
  /// - "START" : The tab stop is aligned to the start of the line. This is the
  /// default.
  /// - "CENTER" : The tab stop is aligned to the center of the line.
  /// - "END" : The tab stop is aligned to the end of the line.
  core.String? alignment;

  /// The offset between this tab stop and the start margin.
  Dimension? offset;

  TabStop();

  TabStop.fromJson(core.Map _json) {
    if (_json.containsKey('alignment')) {
      alignment = _json['alignment'] as core.String;
    }
    if (_json.containsKey('offset')) {
      offset = Dimension.fromJson(
          _json['offset'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alignment != null) 'alignment': alignment!,
        if (offset != null) 'offset': offset!.toJson(),
      };
}

/// A StructuralElement representing a table.
class Table {
  /// Number of columns in the table.
  ///
  /// It is possible for a table to be non-rectangular, so some rows may have a
  /// different number of cells.
  core.int? columns;

  /// Number of rows in the table.
  core.int? rows;

  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// A Table may have multiple insertion IDs if it is a nested suggested
  /// change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  /// The contents and style of each row.
  core.List<TableRow>? tableRows;

  /// The style of the table.
  TableStyle? tableStyle;

  Table();

  Table.fromJson(core.Map _json) {
    if (_json.containsKey('columns')) {
      columns = _json['columns'] as core.int;
    }
    if (_json.containsKey('rows')) {
      rows = _json['rows'] as core.int;
    }
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('tableRows')) {
      tableRows = (_json['tableRows'] as core.List)
          .map<TableRow>((value) =>
              TableRow.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('tableStyle')) {
      tableStyle = TableStyle.fromJson(
          _json['tableStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columns != null) 'columns': columns!,
        if (rows != null) 'rows': rows!,
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
        if (tableRows != null)
          'tableRows': tableRows!.map((value) => value.toJson()).toList(),
        if (tableStyle != null) 'tableStyle': tableStyle!.toJson(),
      };
}

/// The contents and style of a cell in a Table.
class TableCell {
  /// The content of the cell.
  core.List<StructuralElement>? content;

  /// The zero-based end index of this cell, exclusive, in UTF-16 code units.
  core.int? endIndex;

  /// The zero-based start index of this cell, in UTF-16 code units.
  core.int? startIndex;

  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// A TableCell may have multiple insertion IDs if it is a nested suggested
  /// change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  /// The suggested changes to the table cell style, keyed by suggestion ID.
  core.Map<core.String, SuggestedTableCellStyle>?
      suggestedTableCellStyleChanges;

  /// The style of the cell.
  TableCellStyle? tableCellStyle;

  TableCell();

  TableCell.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = (_json['content'] as core.List)
          .map<StructuralElement>((value) => StructuralElement.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('endIndex')) {
      endIndex = _json['endIndex'] as core.int;
    }
    if (_json.containsKey('startIndex')) {
      startIndex = _json['startIndex'] as core.int;
    }
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedTableCellStyleChanges')) {
      suggestedTableCellStyleChanges = (_json['suggestedTableCellStyleChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedTableCellStyle.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('tableCellStyle')) {
      tableCellStyle = TableCellStyle.fromJson(
          _json['tableCellStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null)
          'content': content!.map((value) => value.toJson()).toList(),
        if (endIndex != null) 'endIndex': endIndex!,
        if (startIndex != null) 'startIndex': startIndex!,
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
        if (suggestedTableCellStyleChanges != null)
          'suggestedTableCellStyleChanges': suggestedTableCellStyleChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (tableCellStyle != null) 'tableCellStyle': tableCellStyle!.toJson(),
      };
}

/// A border around a table cell.
///
/// Table cell borders cannot be transparent. To hide a table cell border, make
/// its width 0.
class TableCellBorder {
  /// The color of the border.
  ///
  /// This color cannot be transparent.
  OptionalColor? color;

  /// The dash style of the border.
  /// Possible string values are:
  /// - "DASH_STYLE_UNSPECIFIED" : Unspecified dash style.
  /// - "SOLID" : Solid line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'solid'. This is the default dash style.
  /// - "DOT" : Dotted line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'dot'.
  /// - "DASH" : Dashed line. Corresponds to ECMA-376 ST_PresetLineDashVal value
  /// 'dash'.
  core.String? dashStyle;

  /// The width of the border.
  Dimension? width;

  TableCellBorder();

  TableCellBorder.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color = OptionalColor.fromJson(
          _json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dashStyle')) {
      dashStyle = _json['dashStyle'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = Dimension.fromJson(
          _json['width'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
        if (dashStyle != null) 'dashStyle': dashStyle!,
        if (width != null) 'width': width!.toJson(),
      };
}

/// Location of a single cell within a table.
class TableCellLocation {
  /// The zero-based column index.
  ///
  /// For example, the second column in the table has a column index of 1.
  core.int? columnIndex;

  /// The zero-based row index.
  ///
  /// For example, the second row in the table has a row index of 1.
  core.int? rowIndex;

  /// The location where the table starts in the document.
  Location? tableStartLocation;

  TableCellLocation();

  TableCellLocation.fromJson(core.Map _json) {
    if (_json.containsKey('columnIndex')) {
      columnIndex = _json['columnIndex'] as core.int;
    }
    if (_json.containsKey('rowIndex')) {
      rowIndex = _json['rowIndex'] as core.int;
    }
    if (_json.containsKey('tableStartLocation')) {
      tableStartLocation = Location.fromJson(
          _json['tableStartLocation'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnIndex != null) 'columnIndex': columnIndex!,
        if (rowIndex != null) 'rowIndex': rowIndex!,
        if (tableStartLocation != null)
          'tableStartLocation': tableStartLocation!.toJson(),
      };
}

/// The style of a TableCell.
///
/// Inherited table cell styles are represented as unset fields in this message.
/// A table cell style can inherit from the table's style.
class TableCellStyle {
  /// The background color of the cell.
  OptionalColor? backgroundColor;

  /// The bottom border of the cell.
  TableCellBorder? borderBottom;

  /// The left border of the cell.
  TableCellBorder? borderLeft;

  /// The right border of the cell.
  TableCellBorder? borderRight;

  /// The top border of the cell.
  TableCellBorder? borderTop;

  /// The column span of the cell.
  ///
  /// This property is read-only.
  core.int? columnSpan;

  /// The alignment of the content in the table cell.
  ///
  /// The default alignment matches the alignment for newly created table cells
  /// in the Docs editor.
  /// Possible string values are:
  /// - "CONTENT_ALIGNMENT_UNSPECIFIED" : An unspecified content alignment. The
  /// content alignment is inherited from the parent if one exists.
  /// - "CONTENT_ALIGNMENT_UNSUPPORTED" : An unsupported content alignment.
  /// - "TOP" : An alignment that aligns the content to the top of the content
  /// holder. Corresponds to ECMA-376 ST_TextAnchoringType 't'.
  /// - "MIDDLE" : An alignment that aligns the content to the middle of the
  /// content holder. Corresponds to ECMA-376 ST_TextAnchoringType 'ctr'.
  /// - "BOTTOM" : An alignment that aligns the content to the bottom of the
  /// content holder. Corresponds to ECMA-376 ST_TextAnchoringType 'b'.
  core.String? contentAlignment;

  /// The bottom padding of the cell.
  Dimension? paddingBottom;

  /// The left padding of the cell.
  Dimension? paddingLeft;

  /// The right padding of the cell.
  Dimension? paddingRight;

  /// The top padding of the cell.
  Dimension? paddingTop;

  /// The row span of the cell.
  ///
  /// This property is read-only.
  core.int? rowSpan;

  TableCellStyle();

  TableCellStyle.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundColor')) {
      backgroundColor = OptionalColor.fromJson(
          _json['backgroundColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('borderBottom')) {
      borderBottom = TableCellBorder.fromJson(
          _json['borderBottom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('borderLeft')) {
      borderLeft = TableCellBorder.fromJson(
          _json['borderLeft'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('borderRight')) {
      borderRight = TableCellBorder.fromJson(
          _json['borderRight'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('borderTop')) {
      borderTop = TableCellBorder.fromJson(
          _json['borderTop'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('columnSpan')) {
      columnSpan = _json['columnSpan'] as core.int;
    }
    if (_json.containsKey('contentAlignment')) {
      contentAlignment = _json['contentAlignment'] as core.String;
    }
    if (_json.containsKey('paddingBottom')) {
      paddingBottom = Dimension.fromJson(
          _json['paddingBottom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('paddingLeft')) {
      paddingLeft = Dimension.fromJson(
          _json['paddingLeft'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('paddingRight')) {
      paddingRight = Dimension.fromJson(
          _json['paddingRight'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('paddingTop')) {
      paddingTop = Dimension.fromJson(
          _json['paddingTop'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rowSpan')) {
      rowSpan = _json['rowSpan'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundColor != null)
          'backgroundColor': backgroundColor!.toJson(),
        if (borderBottom != null) 'borderBottom': borderBottom!.toJson(),
        if (borderLeft != null) 'borderLeft': borderLeft!.toJson(),
        if (borderRight != null) 'borderRight': borderRight!.toJson(),
        if (borderTop != null) 'borderTop': borderTop!.toJson(),
        if (columnSpan != null) 'columnSpan': columnSpan!,
        if (contentAlignment != null) 'contentAlignment': contentAlignment!,
        if (paddingBottom != null) 'paddingBottom': paddingBottom!.toJson(),
        if (paddingLeft != null) 'paddingLeft': paddingLeft!.toJson(),
        if (paddingRight != null) 'paddingRight': paddingRight!.toJson(),
        if (paddingTop != null) 'paddingTop': paddingTop!.toJson(),
        if (rowSpan != null) 'rowSpan': rowSpan!,
      };
}

/// A mask that indicates which of the fields on the base TableCellStyle have
/// been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class TableCellStyleSuggestionState {
  /// Indicates if there was a suggested change to background_color.
  core.bool? backgroundColorSuggested;

  /// Indicates if there was a suggested change to border_bottom.
  core.bool? borderBottomSuggested;

  /// Indicates if there was a suggested change to border_left.
  core.bool? borderLeftSuggested;

  /// Indicates if there was a suggested change to border_right.
  core.bool? borderRightSuggested;

  /// Indicates if there was a suggested change to border_top.
  core.bool? borderTopSuggested;

  /// Indicates if there was a suggested change to column_span.
  core.bool? columnSpanSuggested;

  /// Indicates if there was a suggested change to content_alignment.
  core.bool? contentAlignmentSuggested;

  /// Indicates if there was a suggested change to padding_bottom.
  core.bool? paddingBottomSuggested;

  /// Indicates if there was a suggested change to padding_left.
  core.bool? paddingLeftSuggested;

  /// Indicates if there was a suggested change to padding_right.
  core.bool? paddingRightSuggested;

  /// Indicates if there was a suggested change to padding_top.
  core.bool? paddingTopSuggested;

  /// Indicates if there was a suggested change to row_span.
  core.bool? rowSpanSuggested;

  TableCellStyleSuggestionState();

  TableCellStyleSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundColorSuggested')) {
      backgroundColorSuggested = _json['backgroundColorSuggested'] as core.bool;
    }
    if (_json.containsKey('borderBottomSuggested')) {
      borderBottomSuggested = _json['borderBottomSuggested'] as core.bool;
    }
    if (_json.containsKey('borderLeftSuggested')) {
      borderLeftSuggested = _json['borderLeftSuggested'] as core.bool;
    }
    if (_json.containsKey('borderRightSuggested')) {
      borderRightSuggested = _json['borderRightSuggested'] as core.bool;
    }
    if (_json.containsKey('borderTopSuggested')) {
      borderTopSuggested = _json['borderTopSuggested'] as core.bool;
    }
    if (_json.containsKey('columnSpanSuggested')) {
      columnSpanSuggested = _json['columnSpanSuggested'] as core.bool;
    }
    if (_json.containsKey('contentAlignmentSuggested')) {
      contentAlignmentSuggested =
          _json['contentAlignmentSuggested'] as core.bool;
    }
    if (_json.containsKey('paddingBottomSuggested')) {
      paddingBottomSuggested = _json['paddingBottomSuggested'] as core.bool;
    }
    if (_json.containsKey('paddingLeftSuggested')) {
      paddingLeftSuggested = _json['paddingLeftSuggested'] as core.bool;
    }
    if (_json.containsKey('paddingRightSuggested')) {
      paddingRightSuggested = _json['paddingRightSuggested'] as core.bool;
    }
    if (_json.containsKey('paddingTopSuggested')) {
      paddingTopSuggested = _json['paddingTopSuggested'] as core.bool;
    }
    if (_json.containsKey('rowSpanSuggested')) {
      rowSpanSuggested = _json['rowSpanSuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundColorSuggested != null)
          'backgroundColorSuggested': backgroundColorSuggested!,
        if (borderBottomSuggested != null)
          'borderBottomSuggested': borderBottomSuggested!,
        if (borderLeftSuggested != null)
          'borderLeftSuggested': borderLeftSuggested!,
        if (borderRightSuggested != null)
          'borderRightSuggested': borderRightSuggested!,
        if (borderTopSuggested != null)
          'borderTopSuggested': borderTopSuggested!,
        if (columnSpanSuggested != null)
          'columnSpanSuggested': columnSpanSuggested!,
        if (contentAlignmentSuggested != null)
          'contentAlignmentSuggested': contentAlignmentSuggested!,
        if (paddingBottomSuggested != null)
          'paddingBottomSuggested': paddingBottomSuggested!,
        if (paddingLeftSuggested != null)
          'paddingLeftSuggested': paddingLeftSuggested!,
        if (paddingRightSuggested != null)
          'paddingRightSuggested': paddingRightSuggested!,
        if (paddingTopSuggested != null)
          'paddingTopSuggested': paddingTopSuggested!,
        if (rowSpanSuggested != null) 'rowSpanSuggested': rowSpanSuggested!,
      };
}

/// The properties of a column in a table.
class TableColumnProperties {
  /// The width of the column.
  ///
  /// Set when the column's `width_type` is FIXED_WIDTH.
  Dimension? width;

  /// The width type of the column.
  /// Possible string values are:
  /// - "WIDTH_TYPE_UNSPECIFIED" : The column width type is unspecified.
  /// - "EVENLY_DISTRIBUTED" : The column width is evenly distributed among the
  /// other evenly distrubted columns. The width of the column is automatically
  /// determined and will have an equal portion of the width remaining for the
  /// table after accounting for all columns with specified widths.
  /// - "FIXED_WIDTH" : A fixed column width. The width property contains the
  /// column's width.
  core.String? widthType;

  TableColumnProperties();

  TableColumnProperties.fromJson(core.Map _json) {
    if (_json.containsKey('width')) {
      width = Dimension.fromJson(
          _json['width'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('widthType')) {
      widthType = _json['widthType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (width != null) 'width': width!.toJson(),
        if (widthType != null) 'widthType': widthType!,
      };
}

/// A StructuralElement representing a table of contents.
class TableOfContents {
  /// The content of the table of contents.
  core.List<StructuralElement>? content;

  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// A TableOfContents may have multiple insertion IDs if it is a nested
  /// suggested change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  TableOfContents();

  TableOfContents.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = (_json['content'] as core.List)
          .map<StructuralElement>((value) => StructuralElement.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null)
          'content': content!.map((value) => value.toJson()).toList(),
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
      };
}

/// A table range represents a reference to a subset of a table.
///
/// It's important to note that the cells specified by a table range do not
/// necessarily form a rectangle. For example, let's say we have a 3 x 3 table
/// where all the cells of the last row are merged together. The table looks
/// like this: \[ \] A table range with table cell location =
/// (table_start_location, row = 0, column = 0), row span = 3 and column span =
/// 2 specifies the following cells: x x \[ x x x \]
class TableRange {
  /// The column span of the table range.
  core.int? columnSpan;

  /// The row span of the table range.
  core.int? rowSpan;

  /// The cell location where the table range starts.
  TableCellLocation? tableCellLocation;

  TableRange();

  TableRange.fromJson(core.Map _json) {
    if (_json.containsKey('columnSpan')) {
      columnSpan = _json['columnSpan'] as core.int;
    }
    if (_json.containsKey('rowSpan')) {
      rowSpan = _json['rowSpan'] as core.int;
    }
    if (_json.containsKey('tableCellLocation')) {
      tableCellLocation = TableCellLocation.fromJson(
          _json['tableCellLocation'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnSpan != null) 'columnSpan': columnSpan!,
        if (rowSpan != null) 'rowSpan': rowSpan!,
        if (tableCellLocation != null)
          'tableCellLocation': tableCellLocation!.toJson(),
      };
}

/// The contents and style of a row in a Table.
class TableRow {
  /// The zero-based end index of this row, exclusive, in UTF-16 code units.
  core.int? endIndex;

  /// The zero-based start index of this row, in UTF-16 code units.
  core.int? startIndex;

  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// A TableRow may have multiple insertion IDs if it is a nested suggested
  /// change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  /// The suggested style changes to this row, keyed by suggestion ID.
  core.Map<core.String, SuggestedTableRowStyle>? suggestedTableRowStyleChanges;

  /// The contents and style of each cell in this row.
  ///
  /// It is possible for a table to be non-rectangular, so some rows may have a
  /// different number of cells than other rows in the same table.
  core.List<TableCell>? tableCells;

  /// The style of the table row.
  TableRowStyle? tableRowStyle;

  TableRow();

  TableRow.fromJson(core.Map _json) {
    if (_json.containsKey('endIndex')) {
      endIndex = _json['endIndex'] as core.int;
    }
    if (_json.containsKey('startIndex')) {
      startIndex = _json['startIndex'] as core.int;
    }
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedTableRowStyleChanges')) {
      suggestedTableRowStyleChanges = (_json['suggestedTableRowStyleChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedTableRowStyle.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('tableCells')) {
      tableCells = (_json['tableCells'] as core.List)
          .map<TableCell>((value) =>
              TableCell.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('tableRowStyle')) {
      tableRowStyle = TableRowStyle.fromJson(
          _json['tableRowStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endIndex != null) 'endIndex': endIndex!,
        if (startIndex != null) 'startIndex': startIndex!,
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
        if (suggestedTableRowStyleChanges != null)
          'suggestedTableRowStyleChanges': suggestedTableRowStyleChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (tableCells != null)
          'tableCells': tableCells!.map((value) => value.toJson()).toList(),
        if (tableRowStyle != null) 'tableRowStyle': tableRowStyle!.toJson(),
      };
}

/// Styles that apply to a table row.
class TableRowStyle {
  /// The minimum height of the row.
  ///
  /// The row will be rendered in the Docs editor at a height equal to or
  /// greater than this value in order to show all the content in the row's
  /// cells.
  Dimension? minRowHeight;

  TableRowStyle();

  TableRowStyle.fromJson(core.Map _json) {
    if (_json.containsKey('minRowHeight')) {
      minRowHeight = Dimension.fromJson(
          _json['minRowHeight'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (minRowHeight != null) 'minRowHeight': minRowHeight!.toJson(),
      };
}

/// A mask that indicates which of the fields on the base TableRowStyle have
/// been changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class TableRowStyleSuggestionState {
  /// Indicates if there was a suggested change to min_row_height.
  core.bool? minRowHeightSuggested;

  TableRowStyleSuggestionState();

  TableRowStyleSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('minRowHeightSuggested')) {
      minRowHeightSuggested = _json['minRowHeightSuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (minRowHeightSuggested != null)
          'minRowHeightSuggested': minRowHeightSuggested!,
      };
}

/// Styles that apply to a table.
class TableStyle {
  /// The properties of each column.
  ///
  /// Note that in Docs, tables contain rows and rows contain cells, similar to
  /// HTML. So the properties for a row can be found on the row's
  /// table_row_style.
  core.List<TableColumnProperties>? tableColumnProperties;

  TableStyle();

  TableStyle.fromJson(core.Map _json) {
    if (_json.containsKey('tableColumnProperties')) {
      tableColumnProperties = (_json['tableColumnProperties'] as core.List)
          .map<TableColumnProperties>((value) => TableColumnProperties.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tableColumnProperties != null)
          'tableColumnProperties':
              tableColumnProperties!.map((value) => value.toJson()).toList(),
      };
}

/// A ParagraphElement that represents a run of text that all has the same
/// styling.
class TextRun {
  /// The text of this run.
  ///
  /// Any non-text elements in the run are replaced with the Unicode character
  /// U+E907.
  core.String? content;

  /// The suggested deletion IDs.
  ///
  /// If empty, then there are no suggested deletions of this content.
  core.List<core.String>? suggestedDeletionIds;

  /// The suggested insertion IDs.
  ///
  /// A TextRun may have multiple insertion IDs if it is a nested suggested
  /// change. If empty, then this is not a suggested insertion.
  core.List<core.String>? suggestedInsertionIds;

  /// The suggested text style changes to this run, keyed by suggestion ID.
  core.Map<core.String, SuggestedTextStyle>? suggestedTextStyleChanges;

  /// The text style of this run.
  TextStyle? textStyle;

  TextRun();

  TextRun.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('suggestedDeletionIds')) {
      suggestedDeletionIds = (_json['suggestedDeletionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedInsertionIds')) {
      suggestedInsertionIds = (_json['suggestedInsertionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('suggestedTextStyleChanges')) {
      suggestedTextStyleChanges = (_json['suggestedTextStyleChanges']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          SuggestedTextStyle.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (suggestedDeletionIds != null)
          'suggestedDeletionIds': suggestedDeletionIds!,
        if (suggestedInsertionIds != null)
          'suggestedInsertionIds': suggestedInsertionIds!,
        if (suggestedTextStyleChanges != null)
          'suggestedTextStyleChanges': suggestedTextStyleChanges!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
      };
}

/// Represents the styling that can be applied to text.
///
/// Inherited text styles are represented as unset fields in this message. A
/// text style's parent depends on where the text style is defined: * The
/// TextStyle of text in a Paragraph inherits from the paragraph's corresponding
/// named style type. * The TextStyle on a named style inherits from the normal
/// text named style. * The TextStyle of the normal text named style inherits
/// from the default text style in the Docs editor. * The TextStyle on a
/// Paragraph element that is contained in a table may inherit its text style
/// from the table style. If the text style does not inherit from a parent,
/// unsetting fields will revert the style to a value matching the defaults in
/// the Docs editor.
class TextStyle {
  /// The background color of the text.
  ///
  /// If set, the color is either an RGB color or transparent, depending on the
  /// `color` field.
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

  /// The size of the text's font.
  Dimension? fontSize;

  /// The foreground color of the text.
  ///
  /// If set, the color is either an RGB color or transparent, depending on the
  /// `color` field.
  OptionalColor? foregroundColor;

  /// Whether or not the text is italicized.
  core.bool? italic;

  /// The hyperlink destination of the text.
  ///
  /// If unset, there is no link. Links are not inherited from parent text.
  /// Changing the link in an update request causes some other changes to the
  /// text style of the range: * When setting a link, the text foreground color
  /// will be updated to the default link color and the text will be underlined.
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
  /// If an update request specifies values for both `weighted_font_family` and
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

/// A mask that indicates which of the fields on the base TextStyle have been
/// changed in this suggestion.
///
/// For any field set to true, there is a new suggested value.
class TextStyleSuggestionState {
  /// Indicates if there was a suggested change to background_color.
  core.bool? backgroundColorSuggested;

  /// Indicates if there was a suggested change to baseline_offset.
  core.bool? baselineOffsetSuggested;

  /// Indicates if there was a suggested change to bold.
  core.bool? boldSuggested;

  /// Indicates if there was a suggested change to font_size.
  core.bool? fontSizeSuggested;

  /// Indicates if there was a suggested change to foreground_color.
  core.bool? foregroundColorSuggested;

  /// Indicates if there was a suggested change to italic.
  core.bool? italicSuggested;

  /// Indicates if there was a suggested change to link.
  core.bool? linkSuggested;

  /// Indicates if there was a suggested change to small_caps.
  core.bool? smallCapsSuggested;

  /// Indicates if there was a suggested change to strikethrough.
  core.bool? strikethroughSuggested;

  /// Indicates if there was a suggested change to underline.
  core.bool? underlineSuggested;

  /// Indicates if there was a suggested change to weighted_font_family.
  core.bool? weightedFontFamilySuggested;

  TextStyleSuggestionState();

  TextStyleSuggestionState.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundColorSuggested')) {
      backgroundColorSuggested = _json['backgroundColorSuggested'] as core.bool;
    }
    if (_json.containsKey('baselineOffsetSuggested')) {
      baselineOffsetSuggested = _json['baselineOffsetSuggested'] as core.bool;
    }
    if (_json.containsKey('boldSuggested')) {
      boldSuggested = _json['boldSuggested'] as core.bool;
    }
    if (_json.containsKey('fontSizeSuggested')) {
      fontSizeSuggested = _json['fontSizeSuggested'] as core.bool;
    }
    if (_json.containsKey('foregroundColorSuggested')) {
      foregroundColorSuggested = _json['foregroundColorSuggested'] as core.bool;
    }
    if (_json.containsKey('italicSuggested')) {
      italicSuggested = _json['italicSuggested'] as core.bool;
    }
    if (_json.containsKey('linkSuggested')) {
      linkSuggested = _json['linkSuggested'] as core.bool;
    }
    if (_json.containsKey('smallCapsSuggested')) {
      smallCapsSuggested = _json['smallCapsSuggested'] as core.bool;
    }
    if (_json.containsKey('strikethroughSuggested')) {
      strikethroughSuggested = _json['strikethroughSuggested'] as core.bool;
    }
    if (_json.containsKey('underlineSuggested')) {
      underlineSuggested = _json['underlineSuggested'] as core.bool;
    }
    if (_json.containsKey('weightedFontFamilySuggested')) {
      weightedFontFamilySuggested =
          _json['weightedFontFamilySuggested'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundColorSuggested != null)
          'backgroundColorSuggested': backgroundColorSuggested!,
        if (baselineOffsetSuggested != null)
          'baselineOffsetSuggested': baselineOffsetSuggested!,
        if (boldSuggested != null) 'boldSuggested': boldSuggested!,
        if (fontSizeSuggested != null) 'fontSizeSuggested': fontSizeSuggested!,
        if (foregroundColorSuggested != null)
          'foregroundColorSuggested': foregroundColorSuggested!,
        if (italicSuggested != null) 'italicSuggested': italicSuggested!,
        if (linkSuggested != null) 'linkSuggested': linkSuggested!,
        if (smallCapsSuggested != null)
          'smallCapsSuggested': smallCapsSuggested!,
        if (strikethroughSuggested != null)
          'strikethroughSuggested': strikethroughSuggested!,
        if (underlineSuggested != null)
          'underlineSuggested': underlineSuggested!,
        if (weightedFontFamilySuggested != null)
          'weightedFontFamilySuggested': weightedFontFamilySuggested!,
      };
}

/// Unmerges cells in a Table.
class UnmergeTableCellsRequest {
  /// The table range specifying which cells of the table to unmerge.
  ///
  /// All merged cells in this range will be unmerged, and cells that are
  /// already unmerged will not be affected. If the range has no merged cells,
  /// the request will do nothing. If there is text in any of the merged cells,
  /// the text will remain in the "head" cell of the resulting block of unmerged
  /// cells. The "head" cell is the upper-left cell when the content direction
  /// is from left to right, and the upper-right otherwise.
  TableRange? tableRange;

  UnmergeTableCellsRequest();

  UnmergeTableCellsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('tableRange')) {
      tableRange = TableRange.fromJson(
          _json['tableRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tableRange != null) 'tableRange': tableRange!.toJson(),
      };
}

/// Updates the DocumentStyle.
class UpdateDocumentStyleRequest {
  /// The styles to set on the document.
  ///
  /// Certain document style changes may cause other changes in order to mirror
  /// the behavior of the Docs editor. See the documentation of DocumentStyle
  /// for more information.
  DocumentStyle? documentStyle;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `document_style` is implied
  /// and should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field. For example to update the background, set `fields` to
  /// `"background"`.
  core.String? fields;

  UpdateDocumentStyleRequest();

  UpdateDocumentStyleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('documentStyle')) {
      documentStyle = DocumentStyle.fromJson(
          _json['documentStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (documentStyle != null) 'documentStyle': documentStyle!.toJson(),
        if (fields != null) 'fields': fields!,
      };
}

/// Update the styling of all paragraphs that overlap with the given range.
class UpdateParagraphStyleRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `paragraph_style` is
  /// implied and should not be specified. For example, to update the paragraph
  /// style's alignment property, set `fields` to `"alignment"`. To reset a
  /// property to its default value, include its field name in the field mask
  /// but leave the field itself unset.
  core.String? fields;

  /// The styles to set on the paragraphs.
  ///
  /// Certain paragraph style changes may cause other changes in order to mirror
  /// the behavior of the Docs editor. See the documentation of ParagraphStyle
  /// for more information.
  ParagraphStyle? paragraphStyle;

  /// The range overlapping the paragraphs to style.
  Range? range;

  UpdateParagraphStyleRequest();

  UpdateParagraphStyleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('paragraphStyle')) {
      paragraphStyle = ParagraphStyle.fromJson(
          _json['paragraphStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('range')) {
      range =
          Range.fromJson(_json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (paragraphStyle != null) 'paragraphStyle': paragraphStyle!.toJson(),
        if (range != null) 'range': range!.toJson(),
      };
}

/// Updates the SectionStyle.
class UpdateSectionStyleRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `section_style` is implied
  /// and must not be specified. A single `"*"` can be used as short-hand for
  /// listing every field. For example to update the left margin, set `fields`
  /// to `"margin_left"`.
  core.String? fields;

  /// The range overlapping the sections to style.
  ///
  /// Because section breaks can only be inserted inside the body, the segment
  /// ID field must be empty.
  Range? range;

  /// The styles to be set on the section.
  ///
  /// Certain section style changes may cause other changes in order to mirror
  /// the behavior of the Docs editor. See the documentation of SectionStyle for
  /// more information.
  SectionStyle? sectionStyle;

  UpdateSectionStyleRequest();

  UpdateSectionStyleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('range')) {
      range =
          Range.fromJson(_json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sectionStyle')) {
      sectionStyle = SectionStyle.fromJson(
          _json['sectionStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (range != null) 'range': range!.toJson(),
        if (sectionStyle != null) 'sectionStyle': sectionStyle!.toJson(),
      };
}

/// Updates the style of a range of table cells.
class UpdateTableCellStyleRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `tableCellStyle` is implied
  /// and should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field. For example to update the table cell background
  /// color, set `fields` to `"backgroundColor"`. To reset a property to its
  /// default value, include its field name in the field mask but leave the
  /// field itself unset.
  core.String? fields;

  /// The style to set on the table cells.
  ///
  /// When updating borders, if a cell shares a border with an adjacent cell,
  /// the corresponding border property of the adjacent cell is updated as well.
  /// Borders that are merged and invisible are not updated. Since updating a
  /// border shared by adjacent cells in the same request can cause conflicting
  /// border updates, border updates are applied in the following order: -
  /// `border_right` - `border_left` - `border_bottom` - `border_top`
  TableCellStyle? tableCellStyle;

  /// The table range representing the subset of the table to which the updates
  /// are applied.
  TableRange? tableRange;

  /// The location where the table starts in the document.
  ///
  /// When specified, the updates are applied to all the cells in the table.
  Location? tableStartLocation;

  UpdateTableCellStyleRequest();

  UpdateTableCellStyleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('tableCellStyle')) {
      tableCellStyle = TableCellStyle.fromJson(
          _json['tableCellStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableRange')) {
      tableRange = TableRange.fromJson(
          _json['tableRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableStartLocation')) {
      tableStartLocation = Location.fromJson(
          _json['tableStartLocation'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (tableCellStyle != null) 'tableCellStyle': tableCellStyle!.toJson(),
        if (tableRange != null) 'tableRange': tableRange!.toJson(),
        if (tableStartLocation != null)
          'tableStartLocation': tableStartLocation!.toJson(),
      };
}

/// Updates the TableColumnProperties of columns in a table.
class UpdateTableColumnPropertiesRequest {
  /// The list of zero-based column indices whose property should be updated.
  ///
  /// If no indices are specified, all columns will be updated.
  core.List<core.int>? columnIndices;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `tableColumnProperties` is
  /// implied and should not be specified. A single `"*"` can be used as
  /// short-hand for listing every field. For example to update the column
  /// width, set `fields` to `"width"`.
  core.String? fields;

  /// The table column properties to update.
  ///
  /// If the value of `table_column_properties#width` is less than 5 points
  /// (5/72 inch), a 400 bad request error is returned.
  TableColumnProperties? tableColumnProperties;

  /// The location where the table starts in the document.
  Location? tableStartLocation;

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
    if (_json.containsKey('tableColumnProperties')) {
      tableColumnProperties = TableColumnProperties.fromJson(
          _json['tableColumnProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableStartLocation')) {
      tableStartLocation = Location.fromJson(
          _json['tableStartLocation'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnIndices != null) 'columnIndices': columnIndices!,
        if (fields != null) 'fields': fields!,
        if (tableColumnProperties != null)
          'tableColumnProperties': tableColumnProperties!.toJson(),
        if (tableStartLocation != null)
          'tableStartLocation': tableStartLocation!.toJson(),
      };
}

/// Updates the TableRowStyle of rows in a table.
class UpdateTableRowStyleRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `tableRowStyle` is implied
  /// and should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field. For example to update the minimum row height, set
  /// `fields` to `"min_row_height"`.
  core.String? fields;

  /// The list of zero-based row indices whose style should be updated.
  ///
  /// If no indices are specified, all rows will be updated.
  core.List<core.int>? rowIndices;

  /// The styles to be set on the rows.
  TableRowStyle? tableRowStyle;

  /// The location where the table starts in the document.
  Location? tableStartLocation;

  UpdateTableRowStyleRequest();

  UpdateTableRowStyleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('rowIndices')) {
      rowIndices = (_json['rowIndices'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('tableRowStyle')) {
      tableRowStyle = TableRowStyle.fromJson(
          _json['tableRowStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableStartLocation')) {
      tableStartLocation = Location.fromJson(
          _json['tableStartLocation'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (rowIndices != null) 'rowIndices': rowIndices!,
        if (tableRowStyle != null) 'tableRowStyle': tableRowStyle!.toJson(),
        if (tableStartLocation != null)
          'tableStartLocation': tableStartLocation!.toJson(),
      };
}

/// Update the styling of text.
class UpdateTextStyleRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `text_style` is implied and
  /// should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field. For example, to update the text style to bold, set
  /// `fields` to `"bold"`. To reset a property to its default value, include
  /// its field name in the field mask but leave the field itself unset.
  core.String? fields;

  /// The range of text to style.
  ///
  /// The range may be extended to include adjacent newlines. If the range fully
  /// contains a paragraph belonging to a list, the paragraph's bullet is also
  /// updated with the matching text style. Ranges cannot be inserted inside a
  /// relative UpdateTextStyleRequest.
  Range? range;

  /// The styles to set on the text.
  ///
  /// If the value for a particular style matches that of the parent, that style
  /// will be set to inherit. Certain text style changes may cause other changes
  /// in order to to mirror the behavior of the Docs editor. See the
  /// documentation of TextStyle for more information.
  TextStyle? textStyle;

  UpdateTextStyleRequest();

  UpdateTextStyleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('range')) {
      range =
          Range.fromJson(_json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textStyle')) {
      textStyle = TextStyle.fromJson(
          _json['textStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (range != null) 'range': range!.toJson(),
        if (textStyle != null) 'textStyle': textStyle!.toJson(),
      };
}

/// Represents a font family and weight of text.
class WeightedFontFamily {
  /// The font family of the text.
  ///
  /// The font family can be any font from the Font menu in Docs or from
  /// [Google Fonts](https://fonts.google.com/). If the font name is
  /// unrecognized, the text is rendered in `Arial`.
  core.String? fontFamily;

  /// The weight of the font.
  ///
  /// This field can have any value that is a multiple of `100` between `100`
  /// and `900`, inclusive. This range corresponds to the numerical values
  /// described in the CSS 2.1 Specification,
  /// [section 15.6](https://www.w3.org/TR/CSS21/fonts.html#font-boldness), with
  /// non-numerical values disallowed. The default value is `400` ("normal").
  /// The font weight makes up just one component of the rendered font weight.
  /// The rendered weight is determined by a combination of the `weight` and the
  /// text style's resolved `bold` value, after accounting for inheritance: * If
  /// the text is bold and the weight is less than `400`, the rendered weight is
  /// 400. * If the text is bold and the weight is greater than or equal to
  /// `400` but is less than `700`, the rendered weight is `700`. * If the
  /// weight is greater than or equal to `700`, the rendered weight is equal to
  /// the weight. * If the text is not bold, the rendered weight is equal to the
  /// weight.
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

/// Provides control over how write requests are executed.
class WriteControl {
  /// The revision ID of the document that the write request will be applied to.
  ///
  /// If this is not the latest revision of the document, the request will not
  /// be processed and will return a 400 bad request error. When a required
  /// revision ID is returned in a response, it indicates the revision ID of the
  /// document after the request was applied.
  core.String? requiredRevisionId;

  /// The target revision ID of the document that the write request will be
  /// applied to.
  ///
  /// If collaborator changes have occurred after the document was read using
  /// the API, the changes produced by this write request will be transformed
  /// against the collaborator changes. This results in a new revision of the
  /// document which incorporates both the changes in the request and the
  /// collaborator changes, and the Docs server will resolve conflicting
  /// changes. When using `target_revision_id`, the API client can be thought of
  /// as another collaborator of the document. The target revision ID may only
  /// be used to write to recent versions of a document. If the target revision
  /// is too far behind the latest revision, the request will not be processed
  /// and will return a 400 bad request error and the request should be retried
  /// after reading the latest version of the document. In most cases a
  /// `revision_id` will remain valid for use as a target revision for several
  /// minutes after it is read, but for frequently-edited documents this window
  /// may be shorter.
  core.String? targetRevisionId;

  WriteControl();

  WriteControl.fromJson(core.Map _json) {
    if (_json.containsKey('requiredRevisionId')) {
      requiredRevisionId = _json['requiredRevisionId'] as core.String;
    }
    if (_json.containsKey('targetRevisionId')) {
      targetRevisionId = _json['targetRevisionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requiredRevisionId != null)
          'requiredRevisionId': requiredRevisionId!,
        if (targetRevisionId != null) 'targetRevisionId': targetRevisionId!,
      };
}
