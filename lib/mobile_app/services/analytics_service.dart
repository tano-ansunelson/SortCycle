import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get pickup request analytics for a specific time period
  static Future<Map<String, dynamic>> getPickupAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? town,
  }) async {
    try {
      // Default to last 30 days if no dates provided
      final now = DateTime.now();
      final defaultStartDate =
          startDate ?? now.subtract(const Duration(days: 30));
      final defaultEndDate = endDate ?? now;

      Query query = _firestore
          .collection('pickup_requests')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(defaultStartDate),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(defaultEndDate),
          );

      // Add town filter if specified
      if (town != null && town.isNotEmpty) {
        query = query.where('userTown', isEqualTo: town.toLowerCase());
      }

      final snapshot = await query.get();
      final requests = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return _analyzePickupData(requests, defaultStartDate, defaultEndDate);
    } catch (e) {
      print('Error fetching pickup analytics: $e');
      return _getEmptyAnalytics();
    }
  }

  // Get demand insights by area
  static Future<List<Map<String, dynamic>>> getDemandInsightsByArea({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final defaultStartDate =
          startDate ?? now.subtract(const Duration(days: 7));
      final defaultEndDate = endDate ?? now;

      final snapshot = await _firestore
          .collection('pickup_requests')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(defaultStartDate),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(defaultEndDate),
          )
          .get();

      final requests = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Group by town
      final Map<String, List<Map<String, dynamic>>> townGroups = {};
      for (final request in requests) {
        final town = request['userTown']?.toString().toLowerCase() ?? 'unknown';
        townGroups.putIfAbsent(town, () => []).add(request);
      }

      // Calculate insights for each town
      final List<Map<String, dynamic>> insights = [];
      for (final entry in townGroups.entries) {
        final town = entry.key;
        final townRequests = entry.value;

        // Calculate statistics
        final totalRequests = townRequests.length;
        final emergencyRequests = townRequests
            .where((r) => r['isEmergency'] == true)
            .length;
        final completedRequests = townRequests
            .where((r) => r['status'] == 'completed')
            .length;
        final averageBins =
            townRequests.fold<double>(
              0,
              (sum, r) => sum + (r['binCount'] ?? 1),
            ) /
            totalRequests;
        final totalRevenue = townRequests.fold<double>(
          0,
          (sum, r) => sum + (r['totalAmount'] ?? 0),
        );

        // Get day of week distribution
        final dayDistribution = _getDayDistribution(townRequests);

        insights.add({
          'town': town,
          'totalRequests': totalRequests,
          'emergencyRequests': emergencyRequests,
          'completedRequests': completedRequests,
          'completionRate': totalRequests > 0
              ? (completedRequests / totalRequests) * 100
              : 0,
          'averageBins': averageBins,
          'totalRevenue': totalRevenue,
          'dayDistribution': dayDistribution,
          'demandLevel': _getDemandLevel(totalRequests),
        });
      }

      // Sort by total requests (highest demand first)
      insights.sort((a, b) => b['totalRequests'].compareTo(a['totalRequests']));

      return insights;
    } catch (e) {
      print('Error fetching demand insights: $e');
      return [];
    }
  }

  // Get predictive forecast for next week
  static Future<Map<String, dynamic>> getPredictiveForecast({
    String? town,
  }) async {
    try {
      // Get historical data for the last 4 weeks
      final now = DateTime.now();
      final fourWeeksAgo = now.subtract(const Duration(days: 28));

      final snapshot = await _firestore
          .collection('pickup_requests')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fourWeeksAgo),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      final requests = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Filter by town if specified
      final filteredRequests = town != null
          ? requests
                .where(
                  (r) =>
                      r['userTown']?.toString().toLowerCase() ==
                      town.toLowerCase(),
                )
                .toList()
          : requests;

      return _generateForecast(filteredRequests, now);
    } catch (e) {
      print('Error generating forecast: $e');
      return _getEmptyForecast();
    }
  }

  // Get weekly trends
  static Future<List<Map<String, dynamic>>> getWeeklyTrends({
    int weeks = 4,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: weeks * 7));

      final snapshot = await _firestore
          .collection('pickup_requests')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      final requests = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Group by week
      final Map<String, List<Map<String, dynamic>>> weeklyGroups = {};
      for (final request in requests) {
        final createdAt = (request['createdAt'] as Timestamp).toDate();
        final weekKey = _getWeekKey(createdAt);
        weeklyGroups.putIfAbsent(weekKey, () => []).add(request);
      }

      // Calculate weekly statistics
      final List<Map<String, dynamic>> trends = [];
      for (int i = weeks - 1; i >= 0; i--) {
        final weekDate = now.subtract(Duration(days: i * 7));
        final weekKey = _getWeekKey(weekDate);
        final weekRequests = weeklyGroups[weekKey] ?? [];

        trends.add({
          'week': weekKey,
          'date': weekDate,
          'totalRequests': weekRequests.length,
          'emergencyRequests': weekRequests
              .where((r) => r['isEmergency'] == true)
              .length,
          'completedRequests': weekRequests
              .where((r) => r['status'] == 'completed')
              .length,
          'totalRevenue': weekRequests.fold<double>(
            0,
            (sum, r) => sum + (r['totalAmount'] ?? 0),
          ),
          'averageBins': weekRequests.isNotEmpty
              ? weekRequests.fold<double>(
                      0,
                      (sum, r) => sum + (r['binCount'] ?? 1),
                    ) /
                    weekRequests.length
              : 0,
        });
      }

      return trends;
    } catch (e) {
      print('Error fetching weekly trends: $e');
      return [];
    }
  }

  // Private helper methods
  static Map<String, dynamic> _analyzePickupData(
    List<Map<String, dynamic>> requests,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (requests.isEmpty) return _getEmptyAnalytics();

    final totalRequests = requests.length;
    final emergencyRequests = requests
        .where((r) => r['isEmergency'] == true)
        .length;
    final completedRequests = requests
        .where((r) => r['status'] == 'completed')
        .length;
    final pendingRequests = requests
        .where((r) => r['status'] == 'pending')
        .length;
    final inProgressRequests = requests
        .where((r) => r['status'] == 'in_progress')
        .length;

    final totalRevenue = requests.fold<double>(
      0,
      (sum, r) => sum + (r['totalAmount'] ?? 0),
    );
    final averageBins =
        requests.fold<double>(0, (sum, r) => sum + (r['binCount'] ?? 1)) /
        totalRequests;

    // Calculate completion rate
    final completionRate = totalRequests > 0
        ? (completedRequests / totalRequests) * 100
        : 0;

    // Get top towns by request count
    final Map<String, int> townCounts = {};
    for (final request in requests) {
      final town = request['userTown']?.toString().toLowerCase() ?? 'unknown';
      townCounts[town] = (townCounts[town] ?? 0) + 1;
    }

    final topTowns = townCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalRequests': totalRequests,
      'emergencyRequests': emergencyRequests,
      'completedRequests': completedRequests,
      'pendingRequests': pendingRequests,
      'inProgressRequests': inProgressRequests,
      'completionRate': completionRate,
      'totalRevenue': totalRevenue,
      'averageBins': averageBins,
      'topTowns': topTowns
          .take(5)
          .map((e) => {'town': e.key, 'count': e.value})
          .toList(),
      'period': {'startDate': startDate, 'endDate': endDate},
    };
  }

  static Map<String, int> _getDayDistribution(
    List<Map<String, dynamic>> requests,
  ) {
    final Map<String, int> distribution = {};
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    for (final day in days) {
      distribution[day] = 0;
    }

    for (final request in requests) {
      final createdAt = (request['createdAt'] as Timestamp).toDate();
      final dayName = DateFormat('EEEE').format(createdAt);
      distribution[dayName] = (distribution[dayName] ?? 0) + 1;
    }

    return distribution;
  }

  static String _getDemandLevel(int requestCount) {
    if (requestCount >= 20) return 'Very High';
    if (requestCount >= 15) return 'High';
    if (requestCount >= 10) return 'Medium';
    if (requestCount >= 5) return 'Low';
    return 'Very Low';
  }

  static Map<String, dynamic> _generateForecast(
    List<Map<String, dynamic>> requests,
    DateTime now,
  ) {
    if (requests.isEmpty) return _getEmptyForecast();

    // Simple moving average for next 7 days
    final dailyRequests = <String, int>{};
    for (final request in requests) {
      final createdAt = (request['createdAt'] as Timestamp).toDate();
      final dayKey = DateFormat('yyyy-MM-dd').format(createdAt);
      dailyRequests[dayKey] = (dailyRequests[dayKey] ?? 0) + 1;
    }

    // Calculate average daily requests
    final totalDays = dailyRequests.length;
    final averageDaily = totalDays > 0 ? requests.length / totalDays : 0;

    // Generate forecast for next 7 days
    final forecast = <Map<String, dynamic>>[];
    for (int i = 1; i <= 7; i++) {
      final forecastDate = now.add(Duration(days: i));
      final dayName = DateFormat('EEEE').format(forecastDate);

      // Adjust based on day of week patterns
      double multiplier = 1.0;
      if (dayName == 'Saturday' || dayName == 'Sunday') {
        multiplier = 0.7; // Lower demand on weekends
      } else if (dayName == 'Monday') {
        multiplier = 1.2; // Higher demand on Monday
      }

      forecast.add({
        'date': forecastDate,
        'dayName': dayName,
        'predictedRequests': (averageDaily * multiplier).round(),
        'confidence': _getConfidenceLevel(totalDays),
      });
    }

    return {
      'forecast': forecast,
      'averageDaily': averageDaily,
      'totalPredicted': forecast.fold<int>(
        0,
        (sum, f) => sum + f['predictedRequests'] as int,
      ),
      'generatedAt': now,
    };
  }

  static String _getConfidenceLevel(int dataPoints) {
    if (dataPoints >= 20) return 'High';
    if (dataPoints >= 10) return 'Medium';
    return 'Low';
  }

  static String _getWeekKey(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return DateFormat('MMM dd').format(startOfWeek);
  }

  static Map<String, dynamic> _getEmptyAnalytics() {
    return {
      'totalRequests': 0,
      'emergencyRequests': 0,
      'completedRequests': 0,
      'pendingRequests': 0,
      'inProgressRequests': 0,
      'completionRate': 0,
      'totalRevenue': 0,
      'averageBins': 0,
      'topTowns': [],
    };
  }

  static Map<String, dynamic> _getEmptyForecast() {
    return {
      'forecast': [],
      'averageDaily': 0,
      'totalPredicted': 0,
      'generatedAt': DateTime.now(),
    };
  }
}
