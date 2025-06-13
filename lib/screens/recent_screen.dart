import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample local data
    final List<Map<String, dynamic>> recentItems = [
      {
        'image': 'assests/image (13).jpg',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
        'category': 'Plastic',
        'tip': 'Clean and squash plastic bottles before recycling.',
        'impact': 4,
      },
      {
        'image': 'assests/image (1).jpg',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'category': 'Glass',
        'tip': 'Remove labels and rinse before recycling glass jars.',
        'impact': 2,
      },
      {
        'image': 'assests/image.jpg',
        'timestamp': DateTime.now().subtract(const Duration(days: 2, hours: 3)),
        'category': 'Cardboard',
        'tip': 'Flatten boxes to save space in recycling.',
        'impact': 1,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEFF5F1),
      appBar: AppBar(
        title: const Text('Recent Classifications'),
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recentItems.length,
        itemBuilder: (context, index) {
          final item = recentItems[index];
          final timestamp = DateFormat.yMMMd().add_jm().format(
            item['timestamp'],
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      item['image'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text info section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['category'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timestamp,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(item['tip'], style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(
                              "Impact:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            for (int i = 0; i < 5; i++)
                              Icon(
                                Icons.eco,
                                size: 16,
                                color: i < item['impact']
                                    ? Colors.green
                                    : Colors.grey.shade300,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
