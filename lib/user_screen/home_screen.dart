import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/model/waste_classify_model.dart';
import 'package:flutter_application_1/user_screen/classification_result_screen.dart';
import 'package:flutter_application_1/user_screen/recent_screen.dart';
import 'package:flutter_application_1/user_screen/stats_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/web.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final MLService _mlService = MLService();

class _HomeScreenState extends State<HomeScreen> {
  int myIndex = 1;
  File? image;

  final log = Logger();
  Future<void> _classifyAndNavigate(
    File imageFile,
    BuildContext context,
  ) async {
    final navigator = Navigator.of(context);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _mlService.getTopPrediction(imageFile.path);
      if (!mounted) return;
      navigator.pop(); // close the loading dialog

      if (result != null) {
        if (!mounted) return;
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ClassificationResultScreen(
              imagePath: imageFile.path,
              category: result.category,
              confidence: result.confidence,
              recyclingInstructions: RecyclingInstructions.getInstructions(
                result.category,
              ),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        _showError(context, 'No classification result found');
      }
    } catch (e) {
      navigator.pop(); // close dialog
      _showError(context, 'Classification failed: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future pickImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage == null) return;
      final imageTemporary = File(pickedImage.path);
      setState(() {
        image = imageTemporary;
      });
    } on PlatformException catch (e) {
      log.e('Failed to pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const StatsScreen(),
      HomeContent(
        image: image,
        pickImageCallback: pickImage,
        onSubmit: () async {
          if (image != null) {
            await _classifyAndNavigate(image!, context);
          }
        },
      ),
      const RecentScreen(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('EcoClassify'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              icon: const Icon(Icons.person_outline_rounded, size: 24),
            ),
          ),
        ],
      ),
      body: screens[myIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey.shade600,
          currentIndex: myIndex,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.barChart2),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.history),
              label: 'Recent',
            ),
          ],
          onTap: (index) {
            setState(() {
              myIndex = index;
            });
          },
        ),
      ),
      // Floating action button for location
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/recycling-centers');
        },
        tooltip: 'Location',
        backgroundColor: Colors.green,
        child: const Icon(Icons.location_on_outlined),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final File? image;
  final Function(ImageSource) pickImageCallback;
  final VoidCallback? onSubmit;

  const HomeContent({
    super.key,
    required this.image,
    required this.pickImageCallback,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2E7D32).withOpacity(0.1),
                    const Color(0xFF4CAF50).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Classify Your Waste',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take or upload a photo to identify and classify your waste items',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => pickImageCallback(ImageSource.camera),
                        borderRadius: BorderRadius.circular(20),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Take Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => pickImageCallback(ImageSource.gallery),
                        borderRadius: BorderRadius.circular(20),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              color: Color(0xFF2E7D32),
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Gallery',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Image Display
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: image != null
                  ? Stack(
                      children: [
                        Image.file(
                          image!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.grey.shade400,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No image selected',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your selected image will appear here',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: image != null ? onSubmit : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey.shade600,
                  elevation: image != null ? 4 : 0,
                  shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      image != null
                          ? Icons.send_rounded
                          : Icons.image_not_supported_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      image != null
                          ? 'Classify Image'
                          : 'Select an Image First',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Tips Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
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
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Photo Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...[
                    'Use good lighting for clear visibility',
                    'Focus on the waste item you want to classify',
                    'Avoid shadows and reflections',
                    'Keep background simple and uncluttered',
                  ].map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
