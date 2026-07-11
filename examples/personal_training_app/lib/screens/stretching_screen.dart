import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/stretching_library.dart';
import 'package:firebase_database/firebase_database.dart';

class StretchingScreen extends StatefulWidget {
  const StretchingScreen({super.key});

  @override
  State<StretchingScreen> createState() => _StretchingScreenState();
}

class _StretchingScreenState extends State<StretchingScreen> {
  String selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Upper Body', 'Lower Body', 'Full Body'];
    return Scaffold(
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('stretchingLibrary').onValue,
        builder: (context, snapshot) {
          List<StretchingExercise> stretches = [];
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = snapshot.data!.snapshot.value as List<dynamic>?;
            if (data != null) {
              stretches = data
                  .where((e) => e != null)
                  .map(
                    (e) => StretchingExercise.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList();
            }
          } else {
            stretches = stretchingLibrary;
          }
          final filteredStretches = stretches
              .where(
                (s) =>
                    (selectedCategory == 'All' ||
                        s.category == selectedCategory) &&
                    (_searchQuery.isEmpty ||
                        s.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        )),
              )
              .toList();
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF059669),
                      const Color(0xFF059669).withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stretching Routines',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Improve flexibility and recovery',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search stretches...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      final isSelected = category == selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: const Color(0xFF059669),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: filteredStretches.length,
                  itemBuilder: (context, index) {
                    final stretch = filteredStretches[index];
                    return StretchCard(stretch: stretch);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StretchCard extends StatefulWidget {
  final StretchingExercise stretch;

  const StretchCard({super.key, required this.stretch});

  @override
  State<StretchCard> createState() => _StretchCardState();
}

class _StretchCardState extends State<StretchCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 24,
            ),
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            leading: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.self_improvement,
                color: Color(0xFF059669),
                size: 38,
              ),
            ),
            title: Text(
              widget.stretch.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
                fontSize: 26,
              ),
            ),
            subtitle: Text(
              '${widget.stretch.category} • ${widget.stretch.duration}',
              style: const TextStyle(fontSize: 18),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF059669),
              size: 32,
            ),
          ),
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Duration',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF059669),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.stretch.duration,
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.stretch.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4B5563),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final url = Uri.parse(widget.stretch.youtubeUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        } catch (e) {
                          print('Error launching URL: $e');
                        }
                      },
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Watch Demo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
