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

/// Google Sheets API - v4
///
/// Reads and writes Google Sheets.
///
/// For more information, see <https://developers.google.com/sheets/>
///
/// Create an instance of [SheetsApi] to access these resources:
///
/// - [SpreadsheetsResource]
///   - [SpreadsheetsDeveloperMetadataResource]
///   - [SpreadsheetsSheetsResource]
///   - [SpreadsheetsValuesResource]
library sheets.v4;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Reads and writes Google Sheets.
class SheetsApi {
  /// See, edit, create, and delete all of your Google Drive files
  static const driveScope = 'https://www.googleapis.com/auth/drive';

  /// See, edit, create, and delete only the specific Google Drive files you use
  /// with this app
  static const driveFileScope = 'https://www.googleapis.com/auth/drive.file';

  /// See and download all your Google Drive files
  static const driveReadonlyScope =
      'https://www.googleapis.com/auth/drive.readonly';

  /// See, edit, create, and delete your spreadsheets in Google Drive
  static const spreadsheetsScope =
      'https://www.googleapis.com/auth/spreadsheets';

  /// View your Google Spreadsheets
  static const spreadsheetsReadonlyScope =
      'https://www.googleapis.com/auth/spreadsheets.readonly';

  final commons.ApiRequester _requester;

  SpreadsheetsResource get spreadsheets => SpreadsheetsResource(_requester);

  SheetsApi(http.Client client,
      {core.String rootUrl = 'https://sheets.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class SpreadsheetsResource {
  final commons.ApiRequester _requester;

  SpreadsheetsDeveloperMetadataResource get developerMetadata =>
      SpreadsheetsDeveloperMetadataResource(_requester);
  SpreadsheetsSheetsResource get sheets =>
      SpreadsheetsSheetsResource(_requester);
  SpreadsheetsValuesResource get values =>
      SpreadsheetsValuesResource(_requester);

  SpreadsheetsResource(commons.ApiRequester client) : _requester = client;

  /// Applies one or more updates to the spreadsheet.
  ///
  /// Each request is validated before being applied. If any request is not
  /// valid then the entire request will fail and nothing will be applied. Some
  /// requests have replies to give you some information about how they are
  /// applied. The replies will mirror the requests. For example, if you applied
  /// 4 updates and the 3rd one had a reply, then the response will have 2 empty
  /// replies, the actual reply, and another empty reply, in that order. Due to
  /// the collaborative nature of spreadsheets, it is not guaranteed that the
  /// spreadsheet will reflect exactly your changes after this completes,
  /// however it is guaranteed that the updates in the request will be applied
  /// together atomically. Your changes may be altered with respect to
  /// collaborator changes. If there are no collaborators, the spreadsheet
  /// should reflect your changes.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The spreadsheet to apply the updates to.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchUpdateSpreadsheetResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchUpdateSpreadsheetResponse> batchUpdate(
    BatchUpdateSpreadsheetRequest request,
    core.String spreadsheetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        ':batchUpdate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BatchUpdateSpreadsheetResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a spreadsheet, returning the newly created spreadsheet.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Spreadsheet].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Spreadsheet> create(
    Spreadsheet request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v4/spreadsheets';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Spreadsheet.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the spreadsheet at the given ID.
  ///
  /// The caller must specify the spreadsheet ID. By default, data within grids
  /// will not be returned. You can include grid data one of two ways: * Specify
  /// a field mask listing your desired fields using the `fields` URL parameter
  /// in HTTP * Set the includeGridData URL parameter to true. If a field mask
  /// is set, the `includeGridData` parameter is ignored For large spreadsheets,
  /// it is recommended to retrieve only the specific fields of the spreadsheet
  /// that you want. To retrieve only subsets of the spreadsheet, use the ranges
  /// URL parameter. Multiple ranges can be specified. Limiting the range will
  /// return only the portions of the spreadsheet that intersect the requested
  /// ranges. Ranges are specified using A1 notation.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The spreadsheet to request.
  ///
  /// [includeGridData] - True if grid data should be returned. This parameter
  /// is ignored if a field mask was set in the request.
  ///
  /// [ranges] - The ranges to retrieve from the spreadsheet.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Spreadsheet].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Spreadsheet> get(
    core.String spreadsheetId, {
    core.bool? includeGridData,
    core.List<core.String>? ranges,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeGridData != null) 'includeGridData': ['${includeGridData}'],
      if (ranges != null) 'ranges': ranges,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' + commons.escapeVariable('$spreadsheetId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Spreadsheet.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the spreadsheet at the given ID.
  ///
  /// The caller must specify the spreadsheet ID. This method differs from
  /// GetSpreadsheet in that it allows selecting which subsets of spreadsheet
  /// data to return by specifying a dataFilters parameter. Multiple DataFilters
  /// can be specified. Specifying one or more data filters will return the
  /// portions of the spreadsheet that intersect ranges matched by any of the
  /// filters. By default, data within grids will not be returned. You can
  /// include grid data one of two ways: * Specify a field mask listing your
  /// desired fields using the `fields` URL parameter in HTTP * Set the
  /// includeGridData parameter to true. If a field mask is set, the
  /// `includeGridData` parameter is ignored For large spreadsheets, it is
  /// recommended to retrieve only the specific fields of the spreadsheet that
  /// you want.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The spreadsheet to request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Spreadsheet].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Spreadsheet> getByDataFilter(
    GetSpreadsheetByDataFilterRequest request,
    core.String spreadsheetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        ':getByDataFilter';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Spreadsheet.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class SpreadsheetsDeveloperMetadataResource {
  final commons.ApiRequester _requester;

  SpreadsheetsDeveloperMetadataResource(commons.ApiRequester client)
      : _requester = client;

  /// Returns the developer metadata with the specified ID.
  ///
  /// The caller must specify the spreadsheet ID and the developer metadata's
  /// unique metadataId.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet to retrieve metadata from.
  ///
  /// [metadataId] - The ID of the developer metadata to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DeveloperMetadata].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DeveloperMetadata> get(
    core.String spreadsheetId,
    core.int metadataId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/developerMetadata/' +
        commons.escapeVariable('$metadataId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DeveloperMetadata.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns all developer metadata matching the specified DataFilter.
  ///
  /// If the provided DataFilter represents a DeveloperMetadataLookup object,
  /// this will return all DeveloperMetadata entries selected by it. If the
  /// DataFilter represents a location in a spreadsheet, this will return all
  /// developer metadata associated with locations intersecting that region.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet to retrieve metadata from.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchDeveloperMetadataResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchDeveloperMetadataResponse> search(
    SearchDeveloperMetadataRequest request,
    core.String spreadsheetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/developerMetadata:search';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SearchDeveloperMetadataResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class SpreadsheetsSheetsResource {
  final commons.ApiRequester _requester;

  SpreadsheetsSheetsResource(commons.ApiRequester client) : _requester = client;

  /// Copies a single sheet from a spreadsheet to another spreadsheet.
  ///
  /// Returns the properties of the newly created sheet.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet containing the sheet to copy.
  ///
  /// [sheetId] - The ID of the sheet to copy.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SheetProperties].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SheetProperties> copyTo(
    CopySheetToAnotherSpreadsheetRequest request,
    core.String spreadsheetId,
    core.int sheetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/sheets/' +
        commons.escapeVariable('$sheetId') +
        ':copyTo';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SheetProperties.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class SpreadsheetsValuesResource {
  final commons.ApiRequester _requester;

  SpreadsheetsValuesResource(commons.ApiRequester client) : _requester = client;

  /// Appends values to a spreadsheet.
  ///
  /// The input range is used to search for existing data and find a "table"
  /// within that range. Values will be appended to the next row of the table,
  /// starting with the first column of the table. See the
  /// \[guide\](/sheets/api/guides/values#appending_values) and \[sample
  /// code\](/sheets/api/samples/writing#append_values) for specific details of
  /// how tables are detected and data is appended. The caller must specify the
  /// spreadsheet ID, range, and a valueInputOption. The `valueInputOption` only
  /// controls how the input data will be added to the sheet (column-wise or
  /// row-wise), it does not influence what cell the data starts being written
  /// to.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet to update.
  ///
  /// [range] - The A1 notation of a range to search for a logical table of
  /// data. Values are appended after the last row of the table.
  ///
  /// [includeValuesInResponse] - Determines if the update response should
  /// include the values of the cells that were appended. By default, responses
  /// do not include the updated values.
  ///
  /// [insertDataOption] - How the input data should be inserted.
  /// Possible string values are:
  /// - "OVERWRITE" : The new data overwrites existing data in the areas it is
  /// written. (Note: adding data to the end of the sheet will still insert new
  /// rows or columns so the data can be written.)
  /// - "INSERT_ROWS" : Rows are inserted for the new data.
  ///
  /// [responseDateTimeRenderOption] - Determines how dates, times, and
  /// durations in the response should be rendered. This is ignored if
  /// response_value_render_option is FORMATTED_VALUE. The default dateTime
  /// render option is SERIAL_NUMBER.
  /// Possible string values are:
  /// - "SERIAL_NUMBER" : Instructs date, time, datetime, and duration fields to
  /// be output as doubles in "serial number" format, as popularized by Lotus
  /// 1-2-3. The whole number portion of the value (left of the decimal) counts
  /// the days since December 30th 1899. The fractional portion (right of the
  /// decimal) counts the time as a fraction of the day. For example, January
  /// 1st 1900 at noon would be 2.5, 2 because it's 2 days after December 30st
  /// 1899, and .5 because noon is half a day. February 1st 1900 at 3pm would be
  /// 33.625. This correctly treats the year 1900 as not a leap year.
  /// - "FORMATTED_STRING" : Instructs date, time, datetime, and duration fields
  /// to be output as strings in their given number format (which is dependent
  /// on the spreadsheet locale).
  ///
  /// [responseValueRenderOption] - Determines how values in the response should
  /// be rendered. The default render option is FORMATTED_VALUE.
  /// Possible string values are:
  /// - "FORMATTED_VALUE" : Values will be calculated & formatted in the reply
  /// according to the cell's formatting. Formatting is based on the
  /// spreadsheet's locale, not the requesting user's locale. For example, if
  /// `A1` is `1.23` and `A2` is `=A1` and formatted as currency, then `A2`
  /// would return `"$1.23"`.
  /// - "UNFORMATTED_VALUE" : Values will be calculated, but not formatted in
  /// the reply. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then `A2` would return the number `1.23`.
  /// - "FORMULA" : Values will not be calculated. The reply will include the
  /// formulas. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then A2 would return `"=A1"`.
  ///
  /// [valueInputOption] - How the input data should be interpreted.
  /// Possible string values are:
  /// - "INPUT_VALUE_OPTION_UNSPECIFIED" : Default input value. This value must
  /// not be used.
  /// - "RAW" : The values the user has entered will not be parsed and will be
  /// stored as-is.
  /// - "USER_ENTERED" : The values will be parsed as if the user typed them
  /// into the UI. Numbers will stay as numbers, but strings may be converted to
  /// numbers, dates, etc. following the same rules that are applied when
  /// entering text into a cell via the Google Sheets UI.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AppendValuesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AppendValuesResponse> append(
    ValueRange request,
    core.String spreadsheetId,
    core.String range, {
    core.bool? includeValuesInResponse,
    core.String? insertDataOption,
    core.String? responseDateTimeRenderOption,
    core.String? responseValueRenderOption,
    core.String? valueInputOption,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeValuesInResponse != null)
        'includeValuesInResponse': ['${includeValuesInResponse}'],
      if (insertDataOption != null) 'insertDataOption': [insertDataOption],
      if (responseDateTimeRenderOption != null)
        'responseDateTimeRenderOption': [responseDateTimeRenderOption],
      if (responseValueRenderOption != null)
        'responseValueRenderOption': [responseValueRenderOption],
      if (valueInputOption != null) 'valueInputOption': [valueInputOption],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/values/' +
        commons.escapeVariable('$range') +
        ':append';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AppendValuesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Clears one or more ranges of values from a spreadsheet.
  ///
  /// The caller must specify the spreadsheet ID and one or more ranges. Only
  /// values are cleared -- all other properties of the cell (such as
  /// formatting, data validation, etc..) are kept.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchClearValuesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchClearValuesResponse> batchClear(
    BatchClearValuesRequest request,
    core.String spreadsheetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/values:batchClear';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BatchClearValuesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Clears one or more ranges of values from a spreadsheet.
  ///
  /// The caller must specify the spreadsheet ID and one or more DataFilters.
  /// Ranges matching any of the specified data filters will be cleared. Only
  /// values are cleared -- all other properties of the cell (such as
  /// formatting, data validation, etc..) are kept.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchClearValuesByDataFilterResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchClearValuesByDataFilterResponse> batchClearByDataFilter(
    BatchClearValuesByDataFilterRequest request,
    core.String spreadsheetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/values:batchClearByDataFilter';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BatchClearValuesByDataFilterResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns one or more ranges of values from a spreadsheet.
  ///
  /// The caller must specify the spreadsheet ID and one or more ranges.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet to retrieve data from.
  ///
  /// [dateTimeRenderOption] - How dates, times, and durations should be
  /// represented in the output. This is ignored if value_render_option is
  /// FORMATTED_VALUE. The default dateTime render option is SERIAL_NUMBER.
  /// Possible string values are:
  /// - "SERIAL_NUMBER" : Instructs date, time, datetime, and duration fields to
  /// be output as doubles in "serial number" format, as popularized by Lotus
  /// 1-2-3. The whole number portion of the value (left of the decimal) counts
  /// the days since December 30th 1899. The fractional portion (right of the
  /// decimal) counts the time as a fraction of the day. For example, January
  /// 1st 1900 at noon would be 2.5, 2 because it's 2 days after December 30st
  /// 1899, and .5 because noon is half a day. February 1st 1900 at 3pm would be
  /// 33.625. This correctly treats the year 1900 as not a leap year.
  /// - "FORMATTED_STRING" : Instructs date, time, datetime, and duration fields
  /// to be output as strings in their given number format (which is dependent
  /// on the spreadsheet locale).
  ///
  /// [majorDimension] - The major dimension that results should use. For
  /// example, if the spreadsheet data is: `A1=1,B1=2,A2=3,B2=4`, then
  /// requesting `range=A1:B2,majorDimension=ROWS` returns `[[1,2],[3,4]]`,
  /// whereas requesting `range=A1:B2,majorDimension=COLUMNS` returns
  /// `[[1,3],[2,4]]`.
  /// Possible string values are:
  /// - "DIMENSION_UNSPECIFIED" : The default value, do not use.
  /// - "ROWS" : Operates on the rows of a sheet.
  /// - "COLUMNS" : Operates on the columns of a sheet.
  ///
  /// [ranges] - The A1 notation or R1C1 notation of the range to retrieve
  /// values from.
  ///
  /// [valueRenderOption] - How values should be represented in the output. The
  /// default render option is ValueRenderOption.FORMATTED_VALUE.
  /// Possible string values are:
  /// - "FORMATTED_VALUE" : Values will be calculated & formatted in the reply
  /// according to the cell's formatting. Formatting is based on the
  /// spreadsheet's locale, not the requesting user's locale. For example, if
  /// `A1` is `1.23` and `A2` is `=A1` and formatted as currency, then `A2`
  /// would return `"$1.23"`.
  /// - "UNFORMATTED_VALUE" : Values will be calculated, but not formatted in
  /// the reply. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then `A2` would return the number `1.23`.
  /// - "FORMULA" : Values will not be calculated. The reply will include the
  /// formulas. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then A2 would return `"=A1"`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchGetValuesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchGetValuesResponse> batchGet(
    core.String spreadsheetId, {
    core.String? dateTimeRenderOption,
    core.String? majorDimension,
    core.List<core.String>? ranges,
    core.String? valueRenderOption,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (dateTimeRenderOption != null)
        'dateTimeRenderOption': [dateTimeRenderOption],
      if (majorDimension != null) 'majorDimension': [majorDimension],
      if (ranges != null) 'ranges': ranges,
      if (valueRenderOption != null) 'valueRenderOption': [valueRenderOption],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/values:batchGet';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BatchGetValuesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns one or more ranges of values that match the specified data
  /// filters.
  ///
  /// The caller must specify the spreadsheet ID and one or more DataFilters.
  /// Ranges that match any of the data filters in the request will be returned.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet to retrieve data from.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchGetValuesByDataFilterResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchGetValuesByDataFilterResponse> batchGetByDataFilter(
    BatchGetValuesByDataFilterRequest request,
    core.String spreadsheetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/values:batchGetByDataFilter';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BatchGetValuesByDataFilterResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets values in one or more ranges of a spreadsheet.
  ///
  /// The caller must specify the spreadsheet ID, a valueInputOption, and one or
  /// more ValueRanges.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchUpdateValuesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchUpdateValuesResponse> batchUpdate(
    BatchUpdateValuesRequest request,
    core.String spreadsheetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/values:batchUpdate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BatchUpdateValuesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets values in one or more ranges of a spreadsheet.
  ///
  /// The caller must specify the spreadsheet ID, a valueInputOption, and one or
  /// more DataFilterValueRanges.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchUpdateValuesByDataFilterResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchUpdateValuesByDataFilterResponse> batchUpdateByDataFilter(
    BatchUpdateValuesByDataFilterRequest request,
    core.String spreadsheetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/values:batchUpdateByDataFilter';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BatchUpdateValuesByDataFilterResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Clears values from a spreadsheet.
  ///
  /// The caller must specify the spreadsheet ID and range. Only values are
  /// cleared -- all other properties of the cell (such as formatting, data
  /// validation, etc..) are kept.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet to update.
  ///
  /// [range] - The A1 notation or R1C1 notation of the values to clear.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ClearValuesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ClearValuesResponse> clear(
    ClearValuesRequest request,
    core.String spreadsheetId,
    core.String range, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/values/' +
        commons.escapeVariable('$range') +
        ':clear';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ClearValuesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns a range of values from a spreadsheet.
  ///
  /// The caller must specify the spreadsheet ID and a range.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet to retrieve data from.
  ///
  /// [range] - The A1 notation or R1C1 notation of the range to retrieve values
  /// from.
  ///
  /// [dateTimeRenderOption] - How dates, times, and durations should be
  /// represented in the output. This is ignored if value_render_option is
  /// FORMATTED_VALUE. The default dateTime render option is SERIAL_NUMBER.
  /// Possible string values are:
  /// - "SERIAL_NUMBER" : Instructs date, time, datetime, and duration fields to
  /// be output as doubles in "serial number" format, as popularized by Lotus
  /// 1-2-3. The whole number portion of the value (left of the decimal) counts
  /// the days since December 30th 1899. The fractional portion (right of the
  /// decimal) counts the time as a fraction of the day. For example, January
  /// 1st 1900 at noon would be 2.5, 2 because it's 2 days after December 30st
  /// 1899, and .5 because noon is half a day. February 1st 1900 at 3pm would be
  /// 33.625. This correctly treats the year 1900 as not a leap year.
  /// - "FORMATTED_STRING" : Instructs date, time, datetime, and duration fields
  /// to be output as strings in their given number format (which is dependent
  /// on the spreadsheet locale).
  ///
  /// [majorDimension] - The major dimension that results should use. For
  /// example, if the spreadsheet data is: `A1=1,B1=2,A2=3,B2=4`, then
  /// requesting `range=A1:B2,majorDimension=ROWS` returns `[[1,2],[3,4]]`,
  /// whereas requesting `range=A1:B2,majorDimension=COLUMNS` returns
  /// `[[1,3],[2,4]]`.
  /// Possible string values are:
  /// - "DIMENSION_UNSPECIFIED" : The default value, do not use.
  /// - "ROWS" : Operates on the rows of a sheet.
  /// - "COLUMNS" : Operates on the columns of a sheet.
  ///
  /// [valueRenderOption] - How values should be represented in the output. The
  /// default render option is FORMATTED_VALUE.
  /// Possible string values are:
  /// - "FORMATTED_VALUE" : Values will be calculated & formatted in the reply
  /// according to the cell's formatting. Formatting is based on the
  /// spreadsheet's locale, not the requesting user's locale. For example, if
  /// `A1` is `1.23` and `A2` is `=A1` and formatted as currency, then `A2`
  /// would return `"$1.23"`.
  /// - "UNFORMATTED_VALUE" : Values will be calculated, but not formatted in
  /// the reply. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then `A2` would return the number `1.23`.
  /// - "FORMULA" : Values will not be calculated. The reply will include the
  /// formulas. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then A2 would return `"=A1"`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ValueRange].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ValueRange> get(
    core.String spreadsheetId,
    core.String range, {
    core.String? dateTimeRenderOption,
    core.String? majorDimension,
    core.String? valueRenderOption,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (dateTimeRenderOption != null)
        'dateTimeRenderOption': [dateTimeRenderOption],
      if (majorDimension != null) 'majorDimension': [majorDimension],
      if (valueRenderOption != null) 'valueRenderOption': [valueRenderOption],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/values/' +
        commons.escapeVariable('$range');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ValueRange.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets values in a range of a spreadsheet.
  ///
  /// The caller must specify the spreadsheet ID, range, and a valueInputOption.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [spreadsheetId] - The ID of the spreadsheet to update.
  ///
  /// [range] - The A1 notation of the values to update.
  ///
  /// [includeValuesInResponse] - Determines if the update response should
  /// include the values of the cells that were updated. By default, responses
  /// do not include the updated values. If the range to write was larger than
  /// the range actually written, the response includes all values in the
  /// requested range (excluding trailing empty rows and columns).
  ///
  /// [responseDateTimeRenderOption] - Determines how dates, times, and
  /// durations in the response should be rendered. This is ignored if
  /// response_value_render_option is FORMATTED_VALUE. The default dateTime
  /// render option is SERIAL_NUMBER.
  /// Possible string values are:
  /// - "SERIAL_NUMBER" : Instructs date, time, datetime, and duration fields to
  /// be output as doubles in "serial number" format, as popularized by Lotus
  /// 1-2-3. The whole number portion of the value (left of the decimal) counts
  /// the days since December 30th 1899. The fractional portion (right of the
  /// decimal) counts the time as a fraction of the day. For example, January
  /// 1st 1900 at noon would be 2.5, 2 because it's 2 days after December 30st
  /// 1899, and .5 because noon is half a day. February 1st 1900 at 3pm would be
  /// 33.625. This correctly treats the year 1900 as not a leap year.
  /// - "FORMATTED_STRING" : Instructs date, time, datetime, and duration fields
  /// to be output as strings in their given number format (which is dependent
  /// on the spreadsheet locale).
  ///
  /// [responseValueRenderOption] - Determines how values in the response should
  /// be rendered. The default render option is FORMATTED_VALUE.
  /// Possible string values are:
  /// - "FORMATTED_VALUE" : Values will be calculated & formatted in the reply
  /// according to the cell's formatting. Formatting is based on the
  /// spreadsheet's locale, not the requesting user's locale. For example, if
  /// `A1` is `1.23` and `A2` is `=A1` and formatted as currency, then `A2`
  /// would return `"$1.23"`.
  /// - "UNFORMATTED_VALUE" : Values will be calculated, but not formatted in
  /// the reply. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then `A2` would return the number `1.23`.
  /// - "FORMULA" : Values will not be calculated. The reply will include the
  /// formulas. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then A2 would return `"=A1"`.
  ///
  /// [valueInputOption] - How the input data should be interpreted.
  /// Possible string values are:
  /// - "INPUT_VALUE_OPTION_UNSPECIFIED" : Default input value. This value must
  /// not be used.
  /// - "RAW" : The values the user has entered will not be parsed and will be
  /// stored as-is.
  /// - "USER_ENTERED" : The values will be parsed as if the user typed them
  /// into the UI. Numbers will stay as numbers, but strings may be converted to
  /// numbers, dates, etc. following the same rules that are applied when
  /// entering text into a cell via the Google Sheets UI.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UpdateValuesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UpdateValuesResponse> update(
    ValueRange request,
    core.String spreadsheetId,
    core.String range, {
    core.bool? includeValuesInResponse,
    core.String? responseDateTimeRenderOption,
    core.String? responseValueRenderOption,
    core.String? valueInputOption,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeValuesInResponse != null)
        'includeValuesInResponse': ['${includeValuesInResponse}'],
      if (responseDateTimeRenderOption != null)
        'responseDateTimeRenderOption': [responseDateTimeRenderOption],
      if (responseValueRenderOption != null)
        'responseValueRenderOption': [responseValueRenderOption],
      if (valueInputOption != null) 'valueInputOption': [valueInputOption],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v4/spreadsheets/' +
        commons.escapeVariable('$spreadsheetId') +
        '/values/' +
        commons.escapeVariable('$range');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return UpdateValuesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Adds a new banded range to the spreadsheet.
class AddBandingRequest {
  /// The banded range to add.
  ///
  /// The bandedRangeId field is optional; if one is not set, an id will be
  /// randomly generated. (It is an error to specify the ID of a range that
  /// already exists.)
  BandedRange? bandedRange;

  AddBandingRequest();

  AddBandingRequest.fromJson(core.Map _json) {
    if (_json.containsKey('bandedRange')) {
      bandedRange = BandedRange.fromJson(
          _json['bandedRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bandedRange != null) 'bandedRange': bandedRange!.toJson(),
      };
}

/// The result of adding a banded range.
class AddBandingResponse {
  /// The banded range that was added.
  BandedRange? bandedRange;

  AddBandingResponse();

  AddBandingResponse.fromJson(core.Map _json) {
    if (_json.containsKey('bandedRange')) {
      bandedRange = BandedRange.fromJson(
          _json['bandedRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bandedRange != null) 'bandedRange': bandedRange!.toJson(),
      };
}

/// Adds a chart to a sheet in the spreadsheet.
class AddChartRequest {
  /// The chart that should be added to the spreadsheet, including the position
  /// where it should be placed.
  ///
  /// The chartId field is optional; if one is not set, an id will be randomly
  /// generated. (It is an error to specify the ID of an embedded object that
  /// already exists.)
  EmbeddedChart? chart;

  AddChartRequest();

  AddChartRequest.fromJson(core.Map _json) {
    if (_json.containsKey('chart')) {
      chart = EmbeddedChart.fromJson(
          _json['chart'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chart != null) 'chart': chart!.toJson(),
      };
}

/// The result of adding a chart to a spreadsheet.
class AddChartResponse {
  /// The newly added chart.
  EmbeddedChart? chart;

  AddChartResponse();

  AddChartResponse.fromJson(core.Map _json) {
    if (_json.containsKey('chart')) {
      chart = EmbeddedChart.fromJson(
          _json['chart'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chart != null) 'chart': chart!.toJson(),
      };
}

/// Adds a new conditional format rule at the given index.
///
/// All subsequent rules' indexes are incremented.
class AddConditionalFormatRuleRequest {
  /// The zero-based index where the rule should be inserted.
  core.int? index;

  /// The rule to add.
  ConditionalFormatRule? rule;

  AddConditionalFormatRuleRequest();

  AddConditionalFormatRuleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('index')) {
      index = _json['index'] as core.int;
    }
    if (_json.containsKey('rule')) {
      rule = ConditionalFormatRule.fromJson(
          _json['rule'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (index != null) 'index': index!,
        if (rule != null) 'rule': rule!.toJson(),
      };
}

/// Adds a data source.
///
/// After the data source is added successfully, an associated DATA_SOURCE sheet
/// is created and an execution is triggered to refresh the sheet to read data
/// from the data source. The request requires an additional `bigquery.readonly`
/// OAuth scope.
class AddDataSourceRequest {
  /// The data source to add.
  DataSource? dataSource;

  AddDataSourceRequest();

  AddDataSourceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataSource')) {
      dataSource = DataSource.fromJson(
          _json['dataSource'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSource != null) 'dataSource': dataSource!.toJson(),
      };
}

/// The result of adding a data source.
class AddDataSourceResponse {
  /// The data execution status.
  DataExecutionStatus? dataExecutionStatus;

  /// The data source that was created.
  DataSource? dataSource;

  AddDataSourceResponse();

  AddDataSourceResponse.fromJson(core.Map _json) {
    if (_json.containsKey('dataExecutionStatus')) {
      dataExecutionStatus = DataExecutionStatus.fromJson(
          _json['dataExecutionStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataSource')) {
      dataSource = DataSource.fromJson(
          _json['dataSource'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataExecutionStatus != null)
          'dataExecutionStatus': dataExecutionStatus!.toJson(),
        if (dataSource != null) 'dataSource': dataSource!.toJson(),
      };
}

/// Creates a group over the specified range.
///
/// If the requested range is a superset of the range of an existing group G,
/// then the depth of G is incremented and this new group G' has the depth of
/// that group. For example, a group \[C:D, depth 1\] + \[B:E\] results in
/// groups \[B:E, depth 1\] and \[C:D, depth 2\]. If the requested range is a
/// subset of the range of an existing group G, then the depth of the new group
/// G' becomes one greater than the depth of G. For example, a group \[B:E,
/// depth 1\] + \[C:D\] results in groups \[B:E, depth 1\] and \[C:D, depth 2\].
/// If the requested range starts before and ends within, or starts within and
/// ends after, the range of an existing group G, then the range of the existing
/// group G becomes the union of the ranges, and the new group G' has depth one
/// greater than the depth of G and range as the intersection of the ranges. For
/// example, a group \[B:D, depth 1\] + \[C:E\] results in groups \[B:E, depth
/// 1\] and \[C:D, depth 2\].
class AddDimensionGroupRequest {
  /// The range over which to create a group.
  DimensionRange? range;

  AddDimensionGroupRequest();

  AddDimensionGroupRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range = DimensionRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
      };
}

/// The result of adding a group.
class AddDimensionGroupResponse {
  /// All groups of a dimension after adding a group to that dimension.
  core.List<DimensionGroup>? dimensionGroups;

  AddDimensionGroupResponse();

  AddDimensionGroupResponse.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionGroups')) {
      dimensionGroups = (_json['dimensionGroups'] as core.List)
          .map<DimensionGroup>((value) => DimensionGroup.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionGroups != null)
          'dimensionGroups':
              dimensionGroups!.map((value) => value.toJson()).toList(),
      };
}

/// Adds a filter view.
class AddFilterViewRequest {
  /// The filter to add.
  ///
  /// The filterViewId field is optional; if one is not set, an id will be
  /// randomly generated. (It is an error to specify the ID of a filter that
  /// already exists.)
  FilterView? filter;

  AddFilterViewRequest();

  AddFilterViewRequest.fromJson(core.Map _json) {
    if (_json.containsKey('filter')) {
      filter = FilterView.fromJson(
          _json['filter'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filter != null) 'filter': filter!.toJson(),
      };
}

/// The result of adding a filter view.
class AddFilterViewResponse {
  /// The newly added filter view.
  FilterView? filter;

  AddFilterViewResponse();

  AddFilterViewResponse.fromJson(core.Map _json) {
    if (_json.containsKey('filter')) {
      filter = FilterView.fromJson(
          _json['filter'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filter != null) 'filter': filter!.toJson(),
      };
}

/// Adds a named range to the spreadsheet.
class AddNamedRangeRequest {
  /// The named range to add.
  ///
  /// The namedRangeId field is optional; if one is not set, an id will be
  /// randomly generated. (It is an error to specify the ID of a range that
  /// already exists.)
  NamedRange? namedRange;

  AddNamedRangeRequest();

  AddNamedRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('namedRange')) {
      namedRange = NamedRange.fromJson(
          _json['namedRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (namedRange != null) 'namedRange': namedRange!.toJson(),
      };
}

/// The result of adding a named range.
class AddNamedRangeResponse {
  /// The named range to add.
  NamedRange? namedRange;

  AddNamedRangeResponse();

  AddNamedRangeResponse.fromJson(core.Map _json) {
    if (_json.containsKey('namedRange')) {
      namedRange = NamedRange.fromJson(
          _json['namedRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (namedRange != null) 'namedRange': namedRange!.toJson(),
      };
}

/// Adds a new protected range.
class AddProtectedRangeRequest {
  /// The protected range to be added.
  ///
  /// The protectedRangeId field is optional; if one is not set, an id will be
  /// randomly generated. (It is an error to specify the ID of a range that
  /// already exists.)
  ProtectedRange? protectedRange;

  AddProtectedRangeRequest();

  AddProtectedRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('protectedRange')) {
      protectedRange = ProtectedRange.fromJson(
          _json['protectedRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (protectedRange != null) 'protectedRange': protectedRange!.toJson(),
      };
}

/// The result of adding a new protected range.
class AddProtectedRangeResponse {
  /// The newly added protected range.
  ProtectedRange? protectedRange;

  AddProtectedRangeResponse();

  AddProtectedRangeResponse.fromJson(core.Map _json) {
    if (_json.containsKey('protectedRange')) {
      protectedRange = ProtectedRange.fromJson(
          _json['protectedRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (protectedRange != null) 'protectedRange': protectedRange!.toJson(),
      };
}

/// Adds a new sheet.
///
/// When a sheet is added at a given index, all subsequent sheets' indexes are
/// incremented. To add an object sheet, use AddChartRequest instead and specify
/// EmbeddedObjectPosition.sheetId or EmbeddedObjectPosition.newSheet.
class AddSheetRequest {
  /// The properties the new sheet should have.
  ///
  /// All properties are optional. The sheetId field is optional; if one is not
  /// set, an id will be randomly generated. (It is an error to specify the ID
  /// of a sheet that already exists.)
  SheetProperties? properties;

  AddSheetRequest();

  AddSheetRequest.fromJson(core.Map _json) {
    if (_json.containsKey('properties')) {
      properties = SheetProperties.fromJson(
          _json['properties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (properties != null) 'properties': properties!.toJson(),
      };
}

/// The result of adding a sheet.
class AddSheetResponse {
  /// The properties of the newly added sheet.
  SheetProperties? properties;

  AddSheetResponse();

  AddSheetResponse.fromJson(core.Map _json) {
    if (_json.containsKey('properties')) {
      properties = SheetProperties.fromJson(
          _json['properties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (properties != null) 'properties': properties!.toJson(),
      };
}

/// Adds a slicer to a sheet in the spreadsheet.
class AddSlicerRequest {
  /// The slicer that should be added to the spreadsheet, including the position
  /// where it should be placed.
  ///
  /// The slicerId field is optional; if one is not set, an id will be randomly
  /// generated. (It is an error to specify the ID of a slicer that already
  /// exists.)
  Slicer? slicer;

  AddSlicerRequest();

  AddSlicerRequest.fromJson(core.Map _json) {
    if (_json.containsKey('slicer')) {
      slicer = Slicer.fromJson(
          _json['slicer'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (slicer != null) 'slicer': slicer!.toJson(),
      };
}

/// The result of adding a slicer to a spreadsheet.
class AddSlicerResponse {
  /// The newly added slicer.
  Slicer? slicer;

  AddSlicerResponse();

  AddSlicerResponse.fromJson(core.Map _json) {
    if (_json.containsKey('slicer')) {
      slicer = Slicer.fromJson(
          _json['slicer'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (slicer != null) 'slicer': slicer!.toJson(),
      };
}

/// Adds new cells after the last row with data in a sheet, inserting new rows
/// into the sheet if necessary.
class AppendCellsRequest {
  /// The fields of CellData that should be updated.
  ///
  /// At least one field must be specified. The root is the CellData;
  /// 'row.values.' should not be specified. A single `"*"` can be used as
  /// short-hand for listing every field.
  core.String? fields;

  /// The data to append.
  core.List<RowData>? rows;

  /// The sheet ID to append the data to.
  core.int? sheetId;

  AppendCellsRequest();

  AppendCellsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<RowData>((value) =>
              RowData.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
        if (sheetId != null) 'sheetId': sheetId!,
      };
}

/// Appends rows or columns to the end of a sheet.
class AppendDimensionRequest {
  /// Whether rows or columns should be appended.
  /// Possible string values are:
  /// - "DIMENSION_UNSPECIFIED" : The default value, do not use.
  /// - "ROWS" : Operates on the rows of a sheet.
  /// - "COLUMNS" : Operates on the columns of a sheet.
  core.String? dimension;

  /// The number of rows or columns to append.
  core.int? length;

  /// The sheet to append rows or columns to.
  core.int? sheetId;

  AppendDimensionRequest();

  AppendDimensionRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dimension')) {
      dimension = _json['dimension'] as core.String;
    }
    if (_json.containsKey('length')) {
      length = _json['length'] as core.int;
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimension != null) 'dimension': dimension!,
        if (length != null) 'length': length!,
        if (sheetId != null) 'sheetId': sheetId!,
      };
}

/// The response when updating a range of values in a spreadsheet.
class AppendValuesResponse {
  /// The spreadsheet the updates were applied to.
  core.String? spreadsheetId;

  /// The range (in A1 notation) of the table that values are being appended to
  /// (before the values were appended).
  ///
  /// Empty if no table was found.
  core.String? tableRange;

  /// Information about the updates that were applied.
  UpdateValuesResponse? updates;

  AppendValuesResponse();

  AppendValuesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
    if (_json.containsKey('tableRange')) {
      tableRange = _json['tableRange'] as core.String;
    }
    if (_json.containsKey('updates')) {
      updates = UpdateValuesResponse.fromJson(
          _json['updates'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
        if (tableRange != null) 'tableRange': tableRange!,
        if (updates != null) 'updates': updates!.toJson(),
      };
}

/// Fills in more data based on existing data.
class AutoFillRequest {
  /// The range to autofill.
  ///
  /// This will examine the range and detect the location that has data and
  /// automatically fill that data in to the rest of the range.
  GridRange? range;

  /// The source and destination areas to autofill.
  ///
  /// This explicitly lists the source of the autofill and where to extend that
  /// data.
  SourceAndDestination? sourceAndDestination;

  /// True if we should generate data with the "alternate" series.
  ///
  /// This differs based on the type and amount of source data.
  core.bool? useAlternateSeries;

  AutoFillRequest();

  AutoFillRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sourceAndDestination')) {
      sourceAndDestination = SourceAndDestination.fromJson(
          _json['sourceAndDestination'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('useAlternateSeries')) {
      useAlternateSeries = _json['useAlternateSeries'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
        if (sourceAndDestination != null)
          'sourceAndDestination': sourceAndDestination!.toJson(),
        if (useAlternateSeries != null)
          'useAlternateSeries': useAlternateSeries!,
      };
}

/// Automatically resizes one or more dimensions based on the contents of the
/// cells in that dimension.
class AutoResizeDimensionsRequest {
  /// The dimensions on a data source sheet to automatically resize.
  DataSourceSheetDimensionRange? dataSourceSheetDimensions;

  /// The dimensions to automatically resize.
  DimensionRange? dimensions;

  AutoResizeDimensionsRequest();

  AutoResizeDimensionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceSheetDimensions')) {
      dataSourceSheetDimensions = DataSourceSheetDimensionRange.fromJson(
          _json['dataSourceSheetDimensions']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dimensions')) {
      dimensions = DimensionRange.fromJson(
          _json['dimensions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceSheetDimensions != null)
          'dataSourceSheetDimensions': dataSourceSheetDimensions!.toJson(),
        if (dimensions != null) 'dimensions': dimensions!.toJson(),
      };
}

/// A banded (alternating colors) range in a sheet.
class BandedRange {
  /// The id of the banded range.
  core.int? bandedRangeId;

  /// Properties for column bands.
  ///
  /// These properties are applied on a column- by-column basis throughout all
  /// the columns in the range. At least one of row_properties or
  /// column_properties must be specified.
  BandingProperties? columnProperties;

  /// The range over which these properties are applied.
  GridRange? range;

  /// Properties for row bands.
  ///
  /// These properties are applied on a row-by-row basis throughout all the rows
  /// in the range. At least one of row_properties or column_properties must be
  /// specified.
  BandingProperties? rowProperties;

  BandedRange();

  BandedRange.fromJson(core.Map _json) {
    if (_json.containsKey('bandedRangeId')) {
      bandedRangeId = _json['bandedRangeId'] as core.int;
    }
    if (_json.containsKey('columnProperties')) {
      columnProperties = BandingProperties.fromJson(
          _json['columnProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rowProperties')) {
      rowProperties = BandingProperties.fromJson(
          _json['rowProperties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bandedRangeId != null) 'bandedRangeId': bandedRangeId!,
        if (columnProperties != null)
          'columnProperties': columnProperties!.toJson(),
        if (range != null) 'range': range!.toJson(),
        if (rowProperties != null) 'rowProperties': rowProperties!.toJson(),
      };
}

/// Properties referring a single dimension (either row or column).
///
/// If both BandedRange.row_properties and BandedRange.column_properties are
/// set, the fill colors are applied to cells according to the following rules:
/// * header_color and footer_color take priority over band colors. *
/// first_band_color takes priority over second_band_color. * row_properties
/// takes priority over column_properties. For example, the first row color
/// takes priority over the first column color, but the first column color takes
/// priority over the second row color. Similarly, the row header takes priority
/// over the column header in the top left cell, but the column header takes
/// priority over the first row color if the row header is not set.
class BandingProperties {
  /// The first color that is alternating.
  ///
  /// (Required)
  Color? firstBandColor;

  /// The first color that is alternating.
  ///
  /// (Required) If first_band_color is also set, this field takes precedence.
  ColorStyle? firstBandColorStyle;

  /// The color of the last row or column.
  ///
  /// If this field is not set, the last row or column is filled with either
  /// first_band_color or second_band_color, depending on the color of the
  /// previous row or column.
  Color? footerColor;

  /// The color of the last row or column.
  ///
  /// If this field is not set, the last row or column is filled with either
  /// first_band_color or second_band_color, depending on the color of the
  /// previous row or column. If footer_color is also set, this field takes
  /// precedence.
  ColorStyle? footerColorStyle;

  /// The color of the first row or column.
  ///
  /// If this field is set, the first row or column is filled with this color
  /// and the colors alternate between first_band_color and second_band_color
  /// starting from the second row or column. Otherwise, the first row or column
  /// is filled with first_band_color and the colors proceed to alternate as
  /// they normally would.
  Color? headerColor;

  /// The color of the first row or column.
  ///
  /// If this field is set, the first row or column is filled with this color
  /// and the colors alternate between first_band_color and second_band_color
  /// starting from the second row or column. Otherwise, the first row or column
  /// is filled with first_band_color and the colors proceed to alternate as
  /// they normally would. If header_color is also set, this field takes
  /// precedence.
  ColorStyle? headerColorStyle;

  /// The second color that is alternating.
  ///
  /// (Required)
  Color? secondBandColor;

  /// The second color that is alternating.
  ///
  /// (Required) If second_band_color is also set, this field takes precedence.
  ColorStyle? secondBandColorStyle;

  BandingProperties();

  BandingProperties.fromJson(core.Map _json) {
    if (_json.containsKey('firstBandColor')) {
      firstBandColor = Color.fromJson(
          _json['firstBandColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('firstBandColorStyle')) {
      firstBandColorStyle = ColorStyle.fromJson(
          _json['firstBandColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('footerColor')) {
      footerColor = Color.fromJson(
          _json['footerColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('footerColorStyle')) {
      footerColorStyle = ColorStyle.fromJson(
          _json['footerColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('headerColor')) {
      headerColor = Color.fromJson(
          _json['headerColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('headerColorStyle')) {
      headerColorStyle = ColorStyle.fromJson(
          _json['headerColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('secondBandColor')) {
      secondBandColor = Color.fromJson(
          _json['secondBandColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('secondBandColorStyle')) {
      secondBandColorStyle = ColorStyle.fromJson(
          _json['secondBandColorStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (firstBandColor != null) 'firstBandColor': firstBandColor!.toJson(),
        if (firstBandColorStyle != null)
          'firstBandColorStyle': firstBandColorStyle!.toJson(),
        if (footerColor != null) 'footerColor': footerColor!.toJson(),
        if (footerColorStyle != null)
          'footerColorStyle': footerColorStyle!.toJson(),
        if (headerColor != null) 'headerColor': headerColor!.toJson(),
        if (headerColorStyle != null)
          'headerColorStyle': headerColorStyle!.toJson(),
        if (secondBandColor != null)
          'secondBandColor': secondBandColor!.toJson(),
        if (secondBandColorStyle != null)
          'secondBandColorStyle': secondBandColorStyle!.toJson(),
      };
}

/// Formatting options for baseline value.
class BaselineValueFormat {
  /// The comparison type of key value with baseline value.
  /// Possible string values are:
  /// - "COMPARISON_TYPE_UNDEFINED" : Default value, do not use.
  /// - "ABSOLUTE_DIFFERENCE" : Use absolute difference between key and baseline
  /// value.
  /// - "PERCENTAGE_DIFFERENCE" : Use percentage difference between key and
  /// baseline value.
  core.String? comparisonType;

  /// Description which is appended after the baseline value.
  ///
  /// This field is optional.
  core.String? description;

  /// Color to be used, in case baseline value represents a negative change for
  /// key value.
  ///
  /// This field is optional.
  Color? negativeColor;

  /// Color to be used, in case baseline value represents a negative change for
  /// key value.
  ///
  /// This field is optional. If negative_color is also set, this field takes
  /// precedence.
  ColorStyle? negativeColorStyle;

  /// Specifies the horizontal text positioning of baseline value.
  ///
  /// This field is optional. If not specified, default positioning is used.
  TextPosition? position;

  /// Color to be used, in case baseline value represents a positive change for
  /// key value.
  ///
  /// This field is optional.
  Color? positiveColor;

  /// Color to be used, in case baseline value represents a positive change for
  /// key value.
  ///
  /// This field is optional. If positive_color is also set, this field takes
  /// precedence.
  ColorStyle? positiveColorStyle;

  /// Text formatting options for baseline value.
  ///
  /// The link field is not supported.
  TextFormat? textFormat;

  BaselineValueFormat();

  BaselineValueFormat.fromJson(core.Map _json) {
    if (_json.containsKey('comparisonType')) {
      comparisonType = _json['comparisonType'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('negativeColor')) {
      negativeColor = Color.fromJson(
          _json['negativeColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('negativeColorStyle')) {
      negativeColorStyle = ColorStyle.fromJson(
          _json['negativeColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('position')) {
      position = TextPosition.fromJson(
          _json['position'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('positiveColor')) {
      positiveColor = Color.fromJson(
          _json['positiveColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('positiveColorStyle')) {
      positiveColorStyle = ColorStyle.fromJson(
          _json['positiveColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textFormat')) {
      textFormat = TextFormat.fromJson(
          _json['textFormat'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (comparisonType != null) 'comparisonType': comparisonType!,
        if (description != null) 'description': description!,
        if (negativeColor != null) 'negativeColor': negativeColor!.toJson(),
        if (negativeColorStyle != null)
          'negativeColorStyle': negativeColorStyle!.toJson(),
        if (position != null) 'position': position!.toJson(),
        if (positiveColor != null) 'positiveColor': positiveColor!.toJson(),
        if (positiveColorStyle != null)
          'positiveColorStyle': positiveColorStyle!.toJson(),
        if (textFormat != null) 'textFormat': textFormat!.toJson(),
      };
}

/// An axis of the chart.
///
/// A chart may not have more than one axis per axis position.
class BasicChartAxis {
  /// The format of the title.
  ///
  /// Only valid if the axis is not associated with the domain. The link field
  /// is not supported.
  TextFormat? format;

  /// The position of this axis.
  /// Possible string values are:
  /// - "BASIC_CHART_AXIS_POSITION_UNSPECIFIED" : Default value, do not use.
  /// - "BOTTOM_AXIS" : The axis rendered at the bottom of a chart. For most
  /// charts, this is the standard major axis. For bar charts, this is a minor
  /// axis.
  /// - "LEFT_AXIS" : The axis rendered at the left of a chart. For most charts,
  /// this is a minor axis. For bar charts, this is the standard major axis.
  /// - "RIGHT_AXIS" : The axis rendered at the right of a chart. For most
  /// charts, this is a minor axis. For bar charts, this is an unusual major
  /// axis.
  core.String? position;

  /// The title of this axis.
  ///
  /// If set, this overrides any title inferred from headers of the data.
  core.String? title;

  /// The axis title text position.
  TextPosition? titleTextPosition;

  /// The view window options for this axis.
  ChartAxisViewWindowOptions? viewWindowOptions;

  BasicChartAxis();

  BasicChartAxis.fromJson(core.Map _json) {
    if (_json.containsKey('format')) {
      format = TextFormat.fromJson(
          _json['format'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('position')) {
      position = _json['position'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('titleTextPosition')) {
      titleTextPosition = TextPosition.fromJson(
          _json['titleTextPosition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('viewWindowOptions')) {
      viewWindowOptions = ChartAxisViewWindowOptions.fromJson(
          _json['viewWindowOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (format != null) 'format': format!.toJson(),
        if (position != null) 'position': position!,
        if (title != null) 'title': title!,
        if (titleTextPosition != null)
          'titleTextPosition': titleTextPosition!.toJson(),
        if (viewWindowOptions != null)
          'viewWindowOptions': viewWindowOptions!.toJson(),
      };
}

/// The domain of a chart.
///
/// For example, if charting stock prices over time, this would be the date.
class BasicChartDomain {
  /// The data of the domain.
  ///
  /// For example, if charting stock prices over time, this is the data
  /// representing the dates.
  ChartData? domain;

  /// True to reverse the order of the domain values (horizontal axis).
  core.bool? reversed;

  BasicChartDomain();

  BasicChartDomain.fromJson(core.Map _json) {
    if (_json.containsKey('domain')) {
      domain = ChartData.fromJson(
          _json['domain'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reversed')) {
      reversed = _json['reversed'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (domain != null) 'domain': domain!.toJson(),
        if (reversed != null) 'reversed': reversed!,
      };
}

/// A single series of data in a chart.
///
/// For example, if charting stock prices over time, multiple series may exist,
/// one for the "Open Price", "High Price", "Low Price" and "Close Price".
class BasicChartSeries {
  /// The color for elements (such as bars, lines, and points) associated with
  /// this series.
  ///
  /// If empty, a default color is used.
  Color? color;

  /// The color for elements (such as bars, lines, and points) associated with
  /// this series.
  ///
  /// If empty, a default color is used. If color is also set, this field takes
  /// precedence.
  ColorStyle? colorStyle;

  /// Information about the data labels for this series.
  DataLabel? dataLabel;

  /// The line style of this series.
  ///
  /// Valid only if the chartType is AREA, LINE, or SCATTER. COMBO charts are
  /// also supported if the series chart type is AREA or LINE.
  LineStyle? lineStyle;

  /// The style for points associated with this series.
  ///
  /// Valid only if the chartType is AREA, LINE, or SCATTER. COMBO charts are
  /// also supported if the series chart type is AREA, LINE, or SCATTER. If
  /// empty, a default point style is used.
  PointStyle? pointStyle;

  /// The data being visualized in this chart series.
  ChartData? series;

  /// Style override settings for series data points.
  core.List<BasicSeriesDataPointStyleOverride>? styleOverrides;

  /// The minor axis that will specify the range of values for this series.
  ///
  /// For example, if charting stocks over time, the "Volume" series may want to
  /// be pinned to the right with the prices pinned to the left, because the
  /// scale of trading volume is different than the scale of prices. It is an
  /// error to specify an axis that isn't a valid minor axis for the chart's
  /// type.
  /// Possible string values are:
  /// - "BASIC_CHART_AXIS_POSITION_UNSPECIFIED" : Default value, do not use.
  /// - "BOTTOM_AXIS" : The axis rendered at the bottom of a chart. For most
  /// charts, this is the standard major axis. For bar charts, this is a minor
  /// axis.
  /// - "LEFT_AXIS" : The axis rendered at the left of a chart. For most charts,
  /// this is a minor axis. For bar charts, this is the standard major axis.
  /// - "RIGHT_AXIS" : The axis rendered at the right of a chart. For most
  /// charts, this is a minor axis. For bar charts, this is an unusual major
  /// axis.
  core.String? targetAxis;

  /// The type of this series.
  ///
  /// Valid only if the chartType is COMBO. Different types will change the way
  /// the series is visualized. Only LINE, AREA, and COLUMN are supported.
  /// Possible string values are:
  /// - "BASIC_CHART_TYPE_UNSPECIFIED" : Default value, do not use.
  /// - "BAR" : A bar chart.
  /// - "LINE" : A line chart.
  /// - "AREA" : An area chart.
  /// - "COLUMN" : A column chart.
  /// - "SCATTER" : A scatter chart.
  /// - "COMBO" : A combo chart.
  /// - "STEPPED_AREA" : A stepped area chart.
  core.String? type;

  BasicChartSeries();

  BasicChartSeries.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color =
          Color.fromJson(_json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('colorStyle')) {
      colorStyle = ColorStyle.fromJson(
          _json['colorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataLabel')) {
      dataLabel = DataLabel.fromJson(
          _json['dataLabel'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lineStyle')) {
      lineStyle = LineStyle.fromJson(
          _json['lineStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pointStyle')) {
      pointStyle = PointStyle.fromJson(
          _json['pointStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('series')) {
      series = ChartData.fromJson(
          _json['series'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('styleOverrides')) {
      styleOverrides = (_json['styleOverrides'] as core.List)
          .map<BasicSeriesDataPointStyleOverride>((value) =>
              BasicSeriesDataPointStyleOverride.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('targetAxis')) {
      targetAxis = _json['targetAxis'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
        if (colorStyle != null) 'colorStyle': colorStyle!.toJson(),
        if (dataLabel != null) 'dataLabel': dataLabel!.toJson(),
        if (lineStyle != null) 'lineStyle': lineStyle!.toJson(),
        if (pointStyle != null) 'pointStyle': pointStyle!.toJson(),
        if (series != null) 'series': series!.toJson(),
        if (styleOverrides != null)
          'styleOverrides':
              styleOverrides!.map((value) => value.toJson()).toList(),
        if (targetAxis != null) 'targetAxis': targetAxis!,
        if (type != null) 'type': type!,
      };
}

/// The specification for a basic chart.
///
/// See BasicChartType for the list of charts this supports.
class BasicChartSpec {
  /// The axis on the chart.
  core.List<BasicChartAxis>? axis;

  /// The type of the chart.
  /// Possible string values are:
  /// - "BASIC_CHART_TYPE_UNSPECIFIED" : Default value, do not use.
  /// - "BAR" : A bar chart.
  /// - "LINE" : A line chart.
  /// - "AREA" : An area chart.
  /// - "COLUMN" : A column chart.
  /// - "SCATTER" : A scatter chart.
  /// - "COMBO" : A combo chart.
  /// - "STEPPED_AREA" : A stepped area chart.
  core.String? chartType;

  /// The behavior of tooltips and data highlighting when hovering on data and
  /// chart area.
  /// Possible string values are:
  /// - "BASIC_CHART_COMPARE_MODE_UNSPECIFIED" : Default value, do not use.
  /// - "DATUM" : Only the focused data element is highlighted and shown in the
  /// tooltip.
  /// - "CATEGORY" : All data elements with the same category (e.g., domain
  /// value) are highlighted and shown in the tooltip.
  core.String? compareMode;

  /// The domain of data this is charting.
  ///
  /// Only a single domain is supported.
  core.List<BasicChartDomain>? domains;

  /// The number of rows or columns in the data that are "headers".
  ///
  /// If not set, Google Sheets will guess how many rows are headers based on
  /// the data. (Note that BasicChartAxis.title may override the axis title
  /// inferred from the header values.)
  core.int? headerCount;

  /// If some values in a series are missing, gaps may appear in the chart (e.g,
  /// segments of lines in a line chart will be missing).
  ///
  /// To eliminate these gaps set this to true. Applies to Line, Area, and Combo
  /// charts.
  core.bool? interpolateNulls;

  /// The position of the chart legend.
  /// Possible string values are:
  /// - "BASIC_CHART_LEGEND_POSITION_UNSPECIFIED" : Default value, do not use.
  /// - "BOTTOM_LEGEND" : The legend is rendered on the bottom of the chart.
  /// - "LEFT_LEGEND" : The legend is rendered on the left of the chart.
  /// - "RIGHT_LEGEND" : The legend is rendered on the right of the chart.
  /// - "TOP_LEGEND" : The legend is rendered on the top of the chart.
  /// - "NO_LEGEND" : No legend is rendered.
  core.String? legendPosition;

  /// Gets whether all lines should be rendered smooth or straight by default.
  ///
  /// Applies to Line charts.
  core.bool? lineSmoothing;

  /// The data this chart is visualizing.
  core.List<BasicChartSeries>? series;

  /// The stacked type for charts that support vertical stacking.
  ///
  /// Applies to Area, Bar, Column, Combo, and Stepped Area charts.
  /// Possible string values are:
  /// - "BASIC_CHART_STACKED_TYPE_UNSPECIFIED" : Default value, do not use.
  /// - "NOT_STACKED" : Series are not stacked.
  /// - "STACKED" : Series values are stacked, each value is rendered vertically
  /// beginning from the top of the value below it.
  /// - "PERCENT_STACKED" : Vertical stacks are stretched to reach the top of
  /// the chart, with values laid out as percentages of each other.
  core.String? stackedType;

  /// True to make the chart 3D.
  ///
  /// Applies to Bar and Column charts.
  core.bool? threeDimensional;

  /// Controls whether to display additional data labels on stacked charts which
  /// sum the total value of all stacked values at each value along the domain
  /// axis.
  ///
  /// These data labels can only be set when chart_type is one of AREA, BAR,
  /// COLUMN, COMBO or STEPPED_AREA and stacked_type is either STACKED or
  /// PERCENT_STACKED. In addition, for COMBO, this will only be supported if
  /// there is only one type of stackable series type or one type has more
  /// series than the others and each of the other types have no more than one
  /// series. For example, if a chart has two stacked bar series and one area
  /// series, the total data labels will be supported. If it has three bar
  /// series and two area series, total data labels are not allowed. Neither
  /// CUSTOM nor placement can be set on the total_data_label.
  DataLabel? totalDataLabel;

  BasicChartSpec();

  BasicChartSpec.fromJson(core.Map _json) {
    if (_json.containsKey('axis')) {
      axis = (_json['axis'] as core.List)
          .map<BasicChartAxis>((value) => BasicChartAxis.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('chartType')) {
      chartType = _json['chartType'] as core.String;
    }
    if (_json.containsKey('compareMode')) {
      compareMode = _json['compareMode'] as core.String;
    }
    if (_json.containsKey('domains')) {
      domains = (_json['domains'] as core.List)
          .map<BasicChartDomain>((value) => BasicChartDomain.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('headerCount')) {
      headerCount = _json['headerCount'] as core.int;
    }
    if (_json.containsKey('interpolateNulls')) {
      interpolateNulls = _json['interpolateNulls'] as core.bool;
    }
    if (_json.containsKey('legendPosition')) {
      legendPosition = _json['legendPosition'] as core.String;
    }
    if (_json.containsKey('lineSmoothing')) {
      lineSmoothing = _json['lineSmoothing'] as core.bool;
    }
    if (_json.containsKey('series')) {
      series = (_json['series'] as core.List)
          .map<BasicChartSeries>((value) => BasicChartSeries.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('stackedType')) {
      stackedType = _json['stackedType'] as core.String;
    }
    if (_json.containsKey('threeDimensional')) {
      threeDimensional = _json['threeDimensional'] as core.bool;
    }
    if (_json.containsKey('totalDataLabel')) {
      totalDataLabel = DataLabel.fromJson(
          _json['totalDataLabel'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (axis != null) 'axis': axis!.map((value) => value.toJson()).toList(),
        if (chartType != null) 'chartType': chartType!,
        if (compareMode != null) 'compareMode': compareMode!,
        if (domains != null)
          'domains': domains!.map((value) => value.toJson()).toList(),
        if (headerCount != null) 'headerCount': headerCount!,
        if (interpolateNulls != null) 'interpolateNulls': interpolateNulls!,
        if (legendPosition != null) 'legendPosition': legendPosition!,
        if (lineSmoothing != null) 'lineSmoothing': lineSmoothing!,
        if (series != null)
          'series': series!.map((value) => value.toJson()).toList(),
        if (stackedType != null) 'stackedType': stackedType!,
        if (threeDimensional != null) 'threeDimensional': threeDimensional!,
        if (totalDataLabel != null) 'totalDataLabel': totalDataLabel!.toJson(),
      };
}

/// The default filter associated with a sheet.
class BasicFilter {
  /// The criteria for showing/hiding values per column.
  ///
  /// The map's key is the column index, and the value is the criteria for that
  /// column. This field is deprecated in favor of filter_specs.
  core.Map<core.String, FilterCriteria>? criteria;

  /// The filter criteria per column.
  ///
  /// Both criteria and filter_specs are populated in responses. If both fields
  /// are specified in an update request, this field takes precedence.
  core.List<FilterSpec>? filterSpecs;

  /// The range the filter covers.
  GridRange? range;

  /// The sort order per column.
  ///
  /// Later specifications are used when values are equal in the earlier
  /// specifications.
  core.List<SortSpec>? sortSpecs;

  BasicFilter();

  BasicFilter.fromJson(core.Map _json) {
    if (_json.containsKey('criteria')) {
      criteria = (_json['criteria'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          FilterCriteria.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('filterSpecs')) {
      filterSpecs = (_json['filterSpecs'] as core.List)
          .map<FilterSpec>((value) =>
              FilterSpec.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sortSpecs')) {
      sortSpecs = (_json['sortSpecs'] as core.List)
          .map<SortSpec>((value) =>
              SortSpec.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (criteria != null)
          'criteria':
              criteria!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (filterSpecs != null)
          'filterSpecs': filterSpecs!.map((value) => value.toJson()).toList(),
        if (range != null) 'range': range!.toJson(),
        if (sortSpecs != null)
          'sortSpecs': sortSpecs!.map((value) => value.toJson()).toList(),
      };
}

/// Style override settings for a single series data point.
class BasicSeriesDataPointStyleOverride {
  /// Color of the series data point.
  ///
  /// If empty, the series default is used.
  Color? color;

  /// Color of the series data point.
  ///
  /// If empty, the series default is used. If color is also set, this field
  /// takes precedence.
  ColorStyle? colorStyle;

  /// Zero based index of the series data point.
  core.int? index;

  /// Point style of the series data point.
  ///
  /// Valid only if the chartType is AREA, LINE, or SCATTER. COMBO charts are
  /// also supported if the series chart type is AREA, LINE, or SCATTER. If
  /// empty, the series default is used.
  PointStyle? pointStyle;

  BasicSeriesDataPointStyleOverride();

  BasicSeriesDataPointStyleOverride.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color =
          Color.fromJson(_json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('colorStyle')) {
      colorStyle = ColorStyle.fromJson(
          _json['colorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('index')) {
      index = _json['index'] as core.int;
    }
    if (_json.containsKey('pointStyle')) {
      pointStyle = PointStyle.fromJson(
          _json['pointStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
        if (colorStyle != null) 'colorStyle': colorStyle!.toJson(),
        if (index != null) 'index': index!,
        if (pointStyle != null) 'pointStyle': pointStyle!.toJson(),
      };
}

/// The request for clearing more than one range selected by a DataFilter in a
/// spreadsheet.
class BatchClearValuesByDataFilterRequest {
  /// The DataFilters used to determine which ranges to clear.
  core.List<DataFilter>? dataFilters;

  BatchClearValuesByDataFilterRequest();

  BatchClearValuesByDataFilterRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataFilters')) {
      dataFilters = (_json['dataFilters'] as core.List)
          .map<DataFilter>((value) =>
              DataFilter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataFilters != null)
          'dataFilters': dataFilters!.map((value) => value.toJson()).toList(),
      };
}

/// The response when clearing a range of values selected with DataFilters in a
/// spreadsheet.
class BatchClearValuesByDataFilterResponse {
  /// The ranges that were cleared, in A1 notation.
  ///
  /// If the requests are for an unbounded range or a ranger larger than the
  /// bounds of the sheet, this is the actual ranges that were cleared, bounded
  /// to the sheet's limits.
  core.List<core.String>? clearedRanges;

  /// The spreadsheet the updates were applied to.
  core.String? spreadsheetId;

  BatchClearValuesByDataFilterResponse();

  BatchClearValuesByDataFilterResponse.fromJson(core.Map _json) {
    if (_json.containsKey('clearedRanges')) {
      clearedRanges = (_json['clearedRanges'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clearedRanges != null) 'clearedRanges': clearedRanges!,
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
      };
}

/// The request for clearing more than one range of values in a spreadsheet.
class BatchClearValuesRequest {
  /// The ranges to clear, in A1 or R1C1 notation.
  core.List<core.String>? ranges;

  BatchClearValuesRequest();

  BatchClearValuesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('ranges')) {
      ranges = (_json['ranges'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ranges != null) 'ranges': ranges!,
      };
}

/// The response when clearing a range of values in a spreadsheet.
class BatchClearValuesResponse {
  /// The ranges that were cleared, in A1 notation.
  ///
  /// If the requests are for an unbounded range or a ranger larger than the
  /// bounds of the sheet, this is the actual ranges that were cleared, bounded
  /// to the sheet's limits.
  core.List<core.String>? clearedRanges;

  /// The spreadsheet the updates were applied to.
  core.String? spreadsheetId;

  BatchClearValuesResponse();

  BatchClearValuesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('clearedRanges')) {
      clearedRanges = (_json['clearedRanges'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clearedRanges != null) 'clearedRanges': clearedRanges!,
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
      };
}

/// The request for retrieving a range of values in a spreadsheet selected by a
/// set of DataFilters.
class BatchGetValuesByDataFilterRequest {
  /// The data filters used to match the ranges of values to retrieve.
  ///
  /// Ranges that match any of the specified data filters are included in the
  /// response.
  core.List<DataFilter>? dataFilters;

  /// How dates, times, and durations should be represented in the output.
  ///
  /// This is ignored if value_render_option is FORMATTED_VALUE. The default
  /// dateTime render option is SERIAL_NUMBER.
  /// Possible string values are:
  /// - "SERIAL_NUMBER" : Instructs date, time, datetime, and duration fields to
  /// be output as doubles in "serial number" format, as popularized by Lotus
  /// 1-2-3. The whole number portion of the value (left of the decimal) counts
  /// the days since December 30th 1899. The fractional portion (right of the
  /// decimal) counts the time as a fraction of the day. For example, January
  /// 1st 1900 at noon would be 2.5, 2 because it's 2 days after December 30st
  /// 1899, and .5 because noon is half a day. February 1st 1900 at 3pm would be
  /// 33.625. This correctly treats the year 1900 as not a leap year.
  /// - "FORMATTED_STRING" : Instructs date, time, datetime, and duration fields
  /// to be output as strings in their given number format (which is dependent
  /// on the spreadsheet locale).
  core.String? dateTimeRenderOption;

  /// The major dimension that results should use.
  ///
  /// For example, if the spreadsheet data is: `A1=1,B1=2,A2=3,B2=4`, then a
  /// request that selects that range and sets `majorDimension=ROWS` returns
  /// `[[1,2],[3,4]]`, whereas a request that sets `majorDimension=COLUMNS`
  /// returns `[[1,3],[2,4]]`.
  /// Possible string values are:
  /// - "DIMENSION_UNSPECIFIED" : The default value, do not use.
  /// - "ROWS" : Operates on the rows of a sheet.
  /// - "COLUMNS" : Operates on the columns of a sheet.
  core.String? majorDimension;

  /// How values should be represented in the output.
  ///
  /// The default render option is FORMATTED_VALUE.
  /// Possible string values are:
  /// - "FORMATTED_VALUE" : Values will be calculated & formatted in the reply
  /// according to the cell's formatting. Formatting is based on the
  /// spreadsheet's locale, not the requesting user's locale. For example, if
  /// `A1` is `1.23` and `A2` is `=A1` and formatted as currency, then `A2`
  /// would return `"$1.23"`.
  /// - "UNFORMATTED_VALUE" : Values will be calculated, but not formatted in
  /// the reply. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then `A2` would return the number `1.23`.
  /// - "FORMULA" : Values will not be calculated. The reply will include the
  /// formulas. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then A2 would return `"=A1"`.
  core.String? valueRenderOption;

  BatchGetValuesByDataFilterRequest();

  BatchGetValuesByDataFilterRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataFilters')) {
      dataFilters = (_json['dataFilters'] as core.List)
          .map<DataFilter>((value) =>
              DataFilter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dateTimeRenderOption')) {
      dateTimeRenderOption = _json['dateTimeRenderOption'] as core.String;
    }
    if (_json.containsKey('majorDimension')) {
      majorDimension = _json['majorDimension'] as core.String;
    }
    if (_json.containsKey('valueRenderOption')) {
      valueRenderOption = _json['valueRenderOption'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataFilters != null)
          'dataFilters': dataFilters!.map((value) => value.toJson()).toList(),
        if (dateTimeRenderOption != null)
          'dateTimeRenderOption': dateTimeRenderOption!,
        if (majorDimension != null) 'majorDimension': majorDimension!,
        if (valueRenderOption != null) 'valueRenderOption': valueRenderOption!,
      };
}

/// The response when retrieving more than one range of values in a spreadsheet
/// selected by DataFilters.
class BatchGetValuesByDataFilterResponse {
  /// The ID of the spreadsheet the data was retrieved from.
  core.String? spreadsheetId;

  /// The requested values with the list of data filters that matched them.
  core.List<MatchedValueRange>? valueRanges;

  BatchGetValuesByDataFilterResponse();

  BatchGetValuesByDataFilterResponse.fromJson(core.Map _json) {
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
    if (_json.containsKey('valueRanges')) {
      valueRanges = (_json['valueRanges'] as core.List)
          .map<MatchedValueRange>((value) => MatchedValueRange.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
        if (valueRanges != null)
          'valueRanges': valueRanges!.map((value) => value.toJson()).toList(),
      };
}

/// The response when retrieving more than one range of values in a spreadsheet.
class BatchGetValuesResponse {
  /// The ID of the spreadsheet the data was retrieved from.
  core.String? spreadsheetId;

  /// The requested values.
  ///
  /// The order of the ValueRanges is the same as the order of the requested
  /// ranges.
  core.List<ValueRange>? valueRanges;

  BatchGetValuesResponse();

  BatchGetValuesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
    if (_json.containsKey('valueRanges')) {
      valueRanges = (_json['valueRanges'] as core.List)
          .map<ValueRange>((value) =>
              ValueRange.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
        if (valueRanges != null)
          'valueRanges': valueRanges!.map((value) => value.toJson()).toList(),
      };
}

/// The request for updating any aspect of a spreadsheet.
class BatchUpdateSpreadsheetRequest {
  /// Determines if the update response should include the spreadsheet resource.
  core.bool? includeSpreadsheetInResponse;

  /// A list of updates to apply to the spreadsheet.
  ///
  /// Requests will be applied in the order they are specified. If any request
  /// is not valid, no requests will be applied.
  core.List<Request>? requests;

  /// True if grid data should be returned.
  ///
  /// Meaningful only if include_spreadsheet_in_response is 'true'. This
  /// parameter is ignored if a field mask was set in the request.
  core.bool? responseIncludeGridData;

  /// Limits the ranges included in the response spreadsheet.
  ///
  /// Meaningful only if include_spreadsheet_in_response is 'true'.
  core.List<core.String>? responseRanges;

  BatchUpdateSpreadsheetRequest();

  BatchUpdateSpreadsheetRequest.fromJson(core.Map _json) {
    if (_json.containsKey('includeSpreadsheetInResponse')) {
      includeSpreadsheetInResponse =
          _json['includeSpreadsheetInResponse'] as core.bool;
    }
    if (_json.containsKey('requests')) {
      requests = (_json['requests'] as core.List)
          .map<Request>((value) =>
              Request.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('responseIncludeGridData')) {
      responseIncludeGridData = _json['responseIncludeGridData'] as core.bool;
    }
    if (_json.containsKey('responseRanges')) {
      responseRanges = (_json['responseRanges'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (includeSpreadsheetInResponse != null)
          'includeSpreadsheetInResponse': includeSpreadsheetInResponse!,
        if (requests != null)
          'requests': requests!.map((value) => value.toJson()).toList(),
        if (responseIncludeGridData != null)
          'responseIncludeGridData': responseIncludeGridData!,
        if (responseRanges != null) 'responseRanges': responseRanges!,
      };
}

/// The reply for batch updating a spreadsheet.
class BatchUpdateSpreadsheetResponse {
  /// The reply of the updates.
  ///
  /// This maps 1:1 with the updates, although replies to some requests may be
  /// empty.
  core.List<Response>? replies;

  /// The spreadsheet the updates were applied to.
  core.String? spreadsheetId;

  /// The spreadsheet after updates were applied.
  ///
  /// This is only set if
  /// BatchUpdateSpreadsheetRequest.include_spreadsheet_in_response is `true`.
  Spreadsheet? updatedSpreadsheet;

  BatchUpdateSpreadsheetResponse();

  BatchUpdateSpreadsheetResponse.fromJson(core.Map _json) {
    if (_json.containsKey('replies')) {
      replies = (_json['replies'] as core.List)
          .map<Response>((value) =>
              Response.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
    if (_json.containsKey('updatedSpreadsheet')) {
      updatedSpreadsheet = Spreadsheet.fromJson(
          _json['updatedSpreadsheet'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (replies != null)
          'replies': replies!.map((value) => value.toJson()).toList(),
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
        if (updatedSpreadsheet != null)
          'updatedSpreadsheet': updatedSpreadsheet!.toJson(),
      };
}

/// The request for updating more than one range of values in a spreadsheet.
class BatchUpdateValuesByDataFilterRequest {
  /// The new values to apply to the spreadsheet.
  ///
  /// If more than one range is matched by the specified DataFilter the
  /// specified values are applied to all of those ranges.
  core.List<DataFilterValueRange>? data;

  /// Determines if the update response should include the values of the cells
  /// that were updated.
  ///
  /// By default, responses do not include the updated values. The `updatedData`
  /// field within each of the BatchUpdateValuesResponse.responses contains the
  /// updated values. If the range to write was larger than the range actually
  /// written, the response includes all values in the requested range
  /// (excluding trailing empty rows and columns).
  core.bool? includeValuesInResponse;

  /// Determines how dates, times, and durations in the response should be
  /// rendered.
  ///
  /// This is ignored if response_value_render_option is FORMATTED_VALUE. The
  /// default dateTime render option is SERIAL_NUMBER.
  /// Possible string values are:
  /// - "SERIAL_NUMBER" : Instructs date, time, datetime, and duration fields to
  /// be output as doubles in "serial number" format, as popularized by Lotus
  /// 1-2-3. The whole number portion of the value (left of the decimal) counts
  /// the days since December 30th 1899. The fractional portion (right of the
  /// decimal) counts the time as a fraction of the day. For example, January
  /// 1st 1900 at noon would be 2.5, 2 because it's 2 days after December 30st
  /// 1899, and .5 because noon is half a day. February 1st 1900 at 3pm would be
  /// 33.625. This correctly treats the year 1900 as not a leap year.
  /// - "FORMATTED_STRING" : Instructs date, time, datetime, and duration fields
  /// to be output as strings in their given number format (which is dependent
  /// on the spreadsheet locale).
  core.String? responseDateTimeRenderOption;

  /// Determines how values in the response should be rendered.
  ///
  /// The default render option is FORMATTED_VALUE.
  /// Possible string values are:
  /// - "FORMATTED_VALUE" : Values will be calculated & formatted in the reply
  /// according to the cell's formatting. Formatting is based on the
  /// spreadsheet's locale, not the requesting user's locale. For example, if
  /// `A1` is `1.23` and `A2` is `=A1` and formatted as currency, then `A2`
  /// would return `"$1.23"`.
  /// - "UNFORMATTED_VALUE" : Values will be calculated, but not formatted in
  /// the reply. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then `A2` would return the number `1.23`.
  /// - "FORMULA" : Values will not be calculated. The reply will include the
  /// formulas. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then A2 would return `"=A1"`.
  core.String? responseValueRenderOption;

  /// How the input data should be interpreted.
  /// Possible string values are:
  /// - "INPUT_VALUE_OPTION_UNSPECIFIED" : Default input value. This value must
  /// not be used.
  /// - "RAW" : The values the user has entered will not be parsed and will be
  /// stored as-is.
  /// - "USER_ENTERED" : The values will be parsed as if the user typed them
  /// into the UI. Numbers will stay as numbers, but strings may be converted to
  /// numbers, dates, etc. following the same rules that are applied when
  /// entering text into a cell via the Google Sheets UI.
  core.String? valueInputOption;

  BatchUpdateValuesByDataFilterRequest();

  BatchUpdateValuesByDataFilterRequest.fromJson(core.Map _json) {
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.List)
          .map<DataFilterValueRange>((value) => DataFilterValueRange.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('includeValuesInResponse')) {
      includeValuesInResponse = _json['includeValuesInResponse'] as core.bool;
    }
    if (_json.containsKey('responseDateTimeRenderOption')) {
      responseDateTimeRenderOption =
          _json['responseDateTimeRenderOption'] as core.String;
    }
    if (_json.containsKey('responseValueRenderOption')) {
      responseValueRenderOption =
          _json['responseValueRenderOption'] as core.String;
    }
    if (_json.containsKey('valueInputOption')) {
      valueInputOption = _json['valueInputOption'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (data != null) 'data': data!.map((value) => value.toJson()).toList(),
        if (includeValuesInResponse != null)
          'includeValuesInResponse': includeValuesInResponse!,
        if (responseDateTimeRenderOption != null)
          'responseDateTimeRenderOption': responseDateTimeRenderOption!,
        if (responseValueRenderOption != null)
          'responseValueRenderOption': responseValueRenderOption!,
        if (valueInputOption != null) 'valueInputOption': valueInputOption!,
      };
}

/// The response when updating a range of values in a spreadsheet.
class BatchUpdateValuesByDataFilterResponse {
  /// The response for each range updated.
  core.List<UpdateValuesByDataFilterResponse>? responses;

  /// The spreadsheet the updates were applied to.
  core.String? spreadsheetId;

  /// The total number of cells updated.
  core.int? totalUpdatedCells;

  /// The total number of columns where at least one cell in the column was
  /// updated.
  core.int? totalUpdatedColumns;

  /// The total number of rows where at least one cell in the row was updated.
  core.int? totalUpdatedRows;

  /// The total number of sheets where at least one cell in the sheet was
  /// updated.
  core.int? totalUpdatedSheets;

  BatchUpdateValuesByDataFilterResponse();

  BatchUpdateValuesByDataFilterResponse.fromJson(core.Map _json) {
    if (_json.containsKey('responses')) {
      responses = (_json['responses'] as core.List)
          .map<UpdateValuesByDataFilterResponse>((value) =>
              UpdateValuesByDataFilterResponse.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
    if (_json.containsKey('totalUpdatedCells')) {
      totalUpdatedCells = _json['totalUpdatedCells'] as core.int;
    }
    if (_json.containsKey('totalUpdatedColumns')) {
      totalUpdatedColumns = _json['totalUpdatedColumns'] as core.int;
    }
    if (_json.containsKey('totalUpdatedRows')) {
      totalUpdatedRows = _json['totalUpdatedRows'] as core.int;
    }
    if (_json.containsKey('totalUpdatedSheets')) {
      totalUpdatedSheets = _json['totalUpdatedSheets'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (responses != null)
          'responses': responses!.map((value) => value.toJson()).toList(),
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
        if (totalUpdatedCells != null) 'totalUpdatedCells': totalUpdatedCells!,
        if (totalUpdatedColumns != null)
          'totalUpdatedColumns': totalUpdatedColumns!,
        if (totalUpdatedRows != null) 'totalUpdatedRows': totalUpdatedRows!,
        if (totalUpdatedSheets != null)
          'totalUpdatedSheets': totalUpdatedSheets!,
      };
}

/// The request for updating more than one range of values in a spreadsheet.
class BatchUpdateValuesRequest {
  /// The new values to apply to the spreadsheet.
  core.List<ValueRange>? data;

  /// Determines if the update response should include the values of the cells
  /// that were updated.
  ///
  /// By default, responses do not include the updated values. The `updatedData`
  /// field within each of the BatchUpdateValuesResponse.responses contains the
  /// updated values. If the range to write was larger than the range actually
  /// written, the response includes all values in the requested range
  /// (excluding trailing empty rows and columns).
  core.bool? includeValuesInResponse;

  /// Determines how dates, times, and durations in the response should be
  /// rendered.
  ///
  /// This is ignored if response_value_render_option is FORMATTED_VALUE. The
  /// default dateTime render option is SERIAL_NUMBER.
  /// Possible string values are:
  /// - "SERIAL_NUMBER" : Instructs date, time, datetime, and duration fields to
  /// be output as doubles in "serial number" format, as popularized by Lotus
  /// 1-2-3. The whole number portion of the value (left of the decimal) counts
  /// the days since December 30th 1899. The fractional portion (right of the
  /// decimal) counts the time as a fraction of the day. For example, January
  /// 1st 1900 at noon would be 2.5, 2 because it's 2 days after December 30st
  /// 1899, and .5 because noon is half a day. February 1st 1900 at 3pm would be
  /// 33.625. This correctly treats the year 1900 as not a leap year.
  /// - "FORMATTED_STRING" : Instructs date, time, datetime, and duration fields
  /// to be output as strings in their given number format (which is dependent
  /// on the spreadsheet locale).
  core.String? responseDateTimeRenderOption;

  /// Determines how values in the response should be rendered.
  ///
  /// The default render option is FORMATTED_VALUE.
  /// Possible string values are:
  /// - "FORMATTED_VALUE" : Values will be calculated & formatted in the reply
  /// according to the cell's formatting. Formatting is based on the
  /// spreadsheet's locale, not the requesting user's locale. For example, if
  /// `A1` is `1.23` and `A2` is `=A1` and formatted as currency, then `A2`
  /// would return `"$1.23"`.
  /// - "UNFORMATTED_VALUE" : Values will be calculated, but not formatted in
  /// the reply. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then `A2` would return the number `1.23`.
  /// - "FORMULA" : Values will not be calculated. The reply will include the
  /// formulas. For example, if `A1` is `1.23` and `A2` is `=A1` and formatted
  /// as currency, then A2 would return `"=A1"`.
  core.String? responseValueRenderOption;

  /// How the input data should be interpreted.
  /// Possible string values are:
  /// - "INPUT_VALUE_OPTION_UNSPECIFIED" : Default input value. This value must
  /// not be used.
  /// - "RAW" : The values the user has entered will not be parsed and will be
  /// stored as-is.
  /// - "USER_ENTERED" : The values will be parsed as if the user typed them
  /// into the UI. Numbers will stay as numbers, but strings may be converted to
  /// numbers, dates, etc. following the same rules that are applied when
  /// entering text into a cell via the Google Sheets UI.
  core.String? valueInputOption;

  BatchUpdateValuesRequest();

  BatchUpdateValuesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.List)
          .map<ValueRange>((value) =>
              ValueRange.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('includeValuesInResponse')) {
      includeValuesInResponse = _json['includeValuesInResponse'] as core.bool;
    }
    if (_json.containsKey('responseDateTimeRenderOption')) {
      responseDateTimeRenderOption =
          _json['responseDateTimeRenderOption'] as core.String;
    }
    if (_json.containsKey('responseValueRenderOption')) {
      responseValueRenderOption =
          _json['responseValueRenderOption'] as core.String;
    }
    if (_json.containsKey('valueInputOption')) {
      valueInputOption = _json['valueInputOption'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (data != null) 'data': data!.map((value) => value.toJson()).toList(),
        if (includeValuesInResponse != null)
          'includeValuesInResponse': includeValuesInResponse!,
        if (responseDateTimeRenderOption != null)
          'responseDateTimeRenderOption': responseDateTimeRenderOption!,
        if (responseValueRenderOption != null)
          'responseValueRenderOption': responseValueRenderOption!,
        if (valueInputOption != null) 'valueInputOption': valueInputOption!,
      };
}

/// The response when updating a range of values in a spreadsheet.
class BatchUpdateValuesResponse {
  /// One UpdateValuesResponse per requested range, in the same order as the
  /// requests appeared.
  core.List<UpdateValuesResponse>? responses;

  /// The spreadsheet the updates were applied to.
  core.String? spreadsheetId;

  /// The total number of cells updated.
  core.int? totalUpdatedCells;

  /// The total number of columns where at least one cell in the column was
  /// updated.
  core.int? totalUpdatedColumns;

  /// The total number of rows where at least one cell in the row was updated.
  core.int? totalUpdatedRows;

  /// The total number of sheets where at least one cell in the sheet was
  /// updated.
  core.int? totalUpdatedSheets;

  BatchUpdateValuesResponse();

  BatchUpdateValuesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('responses')) {
      responses = (_json['responses'] as core.List)
          .map<UpdateValuesResponse>((value) => UpdateValuesResponse.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
    if (_json.containsKey('totalUpdatedCells')) {
      totalUpdatedCells = _json['totalUpdatedCells'] as core.int;
    }
    if (_json.containsKey('totalUpdatedColumns')) {
      totalUpdatedColumns = _json['totalUpdatedColumns'] as core.int;
    }
    if (_json.containsKey('totalUpdatedRows')) {
      totalUpdatedRows = _json['totalUpdatedRows'] as core.int;
    }
    if (_json.containsKey('totalUpdatedSheets')) {
      totalUpdatedSheets = _json['totalUpdatedSheets'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (responses != null)
          'responses': responses!.map((value) => value.toJson()).toList(),
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
        if (totalUpdatedCells != null) 'totalUpdatedCells': totalUpdatedCells!,
        if (totalUpdatedColumns != null)
          'totalUpdatedColumns': totalUpdatedColumns!,
        if (totalUpdatedRows != null) 'totalUpdatedRows': totalUpdatedRows!,
        if (totalUpdatedSheets != null)
          'totalUpdatedSheets': totalUpdatedSheets!,
      };
}

/// The specification of a BigQuery data source that's connected to a sheet.
class BigQueryDataSourceSpec {
  /// The ID of a BigQuery enabled GCP project with a billing account attached.
  ///
  /// For any queries executed against the data source, the project is charged.
  core.String? projectId;

  /// A BigQueryQuerySpec.
  BigQueryQuerySpec? querySpec;

  /// A BigQueryTableSpec.
  BigQueryTableSpec? tableSpec;

  BigQueryDataSourceSpec();

  BigQueryDataSourceSpec.fromJson(core.Map _json) {
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('querySpec')) {
      querySpec = BigQueryQuerySpec.fromJson(
          _json['querySpec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableSpec')) {
      tableSpec = BigQueryTableSpec.fromJson(
          _json['tableSpec'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (projectId != null) 'projectId': projectId!,
        if (querySpec != null) 'querySpec': querySpec!.toJson(),
        if (tableSpec != null) 'tableSpec': tableSpec!.toJson(),
      };
}

/// Specifies a custom BigQuery query.
class BigQueryQuerySpec {
  /// The raw query string.
  core.String? rawQuery;

  BigQueryQuerySpec();

  BigQueryQuerySpec.fromJson(core.Map _json) {
    if (_json.containsKey('rawQuery')) {
      rawQuery = _json['rawQuery'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rawQuery != null) 'rawQuery': rawQuery!,
      };
}

/// Specifies a BigQuery table definition.
///
/// Only [native tables](https://cloud.google.com/bigquery/docs/tables-intro) is
/// allowed.
class BigQueryTableSpec {
  /// The BigQuery dataset id.
  core.String? datasetId;

  /// The BigQuery table id.
  core.String? tableId;

  /// The ID of a BigQuery project the table belongs to.
  ///
  /// If not specified, the project_id is assumed.
  core.String? tableProjectId;

  BigQueryTableSpec();

  BigQueryTableSpec.fromJson(core.Map _json) {
    if (_json.containsKey('datasetId')) {
      datasetId = _json['datasetId'] as core.String;
    }
    if (_json.containsKey('tableId')) {
      tableId = _json['tableId'] as core.String;
    }
    if (_json.containsKey('tableProjectId')) {
      tableProjectId = _json['tableProjectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (datasetId != null) 'datasetId': datasetId!,
        if (tableId != null) 'tableId': tableId!,
        if (tableProjectId != null) 'tableProjectId': tableProjectId!,
      };
}

/// A condition that can evaluate to true or false.
///
/// BooleanConditions are used by conditional formatting, data validation, and
/// the criteria in filters.
class BooleanCondition {
  /// The type of condition.
  /// Possible string values are:
  /// - "CONDITION_TYPE_UNSPECIFIED" : The default value, do not use.
  /// - "NUMBER_GREATER" : The cell's value must be greater than the condition's
  /// value. Supported by data validation, conditional formatting and filters.
  /// Requires a single ConditionValue.
  /// - "NUMBER_GREATER_THAN_EQ" : The cell's value must be greater than or
  /// equal to the condition's value. Supported by data validation, conditional
  /// formatting and filters. Requires a single ConditionValue.
  /// - "NUMBER_LESS" : The cell's value must be less than the condition's
  /// value. Supported by data validation, conditional formatting and filters.
  /// Requires a single ConditionValue.
  /// - "NUMBER_LESS_THAN_EQ" : The cell's value must be less than or equal to
  /// the condition's value. Supported by data validation, conditional
  /// formatting and filters. Requires a single ConditionValue.
  /// - "NUMBER_EQ" : The cell's value must be equal to the condition's value.
  /// Supported by data validation, conditional formatting and filters. Requires
  /// a single ConditionValue for data validation, conditional formatting, and
  /// filters on non-data source objects and at least one ConditionValue for
  /// filters on data source objects.
  /// - "NUMBER_NOT_EQ" : The cell's value must be not equal to the condition's
  /// value. Supported by data validation, conditional formatting and filters.
  /// Requires a single ConditionValue for data validation, conditional
  /// formatting, and filters on non-data source objects and at least one
  /// ConditionValue for filters on data source objects.
  /// - "NUMBER_BETWEEN" : The cell's value must be between the two condition
  /// values. Supported by data validation, conditional formatting and filters.
  /// Requires exactly two ConditionValues.
  /// - "NUMBER_NOT_BETWEEN" : The cell's value must not be between the two
  /// condition values. Supported by data validation, conditional formatting and
  /// filters. Requires exactly two ConditionValues.
  /// - "TEXT_CONTAINS" : The cell's value must contain the condition's value.
  /// Supported by data validation, conditional formatting and filters. Requires
  /// a single ConditionValue.
  /// - "TEXT_NOT_CONTAINS" : The cell's value must not contain the condition's
  /// value. Supported by data validation, conditional formatting and filters.
  /// Requires a single ConditionValue.
  /// - "TEXT_STARTS_WITH" : The cell's value must start with the condition's
  /// value. Supported by conditional formatting and filters. Requires a single
  /// ConditionValue.
  /// - "TEXT_ENDS_WITH" : The cell's value must end with the condition's value.
  /// Supported by conditional formatting and filters. Requires a single
  /// ConditionValue.
  /// - "TEXT_EQ" : The cell's value must be exactly the condition's value.
  /// Supported by data validation, conditional formatting and filters. Requires
  /// a single ConditionValue for data validation, conditional formatting, and
  /// filters on non-data source objects and at least one ConditionValue for
  /// filters on data source objects.
  /// - "TEXT_IS_EMAIL" : The cell's value must be a valid email address.
  /// Supported by data validation. Requires no ConditionValues.
  /// - "TEXT_IS_URL" : The cell's value must be a valid URL. Supported by data
  /// validation. Requires no ConditionValues.
  /// - "DATE_EQ" : The cell's value must be the same date as the condition's
  /// value. Supported by data validation, conditional formatting and filters.
  /// Requires a single ConditionValue for data validation, conditional
  /// formatting, and filters on non-data source objects and at least one
  /// ConditionValue for filters on data source objects.
  /// - "DATE_BEFORE" : The cell's value must be before the date of the
  /// condition's value. Supported by data validation, conditional formatting
  /// and filters. Requires a single ConditionValue that may be a relative date.
  /// - "DATE_AFTER" : The cell's value must be after the date of the
  /// condition's value. Supported by data validation, conditional formatting
  /// and filters. Requires a single ConditionValue that may be a relative date.
  /// - "DATE_ON_OR_BEFORE" : The cell's value must be on or before the date of
  /// the condition's value. Supported by data validation. Requires a single
  /// ConditionValue that may be a relative date.
  /// - "DATE_ON_OR_AFTER" : The cell's value must be on or after the date of
  /// the condition's value. Supported by data validation. Requires a single
  /// ConditionValue that may be a relative date.
  /// - "DATE_BETWEEN" : The cell's value must be between the dates of the two
  /// condition values. Supported by data validation. Requires exactly two
  /// ConditionValues.
  /// - "DATE_NOT_BETWEEN" : The cell's value must be outside the dates of the
  /// two condition values. Supported by data validation. Requires exactly two
  /// ConditionValues.
  /// - "DATE_IS_VALID" : The cell's value must be a date. Supported by data
  /// validation. Requires no ConditionValues.
  /// - "ONE_OF_RANGE" : The cell's value must be listed in the grid in
  /// condition value's range. Supported by data validation. Requires a single
  /// ConditionValue, and the value must be a valid range in A1 notation.
  /// - "ONE_OF_LIST" : The cell's value must be in the list of condition
  /// values. Supported by data validation. Supports any number of condition
  /// values, one per item in the list. Formulas are not supported in the
  /// values.
  /// - "BLANK" : The cell's value must be empty. Supported by conditional
  /// formatting and filters. Requires no ConditionValues.
  /// - "NOT_BLANK" : The cell's value must not be empty. Supported by
  /// conditional formatting and filters. Requires no ConditionValues.
  /// - "CUSTOM_FORMULA" : The condition's formula must evaluate to true.
  /// Supported by data validation, conditional formatting and filters. Not
  /// supported by data source sheet filters. Requires a single ConditionValue.
  /// - "BOOLEAN" : The cell's value must be TRUE/FALSE or in the list of
  /// condition values. Supported by data validation. Renders as a cell
  /// checkbox. Supports zero, one or two ConditionValues. No values indicates
  /// the cell must be TRUE or FALSE, where TRUE renders as checked and FALSE
  /// renders as unchecked. One value indicates the cell will render as checked
  /// when it contains that value and unchecked when it is blank. Two values
  /// indicate that the cell will render as checked when it contains the first
  /// value and unchecked when it contains the second value. For example,
  /// \["Yes","No"\] indicates that the cell will render a checked box when it
  /// has the value "Yes" and an unchecked box when it has the value "No".
  /// - "TEXT_NOT_EQ" : The cell's value must be exactly not the condition's
  /// value. Supported by filters on data source objects. Requires at least one
  /// ConditionValue.
  /// - "DATE_NOT_EQ" : The cell's value must be exactly not the condition's
  /// value. Supported by filters on data source objects. Requires at least one
  /// ConditionValue.
  core.String? type;

  /// The values of the condition.
  ///
  /// The number of supported values depends on the condition type. Some support
  /// zero values, others one or two values, and ConditionType.ONE_OF_LIST
  /// supports an arbitrary number of values.
  core.List<ConditionValue>? values;

  BooleanCondition();

  BooleanCondition.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<ConditionValue>((value) => ConditionValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
        if (values != null)
          'values': values!.map((value) => value.toJson()).toList(),
      };
}

/// A rule that may or may not match, depending on the condition.
class BooleanRule {
  /// The condition of the rule.
  ///
  /// If the condition evaluates to true, the format is applied.
  BooleanCondition? condition;

  /// The format to apply.
  ///
  /// Conditional formatting can only apply a subset of formatting: bold,
  /// italic, strikethrough, foreground color & background color.
  CellFormat? format;

  BooleanRule();

  BooleanRule.fromJson(core.Map _json) {
    if (_json.containsKey('condition')) {
      condition = BooleanCondition.fromJson(
          _json['condition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('format')) {
      format = CellFormat.fromJson(
          _json['format'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (condition != null) 'condition': condition!.toJson(),
        if (format != null) 'format': format!.toJson(),
      };
}

/// A border along a cell.
class Border {
  /// The color of the border.
  Color? color;

  /// The color of the border.
  ///
  /// If color is also set, this field takes precedence.
  ColorStyle? colorStyle;

  /// The style of the border.
  /// Possible string values are:
  /// - "STYLE_UNSPECIFIED" : The style is not specified. Do not use this.
  /// - "DOTTED" : The border is dotted.
  /// - "DASHED" : The border is dashed.
  /// - "SOLID" : The border is a thin solid line.
  /// - "SOLID_MEDIUM" : The border is a medium solid line.
  /// - "SOLID_THICK" : The border is a thick solid line.
  /// - "NONE" : No border. Used only when updating a border in order to erase
  /// it.
  /// - "DOUBLE" : The border is two solid lines.
  core.String? style;

  /// The width of the border, in pixels.
  ///
  /// Deprecated; the width is determined by the "style" field.
  core.int? width;

  Border();

  Border.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color =
          Color.fromJson(_json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('colorStyle')) {
      colorStyle = ColorStyle.fromJson(
          _json['colorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('style')) {
      style = _json['style'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
        if (colorStyle != null) 'colorStyle': colorStyle!.toJson(),
        if (style != null) 'style': style!,
        if (width != null) 'width': width!,
      };
}

/// The borders of the cell.
class Borders {
  /// The bottom border of the cell.
  Border? bottom;

  /// The left border of the cell.
  Border? left;

  /// The right border of the cell.
  Border? right;

  /// The top border of the cell.
  Border? top;

  Borders();

  Borders.fromJson(core.Map _json) {
    if (_json.containsKey('bottom')) {
      bottom = Border.fromJson(
          _json['bottom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('left')) {
      left =
          Border.fromJson(_json['left'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('right')) {
      right = Border.fromJson(
          _json['right'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('top')) {
      top =
          Border.fromJson(_json['top'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bottom != null) 'bottom': bottom!.toJson(),
        if (left != null) 'left': left!.toJson(),
        if (right != null) 'right': right!.toJson(),
        if (top != null) 'top': top!.toJson(),
      };
}

/// A bubble chart.
class BubbleChartSpec {
  /// The bubble border color.
  Color? bubbleBorderColor;

  /// The bubble border color.
  ///
  /// If bubble_border_color is also set, this field takes precedence.
  ColorStyle? bubbleBorderColorStyle;

  /// The data containing the bubble labels.
  ///
  /// These do not need to be unique.
  ChartData? bubbleLabels;

  /// The max radius size of the bubbles, in pixels.
  ///
  /// If specified, the field must be a positive value.
  core.int? bubbleMaxRadiusSize;

  /// The minimum radius size of the bubbles, in pixels.
  ///
  /// If specific, the field must be a positive value.
  core.int? bubbleMinRadiusSize;

  /// The opacity of the bubbles between 0 and 1.0.
  ///
  /// 0 is fully transparent and 1 is fully opaque.
  core.double? bubbleOpacity;

  /// The data containing the bubble sizes.
  ///
  /// Bubble sizes are used to draw the bubbles at different sizes relative to
  /// each other. If specified, group_ids must also be specified. This field is
  /// optional.
  ChartData? bubbleSizes;

  /// The format of the text inside the bubbles.
  ///
  /// Strikethrough, underline, and link are not supported.
  TextFormat? bubbleTextStyle;

  /// The data containing the bubble x-values.
  ///
  /// These values locate the bubbles in the chart horizontally.
  ChartData? domain;

  /// The data containing the bubble group IDs.
  ///
  /// All bubbles with the same group ID are drawn in the same color. If
  /// bubble_sizes is specified then this field must also be specified but may
  /// contain blank values. This field is optional.
  ChartData? groupIds;

  /// Where the legend of the chart should be drawn.
  /// Possible string values are:
  /// - "BUBBLE_CHART_LEGEND_POSITION_UNSPECIFIED" : Default value, do not use.
  /// - "BOTTOM_LEGEND" : The legend is rendered on the bottom of the chart.
  /// - "LEFT_LEGEND" : The legend is rendered on the left of the chart.
  /// - "RIGHT_LEGEND" : The legend is rendered on the right of the chart.
  /// - "TOP_LEGEND" : The legend is rendered on the top of the chart.
  /// - "NO_LEGEND" : No legend is rendered.
  /// - "INSIDE_LEGEND" : The legend is rendered inside the chart area.
  core.String? legendPosition;

  /// The data containing the bubble y-values.
  ///
  /// These values locate the bubbles in the chart vertically.
  ChartData? series;

  BubbleChartSpec();

  BubbleChartSpec.fromJson(core.Map _json) {
    if (_json.containsKey('bubbleBorderColor')) {
      bubbleBorderColor = Color.fromJson(
          _json['bubbleBorderColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('bubbleBorderColorStyle')) {
      bubbleBorderColorStyle = ColorStyle.fromJson(
          _json['bubbleBorderColorStyle']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('bubbleLabels')) {
      bubbleLabels = ChartData.fromJson(
          _json['bubbleLabels'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('bubbleMaxRadiusSize')) {
      bubbleMaxRadiusSize = _json['bubbleMaxRadiusSize'] as core.int;
    }
    if (_json.containsKey('bubbleMinRadiusSize')) {
      bubbleMinRadiusSize = _json['bubbleMinRadiusSize'] as core.int;
    }
    if (_json.containsKey('bubbleOpacity')) {
      bubbleOpacity = (_json['bubbleOpacity'] as core.num).toDouble();
    }
    if (_json.containsKey('bubbleSizes')) {
      bubbleSizes = ChartData.fromJson(
          _json['bubbleSizes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('bubbleTextStyle')) {
      bubbleTextStyle = TextFormat.fromJson(
          _json['bubbleTextStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('domain')) {
      domain = ChartData.fromJson(
          _json['domain'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('groupIds')) {
      groupIds = ChartData.fromJson(
          _json['groupIds'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('legendPosition')) {
      legendPosition = _json['legendPosition'] as core.String;
    }
    if (_json.containsKey('series')) {
      series = ChartData.fromJson(
          _json['series'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bubbleBorderColor != null)
          'bubbleBorderColor': bubbleBorderColor!.toJson(),
        if (bubbleBorderColorStyle != null)
          'bubbleBorderColorStyle': bubbleBorderColorStyle!.toJson(),
        if (bubbleLabels != null) 'bubbleLabels': bubbleLabels!.toJson(),
        if (bubbleMaxRadiusSize != null)
          'bubbleMaxRadiusSize': bubbleMaxRadiusSize!,
        if (bubbleMinRadiusSize != null)
          'bubbleMinRadiusSize': bubbleMinRadiusSize!,
        if (bubbleOpacity != null) 'bubbleOpacity': bubbleOpacity!,
        if (bubbleSizes != null) 'bubbleSizes': bubbleSizes!.toJson(),
        if (bubbleTextStyle != null)
          'bubbleTextStyle': bubbleTextStyle!.toJson(),
        if (domain != null) 'domain': domain!.toJson(),
        if (groupIds != null) 'groupIds': groupIds!.toJson(),
        if (legendPosition != null) 'legendPosition': legendPosition!,
        if (series != null) 'series': series!.toJson(),
      };
}

/// A candlestick chart.
class CandlestickChartSpec {
  /// The Candlestick chart data.
  ///
  /// Only one CandlestickData is supported.
  core.List<CandlestickData>? data;

  /// The domain data (horizontal axis) for the candlestick chart.
  ///
  /// String data will be treated as discrete labels, other data will be treated
  /// as continuous values.
  CandlestickDomain? domain;

  CandlestickChartSpec();

  CandlestickChartSpec.fromJson(core.Map _json) {
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.List)
          .map<CandlestickData>((value) => CandlestickData.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('domain')) {
      domain = CandlestickDomain.fromJson(
          _json['domain'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (data != null) 'data': data!.map((value) => value.toJson()).toList(),
        if (domain != null) 'domain': domain!.toJson(),
      };
}

/// The Candlestick chart data, each containing the low, open, close, and high
/// values for a series.
class CandlestickData {
  /// The range data (vertical axis) for the close/final value for each candle.
  ///
  /// This is the top of the candle body. If greater than the open value the
  /// candle will be filled. Otherwise the candle will be hollow.
  CandlestickSeries? closeSeries;

  /// The range data (vertical axis) for the high/maximum value for each candle.
  ///
  /// This is the top of the candle's center line.
  CandlestickSeries? highSeries;

  /// The range data (vertical axis) for the low/minimum value for each candle.
  ///
  /// This is the bottom of the candle's center line.
  CandlestickSeries? lowSeries;

  /// The range data (vertical axis) for the open/initial value for each candle.
  ///
  /// This is the bottom of the candle body. If less than the close value the
  /// candle will be filled. Otherwise the candle will be hollow.
  CandlestickSeries? openSeries;

  CandlestickData();

  CandlestickData.fromJson(core.Map _json) {
    if (_json.containsKey('closeSeries')) {
      closeSeries = CandlestickSeries.fromJson(
          _json['closeSeries'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('highSeries')) {
      highSeries = CandlestickSeries.fromJson(
          _json['highSeries'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lowSeries')) {
      lowSeries = CandlestickSeries.fromJson(
          _json['lowSeries'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('openSeries')) {
      openSeries = CandlestickSeries.fromJson(
          _json['openSeries'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (closeSeries != null) 'closeSeries': closeSeries!.toJson(),
        if (highSeries != null) 'highSeries': highSeries!.toJson(),
        if (lowSeries != null) 'lowSeries': lowSeries!.toJson(),
        if (openSeries != null) 'openSeries': openSeries!.toJson(),
      };
}

/// The domain of a CandlestickChart.
class CandlestickDomain {
  /// The data of the CandlestickDomain.
  ChartData? data;

  /// True to reverse the order of the domain values (horizontal axis).
  core.bool? reversed;

  CandlestickDomain();

  CandlestickDomain.fromJson(core.Map _json) {
    if (_json.containsKey('data')) {
      data = ChartData.fromJson(
          _json['data'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reversed')) {
      reversed = _json['reversed'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (data != null) 'data': data!.toJson(),
        if (reversed != null) 'reversed': reversed!,
      };
}

/// The series of a CandlestickData.
class CandlestickSeries {
  /// The data of the CandlestickSeries.
  ChartData? data;

  CandlestickSeries();

  CandlestickSeries.fromJson(core.Map _json) {
    if (_json.containsKey('data')) {
      data = ChartData.fromJson(
          _json['data'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (data != null) 'data': data!.toJson(),
      };
}

/// Data about a specific cell.
class CellData {
  /// Information about a data source formula on the cell.
  ///
  /// The field is set if user_entered_value is a formula referencing some
  /// DATA_SOURCE sheet, e.g. `=SUM(DataSheet!Column)`.
  ///
  /// Output only.
  DataSourceFormula? dataSourceFormula;

  /// A data source table anchored at this cell.
  ///
  /// The size of data source table itself is computed dynamically based on its
  /// configuration. Only the first cell of the data source table contains the
  /// data source table definition. The other cells will contain the display
  /// values of the data source table result in their effective_value fields.
  DataSourceTable? dataSourceTable;

  /// A data validation rule on the cell, if any.
  ///
  /// When writing, the new data validation rule will overwrite any prior rule.
  DataValidationRule? dataValidation;

  /// The effective format being used by the cell.
  ///
  /// This includes the results of applying any conditional formatting and, if
  /// the cell contains a formula, the computed number format. If the effective
  /// format is the default format, effective format will not be written. This
  /// field is read-only.
  CellFormat? effectiveFormat;

  /// The effective value of the cell.
  ///
  /// For cells with formulas, this is the calculated value. For cells with
  /// literals, this is the same as the user_entered_value. This field is
  /// read-only.
  ExtendedValue? effectiveValue;

  /// The formatted value of the cell.
  ///
  /// This is the value as it's shown to the user. This field is read-only.
  core.String? formattedValue;

  /// A hyperlink this cell points to, if any.
  ///
  /// If the cell contains multiple hyperlinks, this field will be empty. This
  /// field is read-only. To set it, use a `=HYPERLINK` formula in the
  /// userEnteredValue.formulaValue field. A cell-level link can also be set
  /// from the userEnteredFormat.textFormat field. Alternatively, set a
  /// hyperlink in the textFormatRun.format.link field that spans the entire
  /// cell.
  core.String? hyperlink;

  /// Any note on the cell.
  core.String? note;

  /// A pivot table anchored at this cell.
  ///
  /// The size of pivot table itself is computed dynamically based on its data,
  /// grouping, filters, values, etc. Only the top-left cell of the pivot table
  /// contains the pivot table definition. The other cells will contain the
  /// calculated values of the results of the pivot in their effective_value
  /// fields.
  PivotTable? pivotTable;

  /// Runs of rich text applied to subsections of the cell.
  ///
  /// Runs are only valid on user entered strings, not formulas, bools, or
  /// numbers. Properties of a run start at a specific index in the text and
  /// continue until the next run. Runs will inherit the properties of the cell
  /// unless explicitly changed. When writing, the new runs will overwrite any
  /// prior runs. When writing a new user_entered_value, previous runs are
  /// erased.
  core.List<TextFormatRun>? textFormatRuns;

  /// The format the user entered for the cell.
  ///
  /// When writing, the new format will be merged with the existing format.
  CellFormat? userEnteredFormat;

  /// The value the user entered in the cell.
  ///
  /// e.g, `1234`, `'Hello'`, or `=NOW()` Note: Dates, Times and DateTimes are
  /// represented as doubles in serial number format.
  ExtendedValue? userEnteredValue;

  CellData();

  CellData.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceFormula')) {
      dataSourceFormula = DataSourceFormula.fromJson(
          _json['dataSourceFormula'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataSourceTable')) {
      dataSourceTable = DataSourceTable.fromJson(
          _json['dataSourceTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataValidation')) {
      dataValidation = DataValidationRule.fromJson(
          _json['dataValidation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('effectiveFormat')) {
      effectiveFormat = CellFormat.fromJson(
          _json['effectiveFormat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('effectiveValue')) {
      effectiveValue = ExtendedValue.fromJson(
          _json['effectiveValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('formattedValue')) {
      formattedValue = _json['formattedValue'] as core.String;
    }
    if (_json.containsKey('hyperlink')) {
      hyperlink = _json['hyperlink'] as core.String;
    }
    if (_json.containsKey('note')) {
      note = _json['note'] as core.String;
    }
    if (_json.containsKey('pivotTable')) {
      pivotTable = PivotTable.fromJson(
          _json['pivotTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textFormatRuns')) {
      textFormatRuns = (_json['textFormatRuns'] as core.List)
          .map<TextFormatRun>((value) => TextFormatRun.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('userEnteredFormat')) {
      userEnteredFormat = CellFormat.fromJson(
          _json['userEnteredFormat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('userEnteredValue')) {
      userEnteredValue = ExtendedValue.fromJson(
          _json['userEnteredValue'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceFormula != null)
          'dataSourceFormula': dataSourceFormula!.toJson(),
        if (dataSourceTable != null)
          'dataSourceTable': dataSourceTable!.toJson(),
        if (dataValidation != null) 'dataValidation': dataValidation!.toJson(),
        if (effectiveFormat != null)
          'effectiveFormat': effectiveFormat!.toJson(),
        if (effectiveValue != null) 'effectiveValue': effectiveValue!.toJson(),
        if (formattedValue != null) 'formattedValue': formattedValue!,
        if (hyperlink != null) 'hyperlink': hyperlink!,
        if (note != null) 'note': note!,
        if (pivotTable != null) 'pivotTable': pivotTable!.toJson(),
        if (textFormatRuns != null)
          'textFormatRuns':
              textFormatRuns!.map((value) => value.toJson()).toList(),
        if (userEnteredFormat != null)
          'userEnteredFormat': userEnteredFormat!.toJson(),
        if (userEnteredValue != null)
          'userEnteredValue': userEnteredValue!.toJson(),
      };
}

/// The format of a cell.
class CellFormat {
  /// The background color of the cell.
  Color? backgroundColor;

  /// The background color of the cell.
  ///
  /// If background_color is also set, this field takes precedence.
  ColorStyle? backgroundColorStyle;

  /// The borders of the cell.
  Borders? borders;

  /// The horizontal alignment of the value in the cell.
  /// Possible string values are:
  /// - "HORIZONTAL_ALIGN_UNSPECIFIED" : The horizontal alignment is not
  /// specified. Do not use this.
  /// - "LEFT" : The text is explicitly aligned to the left of the cell.
  /// - "CENTER" : The text is explicitly aligned to the center of the cell.
  /// - "RIGHT" : The text is explicitly aligned to the right of the cell.
  core.String? horizontalAlignment;

  /// How a hyperlink, if it exists, should be displayed in the cell.
  /// Possible string values are:
  /// - "HYPERLINK_DISPLAY_TYPE_UNSPECIFIED" : The default value: the hyperlink
  /// is rendered. Do not use this.
  /// - "LINKED" : A hyperlink should be explicitly rendered.
  /// - "PLAIN_TEXT" : A hyperlink should not be rendered.
  core.String? hyperlinkDisplayType;

  /// A format describing how number values should be represented to the user.
  NumberFormat? numberFormat;

  /// The padding of the cell.
  Padding? padding;

  /// The direction of the text in the cell.
  /// Possible string values are:
  /// - "TEXT_DIRECTION_UNSPECIFIED" : The text direction is not specified. Do
  /// not use this.
  /// - "LEFT_TO_RIGHT" : The text direction of left-to-right was set by the
  /// user.
  /// - "RIGHT_TO_LEFT" : The text direction of right-to-left was set by the
  /// user.
  core.String? textDirection;

  /// The format of the text in the cell (unless overridden by a format run).
  ///
  /// Setting a cell-level link will clear the cell's existing links. Setting a
  /// link in a format run will clear the cell-level link.
  TextFormat? textFormat;

  /// The rotation applied to text in a cell
  TextRotation? textRotation;

  /// The vertical alignment of the value in the cell.
  /// Possible string values are:
  /// - "VERTICAL_ALIGN_UNSPECIFIED" : The vertical alignment is not specified.
  /// Do not use this.
  /// - "TOP" : The text is explicitly aligned to the top of the cell.
  /// - "MIDDLE" : The text is explicitly aligned to the middle of the cell.
  /// - "BOTTOM" : The text is explicitly aligned to the bottom of the cell.
  core.String? verticalAlignment;

  /// The wrap strategy for the value in the cell.
  /// Possible string values are:
  /// - "WRAP_STRATEGY_UNSPECIFIED" : The default value, do not use.
  /// - "OVERFLOW_CELL" : Lines that are longer than the cell width will be
  /// written in the next cell over, so long as that cell is empty. If the next
  /// cell over is non-empty, this behaves the same as `CLIP`. The text will
  /// never wrap to the next line unless the user manually inserts a new line.
  /// Example: | First sentence. | | Manual newline that is very long. <- Text
  /// continues into next cell | Next newline. |
  /// - "LEGACY_WRAP" : This wrap strategy represents the old Google Sheets wrap
  /// strategy where words that are longer than a line are clipped rather than
  /// broken. This strategy is not supported on all platforms and is being
  /// phased out. Example: | Cell has a | | loooooooooo| <- Word is clipped. |
  /// word. |
  /// - "CLIP" : Lines that are longer than the cell width will be clipped. The
  /// text will never wrap to the next line unless the user manually inserts a
  /// new line. Example: | First sentence. | | Manual newline t| <- Text is
  /// clipped | Next newline. |
  /// - "WRAP" : Words that are longer than a line are wrapped at the character
  /// level rather than clipped. Example: | Cell has a | | loooooooooo| <- Word
  /// is broken. | ong word. |
  core.String? wrapStrategy;

  CellFormat();

  CellFormat.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundColor')) {
      backgroundColor = Color.fromJson(
          _json['backgroundColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('backgroundColorStyle')) {
      backgroundColorStyle = ColorStyle.fromJson(
          _json['backgroundColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('borders')) {
      borders = Borders.fromJson(
          _json['borders'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('horizontalAlignment')) {
      horizontalAlignment = _json['horizontalAlignment'] as core.String;
    }
    if (_json.containsKey('hyperlinkDisplayType')) {
      hyperlinkDisplayType = _json['hyperlinkDisplayType'] as core.String;
    }
    if (_json.containsKey('numberFormat')) {
      numberFormat = NumberFormat.fromJson(
          _json['numberFormat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('padding')) {
      padding = Padding.fromJson(
          _json['padding'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textDirection')) {
      textDirection = _json['textDirection'] as core.String;
    }
    if (_json.containsKey('textFormat')) {
      textFormat = TextFormat.fromJson(
          _json['textFormat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textRotation')) {
      textRotation = TextRotation.fromJson(
          _json['textRotation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('verticalAlignment')) {
      verticalAlignment = _json['verticalAlignment'] as core.String;
    }
    if (_json.containsKey('wrapStrategy')) {
      wrapStrategy = _json['wrapStrategy'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundColor != null)
          'backgroundColor': backgroundColor!.toJson(),
        if (backgroundColorStyle != null)
          'backgroundColorStyle': backgroundColorStyle!.toJson(),
        if (borders != null) 'borders': borders!.toJson(),
        if (horizontalAlignment != null)
          'horizontalAlignment': horizontalAlignment!,
        if (hyperlinkDisplayType != null)
          'hyperlinkDisplayType': hyperlinkDisplayType!,
        if (numberFormat != null) 'numberFormat': numberFormat!.toJson(),
        if (padding != null) 'padding': padding!.toJson(),
        if (textDirection != null) 'textDirection': textDirection!,
        if (textFormat != null) 'textFormat': textFormat!.toJson(),
        if (textRotation != null) 'textRotation': textRotation!.toJson(),
        if (verticalAlignment != null) 'verticalAlignment': verticalAlignment!,
        if (wrapStrategy != null) 'wrapStrategy': wrapStrategy!,
      };
}

/// The options that define a "view window" for a chart (such as the visible
/// values in an axis).
class ChartAxisViewWindowOptions {
  /// The maximum numeric value to be shown in this view window.
  ///
  /// If unset, will automatically determine a maximum value that looks good for
  /// the data.
  core.double? viewWindowMax;

  /// The minimum numeric value to be shown in this view window.
  ///
  /// If unset, will automatically determine a minimum value that looks good for
  /// the data.
  core.double? viewWindowMin;

  /// The view window's mode.
  /// Possible string values are:
  /// - "DEFAULT_VIEW_WINDOW_MODE" : The default view window mode used in the
  /// Sheets editor for this chart type. In most cases, if set, the default mode
  /// is equivalent to `PRETTY`.
  /// - "VIEW_WINDOW_MODE_UNSUPPORTED" : Do not use. Represents that the
  /// currently set mode is not supported by the API.
  /// - "EXPLICIT" : Follows the min and max exactly if specified. If a value is
  /// unspecified, it will fall back to the `PRETTY` value.
  /// - "PRETTY" : Chooses a min and max that make the chart look good. Both min
  /// and max are ignored in this mode.
  core.String? viewWindowMode;

  ChartAxisViewWindowOptions();

  ChartAxisViewWindowOptions.fromJson(core.Map _json) {
    if (_json.containsKey('viewWindowMax')) {
      viewWindowMax = (_json['viewWindowMax'] as core.num).toDouble();
    }
    if (_json.containsKey('viewWindowMin')) {
      viewWindowMin = (_json['viewWindowMin'] as core.num).toDouble();
    }
    if (_json.containsKey('viewWindowMode')) {
      viewWindowMode = _json['viewWindowMode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (viewWindowMax != null) 'viewWindowMax': viewWindowMax!,
        if (viewWindowMin != null) 'viewWindowMin': viewWindowMin!,
        if (viewWindowMode != null) 'viewWindowMode': viewWindowMode!,
      };
}

/// Custom number formatting options for chart attributes.
class ChartCustomNumberFormatOptions {
  /// Custom prefix to be prepended to the chart attribute.
  ///
  /// This field is optional.
  core.String? prefix;

  /// Custom suffix to be appended to the chart attribute.
  ///
  /// This field is optional.
  core.String? suffix;

  ChartCustomNumberFormatOptions();

  ChartCustomNumberFormatOptions.fromJson(core.Map _json) {
    if (_json.containsKey('prefix')) {
      prefix = _json['prefix'] as core.String;
    }
    if (_json.containsKey('suffix')) {
      suffix = _json['suffix'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (prefix != null) 'prefix': prefix!,
        if (suffix != null) 'suffix': suffix!,
      };
}

/// The data included in a domain or series.
class ChartData {
  /// The aggregation type for the series of a data source chart.
  ///
  /// Only supported for data source charts.
  /// Possible string values are:
  /// - "CHART_AGGREGATE_TYPE_UNSPECIFIED" : Default value, do not use.
  /// - "AVERAGE" : Average aggregate function.
  /// - "COUNT" : Count aggregate function.
  /// - "MAX" : Maximum aggregate function.
  /// - "MEDIAN" : Median aggregate function.
  /// - "MIN" : Minimum aggregate function.
  /// - "SUM" : Sum aggregate function.
  core.String? aggregateType;

  /// The reference to the data source column that the data reads from.
  DataSourceColumnReference? columnReference;

  /// The rule to group the data by if the ChartData backs the domain of a data
  /// source chart.
  ///
  /// Only supported for data source charts.
  ChartGroupRule? groupRule;

  /// The source ranges of the data.
  ChartSourceRange? sourceRange;

  ChartData();

  ChartData.fromJson(core.Map _json) {
    if (_json.containsKey('aggregateType')) {
      aggregateType = _json['aggregateType'] as core.String;
    }
    if (_json.containsKey('columnReference')) {
      columnReference = DataSourceColumnReference.fromJson(
          _json['columnReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('groupRule')) {
      groupRule = ChartGroupRule.fromJson(
          _json['groupRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sourceRange')) {
      sourceRange = ChartSourceRange.fromJson(
          _json['sourceRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aggregateType != null) 'aggregateType': aggregateType!,
        if (columnReference != null)
          'columnReference': columnReference!.toJson(),
        if (groupRule != null) 'groupRule': groupRule!.toJson(),
        if (sourceRange != null) 'sourceRange': sourceRange!.toJson(),
      };
}

/// Allows you to organize the date-time values in a source data column into
/// buckets based on selected parts of their date or time values.
class ChartDateTimeRule {
  /// The type of date-time grouping to apply.
  /// Possible string values are:
  /// - "CHART_DATE_TIME_RULE_TYPE_UNSPECIFIED" : The default type, do not use.
  /// - "SECOND" : Group dates by second, from 0 to 59.
  /// - "MINUTE" : Group dates by minute, from 0 to 59.
  /// - "HOUR" : Group dates by hour using a 24-hour system, from 0 to 23.
  /// - "HOUR_MINUTE" : Group dates by hour and minute using a 24-hour system,
  /// for example 19:45.
  /// - "HOUR_MINUTE_AMPM" : Group dates by hour and minute using a 12-hour
  /// system, for example 7:45 PM. The AM/PM designation is translated based on
  /// the spreadsheet locale.
  /// - "DAY_OF_WEEK" : Group dates by day of week, for example Sunday. The days
  /// of the week will be translated based on the spreadsheet locale.
  /// - "DAY_OF_YEAR" : Group dates by day of year, from 1 to 366. Note that
  /// dates after Feb. 29 fall in different buckets in leap years than in
  /// non-leap years.
  /// - "DAY_OF_MONTH" : Group dates by day of month, from 1 to 31.
  /// - "DAY_MONTH" : Group dates by day and month, for example 22-Nov. The
  /// month is translated based on the spreadsheet locale.
  /// - "MONTH" : Group dates by month, for example Nov. The month is translated
  /// based on the spreadsheet locale.
  /// - "QUARTER" : Group dates by quarter, for example Q1 (which represents
  /// Jan-Mar).
  /// - "YEAR" : Group dates by year, for example 2008.
  /// - "YEAR_MONTH" : Group dates by year and month, for example 2008-Nov. The
  /// month is translated based on the spreadsheet locale.
  /// - "YEAR_QUARTER" : Group dates by year and quarter, for example 2008 Q4.
  /// - "YEAR_MONTH_DAY" : Group dates by year, month, and day, for example
  /// 2008-11-22.
  core.String? type;

  ChartDateTimeRule();

  ChartDateTimeRule.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
      };
}

/// An optional setting on the ChartData of the domain of a data source chart
/// that defines buckets for the values in the domain rather than breaking out
/// each individual value.
///
/// For example, when plotting a data source chart, you can specify a histogram
/// rule on the domain (it should only contain numeric values), grouping its
/// values into buckets. Any values of a chart series that fall into the same
/// bucket are aggregated based on the aggregate_type.
class ChartGroupRule {
  /// A ChartDateTimeRule.
  ChartDateTimeRule? dateTimeRule;

  /// A ChartHistogramRule
  ChartHistogramRule? histogramRule;

  ChartGroupRule();

  ChartGroupRule.fromJson(core.Map _json) {
    if (_json.containsKey('dateTimeRule')) {
      dateTimeRule = ChartDateTimeRule.fromJson(
          _json['dateTimeRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('histogramRule')) {
      histogramRule = ChartHistogramRule.fromJson(
          _json['histogramRule'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dateTimeRule != null) 'dateTimeRule': dateTimeRule!.toJson(),
        if (histogramRule != null) 'histogramRule': histogramRule!.toJson(),
      };
}

/// Allows you to organize numeric values in a source data column into buckets
/// of constant size.
class ChartHistogramRule {
  /// The size of the buckets that are created.
  ///
  /// Must be positive.
  core.double? intervalSize;

  /// The maximum value at which items are placed into buckets.
  ///
  /// Values greater than the maximum are grouped into a single bucket. If
  /// omitted, it is determined by the maximum item value.
  core.double? maxValue;

  /// The minimum value at which items are placed into buckets.
  ///
  /// Values that are less than the minimum are grouped into a single bucket. If
  /// omitted, it is determined by the minimum item value.
  core.double? minValue;

  ChartHistogramRule();

  ChartHistogramRule.fromJson(core.Map _json) {
    if (_json.containsKey('intervalSize')) {
      intervalSize = (_json['intervalSize'] as core.num).toDouble();
    }
    if (_json.containsKey('maxValue')) {
      maxValue = (_json['maxValue'] as core.num).toDouble();
    }
    if (_json.containsKey('minValue')) {
      minValue = (_json['minValue'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (intervalSize != null) 'intervalSize': intervalSize!,
        if (maxValue != null) 'maxValue': maxValue!,
        if (minValue != null) 'minValue': minValue!,
      };
}

/// Source ranges for a chart.
class ChartSourceRange {
  /// The ranges of data for a series or domain.
  ///
  /// Exactly one dimension must have a length of 1, and all sources in the list
  /// must have the same dimension with length 1. The domain (if it exists) &
  /// all series must have the same number of source ranges. If using more than
  /// one source range, then the source range at a given offset must be in order
  /// and contiguous across the domain and series. For example, these are valid
  /// configurations: domain sources: A1:A5 series1 sources: B1:B5 series2
  /// sources: D6:D10 domain sources: A1:A5, C10:C12 series1 sources: B1:B5,
  /// D10:D12 series2 sources: C1:C5, E10:E12
  core.List<GridRange>? sources;

  ChartSourceRange();

  ChartSourceRange.fromJson(core.Map _json) {
    if (_json.containsKey('sources')) {
      sources = (_json['sources'] as core.List)
          .map<GridRange>((value) =>
              GridRange.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sources != null)
          'sources': sources!.map((value) => value.toJson()).toList(),
      };
}

/// The specifications of a chart.
class ChartSpec {
  /// The alternative text that describes the chart.
  ///
  /// This is often used for accessibility.
  core.String? altText;

  /// The background color of the entire chart.
  ///
  /// Not applicable to Org charts.
  Color? backgroundColor;

  /// The background color of the entire chart.
  ///
  /// Not applicable to Org charts. If background_color is also set, this field
  /// takes precedence.
  ColorStyle? backgroundColorStyle;

  /// A basic chart specification, can be one of many kinds of charts.
  ///
  /// See BasicChartType for the list of all charts this supports.
  BasicChartSpec? basicChart;

  /// A bubble chart specification.
  BubbleChartSpec? bubbleChart;

  /// A candlestick chart specification.
  CandlestickChartSpec? candlestickChart;

  /// If present, the field contains data source chart specific properties.
  DataSourceChartProperties? dataSourceChartProperties;

  /// The filters applied to the source data of the chart.
  ///
  /// Only supported for data source charts.
  core.List<FilterSpec>? filterSpecs;

  /// The name of the font to use by default for all chart text (e.g. title,
  /// axis labels, legend).
  ///
  /// If a font is specified for a specific part of the chart it will override
  /// this font name.
  core.String? fontName;

  /// Determines how the charts will use hidden rows or columns.
  /// Possible string values are:
  /// - "CHART_HIDDEN_DIMENSION_STRATEGY_UNSPECIFIED" : Default value, do not
  /// use.
  /// - "SKIP_HIDDEN_ROWS_AND_COLUMNS" : Charts will skip hidden rows and
  /// columns.
  /// - "SKIP_HIDDEN_ROWS" : Charts will skip hidden rows only.
  /// - "SKIP_HIDDEN_COLUMNS" : Charts will skip hidden columns only.
  /// - "SHOW_ALL" : Charts will not skip any hidden rows or columns.
  core.String? hiddenDimensionStrategy;

  /// A histogram chart specification.
  HistogramChartSpec? histogramChart;

  /// True to make a chart fill the entire space in which it's rendered with
  /// minimum padding.
  ///
  /// False to use the default padding. (Not applicable to Geo and Org charts.)
  core.bool? maximized;

  /// An org chart specification.
  OrgChartSpec? orgChart;

  /// A pie chart specification.
  PieChartSpec? pieChart;

  /// A scorecard chart specification.
  ScorecardChartSpec? scorecardChart;

  /// The order to sort the chart data by.
  ///
  /// Only a single sort spec is supported. Only supported for data source
  /// charts.
  core.List<SortSpec>? sortSpecs;

  /// The subtitle of the chart.
  core.String? subtitle;

  /// The subtitle text format.
  ///
  /// Strikethrough, underline, and link are not supported.
  TextFormat? subtitleTextFormat;

  /// The subtitle text position.
  ///
  /// This field is optional.
  TextPosition? subtitleTextPosition;

  /// The title of the chart.
  core.String? title;

  /// The title text format.
  ///
  /// Strikethrough, underline, and link are not supported.
  TextFormat? titleTextFormat;

  /// The title text position.
  ///
  /// This field is optional.
  TextPosition? titleTextPosition;

  /// A treemap chart specification.
  TreemapChartSpec? treemapChart;

  /// A waterfall chart specification.
  WaterfallChartSpec? waterfallChart;

  ChartSpec();

  ChartSpec.fromJson(core.Map _json) {
    if (_json.containsKey('altText')) {
      altText = _json['altText'] as core.String;
    }
    if (_json.containsKey('backgroundColor')) {
      backgroundColor = Color.fromJson(
          _json['backgroundColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('backgroundColorStyle')) {
      backgroundColorStyle = ColorStyle.fromJson(
          _json['backgroundColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('basicChart')) {
      basicChart = BasicChartSpec.fromJson(
          _json['basicChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('bubbleChart')) {
      bubbleChart = BubbleChartSpec.fromJson(
          _json['bubbleChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('candlestickChart')) {
      candlestickChart = CandlestickChartSpec.fromJson(
          _json['candlestickChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataSourceChartProperties')) {
      dataSourceChartProperties = DataSourceChartProperties.fromJson(
          _json['dataSourceChartProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('filterSpecs')) {
      filterSpecs = (_json['filterSpecs'] as core.List)
          .map<FilterSpec>((value) =>
              FilterSpec.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('fontName')) {
      fontName = _json['fontName'] as core.String;
    }
    if (_json.containsKey('hiddenDimensionStrategy')) {
      hiddenDimensionStrategy = _json['hiddenDimensionStrategy'] as core.String;
    }
    if (_json.containsKey('histogramChart')) {
      histogramChart = HistogramChartSpec.fromJson(
          _json['histogramChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('maximized')) {
      maximized = _json['maximized'] as core.bool;
    }
    if (_json.containsKey('orgChart')) {
      orgChart = OrgChartSpec.fromJson(
          _json['orgChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pieChart')) {
      pieChart = PieChartSpec.fromJson(
          _json['pieChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('scorecardChart')) {
      scorecardChart = ScorecardChartSpec.fromJson(
          _json['scorecardChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sortSpecs')) {
      sortSpecs = (_json['sortSpecs'] as core.List)
          .map<SortSpec>((value) =>
              SortSpec.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('subtitle')) {
      subtitle = _json['subtitle'] as core.String;
    }
    if (_json.containsKey('subtitleTextFormat')) {
      subtitleTextFormat = TextFormat.fromJson(
          _json['subtitleTextFormat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subtitleTextPosition')) {
      subtitleTextPosition = TextPosition.fromJson(
          _json['subtitleTextPosition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('titleTextFormat')) {
      titleTextFormat = TextFormat.fromJson(
          _json['titleTextFormat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('titleTextPosition')) {
      titleTextPosition = TextPosition.fromJson(
          _json['titleTextPosition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('treemapChart')) {
      treemapChart = TreemapChartSpec.fromJson(
          _json['treemapChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('waterfallChart')) {
      waterfallChart = WaterfallChartSpec.fromJson(
          _json['waterfallChart'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (altText != null) 'altText': altText!,
        if (backgroundColor != null)
          'backgroundColor': backgroundColor!.toJson(),
        if (backgroundColorStyle != null)
          'backgroundColorStyle': backgroundColorStyle!.toJson(),
        if (basicChart != null) 'basicChart': basicChart!.toJson(),
        if (bubbleChart != null) 'bubbleChart': bubbleChart!.toJson(),
        if (candlestickChart != null)
          'candlestickChart': candlestickChart!.toJson(),
        if (dataSourceChartProperties != null)
          'dataSourceChartProperties': dataSourceChartProperties!.toJson(),
        if (filterSpecs != null)
          'filterSpecs': filterSpecs!.map((value) => value.toJson()).toList(),
        if (fontName != null) 'fontName': fontName!,
        if (hiddenDimensionStrategy != null)
          'hiddenDimensionStrategy': hiddenDimensionStrategy!,
        if (histogramChart != null) 'histogramChart': histogramChart!.toJson(),
        if (maximized != null) 'maximized': maximized!,
        if (orgChart != null) 'orgChart': orgChart!.toJson(),
        if (pieChart != null) 'pieChart': pieChart!.toJson(),
        if (scorecardChart != null) 'scorecardChart': scorecardChart!.toJson(),
        if (sortSpecs != null)
          'sortSpecs': sortSpecs!.map((value) => value.toJson()).toList(),
        if (subtitle != null) 'subtitle': subtitle!,
        if (subtitleTextFormat != null)
          'subtitleTextFormat': subtitleTextFormat!.toJson(),
        if (subtitleTextPosition != null)
          'subtitleTextPosition': subtitleTextPosition!.toJson(),
        if (title != null) 'title': title!,
        if (titleTextFormat != null)
          'titleTextFormat': titleTextFormat!.toJson(),
        if (titleTextPosition != null)
          'titleTextPosition': titleTextPosition!.toJson(),
        if (treemapChart != null) 'treemapChart': treemapChart!.toJson(),
        if (waterfallChart != null) 'waterfallChart': waterfallChart!.toJson(),
      };
}

/// Clears the basic filter, if any exists on the sheet.
class ClearBasicFilterRequest {
  /// The sheet ID on which the basic filter should be cleared.
  core.int? sheetId;

  ClearBasicFilterRequest();

  ClearBasicFilterRequest.fromJson(core.Map _json) {
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sheetId != null) 'sheetId': sheetId!,
      };
}

/// The request for clearing a range of values in a spreadsheet.
class ClearValuesRequest {
  ClearValuesRequest();

  ClearValuesRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The response when clearing a range of values in a spreadsheet.
class ClearValuesResponse {
  /// The range (in A1 notation) that was cleared.
  ///
  /// (If the request was for an unbounded range or a ranger larger than the
  /// bounds of the sheet, this will be the actual range that was cleared,
  /// bounded to the sheet's limits.)
  core.String? clearedRange;

  /// The spreadsheet the updates were applied to.
  core.String? spreadsheetId;

  ClearValuesResponse();

  ClearValuesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('clearedRange')) {
      clearedRange = _json['clearedRange'] as core.String;
    }
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clearedRange != null) 'clearedRange': clearedRange!,
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
      };
}

/// Represents a color in the RGBA color space.
///
/// This representation is designed for simplicity of conversion to/from color
/// representations in various languages over compactness. For example, the
/// fields of this representation can be trivially provided to the constructor
/// of `java.awt.Color` in Java; it can also be trivially provided to UIColor's
/// `+colorWithRed:green:blue:alpha` method in iOS; and, with just a little
/// work, it can be easily formatted into a CSS `rgba()` string in JavaScript.
/// This reference page doesn't carry information about the absolute color space
/// that should be used to interpret the RGB value (e.g. sRGB, Adobe RGB,
/// DCI-P3, BT.2020, etc.). By default, applications should assume the sRGB
/// color space. When color equality needs to be decided, implementations,
/// unless documented otherwise, treat two colors as equal if all their red,
/// green, blue, and alpha values each differ by at most 1e-5. Example (Java):
/// import com.google.type.Color; // ... public static java.awt.Color
/// fromProto(Color protocolor) { float alpha = protocolor.hasAlpha() ?
/// protocolor.getAlpha().getValue() : 1.0; return new java.awt.Color(
/// protocolor.getRed(), protocolor.getGreen(), protocolor.getBlue(), alpha); }
/// public static Color toProto(java.awt.Color color) { float red = (float)
/// color.getRed(); float green = (float) color.getGreen(); float blue = (float)
/// color.getBlue(); float denominator = 255.0; Color.Builder resultBuilder =
/// Color .newBuilder() .setRed(red / denominator) .setGreen(green /
/// denominator) .setBlue(blue / denominator); int alpha = color.getAlpha(); if
/// (alpha != 255) { result.setAlpha( FloatValue .newBuilder()
/// .setValue(((float) alpha) / denominator) .build()); } return
/// resultBuilder.build(); } // ... Example (iOS / Obj-C): // ... static
/// UIColor* fromProto(Color* protocolor) { float red = \[protocolor red\];
/// float green = \[protocolor green\]; float blue = \[protocolor blue\];
/// FloatValue* alpha_wrapper = \[protocolor alpha\]; float alpha = 1.0; if
/// (alpha_wrapper != nil) { alpha = \[alpha_wrapper value\]; } return \[UIColor
/// colorWithRed:red green:green blue:blue alpha:alpha\]; } static Color*
/// toProto(UIColor* color) { CGFloat red, green, blue, alpha; if (!\[color
/// getRed:&red green:&green blue:&blue alpha:&alpha\]) { return nil; } Color*
/// result = \[\[Color alloc\] init\]; \[result setRed:red\]; \[result
/// setGreen:green\]; \[result setBlue:blue\]; if (alpha <= 0.9999) { \[result
/// setAlpha:floatWrapperWithValue(alpha)\]; } \[result autorelease\]; return
/// result; } // ... Example (JavaScript): // ... var protoToCssColor =
/// function(rgb_color) { var redFrac = rgb_color.red || 0.0; var greenFrac =
/// rgb_color.green || 0.0; var blueFrac = rgb_color.blue || 0.0; var red =
/// Math.floor(redFrac * 255); var green = Math.floor(greenFrac * 255); var blue
/// = Math.floor(blueFrac * 255); if (!('alpha' in rgb_color)) { return
/// rgbToCssColor(red, green, blue); } var alphaFrac = rgb_color.alpha.value ||
/// 0.0; var rgbParams = \[red, green, blue\].join(','); return \['rgba(',
/// rgbParams, ',', alphaFrac, ')'\].join(''); }; var rgbToCssColor =
/// function(red, green, blue) { var rgbNumber = new Number((red << 16) | (green
/// << 8) | blue); var hexString = rgbNumber.toString(16); var missingZeros = 6
/// - hexString.length; var resultBuilder = \['#'\]; for (var i = 0; i <
/// missingZeros; i++) { resultBuilder.push('0'); }
/// resultBuilder.push(hexString); return resultBuilder.join(''); }; // ...
class Color {
  /// The fraction of this color that should be applied to the pixel.
  ///
  /// That is, the final pixel color is defined by the equation: `pixel color =
  /// alpha * (this color) + (1.0 - alpha) * (background color)` This means that
  /// a value of 1.0 corresponds to a solid color, whereas a value of 0.0
  /// corresponds to a completely transparent color. This uses a wrapper message
  /// rather than a simple float scalar so that it is possible to distinguish
  /// between a default value and the value being unset. If omitted, this color
  /// object is rendered as a solid color (as if the alpha value had been
  /// explicitly given a value of 1.0).
  core.double? alpha;

  /// The amount of blue in the color as a value in the interval \[0, 1\].
  core.double? blue;

  /// The amount of green in the color as a value in the interval \[0, 1\].
  core.double? green;

  /// The amount of red in the color as a value in the interval \[0, 1\].
  core.double? red;

  Color();

  Color.fromJson(core.Map _json) {
    if (_json.containsKey('alpha')) {
      alpha = (_json['alpha'] as core.num).toDouble();
    }
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
        if (alpha != null) 'alpha': alpha!,
        if (blue != null) 'blue': blue!,
        if (green != null) 'green': green!,
        if (red != null) 'red': red!,
      };
}

/// A color value.
class ColorStyle {
  /// RGB color.
  Color? rgbColor;

  /// Theme color.
  /// Possible string values are:
  /// - "THEME_COLOR_TYPE_UNSPECIFIED" : Unspecified theme color
  /// - "TEXT" : Represents the primary text color
  /// - "BACKGROUND" : Represents the primary background color
  /// - "ACCENT1" : Represents the first accent color
  /// - "ACCENT2" : Represents the second accent color
  /// - "ACCENT3" : Represents the third accent color
  /// - "ACCENT4" : Represents the fourth accent color
  /// - "ACCENT5" : Represents the fifth accent color
  /// - "ACCENT6" : Represents the sixth accent color
  /// - "LINK" : Represents the color to use for hyperlinks
  core.String? themeColor;

  ColorStyle();

  ColorStyle.fromJson(core.Map _json) {
    if (_json.containsKey('rgbColor')) {
      rgbColor = Color.fromJson(
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

/// The value of the condition.
class ConditionValue {
  /// A relative date (based on the current date).
  ///
  /// Valid only if the type is DATE_BEFORE, DATE_AFTER, DATE_ON_OR_BEFORE or
  /// DATE_ON_OR_AFTER. Relative dates are not supported in data validation.
  /// They are supported only in conditional formatting and conditional filters.
  /// Possible string values are:
  /// - "RELATIVE_DATE_UNSPECIFIED" : Default value, do not use.
  /// - "PAST_YEAR" : The value is one year before today.
  /// - "PAST_MONTH" : The value is one month before today.
  /// - "PAST_WEEK" : The value is one week before today.
  /// - "YESTERDAY" : The value is yesterday.
  /// - "TODAY" : The value is today.
  /// - "TOMORROW" : The value is tomorrow.
  core.String? relativeDate;

  /// A value the condition is based on.
  ///
  /// The value is parsed as if the user typed into a cell. Formulas are
  /// supported (and must begin with an `=` or a '+').
  core.String? userEnteredValue;

  ConditionValue();

  ConditionValue.fromJson(core.Map _json) {
    if (_json.containsKey('relativeDate')) {
      relativeDate = _json['relativeDate'] as core.String;
    }
    if (_json.containsKey('userEnteredValue')) {
      userEnteredValue = _json['userEnteredValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (relativeDate != null) 'relativeDate': relativeDate!,
        if (userEnteredValue != null) 'userEnteredValue': userEnteredValue!,
      };
}

/// A rule describing a conditional format.
class ConditionalFormatRule {
  /// The formatting is either "on" or "off" according to the rule.
  BooleanRule? booleanRule;

  /// The formatting will vary based on the gradients in the rule.
  GradientRule? gradientRule;

  /// The ranges that are formatted if the condition is true.
  ///
  /// All the ranges must be on the same grid.
  core.List<GridRange>? ranges;

  ConditionalFormatRule();

  ConditionalFormatRule.fromJson(core.Map _json) {
    if (_json.containsKey('booleanRule')) {
      booleanRule = BooleanRule.fromJson(
          _json['booleanRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gradientRule')) {
      gradientRule = GradientRule.fromJson(
          _json['gradientRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ranges')) {
      ranges = (_json['ranges'] as core.List)
          .map<GridRange>((value) =>
              GridRange.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (booleanRule != null) 'booleanRule': booleanRule!.toJson(),
        if (gradientRule != null) 'gradientRule': gradientRule!.toJson(),
        if (ranges != null)
          'ranges': ranges!.map((value) => value.toJson()).toList(),
      };
}

/// Copies data from the source to the destination.
class CopyPasteRequest {
  /// The location to paste to.
  ///
  /// If the range covers a span that's a multiple of the source's height or
  /// width, then the data will be repeated to fill in the destination range. If
  /// the range is smaller than the source range, the entire source data will
  /// still be copied (beyond the end of the destination range).
  GridRange? destination;

  /// How that data should be oriented when pasting.
  /// Possible string values are:
  /// - "NORMAL" : Paste normally.
  /// - "TRANSPOSE" : Paste transposed, where all rows become columns and vice
  /// versa.
  core.String? pasteOrientation;

  /// What kind of data to paste.
  /// Possible string values are:
  /// - "PASTE_NORMAL" : Paste values, formulas, formats, and merges.
  /// - "PASTE_VALUES" : Paste the values ONLY without formats, formulas, or
  /// merges.
  /// - "PASTE_FORMAT" : Paste the format and data validation only.
  /// - "PASTE_NO_BORDERS" : Like `PASTE_NORMAL` but without borders.
  /// - "PASTE_FORMULA" : Paste the formulas only.
  /// - "PASTE_DATA_VALIDATION" : Paste the data validation only.
  /// - "PASTE_CONDITIONAL_FORMATTING" : Paste the conditional formatting rules
  /// only.
  core.String? pasteType;

  /// The source range to copy.
  GridRange? source;

  CopyPasteRequest();

  CopyPasteRequest.fromJson(core.Map _json) {
    if (_json.containsKey('destination')) {
      destination = GridRange.fromJson(
          _json['destination'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pasteOrientation')) {
      pasteOrientation = _json['pasteOrientation'] as core.String;
    }
    if (_json.containsKey('pasteType')) {
      pasteType = _json['pasteType'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = GridRange.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destination != null) 'destination': destination!.toJson(),
        if (pasteOrientation != null) 'pasteOrientation': pasteOrientation!,
        if (pasteType != null) 'pasteType': pasteType!,
        if (source != null) 'source': source!.toJson(),
      };
}

/// The request to copy a sheet across spreadsheets.
class CopySheetToAnotherSpreadsheetRequest {
  /// The ID of the spreadsheet to copy the sheet to.
  core.String? destinationSpreadsheetId;

  CopySheetToAnotherSpreadsheetRequest();

  CopySheetToAnotherSpreadsheetRequest.fromJson(core.Map _json) {
    if (_json.containsKey('destinationSpreadsheetId')) {
      destinationSpreadsheetId =
          _json['destinationSpreadsheetId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationSpreadsheetId != null)
          'destinationSpreadsheetId': destinationSpreadsheetId!,
      };
}

/// A request to create developer metadata.
class CreateDeveloperMetadataRequest {
  /// The developer metadata to create.
  DeveloperMetadata? developerMetadata;

  CreateDeveloperMetadataRequest();

  CreateDeveloperMetadataRequest.fromJson(core.Map _json) {
    if (_json.containsKey('developerMetadata')) {
      developerMetadata = DeveloperMetadata.fromJson(
          _json['developerMetadata'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (developerMetadata != null)
          'developerMetadata': developerMetadata!.toJson(),
      };
}

/// The response from creating developer metadata.
class CreateDeveloperMetadataResponse {
  /// The developer metadata that was created.
  DeveloperMetadata? developerMetadata;

  CreateDeveloperMetadataResponse();

  CreateDeveloperMetadataResponse.fromJson(core.Map _json) {
    if (_json.containsKey('developerMetadata')) {
      developerMetadata = DeveloperMetadata.fromJson(
          _json['developerMetadata'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (developerMetadata != null)
          'developerMetadata': developerMetadata!.toJson(),
      };
}

/// Moves data from the source to the destination.
class CutPasteRequest {
  /// The top-left coordinate where the data should be pasted.
  GridCoordinate? destination;

  /// What kind of data to paste.
  ///
  /// All the source data will be cut, regardless of what is pasted.
  /// Possible string values are:
  /// - "PASTE_NORMAL" : Paste values, formulas, formats, and merges.
  /// - "PASTE_VALUES" : Paste the values ONLY without formats, formulas, or
  /// merges.
  /// - "PASTE_FORMAT" : Paste the format and data validation only.
  /// - "PASTE_NO_BORDERS" : Like `PASTE_NORMAL` but without borders.
  /// - "PASTE_FORMULA" : Paste the formulas only.
  /// - "PASTE_DATA_VALIDATION" : Paste the data validation only.
  /// - "PASTE_CONDITIONAL_FORMATTING" : Paste the conditional formatting rules
  /// only.
  core.String? pasteType;

  /// The source data to cut.
  GridRange? source;

  CutPasteRequest();

  CutPasteRequest.fromJson(core.Map _json) {
    if (_json.containsKey('destination')) {
      destination = GridCoordinate.fromJson(
          _json['destination'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pasteType')) {
      pasteType = _json['pasteType'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = GridRange.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destination != null) 'destination': destination!.toJson(),
        if (pasteType != null) 'pasteType': pasteType!,
        if (source != null) 'source': source!.toJson(),
      };
}

/// The data execution status.
///
/// A data execution is created to sync a data source object with the latest
/// data from a DataSource. It is usually scheduled to run at background, you
/// can check its state to tell if an execution completes There are several
/// scenarios where a data execution is triggered to run: * Adding a data source
/// creates an associated data source sheet as well as a data execution to sync
/// the data from the data source to the sheet. * Updating a data source creates
/// a data execution to refresh the associated data source sheet similarly. *
/// You can send refresh request to explicitly refresh one or multiple data
/// source objects.
class DataExecutionStatus {
  /// The error code.
  /// Possible string values are:
  /// - "DATA_EXECUTION_ERROR_CODE_UNSPECIFIED" : Default value, do not use.
  /// - "TIMED_OUT" : The data execution timed out.
  /// - "TOO_MANY_ROWS" : The data execution returns more rows than the limit.
  /// - "TOO_MANY_CELLS" : The data execution returns more cells than the limit.
  /// - "ENGINE" : Error is received from the backend data execution engine
  /// (e.g. BigQuery). Check error_message for details.
  /// - "PARAMETER_INVALID" : One or some of the provided data source parameters
  /// are invalid.
  /// - "UNSUPPORTED_DATA_TYPE" : The data execution returns an unsupported data
  /// type.
  /// - "DUPLICATE_COLUMN_NAMES" : The data execution returns duplicate column
  /// names or aliases.
  /// - "INTERRUPTED" : The data execution is interrupted. Please refresh later.
  /// - "CONCURRENT_QUERY" : The data execution is currently in progress, can
  /// not be refreshed until it completes.
  /// - "OTHER" : Other errors.
  /// - "TOO_MANY_CHARS_PER_CELL" : The data execution returns values that
  /// exceed the maximum characters allowed in a single cell.
  /// - "DATA_NOT_FOUND" : The database referenced by the data source is not
  /// found. * /
  /// - "PERMISSION_DENIED" : The user does not have access to the database
  /// referenced by the data source.
  /// - "MISSING_COLUMN_ALIAS" : The data execution returns columns with missing
  /// aliases.
  /// - "OBJECT_NOT_FOUND" : The data source object does not exist.
  /// - "OBJECT_IN_ERROR_STATE" : The data source object is currently in error
  /// state. To force refresh, set force in RefreshDataSourceRequest.
  /// - "OBJECT_SPEC_INVALID" : The data source object specification is invalid.
  core.String? errorCode;

  /// The error message, which may be empty.
  core.String? errorMessage;

  /// Gets the time the data last successfully refreshed.
  core.String? lastRefreshTime;

  /// The state of the data execution.
  /// Possible string values are:
  /// - "DATA_EXECUTION_STATE_UNSPECIFIED" : Default value, do not use.
  /// - "NOT_STARTED" : The data execution has not started.
  /// - "RUNNING" : The data execution has started and is running.
  /// - "SUCCEEDED" : The data execution has completed successfully.
  /// - "FAILED" : The data execution has completed with errors.
  core.String? state;

  DataExecutionStatus();

  DataExecutionStatus.fromJson(core.Map _json) {
    if (_json.containsKey('errorCode')) {
      errorCode = _json['errorCode'] as core.String;
    }
    if (_json.containsKey('errorMessage')) {
      errorMessage = _json['errorMessage'] as core.String;
    }
    if (_json.containsKey('lastRefreshTime')) {
      lastRefreshTime = _json['lastRefreshTime'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorCode != null) 'errorCode': errorCode!,
        if (errorMessage != null) 'errorMessage': errorMessage!,
        if (lastRefreshTime != null) 'lastRefreshTime': lastRefreshTime!,
        if (state != null) 'state': state!,
      };
}

/// Filter that describes what data should be selected or returned from a
/// request.
class DataFilter {
  /// Selects data that matches the specified A1 range.
  core.String? a1Range;

  /// Selects data associated with the developer metadata matching the criteria
  /// described by this DeveloperMetadataLookup.
  DeveloperMetadataLookup? developerMetadataLookup;

  /// Selects data that matches the range described by the GridRange.
  GridRange? gridRange;

  DataFilter();

  DataFilter.fromJson(core.Map _json) {
    if (_json.containsKey('a1Range')) {
      a1Range = _json['a1Range'] as core.String;
    }
    if (_json.containsKey('developerMetadataLookup')) {
      developerMetadataLookup = DeveloperMetadataLookup.fromJson(
          _json['developerMetadataLookup']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gridRange')) {
      gridRange = GridRange.fromJson(
          _json['gridRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (a1Range != null) 'a1Range': a1Range!,
        if (developerMetadataLookup != null)
          'developerMetadataLookup': developerMetadataLookup!.toJson(),
        if (gridRange != null) 'gridRange': gridRange!.toJson(),
      };
}

/// A range of values whose location is specified by a DataFilter.
class DataFilterValueRange {
  /// The data filter describing the location of the values in the spreadsheet.
  DataFilter? dataFilter;

  /// The major dimension of the values.
  /// Possible string values are:
  /// - "DIMENSION_UNSPECIFIED" : The default value, do not use.
  /// - "ROWS" : Operates on the rows of a sheet.
  /// - "COLUMNS" : Operates on the columns of a sheet.
  core.String? majorDimension;

  /// The data to be written.
  ///
  /// If the provided values exceed any of the ranges matched by the data filter
  /// then the request fails. If the provided values are less than the matched
  /// ranges only the specified values are written, existing values in the
  /// matched ranges remain unaffected.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.List<core.Object>>? values;

  DataFilterValueRange();

  DataFilterValueRange.fromJson(core.Map _json) {
    if (_json.containsKey('dataFilter')) {
      dataFilter = DataFilter.fromJson(
          _json['dataFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('majorDimension')) {
      majorDimension = _json['majorDimension'] as core.String;
    }
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.List<core.Object>>((value) => (value as core.List)
              .map<core.Object>((value) => value as core.Object)
              .toList())
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataFilter != null) 'dataFilter': dataFilter!.toJson(),
        if (majorDimension != null) 'majorDimension': majorDimension!,
        if (values != null) 'values': values!,
      };
}

/// Settings for one set of data labels.
///
/// Data labels are annotations that appear next to a set of data, such as the
/// points on a line chart, and provide additional information about what the
/// data represents, such as a text representation of the value behind that
/// point on the graph.
class DataLabel {
  /// Data to use for custom labels.
  ///
  /// Only used if type is set to CUSTOM. This data must be the same length as
  /// the series or other element this data label is applied to. In addition, if
  /// the series is split into multiple source ranges, this source data must
  /// come from the next column in the source data. For example, if the series
  /// is B2:B4,E6:E8 then this data must come from C2:C4,F6:F8.
  ChartData? customLabelData;

  /// The placement of the data label relative to the labeled data.
  /// Possible string values are:
  /// - "DATA_LABEL_PLACEMENT_UNSPECIFIED" : The positioning is determined
  /// automatically by the renderer.
  /// - "CENTER" : Center within a bar or column, both horizontally and
  /// vertically.
  /// - "LEFT" : To the left of a data point.
  /// - "RIGHT" : To the right of a data point.
  /// - "ABOVE" : Above a data point.
  /// - "BELOW" : Below a data point.
  /// - "INSIDE_END" : Inside a bar or column at the end (top if positive,
  /// bottom if negative).
  /// - "INSIDE_BASE" : Inside a bar or column at the base.
  /// - "OUTSIDE_END" : Outside a bar or column at the end.
  core.String? placement;

  /// The text format used for the data label.
  ///
  /// The link field is not supported.
  TextFormat? textFormat;

  /// The type of the data label.
  /// Possible string values are:
  /// - "DATA_LABEL_TYPE_UNSPECIFIED" : The data label type is not specified and
  /// will be interpreted depending on the context of the data label within the
  /// chart.
  /// - "NONE" : The data label is not displayed.
  /// - "DATA" : The data label is displayed using values from the series data.
  /// - "CUSTOM" : The data label is displayed using values from a custom data
  /// source indicated by customLabelData.
  core.String? type;

  DataLabel();

  DataLabel.fromJson(core.Map _json) {
    if (_json.containsKey('customLabelData')) {
      customLabelData = ChartData.fromJson(
          _json['customLabelData'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('placement')) {
      placement = _json['placement'] as core.String;
    }
    if (_json.containsKey('textFormat')) {
      textFormat = TextFormat.fromJson(
          _json['textFormat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customLabelData != null)
          'customLabelData': customLabelData!.toJson(),
        if (placement != null) 'placement': placement!,
        if (textFormat != null) 'textFormat': textFormat!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// Information about an external data source in the spreadsheet.
class DataSource {
  /// All calculated columns in the data source.
  core.List<DataSourceColumn>? calculatedColumns;

  /// The spreadsheet-scoped unique ID that identifies the data source.
  ///
  /// Example: 1080547365.
  core.String? dataSourceId;

  /// The ID of the Sheet connected with the data source.
  ///
  /// The field cannot be changed once set. When creating a data source, an
  /// associated DATA_SOURCE sheet is also created, if the field is not
  /// specified, the ID of the created sheet will be randomly generated.
  core.int? sheetId;

  /// The DataSourceSpec for the data source connected with this spreadsheet.
  DataSourceSpec? spec;

  DataSource();

  DataSource.fromJson(core.Map _json) {
    if (_json.containsKey('calculatedColumns')) {
      calculatedColumns = (_json['calculatedColumns'] as core.List)
          .map<DataSourceColumn>((value) => DataSourceColumn.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
    if (_json.containsKey('spec')) {
      spec = DataSourceSpec.fromJson(
          _json['spec'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (calculatedColumns != null)
          'calculatedColumns':
              calculatedColumns!.map((value) => value.toJson()).toList(),
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
        if (sheetId != null) 'sheetId': sheetId!,
        if (spec != null) 'spec': spec!.toJson(),
      };
}

/// Properties of a data source chart.
class DataSourceChartProperties {
  /// The data execution status.
  ///
  /// Output only.
  DataExecutionStatus? dataExecutionStatus;

  /// ID of the data source that the chart is associated with.
  core.String? dataSourceId;

  DataSourceChartProperties();

  DataSourceChartProperties.fromJson(core.Map _json) {
    if (_json.containsKey('dataExecutionStatus')) {
      dataExecutionStatus = DataExecutionStatus.fromJson(
          _json['dataExecutionStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataExecutionStatus != null)
          'dataExecutionStatus': dataExecutionStatus!.toJson(),
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
      };
}

/// A column in a data source.
class DataSourceColumn {
  /// The formula of the calculated column.
  core.String? formula;

  /// The column reference.
  DataSourceColumnReference? reference;

  DataSourceColumn();

  DataSourceColumn.fromJson(core.Map _json) {
    if (_json.containsKey('formula')) {
      formula = _json['formula'] as core.String;
    }
    if (_json.containsKey('reference')) {
      reference = DataSourceColumnReference.fromJson(
          _json['reference'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (formula != null) 'formula': formula!,
        if (reference != null) 'reference': reference!.toJson(),
      };
}

/// An unique identifier that references a data source column.
class DataSourceColumnReference {
  /// The display name of the column.
  ///
  /// It should be unique within a data source.
  core.String? name;

  DataSourceColumnReference();

  DataSourceColumnReference.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
      };
}

/// A data source formula.
class DataSourceFormula {
  /// The data execution status.
  ///
  /// Output only.
  DataExecutionStatus? dataExecutionStatus;

  /// The ID of the data source the formula is associated with.
  core.String? dataSourceId;

  DataSourceFormula();

  DataSourceFormula.fromJson(core.Map _json) {
    if (_json.containsKey('dataExecutionStatus')) {
      dataExecutionStatus = DataExecutionStatus.fromJson(
          _json['dataExecutionStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataExecutionStatus != null)
          'dataExecutionStatus': dataExecutionStatus!.toJson(),
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
      };
}

/// Reference to a data source object.
class DataSourceObjectReference {
  /// References to a data source chart.
  core.int? chartId;

  /// References to a cell containing DataSourceFormula.
  GridCoordinate? dataSourceFormulaCell;

  /// References to a data source PivotTable anchored at the cell.
  GridCoordinate? dataSourcePivotTableAnchorCell;

  /// References to a DataSourceTable anchored at the cell.
  GridCoordinate? dataSourceTableAnchorCell;

  /// References to a DATA_SOURCE sheet.
  core.String? sheetId;

  DataSourceObjectReference();

  DataSourceObjectReference.fromJson(core.Map _json) {
    if (_json.containsKey('chartId')) {
      chartId = _json['chartId'] as core.int;
    }
    if (_json.containsKey('dataSourceFormulaCell')) {
      dataSourceFormulaCell = GridCoordinate.fromJson(
          _json['dataSourceFormulaCell']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataSourcePivotTableAnchorCell')) {
      dataSourcePivotTableAnchorCell = GridCoordinate.fromJson(
          _json['dataSourcePivotTableAnchorCell']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataSourceTableAnchorCell')) {
      dataSourceTableAnchorCell = GridCoordinate.fromJson(
          _json['dataSourceTableAnchorCell']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chartId != null) 'chartId': chartId!,
        if (dataSourceFormulaCell != null)
          'dataSourceFormulaCell': dataSourceFormulaCell!.toJson(),
        if (dataSourcePivotTableAnchorCell != null)
          'dataSourcePivotTableAnchorCell':
              dataSourcePivotTableAnchorCell!.toJson(),
        if (dataSourceTableAnchorCell != null)
          'dataSourceTableAnchorCell': dataSourceTableAnchorCell!.toJson(),
        if (sheetId != null) 'sheetId': sheetId!,
      };
}

/// A list of references to data source objects.
class DataSourceObjectReferences {
  /// The references.
  core.List<DataSourceObjectReference>? references;

  DataSourceObjectReferences();

  DataSourceObjectReferences.fromJson(core.Map _json) {
    if (_json.containsKey('references')) {
      references = (_json['references'] as core.List)
          .map<DataSourceObjectReference>((value) =>
              DataSourceObjectReference.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (references != null)
          'references': references!.map((value) => value.toJson()).toList(),
      };
}

/// A parameter in a data source's query.
///
/// The parameter allows the user to pass in values from the spreadsheet into a
/// query.
class DataSourceParameter {
  /// Named parameter.
  ///
  /// Must be a legitimate identifier for the DataSource that supports it. For
  /// example,
  /// [BigQuery identifier](https://cloud.google.com/bigquery/docs/reference/standard-sql/lexical#identifiers).
  core.String? name;

  /// ID of a NamedRange.
  ///
  /// Its size must be 1x1.
  core.String? namedRangeId;

  /// A range that contains the value of the parameter.
  ///
  /// Its size must be 1x1.
  GridRange? range;

  DataSourceParameter();

  DataSourceParameter.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('namedRangeId')) {
      namedRangeId = _json['namedRangeId'] as core.String;
    }
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (namedRangeId != null) 'namedRangeId': namedRangeId!,
        if (range != null) 'range': range!.toJson(),
      };
}

/// A schedule for data to refresh every day in a given time interval.
class DataSourceRefreshDailySchedule {
  /// The start time of a time interval in which a data source refresh is
  /// scheduled.
  ///
  /// Only `hours` part is used. The time interval size defaults to that in the
  /// Sheets editor.
  TimeOfDay? startTime;

  DataSourceRefreshDailySchedule();

  DataSourceRefreshDailySchedule.fromJson(core.Map _json) {
    if (_json.containsKey('startTime')) {
      startTime = TimeOfDay.fromJson(
          _json['startTime'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (startTime != null) 'startTime': startTime!.toJson(),
      };
}

/// A monthly schedule for data to refresh on specific days in the month in a
/// given time interval.
class DataSourceRefreshMonthlySchedule {
  /// Days of the month to refresh.
  ///
  /// Only 1-28 are supported, mapping to the 1st to the 28th day. At lesat one
  /// day must be specified.
  core.List<core.int>? daysOfMonth;

  /// The start time of a time interval in which a data source refresh is
  /// scheduled.
  ///
  /// Only `hours` part is used. The time interval size defaults to that in the
  /// Sheets editor.
  TimeOfDay? startTime;

  DataSourceRefreshMonthlySchedule();

  DataSourceRefreshMonthlySchedule.fromJson(core.Map _json) {
    if (_json.containsKey('daysOfMonth')) {
      daysOfMonth = (_json['daysOfMonth'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('startTime')) {
      startTime = TimeOfDay.fromJson(
          _json['startTime'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (daysOfMonth != null) 'daysOfMonth': daysOfMonth!,
        if (startTime != null) 'startTime': startTime!.toJson(),
      };
}

/// Schedule for refreshing the data source.
///
/// Data sources in the spreadsheet are refreshed within a time interval. You
/// can specify the start time by clicking the Scheduled Refresh button in the
/// Sheets editor, but the interval is fixed at 4 hours. For example, if you
/// specify a start time of 8am , the refresh will take place between 8am and
/// 12pm every day.
class DataSourceRefreshSchedule {
  /// Daily refresh schedule.
  DataSourceRefreshDailySchedule? dailySchedule;

  /// True if the refresh schedule is enabled, or false otherwise.
  core.bool? enabled;

  /// Monthly refresh schedule.
  DataSourceRefreshMonthlySchedule? monthlySchedule;

  /// The time interval of the next run.
  ///
  /// Output only.
  Interval? nextRun;

  /// The scope of the refresh.
  ///
  /// Must be ALL_DATA_SOURCES.
  /// Possible string values are:
  /// - "DATA_SOURCE_REFRESH_SCOPE_UNSPECIFIED" : Default value, do not use.
  /// - "ALL_DATA_SOURCES" : Refreshes all data sources and their associated
  /// data source objects in the spreadsheet.
  core.String? refreshScope;

  /// Weekly refresh schedule.
  DataSourceRefreshWeeklySchedule? weeklySchedule;

  DataSourceRefreshSchedule();

  DataSourceRefreshSchedule.fromJson(core.Map _json) {
    if (_json.containsKey('dailySchedule')) {
      dailySchedule = DataSourceRefreshDailySchedule.fromJson(
          _json['dailySchedule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
    if (_json.containsKey('monthlySchedule')) {
      monthlySchedule = DataSourceRefreshMonthlySchedule.fromJson(
          _json['monthlySchedule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nextRun')) {
      nextRun = Interval.fromJson(
          _json['nextRun'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('refreshScope')) {
      refreshScope = _json['refreshScope'] as core.String;
    }
    if (_json.containsKey('weeklySchedule')) {
      weeklySchedule = DataSourceRefreshWeeklySchedule.fromJson(
          _json['weeklySchedule'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dailySchedule != null) 'dailySchedule': dailySchedule!.toJson(),
        if (enabled != null) 'enabled': enabled!,
        if (monthlySchedule != null)
          'monthlySchedule': monthlySchedule!.toJson(),
        if (nextRun != null) 'nextRun': nextRun!.toJson(),
        if (refreshScope != null) 'refreshScope': refreshScope!,
        if (weeklySchedule != null) 'weeklySchedule': weeklySchedule!.toJson(),
      };
}

/// A weekly schedule for data to refresh on specific days in a given time
/// interval.
class DataSourceRefreshWeeklySchedule {
  /// Days of the week to refresh.
  ///
  /// At least one day must be specified.
  core.List<core.String>? daysOfWeek;

  /// The start time of a time interval in which a data source refresh is
  /// scheduled.
  ///
  /// Only `hours` part is used. The time interval size defaults to that in the
  /// Sheets editor.
  TimeOfDay? startTime;

  DataSourceRefreshWeeklySchedule();

  DataSourceRefreshWeeklySchedule.fromJson(core.Map _json) {
    if (_json.containsKey('daysOfWeek')) {
      daysOfWeek = (_json['daysOfWeek'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('startTime')) {
      startTime = TimeOfDay.fromJson(
          _json['startTime'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek!,
        if (startTime != null) 'startTime': startTime!.toJson(),
      };
}

/// A range along a single dimension on a DATA_SOURCE sheet.
class DataSourceSheetDimensionRange {
  /// The columns on the data source sheet.
  core.List<DataSourceColumnReference>? columnReferences;

  /// The ID of the data source sheet the range is on.
  core.int? sheetId;

  DataSourceSheetDimensionRange();

  DataSourceSheetDimensionRange.fromJson(core.Map _json) {
    if (_json.containsKey('columnReferences')) {
      columnReferences = (_json['columnReferences'] as core.List)
          .map<DataSourceColumnReference>((value) =>
              DataSourceColumnReference.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnReferences != null)
          'columnReferences':
              columnReferences!.map((value) => value.toJson()).toList(),
        if (sheetId != null) 'sheetId': sheetId!,
      };
}

/// Additional properties of a DATA_SOURCE sheet.
class DataSourceSheetProperties {
  /// The columns displayed on the sheet, corresponding to the values in
  /// RowData.
  core.List<DataSourceColumn>? columns;

  /// The data execution status.
  DataExecutionStatus? dataExecutionStatus;

  /// ID of the DataSource the sheet is connected to.
  core.String? dataSourceId;

  DataSourceSheetProperties();

  DataSourceSheetProperties.fromJson(core.Map _json) {
    if (_json.containsKey('columns')) {
      columns = (_json['columns'] as core.List)
          .map<DataSourceColumn>((value) => DataSourceColumn.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dataExecutionStatus')) {
      dataExecutionStatus = DataExecutionStatus.fromJson(
          _json['dataExecutionStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columns != null)
          'columns': columns!.map((value) => value.toJson()).toList(),
        if (dataExecutionStatus != null)
          'dataExecutionStatus': dataExecutionStatus!.toJson(),
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
      };
}

/// This specifies the details of the data source.
///
/// For example, for BigQuery, this specifies information about the BigQuery
/// source.
class DataSourceSpec {
  /// A BigQueryDataSourceSpec.
  BigQueryDataSourceSpec? bigQuery;

  /// The parameters of the data source, used when querying the data source.
  core.List<DataSourceParameter>? parameters;

  DataSourceSpec();

  DataSourceSpec.fromJson(core.Map _json) {
    if (_json.containsKey('bigQuery')) {
      bigQuery = BigQueryDataSourceSpec.fromJson(
          _json['bigQuery'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<DataSourceParameter>((value) => DataSourceParameter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bigQuery != null) 'bigQuery': bigQuery!.toJson(),
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
      };
}

/// A data source table, which allows the user to import a static table of data
/// from the DataSource into Sheets.
///
/// This is also known as "Extract" in the Sheets editor.
class DataSourceTable {
  /// The type to select columns for the data source table.
  ///
  /// Defaults to SELECTED.
  /// Possible string values are:
  /// - "DATA_SOURCE_TABLE_COLUMN_SELECTION_TYPE_UNSPECIFIED" : The default
  /// column selection type, do not use.
  /// - "SELECTED" : Select columns specified by columns field.
  /// - "SYNC_ALL" : Sync all current and future columns in the data source. If
  /// set, the data source table fetches all the columns in the data source at
  /// the time of refresh.
  core.String? columnSelectionType;

  /// Columns selected for the data source table.
  ///
  /// The column_selection_type must be SELECTED.
  core.List<DataSourceColumnReference>? columns;

  /// The data execution status.
  ///
  /// Output only.
  DataExecutionStatus? dataExecutionStatus;

  /// The ID of the data source the data source table is associated with.
  core.String? dataSourceId;

  /// Filter specifications in the data source table.
  core.List<FilterSpec>? filterSpecs;

  /// The limit of rows to return.
  ///
  /// If not set, a default limit is applied. Please refer to the Sheets editor
  /// for the default and max limit.
  core.int? rowLimit;

  /// Sort specifications in the data source table.
  ///
  /// The result of the data source table is sorted based on the sort
  /// specifications in order.
  core.List<SortSpec>? sortSpecs;

  DataSourceTable();

  DataSourceTable.fromJson(core.Map _json) {
    if (_json.containsKey('columnSelectionType')) {
      columnSelectionType = _json['columnSelectionType'] as core.String;
    }
    if (_json.containsKey('columns')) {
      columns = (_json['columns'] as core.List)
          .map<DataSourceColumnReference>((value) =>
              DataSourceColumnReference.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dataExecutionStatus')) {
      dataExecutionStatus = DataExecutionStatus.fromJson(
          _json['dataExecutionStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
    if (_json.containsKey('filterSpecs')) {
      filterSpecs = (_json['filterSpecs'] as core.List)
          .map<FilterSpec>((value) =>
              FilterSpec.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('rowLimit')) {
      rowLimit = _json['rowLimit'] as core.int;
    }
    if (_json.containsKey('sortSpecs')) {
      sortSpecs = (_json['sortSpecs'] as core.List)
          .map<SortSpec>((value) =>
              SortSpec.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnSelectionType != null)
          'columnSelectionType': columnSelectionType!,
        if (columns != null)
          'columns': columns!.map((value) => value.toJson()).toList(),
        if (dataExecutionStatus != null)
          'dataExecutionStatus': dataExecutionStatus!.toJson(),
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
        if (filterSpecs != null)
          'filterSpecs': filterSpecs!.map((value) => value.toJson()).toList(),
        if (rowLimit != null) 'rowLimit': rowLimit!,
        if (sortSpecs != null)
          'sortSpecs': sortSpecs!.map((value) => value.toJson()).toList(),
      };
}

/// A data validation rule.
class DataValidationRule {
  /// The condition that data in the cell must match.
  BooleanCondition? condition;

  /// A message to show the user when adding data to the cell.
  core.String? inputMessage;

  /// True if the UI should be customized based on the kind of condition.
  ///
  /// If true, "List" conditions will show a dropdown.
  core.bool? showCustomUi;

  /// True if invalid data should be rejected.
  core.bool? strict;

  DataValidationRule();

  DataValidationRule.fromJson(core.Map _json) {
    if (_json.containsKey('condition')) {
      condition = BooleanCondition.fromJson(
          _json['condition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inputMessage')) {
      inputMessage = _json['inputMessage'] as core.String;
    }
    if (_json.containsKey('showCustomUi')) {
      showCustomUi = _json['showCustomUi'] as core.bool;
    }
    if (_json.containsKey('strict')) {
      strict = _json['strict'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (condition != null) 'condition': condition!.toJson(),
        if (inputMessage != null) 'inputMessage': inputMessage!,
        if (showCustomUi != null) 'showCustomUi': showCustomUi!,
        if (strict != null) 'strict': strict!,
      };
}

/// Allows you to organize the date-time values in a source data column into
/// buckets based on selected parts of their date or time values.
///
/// For example, consider a pivot table showing sales transactions by date:
/// +----------+--------------+ | Date | SUM of Sales |
/// +----------+--------------+ | 1/1/2017 | $621.14 | | 2/3/2017 | $708.84 | |
/// 5/8/2017 | $326.84 | ... +----------+--------------+ Applying a date-time
/// group rule with a DateTimeRuleType of YEAR_MONTH results in the following
/// pivot table. +--------------+--------------+ | Grouped Date | SUM of Sales |
/// +--------------+--------------+ | 2017-Jan | $53,731.78 | | 2017-Feb |
/// $83,475.32 | | 2017-Mar | $94,385.05 | ... +--------------+--------------+
class DateTimeRule {
  /// The type of date-time grouping to apply.
  /// Possible string values are:
  /// - "DATE_TIME_RULE_TYPE_UNSPECIFIED" : The default type, do not use.
  /// - "SECOND" : Group dates by second, from 0 to 59.
  /// - "MINUTE" : Group dates by minute, from 0 to 59.
  /// - "HOUR" : Group dates by hour using a 24-hour system, from 0 to 23.
  /// - "HOUR_MINUTE" : Group dates by hour and minute using a 24-hour system,
  /// for example 19:45.
  /// - "HOUR_MINUTE_AMPM" : Group dates by hour and minute using a 12-hour
  /// system, for example 7:45 PM. The AM/PM designation is translated based on
  /// the spreadsheet locale.
  /// - "DAY_OF_WEEK" : Group dates by day of week, for example Sunday. The days
  /// of the week will be translated based on the spreadsheet locale.
  /// - "DAY_OF_YEAR" : Group dates by day of year, from 1 to 366. Note that
  /// dates after Feb. 29 fall in different buckets in leap years than in
  /// non-leap years.
  /// - "DAY_OF_MONTH" : Group dates by day of month, from 1 to 31.
  /// - "DAY_MONTH" : Group dates by day and month, for example 22-Nov. The
  /// month is translated based on the spreadsheet locale.
  /// - "MONTH" : Group dates by month, for example Nov. The month is translated
  /// based on the spreadsheet locale.
  /// - "QUARTER" : Group dates by quarter, for example Q1 (which represents
  /// Jan-Mar).
  /// - "YEAR" : Group dates by year, for example 2008.
  /// - "YEAR_MONTH" : Group dates by year and month, for example 2008-Nov. The
  /// month is translated based on the spreadsheet locale.
  /// - "YEAR_QUARTER" : Group dates by year and quarter, for example 2008 Q4.
  /// - "YEAR_MONTH_DAY" : Group dates by year, month, and day, for example
  /// 2008-11-22.
  core.String? type;

  DateTimeRule();

  DateTimeRule.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
      };
}

/// Removes the banded range with the given ID from the spreadsheet.
class DeleteBandingRequest {
  /// The ID of the banded range to delete.
  core.int? bandedRangeId;

  DeleteBandingRequest();

  DeleteBandingRequest.fromJson(core.Map _json) {
    if (_json.containsKey('bandedRangeId')) {
      bandedRangeId = _json['bandedRangeId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bandedRangeId != null) 'bandedRangeId': bandedRangeId!,
      };
}

/// Deletes a conditional format rule at the given index.
///
/// All subsequent rules' indexes are decremented.
class DeleteConditionalFormatRuleRequest {
  /// The zero-based index of the rule to be deleted.
  core.int? index;

  /// The sheet the rule is being deleted from.
  core.int? sheetId;

  DeleteConditionalFormatRuleRequest();

  DeleteConditionalFormatRuleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('index')) {
      index = _json['index'] as core.int;
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (index != null) 'index': index!,
        if (sheetId != null) 'sheetId': sheetId!,
      };
}

/// The result of deleting a conditional format rule.
class DeleteConditionalFormatRuleResponse {
  /// The rule that was deleted.
  ConditionalFormatRule? rule;

  DeleteConditionalFormatRuleResponse();

  DeleteConditionalFormatRuleResponse.fromJson(core.Map _json) {
    if (_json.containsKey('rule')) {
      rule = ConditionalFormatRule.fromJson(
          _json['rule'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rule != null) 'rule': rule!.toJson(),
      };
}

/// Deletes a data source.
///
/// The request also deletes the associated data source sheet, and unlinks all
/// associated data source objects.
class DeleteDataSourceRequest {
  /// The ID of the data source to delete.
  core.String? dataSourceId;

  DeleteDataSourceRequest();

  DeleteDataSourceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
      };
}

/// A request to delete developer metadata.
class DeleteDeveloperMetadataRequest {
  /// The data filter describing the criteria used to select which developer
  /// metadata entry to delete.
  DataFilter? dataFilter;

  DeleteDeveloperMetadataRequest();

  DeleteDeveloperMetadataRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataFilter')) {
      dataFilter = DataFilter.fromJson(
          _json['dataFilter'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataFilter != null) 'dataFilter': dataFilter!.toJson(),
      };
}

/// The response from deleting developer metadata.
class DeleteDeveloperMetadataResponse {
  /// The metadata that was deleted.
  core.List<DeveloperMetadata>? deletedDeveloperMetadata;

  DeleteDeveloperMetadataResponse();

  DeleteDeveloperMetadataResponse.fromJson(core.Map _json) {
    if (_json.containsKey('deletedDeveloperMetadata')) {
      deletedDeveloperMetadata =
          (_json['deletedDeveloperMetadata'] as core.List)
              .map<DeveloperMetadata>((value) => DeveloperMetadata.fromJson(
                  value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deletedDeveloperMetadata != null)
          'deletedDeveloperMetadata':
              deletedDeveloperMetadata!.map((value) => value.toJson()).toList(),
      };
}

/// Deletes a group over the specified range by decrementing the depth of the
/// dimensions in the range.
///
/// For example, assume the sheet has a depth-1 group over B:E and a depth-2
/// group over C:D. Deleting a group over D:E leaves the sheet with a depth-1
/// group over B:D and a depth-2 group over C:C.
class DeleteDimensionGroupRequest {
  /// The range of the group to be deleted.
  DimensionRange? range;

  DeleteDimensionGroupRequest();

  DeleteDimensionGroupRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range = DimensionRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
      };
}

/// The result of deleting a group.
class DeleteDimensionGroupResponse {
  /// All groups of a dimension after deleting a group from that dimension.
  core.List<DimensionGroup>? dimensionGroups;

  DeleteDimensionGroupResponse();

  DeleteDimensionGroupResponse.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionGroups')) {
      dimensionGroups = (_json['dimensionGroups'] as core.List)
          .map<DimensionGroup>((value) => DimensionGroup.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionGroups != null)
          'dimensionGroups':
              dimensionGroups!.map((value) => value.toJson()).toList(),
      };
}

/// Deletes the dimensions from the sheet.
class DeleteDimensionRequest {
  /// The dimensions to delete from the sheet.
  DimensionRange? range;

  DeleteDimensionRequest();

  DeleteDimensionRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range = DimensionRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
      };
}

/// Removes rows within this range that contain values in the specified columns
/// that are duplicates of values in any previous row.
///
/// Rows with identical values but different letter cases, formatting, or
/// formulas are considered to be duplicates. This request also removes
/// duplicate rows hidden from view (for example, due to a filter). When
/// removing duplicates, the first instance of each duplicate row scanning from
/// the top downwards is kept in the resulting range. Content outside of the
/// specified range isn't removed, and rows considered duplicates do not have to
/// be adjacent to each other in the range.
class DeleteDuplicatesRequest {
  /// The columns in the range to analyze for duplicate values.
  ///
  /// If no columns are selected then all columns are analyzed for duplicates.
  core.List<DimensionRange>? comparisonColumns;

  /// The range to remove duplicates rows from.
  GridRange? range;

  DeleteDuplicatesRequest();

  DeleteDuplicatesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('comparisonColumns')) {
      comparisonColumns = (_json['comparisonColumns'] as core.List)
          .map<DimensionRange>((value) => DimensionRange.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (comparisonColumns != null)
          'comparisonColumns':
              comparisonColumns!.map((value) => value.toJson()).toList(),
        if (range != null) 'range': range!.toJson(),
      };
}

/// The result of removing duplicates in a range.
class DeleteDuplicatesResponse {
  /// The number of duplicate rows removed.
  core.int? duplicatesRemovedCount;

  DeleteDuplicatesResponse();

  DeleteDuplicatesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('duplicatesRemovedCount')) {
      duplicatesRemovedCount = _json['duplicatesRemovedCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (duplicatesRemovedCount != null)
          'duplicatesRemovedCount': duplicatesRemovedCount!,
      };
}

/// Deletes the embedded object with the given ID.
class DeleteEmbeddedObjectRequest {
  /// The ID of the embedded object to delete.
  core.int? objectId;

  DeleteEmbeddedObjectRequest();

  DeleteEmbeddedObjectRequest.fromJson(core.Map _json) {
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Deletes a particular filter view.
class DeleteFilterViewRequest {
  /// The ID of the filter to delete.
  core.int? filterId;

  DeleteFilterViewRequest();

  DeleteFilterViewRequest.fromJson(core.Map _json) {
    if (_json.containsKey('filterId')) {
      filterId = _json['filterId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filterId != null) 'filterId': filterId!,
      };
}

/// Removes the named range with the given ID from the spreadsheet.
class DeleteNamedRangeRequest {
  /// The ID of the named range to delete.
  core.String? namedRangeId;

  DeleteNamedRangeRequest();

  DeleteNamedRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('namedRangeId')) {
      namedRangeId = _json['namedRangeId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (namedRangeId != null) 'namedRangeId': namedRangeId!,
      };
}

/// Deletes the protected range with the given ID.
class DeleteProtectedRangeRequest {
  /// The ID of the protected range to delete.
  core.int? protectedRangeId;

  DeleteProtectedRangeRequest();

  DeleteProtectedRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('protectedRangeId')) {
      protectedRangeId = _json['protectedRangeId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (protectedRangeId != null) 'protectedRangeId': protectedRangeId!,
      };
}

/// Deletes a range of cells, shifting other cells into the deleted area.
class DeleteRangeRequest {
  /// The range of cells to delete.
  GridRange? range;

  /// The dimension from which deleted cells will be replaced with.
  ///
  /// If ROWS, existing cells will be shifted upward to replace the deleted
  /// cells. If COLUMNS, existing cells will be shifted left to replace the
  /// deleted cells.
  /// Possible string values are:
  /// - "DIMENSION_UNSPECIFIED" : The default value, do not use.
  /// - "ROWS" : Operates on the rows of a sheet.
  /// - "COLUMNS" : Operates on the columns of a sheet.
  core.String? shiftDimension;

  DeleteRangeRequest();

  DeleteRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shiftDimension')) {
      shiftDimension = _json['shiftDimension'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
        if (shiftDimension != null) 'shiftDimension': shiftDimension!,
      };
}

/// Deletes the requested sheet.
class DeleteSheetRequest {
  /// The ID of the sheet to delete.
  ///
  /// If the sheet is of DATA_SOURCE type, the associated DataSource is also
  /// deleted.
  core.int? sheetId;

  DeleteSheetRequest();

  DeleteSheetRequest.fromJson(core.Map _json) {
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sheetId != null) 'sheetId': sheetId!,
      };
}

/// Developer metadata associated with a location or object in a spreadsheet.
///
/// Developer metadata may be used to associate arbitrary data with various
/// parts of a spreadsheet and will remain associated at those locations as they
/// move around and the spreadsheet is edited. For example, if developer
/// metadata is associated with row 5 and another row is then subsequently
/// inserted above row 5, that original metadata will still be associated with
/// the row it was first associated with (what is now row 6). If the associated
/// object is deleted its metadata is deleted too.
class DeveloperMetadata {
  /// The location where the metadata is associated.
  DeveloperMetadataLocation? location;

  /// The spreadsheet-scoped unique ID that identifies the metadata.
  ///
  /// IDs may be specified when metadata is created, otherwise one will be
  /// randomly generated and assigned. Must be positive.
  core.int? metadataId;

  /// The metadata key.
  ///
  /// There may be multiple metadata in a spreadsheet with the same key.
  /// Developer metadata must always have a key specified.
  core.String? metadataKey;

  /// Data associated with the metadata's key.
  core.String? metadataValue;

  /// The metadata visibility.
  ///
  /// Developer metadata must always have a visibility specified.
  /// Possible string values are:
  /// - "DEVELOPER_METADATA_VISIBILITY_UNSPECIFIED" : Default value.
  /// - "DOCUMENT" : Document-visible metadata is accessible from any developer
  /// project with access to the document.
  /// - "PROJECT" : Project-visible metadata is only visible to and accessible
  /// by the developer project that created the metadata.
  core.String? visibility;

  DeveloperMetadata();

  DeveloperMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('location')) {
      location = DeveloperMetadataLocation.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metadataId')) {
      metadataId = _json['metadataId'] as core.int;
    }
    if (_json.containsKey('metadataKey')) {
      metadataKey = _json['metadataKey'] as core.String;
    }
    if (_json.containsKey('metadataValue')) {
      metadataValue = _json['metadataValue'] as core.String;
    }
    if (_json.containsKey('visibility')) {
      visibility = _json['visibility'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (location != null) 'location': location!.toJson(),
        if (metadataId != null) 'metadataId': metadataId!,
        if (metadataKey != null) 'metadataKey': metadataKey!,
        if (metadataValue != null) 'metadataValue': metadataValue!,
        if (visibility != null) 'visibility': visibility!,
      };
}

/// A location where metadata may be associated in a spreadsheet.
class DeveloperMetadataLocation {
  /// Represents the row or column when metadata is associated with a dimension.
  ///
  /// The specified DimensionRange must represent a single row or column; it
  /// cannot be unbounded or span multiple rows or columns.
  DimensionRange? dimensionRange;

  /// The type of location this object represents.
  ///
  /// This field is read-only.
  /// Possible string values are:
  /// - "DEVELOPER_METADATA_LOCATION_TYPE_UNSPECIFIED" : Default value.
  /// - "ROW" : Developer metadata associated on an entire row dimension.
  /// - "COLUMN" : Developer metadata associated on an entire column dimension.
  /// - "SHEET" : Developer metadata associated on an entire sheet.
  /// - "SPREADSHEET" : Developer metadata associated on the entire spreadsheet.
  core.String? locationType;

  /// The ID of the sheet when metadata is associated with an entire sheet.
  core.int? sheetId;

  /// True when metadata is associated with an entire spreadsheet.
  core.bool? spreadsheet;

  DeveloperMetadataLocation();

  DeveloperMetadataLocation.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionRange')) {
      dimensionRange = DimensionRange.fromJson(
          _json['dimensionRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('locationType')) {
      locationType = _json['locationType'] as core.String;
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
    if (_json.containsKey('spreadsheet')) {
      spreadsheet = _json['spreadsheet'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionRange != null) 'dimensionRange': dimensionRange!.toJson(),
        if (locationType != null) 'locationType': locationType!,
        if (sheetId != null) 'sheetId': sheetId!,
        if (spreadsheet != null) 'spreadsheet': spreadsheet!,
      };
}

/// Selects DeveloperMetadata that matches all of the specified fields.
///
/// For example, if only a metadata ID is specified this considers the
/// DeveloperMetadata with that particular unique ID. If a metadata key is
/// specified, this considers all developer metadata with that key. If a key,
/// visibility, and location type are all specified, this considers all
/// developer metadata with that key and visibility that are associated with a
/// location of that type. In general, this selects all DeveloperMetadata that
/// matches the intersection of all the specified fields; any field or
/// combination of fields may be specified.
class DeveloperMetadataLookup {
  /// Determines how this lookup matches the location.
  ///
  /// If this field is specified as EXACT, only developer metadata associated on
  /// the exact location specified is matched. If this field is specified to
  /// INTERSECTING, developer metadata associated on intersecting locations is
  /// also matched. If left unspecified, this field assumes a default value of
  /// INTERSECTING. If this field is specified, a metadataLocation must also be
  /// specified.
  /// Possible string values are:
  /// - "DEVELOPER_METADATA_LOCATION_MATCHING_STRATEGY_UNSPECIFIED" : Default
  /// value. This value must not be used.
  /// - "EXACT_LOCATION" : Indicates that a specified location should be matched
  /// exactly. For example, if row three were specified as a location this
  /// matching strategy would only match developer metadata also associated on
  /// row three. Metadata associated on other locations would not be considered.
  /// - "INTERSECTING_LOCATION" : Indicates that a specified location should
  /// match that exact location as well as any intersecting locations. For
  /// example, if row three were specified as a location this matching strategy
  /// would match developer metadata associated on row three as well as metadata
  /// associated on locations that intersect row three. If, for instance, there
  /// was developer metadata associated on column B, this matching strategy
  /// would also match that location because column B intersects row three.
  core.String? locationMatchingStrategy;

  /// Limits the selected developer metadata to those entries which are
  /// associated with locations of the specified type.
  ///
  /// For example, when this field is specified as ROW this lookup only
  /// considers developer metadata associated on rows. If the field is left
  /// unspecified, all location types are considered. This field cannot be
  /// specified as SPREADSHEET when the locationMatchingStrategy is specified as
  /// INTERSECTING or when the metadataLocation is specified as a
  /// non-spreadsheet location: spreadsheet metadata cannot intersect any other
  /// developer metadata location. This field also must be left unspecified when
  /// the locationMatchingStrategy is specified as EXACT.
  /// Possible string values are:
  /// - "DEVELOPER_METADATA_LOCATION_TYPE_UNSPECIFIED" : Default value.
  /// - "ROW" : Developer metadata associated on an entire row dimension.
  /// - "COLUMN" : Developer metadata associated on an entire column dimension.
  /// - "SHEET" : Developer metadata associated on an entire sheet.
  /// - "SPREADSHEET" : Developer metadata associated on the entire spreadsheet.
  core.String? locationType;

  /// Limits the selected developer metadata to that which has a matching
  /// DeveloperMetadata.metadata_id.
  core.int? metadataId;

  /// Limits the selected developer metadata to that which has a matching
  /// DeveloperMetadata.metadata_key.
  core.String? metadataKey;

  /// Limits the selected developer metadata to those entries associated with
  /// the specified location.
  ///
  /// This field either matches exact locations or all intersecting locations
  /// according the specified locationMatchingStrategy.
  DeveloperMetadataLocation? metadataLocation;

  /// Limits the selected developer metadata to that which has a matching
  /// DeveloperMetadata.metadata_value.
  core.String? metadataValue;

  /// Limits the selected developer metadata to that which has a matching
  /// DeveloperMetadata.visibility.
  ///
  /// If left unspecified, all developer metadata visibile to the requesting
  /// project is considered.
  /// Possible string values are:
  /// - "DEVELOPER_METADATA_VISIBILITY_UNSPECIFIED" : Default value.
  /// - "DOCUMENT" : Document-visible metadata is accessible from any developer
  /// project with access to the document.
  /// - "PROJECT" : Project-visible metadata is only visible to and accessible
  /// by the developer project that created the metadata.
  core.String? visibility;

  DeveloperMetadataLookup();

  DeveloperMetadataLookup.fromJson(core.Map _json) {
    if (_json.containsKey('locationMatchingStrategy')) {
      locationMatchingStrategy =
          _json['locationMatchingStrategy'] as core.String;
    }
    if (_json.containsKey('locationType')) {
      locationType = _json['locationType'] as core.String;
    }
    if (_json.containsKey('metadataId')) {
      metadataId = _json['metadataId'] as core.int;
    }
    if (_json.containsKey('metadataKey')) {
      metadataKey = _json['metadataKey'] as core.String;
    }
    if (_json.containsKey('metadataLocation')) {
      metadataLocation = DeveloperMetadataLocation.fromJson(
          _json['metadataLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metadataValue')) {
      metadataValue = _json['metadataValue'] as core.String;
    }
    if (_json.containsKey('visibility')) {
      visibility = _json['visibility'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (locationMatchingStrategy != null)
          'locationMatchingStrategy': locationMatchingStrategy!,
        if (locationType != null) 'locationType': locationType!,
        if (metadataId != null) 'metadataId': metadataId!,
        if (metadataKey != null) 'metadataKey': metadataKey!,
        if (metadataLocation != null)
          'metadataLocation': metadataLocation!.toJson(),
        if (metadataValue != null) 'metadataValue': metadataValue!,
        if (visibility != null) 'visibility': visibility!,
      };
}

/// A group over an interval of rows or columns on a sheet, which can contain or
/// be contained within other groups.
///
/// A group can be collapsed or expanded as a unit on the sheet.
class DimensionGroup {
  /// This field is true if this group is collapsed.
  ///
  /// A collapsed group remains collapsed if an overlapping group at a shallower
  /// depth is expanded. A true value does not imply that all dimensions within
  /// the group are hidden, since a dimension's visibility can change
  /// independently from this group property. However, when this property is
  /// updated, all dimensions within it are set to hidden if this field is true,
  /// or set to visible if this field is false.
  core.bool? collapsed;

  /// The depth of the group, representing how many groups have a range that
  /// wholly contains the range of this group.
  core.int? depth;

  /// The range over which this group exists.
  DimensionRange? range;

  DimensionGroup();

  DimensionGroup.fromJson(core.Map _json) {
    if (_json.containsKey('collapsed')) {
      collapsed = _json['collapsed'] as core.bool;
    }
    if (_json.containsKey('depth')) {
      depth = _json['depth'] as core.int;
    }
    if (_json.containsKey('range')) {
      range = DimensionRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (collapsed != null) 'collapsed': collapsed!,
        if (depth != null) 'depth': depth!,
        if (range != null) 'range': range!.toJson(),
      };
}

/// Properties about a dimension.
class DimensionProperties {
  /// If set, this is a column in a data source sheet.
  ///
  /// Output only.
  DataSourceColumnReference? dataSourceColumnReference;

  /// The developer metadata associated with a single row or column.
  core.List<DeveloperMetadata>? developerMetadata;

  /// True if this dimension is being filtered.
  ///
  /// This field is read-only.
  core.bool? hiddenByFilter;

  /// True if this dimension is explicitly hidden.
  core.bool? hiddenByUser;

  /// The height (if a row) or width (if a column) of the dimension in pixels.
  core.int? pixelSize;

  DimensionProperties();

  DimensionProperties.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceColumnReference')) {
      dataSourceColumnReference = DataSourceColumnReference.fromJson(
          _json['dataSourceColumnReference']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('developerMetadata')) {
      developerMetadata = (_json['developerMetadata'] as core.List)
          .map<DeveloperMetadata>((value) => DeveloperMetadata.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('hiddenByFilter')) {
      hiddenByFilter = _json['hiddenByFilter'] as core.bool;
    }
    if (_json.containsKey('hiddenByUser')) {
      hiddenByUser = _json['hiddenByUser'] as core.bool;
    }
    if (_json.containsKey('pixelSize')) {
      pixelSize = _json['pixelSize'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceColumnReference != null)
          'dataSourceColumnReference': dataSourceColumnReference!.toJson(),
        if (developerMetadata != null)
          'developerMetadata':
              developerMetadata!.map((value) => value.toJson()).toList(),
        if (hiddenByFilter != null) 'hiddenByFilter': hiddenByFilter!,
        if (hiddenByUser != null) 'hiddenByUser': hiddenByUser!,
        if (pixelSize != null) 'pixelSize': pixelSize!,
      };
}

/// A range along a single dimension on a sheet.
///
/// All indexes are zero-based. Indexes are half open: the start index is
/// inclusive and the end index is exclusive. Missing indexes indicate the range
/// is unbounded on that side.
class DimensionRange {
  /// The dimension of the span.
  /// Possible string values are:
  /// - "DIMENSION_UNSPECIFIED" : The default value, do not use.
  /// - "ROWS" : Operates on the rows of a sheet.
  /// - "COLUMNS" : Operates on the columns of a sheet.
  core.String? dimension;

  /// The end (exclusive) of the span, or not set if unbounded.
  core.int? endIndex;

  /// The sheet this span is on.
  core.int? sheetId;

  /// The start (inclusive) of the span, or not set if unbounded.
  core.int? startIndex;

  DimensionRange();

  DimensionRange.fromJson(core.Map _json) {
    if (_json.containsKey('dimension')) {
      dimension = _json['dimension'] as core.String;
    }
    if (_json.containsKey('endIndex')) {
      endIndex = _json['endIndex'] as core.int;
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
    if (_json.containsKey('startIndex')) {
      startIndex = _json['startIndex'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimension != null) 'dimension': dimension!,
        if (endIndex != null) 'endIndex': endIndex!,
        if (sheetId != null) 'sheetId': sheetId!,
        if (startIndex != null) 'startIndex': startIndex!,
      };
}

/// Duplicates a particular filter view.
class DuplicateFilterViewRequest {
  /// The ID of the filter being duplicated.
  core.int? filterId;

  DuplicateFilterViewRequest();

  DuplicateFilterViewRequest.fromJson(core.Map _json) {
    if (_json.containsKey('filterId')) {
      filterId = _json['filterId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filterId != null) 'filterId': filterId!,
      };
}

/// The result of a filter view being duplicated.
class DuplicateFilterViewResponse {
  /// The newly created filter.
  FilterView? filter;

  DuplicateFilterViewResponse();

  DuplicateFilterViewResponse.fromJson(core.Map _json) {
    if (_json.containsKey('filter')) {
      filter = FilterView.fromJson(
          _json['filter'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filter != null) 'filter': filter!.toJson(),
      };
}

/// Duplicates the contents of a sheet.
class DuplicateSheetRequest {
  /// The zero-based index where the new sheet should be inserted.
  ///
  /// The index of all sheets after this are incremented.
  core.int? insertSheetIndex;

  /// If set, the ID of the new sheet.
  ///
  /// If not set, an ID is chosen. If set, the ID must not conflict with any
  /// existing sheet ID. If set, it must be non-negative.
  core.int? newSheetId;

  /// The name of the new sheet.
  ///
  /// If empty, a new name is chosen for you.
  core.String? newSheetName;

  /// The sheet to duplicate.
  ///
  /// If the source sheet is of DATA_SOURCE type, its backing DataSource is also
  /// duplicated and associated with the new copy of the sheet. No data
  /// execution is triggered, the grid data of this sheet is also copied over
  /// but only available after the batch request completes.
  core.int? sourceSheetId;

  DuplicateSheetRequest();

  DuplicateSheetRequest.fromJson(core.Map _json) {
    if (_json.containsKey('insertSheetIndex')) {
      insertSheetIndex = _json['insertSheetIndex'] as core.int;
    }
    if (_json.containsKey('newSheetId')) {
      newSheetId = _json['newSheetId'] as core.int;
    }
    if (_json.containsKey('newSheetName')) {
      newSheetName = _json['newSheetName'] as core.String;
    }
    if (_json.containsKey('sourceSheetId')) {
      sourceSheetId = _json['sourceSheetId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (insertSheetIndex != null) 'insertSheetIndex': insertSheetIndex!,
        if (newSheetId != null) 'newSheetId': newSheetId!,
        if (newSheetName != null) 'newSheetName': newSheetName!,
        if (sourceSheetId != null) 'sourceSheetId': sourceSheetId!,
      };
}

/// The result of duplicating a sheet.
class DuplicateSheetResponse {
  /// The properties of the duplicate sheet.
  SheetProperties? properties;

  DuplicateSheetResponse();

  DuplicateSheetResponse.fromJson(core.Map _json) {
    if (_json.containsKey('properties')) {
      properties = SheetProperties.fromJson(
          _json['properties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (properties != null) 'properties': properties!.toJson(),
      };
}

/// The editors of a protected range.
class Editors {
  /// True if anyone in the document's domain has edit access to the protected
  /// range.
  ///
  /// Domain protection is only supported on documents within a domain.
  core.bool? domainUsersCanEdit;

  /// The email addresses of groups with edit access to the protected range.
  core.List<core.String>? groups;

  /// The email addresses of users with edit access to the protected range.
  core.List<core.String>? users;

  Editors();

  Editors.fromJson(core.Map _json) {
    if (_json.containsKey('domainUsersCanEdit')) {
      domainUsersCanEdit = _json['domainUsersCanEdit'] as core.bool;
    }
    if (_json.containsKey('groups')) {
      groups = (_json['groups'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('users')) {
      users = (_json['users'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (domainUsersCanEdit != null)
          'domainUsersCanEdit': domainUsersCanEdit!,
        if (groups != null) 'groups': groups!,
        if (users != null) 'users': users!,
      };
}

/// A chart embedded in a sheet.
class EmbeddedChart {
  /// The border of the chart.
  EmbeddedObjectBorder? border;

  /// The ID of the chart.
  core.int? chartId;

  /// The position of the chart.
  EmbeddedObjectPosition? position;

  /// The specification of the chart.
  ChartSpec? spec;

  EmbeddedChart();

  EmbeddedChart.fromJson(core.Map _json) {
    if (_json.containsKey('border')) {
      border = EmbeddedObjectBorder.fromJson(
          _json['border'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('chartId')) {
      chartId = _json['chartId'] as core.int;
    }
    if (_json.containsKey('position')) {
      position = EmbeddedObjectPosition.fromJson(
          _json['position'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spec')) {
      spec = ChartSpec.fromJson(
          _json['spec'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (border != null) 'border': border!.toJson(),
        if (chartId != null) 'chartId': chartId!,
        if (position != null) 'position': position!.toJson(),
        if (spec != null) 'spec': spec!.toJson(),
      };
}

/// A border along an embedded object.
class EmbeddedObjectBorder {
  /// The color of the border.
  Color? color;

  /// The color of the border.
  ///
  /// If color is also set, this field takes precedence.
  ColorStyle? colorStyle;

  EmbeddedObjectBorder();

  EmbeddedObjectBorder.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color =
          Color.fromJson(_json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('colorStyle')) {
      colorStyle = ColorStyle.fromJson(
          _json['colorStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
        if (colorStyle != null) 'colorStyle': colorStyle!.toJson(),
      };
}

/// The position of an embedded object such as a chart.
class EmbeddedObjectPosition {
  /// If true, the embedded object is put on a new sheet whose ID is chosen for
  /// you.
  ///
  /// Used only when writing.
  core.bool? newSheet;

  /// The position at which the object is overlaid on top of a grid.
  OverlayPosition? overlayPosition;

  /// The sheet this is on.
  ///
  /// Set only if the embedded object is on its own sheet. Must be non-negative.
  core.int? sheetId;

  EmbeddedObjectPosition();

  EmbeddedObjectPosition.fromJson(core.Map _json) {
    if (_json.containsKey('newSheet')) {
      newSheet = _json['newSheet'] as core.bool;
    }
    if (_json.containsKey('overlayPosition')) {
      overlayPosition = OverlayPosition.fromJson(
          _json['overlayPosition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (newSheet != null) 'newSheet': newSheet!,
        if (overlayPosition != null)
          'overlayPosition': overlayPosition!.toJson(),
        if (sheetId != null) 'sheetId': sheetId!,
      };
}

/// An error in a cell.
class ErrorValue {
  /// A message with more information about the error (in the spreadsheet's
  /// locale).
  core.String? message;

  /// The type of error.
  /// Possible string values are:
  /// - "ERROR_TYPE_UNSPECIFIED" : The default error type, do not use this.
  /// - "ERROR" : Corresponds to the `#ERROR!` error.
  /// - "NULL_VALUE" : Corresponds to the `#NULL!` error.
  /// - "DIVIDE_BY_ZERO" : Corresponds to the `#DIV/0` error.
  /// - "VALUE" : Corresponds to the `#VALUE!` error.
  /// - "REF" : Corresponds to the `#REF!` error.
  /// - "NAME" : Corresponds to the `#NAME?` error.
  /// - "NUM" : Corresponds to the `#NUM!` error.
  /// - "N_A" : Corresponds to the `#N/A` error.
  /// - "LOADING" : Corresponds to the `Loading...` state.
  core.String? type;

  ErrorValue();

  ErrorValue.fromJson(core.Map _json) {
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (message != null) 'message': message!,
        if (type != null) 'type': type!,
      };
}

/// The kinds of value that a cell in a spreadsheet can have.
class ExtendedValue {
  /// Represents a boolean value.
  core.bool? boolValue;

  /// Represents an error.
  ///
  /// This field is read-only.
  ErrorValue? errorValue;

  /// Represents a formula.
  core.String? formulaValue;

  /// Represents a double value.
  ///
  /// Note: Dates, Times and DateTimes are represented as doubles in
  /// SERIAL_NUMBER format.
  core.double? numberValue;

  /// Represents a string value.
  ///
  /// Leading single quotes are not included. For example, if the user typed
  /// `'123` into the UI, this would be represented as a `stringValue` of
  /// `"123"`.
  core.String? stringValue;

  ExtendedValue();

  ExtendedValue.fromJson(core.Map _json) {
    if (_json.containsKey('boolValue')) {
      boolValue = _json['boolValue'] as core.bool;
    }
    if (_json.containsKey('errorValue')) {
      errorValue = ErrorValue.fromJson(
          _json['errorValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('formulaValue')) {
      formulaValue = _json['formulaValue'] as core.String;
    }
    if (_json.containsKey('numberValue')) {
      numberValue = (_json['numberValue'] as core.num).toDouble();
    }
    if (_json.containsKey('stringValue')) {
      stringValue = _json['stringValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (boolValue != null) 'boolValue': boolValue!,
        if (errorValue != null) 'errorValue': errorValue!.toJson(),
        if (formulaValue != null) 'formulaValue': formulaValue!,
        if (numberValue != null) 'numberValue': numberValue!,
        if (stringValue != null) 'stringValue': stringValue!,
      };
}

/// Criteria for showing/hiding rows in a filter or filter view.
class FilterCriteria {
  /// A condition that must be true for values to be shown.
  ///
  /// (This does not override hidden_values -- if a value is listed there, it
  /// will still be hidden.)
  BooleanCondition? condition;

  /// Values that should be hidden.
  core.List<core.String>? hiddenValues;

  /// The background fill color to filter by; only cells with this fill color
  /// are shown.
  ///
  /// Mutually exclusive with visible_foreground_color.
  Color? visibleBackgroundColor;

  /// The background fill color to filter by; only cells with this fill color
  /// are shown.
  ///
  /// This field is mutually exclusive with visible_foreground_color, and must
  /// be set to an RGB-type color. If visible_background_color is also set, this
  /// field takes precedence.
  ColorStyle? visibleBackgroundColorStyle;

  /// The foreground color to filter by; only cells with this foreground color
  /// are shown.
  ///
  /// Mutually exclusive with visible_background_color.
  Color? visibleForegroundColor;

  /// The foreground color to filter by; only cells with this foreground color
  /// are shown.
  ///
  /// This field is mutually exclusive with visible_background_color, and must
  /// be set to an RGB-type color. If visible_foreground_color is also set, this
  /// field takes precedence.
  ColorStyle? visibleForegroundColorStyle;

  FilterCriteria();

  FilterCriteria.fromJson(core.Map _json) {
    if (_json.containsKey('condition')) {
      condition = BooleanCondition.fromJson(
          _json['condition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hiddenValues')) {
      hiddenValues = (_json['hiddenValues'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('visibleBackgroundColor')) {
      visibleBackgroundColor = Color.fromJson(_json['visibleBackgroundColor']
          as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('visibleBackgroundColorStyle')) {
      visibleBackgroundColorStyle = ColorStyle.fromJson(
          _json['visibleBackgroundColorStyle']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('visibleForegroundColor')) {
      visibleForegroundColor = Color.fromJson(_json['visibleForegroundColor']
          as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('visibleForegroundColorStyle')) {
      visibleForegroundColorStyle = ColorStyle.fromJson(
          _json['visibleForegroundColorStyle']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (condition != null) 'condition': condition!.toJson(),
        if (hiddenValues != null) 'hiddenValues': hiddenValues!,
        if (visibleBackgroundColor != null)
          'visibleBackgroundColor': visibleBackgroundColor!.toJson(),
        if (visibleBackgroundColorStyle != null)
          'visibleBackgroundColorStyle': visibleBackgroundColorStyle!.toJson(),
        if (visibleForegroundColor != null)
          'visibleForegroundColor': visibleForegroundColor!.toJson(),
        if (visibleForegroundColorStyle != null)
          'visibleForegroundColorStyle': visibleForegroundColorStyle!.toJson(),
      };
}

/// The filter criteria associated with a specific column.
class FilterSpec {
  /// The column index.
  core.int? columnIndex;

  /// Reference to a data source column.
  DataSourceColumnReference? dataSourceColumnReference;

  /// The criteria for the column.
  FilterCriteria? filterCriteria;

  FilterSpec();

  FilterSpec.fromJson(core.Map _json) {
    if (_json.containsKey('columnIndex')) {
      columnIndex = _json['columnIndex'] as core.int;
    }
    if (_json.containsKey('dataSourceColumnReference')) {
      dataSourceColumnReference = DataSourceColumnReference.fromJson(
          _json['dataSourceColumnReference']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('filterCriteria')) {
      filterCriteria = FilterCriteria.fromJson(
          _json['filterCriteria'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnIndex != null) 'columnIndex': columnIndex!,
        if (dataSourceColumnReference != null)
          'dataSourceColumnReference': dataSourceColumnReference!.toJson(),
        if (filterCriteria != null) 'filterCriteria': filterCriteria!.toJson(),
      };
}

/// A filter view.
class FilterView {
  /// The criteria for showing/hiding values per column.
  ///
  /// The map's key is the column index, and the value is the criteria for that
  /// column. This field is deprecated in favor of filter_specs.
  core.Map<core.String, FilterCriteria>? criteria;

  /// The filter criteria for showing/hiding values per column.
  ///
  /// Both criteria and filter_specs are populated in responses. If both fields
  /// are specified in an update request, this field takes precedence.
  core.List<FilterSpec>? filterSpecs;

  /// The ID of the filter view.
  core.int? filterViewId;

  /// The named range this filter view is backed by, if any.
  ///
  /// When writing, only one of range or named_range_id may be set.
  core.String? namedRangeId;

  /// The range this filter view covers.
  ///
  /// When writing, only one of range or named_range_id may be set.
  GridRange? range;

  /// The sort order per column.
  ///
  /// Later specifications are used when values are equal in the earlier
  /// specifications.
  core.List<SortSpec>? sortSpecs;

  /// The name of the filter view.
  core.String? title;

  FilterView();

  FilterView.fromJson(core.Map _json) {
    if (_json.containsKey('criteria')) {
      criteria = (_json['criteria'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          FilterCriteria.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('filterSpecs')) {
      filterSpecs = (_json['filterSpecs'] as core.List)
          .map<FilterSpec>((value) =>
              FilterSpec.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('filterViewId')) {
      filterViewId = _json['filterViewId'] as core.int;
    }
    if (_json.containsKey('namedRangeId')) {
      namedRangeId = _json['namedRangeId'] as core.String;
    }
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sortSpecs')) {
      sortSpecs = (_json['sortSpecs'] as core.List)
          .map<SortSpec>((value) =>
              SortSpec.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (criteria != null)
          'criteria':
              criteria!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (filterSpecs != null)
          'filterSpecs': filterSpecs!.map((value) => value.toJson()).toList(),
        if (filterViewId != null) 'filterViewId': filterViewId!,
        if (namedRangeId != null) 'namedRangeId': namedRangeId!,
        if (range != null) 'range': range!.toJson(),
        if (sortSpecs != null)
          'sortSpecs': sortSpecs!.map((value) => value.toJson()).toList(),
        if (title != null) 'title': title!,
      };
}

/// Finds and replaces data in cells over a range, sheet, or all sheets.
class FindReplaceRequest {
  /// True to find/replace over all sheets.
  core.bool? allSheets;

  /// The value to search.
  core.String? find;

  /// True if the search should include cells with formulas.
  ///
  /// False to skip cells with formulas.
  core.bool? includeFormulas;

  /// True if the search is case sensitive.
  core.bool? matchCase;

  /// True if the find value should match the entire cell.
  core.bool? matchEntireCell;

  /// The range to find/replace over.
  GridRange? range;

  /// The value to use as the replacement.
  core.String? replacement;

  /// True if the find value is a regex.
  ///
  /// The regular expression and replacement should follow Java regex rules at
  /// https://docs.oracle.com/javase/8/docs/api/java/util/regex/Pattern.html.
  /// The replacement string is allowed to refer to capturing groups. For
  /// example, if one cell has the contents `"Google Sheets"` and another has
  /// `"Google Docs"`, then searching for `"o.* (.*)"` with a replacement of
  /// `"$1 Rocks"` would change the contents of the cells to `"GSheets Rocks"`
  /// and `"GDocs Rocks"` respectively.
  core.bool? searchByRegex;

  /// The sheet to find/replace over.
  core.int? sheetId;

  FindReplaceRequest();

  FindReplaceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('allSheets')) {
      allSheets = _json['allSheets'] as core.bool;
    }
    if (_json.containsKey('find')) {
      find = _json['find'] as core.String;
    }
    if (_json.containsKey('includeFormulas')) {
      includeFormulas = _json['includeFormulas'] as core.bool;
    }
    if (_json.containsKey('matchCase')) {
      matchCase = _json['matchCase'] as core.bool;
    }
    if (_json.containsKey('matchEntireCell')) {
      matchEntireCell = _json['matchEntireCell'] as core.bool;
    }
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('replacement')) {
      replacement = _json['replacement'] as core.String;
    }
    if (_json.containsKey('searchByRegex')) {
      searchByRegex = _json['searchByRegex'] as core.bool;
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allSheets != null) 'allSheets': allSheets!,
        if (find != null) 'find': find!,
        if (includeFormulas != null) 'includeFormulas': includeFormulas!,
        if (matchCase != null) 'matchCase': matchCase!,
        if (matchEntireCell != null) 'matchEntireCell': matchEntireCell!,
        if (range != null) 'range': range!.toJson(),
        if (replacement != null) 'replacement': replacement!,
        if (searchByRegex != null) 'searchByRegex': searchByRegex!,
        if (sheetId != null) 'sheetId': sheetId!,
      };
}

/// The result of the find/replace.
class FindReplaceResponse {
  /// The number of formula cells changed.
  core.int? formulasChanged;

  /// The number of occurrences (possibly multiple within a cell) changed.
  ///
  /// For example, if replacing `"e"` with `"o"` in `"Google Sheets"`, this
  /// would be `"3"` because `"Google Sheets"` -> `"Googlo Shoots"`.
  core.int? occurrencesChanged;

  /// The number of rows changed.
  core.int? rowsChanged;

  /// The number of sheets changed.
  core.int? sheetsChanged;

  /// The number of non-formula cells changed.
  core.int? valuesChanged;

  FindReplaceResponse();

  FindReplaceResponse.fromJson(core.Map _json) {
    if (_json.containsKey('formulasChanged')) {
      formulasChanged = _json['formulasChanged'] as core.int;
    }
    if (_json.containsKey('occurrencesChanged')) {
      occurrencesChanged = _json['occurrencesChanged'] as core.int;
    }
    if (_json.containsKey('rowsChanged')) {
      rowsChanged = _json['rowsChanged'] as core.int;
    }
    if (_json.containsKey('sheetsChanged')) {
      sheetsChanged = _json['sheetsChanged'] as core.int;
    }
    if (_json.containsKey('valuesChanged')) {
      valuesChanged = _json['valuesChanged'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (formulasChanged != null) 'formulasChanged': formulasChanged!,
        if (occurrencesChanged != null)
          'occurrencesChanged': occurrencesChanged!,
        if (rowsChanged != null) 'rowsChanged': rowsChanged!,
        if (sheetsChanged != null) 'sheetsChanged': sheetsChanged!,
        if (valuesChanged != null) 'valuesChanged': valuesChanged!,
      };
}

/// The request for retrieving a Spreadsheet.
class GetSpreadsheetByDataFilterRequest {
  /// The DataFilters used to select which ranges to retrieve from the
  /// spreadsheet.
  core.List<DataFilter>? dataFilters;

  /// True if grid data should be returned.
  ///
  /// This parameter is ignored if a field mask was set in the request.
  core.bool? includeGridData;

  GetSpreadsheetByDataFilterRequest();

  GetSpreadsheetByDataFilterRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataFilters')) {
      dataFilters = (_json['dataFilters'] as core.List)
          .map<DataFilter>((value) =>
              DataFilter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('includeGridData')) {
      includeGridData = _json['includeGridData'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataFilters != null)
          'dataFilters': dataFilters!.map((value) => value.toJson()).toList(),
        if (includeGridData != null) 'includeGridData': includeGridData!,
      };
}

/// A rule that applies a gradient color scale format, based on the
/// interpolation points listed.
///
/// The format of a cell will vary based on its contents as compared to the
/// values of the interpolation points.
class GradientRule {
  /// The final interpolation point.
  InterpolationPoint? maxpoint;

  /// An optional midway interpolation point.
  InterpolationPoint? midpoint;

  /// The starting interpolation point.
  InterpolationPoint? minpoint;

  GradientRule();

  GradientRule.fromJson(core.Map _json) {
    if (_json.containsKey('maxpoint')) {
      maxpoint = InterpolationPoint.fromJson(
          _json['maxpoint'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('midpoint')) {
      midpoint = InterpolationPoint.fromJson(
          _json['midpoint'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('minpoint')) {
      minpoint = InterpolationPoint.fromJson(
          _json['minpoint'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maxpoint != null) 'maxpoint': maxpoint!.toJson(),
        if (midpoint != null) 'midpoint': midpoint!.toJson(),
        if (minpoint != null) 'minpoint': minpoint!.toJson(),
      };
}

/// A coordinate in a sheet.
///
/// All indexes are zero-based.
class GridCoordinate {
  /// The column index of the coordinate.
  core.int? columnIndex;

  /// The row index of the coordinate.
  core.int? rowIndex;

  /// The sheet this coordinate is on.
  core.int? sheetId;

  GridCoordinate();

  GridCoordinate.fromJson(core.Map _json) {
    if (_json.containsKey('columnIndex')) {
      columnIndex = _json['columnIndex'] as core.int;
    }
    if (_json.containsKey('rowIndex')) {
      rowIndex = _json['rowIndex'] as core.int;
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnIndex != null) 'columnIndex': columnIndex!,
        if (rowIndex != null) 'rowIndex': rowIndex!,
        if (sheetId != null) 'sheetId': sheetId!,
      };
}

/// Data in the grid, as well as metadata about the dimensions.
class GridData {
  /// Metadata about the requested columns in the grid, starting with the column
  /// in start_column.
  core.List<DimensionProperties>? columnMetadata;

  /// The data in the grid, one entry per row, starting with the row in
  /// startRow.
  ///
  /// The values in RowData will correspond to columns starting at start_column.
  core.List<RowData>? rowData;

  /// Metadata about the requested rows in the grid, starting with the row in
  /// start_row.
  core.List<DimensionProperties>? rowMetadata;

  /// The first column this GridData refers to, zero-based.
  core.int? startColumn;

  /// The first row this GridData refers to, zero-based.
  core.int? startRow;

  GridData();

  GridData.fromJson(core.Map _json) {
    if (_json.containsKey('columnMetadata')) {
      columnMetadata = (_json['columnMetadata'] as core.List)
          .map<DimensionProperties>((value) => DimensionProperties.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('rowData')) {
      rowData = (_json['rowData'] as core.List)
          .map<RowData>((value) =>
              RowData.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('rowMetadata')) {
      rowMetadata = (_json['rowMetadata'] as core.List)
          .map<DimensionProperties>((value) => DimensionProperties.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('startColumn')) {
      startColumn = _json['startColumn'] as core.int;
    }
    if (_json.containsKey('startRow')) {
      startRow = _json['startRow'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnMetadata != null)
          'columnMetadata':
              columnMetadata!.map((value) => value.toJson()).toList(),
        if (rowData != null)
          'rowData': rowData!.map((value) => value.toJson()).toList(),
        if (rowMetadata != null)
          'rowMetadata': rowMetadata!.map((value) => value.toJson()).toList(),
        if (startColumn != null) 'startColumn': startColumn!,
        if (startRow != null) 'startRow': startRow!,
      };
}

/// Properties of a grid.
class GridProperties {
  /// The number of columns in the grid.
  core.int? columnCount;

  /// True if the column grouping control toggle is shown after the group.
  core.bool? columnGroupControlAfter;

  /// The number of columns that are frozen in the grid.
  core.int? frozenColumnCount;

  /// The number of rows that are frozen in the grid.
  core.int? frozenRowCount;

  /// True if the grid isn't showing gridlines in the UI.
  core.bool? hideGridlines;

  /// The number of rows in the grid.
  core.int? rowCount;

  /// True if the row grouping control toggle is shown after the group.
  core.bool? rowGroupControlAfter;

  GridProperties();

  GridProperties.fromJson(core.Map _json) {
    if (_json.containsKey('columnCount')) {
      columnCount = _json['columnCount'] as core.int;
    }
    if (_json.containsKey('columnGroupControlAfter')) {
      columnGroupControlAfter = _json['columnGroupControlAfter'] as core.bool;
    }
    if (_json.containsKey('frozenColumnCount')) {
      frozenColumnCount = _json['frozenColumnCount'] as core.int;
    }
    if (_json.containsKey('frozenRowCount')) {
      frozenRowCount = _json['frozenRowCount'] as core.int;
    }
    if (_json.containsKey('hideGridlines')) {
      hideGridlines = _json['hideGridlines'] as core.bool;
    }
    if (_json.containsKey('rowCount')) {
      rowCount = _json['rowCount'] as core.int;
    }
    if (_json.containsKey('rowGroupControlAfter')) {
      rowGroupControlAfter = _json['rowGroupControlAfter'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnCount != null) 'columnCount': columnCount!,
        if (columnGroupControlAfter != null)
          'columnGroupControlAfter': columnGroupControlAfter!,
        if (frozenColumnCount != null) 'frozenColumnCount': frozenColumnCount!,
        if (frozenRowCount != null) 'frozenRowCount': frozenRowCount!,
        if (hideGridlines != null) 'hideGridlines': hideGridlines!,
        if (rowCount != null) 'rowCount': rowCount!,
        if (rowGroupControlAfter != null)
          'rowGroupControlAfter': rowGroupControlAfter!,
      };
}

/// A range on a sheet.
///
/// All indexes are zero-based. Indexes are half open, i.e. the start index is
/// inclusive and the end index is exclusive -- \[start_index, end_index).
/// Missing indexes indicate the range is unbounded on that side. For example,
/// if `"Sheet1"` is sheet ID 0, then: `Sheet1!A1:A1 == sheet_id: 0,
/// start_row_index: 0, end_row_index: 1, start_column_index: 0,
/// end_column_index: 1` `Sheet1!A3:B4 == sheet_id: 0, start_row_index: 2,
/// end_row_index: 4, start_column_index: 0, end_column_index: 2` `Sheet1!A:B ==
/// sheet_id: 0, start_column_index: 0, end_column_index: 2` `Sheet1!A5:B ==
/// sheet_id: 0, start_row_index: 4, start_column_index: 0, end_column_index: 2`
/// `Sheet1 == sheet_id:0` The start index must always be less than or equal to
/// the end index. If the start index equals the end index, then the range is
/// empty. Empty ranges are typically not meaningful and are usually rendered in
/// the UI as `#REF!`.
class GridRange {
  /// The end column (exclusive) of the range, or not set if unbounded.
  core.int? endColumnIndex;

  /// The end row (exclusive) of the range, or not set if unbounded.
  core.int? endRowIndex;

  /// The sheet this range is on.
  core.int? sheetId;

  /// The start column (inclusive) of the range, or not set if unbounded.
  core.int? startColumnIndex;

  /// The start row (inclusive) of the range, or not set if unbounded.
  core.int? startRowIndex;

  GridRange();

  GridRange.fromJson(core.Map _json) {
    if (_json.containsKey('endColumnIndex')) {
      endColumnIndex = _json['endColumnIndex'] as core.int;
    }
    if (_json.containsKey('endRowIndex')) {
      endRowIndex = _json['endRowIndex'] as core.int;
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
    if (_json.containsKey('startColumnIndex')) {
      startColumnIndex = _json['startColumnIndex'] as core.int;
    }
    if (_json.containsKey('startRowIndex')) {
      startRowIndex = _json['startRowIndex'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endColumnIndex != null) 'endColumnIndex': endColumnIndex!,
        if (endRowIndex != null) 'endRowIndex': endRowIndex!,
        if (sheetId != null) 'sheetId': sheetId!,
        if (startColumnIndex != null) 'startColumnIndex': startColumnIndex!,
        if (startRowIndex != null) 'startRowIndex': startRowIndex!,
      };
}

/// A histogram chart.
///
/// A histogram chart groups data items into bins, displaying each bin as a
/// column of stacked items. Histograms are used to display the distribution of
/// a dataset. Each column of items represents a range into which those items
/// fall. The number of bins can be chosen automatically or specified
/// explicitly.
class HistogramChartSpec {
  /// By default the bucket size (the range of values stacked in a single
  /// column) is chosen automatically, but it may be overridden here.
  ///
  /// E.g., A bucket size of 1.5 results in buckets from 0 - 1.5, 1.5 - 3.0,
  /// etc. Cannot be negative. This field is optional.
  core.double? bucketSize;

  /// The position of the chart legend.
  /// Possible string values are:
  /// - "HISTOGRAM_CHART_LEGEND_POSITION_UNSPECIFIED" : Default value, do not
  /// use.
  /// - "BOTTOM_LEGEND" : The legend is rendered on the bottom of the chart.
  /// - "LEFT_LEGEND" : The legend is rendered on the left of the chart.
  /// - "RIGHT_LEGEND" : The legend is rendered on the right of the chart.
  /// - "TOP_LEGEND" : The legend is rendered on the top of the chart.
  /// - "NO_LEGEND" : No legend is rendered.
  /// - "INSIDE_LEGEND" : The legend is rendered inside the chart area.
  core.String? legendPosition;

  /// The outlier percentile is used to ensure that outliers do not adversely
  /// affect the calculation of bucket sizes.
  ///
  /// For example, setting an outlier percentile of 0.05 indicates that the top
  /// and bottom 5% of values when calculating buckets. The values are still
  /// included in the chart, they will be added to the first or last buckets
  /// instead of their own buckets. Must be between 0.0 and 0.5.
  core.double? outlierPercentile;

  /// The series for a histogram may be either a single series of values to be
  /// bucketed or multiple series, each of the same length, containing the name
  /// of the series followed by the values to be bucketed for that series.
  core.List<HistogramSeries>? series;

  /// Whether horizontal divider lines should be displayed between items in each
  /// column.
  core.bool? showItemDividers;

  HistogramChartSpec();

  HistogramChartSpec.fromJson(core.Map _json) {
    if (_json.containsKey('bucketSize')) {
      bucketSize = (_json['bucketSize'] as core.num).toDouble();
    }
    if (_json.containsKey('legendPosition')) {
      legendPosition = _json['legendPosition'] as core.String;
    }
    if (_json.containsKey('outlierPercentile')) {
      outlierPercentile = (_json['outlierPercentile'] as core.num).toDouble();
    }
    if (_json.containsKey('series')) {
      series = (_json['series'] as core.List)
          .map<HistogramSeries>((value) => HistogramSeries.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('showItemDividers')) {
      showItemDividers = _json['showItemDividers'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bucketSize != null) 'bucketSize': bucketSize!,
        if (legendPosition != null) 'legendPosition': legendPosition!,
        if (outlierPercentile != null) 'outlierPercentile': outlierPercentile!,
        if (series != null)
          'series': series!.map((value) => value.toJson()).toList(),
        if (showItemDividers != null) 'showItemDividers': showItemDividers!,
      };
}

/// Allows you to organize the numeric values in a source data column into
/// buckets of a constant size.
///
/// All values from HistogramRule.start to HistogramRule.end are placed into
/// groups of size HistogramRule.interval. In addition, all values below
/// HistogramRule.start are placed in one group, and all values above
/// HistogramRule.end are placed in another. Only HistogramRule.interval is
/// required, though if HistogramRule.start and HistogramRule.end are both
/// provided, HistogramRule.start must be less than HistogramRule.end. For
/// example, a pivot table showing average purchase amount by age that has 50+
/// rows: +-----+-------------------+ | Age | AVERAGE of Amount |
/// +-----+-------------------+ | 16 | $27.13 | | 17 | $5.24 | | 18 | $20.15 |
/// ... +-----+-------------------+ could be turned into a pivot table that
/// looks like the one below by applying a histogram group rule with a
/// HistogramRule.start of 25, an HistogramRule.interval of 20, and an
/// HistogramRule.end of 65. +-------------+-------------------+ | Grouped Age |
/// AVERAGE of Amount | +-------------+-------------------+ | < 25 | $19.34 | |
/// 25-45 | $31.43 | | 45-65 | $35.87 | | > 65 | $27.55 |
/// +-------------+-------------------+ | Grand Total | $29.12 |
/// +-------------+-------------------+
class HistogramRule {
  /// The maximum value at which items are placed into buckets of constant size.
  ///
  /// Values above end are lumped into a single bucket. This field is optional.
  core.double? end;

  /// The size of the buckets that are created.
  ///
  /// Must be positive.
  core.double? interval;

  /// The minimum value at which items are placed into buckets of constant size.
  ///
  /// Values below start are lumped into a single bucket. This field is
  /// optional.
  core.double? start;

  HistogramRule();

  HistogramRule.fromJson(core.Map _json) {
    if (_json.containsKey('end')) {
      end = (_json['end'] as core.num).toDouble();
    }
    if (_json.containsKey('interval')) {
      interval = (_json['interval'] as core.num).toDouble();
    }
    if (_json.containsKey('start')) {
      start = (_json['start'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (end != null) 'end': end!,
        if (interval != null) 'interval': interval!,
        if (start != null) 'start': start!,
      };
}

/// A histogram series containing the series color and data.
class HistogramSeries {
  /// The color of the column representing this series in each bucket.
  ///
  /// This field is optional.
  Color? barColor;

  /// The color of the column representing this series in each bucket.
  ///
  /// This field is optional. If bar_color is also set, this field takes
  /// precedence.
  ColorStyle? barColorStyle;

  /// The data for this histogram series.
  ChartData? data;

  HistogramSeries();

  HistogramSeries.fromJson(core.Map _json) {
    if (_json.containsKey('barColor')) {
      barColor = Color.fromJson(
          _json['barColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('barColorStyle')) {
      barColorStyle = ColorStyle.fromJson(
          _json['barColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('data')) {
      data = ChartData.fromJson(
          _json['data'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (barColor != null) 'barColor': barColor!.toJson(),
        if (barColorStyle != null) 'barColorStyle': barColorStyle!.toJson(),
        if (data != null) 'data': data!.toJson(),
      };
}

/// Inserts rows or columns in a sheet at a particular index.
class InsertDimensionRequest {
  /// Whether dimension properties should be extended from the dimensions before
  /// or after the newly inserted dimensions.
  ///
  /// True to inherit from the dimensions before (in which case the start index
  /// must be greater than 0), and false to inherit from the dimensions after.
  /// For example, if row index 0 has red background and row index 1 has a green
  /// background, then inserting 2 rows at index 1 can inherit either the green
  /// or red background. If `inheritFromBefore` is true, the two new rows will
  /// be red (because the row before the insertion point was red), whereas if
  /// `inheritFromBefore` is false, the two new rows will be green (because the
  /// row after the insertion point was green).
  core.bool? inheritFromBefore;

  /// The dimensions to insert.
  ///
  /// Both the start and end indexes must be bounded.
  DimensionRange? range;

  InsertDimensionRequest();

  InsertDimensionRequest.fromJson(core.Map _json) {
    if (_json.containsKey('inheritFromBefore')) {
      inheritFromBefore = _json['inheritFromBefore'] as core.bool;
    }
    if (_json.containsKey('range')) {
      range = DimensionRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inheritFromBefore != null) 'inheritFromBefore': inheritFromBefore!,
        if (range != null) 'range': range!.toJson(),
      };
}

/// Inserts cells into a range, shifting the existing cells over or down.
class InsertRangeRequest {
  /// The range to insert new cells into.
  GridRange? range;

  /// The dimension which will be shifted when inserting cells.
  ///
  /// If ROWS, existing cells will be shifted down. If COLUMNS, existing cells
  /// will be shifted right.
  /// Possible string values are:
  /// - "DIMENSION_UNSPECIFIED" : The default value, do not use.
  /// - "ROWS" : Operates on the rows of a sheet.
  /// - "COLUMNS" : Operates on the columns of a sheet.
  core.String? shiftDimension;

  InsertRangeRequest();

  InsertRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shiftDimension')) {
      shiftDimension = _json['shiftDimension'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
        if (shiftDimension != null) 'shiftDimension': shiftDimension!,
      };
}

/// A single interpolation point on a gradient conditional format.
///
/// These pin the gradient color scale according to the color, type and value
/// chosen.
class InterpolationPoint {
  /// The color this interpolation point should use.
  Color? color;

  /// The color this interpolation point should use.
  ///
  /// If color is also set, this field takes precedence.
  ColorStyle? colorStyle;

  /// How the value should be interpreted.
  /// Possible string values are:
  /// - "INTERPOLATION_POINT_TYPE_UNSPECIFIED" : The default value, do not use.
  /// - "MIN" : The interpolation point uses the minimum value in the cells over
  /// the range of the conditional format.
  /// - "MAX" : The interpolation point uses the maximum value in the cells over
  /// the range of the conditional format.
  /// - "NUMBER" : The interpolation point uses exactly the value in
  /// InterpolationPoint.value.
  /// - "PERCENT" : The interpolation point is the given percentage over all the
  /// cells in the range of the conditional format. This is equivalent to
  /// `NUMBER` if the value was: `=(MAX(FLATTEN(range)) * (value / 100)) +
  /// (MIN(FLATTEN(range)) * (1 - (value / 100)))` (where errors in the range
  /// are ignored when flattening).
  /// - "PERCENTILE" : The interpolation point is the given percentile over all
  /// the cells in the range of the conditional format. This is equivalent to
  /// `NUMBER` if the value was: `=PERCENTILE(FLATTEN(range), value / 100)`
  /// (where errors in the range are ignored when flattening).
  core.String? type;

  /// The value this interpolation point uses.
  ///
  /// May be a formula. Unused if type is MIN or MAX.
  core.String? value;

  InterpolationPoint();

  InterpolationPoint.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color =
          Color.fromJson(_json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('colorStyle')) {
      colorStyle = ColorStyle.fromJson(
          _json['colorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
        if (colorStyle != null) 'colorStyle': colorStyle!.toJson(),
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
      };
}

/// Represents a time interval, encoded as a Timestamp start (inclusive) and a
/// Timestamp end (exclusive).
///
/// The start must be less than or equal to the end. When the start equals the
/// end, the interval is empty (matches no time). When both start and end are
/// unspecified, the interval matches any time.
class Interval {
  /// Exclusive end of the interval.
  ///
  /// If specified, a Timestamp matching this interval will have to be before
  /// the end.
  ///
  /// Optional.
  core.String? endTime;

  /// Inclusive start of the interval.
  ///
  /// If specified, a Timestamp matching this interval will have to be the same
  /// or after the start.
  ///
  /// Optional.
  core.String? startTime;

  Interval();

  Interval.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (startTime != null) 'startTime': startTime!,
      };
}

/// Settings to control how circular dependencies are resolved with iterative
/// calculation.
class IterativeCalculationSettings {
  /// When iterative calculation is enabled and successive results differ by
  /// less than this threshold value, the calculation rounds stop.
  core.double? convergenceThreshold;

  /// When iterative calculation is enabled, the maximum number of calculation
  /// rounds to perform.
  core.int? maxIterations;

  IterativeCalculationSettings();

  IterativeCalculationSettings.fromJson(core.Map _json) {
    if (_json.containsKey('convergenceThreshold')) {
      convergenceThreshold =
          (_json['convergenceThreshold'] as core.num).toDouble();
    }
    if (_json.containsKey('maxIterations')) {
      maxIterations = _json['maxIterations'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (convergenceThreshold != null)
          'convergenceThreshold': convergenceThreshold!,
        if (maxIterations != null) 'maxIterations': maxIterations!,
      };
}

/// Formatting options for key value.
class KeyValueFormat {
  /// Specifies the horizontal text positioning of key value.
  ///
  /// This field is optional. If not specified, default positioning is used.
  TextPosition? position;

  /// Text formatting options for key value.
  ///
  /// The link field is not supported.
  TextFormat? textFormat;

  KeyValueFormat();

  KeyValueFormat.fromJson(core.Map _json) {
    if (_json.containsKey('position')) {
      position = TextPosition.fromJson(
          _json['position'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textFormat')) {
      textFormat = TextFormat.fromJson(
          _json['textFormat'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (position != null) 'position': position!.toJson(),
        if (textFormat != null) 'textFormat': textFormat!.toJson(),
      };
}

/// Properties that describe the style of a line.
class LineStyle {
  /// The dash type of the line.
  /// Possible string values are:
  /// - "LINE_DASH_TYPE_UNSPECIFIED" : Default value, do not use.
  /// - "INVISIBLE" : No dash type, which is equivalent to a non-visible line.
  /// - "CUSTOM" : A custom dash for a line. Modifying the exact custom dash
  /// style is currently unsupported.
  /// - "SOLID" : A solid line.
  /// - "DOTTED" : A dotted line.
  /// - "MEDIUM_DASHED" : A dashed line where the dashes have "medium" length.
  /// - "MEDIUM_DASHED_DOTTED" : A line that alternates between a "medium" dash
  /// and a dot.
  /// - "LONG_DASHED" : A dashed line where the dashes have "long" length.
  /// - "LONG_DASHED_DOTTED" : A line that alternates between a "long" dash and
  /// a dot.
  core.String? type;

  /// The thickness of the line, in px.
  core.int? width;

  LineStyle();

  LineStyle.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
        if (width != null) 'width': width!,
      };
}

/// An external or local reference.
class Link {
  /// The link identifier.
  core.String? uri;

  Link();

  Link.fromJson(core.Map _json) {
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (uri != null) 'uri': uri!,
      };
}

/// Allows you to manually organize the values in a source data column into
/// buckets with names of your choosing.
///
/// For example, a pivot table that aggregates population by state:
/// +-------+-------------------+ | State | SUM of Population |
/// +-------+-------------------+ | AK | 0.7 | | AL | 4.8 | | AR | 2.9 | ...
/// +-------+-------------------+ could be turned into a pivot table that
/// aggregates population by time zone by providing a list of groups (for
/// example, groupName = 'Central', items = \['AL', 'AR', 'IA', ...\]) to a
/// manual group rule. Note that a similar effect could be achieved by adding a
/// time zone column to the source data and adjusting the pivot table.
/// +-----------+-------------------+ | Time Zone | SUM of Population |
/// +-----------+-------------------+ | Central | 106.3 | | Eastern | 151.9 | |
/// Mountain | 17.4 | ... +-----------+-------------------+
class ManualRule {
  /// The list of group names and the corresponding items from the source data
  /// that map to each group name.
  core.List<ManualRuleGroup>? groups;

  ManualRule();

  ManualRule.fromJson(core.Map _json) {
    if (_json.containsKey('groups')) {
      groups = (_json['groups'] as core.List)
          .map<ManualRuleGroup>((value) => ManualRuleGroup.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (groups != null)
          'groups': groups!.map((value) => value.toJson()).toList(),
      };
}

/// A group name and a list of items from the source data that should be placed
/// in the group with this name.
class ManualRuleGroup {
  /// The group name, which must be a string.
  ///
  /// Each group in a given ManualRule must have a unique group name.
  ExtendedValue? groupName;

  /// The items in the source data that should be placed into this group.
  ///
  /// Each item may be a string, number, or boolean. Items may appear in at most
  /// one group within a given ManualRule. Items that do not appear in any group
  /// will appear on their own.
  core.List<ExtendedValue>? items;

  ManualRuleGroup();

  ManualRuleGroup.fromJson(core.Map _json) {
    if (_json.containsKey('groupName')) {
      groupName = ExtendedValue.fromJson(
          _json['groupName'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<ExtendedValue>((value) => ExtendedValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (groupName != null) 'groupName': groupName!.toJson(),
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
      };
}

/// A developer metadata entry and the data filters specified in the original
/// request that matched it.
class MatchedDeveloperMetadata {
  /// All filters matching the returned developer metadata.
  core.List<DataFilter>? dataFilters;

  /// The developer metadata matching the specified filters.
  DeveloperMetadata? developerMetadata;

  MatchedDeveloperMetadata();

  MatchedDeveloperMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('dataFilters')) {
      dataFilters = (_json['dataFilters'] as core.List)
          .map<DataFilter>((value) =>
              DataFilter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('developerMetadata')) {
      developerMetadata = DeveloperMetadata.fromJson(
          _json['developerMetadata'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataFilters != null)
          'dataFilters': dataFilters!.map((value) => value.toJson()).toList(),
        if (developerMetadata != null)
          'developerMetadata': developerMetadata!.toJson(),
      };
}

/// A value range that was matched by one or more data filers.
class MatchedValueRange {
  /// The DataFilters from the request that matched the range of values.
  core.List<DataFilter>? dataFilters;

  /// The values matched by the DataFilter.
  ValueRange? valueRange;

  MatchedValueRange();

  MatchedValueRange.fromJson(core.Map _json) {
    if (_json.containsKey('dataFilters')) {
      dataFilters = (_json['dataFilters'] as core.List)
          .map<DataFilter>((value) =>
              DataFilter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('valueRange')) {
      valueRange = ValueRange.fromJson(
          _json['valueRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataFilters != null)
          'dataFilters': dataFilters!.map((value) => value.toJson()).toList(),
        if (valueRange != null) 'valueRange': valueRange!.toJson(),
      };
}

/// Merges all cells in the range.
class MergeCellsRequest {
  /// How the cells should be merged.
  /// Possible string values are:
  /// - "MERGE_ALL" : Create a single merge from the range
  /// - "MERGE_COLUMNS" : Create a merge for each column in the range
  /// - "MERGE_ROWS" : Create a merge for each row in the range
  core.String? mergeType;

  /// The range of cells to merge.
  GridRange? range;

  MergeCellsRequest();

  MergeCellsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('mergeType')) {
      mergeType = _json['mergeType'] as core.String;
    }
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mergeType != null) 'mergeType': mergeType!,
        if (range != null) 'range': range!.toJson(),
      };
}

/// Moves one or more rows or columns.
class MoveDimensionRequest {
  /// The zero-based start index of where to move the source data to, based on
  /// the coordinates *before* the source data is removed from the grid.
  ///
  /// Existing data will be shifted down or right (depending on the dimension)
  /// to make room for the moved dimensions. The source dimensions are removed
  /// from the grid, so the the data may end up in a different index than
  /// specified. For example, given `A1..A5` of `0, 1, 2, 3, 4` and wanting to
  /// move `"1"` and `"2"` to between `"3"` and `"4"`, the source would be `ROWS
  /// [1..3)`,and the destination index would be `"4"` (the zero-based index of
  /// row 5). The end result would be `A1..A5` of `0, 3, 1, 2, 4`.
  core.int? destinationIndex;

  /// The source dimensions to move.
  DimensionRange? source;

  MoveDimensionRequest();

  MoveDimensionRequest.fromJson(core.Map _json) {
    if (_json.containsKey('destinationIndex')) {
      destinationIndex = _json['destinationIndex'] as core.int;
    }
    if (_json.containsKey('source')) {
      source = DimensionRange.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationIndex != null) 'destinationIndex': destinationIndex!,
        if (source != null) 'source': source!.toJson(),
      };
}

/// A named range.
class NamedRange {
  /// The name of the named range.
  core.String? name;

  /// The ID of the named range.
  core.String? namedRangeId;

  /// The range this represents.
  GridRange? range;

  NamedRange();

  NamedRange.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('namedRangeId')) {
      namedRangeId = _json['namedRangeId'] as core.String;
    }
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (namedRangeId != null) 'namedRangeId': namedRangeId!,
        if (range != null) 'range': range!.toJson(),
      };
}

/// The number format of a cell.
class NumberFormat {
  /// Pattern string used for formatting.
  ///
  /// If not set, a default pattern based on the user's locale will be used if
  /// necessary for the given type. See the \[Date and Number Formats
  /// guide\](/sheets/api/guides/formats) for more information about the
  /// supported patterns.
  core.String? pattern;

  /// The type of the number format.
  ///
  /// When writing, this field must be set.
  /// Possible string values are:
  /// - "NUMBER_FORMAT_TYPE_UNSPECIFIED" : The number format is not specified
  /// and is based on the contents of the cell. Do not explicitly use this.
  /// - "TEXT" : Text formatting, e.g `1000.12`
  /// - "NUMBER" : Number formatting, e.g, `1,000.12`
  /// - "PERCENT" : Percent formatting, e.g `10.12%`
  /// - "CURRENCY" : Currency formatting, e.g `$1,000.12`
  /// - "DATE" : Date formatting, e.g `9/26/2008`
  /// - "TIME" : Time formatting, e.g `3:59:00 PM`
  /// - "DATE_TIME" : Date+Time formatting, e.g `9/26/08 15:59:00`
  /// - "SCIENTIFIC" : Scientific number formatting, e.g `1.01E+03`
  core.String? type;

  NumberFormat();

  NumberFormat.fromJson(core.Map _json) {
    if (_json.containsKey('pattern')) {
      pattern = _json['pattern'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pattern != null) 'pattern': pattern!,
        if (type != null) 'type': type!,
      };
}

/// An org chart.
///
/// Org charts require a unique set of labels in labels and may optionally
/// include parent_labels and tooltips. parent_labels contain, for each node,
/// the label identifying the parent node. tooltips contain, for each node, an
/// optional tooltip. For example, to describe an OrgChart with Alice as the
/// CEO, Bob as the President (reporting to Alice) and Cathy as VP of Sales
/// (also reporting to Alice), have labels contain "Alice", "Bob", "Cathy",
/// parent_labels contain "", "Alice", "Alice" and tooltips contain "CEO",
/// "President", "VP Sales".
class OrgChartSpec {
  /// The data containing the labels for all the nodes in the chart.
  ///
  /// Labels must be unique.
  ChartData? labels;

  /// The color of the org chart nodes.
  Color? nodeColor;

  /// The color of the org chart nodes.
  ///
  /// If node_color is also set, this field takes precedence.
  ColorStyle? nodeColorStyle;

  /// The size of the org chart nodes.
  /// Possible string values are:
  /// - "ORG_CHART_LABEL_SIZE_UNSPECIFIED" : Default value, do not use.
  /// - "SMALL" : The small org chart node size.
  /// - "MEDIUM" : The medium org chart node size.
  /// - "LARGE" : The large org chart node size.
  core.String? nodeSize;

  /// The data containing the label of the parent for the corresponding node.
  ///
  /// A blank value indicates that the node has no parent and is a top-level
  /// node. This field is optional.
  ChartData? parentLabels;

  /// The color of the selected org chart nodes.
  Color? selectedNodeColor;

  /// The color of the selected org chart nodes.
  ///
  /// If selected_node_color is also set, this field takes precedence.
  ColorStyle? selectedNodeColorStyle;

  /// The data containing the tooltip for the corresponding node.
  ///
  /// A blank value results in no tooltip being displayed for the node. This
  /// field is optional.
  ChartData? tooltips;

  OrgChartSpec();

  OrgChartSpec.fromJson(core.Map _json) {
    if (_json.containsKey('labels')) {
      labels = ChartData.fromJson(
          _json['labels'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nodeColor')) {
      nodeColor = Color.fromJson(
          _json['nodeColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nodeColorStyle')) {
      nodeColorStyle = ColorStyle.fromJson(
          _json['nodeColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nodeSize')) {
      nodeSize = _json['nodeSize'] as core.String;
    }
    if (_json.containsKey('parentLabels')) {
      parentLabels = ChartData.fromJson(
          _json['parentLabels'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('selectedNodeColor')) {
      selectedNodeColor = Color.fromJson(
          _json['selectedNodeColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('selectedNodeColorStyle')) {
      selectedNodeColorStyle = ColorStyle.fromJson(
          _json['selectedNodeColorStyle']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tooltips')) {
      tooltips = ChartData.fromJson(
          _json['tooltips'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (labels != null) 'labels': labels!.toJson(),
        if (nodeColor != null) 'nodeColor': nodeColor!.toJson(),
        if (nodeColorStyle != null) 'nodeColorStyle': nodeColorStyle!.toJson(),
        if (nodeSize != null) 'nodeSize': nodeSize!,
        if (parentLabels != null) 'parentLabels': parentLabels!.toJson(),
        if (selectedNodeColor != null)
          'selectedNodeColor': selectedNodeColor!.toJson(),
        if (selectedNodeColorStyle != null)
          'selectedNodeColorStyle': selectedNodeColorStyle!.toJson(),
        if (tooltips != null) 'tooltips': tooltips!.toJson(),
      };
}

/// The location an object is overlaid on top of a grid.
class OverlayPosition {
  /// The cell the object is anchored to.
  GridCoordinate? anchorCell;

  /// The height of the object, in pixels.
  ///
  /// Defaults to 371.
  core.int? heightPixels;

  /// The horizontal offset, in pixels, that the object is offset from the
  /// anchor cell.
  core.int? offsetXPixels;

  /// The vertical offset, in pixels, that the object is offset from the anchor
  /// cell.
  core.int? offsetYPixels;

  /// The width of the object, in pixels.
  ///
  /// Defaults to 600.
  core.int? widthPixels;

  OverlayPosition();

  OverlayPosition.fromJson(core.Map _json) {
    if (_json.containsKey('anchorCell')) {
      anchorCell = GridCoordinate.fromJson(
          _json['anchorCell'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('heightPixels')) {
      heightPixels = _json['heightPixels'] as core.int;
    }
    if (_json.containsKey('offsetXPixels')) {
      offsetXPixels = _json['offsetXPixels'] as core.int;
    }
    if (_json.containsKey('offsetYPixels')) {
      offsetYPixels = _json['offsetYPixels'] as core.int;
    }
    if (_json.containsKey('widthPixels')) {
      widthPixels = _json['widthPixels'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (anchorCell != null) 'anchorCell': anchorCell!.toJson(),
        if (heightPixels != null) 'heightPixels': heightPixels!,
        if (offsetXPixels != null) 'offsetXPixels': offsetXPixels!,
        if (offsetYPixels != null) 'offsetYPixels': offsetYPixels!,
        if (widthPixels != null) 'widthPixels': widthPixels!,
      };
}

/// The amount of padding around the cell, in pixels.
///
/// When updating padding, every field must be specified.
class Padding {
  /// The bottom padding of the cell.
  core.int? bottom;

  /// The left padding of the cell.
  core.int? left;

  /// The right padding of the cell.
  core.int? right;

  /// The top padding of the cell.
  core.int? top;

  Padding();

  Padding.fromJson(core.Map _json) {
    if (_json.containsKey('bottom')) {
      bottom = _json['bottom'] as core.int;
    }
    if (_json.containsKey('left')) {
      left = _json['left'] as core.int;
    }
    if (_json.containsKey('right')) {
      right = _json['right'] as core.int;
    }
    if (_json.containsKey('top')) {
      top = _json['top'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bottom != null) 'bottom': bottom!,
        if (left != null) 'left': left!,
        if (right != null) 'right': right!,
        if (top != null) 'top': top!,
      };
}

/// Inserts data into the spreadsheet starting at the specified coordinate.
class PasteDataRequest {
  /// The coordinate at which the data should start being inserted.
  GridCoordinate? coordinate;

  /// The data to insert.
  core.String? data;

  /// The delimiter in the data.
  core.String? delimiter;

  /// True if the data is HTML.
  core.bool? html;

  /// How the data should be pasted.
  /// Possible string values are:
  /// - "PASTE_NORMAL" : Paste values, formulas, formats, and merges.
  /// - "PASTE_VALUES" : Paste the values ONLY without formats, formulas, or
  /// merges.
  /// - "PASTE_FORMAT" : Paste the format and data validation only.
  /// - "PASTE_NO_BORDERS" : Like `PASTE_NORMAL` but without borders.
  /// - "PASTE_FORMULA" : Paste the formulas only.
  /// - "PASTE_DATA_VALIDATION" : Paste the data validation only.
  /// - "PASTE_CONDITIONAL_FORMATTING" : Paste the conditional formatting rules
  /// only.
  core.String? type;

  PasteDataRequest();

  PasteDataRequest.fromJson(core.Map _json) {
    if (_json.containsKey('coordinate')) {
      coordinate = GridCoordinate.fromJson(
          _json['coordinate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('data')) {
      data = _json['data'] as core.String;
    }
    if (_json.containsKey('delimiter')) {
      delimiter = _json['delimiter'] as core.String;
    }
    if (_json.containsKey('html')) {
      html = _json['html'] as core.bool;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (coordinate != null) 'coordinate': coordinate!.toJson(),
        if (data != null) 'data': data!,
        if (delimiter != null) 'delimiter': delimiter!,
        if (html != null) 'html': html!,
        if (type != null) 'type': type!,
      };
}

/// A pie chart.
class PieChartSpec {
  /// The data that covers the domain of the pie chart.
  ChartData? domain;

  /// Where the legend of the pie chart should be drawn.
  /// Possible string values are:
  /// - "PIE_CHART_LEGEND_POSITION_UNSPECIFIED" : Default value, do not use.
  /// - "BOTTOM_LEGEND" : The legend is rendered on the bottom of the chart.
  /// - "LEFT_LEGEND" : The legend is rendered on the left of the chart.
  /// - "RIGHT_LEGEND" : The legend is rendered on the right of the chart.
  /// - "TOP_LEGEND" : The legend is rendered on the top of the chart.
  /// - "NO_LEGEND" : No legend is rendered.
  /// - "LABELED_LEGEND" : Each pie slice has a label attached to it.
  core.String? legendPosition;

  /// The size of the hole in the pie chart.
  core.double? pieHole;

  /// The data that covers the one and only series of the pie chart.
  ChartData? series;

  /// True if the pie is three dimensional.
  core.bool? threeDimensional;

  PieChartSpec();

  PieChartSpec.fromJson(core.Map _json) {
    if (_json.containsKey('domain')) {
      domain = ChartData.fromJson(
          _json['domain'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('legendPosition')) {
      legendPosition = _json['legendPosition'] as core.String;
    }
    if (_json.containsKey('pieHole')) {
      pieHole = (_json['pieHole'] as core.num).toDouble();
    }
    if (_json.containsKey('series')) {
      series = ChartData.fromJson(
          _json['series'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('threeDimensional')) {
      threeDimensional = _json['threeDimensional'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (domain != null) 'domain': domain!.toJson(),
        if (legendPosition != null) 'legendPosition': legendPosition!,
        if (pieHole != null) 'pieHole': pieHole!,
        if (series != null) 'series': series!.toJson(),
        if (threeDimensional != null) 'threeDimensional': threeDimensional!,
      };
}

/// Criteria for showing/hiding rows in a pivot table.
class PivotFilterCriteria {
  /// A condition that must be true for values to be shown.
  ///
  /// (`visibleValues` does not override this -- even if a value is listed
  /// there, it is still hidden if it does not meet the condition.) Condition
  /// values that refer to ranges in A1-notation are evaluated relative to the
  /// pivot table sheet. References are treated absolutely, so are not filled
  /// down the pivot table. For example, a condition value of `=A1` on "Pivot
  /// Table 1" is treated as `'Pivot Table 1'!$A$1`. The source data of the
  /// pivot table can be referenced by column header name. For example, if the
  /// source data has columns named "Revenue" and "Cost" and a condition is
  /// applied to the "Revenue" column with type `NUMBER_GREATER` and value
  /// `=Cost`, then only columns where "Revenue" > "Cost" are included.
  BooleanCondition? condition;

  /// Whether values are visible by default.
  ///
  /// If true, the visible_values are ignored, all values that meet condition
  /// (if specified) are shown. If false, values that are both in visible_values
  /// and meet condition are shown.
  core.bool? visibleByDefault;

  /// Values that should be included.
  ///
  /// Values not listed here are excluded.
  core.List<core.String>? visibleValues;

  PivotFilterCriteria();

  PivotFilterCriteria.fromJson(core.Map _json) {
    if (_json.containsKey('condition')) {
      condition = BooleanCondition.fromJson(
          _json['condition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('visibleByDefault')) {
      visibleByDefault = _json['visibleByDefault'] as core.bool;
    }
    if (_json.containsKey('visibleValues')) {
      visibleValues = (_json['visibleValues'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (condition != null) 'condition': condition!.toJson(),
        if (visibleByDefault != null) 'visibleByDefault': visibleByDefault!,
        if (visibleValues != null) 'visibleValues': visibleValues!,
      };
}

/// The pivot table filter criteria associated with a specific source column
/// offset.
class PivotFilterSpec {
  /// The column offset of the source range.
  core.int? columnOffsetIndex;

  /// The reference to the data source column.
  DataSourceColumnReference? dataSourceColumnReference;

  /// The criteria for the column.
  PivotFilterCriteria? filterCriteria;

  PivotFilterSpec();

  PivotFilterSpec.fromJson(core.Map _json) {
    if (_json.containsKey('columnOffsetIndex')) {
      columnOffsetIndex = _json['columnOffsetIndex'] as core.int;
    }
    if (_json.containsKey('dataSourceColumnReference')) {
      dataSourceColumnReference = DataSourceColumnReference.fromJson(
          _json['dataSourceColumnReference']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('filterCriteria')) {
      filterCriteria = PivotFilterCriteria.fromJson(
          _json['filterCriteria'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnOffsetIndex != null) 'columnOffsetIndex': columnOffsetIndex!,
        if (dataSourceColumnReference != null)
          'dataSourceColumnReference': dataSourceColumnReference!.toJson(),
        if (filterCriteria != null) 'filterCriteria': filterCriteria!.toJson(),
      };
}

/// A single grouping (either row or column) in a pivot table.
class PivotGroup {
  /// The reference to the data source column this grouping is based on.
  DataSourceColumnReference? dataSourceColumnReference;

  /// The count limit on rows or columns to apply to this pivot group.
  PivotGroupLimit? groupLimit;

  /// The group rule to apply to this row/column group.
  PivotGroupRule? groupRule;

  /// The labels to use for the row/column groups which can be customized.
  ///
  /// For example, in the following pivot table, the row label is `Region`
  /// (which could be renamed to `State`) and the column label is `Product`
  /// (which could be renamed `Item`). Pivot tables created before December 2017
  /// do not have header labels. If you'd like to add header labels to an
  /// existing pivot table, please delete the existing pivot table and then
  /// create a new pivot table with same parameters.
  /// +--------------+---------+-------+ | SUM of Units | Product | | | Region |
  /// Pen | Paper | +--------------+---------+-------+ | New York | 345 | 98 | |
  /// Oregon | 234 | 123 | | Tennessee | 531 | 415 |
  /// +--------------+---------+-------+ | Grand Total | 1110 | 636 |
  /// +--------------+---------+-------+
  core.String? label;

  /// True if the headings in this pivot group should be repeated.
  ///
  /// This is only valid for row groupings and is ignored by columns. By
  /// default, we minimize repetition of headings by not showing higher level
  /// headings where they are the same. For example, even though the third row
  /// below corresponds to "Q1 Mar", "Q1" is not shown because it is redundant
  /// with previous rows. Setting repeat_headings to true would cause "Q1" to be
  /// repeated for "Feb" and "Mar". +--------------+ | Q1 | Jan | | | Feb | | |
  /// Mar | +--------+-----+ | Q1 Total | +--------------+
  core.bool? repeatHeadings;

  /// True if the pivot table should include the totals for this grouping.
  core.bool? showTotals;

  /// The order the values in this group should be sorted.
  /// Possible string values are:
  /// - "SORT_ORDER_UNSPECIFIED" : Default value, do not use this.
  /// - "ASCENDING" : Sort ascending.
  /// - "DESCENDING" : Sort descending.
  core.String? sortOrder;

  /// The column offset of the source range that this grouping is based on.
  ///
  /// For example, if the source was `C10:E15`, a `sourceColumnOffset` of `0`
  /// means this group refers to column `C`, whereas the offset `1` would refer
  /// to column `D`.
  core.int? sourceColumnOffset;

  /// The bucket of the opposite pivot group to sort by.
  ///
  /// If not specified, sorting is alphabetical by this group's values.
  PivotGroupSortValueBucket? valueBucket;

  /// Metadata about values in the grouping.
  core.List<PivotGroupValueMetadata>? valueMetadata;

  PivotGroup();

  PivotGroup.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceColumnReference')) {
      dataSourceColumnReference = DataSourceColumnReference.fromJson(
          _json['dataSourceColumnReference']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('groupLimit')) {
      groupLimit = PivotGroupLimit.fromJson(
          _json['groupLimit'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('groupRule')) {
      groupRule = PivotGroupRule.fromJson(
          _json['groupRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('label')) {
      label = _json['label'] as core.String;
    }
    if (_json.containsKey('repeatHeadings')) {
      repeatHeadings = _json['repeatHeadings'] as core.bool;
    }
    if (_json.containsKey('showTotals')) {
      showTotals = _json['showTotals'] as core.bool;
    }
    if (_json.containsKey('sortOrder')) {
      sortOrder = _json['sortOrder'] as core.String;
    }
    if (_json.containsKey('sourceColumnOffset')) {
      sourceColumnOffset = _json['sourceColumnOffset'] as core.int;
    }
    if (_json.containsKey('valueBucket')) {
      valueBucket = PivotGroupSortValueBucket.fromJson(
          _json['valueBucket'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('valueMetadata')) {
      valueMetadata = (_json['valueMetadata'] as core.List)
          .map<PivotGroupValueMetadata>((value) =>
              PivotGroupValueMetadata.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceColumnReference != null)
          'dataSourceColumnReference': dataSourceColumnReference!.toJson(),
        if (groupLimit != null) 'groupLimit': groupLimit!.toJson(),
        if (groupRule != null) 'groupRule': groupRule!.toJson(),
        if (label != null) 'label': label!,
        if (repeatHeadings != null) 'repeatHeadings': repeatHeadings!,
        if (showTotals != null) 'showTotals': showTotals!,
        if (sortOrder != null) 'sortOrder': sortOrder!,
        if (sourceColumnOffset != null)
          'sourceColumnOffset': sourceColumnOffset!,
        if (valueBucket != null) 'valueBucket': valueBucket!.toJson(),
        if (valueMetadata != null)
          'valueMetadata':
              valueMetadata!.map((value) => value.toJson()).toList(),
      };
}

/// The count limit on rows or columns in the pivot group.
class PivotGroupLimit {
  /// The order in which the group limit is applied to the pivot table.
  ///
  /// Pivot group limits are applied from lower to higher order number. Order
  /// numbers are normalized to consecutive integers from 0. For write request,
  /// to fully customize the applying orders, all pivot group limits should have
  /// this field set with an unique number. Otherwise, the order is determined
  /// by the index in the PivotTable.rows list and then the PivotTable.columns
  /// list.
  core.int? applyOrder;

  /// The count limit.
  core.int? countLimit;

  PivotGroupLimit();

  PivotGroupLimit.fromJson(core.Map _json) {
    if (_json.containsKey('applyOrder')) {
      applyOrder = _json['applyOrder'] as core.int;
    }
    if (_json.containsKey('countLimit')) {
      countLimit = _json['countLimit'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applyOrder != null) 'applyOrder': applyOrder!,
        if (countLimit != null) 'countLimit': countLimit!,
      };
}

/// An optional setting on a PivotGroup that defines buckets for the values in
/// the source data column rather than breaking out each individual value.
///
/// Only one PivotGroup with a group rule may be added for each column in the
/// source data, though on any given column you may add both a PivotGroup that
/// has a rule and a PivotGroup that does not.
class PivotGroupRule {
  /// A DateTimeRule.
  DateTimeRule? dateTimeRule;

  /// A HistogramRule.
  HistogramRule? histogramRule;

  /// A ManualRule.
  ManualRule? manualRule;

  PivotGroupRule();

  PivotGroupRule.fromJson(core.Map _json) {
    if (_json.containsKey('dateTimeRule')) {
      dateTimeRule = DateTimeRule.fromJson(
          _json['dateTimeRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('histogramRule')) {
      histogramRule = HistogramRule.fromJson(
          _json['histogramRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('manualRule')) {
      manualRule = ManualRule.fromJson(
          _json['manualRule'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dateTimeRule != null) 'dateTimeRule': dateTimeRule!.toJson(),
        if (histogramRule != null) 'histogramRule': histogramRule!.toJson(),
        if (manualRule != null) 'manualRule': manualRule!.toJson(),
      };
}

/// Information about which values in a pivot group should be used for sorting.
class PivotGroupSortValueBucket {
  /// Determines the bucket from which values are chosen to sort.
  ///
  /// For example, in a pivot table with one row group & two column groups, the
  /// row group can list up to two values. The first value corresponds to a
  /// value within the first column group, and the second value corresponds to a
  /// value in the second column group. If no values are listed, this would
  /// indicate that the row should be sorted according to the "Grand Total" over
  /// the column groups. If a single value is listed, this would correspond to
  /// using the "Total" of that bucket.
  core.List<ExtendedValue>? buckets;

  /// The offset in the PivotTable.values list which the values in this grouping
  /// should be sorted by.
  core.int? valuesIndex;

  PivotGroupSortValueBucket();

  PivotGroupSortValueBucket.fromJson(core.Map _json) {
    if (_json.containsKey('buckets')) {
      buckets = (_json['buckets'] as core.List)
          .map<ExtendedValue>((value) => ExtendedValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('valuesIndex')) {
      valuesIndex = _json['valuesIndex'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buckets != null)
          'buckets': buckets!.map((value) => value.toJson()).toList(),
        if (valuesIndex != null) 'valuesIndex': valuesIndex!,
      };
}

/// Metadata about a value in a pivot grouping.
class PivotGroupValueMetadata {
  /// True if the data corresponding to the value is collapsed.
  core.bool? collapsed;

  /// The calculated value the metadata corresponds to.
  ///
  /// (Note that formulaValue is not valid, because the values will be
  /// calculated.)
  ExtendedValue? value;

  PivotGroupValueMetadata();

  PivotGroupValueMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('collapsed')) {
      collapsed = _json['collapsed'] as core.bool;
    }
    if (_json.containsKey('value')) {
      value = ExtendedValue.fromJson(
          _json['value'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (collapsed != null) 'collapsed': collapsed!,
        if (value != null) 'value': value!.toJson(),
      };
}

/// A pivot table.
class PivotTable {
  /// Each column grouping in the pivot table.
  core.List<PivotGroup>? columns;

  /// An optional mapping of filters per source column offset.
  ///
  /// The filters are applied before aggregating data into the pivot table. The
  /// map's key is the column offset of the source range that you want to
  /// filter, and the value is the criteria for that column. For example, if the
  /// source was `C10:E15`, a key of `0` will have the filter for column `C`,
  /// whereas the key `1` is for column `D`. This field is deprecated in favor
  /// of filter_specs.
  core.Map<core.String, PivotFilterCriteria>? criteria;

  /// The data execution status for data source pivot tables.
  ///
  /// Output only.
  DataExecutionStatus? dataExecutionStatus;

  /// The ID of the data source the pivot table is reading data from.
  core.String? dataSourceId;

  /// The filters applied to the source columns before aggregating data for the
  /// pivot table.
  ///
  /// Both criteria and filter_specs are populated in responses. If both fields
  /// are specified in an update request, this field takes precedence.
  core.List<PivotFilterSpec>? filterSpecs;

  /// Each row grouping in the pivot table.
  core.List<PivotGroup>? rows;

  /// The range the pivot table is reading data from.
  GridRange? source;

  /// Whether values should be listed horizontally (as columns) or vertically
  /// (as rows).
  /// Possible string values are:
  /// - "HORIZONTAL" : Values are laid out horizontally (as columns).
  /// - "VERTICAL" : Values are laid out vertically (as rows).
  core.String? valueLayout;

  /// A list of values to include in the pivot table.
  core.List<PivotValue>? values;

  PivotTable();

  PivotTable.fromJson(core.Map _json) {
    if (_json.containsKey('columns')) {
      columns = (_json['columns'] as core.List)
          .map<PivotGroup>((value) =>
              PivotGroup.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('criteria')) {
      criteria = (_json['criteria'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          PivotFilterCriteria.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('dataExecutionStatus')) {
      dataExecutionStatus = DataExecutionStatus.fromJson(
          _json['dataExecutionStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
    if (_json.containsKey('filterSpecs')) {
      filterSpecs = (_json['filterSpecs'] as core.List)
          .map<PivotFilterSpec>((value) => PivotFilterSpec.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<PivotGroup>((value) =>
              PivotGroup.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('source')) {
      source = GridRange.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('valueLayout')) {
      valueLayout = _json['valueLayout'] as core.String;
    }
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<PivotValue>((value) =>
              PivotValue.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columns != null)
          'columns': columns!.map((value) => value.toJson()).toList(),
        if (criteria != null)
          'criteria':
              criteria!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (dataExecutionStatus != null)
          'dataExecutionStatus': dataExecutionStatus!.toJson(),
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
        if (filterSpecs != null)
          'filterSpecs': filterSpecs!.map((value) => value.toJson()).toList(),
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
        if (source != null) 'source': source!.toJson(),
        if (valueLayout != null) 'valueLayout': valueLayout!,
        if (values != null)
          'values': values!.map((value) => value.toJson()).toList(),
      };
}

/// The definition of how a value in a pivot table should be calculated.
class PivotValue {
  /// If specified, indicates that pivot values should be displayed as the
  /// result of a calculation with another pivot value.
  ///
  /// For example, if calculated_display_type is specified as
  /// PERCENT_OF_GRAND_TOTAL, all the pivot values are displayed as the
  /// percentage of the grand total. In the Sheets editor, this is referred to
  /// as "Show As" in the value section of a pivot table.
  /// Possible string values are:
  /// - "PIVOT_VALUE_CALCULATED_DISPLAY_TYPE_UNSPECIFIED" : Default value, do
  /// not use.
  /// - "PERCENT_OF_ROW_TOTAL" : Shows the pivot values as percentage of the row
  /// total values.
  /// - "PERCENT_OF_COLUMN_TOTAL" : Shows the pivot values as percentage of the
  /// column total values.
  /// - "PERCENT_OF_GRAND_TOTAL" : Shows the pivot values as percentage of the
  /// grand total values.
  core.String? calculatedDisplayType;

  /// The reference to the data source column that this value reads from.
  DataSourceColumnReference? dataSourceColumnReference;

  /// A custom formula to calculate the value.
  ///
  /// The formula must start with an `=` character.
  core.String? formula;

  /// A name to use for the value.
  core.String? name;

  /// The column offset of the source range that this value reads from.
  ///
  /// For example, if the source was `C10:E15`, a `sourceColumnOffset` of `0`
  /// means this value refers to column `C`, whereas the offset `1` would refer
  /// to column `D`.
  core.int? sourceColumnOffset;

  /// A function to summarize the value.
  ///
  /// If formula is set, the only supported values are SUM and CUSTOM. If
  /// sourceColumnOffset is set, then `CUSTOM` is not supported.
  /// Possible string values are:
  /// - "PIVOT_STANDARD_VALUE_FUNCTION_UNSPECIFIED" : The default, do not use.
  /// - "SUM" : Corresponds to the `SUM` function.
  /// - "COUNTA" : Corresponds to the `COUNTA` function.
  /// - "COUNT" : Corresponds to the `COUNT` function.
  /// - "COUNTUNIQUE" : Corresponds to the `COUNTUNIQUE` function.
  /// - "AVERAGE" : Corresponds to the `AVERAGE` function.
  /// - "MAX" : Corresponds to the `MAX` function.
  /// - "MIN" : Corresponds to the `MIN` function.
  /// - "MEDIAN" : Corresponds to the `MEDIAN` function.
  /// - "PRODUCT" : Corresponds to the `PRODUCT` function.
  /// - "STDEV" : Corresponds to the `STDEV` function.
  /// - "STDEVP" : Corresponds to the `STDEVP` function.
  /// - "VAR" : Corresponds to the `VAR` function.
  /// - "VARP" : Corresponds to the `VARP` function.
  /// - "CUSTOM" : Indicates the formula should be used as-is. Only valid if
  /// PivotValue.formula was set.
  core.String? summarizeFunction;

  PivotValue();

  PivotValue.fromJson(core.Map _json) {
    if (_json.containsKey('calculatedDisplayType')) {
      calculatedDisplayType = _json['calculatedDisplayType'] as core.String;
    }
    if (_json.containsKey('dataSourceColumnReference')) {
      dataSourceColumnReference = DataSourceColumnReference.fromJson(
          _json['dataSourceColumnReference']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('formula')) {
      formula = _json['formula'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('sourceColumnOffset')) {
      sourceColumnOffset = _json['sourceColumnOffset'] as core.int;
    }
    if (_json.containsKey('summarizeFunction')) {
      summarizeFunction = _json['summarizeFunction'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (calculatedDisplayType != null)
          'calculatedDisplayType': calculatedDisplayType!,
        if (dataSourceColumnReference != null)
          'dataSourceColumnReference': dataSourceColumnReference!.toJson(),
        if (formula != null) 'formula': formula!,
        if (name != null) 'name': name!,
        if (sourceColumnOffset != null)
          'sourceColumnOffset': sourceColumnOffset!,
        if (summarizeFunction != null) 'summarizeFunction': summarizeFunction!,
      };
}

/// The style of a point on the chart.
class PointStyle {
  /// The point shape.
  ///
  /// If empty or unspecified, a default shape is used.
  /// Possible string values are:
  /// - "POINT_SHAPE_UNSPECIFIED" : Default value.
  /// - "CIRCLE" : A circle shape.
  /// - "DIAMOND" : A diamond shape.
  /// - "HEXAGON" : A hexagon shape.
  /// - "PENTAGON" : A pentagon shape.
  /// - "SQUARE" : A square shape.
  /// - "STAR" : A star shape.
  /// - "TRIANGLE" : A triangle shape.
  /// - "X_MARK" : An x-mark shape.
  core.String? shape;

  /// The point size.
  ///
  /// If empty, a default size is used.
  core.double? size;

  PointStyle();

  PointStyle.fromJson(core.Map _json) {
    if (_json.containsKey('shape')) {
      shape = _json['shape'] as core.String;
    }
    if (_json.containsKey('size')) {
      size = (_json['size'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (shape != null) 'shape': shape!,
        if (size != null) 'size': size!,
      };
}

/// A protected range.
class ProtectedRange {
  /// The description of this protected range.
  core.String? description;

  /// The users and groups with edit access to the protected range.
  ///
  /// This field is only visible to users with edit access to the protected
  /// range and the document. Editors are not supported with warning_only
  /// protection.
  Editors? editors;

  /// The named range this protected range is backed by, if any.
  ///
  /// When writing, only one of range or named_range_id may be set.
  core.String? namedRangeId;

  /// The ID of the protected range.
  ///
  /// This field is read-only.
  core.int? protectedRangeId;

  /// The range that is being protected.
  ///
  /// The range may be fully unbounded, in which case this is considered a
  /// protected sheet. When writing, only one of range or named_range_id may be
  /// set.
  GridRange? range;

  /// True if the user who requested this protected range can edit the protected
  /// area.
  ///
  /// This field is read-only.
  core.bool? requestingUserCanEdit;

  /// The list of unprotected ranges within a protected sheet.
  ///
  /// Unprotected ranges are only supported on protected sheets.
  core.List<GridRange>? unprotectedRanges;

  /// True if this protected range will show a warning when editing.
  ///
  /// Warning-based protection means that every user can edit data in the
  /// protected range, except editing will prompt a warning asking the user to
  /// confirm the edit. When writing: if this field is true, then editors is
  /// ignored. Additionally, if this field is changed from true to false and the
  /// `editors` field is not set (nor included in the field mask), then the
  /// editors will be set to all the editors in the document.
  core.bool? warningOnly;

  ProtectedRange();

  ProtectedRange.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('editors')) {
      editors = Editors.fromJson(
          _json['editors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('namedRangeId')) {
      namedRangeId = _json['namedRangeId'] as core.String;
    }
    if (_json.containsKey('protectedRangeId')) {
      protectedRangeId = _json['protectedRangeId'] as core.int;
    }
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('requestingUserCanEdit')) {
      requestingUserCanEdit = _json['requestingUserCanEdit'] as core.bool;
    }
    if (_json.containsKey('unprotectedRanges')) {
      unprotectedRanges = (_json['unprotectedRanges'] as core.List)
          .map<GridRange>((value) =>
              GridRange.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('warningOnly')) {
      warningOnly = _json['warningOnly'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (editors != null) 'editors': editors!.toJson(),
        if (namedRangeId != null) 'namedRangeId': namedRangeId!,
        if (protectedRangeId != null) 'protectedRangeId': protectedRangeId!,
        if (range != null) 'range': range!.toJson(),
        if (requestingUserCanEdit != null)
          'requestingUserCanEdit': requestingUserCanEdit!,
        if (unprotectedRanges != null)
          'unprotectedRanges':
              unprotectedRanges!.map((value) => value.toJson()).toList(),
        if (warningOnly != null) 'warningOnly': warningOnly!,
      };
}

/// Randomizes the order of the rows in a range.
class RandomizeRangeRequest {
  /// The range to randomize.
  GridRange? range;

  RandomizeRangeRequest();

  RandomizeRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
      };
}

/// The execution status of refreshing one data source object.
class RefreshDataSourceObjectExecutionStatus {
  /// The data execution status.
  DataExecutionStatus? dataExecutionStatus;

  /// Reference to a data source object being refreshed.
  DataSourceObjectReference? reference;

  RefreshDataSourceObjectExecutionStatus();

  RefreshDataSourceObjectExecutionStatus.fromJson(core.Map _json) {
    if (_json.containsKey('dataExecutionStatus')) {
      dataExecutionStatus = DataExecutionStatus.fromJson(
          _json['dataExecutionStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reference')) {
      reference = DataSourceObjectReference.fromJson(
          _json['reference'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataExecutionStatus != null)
          'dataExecutionStatus': dataExecutionStatus!.toJson(),
        if (reference != null) 'reference': reference!.toJson(),
      };
}

/// Refreshes one or multiple data source objects in the spreadsheet by the
/// specified references.
///
/// The request requires an additional `bigquery.readonly` OAuth scope. If there
/// are multiple refresh requests referencing the same data source objects in
/// one batch, only the last refresh request is processed, and all those
/// requests will have the same response accordingly.
class RefreshDataSourceRequest {
  /// Reference to a DataSource.
  ///
  /// If specified, refreshes all associated data source objects for the data
  /// source.
  core.String? dataSourceId;

  /// Refreshes the data source objects regardless of the current state.
  ///
  /// If not set and a referenced data source object was in error state, the
  /// refresh will fail immediately.
  core.bool? force;

  /// Refreshes all existing data source objects in the spreadsheet.
  core.bool? isAll;

  /// References to data source objects to refresh.
  DataSourceObjectReferences? references;

  RefreshDataSourceRequest();

  RefreshDataSourceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
    if (_json.containsKey('force')) {
      force = _json['force'] as core.bool;
    }
    if (_json.containsKey('isAll')) {
      isAll = _json['isAll'] as core.bool;
    }
    if (_json.containsKey('references')) {
      references = DataSourceObjectReferences.fromJson(
          _json['references'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
        if (force != null) 'force': force!,
        if (isAll != null) 'isAll': isAll!,
        if (references != null) 'references': references!.toJson(),
      };
}

/// The response from refreshing one or multiple data source objects.
class RefreshDataSourceResponse {
  /// All the refresh status for the data source object references specified in
  /// the request.
  ///
  /// If is_all is specified, the field contains only those in failure status.
  core.List<RefreshDataSourceObjectExecutionStatus>? statuses;

  RefreshDataSourceResponse();

  RefreshDataSourceResponse.fromJson(core.Map _json) {
    if (_json.containsKey('statuses')) {
      statuses = (_json['statuses'] as core.List)
          .map<RefreshDataSourceObjectExecutionStatus>((value) =>
              RefreshDataSourceObjectExecutionStatus.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (statuses != null)
          'statuses': statuses!.map((value) => value.toJson()).toList(),
      };
}

/// Updates all cells in the range to the values in the given Cell object.
///
/// Only the fields listed in the fields field are updated; others are
/// unchanged. If writing a cell with a formula, the formula's ranges will
/// automatically increment for each field in the range. For example, if writing
/// a cell with formula `=A1` into range B2:C4, B2 would be `=A1`, B3 would be
/// `=A2`, B4 would be `=A3`, C2 would be `=B1`, C3 would be `=B2`, C4 would be
/// `=B3`. To keep the formula's ranges static, use the `$` indicator. For
/// example, use the formula `=$A$1` to prevent both the row and the column from
/// incrementing.
class RepeatCellRequest {
  /// The data to write.
  CellData? cell;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `cell` is implied and
  /// should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field.
  core.String? fields;

  /// The range to repeat the cell in.
  GridRange? range;

  RepeatCellRequest();

  RepeatCellRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cell')) {
      cell = CellData.fromJson(
          _json['cell'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cell != null) 'cell': cell!.toJson(),
        if (fields != null) 'fields': fields!,
        if (range != null) 'range': range!.toJson(),
      };
}

/// A single kind of update to apply to a spreadsheet.
class Request {
  /// Adds a new banded range
  AddBandingRequest? addBanding;

  /// Adds a chart.
  AddChartRequest? addChart;

  /// Adds a new conditional format rule.
  AddConditionalFormatRuleRequest? addConditionalFormatRule;

  /// Adds a data source.
  AddDataSourceRequest? addDataSource;

  /// Creates a group over the specified range.
  AddDimensionGroupRequest? addDimensionGroup;

  /// Adds a filter view.
  AddFilterViewRequest? addFilterView;

  /// Adds a named range.
  AddNamedRangeRequest? addNamedRange;

  /// Adds a protected range.
  AddProtectedRangeRequest? addProtectedRange;

  /// Adds a sheet.
  AddSheetRequest? addSheet;

  /// Adds a slicer.
  AddSlicerRequest? addSlicer;

  /// Appends cells after the last row with data in a sheet.
  AppendCellsRequest? appendCells;

  /// Appends dimensions to the end of a sheet.
  AppendDimensionRequest? appendDimension;

  /// Automatically fills in more data based on existing data.
  AutoFillRequest? autoFill;

  /// Automatically resizes one or more dimensions based on the contents of the
  /// cells in that dimension.
  AutoResizeDimensionsRequest? autoResizeDimensions;

  /// Clears the basic filter on a sheet.
  ClearBasicFilterRequest? clearBasicFilter;

  /// Copies data from one area and pastes it to another.
  CopyPasteRequest? copyPaste;

  /// Creates new developer metadata
  CreateDeveloperMetadataRequest? createDeveloperMetadata;

  /// Cuts data from one area and pastes it to another.
  CutPasteRequest? cutPaste;

  /// Removes a banded range
  DeleteBandingRequest? deleteBanding;

  /// Deletes an existing conditional format rule.
  DeleteConditionalFormatRuleRequest? deleteConditionalFormatRule;

  /// Deletes a data source.
  DeleteDataSourceRequest? deleteDataSource;

  /// Deletes developer metadata
  DeleteDeveloperMetadataRequest? deleteDeveloperMetadata;

  /// Deletes rows or columns in a sheet.
  DeleteDimensionRequest? deleteDimension;

  /// Deletes a group over the specified range.
  DeleteDimensionGroupRequest? deleteDimensionGroup;

  /// Removes rows containing duplicate values in specified columns of a cell
  /// range.
  DeleteDuplicatesRequest? deleteDuplicates;

  /// Deletes an embedded object (e.g, chart, image) in a sheet.
  DeleteEmbeddedObjectRequest? deleteEmbeddedObject;

  /// Deletes a filter view from a sheet.
  DeleteFilterViewRequest? deleteFilterView;

  /// Deletes a named range.
  DeleteNamedRangeRequest? deleteNamedRange;

  /// Deletes a protected range.
  DeleteProtectedRangeRequest? deleteProtectedRange;

  /// Deletes a range of cells from a sheet, shifting the remaining cells.
  DeleteRangeRequest? deleteRange;

  /// Deletes a sheet.
  DeleteSheetRequest? deleteSheet;

  /// Duplicates a filter view.
  DuplicateFilterViewRequest? duplicateFilterView;

  /// Duplicates a sheet.
  DuplicateSheetRequest? duplicateSheet;

  /// Finds and replaces occurrences of some text with other text.
  FindReplaceRequest? findReplace;

  /// Inserts new rows or columns in a sheet.
  InsertDimensionRequest? insertDimension;

  /// Inserts new cells in a sheet, shifting the existing cells.
  InsertRangeRequest? insertRange;

  /// Merges cells together.
  MergeCellsRequest? mergeCells;

  /// Moves rows or columns to another location in a sheet.
  MoveDimensionRequest? moveDimension;

  /// Pastes data (HTML or delimited) into a sheet.
  PasteDataRequest? pasteData;

  /// Randomizes the order of the rows in a range.
  RandomizeRangeRequest? randomizeRange;

  /// Refreshs one or multiple data sources and associated dbobjects.
  RefreshDataSourceRequest? refreshDataSource;

  /// Repeats a single cell across a range.
  RepeatCellRequest? repeatCell;

  /// Sets the basic filter on a sheet.
  SetBasicFilterRequest? setBasicFilter;

  /// Sets data validation for one or more cells.
  SetDataValidationRequest? setDataValidation;

  /// Sorts data in a range.
  SortRangeRequest? sortRange;

  /// Converts a column of text into many columns of text.
  TextToColumnsRequest? textToColumns;

  /// Trims cells of whitespace (such as spaces, tabs, or new lines).
  TrimWhitespaceRequest? trimWhitespace;

  /// Unmerges merged cells.
  UnmergeCellsRequest? unmergeCells;

  /// Updates a banded range
  UpdateBandingRequest? updateBanding;

  /// Updates the borders in a range of cells.
  UpdateBordersRequest? updateBorders;

  /// Updates many cells at once.
  UpdateCellsRequest? updateCells;

  /// Updates a chart's specifications.
  UpdateChartSpecRequest? updateChartSpec;

  /// Updates an existing conditional format rule.
  UpdateConditionalFormatRuleRequest? updateConditionalFormatRule;

  /// Updates a data source.
  UpdateDataSourceRequest? updateDataSource;

  /// Updates an existing developer metadata entry
  UpdateDeveloperMetadataRequest? updateDeveloperMetadata;

  /// Updates the state of the specified group.
  UpdateDimensionGroupRequest? updateDimensionGroup;

  /// Updates dimensions' properties.
  UpdateDimensionPropertiesRequest? updateDimensionProperties;

  /// Updates an embedded object's border.
  UpdateEmbeddedObjectBorderRequest? updateEmbeddedObjectBorder;

  /// Updates an embedded object's (e.g. chart, image) position.
  UpdateEmbeddedObjectPositionRequest? updateEmbeddedObjectPosition;

  /// Updates the properties of a filter view.
  UpdateFilterViewRequest? updateFilterView;

  /// Updates a named range.
  UpdateNamedRangeRequest? updateNamedRange;

  /// Updates a protected range.
  UpdateProtectedRangeRequest? updateProtectedRange;

  /// Updates a sheet's properties.
  UpdateSheetPropertiesRequest? updateSheetProperties;

  /// Updates a slicer's specifications.
  UpdateSlicerSpecRequest? updateSlicerSpec;

  /// Updates the spreadsheet's properties.
  UpdateSpreadsheetPropertiesRequest? updateSpreadsheetProperties;

  Request();

  Request.fromJson(core.Map _json) {
    if (_json.containsKey('addBanding')) {
      addBanding = AddBandingRequest.fromJson(
          _json['addBanding'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addChart')) {
      addChart = AddChartRequest.fromJson(
          _json['addChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addConditionalFormatRule')) {
      addConditionalFormatRule = AddConditionalFormatRuleRequest.fromJson(
          _json['addConditionalFormatRule']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addDataSource')) {
      addDataSource = AddDataSourceRequest.fromJson(
          _json['addDataSource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addDimensionGroup')) {
      addDimensionGroup = AddDimensionGroupRequest.fromJson(
          _json['addDimensionGroup'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addFilterView')) {
      addFilterView = AddFilterViewRequest.fromJson(
          _json['addFilterView'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addNamedRange')) {
      addNamedRange = AddNamedRangeRequest.fromJson(
          _json['addNamedRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addProtectedRange')) {
      addProtectedRange = AddProtectedRangeRequest.fromJson(
          _json['addProtectedRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addSheet')) {
      addSheet = AddSheetRequest.fromJson(
          _json['addSheet'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addSlicer')) {
      addSlicer = AddSlicerRequest.fromJson(
          _json['addSlicer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('appendCells')) {
      appendCells = AppendCellsRequest.fromJson(
          _json['appendCells'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('appendDimension')) {
      appendDimension = AppendDimensionRequest.fromJson(
          _json['appendDimension'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('autoFill')) {
      autoFill = AutoFillRequest.fromJson(
          _json['autoFill'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('autoResizeDimensions')) {
      autoResizeDimensions = AutoResizeDimensionsRequest.fromJson(
          _json['autoResizeDimensions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('clearBasicFilter')) {
      clearBasicFilter = ClearBasicFilterRequest.fromJson(
          _json['clearBasicFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('copyPaste')) {
      copyPaste = CopyPasteRequest.fromJson(
          _json['copyPaste'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createDeveloperMetadata')) {
      createDeveloperMetadata = CreateDeveloperMetadataRequest.fromJson(
          _json['createDeveloperMetadata']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('cutPaste')) {
      cutPaste = CutPasteRequest.fromJson(
          _json['cutPaste'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteBanding')) {
      deleteBanding = DeleteBandingRequest.fromJson(
          _json['deleteBanding'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteConditionalFormatRule')) {
      deleteConditionalFormatRule = DeleteConditionalFormatRuleRequest.fromJson(
          _json['deleteConditionalFormatRule']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteDataSource')) {
      deleteDataSource = DeleteDataSourceRequest.fromJson(
          _json['deleteDataSource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteDeveloperMetadata')) {
      deleteDeveloperMetadata = DeleteDeveloperMetadataRequest.fromJson(
          _json['deleteDeveloperMetadata']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteDimension')) {
      deleteDimension = DeleteDimensionRequest.fromJson(
          _json['deleteDimension'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteDimensionGroup')) {
      deleteDimensionGroup = DeleteDimensionGroupRequest.fromJson(
          _json['deleteDimensionGroup'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteDuplicates')) {
      deleteDuplicates = DeleteDuplicatesRequest.fromJson(
          _json['deleteDuplicates'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteEmbeddedObject')) {
      deleteEmbeddedObject = DeleteEmbeddedObjectRequest.fromJson(
          _json['deleteEmbeddedObject'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteFilterView')) {
      deleteFilterView = DeleteFilterViewRequest.fromJson(
          _json['deleteFilterView'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteNamedRange')) {
      deleteNamedRange = DeleteNamedRangeRequest.fromJson(
          _json['deleteNamedRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteProtectedRange')) {
      deleteProtectedRange = DeleteProtectedRangeRequest.fromJson(
          _json['deleteProtectedRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteRange')) {
      deleteRange = DeleteRangeRequest.fromJson(
          _json['deleteRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteSheet')) {
      deleteSheet = DeleteSheetRequest.fromJson(
          _json['deleteSheet'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('duplicateFilterView')) {
      duplicateFilterView = DuplicateFilterViewRequest.fromJson(
          _json['duplicateFilterView'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('duplicateSheet')) {
      duplicateSheet = DuplicateSheetRequest.fromJson(
          _json['duplicateSheet'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('findReplace')) {
      findReplace = FindReplaceRequest.fromJson(
          _json['findReplace'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertDimension')) {
      insertDimension = InsertDimensionRequest.fromJson(
          _json['insertDimension'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertRange')) {
      insertRange = InsertRangeRequest.fromJson(
          _json['insertRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mergeCells')) {
      mergeCells = MergeCellsRequest.fromJson(
          _json['mergeCells'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('moveDimension')) {
      moveDimension = MoveDimensionRequest.fromJson(
          _json['moveDimension'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pasteData')) {
      pasteData = PasteDataRequest.fromJson(
          _json['pasteData'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('randomizeRange')) {
      randomizeRange = RandomizeRangeRequest.fromJson(
          _json['randomizeRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('refreshDataSource')) {
      refreshDataSource = RefreshDataSourceRequest.fromJson(
          _json['refreshDataSource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('repeatCell')) {
      repeatCell = RepeatCellRequest.fromJson(
          _json['repeatCell'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('setBasicFilter')) {
      setBasicFilter = SetBasicFilterRequest.fromJson(
          _json['setBasicFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('setDataValidation')) {
      setDataValidation = SetDataValidationRequest.fromJson(
          _json['setDataValidation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sortRange')) {
      sortRange = SortRangeRequest.fromJson(
          _json['sortRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textToColumns')) {
      textToColumns = TextToColumnsRequest.fromJson(
          _json['textToColumns'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('trimWhitespace')) {
      trimWhitespace = TrimWhitespaceRequest.fromJson(
          _json['trimWhitespace'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unmergeCells')) {
      unmergeCells = UnmergeCellsRequest.fromJson(
          _json['unmergeCells'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateBanding')) {
      updateBanding = UpdateBandingRequest.fromJson(
          _json['updateBanding'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateBorders')) {
      updateBorders = UpdateBordersRequest.fromJson(
          _json['updateBorders'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateCells')) {
      updateCells = UpdateCellsRequest.fromJson(
          _json['updateCells'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateChartSpec')) {
      updateChartSpec = UpdateChartSpecRequest.fromJson(
          _json['updateChartSpec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateConditionalFormatRule')) {
      updateConditionalFormatRule = UpdateConditionalFormatRuleRequest.fromJson(
          _json['updateConditionalFormatRule']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateDataSource')) {
      updateDataSource = UpdateDataSourceRequest.fromJson(
          _json['updateDataSource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateDeveloperMetadata')) {
      updateDeveloperMetadata = UpdateDeveloperMetadataRequest.fromJson(
          _json['updateDeveloperMetadata']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateDimensionGroup')) {
      updateDimensionGroup = UpdateDimensionGroupRequest.fromJson(
          _json['updateDimensionGroup'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateDimensionProperties')) {
      updateDimensionProperties = UpdateDimensionPropertiesRequest.fromJson(
          _json['updateDimensionProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateEmbeddedObjectBorder')) {
      updateEmbeddedObjectBorder = UpdateEmbeddedObjectBorderRequest.fromJson(
          _json['updateEmbeddedObjectBorder']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateEmbeddedObjectPosition')) {
      updateEmbeddedObjectPosition =
          UpdateEmbeddedObjectPositionRequest.fromJson(
              _json['updateEmbeddedObjectPosition']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateFilterView')) {
      updateFilterView = UpdateFilterViewRequest.fromJson(
          _json['updateFilterView'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateNamedRange')) {
      updateNamedRange = UpdateNamedRangeRequest.fromJson(
          _json['updateNamedRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateProtectedRange')) {
      updateProtectedRange = UpdateProtectedRangeRequest.fromJson(
          _json['updateProtectedRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateSheetProperties')) {
      updateSheetProperties = UpdateSheetPropertiesRequest.fromJson(
          _json['updateSheetProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateSlicerSpec')) {
      updateSlicerSpec = UpdateSlicerSpecRequest.fromJson(
          _json['updateSlicerSpec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateSpreadsheetProperties')) {
      updateSpreadsheetProperties = UpdateSpreadsheetPropertiesRequest.fromJson(
          _json['updateSpreadsheetProperties']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (addBanding != null) 'addBanding': addBanding!.toJson(),
        if (addChart != null) 'addChart': addChart!.toJson(),
        if (addConditionalFormatRule != null)
          'addConditionalFormatRule': addConditionalFormatRule!.toJson(),
        if (addDataSource != null) 'addDataSource': addDataSource!.toJson(),
        if (addDimensionGroup != null)
          'addDimensionGroup': addDimensionGroup!.toJson(),
        if (addFilterView != null) 'addFilterView': addFilterView!.toJson(),
        if (addNamedRange != null) 'addNamedRange': addNamedRange!.toJson(),
        if (addProtectedRange != null)
          'addProtectedRange': addProtectedRange!.toJson(),
        if (addSheet != null) 'addSheet': addSheet!.toJson(),
        if (addSlicer != null) 'addSlicer': addSlicer!.toJson(),
        if (appendCells != null) 'appendCells': appendCells!.toJson(),
        if (appendDimension != null)
          'appendDimension': appendDimension!.toJson(),
        if (autoFill != null) 'autoFill': autoFill!.toJson(),
        if (autoResizeDimensions != null)
          'autoResizeDimensions': autoResizeDimensions!.toJson(),
        if (clearBasicFilter != null)
          'clearBasicFilter': clearBasicFilter!.toJson(),
        if (copyPaste != null) 'copyPaste': copyPaste!.toJson(),
        if (createDeveloperMetadata != null)
          'createDeveloperMetadata': createDeveloperMetadata!.toJson(),
        if (cutPaste != null) 'cutPaste': cutPaste!.toJson(),
        if (deleteBanding != null) 'deleteBanding': deleteBanding!.toJson(),
        if (deleteConditionalFormatRule != null)
          'deleteConditionalFormatRule': deleteConditionalFormatRule!.toJson(),
        if (deleteDataSource != null)
          'deleteDataSource': deleteDataSource!.toJson(),
        if (deleteDeveloperMetadata != null)
          'deleteDeveloperMetadata': deleteDeveloperMetadata!.toJson(),
        if (deleteDimension != null)
          'deleteDimension': deleteDimension!.toJson(),
        if (deleteDimensionGroup != null)
          'deleteDimensionGroup': deleteDimensionGroup!.toJson(),
        if (deleteDuplicates != null)
          'deleteDuplicates': deleteDuplicates!.toJson(),
        if (deleteEmbeddedObject != null)
          'deleteEmbeddedObject': deleteEmbeddedObject!.toJson(),
        if (deleteFilterView != null)
          'deleteFilterView': deleteFilterView!.toJson(),
        if (deleteNamedRange != null)
          'deleteNamedRange': deleteNamedRange!.toJson(),
        if (deleteProtectedRange != null)
          'deleteProtectedRange': deleteProtectedRange!.toJson(),
        if (deleteRange != null) 'deleteRange': deleteRange!.toJson(),
        if (deleteSheet != null) 'deleteSheet': deleteSheet!.toJson(),
        if (duplicateFilterView != null)
          'duplicateFilterView': duplicateFilterView!.toJson(),
        if (duplicateSheet != null) 'duplicateSheet': duplicateSheet!.toJson(),
        if (findReplace != null) 'findReplace': findReplace!.toJson(),
        if (insertDimension != null)
          'insertDimension': insertDimension!.toJson(),
        if (insertRange != null) 'insertRange': insertRange!.toJson(),
        if (mergeCells != null) 'mergeCells': mergeCells!.toJson(),
        if (moveDimension != null) 'moveDimension': moveDimension!.toJson(),
        if (pasteData != null) 'pasteData': pasteData!.toJson(),
        if (randomizeRange != null) 'randomizeRange': randomizeRange!.toJson(),
        if (refreshDataSource != null)
          'refreshDataSource': refreshDataSource!.toJson(),
        if (repeatCell != null) 'repeatCell': repeatCell!.toJson(),
        if (setBasicFilter != null) 'setBasicFilter': setBasicFilter!.toJson(),
        if (setDataValidation != null)
          'setDataValidation': setDataValidation!.toJson(),
        if (sortRange != null) 'sortRange': sortRange!.toJson(),
        if (textToColumns != null) 'textToColumns': textToColumns!.toJson(),
        if (trimWhitespace != null) 'trimWhitespace': trimWhitespace!.toJson(),
        if (unmergeCells != null) 'unmergeCells': unmergeCells!.toJson(),
        if (updateBanding != null) 'updateBanding': updateBanding!.toJson(),
        if (updateBorders != null) 'updateBorders': updateBorders!.toJson(),
        if (updateCells != null) 'updateCells': updateCells!.toJson(),
        if (updateChartSpec != null)
          'updateChartSpec': updateChartSpec!.toJson(),
        if (updateConditionalFormatRule != null)
          'updateConditionalFormatRule': updateConditionalFormatRule!.toJson(),
        if (updateDataSource != null)
          'updateDataSource': updateDataSource!.toJson(),
        if (updateDeveloperMetadata != null)
          'updateDeveloperMetadata': updateDeveloperMetadata!.toJson(),
        if (updateDimensionGroup != null)
          'updateDimensionGroup': updateDimensionGroup!.toJson(),
        if (updateDimensionProperties != null)
          'updateDimensionProperties': updateDimensionProperties!.toJson(),
        if (updateEmbeddedObjectBorder != null)
          'updateEmbeddedObjectBorder': updateEmbeddedObjectBorder!.toJson(),
        if (updateEmbeddedObjectPosition != null)
          'updateEmbeddedObjectPosition':
              updateEmbeddedObjectPosition!.toJson(),
        if (updateFilterView != null)
          'updateFilterView': updateFilterView!.toJson(),
        if (updateNamedRange != null)
          'updateNamedRange': updateNamedRange!.toJson(),
        if (updateProtectedRange != null)
          'updateProtectedRange': updateProtectedRange!.toJson(),
        if (updateSheetProperties != null)
          'updateSheetProperties': updateSheetProperties!.toJson(),
        if (updateSlicerSpec != null)
          'updateSlicerSpec': updateSlicerSpec!.toJson(),
        if (updateSpreadsheetProperties != null)
          'updateSpreadsheetProperties': updateSpreadsheetProperties!.toJson(),
      };
}

/// A single response from an update.
class Response {
  /// A reply from adding a banded range.
  AddBandingResponse? addBanding;

  /// A reply from adding a chart.
  AddChartResponse? addChart;

  /// A reply from adding a data source.
  AddDataSourceResponse? addDataSource;

  /// A reply from adding a dimension group.
  AddDimensionGroupResponse? addDimensionGroup;

  /// A reply from adding a filter view.
  AddFilterViewResponse? addFilterView;

  /// A reply from adding a named range.
  AddNamedRangeResponse? addNamedRange;

  /// A reply from adding a protected range.
  AddProtectedRangeResponse? addProtectedRange;

  /// A reply from adding a sheet.
  AddSheetResponse? addSheet;

  /// A reply from adding a slicer.
  AddSlicerResponse? addSlicer;

  /// A reply from creating a developer metadata entry.
  CreateDeveloperMetadataResponse? createDeveloperMetadata;

  /// A reply from deleting a conditional format rule.
  DeleteConditionalFormatRuleResponse? deleteConditionalFormatRule;

  /// A reply from deleting a developer metadata entry.
  DeleteDeveloperMetadataResponse? deleteDeveloperMetadata;

  /// A reply from deleting a dimension group.
  DeleteDimensionGroupResponse? deleteDimensionGroup;

  /// A reply from removing rows containing duplicate values.
  DeleteDuplicatesResponse? deleteDuplicates;

  /// A reply from duplicating a filter view.
  DuplicateFilterViewResponse? duplicateFilterView;

  /// A reply from duplicating a sheet.
  DuplicateSheetResponse? duplicateSheet;

  /// A reply from doing a find/replace.
  FindReplaceResponse? findReplace;

  /// A reply from refreshing data source objects.
  RefreshDataSourceResponse? refreshDataSource;

  /// A reply from trimming whitespace.
  TrimWhitespaceResponse? trimWhitespace;

  /// A reply from updating a conditional format rule.
  UpdateConditionalFormatRuleResponse? updateConditionalFormatRule;

  /// A reply from updating a data source.
  UpdateDataSourceResponse? updateDataSource;

  /// A reply from updating a developer metadata entry.
  UpdateDeveloperMetadataResponse? updateDeveloperMetadata;

  /// A reply from updating an embedded object's position.
  UpdateEmbeddedObjectPositionResponse? updateEmbeddedObjectPosition;

  Response();

  Response.fromJson(core.Map _json) {
    if (_json.containsKey('addBanding')) {
      addBanding = AddBandingResponse.fromJson(
          _json['addBanding'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addChart')) {
      addChart = AddChartResponse.fromJson(
          _json['addChart'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addDataSource')) {
      addDataSource = AddDataSourceResponse.fromJson(
          _json['addDataSource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addDimensionGroup')) {
      addDimensionGroup = AddDimensionGroupResponse.fromJson(
          _json['addDimensionGroup'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addFilterView')) {
      addFilterView = AddFilterViewResponse.fromJson(
          _json['addFilterView'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addNamedRange')) {
      addNamedRange = AddNamedRangeResponse.fromJson(
          _json['addNamedRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addProtectedRange')) {
      addProtectedRange = AddProtectedRangeResponse.fromJson(
          _json['addProtectedRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addSheet')) {
      addSheet = AddSheetResponse.fromJson(
          _json['addSheet'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('addSlicer')) {
      addSlicer = AddSlicerResponse.fromJson(
          _json['addSlicer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createDeveloperMetadata')) {
      createDeveloperMetadata = CreateDeveloperMetadataResponse.fromJson(
          _json['createDeveloperMetadata']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteConditionalFormatRule')) {
      deleteConditionalFormatRule =
          DeleteConditionalFormatRuleResponse.fromJson(
              _json['deleteConditionalFormatRule']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteDeveloperMetadata')) {
      deleteDeveloperMetadata = DeleteDeveloperMetadataResponse.fromJson(
          _json['deleteDeveloperMetadata']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteDimensionGroup')) {
      deleteDimensionGroup = DeleteDimensionGroupResponse.fromJson(
          _json['deleteDimensionGroup'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleteDuplicates')) {
      deleteDuplicates = DeleteDuplicatesResponse.fromJson(
          _json['deleteDuplicates'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('duplicateFilterView')) {
      duplicateFilterView = DuplicateFilterViewResponse.fromJson(
          _json['duplicateFilterView'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('duplicateSheet')) {
      duplicateSheet = DuplicateSheetResponse.fromJson(
          _json['duplicateSheet'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('findReplace')) {
      findReplace = FindReplaceResponse.fromJson(
          _json['findReplace'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('refreshDataSource')) {
      refreshDataSource = RefreshDataSourceResponse.fromJson(
          _json['refreshDataSource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('trimWhitespace')) {
      trimWhitespace = TrimWhitespaceResponse.fromJson(
          _json['trimWhitespace'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateConditionalFormatRule')) {
      updateConditionalFormatRule =
          UpdateConditionalFormatRuleResponse.fromJson(
              _json['updateConditionalFormatRule']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateDataSource')) {
      updateDataSource = UpdateDataSourceResponse.fromJson(
          _json['updateDataSource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateDeveloperMetadata')) {
      updateDeveloperMetadata = UpdateDeveloperMetadataResponse.fromJson(
          _json['updateDeveloperMetadata']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateEmbeddedObjectPosition')) {
      updateEmbeddedObjectPosition =
          UpdateEmbeddedObjectPositionResponse.fromJson(
              _json['updateEmbeddedObjectPosition']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (addBanding != null) 'addBanding': addBanding!.toJson(),
        if (addChart != null) 'addChart': addChart!.toJson(),
        if (addDataSource != null) 'addDataSource': addDataSource!.toJson(),
        if (addDimensionGroup != null)
          'addDimensionGroup': addDimensionGroup!.toJson(),
        if (addFilterView != null) 'addFilterView': addFilterView!.toJson(),
        if (addNamedRange != null) 'addNamedRange': addNamedRange!.toJson(),
        if (addProtectedRange != null)
          'addProtectedRange': addProtectedRange!.toJson(),
        if (addSheet != null) 'addSheet': addSheet!.toJson(),
        if (addSlicer != null) 'addSlicer': addSlicer!.toJson(),
        if (createDeveloperMetadata != null)
          'createDeveloperMetadata': createDeveloperMetadata!.toJson(),
        if (deleteConditionalFormatRule != null)
          'deleteConditionalFormatRule': deleteConditionalFormatRule!.toJson(),
        if (deleteDeveloperMetadata != null)
          'deleteDeveloperMetadata': deleteDeveloperMetadata!.toJson(),
        if (deleteDimensionGroup != null)
          'deleteDimensionGroup': deleteDimensionGroup!.toJson(),
        if (deleteDuplicates != null)
          'deleteDuplicates': deleteDuplicates!.toJson(),
        if (duplicateFilterView != null)
          'duplicateFilterView': duplicateFilterView!.toJson(),
        if (duplicateSheet != null) 'duplicateSheet': duplicateSheet!.toJson(),
        if (findReplace != null) 'findReplace': findReplace!.toJson(),
        if (refreshDataSource != null)
          'refreshDataSource': refreshDataSource!.toJson(),
        if (trimWhitespace != null) 'trimWhitespace': trimWhitespace!.toJson(),
        if (updateConditionalFormatRule != null)
          'updateConditionalFormatRule': updateConditionalFormatRule!.toJson(),
        if (updateDataSource != null)
          'updateDataSource': updateDataSource!.toJson(),
        if (updateDeveloperMetadata != null)
          'updateDeveloperMetadata': updateDeveloperMetadata!.toJson(),
        if (updateEmbeddedObjectPosition != null)
          'updateEmbeddedObjectPosition':
              updateEmbeddedObjectPosition!.toJson(),
      };
}

/// Data about each cell in a row.
class RowData {
  /// The values in the row, one per column.
  core.List<CellData>? values;

  RowData();

  RowData.fromJson(core.Map _json) {
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<CellData>((value) =>
              CellData.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (values != null)
          'values': values!.map((value) => value.toJson()).toList(),
      };
}

/// A scorecard chart.
///
/// Scorecard charts are used to highlight key performance indicators, known as
/// KPIs, on the spreadsheet. A scorecard chart can represent things like total
/// sales, average cost, or a top selling item. You can specify a single data
/// value, or aggregate over a range of data. Percentage or absolute difference
/// from a baseline value can be highlighted, like changes over time.
class ScorecardChartSpec {
  /// The aggregation type for key and baseline chart data in scorecard chart.
  ///
  /// This field is not supported for data source charts. Use the
  /// ChartData.aggregateType field of the key_value_data or baseline_value_data
  /// instead for data source charts. This field is optional.
  /// Possible string values are:
  /// - "CHART_AGGREGATE_TYPE_UNSPECIFIED" : Default value, do not use.
  /// - "AVERAGE" : Average aggregate function.
  /// - "COUNT" : Count aggregate function.
  /// - "MAX" : Maximum aggregate function.
  /// - "MEDIAN" : Median aggregate function.
  /// - "MIN" : Minimum aggregate function.
  /// - "SUM" : Sum aggregate function.
  core.String? aggregateType;

  /// The data for scorecard baseline value.
  ///
  /// This field is optional.
  ChartData? baselineValueData;

  /// Formatting options for baseline value.
  ///
  /// This field is needed only if baseline_value_data is specified.
  BaselineValueFormat? baselineValueFormat;

  /// Custom formatting options for numeric key/baseline values in scorecard
  /// chart.
  ///
  /// This field is used only when number_format_source is set to CUSTOM. This
  /// field is optional.
  ChartCustomNumberFormatOptions? customFormatOptions;

  /// The data for scorecard key value.
  ChartData? keyValueData;

  /// Formatting options for key value.
  KeyValueFormat? keyValueFormat;

  /// The number format source used in the scorecard chart.
  ///
  /// This field is optional.
  /// Possible string values are:
  /// - "CHART_NUMBER_FORMAT_SOURCE_UNDEFINED" : Default value, do not use.
  /// - "FROM_DATA" : Inherit number formatting from data.
  /// - "CUSTOM" : Apply custom formatting as specified by
  /// ChartCustomNumberFormatOptions.
  core.String? numberFormatSource;

  /// Value to scale scorecard key and baseline value.
  ///
  /// For example, a factor of 10 can be used to divide all values in the chart
  /// by 10. This field is optional.
  core.double? scaleFactor;

  ScorecardChartSpec();

  ScorecardChartSpec.fromJson(core.Map _json) {
    if (_json.containsKey('aggregateType')) {
      aggregateType = _json['aggregateType'] as core.String;
    }
    if (_json.containsKey('baselineValueData')) {
      baselineValueData = ChartData.fromJson(
          _json['baselineValueData'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('baselineValueFormat')) {
      baselineValueFormat = BaselineValueFormat.fromJson(
          _json['baselineValueFormat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('customFormatOptions')) {
      customFormatOptions = ChartCustomNumberFormatOptions.fromJson(
          _json['customFormatOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('keyValueData')) {
      keyValueData = ChartData.fromJson(
          _json['keyValueData'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('keyValueFormat')) {
      keyValueFormat = KeyValueFormat.fromJson(
          _json['keyValueFormat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('numberFormatSource')) {
      numberFormatSource = _json['numberFormatSource'] as core.String;
    }
    if (_json.containsKey('scaleFactor')) {
      scaleFactor = (_json['scaleFactor'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aggregateType != null) 'aggregateType': aggregateType!,
        if (baselineValueData != null)
          'baselineValueData': baselineValueData!.toJson(),
        if (baselineValueFormat != null)
          'baselineValueFormat': baselineValueFormat!.toJson(),
        if (customFormatOptions != null)
          'customFormatOptions': customFormatOptions!.toJson(),
        if (keyValueData != null) 'keyValueData': keyValueData!.toJson(),
        if (keyValueFormat != null) 'keyValueFormat': keyValueFormat!.toJson(),
        if (numberFormatSource != null)
          'numberFormatSource': numberFormatSource!,
        if (scaleFactor != null) 'scaleFactor': scaleFactor!,
      };
}

/// A request to retrieve all developer metadata matching the set of specified
/// criteria.
class SearchDeveloperMetadataRequest {
  /// The data filters describing the criteria used to determine which
  /// DeveloperMetadata entries to return.
  ///
  /// DeveloperMetadata matching any of the specified filters are included in
  /// the response.
  core.List<DataFilter>? dataFilters;

  SearchDeveloperMetadataRequest();

  SearchDeveloperMetadataRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataFilters')) {
      dataFilters = (_json['dataFilters'] as core.List)
          .map<DataFilter>((value) =>
              DataFilter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataFilters != null)
          'dataFilters': dataFilters!.map((value) => value.toJson()).toList(),
      };
}

/// A reply to a developer metadata search request.
class SearchDeveloperMetadataResponse {
  /// The metadata matching the criteria of the search request.
  core.List<MatchedDeveloperMetadata>? matchedDeveloperMetadata;

  SearchDeveloperMetadataResponse();

  SearchDeveloperMetadataResponse.fromJson(core.Map _json) {
    if (_json.containsKey('matchedDeveloperMetadata')) {
      matchedDeveloperMetadata =
          (_json['matchedDeveloperMetadata'] as core.List)
              .map<MatchedDeveloperMetadata>((value) =>
                  MatchedDeveloperMetadata.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (matchedDeveloperMetadata != null)
          'matchedDeveloperMetadata':
              matchedDeveloperMetadata!.map((value) => value.toJson()).toList(),
      };
}

/// Sets the basic filter associated with a sheet.
class SetBasicFilterRequest {
  /// The filter to set.
  BasicFilter? filter;

  SetBasicFilterRequest();

  SetBasicFilterRequest.fromJson(core.Map _json) {
    if (_json.containsKey('filter')) {
      filter = BasicFilter.fromJson(
          _json['filter'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filter != null) 'filter': filter!.toJson(),
      };
}

/// Sets a data validation rule to every cell in the range.
///
/// To clear validation in a range, call this with no rule specified.
class SetDataValidationRequest {
  /// The range the data validation rule should apply to.
  GridRange? range;

  /// The data validation rule to set on each cell in the range, or empty to
  /// clear the data validation in the range.
  DataValidationRule? rule;

  SetDataValidationRequest();

  SetDataValidationRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rule')) {
      rule = DataValidationRule.fromJson(
          _json['rule'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
        if (rule != null) 'rule': rule!.toJson(),
      };
}

/// A sheet in a spreadsheet.
class Sheet {
  /// The banded (alternating colors) ranges on this sheet.
  core.List<BandedRange>? bandedRanges;

  /// The filter on this sheet, if any.
  BasicFilter? basicFilter;

  /// The specifications of every chart on this sheet.
  core.List<EmbeddedChart>? charts;

  /// All column groups on this sheet, ordered by increasing range start index,
  /// then by group depth.
  core.List<DimensionGroup>? columnGroups;

  /// The conditional format rules in this sheet.
  core.List<ConditionalFormatRule>? conditionalFormats;

  /// Data in the grid, if this is a grid sheet.
  ///
  /// The number of GridData objects returned is dependent on the number of
  /// ranges requested on this sheet. For example, if this is representing
  /// `Sheet1`, and the spreadsheet was requested with ranges `Sheet1!A1:C10`
  /// and `Sheet1!D15:E20`, then the first GridData will have a
  /// startRow/startColumn of `0`, while the second one will have `startRow 14`
  /// (zero-based row 15), and `startColumn 3` (zero-based column D). For a
  /// DATA_SOURCE sheet, you can not request a specific range, the GridData
  /// contains all the values.
  core.List<GridData>? data;

  /// The developer metadata associated with a sheet.
  core.List<DeveloperMetadata>? developerMetadata;

  /// The filter views in this sheet.
  core.List<FilterView>? filterViews;

  /// The ranges that are merged together.
  core.List<GridRange>? merges;

  /// The properties of the sheet.
  SheetProperties? properties;

  /// The protected ranges in this sheet.
  core.List<ProtectedRange>? protectedRanges;

  /// All row groups on this sheet, ordered by increasing range start index,
  /// then by group depth.
  core.List<DimensionGroup>? rowGroups;

  /// The slicers on this sheet.
  core.List<Slicer>? slicers;

  Sheet();

  Sheet.fromJson(core.Map _json) {
    if (_json.containsKey('bandedRanges')) {
      bandedRanges = (_json['bandedRanges'] as core.List)
          .map<BandedRange>((value) => BandedRange.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('basicFilter')) {
      basicFilter = BasicFilter.fromJson(
          _json['basicFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('charts')) {
      charts = (_json['charts'] as core.List)
          .map<EmbeddedChart>((value) => EmbeddedChart.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('columnGroups')) {
      columnGroups = (_json['columnGroups'] as core.List)
          .map<DimensionGroup>((value) => DimensionGroup.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('conditionalFormats')) {
      conditionalFormats = (_json['conditionalFormats'] as core.List)
          .map<ConditionalFormatRule>((value) => ConditionalFormatRule.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.List)
          .map<GridData>((value) =>
              GridData.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('developerMetadata')) {
      developerMetadata = (_json['developerMetadata'] as core.List)
          .map<DeveloperMetadata>((value) => DeveloperMetadata.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('filterViews')) {
      filterViews = (_json['filterViews'] as core.List)
          .map<FilterView>((value) =>
              FilterView.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('merges')) {
      merges = (_json['merges'] as core.List)
          .map<GridRange>((value) =>
              GridRange.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('properties')) {
      properties = SheetProperties.fromJson(
          _json['properties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('protectedRanges')) {
      protectedRanges = (_json['protectedRanges'] as core.List)
          .map<ProtectedRange>((value) => ProtectedRange.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('rowGroups')) {
      rowGroups = (_json['rowGroups'] as core.List)
          .map<DimensionGroup>((value) => DimensionGroup.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('slicers')) {
      slicers = (_json['slicers'] as core.List)
          .map<Slicer>((value) =>
              Slicer.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bandedRanges != null)
          'bandedRanges': bandedRanges!.map((value) => value.toJson()).toList(),
        if (basicFilter != null) 'basicFilter': basicFilter!.toJson(),
        if (charts != null)
          'charts': charts!.map((value) => value.toJson()).toList(),
        if (columnGroups != null)
          'columnGroups': columnGroups!.map((value) => value.toJson()).toList(),
        if (conditionalFormats != null)
          'conditionalFormats':
              conditionalFormats!.map((value) => value.toJson()).toList(),
        if (data != null) 'data': data!.map((value) => value.toJson()).toList(),
        if (developerMetadata != null)
          'developerMetadata':
              developerMetadata!.map((value) => value.toJson()).toList(),
        if (filterViews != null)
          'filterViews': filterViews!.map((value) => value.toJson()).toList(),
        if (merges != null)
          'merges': merges!.map((value) => value.toJson()).toList(),
        if (properties != null) 'properties': properties!.toJson(),
        if (protectedRanges != null)
          'protectedRanges':
              protectedRanges!.map((value) => value.toJson()).toList(),
        if (rowGroups != null)
          'rowGroups': rowGroups!.map((value) => value.toJson()).toList(),
        if (slicers != null)
          'slicers': slicers!.map((value) => value.toJson()).toList(),
      };
}

/// Properties of a sheet.
class SheetProperties {
  /// If present, the field contains DATA_SOURCE sheet specific properties.
  ///
  /// Output only.
  DataSourceSheetProperties? dataSourceSheetProperties;

  /// Additional properties of the sheet if this sheet is a grid.
  ///
  /// (If the sheet is an object sheet, containing a chart or image, then this
  /// field will be absent.) When writing it is an error to set any grid
  /// properties on non-grid sheets. If this sheet is a DATA_SOURCE sheet, this
  /// field is output only but contains the properties that reflect how a data
  /// source sheet is rendered in the UI, e.g. row_count.
  GridProperties? gridProperties;

  /// True if the sheet is hidden in the UI, false if it's visible.
  core.bool? hidden;

  /// The index of the sheet within the spreadsheet.
  ///
  /// When adding or updating sheet properties, if this field is excluded then
  /// the sheet is added or moved to the end of the sheet list. When updating
  /// sheet indices or inserting sheets, movement is considered in "before the
  /// move" indexes. For example, if there were 3 sheets (S1, S2, S3) in order
  /// to move S1 ahead of S2 the index would have to be set to 2. A sheet index
  /// update request is ignored if the requested index is identical to the
  /// sheets current index or if the requested new index is equal to the current
  /// sheet index + 1.
  core.int? index;

  /// True if the sheet is an RTL sheet instead of an LTR sheet.
  core.bool? rightToLeft;

  /// The ID of the sheet.
  ///
  /// Must be non-negative. This field cannot be changed once set.
  core.int? sheetId;

  /// The type of sheet.
  ///
  /// Defaults to GRID. This field cannot be changed once set.
  /// Possible string values are:
  /// - "SHEET_TYPE_UNSPECIFIED" : Default value, do not use.
  /// - "GRID" : The sheet is a grid.
  /// - "OBJECT" : The sheet has no grid and instead has an object like a chart
  /// or image.
  /// - "DATA_SOURCE" : The sheet connects with an external DataSource and shows
  /// the preview of data.
  core.String? sheetType;

  /// The color of the tab in the UI.
  Color? tabColor;

  /// The color of the tab in the UI.
  ///
  /// If tab_color is also set, this field takes precedence.
  ColorStyle? tabColorStyle;

  /// The name of the sheet.
  core.String? title;

  SheetProperties();

  SheetProperties.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceSheetProperties')) {
      dataSourceSheetProperties = DataSourceSheetProperties.fromJson(
          _json['dataSourceSheetProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gridProperties')) {
      gridProperties = GridProperties.fromJson(
          _json['gridProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hidden')) {
      hidden = _json['hidden'] as core.bool;
    }
    if (_json.containsKey('index')) {
      index = _json['index'] as core.int;
    }
    if (_json.containsKey('rightToLeft')) {
      rightToLeft = _json['rightToLeft'] as core.bool;
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
    if (_json.containsKey('sheetType')) {
      sheetType = _json['sheetType'] as core.String;
    }
    if (_json.containsKey('tabColor')) {
      tabColor = Color.fromJson(
          _json['tabColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tabColorStyle')) {
      tabColorStyle = ColorStyle.fromJson(
          _json['tabColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceSheetProperties != null)
          'dataSourceSheetProperties': dataSourceSheetProperties!.toJson(),
        if (gridProperties != null) 'gridProperties': gridProperties!.toJson(),
        if (hidden != null) 'hidden': hidden!,
        if (index != null) 'index': index!,
        if (rightToLeft != null) 'rightToLeft': rightToLeft!,
        if (sheetId != null) 'sheetId': sheetId!,
        if (sheetType != null) 'sheetType': sheetType!,
        if (tabColor != null) 'tabColor': tabColor!.toJson(),
        if (tabColorStyle != null) 'tabColorStyle': tabColorStyle!.toJson(),
        if (title != null) 'title': title!,
      };
}

/// A slicer in a sheet.
class Slicer {
  /// The position of the slicer.
  ///
  /// Note that slicer can be positioned only on existing sheet. Also, width and
  /// height of slicer can be automatically adjusted to keep it within permitted
  /// limits.
  EmbeddedObjectPosition? position;

  /// The ID of the slicer.
  core.int? slicerId;

  /// The specification of the slicer.
  SlicerSpec? spec;

  Slicer();

  Slicer.fromJson(core.Map _json) {
    if (_json.containsKey('position')) {
      position = EmbeddedObjectPosition.fromJson(
          _json['position'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('slicerId')) {
      slicerId = _json['slicerId'] as core.int;
    }
    if (_json.containsKey('spec')) {
      spec = SlicerSpec.fromJson(
          _json['spec'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (position != null) 'position': position!.toJson(),
        if (slicerId != null) 'slicerId': slicerId!,
        if (spec != null) 'spec': spec!.toJson(),
      };
}

/// The specifications of a slicer.
class SlicerSpec {
  /// True if the filter should apply to pivot tables.
  ///
  /// If not set, default to `True`.
  core.bool? applyToPivotTables;

  /// The background color of the slicer.
  Color? backgroundColor;

  /// The background color of the slicer.
  ///
  /// If background_color is also set, this field takes precedence.
  ColorStyle? backgroundColorStyle;

  /// The column index in the data table on which the filter is applied to.
  core.int? columnIndex;

  /// The data range of the slicer.
  GridRange? dataRange;

  /// The filtering criteria of the slicer.
  FilterCriteria? filterCriteria;

  /// The horizontal alignment of title in the slicer.
  ///
  /// If unspecified, defaults to `LEFT`
  /// Possible string values are:
  /// - "HORIZONTAL_ALIGN_UNSPECIFIED" : The horizontal alignment is not
  /// specified. Do not use this.
  /// - "LEFT" : The text is explicitly aligned to the left of the cell.
  /// - "CENTER" : The text is explicitly aligned to the center of the cell.
  /// - "RIGHT" : The text is explicitly aligned to the right of the cell.
  core.String? horizontalAlignment;

  /// The text format of title in the slicer.
  ///
  /// The link field is not supported.
  TextFormat? textFormat;

  /// The title of the slicer.
  core.String? title;

  SlicerSpec();

  SlicerSpec.fromJson(core.Map _json) {
    if (_json.containsKey('applyToPivotTables')) {
      applyToPivotTables = _json['applyToPivotTables'] as core.bool;
    }
    if (_json.containsKey('backgroundColor')) {
      backgroundColor = Color.fromJson(
          _json['backgroundColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('backgroundColorStyle')) {
      backgroundColorStyle = ColorStyle.fromJson(
          _json['backgroundColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('columnIndex')) {
      columnIndex = _json['columnIndex'] as core.int;
    }
    if (_json.containsKey('dataRange')) {
      dataRange = GridRange.fromJson(
          _json['dataRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('filterCriteria')) {
      filterCriteria = FilterCriteria.fromJson(
          _json['filterCriteria'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('horizontalAlignment')) {
      horizontalAlignment = _json['horizontalAlignment'] as core.String;
    }
    if (_json.containsKey('textFormat')) {
      textFormat = TextFormat.fromJson(
          _json['textFormat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applyToPivotTables != null)
          'applyToPivotTables': applyToPivotTables!,
        if (backgroundColor != null)
          'backgroundColor': backgroundColor!.toJson(),
        if (backgroundColorStyle != null)
          'backgroundColorStyle': backgroundColorStyle!.toJson(),
        if (columnIndex != null) 'columnIndex': columnIndex!,
        if (dataRange != null) 'dataRange': dataRange!.toJson(),
        if (filterCriteria != null) 'filterCriteria': filterCriteria!.toJson(),
        if (horizontalAlignment != null)
          'horizontalAlignment': horizontalAlignment!,
        if (textFormat != null) 'textFormat': textFormat!.toJson(),
        if (title != null) 'title': title!,
      };
}

/// Sorts data in rows based on a sort order per column.
class SortRangeRequest {
  /// The range to sort.
  GridRange? range;

  /// The sort order per column.
  ///
  /// Later specifications are used when values are equal in the earlier
  /// specifications.
  core.List<SortSpec>? sortSpecs;

  SortRangeRequest();

  SortRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sortSpecs')) {
      sortSpecs = (_json['sortSpecs'] as core.List)
          .map<SortSpec>((value) =>
              SortSpec.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
        if (sortSpecs != null)
          'sortSpecs': sortSpecs!.map((value) => value.toJson()).toList(),
      };
}

/// A sort order associated with a specific column or row.
class SortSpec {
  /// The background fill color to sort by; cells with this fill color are
  /// sorted to the top.
  ///
  /// Mutually exclusive with foreground_color.
  Color? backgroundColor;

  /// The background fill color to sort by; cells with this fill color are
  /// sorted to the top.
  ///
  /// Mutually exclusive with foreground_color, and must be an RGB-type color.
  /// If background_color is also set, this field takes precedence.
  ColorStyle? backgroundColorStyle;

  /// Reference to a data source column.
  DataSourceColumnReference? dataSourceColumnReference;

  /// The dimension the sort should be applied to.
  core.int? dimensionIndex;

  /// The foreground color to sort by; cells with this foreground color are
  /// sorted to the top.
  ///
  /// Mutually exclusive with background_color.
  Color? foregroundColor;

  /// The foreground color to sort by; cells with this foreground color are
  /// sorted to the top.
  ///
  /// Mutually exclusive with background_color, and must be an RGB-type color.
  /// If foreground_color is also set, this field takes precedence.
  ColorStyle? foregroundColorStyle;

  /// The order data should be sorted.
  /// Possible string values are:
  /// - "SORT_ORDER_UNSPECIFIED" : Default value, do not use this.
  /// - "ASCENDING" : Sort ascending.
  /// - "DESCENDING" : Sort descending.
  core.String? sortOrder;

  SortSpec();

  SortSpec.fromJson(core.Map _json) {
    if (_json.containsKey('backgroundColor')) {
      backgroundColor = Color.fromJson(
          _json['backgroundColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('backgroundColorStyle')) {
      backgroundColorStyle = ColorStyle.fromJson(
          _json['backgroundColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataSourceColumnReference')) {
      dataSourceColumnReference = DataSourceColumnReference.fromJson(
          _json['dataSourceColumnReference']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dimensionIndex')) {
      dimensionIndex = _json['dimensionIndex'] as core.int;
    }
    if (_json.containsKey('foregroundColor')) {
      foregroundColor = Color.fromJson(
          _json['foregroundColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('foregroundColorStyle')) {
      foregroundColorStyle = ColorStyle.fromJson(
          _json['foregroundColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sortOrder')) {
      sortOrder = _json['sortOrder'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backgroundColor != null)
          'backgroundColor': backgroundColor!.toJson(),
        if (backgroundColorStyle != null)
          'backgroundColorStyle': backgroundColorStyle!.toJson(),
        if (dataSourceColumnReference != null)
          'dataSourceColumnReference': dataSourceColumnReference!.toJson(),
        if (dimensionIndex != null) 'dimensionIndex': dimensionIndex!,
        if (foregroundColor != null)
          'foregroundColor': foregroundColor!.toJson(),
        if (foregroundColorStyle != null)
          'foregroundColorStyle': foregroundColorStyle!.toJson(),
        if (sortOrder != null) 'sortOrder': sortOrder!,
      };
}

/// A combination of a source range and how to extend that source.
class SourceAndDestination {
  /// The dimension that data should be filled into.
  /// Possible string values are:
  /// - "DIMENSION_UNSPECIFIED" : The default value, do not use.
  /// - "ROWS" : Operates on the rows of a sheet.
  /// - "COLUMNS" : Operates on the columns of a sheet.
  core.String? dimension;

  /// The number of rows or columns that data should be filled into.
  ///
  /// Positive numbers expand beyond the last row or last column of the source.
  /// Negative numbers expand before the first row or first column of the
  /// source.
  core.int? fillLength;

  /// The location of the data to use as the source of the autofill.
  GridRange? source;

  SourceAndDestination();

  SourceAndDestination.fromJson(core.Map _json) {
    if (_json.containsKey('dimension')) {
      dimension = _json['dimension'] as core.String;
    }
    if (_json.containsKey('fillLength')) {
      fillLength = _json['fillLength'] as core.int;
    }
    if (_json.containsKey('source')) {
      source = GridRange.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimension != null) 'dimension': dimension!,
        if (fillLength != null) 'fillLength': fillLength!,
        if (source != null) 'source': source!.toJson(),
      };
}

/// Resource that represents a spreadsheet.
class Spreadsheet {
  /// A list of data source refresh schedules.
  ///
  /// Output only.
  core.List<DataSourceRefreshSchedule>? dataSourceSchedules;

  /// A list of external data sources connected with the spreadsheet.
  core.List<DataSource>? dataSources;

  /// The developer metadata associated with a spreadsheet.
  core.List<DeveloperMetadata>? developerMetadata;

  /// The named ranges defined in a spreadsheet.
  core.List<NamedRange>? namedRanges;

  /// Overall properties of a spreadsheet.
  SpreadsheetProperties? properties;

  /// The sheets that are part of a spreadsheet.
  core.List<Sheet>? sheets;

  /// The ID of the spreadsheet.
  ///
  /// This field is read-only.
  core.String? spreadsheetId;

  /// The url of the spreadsheet.
  ///
  /// This field is read-only.
  core.String? spreadsheetUrl;

  Spreadsheet();

  Spreadsheet.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceSchedules')) {
      dataSourceSchedules = (_json['dataSourceSchedules'] as core.List)
          .map<DataSourceRefreshSchedule>((value) =>
              DataSourceRefreshSchedule.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dataSources')) {
      dataSources = (_json['dataSources'] as core.List)
          .map<DataSource>((value) =>
              DataSource.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('developerMetadata')) {
      developerMetadata = (_json['developerMetadata'] as core.List)
          .map<DeveloperMetadata>((value) => DeveloperMetadata.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('namedRanges')) {
      namedRanges = (_json['namedRanges'] as core.List)
          .map<NamedRange>((value) =>
              NamedRange.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('properties')) {
      properties = SpreadsheetProperties.fromJson(
          _json['properties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sheets')) {
      sheets = (_json['sheets'] as core.List)
          .map<Sheet>((value) =>
              Sheet.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
    if (_json.containsKey('spreadsheetUrl')) {
      spreadsheetUrl = _json['spreadsheetUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceSchedules != null)
          'dataSourceSchedules':
              dataSourceSchedules!.map((value) => value.toJson()).toList(),
        if (dataSources != null)
          'dataSources': dataSources!.map((value) => value.toJson()).toList(),
        if (developerMetadata != null)
          'developerMetadata':
              developerMetadata!.map((value) => value.toJson()).toList(),
        if (namedRanges != null)
          'namedRanges': namedRanges!.map((value) => value.toJson()).toList(),
        if (properties != null) 'properties': properties!.toJson(),
        if (sheets != null)
          'sheets': sheets!.map((value) => value.toJson()).toList(),
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
        if (spreadsheetUrl != null) 'spreadsheetUrl': spreadsheetUrl!,
      };
}

/// Properties of a spreadsheet.
class SpreadsheetProperties {
  /// The amount of time to wait before volatile functions are recalculated.
  /// Possible string values are:
  /// - "RECALCULATION_INTERVAL_UNSPECIFIED" : Default value. This value must
  /// not be used.
  /// - "ON_CHANGE" : Volatile functions are updated on every change.
  /// - "MINUTE" : Volatile functions are updated on every change and every
  /// minute.
  /// - "HOUR" : Volatile functions are updated on every change and hourly.
  core.String? autoRecalc;

  /// The default format of all cells in the spreadsheet.
  ///
  /// CellData.effectiveFormat will not be set if the cell's format is equal to
  /// this default format. This field is read-only.
  CellFormat? defaultFormat;

  /// Determines whether and how circular references are resolved with iterative
  /// calculation.
  ///
  /// Absence of this field means that circular references result in calculation
  /// errors.
  IterativeCalculationSettings? iterativeCalculationSettings;

  /// The locale of the spreadsheet in one of the following formats: * an ISO
  /// 639-1 language code such as `en` * an ISO 639-2 language code such as
  /// `fil`, if no 639-1 code exists * a combination of the ISO language code
  /// and country code, such as `en_US` Note: when updating this field, not all
  /// locales/languages are supported.
  core.String? locale;

  /// Theme applied to the spreadsheet.
  SpreadsheetTheme? spreadsheetTheme;

  /// The time zone of the spreadsheet, in CLDR format such as
  /// `America/New_York`.
  ///
  /// If the time zone isn't recognized, this may be a custom time zone such as
  /// `GMT-07:00`.
  core.String? timeZone;

  /// The title of the spreadsheet.
  core.String? title;

  SpreadsheetProperties();

  SpreadsheetProperties.fromJson(core.Map _json) {
    if (_json.containsKey('autoRecalc')) {
      autoRecalc = _json['autoRecalc'] as core.String;
    }
    if (_json.containsKey('defaultFormat')) {
      defaultFormat = CellFormat.fromJson(
          _json['defaultFormat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('iterativeCalculationSettings')) {
      iterativeCalculationSettings = IterativeCalculationSettings.fromJson(
          _json['iterativeCalculationSettings']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('locale')) {
      locale = _json['locale'] as core.String;
    }
    if (_json.containsKey('spreadsheetTheme')) {
      spreadsheetTheme = SpreadsheetTheme.fromJson(
          _json['spreadsheetTheme'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeZone')) {
      timeZone = _json['timeZone'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoRecalc != null) 'autoRecalc': autoRecalc!,
        if (defaultFormat != null) 'defaultFormat': defaultFormat!.toJson(),
        if (iterativeCalculationSettings != null)
          'iterativeCalculationSettings':
              iterativeCalculationSettings!.toJson(),
        if (locale != null) 'locale': locale!,
        if (spreadsheetTheme != null)
          'spreadsheetTheme': spreadsheetTheme!.toJson(),
        if (timeZone != null) 'timeZone': timeZone!,
        if (title != null) 'title': title!,
      };
}

/// Represents spreadsheet theme
class SpreadsheetTheme {
  /// Name of the primary font family.
  core.String? primaryFontFamily;

  /// The spreadsheet theme color pairs.
  ///
  /// To update you must provide all theme color pairs.
  core.List<ThemeColorPair>? themeColors;

  SpreadsheetTheme();

  SpreadsheetTheme.fromJson(core.Map _json) {
    if (_json.containsKey('primaryFontFamily')) {
      primaryFontFamily = _json['primaryFontFamily'] as core.String;
    }
    if (_json.containsKey('themeColors')) {
      themeColors = (_json['themeColors'] as core.List)
          .map<ThemeColorPair>((value) => ThemeColorPair.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (primaryFontFamily != null) 'primaryFontFamily': primaryFontFamily!,
        if (themeColors != null)
          'themeColors': themeColors!.map((value) => value.toJson()).toList(),
      };
}

/// The format of a run of text in a cell.
///
/// Absent values indicate that the field isn't specified.
class TextFormat {
  /// True if the text is bold.
  core.bool? bold;

  /// The font family.
  core.String? fontFamily;

  /// The size of the font.
  core.int? fontSize;

  /// The foreground color of the text.
  Color? foregroundColor;

  /// The foreground color of the text.
  ///
  /// If foreground_color is also set, this field takes precedence.
  ColorStyle? foregroundColorStyle;

  /// True if the text is italicized.
  core.bool? italic;

  /// The link destination of the text, if any.
  ///
  /// Setting a link in a format run will clear an existing cell-level link.
  /// When a link is set, the text foreground color will be set to the default
  /// link color and the text will be underlined. If these fields are modified
  /// in the same request, those values will be used instead of the link
  /// defaults.
  Link? link;

  /// True if the text has a strikethrough.
  core.bool? strikethrough;

  /// True if the text is underlined.
  core.bool? underline;

  TextFormat();

  TextFormat.fromJson(core.Map _json) {
    if (_json.containsKey('bold')) {
      bold = _json['bold'] as core.bool;
    }
    if (_json.containsKey('fontFamily')) {
      fontFamily = _json['fontFamily'] as core.String;
    }
    if (_json.containsKey('fontSize')) {
      fontSize = _json['fontSize'] as core.int;
    }
    if (_json.containsKey('foregroundColor')) {
      foregroundColor = Color.fromJson(
          _json['foregroundColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('foregroundColorStyle')) {
      foregroundColorStyle = ColorStyle.fromJson(
          _json['foregroundColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('italic')) {
      italic = _json['italic'] as core.bool;
    }
    if (_json.containsKey('link')) {
      link =
          Link.fromJson(_json['link'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('strikethrough')) {
      strikethrough = _json['strikethrough'] as core.bool;
    }
    if (_json.containsKey('underline')) {
      underline = _json['underline'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bold != null) 'bold': bold!,
        if (fontFamily != null) 'fontFamily': fontFamily!,
        if (fontSize != null) 'fontSize': fontSize!,
        if (foregroundColor != null)
          'foregroundColor': foregroundColor!.toJson(),
        if (foregroundColorStyle != null)
          'foregroundColorStyle': foregroundColorStyle!.toJson(),
        if (italic != null) 'italic': italic!,
        if (link != null) 'link': link!.toJson(),
        if (strikethrough != null) 'strikethrough': strikethrough!,
        if (underline != null) 'underline': underline!,
      };
}

/// A run of a text format.
///
/// The format of this run continues until the start index of the next run. When
/// updating, all fields must be set.
class TextFormatRun {
  /// The format of this run.
  ///
  /// Absent values inherit the cell's format.
  TextFormat? format;

  /// The character index where this run starts.
  core.int? startIndex;

  TextFormatRun();

  TextFormatRun.fromJson(core.Map _json) {
    if (_json.containsKey('format')) {
      format = TextFormat.fromJson(
          _json['format'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startIndex')) {
      startIndex = _json['startIndex'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (format != null) 'format': format!.toJson(),
        if (startIndex != null) 'startIndex': startIndex!,
      };
}

/// Position settings for text.
class TextPosition {
  /// Horizontal alignment setting for the piece of text.
  /// Possible string values are:
  /// - "HORIZONTAL_ALIGN_UNSPECIFIED" : The horizontal alignment is not
  /// specified. Do not use this.
  /// - "LEFT" : The text is explicitly aligned to the left of the cell.
  /// - "CENTER" : The text is explicitly aligned to the center of the cell.
  /// - "RIGHT" : The text is explicitly aligned to the right of the cell.
  core.String? horizontalAlignment;

  TextPosition();

  TextPosition.fromJson(core.Map _json) {
    if (_json.containsKey('horizontalAlignment')) {
      horizontalAlignment = _json['horizontalAlignment'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (horizontalAlignment != null)
          'horizontalAlignment': horizontalAlignment!,
      };
}

/// The rotation applied to text in a cell.
class TextRotation {
  /// The angle between the standard orientation and the desired orientation.
  ///
  /// Measured in degrees. Valid values are between -90 and 90. Positive angles
  /// are angled upwards, negative are angled downwards. Note: For LTR text
  /// direction positive angles are in the counterclockwise direction, whereas
  /// for RTL they are in the clockwise direction
  core.int? angle;

  /// If true, text reads top to bottom, but the orientation of individual
  /// characters is unchanged.
  ///
  /// For example: | V | | e | | r | | t | | i | | c | | a | | l |
  core.bool? vertical;

  TextRotation();

  TextRotation.fromJson(core.Map _json) {
    if (_json.containsKey('angle')) {
      angle = _json['angle'] as core.int;
    }
    if (_json.containsKey('vertical')) {
      vertical = _json['vertical'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (angle != null) 'angle': angle!,
        if (vertical != null) 'vertical': vertical!,
      };
}

/// Splits a column of text into multiple columns, based on a delimiter in each
/// cell.
class TextToColumnsRequest {
  /// The delimiter to use.
  ///
  /// Used only if delimiterType is CUSTOM.
  core.String? delimiter;

  /// The delimiter type to use.
  /// Possible string values are:
  /// - "DELIMITER_TYPE_UNSPECIFIED" : Default value. This value must not be
  /// used.
  /// - "COMMA" : ","
  /// - "SEMICOLON" : ";"
  /// - "PERIOD" : "."
  /// - "SPACE" : " "
  /// - "CUSTOM" : A custom value as defined in delimiter.
  /// - "AUTODETECT" : Automatically detect columns.
  core.String? delimiterType;

  /// The source data range.
  ///
  /// This must span exactly one column.
  GridRange? source;

  TextToColumnsRequest();

  TextToColumnsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('delimiter')) {
      delimiter = _json['delimiter'] as core.String;
    }
    if (_json.containsKey('delimiterType')) {
      delimiterType = _json['delimiterType'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = GridRange.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (delimiter != null) 'delimiter': delimiter!,
        if (delimiterType != null) 'delimiterType': delimiterType!,
        if (source != null) 'source': source!.toJson(),
      };
}

/// A pair mapping a spreadsheet theme color type to the concrete color it
/// represents.
class ThemeColorPair {
  /// The concrete color corresponding to the theme color type.
  ColorStyle? color;

  /// The type of the spreadsheet theme color.
  /// Possible string values are:
  /// - "THEME_COLOR_TYPE_UNSPECIFIED" : Unspecified theme color
  /// - "TEXT" : Represents the primary text color
  /// - "BACKGROUND" : Represents the primary background color
  /// - "ACCENT1" : Represents the first accent color
  /// - "ACCENT2" : Represents the second accent color
  /// - "ACCENT3" : Represents the third accent color
  /// - "ACCENT4" : Represents the fourth accent color
  /// - "ACCENT5" : Represents the fifth accent color
  /// - "ACCENT6" : Represents the sixth accent color
  /// - "LINK" : Represents the color to use for hyperlinks
  core.String? colorType;

  ThemeColorPair();

  ThemeColorPair.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color = ColorStyle.fromJson(
          _json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('colorType')) {
      colorType = _json['colorType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
        if (colorType != null) 'colorType': colorType!,
      };
}

/// Represents a time of day.
///
/// The date and time zone are either not significant or are specified
/// elsewhere. An API may choose to allow leap seconds. Related types are
/// google.type.Date and `google.protobuf.Timestamp`.
class TimeOfDay {
  /// Hours of day in 24 hour format.
  ///
  /// Should be from 0 to 23. An API may choose to allow the value "24:00:00"
  /// for scenarios like business closing time.
  core.int? hours;

  /// Minutes of hour of day.
  ///
  /// Must be from 0 to 59.
  core.int? minutes;

  /// Fractions of seconds in nanoseconds.
  ///
  /// Must be from 0 to 999,999,999.
  core.int? nanos;

  /// Seconds of minutes of the time.
  ///
  /// Must normally be from 0 to 59. An API may allow the value 60 if it allows
  /// leap-seconds.
  core.int? seconds;

  TimeOfDay();

  TimeOfDay.fromJson(core.Map _json) {
    if (_json.containsKey('hours')) {
      hours = _json['hours'] as core.int;
    }
    if (_json.containsKey('minutes')) {
      minutes = _json['minutes'] as core.int;
    }
    if (_json.containsKey('nanos')) {
      nanos = _json['nanos'] as core.int;
    }
    if (_json.containsKey('seconds')) {
      seconds = _json['seconds'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hours != null) 'hours': hours!,
        if (minutes != null) 'minutes': minutes!,
        if (nanos != null) 'nanos': nanos!,
        if (seconds != null) 'seconds': seconds!,
      };
}

/// A color scale for a treemap chart.
class TreemapChartColorScale {
  /// The background color for cells with a color value greater than or equal to
  /// maxValue.
  ///
  /// Defaults to #109618 if not specified.
  Color? maxValueColor;

  /// The background color for cells with a color value greater than or equal to
  /// maxValue.
  ///
  /// Defaults to #109618 if not specified. If max_value_color is also set, this
  /// field takes precedence.
  ColorStyle? maxValueColorStyle;

  /// The background color for cells with a color value at the midpoint between
  /// minValue and maxValue.
  ///
  /// Defaults to #efe6dc if not specified.
  Color? midValueColor;

  /// The background color for cells with a color value at the midpoint between
  /// minValue and maxValue.
  ///
  /// Defaults to #efe6dc if not specified. If mid_value_color is also set, this
  /// field takes precedence.
  ColorStyle? midValueColorStyle;

  /// The background color for cells with a color value less than or equal to
  /// minValue.
  ///
  /// Defaults to #dc3912 if not specified.
  Color? minValueColor;

  /// The background color for cells with a color value less than or equal to
  /// minValue.
  ///
  /// Defaults to #dc3912 if not specified. If min_value_color is also set, this
  /// field takes precedence.
  ColorStyle? minValueColorStyle;

  /// The background color for cells that have no color data associated with
  /// them.
  ///
  /// Defaults to #000000 if not specified.
  Color? noDataColor;

  /// The background color for cells that have no color data associated with
  /// them.
  ///
  /// Defaults to #000000 if not specified. If no_data_color is also set, this
  /// field takes precedence.
  ColorStyle? noDataColorStyle;

  TreemapChartColorScale();

  TreemapChartColorScale.fromJson(core.Map _json) {
    if (_json.containsKey('maxValueColor')) {
      maxValueColor = Color.fromJson(
          _json['maxValueColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('maxValueColorStyle')) {
      maxValueColorStyle = ColorStyle.fromJson(
          _json['maxValueColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('midValueColor')) {
      midValueColor = Color.fromJson(
          _json['midValueColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('midValueColorStyle')) {
      midValueColorStyle = ColorStyle.fromJson(
          _json['midValueColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('minValueColor')) {
      minValueColor = Color.fromJson(
          _json['minValueColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('minValueColorStyle')) {
      minValueColorStyle = ColorStyle.fromJson(
          _json['minValueColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('noDataColor')) {
      noDataColor = Color.fromJson(
          _json['noDataColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('noDataColorStyle')) {
      noDataColorStyle = ColorStyle.fromJson(
          _json['noDataColorStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maxValueColor != null) 'maxValueColor': maxValueColor!.toJson(),
        if (maxValueColorStyle != null)
          'maxValueColorStyle': maxValueColorStyle!.toJson(),
        if (midValueColor != null) 'midValueColor': midValueColor!.toJson(),
        if (midValueColorStyle != null)
          'midValueColorStyle': midValueColorStyle!.toJson(),
        if (minValueColor != null) 'minValueColor': minValueColor!.toJson(),
        if (minValueColorStyle != null)
          'minValueColorStyle': minValueColorStyle!.toJson(),
        if (noDataColor != null) 'noDataColor': noDataColor!.toJson(),
        if (noDataColorStyle != null)
          'noDataColorStyle': noDataColorStyle!.toJson(),
      };
}

/// A Treemap chart.
class TreemapChartSpec {
  /// The data that determines the background color of each treemap data cell.
  ///
  /// This field is optional. If not specified, size_data is used to determine
  /// background colors. If specified, the data is expected to be numeric.
  /// color_scale will determine how the values in this data map to data cell
  /// background colors.
  ChartData? colorData;

  /// The color scale for data cells in the treemap chart.
  ///
  /// Data cells are assigned colors based on their color values. These color
  /// values come from color_data, or from size_data if color_data is not
  /// specified. Cells with color values less than or equal to min_value will
  /// have minValueColor as their background color. Cells with color values
  /// greater than or equal to max_value will have maxValueColor as their
  /// background color. Cells with color values between min_value and max_value
  /// will have background colors on a gradient between minValueColor and
  /// maxValueColor, the midpoint of the gradient being midValueColor. Cells
  /// with missing or non-numeric color values will have noDataColor as their
  /// background color.
  TreemapChartColorScale? colorScale;

  /// The background color for header cells.
  Color? headerColor;

  /// The background color for header cells.
  ///
  /// If header_color is also set, this field takes precedence.
  ColorStyle? headerColorStyle;

  /// True to hide tooltips.
  core.bool? hideTooltips;

  /// The number of additional data levels beyond the labeled levels to be shown
  /// on the treemap chart.
  ///
  /// These levels are not interactive and are shown without their labels.
  /// Defaults to 0 if not specified.
  core.int? hintedLevels;

  /// The data that contains the treemap cell labels.
  ChartData? labels;

  /// The number of data levels to show on the treemap chart.
  ///
  /// These levels are interactive and are shown with their labels. Defaults to
  /// 2 if not specified.
  core.int? levels;

  /// The maximum possible data value.
  ///
  /// Cells with values greater than this will have the same color as cells with
  /// this value. If not specified, defaults to the actual maximum value from
  /// color_data, or the maximum value from size_data if color_data is not
  /// specified.
  core.double? maxValue;

  /// The minimum possible data value.
  ///
  /// Cells with values less than this will have the same color as cells with
  /// this value. If not specified, defaults to the actual minimum value from
  /// color_data, or the minimum value from size_data if color_data is not
  /// specified.
  core.double? minValue;

  /// The data the contains the treemap cells' parent labels.
  ChartData? parentLabels;

  /// The data that determines the size of each treemap data cell.
  ///
  /// This data is expected to be numeric. The cells corresponding to
  /// non-numeric or missing data will not be rendered. If color_data is not
  /// specified, this data is used to determine data cell background colors as
  /// well.
  ChartData? sizeData;

  /// The text format for all labels on the chart.
  ///
  /// The link field is not supported.
  TextFormat? textFormat;

  TreemapChartSpec();

  TreemapChartSpec.fromJson(core.Map _json) {
    if (_json.containsKey('colorData')) {
      colorData = ChartData.fromJson(
          _json['colorData'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('colorScale')) {
      colorScale = TreemapChartColorScale.fromJson(
          _json['colorScale'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('headerColor')) {
      headerColor = Color.fromJson(
          _json['headerColor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('headerColorStyle')) {
      headerColorStyle = ColorStyle.fromJson(
          _json['headerColorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hideTooltips')) {
      hideTooltips = _json['hideTooltips'] as core.bool;
    }
    if (_json.containsKey('hintedLevels')) {
      hintedLevels = _json['hintedLevels'] as core.int;
    }
    if (_json.containsKey('labels')) {
      labels = ChartData.fromJson(
          _json['labels'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('levels')) {
      levels = _json['levels'] as core.int;
    }
    if (_json.containsKey('maxValue')) {
      maxValue = (_json['maxValue'] as core.num).toDouble();
    }
    if (_json.containsKey('minValue')) {
      minValue = (_json['minValue'] as core.num).toDouble();
    }
    if (_json.containsKey('parentLabels')) {
      parentLabels = ChartData.fromJson(
          _json['parentLabels'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sizeData')) {
      sizeData = ChartData.fromJson(
          _json['sizeData'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textFormat')) {
      textFormat = TextFormat.fromJson(
          _json['textFormat'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (colorData != null) 'colorData': colorData!.toJson(),
        if (colorScale != null) 'colorScale': colorScale!.toJson(),
        if (headerColor != null) 'headerColor': headerColor!.toJson(),
        if (headerColorStyle != null)
          'headerColorStyle': headerColorStyle!.toJson(),
        if (hideTooltips != null) 'hideTooltips': hideTooltips!,
        if (hintedLevels != null) 'hintedLevels': hintedLevels!,
        if (labels != null) 'labels': labels!.toJson(),
        if (levels != null) 'levels': levels!,
        if (maxValue != null) 'maxValue': maxValue!,
        if (minValue != null) 'minValue': minValue!,
        if (parentLabels != null) 'parentLabels': parentLabels!.toJson(),
        if (sizeData != null) 'sizeData': sizeData!.toJson(),
        if (textFormat != null) 'textFormat': textFormat!.toJson(),
      };
}

/// Trims the whitespace (such as spaces, tabs, or new lines) in every cell in
/// the specified range.
///
/// This request removes all whitespace from the start and end of each cell's
/// text, and reduces any subsequence of remaining whitespace characters to a
/// single space. If the resulting trimmed text starts with a '+' or '='
/// character, the text remains as a string value and isn't interpreted as a
/// formula.
class TrimWhitespaceRequest {
  /// The range whose cells to trim.
  GridRange? range;

  TrimWhitespaceRequest();

  TrimWhitespaceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
      };
}

/// The result of trimming whitespace in cells.
class TrimWhitespaceResponse {
  /// The number of cells that were trimmed of whitespace.
  core.int? cellsChangedCount;

  TrimWhitespaceResponse();

  TrimWhitespaceResponse.fromJson(core.Map _json) {
    if (_json.containsKey('cellsChangedCount')) {
      cellsChangedCount = _json['cellsChangedCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cellsChangedCount != null) 'cellsChangedCount': cellsChangedCount!,
      };
}

/// Unmerges cells in the given range.
class UnmergeCellsRequest {
  /// The range within which all cells should be unmerged.
  ///
  /// If the range spans multiple merges, all will be unmerged. The range must
  /// not partially span any merge.
  GridRange? range;

  UnmergeCellsRequest();

  UnmergeCellsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!.toJson(),
      };
}

/// Updates properties of the supplied banded range.
class UpdateBandingRequest {
  /// The banded range to update with the new properties.
  BandedRange? bandedRange;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `bandedRange` is implied
  /// and should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field.
  core.String? fields;

  UpdateBandingRequest();

  UpdateBandingRequest.fromJson(core.Map _json) {
    if (_json.containsKey('bandedRange')) {
      bandedRange = BandedRange.fromJson(
          _json['bandedRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bandedRange != null) 'bandedRange': bandedRange!.toJson(),
        if (fields != null) 'fields': fields!,
      };
}

/// Updates the borders of a range.
///
/// If a field is not set in the request, that means the border remains as-is.
/// For example, with two subsequent UpdateBordersRequest: 1. range: A1:A5 `{
/// top: RED, bottom: WHITE }` 2. range: A1:A5 `{ left: BLUE }` That would
/// result in A1:A5 having a borders of `{ top: RED, bottom: WHITE, left: BLUE
/// }`. If you want to clear a border, explicitly set the style to NONE.
class UpdateBordersRequest {
  /// The border to put at the bottom of the range.
  Border? bottom;

  /// The horizontal border to put within the range.
  Border? innerHorizontal;

  /// The vertical border to put within the range.
  Border? innerVertical;

  /// The border to put at the left of the range.
  Border? left;

  /// The range whose borders should be updated.
  GridRange? range;

  /// The border to put at the right of the range.
  Border? right;

  /// The border to put at the top of the range.
  Border? top;

  UpdateBordersRequest();

  UpdateBordersRequest.fromJson(core.Map _json) {
    if (_json.containsKey('bottom')) {
      bottom = Border.fromJson(
          _json['bottom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('innerHorizontal')) {
      innerHorizontal = Border.fromJson(
          _json['innerHorizontal'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('innerVertical')) {
      innerVertical = Border.fromJson(
          _json['innerVertical'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('left')) {
      left =
          Border.fromJson(_json['left'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('right')) {
      right = Border.fromJson(
          _json['right'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('top')) {
      top =
          Border.fromJson(_json['top'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bottom != null) 'bottom': bottom!.toJson(),
        if (innerHorizontal != null)
          'innerHorizontal': innerHorizontal!.toJson(),
        if (innerVertical != null) 'innerVertical': innerVertical!.toJson(),
        if (left != null) 'left': left!.toJson(),
        if (range != null) 'range': range!.toJson(),
        if (right != null) 'right': right!.toJson(),
        if (top != null) 'top': top!.toJson(),
      };
}

/// Updates all cells in a range with new data.
class UpdateCellsRequest {
  /// The fields of CellData that should be updated.
  ///
  /// At least one field must be specified. The root is the CellData;
  /// 'row.values.' should not be specified. A single `"*"` can be used as
  /// short-hand for listing every field.
  core.String? fields;

  /// The range to write data to.
  ///
  /// If the data in rows does not cover the entire requested range, the fields
  /// matching those set in fields will be cleared.
  GridRange? range;

  /// The data to write.
  core.List<RowData>? rows;

  /// The coordinate to start writing data at.
  ///
  /// Any number of rows and columns (including a different number of columns
  /// per row) may be written.
  GridCoordinate? start;

  UpdateCellsRequest();

  UpdateCellsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('range')) {
      range = GridRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<RowData>((value) =>
              RowData.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('start')) {
      start = GridCoordinate.fromJson(
          _json['start'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (range != null) 'range': range!.toJson(),
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
        if (start != null) 'start': start!.toJson(),
      };
}

/// Updates a chart's specifications.
///
/// (This does not move or resize a chart. To move or resize a chart, use
/// UpdateEmbeddedObjectPositionRequest.)
class UpdateChartSpecRequest {
  /// The ID of the chart to update.
  core.int? chartId;

  /// The specification to apply to the chart.
  ChartSpec? spec;

  UpdateChartSpecRequest();

  UpdateChartSpecRequest.fromJson(core.Map _json) {
    if (_json.containsKey('chartId')) {
      chartId = _json['chartId'] as core.int;
    }
    if (_json.containsKey('spec')) {
      spec = ChartSpec.fromJson(
          _json['spec'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chartId != null) 'chartId': chartId!,
        if (spec != null) 'spec': spec!.toJson(),
      };
}

/// Updates a conditional format rule at the given index, or moves a conditional
/// format rule to another index.
class UpdateConditionalFormatRuleRequest {
  /// The zero-based index of the rule that should be replaced or moved.
  core.int? index;

  /// The zero-based new index the rule should end up at.
  core.int? newIndex;

  /// The rule that should replace the rule at the given index.
  ConditionalFormatRule? rule;

  /// The sheet of the rule to move.
  ///
  /// Required if new_index is set, unused otherwise.
  core.int? sheetId;

  UpdateConditionalFormatRuleRequest();

  UpdateConditionalFormatRuleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('index')) {
      index = _json['index'] as core.int;
    }
    if (_json.containsKey('newIndex')) {
      newIndex = _json['newIndex'] as core.int;
    }
    if (_json.containsKey('rule')) {
      rule = ConditionalFormatRule.fromJson(
          _json['rule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sheetId')) {
      sheetId = _json['sheetId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (index != null) 'index': index!,
        if (newIndex != null) 'newIndex': newIndex!,
        if (rule != null) 'rule': rule!.toJson(),
        if (sheetId != null) 'sheetId': sheetId!,
      };
}

/// The result of updating a conditional format rule.
class UpdateConditionalFormatRuleResponse {
  /// The index of the new rule.
  core.int? newIndex;

  /// The new rule that replaced the old rule (if replacing), or the rule that
  /// was moved (if moved)
  ConditionalFormatRule? newRule;

  /// The old index of the rule.
  ///
  /// Not set if a rule was replaced (because it is the same as new_index).
  core.int? oldIndex;

  /// The old (deleted) rule.
  ///
  /// Not set if a rule was moved (because it is the same as new_rule).
  ConditionalFormatRule? oldRule;

  UpdateConditionalFormatRuleResponse();

  UpdateConditionalFormatRuleResponse.fromJson(core.Map _json) {
    if (_json.containsKey('newIndex')) {
      newIndex = _json['newIndex'] as core.int;
    }
    if (_json.containsKey('newRule')) {
      newRule = ConditionalFormatRule.fromJson(
          _json['newRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('oldIndex')) {
      oldIndex = _json['oldIndex'] as core.int;
    }
    if (_json.containsKey('oldRule')) {
      oldRule = ConditionalFormatRule.fromJson(
          _json['oldRule'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (newIndex != null) 'newIndex': newIndex!,
        if (newRule != null) 'newRule': newRule!.toJson(),
        if (oldIndex != null) 'oldIndex': oldIndex!,
        if (oldRule != null) 'oldRule': oldRule!.toJson(),
      };
}

/// Updates a data source.
///
/// After the data source is updated successfully, an execution is triggered to
/// refresh the associated DATA_SOURCE sheet to read data from the updated data
/// source. The request requires an additional `bigquery.readonly` OAuth scope.
class UpdateDataSourceRequest {
  /// The data source to update.
  DataSource? dataSource;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `dataSource` is implied and
  /// should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field.
  core.String? fields;

  UpdateDataSourceRequest();

  UpdateDataSourceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataSource')) {
      dataSource = DataSource.fromJson(
          _json['dataSource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSource != null) 'dataSource': dataSource!.toJson(),
        if (fields != null) 'fields': fields!,
      };
}

/// The response from updating data source.
class UpdateDataSourceResponse {
  /// The data execution status.
  DataExecutionStatus? dataExecutionStatus;

  /// The updated data source.
  DataSource? dataSource;

  UpdateDataSourceResponse();

  UpdateDataSourceResponse.fromJson(core.Map _json) {
    if (_json.containsKey('dataExecutionStatus')) {
      dataExecutionStatus = DataExecutionStatus.fromJson(
          _json['dataExecutionStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataSource')) {
      dataSource = DataSource.fromJson(
          _json['dataSource'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataExecutionStatus != null)
          'dataExecutionStatus': dataExecutionStatus!.toJson(),
        if (dataSource != null) 'dataSource': dataSource!.toJson(),
      };
}

/// A request to update properties of developer metadata.
///
/// Updates the properties of the developer metadata selected by the filters to
/// the values provided in the DeveloperMetadata resource. Callers must specify
/// the properties they wish to update in the fields parameter, as well as
/// specify at least one DataFilter matching the metadata they wish to update.
class UpdateDeveloperMetadataRequest {
  /// The filters matching the developer metadata entries to update.
  core.List<DataFilter>? dataFilters;

  /// The value that all metadata matched by the data filters will be updated
  /// to.
  DeveloperMetadata? developerMetadata;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `developerMetadata` is
  /// implied and should not be specified. A single `"*"` can be used as
  /// short-hand for listing every field.
  core.String? fields;

  UpdateDeveloperMetadataRequest();

  UpdateDeveloperMetadataRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataFilters')) {
      dataFilters = (_json['dataFilters'] as core.List)
          .map<DataFilter>((value) =>
              DataFilter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('developerMetadata')) {
      developerMetadata = DeveloperMetadata.fromJson(
          _json['developerMetadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataFilters != null)
          'dataFilters': dataFilters!.map((value) => value.toJson()).toList(),
        if (developerMetadata != null)
          'developerMetadata': developerMetadata!.toJson(),
        if (fields != null) 'fields': fields!,
      };
}

/// The response from updating developer metadata.
class UpdateDeveloperMetadataResponse {
  /// The updated developer metadata.
  core.List<DeveloperMetadata>? developerMetadata;

  UpdateDeveloperMetadataResponse();

  UpdateDeveloperMetadataResponse.fromJson(core.Map _json) {
    if (_json.containsKey('developerMetadata')) {
      developerMetadata = (_json['developerMetadata'] as core.List)
          .map<DeveloperMetadata>((value) => DeveloperMetadata.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (developerMetadata != null)
          'developerMetadata':
              developerMetadata!.map((value) => value.toJson()).toList(),
      };
}

/// Updates the state of the specified group.
class UpdateDimensionGroupRequest {
  /// The group whose state should be updated.
  ///
  /// The range and depth of the group should specify a valid group on the
  /// sheet, and all other fields updated.
  DimensionGroup? dimensionGroup;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `dimensionGroup` is implied
  /// and should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field.
  core.String? fields;

  UpdateDimensionGroupRequest();

  UpdateDimensionGroupRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionGroup')) {
      dimensionGroup = DimensionGroup.fromJson(
          _json['dimensionGroup'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionGroup != null) 'dimensionGroup': dimensionGroup!.toJson(),
        if (fields != null) 'fields': fields!,
      };
}

/// Updates properties of dimensions within the specified range.
class UpdateDimensionPropertiesRequest {
  /// The columns on a data source sheet to update.
  DataSourceSheetDimensionRange? dataSourceSheetRange;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `properties` is implied and
  /// should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field.
  core.String? fields;

  /// Properties to update.
  DimensionProperties? properties;

  /// The rows or columns to update.
  DimensionRange? range;

  UpdateDimensionPropertiesRequest();

  UpdateDimensionPropertiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceSheetRange')) {
      dataSourceSheetRange = DataSourceSheetDimensionRange.fromJson(
          _json['dataSourceSheetRange'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('properties')) {
      properties = DimensionProperties.fromJson(
          _json['properties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('range')) {
      range = DimensionRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceSheetRange != null)
          'dataSourceSheetRange': dataSourceSheetRange!.toJson(),
        if (fields != null) 'fields': fields!,
        if (properties != null) 'properties': properties!.toJson(),
        if (range != null) 'range': range!.toJson(),
      };
}

/// Updates an embedded object's border property.
class UpdateEmbeddedObjectBorderRequest {
  /// The border that applies to the embedded object.
  EmbeddedObjectBorder? border;

  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `border` is implied and
  /// should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field.
  core.String? fields;

  /// The ID of the embedded object to update.
  core.int? objectId;

  UpdateEmbeddedObjectBorderRequest();

  UpdateEmbeddedObjectBorderRequest.fromJson(core.Map _json) {
    if (_json.containsKey('border')) {
      border = EmbeddedObjectBorder.fromJson(
          _json['border'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (border != null) 'border': border!.toJson(),
        if (fields != null) 'fields': fields!,
        if (objectId != null) 'objectId': objectId!,
      };
}

/// Update an embedded object's position (such as a moving or resizing a chart
/// or image).
class UpdateEmbeddedObjectPositionRequest {
  /// The fields of OverlayPosition that should be updated when setting a new
  /// position.
  ///
  /// Used only if newPosition.overlayPosition is set, in which case at least
  /// one field must be specified. The root `newPosition.overlayPosition` is
  /// implied and should not be specified. A single `"*"` can be used as
  /// short-hand for listing every field.
  core.String? fields;

  /// An explicit position to move the embedded object to.
  ///
  /// If newPosition.sheetId is set, a new sheet with that ID will be created.
  /// If newPosition.newSheet is set to true, a new sheet will be created with
  /// an ID that will be chosen for you.
  EmbeddedObjectPosition? newPosition;

  /// The ID of the object to moved.
  core.int? objectId;

  UpdateEmbeddedObjectPositionRequest();

  UpdateEmbeddedObjectPositionRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('newPosition')) {
      newPosition = EmbeddedObjectPosition.fromJson(
          _json['newPosition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectId')) {
      objectId = _json['objectId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (newPosition != null) 'newPosition': newPosition!.toJson(),
        if (objectId != null) 'objectId': objectId!,
      };
}

/// The result of updating an embedded object's position.
class UpdateEmbeddedObjectPositionResponse {
  /// The new position of the embedded object.
  EmbeddedObjectPosition? position;

  UpdateEmbeddedObjectPositionResponse();

  UpdateEmbeddedObjectPositionResponse.fromJson(core.Map _json) {
    if (_json.containsKey('position')) {
      position = EmbeddedObjectPosition.fromJson(
          _json['position'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (position != null) 'position': position!.toJson(),
      };
}

/// Updates properties of the filter view.
class UpdateFilterViewRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `filter` is implied and
  /// should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field.
  core.String? fields;

  /// The new properties of the filter view.
  FilterView? filter;

  UpdateFilterViewRequest();

  UpdateFilterViewRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('filter')) {
      filter = FilterView.fromJson(
          _json['filter'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (filter != null) 'filter': filter!.toJson(),
      };
}

/// Updates properties of the named range with the specified namedRangeId.
class UpdateNamedRangeRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `namedRange` is implied and
  /// should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field.
  core.String? fields;

  /// The named range to update with the new properties.
  NamedRange? namedRange;

  UpdateNamedRangeRequest();

  UpdateNamedRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('namedRange')) {
      namedRange = NamedRange.fromJson(
          _json['namedRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (namedRange != null) 'namedRange': namedRange!.toJson(),
      };
}

/// Updates an existing protected range with the specified protectedRangeId.
class UpdateProtectedRangeRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `protectedRange` is implied
  /// and should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field.
  core.String? fields;

  /// The protected range to update with the new properties.
  ProtectedRange? protectedRange;

  UpdateProtectedRangeRequest();

  UpdateProtectedRangeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('protectedRange')) {
      protectedRange = ProtectedRange.fromJson(
          _json['protectedRange'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (protectedRange != null) 'protectedRange': protectedRange!.toJson(),
      };
}

/// Updates properties of the sheet with the specified sheetId.
class UpdateSheetPropertiesRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root `properties` is implied and
  /// should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field.
  core.String? fields;

  /// The properties to update.
  SheetProperties? properties;

  UpdateSheetPropertiesRequest();

  UpdateSheetPropertiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('properties')) {
      properties = SheetProperties.fromJson(
          _json['properties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (properties != null) 'properties': properties!.toJson(),
      };
}

/// Updates a slicer's specifications.
///
/// (This does not move or resize a slicer. To move or resize a slicer use
/// UpdateEmbeddedObjectPositionRequest.
class UpdateSlicerSpecRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root \`SlicerSpec\` is implied
  /// and should not be specified. A single "*"\` can be used as short-hand for
  /// listing every field.
  core.String? fields;

  /// The id of the slicer to update.
  core.int? slicerId;

  /// The specification to apply to the slicer.
  SlicerSpec? spec;

  UpdateSlicerSpecRequest();

  UpdateSlicerSpecRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('slicerId')) {
      slicerId = _json['slicerId'] as core.int;
    }
    if (_json.containsKey('spec')) {
      spec = SlicerSpec.fromJson(
          _json['spec'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (slicerId != null) 'slicerId': slicerId!,
        if (spec != null) 'spec': spec!.toJson(),
      };
}

/// Updates properties of a spreadsheet.
class UpdateSpreadsheetPropertiesRequest {
  /// The fields that should be updated.
  ///
  /// At least one field must be specified. The root 'properties' is implied and
  /// should not be specified. A single `"*"` can be used as short-hand for
  /// listing every field.
  core.String? fields;

  /// The properties to update.
  SpreadsheetProperties? properties;

  UpdateSpreadsheetPropertiesRequest();

  UpdateSpreadsheetPropertiesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = _json['fields'] as core.String;
    }
    if (_json.containsKey('properties')) {
      properties = SpreadsheetProperties.fromJson(
          _json['properties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
        if (properties != null) 'properties': properties!.toJson(),
      };
}

/// The response when updating a range of values by a data filter in a
/// spreadsheet.
class UpdateValuesByDataFilterResponse {
  /// The data filter that selected the range that was updated.
  DataFilter? dataFilter;

  /// The number of cells updated.
  core.int? updatedCells;

  /// The number of columns where at least one cell in the column was updated.
  core.int? updatedColumns;

  /// The values of the cells in the range matched by the dataFilter after all
  /// updates were applied.
  ///
  /// This is only included if the request's `includeValuesInResponse` field was
  /// `true`.
  ValueRange? updatedData;

  /// The range (in A1 notation) that updates were applied to.
  core.String? updatedRange;

  /// The number of rows where at least one cell in the row was updated.
  core.int? updatedRows;

  UpdateValuesByDataFilterResponse();

  UpdateValuesByDataFilterResponse.fromJson(core.Map _json) {
    if (_json.containsKey('dataFilter')) {
      dataFilter = DataFilter.fromJson(
          _json['dataFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updatedCells')) {
      updatedCells = _json['updatedCells'] as core.int;
    }
    if (_json.containsKey('updatedColumns')) {
      updatedColumns = _json['updatedColumns'] as core.int;
    }
    if (_json.containsKey('updatedData')) {
      updatedData = ValueRange.fromJson(
          _json['updatedData'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updatedRange')) {
      updatedRange = _json['updatedRange'] as core.String;
    }
    if (_json.containsKey('updatedRows')) {
      updatedRows = _json['updatedRows'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataFilter != null) 'dataFilter': dataFilter!.toJson(),
        if (updatedCells != null) 'updatedCells': updatedCells!,
        if (updatedColumns != null) 'updatedColumns': updatedColumns!,
        if (updatedData != null) 'updatedData': updatedData!.toJson(),
        if (updatedRange != null) 'updatedRange': updatedRange!,
        if (updatedRows != null) 'updatedRows': updatedRows!,
      };
}

/// The response when updating a range of values in a spreadsheet.
class UpdateValuesResponse {
  /// The spreadsheet the updates were applied to.
  core.String? spreadsheetId;

  /// The number of cells updated.
  core.int? updatedCells;

  /// The number of columns where at least one cell in the column was updated.
  core.int? updatedColumns;

  /// The values of the cells after updates were applied.
  ///
  /// This is only included if the request's `includeValuesInResponse` field was
  /// `true`.
  ValueRange? updatedData;

  /// The range (in A1 notation) that updates were applied to.
  core.String? updatedRange;

  /// The number of rows where at least one cell in the row was updated.
  core.int? updatedRows;

  UpdateValuesResponse();

  UpdateValuesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('spreadsheetId')) {
      spreadsheetId = _json['spreadsheetId'] as core.String;
    }
    if (_json.containsKey('updatedCells')) {
      updatedCells = _json['updatedCells'] as core.int;
    }
    if (_json.containsKey('updatedColumns')) {
      updatedColumns = _json['updatedColumns'] as core.int;
    }
    if (_json.containsKey('updatedData')) {
      updatedData = ValueRange.fromJson(
          _json['updatedData'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updatedRange')) {
      updatedRange = _json['updatedRange'] as core.String;
    }
    if (_json.containsKey('updatedRows')) {
      updatedRows = _json['updatedRows'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (spreadsheetId != null) 'spreadsheetId': spreadsheetId!,
        if (updatedCells != null) 'updatedCells': updatedCells!,
        if (updatedColumns != null) 'updatedColumns': updatedColumns!,
        if (updatedData != null) 'updatedData': updatedData!.toJson(),
        if (updatedRange != null) 'updatedRange': updatedRange!,
        if (updatedRows != null) 'updatedRows': updatedRows!,
      };
}

/// Data within a range of the spreadsheet.
class ValueRange {
  /// The major dimension of the values.
  ///
  /// For output, if the spreadsheet data is: `A1=1,B1=2,A2=3,B2=4`, then
  /// requesting `range=A1:B2,majorDimension=ROWS` will return `[[1,2],[3,4]]`,
  /// whereas requesting `range=A1:B2,majorDimension=COLUMNS` will return
  /// `[[1,3],[2,4]]`. For input, with `range=A1:B2,majorDimension=ROWS` then
  /// `[[1,2],[3,4]]` will set `A1=1,B1=2,A2=3,B2=4`. With
  /// `range=A1:B2,majorDimension=COLUMNS` then `[[1,2],[3,4]]` will set
  /// `A1=1,B1=3,A2=2,B2=4`. When writing, if this field is not set, it defaults
  /// to ROWS.
  /// Possible string values are:
  /// - "DIMENSION_UNSPECIFIED" : The default value, do not use.
  /// - "ROWS" : Operates on the rows of a sheet.
  /// - "COLUMNS" : Operates on the columns of a sheet.
  core.String? majorDimension;

  /// The range the values cover, in A1 notation.
  ///
  /// For output, this range indicates the entire requested range, even though
  /// the values will exclude trailing rows and columns. When appending values,
  /// this field represents the range to search for a table, after which values
  /// will be appended.
  core.String? range;

  /// The data that was read or to be written.
  ///
  /// This is an array of arrays, the outer array representing all the data and
  /// each inner array representing a major dimension. Each item in the inner
  /// array corresponds with one cell. For output, empty trailing rows and
  /// columns will not be included. For input, supported value types are: bool,
  /// string, and double. Null values will be skipped. To set a cell to an empty
  /// value, set the string value to an empty string.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.List<core.Object>>? values;

  ValueRange();

  ValueRange.fromJson(core.Map _json) {
    if (_json.containsKey('majorDimension')) {
      majorDimension = _json['majorDimension'] as core.String;
    }
    if (_json.containsKey('range')) {
      range = _json['range'] as core.String;
    }
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.List<core.Object>>((value) => (value as core.List)
              .map<core.Object>((value) => value as core.Object)
              .toList())
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (majorDimension != null) 'majorDimension': majorDimension!,
        if (range != null) 'range': range!,
        if (values != null) 'values': values!,
      };
}

/// Styles for a waterfall chart column.
class WaterfallChartColumnStyle {
  /// The color of the column.
  Color? color;

  /// The color of the column.
  ///
  /// If color is also set, this field takes precedence.
  ColorStyle? colorStyle;

  /// The label of the column's legend.
  core.String? label;

  WaterfallChartColumnStyle();

  WaterfallChartColumnStyle.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color =
          Color.fromJson(_json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('colorStyle')) {
      colorStyle = ColorStyle.fromJson(
          _json['colorStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('label')) {
      label = _json['label'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
        if (colorStyle != null) 'colorStyle': colorStyle!.toJson(),
        if (label != null) 'label': label!,
      };
}

/// A custom subtotal column for a waterfall chart series.
class WaterfallChartCustomSubtotal {
  /// True if the data point at subtotal_index is the subtotal.
  ///
  /// If false, the subtotal will be computed and appear after the data point.
  core.bool? dataIsSubtotal;

  /// A label for the subtotal column.
  core.String? label;

  /// The 0-based index of a data point within the series.
  ///
  /// If data_is_subtotal is true, the data point at this index is the subtotal.
  /// Otherwise, the subtotal appears after the data point with this index. A
  /// series can have multiple subtotals at arbitrary indices, but subtotals do
  /// not affect the indices of the data points. For example, if a series has
  /// three data points, their indices will always be 0, 1, and 2, regardless of
  /// how many subtotals exist on the series or what data points they are
  /// associated with.
  core.int? subtotalIndex;

  WaterfallChartCustomSubtotal();

  WaterfallChartCustomSubtotal.fromJson(core.Map _json) {
    if (_json.containsKey('dataIsSubtotal')) {
      dataIsSubtotal = _json['dataIsSubtotal'] as core.bool;
    }
    if (_json.containsKey('label')) {
      label = _json['label'] as core.String;
    }
    if (_json.containsKey('subtotalIndex')) {
      subtotalIndex = _json['subtotalIndex'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataIsSubtotal != null) 'dataIsSubtotal': dataIsSubtotal!,
        if (label != null) 'label': label!,
        if (subtotalIndex != null) 'subtotalIndex': subtotalIndex!,
      };
}

/// The domain of a waterfall chart.
class WaterfallChartDomain {
  /// The data of the WaterfallChartDomain.
  ChartData? data;

  /// True to reverse the order of the domain values (horizontal axis).
  core.bool? reversed;

  WaterfallChartDomain();

  WaterfallChartDomain.fromJson(core.Map _json) {
    if (_json.containsKey('data')) {
      data = ChartData.fromJson(
          _json['data'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reversed')) {
      reversed = _json['reversed'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (data != null) 'data': data!.toJson(),
        if (reversed != null) 'reversed': reversed!,
      };
}

/// A single series of data for a waterfall chart.
class WaterfallChartSeries {
  /// Custom subtotal columns appearing in this series.
  ///
  /// The order in which subtotals are defined is not significant. Only one
  /// subtotal may be defined for each data point.
  core.List<WaterfallChartCustomSubtotal>? customSubtotals;

  /// The data being visualized in this series.
  ChartData? data;

  /// Information about the data labels for this series.
  DataLabel? dataLabel;

  /// True to hide the subtotal column from the end of the series.
  ///
  /// By default, a subtotal column will appear at the end of each series.
  /// Setting this field to true will hide that subtotal column for this series.
  core.bool? hideTrailingSubtotal;

  /// Styles for all columns in this series with negative values.
  WaterfallChartColumnStyle? negativeColumnsStyle;

  /// Styles for all columns in this series with positive values.
  WaterfallChartColumnStyle? positiveColumnsStyle;

  /// Styles for all subtotal columns in this series.
  WaterfallChartColumnStyle? subtotalColumnsStyle;

  WaterfallChartSeries();

  WaterfallChartSeries.fromJson(core.Map _json) {
    if (_json.containsKey('customSubtotals')) {
      customSubtotals = (_json['customSubtotals'] as core.List)
          .map<WaterfallChartCustomSubtotal>((value) =>
              WaterfallChartCustomSubtotal.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('data')) {
      data = ChartData.fromJson(
          _json['data'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataLabel')) {
      dataLabel = DataLabel.fromJson(
          _json['dataLabel'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hideTrailingSubtotal')) {
      hideTrailingSubtotal = _json['hideTrailingSubtotal'] as core.bool;
    }
    if (_json.containsKey('negativeColumnsStyle')) {
      negativeColumnsStyle = WaterfallChartColumnStyle.fromJson(
          _json['negativeColumnsStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('positiveColumnsStyle')) {
      positiveColumnsStyle = WaterfallChartColumnStyle.fromJson(
          _json['positiveColumnsStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subtotalColumnsStyle')) {
      subtotalColumnsStyle = WaterfallChartColumnStyle.fromJson(
          _json['subtotalColumnsStyle'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customSubtotals != null)
          'customSubtotals':
              customSubtotals!.map((value) => value.toJson()).toList(),
        if (data != null) 'data': data!.toJson(),
        if (dataLabel != null) 'dataLabel': dataLabel!.toJson(),
        if (hideTrailingSubtotal != null)
          'hideTrailingSubtotal': hideTrailingSubtotal!,
        if (negativeColumnsStyle != null)
          'negativeColumnsStyle': negativeColumnsStyle!.toJson(),
        if (positiveColumnsStyle != null)
          'positiveColumnsStyle': positiveColumnsStyle!.toJson(),
        if (subtotalColumnsStyle != null)
          'subtotalColumnsStyle': subtotalColumnsStyle!.toJson(),
      };
}

/// A waterfall chart.
class WaterfallChartSpec {
  /// The line style for the connector lines.
  LineStyle? connectorLineStyle;

  /// The domain data (horizontal axis) for the waterfall chart.
  WaterfallChartDomain? domain;

  /// True to interpret the first value as a total.
  core.bool? firstValueIsTotal;

  /// True to hide connector lines between columns.
  core.bool? hideConnectorLines;

  /// The data this waterfall chart is visualizing.
  core.List<WaterfallChartSeries>? series;

  /// The stacked type.
  /// Possible string values are:
  /// - "WATERFALL_STACKED_TYPE_UNSPECIFIED" : Default value, do not use.
  /// - "STACKED" : Values corresponding to the same domain (horizontal axis)
  /// value will be stacked vertically.
  /// - "SEQUENTIAL" : Series will spread out along the horizontal axis.
  core.String? stackedType;

  /// Controls whether to display additional data labels on stacked charts which
  /// sum the total value of all stacked values at each value along the domain
  /// axis.
  ///
  /// stacked_type must be STACKED and neither CUSTOM nor placement can be set
  /// on the total_data_label.
  DataLabel? totalDataLabel;

  WaterfallChartSpec();

  WaterfallChartSpec.fromJson(core.Map _json) {
    if (_json.containsKey('connectorLineStyle')) {
      connectorLineStyle = LineStyle.fromJson(
          _json['connectorLineStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('domain')) {
      domain = WaterfallChartDomain.fromJson(
          _json['domain'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('firstValueIsTotal')) {
      firstValueIsTotal = _json['firstValueIsTotal'] as core.bool;
    }
    if (_json.containsKey('hideConnectorLines')) {
      hideConnectorLines = _json['hideConnectorLines'] as core.bool;
    }
    if (_json.containsKey('series')) {
      series = (_json['series'] as core.List)
          .map<WaterfallChartSeries>((value) => WaterfallChartSeries.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('stackedType')) {
      stackedType = _json['stackedType'] as core.String;
    }
    if (_json.containsKey('totalDataLabel')) {
      totalDataLabel = DataLabel.fromJson(
          _json['totalDataLabel'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (connectorLineStyle != null)
          'connectorLineStyle': connectorLineStyle!.toJson(),
        if (domain != null) 'domain': domain!.toJson(),
        if (firstValueIsTotal != null) 'firstValueIsTotal': firstValueIsTotal!,
        if (hideConnectorLines != null)
          'hideConnectorLines': hideConnectorLines!,
        if (series != null)
          'series': series!.map((value) => value.toJson()).toList(),
        if (stackedType != null) 'stackedType': stackedType!,
        if (totalDataLabel != null) 'totalDataLabel': totalDataLabel!.toJson(),
      };
}
