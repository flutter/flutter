// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Snapshot from http://www.nasdaq.com/screening/company-list.aspx
// Fetched 2/23/2014.
// "Symbol","Name","LastSale","MarketCap","IPOyear","Sector","industry","Summary Quote",
// Data in stock_data.json

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

final math.Random _rng = new math.Random();

class Stock {
  String symbol;
  String name;
  double lastSale;
  String marketCap;
  double percentChange;

  Stock(this.symbol, this.name, this.lastSale, this.marketCap, this.percentChange);

  Stock.fromFields(List<String> fields) {
    // FIXME: This class should only have static data, not lastSale, etc.
    // "Symbol","Name","LastSale","MarketCap","IPOyear","Sector","industry","Summary Quote",
    lastSale = 0.0;
    try{
      lastSale = double.parse(fields[2]);
    } catch(_) {}
    symbol = fields[0];
    name = fields[1];
    marketCap = fields[4];
    percentChange = (_rng.nextDouble() * 20) - 10;
  }
}

class StockData {
  StockData(this._data);

  final List<List<String>> _data;

  void appendTo(Map<String, Stock> stocks, List<String> symbols) {
    for (List<String> fields in _data) {
      final Stock stock = new Stock.fromFields(fields);
      symbols.add(stock.symbol);
      stocks[stock.symbol] = stock;
    }
    symbols.sort();
  }
}

typedef void StockDataCallback(StockData data);
const int _kChunkCount = 30;

String _urlToFetch(int chunk) {
  return 'https://domokit.github.io/examples/stocks/data/stock_data_$chunk.json';
}

class StockDataFetcher {
  StockDataFetcher(this.callback) {
    _httpClient = createHttpClient();
    _fetchNextChunk();
  }

  final StockDataCallback callback;
  http.Client _httpClient;

  static bool actuallyFetchData = true;

  int _nextChunk = 0;

  void _fetchNextChunk() {
    if (!actuallyFetchData)
      return;
    _httpClient.get(_urlToFetch(_nextChunk++)).then<Null>((http.Response response) {
      final String json = response.body;
      if (json == null) {
        print("Failed to load stock data chunk ${_nextChunk - 1}");
        return null;
      }
      final JsonDecoder decoder = const JsonDecoder();
      callback(new StockData(decoder.convert(json)));
      if (_nextChunk < _kChunkCount)
        _fetchNextChunk();
    });
  }
}
