import 'package:flutter/material.dart';
import 'package:flutter_application_1/mobile_app/services/analytics_service.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _demandInsights = [];
  List<Map<String, dynamic>> _weeklyTrends = [];
  Map<String, dynamic> _forecast = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        AnalyticsService.getPickupAnalytics(),
        AnalyticsService.getDemandInsightsByArea(),
        AnalyticsService.getWeeklyTrends(),
        AnalyticsService.getPredictiveForecast(),
      ]);

      setState(() {
        _analytics = results[0] as Map<String, dynamic>;
        _demandInsights = results[1] as List<Map<String, dynamic>>;
        _weeklyTrends = results[2] as List<Map<String, dynamic>>;
        _forecast = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Demand', icon: Icon(Icons.location_city)),
            Tab(text: 'Forecast', icon: Icon(Icons.trending_up)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDemandTab(),
                _buildForecastTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildTopTownsCard(),
          const SizedBox(height: 24),
          _buildWeeklyTrendsChart(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'Total Requests',
          _analytics['totalRequests']?.toString() ?? '0',
          Icons.assignment,
          Colors.blue,
        ),
        _buildStatCard(
          'Emergency Requests',
          _analytics['emergencyRequests']?.toString() ?? '0',
          Icons.emergency,
          Colors.red,
        ),
        _buildStatCard(
          'Completion Rate',
          '${(_analytics['completionRate'] ?? 0).toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Total Revenue',
          'GH₵${(_analytics['totalRevenue'] ?? 0).toStringAsFixed(0)}',
          Icons.attach_money,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopTownsCard() {
    final topTowns = _analytics['topTowns'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_city, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              const Text(
                'Top Areas by Demand',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topTowns.isEmpty)
            const Text(
              'No data available',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...topTowns.map(
              (town) => _buildTownItem(
                town['town']?.toString() ?? 'Unknown',
                town['count']?.toString() ?? '0',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTownItem(String town, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              town.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count requests',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendsChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green.shade600),
              const SizedBox(width: 12),
              const Text(
                'Weekly Trends (Last 4 Weeks)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_weeklyTrends.isEmpty)
            const Text(
              'No trend data available',
              style: TextStyle(color: Colors.grey),
            )
          else
            SizedBox(height: 200, child: _buildTrendsChart()),
        ],
      ),
    );
  }

  Widget _buildTrendsChart() {
    final maxRequests = _weeklyTrends.fold<int>(
      0,
      (max, trend) => (trend['totalRequests'] as int) > max
          ? trend['totalRequests'] as int
          : max,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _weeklyTrends.map((trend) {
        final height = maxRequests > 0
            ? (trend['totalRequests'] as int) / maxRequests
            : 0.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${trend['totalRequests']}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: height * 150,
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trend['week']?.toString() ?? '',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDemandTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Demand Insights by Area',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_demandInsights.isEmpty)
            const Center(
              child: Text(
                'No demand data available',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._demandInsights.map((insight) => _buildDemandCard(insight)),
        ],
      ),
    );
  }

  Widget _buildDemandCard(Map<String, dynamic> insight) {
    final town = insight['town']?.toString() ?? 'Unknown';
    final totalRequests = insight['totalRequests'] as int? ?? 0;
    final emergencyRequests = insight['emergencyRequests'] as int? ?? 0;
    final completionRate = insight['completionRate'] as double? ?? 0;
    final demandLevel = insight['demandLevel']?.toString() ?? 'Low';
    final totalRevenue = insight['totalRevenue'] as double? ?? 0;

    Color demandColor;
    switch (demandLevel) {
      case 'Very High':
        demandColor = Colors.red;
        break;
      case 'High':
        demandColor = Colors.orange;
        break;
      case 'Medium':
        demandColor = Colors.yellow.shade700;
        break;
      default:
        demandColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  town.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: demandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: demandColor),
                ),
                child: Text(
                  demandLevel,
                  style: TextStyle(
                    color: demandColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInsightItem(
                  'Total Requests',
                  totalRequests.toString(),
                  Icons.assignment,
                ),
              ),
              Expanded(
                child: _buildInsightItem(
                  'Emergency',
                  emergencyRequests.toString(),
                  Icons.emergency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInsightItem(
                  'Completion Rate',
                  '${completionRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildInsightItem(
                  'Revenue',
                  'GH₵${totalRevenue.toStringAsFixed(0)}',
                  Icons.attach_money,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForecastTab() {
    final forecast = _forecast['forecast'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Predictive Forecast',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Next 7 days demand prediction',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          if (forecast.isEmpty)
            const Center(
              child: Text(
                'No forecast data available',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...forecast.map((day) => _buildForecastCard(day)),
        ],
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> day) {
    final date = day['date'] as DateTime? ?? DateTime.now();
    final dayName = day['dayName']?.toString() ?? '';
    final predictedRequests = day['predictedRequests'] as int? ?? 0;
    final confidence = day['confidence']?.toString() ?? 'Low';

    Color confidenceColor;
    switch (confidence) {
      case 'High':
        confidenceColor = Colors.green;
        break;
      case 'Medium':
        confidenceColor = Colors.orange;
        break;
      default:
        confidenceColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                DateFormat('dd').format(date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$predictedRequests',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blue.shade700,
                ),
              ),
              Text(
                'requests',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: confidenceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: confidenceColor),
            ),
            child: Text(
              confidence,
              style: TextStyle(
                color: confidenceColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
