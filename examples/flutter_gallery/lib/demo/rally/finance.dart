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

import 'package:flutter/material.dart';

import 'package:flutter_gallery/demo/rally/charts/pie_chart.dart';
import 'package:flutter_gallery/demo/rally/charts/line_chart.dart';
import 'package:flutter_gallery/demo/rally/charts/vertical_fraction_bar.dart';
import 'package:flutter_gallery/demo/rally/colors.dart';
import 'package:flutter_gallery/demo/rally/data.dart';
import 'package:flutter_gallery/demo/rally/formatters.dart';

class FinancialEntityView extends StatelessWidget {
  const FinancialEntityView({
    this.heroLabel,
    this.heroAmount,
    this.wholeAmount,
    this.segments,
    this.financialEntityCards,
  }) : assert(segments.length == financialEntityCards.length);

  /// The amounts to assign each item.
  final List<RallyPieChartSegment> segments;
  final String heroLabel;
  final double heroAmount;
  final double wholeAmount;
  final List<FinancialEntityCategoryView> financialEntityCards;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RallyPieChart(
          heroLabel: heroLabel,
          heroAmount: heroAmount,
          wholeAmount: wholeAmount,
          segments: segments,
        ),
        SizedBox(
          height: 1,
          child: Container(
            color: const Color(0xA026282F),
          ),
        ),
        ListView(shrinkWrap: true, children: financialEntityCards),
      ],
    );
  }
}

/// A reusable widget to show balance information of a single entity as a card.
class FinancialEntityCategoryView extends StatelessWidget {
  const FinancialEntityCategoryView({
    @required this.indicatorColor,
    @required this.indicatorFraction,
    @required this.title,
    @required this.subtitle,
    @required this.amount,
    @required this.suffix,
  });

  final Color indicatorColor;
  final double indicatorFraction;
  final String title;
  final String subtitle;
  final double amount;
  final Widget suffix;

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute<FinancialEntityCategoryDetailsPage>(
            builder: (BuildContext context) => FinancialEntityCategoryDetailsPage(),
          ),
        );
      },
      child: SizedBox(
        height: 68,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: VerticalFractionBar(
                      color: indicatorColor,
                      fraction: indicatorFraction,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.body1.copyWith(fontSize: 16),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.body1.copyWith(color: RallyColors.gray60),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '\$ ' + usdFormat.format(amount),
                    style: Theme.of(context).textTheme.body2.copyWith(fontSize: 20, color: RallyColors.gray),
                  ),
                  SizedBox(width: 32, child: suffix),
                ],
              ),
            ),
            const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Color(0xAA282828),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data model for [FinancialEntityCategoryView].
class FinancialEntityCategoryModel {
  const FinancialEntityCategoryModel(
    this.indicatorColor,
    this.indicatorFraction,
    this.title,
    this.subtitle,
    this.usdAmount,
    this.suffix,
  );

  final Color indicatorColor;
  final double indicatorFraction;
  final String title;
  final String subtitle;
  final double usdAmount;
  final Widget suffix;
}

FinancialEntityCategoryView buildFinancialEntityFromAccountData(
  AccountData model,
  int accountDataIndex,
) {
  return FinancialEntityCategoryView(
    suffix: const Icon(Icons.chevron_right, color: Colors.grey),
    title: model.name,
    subtitle: '• • • • • • ${model.accountNumber.substring(6)}',
    indicatorColor: RallyColors.accountColor(accountDataIndex),
    indicatorFraction: 1,
    amount: model.primaryAmount,
  );
}

FinancialEntityCategoryView buildFinancialEntityFromBillData(
  BillData model,
  int billDataInex,
) {
  return FinancialEntityCategoryView(
    suffix: const Icon(Icons.chevron_right, color: Colors.grey),
    title: model.name,
    subtitle: model.dueDate,
    indicatorColor: RallyColors.billColor(billDataInex),
    indicatorFraction: 1,
    amount: model.primaryAmount,
  );
}

FinancialEntityCategoryView buildFinancialEntityFromBudgetData(
  BudgetData item,
  int budgetDataIndex,
  BuildContext context,
) {
  final String amountUsed = usdWithSignFormat.format(item.amountUsed);
  final String primaryAmount = usdWithSignFormat.format(item.primaryAmount);

  return FinancialEntityCategoryView(
    suffix: Text(
      ' LEFT',
      style: Theme.of(context).textTheme.body1.copyWith(color: RallyColors.gray60, fontSize: 10),
    ),
    title: item.name,
    subtitle: amountUsed + ' / ' + primaryAmount,
    indicatorColor: RallyColors.budgetColor(budgetDataIndex),
    indicatorFraction: item.amountUsed / item.primaryAmount,
    amount: item.primaryAmount - item.amountUsed,
  );
}

List<FinancialEntityCategoryView> buildAccountDataListViews(
    List<AccountData> items) {
  return List<FinancialEntityCategoryView>.generate(
    items.length,
    (int i) => buildFinancialEntityFromAccountData(items[i], i),
  );
}

List<FinancialEntityCategoryView> buildBillDataListViews(List<BillData> items) {
  return List<FinancialEntityCategoryView>.generate(
    items.length,
    (int i) => buildFinancialEntityFromBillData(items[i], i),
  );
}

List<FinancialEntityCategoryView> buildBudgetDataListViews(
    List<BudgetData> items, BuildContext context) {
  return <FinancialEntityCategoryView>[
    for (int i = 0; i < items.length; i++)
      buildFinancialEntityFromBudgetData(items[i], i, context)
  ];
}

class FinancialEntityCategoryDetailsPage extends StatelessWidget {
  final List<DetailedEventData> items = DummyDataService.getDetailedEventItems();

  @override
  Widget build(BuildContext context) {
    final List<_DetailedEventCard> cards = items.map((DetailedEventData detailedEventData) {
      return _DetailedEventCard(
        title: detailedEventData.title,
        subtitle: dateFormat.format(detailedEventData.date),
        amount: detailedEventData.amount,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Checking',
          style: Theme.of(context).textTheme.body1.copyWith(fontSize: 18),
        ),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 200,
            width: double.infinity,
            child: RallyLineChart(events: items),
          ),
          Flexible(
            child: ListView(shrinkWrap: true, children: cards),
          ),
        ],
      ),
    );
  }
}

class _DetailedEventCard extends StatelessWidget {
  const _DetailedEventCard({
    @required this.title,
    @required this.subtitle,
    @required this.amount,
  });

  final String title;
  final String subtitle;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return FlatButton(
      onPressed: () {},
      child: SizedBox(
        height: 68,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 67,
              child: Row(
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: textTheme.body1.copyWith(fontSize: 16),
                      ),
                      Text(
                        subtitle,
                        style: textTheme.body1.copyWith(color: RallyColors.gray60),
                      )
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '\$${usdFormat.format(amount)}',
                    style: textTheme.body2.copyWith(fontSize: 20, color: RallyColors.gray),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 1,
                child: Container(
                  color: const Color(0xAA282828),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
