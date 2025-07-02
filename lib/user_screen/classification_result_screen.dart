import 'package:flutter/material.dart';
import 'dart:io';

class ClassificationResultScreen extends StatelessWidget {
  final String? imagePath;
  final String category;
  final double confidence;
  final String recyclingInstructions;

  const ClassificationResultScreen({
    super.key,
    this.imagePath,
    required this.category,
    required this.confidence,
    required this.recyclingInstructions,
  });

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'plastic':
        return const Color(0xFF4FC3F7);
      case 'paper':
        return const Color(0xFF8D6E63);
      case 'glass':
        return const Color(0xFF66BB6A);
      case 'metal':
        return const Color(0xFF90A4AE);
      case 'cardboard':
        return const Color(0xFFFFB74D);
      case 'organic':
        return const Color(0xFF81C784);
      case 'trash':
        return const Color(0xFFE57373);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plastic':
        return Icons.water_drop;
      case 'paper':
        return Icons.description;
      case 'glass':
        return Icons.local_drink;
      case 'metal':
        return Icons.hardware;
      case 'cardboard':
        return Icons.inventory_2;
      case 'organic':
        return Icons.eco;
      case 'trash':
        return Icons.delete;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(category);
    final categoryIcon = _getCategoryIcon(category);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: double.infinity),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [categoryColor, categoryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Classification Complete",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Image Section
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: categoryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderImage(
                                    categoryIcon,
                                    categoryColor,
                                  );
                                },
                              ),
                            )
                          : _buildPlaceholderImage(categoryIcon, categoryColor),
                    ),

                    const SizedBox(height: 24),

                    // Category and Confidence Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: categoryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: categoryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  categoryIcon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: categoryColor,
                                    ),
                                  ),
                                  Text(
                                    "Detected Category",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Confidence Score
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Confidence Score",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                "${(confidence * 100).toStringAsFixed(1)}%",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Confidence Bar
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: confidence,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: categoryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recycling Instructions Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.recycling,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "How to Recycle",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            recyclingInstructions,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: categoryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Close",
                              style: TextStyle(
                                color: categoryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Add to stats or save functionality
                              Navigator.of(context).pop();
                              // You can add navigation to stats screen here
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: categoryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Save Result",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              "Image Preview",
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the dialog
void showClassificationResult(
  BuildContext context, {
  String? imagePath,
  required String category,
  required double confidence,
  required String recyclingInstructions,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => ClassificationResultScreen(
      imagePath: imagePath,
      category: category,
      confidence: confidence,
      recyclingInstructions: recyclingInstructions,
    ),
  );
}

// Example usage and sample recycling instructions
class RecyclingInstructions {
  static const Map<String, String> instructions = {
    'plastic': '''
1. Clean the plastic item thoroughly to remove any food residue or labels.
2. Check the recycling number on the bottom (1-7) to determine recyclability.
3. Remove caps and lids if they're made of different plastic types.
4. Place in your recycling bin or take to a plastic recycling center.
5. Avoid putting plastic bags in curbside recycling - take them to grocery store collection points.
''',
    'paper': '''
1. Remove any plastic wrapping, tape, or staples from the paper.
2. Ensure the paper is clean and dry - no food stains or grease.
3. Flatten cardboard boxes and paper items to save space.
4. Place in your paper recycling bin or bundle together.
5. Avoid recycling wax-coated paper, tissues, or paper towels.
''',
    'glass': '''
1. Rinse the glass container to remove any food or liquid residue.
2. Remove metal lids and caps (recycle these separately).
3. Leave labels on - they'll be removed during the recycling process.
4. Place in your glass recycling bin or take to a glass recycling center.
5. Separate by color if your local facility requires it (clear, brown, green).
''',
    'metal': '''
1. Clean the metal item to remove any food residue or labels.
2. Remove any non-metal components like plastic handles or rubber seals.
3. Crush aluminum cans to save space, but don't crush steel cans.
4. Place in your metal recycling bin or take to a scrap metal dealer.
5. Separate ferrous (magnetic) and non-ferrous metals if required.
''',
    'cardboard': '''
1. Break down boxes and flatten them to save space.
2. Remove any plastic tape, labels, or packing materials.
3. Ensure cardboard is clean and dry - no grease or food stains.
4. Place in your cardboard recycling bin or bundle together.
5. Avoid recycling wax-coated or laminated cardboard.
''',
    'organic': '''
1. Separate organic waste from other materials immediately.
2. Place in a compost bin or organic waste collection container.
3. Keep away from meat, dairy, and oily foods unless your facility accepts them.
4. Turn compost regularly if composting at home.
5. Consider starting a home compost system for garden benefits.
''',
    'trash': '''
This item cannot be recycled through standard programs. Consider these options:
1. Check if it can be repaired or repurposed instead of discarding.
2. Look for specialized recycling programs for this type of material.
3. Dispose of it properly in your regular trash bin.
4. Consider donating if the item is still usable.
5. Research local hazardous waste disposal if it contains harmful materials.
''',
  };

  static String getInstructions(String category) {
    return instructions[category.toLowerCase()] ?? instructions['trash']!;
  }
}
