import 'package:flutter/material.dart';

/// Flutter code sample for [SliverExpansionPanelList].

void main() => runApp(const SliverExpansionPanelListExampleApp());

class SliverExpansionPanelListExampleApp extends StatelessWidget {
  const SliverExpansionPanelListExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SliverExpansionPanelListExample(),
    );
  }
}

class Item {
  Item({
    required this.expandedValue,
    required this.headerValue,
    this.isExpanded = false,
  });

  String expandedValue;
  String headerValue;
  bool isExpanded;
}

List<Item> generateItems(int numberOfItems) {
  return List<Item>.generate(numberOfItems, (int index) {
    return Item(
      headerValue: 'Panel $index',
      expandedValue: 'This is item number $index',
      isExpanded: false,
    );
  });
}

class SliverExpansionPanelListExample extends StatefulWidget {
  const SliverExpansionPanelListExample({super.key});

  @override
  State<SliverExpansionPanelListExample> createState() =>
      _SliverExpansionPanelListExampleState();
}

class _SliverExpansionPanelListExampleState
    extends State<SliverExpansionPanelListExample> {
  List<Item> items = generateItems(10);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SliverExpansionPanelList Example'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 48.0),
            child: IconButton(
              onPressed: () {
                setState(() {
                  items.add(
                    Item(
                      headerValue: 'Panel ${items.length}',
                      expandedValue: 'This is item number ${items.length}',
                      isExpanded: false,
                    ),
                  );
                });
              },
              icon: Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverExpansionPanelList(
              expansionPanels: items.map<SliverExpansionPanel>((Item item) {
                return SliverExpansionPanel(
                  key: ValueKey("${item.headerValue} - ${item.expandedValue}"),
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return ListTile(title: Text(item.headerValue));
                  },
                  canTapOnHeader: false,
                  body: ListTile(
                    title: Text(item.expandedValue),
                    subtitle: const Text(
                      'To delete this panel, tap the trash can icon',
                    ),
                    trailing: const Icon(Icons.delete),
                    onTap: () {
                      setState(() {
                        items.remove(item);
                      });
                    },
                  ),
                  isExpanded: item.isExpanded,
                );
              }).toList(),
              expansionCallback: (index, isExpanded) {
                setState(() {
                  items[index].isExpanded = isExpanded;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}