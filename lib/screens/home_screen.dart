import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screens/recent_screen.dart';
import 'package:flutter_application_1/screens/stats_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart'; // For icons

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int myIndex = 1;
  File? image;

  Future pickImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage == null) return;
      final imageTemporary = File(pickedImage.path);
      setState(() {
        image = imageTemporary;
      });
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const StatsScreen(),
      HomeContent(
        image: image,
        pickImageCallback: pickImage,
      ), // we'll extract your current UI here
      const RecentScreen(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFEFF5F1), // Light green/grey background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('EcoClassify'),
        backgroundColor: const Color(0xFF1B5E20), // Dark green
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: const Icon(Icons.person_2_outlined),
          ),
        ],
      ),
      body: screens[myIndex],

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF1B5E20),
        unselectedItemColor: Colors.grey,
        currentIndex: myIndex, // Home tab selected
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.barChart2),
            label: 'Stats',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.history),
            label: 'Recent',
          ),
        ],
        onTap: (index) {
          setState(() {
            myIndex = index;
          });

          // TODO: Add navigation logic
        },
      ),
    );
  }
}

//
//HOME PAGE
//
//
class HomeContent extends StatelessWidget {
  final File? image;
  final Function(ImageSource) pickImageCallback;

  const HomeContent({
    super.key,
    required this.image,
    required this.pickImageCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Upload Image',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Capture or select an image for classification.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => pickImageCallback(ImageSource.camera),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  'Take Photo',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => pickImageCallback(ImageSource.gallery),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.photo_library, color: Colors.white),
                label: const Text(
                  'Gallery',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),

          // Image Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 201, 231, 168),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image Capture Tips',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(height: 20),
                Text('• Ensure good lighting.'),
                Text('• Focus on the object.'),
                Text('• Avoid reflections and glare.'),
                Text('• Keep the background clear.'),
              ],
            ),
          ),

          const Spacer(),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            child: image != null
                ? Image.file(
                    image!,
                    fit: BoxFit.fill,
                    width: double.infinity,
                    alignment: Alignment.center,
                  )
                : const Text(
                    'Selected image will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: Submit image logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Submit Image'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
