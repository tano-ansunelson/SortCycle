import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProofService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Capture or pick an image for proof of service
  static Future<File?> captureProofImage() async {
    try {
      // Show options for camera or gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error capturing proof image: $e');
      return null;
    }
  }

  /// Pick an image from gallery for proof of service
  static Future<File?> pickProofImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking proof image: $e');
      return null;
    }
  }

  /// Upload proof image to Firebase Storage
  static Future<String?> uploadProofImage(
    File imageFile,
    String requestId,
    String collectorId,
  ) async {
    try {
      // Create a unique filename
      final fileName = 'proof_${requestId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('proof_images/$fileName');

      // Upload the file
      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'requestId': requestId,
            'collectorId': collectorId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading proof image: $e');
      return null;
    }
  }

  /// Update pickup request with proof image URL
  static Future<bool> updatePickupWithProof(
    String requestId,
    String proofImageUrl,
  ) async {
    try {
      await _firestore.collection('pickup_requests').doc(requestId).update({
        'proofImageUrl': proofImageUrl,
        'proofUploadedAt': FieldValue.serverTimestamp(),
        'status': 'completed_with_proof',
      });
      return true;
    } catch (e) {
      print('Error updating pickup with proof: $e');
      return false;
    }
  }

  /// Send proof image to existing chat system
  static Future<bool> sendProofToChat(
    String requestId,
    String proofImageUrl,
    String collectorId,
    String collectorName,
    String userId,
  ) async {
    try {
      // Create message in the existing chat system
      final messageData = {
        'senderId': collectorId,
        'senderName': collectorName,
        'message': 'Proof of service completed',
        'imageUrl': proofImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'proof',
        'isFromCollector': true,
        'isRead': false,
        'reactions': {},
      };

      // Add message to the existing chat messages collection
      await _firestore
          .collection('chats')
          .doc(requestId)
          .collection('messages')
          .add(messageData);

      // Check if chat document exists, if not create it
      final chatDocRef = _firestore.collection('chats').doc(requestId);
      final chatDoc = await chatDocRef.get();
      
      if (!chatDoc.exists) {
        // Create the chat document if it doesn't exist
        await chatDocRef.set({
          'requestId': requestId,
          'collectorId': collectorId,
          'collectorName': collectorName,
          'userId': userId,
          'lastMessage': '📷 Proof of service provided',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {
            'user': 1,
            'collector': 0,
          },
          'collectorTyping': false,
          'userTyping': false,
          'lastSeen': {
            'collector': FieldValue.serverTimestamp(),
            'user': null,
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing chat document with last message info
        await chatDocRef.update({
          'lastMessage': '📷 Proof of service provided',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount.user': FieldValue.increment(1),
          'collectorTyping': false,
          'lastSeen.collector': FieldValue.serverTimestamp(),
        });
      }

      // Create notification for the user
      try {
        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'new_message',
          'title': '📷 Proof of Service',
          'message': '$collectorName has provided proof of service completion',
          'data': {
            'chatId': requestId,
            'senderId': collectorId,
            'senderName': collectorName,
            'message': 'Proof of service completed',
            'imageUrl': proofImageUrl,
            'messageType': 'proof',
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error creating proof notification: $e');
      }

      return true;
    } catch (e) {
      print('Error sending proof to chat: $e');
      return false;
    }
  }

  /// Complete the full proof of service workflow
  static Future<bool> completeProofOfWorkflow({
    required String requestId,
    required String collectorId,
    required String collectorName,
    required String userId,
    required File proofImage,
  }) async {
    try {
      // 1. Upload image to Firebase Storage
      final imageUrl = await uploadProofImage(proofImage, requestId, collectorId);
      if (imageUrl == null) {
        throw Exception('Failed to upload proof image');
      }

      // 2. Update pickup request with proof
      final updateSuccess = await updatePickupWithProof(requestId, imageUrl);
      if (!updateSuccess) {
        throw Exception('Failed to update pickup request');
      }

      // 3. Send proof to chat
      final chatSuccess = await sendProofToChat(
        requestId,
        imageUrl,
        collectorId,
        collectorName,
        userId,
      );
      if (!chatSuccess) {
        throw Exception('Failed to send proof to chat');
      }

      return true;
    } catch (e) {
      print('Error in proof workflow: $e');
      return false;
    }
  }

  /// Delete proof image from storage (cleanup)
  static Future<bool> deleteProofImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting proof image: $e');
      return false;
    }
  }
}
