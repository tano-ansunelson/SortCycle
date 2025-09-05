import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a rating for a collector
  static Future<bool> submitRating({
    required String requestId,
    required String collectorId,
    required String userId,
    required int rating, // 1-5 stars
    String? comment,
  }) async {
    try {
      // Validate rating
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Create rating document
      await _firestore.collection('ratings').add({
        'requestId': requestId,
        'collectorId': collectorId,
        'userId': userId,
        'rating': rating,
        'comment': comment ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update collector's average rating
      await _updateCollectorRating(collectorId);

      // Mark request as rated
      await _firestore.collection('pickup_requests').doc(requestId).update({
        'isRated': true,
        'userRating': rating,
        'userComment': comment ?? '',
        'ratedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error submitting rating: $e');
      return false;
    }
  }

  /// Update collector's average rating
  static Future<void> _updateCollectorRating(String collectorId) async {
    try {
      // Get all ratings for this collector
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('collectorId', isEqualTo: collectorId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      // Calculate average rating
      double totalRating = 0;
      int ratingCount = 0;

      for (final doc in ratingsSnapshot.docs) {
        final data = doc.data();
        totalRating += (data['rating'] as int).toDouble();
        ratingCount++;
      }

      final averageRating = totalRating / ratingCount;

      // Update collector document
      await _firestore.collection('collectors').doc(collectorId).update({
        'averageRating': averageRating,
        'totalRatings': ratingCount,
        'lastRatingUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating collector rating: $e');
    }
  }

  /// Get collector's rating information
  static Future<Map<String, dynamic>?> getCollectorRating(String collectorId) async {
    try {
      final doc = await _firestore.collection('collectors').doc(collectorId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'averageRating': data['averageRating'] ?? 0.0,
          'totalRatings': data['totalRatings'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      print('Error getting collector rating: $e');
      return null;
    }
  }

  /// Check if user has already rated a request
  static Future<bool> hasUserRated(String requestId, String userId) async {
    try {
      final doc = await _firestore.collection('pickup_requests').doc(requestId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return data['isRated'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking if user rated: $e');
      return false;
    }
  }

  /// Get recent ratings for a collector
  static Future<List<Map<String, dynamic>>> getRecentRatings(String collectorId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('collectorId', isEqualTo: collectorId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'rating': data['rating'],
          'comment': data['comment'],
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      print('Error getting recent ratings: $e');
      return [];
    }
  }
}
