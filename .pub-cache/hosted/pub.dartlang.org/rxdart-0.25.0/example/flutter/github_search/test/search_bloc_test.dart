import 'dart:async';

import 'package:github_search/github_api.dart';
import 'package:github_search/search_bloc.dart';
import 'package:github_search/search_state.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockGithubApi extends Mock implements GithubApi {}

void main() {
  group('SearchBloc', () {
    test('starts with an initial no term state', () {
      final api = MockGithubApi();
      final bloc = SearchBloc(api);

      expect(
        bloc.state,
        emitsInOrder([noTerm]),
      );
    });

    test('emits a loading state then result state when api call succeeds', () {
      final api = MockGithubApi();
      final bloc = SearchBloc(api);

      when(api.search('T')).thenAnswer(
          (_) async => SearchResult([SearchResultItem('A', 'B', 'C')]));

      scheduleMicrotask(() {
        bloc.onTextChanged.add('T');
      });

      expect(
        bloc.state,
        emitsInOrder([noTerm, loading, populated]),
      );
    });

    test('emits a no term state when user provides an empty search term', () {
      final api = MockGithubApi();
      final bloc = SearchBloc(api);

      scheduleMicrotask(() {
        bloc.onTextChanged.add('');
      });

      expect(
        bloc.state,
        emitsInOrder([noTerm, noTerm]),
      );
    });

    test('emits an empty state when no results are returned', () {
      final api = MockGithubApi();
      final bloc = SearchBloc(api);

      when(api.search('T')).thenAnswer((_) async => SearchResult([]));

      scheduleMicrotask(() {
        bloc.onTextChanged.add('T');
      });

      expect(
        bloc.state,
        emitsInOrder([noTerm, loading, empty]),
      );
    });

    test('throws an error when the backend errors', () {
      final api = MockGithubApi();
      final bloc = SearchBloc(api);

      when(api.search('T')).thenThrow(Exception());

      scheduleMicrotask(() {
        bloc.onTextChanged.add('T');
      });

      expect(
        bloc.state,
        emitsInOrder([noTerm, loading, error]),
      );
    });

    test('closes the stream on dispose', () {
      final api = MockGithubApi();
      final bloc = SearchBloc(api);

      scheduleMicrotask(() {
        bloc.dispose();
      });

      expect(
        bloc.state,
        emitsInOrder([noTerm, emitsDone]),
      );
    });
  });
}

const noTerm = TypeMatcher<SearchNoTerm>();

const loading = TypeMatcher<SearchLoading>();

const empty = TypeMatcher<SearchEmpty>();

const populated = TypeMatcher<SearchPopulated>();

const error = TypeMatcher<SearchError>();
