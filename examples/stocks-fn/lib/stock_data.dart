// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';
import 'package:sky/framework/debug/tracing.dart';
import 'package:sky/framework/net/fetch.dart';

// Snapshot from http://www.nasdaq.com/screening/company-list.aspx
// Fetched 2/23/2014.
// "Symbol","Name","LastSale","MarketCap","IPOyear","Sector","industry","Summary Quote",
// Data in stock_data.json

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
    var rng = new Random();
    percentChange = (rng.nextDouble() * 20) - 10;
  }
}

class StockOracle {
  List<Stock> stocks;

  StockOracle(this.stocks);

  StockOracle.fromCompanyList(List<List<String>> list) {
    stocks = list.map((fields) => new Stock.fromFields(fields)).toList();
  }

  Stock lookupBySymbol(String symbol) {
    this.stocks.forEach((stock) {
      if (stock.symbol == symbol)
        return stock;
    });
    return null;
  }
}

Future<StockOracle> fetchStockOracle() async {
  Response response = await fetch('lib/stock_data.json');

  return trace('stocks::fetchStockOracle', () {
    String json = response.bodyAsString();
    JsonDecoder decoder = new JsonDecoder();
    var companyList = decoder.convert(json);
    return new StockOracle.fromCompanyList(companyList);
  });
}
