import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:rxdart/rxdart.dart';

void main() {
  final searchInput = querySelector('#searchInput');
  final resultsField = querySelector('#resultsField');

  searchInput.onKeyUp
      // return the event target
      .map((event) => event.target)
      // cast the event target as InputElement
      .whereType<InputElement>()
      // Use map() to take the value from the input field
      .map((inputElement) => (inputElement.value))
      // Use distinct() to ignore all keystrokes that don't have an impact on
      // the input field's value (brake, ctrl, shift, ..)
      .distinct()
      // Ensure the term has some value before calling the API
      .where((term) => term.isNotEmpty)
      // Use debounce() to prevent calling the server on fast following
      // keystrokes
      .debounceTime(const Duration(milliseconds: 250))
      // Use doOnData() to clear resultsField
      .doOnData((_) => resultsField.innerHtml = '')
      // Use switchMap to call the gitHub API
      //
      // When a new search term follows a previous term quite fast, it's
      // possible the server is still looking for the previous one. Since
      // we're only interested in the results of the very last search term
      // entered, switchMap will cancel the previous request, and notify use
      // of the last result that comes in. Normal flatMap() would give us all
      // previous results as well.
      .switchMap((term) => Stream.fromFuture(_searchGithubFor(term)))
      .listen((result) => result.forEach((item) => resultsField.innerHtml +=
          "<li>${item['fullName']} (${item['url']})</li>"));
}

Future<List<Map<String, String>>> _searchGithubFor(String term) async {
  if (term.isEmpty) {
    throw ArgumentError('Need to provide a term');
  }

  final request = await HttpRequest.request(
    'https://api.github.com/search/repositories?q=$term',
    requestHeaders: {"Content-Type": "application/json"},
  );
  final List itemList = json.decode(request.responseText)['items'] as List;
  final List<Map<String, dynamic>> items =
      itemList.cast<Map<String, dynamic>>();

  return items.map((item) {
    return {
      "fullName": item['full_name'].toString(),
      "url": item["html_url"].toString()
    };
  }).toList();
}
