import 'package:github_search/github_api.dart';

// The State represents the data the View requires. The View consumes a Stream
// of States. The view rebuilds every time the Stream emits a new State!
//
// The State Stream will emit new States depending on the situation: The
// initial state, loading states, the list of results, and any errors that
// happen.
//
// The State Stream responds to input from the View by accepting a
// Stream<String>. We call this Stream the onTextChanged "intent".
class SearchState {}

class SearchLoading extends SearchState {}

class SearchError extends SearchState {}

class SearchNoTerm extends SearchState {}

class SearchPopulated extends SearchState {
  final SearchResult result;

  SearchPopulated(this.result);
}

class SearchEmpty extends SearchState {}
