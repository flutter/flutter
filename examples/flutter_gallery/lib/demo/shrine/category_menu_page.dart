// Copyright 2018-present the Flutter authors. All Rights Reserved.
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
import 'package:scoped_model/scoped_model.dart';

import 'package:flutter_gallery/demo/shrine/colors.dart';
import 'package:flutter_gallery/demo/shrine/model/app_state_model.dart';
import 'package:flutter_gallery/demo/shrine/model/product.dart';

class CategoryMenuPage extends StatelessWidget {
  const CategoryMenuPage({
    Key key,
    this.onCategoryTap,
  }) : super(key: key);

  final VoidCallback onCategoryTap;

  Widget _buildCategory(Category category, BuildContext context) {
    final String categoryString = category.toString().replaceAll('Category.', '').toUpperCase();
    final ThemeData theme = Theme.of(context);
    return ScopedModelDescendant<AppStateModel>(
      builder: (BuildContext context, Widget child, AppStateModel model) =>
          GestureDetector(
            onTap: () {
              model.setCategory(category);
              if (onCategoryTap != null) {
                onCategoryTap();
              }
            },
            child: model.selectedCategory == category
              ? Column(
                  children: <Widget>[
                    const SizedBox(height: 16.0),
                    Text(
                      categoryString,
                      style: theme.textTheme.body2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14.0),
                    Container(
                      width: 70.0,
                      height: 2.0,
                      color: kShrinePink400,
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    categoryString,
                    style: theme.textTheme.body2.copyWith(
                      color: kShrineBrown900.withAlpha(153)
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.only(top: 40.0),
        color: kShrinePink100,
        child: ListView(
          children: Category.values.map((Category c) => _buildCategory(c, context)).toList(),
        ),
      ),
    );
  }
}
