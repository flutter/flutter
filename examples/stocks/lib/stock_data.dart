// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Snapshot from http://www.nasdaq.com/screening/company-list.aspx
// Fetched 2/23/2014.
// "Symbol","Name","LastSale","MarketCap","IPOyear","Sector","industry","Summary Quote",
// Data in stock_data.json

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/http.dart' as http;

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
  List<List<String>> _data;

  StockData(this._data);

  void appendTo(Map<String, Stock> stocks, List<String> symbols) {
    for (List<String> fields in _data) {
      Stock stock = new Stock.fromFields(fields);
      symbols.add(stock.symbol);
      stocks[stock.symbol] = stock;
    }
    symbols.sort();
  }
}

typedef void StockDataCallback(StockData data);
const _kChunkSize = 100;

String _urlToFetch(int chunk) {
  Map<String, String> queryParameters = {
    'limitToFirst': _kChunkSize.toString(),
    'startAt': '\"${chunk * _kChunkSize}\"',
    'orderBy': '"\$key"',
  };
  // Just a demo firebase app owned by eseidel.
  return new Uri.https(
    'sizzling-torch-6112.firebaseio.com',
    '.json',
    queryParameters=queryParameters
  ).toString();
}

class StockDataFetcher {
  int _nextChunk = 0;
  final StockDataCallback callback;

  static bool actuallyFetchData = true;

  StockDataFetcher(this.callback) {
    _fetchNextChunk();
  }

  void _fetchNextChunk() {
    if (!actuallyFetchData)
      return;

    http.get(_urlToFetch(_nextChunk++)).then((http.Response response) {
      String json = response.body;
      if (json == null) {
        print("Failed to load stock data chunk ${_nextChunk - 1}");
        return;
      }
      JsonDecoder decoder = new JsonDecoder();
      Map responseJson = decoder.convert(json);
      callback(new StockData(responseJson.values.toList()));
      if (responseJson.isNotEmpty)
        _fetchNextChunk();
    });
  }
}
