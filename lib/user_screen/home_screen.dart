import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/model/waste_classify_model.dart';
import 'package:flutter_application_1/user_screen/classification_result_screen.dart';
import 'package:flutter_application_1/user_screen/homecontent.dart';
import 'package:flutter_application_1/user_screen/recent_classification_tab.dart';
import 'package:flutter_application_1/user_screen/recent_screen.dart';
//import 'package:flutter_application_1/user_screen/waste_form.dart';
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
  int myIndex = 2;
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
              onDone: () {
                setState(() {
                  image = null;
                });
              },
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
      WasteForm(),
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
      const RecentClassificationsTab(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),

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
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Pickup',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.barChart2),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.pushNamed(context, '/recycling-centers');
      //   },
      //   tooltip: 'Location',
      //   backgroundColor: Colors.green,
      //   child: const Icon(Icons.location_on_outlined),
      // ),
    );
  }
}
