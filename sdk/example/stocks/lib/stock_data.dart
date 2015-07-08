// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:sky/mojo/net/fetch.dart';
import 'package:sky/mojo/asset_bundle.dart';

// Snapshot from http://www.nasdaq.com/screening/company-list.aspx
// Fetched 2/23/2014.
// "Symbol","Name","LastSale","MarketCap","IPOyear","Sector","industry","Summary Quote",
// Data in stock_data.json

final Random _rng = new Random();

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
  List<List<String>> _data;

  StockData(this._data);

  void appendTo(List<Stock> stocks) {
    for (List<String> fields in _data)
      stocks.add(new Stock.fromFields(fields));
  }
}

typedef void StockDataCallback(StockData data);
const _kChunkCount = 30;

String _urlToFetch(int chunk) {
  if (rootBundle == null)
    return '../data/stock_data_${chunk}.json';
  return 'https://domokit.github.io/example/stocks/data/stock_data_${chunk}.json';
}

class StockDataFetcher {
  int _nextChunk = 0;
  final StockDataCallback callback;

  StockDataFetcher(this.callback) {
    _fetchNextChunk();
  }

  void _fetchNextChunk() {
    fetchBody(_urlToFetch(_nextChunk++)).then((Response response) {
      String json = response.bodyAsString();
      if (json == null) {
        print("Failed to load stock data chunk ${_nextChunk - 1}");
        return;
      }
      JsonDecoder decoder = new JsonDecoder();

      callback(new StockData(decoder.convert(json)));

      if (_nextChunk < _kChunkCount)
        _fetchNextChunk();
    });
  }
}
