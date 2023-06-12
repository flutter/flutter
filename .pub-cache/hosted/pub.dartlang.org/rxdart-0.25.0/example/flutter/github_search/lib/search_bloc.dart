import 'dart:async';

import 'package:github_search/github_api.dart';
import 'package:github_search/search_state.dart';
import 'package:rxdart/rxdart.dart';

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
        // State. If another search term is entered, flatMapLatest will ensure
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

  static Stream<SearchState> _search(String term, GithubApi api) async* {
    if (term.isEmpty) {
      yield SearchNoTerm();
    } else {
      yield SearchLoading();

      try {
        final result = await api.search(term);

        if (result.isEmpty) {
          yield SearchEmpty();
        } else {
          yield SearchPopulated(result);
        }
      } catch (e) {
        yield SearchError();
      }
    }
  }
}
