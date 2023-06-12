import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GithubApi {
  final String baseUrl;
  final Map<String, SearchResult> cache;
  final http.Client client;

  GithubApi({
    http.Client? client,
    Map<String, SearchResult>? cache,
    this.baseUrl = 'https://api.github.com/search/repositories?q=',
  })  : client = client ?? http.Client(),
        cache = cache ?? <String, SearchResult>{};

  /// Search Github for repositories using the given term
  Future<SearchResult> search(String term) async {
    final cached = cache[term];
    if (cached != null) {
      return cached;
    } else {
      final result = await _fetchResults(term);

      cache[term] = result;

      return result;
    }
  }

  Future<SearchResult> _fetchResults(String term) async {
    final response = await client.get(Uri.parse('$baseUrl$term'));
    final results = json.decode(response.body);

    return SearchResult.fromJson(results['items']);
  }
}

class SearchResult {
  final List<SearchResultItem> items;

  SearchResult(this.items);

  factory SearchResult.fromJson(dynamic json) {
    final items = (json as List)
        .map((item) => SearchResultItem.fromJson(item))
        .toList(growable: false);

    return SearchResult(items);
  }

  bool get isPopulated => items.isNotEmpty;

  bool get isEmpty => items.isEmpty;
}

class SearchResultItem {
  final String fullName;
  final String url;
  final String avatarUrl;

  SearchResultItem(this.fullName, this.url, this.avatarUrl);

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      json['full_name'] as String,
      json['html_url'] as String,
      (json['owner'] as Map<String, dynamic>)['avatar_url'] as String,
    );
  }
}
