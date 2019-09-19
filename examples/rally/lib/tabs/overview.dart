// Copyright 2019-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:rally/colors.dart';
import 'package:rally/data.dart';
import 'package:rally/finance.dart';
import 'package:rally/formatters.dart';

/// A page that shows a status overview.
class OverviewView extends StatefulWidget {
  @override
  _OverviewViewState createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  @override
  Widget build(BuildContext context) {
    final accountDataList = DummyDataService.getAccountDataList();
    final billDataList = DummyDataService.getBillDataList();
    final budgetDataList = DummyDataService.getBudgetDataList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        children: [
          _AlertsView(),
          SizedBox(height: 16),
          _FinancialView(
            title: 'Accounts',
            total: sumAccountDataPrimaryAmount(accountDataList),
            financialItemViews: buildAccountDataListViews(accountDataList),
          ),
          SizedBox(height: 16),
          _FinancialView(
            title: 'Bills',
            total: sumBillDataPrimaryAmount(billDataList),
            financialItemViews: buildBillDataListViews(billDataList),
          ),
          SizedBox(height: 16),
          _FinancialView(
            title: 'Budgets',
            total: sumBudgetDataPrimaryAmount(budgetDataList),
            financialItemViews:
                buildBudgetDataListViews(budgetDataList, context),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AlertsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16, top: 4, bottom: 4),
      color: RallyColors.cardBackground,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alerts'),
              FlatButton(
                onPressed: () {},
                child: Text('SEE ALL'),
                textColor: Colors.white,
              ),
            ],
          ),
          Container(color: RallyColors.primaryBackground, height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                    'Heads up, you’ve used up 90% of your Shopping budget for '
                    'this month.'),
              ),
              SizedBox(
                width: 100,
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.sort, color: RallyColors.white60),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinancialView extends StatelessWidget {
  _FinancialView({this.title, this.total, this.financialItemViews});

  final String title;
  final double total;
  final List<FinancialEntityCategoryView> financialItemViews;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: RallyColors.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(title),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16),
            child: Text(
              Formatters.usdWithSign.format(total),
              style: theme.textTheme.body2.copyWith(
                fontSize: 44.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...financialItemViews.sublist(0, min(financialItemViews.length, 3)),
          FlatButton(
            child: Text('SEE ALL'),
            textColor: Colors.white,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
