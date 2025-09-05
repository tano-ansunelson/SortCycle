import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePictureService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Capture profile picture from camera
  static Future<File?> captureProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error capturing profile picture: $e');
      return null;
    }
  }

  /// Pick profile picture from gallery
  static Future<File?> pickProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking profile picture: $e');
      return null;
    }
  }

  /// Upload profile picture to Firebase Storage
  static Future<String?> uploadProfilePicture(
    File imageFile,
    String userId,
    String userType, // 'user' or 'collector'
  ) async {
    try {
      // Create a unique filename
      final fileName = 'profile_${userType}_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('profile_pictures/$fileName');

      // Upload the file
      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'userType': userType,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Update user profile with profile picture URL
  static Future<bool> updateUserProfilePicture(
    String userId,
    String profilePictureUrl,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profilePictureUrl': profilePictureUrl,
        'profilePictureUpdatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating user profile picture: $e');
      return false;
    }
  }

  /// Update collector profile with profile picture URL
  static Future<bool> updateCollectorProfilePicture(
    String collectorId,
    String profilePictureUrl,
  ) async {
    try {
      await _firestore.collection('collectors').doc(collectorId).update({
        'profilePictureUrl': profilePictureUrl,
        'profilePictureUpdatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating collector profile picture: $e');
      return false;
    }
  }

  /// Complete profile picture update workflow
  static Future<bool> updateProfilePicture({
    required String userId,
    required String userType, // 'user' or 'collector'
    required File profileImage,
  }) async {
    try {
      // 1. Upload image to Firebase Storage
      final imageUrl = await uploadProfilePicture(profileImage, userId, userType);
      if (imageUrl == null) {
        throw Exception('Failed to upload profile picture');
      }

      // 2. Update profile with new picture URL
      bool updateSuccess;
      if (userType == 'user') {
        updateSuccess = await updateUserProfilePicture(userId, imageUrl);
      } else {
        updateSuccess = await updateCollectorProfilePicture(userId, imageUrl);
      }

      if (!updateSuccess) {
        throw Exception('Failed to update profile');
      }

      return true;
    } catch (e) {
      print('Error in profile picture update workflow: $e');
      return false;
    }
  }

  /// Delete old profile picture from storage (cleanup)
  static Future<bool> deleteProfilePicture(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting profile picture: $e');
      return false;
    }
  }

  /// Get default profile picture URL based on user type
  static String getDefaultProfilePicture(String userType) {
    if (userType == 'collector') {
      return 'https://firebasestorage.googleapis.com/v0/b/ecoclassify-d9e76.appspot.com/o/default_images%2Fdefault_collector.png?alt=media';
    } else {
      return 'https://firebasestorage.googleapis.com/v0/b/ecoclassify-d9e76.appspot.com/o/default_images%2Fdefault_user.png?alt=media';
    }
  }
}
