import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'github_api.dart';
import 'search_state.dart';

class SearchBloc {
  final Sink<String> onTextChanged;
  final Stream<SearchState> state;

  factory SearchBloc(GithubApi api) {
    final onTextChanged = PublishSubject<String>();

    final state = onTextChanged
        // If the text has not changed, do not perform a new search
        .distinct()
        // Wait for the user to stop typing for 250ms before running a search
        .debounceTime(const Duration(milliseconds: 250))
        // Call the Github api with the given search term and convert it to a
        // State. If another search term is entered, switchMap will ensure
        // the previous search is discarded so we don't deliver stale results
        // to the View.
        .switchMap<SearchState>((String term) => _search(term, api))
        // The initial state to deliver to the screen.
        .startWith(SearchNoTerm());

    return SearchBloc._(onTextChanged, state);
  }

  SearchBloc._(this.onTextChanged, this.state);

  void dispose() {
    onTextChanged.close();
  }

  static Stream<SearchState> _search(String term, GithubApi api) => term.isEmpty
      ? Stream.value(SearchNoTerm())
      : Rx.fromCallable(() => api.search(term))
          .map((result) =>
              result.isEmpty ? SearchEmpty() : SearchPopulated(result))
          .startWith(SearchLoading())
          .onErrorReturn(SearchError());
}
