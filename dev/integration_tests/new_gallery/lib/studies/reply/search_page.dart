import 'package:flutter/material.dart';
import 'package:gallery/studies/reply/model/email_store.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BackButton(
                      key: const ValueKey('ReplyExit'),
                      onPressed: () {
                        Provider.of<EmailStore>(
                          context,
                          listen: false,
                        ).onSearchPage = false;
                      },
                    ),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration.collapsed(
                          hintText: 'Search email',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic),
                      onPressed: () {},
                    )
                  ],
                ),
              ),
              const Divider(thickness: 1),
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: 'YESTERDAY'),
                      _SearchHistoryTile(
                        search: '481 Van Brunt Street',
                        address: 'Brooklyn, NY',
                      ),
                      _SearchHistoryTile(
                        icon: Icons.home,
                        search: 'Home',
                        address: '199 Pacific Street, Brooklyn, NY',
                      ),
                      _SectionHeader(title: 'THIS WEEK'),
                      _SearchHistoryTile(
                        search: 'BEP GA',
                        address: 'Forsyth Street, New York, NY',
                      ),
                      _SearchHistoryTile(
                        search: 'Sushi Nakazawa',
                        address: 'Commerce Street, New York, NY',
                      ),
                      _SearchHistoryTile(
                        search: 'IFC Center',
                        address: '6th Avenue, New York, NY',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 16,
        top: 16,
        bottom: 16,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _SearchHistoryTile extends StatelessWidget {
  const _SearchHistoryTile({
    this.icon = Icons.access_time,
    required this.search,
    required this.address,
  });

  final IconData icon;
  final String search;
  final String address;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(search),
      subtitle: Text(address),
      onTap: () {},
    );
  }
}
