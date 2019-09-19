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
import 'package:flutter/widgets.dart';

import 'package:rally/charts/pie_chart.dart';
import 'package:rally/charts/line_chart.dart';
import 'package:rally/charts/vertical_fraction_bar.dart';
import 'package:rally/colors.dart';
import 'package:rally/data.dart';
import 'package:rally/formatters.dart';

class FinancialEntityView extends StatelessWidget {
  FinancialEntityView({
    this.heroLabel,
    this.heroAmount,
    this.wholeAmount,
    this.segments,
    this.financialEntityCards,
  }) : assert(segments.length == financialEntityCards.length);

  /// The amounts to assign each item.
  ///
  /// This list must have the same length as [colors].
  final List<RallyPieChartSegment> segments;
  final String heroLabel;
  final double heroAmount;
  final double wholeAmount;
  final List<FinancialEntityCategoryView> financialEntityCards;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RallyPieChart(
          heroLabel: heroLabel,
          heroAmount: heroAmount,
          wholeAmount: wholeAmount,
          segments: segments,
        ),
        SizedBox(
          height: 1.0,
          child: Container(
            color: Color(0xA026282F),
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
            builder: (context) => FinancialEntityCategoryDetailsPage(),
          ),
        );
      },
      child: SizedBox(
        height: 68,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 12, right: 12),
                    child: VerticalFractionBar(
                      color: indicatorColor,
                      fraction: indicatorFraction,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .body1
                            .copyWith(fontSize: 16.0),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .body1
                            .copyWith(color: RallyColors.gray60),
                      ),
                    ],
                  ),
                  Spacer(),
                  Text(
                    '\$ ' + Formatters.usd.format(amount),
                    style: Theme.of(context)
                        .textTheme
                        .body2
                        .copyWith(fontSize: 20.0, color: RallyColors.gray),
                  ),
                  SizedBox(width: 32.0, child: suffix),
                ],
              ),
            ),
            Divider(
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
  final Color indicatorColor;
  final double indicatorFraction;
  final String title;
  final String subtitle;
  final double usdAmount;
  final Widget suffix;

  const FinancialEntityCategoryModel(
    this.indicatorColor,
    this.indicatorFraction,
    this.title,
    this.subtitle,
    this.usdAmount,
    this.suffix,
  );
}

FinancialEntityCategoryView buildFinancialEntityFromAccountData(
  AccountData model,
  int i,
) {
  return FinancialEntityCategoryView(
    suffix: Icon(Icons.chevron_right, color: Colors.grey),
    title: model.name,
    subtitle: '• • • • • • ${model.accountNumber.substring(6)}',
    indicatorColor: RallyColors.accountColor(i),
    indicatorFraction: 1.0,
    amount: model.primaryAmount,
  );
}

FinancialEntityCategoryView buildFinancialEntityFromBillData(
  BillData model,
  int i,
) {
  return FinancialEntityCategoryView(
    suffix: Icon(Icons.chevron_right, color: Colors.grey),
    title: model.name,
    subtitle: model.dueDate,
    indicatorColor: RallyColors.billColor(i),
    indicatorFraction: 1.0,
    amount: model.primaryAmount,
  );
}

FinancialEntityCategoryView buildFinancialEntityFromBudgetData(
  BudgetData item,
  int i,
  BuildContext context,
) {
  return FinancialEntityCategoryView(
    suffix: Text(' LEFT',
        style: Theme.of(context)
            .textTheme
            .body1
            .copyWith(color: RallyColors.gray60, fontSize: 10.0)),
    title: item.name,
    subtitle: Formatters.usdWithSign.format(item.amountUsed) +
        ' / ' +
        Formatters.usdWithSign.format(item.primaryAmount),
    indicatorColor: RallyColors.budgetColor(i),
    indicatorFraction: item.amountUsed / item.primaryAmount,
    amount: item.primaryAmount - item.amountUsed,
  );
}

List<FinancialEntityCategoryView> buildAccountDataListViews(
    List<AccountData> items) {
  return List<FinancialEntityCategoryView>.generate(
      items.length, (i) => buildFinancialEntityFromAccountData(items[i], i));
}

List<FinancialEntityCategoryView> buildBillDataListViews(List<BillData> items) {
  return List<FinancialEntityCategoryView>.generate(
      items.length, (i) => buildFinancialEntityFromBillData(items[i], i));
}

List<FinancialEntityCategoryView> buildBudgetDataListViews(
    List<BudgetData> items, BuildContext context) {
  return [
    for (var i = 0; i < items.length; i++)
      buildFinancialEntityFromBudgetData(items[i], i, context)
  ];
}

class FinancialEntityCategoryDetailsPage extends StatelessWidget {
  final List<DetailedEventData> items =
      DummyDataService.getDetailedEventItems();

  @override
  Widget build(BuildContext context) {
    final List<_DetailedEventCard> cards = items
        .map((i) => _DetailedEventCard(
              title: i.title,
              subtitle: Formatters.date.format(i.date),
              amount: i.amount,
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        centerTitle: true,
        title: Text(
          'Checking',
          style: Theme.of(context).textTheme.body1.copyWith(fontSize: 18.0),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
              height: 200.0,
              width: double.infinity,
              child: RallyLineChart(events: items)),
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
    return FlatButton(
      onPressed: () {},
      child: SizedBox(
        height: 68.0,
        child: Column(
          children: [
            SizedBox(
              height: 67.0,
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .body1
                            .copyWith(fontSize: 16.0),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .body1
                            .copyWith(color: RallyColors.gray60),
                      )
                    ],
                  ),
                  Spacer(),
                  Text(
                    '\$${Formatters.usd.format(amount)}',
                    style: Theme.of(context)
                        .textTheme
                        .body2
                        .copyWith(fontSize: 20.0, color: RallyColors.gray),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 1.0,
                child: Container(
                  color: Color(0xAA282828),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
